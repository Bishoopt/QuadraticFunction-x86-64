#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "x86_function.h" 
int main(int argc, char ** argv)
{
	if(argc!=4)
	{
		printf("Using a, b, c ax^2+bx+c\n");
		return -1;
	}
    bool quit = false;
    SDL_Event event;
	int width=800;
	int height=600;
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window * window = SDL_CreateWindow("Quadratic Function",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);

    SDL_Renderer * renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Texture * texture = SDL_CreateTexture(renderer,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STATIC, width, height);

	unsigned long* pPixelBuffer=(unsigned long*)calloc(width*height,sizeof(unsigned long));
	float s=0.5f;
    float A=atof(argv[1]),B=atof(argv[2]),C=atof(argv[3]);
	x86_function((unsigned char*)pPixelBuffer,width,height,A,B,C,s);
	while (!quit)
    {
        SDL_UpdateTexture(texture, NULL, pPixelBuffer, width * sizeof(Uint32));
        SDL_WaitEvent(&event);

        switch (event.type)
        {
	case SDL_KEYDOWN:
               switch( event.key.keysym.sym ){
                    case SDLK_UP:
                        s+=0.025f;
                        memset(pPixelBuffer,0,width*height*sizeof(unsigned long));
						x86_function((unsigned char*)pPixelBuffer,width,height,A,B,C,s);
						break;
                    case SDLK_DOWN:
                        s-=0.025f;
						if(s<=0.1f)
							s=0.1f;
						memset(pPixelBuffer,0,width*height*sizeof(unsigned long));
						x86_function((unsigned char*)pPixelBuffer,width,height,A,B,C,s);
                        break;
                    default:
                        break;
                }
			break;
       case SDL_QUIT:
            quit = true;
            break;
        }

        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
