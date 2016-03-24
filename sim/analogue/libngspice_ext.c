/* Copyright (C) 2016 Kim Taylor
 *
 * This file is part of hbc_mac.
 *
 * hbc_mac is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * hbc_mac is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define str(s) #s
#define xstr(s) str(s)

#define STIM_DIR "../"

#ifndef FILENAME
#define FILENAME tx_data
#endif

#ifndef TX_SOURCE
#define TX_SOURCE v1
#endif

#define FILENAME_STR xstr(FILENAME)
#define TX_SOURCE_STR xstr(TX_SOURCE)

/* #define logfile "debug.txt" */

double *stim_when;
uint8_t  *stim_val;
static int num_stim, first_stim, last_stim;
static int init_done;
static FILE *print_output;

/*  TYPE std_ulogic IS ( 'U',  -- Uninitialized
 *                       'X',  -- Forcing  Unknown
 *                       '0',  -- Forcing  0
 *                       '1',  -- Forcing  1
 *                       'Z',  -- High Impedance
 *                       'W',  -- Weak     Unknown
 *                       'L',  -- Weak     0
 *                       'H',  -- Weak     1
 *                       '-'   -- Don't care
 *                     ); */

typedef enum {
    STD_LOGIC_U,
    STD_LOGIC_X,
    STD_LOGIC_0,
    STD_LOGIC_1,
    STD_LOGIC_Z,
    STD_LOGIC_W,
    STD_LOGIC_L,
    STD_LOGIC_H,
    STD_LOGIC_D,
} std_logic;

static inline uint8_t ghdl_to_spice(uint8_t ghdl_val) {
    std_logic std_logic_val = ghdl_val;
    switch (std_logic_val) {
        case STD_LOGIC_U: /* 'U' */
            return 0;
        case STD_LOGIC_X: /* 'X' */
            return 0;
        case STD_LOGIC_0: /* '0' */
            return 0;
        case STD_LOGIC_1: /* '1' */
            return 1;
        case STD_LOGIC_Z: /* 'Z' */
            return 0;
        case STD_LOGIC_W: /* 'W' */
            return 0;
        case STD_LOGIC_L: /* 'L' */
            return 0;
        case STD_LOGIC_H: /* 'H' */
            return 1;
        case STD_LOGIC_D: /* '-' */
            return 0;
    }
    return 0;
}

static int open_stimulus(const char *file_name) {
    int i;
    int unused;
    FILE *time_fp, *val_fp;
    char *time_filename, *val_filename;
    long num_vals;
    uint64_t ghdl_time;
    uint8_t ghdl_val;
    (void) unused;

    unused = asprintf(&val_filename, "%s%s.value", STIM_DIR, file_name);
    unused = asprintf(&time_filename, "%s%s.time", STIM_DIR, file_name);

    time_fp = fopen(time_filename, "r");
    val_fp = fopen(val_filename, "r");

    free(time_filename);
    free(val_filename);

    if (!time_fp) {
        fprintf(print_output, "Couldn't open time file %s\n", time_filename);
        return -1;
    }

    if (!val_fp) {
        fprintf(print_output, "Couldn't open value file %s\n", val_filename);
        return -1;
    }

    unused = fseek(val_fp, 0, SEEK_END);
    num_vals = ftell(val_fp);
    fprintf(print_output, "Found %li values\n", num_vals);
    unused = fseek(val_fp, 0, SEEK_SET);

    stim_when = malloc(sizeof(double) * num_vals);
    stim_val = malloc(sizeof(uint8_t) * num_vals);

    for (i = 0; i < num_vals; i++) {
        unused = fread(&ghdl_time, sizeof(uint64_t), 1, time_fp);
        unused = fread(&ghdl_val, sizeof(uint8_t), 1, val_fp);
        stim_when[i] = ghdl_time * 1e-15;
        stim_val[i] = ghdl_to_spice(ghdl_val);
    }

    return num_vals;
}

static void do_init(void) {
    int i;

#ifdef logfile
    print_output = fopen(logfile, "w");
#else
    print_output = stdout;
#endif

    fprintf(print_output, "Opening stimulus file: %s\n", FILENAME_STR);

    num_stim = open_stimulus(FILENAME_STR);
    if (num_stim < 0) {
        fprintf(print_output, "Error opening stimulus file\n");
        exit(1);
    }

    for (i = 0; i < num_stim; i++) {
        if (stim_val[i] == 1) break;
    }
    first_stim = i;
    fprintf(print_output, "First stimulus: %e\n", stim_when[i]);

    for (i = num_stim - 1; i > 0; i--) {
        if (stim_val[i] == 1) break;
    }
    last_stim = i;
    fprintf(print_output, "Last stimulus: %e\n", stim_when[i]);

    init_done = 1;

    return;
}

double getvsrcval(double time, char *srcname) {
    static int index;
    if (!init_done) do_init();

    if (strcmp(srcname, TX_SOURCE_STR)) return 0;
    
    while (stim_when[index + 1] < time) {
	index++;
	if ((index + 1) >= num_stim) break;
    }

    return stim_val[index] * 2.5; 
}

double getisrcval(double time, char *srcname) {
    return 0;
}

