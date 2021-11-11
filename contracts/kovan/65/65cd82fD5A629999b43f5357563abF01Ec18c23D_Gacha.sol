/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Gacha {
    address owner;
    string[]  items;
    uint _balance;
    mapping(address => uint) user_balance;
    uint totalSupply;
    uint minimum = 10000;
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    event Deposit(address indexed user , uint amount);
    event Withdraw(address indexed user, uint amount);
    event Gachapon(address indexed user, uint amount);
    event CreateOwner(address indexed user);
    event AddItem(string item, uint n);
    
    constructor() {
        owner = msg.sender;
        emit CreateOwner(owner);
    }
    
    function deposit() external payable {
        user_balance[msg.sender] += msg.value;
        _balance += msg.value;
        emit Deposit(msg.sender , msg.value);
    }
    
    function withdraw(uint _amount) public {
        require(_amount <= user_balance[msg.sender], "Money not enough.");
        payable(msg.sender).transfer(_amount);
        user_balance[msg.sender] -= _amount;
        _balance -= _amount;
        emit Withdraw(msg.sender , _amount);
    }
    
    function checkBalance() public view returns(uint balance) {
        return user_balance[msg.sender];
    }
    
    function gachapon(uint _coin) public  {
        require(user_balance[msg.sender] >= minimum, "Balane not enough.");
        require(items.length > 0 , "Item is empty.");
        emit Gachapon(msg.sender, _coin);
        totalSupply  += _coin;
        user_balance[msg.sender] -= _coin;
        uint n = random(items.length);
        string memory _item = items[n];
        string memory jackpot = "jackpot";
        string memory lucky = "lucky";
        if(keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked(jackpot))) {
            user_balance[msg.sender] += _coin + uint(_coin / 2);
        } else if(keccak256(bytes(_item)) == keccak256(bytes(lucky))) {
            user_balance[msg.sender] += uint(_coin / 2);
        } else {
            user_balance[msg.sender] += 0;
        }
    }
    
    function resetItems() isOwner public {
        delete items;
    }
    
    function setMinimun(uint _newCoin) public isOwner {
        minimum = _newCoin;
    }
    
    function getMinimum() public view isOwner returns(uint coin) {
        return minimum;
    }
    
    function addItem(string memory _item, uint n) public isOwner {
        require(n > 0 && n <= 100 , "n between 1 - 100;");
        for(uint i = 0 ; i < n ;i++){
            items.push(_item);
        }
        emit AddItem(_item,n);
    }
    
    function getItem() public view returns(string[] memory list){
        return items;
    }
    
    function random(uint n) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp , block.difficulty, msg.sender))) % n;
    }

}