/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract Owned {
    address public owner;
    address  newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) internal onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() internal {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract YoplexToken is Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    bool public stopped =false;
    mapping(address => uint) balances;
    
    constructor(){
        symbol = "Yplx ";
        name = "Yoplex";
        decimals = 18;
        totalSupply = 8400000000000000000000000000;
        balances[owner] = totalSupply;
    }
 
  function balanceOf(address user) public view returns (uint) {
        return balances[user];
    }
    
}