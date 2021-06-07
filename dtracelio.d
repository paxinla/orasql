#!/usr/sbin/dtrace -Cs

/********************************************************************************************/
/*                                                                                          */
/*   File Name:    dtracelio.d                                                              */
/*   Version:      0.41                                                                     */
/*   Authors:      Alexander Anokhin ( http://alexanderanokhin.wordpress.com )              */
/*                 Andrey Nikolaev   ( http://andreynikolaev.wordpress.com )                */
/*   Dated:        Oct 2011                                                                 */
/*   Purpose:      The script shows calls of the functions                                  */
/*                 performing logical I/O in Oracle.                                        */
/*                 Current version monitors execution of functions:                         */
/*                 kcbgtcr - Kernel Cache Buffer Get Consistent Read                        */
/*                 kcbgcur - Kernel Cache Buffer Get Current Read                           */
/*                 kcbget  - Kernel Cache Buffer Get                                        */
/*                                                                                          */
/*   Usage:        dtracelio.d <PID> [SHOW_EACH_CALL]                                       */
/*                 PID: unix process ID                                                     */
/*                 SHOW_EACH_CALL: 1 - enable output of each call  (default)                */
/*                                 0 - disable output of each call                          */
/*                                                                                          */
/*   Output:       Example of function calls output (SHOW_EACH_CALL mode):                  */
/*                 kcbgtcr(0xFFFFFD7FFFDFB0F0,0,577,0)                                      */
/*                 [tsn: 4 rdba: 0x100060a (4/1546) obj: 79218 dobj: 79218]                 */
/*                 where: 742                                                               */
/*                                                                                          */
/*                 kcbgtcr()    - this is the function call with 4 arguments                */
/*                 tsn          每 a tablespace number (v$tablespace.ts#)                    */
/*                 rdba         每 a relative dba (data block address)                       */
/*                 (4/1546)     每 file 4 block 1546                                         */
/*                 obj          每 dictionary object number (dba_objects.object_id)          */
/*                 dobj         每 data object number (dba_objects.data_object_id)           */
/*                 mode_held:   - (only for kcbgcur) mode in which the block                */
/*                                is pinned (x$bh.mode_held)                                */
/*                                0 not pinned (KCBMNULL)                                   */
/*                                1 shared     (KCBMSHR)                                    */
/*                                2 exclusive  (KCBMEXCL)                                   */
/*                 where        每 location from which function was called (x$kcbwf.indx)    */
/*                                                                                          */
/*                 Example of Summary section                                               */
/*                 (appeared after script is finished by Ctrl+C)                            */
/*                 =============================== Summary =========================        */
/*                 object_id    data_object_id  function   mode_held  where    count        */
/*                 79250        79250           kcbgtcr               743      1            */
/*                 79250        79250           kcbgtcr               744      3            */
/*                 79250        79250           kcbgtcr               869      1072         */
/*                                                                                          */
/*                 Summary section is aggregation of all calls grouped by                   */
/*                 object_id, data_object_id, function, mode_held, where.                   */
/*                                                                                          */
/*   Other:        Some bits of info in 8103.1                                              */
/*                 Note that data structures definitions are not full                       */
/*                 in current version of the script                                         */
/*                                                                                          */
/********************************************************************************************/

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10Hz

/*      0. Several standard oratype.h declarations */

typedef unsigned long long 	ub8;	/* unsigned int of length 8 */
typedef unsigned int       	ub4;
typedef unsigned short     	ub2;
typedef unsigned char      	ub1;
typedef 	 int       	sb4;

/*  */
typedef sb4 kobjd;
typedef sb4 kobjn;
typedef ub4 ktsn;
typedef ub4 krdba;

/* definition from MOS note 8103.1 */

typedef struct kdbafr /* full relative dba */
{
    ktsn tsn_kdbafr;  /* a tablespace number */
    krdba dba_kdbafr; /* a relative dba */
} kdbafr;

typedef struct ktid /* relative dba + objd */
{
    struct kdbafr dbr_ktid; /* a relative dba */
    kobjd objd_ktid; /* data object number */
    kobjn objn_ktid; /* dictionary object number */
} ktid;

typedef struct kcbds
{
    struct ktid kcbdstid; /* full relative DBA plus object number */
    /* Here unknown (yet ;-)) part of the structure */
} kcbds;

BEGIN
{
    printf("\nDynamic tracing of Oracle logical I/O v0.41 by Alexander Anokhin ( http://alexanderanokhin.wordpress.com )\n\n");
    show_each_call = ($$2 == NULL) ? 1:$2;
}

pid$1::kcbgtcr:entry,
pid$1::kcbgcur:entry,
pid$1::kcbget:entry
{
    blk         = ((kcbds *) copyin(arg0, sizeof(kcbds)));
    tsn         = blk->kcbdstid.dbr_ktid.tsn_kdbafr;
    rdba        = blk->kcbdstid.dbr_ktid.dba_kdbafr;
    objd        = blk->kcbdstid.objd_ktid;
    objn        = blk->kcbdstid.objn_ktid;
    rdba_file   = rdba>>22;		/* for smallfile tablespaces */
    rdba_block  = rdba&0x3FFFFF;
    mode_held   = arg1;
    where       = arg2&0xFFFF;
    @func[objn,objd,probefunc,(probefunc=="kcbgcur" || probefunc=="kcbget"? lltostr(mode_held):""),where] = count();
}

pid$1::kcbgtcr:entry
/show_each_call/
{
    printf("%s(0x%X,%d,%d,%d) [tsn: %d rdba: 0x%x (%d/%d) obj: %d dobj: %d] where: %d\n",probefunc,arg0,arg1,arg2,arg3,tsn, rdba,rdba_file,rdba_block,objn, objd, where);
}

pid$1::kcbgcur:entry,
pid$1::kcbget:entry
/show_each_call/
{
    printf("%s(0x%X,%d,%d,%d) [tsn: %d rdba: 0x%x (%d/%d) obj: %d dobj: %d] where: %d mode_held: %d\n",probefunc,arg0,arg1,arg2,arg3,tsn, rdba,rdba_file,rdba_block,objn, objd, where, mode_held);
}

END
{
    printf("\n============================ Summary ============================\n");
    printf("object_id    data_object_id  function   mode_held  where    count\n");
    printa("%-12d %-15d %-10s %-10s %-8d %@d\n", @func);
}