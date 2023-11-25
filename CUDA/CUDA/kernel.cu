//#include "cuda_runtime.h"
//#include "device_launch_parameters.h"
//#include <string.h>
//#include <stdio.h>
//#include <time.h>
//
//#define LIMIT 150//00000
//#define N (1000*1024)
//
//
//bool in_BlackList(char**, char[], int);
//
//void CreateDictFile(FILE* dataset, FILE* wdataset, char** BlackList, char dict_index[26][201], int sizeBlack) {
//    if (dataset != NULL) {
//        char Line[500];
//        fgets(Line, 500, dataset);
//        fprintf(wdataset, "%s\n" , Line); //escrever as colunas no arquivo final
//        char* StringLine = strtok(Line, ","); //dividir Linha em tokens, separados por ,
//        int i = 0;
//        FILE* dict;
//
//        while (StringLine != NULL) { //Enquanto houver tokens
//            char* actual = strdup(StringLine); //pegar token atual
//
//            //verificar se o valor esta na blacklist
//            if (in_BlackList(BlackList, actual, sizeBlack)) {
//                strcpy(dict_index[i], "b");
//            }
//            else {
//                snprintf(dict_index[i], 201, "dicts/%s.csv", actual);
//                dict = fopen(dict_index[i], "wb");
//                if (dict != NULL) {
//                    fprintf(dict, "id, descrição");
//
//                    //funcao para preencher id
//                    fclose(dict);
//                }
//            }
//            StringLine = strtok(NULL, ","); //Proximo token
//            i++;
//        }
//
//    }
//}
//
//bool in_BlackList(char** BackList, char Value[], int size) {
//
//    for (int i = 0; i < size; i++) {
//        if (strcmp(BackList[i], Value) == 0) {
//            return true;
//        }
//    }
//    return false;
//}
//
//void datasetManipulation(char dict_index[26][201],int d_aux, char m_dataset[(int)(LIMIT * 0.10) + 1][26][201]) {
//    char Line[500];
//    char ids[LIMIT][201];
//    
//    for (int i = 0; i < 26; i++) {
//        if(strlen(dict_index[i]) > 1) {
//            int index = 0;
//            FILE* dict = fopen(dict_index[i], "r");
//            if (dict != NULL) {
//                fgets(Line, 500, dict); //ler primeira linha para ignorar
//                while (fgets(Line, 500, dict)) {
//                    char* StringLine = strtok(Line, ",");
//                    StringLine = strtok(NULL, ","); //ignorar primeira id
//                    strcpy(ids[index], strdup(StringLine));
//                    index++;
//                }
//                fclose(dict);
//            }
//
//
//            //preencher ids
//            for (int j = d_aux+1; j > 0; j--) {
//                bool in_id = false;
//                for (int z = 0; z < index; z++) {
//                    if (strcmp(ids[z], m_dataset[j][i]) == 0) {
//                        in_id = true;
//                    }
//                }
//                if (!in_id) {
//                    strcpy(ids[index], m_dataset[j][i]);
//                    printf("%s", ids[index]);
//                    index++;
//                }
//            }
//
//            dict = fopen(dict_index[i], "w");
//            if (dict != NULL) {
//                fprintf(dict, "id, descrição\n");
//                for (int j = 0; j < index; j++) {
//                    fprintf(dict, "%d,%s\n", (j + 1), ids[j]);
//                }
//                fclose(dict);
//            }
//        }
//    }
//}
//
//void readCircle(FILE* dataset, char dict_index[26][201]) {
//    int aux = (int)(LIMIT * 0.10) + 1;
//    int sum = 1;
//    char Line[500];
//    bool can_loop = true;
//    fgets(Line, sizeof(Line), dataset);
//    
//    while(LIMIT >= sum)
//    {
//        int d_aux = 0;
//        char m_dataset[(int)(LIMIT * 0.10) + 1][26][201];
//        while (fgets(Line, sizeof(Line), dataset) != NULL && aux > d_aux) {
//            //printf("%s\n", Line);
//            char* StringLine = strtok(Line, ",");
//            int i = 0;
//            while (StringLine != NULL) { //Enquanto houver tokens
//                char* actual = strdup(StringLine); //pegar token atual
//                //printf("%s\n", actual);
//                if (strlen(actual) > 0) {
//                    strcpy(m_dataset[d_aux][i], actual);
//                }
//                //printf(" %s ", m_dataset[d_aux][i]);
//                StringLine = strtok(NULL, ",");
//                i++;
//            }
//            //printf("%s ", m_dataset[][0]);
//            //datasetManipulation(dict_index,d_aux, m_dataset);
//            
//            sum++;
//            d_aux++;
//        }
//for (int z = 0; z < (int)(LIMIT * 0.10) + 1; z++) {
//                printf("linha %d: ", z);
//                for (int j = 0; j < 26; j++) {
//                    //printf("%s ", m_dataset[z][j]);
//                }
//                printf("\n");
//            }
//
//        
//    }
//    
//}
//
//int main()
//{
//
//    FILE* dataset = fopen("dataset_00_sem_virg.csv", "r");
//    FILE* wdataset = fopen("dataset_00_sem_virg_final.csv", "w");
//
//    char* Blacklist[] = { "idatracacao", "idcarga", "nacionalidadearmador", "pesocarga_cntr", "pesocargabruta", "qtcarga", "tatracado", "tesperaatracacao", "tesperacainicioop",
//"tesperadesatracacao", "testadia", "toperacao", "ano" }; //os seguintes nomes sao colunas de valores ja numericos, nao precisando de um tratamento de id para tais
//    char dict_index[26][201];
//
//    CreateDictFile(dataset,wdataset,Blacklist,dict_index, sizeof(Blacklist) / sizeof(Blacklist[0]));
//    readCircle(dataset, dict_index);
//    return 0;
//}
