pragma solidity ^0.4.20;

contract TxnFee {
    address public owner;
    address public primary_wallet;
    address public thirty_wallet;
    address public ten_wallet;
    
    constructor (address main_wallet, address first, address second) public {
        owner = msg.sender;
        primary_wallet = main_wallet;
        thirty_wallet = first;
        ten_wallet = second;
    }
    
    event Contribution (address investor, uint256 eth_paid);
    
    function () public payable {
        emit Contribution(msg.sender, msg.value);
        uint256 thirty_value = msg.value * 3 / 10;
        uint256 ten_value = msg.value * 1 / 10;
        thirty_wallet.transfer(thirty_value);
        ten_wallet.transfer(ten_value);
        primary_wallet.transfer(msg.value - (thirty_value + ten_value));
    }
}