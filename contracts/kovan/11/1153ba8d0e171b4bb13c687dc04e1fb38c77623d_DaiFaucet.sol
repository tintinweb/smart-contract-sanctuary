/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}


contract owned {
    DaiToken daiToken;
    address owner;

    constructor() {
        owner = msg.sender;
        daiToken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner of this contract, so you can not call this function");
        _;
    }
}


contract mortal is owned {
    function destroy() public onlyOwner {
        daiToken.transfer(owner, daiToken.balanceOf(address(this)));
        // selfdestruct(msg.sender);
    }    
}


contract DaiFaucet is mortal {
    
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    function withdraw(uint _amount) public {
        
        require(daiToken.balanceOf(address(this)) >= _amount, "You do not have so many dai token");
        
        daiToken.transfer(msg.sender, _amount);
        emit Withdrawal(msg.sender, _amount);
    }

    fallback () external payable {
        emit Deposit(msg.sender, msg.value);
    }
}