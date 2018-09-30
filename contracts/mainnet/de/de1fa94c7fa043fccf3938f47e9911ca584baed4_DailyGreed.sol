pragma solidity ^0.4.24;
contract DailyGreed {
    address owner;

    function Daily() {
        owner = msg.sender;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        owner.send(msg.value / 10);
        if (balances[msg.sender] != 0){
        address kashout = msg.sender;
        uint256 getout = balances[msg.sender]*5/100*(block.number-timestamp[msg.sender])/5900;
        kashout.send(getout);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}