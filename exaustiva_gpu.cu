#include <iostream>
#include <vector>
#include <algorithm>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/remove.h>

using namespace std;

struct Filme {
    int inicio;
    int fim;
    int categoria;
};

struct CompareFilmes {
    __host__ __device__
    bool operator()(const Filme& a, const Filme& b) const {
        return a.fim < b.fim;
    }
};

struct Filtro {
    __host__ __device__
    bool operator()(const Filme& filme) const {
        return filme.fim <= filme.inicio;
    }
};

struct Combination {
    int count;
    vector<Filme> filmes;
};

vector<int> getCategoriaCounts(const Combination& combination) {
    vector<int> categoriaCounts(10, 0);  // Assumindo que o máximo número de categorias é 10
    for (const auto& filme : combination.filmes) {
        categoriaCounts[filme.categoria]++;
    }
    return categoriaCounts;
}

bool checkCategoriaLimits(const Combination& combination, const vector<int>& categoriasMax) {
    vector<int> categoriaCounts = getCategoriaCounts(combination);
    for (int i = 1; i <= categoriasMax.size(); i++) {
        if (categoriaCounts[i] > categoriasMax[i - 1]) {
            return false;
        }
    }
    return true;
}

bool checkOverlap(const Filme& filme1, const Filme& filme2) {
    return filme1.inicio < filme2.fim && filme2.inicio < filme1.fim;
}

Combination findMaxCombination(const thrust::device_vector<Filme>& filmesDevice, const vector<int>& categoriasMax,
                               Combination& currentCombination, int currentIndex) {
    if (currentIndex >= filmesDevice.size()) {
        return currentCombination;
    }

    const Filme& filmeAtual = filmesDevice[currentIndex];

    // Verificar se o filme atual pode ser adicionado à combinação
    bool podeAdicionarFilme = true;

    // Verificar se há overlap entre o filme atual e os filmes já presentes na combinação
    for (const auto& filme : currentCombination.filmes) {
        if (checkOverlap(filme, filmeAtual)) {
            podeAdicionarFilme = false;
            break;
        }
    }

    Combination maxCombination = currentCombination;

    if (podeAdicionarFilme) {
        Combination withFilme = currentCombination;
        withFilme.filmes.push_back(filmeAtual);
        withFilme.count++;

        // Verificar se a combinação atual satisfaz as restrições de categorias
        if (checkCategoriaLimits(withFilme, categoriasMax)) {
            // Chamada recursiva para testar a próxima posição
            Combination combinationWithFilme = findMaxCombination(filmesDevice, categoriasMax, withFilme, currentIndex + 1);

            if (combinationWithFilme.count > maxCombination.count) {
                maxCombination = combinationWithFilme;
            }
        }
    }

    // Verificar se é possível obter uma combinação melhor a partir da próxima posição
    if (currentCombination.count + filmesDevice.size() - currentIndex > maxCombination.count) {
        // Chamada recursiva para pular para a próxima posição sem adicionar o filme atual
        Combination combinationWithoutFilme = findMaxCombination(filmesDevice, categoriasMax, currentCombination, currentIndex + 1);

        if (combinationWithoutFilme.count > maxCombination.count) {
            maxCombination = combinationWithoutFilme;
        }
    }

    return maxCombination;
}

bool validateArgs(int argc, char *argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <filename>" << endl;
        return false;
    }
    return true;
}

int main(int argc, char *argv[]) {
    if (!validateArgs(argc, argv)) {
        return 1;
    }

    int N;
    int M;
    vector<Filme> filmes;
    vector<int> categoriasMax;

    cin >> N >> M;

    for (int i = 0; i < M; i++) {
        int categoriaMax;
        cin >> categoriaMax;
        categoriasMax.push_back(categoriaMax);
    }

    for (int i = 0; i < N; i++) {
        Filme filme;
        cin >> filme.inicio >> filme.fim >> filme.categoria;
        filmes.push_back(filme);
    }

    thrust::host_vector<Filme> filmesHost = filmes;
    thrust::device_vector<Filme> filmesDevice = filmesHost;

    thrust::sort(filmesDevice.begin(), filmesDevice.end(), CompareFilmes());

    filmesDevice.erase(thrust::remove_if(filmesDevice.begin(), filmesDevice.end(), Filtro()), filmesDevice.end());

    thrust::host_vector<Filme> filmesResultadoHost = filmesDevice;

    Combination combinacaoAtual;
    Combination maxCombination = findMaxCombination(filmesDevice, categoriasMax, combinacaoAtual, 0);

    cout << maxCombination.filmes.size() << endl;
    for (const auto& filme : maxCombination.filmes) {
        cout << filme.inicio << " " << filme.fim << " " << filme.categoria << endl;
    }

    return 0;
}


