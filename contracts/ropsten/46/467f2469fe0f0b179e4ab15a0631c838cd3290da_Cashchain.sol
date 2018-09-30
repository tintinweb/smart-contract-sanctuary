pragma solidity ^0.4.24;
contract Cashchain {
    address owner;

    function Cashchain() {
        owner = msg.sender;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        owner.send(msg.value / 11);
        if (balances[msg.sender] != 0){
        address kashout = msg.sender;
        uint256 getout = balances[msg.sender]*35/1000*(block.number-timestamp[msg.sender])/5900;
        kashout.send(getout);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}