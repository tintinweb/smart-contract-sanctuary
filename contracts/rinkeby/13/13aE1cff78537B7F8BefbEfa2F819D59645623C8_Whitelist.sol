pragma solidity 0.7.6;
import './Ownable.sol';

contract Whitelist is Ownable {
    mapping(address => uint256) public tiers;
    event ChangeTier(address indexed account, uint256 tier);

    bool initialized = false;

    constructor (address admin) Ownable(admin) {}

    function initialize(address admin) public {
        require(initialized == false, "Tiers: contract has already been initialized.");
        owner = admin;
        initialized = true;
    }

    function changeTier(address _address, uint256 _tier) public onlyOwner {
        tiers[_address] = _tier;
        emit ChangeTier(_address, _tier);
    }

    function changeTierBatch(address[] calldata _addresses, uint256[] calldata _tierList) public onlyOwner {
        uint arrayLength = _addresses.length;
        require(arrayLength == _tierList.length, "Tiers: Arrays are not the same size");
        for (uint i = 0; i < arrayLength; i++) {
            address _address = _addresses[i];
            uint256 _tier = _tierList[i];
            tiers[_address] = _tier;
            emit ChangeTier(_address, _tier);
        }
    }

    function getTier(address _address) public view returns(uint256) {
        return tiers[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the initial owner.
     */
    constructor (address _owner) public {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function setNewOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner cannot be the zero address");
        newOwner = _newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership() public {
        require(msg.sender == newOwner, "Ownable: caller must be new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}