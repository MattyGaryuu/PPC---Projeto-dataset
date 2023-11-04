#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include<chrono>

using namespace std;


int main() {
    auto start_time = std::chrono::high_resolution_clock::now();
    //std::ifstream arquivo("sample.csv"); //teste
    std::ifstream arquivo("testeMaior.csv"); //arquivo

#pragma omp parallel //Criar os Dicionarios baseado nas colunas
    {
        //nesse caso a diferenca usando open mp foi quase nula, foi tentado fazer um pushback no while e depois um parallel for, mas o tempo de execucao piorou
        if (arquivo.is_open()) {
            std::string Line; //string responsavel por armazenar a linha
            if (std::getline(arquivo, Line)) {
                std::cout << "A primeira linha do arquivo é: " << Line << std::endl;
                int num_column = 0; //descobrir a quantidade de coluna
                std::istringstream StringLine(Line);
                std::string data; //armazenar os valores separados por virguma
                while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                    num_column++; // Conta as colunas
                    std::ofstream dict;
                    dict.open("dicts/" + data + ".csv");
                    if (arquivo.is_open()) {
                        arquivo.close();
                    }
                }
                std::cout << "Numero de Colunas: " << num_column << std::endl;
            }
            else {
                std::cerr << "O arquivo está vazio." << std::endl;
            }

            arquivo.close();
        }
        else {
            std::cerr << "Não foi possível abrir o arquivo." << std::endl;
        }
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    std::cout << "Tempo de execução: " << duration << " milissegundos" << std::endl;

    return 0;
}
