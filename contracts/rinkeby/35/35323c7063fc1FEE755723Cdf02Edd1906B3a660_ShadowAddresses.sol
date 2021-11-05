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