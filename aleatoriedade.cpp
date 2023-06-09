#include <iostream>
#include <vector>
#include <algorithm>
#include <bitset>
#include <random>
#include <boost/random.hpp>

using namespace std;

struct filme {
    int inicio;
    int fim;
    int categoria;
};

bool compareMovies(filme a, filme b) {
    return a.fim < b.fim;
}

bool timeAvailable(bitset<24>& times, filme movie){
    for (int i = movie.inicio; i < movie.fim; i++) {
        if (times[i] == 1) {
            return false;
        }
    }
    return true;
}

void filtro (vector<filme> &movies){
        movies.erase(
        remove_if(movies.begin(), movies.end(), [](const filme& movie) {
            return movie.fim <= movie.inicio;
    }), movies.end());
}

vector<filme> chooseMovies(vector<filme>& movies, vector<int>& categoriesMax) {
    bitset<24> movieTimes;
    vector<filme> chosenMovies;

    std::default_random_engine generator;
    std::uniform_real_distribution<double> distribution(0.0, 1.0);

    for (int i = 0; i < movies.size(); i++) {
        if (distribution(generator) <= 0.25) {
            int randomIndex = rand() % movies.size();
            if (categoriesMax[movies[randomIndex].categoria] > 0 && timeAvailable(movieTimes, movies[randomIndex])) {
                chosenMovies.push_back(movies[randomIndex]);
                for (int j = movies[randomIndex].inicio; j < movies[randomIndex].fim; j++) {
                    movieTimes[j] = 1;
                }
                categoriesMax[movies[randomIndex].categoria]--;
            }
        }
        else if (categoriesMax[movies[i].categoria] > 0 && timeAvailable(movieTimes, movies[i])) {
            chosenMovies.push_back(movies[i]);
            for (int j = movies[i].inicio; j < movies[i].fim; j++) {
                movieTimes[j] = 1;
            }
            categoriesMax[movies[i].categoria]--;
        }
    }

    return chosenMovies;
}

int main() {
    int n, n_categories;
    cin >> n >> n_categories;

    vector<filme> movies(n);
    vector<int> categoriesMax(n_categories+1);

    for (int i = 1; i < n_categories+1; i++) {
        cin >> categoriesMax[i];
    }

    for (int i = 0; i < n; i++) {
        cin >> movies[i].inicio >> movies[i].fim >> movies[i].categoria;
        if (movies[i].fim == 0){
            movies[i].fim = 24;
        }
    }

    filtro(movies);

    sort(movies.begin(), movies.end(), compareMovies);

    vector<filme> chosenMovies = chooseMovies(movies, categoriesMax);

     sort(chosenMovies.begin(), chosenMovies.end(), compareMovies);

    std::cout << "Número de filmes:" << chosenMovies.size() << std::endl; 

    for (int i = 0; i < chosenMovies.size(); i++) {
        std:: cout << chosenMovies[i].inicio << " " << chosenMovies[i].fim << " " << chosenMovies[i].categoria << std::endl;
    }

    return 0;
}

