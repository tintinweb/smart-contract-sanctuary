// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Customer {

    uint private userCount = 0;
    address private userWalletAddr;
    address private owner;

    mapping (uint => address) private customers;

    // EVENTS
    event OwnerSet(address indexed oldOwner, address indexed newOwner);


    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /*
    * @dev Set contract deployer as owner
    */
    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    /*
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function createCustomer( address _walletAddr ) public isOwner {
        userCount++;
        customers[userCount] = _walletAddr;
    }

    function getCustomer (uint userId) view public isOwner returns (address) {
        return customers[userId];
    }

}