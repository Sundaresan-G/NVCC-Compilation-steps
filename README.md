## NVCC Compilation understanding
NVIDIA V100 with arch=sm_70. 
CUDA Toolkit 12.1

Reference: https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/#the-cuda-compilation-trajectory

1. Using nvcc -dryrun option, output is provided at the bottom.
2. Host compiler generates preprocesses file .cpp4.ii: 
`gcc -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -E -x c++ -D__CUDACC__ -D__NVCC__  "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 "vec_add.cu" -o "tmpxft_00004a81_00000000-5_vec_add.cpp4.ii" `.
3. cudafe++ generates the stub file .cudafe1.stub.c, module ID file .module_id and further processes the previous .cpp4.ii input file to obtain .cudfe1.cpp file for host side.
`cudafe++ --c++17 --gnu_version=120200 --display_error_number --orig_src_file_name "vec_add.cu" --orig_src_path_name "/home/hgx/sundaresan/gpu_trials/vec_add.cu" --allow_managed  --m64 --parse_templates --gen_c_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.cpp" --stub_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c" --gen_module_id_file --module_id_file_name "tmpxft_00004a81_00000000-4_vec_add.module_id" "tmpxft_00004a81_00000000-5_vec_add.cpp4.ii"`
4. Host compiler is used again on source .cu file to generate device side preprocessed file .cpp1.ii.
`gcc -D__CUDA_ARCH__=700 -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -E -x c++  -DCUDA_DOUBLE_MATH_FUNCTIONS -D__CUDACC__ -D__NVCC__  "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 "vec_add.cu" -o "tmpxft_00004a81_00000000-9_vec_add.cpp1.ii"`
5. cicc uses .cpp1.ii and source .cu file to generate .cudafe1.stub.c, .cudafe1.c, .cudafe1.gpu and finally output file .ptx. This ptx file contains the requires intermediate representation of kernel function. Each ptx file can contain several kernel functions, but for only one architecture.
`cicc --c++17 --gnu_version=120200 --display_error_number --orig_src_file_name "vec_add.cu" --orig_src_path_name "/home/hgx/sundaresan/gpu_trials/vec_add.cu" --allow_managed   -arch compute_70 -m64 --no-version-ident -ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 --include_file_name "tmpxft_00004a81_00000000-3_vec_add.fatbin.c" -tused --module_id_file_name "tmpxft_00004a81_00000000-4_vec_add.module_id" --gen_c_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.c" --stub_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c" --gen_device_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.gpu"  "tmpxft_00004a81_00000000-9_vec_add.cpp1.ii" -o "tmpxft_00004a81_00000000-6_vec_add.ptx"`
6. ptxas generates the binary file .cubin from .ptx.
`ptxas -arch=sm_70 -m64  "tmpxft_00004a81_00000000-6_vec_add.ptx"  -o "tmpxft_00004a81_00000000-10_vec_add.sm_70.cubin" `
7. fatbinary embeds .cubin file machine instructions in .fatbin.c. This .fatbin.c is included in .cudafe1.stub.c and thus subsequently in .cudafe1.cpp. Thus .cudafe1.cpp contains both host and device side code after this point.
`fatbinary -64 --cicc-cmdline="-ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 " "--image3=kind=elf,sm=70,file=tmpxft_00004a81_00000000-10_vec_add.sm_70.cubin" "--image3=kind=ptx,sm=70,file=tmpxft_00004a81_00000000-6_vec_add.ptx" --embedded-fatbin="tmpxft_00004a81_00000000-3_vec_add.fatbin.c" `
8. Host compiler compiles code .cudafe1.cpp (contains both host and device codes) to object file .o without linking.
`gcc -D__CUDA_ARCH__=700 -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -c -x c++  -DCUDA_DOUBLE_MATH_FUNCTIONS -Wno-psabi "-I/home/hgx/.triton/nvidia/bin/../include"   -m64 "tmpxft_00004a81_00000000-6_vec_add.cudafe1.cpp" -o "tmpxft_00004a81_00000000-11_vec_add.o"`
9. nvlink operates on host object file .o to assist dynamic linking by creation of a_dlink.reg.c, a_dlink.sm_70.cubin files.  
`nvlink -m64 --arch=sm_70 --register-link-binaries="tmpxft_00004a81_00000000-7_a_dlink.reg.c"    "-L/home/hgx/.triton/nvidia/bin/../lib/stubs" "-L/home/hgx/.triton/nvidia/bin/../lib" -cpu-arch=X86_64 "tmpxft_00004a81_00000000-11_vec_add.o"  -lcudadevrt  -o "tmpxft_00004a81_00000000-12_a_dlink.sm_70.cubin" --host-ccbin "gcc"`
10. fatbinary embeds a_dlink.sm_70.cubin file to a_dlink.fatbin.c file.
`fatbinary -64 --cicc-cmdline="-ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 " -link "--image3=kind=elf,sm=70,file=tmpxft_00004a81_00000000-12_a_dlink.sm_70.cubin" --embedded-fatbin="tmpxft_00004a81_00000000-8_a_dlink.fatbin.c" `
11. Finally host compilers compile a_dlink.fatbin.c to a_dlink.o. 
`gcc -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -c -x c++ -DFATBINFILE="\"tmpxft_00004a81_00000000-8_a_dlink.fatbin.c\"" -DREGISTERLINKBINARYFILE="\"tmpxft_00004a81_00000000-7_a_dlink.reg.c\"" -I. -D__NV_EXTRA_INITIALIZATION= -D__NV_EXTRA_FINALIZATION= -D__CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__  -Wno-psabi "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -m64 "/home/hgx/.triton/nvidia/bin/crt/link.stub" -o "tmpxft_00004a81_00000000-13_a_dlink.o"`
12. Then host compiler links cudart and cudadevrt statically (default behaviour) to get the final executable .out.
`g++ -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -m64 -Wl,--start-group "tmpxft_00004a81_00000000-13_a_dlink.o" "tmpxft_00004a81_00000000-11_vec_add.o"   "-L/home/hgx/.triton/nvidia/bin/../lib/stubs" "-L/home/hgx/.triton/nvidia/bin/../lib"  -lcudadevrt  -lcudart_static  -lrt -lpthread  -ldl  -Wl,--end-group -o "a.out"`



# nvcc -arch=sm_70 -dryrun code.cu
```bash
_NVVM_BRANCH_=nvvm
_NVVM_BRANCH_SUFFIX_=
_SPACE_= 
_CUDART_=cudart
_HERE_=/home/hgx/.triton/nvidia/bin
_THERE_=/home/hgx/.triton/nvidia/bin
_TARGET_SIZE_=
_TARGET_DIR_=
_TARGET_SIZE_=64
TOP=/home/hgx/.triton/nvidia/bin/..
NVVMIR_LIBRARY_DIR=/home/hgx/.triton/nvidia/bin/../nvvm/libdevice
LD_LIBRARY_PATH=/home/hgx/.triton/nvidia/bin/../lib:/usr/local/cuda-12.1/lib64:/usr/local/cuda-12.1/extras/CUPTI/lib64::/data/sudarsh2/gurobi/gurobi951/linux64/lib:/data/sudarsh2/gurobi/gurobi951/linux64/lib
PATH=/home/hgx/.triton/nvidia/bin/../nvvm/bin:/home/hgx/.triton/nvidia/bin:/home/hgx/.triton/nvidia/bin:/usr/local/cuda-12.1/bin:/home/hgx/miniforge3/envs/sundaresan/bin:/home/hgx/miniforge3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:
INCLUDES="-I/home/hgx/.triton/nvidia/bin/../include"  
LIBRARIES=  "-L/home/hgx/.triton/nvidia/bin/../lib/stubs" "-L/home/hgx/.triton/nvidia/bin/../lib"
CUDAFE_FLAGS=
PTXAS_FLAGS=
gcc -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -E -x c++ -D__CUDACC__ -D__NVCC__  "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 "vec_add.cu" -o "tmpxft_00004a81_00000000-5_vec_add.cpp4.ii" 
cudafe++ --c++17 --gnu_version=120200 --display_error_number --orig_src_file_name "vec_add.cu" --orig_src_path_name "/home/hgx/sundaresan/gpu_trials/vec_add.cu" --allow_managed  --m64 --parse_templates --gen_c_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.cpp" --stub_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c" --gen_module_id_file --module_id_file_name "tmpxft_00004a81_00000000-4_vec_add.module_id" "tmpxft_00004a81_00000000-5_vec_add.cpp4.ii" 
gcc -D__CUDA_ARCH__=700 -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -E -x c++  -DCUDA_DOUBLE_MATH_FUNCTIONS -D__CUDACC__ -D__NVCC__  "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 "vec_add.cu" -o "tmpxft_00004a81_00000000-9_vec_add.cpp1.ii" 
cicc --c++17 --gnu_version=120200 --display_error_number --orig_src_file_name "vec_add.cu" --orig_src_path_name "/home/hgx/sundaresan/gpu_trials/vec_add.cu" --allow_managed   -arch compute_70 -m64 --no-version-ident -ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 --include_file_name "tmpxft_00004a81_00000000-3_vec_add.fatbin.c" -tused --module_id_file_name "tmpxft_00004a81_00000000-4_vec_add.module_id" --gen_c_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.c" --stub_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c" --gen_device_file_name "tmpxft_00004a81_00000000-6_vec_add.cudafe1.gpu"  "tmpxft_00004a81_00000000-9_vec_add.cpp1.ii" -o "tmpxft_00004a81_00000000-6_vec_add.ptx"
ptxas -arch=sm_70 -m64  "tmpxft_00004a81_00000000-6_vec_add.ptx"  -o "tmpxft_00004a81_00000000-10_vec_add.sm_70.cubin" 
fatbinary -64 --cicc-cmdline="-ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 " "--image3=kind=elf,sm=70,file=tmpxft_00004a81_00000000-10_vec_add.sm_70.cubin" "--image3=kind=ptx,sm=70,file=tmpxft_00004a81_00000000-6_vec_add.ptx" --embedded-fatbin="tmpxft_00004a81_00000000-3_vec_add.fatbin.c" 
# rm tmpxft_00004a81_00000000-3_vec_add.fatbin
gcc -D__CUDA_ARCH__=700 -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -c -x c++  -DCUDA_DOUBLE_MATH_FUNCTIONS -Wno-psabi "-I/home/hgx/.triton/nvidia/bin/../include"   -m64 "tmpxft_00004a81_00000000-6_vec_add.cudafe1.cpp" -o "tmpxft_00004a81_00000000-11_vec_add.o" 
nvlink -m64 --arch=sm_70 --register-link-binaries="tmpxft_00004a81_00000000-7_a_dlink.reg.c"    "-L/home/hgx/.triton/nvidia/bin/../lib/stubs" "-L/home/hgx/.triton/nvidia/bin/../lib" -cpu-arch=X86_64 "tmpxft_00004a81_00000000-11_vec_add.o"  -lcudadevrt  -o "tmpxft_00004a81_00000000-12_a_dlink.sm_70.cubin" --host-ccbin "gcc"
fatbinary -64 --cicc-cmdline="-ftz=0 -prec_div=1 -prec_sqrt=1 -fmad=1 " -link "--image3=kind=elf,sm=70,file=tmpxft_00004a81_00000000-12_a_dlink.sm_70.cubin" --embedded-fatbin="tmpxft_00004a81_00000000-8_a_dlink.fatbin.c" 
# rm tmpxft_00004a81_00000000-8_a_dlink.fatbin
gcc -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -c -x c++ -DFATBINFILE="\"tmpxft_00004a81_00000000-8_a_dlink.fatbin.c\"" -DREGISTERLINKBINARYFILE="\"tmpxft_00004a81_00000000-7_a_dlink.reg.c\"" -I. -D__NV_EXTRA_INITIALIZATION= -D__NV_EXTRA_FINALIZATION= -D__CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__  -Wno-psabi "-I/home/hgx/.triton/nvidia/bin/../include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=4 -D__CUDACC_VER_BUILD__=99 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=4 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -m64 "/home/hgx/.triton/nvidia/bin/crt/link.stub" -o "tmpxft_00004a81_00000000-13_a_dlink.o" 
g++ -D__CUDA_ARCH_LIST__=700 -D__NV_LEGACY_LAUNCH -m64 -Wl,--start-group "tmpxft_00004a81_00000000-13_a_dlink.o" "tmpxft_00004a81_00000000-11_vec_add.o"   "-L/home/hgx/.triton/nvidia/bin/../lib/stubs" "-L/home/hgx/.triton/nvidia/bin/../lib"  -lcudadevrt  -lcudart_static  -lrt -lpthread  -ldl  -Wl,--end-group -o "a.out" 
```
