// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


pragma solidity ^0.7.0;

/// @title Bits Manipulation Library
/// @author Felipe Argento / Stephen Chen
/// @notice Implements bit manipulation helper functions
library BitsManipulationLibrary {

    /// @notice Sign extend a shorter signed value to the full int32
    /// @param number signed number to be extended
    /// @param wordSize number of bits of the signed number, ie, 8 for int8
    function int32SignExtension(int32 number, uint32 wordSize)
    public pure returns(int32)
    {
        uint32 uNumber = uint32(number);
        bool isNegative = ((uint64(1) << (wordSize - 1)) & uNumber) > 0;
        uint32 mask = ((uint32(2) ** wordSize) - 1);

        if (isNegative) {
            uNumber = uNumber | ~mask;
        }

        return int32(uNumber);
    }

    /// @notice Sign extend a shorter signed value to the full uint64
    /// @param number signed number to be extended
    /// @param wordSize number of bits of the signed number, ie, 8 for int8
    function uint64SignExtension(uint64 number, uint64 wordSize)
    public pure returns(uint64)
    {
        uint64 uNumber = number;
        bool isNegative = ((uint64(1) << (wordSize - 1)) & uNumber) > 0;
        uint64 mask = ((uint64(2) ** wordSize) - 1);

        if (isNegative) {
            uNumber = uNumber | ~mask;
        }

        return uNumber;
    }

    /// @notice Swap byte order of unsigned ints with 64 bytes
    /// @param num number to have bytes swapped
    function uint64SwapEndian(uint64 num) public pure returns(uint64) {
        uint64 output = ((num & 0x00000000000000ff) << 56)|
            ((num & 0x000000000000ff00) << 40)|
            ((num & 0x0000000000ff0000) << 24)|
            ((num & 0x00000000ff000000) << 8) |
            ((num & 0x000000ff00000000) >> 8) |
            ((num & 0x0000ff0000000000) >> 24)|
            ((num & 0x00ff000000000000) >> 40)|
            ((num & 0xff00000000000000) >> 56);

        return output;
    }

    /// @notice Swap byte order of unsigned ints with 32 bytes
    /// @param num number to have bytes swapped
    function uint32SwapEndian(uint32 num) public pure returns(uint32) {
        uint32 output = ((num >> 24) & 0xff) | ((num << 8) & 0xff0000) | ((num >> 8) & 0xff00) | ((num << 24) & 0xff000000);
        return output;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";
import "./RealTimeClock.sol";


/// @title CLINT
/// @author Felipe Argento
/// @notice Implements the Core Local Interruptor functionalities
/// @dev CLINT active addresses are 0x0200bff8(mtime) and 0x02004000(mtimecmp)
/// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library CLINT {

    uint64 constant CLINT_MSIP0_ADDR = 0x02000000;
    uint64 constant CLINT_MTIMECMP_ADDR = 0x02004000;
    uint64 constant CLINT_MTIME_ADDR = 0x0200bff8;

    /// @notice reads clint
    /// @param offset can be uint8, uint16, uint32 or uint64
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if read was successfull
    /// @return uint64 pval
    function clintRead(
        MemoryInteractor mi,
        uint64 offset,
        uint64 wordSize
    )
    public returns (bool, uint64)
    {

        if (offset == CLINT_MSIP0_ADDR) {
            return clintReadMsip(mi, wordSize);
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            return clintReadMtime(mi, wordSize);
        } else if (offset == CLINT_MTIME_ADDR) {
            return clintReadMtimecmp(mi, wordSize);
        } else {
            return (false, 0);
        }
    }

    /// @notice write to clint
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param offset can be uint8, uint16, uint32 or uint64
    /// @param val to be written
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if write was successfull
    function clintWrite(
        MemoryInteractor mi,
        uint64 offset,
        uint64 val,
        uint64 wordSize)
    public returns (bool)
    {
        if (offset == CLINT_MSIP0_ADDR) {
            if (wordSize == 32) {
                if ((val & 1) != 0) {
                    mi.setMip(RiscVConstants.getMipMsipMask());
                } else {
                    mi.resetMip(RiscVConstants.getMipMsipMask());
                }
                return true;
            }
            return false;
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            if (wordSize == 64) {
                mi.writeClintMtimecmp(val);
                mi.resetMip(RiscVConstants.getMipMsipMask());
                return true;
            }
            // partial mtimecmp is not supported
            return false;
        }
        return false;
    }

    // internal functions
    function clintReadMsip(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 32) {
            if ((mi.readMip() & RiscVConstants.getMipMsipMask()) == RiscVConstants.getMipMsipMask()) {
                return(true, 1);
            } else {
                return (true, 0);
            }
        }
        return (false, 0);
    }

    function clintReadMtime(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, RealTimeClock.rtcCycleToTime(mi.readMcycle()));
        }
        return (false, 0);
    }

    function clintReadMtimecmp(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, mi.readClintMtimecmp());
        }
        return (false, 0);
    }

    // getters
    function getClintMtimecmp() public pure returns (uint64) {
        return CLINT_MTIMECMP_ADDR;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";
import "./CSRReads.sol";

/// @title CSR
/// @author Felipe Argento
/// @notice Implements main CSR read and write logic
library CSR {

    //CSR addresses
    uint32 constant UCYCLE = 0xc00;
    uint32 constant UTIME = 0xc01;
    uint32 constant UINSTRET =  0xc02;

    uint32 constant SSTATUS = 0x100;
    uint32 constant SIE = 0x104;
    uint32 constant STVEC = 0x105;
    uint32 constant SCOUNTEREN = 0x106;

    uint32 constant SSCRATCH = 0x140;
    uint32 constant SEPC = 0x141;
    uint32 constant SCAUSE = 0x142;
    uint32 constant STVAL = 0x143;
    uint32 constant SIP = 0x144;

    uint32 constant SATP = 0x180;

    uint32 constant MVENDORID = 0xf11;
    uint32 constant MARCHID = 0xf12;
    uint32 constant MIMPID = 0xf13;
    uint32 constant MHARTID = 0xf14;

    uint32 constant MSTATUS = 0x300;
    uint32 constant MISA = 0x301;
    uint32 constant MEDELEG = 0x302;
    uint32 constant MIDELEG = 0x303;
    uint32 constant MIE = 0x304;
    uint32 constant MTVEC = 0x305;
    uint32 constant MCOUNTEREN = 0x306;

    uint32 constant MSCRATCH = 0x340;
    uint32 constant MEPC = 0x341;
    uint32 constant MCAUSE = 0x342;
    uint32 constant MTVAL = 0x343;
    uint32 constant MIP = 0x344;

    uint32 constant MCYCLE = 0xb00;
    uint32 constant MINSTRET = 0xb02;

    uint32 constant TSELECT = 0x7a0;
    uint32 constant TDATA1 = 0x7a1;
    uint32 constant TDATA2 = 0x7a2;
    uint32 constant TDATA3 = 0x7a3;

    /// @notice Reads the value of a CSR given its address
    /// @dev If/else should change to binary search to increase performance
    /// @param mi MemoryInteractor with which Step function is interacting.
    /// @param csrAddr Address of CSR in file.
    /// @return Returns the status of the operation (true for success, false otherwise).
    /// @return Register value.
    function readCsr(MemoryInteractor mi, uint32 csrAddr)
    public returns (bool, uint64)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv()) {
            return(false, 0);
        }
        if (csrAddr == UCYCLE) {
            return CSRReads.readCsrCycle(mi, csrAddr);
        } else if (csrAddr == UINSTRET) {
            return CSRReads.readCsrInstret(mi, csrAddr);
        } else if (csrAddr == UTIME) {
            return CSRReads.readCsrTime(mi, csrAddr);
        } else if (csrAddr == SSTATUS) {
            return CSRReads.readCsrSstatus(mi);
        } else if (csrAddr == SIE) {
            return CSRReads.readCsrSie(mi);
        } else if (csrAddr == STVEC) {
            return CSRReads.readCsrStvec(mi);
        } else if (csrAddr == SCOUNTEREN) {
            return CSRReads.readCsrScounteren(mi);
        } else if (csrAddr == SSCRATCH) {
            return CSRReads.readCsrSscratch(mi);
        } else if (csrAddr == SEPC) {
            return CSRReads.readCsrSepc(mi);
        } else if (csrAddr == SCAUSE) {
            return CSRReads.readCsrScause(mi);
        } else if (csrAddr == STVAL) {
            return CSRReads.readCsrStval(mi);
        } else if (csrAddr == SIP) {
            return CSRReads.readCsrSip(mi);
        } else if (csrAddr == SATP) {
            return CSRReads.readCsrSatp(mi);
        } else if (csrAddr == MSTATUS) {
            return CSRReads.readCsrMstatus(mi);
        } else if (csrAddr == MISA) {
            return CSRReads.readCsrMisa(mi);
        } else if (csrAddr == MEDELEG) {
            return CSRReads.readCsrMedeleg(mi);
        } else if (csrAddr == MIDELEG) {
            return CSRReads.readCsrMideleg(mi);
        } else if (csrAddr == MIE) {
            return CSRReads.readCsrMie(mi);
        } else if (csrAddr == MTVEC) {
            return CSRReads.readCsrMtvec(mi);
        } else if (csrAddr == MCOUNTEREN) {
            return CSRReads.readCsrMcounteren(mi);
        } else if (csrAddr == MSCRATCH) {
            return CSRReads.readCsrMscratch(mi);
        } else if (csrAddr == MEPC) {
            return CSRReads.readCsrMepc(mi);
        } else if (csrAddr == MCAUSE) {
            return CSRReads.readCsrMcause(mi);
        } else if (csrAddr == MTVAL) {
            return CSRReads.readCsrMtval(mi);
        } else if (csrAddr == MIP) {
            return CSRReads.readCsrMip(mi);
        } else if (csrAddr == MCYCLE) {
            return CSRReads.readCsrMcycle(mi);
        } else if (csrAddr == MINSTRET) {
            return CSRReads.readCsrMinstret(mi);
        } else if (csrAddr == MVENDORID) {
            return CSRReads.readCsrMvendorid(mi);
        } else if (csrAddr == MARCHID) {
            return CSRReads.readCsrMarchid(mi);
        } else if (csrAddr == MIMPID) {
            return CSRReads.readCsrMimpid(mi);
        } else if (csrAddr == TSELECT || csrAddr == TDATA1 || csrAddr == TDATA2 || csrAddr == TDATA3 || csrAddr == MHARTID) {
            //All hardwired to zero
            return (true, 0);
        }

        return CSRReads.readCsrFail();
    }

    /// @notice Writes a value to a CSR given its address
    /// @dev If/else should change to binary search to increase performance
    /// @param mi MemoryInteractor with which Step function is interacting.
    /// @param csrAddr Address of CSR in file.
    /// @param val Value to be written;
    /// @return The status of the operation (true for success, false otherwise).
    function writeCsr(
        MemoryInteractor mi,
        uint32 csrAddr,
        uint64 val
    )
    public returns (bool)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv()) {
            return false;
        }

        if (csrIsReadOnly(csrAddr)) {
            return false;
        }

        if (csrAddr == SSTATUS) {
            uint64 cMstatus = mi.readMstatus();
            return writeCsrMstatus(mi, (cMstatus & ~RiscVConstants.getSstatusWMask()) | (val & RiscVConstants.getSstatusWMask()));

        } else if (csrAddr == SIE) {
            uint64 mask = mi.readMideleg();
            uint64 cMie = mi.readMie();

            mi.writeMie((cMie & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == STVEC) {
            mi.writeStvec(val & uint64(~3));
            return true;
        } else if (csrAddr == SCOUNTEREN) {
            mi.writeScounteren(val & RiscVConstants.getScounterenRwMask());
            return true;
        } else if (csrAddr == SSCRATCH) {
            mi.writeSscratch(val);
            return true;
        } else if (csrAddr == SEPC) {
            mi.writeSepc(val & uint64(~3));
            return true;
        } else if (csrAddr == SCAUSE) {
            mi.writeScause(val);
            return true;
        } else if (csrAddr == STVAL) {
            mi.writeStval(val);
            return true;
        } else if (csrAddr == SIP) {
            uint64 cMask = mi.readMideleg();
            uint64 cMip = mi.readMip();

            cMip = (cMip & ~cMask) | (val & cMask);
            mi.writeMip(cMip);
            return true;
        } else if (csrAddr == SATP) {
            uint64 cSatp = mi.readSatp();
            int mode = cSatp >> 60;
            int newMode = (val >> 60) & 0xf;

            if (newMode == 0 || (newMode >= 8 && newMode <= 9)) {
                mode = newMode;
            }
            mi.writeSatp((val & ((uint64(1) << 44) - 1) | uint64(mode) << 60));
            return true;

        } else if (csrAddr == MSTATUS) {
            return writeCsrMstatus(mi, val);
        } else if (csrAddr == MEDELEG) {
            uint64 mask = ((uint64(1) << (RiscVConstants.getMcauseStoreAmoPageFault() + 1)) - 1);
            mi.writeMedeleg((mi.readMedeleg() & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == MIDELEG) {
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();
            mi.writeMideleg(((mi.readMideleg() & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MIE) {
            uint64 mask = RiscVConstants.getMipMsipMask() | RiscVConstants.getMipMtipMask() | RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();

            mi.writeMie(((mi.readMie() & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MTVEC) {
            mi.writeMtvec(val & uint64(~3));
            return true;
        } else if (csrAddr == MCOUNTEREN) {
            mi.writeMcounteren(val & RiscVConstants.getMcounterenRwMask());
            return true;
        } else if (csrAddr == MSCRATCH) {
            mi.writeMscratch(val);
            return true;
        } else if (csrAddr == MEPC) {
            mi.writeMepc(val & uint64(~3));
            return true;
        } else if (csrAddr == MCAUSE) {
            mi.writeMcause(val);
            return true;
        } else if (csrAddr == MTVAL) {
            mi.writeMtval(val);
            return true;
        } else if (csrAddr == MIP) {
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask();
            uint64 cMip = mi.readMip();

            cMip = (cMip & ~mask) | (val & mask);

            mi.writeMip(cMip);
            return true;
        } else if (csrAddr == MCYCLE) {
            // We can't allow writes to mcycle because we use it to measure the progress in machine execution.
            // BBL enables all counters in both M- and S-modes
            // We instead raise an exception.
            return false;
        } else if (csrAddr == MINSTRET) {
            // In Spike, QEMU, and riscvemu, mcycle and minstret are the aliases for the same counter
            // QEMU calls exit (!) on writes to mcycle or minstret
            mi.writeMinstret(val-1); // The value will be incremented after the instruction is executed
            return true;
        } else if (csrAddr == TSELECT || csrAddr == TDATA1 || csrAddr == TDATA2 || csrAddr == TDATA3 || csrAddr == MISA) {
            // Ignore writes
            return (true);
        }
        return false;
    }

    // Extract privilege level from CSR
    // Bits csr[9:8] encode the CSR's privilege level (i.e lowest privilege level
    // that can access that CSR.
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    function csrPriv(uint32 csrAddr) internal pure returns(uint32) {
        return (csrAddr >> 8) & 3;
    }

    // The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0])
    // The top two bits (csr[11:10]) indicate whether the register is
    // read/write (00, 01, or 10) or read-only (11)
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    function csrIsReadOnly(uint32 csrAddr) internal pure returns(bool) {
        return ((csrAddr & 0xc00) == 0xc00);
    }

    function writeCsrMstatus(MemoryInteractor mi, uint64 val)
    internal returns(bool)
    {
        uint64 cMstatus = mi.readMstatus() & RiscVConstants.getMstatusRMask();
        // Modifiy  only bits that can be written to
        cMstatus = (cMstatus & ~RiscVConstants.getMstatusWMask()) | (val & RiscVConstants.getMstatusWMask());
        //Update the SD bit
        if ((cMstatus & RiscVConstants.getMstatusFsMask()) == RiscVConstants.getMstatusFsMask()) {
            cMstatus |= RiscVConstants.getMstatusSdMask();
        }
        mi.writeMstatus(cMstatus);
        return true;
    }

}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./CSR.sol";

/// @title CSRExecute
/// @author Felipe Argento
/// @notice Implements CSR execute logic
library CSRExecute {
    uint256 constant CSRRS_CODE = 0;
    uint256 constant CSRRC_CODE = 1;

    uint256 constant CSRRSI_CODE = 0;
    uint256 constant CSRRCI_CODE = 1;

    /// @notice Implementation of CSRRS and CSRRC instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrSC(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode
    )
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint64 rs1val = mi.readX(rs1);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, csrval);
        }

        uint64 execValue = 0;
        if (insncode == CSRRS_CODE) {
            execValue = executeCSRRS(csrval, rs1val);
        } else {
            // insncode == CSRRCCode
            execValue = executeCSRRC(csrval, rs1val);
        }
        if (rs1 != 0) {
            if (!CSR.writeCsr(
                mi,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    /// @notice Implementation of CSRRSI and CSRRCI instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written.
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrSCI(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode)
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, csrval);
        }

        uint64 execValue = 0;
        if (insncode == CSRRSI_CODE) {
            execValue = executeCSRRSI(csrval, rs1);
        } else {
            // insncode == CSRRCICode
            execValue = executeCSRRCI(csrval, rs1);
        }

        if (rs1 != 0) {
            if (!CSR.writeCsr(
                mi,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    /// @notice Implementation of CSRRW and CSRRWI instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written.
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrRW(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode
    )
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = true;
        uint64 csrval = 0;
        uint64 rs1val = 0;

        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            (status, csrval) = CSR.readCsr(mi, csrAddress);
        }

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }

        if (insncode == 0) {
            rs1val = executeCSRRW(mi, insn);
        } else {
            // insncode == 1
            rs1val = executeCSRRWI(insn);
        }

        if (!CSR.writeCsr(
                mi,
                csrAddress,
                rs1val
        )) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        if (rd != 0) {
            mi.writeX(rd, csrval);
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    //internal functions
    function executeCSRRW(MemoryInteractor mi, uint32 insn)
    internal returns(uint64)
    {
        return mi.readX(RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRWI(uint32 insn) internal pure returns(uint64) {
        return uint64(RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRS(uint64 csr, uint64 rs1) internal pure returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRC(uint64 csr, uint64 rs1) internal pure returns(uint64) {
        return csr & ~rs1;
    }

    function executeCSRRSI(uint64 csr, uint32 rs1) internal pure returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRCI(uint64 csr, uint32 rs1) internal pure returns(uint64) {
        return csr & ~rs1;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./RealTimeClock.sol";

/// @title CSRReads
/// @author Felipe Argento
/// @notice Implements CSR read logic
library CSRReads {
    function readCsrCycle(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            return (true, mi.readMcycle());
        } else {
            return (false, 0);
        }
    }

    function readCsrInstret(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            return (true, mi.readMinstret());
        } else {
            return (false, 0);
        }
    }

    function readCsrTime(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            uint64 mtime = RealTimeClock.rtcCycleToTime(mi.readMcycle());
            return (true, mtime);
        } else {
            return (false, 0);
        }
    }

    function readCsrSstatus(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus() & RiscVConstants.getSstatusRMask());
    }

    function readCsrSie(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mie = mi.readMie();
        uint64 mideleg = mi.readMideleg();

        return (true, mie & mideleg);
    }

    function readCsrStvec(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readStvec());
    }

    function readCsrScounteren(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readScounteren());
    }

    function readCsrSscratch(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readSscratch());
    }

    function readCsrSepc(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readSepc());
    }

    function readCsrScause(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readScause());
    }

    function readCsrStval(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readStval());
    }

    function readCsrSip(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mip = mi.readMip();
        uint64 mideleg = mi.readMideleg();
        return (true, mip & mideleg);
    }

    function readCsrSatp(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mstatus = mi.readMstatus();
        uint64 priv = mi.readIflagsPrv();

        if (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTvmMask() != 0)) {
            return (false, 0);
        } else {
            return (true, mi.readSatp());
        }
    }

    function readCsrMstatus(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus() & RiscVConstants.getMstatusRMask());
    }

    function readCsrMisa(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMisa());
    }

    function readCsrMedeleg(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMedeleg());
    }

    function readCsrMideleg(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMideleg());
    }

    function readCsrMie(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMie());
    }

    function readCsrMtvec(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtvec());
    }

    function readCsrMcounteren(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcounteren());
    }

    function readCsrMscratch(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMscratch());
    }

    function readCsrMepc(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMepc());
    }

    function readCsrMcause(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcause());
    }

    function readCsrMtval(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtval());
    }

    function readCsrMip(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMip());
    }

    function readCsrMcycle(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcycle());
    }

    function readCsrMinstret(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMinstret());
    }

    function readCsrMvendorid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMvendorid());
    }

    function readCsrMarchid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMarchid());
    }

    function readCsrMimpid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMimpid());
    }

    function readCsrFail() internal pure returns(bool, uint64) {
        return (false, 0);
    }

    // Check if counter is enabled. mcounteren control the availability of the
    // hardware performance monitoring counter to the next-lowest priv level.
    // Reference: riscv-privileged-v1.10 - section 3.1.17 - page 32.
    function rdcounteren(MemoryInteractor mi, uint32 csrAddr)
    internal returns (bool)
    {
        uint64 counteren = RiscVConstants.getMcounterenRwMask();
        uint64 priv = mi.readIflagsPrv();

        if (priv < RiscVConstants.getPrvM()) {
            counteren &= mi.readMcounteren();
            if (priv < RiscVConstants.getPrvS()) {
                counteren &= mi.readScounteren();
            }
        }
        return (((counteren >> (csrAddr & 0x1f)) & 1) != 0);
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";

/// @title Exceptions
/// @author Felipe Argento
/// @notice Implements raise exception behavior and mcause getters
library Exceptions {

    /// @notice Raise an exception (or interrupt).
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param cause Exception (or interrupt) mcause (or scause).
    /// @param tval Associated tval.
    function raiseException(
        MemoryInteractor mi,
        uint64 cause,
        uint64 tval)
    public
    {
        // All traps are handled in machine-mode, by default. Mideleg or Medeleg provide
        // bits to indicate if the interruption/exception should be taken care of by
        // lower privilege levels.
        // Medeleg -> Machine Exception Delegation register
        // Mideleg -> Machine Interrupt Delegation register
        // Reference: riscv-privileged-v1.9.1.pdf - Section 3.1.12, page 28.
        uint64 deleg = 0;
        uint64 priv = mi.readIflagsPrv();

        if (priv <= RiscVConstants.getPrvS()) {
            if ((cause & getMcauseInterruptFlag()) != 0) {
                // If exception was caused by an interruption the delegated information is
                // stored on mideleg register.

                // Clear the MCAUSE_INTERRUPT_FLAG() bit before shifting
                deleg = (mi.readMideleg() >> (cause & uint64(RiscVConstants.getXlen() - 1))) & 1;
            } else {
                //If not, information is in the medeleg register
                deleg = (mi.readMedeleg() >> cause) & 1;
            }
        }
        if (deleg != 0) {
            //is in S mode

            // SCAUSE - Supervisor Cause Register
            // Register containg Interrupt bit (shows if the exception was cause by an interrupt
            // and the Exception code, that identifies the last exception
            // The execption codes can be seen at table 4.1
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.8, page 51.
            mi.writeScause(cause);

            // SEPC - Supervisor Exception Program Counter
            // When a trap is taken, sepc is written with the address of the instruction
            // the encountered the exception.
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.7, page 50.
            mi.writeSepc(mi.readPc());

            // STVAL - Supervisor Trap Value
            // stval is written with exception-specific information, when a trap is
            // taken into S-Mode. The specific values can be found in Reference.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.11, page 55.
            mi.writeStval(tval);

            // MSTATUS - Machine Status Register
            // keeps track of and controls hart's current operating state.
            // Reference: riscv-privileged-v1.10.pdf - Section 3.1.16, page 19.
            uint64 mstatus = mi.readMstatus();

            // The SPIE bit indicates whether supervisor interrupts were enabled prior
            // to trapping into supervisor mode. When a trap is taken into supervisor
            // mode, SPIE is set to SIE, and SIE is set to 0. When an SRET instruction
            // is executed, SIE is set to SPIE, then SPIE is set to 1.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 19.
            mstatus = (mstatus & ~RiscVConstants.getMstatusSpieMask()) | (((mstatus >> RiscVConstants.getPrvS()) & 1) << RiscVConstants.getMstatusSpieShift());

            // The SPP bit indicates the privilege level at which a hart was executing
            // before entering supervisor mode. When a trap is taken, SPP is set to 0
            // if the trap originated from user mode, or 1 otherwise.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 49.
            mstatus = (mstatus & ~RiscVConstants.getMstatusSppMask()) | (priv << RiscVConstants.getMstatusSppShift());

            // The SIE bit enables or disables all interrupts in supervisor mode.
            // When SIE is clear, interrupts are not taken while in supervisor mode.
            // When the hart is running in user-mode, the value in SIE is ignored, and
            // supervisor-level interrupts are enabled. The supervisor can disable
            // indivdual interrupt sources using the sie register.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 50.
            mstatus &= ~RiscVConstants.getMstatusSieMask();

            mi.writeMstatus(mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.getPrvS()) {
                mi.setPriv(RiscVConstants.getPrvS());
            }
            // SVEC - Supervisor Trap Vector Base Address Register
            mi.writePc(mi.readStvec());
        } else {
            // is in M mode
            mi.writeMcause(cause);
            mi.writeMepc(mi.readPc());
            mi.writeMtval(tval);
            uint64 mstatus = mi.readMstatus();

            mstatus = (mstatus & ~RiscVConstants.getMstatusMpieMask()) | (((mstatus >> RiscVConstants.getPrvM()) & 1) << RiscVConstants.getMstatusMpieShift());
            mstatus = (mstatus & ~RiscVConstants.getMstatusMppMask()) | (priv << RiscVConstants.getMstatusMppShift());

            mstatus &= ~RiscVConstants.getMstatusMieMask();
            mi.writeMstatus(mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.getPrvM()) {
                mi.setPriv(RiscVConstants.getPrvM());
            }
            mi.writePc(mi.readMtvec());
        }
    }

    function getMcauseInsnAddressMisaligned() public pure returns(uint64) {return 0x0;}
    function getMcauseInsnAccessFault() public pure returns(uint64) {return 0x1;}
    function getMcauseIllegalInsn() public pure returns(uint64) {return 0x2;}
    function getMcauseBreakpoint() public pure returns(uint64) {return 0x3;}
    function getMcauseLoadAddressMisaligned() public pure returns(uint64) {return 0x4;}
    function getMcauseLoadAccessFault() public pure returns(uint64) {return 0x5;}
    function getMcauseStoreAmoAddressMisaligned () public pure returns(uint64) {return 0x6;}
    function getMcauseStoreAmoAccessFault() public pure returns(uint64) {return 0x7;}
    function getMcauseEcallBase() public pure returns(uint64) {return 0x8;}
    function getMcauseFetchPageFault() public pure returns(uint64) {return 0xc;}
    function getMcauseLoadPageFault() public pure returns(uint64) {return 0xd;}
    function getMcauseStoreAmoPageFault() public pure returns(uint64) {return 0xf;}

    function getMcauseInterruptFlag() public pure returns(uint64) {return uint64(1) << uint64(RiscVConstants.getXlen() - 1);}

}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./VirtualMemory.sol";
import "./MemoryInteractor.sol";
import "./CSRExecute.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";
import "./RiscVInstructions/S_Instructions.sol";
import "./RiscVInstructions/StandAloneInstructions.sol";
import "./RiscVInstructions/AtomicInstructions.sol";
import "./RiscVInstructions/EnvTrapIntInstructions.sol";
import {Exceptions} from "./Exceptions.sol";

/// @title Execute
/// @author Felipe Argento
/// @notice Finds instructions and execute them or delegate their execution to another library
library Execute {
    uint256 constant ARITH_IMM_GROUP = 0;
    uint256 constant ARITH_IMM_GROUP_32 = 1;

    uint256 constant ARITH_GROUP = 0;
    uint256 constant ARITH_GROUP_32 = 1;

    uint256 constant CSRRW_CODE = 0;
    uint256 constant CSRRWI_CODE = 1;

    uint256 constant CSRRS_CODE = 0;
    uint256 constant CSRRC_CODE = 1;

    uint256 constant CSRRSI_CODE = 0;
    uint256 constant CSRRCI_CODE = 1;


    /// @notice Finds associated instruction and execute it.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeInsn(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        // Finds instruction associated with that opcode
        // Sometimes the opcode fully defines the associated instruction, but most
        // of the times it only specifies which group it belongs to.
        // For example, an opcode of: 01100111 is always a LUI instruction but an
        // opcode of 1100011 might be BEQ, BNE, BLT etc
        // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104

        // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
        // R-Type, I-Type, S-Trype and U-Type
        // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
        uint32 opcode = RiscVDecoder.insnOpcode(insn);

        if (opcode < 0x002f) {
            if (opcode < 0x0017) {
                if (opcode == 0x0003) {
                    return loadFunct3(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x000f) {
                    return fenceGroup(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x0013) {
                    return executeArithmeticImmediate(
                        mi,
                        insn,
                        pc,
                        ARITH_IMM_GROUP
                    );
                }
            } else if (opcode > 0x0017) {
                if (opcode == 0x001b) {
                    return executeArithmeticImmediate(
                        mi,
                        insn,
                        pc,
                        ARITH_IMM_GROUP_32
                    );
                } else if (opcode == 0x0023) {
                    return storeFunct3(
                        mi,
                        insn,
                        pc
                    );
                }
            } else if (opcode == 0x0017) {
                StandAloneInstructions.executeAuipc(
                    mi,
                    insn,
                    pc
                );
                return advanceToNextInsn(mi,  pc);
            }
        } else if (opcode > 0x002f) {
            if (opcode < 0x0063) {
                if (opcode == 0x0033) {
                    return executeArithmetic(
                        mi,
                        insn,
                        pc,
                        ARITH_GROUP
                    );
                } else if (opcode == 0x003b) {
                    return executeArithmetic(
                        mi,
                        insn,
                        pc,
                        ARITH_GROUP_32
                    );
                } else if (opcode == 0x0037) {
                    StandAloneInstructions.executeLui(
                        mi,
                        insn
                    );
                    return advanceToNextInsn(mi,  pc);
                }
            } else if (opcode > 0x0063) {
                if (opcode == 0x0067) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJalr(
                        mi,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi,  newPc);
                    } else {
                        return raiseMisalignedFetchException(mi,  newPc);
                    }
                } else if (opcode == 0x0073) {
                    return csrEnvTrapIntMmFunct3(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x006f) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJal(
                        mi,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi,  newPc);
                    } else {
                        return raiseMisalignedFetchException(mi,  newPc);
                    }
                }
            } else if (opcode == 0x0063) {
                return executeBranch(
                    mi,
                    insn,
                    pc
                );
            }
        } else if (opcode == 0x002f) {
            return atomicFunct3Funct5(
                mi,
                insn,
                pc
            );
        }
        return raiseIllegalInsnException(mi,  insn);
    }

    /// @notice Finds and execute Arithmetic Immediate instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeArithmeticImmediate(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint256 immGroup
    )
    public returns (executeStatus)
    {
        uint32 rd = RiscVDecoder.insnRd(insn);
        uint64 arithImmResult;
        bool insnValid;

        if (rd != 0) {
            if (immGroup == ARITH_IMM_GROUP) {
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediateFunct3(mi,  insn);
            } else {
                //immGroup == ARITH_IMM_GROUP_32
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediate32Funct3(mi,  insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi,  insn);
            }

            mi.writeX(rd, arithImmResult);
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Arithmetic instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeArithmetic(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint256 groupCode
    )
    public returns (executeStatus)
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            uint64 arithResult = 0;
            bool insnValid = false;

            if (groupCode == ARITH_GROUP) {
                (arithResult, insnValid) = ArithmeticInstructions.arithmeticFunct3Funct7(mi,  insn);
            } else {
                // groupCode == arith_32Group
                (arithResult, insnValid) = ArithmeticInstructions.arithmetic32Funct3Funct7(mi,  insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi,  insn);
            }
            mi.writeX( rd, arithResult);
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Branch instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeBranch(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc)
    public returns (executeStatus)
    {

        (bool branchValuated, bool insnValid) = BranchInstructions.branchFunct3(mi,  insn);

        if (!insnValid) {
            return raiseIllegalInsnException(mi,  insn);
        }

        if (branchValuated) {
            uint64 newPc = uint64(int64(pc) + int64(RiscVDecoder.insnBImm(insn)));
            if ((newPc & 3) != 0) {
                return raiseMisalignedFetchException(mi,  newPc);
            }else {
                return executeJump(mi,  newPc);
            }
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Load instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
   function executeLoad(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint64 wordSize,
        bool isSigned
    )
    public returns (executeStatus)
    {
        uint64 vaddr = mi.readX( RiscVDecoder.insnRs1(insn));
        int32 imm = RiscVDecoder.insnIImm(insn);
        uint32 rd = RiscVDecoder.insnRd(insn);

        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr + uint64(imm)
        );

        if (succ) {
            if (isSigned) {
                val = BitsManipulationLibrary.uint64SignExtension(val, wordSize);
            }

            if (rd != 0) {
                mi.writeX(rd, val);
            }

            return advanceToNextInsn(mi, pc);

        } else {
            //return advanceToRaisedException()
            return executeStatus.retired;
        }
    }

    /// @notice Execute S_fence_VMA instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeSfenceVma(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if ((insn & 0xFE007FFF) == 0x12000073) {
            uint64 priv = mi.readIflagsPrv();
            uint64 mstatus = mi.readMstatus();

            if (priv == RiscVConstants.getPrvU() || (priv == RiscVConstants.getPrvS() && ((mstatus & RiscVConstants.getMstatusTvmMask() != 0)))) {
                return raiseIllegalInsnException(mi, insn);
            }

            return advanceToNextInsn(mi, pc);
        } else {
            return raiseIllegalInsnException(mi, insn);
        }
    }

    /// @notice Execute jump - writes a new pc
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param newPc pc to be written
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeJump(MemoryInteractor mi, uint64 newPc)
    public returns (executeStatus)
    {
        mi.writePc( newPc);
        return executeStatus.retired;
    }

    /// @notice Raises Misaligned Fetch Exception
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc current pc
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function raiseMisalignedFetchException(MemoryInteractor mi, uint64 pc)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseInsnAddressMisaligned(),
            pc
        );
        return executeStatus.retired;
    }

    /// @notice Raises Illegal Instruction Exception
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn instruction that was deemed illegal
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function raiseIllegalInsnException(MemoryInteractor mi, uint32 insn)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseIllegalInsn(),
            insn
        );
        return executeStatus.illegal;
    }

    /// @notice Advances to next instruction by increasing pc
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc current pc
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function advanceToNextInsn(MemoryInteractor mi, uint64 pc)
    public returns (executeStatus)
    {
        mi.writePc( pc + 4);
        return executeStatus.retired;
    }

    /// @notice Given a fence funct3 insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for fence funct3 field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function fenceGroup(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns(executeStatus)
    {
        if (insn == 0x0000100f) {
            /*insn == 0x0000*/
            //return "FENCE";
            //really do nothing
            return advanceToNextInsn(mi, pc);
        } else if (insn & 0xf00fff80 != 0) {
            /*insn == 0x0001*/
            return raiseIllegalInsnException(mi, insn);
        }
        //return "FENCE_I";
        //really do nothing
        return advanceToNextInsn(mi, pc);
    }

    /// @notice Given csr env trap int mm funct3 insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for fence funct3 field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function csrEnvTrapIntMmFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return envTrapIntGroup(
                    mi,
                    insn,
                    pc
                );
            } else if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "CSRRS";
                if (CSRExecute.executeCsrSC(
                    mi,
                    insn,
                    CSRRS_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                //return "CSRRW";
                if (CSRExecute.executeCsrRW(
                    mi,
                    insn,
                    CSRRW_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            }
        } else if (funct3 > 0x0003) {
            if (funct3 == 0x0005) {
                /*funct3 == 0x0005*/
                //return "CSRRWI";
                if (CSRExecute.executeCsrRW(
                    mi,
                    insn,
                    CSRRWI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                //return "CSRRCI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    insn,
                    CSRRCI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                //return "CSRRSI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    insn,
                    CSRRSI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            }
        } else if (funct3 == 0x0003) {
            /*funct3 == 0x0003*/
            //return "CSRRC";
            if (CSRExecute.executeCsrSC(
                mi,
                insn,
                CSRRC_CODE
            )) {
                return advanceToNextInsn(mi, pc);
            } else {
                return raiseIllegalInsnException(mi, insn);
            }
        }
        return raiseIllegalInsnException(mi, insn);
    }

    /// @notice Given a store funct3 group insn, finds the function associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for store funct3 field
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function storeFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 == 0x0000) {
            /*funct3 == 0x0000*/
            //return "SB";
            return S_Instructions.sb(
                mi,
                insn
            ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
        } else if (funct3 > 0x0001) {
            if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "SW";
                return S_Instructions.sw(
                    mi,
                    insn
                ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
            } else if (funct3 == 0x0003) {
                /*funct3 == 0x0003*/
                //return "SD";
                return S_Instructions.sd(
                    mi,
                    insn
                ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
            }
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SH";
            return S_Instructions.sh(
                mi,
                insn
            ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
        }
        return raiseIllegalInsnException(mi, insn);
    }

    /// @notice Given a env trap int group insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn insn for env trap int group field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function envTrapIntGroup(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if (insn < 0x10200073) {
            if (insn == 0x0073) {
                EnvTrapIntInstructions.executeECALL(
                    mi
                );
                return executeStatus.retired;
            } else if (insn == 0x200073) {
                // No U-Mode traps
                raiseIllegalInsnException(mi, insn);
            } else if (insn == 0x100073) {
                EnvTrapIntInstructions.executeEBREAK(
                    mi
                );
                return executeStatus.retired;
            }
        } else if (insn > 0x10200073) {
            if (insn == 0x10500073) {
                if (!EnvTrapIntInstructions.executeWFI(
                    mi
                )) {
                    return raiseIllegalInsnException(mi, insn);
                }
                return advanceToNextInsn(mi, pc);
            } else if (insn == 0x30200073) {
                if (!EnvTrapIntInstructions.executeMRET(
                    mi
                )) {
                    return raiseIllegalInsnException(mi, insn);
                }
                return executeStatus.retired;
            }
        } else if (insn == 0x10200073) {
            if (!EnvTrapIntInstructions.executeSRET(
                mi
                )
               ) {
                return raiseIllegalInsnException(mi, insn);
            }
            return executeStatus.retired;
        }
        return executeSfenceVma(
            mi,
            insn,
            pc
        );
    }

    /// @notice Given a load funct3 group instruction, finds the function
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for load funct3 field
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function loadFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                //return "LB";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    8,
                    true
                );

            } else if (funct3 == 0x0002) {
                //return "LW";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    32,
                    true
                );
            } else if (funct3 == 0x0001) {
                //return "LH";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    16,
                    true
                );
            }
        } else if (funct3 > 0x0003) {
            if (funct3 == 0x0004) {
                //return "LBU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    8,
                    false
                );
            } else if (funct3 == 0x0006) {
                //return "LWU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    32,
                    false
                );
            } else if (funct3 == 0x0005) {
                //return "LHU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    16,
                    false
                );
            }
        } else if (funct3 == 0x0003) {
            //return "LD";
            return executeLoad(
                mi,
                insn,
                pc,
                64,
                true
            );
        }
        return raiseIllegalInsnException(mi, insn);
    }

    function atomicFunct3Funct5(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3Funct5 = RiscVDecoder.insnFunct3Funct5(insn);
        bool atomSucc;
        // TO-DO: transform in binary search for performance
        if (funct3Funct5 == 0x42) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    insn,
                    32
                );
            } else {
                return raiseIllegalInsnException(mi, insn);
            }
        } else if (funct3Funct5 == 0x43) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                insn,
                32
            );
        } else if (funct3Funct5 == 0x41) {
            atomSucc = AtomicInstructions.executeAMOSWAPW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x40) {
            atomSucc = AtomicInstructions.executeAMOADDW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x44) {
            atomSucc = AtomicInstructions.executeAMOXORW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x4c) {
            atomSucc = AtomicInstructions.executeAMOANDW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x48) {
            atomSucc = AtomicInstructions.executeAMOORW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x50) {
            atomSucc = AtomicInstructions.executeAMOMINW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x54) {
            atomSucc = AtomicInstructions.executeAMOMAXW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x58) {
            atomSucc = AtomicInstructions.executeAMOMINUW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x5c) {
            atomSucc = AtomicInstructions.executeAMOMAXUW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x62) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    insn,
                    64
                );
            }
        } else if (funct3Funct5 == 0x63) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                insn,
                64
            );
        } else if (funct3Funct5 == 0x61) {
            atomSucc = AtomicInstructions.executeAMOSWAPD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x60) {
            atomSucc = AtomicInstructions.executeAMOADDD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x64) {
            atomSucc = AtomicInstructions.executeAMOXORD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x6c) {
            atomSucc = AtomicInstructions.executeAMOANDD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x68) {
            atomSucc = AtomicInstructions.executeAMOORD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x70) {
            atomSucc = AtomicInstructions.executeAMOMIND(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x74) {
            atomSucc = AtomicInstructions.executeAMOMAXD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x78) {
            atomSucc = AtomicInstructions.executeAMOMINUD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x7c) {
            atomSucc = AtomicInstructions.executeAMOMAXUD(
                mi,
                insn
            );
        }
        if (atomSucc) {
            return advanceToNextInsn(mi, pc);
        } else {
            return executeStatus.retired;
        }
    }

    enum executeStatus {
        illegal, // Exception was raised
        retired // Instruction retired - having raised or not an exception
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import "./PMA.sol";
import "./VirtualMemory.sol";
import "./Exceptions.sol";

/// @title Fetch
/// @author Felipe Argento
/// @notice Implements main CSR read and write logic
library Fetch {

    /// @notice Finds and loads next insn.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @return Returns fetchStatus.success if load was successful, excpetion if not.
    /// @return Returns instructions
    /// @return Returns pc
    function fetchInsn(MemoryInteractor mi) public returns (fetchStatus, uint32, uint64) {
        bool translateBool;
        uint64 paddr;

        //readPc
        uint64 pc = mi.readPc();
        (translateBool, paddr) = VirtualMemory.translateVirtualAddress(
            mi,
            pc,
            RiscVConstants.getPteXwrCodeShift()
        );

        //translateVirtualAddress failed
        if (!translateBool) {
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseFetchPageFault(),
                pc
            );
            //returns fetchException and returns zero as insn and pc
            return (fetchStatus.exception, 0, 0);
        }

        // Finds the range in memory in which the physical address is located
        // Returns start and length words from pma
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);

        // M flag defines if the pma range is in memory
        // X flag defines if the pma is executable
        // If the pma is not memory or not executable - this is a pma violation
        // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartX(pmaStart)) {
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseInsnAccessFault(),
                paddr
            );
            return (fetchStatus.exception, 0, 0);
        }

        uint32 insn = 0;

        // Check if instruction is on first 32 bits or last 32 bits
        if ((paddr & 7) == 0) {
            insn = uint32(mi.memoryRead(paddr));
        } else {
            // If not aligned, read at the last addr and shift to get the correct insn
            uint64 fullMemory = mi.memoryRead(paddr - 4);
            insn = uint32(fullMemory >> 32);
        }

        return (fetchStatus.success, insn, pc);
    }

    enum fetchStatus {
        exception, //failed: exception raised
        success
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// @title HTIF
pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";


/// @title HTIF
/// @author Felipe Argento
/// @notice Host-Target-Interface (HTIF) mediates communcation with external world.
/// @dev Its active addresses are 0x40000000(tohost) and 0x40000008(from host)
/// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library HTIF {

    uint64 constant HTIF_TOHOST_ADDR_CONST = 0x40008000;
    uint64 constant HTIF_FROMHOST_ADDR_CONST = 0x40008008;
    uint64 constant HTIF_IYIELD_ADDR_CONST = 0x40008020;

    // [c++] enum HTIF_devices
    uint64 constant HTIF_DEVICE_HALT = 0;        //< Used to halt machine
    uint64 constant HTIF_DEVICE_CONSOLE = 1;     //< Used for console input and output
    uint64 constant HTIF_DEVICE_YIELD = 2;       //< Used to yield control back to host

    // [c++] enum HTIF_commands
    uint64 constant HTIF_HALT_HALT = 0;
    uint64 constant HTIF_CONSOLE_GETCHAR = 0;
    uint64 constant HTIF_CONSOLE_PUTCHAR = 1;
    uint64 constant HTIF_YIELD_PROGRESS = 0;
    uint64 constant HTIF_YIELD_ROLLUP = 1;

    /// @notice reads htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param addr address to read from
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if read was successfull
    /// @return uint64 pval
    function htifRead(
        MemoryInteractor mi,
        uint64 addr,
        uint64 wordSize
    )
    public returns (bool, uint64)
    {
        // HTIF reads must be aligned and 8 bytes
        if (wordSize != 64 || (addr & 7) != 0) {
            return (false, 0);
        }

        if (addr == HTIF_TOHOST_ADDR_CONST) {
            return (true, mi.readHtifTohost());
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            return (true, mi.readHtifFromhost());
        } else {
            return (false, 0);
        }
    }

    /// @notice write htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param addr address to read from
    /// @param val value to be written
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if write was successfull
    function htifWrite(
        MemoryInteractor mi,
        uint64 addr,
        uint64 val,
        uint64 wordSize
    )
    public returns (bool)
    {
        // HTIF writes must be aligned and 8 bytes
        if (wordSize != 64 || (addr & 7) != 0) {
            return false;
        }
        if (addr == HTIF_TOHOST_ADDR_CONST) {
            return htifWriteTohost(mi, val);
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            mi.writeHtifFromhost(val);
            return true;
        } else {
            return false;
        }
    }

    // Internal functions
    function htifWriteFromhost(MemoryInteractor mi, uint64 val)
    internal returns (bool)
    {
        mi.writeHtifFromhost(val);
        // TO-DO: check if h is interactive? reset from host? pollConsole?
        return true;
    }

    function htifWriteTohost(MemoryInteractor mi, uint64 tohost)
    internal returns (bool)
    {
        uint32 device = uint32(tohost >> 56);
        uint32 cmd = uint32((tohost >> 48) & 0xff);
        uint64 payload = uint32((tohost & (~(uint256(1) >> 16))));

        mi.writeHtifTohost(tohost);

        if (device == HTIF_DEVICE_HALT) {
            return htifHalt(
                mi,
                cmd,
                payload);
        } else if (device == HTIF_DEVICE_CONSOLE) {
            return htifConsole(
                mi,
                cmd,
                payload);
        } else if (device == HTIF_DEVICE_YIELD) {
            return htifYield(
                mi,
                cmd,
                payload);
        } else {
            return true;
        }
    }

    function htifHalt(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {
        if (cmd == HTIF_HALT_HALT && ((payload & 1) == 1) ) {
            //set iflags to halted
            mi.setIflagsH(true);
        }
        return true;
    }

    function htifYield(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {
        // If yield command is enabled, yield
        if ((mi.readHtifIYield() >> cmd) & 1 == 1) {
            mi.setIflagsY(true);
            mi.writeHtifFromhost((HTIF_DEVICE_YIELD << 56) | cmd << 48);
        }

        return true;
    }

    function htifConsole(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {
        if (cmd == HTIF_CONSOLE_PUTCHAR) {
            htifPutchar(mi);
        } else if (cmd == HTIF_CONSOLE_GETCHAR) {
            htifGetchar(mi);
        } else {
            // Unknown HTIF console commands are silently ignored
            return true;
        }
    }

    function htifPutchar(MemoryInteractor mi) internal
    returns (bool)
    {
        // TO-DO: what to do in the blockchain? Generate event?
        mi.writeHtifFromhost((HTIF_DEVICE_CONSOLE << 56) | uint64(HTIF_CONSOLE_PUTCHAR) << 48);
        return true;
    }

    function htifGetchar(MemoryInteractor mi) internal
    returns (bool)
    {
        mi.writeHtifFromhost((HTIF_DEVICE_CONSOLE << 56) | uint64(HTIF_CONSOLE_GETCHAR) << 48);
        return true;
    }

    // getters
    function getHtifToHostAddr() public pure returns (uint64) {
        return HTIF_TOHOST_ADDR_CONST;
    }

    function getHtifFromHostAddr() public pure returns (uint64) {
        return HTIF_FROMHOST_ADDR_CONST;
    }

    function getHtifIYieldAddr() public pure returns (uint64) {
        return HTIF_IYIELD_ADDR_CONST;
    }

}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";
import "./Exceptions.sol";

/// @title Interrupts
/// @author Felipe Argento
/// @notice Implements interrupt behaviour
library Interrupts {

    /// @notice Raises an interrupt if any are enabled and pending.
    /// @param mi Memory Interactor with which Step function is interacting.
    function raiseInterruptIfAny(MemoryInteractor mi) public {
        uint32 mask = getPendingIrqMask(mi);
        if (mask != 0) {
            uint64 irqNum = ilog2(mask);
            Exceptions.raiseException(
                mi,
                irqNum | Exceptions.getMcauseInterruptFlag(),
                0
            );
        }
    }

    // Machine Interrupt Registers: mip and mie.
    // mip register contains information on pending interrupts.
    // mie register contains the interrupt enabled bits.
    // Reference: riscv-privileged-v1.10 - section 3.1.14 - page 28.
    function getPendingIrqMask(MemoryInteractor mi) internal returns (uint32) {
        uint64 mip = mi.readMip();
        uint64 mie = mi.readMie();

        uint32 pendingInts = uint32(mip & mie);
        // if there are no pending interrupts, return 0.
        if (pendingInts == 0) {
            return 0;
        }
        uint64 mstatus = 0;
        uint32 enabledInts = 0;

        // Read privilege level on iflags register.
        // The privilege level is represented by bits 2 and 3 on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 priv = mi.readIflagsPrv();

        if (priv == RiscVConstants.getPrvM()) {
            // MSTATUS is the Machine Status Register - it controls the current
            // operating state. The MIE is an interrupt-enable bit for machine mode.
            // MIE for 64bit is stored on location 3 - according to:
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            mstatus = mi.readMstatus();

            if ((mstatus & RiscVConstants.getMstatusMieMask()) != 0) {
                enabledInts = uint32(~mi.readMideleg());
            }
        } else if (priv == RiscVConstants.getPrvS()) {
            // MIDELEG: Machine trap delegation register
            // mideleg defines if a interrupt can be proccessed by a lower privilege
            // level. If mideleg bit is set, the trap will delegated to the S-Mode.
            // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
            mstatus = mi.readMstatus();
            uint64 mideleg = mi.readMideleg();
            enabledInts = uint32(~mideleg);

            // SIE: is the register contaning interrupt enabled bits for supervisor mode.
            // It is located on the first bit of mstatus register (RV64).
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            if ((mstatus & RiscVConstants.getMstatusSieMask()) != 0) {
                //TO-DO: make sure this is the correct cast
                enabledInts = enabledInts | uint32(mideleg);
            }
        } else {
            enabledInts = uint32(-1);
        }
        return pendingInts & enabledInts;
    }

    //TO-DO: optmize log2 function
    function ilog2(uint32 v) public pure returns(uint64) {
        //cpp emulator code:
        //return 31 - _BuiltinClz(v)

        uint leading = 32;
        while (v != 0) {
            v = v >> 1;
            leading--;
        }
        return uint64(31 - leading);
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title MemoryInteractor.sol
pragma solidity ^0.7.0;

import "./ShadowAddresses.sol";
import "./HTIF.sol";
import "./CLINT.sol";
import "./RiscVConstants.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";

/// @title MemoryInteractor
/// @author Felipe Argento
/// @notice Bridge between Memory Manager and Step
/// @dev Every read performed by mi.memoryRead or mi.write should be followed by an
/// @dev endianess swap from little endian to big endian. This is the case because
/// @dev EVM is big endian but RiscV is little endian.
/// @dev Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
/// @dev Reference: Ethereum yellowpaper - Version 69351d5
/// @dev    Appendix H. Virtual Machine Specification
contract MemoryInteractor {

    uint256 rwIndex; // read write index
    uint64[] rwPositions; // read write positions
    bytes8[] rwValues; // read write values
    bool[] isRead; // true if access is read, false if its write

    function initializeMemory(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) virtual public
    {
        require(_rwPositions.length == _rwValues.length, "Read/write arrays are not the same size");
        require(_rwPositions.length == _isRead.length, "Read/write arrays are not the same size");
        rwIndex = 0;
        rwPositions = _rwPositions;
        rwValues = _rwValues;
        isRead = _isRead;
    }

    function getRWIndex() public view returns (uint256) {
        return rwIndex;
    }
    // Reads
    function readX(uint64 registerIndex) public returns (uint64) {
        return memoryRead(registerIndex * 8);
    }

    function readClintMtimecmp() public returns (uint64) {
        return memoryRead(CLINT.getClintMtimecmp());
    }

    function readHtifFromhost() public returns (uint64) {
        return memoryRead(HTIF.getHtifFromHostAddr());
    }

    function readHtifTohost() public returns (uint64) {
        return memoryRead(HTIF.getHtifToHostAddr());
    }

    function readHtifIYield() public returns (uint64) {
        return memoryRead(HTIF.getHtifIYieldAddr());
    }

    function readMie() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMie());
    }

    function readMcause() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcause());
    }

    function readMinstret() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMinstret());
    }

    function readMcycle() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcycle());
    }

    function readMcounteren() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcounteren());
    }

    function readMepc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMepc());
    }

    function readMip() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMip());
    }

    function readMtval() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMtval());
    }

    function readMvendorid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMvendorid());
    }

    function readMarchid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMarchid());
    }

    function readMimpid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMimpid());
    }

    function readMscratch() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMscratch());
    }

    function readSatp() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSatp());
    }

    function readScause() public returns (uint64) {
        return memoryRead(ShadowAddresses.getScause());
    }

    function readSepc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSepc());
    }

    function readScounteren() public returns (uint64) {
        return memoryRead(ShadowAddresses.getScounteren());
    }

    function readStval() public returns (uint64) {
        return memoryRead(ShadowAddresses.getStval());
    }

    function readMideleg() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMideleg());
    }

    function readMedeleg() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMedeleg());
    }

    function readMtvec() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMtvec());
    }

    function readIlrsc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getIlrsc());
    }

    function readPc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getPc());
    }

    function readSscratch() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSscratch());
    }

    function readStvec() public returns (uint64) {
        return memoryRead(ShadowAddresses.getStvec());
    }

    function readMstatus() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMstatus());
    }

    function readMisa() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMisa());
    }

    function readIflags() public returns (uint64) {
        return memoryRead(ShadowAddresses.getIflags());
    }

    function readIflagsPrv() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsPrvMask()) >> RiscVConstants.getIflagsPrvShift();
    }

    function readIflagsH() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsHMask()) >> RiscVConstants.getIflagsHShift();
    }

    function readIflagsY() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsYMask()) >> RiscVConstants.getIflagsYShift();
    }

    function readMemory(uint64 paddr, uint64 wordSize) public returns (uint64) {
        // get relative address from unaligned paddr
        uint64 closestStartAddr = paddr & uint64(~7);
        uint64 relAddr = paddr - closestStartAddr;

        // value just like its on MM, without endianess swap
        uint64 val = pureMemoryRead(closestStartAddr);

        // mask to clean a piece of the value that was on memory
        uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);
        val = BitsManipulationLibrary.uint64SwapEndian(val & valueMask) >> relAddr*8;
        return val;
    }

    // Sets
    function setPriv(uint64 newPriv) public {
        writeIflagsPrv(newPriv);
        writeIlrsc(uint64(-1)); // invalidate reserved address
    }

    function setIflagsI(bool idle) public {
        uint64 iflags = readIflags();

        if (idle) {
            iflags = (iflags | RiscVConstants.getIflagsIMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsIMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function setMip(uint64 mask) public {
        uint64 mip = readMip();
        mip |= mask;

        writeMip(mip);

        setIflagsI(false);
    }

    function resetMip(uint64 mask) public {
        uint64 mip = readMip();
        mip &= ~mask;
        writeMip(mip);
    }

    // Writes
    function writeMie(uint64 value) public {
        memoryWrite(ShadowAddresses.getMie(), value);
    }

    function writeStvec(uint64 value) public {
        memoryWrite(ShadowAddresses.getStvec(), value);
    }

    function writeSscratch(uint64 value) public {
        memoryWrite(ShadowAddresses.getSscratch(), value);
    }

    function writeMip(uint64 value) public {
        memoryWrite(ShadowAddresses.getMip(), value);
    }

    function writeSatp(uint64 value) public {
        memoryWrite(ShadowAddresses.getSatp(), value);
    }

    function writeMedeleg(uint64 value) public {
        memoryWrite(ShadowAddresses.getMedeleg(), value);
    }

    function writeMideleg(uint64 value) public {
        memoryWrite(ShadowAddresses.getMideleg(), value);
    }

    function writeMtvec(uint64 value) public {
        memoryWrite(ShadowAddresses.getMtvec(), value);
    }

    function writeMcounteren(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcounteren(), value);
    }

    function writeMcycle(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcycle(), value);
    }

    function writeMinstret(uint64 value) public {
        memoryWrite(ShadowAddresses.getMinstret(), value);
    }

    function writeMscratch(uint64 value) public {
        memoryWrite(ShadowAddresses.getMscratch(), value);
    }

    function writeScounteren(uint64 value) public {
        memoryWrite(ShadowAddresses.getScounteren(), value);
    }

    function writeScause(uint64 value) public {
        memoryWrite(ShadowAddresses.getScause(), value);
    }

    function writeSepc(uint64 value) public {
        memoryWrite(ShadowAddresses.getSepc(), value);
    }

    function writeStval(uint64 value) public {
        memoryWrite(ShadowAddresses.getStval(), value);
    }

    function writeMstatus(uint64 value) public {
        memoryWrite(ShadowAddresses.getMstatus(), value);
    }

    function writeMcause(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcause(), value);
    }

    function writeMepc(uint64 value) public {
        memoryWrite(ShadowAddresses.getMepc(), value);
    }

    function writeMtval(uint64 value) public {
        memoryWrite(ShadowAddresses.getMtval(), value);
    }

    function writePc(uint64 value) public {
        memoryWrite(ShadowAddresses.getPc(), value);
    }

    function writeIlrsc(uint64 value) public {
        memoryWrite(ShadowAddresses.getIlrsc(), value);
    }

    function writeClintMtimecmp(uint64 value) public {
        memoryWrite(CLINT.getClintMtimecmp(), value);
    }

    function writeHtifFromhost(uint64 value) public {
        memoryWrite(HTIF.getHtifFromHostAddr(), value);
    }

    function writeHtifTohost(uint64 value) public {
        memoryWrite(HTIF.getHtifToHostAddr(), value);
    }

    function setIflagsH(bool halt) public {
        uint64 iflags = readIflags();

        if (halt) {
            iflags = (iflags | RiscVConstants.getIflagsHMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsHMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function setIflagsY(bool isYield) public {
        uint64 iflags = readIflags();

        if (isYield) {
            iflags = (iflags | RiscVConstants.getIflagsYMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsYMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function writeIflagsPrv(uint64 newPriv) public {
        uint64 iflags = readIflags();

        // Clears bits 3 and 2 of iflags and use or to set new value
        iflags = (iflags & (~RiscVConstants.getIflagsPrvMask())) | (newPriv << RiscVConstants.getIflagsPrvShift());

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function writeMemory(
        uint64 paddr,
        uint64 value,
        uint64 wordSize
    ) public
    {
        uint64 numberOfBytes = wordSize / 8;

        if (numberOfBytes == 8) {
            memoryWrite(paddr, value);
        } else {
            // get relative address from unaligned paddr
            uint64 closestStartAddr = paddr & uint64(~7);
            uint64 relAddr = paddr - closestStartAddr;

            // oldvalue just like its on MM, without endianess swap
            uint64 oldVal = pureMemoryRead(closestStartAddr);

            // Mask to clean a piece of the value that was on memory
            uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);

            // value is big endian, need to swap before further operation
            uint64 valueSwap = BitsManipulationLibrary.uint64SwapEndian(value & ((uint64(2) ** wordSize) - 1));

            uint64 newvalue = ((oldVal & ~valueMask) | (valueSwap >> relAddr*8));

            newvalue = BitsManipulationLibrary.uint64SwapEndian(newvalue);
            memoryWrite(closestStartAddr, newvalue);
        }
    }

    function writeX(uint64 registerindex, uint64 value) public {
        memoryWrite(registerindex * 8, value);
    }

    // Internal functions
    function memoryRead(uint64 _readAddress) public returns (uint64) {
        return BitsManipulationLibrary.uint64SwapEndian(
            uint64(memoryAccessManager(_readAddress, true))
        );
    }

    function memoryWrite(uint64 _writeAddress, uint64 _value) virtual public {
        bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(_value));
        require(memoryAccessManager(_writeAddress, false) == bytesvalue, "Written value does not match");
    }

    // Memory Write without endianess swap
    function pureMemoryWrite(uint64 _writeAddress, uint64 _value) virtual internal {
        require(
            memoryAccessManager(_writeAddress, false) == bytes8(_value),
            "Written value does not match"
        );
    }

    // Memory Read without endianess swap
    function pureMemoryRead(uint64 _readAddress) internal returns (uint64) {
        return uint64(memoryAccessManager(_readAddress, true));
    }

   // Private functions

    // takes care of read/write access
    function memoryAccessManager(uint64 _address, bool _accessIsRead) internal virtual returns (bytes8) {
        require(isRead[rwIndex] == _accessIsRead, "Access was not the correct type");

        uint64 position = rwPositions[rwIndex];
        bytes8 value = rwValues[rwIndex];
        rwIndex++;

        require((position & 7) == 0, "Position is not aligned");
        require(position == _address, "Position and read address do not match");

        return value;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";

/// @title PMA
/// @author Felipe Argento
/// @notice Implements PMA behaviour
library PMA {

    uint64 constant MEMORY_ID = 0; //< DID for memory
    uint64 constant SHADOW_ID = 1; //< DID for shadow device
    uint64 constant DRIVE_ID = 2;  //< DID for drive device
    uint64 constant CLINT_ID = 3;  //< DID for CLINT device
    uint64 constant HTIF_ID = 4;   //< DID for HTIF device

    /// @notice Finds PMA that contains target physical address.
    /// @param mi Memory Interactor with which Step function is interacting.
    //  contains the logs for this Step execution.
    /// @param paddr Target physical address.
    /// @return start of pma if found. If not, returns (0)
    function findPmaEntry(MemoryInteractor mi, uint64 paddr) public returns (uint64) {
        // Hard coded ram address starts at 0x800
        // In total there are 32 PMAs from processor shadow to Flash disk 7.
        // PMA 0 - describes RAM and is hardcoded to address 0x800
        // PMA 16 - 23 describe flash devices 0-7
        // RAM start field is hardcoded to 0x800
        // Reference: The Core of Cartesi, v1.02 - Table 3.
        uint64 pmaAddress = 0x800;
        uint64 lastPma = 62; // 0 - 31 * 2 words

        for (uint64 i = 0; i <= lastPma; i += 2) {
            uint64 startWord = mi.memoryRead(pmaAddress + (i * 8));

            uint64 lengthWord = mi.memoryRead(pmaAddress + ((i * 8 + 8)));

            uint64 pmaStart = pmaGetStart(startWord);
            uint64 pmaLength = pmaGetLength(lengthWord);

            // TO-DO: fix overflow possibility
            if (paddr >= pmaStart && paddr <= (pmaStart + pmaLength)) {
                return startWord;
            }

            if (pmaLength == 0) {
                break;
            }
        }

        return 0;
    }

    // M bit defines if the range is memory
    // The flag is pmaEntry start's word first bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartM(uint64 start) public pure returns (bool) {
        return start & 1 == 1;
    }

    // X bit defines if the range is executable
    // The flag is pmaEntry start's word on position 5.
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartX(uint64 start) public pure returns (bool) {
        return (start >> 5) & 1 == 1;
    }

    // E bit defines if the range is excluded
    // The flag is pmaEntry start's word third bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartE(uint64 start) public pure returns (bool) {
        return (start >> 2) & 1 == 1;
    }

    // W bit defines write permission
    // The flag is pmaEntry start's word bit on position 4
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartW(uint64 start) public pure returns (bool) {
        return (start >> 4) & 1 == 1;
    }

    // R bit defines read permission
    // The flag is pmaEntry start's word bit on position 3
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartR(uint64 start) public pure returns (bool) {
        return (start >> 3) & 1 == 1;
    }

    function pmaIsCLINT(uint64 startWord) public pure returns (bool) {
        return pmaGetDID(startWord) == CLINT_ID;
    }

    function pmaIsHTIF(uint64 startWord) public pure returns (bool) {
        return pmaGetDID(startWord) == HTIF_ID;
    }

    // Both pmaStart and pmaLength have to be aligned to a 4KiB boundary.
    // So this leaves the lowest 12 bits for attributes. To find out the actual
    // start and length of the PMAs it is necessary to clean those attribute bits
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetStart(uint64 startWord) internal pure returns (uint64) {
        return startWord & 0xfffffffffffff000;
    }

    function pmaGetLength(uint64 lengthWord) internal pure returns (uint64) {
        return lengthWord & 0xfffffffffffff000;
    }

    // DID is encoded on bytes 8 - 11 of pma's start word.
    // It defines the devices id.
    // 0 for memory ranges
    // 1 for shadows
    // 1 for drive
    // 3 for CLINT
    // 4 for HTIF
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetDID(uint64 startWord) internal pure returns (uint64) {
        return (startWord >> 8) & 0x0F;
    }

}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title RealTimeClock
pragma solidity ^0.7.0;

/// @title RealTimeClock
/// @author Felipe Argento
/// @notice Real Time clock simulator
library RealTimeClock {
    uint64 constant RTC_FREQ_DIV = 100;
    
    /// @notice Converts from cycle count to time count
    /// @param cycle Cycle count
    /// @return Time count
    function rtcCycleToTime(uint64 cycle) public pure returns (uint64) {
        return cycle / RTC_FREQ_DIV;
    }

    /// @notice Converts from time count to cycle count
    /// @param  time Time count
    /// @return Cycle count
    function rtcTimeToCycle(uint64 time) public pure returns (uint64) {
        return time * RTC_FREQ_DIV;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

/// @title RiscVConstants
/// @author Felipe Argento
/// @notice Defines getters for important constants
library RiscVConstants {
    //iflags shifts
    function getIflagsHShift()  public pure returns(uint64) {return 0;}
    function getIflagsYShift()  public pure returns(uint64) {return 1;}
    function getIflagsIShift()  public pure returns(uint64) {return 2;}
    function getIflagsPrvShift()  public pure returns(uint64) {return 3;}

    //iflags masks
    function getIflagsHMask()  public pure returns(uint64) {return uint64(1) << getIflagsHShift();}
    function getIflagsYMask()  public pure returns(uint64) {return uint64(1) << getIflagsYShift();}
    function getIflagsIMask()  public pure returns(uint64) {return uint64(1) << getIflagsIShift();}
    function getIflagsPrvMask()  public pure returns(uint64) {return uint64(3) << getIflagsPrvShift();}

    //general purpose
    function getXlen() public pure returns(uint64) {return 64;}
    function getMxl()  public pure returns(uint64) {return 2;}

    //privilege levels
    function getPrvU() public pure returns(uint64) {return 0;}
    function getPrvS() public pure returns(uint64) {return 1;}
    function getPrvH() public pure returns(uint64) {return 2;}
    function getPrvM() public pure returns(uint64) {return 3;}

    //mstatus shifts
    function getMstatusUieShift()  public pure returns(uint64) {return 0;}
    function getMstatusSieShift()  public pure returns(uint64) {return 1;}
    function getMstatusHieShift()  public pure returns(uint64) {return 2;}
    function getMstatusMieShift()  public pure returns(uint64) {return 3;}
    function getMstatusUpieShift() public pure returns(uint64) {return 4;}
    function getMstatusSpieShift() public pure returns(uint64) {return 5;}
    function getMstatusMpieShift() public pure returns(uint64) {return 7;}
    function getMstatusSppShift()  public pure returns(uint64) {return 8;}
    function getMstatusMppShift()  public pure returns(uint64) {return 11;}
    function getMstatusFsShift()   public pure returns(uint64) {return 13;}

    function getMstatusXsShift()   public pure returns(uint64) {return 15;}
    function getMstatusMprvShift() public pure returns(uint64) {return 17;}
    function getMstatusSumShift()  public pure returns(uint64) {return 18;}
    function getMstatusMxrShift()  public pure returns(uint64) {return 19;}
    function getMstatusTvmShift()  public pure returns(uint64) {return 20;}
    function getMstatusTwShift()   public pure returns(uint64) {return 21;}
    function getMstatusTsrShift()  public pure returns(uint64) {return 22;}


    function getMstatusUxlShift()  public pure returns(uint64) {return 32;}
    function getMstatusSxlShift()  public pure returns(uint64) {return 34;}

    function getMstatusSdShift()   public pure returns(uint64) {return getXlen() - 1;}

    //mstatus masks
    function getMstatusUieMask()  public pure returns(uint64) {return (uint64(1) << getMstatusUieShift());}
    function getMstatusSieMask()  public pure returns(uint64) {return uint64(1) << getMstatusSieShift();}
    function getMstatusMieMask()  public pure returns(uint64) {return uint64(1) << getMstatusMieShift();}
    function getMstatusUpieMask() public pure returns(uint64) {return uint64(1) << getMstatusUpieShift();}
    function getMstatusSpieMask() public pure returns(uint64) {return uint64(1) << getMstatusSpieShift();}
    function getMstatusMpieMask() public pure returns(uint64) {return uint64(1) << getMstatusMpieShift();}
    function getMstatusSppMask()  public pure returns(uint64) {return uint64(1) << getMstatusSppShift();}
    function getMstatusMppMask()  public pure returns(uint64) {return uint64(3) << getMstatusMppShift();}
    function getMstatusFsMask()   public pure returns(uint64) {return uint64(3) << getMstatusFsShift();}
    function getMstatusXsMask()   public pure returns(uint64) {return uint64(3) << getMstatusXsShift();}
    function getMstatusMprvMask() public pure returns(uint64) {return uint64(1) << getMstatusMprvShift();}
    function getMstatusSumMask()  public pure returns(uint64) {return uint64(1) << getMstatusSumShift();}
    function getMstatusMxrMask()  public pure returns(uint64) {return uint64(1) << getMstatusMxrShift();}
    function getMstatusTvmMask()  public pure returns(uint64) {return uint64(1) << getMstatusTvmShift();}
    function getMstatusTwMask()   public pure returns(uint64) {return uint64(1) << getMstatusTwShift();}
    function getMstatusTsrMask()  public pure returns(uint64) {return uint64(1) << getMstatusTsrShift();}

    function getMstatusUxlMask()  public pure returns(uint64) {return uint64(3) << getMstatusUxlShift();}
    function getMstatusSxlMask()  public pure returns(uint64) {return uint64(3) << getMstatusSxlShift();}
    function getMstatusSdMask()   public pure returns(uint64) {return uint64(1) << getMstatusSdShift();}

    // mstatus read/writes
    function getMstatusWMask() public pure returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusMieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusMpieMask() |
            getMstatusSppMask()  |
            getMstatusMppMask()  |
            getMstatusFsMask()   |
            getMstatusMprvMask() |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusTvmMask()  |
            getMstatusTwMask()   |
            getMstatusTsrMask()
        );
    }

    function getMstatusRMask() public pure returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusMieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusMpieMask() |
            getMstatusSppMask()  |
            getMstatusMppMask()  |
            getMstatusFsMask()   |
            getMstatusMprvMask() |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusTvmMask()  |
            getMstatusTwMask()   |
            getMstatusTsrMask()  |
            getMstatusUxlMask()  |
            getMstatusSxlMask()  |
            getMstatusSdMask()
        );
    }

    // sstatus read/writes
    function getSstatusWMask() public pure returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusSppMask()  |
            getMstatusFsMask()   |
            getMstatusSumMask()  |
            getMstatusMxrMask()
        );
    }

    function getSstatusRMask() public pure returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusSppMask()  |
            getMstatusFsMask()   |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusUxlMask()  |
            getMstatusSdMask()
        );
    }

    // mcause for exceptions
    function getMcauseInsnAddressMisaligned() public pure returns(uint64) {return 0x0;} ///< instruction address misaligned
    function getMcauseInsnAccessFault() public pure returns(uint64) {return 0x1;} ///< instruction access fault
    function getMcauseIllegalInsn() public pure returns(uint64) {return 0x2;} ///< illegal instruction
    function getMcauseBreakpoint() public pure returns(uint64) {return 0x3;} ///< breakpoint
    function getMcauseLoadAddressMisaligned() public pure returns(uint64) {return 0x4;} ///< load address misaligned
    function getMcauseLoadAccessFault() public pure returns(uint64) {return 0x5;} ///< load access fault
    function getMcauseStoreAmoAddressMisaligned() public pure returns(uint64) {return 0x6;} ///< store/amo address misaligned
    function getMcauseStoreAmoAccessFault() public pure returns(uint64) {return 0x7;} ///< store/amo access fault
    ///< environment call (+0: from u-mode, +1: from s-mode, +3: from m-mode)
    function getMcauseEcallBase() public pure returns(uint64) { return 0x8;}
    function getMcauseFetchPageFault() public pure returns(uint64) {return 0xc;} ///< instruction page fault
    function getMcauseLoadPageFault() public pure returns(uint64) {return 0xd;} ///< load page fault
    function getMcauseStoreAmoPageFault() public pure returns(uint64) {return 0xf;} ///< store/amo page fault

    function getMcauseInterruptFlag() public pure returns(uint64) {return uint64(1) << (getXlen() - 1);} ///< interrupt flag

    // mcounteren constants
    function getMcounterenCyShift() public pure returns(uint64) {return 0;}
    function getMcounterenTmShift() public pure returns(uint64) {return 1;}
    function getMcounterenIrShift() public pure returns(uint64) {return 2;}

    function getMcounterenCyMask() public pure returns(uint64) {return uint64(1) << getMcounterenCyShift();}
    function getMcounterenTmMask() public pure returns(uint64) {return uint64(1) << getMcounterenTmShift();}
    function getMcounterenIrMask() public pure returns(uint64) {return uint64(1) << getMcounterenIrShift();}

    function getMcounterenRwMask() public pure returns(uint64) {return getMcounterenCyMask() | getMcounterenTmMask() | getMcounterenIrMask();}
    function getScounterenRwMask() public pure returns(uint64) {return getMcounterenRwMask();}

    //paging constants
    function getPgShift() public pure returns(uint64) {return 12;}
    function getPgMask()  public pure returns(uint64) {((uint64(1) << getPgShift()) - 1);}

    function getPteVMask() public pure returns(uint64) {return (1 << 0);}
    function getPteUMask() public pure returns(uint64) {return (1 << 4);}
    function getPteAMask() public pure returns(uint64) {return (1 << 6);}
    function getPteDMask() public pure returns(uint64) {return (1 << 7);}

    function getPteXwrReadShift() public pure returns(uint64) {return 0;}
    function getPteXwrWriteShift() public pure returns(uint64) {return 1;}
    function getPteXwrCodeShift() public pure returns(uint64) {return 2;}

    // page masks
    function getPageNumberShift() public pure returns(uint64) {return 12;}

    function getPageOffsetMask() public pure returns(uint64) {return ((uint64(1) << getPageNumberShift()) - 1);}

    // mip shifts:
    function getMipUsipShift() public pure returns(uint64) {return 0;}
    function getMipSsipShift() public pure returns(uint64) {return 1;}
    function getMipMsipShift() public pure returns(uint64) {return 3;}
    function getMipUtipShift() public pure returns(uint64) {return 4;}
    function getMipStipShift() public pure returns(uint64) {return 5;}
    function getMipMtipShift() public pure returns(uint64) {return 7;}
    function getMipUeipShift() public pure returns(uint64) {return 8;}
    function getMipSeipShift() public pure returns(uint64) {return 9;}
    function getMipMeipShift() public pure returns(uint64) {return 11;}

    function getMipUsipMask() public pure returns(uint64) {return uint64(1) << getMipUsipShift();}
    function getMipSsipMask() public pure returns(uint64) {return uint64(1) << getMipSsipShift();}
    function getMipMsipMask() public pure returns(uint64) {return uint64(1) << getMipMsipShift();}
    function getMipUtipMask() public pure returns(uint64) {return uint64(1) << getMipUtipShift();}
    function getMipStipMask() public pure returns(uint64) {return uint64(1) << getMipStipShift();}
    function getMipMtipMask() public pure returns(uint64) {return uint64(1) << getMipMtipShift();}
    function getMipUeipMask() public pure returns(uint64) {return uint64(1) << getMipUeipShift();}
    function getMipSeipMask() public pure returns(uint64) {return uint64(1) << getMipSeipShift();}
    function getMipMeipMask() public pure returns(uint64) {return uint64(1) << getMipMeipShift();}
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// @title RiscVDecoder
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/BitsManipulationLibrary.sol";

/// @title RiscVDecoder
/// @author Felipe Argento
/// @notice Contract responsible for decoding the riscv's instructions
//      It applies different bitwise operations and masks to reach
//      specific positions and use that positions to identify the
//      correct function to be executed
library RiscVDecoder {
    /// @notice Get the instruction's RD
    /// @param insn Instruction
    function insnRd(uint32 insn) public pure returns(uint32) {
        return (insn >> 7) & 0x1F;
    }

    /// @notice Get the instruction's RS1
    /// @param insn Instruction
    function insnRs1(uint32 insn) public pure returns(uint32) {
        return (insn >> 15) & 0x1F;
    }

    /// @notice Get the instruction's RS2
    /// @param insn Instruction
    function insnRs2(uint32 insn) public pure returns(uint32) {
        return (insn >> 20) & 0x1F;
    }

    /// @notice Get the I-type instruction's immediate value
    /// @param insn Instruction
    function insnIImm(uint32 insn) public pure returns(int32) {
        return int32(insn) >> 20;
    }

    /// @notice Get the I-type instruction's unsigned immediate value
    /// @param insn Instruction
    function insnIUimm(uint32 insn) public pure returns(uint32) {
        return insn >> 20;
    }

    /// @notice Get the U-type instruction's immediate value
    /// @param insn Instruction
    function insnUImm(uint32 insn) public pure returns(int32) {
        return int32(insn & 0xfffff000);
    }

    /// @notice Get the B-type instruction's immediate value
    /// @param insn Instruction
    function insnBImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 12)) & (1 << 12)) |
            ((insn >> (25 - 5)) & 0x7e0) |
            ((insn >> (8 - 1)) & 0x1e) |
            ((insn << (11 - 7)) & (1 << 11))
        );
        return BitsManipulationLibrary.int32SignExtension(imm, 13);
    }

    /// @notice Get the J-type instruction's immediate value
    /// @param insn Instruction
    function insnJImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 20)) & (1 << 20)) |
            ((insn >> (21 - 1)) & 0x7fe) |
            ((insn >> (20 - 11)) & (1 << 11)) |
            (insn & 0xff000)
        );
        return BitsManipulationLibrary.int32SignExtension(imm, 21);
    }

    /// @notice Get the S-type instruction's immediate value
    /// @param insn Instruction
    function insnSImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(((insn & 0xfe000000) >> (25 - 5)) | ((insn >> 7) & 0x1F));
        return BitsManipulationLibrary.int32SignExtension(imm, 12);
    }

    /// @notice Get the instruction's opcode field
    /// @param insn Instruction
    function insnOpcode(uint32 insn) public pure returns (uint32) {
        return insn & 0x7F;
    }

    /// @notice Get the instruction's funct3 field
    /// @param insn Instruction
    function insnFunct3(uint32 insn) public pure returns (uint32) {
        return (insn >> 12) & 0x07;
    }

    /// @notice Get the concatenation of instruction's funct3 and funct7 fields
    /// @param insn Instruction
    function insnFunct3Funct7(uint32 insn) public pure returns (uint32) {
        return ((insn >> 5) & 0x380) | (insn >> 25);
    }

    /// @notice Get the concatenation of instruction's funct3 and funct5 fields
    /// @param insn Instruction
    function insnFunct3Funct5(uint32 insn) public pure returns (uint32) {
        return ((insn >> 7) & 0xE0) | (insn >> 27);
    }

    /// @notice Get the instruction's funct7 field
    /// @param insn Instruction
    function insnFunct7(uint32 insn) public pure returns (uint32) {
        return (insn >> 25) & 0x7F;
    }

    /// @notice Get the instruction's funct6 field
    /// @param insn Instruction
    function insnFunct6(uint32 insn) public pure returns (uint32) {
        return (insn >> 26) & 0x3F;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title ArithmeticImmediateInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../RiscVConstants.sol";

library ArithmeticImmediateInstructions {

    function getRs1Imm(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, int32 imm)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        imm = RiscVDecoder.insnIImm(insn);
    }

    // ADDI adds the sign extended 12 bits immediate to rs1. Overflow is ignored.
    // Reference: riscv-spec-v2.2.pdf -  Page 13
    function executeADDI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int64 val = int64(rs1) + int64(imm);
        return uint64(val);
    }

    // ADDIW adds the sign extended 12 bits immediate to rs1 and produces to correct
    // sign extension for 32 bits at rd. Overflow is ignored and the result is the
    // low 32 bits of the result sign extended to 64 bits.
    // Reference: riscv-spec-v2.2.pdf -  Page 30
    function executeADDIW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return uint64(int32(rs1) + imm);
    }

    // SLLIW is analogous to SLLI but operate on 32 bit values.
    // The amount of shifts are enconded on the lower 5 bits of I-imm.
    // Reference: riscv-spec-v2.2.pdf - Section 4.2 -  Page 30
    function executeSLLIW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(rs1) << uint32(imm & 0x1F);
        return uint64(rs1w);
    }

    // ORI performs logical Or bitwise operation on register rs1 and the sign-extended
    // 12 bit immediate. It places the result in rd.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeORI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 | uint64(imm);
    }

    // SLLI performs the logical left shift. The operand to be shifted is in rs1
    // and the amount of shifts are encoded on the lower 6 bits of I-imm.(RV64)
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeSLLI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 << uint32(imm & 0x3F);
    }

    // SLRI instructions is a logical shift right instruction. The variable to be
    // shift is in rs1 and the amount of shift operations is encoded in the lower
    // 6 bits of the I-immediate field.
    function executeSRLI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        uint32 shiftAmount = uint32(imm & int32(RiscVConstants.getXlen() - 1));

        return rs1 >> shiftAmount;
    }

    // SRLIW instructions operates on a 32bit value and produce a signed results.
    // The variable to be shift is in rs1 and the amount of shift operations is
    // encoded in the lower 6 bits of the I-immediate field.
    function executeSRLIW(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(uint32(rs1) >> uint32(imm & 0x1F));
        return uint64(rs1w);
    }

    // SLTI - Set less than immediate. Places value 1 in rd if rs1 is less than
    // the signed extended imm when both are signed. Else 0 is written.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 13.
    function executeSLTI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return (int64(rs1) < int64(imm))? 1 : 0;
    }

    // SLTIU is analogous to SLLTI but treats imm as unsigned.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeSLTIU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return (rs1 < uint64(imm))? 1 : 0;
    }

    // SRAIW instructions operates on a 32bit value and produce a signed results.
    // The variable to be shift is in rs1 and the amount of shift operations is
    // encoded in the lower 6 bits of the I-immediate field.
    function executeSRAIW(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(rs1) >> uint32(imm & 0x1F);
        return uint64(rs1w);
    }

    // TO-DO: make sure that >> is now arithmetic shift and not logical shift
    // SRAI instruction is analogous to SRAIW but for RV64I
    function executeSRAI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return uint64(int64(rs1) >> uint256(int64(imm) & int64((RiscVConstants.getXlen() - 1))));
    }

    // XORI instructions performs XOR operation on register rs1 and hhe sign extended
    // 12 bit immediate, placing result in rd.
    function executeXORI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 ^ uint64(imm);
    }

    // ANDI instructions performs AND operation on register rs1 and hhe sign extended
    // 12 bit immediate, placing result in rd.
    function executeANDI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        //return (rs1 & uint64(imm) != 0)? 1 : 0;
        return rs1 & uint64(imm);
    }

    /// @notice Given a arithmetic immediate32 funct3 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for arithmetic immediate32 funct3 field.
    function arithmeticImmediate32Funct3(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 == 0x0000) {
            /*funct3 == 0x0000*/
            //return "ADDIW";
            return (executeADDIW(mi, insn), true);
        } else if (funct3 == 0x0005) {
            /*funct3 == 0x0005*/
            return shiftRightImmediate32Group(mi, insn);
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SLLIW";
            return (executeSLLIW(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given a arithmetic immediate funct3 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for arithmetic immediate funct3 field.
    function arithmeticImmediateFunct3(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return (executeADDI(mi, insn), true);

            } else if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                return (executeSLTI(mi, insn), true);
            } else if (funct3 == 0x0001) {
                // Imm[11:6] must be zero for it to be SLLI.
                // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
                if (( insn & (0x3F << 26)) != 0) {
                    return (0, false);
                }
                return (executeSLLI(mi, insn), true);
            }
        } else if (funct3 > 0x0003) {
            if (funct3 < 0x0006) {
                if (funct3 == 0x0004) {
                    /*funct3 == 0x0004*/
                    return (executeXORI(mi, insn), true);
                } else if (funct3 == 0x0005) {
                    /*funct3 == 0x0005*/
                    return shiftRightImmediateFunct6(mi, insn);
                }
            } else if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                return (executeANDI(mi, insn), true);
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                return (executeORI(mi, insn), true);
            }
        } else if (funct3 == 0x0003) {
            /*funct3 == 0x0003*/
            return (executeSLTIU(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given a right immediate funct6 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for right immediate funct6 field.
    function shiftRightImmediateFunct6(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct6 = RiscVDecoder.insnFunct6(insn);
        if (funct6 == 0x0000) {
            /*funct6 == 0x0000*/
            return (executeSRLI(mi, insn), true);
        } else if (funct6 == 0x0010) {
            /*funct6 == 0x0010*/
            return (executeSRAI(mi, insn), true);
        }
        //return "illegal insn";
        return (0, false);
    }

    /// @notice Given a shift right immediate32 funct3 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for shift right immediate32 funct3 field.
    function shiftRightImmediate32Group(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct7 = RiscVDecoder.insnFunct7(insn);

        if (funct7 == 0x0000) {
            /*funct7 == 0x0000*/
            return (executeSRLIW(mi, insn), true);
        } else if (funct7 == 0x0020) {
            /*funct7 == 0x0020*/
            return (executeSRAIW(mi, insn), true);
        }
        return (0, false);
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title ArithmeticInstructions

pragma solidity ^0.7.0;

// Overflow/Underflow behaviour in solidity is to allow them to happen freely.
// This mimics the RiscV behaviour, so we can use the arithmetic operators normally.
// RiscV-spec-v2.2 - Section 2.4:
// https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
// Solidity docs Twos Complement/Underflow/Overflow:
// https://solidity.readthedocs.io/en/latest/security-considerations.html?highlight=overflow#two-s-complement-underflows-overflows
import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";


library ArithmeticInstructions {
    // TO-DO: move XLEN to its own library
    uint constant XLEN = 64;

    // event Print(string message);
    function getRs1Rs2(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, uint64 rs2)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        rs2 = mi.readX(RiscVDecoder.insnRs2(insn));
    }

    function executeADD(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("ADD");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        //BuiltinAddOverflow(rs1, rs2, &val)
        return rs1 + rs2;
    }

    function executeSUB(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SUB");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        //BuiltinSubOverflow(rs1, rs2, &val)
        return rs1 - rs2;
    }

    function executeSLL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 << (rs2 & uint64(XLEN - 1));
    }

    function executeSLT(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLT");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return (int64(rs1) < int64(rs2))? 1:0;
    }

    function executeSLTU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLTU");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return (rs1 < rs2)? 1:0;
    }

    function executeXOR(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("XOR");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 ^ rs2;
    }

    function executeSRL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SRL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 >> (rs2 & (XLEN-1));
    }

    function executeSRA(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SRA");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return uint64(int64(rs1) >> (rs2 & (XLEN-1)));
    }

    function executeOR(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("OR");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 | rs2;
    }

    function executeAND(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("AND");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 & rs2;
    }

    function executeMUL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("MUL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);
        //BuiltinMulOverflow(srs1, srs2, &val);

        return uint64(srs1 * srs2);
    }

    function executeMULH(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("MULH");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        return uint64((int128(srs1) * int128(srs2)) >> 64);
    }

    function executeMULHSU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);

        return uint64((int128(srs1) * int128(rs2)) >> 64);
    }

    function executeMULHU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return uint64((int128(rs1) * int128(rs2)) >> 64);
    }

    function executeDIV(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("DIV");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        if (srs2 == 0) {
            return uint64(-1);
        } else if (srs1 == (int64(1 << (XLEN - 1))) && srs2 == -1) {
            return uint64(srs1);
        } else {
            return uint64(srs1 / srs2);
        }
    }

    function executeDIVU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        if (rs2 == 0) {
            return uint64(-1);
        } else {
            return rs1 / rs2;
        }
    }

    function executeREM(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        if (srs2 == 0) {
            return uint64(srs1);
        } else if (srs1 == (int64(1 << uint64(XLEN - 1))) && srs2 == -1) {
            return 0;
        } else {
            return uint64(srs1 % srs2);
        }
    }

    function executeREMU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        if (rs2 == 0) {
            return rs1;
        } else {
            return rs1 % rs2;
        }
    }

    function executeADDW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("REMU");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w + rs2w);
    }

    function executeSUBW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w - rs2w);
    }

    function executeSLLW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(uint32(rs1) << uint32(rs2 & 31));

        return uint64(rs1w);
    }

    function executeSRLW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(uint32(rs1) >> (rs2 & 31));

        return uint64(rs1w);
    }

    function executeSRAW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1) >> (rs2 & 31);

        return uint64(rs1w);
    }

    function executeMULW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w * rs2w);
    }

    function executeDIVW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);
        if (rs2w == 0) {
            return uint64(-1);
        } else if (rs1w == (int32(1) << (32 - 1)) && rs2w == -1) {
            return uint64(rs1w);
        } else {
            return uint64(rs1w / rs2w);
        }
    }

    function executeDIVUW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        uint32 rs1w = uint32(rs1);
        uint32 rs2w = uint32(rs2);
        if (rs2w == 0) {
            return uint64(-1);
        } else {
            return uint64(int32(rs1w / rs2w));
        }
    }

    function executeREMW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        if (rs2w == 0) {
            return uint64(rs1w);
        } else if (rs1w == (int32(1) << (32 - 1)) && rs2w == -1) {
            return uint64(0);
        } else {
            return uint64(rs1w % rs2w);
        }
    }

    function executeREMUW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        uint32 rs1w = uint32(rs1);
        uint32 rs2w = uint32(rs2);

        if (rs2w == 0) {
            return uint64(int32(rs1w));
        } else {
            return uint64(int32(rs1w % rs2w));
        }
    }

    /// @notice Given a arithmetic funct3 funct7 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for arithmetic 32 funct3 funct7 field.
    function arithmeticFunct3Funct7(MemoryInteractor mi, uint32 insn) public returns (uint64, bool) {
        uint32 funct3Funct7 = RiscVDecoder.insnFunct3Funct7(insn);
        if (funct3Funct7 < 0x0181) {
            if (funct3Funct7 < 0x0081) {
                if (funct3Funct7 < 0x0020) {
                    if (funct3Funct7 == 0x0000) {
                        /*funct3Funct7 == 0x0000*/
                        return (executeADD(mi, insn), true);
                    } else if (funct3Funct7 == 0x0001) {
                        /*funct3Funct7 == 0x0001*/
                        return (executeMUL(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0080) {
                    /*funct3Funct7 == 0x0080*/
                    return (executeSLL(mi, insn), true);
                } else if (funct3Funct7 == 0x0020) {
                    /*funct3Funct7 == 0x0020*/
                    return (executeSUB(mi, insn), true);
                }
            } else if (funct3Funct7 > 0x0081) {
                if (funct3Funct7 == 0x0100) {
                    /*funct3Funct7 == 0x0100*/
                    return (executeSLT(mi, insn), true);
                } else if (funct3Funct7 == 0x0180) {
                    /*funct3Funct7 == 0x0180*/
                    return (executeSLTU(mi, insn), true);
                } else if (funct3Funct7 == 0x0101) {
                    /*funct3Funct7 == 0x0101*/
                    return (executeMULHSU(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0081) {
                /* funct3Funct7 == 0x0081*/
                return (executeMULH(mi, insn), true);
            }
        } else if (funct3Funct7 > 0x0181) {
            if (funct3Funct7 < 0x02a0) {
                if (funct3Funct7 == 0x0200) {
                    /*funct3Funct7 == 0x0200*/
                    return (executeXOR(mi, insn), true);
                } else if (funct3Funct7 > 0x0201) {
                    if (funct3Funct7 == 0x0280) {
                        /*funct3Funct7 == 0x0280*/
                        return (executeSRL(mi, insn), true);
                    } else if (funct3Funct7 == 0x0281) {
                        /*funct3Funct7 == 0x0281*/
                        return (executeDIVU(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0201) {
                    /*funct3Funct7 == 0x0201*/
                    return (executeDIV(mi, insn), true);
                }
            }else if (funct3Funct7 > 0x02a0) {
                if (funct3Funct7 < 0x0380) {
                    if (funct3Funct7 == 0x0300) {
                        /*funct3Funct7 == 0x0300*/
                        return (executeOR(mi, insn), true);
                    } else if (funct3Funct7 == 0x0301) {
                        /*funct3Funct7 == 0x0301*/
                        return (executeREM(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0381) {
                    /*funct3Funct7 == 0x0381*/
                    return (executeREMU(mi, insn), true);
                } else if (funct3Funct7 == 0x380) {
                    /*funct3Funct7 == 0x0380*/
                    return (executeAND(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x02a0) {
                /*funct3Funct7 == 0x02a0*/
                return (executeSRA(mi, insn), true);
            }
        } else if (funct3Funct7 == 0x0181) {
            /*funct3Funct7 == 0x0181*/
            return (executeMULHU(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given an arithmetic32 funct3 funct7 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for arithmetic32 funct3 funct7 field.
    function arithmetic32Funct3Funct7(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {

        uint32 funct3Funct7 = RiscVDecoder.insnFunct3Funct7(insn);

        if (funct3Funct7 < 0x0280) {
            if (funct3Funct7 < 0x0020) {
                if (funct3Funct7 == 0x0000) {
                    /*funct3Funct7 == 0x0000*/
                    return (executeADDW(mi, insn), true);
                } else if (funct3Funct7 == 0x0001) {
                    /*funct3Funct7 == 0x0001*/
                    return (executeMULW(mi, insn), true);
                }
            } else if (funct3Funct7 > 0x0020) {
                if (funct3Funct7 == 0x0080) {
                    /*funct3Funct7 == 0x0080*/
                    return (executeSLLW(mi, insn), true);
                } else if (funct3Funct7 == 0x0201) {
                    /*funct3Funct7 == 0x0201*/
                    return (executeDIVW(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0020) {
                /*funct3Funct7 == 0x0020*/
                return (executeSUBW(mi, insn), true);
            }
        } else if (funct3Funct7 > 0x0280) {
            if (funct3Funct7 < 0x0301) {
                if (funct3Funct7 == 0x0281) {
                    /*funct3Funct7 == 0x0281*/
                    return (executeDIVUW(mi, insn), true);
                } else if (funct3Funct7 == 0x02a0) {
                    /*funct3Funct7 == 0x02a0*/
                    return (executeSRAW(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0381) {
                /*funct3Funct7 == 0x0381*/
                return (executeREMUW(mi, insn), true);
            } else if (funct3Funct7 == 0x0301) {
                /*funct3Funct7 == 0x0301*/
                //return "REMW";
                return (executeREMW(mi, insn), true);
            }
        } else if (funct3Funct7 == 0x0280) {
            /*funct3Funct7 == 0x0280*/
            //return "SRLW";
            return (executeSRLW(mi, insn), true);
        }
        //return "illegal insn";
        return (0, false);
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Atomic instructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../VirtualMemory.sol";

library AtomicInstructions {

    function executeLR(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));
        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr
        );

        if (!succ) {
            //executeRetired / advance to raised expection
            return false;
        }
        mi.writeIlrsc(vaddr);

        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, val);
        }
        // advance to next instruction
        return true;

    }

    function executeSC(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 val = 0;
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));

        if (mi.readIlrsc() == vaddr) {
            if (!VirtualMemory.writeVirtualMemory(
                mi,
                wordSize,
                vaddr,
                mi.readX(RiscVDecoder.insnRs2(insn))
            )) {
                //advance to raised exception
                return false;
            }
            mi.writeIlrsc(uint64(-1));
        } else {
            val = 1;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, val);
        }
        //advance to next insn
        return true;
    }

    function executeAMOPart1(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    internal returns (uint64, uint64, uint64, bool)
    {
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));

        (bool succ, uint64 tmpValm) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr
        );

        if (!succ) {
            return (0, 0, 0, false);
        }
        uint64 tmpValr = mi.readX(RiscVDecoder.insnRs2(insn));

        return (tmpValm, tmpValr, vaddr, true);
    }

    function executeAMODPart2(
        MemoryInteractor mi,
        uint32 insn,
        uint64 vaddr,
        int64 valr,
        int64 valm,
        uint64 wordSize
    )
    internal returns (bool)
    {
        if (!VirtualMemory.writeVirtualMemory(
            mi,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, uint64(valm));
        }
        return true;
    }

    function executeAMOWPart2(
        MemoryInteractor mi,
        uint32 insn,
        uint64 vaddr,
        int32 valr,
        int32 valm,
        uint64 wordSize
    )
    internal returns (bool)
    {
        if (!VirtualMemory.writeVirtualMemory(
            mi,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, uint64(valm));
        }
        return true;
    }

    function executeAMOSWAPW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valr),
            int32(valm), 32
        );
    }

    function executeAMOADDW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(int32(valm) + int32(valr)),
            int32(valm), 32
        );
    }

    function executeAMOXORW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm ^ valr),
            int32(valm), 32
        );
    }

    function executeAMOANDW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm & valr),
            int32(valm),
            32
        );
    }

    function executeAMOORW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm | valr),
            int32(valm),
            32
        );

    }

    function executeAMOMINW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm) < int32(valr)? int32(valm) : int32(valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm) > int32(valr)? int32(valm) : int32(valr),
            int32(valm),
            32
        );
    }

    function executeAMOMINUW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(uint32(valm) < uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXUW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(uint32(valm) > uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOSWAPD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOADDD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm + valr),
            int64(valm),
            64
        );
    }

    function executeAMOXORD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm ^ valr),
            int64(valm),
            64
        );
    }

    function executeAMOANDD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm & valr),
            int64(valm),
            64
        );
    }

    function executeAMOORD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm | valr),
            int64(valm),
            64
        );

    }

    function executeAMOMIND(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm) < int64(valr)? int64(valm) : int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOMAXD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm) > int64(valr)? int64(valm) : int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOMINUD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        // TO-DO: this is uint not int
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(uint64(valm) < uint64(valr)? valm : valr),
            int64(valm),
            64
        );
    }

    // TO-DO: this is uint not int
    function executeAMOMAXUD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(uint64(valm) > uint64(valr)? valm : valr),
            int64(valm),
            64
        );
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title BranchInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";


library BranchInstructions {

    function getRs1Rs2(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, uint64 rs2)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        rs2 = mi.readX(RiscVDecoder.insnRs2(insn));
    }

    function executeBEQ(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 == rs2;
    }

    function executeBNE(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 != rs2;
    }

    function executeBLT(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return int64(rs1) < int64(rs2);
    }

    function executeBGE(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return int64(rs1) >= int64(rs2);
    }

    function executeBLTU(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 < rs2;
    }

    function executeBGEU(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 >= rs2;
    }

    /// @notice Given a branch funct3 group instruction, finds the function
    //  associated with it. Uses binary search for performance.
    //  @param insn for branch funct3 field.
    function branchFunct3(MemoryInteractor mi, uint32 insn)
    public returns (bool, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0005) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return (executeBEQ(mi, insn), true);
            } else if (funct3 == 0x0004) {
                /*funct3 == 0x0004*/
                return (executeBLT(mi, insn), true);
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                return (executeBNE(mi, insn), true);
            }
        } else if (funct3 > 0x0005) {
            if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                return (executeBGEU(mi, insn), true);
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                return (executeBLTU(mi, insn), true);
            }
        } else if (funct3 == 0x0005) {
            /*funct3==0x0005*/
            return (executeBGE(mi, insn), true);
        }
        return (false, false);
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// TO-DO: Add documentation explaining each instruction

/// @title EnvTrapIntInstruction
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../RiscVConstants.sol";
import "../Exceptions.sol";


library EnvTrapIntInstructions {
    function executeECALL(
        MemoryInteractor mi
    ) public
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mtval = mi.readMtval();
        // TO-DO: Are parameter valuation order deterministic? If so, we dont need to allocate memory
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseEcallBase() + priv,
            mtval
        );
    }

    function executeEBREAK(
        MemoryInteractor mi
    ) public
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseBreakpoint(),
            mi.readMtval()
        );
    }

    function executeSRET(
        MemoryInteractor mi
    )
    public returns (bool)
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mstatus = mi.readMstatus();

        if (priv < RiscVConstants.getPrvS() || (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTsrMask() != 0))) {
            return false;
        } else {
            uint64 spp = (mstatus & RiscVConstants.getMstatusSppMask()) >> RiscVConstants.getMstatusSppShift();
            // Set the IE state to previous IE state
            uint64 spie = (mstatus & RiscVConstants.getMstatusSpieMask()) >> RiscVConstants.getMstatusSpieShift();
            mstatus = (mstatus & ~RiscVConstants.getMstatusSieMask()) | (spie << RiscVConstants.getMstatusSieShift());

            // set SPIE to 1
            mstatus |= RiscVConstants.getMstatusSpieMask();
            // set SPP to U
            mstatus &= ~RiscVConstants.getMstatusSppMask();
            mi.writeMstatus(mstatus);
            if (priv != spp) {
                mi.setPriv(spp);
            }
            mi.writePc(mi.readSepc());
            return true;
        }
    }

    function executeMRET(
        MemoryInteractor mi
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv();

        if (priv < RiscVConstants.getPrvM()) {
            return false;
        } else {
            uint64 mstatus = mi.readMstatus();
            uint64 mpp = (mstatus & RiscVConstants.getMstatusMppMask()) >> RiscVConstants.getMstatusMppShift();
            // set IE state to previous IE state
            uint64 mpie = (mstatus & RiscVConstants.getMstatusMpieMask()) >> RiscVConstants.getMstatusMpieShift();
            mstatus = (mstatus & ~RiscVConstants.getMstatusMieMask()) | (mpie << RiscVConstants.getMstatusMieShift());

            // set MPIE to 1
            mstatus |= RiscVConstants.getMstatusMpieMask();
            // set MPP to U
            mstatus &= ~RiscVConstants.getMstatusMppMask();
            mi.writeMstatus(mstatus);

            if (priv != mpp) {
                mi.setPriv(mpp);
            }
            mi.writePc(mi.readMepc());
            return true;
        }
    }

    function executeWFI(
        MemoryInteractor mi
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mstatus = mi.readMstatus();

        if (priv == RiscVConstants.getPrvU() || (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTwMask() != 0))) {
            return false;
        } else {
            uint64 mip = mi.readMip();
            uint64 mie = mi.readMie();
            // Go to power down if no enable interrupts are pending
            if ((mip & mie) == 0) {
                mi.setIflagsI(true);
            }
            return true;
        }
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title S_Instructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../VirtualMemory.sol";


library S_Instructions {
    function getRs1ImmRs2(MemoryInteractor mi, uint32 insn)
    internal returns(uint64 rs1, int32 imm, uint64 val)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        imm = RiscVDecoder.insnSImm(insn);
        val = mi.readX(RiscVDecoder.insnRs2(insn));
    }

    function sb(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, insn);
        // 8 == uint8
        return VirtualMemory.writeVirtualMemory(
            mi,
            8,
            vaddr + uint64(imm),
            val
        );
    }

    function sh(
        MemoryInteractor mi,
        uint32 insn
        )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, insn);
        // 16 == uint16
        return VirtualMemory.writeVirtualMemory(
            mi,
            16,
            vaddr + uint64(imm),
            val
        );
    }

    function sw(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, insn);
        // 32 == uint32
        return VirtualMemory.writeVirtualMemory(
            mi,
            32,
            vaddr + uint64(imm),
            val
        );
    }

    function sd(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, insn);
        // 64 == uint64
        return VirtualMemory.writeVirtualMemory(
            mi,
            64,
            vaddr + uint64(imm),
            val
        );
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title StandAloneInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";


library StandAloneInstructions {
    //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the
    // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
    // Reference: riscv-spec-v2.2.pdf -  Page 14
    function executeAuipc(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    ) public
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + uint64(RiscVDecoder.insnUImm(insn)));
        }
        //return advanceToNextInsn(mi, pc);
    }

    // LUI (i.e load upper immediate). Is used to build 32-bit constants and uses
    // the U-type format. LUI places the U-immediate value in the top 20 bits of
    // the destination register rd, filling in the lowest 12 bits with zeros
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 13
    function executeLui(
        MemoryInteractor mi,
        uint32 insn
    ) public
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, uint64(RiscVDecoder.insnUImm(insn)));
        }
        //return advanceToNextInsn(mi, pc);
    }

    // JALR (i.e Jump and Link Register). uses the I-type encoding. The target
    // address is obtained by adding the 12-bit signed I-immediate to the register
    // rs1, then setting the least-significant bit of the result to zero.
    // The address of the instruction following the jump (pc+4) is written to register rd
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
    function executeJalr(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (bool, uint64)
    {
        uint64 newPc = uint64(int64(mi.readX(RiscVDecoder.insnRs1(insn))) + int64(RiscVDecoder.insnIImm(insn))) & ~uint64(1);

        if ((newPc & 3) != 0) {
            return (false, newPc);
            //return raiseMisalignedFetchException(mi, newPc);
        }
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + 4);
        }
        return (true, newPc);
        //return executeJump(mi, newPc);
    }

    // JAL (i.e Jump and Link). JImmediate encondes a signed offset in multiples
    // of 2 bytes. The offset is added to pc and JAL stores the address of the jump
    // (pc + 4) to the rd register.
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
    function executeJal(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (bool, uint64)
    {
        uint64 newPc = pc + uint64(RiscVDecoder.insnJImm(insn));

        if ((newPc & 3) != 0) {
            return (false, newPc);
            //return raiseMisalignedFetchException(mi, newPc);
        }
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + 4);
        }
        return (true, newPc);
        //return executeJump(mi, newPc);
    }

}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;


/// @title ShadowAddresses
/// @author Felipe Argento
/// @notice Defines the processor state. Memory-mapped to the lowest 512 bytes in pm
/// @dev Defined on Cartesi techpaper version 1.02 - Section 3 - table 2 
/// Source: https://cartesi.io/cartesi_whitepaper.pdf 
library ShadowAddresses {
    uint64 constant PC         = 0x100;
    uint64 constant MVENDORID  = 0x108;
    uint64 constant MARCHID    = 0x110;
    uint64 constant MIMPID     = 0x118;
    uint64 constant MCYCLE     = 0x120;
    uint64 constant MINSTRET   = 0x128;
    uint64 constant MSTATUS    = 0x130;
    uint64 constant MTVEC      = 0x138;
    uint64 constant MSCRATCH   = 0x140;
    uint64 constant MEPC       = 0x148;
    uint64 constant MCAUSE     = 0x150;
    uint64 constant MTVAL      = 0x158;
    uint64 constant MISA       = 0x160;
    uint64 constant MIE        = 0x168;
    uint64 constant MIP        = 0x170;
    uint64 constant MEDELEG    = 0x178;
    uint64 constant MIDELEG    = 0x180;
    uint64 constant MCOUNTEREN = 0x188;
    uint64 constant STVEC      = 0x190;
    uint64 constant SSCRATCH   = 0x198;
    uint64 constant SEPC       = 0x1a0;
    uint64 constant SCAUSE     = 0x1a8;
    uint64 constant STVAL      = 0x1b0;
    uint64 constant SATP       = 0x1b8;
    uint64 constant SCOUNTEREN = 0x1c0;
    uint64 constant ILRSC      = 0x1c8;
    uint64 constant IFLAGS     = 0x1d0;

    //getters - contracts cant access constants directly
    function getPc()         public pure returns(uint64) {return PC;}
    function getMvendorid()  public pure returns(uint64) {return MVENDORID;}
    function getMarchid()    public pure returns(uint64) {return MARCHID;}
    function getMimpid()     public pure returns(uint64) {return MIMPID;}
    function getMcycle()     public pure returns(uint64) {return MCYCLE;}
    function getMinstret()   public pure returns(uint64) {return MINSTRET;}
    function getMstatus()    public pure returns(uint64) {return MSTATUS;}
    function getMtvec()      public pure returns(uint64) {return MTVEC;}
    function getMscratch()   public pure returns(uint64) {return MSCRATCH;}
    function getMepc()       public pure returns(uint64) {return MEPC;}
    function getMcause()     public pure returns(uint64) {return MCAUSE;}
    function getMtval()      public pure returns(uint64) {return MTVAL;}
    function getMisa()       public pure returns(uint64) {return MISA;}
    function getMie()        public pure returns(uint64) {return MIE;}
    function getMip()        public pure returns(uint64) {return MIP;}
    function getMedeleg()    public pure returns(uint64) {return MEDELEG;}
    function getMideleg()    public pure returns(uint64) {return MIDELEG;}
    function getMcounteren() public pure returns(uint64) {return MCOUNTEREN;}
    function getStvec()      public pure returns(uint64) {return STVEC;}
    function getSscratch()   public pure returns(uint64) {return SSCRATCH;}
    function getSepc()       public pure returns(uint64) {return SEPC;}
    function getScause()     public pure returns(uint64) {return SCAUSE;}
    function getStval()      public pure returns(uint64) {return STVAL;}
    function getSatp()       public pure returns(uint64) {return SATP;}
    function getScounteren() public pure returns(uint64) {return SCOUNTEREN;}
    function getIlrsc()      public pure returns(uint64) {return ILRSC;}
    function getIflags()     public pure returns(uint64) {return IFLAGS;}
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Step
pragma solidity ^0.7.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import {Fetch} from "./Fetch.sol";
import {Execute} from "./Execute.sol";
import {Interrupts} from "./Interrupts.sol";

/// @title Step
/// @author Felipe Argento
/// @notice State transiction function that takes the machine from state s[i] to s[i + 1]
contract Step {
    event StepGiven(uint8 exitCode);
    event StepStatus(uint64 cycle, bool halt);

    MemoryInteractor mi;

    constructor(address miAddress) {
        mi = MemoryInteractor(miAddress);
    }

    /// @notice Run step define by a MemoryManager instance.
    /// @return Returns an exit code.
    /// @param _rwPositions position of all read and writes
    /// @param _rwValues value of all read and writes
    /// @param _isRead bool specifying if access is a read
    /// @return Returns an exit code and the amount of memory accesses
    function step(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) public returns (uint8, uint256) {

        mi.initializeMemory(_rwPositions, _rwValues, _isRead);

        // Read iflags register and check its H flag, to see if machine is halted.
        // If machine is halted - nothing else to do. H flag is stored on the least
        // signficant bit on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 halt = mi.readIflagsH();

        if (halt != 0) {
            //machine is halted
            emit StepStatus(0, true);
            return endStep(0);
        }

        uint64 yield = mi.readIflagsY();

        if (yield != 0) {
             //cpu is yielded
            emit StepStatus(0, true);
            return endStep(0);
        }

	    //Raise the highest priority interrupt
        Interrupts.raiseInterruptIfAny(mi);

        //Fetch Instruction
        Fetch.fetchStatus fetchStatus;
        uint64 pc;
        uint32 insn;

        (fetchStatus, insn, pc) = Fetch.fetchInsn(mi);

        if (fetchStatus == Fetch.fetchStatus.success) {
            // If fetch was successfull, tries to execute instruction
            if (Execute.executeInsn(
                    mi,
                    insn,
                    pc
                ) == Execute.executeStatus.retired
               ) {
                // If executeInsn finishes successfully we need to update the number of
                // retired instructions. This number is stored on minstret CSR.
                // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
                uint64 minstret = mi.readMinstret();
                mi.writeMinstret(minstret + 1);
            }
        }
        // Last thing that has to be done in a step is to update the cycle counter.
        // The cycle counter is stored on mcycle CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        uint64 mcycle = mi.readMcycle();
        mi.writeMcycle(mcycle + 1);
        emit StepStatus(mcycle + 1, false);

        return endStep(0);
    }

    function getMemoryInteractor() public view returns (address) {
        return address(mi);
    }

    function endStep(uint8 exitCode) internal returns (uint8, uint256) {
        emit StepGiven(exitCode);

        return (exitCode, mi.getRWIndex());
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import "./PMA.sol";
import "./CLINT.sol";
import "./HTIF.sol";
import "./Exceptions.sol";

/// @title Virtual Memory
/// @author Felipe Argento
/// @notice Defines Virtual Memory behaviour
library VirtualMemory {

    // Variable positions on their respective array.
    // This is not an enum because enum assumes the type from the number of variables
    // So we would have to explicitly cast to uint256 on every single access
    uint256 constant PRIV = 0;
    uint256 constant MODE= 1;
    uint256 constant VADDR_SHIFT = 2;
    uint256 constant PTE_SIZE_LOG2 = 3;
    uint256 constant VPN_BITS = 4;
    uint256 constant SATP_PPN_BITS = 5;

    uint256 constant VADDR_MASK = 0;
    uint256 constant PTE_ADDR = 1;
    uint256 constant MSTATUS = 2;
    uint256 constant SATP = 3;
    uint256 constant VPN_MASK = 4;
    uint256 constant PTE = 5;

    // Write/Read Virtual Address variable indexes
    uint256 constant OFFSET = 0;
    uint256 constant PMA_START = 1;
    uint256 constant PADDR = 2;
    uint256 constant VAL = 3;

    /// @notice Read word to virtual memory
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @param vaddr is the words virtual address
    /// @return True if write was succesfull, false if not.
    /// @return Word with receiveing value.
    function readVirtualMemory(
        MemoryInteractor mi,
        uint64 wordSize,
        uint64 vaddr
    )
    public returns(bool, uint64)
    {
        uint64[6] memory uint64vars;
        if (vaddr & (wordSize/8 - 1) != 0) {
            // Word is not aligned - raise exception
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseLoadAddressMisaligned(),
                vaddr
            );
            return (false, 0);
        } else {
            (bool translateSuccess, uint64 paddr) = translateVirtualAddress(
                mi,
                vaddr,
                RiscVConstants.getPteXwrReadShift()
            );

            if (!translateSuccess) {
                // translation failed - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseLoadPageFault(),
                    vaddr
                );
                return (false, 0);
            }
            uint64vars[PMA_START] = PMA.findPmaEntry(mi, paddr);
            if (PMA.pmaGetIstartE(uint64vars[PMA_START]) || !PMA.pmaGetIstartR(uint64vars[PMA_START])) {
                // PMA is either excluded or we dont have permission to write - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseLoadAccessFault(),
                    vaddr
                );
                return (false, 0);
            } else if (PMA.pmaGetIstartM(uint64vars[PMA_START])) {
                return (true, mi.readMemory(paddr, wordSize));
            }else {
                bool success = false;
                if (PMA.pmaIsHTIF(uint64vars[PMA_START])) {
                    (success, uint64vars[VAL]) = HTIF.htifRead(
                        mi,
                        paddr,
                        wordSize
                    );
                } else if (PMA.pmaIsCLINT(uint64vars[PMA_START])) {
                    (success, uint64vars[VAL]) = CLINT.clintRead(
                        mi,
                        paddr,
                        wordSize
                    );
                }
                if (!success) {
                    Exceptions.raiseException(
                        mi,
                        Exceptions.getMcauseLoadAccessFault(),
                        vaddr
                    );
                }
                return (success, uint64vars[VAL]);
            }
        }
    }

    /// @notice Writes word to virtual memory
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @param vaddr is the words virtual address
    /// @param val is the value to be written
    /// @return True if write was succesfull, false if not.
    function writeVirtualMemory(
        MemoryInteractor mi,
        uint64 wordSize,
        uint64 vaddr,
        uint64 val
    )
    public returns (bool)
    {
        uint64[6] memory uint64vars;

        if (vaddr & ((wordSize / 8) - 1) != 0) {
            // Word is not aligned - raise exception
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseStoreAmoAddressMisaligned(),
                vaddr
            );
            return false;
        } else {
            bool translateSuccess;
            (translateSuccess, uint64vars[PADDR]) = translateVirtualAddress(
                mi,
                vaddr,
                RiscVConstants.getPteXwrWriteShift()
            );

            if (!translateSuccess) {
                // translation failed - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseStoreAmoPageFault(),
                    vaddr);

                return false;
            }
            uint64vars[PMA_START] = PMA.findPmaEntry(mi, uint64vars[PADDR]);

            if (PMA.pmaGetIstartE(uint64vars[PMA_START]) || !PMA.pmaGetIstartW(uint64vars[PMA_START])) {
                // PMA is either excluded or we dont have permission to write - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseStoreAmoAccessFault(),
                    vaddr
                );
                return false;
            } else if (PMA.pmaGetIstartM(uint64vars[PMA_START])) {
                //write to memory
                mi.writeMemory(
                    uint64vars[PADDR],
                    val,
                    wordSize
                );
                return true;
            } else {

                if (PMA.pmaIsHTIF(uint64vars[PMA_START])) {
                    if (!HTIF.htifWrite(
                       mi,
                       PMA.pmaGetStart(uint64vars[PMA_START]), val, wordSize
                    )) {
                        Exceptions.raiseException(
                            mi,
                            Exceptions.getMcauseStoreAmoAccessFault(),
                            vaddr
                        );
                        return false;
                    }
                } else if (PMA.pmaIsCLINT(uint64vars[PMA_START])) {
                    if (!CLINT.clintWrite(
                            mi,
                            PMA.pmaGetStart(uint64vars[PMA_START]), val, wordSize
                    )) {
                        Exceptions.raiseException(
                            mi,
                            Exceptions.getMcauseStoreAmoAccessFault(),
                            vaddr
                        );
                        return false;
                    }
                }
                return true;
            }
        }
    }

    // Finds the physical address associated to the virtual address (vaddr).
    // Walks the page table until it finds a valid one. Returns a bool if the physical
    // address was succesfully found along with the address. Returns false and zer0
    // if something went wrong.

    // Virtual Address Translation proccess is defined, step by step on the following Reference:
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.3.2, page 62.
    function translateVirtualAddress(
        MemoryInteractor mi,
        uint64 vaddr,
        int xwrShift
    )
    public returns(bool, uint64)
    {
        //TO-DO: check shift + mask
        //TO-DO: use bitmanipulation right shift

        // Through arrays we force variables that were being put on stack to be stored
        // in memory. It is more expensive, but the stack only supports 16 variables.
        uint64[6] memory uint64vars;
        int[6] memory intvars;

        // Reads privilege level on iflags register. The privilege level is located
        // on bits 2 and 3.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        intvars[PRIV] = mi.readIflagsPrv();

        //readMstatus
        uint64vars[MSTATUS] = mi.memoryRead(ShadowAddresses.getMstatus());

        // When MPRV is set, data loads and stores use privilege in MPP
        // instead of the current privilege level (code access is unaffected)
        //TO-DO: Check this &/&& and shifts
        if ((uint64vars[MSTATUS] & RiscVConstants.getMstatusMprvMask() != 0) && (xwrShift != RiscVConstants.getPteXwrCodeShift())) {
            intvars[PRIV] = (uint64vars[MSTATUS] & RiscVConstants.getMstatusMppMask()) >> RiscVConstants.getMstatusMppShift();
        }

        // Physical memory is mediated by Machine-mode so, if privilege is M-mode it
        // does not use virtual Memory
        // Reference: riscv-priv-spec-1.7.pdf - Section 3.3, page 32.
        if (intvars[PRIV] == RiscVConstants.getPrvM()) {
            return (true, vaddr);
        }

        // SATP - Supervisor Address Translation and Protection Register
        // Holds MODE, Physical page number (PPN) and address space identifier (ASID)
        // MODE is located on bits 60 to 63 for RV64.
        // Reference: riscv-priv-spec-1.10.pdf - Section 4.1.12, page 56.
        uint64vars[SATP] = mi.memoryRead(ShadowAddresses.getSatp());
        // In RV64, mode can be
        //   0: Bare: No translation or protection
        //   8: sv39: Page-based 39-bit virtual addressing
        //   9: sv48: Page-based 48-bit virtual addressing
        // Reference: riscv-priv-spec-1.10.pdf - Table 4.3, page 57.
        intvars[MODE] = (uint64vars[SATP] >> 60) & 0xf;

        if (intvars[MODE] == 0) {
            return(true, vaddr);
        } else if (intvars[MODE] < 8 || intvars[MODE] > 9) {
            return(false, 0);
        }
        // Here we know we are in sv39 or sv48 modes

        // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
        int levels = intvars[MODE] - 8 + 3;
        // Page offset are bits located from 0 to 11.
        // Then come levels virtual page numbers (VPN)
        // The rest of vaddr must be filled with copies of the
        // most significant bit in VPN[levels]
        // Hence, the use of arithmetic shifts here
        // Reference: riscv-priv-spec-1.10.pdf - Figure 4.16, page 63.

        //TO-DO: Use bitmanipulation library for arithmetic shift
        intvars[VADDR_SHIFT] = RiscVConstants.getXlen() - (RiscVConstants.getPgShift() + levels * 9);
        if (((int64(vaddr) << uint64(intvars[VADDR_SHIFT])) >> uint64(intvars[VADDR_SHIFT])) != int64(vaddr)) {
            return (false, 0);
        }
        // The least significant 44 bits of satp contain the physical page number
        // for the root page table
        // Reference: riscv-priv-spec-1.10.pdf - Figure 4.12, page 57.
        intvars[SATP_PPN_BITS] = 44;
        // Initialize pteAddr with the base address for the root page table
        uint64vars[PTE_ADDR] = (uint64vars[SATP] & ((uint64(1) << uint64(intvars[SATP_PPN_BITS])) - 1)) << RiscVConstants.getPgShift();
        // All page table entries have 8 bytes
        // Each page table has 4k/pteSize entries
        // To index all entries, we need vpnBits
        // Reference: riscv-priv-spec-1.10.pdf - Section 4.4.1, page 63.
        intvars[PTE_SIZE_LOG2] = 3;
        intvars[VPN_BITS] = 12 - intvars[PTE_SIZE_LOG2];
        uint64vars[VPN_MASK] = uint64((1 << uint(intvars[VPN_BITS])) - 1);

        for (int i = 0; i < levels; i++) {
            // Mask out VPN[levels -i-1]
            intvars[VADDR_SHIFT] = RiscVConstants.getPgShift() + intvars[VPN_BITS] * (levels - 1 - i);
            uint64 vpn = (vaddr >> uint(intvars[VADDR_SHIFT])) & uint64vars[VPN_MASK];
            // Add offset to find physical address of page table entry
            uint64vars[PTE_ADDR] += vpn << uint64(intvars[PTE_SIZE_LOG2]);
            //Read page table entry from physical memory
            bool readRamSucc;
            (readRamSucc, uint64vars[PTE]) = readRamUint64(mi, uint64vars[PTE_ADDR]);

            if (!readRamSucc) {
                return(false, 0);
            }

            // The OS can mark page table entries as invalid,
            // but these entries shouldn't be reached during page lookups
            //TO-DO: check if condition
            if ((uint64vars[PTE] & RiscVConstants.getPteVMask()) == 0) {
                return (false, 0);
            }
            // Clear all flags in least significant bits, then shift back to multiple of page size to form physical address
            uint64 ppn = (uint64vars[PTE] >> 10) << RiscVConstants.getPgShift();
            // Obtain X, W, R protection bits
            // X, W, R bits are located on bits 1 to 3 on physical address
            // Reference: riscv-priv-spec-1.10.pdf - Figure 4.18, page 63.
            int xwr = (uint64vars[PTE] >> 1) & 7;
            // xwr !=0 means we are done walking the page tables
            if (xwr != 0) {
                // These protection bit combinations are reserved for future use
                if (xwr == 2 || xwr == 6) {
                    return (false, 0);
                }
                // (We know we are not PRV_M if we reached here)
                if (intvars[PRIV] == RiscVConstants.getPrvS()) {
                    // If SUM is set, forbid S-mode code from accessing U-mode memory
                    //TO-DO: check if condition
                    if ((uint64vars[PTE] & RiscVConstants.getPteUMask() != 0) && ((uint64vars[MSTATUS] & RiscVConstants.getMstatusSumMask())) == 0) {
                        return (false, 0);
                    }
                } else {
                    // Forbid U-mode code from accessing S-mode memory
                    if ((uint64vars[PTE] & RiscVConstants.getPteUMask()) == 0) {
                        return (false, 0);
                    }
                }
                // MXR allows to read access to execute-only pages
                if (uint64vars[MSTATUS] & RiscVConstants.getMstatusMxrMask() != 0) {
                    //Set R bit if X bit is set
                    xwr = xwr | (xwr >> 2);
                }
                // Check protection bits against request access
                if (((xwr >> uint(xwrShift)) & 1) == 0) {
                    return (false, 0);
                }
                // Check page, megapage, and gigapage alignment
                uint64vars[VADDR_MASK] = (uint64(1) << uint64(intvars[VADDR_SHIFT])) - 1;
                if (ppn & uint64vars[VADDR_MASK] != 0) {
                    return (false, 0);
                }
                // Decide if we need to update access bits in pte
                bool updatePte = (uint64vars[PTE] & RiscVConstants.getPteAMask() == 0) || ((uint64vars[PTE] & RiscVConstants.getPteDMask() == 0) && xwrShift == RiscVConstants.getPteXwrWriteShift());

                uint64vars[PTE] |= RiscVConstants.getPteAMask();

                if (xwrShift == RiscVConstants.getPteXwrWriteShift()) {
                    uint64vars[PTE] = uint64vars[PTE] | RiscVConstants.getPteDMask();
                }
                // If so, update pte
                if (updatePte) {
                    writeRamUint64(
                        mi,
                        uint64vars[PTE_ADDR],
                        uint64vars[PTE]
                    );
                }
                // Add page offset in vaddr to ppn to form physical address
                return (true, (vaddr & uint64vars[VADDR_MASK]) | (ppn & ~uint64vars[VADDR_MASK]));
            }else {
                uint64vars[PTE_ADDR] = ppn;
            }
        }
        return (false, 0);
    }

    function readRamUint64(MemoryInteractor mi, uint64 paddr)
    internal returns (bool, uint64)
    {
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartR(pmaStart)) {
            return (false, 0);
        }
        return (true, mi.readMemory(paddr, 64));
    }

    function writeRamUint64(
        MemoryInteractor mi,
        uint64 paddr,
        uint64 val
    )
    internal returns (bool)
    {
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartW(pmaStart)) {
            return false;
        }
        mi.writeMemory(
            paddr,
            val,
            64
        );
        return true;
    }

}