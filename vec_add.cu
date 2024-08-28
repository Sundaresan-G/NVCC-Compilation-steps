#include <cuda_runtime.h>
#include <iostream>
#include <vector>

/*
Total device time elapsed: 1.18128ms for 1024 * 1024 * 128 elements
Test PASSED
Done
*/

#define CHECK_CUDA_ERROR(call)                                                 \
    {                                                                          \
        const cudaError_t error = call;                                        \
        if (error != cudaSuccess) {                                            \
            std::cerr << "Error: " << __FILE__ << ":" << __LINE__ << ", "      \
                      << "code: " << error << ", reason: "                     \
                      << cudaGetErrorString(error) << std::endl;               \
            exit(1);                                                           \
        }                                                                      \
    }

// CUDA Kernel function to add elements of two arrays
__global__ void vectorAdd(const float *A, const float *B, float *C, int numElements) {
    size_t i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < numElements) {
        C[i] = A[i] + B[i];
    }
}

int main(void) {
    // Size of vectors
    size_t numElements = 1024 * 1024 * 128;
    size_t size = numElements * sizeof(float);

    // Host vectors
    std::vector<float> h_A(numElements);
    std::vector<float> h_B(numElements);
    std::vector<float> h_C(numElements);

    // Initialize the host input vectors
    for (int i = 0; i < numElements; ++i) {
        h_A[i] = rand() / (float)RAND_MAX;
        h_B[i] = rand() / (float)RAND_MAX;
    }

    // Device vectors
    float *d_A = nullptr;
    float *d_B = nullptr;
    float *d_C = nullptr;

    // Allocate memory on host and device
    cudaMalloc((void **)&d_A, size);
    cudaMalloc((void **)&d_B, size);
    cudaMalloc((void **)&d_C, size);

    // Copy input vectors from host memory to device memory
    cudaMemcpy(d_A, h_A.data(), size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B.data(), size, cudaMemcpyHostToDevice);

    // Launch the Vector Add CUDA Kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;

    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, numElements); //warmup

    // Start timer
    cudaEvent_t start, stop;
    CHECK_CUDA_ERROR(cudaEventCreate(&start));
    CHECK_CUDA_ERROR(cudaEventCreate(&stop));
    CHECK_CUDA_ERROR(cudaEventRecord(start, 0));

    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, numElements);

    // Check for any errors launching the kernel
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "Failed to launch vectorAdd kernel (error code " << cudaGetErrorString(err) << ")!\n";
        exit(EXIT_FAILURE);
    }

    // Stop timer
    CHECK_CUDA_ERROR(cudaEventRecord(stop, 0));
    CHECK_CUDA_ERROR(cudaEventSynchronize(stop));

    // Calculate elapsed time
    float elapsedTime;
    CHECK_CUDA_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));

    std::cout << "Total device time elapsed: "<<elapsedTime <<"ms \n";

    // Copy the device result vector back to the host result vector
    cudaMemcpy(h_C.data(), d_C, size, cudaMemcpyDeviceToHost);

    // Verify that the result vector is correct
    for (int i = 0; i < numElements; ++i) {
        if (fabs(h_A[i] + h_B[i] - h_C[i]) > 1e-5) {
            std::cerr << "Result verification failed at element " << i << "!\n";
            exit(EXIT_FAILURE);
        }
    }

    std::cout << "Test PASSED\n";

    // Free device global memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    std::cout << "Done\n";
    return 0;
}