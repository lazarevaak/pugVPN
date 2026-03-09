#include <TargetConditionals.h>

#if TARGET_OS_SIMULATOR
void darwin_arm_init_thread_exception_port(void) {}
void darwin_arm_init_mach_exception_handler(void) {}
#endif
