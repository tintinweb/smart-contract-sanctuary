/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.5.9;

interface DaiToken{
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract owned{
    DaiToken daitoken;
    address owner;
    
    constructor() public{
        owner = msg.sender;
        daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }
    
    modifier onlyOwner{
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}


contract mortal is owned{
    
    function destroy() public onlyOwner{
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
        
}

contract DaiFaucet is mortal{
    
    event Withdrawal(address indexed to, uint amt);
    event Deposit(address indexed from, uint amt);
    
    function withdraw(uint amt) public{
        require(amt >= 0.1 ether);
        require(daitoken.balanceOf(address(this)) > amt, 'Insufficeint balance');
        daitoken.transfer(msg.sender, amt);
        emit Withdrawal(msg.sender, amt);
    }
    
    function () external payable{
        emit Deposit(msg.sender, msg.value);
    }
}