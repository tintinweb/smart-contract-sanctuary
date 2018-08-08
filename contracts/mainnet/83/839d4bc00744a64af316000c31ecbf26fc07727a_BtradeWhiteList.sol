pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    function Ownable() public {
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

contract BtradeWhiteList {
	mapping(address => bool) public whiteList;
	
	function BtradeWhiteList() public {
	
	}
	
	function register(address _address) public {
        whiteList[msg.sender] = true;
    }

    function unregister(address _address) public {
        whiteList[msg.sender] = false;
    }

    function isRegistered(address _address) public view returns (bool registered) {
        return whiteList[_address];
    }
}