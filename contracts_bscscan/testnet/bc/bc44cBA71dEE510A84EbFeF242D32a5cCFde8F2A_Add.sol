/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract Add {

    address private owner;
    address private admin;
    uint256 sum=0;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event SumSet(uint256 indexed result);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not owner");
        _;
    }
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        admin = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change admin
     * @param newAdmin address of new admin
     */
    function changeAdmin(address newAdmin) public isOwner {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }
    function add(uint256[] memory array) public isAdmin {
        require(array[0]<array[1], "first number is bigger than second number");
        require(array[0]+array[1]<5, "Sum is smaller than 5");
        sum=array[0]+array[1];
        emit SumSet(sum);
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}