#include <stdio.h>
#include <time.h>
#include <x86intrin.h>
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}
int main(){const long N=5000000;struct timespec t;volatile long long sink=0;double a,b;
 for(long i=0;i<200000;i++)clock_gettime(CLOCK_MONOTONIC,&t);
 a=now();for(long i=0;i<N;i++){clock_gettime(CLOCK_MONOTONIC,&t);sink+=t.tv_nsec;}b=now();
 printf("clock_gettime(MONOTONIC): %6.1f ns per call\n",(b-a)/N*1e9);
 a=now();for(long i=0;i<N;i++){sink+=__rdtsc();}b=now();
 printf("rdtsc directly          : %6.1f ns per call\n",(b-a)/N*1e9);return 0;}
