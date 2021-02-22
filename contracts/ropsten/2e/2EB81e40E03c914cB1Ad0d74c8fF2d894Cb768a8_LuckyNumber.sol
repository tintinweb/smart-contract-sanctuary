/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title LuckyNumber
 * @dev Owner can set a specific number, while others can only request some new number
 */
contract LuckyNumber{

    address private owner;
    uint256 private lucky;
    uint256 private lucky_id;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner; 
    // following method is taken from Owner.sol example in Remix
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
   // following method is taken from Owner.sol example in Remix
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        lucky_id = 0;
        lucky = 555;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
   // following method is taken from Owner.sol example in Remix
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
   // following method is taken from Owner.sol example in Remix
    function getOwner() external view returns (address) {
        return owner;
    }
    
    /** 
     * @dev As owner, set any new lucky number
     *
     */
    function setNewPersonalizedLuckyNumber(uint256 newLuckyNumber) public isOwner {
        lucky = newLuckyNumber;
    }

    /**
     * @dev Return current lucky number
     * @return the current lucky number
     */
    function getTheLuckyNumber() public view returns (uint256){
        return lucky;
    }
    
    /**
     * @dev Generate a new lucky number by cycling through the list
     */
    function generateANewLuckyNumber() public {

        if (lucky_id == 0) {
            lucky = 213;
            lucky_id = 1;
        } else if (lucky_id == 1) {
            lucky = 456;
            lucky_id = 2;
        } else if (lucky_id == 2) {
            lucky = 9;
            lucky_id = 3;
        } else if (lucky_id == 3) {
            lucky = 343;
            lucky_id = 4;
        } else if (lucky_id == 4) {
            lucky = 222;
            lucky_id = 0;
        }
    }

    
}