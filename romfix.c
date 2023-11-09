#include <stdio.h>
#include <string.h>
#include <errno.h>

int main(int argc, char **argv)
{
	int i, c;
	unsigned char sum, fix;
	FILE *fp;

	if(!argv[1]) {
		fprintf(stderr, "no rom file specified\n");
		return 1;
	}

	if(!(fp = fopen(argv[1], "r+b"))) {
		fprintf(stderr, "failed to open %s: %s\n", argv[1], strerror(errno));
		return 1;
	}

	i = 0;
	sum = 0;
	while((c = fgetc(fp)) != -1) {
		if(i++ >= 512) break;
		sum += (unsigned char)c;
	}
	fix = ~sum + 1;

	printf("%02x+%02x\n", (unsigned int)sum, (unsigned int)fix);
	fseek(fp, 512, SEEK_SET);
	fputc(fix, fp);

	fseek(fp, 8191, SEEK_SET);
	fputc(0, fp);

	fclose(fp);
	return 0;
}
