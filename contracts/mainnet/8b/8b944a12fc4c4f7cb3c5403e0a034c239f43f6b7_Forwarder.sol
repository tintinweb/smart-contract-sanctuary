pragma solidity 0.4.25;

/**
 * Contract that will forward any incoming Ether to the address specified upon deployment
 */
contract Forwarder {
    /** Address to which any funds sent to this contract will be forwarded
     *  Event logs to log movement of Ether
    **/
    address constant public destinationAddress = 0x609E7e5Db94b3F47a359955a4c823538A5891D48;
    event LogForwarded(address indexed sender, uint amount);

    /**
     * Default function; Gets called when Ether is deposited, and forwards it to the destination address
     */
    function() payable public {
        emit LogForwarded(msg.sender, msg.value);
        destinationAddress.transfer(msg.value);
    }
}