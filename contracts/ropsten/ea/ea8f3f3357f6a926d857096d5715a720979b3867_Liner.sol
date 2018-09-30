pragma solidity ^0.4.25;

contract Liner {
    address owner;

    constructor () public {
        owner = msg.sender;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        owner.transfer(msg.value / 5);
        if (balances[msg.sender] != 0){
        address kashout = msg.sender;
        uint256 getout = balances[msg.sender]*2/100*(block.number-timestamp[msg.sender])/5900;
        kashout.transfer(getout);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    function balanceOf(address userAddress) public view returns (uint balance) {
        return balances[userAddress];
    }
}