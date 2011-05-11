#include <erl_nif.h>
#include <ketama.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

static ketama_continuum c;

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info)
{
    const ERL_NIF_TERM* tuple;

    int arity;
    int version;
    int size;
    int ret = 0;

    if (!enif_get_tuple(env, load_info, &arity, &tuple) ||
        !enif_get_int(env, tuple[0], &version) ||
        !enif_get_int(env, tuple[1], &size))
    {
        ret = 1981;        
    }

    size += 1;

    char buffer[size];

    if (!enif_get_string(env, tuple[2], buffer, size, ERL_NIF_LATIN1) ||
        !ketama_roll(&c, buffer) ||
        !c)
    {
        ret= 1981;
    }

    return ret;
}

static ERL_NIF_TERM getserver(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int size;
    enif_get_int(env, argv[0], &size);

    size += 1;

    unsigned char key[size];
    enif_get_string(env, argv[1], key, size, ERL_NIF_LATIN1);

    unsigned char buffer[256];
    mcs *m;
    m = ketama_get_server( (char *) &buffer, c);
    sprintf((char *) &buffer, "%s", m->ip);

    ErlNifBinary b = {sizeof(unsigned char) * strlen(buffer), buffer}; 

    return enif_make_binary(env, &b);
}

static ErlNifFunc nif_funcs[] =
{
    {"getserver", 2, getserver}
};

ERL_NIF_INIT(ketama, nif_funcs, load, NULL, NULL, NULL)
