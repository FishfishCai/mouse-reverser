#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>

typedef struct __IOHIDEvent * IOHIDEventRef;
extern IOHIDEventRef CGEventCopyIOHIDEvent(CGEventRef);
extern double IOHIDEventGetFloatValue(IOHIDEventRef, uint32_t);
extern void IOHIDEventSetFloatValue(IOHIDEventRef, uint32_t, double);

static const uint32_t kFieldScrollX = (6u << 16) | 0u;
static const uint32_t kFieldScrollY = (6u << 16) | 1u;

void reverse_iohid_scroll(CGEventRef event) {
    IOHIDEventRef hid = CGEventCopyIOHIDEvent(event);
    if (!hid) return;
    double y = IOHIDEventGetFloatValue(hid, kFieldScrollY);
    double x = IOHIDEventGetFloatValue(hid, kFieldScrollX);
    IOHIDEventSetFloatValue(hid, kFieldScrollY, -y);
    IOHIDEventSetFloatValue(hid, kFieldScrollX, -x);
    CFRelease(hid);
}
