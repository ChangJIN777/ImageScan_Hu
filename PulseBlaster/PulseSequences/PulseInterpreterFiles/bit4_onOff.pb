// Sample program for SpinCore PulseBlaster Interpreter.
// Simple all on all off pattern.

start: 0b1110 0000 0000 0000 0000 1000, 200 us // All bits on for 500 ms, Continue to next instruction
       0b1110 0000 0000 0000 0000 0000, 200 us, branch, start // All bits off for 500 ms, branch to label