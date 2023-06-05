#include <iostream>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>

using namespace std;

struct filme {
    int inicio;
    int fim;
    int categoria;

    __host__ __device__
    bool operator<(const filme& other) const {
        return inicio < other.inicio;
    }
};

void filtro(thrust::host_vector<filme>& movies) {
    movies.erase(
        remove_if(movies.begin(), movies.end(), [](const filme& movie) {
            return movie.fim <= movie.inicio;
        }),
        movies.end());
}

bool isTimeAvailable(const thrust::device_vector<bool>& times, const filme& movie) {
    for (int i = movie.inicio; i < movie.fim; i++) {
        if (times[i]) {
            return false;
        }
    }
    return true;
}

thrust::host_vector<filme> chooseMovies(thrust::host_vector<filme>& movies, thrust::host_vector<int>& categoriesMax) {
    int n = movies.size();
    int combinations = 1 << n; // 2^n
    thrust::host_vector<filme> chosenMovies;
    thrust::host_vector<bool> movieTimes(24, false);

    for (int i = 1; i < combinations; i++) {
        bool valid = true;
        thrust::host_vector<filme> currentSelection;
        thrust::host_vector<bool> currentMovieTimes = movieTimes;
        thrust::host_vector<int> currentCategoriesMax = categoriesMax;

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
        if (valid && currentSelection.size() > chosenMovies.size()) {
            chosenMovies = currentSelection;
        }
    }

    return chosenMovies;
}

int main() {
    int n, n_categories;
    cin >> n >> n_categories;

    thrust::host_vector<filme> movies(n);
    thrust::host_vector<int> categoriesMax(n_categories);

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

    thrust::sort(thrust::host, movies.begin(), movies.end());

    thrust::host_vector<filme> chosenMovies = chooseMovies(movies, categoriesMax);

    cout << "Número de filmes: " << chosenMovies.size() << endl;

    for (int i = 0; i < chosenMovies.size(); i++) {
        cout << chosenMovies[i].inicio << " " << chosenMovies[i].fim << " " << chosenMovies[i].categoria << endl;
    }

    return 0;
}

