#!/usr/bin/env python3
import json
import sys,os
import itertools
import functools
import operator
import difflib
import math

import config.instantiation_file as instantiation_file
import config.modules as modules
import config.makefile as makefile

# Read the config file
def parse_file(fname):
    with open(fname) as rfp:
        return json.load(rfp)

def chain(*dicts):
    def merge_dicts(x,y):
        merges = dict(merge_dicts(v, y[k]) for k,v in x.items() if isinstance(v, dict) and isinstance(y.get(k), dict))
        return { **y, **x, **merges }

    return functools.reduce(merge_dicts, dicts)

constants_header_name = 'inc/champsim_constants.h'
instantiation_file_name = 'src/core_inst.cc'
core_modules_file_name = 'inc/ooo_cpu_modules.inc'
cache_modules_file_name = 'inc/cache_modules.inc'

generated_warning = '/***\n * THIS FILE IS AUTOMATICALLY GENERATED\n * Do not edit this file. It will be overwritten when the configure script is run.\n ***/\n\n'

def write_if_different(fname, new_file_string):
    ratio = 0
    if os.path.exists(fname):
        with open(fname, 'rt') as rfp:
            f = list(l.strip() for l in rfp)
        new_file_lines = list(l.strip() for l in new_file_string.splitlines())
        ratio = difflib.SequenceMatcher(a=f, b=new_file_lines).ratio()

    if ratio < 1:
        with open(fname, 'wt') as wfp:
            wfp.write(new_file_string)

###
# Begin default core model definition
###

default_root = { 'block_size': 64, 'page_size': 4096, 'heartbeat_frequency': 10000000, 'num_cores': 1, 'DIB': {}, 'PTW': {}, 'L1I': {}, 'L1D': {}, 'L2C': {}, 'ITLB': {}, 'DTLB': {}, 'STLB': {}, 'LLC': {}, 'physical_memory': {}, 'virtual_memory': {}}

# Read the config file
if len(sys.argv) >= 2:
    config_file = chain(*map(parse_file, reversed(sys.argv[1:])), default_root)
else:
    print("No configuration specified. Building default ChampSim with no prefetching.")
    config_file = default_root

default_core = { 'frequency' : 4000, 'ifetch_buffer_size': 64, 'decode_buffer_size': 32, 'dispatch_buffer_size': 32, 'rob_size': 352, 'lq_size': 128, 'sq_size': 72, 'fetch_width' : 6, 'decode_width' : 6, 'dispatch_width' : 6, 'execute_width' : 4, 'lq_width' : 2, 'sq_width' : 2, 'retire_width' : 5, 'mispredict_penalty' : 1, 'scheduler_size' : 128, 'decode_latency' : 1, 'dispatch_latency' : 1, 'schedule_latency' : 0, 'execute_latency' : 0, 'branch_predictor': 'bimodal', 'btb': 'basic_btb' }
default_dib  = { 'window_size': 16,'sets': 32, 'ways': 8 }
default_l1i  = { 'sets': 64, 'ways': 8, 'rq_size': 64, 'wq_size': 64, 'pq_size': 32, 'mshr_size': 8, 'latency': 4, 'fill_latency': 1, 'max_read': 2, 'max_write': 2, 'prefetch_as_load': False, 'virtual_prefetch': True, 'wq_check_full_addr': True, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no_instr', 'replacement': 'lru'}
default_l1d  = { 'sets': 64, 'ways': 12, 'rq_size': 64, 'wq_size': 64, 'pq_size': 8, 'mshr_size': 16, 'latency': 5, 'fill_latency': 1, 'max_read': 2, 'max_write': 2, 'prefetch_as_load': False, 'virtual_prefetch': False, 'wq_check_full_addr': True, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru'}
default_l2c  = { 'sets': 1024, 'ways': 8, 'rq_size': 32, 'wq_size': 32, 'pq_size': 16, 'mshr_size': 32, 'latency': 10, 'fill_latency': 1, 'max_read': 1, 'max_write': 1, 'prefetch_as_load': False, 'virtual_prefetch': False, 'wq_check_full_addr': False, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru'}
default_itlb = { 'sets': 16, 'ways': 4, 'rq_size': 16, 'wq_size': 16, 'pq_size': 0, 'mshr_size': 8, 'latency': 1, 'fill_latency': 1, 'max_read': 2, 'max_write': 2, 'prefetch_as_load': False, 'virtual_prefetch': True, 'wq_check_full_addr': True, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru'}
default_dtlb = { 'sets': 16, 'ways': 4, 'rq_size': 16, 'wq_size': 16, 'pq_size': 0, 'mshr_size': 8, 'latency': 1, 'fill_latency': 1, 'max_read': 2, 'max_write': 2, 'prefetch_as_load': False, 'virtual_prefetch': False, 'wq_check_full_addr': True, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru'}
default_stlb = { 'sets': 128, 'ways': 12, 'rq_size': 32, 'wq_size': 32, 'pq_size': 0, 'mshr_size': 16, 'latency': 8, 'fill_latency': 1, 'max_read': 1, 'max_write': 1, 'prefetch_as_load': False, 'virtual_prefetch': False, 'wq_check_full_addr': False, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru'}
default_llc  = { 'sets': 2048*config_file['num_cores'], 'ways': 16, 'rq_size': 32*config_file['num_cores'], 'wq_size': 32*config_file['num_cores'], 'pq_size': 32*config_file['num_cores'], 'mshr_size': 64*config_file['num_cores'], 'latency': 20, 'fill_latency': 1, 'max_read': config_file['num_cores'], 'max_write': config_file['num_cores'], 'prefetch_as_load': False, 'virtual_prefetch': False, 'wq_check_full_addr': False, 'prefetch_activate': 'LOAD,PREFETCH', 'prefetcher': 'no', 'replacement': 'lru', 'name': 'LLC', 'lower_level': 'DRAM' }
default_pmem = { 'name': 'DRAM', 'frequency': 3200, 'channels': 1, 'ranks': 1, 'banks': 8, 'rows': 65536, 'columns': 128, 'lines_per_column': 8, 'channel_width': 8, 'wq_size': 64, 'rq_size': 64, 'tRP': 12.5, 'tRCD': 12.5, 'tCAS': 12.5, 'turn_around_time': 7.5 }
default_vmem = { 'size': 8589934592, 'num_levels': 5, 'minor_fault_penalty': 200 }
default_ptw = { 'pscl5_set' : 1, 'pscl5_way' : 2, 'pscl4_set' : 1, 'pscl4_way': 4, 'pscl3_set' : 2, 'pscl3_way' : 4, 'pscl2_set' : 4, 'pscl2_way': 8, 'ptw_rq_size': 16, 'ptw_mshr_size': 5, 'ptw_max_read': 2, 'ptw_max_write': 2}

###
# Establish default optional values
###

config_file['physical_memory'] = chain(config_file['physical_memory'], default_pmem)
config_file['virtual_memory'] = chain(config_file['virtual_memory'], default_vmem)

cores = config_file.get('ooo_cpu', [{}])

# Index the cache array by names
caches = {c['name']: c for c in config_file.get('cache',[])}
ptws = {p['name']: p for p in config_file.get('ptws',[])}

# Copy or trim cores as necessary to fill out the specified number of cores
cpu_repeat_factor = math.ceil(config_file['num_cores'] / len(cores));
cores = list(itertools.islice(itertools.chain.from_iterable(itertools.repeat(c, cpu_repeat_factor) for c in cores), config_file['num_cores']))

# Default core elements
root_copy_keys = ('PTW', 'DIB', 'L1I', 'L1D', 'L2C', 'ITLB', 'DTLB', 'STLB')
cores = [chain(cpu, {'name': 'cpu'+str(i), 'index': i}, dict(filter(lambda x: x[0] in root_copy_keys, config_file.items())), default_core) for i,cpu in enumerate(cores)]

# Append LLC to cache array
# LLC operates at maximum freqency of cores, if not already specified
caches['LLC'] = chain(caches.get('LLC',{}), config_file['LLC'], {'frequency': max(cpu['frequency'] for cpu in cores)}, default_llc)

# If specified in the core, move definition to cache array
for cpu in cores:
    # Assign defaults that are unique per core
    for cache_name in ('L1I', 'L1D', 'L2C', 'ITLB', 'DTLB', 'STLB'):
        if isinstance(cpu[cache_name], dict):
            cpu[cache_name] = chain(cpu[cache_name], {'name': cpu['name'] + '_' + cache_name}, config_file[cache_name])
            caches[cpu[cache_name]['name']] = cpu[cache_name]
            cpu[cache_name] = cpu[cache_name]['name']
    if isinstance(cpu['PTW'], dict):
        cpu['PTW'] = chain(cpu['PTW'], {'name': cpu['name'] + '_PTW'}, config_file['PTW'])
        ptws[cpu['PTW']['name']] = cpu['PTW']
        cpu['PTW'] = cpu['PTW']['name']

# Assign defaults that are unique per core
for cpu in cores:
    cpu['DIB'] = chain(cpu['DIB'], default_dib)
    ptws[cpu['PTW']] = chain(ptws[cpu['PTW']], config_file.get('PTW', {}), {'cpu': cpu['index'], 'frequency': cpu['frequency'], 'lower_level': cpu['L1D']}, default_ptw)
    caches[cpu['L1I']] = chain(caches[cpu['L1I']], {'frequency': cpu['frequency'], 'lower_level': cpu['L2C'], 'lower_translate': cpu['ITLB'], '_needs_translate': True, '_is_instruction_cache': True}, default_l1i)
    caches[cpu['L1D']] = chain(caches[cpu['L1D']], {'frequency': cpu['frequency'], 'lower_level': cpu['L2C'], 'lower_translate': cpu['DTLB'], '_needs_translate': True}, default_l1d)
    caches[cpu['ITLB']] = chain(caches[cpu['ITLB']], {'frequency': cpu['frequency'], 'lower_level': cpu['STLB']}, default_itlb)
    caches[cpu['DTLB']] = chain(caches[cpu['DTLB']], {'frequency': cpu['frequency'], 'lower_level': cpu['STLB']}, default_dtlb)

    # L2C
    cache_name = caches[cpu['L1D']]['lower_level']
    if cache_name != 'DRAM':
        caches[cache_name] = chain(caches[cache_name], {'frequency': cpu['frequency'], 'lower_level': 'LLC', 'lower_translate': caches[cpu['DTLB']]['lower_level']}, default_l2c)

    # STLB
    cache_name = caches[cpu['DTLB']]['lower_level']
    if cache_name != 'DRAM':
        caches[cache_name] = chain(caches[cache_name], {'frequency': cpu['frequency'], 'lower_level': cpu['PTW']}, default_stlb)

    # LLC
    cache_name = caches[caches[cpu['L1D']]['lower_level']]['lower_level']
    if cache_name != 'DRAM':
        caches[cache_name] = chain(caches[cache_name], default_llc)

def iter_system(system, name, key='lower_level'):
    while name in system:
        yield system[name]
        name = system[name][key]

# Remove caches that are inaccessible
accessible_names = tuple(map(lambda x: x['name'], itertools.chain.from_iterable(iter_system(caches, cpu[name]) for cpu,name in itertools.product(cores, ('ITLB', 'DTLB', 'L1I', 'L1D')))))
caches = dict(filter(lambda x: x[0] in accessible_names, caches.items()))

# Establish latencies in caches
for cache in caches.values():
    cache['hit_latency'] = cache.get('hit_latency') or (cache['latency'] - cache['fill_latency'])

# Scale frequencies
def scale_frequencies(it):
    it_a, it_b = itertools.tee(it, 2)
    max_freq = max(x['frequency'] for x in it_a)
    for x in it_b:
        x['frequency'] = max_freq / x['frequency']

config_file['physical_memory']['io_freq'] = config_file['physical_memory']['frequency'] # Save value
scale_frequencies(itertools.chain(cores, caches.values(), ptws.values(), (config_file['physical_memory'],)))

# TLBs use page offsets, Caches use block offsets
for tlb in itertools.chain.from_iterable(iter_system(caches, cpu[name]) for cpu,name in itertools.product(cores, ('ITLB', 'DTLB'))):
    tlb['offset_bits'] = 'lg2(' + str(config_file['page_size']) + ')'
    tlb['_needs_translate'] = False

for cache in itertools.chain.from_iterable(iter_system(caches, cpu[name]) for cpu,name in itertools.product(cores, ('L1I', 'L1D'))):
    cache['offset_bits'] = 'lg2(' + str(config_file['block_size']) + ')'
    cache['_needs_translate'] = cache.get('_needs_translate', False) or cache.get('virtual_prefetch', False)

# Try the local module directories, then try to interpret as a path
def default_dir(dirname, f):
    fname = os.path.join(dirname, f)
    if not os.path.exists(fname):
        fname = os.path.relpath(os.path.expandvars(os.path.expanduser(f)))
    if not os.path.exists(fname):
        print('Path "' + fname + '" does not exist. Exiting...')
        sys.exit(1)
    return fname

def wrap_list(attr):
    if not isinstance(attr, list):
        attr = [attr]
    return attr

for cache in caches.values():
    cache['replacement'] = [default_dir('replacement', f) for f in wrap_list(cache.get('replacement', []))]
    cache['prefetcher']  = [default_dir('prefetcher', f) for f in wrap_list(cache.get('prefetcher', []))]

for cpu in cores:
    cpu['branch_predictor'] = [default_dir('branch', f) for f in wrap_list(cpu.get('branch_predictor', []))]
    cpu['btb']              = [default_dir('btb', f) for f in wrap_list(cpu.get('btb', []))]

###
# Check to make sure modules exist and they correspond to any already-built modules.
###

def default_modules(dirname):
    return tuple(os.path.join(dirname, d) for d in os.listdir(dirname) if os.path.isdir(os.path.join(dirname, d)))

repl_module_names = itertools.chain(default_modules('replacement'), *(c['replacement'] for c in caches.values()))
pref_module_names = list(itertools.chain(((m,m.endswith('_instr')) for m in default_modules('prefetcher')), *(zip(c['prefetcher'], itertools.repeat(c.get('_is_instruction_cache',False))) for c in caches.values())))
branch_module_names = itertools.chain(default_modules('branch'), *(c['branch_predictor'] for c in cores))
btb_module_names = itertools.chain(default_modules('btb'), *(c['btb'] for c in cores))

repl_data   = {modules.get_module_name(fname): {'fname':fname, **modules.get_repl_data(modules.get_module_name(fname))} for fname in repl_module_names}
pref_data   = {modules.get_module_name(fname): {'fname':fname, **modules.get_pref_data(modules.get_module_name(fname),is_instr)} for fname,is_instr in pref_module_names}
branch_data = {modules.get_module_name(fname): {'fname':fname, **modules.get_branch_data(modules.get_module_name(fname))} for fname in branch_module_names}
btb_data    = {modules.get_module_name(fname): {'fname':fname, **modules.get_btb_data(modules.get_module_name(fname))} for fname in btb_module_names}

for cpu in cores:
    cpu['branch_predictor'] = [module_name for module_name,data in branch_data.items() if data['fname'] in cpu['branch_predictor']]
    cpu['btb']              = [module_name for module_name,data in btb_data.items() if data['fname'] in cpu['btb']]

for cache in caches.values():
    cache['replacement'] = [module_name for module_name,data in repl_data.items() if data['fname'] in cache['replacement']]
    cache['prefetcher']  = [module_name for module_name,data in pref_data.items() if data['fname'] in cache['prefetcher']]

###
# Perform final preparations for file writing
###

# Give each element a fill level
memory_system = dict(**caches, **ptws)
for fill_level, elem in itertools.chain.from_iterable(enumerate(iter_system(memory_system, cpu[name])) for cpu,name in itertools.product(cores, ('ITLB', 'DTLB', 'L1I', 'L1D'))):
    elem['_fill_level'] = max(elem.get('_fill_level',0), fill_level)

# Remove name index
memory_system = list(memory_system.values())

memory_system.sort(key=operator.itemgetter('_fill_level'), reverse=True)

###
# Begin file writing
###
# Instantiation file
write_if_different(instantiation_file_name, generated_warning + instantiation_file.get_instantiation_string(cores, memory_system, config_file['physical_memory'], config_file['virtual_memory']))

# Core modules file
write_if_different(core_modules_file_name, generated_warning + modules.get_branch_string(branch_data) + modules.get_btb_string(btb_data))

# Cache modules file
write_if_different(cache_modules_file_name, generated_warning + modules.get_repl_string(repl_data) + modules.get_pref_string(pref_data))

# Constants header
constants_file = generated_warning
constants_file += '#ifndef CHAMPSIM_CONSTANTS_H\n'
constants_file += '#define CHAMPSIM_CONSTANTS_H\n'
constants_file += '#include <cstdlib>\n'
constants_file += '#include "util.h"\n'
constants_file += 'constexpr unsigned BLOCK_SIZE = {block_size};\n'.format(**config_file)
constants_file += 'constexpr unsigned PAGE_SIZE = {page_size};\n'.format(**config_file)
constants_file += 'constexpr uint64_t STAT_PRINTING_PERIOD = {heartbeat_frequency};\n'.format(**config_file)
constants_file += 'constexpr std::size_t NUM_CPUS = {num_cores};\n'.format(**config_file)
constants_file += 'constexpr std::size_t NUM_CACHES = ' + str(len(caches)) + ';\n'
constants_file += 'constexpr auto LOG2_BLOCK_SIZE = lg2(BLOCK_SIZE);\n'
constants_file += 'constexpr auto LOG2_PAGE_SIZE = lg2(PAGE_SIZE);\n'
constants_file += f'constexpr static std::size_t NUM_BRANCH_MODULES = {len(branch_data)};\n'
constants_file += f'constexpr static std::size_t NUM_BTB_MODULES = {len(btb_data)};\n'
constants_file += f'constexpr static std::size_t NUM_REPLACEMENT_MODULES = {len(repl_data)};\n'
constants_file += f'constexpr static std::size_t NUM_PREFETCH_MODULES = {len(pref_data)};\n'

constants_file += 'constexpr uint64_t DRAM_IO_FREQ = {io_freq};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_CHANNELS = {channels};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_RANKS = {ranks};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_BANKS = {banks};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_ROWS = {rows};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_COLUMNS = {columns};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_CHANNEL_WIDTH = {channel_width};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_WQ_SIZE = {wq_size};\n'.format(**config_file['physical_memory'])
constants_file += 'constexpr std::size_t DRAM_RQ_SIZE = {rq_size};\n'.format(**config_file['physical_memory'])
constants_file += '#endif\n'
write_if_different(constants_header_name, constants_file)

# Makefile
module_info = tuple(itertools.chain(repl_data.values(), pref_data.values(), branch_data.values(), btb_data.values()))
generated_files = (constants_header_name, instantiation_file_name, core_modules_file_name, cache_modules_file_name)
write_if_different('_configuration.mk', 'generated_files = ' + ' '.join(generated_files) + '\n\n' + makefile.get_makefile_string(module_info, **config_file))

# vim: set filetype=python:
