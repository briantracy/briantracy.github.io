


dlopen(NULL) returns handle for current process

dladdr() returns the sumbol name of an address


JSON parser in C

```
union json_value {
    int type;
    union json_data {
        double number;
        const char *string;
        int bool;
        struct {
            const char *key;
            union json_value *value;
        } *dict;
    } data;

```


Re-implement tar (tape archive) with random access

```
struct btar_file_metadata {
	char name[256];
	uint64_t perm;
	uint64_t archive_offset;
}
struct btar_archive_header {
	unsigned char magic[8];
	uint64_t creation_date;
}
```
