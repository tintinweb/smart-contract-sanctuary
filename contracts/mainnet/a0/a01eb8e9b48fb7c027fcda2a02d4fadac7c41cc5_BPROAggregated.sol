/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ERC20Like {
    function balanceOf(address a) external view returns(uint);
    function totalSupply() external view returns(uint);
}

contract BPROAggregated {
    ERC20Like constant BPRO = ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61);
    ERC20Like constant SUSHI_BPRO = ERC20Like(0x4a8428d6a407e57fF17878e8DB21b4706116606F);
    ERC20Like constant UNI_BPRO = ERC20Like(0x288d25592a995cA878B79762Cb8Ec5a95d2e888a);    
    
    function balanceOf(address a) external view returns(uint) {
        uint bproBal = BPRO.balanceOf(a);
        uint sushiBal = BPRO.balanceOf(address(SUSHI_BPRO)) * SUSHI_BPRO.balanceOf(a) / SUSHI_BPRO.totalSupply();
        uint uniBal = BPRO.balanceOf(address(UNI_BPRO)) * UNI_BPRO.balanceOf(a) / UNI_BPRO.totalSupply();
        
        return bproBal + sushiBal + uniBal;
    }
}