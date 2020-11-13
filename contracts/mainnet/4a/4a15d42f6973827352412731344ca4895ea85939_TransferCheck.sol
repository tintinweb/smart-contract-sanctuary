pragma solidity 0.5.12;

contract TransferCheck {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function checkTransfer(address payable _receivingAddress, uint256 amount) external {
        require(msg.sender == owner, "Invalid sender");
        _receivingAddress.transfer(amount);
    }

    function() payable external {}
}