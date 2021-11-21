/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
contract CryptoCompare {
    
    
    string public usd2eth;
    
    
    function updateUsd2Eth(string calldata _usd2eth) external {
        if (msg.sender!=0x1E754f69e571D37F71b7c1dDce1F081Dd51B4b3e){
            revert('wrong owner, cant update');
        }
        
        
        usd2eth = _usd2eth;
        
    } 
    
    
    
}