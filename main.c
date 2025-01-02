// TODO NOTE syntax features of Vimwiki
// heading 1
// heading 2
// heading 3
// heading 4
// heading 5
// heading 6
// minus list
// star list
// minus checkbox
// star checkbox
// link
// link with alias
// code
// table
#include <stdio.h>
#include <string.h>

int retval = 0;

void translate_file(char *path) {
    FILE *file = fopen(path, "r");
    if (!file) {
        fprintf(stderr, "wiki2md: %s: No such file or directory\n", path);
        retval = 1;
        return;
    }
    const size_t path_len = strlen(path);
    if (strcmp(&path[path_len - 5], ".wiki") != 0) {
        fprintf(stderr, "wiki2md: %s is not a Vimwiki file\n", path);
        retval = 1;
        return;
    }

    char target_path[path_len - 1];
    strcpy(target_path, path);
    strcpy(&target_path[path_len - 5], ".md");

    FILE *target = fopen(target_path, "a");
    if (!target) {
        fprintf(stderr, "wiki2md: Could not create %s\n", target_path);
        retval = 1;
        return;
    }
    printf("Created %s\n", target_path);

    char c;
    while ((c = fgetc(file)) != EOF) {
        // TODO END batch these syscalls
        putchar(c);

        // TODO NOW
    }

    fclose(file);
}

int main(int argc, char **argv) {
    if (argc == 1) {
        printf("wiki2md – Vimwiki to Markdown translator\n\n"
               "Usage: wiki2md <source files>\n");
        return 1;
    }

    for (int i = 1; i < argc; ++i) translate_file(argv[i]);
    return retval;
}
