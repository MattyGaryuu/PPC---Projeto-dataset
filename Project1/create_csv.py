import csv
import random

# 1000000 and 52 == roughly 1GB (WARNING TAKES a while, 30s+)
rows = 10
columns = 5000

def generate_random_row(col):
    a = []
    l = [i]
    for j in range(col):
        l.append(random.random())
    a.append(l)
    return a

if __name__ == '__main__':
    f = open('sample.csv', 'w')
    w = csv.writer(f, lineterminator='\n')
    for i in range(rows):
        w.writerows(generate_random_row(columns))
    f.close()