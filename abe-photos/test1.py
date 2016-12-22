from waters15 import cMA_ABE, cMA_CPABE, get_subimage
import json
import timeit

number_executions = 100
atts = 128

def wrapper(func, *args, **kwargs):
    def wrapped():
        return func(*args, **kwargs)
    return wrapped


def init():
    test = cMA_CPABE('conf.json')
    test.new_authority()
    test.new_user()
    test.dump_conf()

def encrypt(cont):
    global_conf_file = "global_conf.json"
    
    with open(global_conf_file) as outfile:
        global_conf = json.load(outfile)
    
    operation = global_conf['operation']
    
    test = cMA_ABE('conf.json')
        
    subimage = get_subimage(global_conf['image']['path'], global_conf['image']['encrypted_area'])
    
    policy_str = test.conf_file['users'][1]['access_policy']
    
    msg = subimage.tobytes()

    ct = test.encrypt(msg, policy_str)
    test.dump_ct(global_conf['ct']+str(cont), test.deepcopy(ct))
    
    wrapped = wrapper(test.encrypt, msg, policy_str)
    return timeit.timeit(wrapped, number=number_executions)
    


def decrypt(cont):
    global_conf = "global_conf.json"
    with open(global_conf) as outfile:
        global_conf = json.load(outfile)
    
    test = cMA_ABE('conf.json')
    ct = test.load_ct(global_conf['ct']+str(cont))

    wrapped = wrapper(test.decrypt, ct, test.user_attrs['gid1'])
    return timeit.timeit(wrapped, number=number_executions)
    
    # decrypted_message = test.decrypt(ct, test.user_attrs['gid4'])
    # print 'Decrypted CT: %s' % decrypted_message
    # print 'FIN DECRYPTING'

def get_latex_figure(data,xtick,ylabel,rotate,xlabels,extraplots=''):
    from string import Template
    
    latex = Template ('''\\begin{tikzpicture}
        \\begin{axis}
            [scale=0.7,
            ylabel=$ylab,
            y label style={at={(axis description cs:0.1,0.5)}},
            xtick=data,
            xticklabels=$xticklabels,
            xlabel=$xlab,
            xticklabel style={rotate=$rotat},
            ]
            \\addplot+[sharp plot] coordinates{
$coordinates
            };
            $extraplot
        \\end{axis}
    \\end{tikzpicture}
    ''')
    return latex.substitute(coordinates=data,xticklabels=xtick,ylab=ylabel,rotat=rotate,xlab=xlabels,C_T='$C_T$',extraplot=extraplots)

def original_test():
    list = []
    
    for cont in range(1, atts):
        list.append('ATT%s' % cont)
        
        with open('conf.json') as outfile:
            conf = json.load(outfile)
        conf['authorities'][0]['attributes'] = list
        
        # if len(list)<4:
        new_list = [s + '@GBG' for s in list]
        policy = ' AND '.join(new_list)
        
        conf['users'][1]['access_policy'] = policy
        conf['users'][0]['attributes'][0]['atts'] = list
        
        with open('conf.json', 'w') as outfile:
            json.dump(conf, outfile, sort_keys=True, indent=4)
        
        init()
        
        print 'Tiempo en encrypt con %s attributes: %s' % (cont, encrypt(cont))
        print 'Tiempo en decrypt con %s attributes: %s' % (cont, decrypt(cont))

def test_sizeCT():
    '''
        Test que coge una imagen de 800x574 y general el codigo de latex para la imagen.
        El test
    '''
    import os
    
    list = []
    lista_size={}
    
    for cont in range(1, atts):
        list.append('ATT%s' % cont)
        
        with open('conf.json') as outfile:
            conf = json.load(outfile)
        conf['authorities'][0]['attributes'] = list
        
        new_list = [s + '@GBG' for s in list]
        policy = ' AND '.join(new_list)
        
        conf['users'][1]['access_policy'] = policy
        conf['users'][0]['attributes'][0]['atts'] = list
        
        with open('conf.json', 'w') as outfile:
            json.dump(conf, outfile, sort_keys=True, indent=4)
        
        init()
        
        print 'Tiempo en encrypt con %s attributes: %s' % (cont, encrypt(cont))
        lista_size[cont] = os.path.getsize('data/ct.json%s' %cont)/1000000.0

    data = ''
    for elem in lista_size.items():
        data = data + '\t\t\t\t %s \n' % str(elem)
    xticklabels = ', '.join(str(x+1) for x in range(cont))
    xticklabels = '{'+xticklabels+'}'
    ylabel = 'Mb of the $C_T$'
    xlabel = 'Number of Attributes'
    rotate = 0
    return get_latex_figure(data, xticklabels,ylabel,rotate,xlabel)

def test_time_Encrypt_Decrypt():
    '''
        Test que coge una imagen de 800x574 y general el codigo de latex para la imagen.
        El test calcula el tiempo en cifrar la imagen entera en funcion del numero de atributos
        en el universo.
        
        El numero de atributos en la policy es fijo == 3
    '''

    lista_aux = {}
    lista_aux2 = {}
    
    for cont in range(3, atts):
        list = []
        
        for aux in range(cont):
            list.append('ATT%s' % aux)
        
        with open('conf.json') as outfile:
            conf = json.load(outfile)
        conf['authorities'][0]['attributes'] = list

        if len(list)<4:
            new_list = [s + '@GBG' for s in list]
            policy = ' AND '.join(new_list)
        
        conf['users'][1]['access_policy'] = policy
        conf['users'][0]['attributes'][0]['atts'] = list
        
        with open('conf.json', 'w') as outfile:
            json.dump(conf, outfile, sort_keys=True, indent=4)
        
        init()
        
        tiempo = encrypt(cont)
        tiempo2 = decrypt(cont)
        # print 'Tiempo en encrypt con %s attributes: %s' % (cont, tiempo)
        lista_aux[cont] = tiempo
        lista_aux2[cont] = tiempo2
        
    
    data = ''
    for elem in lista_aux.items():
        data = data + '\t\t\t\t %s \n' % str(elem)
    xticklabels = ', '.join(str(x + 1) for x in range(cont))
    xticklabels = '{' + xticklabels + '}'
    ylabel = 'Time (s)'
    xlabel = 'Number of Attributes in $\mathcal{U}$, legend style={at={(0.5,1.20)},anchor=north,legend columns=-1}'
    rotate = 0
    
    data2 = ''
    for elem in lista_aux2.items():
        data2 = data2 + '\t\t\t\t %s \n' % str(elem)
    from string import Template
    extraplots=Template('''\\addlegendentry{encryption}
            \\addplot+[sharp plot] coordinates{
$coor
            };
            \\addlegendentry{decryption}''')
    extraplots = extraplots.safe_substitute(coor=data2)
    return get_latex_figure(data, xticklabels, ylabel, rotate, xlabel,extraplots=extraplots)

def test_time_Encrypt_Decrypt_policy():
    '''
        Test que coge una imagen de 800x574 y general el codigo de latex para la imagen.
        El test calcula el tiempo en cifrar/descifrar la imagen entera en funcion del numero de atributos
        en la politica.
    '''
    import os

    lista_aux = {}
    lista_aux2 = {}

    for cont in range(1, atts):
        list = []
    
        for aux in range(cont):
            list.append('ATT%s' % aux)
    
        with open('conf.json') as outfile:
            conf = json.load(outfile)
        # conf['authorities'][0]['attributes'] = list
    
        
        new_list = [s + '@GBG' for s in list]
        policy = ' AND '.join(new_list)
    
        conf['users'][1]['access_policy'] = policy
        conf['users'][0]['attributes'][0]['atts'] = list
    
        with open('conf.json', 'w') as outfile:
            json.dump(conf, outfile, sort_keys=True, indent=4)
    
        init()
    
        tiempo = encrypt(cont)
        tiempo2 = decrypt(cont)
        # print 'Tiempo en encrypt con %s attributes: %s' % (cont, tiempo)
        lista_aux[cont] = tiempo
        lista_aux2[cont] = tiempo2

    data = ''
    for elem in lista_aux.items():
        data = data + '\t\t\t\t %s \n' % str(elem)
    xticklabels = ', '.join(str(x + 1) for x in range(cont))
    xticklabels = '{' + xticklabels + '}'
    ylabel = 'Time (s)'
    xlabel = 'Number of Attributes in $\mathcal{T}$, legend style={at={(0.5,1.20)},anchor=north,legend columns=-1}'
    rotate = 0

    data2 = ''
    for elem in lista_aux2.items():
        data2 = data2 + '\t\t\t\t %s \n' % str(elem)
    from string import Template
    extraplots = Template('''\\addlegendentry{encryption}
            \\addplot+[sharp plot] coordinates{
$coor
            };
            \\addlegendentry{decryption}''')
    extraplots = extraplots.safe_substitute(coor=data2)
    return get_latex_figure(data, xticklabels, ylabel, rotate, xlabel, extraplots=extraplots)

latex1 = test_sizeCT()
target = open('experiment1.txt', 'w')
target.write(latex1)

latex2 = test_time_Encrypt_Decrypt()
target = open('experiment2.txt', 'w')
target.write(latex2)

latex3 = test_time_Encrypt_Decrypt_policy()
target = open('experiment3.txt', 'w')
target.write(latex3)