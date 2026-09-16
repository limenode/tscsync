#define _GNU_SOURCE
#include <stdio.h>
#include <sched.h>
#include <time.h>
#include <unistd.h>
/* Read CLOCK_MONOTONIC (the kernel clock every app uses) pinned to each CPU, back to back. */
static double mono(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}
int main(){
  int n=sysconf(_SC_NPROCESSORS_ONLN); double base=-1;
  printf("%4s %18s\n","cpu","MONOTONIC - cpu1 (s)");
  for(int pass=0;pass<2;pass++) for(int c=0;c<n;c++){
    cpu_set_t s; CPU_ZERO(&s); CPU_SET(c,&s); sched_setaffinity(0,sizeof s,&s); sched_yield();
    double m=mono(); if(base<0&&c==1) base=m;
    if(base>=0) printf("%4d %18.6f%s\n",c,m-base, (m-base<-1||m-base>1)?"   <-- wrong clock":"");
  }
  return 0;
}
