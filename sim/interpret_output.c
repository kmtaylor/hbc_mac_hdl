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
#include <assert.h>

#define GHDL_SIG_HEADER_LENGTH 0x1b
#define GHDL_INDEX_TYPE_LENGTH 4
#define OUTPUT_LENGTH 32

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

int main(void) {
    FILE *fp;
    uint8_t bits[GHDL_INDEX_TYPE_LENGTH + OUTPUT_LENGTH];
    uint32_t val;
    int i;

    fp = fopen("output_data", "r");
    assert(fp);

    fseek(fp, GHDL_SIG_HEADER_LENGTH, SEEK_SET);

    while (fread(bits, 1, GHDL_INDEX_TYPE_LENGTH + OUTPUT_LENGTH, fp)) {
	val = 0;
	for (i = 0; i < OUTPUT_LENGTH; i++) {
	    if (bits[i + GHDL_INDEX_TYPE_LENGTH] == STD_LOGIC_1) {
		val |= (1 << (OUTPUT_LENGTH-1 - i));
	    }
	}
	printf("0x%08X\n", val);
    }

    return 0;
}
