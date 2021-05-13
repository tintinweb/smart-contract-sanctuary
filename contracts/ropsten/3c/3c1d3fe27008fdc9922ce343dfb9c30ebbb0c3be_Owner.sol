/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner 
 * @dev Set & change owner 0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d
 */
contract Owner {

    address private owner; 
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d), owner);
    }

    /**
     * @dev Change owner 
     * @param newOwner 0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d, newOwner);
        owner = newOwner;
    }

    /**Owner.(0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d)
     * @dev Return owner address 0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d
     * @return address of owner 0x72242e4ccFA9a7e0CaDd729b3b7d2302d82BF29d
     */
    function getOwner() external view returns (address) {
        return owner; 
    }
}