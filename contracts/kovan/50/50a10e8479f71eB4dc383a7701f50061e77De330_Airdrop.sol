//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Airdrop is Ownable {

    ILockableToken public token;

    uint256 public amount;
    uint256 public lockShare;
    uint256 public lockDuration;

    mapping (address => bool) public gotTokens;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // EVENTS

    event Airdropped(address indexed account, uint256 amount);

    // CONSTRUCTOR

    constructor(ILockableToken token_, uint256 amount_, uint256 lockShare_, uint256 lockDuration_) Ownable() {
        require(lockShare_ <= 100, "Lock share can be greater than 100%");
        
        token = token_;
        amount = amount_;
        lockShare = lockShare_;
        lockDuration = lockDuration_;
    }

    // PUBLIC FUNCTIONS

    function getTokens() external {
        require(!gotTokens[msg.sender], "Sender has already got tokens");
        gotTokens[msg.sender] = true;
        token.transferAndLock(msg.sender, amount, lockShare, lockDuration);

        emit Airdropped(msg.sender, amount);
    }

    // RESTRICTED FUNCTIONS

    function setAmount(uint256 amount_) external onlyOwner {
        amount = amount_;
    }

    function setLockShare(uint256 lockShare_) external onlyOwner {
        require(lockShare_ <= 100, "Lock share can be greater than 100%");
        lockShare = lockShare_;
    }

    function setLockDuration(uint256 lockDuration_) external onlyOwner {
        lockDuration = lockDuration_;
    }

    function burnRemaining() external onlyOwner {
        token.transfer(BURN_ADDRESS, token.balanceOf(address(this)));
    }
}

interface ILockableToken {
    function transferAndLock(address to, uint256 amount, uint256 lockShare, uint256 lockDuration) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        return msg.data;
    }
}

