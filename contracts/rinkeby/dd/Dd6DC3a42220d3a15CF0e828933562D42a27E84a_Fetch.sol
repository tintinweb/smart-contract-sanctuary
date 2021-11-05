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