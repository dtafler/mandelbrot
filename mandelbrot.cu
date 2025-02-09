#include <SFML/Graphics.hpp>
#include <iostream>
#include <cuda_runtime.h>

const int WIDTH = 800;
const int HEIGHT = 600;

__device__ int mandelbrot(double real, double imag, int maxIter) {
    double zr = 0.0, zi = 0.0;
    int iter = 0;

    while (zr * zr + zi * zi <= 4.0 && iter < maxIter) {
        double temp = zr * zr - zi * zi + real;
        zi = 2.0 * zr * zi + imag;
        zr = temp;
        iter++;
    }

    return iter;
}

__global__ void mandelbrotKernel(int width, int height, double centerX, double centerY, double scale, int maxIter, int* d_image) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        double real = scale * (x - (width / 2.0)) - centerX;
        double imag = centerY + scale * (y - (height / 2.0));

        int iter = mandelbrot(real, imag, maxIter);
        d_image[y * width + x] = iter;
    }
}

sf::Color getColor(int iter, int maxIter) {
    if (iter == maxIter) return sf::Color::Black;
    double t = (double)iter / maxIter;
    return sf::Color((int)(9 * (1 - t) * t * t * t * 255),
                     (int)(15 * (1 - t) * (1 - t) * t * t * 255),
                     (int)(8.5 * (1 - t) * (1 - t) * (1 - t) * t * 255));
}
int getMaxIterations(double zoom) {
    return (int)(100 + log2(zoom) * 50);  // Increase iterations as zoom deepens
}

int main() {
    sf::RenderWindow window(sf::VideoMode(WIDTH, HEIGHT), "Mandelbrot Explorer with CUDA");

    int* d_image;
    cudaMalloc(&d_image, WIDTH * HEIGHT * sizeof(int));
    int* h_image = new int[WIDTH * HEIGHT];

    double centerX = -0.75, centerY = 0.0, scale = 4.0 / WIDTH;
    dim3 blockSize(16, 16);
    dim3 gridSize((WIDTH + blockSize.x - 1) / blockSize.x, (HEIGHT + blockSize.y - 1) / blockSize.y);

    sf::Image image;
    image.create(WIDTH, HEIGHT);
    sf::Texture texture;
    sf::Sprite sprite(texture);

    sf::Font font;
    if (!font.loadFromFile("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")) {
        std::cerr << "Error loading font!\n";
    }

    sf::Text zoomText;
    zoomText.setFont(font);
    zoomText.setCharacterSize(20);
    zoomText.setFillColor(sf::Color::White);

    while (window.isOpen()) {
        zoomText.setString("Zoom: " + std::to_string(1.0 / scale) + "\nCenter: (" +
                        std::to_string(centerX) + ", " + std::to_string(centerY) + ")");
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
            
            bool redraw = false;

            // handle zoom
            double zoomSpeed = 0.25;
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::D)) {
                scale *= (1.0 - zoomSpeed);
                redraw = true;
            }
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::F)) {
                scale *= (1.0 + zoomSpeed);
                redraw = true;
            }

            // handle pan
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::Up)) {
                // std::cout << "UP\n";
                centerY -= 50 * scale;
                redraw = true;
            }
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::Down)) {
                // std::cout << "DOWN\n";
                centerY += 50 * scale;
                redraw = true;
            }
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::Left)) {
                // std::cout << "LEFT\n";
                centerX += 50 * scale;
                redraw = true;
            }
            if (sf::Keyboard::isKeyPressed(sf::Keyboard::Right)) {
                // std::cout << "RIGHT\n";
                centerX -= 50 * scale;
                redraw = true;
            }

            if (redraw) {
                int maxIter = getMaxIterations(1.0 / scale);
                // std::cout << maxIter << std::endl;
                mandelbrotKernel<<<gridSize, blockSize>>>(WIDTH, HEIGHT, centerX, centerY, scale, maxIter, d_image);
                cudaMemcpy(h_image, d_image, WIDTH * HEIGHT * sizeof(int), cudaMemcpyDeviceToHost);
                
                for (int x = 0; x < WIDTH; ++x) {
                    for (int y = 0; y < HEIGHT; ++y) {
                        image.setPixel(x, y, getColor(h_image[y * WIDTH + x], maxIter));
                    }
                }
            }

        }

        texture.loadFromImage(image);
        sprite.setTexture(texture, true);

        window.clear();
        window.draw(sprite);
        window.draw(zoomText);
        window.display();
    }

    cudaFree(d_image);
    delete[] h_image;
    return 0;
}
