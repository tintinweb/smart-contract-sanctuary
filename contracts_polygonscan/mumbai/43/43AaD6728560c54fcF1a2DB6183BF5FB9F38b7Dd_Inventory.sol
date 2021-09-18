/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Inventory {

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
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    struct Car {
        address carAddress;
        uint carPrice;
    }
    
    mapping (address => Car) public garage;
    mapping (address => address) public carToCarOwner;
    
    function addCar(address newCar, uint price) public isOwner {
        garage[newCar] = Car({ carAddress: newCar, carPrice: price });
        carToCarOwner[newCar] = owner;
    }
    
    function buyCar(address carAddress) payable public {
        require(msg.value == garage[carAddress].carPrice, "insufficient amount sent");
        require(carToCarOwner[carAddress] == owner, "car already sold" );
        carToCarOwner[carAddress] =  msg.sender;
    }
    
    function withdrawFunds() public isOwner {
        retrieveMoney(owner, address(this).balance);
    }
    
    function retrieveMoney(address to, uint value) private isOwner{
       address payable receiver = payable(to);
       receiver.transfer(value);
    }
}