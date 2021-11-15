pragma solidity 0.6.4;

contract TestB2 {

    uint public num;
    address public sender;
    uint public value;

    function setVars_DC_pass(address _contract, uint _num) public {
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint,bool)", _num, true)
        );
    }

    function setVars_DC_fail(address _contract, uint _num) public {
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint,bool)", _num, false)
        );
    }

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

