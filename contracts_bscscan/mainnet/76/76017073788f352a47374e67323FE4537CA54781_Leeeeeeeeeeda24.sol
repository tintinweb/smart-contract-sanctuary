/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Leeeeeeeeeeda24 {
    event MoneyReceived(
        address indexed from,
        uint value
    );
    
    event MoneyWithdrawn(
        address indexed to,
        uint value
    );
    
    event LoveSend(
        address indexed from,
        uint256 value
    );
    
    event WishSend(
        address indexed from,
        string with
    );
    
    address private _owner;
    uint256 private _numberOfLove = 0;
    string[] private _wishes;
    
    constructor(uint256 numberOfLove_) {
        _owner = msg.sender;
        _numberOfLove = numberOfLove_;
    }
    
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
    
    function sendLove() public virtual {
        _numberOfLove += 1;
        emit LoveSend(msg.sender, numberOfLove());
    }
    
    function sendWish(string memory wish) public virtual {
        _wishes.push(wish);
        emit WishSend(msg.sender, wish);
    }
    
    function withdrawMoney(address payable operator, uint value) payable public virtual {
        require(msg.sender == _owner, "Only owner can withdraw");
        operator.transfer(value);
        emit MoneyWithdrawn(operator, value);
    }
    
    function lastWish() public view virtual returns (string memory) {
        uint size = _wishes.length;
        require(size > 0);
        return _wishes[size - 1];
    }
    
    function readWish(uint index) public view virtual returns (string memory) {
        uint size = _wishes.length;
        require(size > index);
        return _wishes[index];
    }
    
    function instagram() public view virtual returns (string memory) {
        return "https://www.instagram.com/leeeeeeeeeeda/";
    }
    
    function date() public view virtual returns (string memory) {
        return "16 September 2021";
    }
    
    function numberOfLove() public view virtual returns (uint256) {
        return _numberOfLove;
    }
}