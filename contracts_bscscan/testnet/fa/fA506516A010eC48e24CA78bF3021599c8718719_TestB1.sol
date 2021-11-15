pragma solidity 0.6.4;

contract TestB1 {
    uint public num;
    address public sender;
    uint public value;

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function setVars_DC(address _contract, uint _num) public {
        // A's storage is set with caller's context, B is not modified
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint)", _num)
        );
    }

    function setVars_DC_pass(address _contract, uint _num) public {
        // A's storage is set with caller's context, B is not modified
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVarsPass(uint)", _num)
        );
    }

    function setVars_DC_fail(address _contract, uint _num) public {
        // A's storage is set with caller's context, B is not modified
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVarsFail(uint)", _num)
        );
    }

}

