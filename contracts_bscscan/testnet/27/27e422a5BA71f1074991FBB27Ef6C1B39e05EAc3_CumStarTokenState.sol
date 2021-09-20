/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// File: contracts/src/libs/Context.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
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
        return msg.data;
    }
}

// File: contracts/src/libs/Ownable.sol



pragma solidity ^0.8.7;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/src/utility/Ownable/TokenOwnable.sol



pragma solidity ^0.8.7;


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
abstract contract TokenOwnable is Ownable {

    address private _readerContract;
    address private _minterContract;
    address private _managerContract;
    address private _tokenContract;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {}

    /**
     * @dev Throws if called by any account other than manager contract.
     */
    modifier onlyManager() {
        require(_managerContract == _msgSender(), "Ownable: caller is not manger contract");
        _;
    }

    /**
     * @dev Set manager contract address.
     * Can only be called by the manager contract.
     */
    function setManagerContract(address managerContractAddress_) external virtual onlyOwner {
        _managerContract = managerContractAddress_;
    }

    /**
     * @dev Throws if called by any account other than minter contract.
     */
    modifier onlyMinter() {
        require(_minterContract == _msgSender(), "Ownable: caller is not minter contract");
        _;
    }

    /**
     * @dev Set Minter contract address.
     * Can only be called by the minter contract.
     */
    function setMinterContract(address minterContractAddress_) external onlyOwner {
        _minterContract = minterContractAddress_;
    }

    /**
     * @dev Throws if called by any account other than reader contract.
     */
    modifier onlyReader() {
        require(_readerContract == _msgSender(), "Ownable: caller is not reader contract");
        _;
    }

    /**
     * @dev Set Reader contract address.
     * Can only be called by the reader contract.
     */
    function setReaderContract(address readerContractAddress_) external onlyOwner {
        _readerContract = readerContractAddress_;
    }

    /**
     * @dev Throws if called by any account other than token contract.
     */
    modifier onlyToken() {
        require(_tokenContract == _msgSender(), "Ownable: caller is not token contract");
        _;
    }

    /**
     * @dev Set Token contract address.
     * Can only be called by the token contract.
     */
    function setTokenContract(address tokenContract_) external onlyOwner {
        _tokenContract = tokenContract_;
    }
}

// File: contracts/src/external/CumStar/CumStarTokenState.sol

/**
 *Submitted for verification at BscScan.com on
*/



pragma solidity ^0.8.7;


contract CumStarTokenState is TokenOwnable {
    uint256 public _customerMinCumStarBalance = 0;

    /**
     * @dev Initializes (External) CumStar Token State
     */
    constructor (uint256 customerMinCumStarBalance_) {
        _customerMinCumStarBalance = customerMinCumStarBalance_;
    }

    function getMinBalance() external view onlyToken returns (uint256) {
        return _customerMinCumStarBalance;
    }

    function setMinBalance(uint256 customerMinCumStarBalance) external onlyToken {
        if ( _customerMinCumStarBalance != customerMinCumStarBalance) {
            _customerMinCumStarBalance = customerMinCumStarBalance;
        }
    }
}