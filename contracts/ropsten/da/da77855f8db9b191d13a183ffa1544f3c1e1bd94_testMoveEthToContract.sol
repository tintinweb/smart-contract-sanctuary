/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;


contract testMoveEthToContract {    
    
    
    
    
    fallback() external payable {
    }

    receive() external payable {
    }
    
    
    function sendEth(address payable x, uint value) external {
        x.transfer(value);
    }
    
    
    function getBalance() external view returns (uint) {
        return (address(this).balance);
    }
    
}