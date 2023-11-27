#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <string>
#include <cstring>
#include <iostream>
#include <cstdio>
#include <vector>
#include <chrono>
#include <map>
#include <fstream>
#include <sstream>

#define limit 15000000
#define columns 26
#define string_size 128
#define Max_loop 500000

std::fstream dataset;
std::fstream wdataset;
std::vector<std::string> dictindex;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar a parte do dataset que devera ser modificado
//char h_dataset[limit][12][string_size]; //matriz que ira armazenar a parte do dataset que devera ser modificado
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida
std::fstream dict;
std::map<int, int> Orietation; //guardar as colunas exatas de onde o dataset sera tratado, para ajudar na escrita final



std::vector<std::string> blacklist = { "idatracacao", "idcarga", "nacionalidadearmador", "pesocarga_cntr", "pesocargabruta", "qtcarga", "tatracado", "tesperaatracacao", "tesperacainicioop",
"tesperadesatracacao", "testadia", "toperacao", "ano", "cdmercadoria_cntr" }; //os seguintes nomes sao colunas de valores ja numericos, nao precisando de um tratamento de id para tais

bool in_blackList(std::string value) {
    for (int i = 0; i < size(blacklist); i++) {
        if (blacklist[i] == value) {
            return true;
        }
    }

    return false;
}

//Funcao para ler a primeira linha do arquivo e criar os arquivos de dicionarios necessarios
void CreateDictArchive() {
    if (dataset.is_open()) {
        if (std::getline(dataset, Line)) {
            int i = 0; //responsavel por saber em qual coluna o token esta
            wdataset << Line << std::endl; //escrever cabecalho no arquivo
            std::istringstream StringLine(Line);
            std::string data; //armazenar os valores separados por virguma
            while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                if (!in_blackList(data)) { //blacklist eh responsavel por armazenar as colunas que nao devem ser tratadas
                    dictindex.push_back("dicts/" + data + ".csv");
                    Orietation[i] = 0; //adicionar coluna exata que devera ser tratada, usar a variavel na escrita do dataset
                    dict.open("dicts/" + data + ".csv", std::ios::out | std::ios::trunc); //excluir conteudo se ja existir
                    dict.close();
                }
                else
                {
                    dictindex.push_back("b"); //poderia ser qualquer valor ate memso vazio
                }
                i++;
            }
        }
    }
}

void Id(int indexc, char h_dataset[Max_loop][12][string_size], char h_ids[3000][12][string_size]) {
    std::map<std::string, int> ids; //mapa para facilitar busca
    int indexl = 0;
    //Varrer a tabela de ids para saber em qual index parou
    for (int i = 0; i < 3000; i++) {
        if(strlen(h_ids[i][indexc]) <= 0) break;
        ids[std::string(h_ids[i][indexc])] = i + 1;
        indexl++;
    }

    for (int j = 0; j < m_dataset.size(); j++) {
        if (ids.find(std::string(h_dataset[j][indexc])) == ids.end()) {
            ids[std::string(h_dataset[j][indexc])] = ids.size();
            snprintf(h_ids[indexl][indexc], string_size, h_dataset[j][indexc], indexl, indexc);
            indexl++;
        }
    }

}

void addDict(char h_ids[3000][12][string_size]) {
    int acol = 0; // variavel para acessar o index exato do char
    for (int i = 0; i < 26; i++) {
        if (dictindex[i].size() > 1) {
            std::ofstream dict_out(dictindex[i], std::ios::out | std::ios::trunc); // Excluir conteúdo se já existir
            if (dict_out.is_open())
            {
                dict_out << "Id, Descrição\n";
                for (int j = 0; j < 3000; j++) {
                    if (strlen(h_ids[j][acol]) > 0) dict_out << std::to_string(j + 1) + "," + h_ids[j][acol] + "\n";
                }
                dict_out.close();
                acol++;
            }
            
        }
    }
}

__global__ void CreateIdDataset(char* d_ids, char* d_dataset, int* d_final_dataset) {
    int threadId = blockIdx.x * blockDim.x + threadIdx.x;
    // Calcular a linha e a coluna baseado no valor da thread atual
    int row = threadId / 12;
    int col = threadId % 12;

    if (row < Max_loop && col < 12) {
        //Nao ha como comparar strings em device com funcoes como strcmp, entao o grupo para contornar essa situacao, trabalhou com
        //a ideia do que eh uma string na realidade: uma cadeia de char, entao se fez uma funcao para comparar cada caracter individualmente

        char value_to_find[string_size]; 
        for (int i = 0; i < string_size; i++) {
            value_to_find[i] = d_dataset[row * 12 * string_size + col * string_size + i];
        }

        //procurar em ids
        for (int row_ids = 0; row_ids < 3000; row_ids++) {
            bool strings_equal = true; //variavel responsavel para saber se as strings sao iguais

            //comparar
            for (int i = 0; i < string_size; ++i) {
                char id_value = d_ids[row_ids * 12 * string_size + col * string_size + i]; //caracter exato para se comparar

                if (id_value != value_to_find[i]) {
                    strings_equal = false;
                    break; //economizar tempo
                }
            }

            if (strings_equal) {
                d_final_dataset[row *12 + col] = row_ids + 1;

                break;
            }
        }
    }
}

char h_ids[3000][12][string_size]; //matriz de string responsavel por guardar todos os valores, o index da linha eh seu id, por C nao suportar tamanhos gigantescos de matriz
//apos testes usando c++ e openmp, decidimos usar um valor seguro de 3000 linhas
char h_dataset[Max_loop][12][string_size]; //matriz que ira armazenar a parte do dataset que devera ser modificado

void Loop() {
    bool can_loop = true;
    int sum = 0; //controle para saber se limite foi atingido
    int indexl = 0;

    while (!dataset.eof() && can_loop || limit >= sum && can_loop) {
        for (int i = 0; i < Max_loop; i++) {
            int col = 0; //coluna referencia para o dataset host
            int acol = 0; //coluna atual
            if (std::getline(dataset, Line) && limit >= sum) {
                //separar linha unica em varios componentes para a matriz
                std::istringstream StringLine(Line);
                std::string z_aux;
                std::vector<std::string> V_aux;
                while (std::getline(StringLine, z_aux, ',')) {
                    //procurar em orientation para saber se a coluna atual pertence a host
                    if (Orietation.find(acol) == Orietation.end()) {
                        V_aux.push_back(z_aux); //se nao pertencer dar pushback em V_aux
                    }
                    else {
                        strcpy(h_dataset[i][col], z_aux.c_str());
                        col++;
                    }
                    acol++;

                }
                m_dataset.push_back(V_aux);
                sum++;
            }
            else {
                can_loop = false;
            }
            
        }

        //procurar id de cada coluna
        for (int j = 0; j < 12; j++) {
            Id(j, h_dataset, h_ids);
        }

        //tratamento em cuda, o nosso grupo decidiu por fazer uma nova variavel int para que o valor de row seja armazenados nele,
        //ja que funcoes como to string e atoi nao funcionam no device
        char* d_ids;
        char* d_dataset;
        int* d_final_dataset; //responsavel por fazer as modificacoes

        cudaMalloc((void**)&d_ids, sizeof(char) * 3000 * 12 * string_size);
        cudaMemcpy(d_ids, h_ids, sizeof(char) * 3000 * 12 * string_size, cudaMemcpyHostToDevice);

        cudaMalloc((void**)&d_dataset, sizeof(char) * Max_loop * 12 * string_size);
        cudaMemcpy(d_dataset, h_dataset, sizeof(char) * Max_loop * 12 * string_size, cudaMemcpyHostToDevice);

        cudaMalloc((void**)&d_final_dataset, sizeof(int) * Max_loop * 12);


        dim3 block_dim(512, 1);
        dim3 grid_dim((Max_loop * 12 + block_dim.x - 1) / block_dim.x, 1);

        // Chame a função do kernel
        CreateIdDataset << <grid_dim, block_dim >> > (d_ids, d_dataset, d_final_dataset);


        cudaDeviceSynchronize();

        int* h_final_dataset = new int[Max_loop * 12]; //trazer o dataset final para o host atraves dessa variavel

        cudaMemcpy(h_final_dataset, d_final_dataset, sizeof(int) * Max_loop * 12, cudaMemcpyDeviceToHost);

        cudaFree(d_ids);
        cudaFree(d_dataset);
        cudaFree(d_final_dataset);

        //escrever no dataset
        for (int i = 0; i < m_dataset.size(); i++) {
            wdataset << m_dataset[i][0];
            int index = 1, indext = 0;
            for (int j = 1; j < 26; j++) {
                if (Orietation.find(j) == Orietation.end()) {
                    
                    wdataset << "," + m_dataset[i][index];
                    index++;
                }
                else {
                        wdataset << "," + std::to_string(h_final_dataset[i * 12 + indext]);
                        indext++;
                }
            }
            wdataset << '\n';

        }

        //resetar memoria
        for (int i = 0; i < Max_loop; ++i) {
            for (int j = 0; j < 12; ++j) {
                memset(h_dataset[i][j], 0, string_size);
            }
        }
        m_dataset.clear(); //limpar m_dataset
        printf("%d ", sum);
    }
}

int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    wdataset.open("dataset_00_sem_virg_final.csv", std::ios::out | std::ios::trunc);
    //dataset.close();
    dataset.open("dataset_00_sem_virg.csv", std::ios::in | std::ios::out | std::ios::app); //arquivo

    CreateDictArchive();
    Loop();
    addDict(h_ids);
    dataset.close();
    wdataset.close();

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}