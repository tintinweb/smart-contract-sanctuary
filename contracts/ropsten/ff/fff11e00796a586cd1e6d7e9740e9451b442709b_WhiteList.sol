pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); 
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

/**
 * @title WhiteList
 * @dev manage vectorx whitelist
 */
contract WhiteList is Ownable {
	mapping(address => bool) public whiteList;
	
	event ResistWhiteList(address funder, bool isRegist);    // white list resist event
    event UnregisteWhiteList(address funder, bool isRegist); // white list remove event
	
	function register(address _address) public {
        whiteList[_address] = true;
        emit ResistWhiteList(_address, true);
    }

    function unregister(address _address) public {
        whiteList[_address] = false;
        emit UnregisteWhiteList(_address, false);
    }

    function isRegistered(address _address) public view returns (bool registered) {
        return whiteList[_address];
    }
}