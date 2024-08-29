#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wcast-qual"
#define __NV_CUBIN_HANDLE_STORAGE__ static
#if !defined(__CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__)
#define __CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__
#endif
#include "crt/host_runtime.h"
#include "tmpxft_00004a81_00000000-3_vec_add.fatbin.c"
extern void __device_stub__Z9vectorAddPKfS0_Pfi(const float *, const float *, float *, int);
extern void __device_stub__Z9addFloat4PK6float4S1_PS_m(const struct float4 *, const struct float4 *, struct float4 *, size_t);
static void __nv_cudaEntityRegisterCallback(void **);
static void __sti____cudaRegisterAll(void) __attribute__((__constructor__));
void __device_stub__Z9vectorAddPKfS0_Pfi(const float *__par0, const float *__par1, float *__par2, int __par3){__cudaLaunchPrologue(4);__cudaSetupArgSimple(__par0, 0UL);__cudaSetupArgSimple(__par1, 8UL);__cudaSetupArgSimple(__par2, 16UL);__cudaSetupArgSimple(__par3, 24UL);__cudaLaunch(((char *)((void ( *)(const float *, const float *, float *, int))vectorAdd)));}
# 23 "vec_add.cu"
void vectorAdd( const float *__cuda_0,const float *__cuda_1,float *__cuda_2,int __cuda_3)
# 23 "vec_add.cu"
{__device_stub__Z9vectorAddPKfS0_Pfi( __cuda_0,__cuda_1,__cuda_2,__cuda_3);




}
# 1 "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c"
void __device_stub__Z9addFloat4PK6float4S1_PS_m( const struct float4 *__par0,  const struct float4 *__par1,  struct float4 *__par2,  size_t __par3) {  __cudaLaunchPrologue(4); __cudaSetupArgSimple(__par0, 0UL); __cudaSetupArgSimple(__par1, 8UL); __cudaSetupArgSimple(__par2, 16UL); __cudaSetupArgSimple(__par3, 24UL); __cudaLaunch(((char *)((void ( *)(const struct float4 *, const struct float4 *, struct float4 *, size_t))addFloat4))); }
# 31 "vec_add.cu"
void addFloat4( const struct float4 *__cuda_0,const struct float4 *__cuda_1,struct float4 *__cuda_2,size_t __cuda_3)
# 31 "vec_add.cu"
{__device_stub__Z9addFloat4PK6float4S1_PS_m( __cuda_0,__cuda_1,__cuda_2,__cuda_3);
# 39 "vec_add.cu"
}
# 1 "tmpxft_00004a81_00000000-6_vec_add.cudafe1.stub.c"
static void __nv_cudaEntityRegisterCallback( void **__T8) {  __nv_dummy_param_ref(__T8); __nv_save_fatbinhandle_for_managed_rt(__T8); __cudaRegisterEntry(__T8, ((void ( *)(const struct float4 *, const struct float4 *, struct float4 *, size_t))addFloat4), _Z9addFloat4PK6float4S1_PS_m, (-1)); __cudaRegisterEntry(__T8, ((void ( *)(const float *, const float *, float *, int))vectorAdd), _Z9vectorAddPKfS0_Pfi, (-1)); }
static void __sti____cudaRegisterAll(void) {  __cudaRegisterBinary(__nv_cudaEntityRegisterCallback);  }

#pragma GCC diagnostic pop
