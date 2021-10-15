'''
Created on Oct 1, 2021

@author: varikmp
'''

#import os
import glob

cpu_caches = {}
cpu_dirs = glob.glob('/sys/devices/system/cpu/cpu?')
for cpu_dir in cpu_dirs:
    index_dirs = glob.glob('{}/cache/index*'.format(cpu_dir))
    for index_dir in index_dirs:
        # file_paths = glob.glob('{}/*'.format(index_dir))
        # level = 
        file = open("{}/level".format(index_dir), "r")
        cache_level = int(file.readline()[:-1])
        file.close()

        file = open("{}/type".format(index_dir), "r")
        cache_type = str(file.readline()[:-1])
        file.close()
        if cache_type == "Data":
            cache_type = "d"
        elif cache_type == "Instruction":
            cache_type = "i"
        else:
            cache_type = ""
        
        file = open("{}/shared_cpu_map".format(index_dir), "r")
        cache_shared_cpu_map = str(file.readline()[:-1])
        file.close()
        
        file = open("{}/size".format(index_dir), "r")
        cache_size = str(file.readline()[:-1])
        file.close()
        
        cache_key = "L{}{}".format(cache_level, cache_type)
        if cache_key not in cpu_caches.keys():
            cpu_caches[cache_key] = {}
            cache_size_unit = cache_size[len(cache_size)-1]
            if cache_size_unit == "K":
                cache_size = int(cache_size[:-1]) * 1024
            elif cache_size_unit == "M":
                cache_size = int(cache_size[:-1]) * 1024 * 1024
            else:
                cache_size = int(cache_size)
            cpu_caches[cache_key][cache_shared_cpu_map] = cache_size
        else:
            if cache_shared_cpu_map not in cpu_caches[cache_key].keys():
                cache_size_unit = cache_size[len(cache_size)-1]
                if cache_size_unit == "K":
                    cache_size = int(cache_size[:-1]) * 1024
                elif cache_size_unit == "M":
                    cache_size = int(cache_size[:-1]) * 1024 * 1024
                else:
                    cache_size = int(cache_size)
                cpu_caches[cache_key][cache_shared_cpu_map] = cache_size
        #print("{}".format(cache_key))

for cache_key in cpu_caches.keys():
    total_size = 0
    # print(cpu_caches[cache_key].keys())
    for shared_cpu_map in cpu_caches[cache_key].keys():
        total_size += cpu_caches[cache_key][shared_cpu_map]
    # print(total_size)
    cpu_caches[cache_key] = total_size
print(cpu_caches)

# cpu_caches = {}
# cpu_dirs = glob.glob('/sys/devices/system/cpu/cpu?')
# for count, cpu_dir in enumerate(cpu_dirs):
#     cpu = []
#     index_dirs = glob.glob('{}/cache/index*'.format(cpu_dir))
#     for index_dir in index_dirs:
#         index = {}
#         file_paths = glob.glob('{}/*'.format(index_dir))
#         for file_path in file_paths:
#             file_name = os.path.basename(file_path)
#             file = open(file_path, "r")
#             content = str(file.readline())
#             index[file_name] = ""
#             if len(content) != 0:
#                 index[file_name] = content[:-1]
#             file.close()
#         cpu.append(index)
#     cpu_caches["index{}".format(count)] = cpu
# print(cpu_caches)