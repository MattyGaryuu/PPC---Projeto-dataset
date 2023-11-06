#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include<chrono>

#define limit 1000

std::fstream dataset;
std::vector<std::string> dictindex;
std::vector<std::vector<std::string>> m_dataset; //matriz que ira armazenar o dataset
//aplicar hash aqui para quando cubstituir a tabela
int Point = 1; //ponteiro para orientar onde o dataset parou de ler, ja pulando primeira etapa
std::string Line; //string responsavel por armazenar a linha que atualmente esta sendo lida
std::fstream dict;
std::vector<std::string> m_a;
int Daux;


void CreateDictArchive() { //fun��o para a cria��o dos arquivos de dicionario
    #pragma omp parallel //Criar os Dicionarios baseado nas colunas
        {
            //nesse caso a diferenca usando open mp foi qnula, dado que leitura e escrita de dados geralmente nao faz muita diferenca ser paralelo
            if (dataset.is_open()) {
                if (std::getline(dataset, Line)) {
                    //std::cout << "A primeira linha do arquivo �: " << Line << std::endl;
                    std::istringstream StringLine(Line);
                    std::string data; //armazenar os valores separados por virguma
                    while (std::getline(StringLine, data, ',')) { //pegar o valor antes das/entre as virgula e armazenar em data
                        dictindex.push_back("dicts/" + data + ".csv");
                    }
                }
                else {
                    std::cerr << "O arquivo est� vazio." << std::endl;
                }
            }
            else {
                std::cerr << "N�o foi poss�vel abrir o arquivo." << std::endl;
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
                std::cerr << "O arquivo est� vazio." << std::endl;
                break;
            }
        }
    }

}

bool Verify(int value, std::string VD) {
    //procura na propria matriz temporaria se o valor aparece
    for (int i = 0; i < m_a.size(); i++) {
        if (m_a[i] == VD) {
            return false; //est� na lista
        }
    }
    return true; // nao esta na lista
}

void Editdict() {
    //Afim de poder aplicar uma paraleliza��o no c�digo, o grupo decidiu por fazer uma fun��o que usa-se de um vetor temporario para o armazenamento de dados de cada coluna, verificando
    // se ele n�o aparece no arquivo, se por acaso n�o aparecer um novo valor sera armazenado no vetor m_a. Ao final da fun��o ser� armazenado num arquivo .csv todos os ids.
    //
    //O Grupo tentou tamb�m fazer uma fun��o acessando o arquivo ao ines de um vetor auxiliar mas, como j� dito, era inviavel dado que leitura e escrita geralmente � feito de maneira
    //sequencial e essa leitura e escrita afetariam muito o desempenho do programa.

    for (int i = 0; i < dictindex.size(); i++) { //para cada coluna
        m_a.clear();
        //Ap�s 10 testes com o dataset de 1000 usando um i3 2100 foi percebido que a maneira mais otimizada seria as threads trabalharem a mesma coluna do que mexer simultaneamente em
        // todas (evitando tamb�m uma condi��o de corrida) media trabalhando cada coluna paralelamente:1431 ms. nedia threads trabalhando na mesma coluna = media:1175. collapse piorou a perfomance
        #pragma omp parallel for  
        for (int j = 0; j < m_dataset.size(); j++) { //para cada linha do dataset
            
            //[j] [i]
            if (Verify(i, m_dataset[j][i])) { //verificar se n�o aparece
                m_a.push_back(m_dataset[j][i]);
            }
        }
        //Ap�s analisado todas linhas, armazenar num arquivo
        dict.open(dictindex[i], std::ios::app);
        #pragma omp parallel for
        for(int j = 0; j < m_a.size(); j++){
            dict << std::to_string(j+1) + "," + m_a[j] + "\n"; //sera salvo no arquivo de modo que (index da matriz + 1),(Descri��o)
        }
        dict.close();
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
    std::cout << "Tempo de execu��o: " << duration << " milissegundos" << std::endl;

    return 0;
}
