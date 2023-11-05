#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include<chrono>

std::fstream dataset;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar o dataset
int Pointer = 1; //ponteiro para orientar onde o dataset parou de ler, pular primeira linha do dataset que armazena os nomes das colunas.
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida


void CreateDictArchive() { //função para a criação dos arquivos de dicionario
    #pragma omp parallel //Criar os Dicionarios baseado nas colunas
        {
            //nesse caso a diferenca usando open mp foi qnula, dado que leitura e escrita de dados geralmente nao faz muita diferenca ser paralelo
            if (dataset.is_open()) {
                if (std::getline(dataset, Line)) {
                    std::cout << "A primeira linha do arquivo é: " << Line << std::endl;
                    int num_column = 0; //descobrir a quantidade de coluna
                    std::istringstream StringLine(Line);
                    std::string data; //armazenar os valores separados por virguma
                    while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                        num_column++; // Conta as colunas
                        std::fstream dict("dicts/" + data + ".csv", std::ios::in | std::ios::out | std::ios::app);
                        dict << "codigo,descrição" << '\n';
                        dict.close();
                    }
                    std::cout << "Numero de Colunas: " << num_column << std::endl;
                }
                else {
                    std::cerr << "O arquivo está vazio." << std::endl;
                }
    
                dataset.close();
            }
            else {
                std::cerr << "Não foi possível abrir o arquivo." << std::endl;
            }
        }
}

void ReadCsv() {
    std::string line;

}

int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    //std::ifstream arquivo("sample.csv"); //teste
    dataset.open("testeMaior.csv", std::ios::in | std::ios::out | std::ios::app); //arquivo

    CreateDictArchive();

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}
