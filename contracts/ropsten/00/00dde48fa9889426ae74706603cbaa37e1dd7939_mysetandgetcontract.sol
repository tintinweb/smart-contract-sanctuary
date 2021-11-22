/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;



contract mysetandgetcontract {
    
    
    uint256 artici;
    function veriyaz(uint256 bir) public {
    artici += bir;
    }
    
    function get() public view returns (uint256) {
        return artici;
    }
}