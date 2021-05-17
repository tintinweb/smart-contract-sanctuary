// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract SimpleWallet is Ownable {
    
    function withdrawMoney(address payable _to, uint _amount) public onlyOwner {
        
        _to.transfer(_amount);
    }
    
    receive () external payable {
        
    }
}