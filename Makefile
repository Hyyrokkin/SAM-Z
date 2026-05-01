OBJS = reciter.o sam.o render.o debug.o processframes.o createtransitions.o main.o
BUILD = out/


CC = cc

# libsdl present
CFLAGS = -Wall -O2 -DUSESDL `sdl-config --cflags` -DcMain=main
LFLAGS = `sdl-config --libs`

# no libsdl present
#CFLAGS = -Wall -O2 -DcMain=main
#LFLAGS =

main: $(OBJS)
	$(CC) -o sam $(OBJS) $(LFLAGS)

%.o: src/old/%.c
	$(CC) $(CFLAGS) -c $<

package: 
	tar -cvzf sam.tar.gz README.md Makefile sing src/

clean:
	rm -f *.o
	rm -f *.wav
	rm -f sam
