/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.5.15;

contract Ownable {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
        return true;
    }
}

contract ERC20 {
    function transfer(address to, uint value) public returns (bool);
}

contract ExchangeContract is Ownable {
    uint constant MAX_EXCHANGE  = 1 ether;
    uint constant EXCHANGE_RATE = 100;

    ERC20 xxoo;

    struct User{
        bool exchanged;
        uint ex_date;
        uint ex_amount;
    }
    mapping(address => User) users;

    event Exchange(address indexed who, uint value);

    constructor(address _xxoo_addr) public {
        xxoo = ERC20(_xxoo_addr);
    }

    function exchange() public payable returns (bool){
        require(users[msg.sender].exchanged == false, "already exchanged");
        require(msg.value > 10 && msg.value <= MAX_EXCHANGE, "incorrect value");
        uint exchang_amount = msg.value * EXCHANGE_RATE;

        users[msg.sender].exchanged = true;
        users[msg.sender].ex_date   = block.timestamp;
        users[msg.sender].ex_amount = exchang_amount;

        xxoo.transfer(msg.sender, exchang_amount);
        emit Exchange(msg.sender, exchang_amount);

        return true;
    }

    function query_user(address addr) public view returns (bool, uint, uint) {
        return (users[addr].exchanged,
                users[addr].ex_date,
                users[addr].ex_amount);
    }
}