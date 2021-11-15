pragma solidity 0.6.4;

contract TestB2 {
    // note: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
        //msg.sender.transfer(10000);
    }

    function setVarsPass(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
        msg.sender.transfer(10000);
    }

    function setVarsFail(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
        //msg.sender.transfer(10000);
        revert("fail on purpose");
    }
}

