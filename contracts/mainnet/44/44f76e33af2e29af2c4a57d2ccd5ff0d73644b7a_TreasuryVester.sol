// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISilo {
    function transfer(address dst, uint256 rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Forked from https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
contract TreasuryVester is Ownable {
    address public immutable siloToken;
    address public recipient;

    uint256 public immutable vestingAmount;
    uint256 public immutable vestingBegin;
    uint256 public immutable vestingCliff;
    uint256 public immutable vestingEnd;
    bool public immutable revocable;

    uint256 public lastUpdate;
    bool public revoked;

    constructor(
        address _siloToken,
        address _recipient,
        uint256 _vestingAmount,
        uint256 _vestingBegin,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        bool _revocable
    ) {
        require(_vestingBegin >= block.timestamp, "TreasuryVester::constructor: vesting begin too early");
        require(_vestingCliff >= _vestingBegin, "TreasuryVester::constructor: cliff is too early");
        require(_vestingEnd > _vestingCliff, "TreasuryVester::constructor: end is too early");

        siloToken = _siloToken;
        recipient = _recipient;

        vestingAmount = _vestingAmount;
        vestingBegin = _vestingBegin;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        lastUpdate = _vestingBegin;

        revocable = _revocable;
    }

    function setRecipient(address _recipient) external {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        recipient = _recipient;
    }
    
    function revoke() external onlyOwner {
        require(revocable, "TreasuryVester::revoke cannot revoke");
        require(!revoked, "TreasuryVester::revoke token already revoked");

        if (block.timestamp >= vestingCliff) claim();

        revoked = true;

        ISilo(siloToken).transfer(owner(), ISilo(siloToken).balanceOf(address(this)));
    }

    function claim() public {
        require(!revoked, "TreasuryVester::claim vesting revoked");
        require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
        uint256 amount;

        if (block.timestamp >= vestingEnd) {
            amount = ISilo(siloToken).balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }

        ISilo(siloToken).transfer(recipient, amount);
    }
}