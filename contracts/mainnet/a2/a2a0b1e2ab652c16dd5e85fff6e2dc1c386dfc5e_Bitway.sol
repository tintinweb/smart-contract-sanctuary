/**
 *Submitted for verification at Etherscan.io on 2020-05-21
*/

pragma solidity >=0.5.0 <0.7.0;

// © BITWAY https://bitway.net

contract Bitway {
    address public minter;
    string public name;
    string public symbol;
    uint public decimals;
    uint internal supply;
    uint internal blocks;
    uint internal target;

    mapping (address => uint) internal balances;

    event Transfer(address indexed sender, address indexed receiver, uint amount);

    constructor() public {
        minter = msg.sender;
        name = "Bitway";
        symbol = "WAY";
        decimals = 18;
        supply = 0;
        blocks = 1000000 * 10**uint(decimals);
        target = 21 * blocks;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount == blocks);
        require(supply < target);
        balances[receiver] += amount;
        supply += amount;
    }

    function transfer(address receiver, uint amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function totalSupply() public view returns (uint) {
        return supply;
    }
}