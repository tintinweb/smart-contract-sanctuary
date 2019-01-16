pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * shamelessly borrowed from https://github.com/OpenZeppelin/openzeppelin-solidity
 * 
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Below the Ownable class, create a class for our contract that we will deploy
contract MessageOfTheMoment is Ownable {

    // add data types to the contract
    string public message;
    uint public maxLength;

    // add a constructorto initialize the contract’s data
    constructor() public {
        message = "Nailed it.";
        maxLength = 28;
    } 

    // add a function for anyone to change the message
    // use require to halt execution if the new message is too long
    function setMessage(string _message) public {
        require(bytes(_message).length <= maxLength, "That message is too long.");
        
        message = _message;
    }

    // add an owner-only function to change the maxLength
    // will fail if the caller is not the owner, preventing any data changes
    function setMaxLength(uint _maxLength) public onlyOwner {
        maxLength = _maxLength;
    }

}