/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract owned {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {
    
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

contract Faucet is mortal{

    function withdraw(uint withdraw_amount) public {
        
        require(withdraw_amount <= 0.1 ether);
        msg.sender.transfer(withdraw_amount);
    }

    function () public payable{}
}

contract Token is mortal {
    Faucet _faucet;
    
    constructor(address _f) {
        _faucet = Faucet(_f);
    }
    
    function destroy() onlyOwner{
        _faucet.destroy();
    }
}