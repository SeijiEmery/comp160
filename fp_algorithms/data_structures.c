
typedef struct {
    uint16_t capacity;
    uint16_t length;
    void[]   data;
} array_t;

// eax size => edi ptr
void* array_alloc (size_t size) {
    assert(size > 4);
    void* array = malloc(size);

    // Set capacity, length
    ((uint16_t*)array)[0]  = size - 4;
    ((uint16_t*)length)[1] = 0;

    // Return pointer offset to start of data.
    // Length / capacity obtained via negative offsets.
    return (void*)((uint32_t*)array + 1);
}
void* array_dealloc (void* array) {
    // flag freed by setting capacity, length to 0. (invalid value otherwise -- capacity not allowed to be 0)
    if (((uint32_t*)array)[-1] != 0) {
        ((uint32_t*)array)[-1] = 0;
        free(array - 4);
    }
}

//                  edi          ebx            esi        ecx
void* array_memcpy (void* array, size_t offset, void* src, size_t length) {
    // ...
}


//                    edi          ebx            edx            ecx
void array_memset8   (void* array, size_t offset, uint8_t value, size_t count);

//                    edi          ebx            edx             ecx
void* array_memset32 (void* array, size_t offset, uint32_t value, size_t count);































