pragma solidity 0.4.24;

contract Forwarder {

    address public constant destination = 0x49C9fFDf8376Fcc599f6C6d26C6EaEE61e8db1A8;

    event DepositReceived(address _from, uint256 _value);

    function () payable public {
        if (!destination.call.value(msg.value)(msg.data))
            revert("Tx was rejected by destination");
        emit DepositReceived(msg.sender, msg.value);
    }


    /**
     * In case funds were sent to this address befor smart contract deployment
     */
    function flush() public {
        if (!destination.call.value(address(this).balance)())
            revert("Tx was rejected by destination");
    }

}