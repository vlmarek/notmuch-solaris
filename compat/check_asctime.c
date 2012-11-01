/*
 * This compatibility check actually succeeds (on Solaris) if
 * _POSIX_PTHREAD_SEMANTICS is not defined.  But we need to #define that to get
 * the right version of getpwuid_r(), so we define it here to ensure that the
 * compatibility check ends up doing the same thing as the rest of the code.
 */
#define	_POSIX_PTHREAD_SEMANTICS 1
#include <time.h>
#include <stdio.h>

int main()
{
    struct tm tm;

    (void) asctime_r (&tm, NULL, 0);

    return (0);
}
