/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Nfthere {
    struct User 
    {
        string username;
        string addr;
        bool registered;
    }
    
    address private owner;
    
        // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    mapping(string => User) accounts;
    
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
    
    function signup(string memory _username, string memory _addr) public isOwner
    {
        require(!accounts[_username].registered, "Username already exists");

        require(!accounts[_addr].registered, "Wallet already exists");

        accounts[_username] = User(_username, _addr, true);
        
        accounts[_addr] = User(_username, _addr, true);

    }
    
    function getWallet(string memory _username) external view returns(string memory, string memory)
    {
        return(accounts[_username].username, accounts[_username].addr);
        
    }
    
    function getUsername(string memory _addr) external view returns(string memory)
    {
        return(accounts[_addr].username);
        
    }
    
    
}