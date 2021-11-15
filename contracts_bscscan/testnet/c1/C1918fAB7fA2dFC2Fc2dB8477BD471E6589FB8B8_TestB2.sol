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

    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

