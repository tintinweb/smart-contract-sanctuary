/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.22;

/**
* Contract that will forward any incoming Ether to a receiver address
*/
contract Forwarder {
    // Address to which any funds sent to this contract will be forwarded
    address public destinationAddress;
    
    // Events allow light clients to react on
    // changes efficiently.
    event Forward(address from, address to, uint amount);
    
    /**
    * Create the contract, and set the destination address to that of the creator
    */
    constructor(address receiver) public {
        destinationAddress = receiver;
    }
    
    /**
    * Default function; Gets called when Ether is deposited, and forwards it to the destination address
    */
    function() public payable {
        if (!destinationAddress.send(msg.value))
            revert();
        
        emit Forward(msg.sender, destinationAddress, msg.value);
    }
}