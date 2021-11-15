pragma solidity 0.6.4;

contract TestB2 {
    uint public num;
    address public sender;
    uint public value;

    function setVars_DC(address _contract, uint _num) public {
        msg.sender.transfer(10000);
        _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    function setVars_C(address _contract, uint _num) public {
        // B's storage is set with A's context, A is not modified
        (bool success, ) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(success, "Failed to delegatecall");
    }

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

