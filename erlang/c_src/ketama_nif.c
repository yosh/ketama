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

static ERL_NIF_TERM c_getserver(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary keybin;

    if (!enif_inspect_binary(env, argv[0], &keybin)) {
        return 1983;
    }

    unsigned char key[keybin.size + 1];
    key[keybin.size] = '\0';
    memcpy(key, keybin.data, keybin.size);
    mcs* m;
    m = ketama_get_server(key, c);
    ErlNifBinary b = {sizeof(unsigned char) * strlen(m->ip), m->ip}; 

    return enif_make_binary(env, &b);
}

static ErlNifFunc nif_funcs[] =
{
    {"c_getserver", 1, c_getserver}
};

ERL_NIF_INIT(ketama, nif_funcs, load, NULL, NULL, NULL)
