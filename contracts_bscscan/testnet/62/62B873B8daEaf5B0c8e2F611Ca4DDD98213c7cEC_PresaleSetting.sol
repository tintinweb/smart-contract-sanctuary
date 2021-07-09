/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// File: contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/utils/Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/PresaleSetting.sol

contract PresaleSetting is Ownable {
    string public name;
    uint256 public start;
    uint256 public end;
    uint256 public price;
    uint256 public minPurchase;
    uint256 public totalSupply;
    uint256 public cliff;
    uint256 public vestingMonth;

    constructor(string memory name_, 
                uint256 start_, 
                uint256 end_, 
                uint256 price_, 
                uint256 minPurchase_,
                uint256 totalSupply_, 
                uint256 cliff_, 
                uint256 vestingMonth_) {
        name = name_;
        start = start_;
        end = end_;
        price = price_;
        minPurchase = minPurchase_;
        totalSupply = totalSupply_;
        cliff = cliff_;
        vestingMonth = vestingMonth_;
    }

    function setName(string memory newName) external onlyOwner {
        name = newName;
    }

    function setMinPurchase(uint256 newValue) external onlyOwner {
        minPurchase = newValue;
    }

    function setStart(uint256 newValue) external onlyOwner {
        start = newValue;
    }

    function setEnd(uint256 newValue) external onlyOwner {
        end = newValue;
    }

    function setCliff(uint256 newValue) external onlyOwner {
        cliff = newValue;
    }

    function setTotalSupply(uint256 newValue) external onlyOwner {
        totalSupply = newValue;
    }
    function setPrice(uint256 newValue) external onlyOwner {
        price = newValue;
    }

    function setVestingMonth(uint256 newValue) external onlyOwner {
        vestingMonth = newValue;
    }
}