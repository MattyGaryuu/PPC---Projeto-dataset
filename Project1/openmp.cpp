#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include<chrono>

#define limit 15

std::fstream dataset;
std::vector<std::string> dictindex;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar o dataset
//aplicar hash aqui para quando cubstituir a tabela
int Point = 1; //ponteiro para orientar onde o dataset parou de ler, ja pulando primeira etapa
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida
std::fstream dict;
int Daux;


void CreateDictArchive() { //função para a criação dos arquivos de dicionario
    #pragma omp parallel //Criar os Dicionarios baseado nas colunas
        {
            //nesse caso a diferenca usando open mp foi qnula, dado que leitura e escrita de dados geralmente nao faz muita diferenca ser paralelo
            if (dataset.is_open()) {
                if (std::getline(dataset, Line)) {
                    std::cout << "A primeira linha do arquivo é: " << Line << std::endl;
                    std::istringstream StringLine(Line);
                    std::string data; //armazenar os valores separados por virguma
                    while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                        dict.open("dicts/" + data + ".csv", std::ios::in | std::ios::out | std::ios::app);
                        dict.imbue(std::locale(""));
                        dictindex.push_back("dicts/" + data + ".csv");
                        //dict << "codigo,descrição" << '\n';
                        dict.close();
                    }
                    std::cout << "Numero de Colunas: " << dictindex.size() << std::endl;
                }
                else {
                    std::cerr << "O arquivo está vazio." << std::endl;
                }
            }
            else {
                std::cerr << "Não foi possível abrir o arquivo." << std::endl;
            }
        }
}

void ReadCsv() {
    //dataset.open("testeMaior.csv", std::ios::in | std::ios::out | std::ios::app);
    #pragma omp parallel
    {
        #pragma omp for schedule(dynamic)
        int p_aux = Point;
        for (int i = p_aux; i < (p_aux + limit); i++) {
            if(std::getline(dataset, Line)){

                //separar linha unica em varios componentes para a matriz
                #pragma omp critical
                {
                    std::istringstream StringLine(Line);
                    std::string aux;
                    std::vector<std::string> V_aux;
                    while (std::getline(StringLine, aux, ',')) {
                        V_aux.push_back(aux);
                        //std::cout << aux + ",";
                    }
                    //std::cout << std::endl;
                    m_dataset.push_back(V_aux);
                    Point++;
                }
            }
            else {
                std::cerr << "O arquivo está vazio." << std::endl;
                break;
            }
        }
    }

}

bool Verify(int value, std::string VD) {
    dict.open(dictindex[value], std::ios::in);
    dict.seekg(0, std::ios::beg);
    if (dict.is_open()) {
        while (std::getline(dict, Line)) {
            bool can_verify = false;
            std::istringstream StringLine(Line);
            std::string data; //armazenar os valores separados por virguma
            while (std::getline(StringLine, data, ',')) {
                if(can_verify){
                    //std::cout << VD + "nao eh" + data << std::endl;
                    if (VD == data) {
                        dict.close();
                        //std::cout << "maczada";
                        return false;
                        break;
                    }
                }
                else {
                    can_verify = true;
                }
            }
        }
    }
    else {
        std::cerr << "Erro ao abrir o arquivo "  + dictindex[value] << std::endl;
    }
    dict.close();
    return true; // nao esta na lista
}

void Editdict() {
    for (int i = 0; i < dictindex.size(); i++) {
        Daux = 0;
        for (int j = 0; j < m_dataset.size(); j++) {
            
            //[j] [i]
            if (Verify(i, m_dataset[j][i])) {
                Daux++;
                dict.open(dictindex[i], std::ios::app);
                dict << std::to_string(Daux) + "," + m_dataset[j][i] << '\n';
                std::cout << std::to_string(Daux) +" saf " + m_dataset[j][i] << std::endl;
                dict.close();
            }
            else {
                std::cout << m_dataset[j][i] + "Ja esta no arquivo" << std::endl;
            }
        }
    }
}



void imprimir() { //apagar na versao final
    for (int i = 0; i < m_dataset.size(); i++) {
        for(int j = 0; j < m_dataset[i].size(); j++){
            std::cout << m_dataset[i][j];
        }
        std::cout << Point << std::endl;
    }
}

int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    //std::ifstream arquivo("sample.csv"); //teste
    dataset.open("testeMaior.csv", std::ios::in | std::ios::out | std::ios::app); //arquivo
    dataset.imbue(std::locale(""));

    CreateDictArchive();
    ReadCsv();
    Editdict();
    //imprimir(); //testar

    dataset.close();

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}
