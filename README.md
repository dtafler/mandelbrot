# **Mandelbrot Explorer with CUDA**

## **Overview**
This project is a **Mandelbrot set explorer** accelerated using **CUDA** for fast fractal rendering. 
![Mandelbrot Zoom](mandelbrot.gif)

## **Features**
- **High-performance Mandelbrot rendering** using **CUDA parallelization**.
- **Smooth zooming & panning** with keyboard controls.
- **Dynamic iteration scaling** for improved detail at deeper zoom levels.

## **Controls**
| **Key** | **Action** |
|---------|-----------|
| `D` | Zoom in |
| `F` | Zoom out |
| `Arrow Keys` | Pan up, down, left, right |
| `Esc` / Close Button | Exit program |

## **Requirements**
- **CUDA-enabled GPU** (NVIDIA).
- **SFML** (install `libsfml-dev` on Linux or **SFML package** on Windows).
- **C++17+** and **CUDA Toolkit** installed.

## **Installation & Compilation**
Compile using **NVCC**:

```bash
nvcc -o mandelbrot_cuda mandelbrot.cu -lsfml-graphics -lsfml-window -lsfml-system
```


## **Running the Program**
```bash
./mandelbrot_cuda
```
