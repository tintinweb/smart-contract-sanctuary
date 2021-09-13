/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Indeifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
contract Auction{
    uint64 public abcd = 1;
    
    function getA() public returns(uint64){
        abcd=2;
        return abcd;
    }
}