pragma solidity 0.6.4;

contract TestB1 {

    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

