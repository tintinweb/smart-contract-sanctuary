/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address[] private owners = new address[](5);
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        bool contains = false;
        uint256 x = owners.length;
        uint256 stop = 0;
        for(uint256 i = 0; i < x; i++){
            if(msg.sender == owners[i]){
                contains = true;
                stop = i;
                break;
            }
        }
        require(msg.sender == owners[stop], "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owners[0] = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owners[0]);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner, uint256 index) public isOwner {
        emit OwnerSet(owners[index], newOwner);
        owners[index] = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}