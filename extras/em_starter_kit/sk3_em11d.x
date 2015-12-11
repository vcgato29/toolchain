/* ARC EM Starter Kit v3 EM11D */

MEMORY
{
    ICCM : ORIGIN = 0x00000000, LENGTH = 64K
    DRAM : ORIGIN = 0x10000000, LENGTH = 128M
    DCCM : ORIGIN = 0x80000000, LENGTH = 64K
}

REGION_ALIAS("startup", ICCM)
REGION_ALIAS("text", ICCM)
REGION_ALIAS("data", DRAM)
REGION_ALIAS("sdata", DRAM)

PROVIDE (__stack_top = (0x17FFFFFF & -4) );
PROVIDE (__end_heap = (0x17FFFFFF) );
