/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */
    constructor (){
        owner = msg.sender;
    }

    /* Function to recover the funds on the contract */
    function kill() public isOwner {
        selfdestruct(payable(owner));
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title Balance
 * @dev Store & retrieve deposited ETHER for bound users
 */
contract DepositedBalance is Mortal {
    mapping(string => BoundUser) public boundUsers;
    Address[] public addresses;

    struct Address {
        address addr;
        uint256 depositedAmount;
        bool isBoundToUser;
    }

    struct BoundUser {
        string userId;
        uint256[] addressesIndexes;
    }

    receive() external payable {
        if (msg.value == 0) revert("No funds sent by the user.");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i].addr != msg.sender) continue;

            addresses[i].depositedAmount += msg.value;
            payable(owner).transfer(msg.value);

            return;
        }

        addresses.push(Address(msg.sender, msg.value, false));
        payable(owner).transfer(msg.value);
    }

    function bind(string memory userId) public payable {
        if (bytes(userId).length == 0) revert("Missing user id to bind the address with.");

        bool existingAddress;

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i].addr != msg.sender) continue;

            if (msg.value > 0) {
                addresses[i].depositedAmount += msg.value;
                payable(owner).transfer(msg.value);
            }

            existingAddress = true;

            if (addresses[i].isBoundToUser || isAddressStored(userId)) return;

            addresses[i].isBoundToUser = true;
            boundUsers[userId].addressesIndexes.push(i);
        }

        if (!existingAddress) {
            addresses.push(Address(msg.sender, msg.value, true));
            boundUsers[userId].addressesIndexes.push(addresses.length - 1);
        }

        if (boundUsers[userId].addressesIndexes.length != 0 && bytes(boundUsers[userId].userId).length == 0) {
            boundUsers[userId].userId = userId;
        }
    }

    function isAddressStored(string memory userId) internal view returns (bool b){
        for (uint256 i = 0; i < boundUsers[userId].addressesIndexes.length; i++) {
            if (addresses[boundUsers[userId].addressesIndexes[i]].addr == msg.sender) return true;
        }

        return false;
    }

    function getBalance(string calldata userId) public view returns (uint256){
        uint256 deposits;

        for (uint256 i = 0; i < boundUsers[userId].addressesIndexes.length; i++) {
            deposits += addresses[boundUsers[userId].addressesIndexes[i]].depositedAmount;
        }

        return deposits;
    }
}