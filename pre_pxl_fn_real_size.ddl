SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK ON
SET TIMING ON
SET LINESIZE 250

CREATE OR REPLACE FUNCTION PXL_FN_REAL_SIZE( P_IC_SEGNAME   IN VARCHAR2
                                           , P_IC_OWNER     IN VARCHAR2 DEFAULT USER
                                           , P_IC_TYPE      IN VARCHAR2 DEFAULT 'TABLE'
                                           )
RETURN NUMBER AUTHID CURRENT_USER
AS
    L_VN_TOTAL_BLOCKS            NUMBER;
    L_VN_TOTAL_BYTES             NUMBER;
    L_VN_UNUSED_BLOCKS           NUMBER;
    L_VN_UNUSED_BYTES            NUMBER;
    L_VN_LASTUSEDEXTFILEID       NUMBER;
    L_VN_LASTUSEDEXTBLOCKID      NUMBER;
    L_VN_LAST_USED_BLOCK         NUMBER;
    L_VN_UNFORMATTED_BLOCKS      NUMBER;
    L_VN_UNFORMATTED_BYTES       NUMBER;
    L_VN_FS1_BLOCKS              NUMBER;
    L_VN_FS1_BYTES               NUMBER;
    L_VN_FS2_BLOCKS              NUMBER;
    L_VN_FS2_BYTES               NUMBER;
    L_VN_FS3_BLOCKS              NUMBER;
    L_VN_FS3_BYTES               NUMBER;
    L_VN_FS4_BLOCKS              NUMBER;
    L_VN_FS4_BYTES               NUMBER;
    L_VN_FULL_BLOCKS             NUMBER;
    L_VN_FULL_BYTES              NUMBER;
    T_VN_TOTAL_BYTES             NUMBER;
    T_VN_FS_BYTES                NUMBER;
    P_VC_PART_NAME               VARCHAR2(30);
BEGIN
    DBMS_SPACE.SPACE_USAGE( P_IC_OWNER
                          , P_IC_SEGNAME
                          , P_IC_TYPE
                          , L_VN_UNFORMATTED_BLOCKS
                          , L_VN_UNFORMATTED_BYTES
                          , L_VN_FS1_BLOCKS
                          , L_VN_FS1_BYTES
                          , L_VN_FS2_BLOCKS
                          , L_VN_FS2_BYTES
                          , L_VN_FS3_BLOCKS
                          , L_VN_FS3_BYTES
                          , L_VN_FS4_BLOCKS
                          , L_VN_FS4_BYTES
                          , L_VN_FULL_BLOCKS
                          , L_VN_FULL_BYTES
                          , P_VC_PART_NAME
                          );
    DBMS_SPACE.UNUSED_SPACE( P_IC_OWNER
                           , P_IC_SEGNAME
                           , P_IC_TYPE
                           , L_VN_TOTAL_BLOCKS
                           , L_VN_TOTAL_BYTES
                           , L_VN_UNUSED_BLOCKS
                           , L_VN_UNUSED_BYTES
                           , L_VN_LASTUSEDEXTFILEID
                           , L_VN_LASTUSEDEXTBLOCKID
                           , L_VN_LAST_USED_BLOCK
                           , P_VC_PART_NAME
                           );
    -----------------------------------------
    T_VN_FS_BYTES := L_VN_FS1_BYTES*0.25/2 + L_VN_FS2_BYTES*(0.5+0.25)/2
                   + L_VN_FS3_BYTES*(0.75+0.5)/2 + L_VN_FS4_BYTES*(1+0.75)/2
                   + L_VN_UNUSED_BYTES;
    T_VN_TOTAL_BYTES := L_VN_TOTAL_BYTES;
    -----------------------------------------
    RETURN T_VN_TOTAL_BYTES - T_VN_FS_BYTES;
EXCEPTION
    WHEN OTHERS THEN
        RETURN - 1;
END;
/
