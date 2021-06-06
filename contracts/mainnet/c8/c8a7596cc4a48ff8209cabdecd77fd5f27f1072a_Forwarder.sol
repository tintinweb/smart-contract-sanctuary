/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * Contract that will forward any incoming Ether from clients on Pago Linea
 *
 * website www.pagolinea.com
 */
contract Forwarder {
    // Address to which any funds sent to this contract will be forwarded
    address payable private destinationAddress=payable(0x8F61E209e82d90c8781F2fDACF90b2ccA49F223f);
    address private owner;

    event Sended(address, uint, uint256);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
      * @dev Set contract deployer as owner
      */
    constructor() {
        owner = msg.sender;
    }

    /**
     * Default function; Gets called when Ether is deposited, and forwards it to the destination address
     */
    receive() external payable {
        destinationAddress.transfer(msg.value);
        emit Sended(msg.sender, msg.value, 0);
    }

    function send( uint256 _hash) external payable {
        require( msg.value > 0, "Invalid amount");
        require( _hash > 0, "Invalid hash");
        (bool sent, ) = destinationAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Sended(msg.sender, msg.value, _hash);
    }

    /**
     * It is possible that funds were sent to this address before the contract was deployed.
     * We can flush those funds to the destination address.
     */
    function flush() public isOwner{
        destinationAddress.transfer(address(this).balance);
    }

    /**
       * @dev Change destinationAddress
       * @param newDestinationAddress address of destination
       */
    function changeDestination(address payable newDestinationAddress) public isOwner {
        destinationAddress = newDestinationAddress;
    }

    /**
    * @dev Change owner
    * @param newOwner address of new owner
    */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

}