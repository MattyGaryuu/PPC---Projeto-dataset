
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <string.h>
#include <stdio.h>

#define LIMIT 150//00000
#define N (1000*1024)


bool in_BlackList(char**, char[], int);

void CreateDictFile(FILE* dataset, FILE* wdataset, char** BlackList, char dict_index[26][201], int sizeBlack) {
    if (dataset != NULL) {
        char Line[500];
        fgets(Line, 500, dataset);
        fprintf(wdataset, "%s\n" , Line); //escrever as colunas no arquivo final
        char* StringLine = strtok(Line, ","); //dividir Linha em tokens, separados por ,
        int i = 0;
        FILE* dict;

        while (StringLine != NULL) { //Enquanto houver tokens
            char* actual = strdup(StringLine); //pegar token atual

            //verificar se o valor esta na blacklist
            if (in_BlackList(BlackList, actual, sizeBlack)) {
                strcpy(dict_index[i], "b");
            }
            else {
                snprintf(dict_index[i], 201, "dicts/%s.csv", actual);
                dict = fopen(dict_index[i], "wb");
                if (dict != NULL) {
                    fprintf(dict, "id, descrição");
                    //funcao para preencher id
                    fclose(dict);
                }
            }
            StringLine = strtok(NULL, ","); //Proximo token
            i++;
        }

    }
}

bool in_BlackList(char** BackList, char Value[], int size) {

    for (int i = 0; i < size; i++) {
        if (strcmp(BackList[i], Value) == 0) {
            return true;
        }
    }
    return false;
}

void readCircle() {

}

int main()
{
    FILE* dataset = fopen("dataset_00_sem_virg.csv", "r");
    FILE* wdataset = fopen("dataset_00_sem_virg_final.csv", "w");

    char* Blacklist[] = { "idatracacao", "idcarga", "nacionalidadearmador", "pesocarga_cntr", "pesocargabruta", "qtcarga", "tatracado", "tesperaatracacao", "tesperacainicioop",
"tesperadesatracacao", "testadia", "toperacao", "ano" }; //os seguintes nomes sao colunas de valores ja numericos, nao precisando de um tratamento de id para tais
    char dict_index[26][201];

    CreateDictFile(dataset,wdataset,Blacklist,dict_index, sizeof(Blacklist) / sizeof(Blacklist[0]));

    return 0;
}
