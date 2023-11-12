#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include<chrono>
#include <algorithm>
#include<omp.h>

#define limit 15000000
std::fstream dataset;
std::fstream wdataset;
std::vector<std::string> dictindex;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar o dataset
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida
std::fstream dict;

std::vector<std::string> blacklist = { "idatracacao", "idcarga", "nacionalidadearmador", "pesocarga_cntr", "pesocargabruta", "qtcarga", "tatracado", "tesperaatracacao", "tesperacainicioop",
"tesperadesatracacao", "testadia", "toperacao", "ano"}; //os seguintes nomes sao colunas de valores ja numericos, nao precisando de um tratamento de id para tais

void CreateDictArchive() { //função para a criação dos arquivos de dicionario
            //nesse caso a diferenca usando open mp foi qnula, dado que leitura e escrita de dados geralmente nao faz muita diferenca ser paralelo
            if (dataset.is_open()) {
                if (std::getline(dataset, Line)) {
                    std::istringstream StringLine(Line);
                    std::string data; //armazenar os valores separados por virguma
                    while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                        //tratar black list
                        bool aux = true;
                        for (int i = 0; i < blacklist.size(); i++)
                        {
                            if (data == blacklist[i]) {
                                //#pragma omp critical
                                aux = false;
                            }

                        }
                        if(aux){
                            dictindex.push_back("dicts/" + data + ".csv");
                            dict.open("dicts/" + data + ".csv", std::ios::out | std::ios::trunc); //excluir conteudo se ja existir
                            dict.close();
                        }
                        else {
                            dictindex.push_back("b"); //sinalizador de black list, importante colocar no vetor para que a ordem natural dos outros dados nao fujam do controle
                        }
                        if (dictindex.size() == 1) {
                            wdataset << data;
                        }
                        else{
                            wdataset << "," + data;
                        }
                        

                    }
                }
                else {
                    std::cerr << "O arquivo está vazioo." << std::endl;
                }
            }
            else {
                std::cerr << "Não foi possível abrir o arquivo." << std::endl;
            }
}

void WriteCsv(int sum) {

    for (int i = 0; i < m_dataset.size(); i++) {
        Line = m_dataset[i][0];
        for (int j = 1; j < m_dataset[i].size(); j++) {
            Line += "," + m_dataset[i][j];
        }
        wdataset << Line + '\n';
    }
    
}

void datasetManipulation() {
#pragma omp parallel for shared(dictindex)
    for (int i = 0; i < dictindex.size(); i++) {
        if (dictindex[i].size() > 1) {
            std::map<std::string, int> ids;
            ids[""] = 0;

            std::ifstream dict(dictindex[i]);
            std::string Line;
            std::getline(dict, Line); // Não ler a primeira linha

            while (std::getline(dict, Line)) {
                std::istringstream StringLine(Line);
                std::string value, key;
                while (std::getline(StringLine, value, ',')) {
                    std::getline(StringLine, key, ',');
                    ids[key] = std::stoi(value);
                }
            }
            dict.close();

//O programa se comportor melhor na leitura e escrita dos ids sem o uso de thread, mesmo com omp critical ainda estava dando erros de index nos arquivos
            for (int j = 0; j < m_dataset.size(); j++) {
                if (ids.find(m_dataset[j][i]) == ids.end()) {
                    ids[m_dataset[j][i]] = ids.size();
                }
            }

#pragma omp parallel for
            for (int j = 0; j < m_dataset.size(); j++) {
                m_dataset[j][i] = std::to_string(ids.find(m_dataset[j][i])->second);
            }

            ids.erase(ids.begin());

            std::vector<std::pair<std::string, int>> aux(ids.begin(), ids.end()); //passando para um vetor para a organizacao numerica
            std::sort(aux.begin(), aux.end(),
                [](const auto& a, const auto& b)
                { return a.second < b.second; });

            std::ofstream dict_out(dictindex[i], std::ios::out | std::ios::trunc); // Excluir conteúdo se já existir
            dict_out << "Id, Descrição\n";
            for (const auto& pair : aux) {
                dict_out << std::to_string(pair.second) + "," + pair.first + "\n";
            }
            dict_out.close();
            aux.clear();
        }
    }
}

void readCircle() {
    int sum = 1;
    int aux = static_cast<int>((limit * 0.10));
    bool can_loop = true;
    while (!dataset.eof() && can_loop || (limit + 1) >= sum && can_loop) {
        m_dataset.clear();
        for (int i = 0; i < aux; i++) {
            if (std::getline(dataset, Line) && (limit + 1) >= sum) {
                    //separar linha unica em varios componentes para a matriz
                    std::istringstream StringLine(Line);
                    std::string aux;
                    std::vector<std::string> V_aux;
                    while (std::getline(StringLine, aux, ',')) {
                        V_aux.push_back(aux);
                    }
                    m_dataset.push_back(V_aux);
                }
                else {
                    can_loop = false;
                }
                sum++;
        }
        datasetManipulation();
        WriteCsv(sum);
    }
}

int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    wdataset.open("dataset_00_sem_virg_final.csv", std::ios::out | std::ios::trunc);
    dataset.close();
    dataset.open("dataset_00_sem_virg.csv", std::ios::in | std::ios::out | std::ios::app); //arquivo

    CreateDictArchive();
    dataset << '\n';
    readCircle();
    dataset.close();
    wdataset.close();

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}
