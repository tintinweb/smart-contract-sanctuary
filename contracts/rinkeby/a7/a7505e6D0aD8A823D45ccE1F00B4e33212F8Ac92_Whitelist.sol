/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.1;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWhiteList {
    function isApproved(address entry) external view returns(bool);
 }

contract Whitelist is Ownable, IWhiteList {
    mapping(address=>bool) private approved;
    uint256 public numberApproved;

    event AddressAdded(address newEntry, uint256 numberApproved);
    event AddressRemoved(address entry, uint256 numberApproved);

    function isApproved(address entry) external override view returns(bool) {
        return approved[entry];
    }

    function addToList(address newEntry) external onlyOwner {
        require(!approved[newEntry], "already on list");
        approved[newEntry] = true;
        numberApproved = numberApproved + 1;
        emit AddressAdded(newEntry, numberApproved);
    }

    function removeFromList(address entry) external onlyOwner {
        require(approved[entry], "not on list");
        approved[entry] = false;
        numberApproved = numberApproved - 1;
        emit AddressRemoved(entry, numberApproved);
    }
    
}