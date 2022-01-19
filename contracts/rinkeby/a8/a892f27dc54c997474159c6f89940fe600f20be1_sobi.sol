/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
* @notice Contract is a inheritable smart contract that will add a 
* New modifier called onlyOwner available in the smart contract inherting it
* 
* onlyOwner makes a function only callable from the Token owner
*
*/
contract sobi {
    // _owner is the owner of the Token
    address private _owner;

    /**
    * Event OwnershipTransferred is used to log that a ownership change of the token has occured
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * Modifier
    * We create our own function modifier called onlyOwner, it will Require the current owner to be 
    * the same as msg.sender
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
    * @notice owner() returns the currently assigned owner of the Token
    * 
     */
    function owner() public view returns(address) {
        return _owner;

    }
    /**
    * @notice renounceOwnership will set the owner to zero address
    * This will make the contract owner less, It will make ALL functions with
    * onlyOwner no longer callable.
    * There is no way of restoring the owner
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @notice transferOwnership will assign the {newOwner} as owner
    *
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
    * @notice _transferOwnership will assign the {newOwner} as owner
    *
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }



}