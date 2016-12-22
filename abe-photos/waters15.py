from charm.toolbox.pairinggroup import PairingGroup, GT, G1, G2, ZR
# from charm.schemes.dabe_aw11 import Dabe
from charm.schemes.abenc.abenc_maabe_rw15 import MaabeRW15 as Dabe
from HybridABE15 import HybridABEncMA as HybridABEnc

import numpy as np
import matplotlib.pyplot as plt
import json
from scipy.misc import imsave
import matplotlib.image as mpimg
import os

debug = False
os.chdir('abe-photos') # Update current directory to ABE's script

def merge_dicts(*dict_args):
    """
    Given any number of dicts, shallow copy and merge into a new dict,
    precedence goes to key value pairs in latter dicts.
    """
    result = {}
    for dictionary in dict_args:
        result.update(dictionary)
    return result


class cMA_CPABE(object):
    def __init__(self, conf_file):

        with open(conf_file) as outfile:
            self.conf_file = json.load(outfile)

        group = PairingGroup("SS512")
        self.group = group
        dpabe = Dabe(group)
        self.hyb_abe = HybridABEnc(dpabe, group)

        self.GP = self.hyb_abe.setup()
        if debug: print self.GP

    def get_auth_atts(self):
        lista_final = {}
        for elem in self.conf_file["authorities"]:
            lista_atts = []
            for att in elem['attributes']:
                lista_atts.append(att + '@' + elem['location'])
            lista_final[elem['location']] = lista_atts

        return lista_final

    def get_user_atts(self):
        lista_final = {}
        for elem in self.conf_file["users"]:
            lista_atts = []
            for location in elem['attributes']:
                for att in location['atts']:
                    lista_atts.append(att + '@' + location['location'])
            lista_final[elem['gid']] = lista_atts

        return lista_final

    def new_authority(self):
        # (public_key1, secret_key1) = maabe.authsetup(public_parameters, 'UT')

        auth_attrs = self.get_auth_atts()
        self.allAuthkeys = {}
        for elem in auth_attrs.keys():
            (PK, SK) = self.hyb_abe.authsetup(self.GP, elem)
            self.allAuthkeys[elem] = {'PK': PK, 'SK': SK}

    def new_user(self):
        self.user_attrs = self.get_user_atts()
        for user_gid in self.user_attrs.keys():
            K = {}
            final_key = {}
            for att in self.user_attrs[user_gid]:
                location = att.split('@')[1]
                user_keys1 = self.hyb_abe.keygen(self.GP, self.allAuthkeys[location]['SK'], user_gid, att)
                final_key[att] = user_keys1
            user_keys = {'GID': user_gid, 'keys': final_key}
            self.user_attrs[user_gid] = user_keys

    def dump_conf(self):
        self.dump_key('data/GP.json', self.deepcopy(self.GP), 'GP')
        for auth in self.allAuthkeys.keys():
            self.dump_key('data/auth_%s.json' % auth, self.deepcopy(self.allAuthkeys[auth]), 'auth')
        for user in self.user_attrs.keys():
            self.dump_key('data/user_%s.json' % user, self.deepcopy(self.user_attrs[user]), 'user')

    def deepcopy(self, obj):
        if isinstance(obj, dict):
            return {self.deepcopy(key): self.deepcopy(value) for key, value in obj.items()}
        if hasattr(obj, '__iter__'):
            return type(obj)(self.deepcopy(item) for item in obj)
        return obj

    def dump_key(self, filename, original_key, name=''):

        key = original_key.copy()

        if 'user' in name:
            # Users
            if 'keys' in key.keys():
                for att in key['keys'].keys():
                    if 'K' in key['keys'][att].keys():
                        key['keys'][att]['K'] = self.group.serialize(key['keys'][att]['K'])
                    if 'KP' in key['keys'][att].keys():
                        key['keys'][att]['KP'] = self.group.serialize(key['keys'][att]['KP'])

        if 'GP' in name:
            # For the GP
            import dill
            import pickle
            if 'g1' in key.keys():
                key['g1'] = self.group.serialize(key['g1'])
            if 'g2' in key.keys():
                key['g2'] = self.group.serialize(key['g2'])
            if 'egg' in key.keys():
                key['egg'] = self.group.serialize(key['egg'])
            if 'H' in key.keys():
                # key['H'] = pickle.dumps(key['H'])
                del(key['H'])
            if 'F' in key.keys():
                # key['F'] = pickle.dumps(key['F'])
                del (key['F'])

        if 'auth' in name:
            # For the Authorities
            if 'PK' in key.keys():
                if 'egga' in key['PK'].keys():
                    key['PK']['egga'] = self.group.serialize(key['PK']['egga'])
                if 'gy' in key['PK'].keys():
                    key['PK']['gy'] = self.group.serialize(key['PK']['gy'])
            if 'SK' in key.keys():
                if 'alpha' in key['SK'].keys():
                    key['SK']['alpha'] = self.group.serialize(key['SK']['alpha'])
                if 'y' in key['SK'].keys():
                    key['SK']['y'] = self.group.serialize(key['SK']['y'])

        if 'ct' in name:
            for c_x in key.keys():
                if 'c1' in c_x:
                    for C_x in key['c1'].keys():
                        if isinstance(key['c1'][C_x],dict):
                            pass
                        else:
                            key['c1'][C_x] = self.group.serialize(key['c1'][C_x])

        with open(filename, 'w') as outfile:
            json.dump(key, outfile, sort_keys=True, indent=4)
            # json.dump(key, outfile, sort_keys=True, indent=4)

        # H = pickle.loads(key['H'])

        return key

    def encrypt(self, m, policy):
        # m = groupObj.random(GT)
        # policy = '((one or three) and (TWO or FOUR))'
        if debug: print('Acces Policy: %s' % policy)
        # CT = self.hyb_abe.encrypt(PK, self.GP, m, policy)
        PK = {}
        for location in self.allAuthkeys.keys():
            PK[location.upper()] = self.allAuthkeys[location]['PK']
        CT = self.hyb_abe.encrypt(PK, self.GP, m, policy)
        if debug: print("\nCiphertext...")
        if debug: self.group.debug(CT)

        return CT

    def decrypt(self, CT, K):
        decrypted_message = self.hyb_abe.decrypt(self.GP, K, CT)
        return decrypted_message


class cMA_ABE(object):
    def __init__(self, conf_file):
        with open(conf_file) as outfile:
            self.conf_file = json.load(outfile)

        group = PairingGroup("SS512")
        self.group = group
        dpabe = Dabe(group)
        self.hyb_abe = HybridABEnc(dpabe, group)

        self.load_conf()

        if debug: print self.GP

    def deepcopy(self, obj):
        if isinstance(obj, dict):
            return {self.deepcopy(key): self.deepcopy(value) for key, value in obj.items()}
        if hasattr(obj, '__iter__'):
            return type(obj)(self.deepcopy(item) for item in obj)
        return obj

    def dump_ct(self, filename, original_key):

        key = original_key.copy()

        for c_x in key.keys():
            if 'c1' in c_x:
                for C_x in key['c1'].keys():
                    if isinstance(key['c1'][C_x], dict):
                        for att in key['c1'][C_x].keys():
                            key['c1'][C_x][att] = self.group.serialize(key['c1'][C_x][att])
                    elif isinstance(key['c1'][C_x], unicode):
                        pass
                    else:
                        key['c1'][C_x] = self.group.serialize(key['c1'][C_x])

        with open(filename, 'w') as outfile:
            json.dump(key, outfile, sort_keys=True, indent=4)
            # json.dump(key, outfile, sort_keys=True, indent=4)

        return key

    def load_conf(self):
        self.allAuthkeys = {}
        self.user_attrs = {}
        self.GP = {}

        self.load_key(self.conf_file['GP'], 'GP')
        for path in self.conf_file['authorities']:
            self.load_key(path['path'], 'auth')
        for user in self.conf_file['users']:
            self.load_key('data/user_%s.json' % user['gid'], 'user')

    def load_key(self, path, name):
        with open(path) as outfile:
            filename = json.load(outfile)

        if 'GP' in name:
            self.GP = self.hyb_abe.setup()

            if 'g1' in filename.keys():
                self.GP['g1'] = self.group.deserialize(str(filename['g1']))
            if 'g2' in filename.keys():
                self.GP['g2'] = self.group.deserialize(str(filename['g2']))
            if 'egg' in filename.keys():
                self.GP['egg'] = self.group.deserialize(str(filename['egg']))

        if 'auth' in name:
            location = path.split('.')[0].split('_')[1]
            self.allAuthkeys[location] = {'PK': {}, 'SK': {}}
            for key in filename['PK'].keys():
                if key in ['egga','gy']:
                    self.allAuthkeys[location]['PK'][key] = self.group.deserialize(str(filename['PK'][key]))
                else:
                    self.allAuthkeys[location]['PK'][key] = (filename['PK'][key])
            for key in filename['SK'].keys():
                if key in ['alpha','y']:
                    self.allAuthkeys[location]['SK'][key] = self.group.deserialize(str(filename['SK'][key]))
                else:
                    self.allAuthkeys[location]['SK'][key] = (filename['SK'][key])
            # self.allAuthkeys['PK'].update(self.allAuthkeys[location]['PK']);

        if 'user' in name:
            gid = path.split('.')[0].split('_')[1]
            self.user_attrs[gid] = {'keys': {}, 'GID': {}}
            for key in filename.keys():
                if 'keys' in key:
                    for att in filename[key].keys():
                        self.user_attrs[gid]['keys'][att] = {'K':0,'KP':0}
                        self.user_attrs[gid]['keys'][att]['K'] = self.group.deserialize(str(filename['keys'][att]['K']))
                        self.user_attrs[gid]['keys'][att]['KP'] = self.group.deserialize(str(filename['keys'][att]['KP']))
                else:
                    self.user_attrs[gid]['GID'] = filename['GID']

    def encrypt(self, m, policy):
        # m = groupObj.random(GT)
        # policy = '((one or three) and (TWO or FOUR))'
        if debug: print('Acces Policy: %s' % policy)
        # CT = self.hyb_abe.encrypt(PK, self.GP, m, policy)
        PK = {}
        for location in self.allAuthkeys.keys():
            PK[location.upper()] = self.allAuthkeys[location]['PK']
        CT = self.hyb_abe.encrypt(PK, self.GP, m, policy)
        if debug: print("\nCiphertext...")
        if debug: self.group.debug(CT)

        return CT

    def decrypt(self, CT, K):
        decrypted_message = self.hyb_abe.decrypt(self.GP, K, CT)
        return decrypted_message

    def load_ct(self, path):
        with open(path) as outfile:
            filename = json.load(outfile)

        for c_x in filename.keys():
            if 'c1' in c_x:
                for C_x in filename['c1'].keys():
                    if isinstance(filename['c1'][C_x], dict):
                        for att in filename['c1'][C_x].keys():
                            filename['c1'][C_x][att] = self.group.deserialize(str(filename['c1'][C_x][att]))
                    elif 'policy' in C_x:
                        pass
                    else:
                        filename['c1'][C_x] = self.group.deserialize(str(filename['c1'][C_x]))
        return filename

def get_image():
    image = open('img.jpg').read().encode('base64')

    print image


def get_subimage(filename, indices, image_encrypted):
    img = mpimg.imread(filename)
    subimage = img[indices[0]:indices[1], indices[2]:indices[3]].copy()
    img[indices[0]:indices[1], indices[2]:indices[3]] = [0,0,0]
    imsave(image_encrypted, img)

    return subimage.ravel()

def reconstruir_imagen(decrypted_image, indices, image_encrypted, decrypted_path):
    img = mpimg.imread(image_encrypted)
    img[indices[0]:indices[1], indices[2]:indices[3]] = decrypted_message
    imsave(decrypted_path, img)

def is_not_encrypted(filename, indices):
    img = mpimg.imread(filename)
    subimage = img[indices[0]:indices[1], indices[2]:indices[3]].copy()
    count = 0
    for elem in subimage:
        for elem2 in elem:
            count += 1 if (elem2==np.array([0,0,0])).all() else 0
    print count
    final = False if count else True
    # return final
    return True

if __name__ == "__main__":
    debug = True
    global_conf_file = "global_conf.json"

    with open(global_conf_file) as outfile:
        global_conf = json.load(outfile)

    operation = global_conf['operation']

    if "init" in operation:
        test = cMA_CPABE('conf.json')
        test.new_authority()
        test.new_user()

        print 'FIN CONFIGURACION'

        test.dump_conf()
        print 'FIN DUMP'
    elif "encrypt" in operation:
        test = cMA_ABE('conf.json')

        print 'FIN LOAD FILES'
        if is_not_encrypted(global_conf['image']['path'],global_conf['image']['encrypted_area']):
            subimage = get_subimage(global_conf['image']['path'],global_conf['image']['encrypted_area'],global_conf['image']['encrypted_image'])
            print b'%s' %subimage

            policy_str = test.conf_file['users'][1]['access_policy']
            msg = subimage.tobytes()

            print 'ENCRYPTING'
            ct = test.encrypt(msg, policy_str)
            if debug:
                print("Ciphertext")
                print("c1 =>", ct['c1'])
                print("c2 =>", ct['c2'])
            print 'FIN ENCRYPTING'
            test.dump_ct(global_conf['image']['ct'], test.deepcopy(ct))
        else:
            print "You cannot encrypt an encrypted area!"

    elif "decrypt" in operation:
        test = cMA_ABE('conf.json')
        ct = test.load_ct(global_conf['image']['ct'])
        print 'FIN LOAD FILES'

        print 'DECRYPTING'
        decrypted_message = test.decrypt(ct, test.user_attrs[global_conf['user_decrypt']])
        decrypted_message = np.fromstring(decrypted_message, dtype=np.uint8)
        decrypted_message = np.resize(decrypted_message,
                                      (abs(global_conf['image']['encrypted_area'][0]-global_conf['image']['encrypted_area'][1]),
                                       abs(global_conf['image']['encrypted_area'][2]-global_conf['image']['encrypted_area'][3]),
                                       3)
                                      )
        print 'FIN DECRYPTING'

        reconstruir_imagen(decrypted_message,
                           global_conf['image']['encrypted_area'],
                           global_conf['image']['encrypted_image'],
                           global_conf['image']['decrypted_image'])

    else:
        print "Define operation"
