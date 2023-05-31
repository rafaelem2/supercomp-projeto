#include <iostream>
#include <vector>
#include <algorithm>
#include <bitset>
#include <omp.h>

using namespace std;

struct filme {
    int inicio;
    int fim;
    int categoria;
};

bool compareMovies(filme a, filme b) {
    return a.fim < b.fim;
}

void filtro(vector<filme>& movies) {
    movies.erase(
        remove_if(movies.begin(), movies.end(), [](const filme& movie) {
            return movie.fim <= movie.inicio;
        }),
        movies.end());
}

bool isTimeAvailable(const bitset<24>& times, const filme& movie) {
    for (int i = movie.inicio; i < movie.fim; i++) {
        if (times[i]) {
            return false;
        }
    }
    return true;
}

vector<filme> chooseMovies(vector<filme>& movies, vector<int>& categoriesMax) {
    int n = movies.size();
    int combinations = 1 << n; // 2^n
    vector<filme> chosenMovies;
    bitset<24> movieTimes;

    #pragma omp parallel for
    for (int i = 1; i < combinations; i++) {
        bool valid = true;
        vector<filme> currentSelection;
        bitset<24> currentMovieTimes;
        vector<int> currentCategoriesMax = categoriesMax;

        for (int j = 0; j < n; j++) {
            if ((i >> j) & 1) { 
                filme currentMovie = movies[j];
                if (currentCategoriesMax[currentMovie.categoria - 1] > 0 && isTimeAvailable(currentMovieTimes, currentMovie)) {
                    currentSelection.push_back(currentMovie);
                    for (int k = currentMovie.inicio; k < currentMovie.fim; k++) {
                        currentMovieTimes[k] = true;
                    }
                    currentCategoriesMax[currentMovie.categoria - 1]--;
                } else {
                    valid = false;
                    break;
                }
            }
        }

        #pragma omp critical
        {
            if (valid && currentSelection.size() > chosenMovies.size()) {
                chosenMovies = currentSelection;
            }
        }
    }

    return chosenMovies;
}

int main() {
    int n, n_categories;
    cin >> n >> n_categories;

    vector<filme> movies(n);
    vector<int> categoriesMax(n_categories);

    for (int i = 0; i < n_categories; i++) {
        cin >> categoriesMax[i];
    }

    for (int i = 0; i < n; i++) {
        cin >> movies[i].inicio >> movies[i].fim >> movies[i].categoria;
        if (movies[i].fim == 0) {
            movies[i].fim = 24;
        }
    }

    filtro(movies);

    sort(movies.begin(), movies.end(), compareMovies);

    vector<filme> chosenMovies = chooseMovies(movies, categoriesMax);

    cout << "Número de filmes: " << chosenMovies.size() << endl;

    for (int i = 0; i < chosenMovies.size(); i++) {
        cout << chosenMovies[i].inicio << " " << chosenMovies[i].fim << " " << chosenMovies[i].categoria << endl;
    }

    return 0;
}
