pragma solidity ^0.4.23;

contract Allowance {

    address public father;
    address public child;
    uint public lastWithdrawalTime;
    uint public withdrawalAmount;

    constructor(address _child, uint _withdrawalAmount) public {
        require(_child != address(0));
        require(_withdrawalAmount > 0);
        father = msg.sender;
        child = _child;
        withdrawalAmount = _withdrawalAmount;
        lastWithdrawalTime = block.timestamp;
    }

    modifier childOnly() {
        require(msg.sender == child);
        _;
    }

    function() public payable {
        // Allow payments. By anyone. :)
    }

    function withdraw(uint amount) public childOnly {
        require(lastWithdrawalTime + 5 minutes < block.timestamp);
        child.transfer(amount);
        lastWithdrawalTime = block.timestamp;
    }

}