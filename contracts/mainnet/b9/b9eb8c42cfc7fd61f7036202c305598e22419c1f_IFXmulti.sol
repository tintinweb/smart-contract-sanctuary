/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.8;

/*
    IdeaFeX Token multi-send contract

    Deployed to     : 0xB9eB8c42Cfc7fD61F7036202c305598E22419c1F
    IFX token       : 0x2CF588136b15E47b555331d2f5258063AE6D01ed
*/


/* ERC20 standard interface */

contract ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/* Owned contract */

contract Ownable {
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Only the owner can use this contract");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}


/* Multi send */

contract IFXmulti is Ownable {
    ERC20Interface private _IFX = ERC20Interface(0x2CF588136b15E47b555331d2f5258063AE6D01ed);

    function multisend(address[] memory addresses, uint[] memory values) public onlyOwner {
        uint i = 0;
        while (i < addresses.length) {
           _IFX.transfer(addresses[i], values[i]);
           i += 1;
        }
    }
}