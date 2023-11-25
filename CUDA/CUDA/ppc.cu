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

#define limit 150//00000
#define columns 26
#define string_size 255

std::fstream dataset;
std::fstream wdataset;
std::vector<std::string> dictindex;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar a parte do dataset que devera ser modificado
char h_dataset[limit][12][string_size]; //matriz que ira armazenar a parte do dataset que devera ser modificado
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida
std::fstream dict;
int number = 0;
std::map<int, int> Orietation; //guardar as colunas exatas de onde o dataset sera tratado, para ajudar na escrita final

char h_ids[limit][12][string_size];

std::vector<std::string> blacklist = { "idatracacao", "idcarga", "nacionalidadearmador", "pesocarga_cntr", "pesocargabruta", "qtcarga", "tatracado", "tesperaatracacao", "tesperacainicioop",
"tesperadesatracacao", "testadia", "toperacao", "ano", "cdmercadoria_cntr"}; //os seguintes nomes sao colunas de valores ja numericos, nao precisando de um tratamento de id para tais

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
            int i = 0;
            wdataset << Line << std::endl; //escrever cabecalho no arquivo
            std::istringstream StringLine(Line);
            std::string data; //armazenar os valores separados por virguma
            while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                if (!in_blackList(data)) {
                    dictindex.push_back("dicts/" + data + ".csv");
                    Orietation[i] = 0;
                    number++;
                    dict.open("dicts/" + data + ".csv", std::ios::out | std::ios::trunc); //excluir conteudo se ja existir
                    dict.close();
                }
                else
                {
                    dictindex.push_back("b");
                }
                i++;
            }
        }
    }
}

//void WriteCsv(int sum) {
//
//    for (int i = 0; i < m_dataset.size(); i++) {
//        Line = m_dataset[i][0];
//        for (int j = 1; j < m_dataset[i].size(); j++) {
//            Line += "," + m_dataset[i][j];
//        }
//        wdataset << Line + '\n';
//    }
//
//}

void WriteCsv(int sum) {
    printf("alo %s", h_dataset[0][0]);
    for (int i = 0; i < m_dataset.size(); i++) {
        wdataset << m_dataset[i][0];
        int index = 1, indext = 0;
        for (int j = 1; j < columns; j++) {
            if (Orietation.find(j) == Orietation.end()) {
                wdataset << "," + m_dataset[i][index];
                index++;
            }
            else {
                wdataset << "," + std::string(h_dataset[i][indext]);
                indext++;
            }
        }
        wdataset << '\n';
    }

}

int Id(int indexc) {
    std::map<std::string, int> ids;
    int indexl = 0;
    bool loop = true;
    while (strlen(h_ids[indexl][indexc]) > 0) {
        ids[h_ids[indexl][indexc]] = indexl + 1;
        indexl++;
    }


    for (int j = 0; j < m_dataset.size(); j++) {
        if (ids.find(m_dataset[j][indexc]) == ids.end()) {
            ids[m_dataset[j][indexc]] = ids.size();
            //strcpy(h_ids[indexl][indexc], "");
            snprintf(h_ids[indexl][indexc], string_size, m_dataset[j][indexc].c_str(), indexl, indexc);
            indexl++;
        }
    }

    ids.clear();

    return indexl;
}


void readCircle() {
    int sum = 0;
    int aux = static_cast<int>((limit * 0.10)); // dividir o servico em 10 partes
    bool can_loop = true;

    while (!dataset.eof() && can_loop || limit >= sum && can_loop) {
        m_dataset.clear();
        for (int i = 0; i < aux; i++) {
            int col = 0; //coluna referencia para o dataset host
            int acol = 0; //coluna atual
            if (std::getline(dataset, Line) && limit >= sum) {
                //separar linha unica em varios componentes para a matriz
                std::istringstream StringLine(Line);
                std::string z_aux;
                std::vector<std::string> V_aux;
                while (std::getline(StringLine, z_aux, ',')) {
                    if (Orietation.find(acol) == Orietation.end()) {
                        V_aux.push_back(z_aux);
                    }
                    else {
                        printf("s");
                        strcpy(h_dataset[i][col], z_aux.c_str());
                        col++;
                    }
                    acol++;
                    
                }
                m_dataset.push_back(V_aux);
                
                //strcy(h_dataset[sum][i])

            }
            else {
                can_loop = false;
            }
            sum++;
        }
        
        //int indexc = -1;
        //for (int i = 0; i < dictindex.size(); i++) {
        //    if (dictindex[i].size() > 1) {
        //        indexc++;
        //        int length = Id(indexc);

        //        std::ofstream dict_out(dictindex[i], std::ios::out | std::ios::trunc); // Excluir conteúdo se já existir
        //        if(dict_out.is_open())
        //        {
        //            dict_out << "Id, Descrição\n";
        //            for (int j = 0; j < length; j++) {
        //                //std::cout << h_ids[j][i] << " ";
        //                if(strlen(h_ids[j][i]) > 0) dict_out << std::to_string(j + 1) + "," + h_ids[j][i] + "\n";
        //            }
        //            dict_out.close();
        //        }
        //        //printf("%d ",length);
        //    }
        //}

        //datasetManipulation();
        WriteCsv(sum);
    }
}


int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    wdataset.open("dataset_00_sem_virg_final.csv", std::ios::out | std::ios::trunc);
    //dataset.close();
    dataset.open("dataset_00_sem_virg.csv", std::ios::in | std::ios::out | std::ios::app); //arquivo

    CreateDictArchive();
    //wdataset << '\n';
    readCircle();
    dataset.close();
    wdataset.close();

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}