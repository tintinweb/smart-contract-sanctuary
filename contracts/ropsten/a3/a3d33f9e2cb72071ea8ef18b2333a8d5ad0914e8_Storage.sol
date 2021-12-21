/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address private owner;
    mapping(address => uint256) storedNumbers;

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

    function changeOwnder(address newOwner) public isOwner{
        owner = newOwner;
    }

    
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }


    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        storedNumbers[msg.sender] = num;
    }

    function retrieve() public view returns (uint256){
        return storedNumbers[msg.sender];
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveNumberOf(address add) public view returns (uint256){
        return storedNumbers[add];
    }

    function storeNumberOf(address add, uint256 num) public isOwner{
        storedNumbers[add] = num;
    }

}