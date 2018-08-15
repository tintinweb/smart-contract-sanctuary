pragma solidity 0.4.24;

contract Receiver {

    event ReceivedFunds(address from, uint256 amount);

    function () payable public {
        emit ReceivedFunds(msg.sender, msg.value);
    }
}