structs
=======

Cross-target structs implementation for haxe. Will take care of stack-allocated classes, and also will take benefit from each platform fastest way to deal with the memory layout of Array of structs.

Its primary goal is to provide a common interface to use each platforms' fastest way to deal with hardware graphics. On Flash (Molehill), it is made using flash.Memory API; On js, using TypedArray, for example
