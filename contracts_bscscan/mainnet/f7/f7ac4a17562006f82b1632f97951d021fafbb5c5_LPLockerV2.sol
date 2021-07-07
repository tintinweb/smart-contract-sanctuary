/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
// The SharkDownV2🦈 LP Locker @ BSC - 0x226bd0bc871fc78ea47be01905b9c90e8bf374ab
// --------------------------------------------------
// @BSC: 0xf7AC4A17562006f82b1632F97951d021FaFbb5C5 |
// --------------------------------------------------
//  ________  ___  ___  ________  ________  ___  __    ________  ________  ___       __   ________           ___       ________  ________  ___  __    _______   ________
// |\   ____\|\  \|\  \|\   __  \|\   __  \|\  \|\  \ |\   ___ \|\   __  \|\  \     |\  \|\   ___  \        |\  \     |\   __  \|\   ____\|\  \|\  \ |\  ___ \ |\   __  \
// \ \  \___|\ \  \\\  \ \  \|\  \ \  \|\  \ \  \/  /|\ \  \_|\ \ \  \|\  \ \  \    \ \  \ \  \\ \  \       \ \  \    \ \  \|\  \ \  \___|\ \  \/  /|\ \   __/|\ \  \|\  \
//  \ \_____  \ \   __  \ \   __  \ \   _  _\ \   ___  \ \  \ \\ \ \  \\\  \ \  \  __\ \  \ \  \\ \  \       \ \  \    \ \  \\\  \ \  \    \ \   ___  \ \  \_|/_\ \   _  _\
//   \|____|\  \ \  \ \  \ \  \ \  \ \  \\  \\ \  \\ \  \ \  \_\\ \ \  \\\  \ \  \|\__\_\  \ \  \\ \  \       \ \  \____\ \  \\\  \ \  \____\ \  \\ \  \ \  \_|\ \ \  \\  \|
//     ____\_\  \ \__\ \__\ \__\ \__\ \__\\ _\\ \__\\ \__\ \_______\ \_______\ \____________\ \__\\ \__\       \ \_______\ \_______\ \_______\ \__\\ \__\ \_______\ \__\\ _\
//    |\_________\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|\|_______|\|_______|\|____________|\|__| \|__|        \|_______|\|_______|\|_______|\|__| \|__|\|_______|\|__|\|__|
//    \|_________|

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\Locker.sol

pragma solidity ^0.7.6;

contract LPLockerV2 is Ownable {
    uint256 public LockTimestamp;
    address public constant LPTokenAddress =
        0x226bd0BC871FC78EA47BE01905B9c90e8bf374Ab;
    // Base func
    function transferAnyERC20Token(address tokenAddress, uint256 tokens)
        public
    {
        require(block.timestamp > LockTimestamp, "LOCKED");

        if (IERC20(tokenAddress).transfer(owner(), tokens)) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function getBalanceOfAnyTokenInThisAddress(address tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        balance = IERC20(tokenAddress).balanceOf(address(this));
    }

    function getNow() external view returns (uint256 TimestampNow) {
        TimestampNow = block.timestamp;
    }

    // Locker func
    function updateLockTimestamp(uint256 newLockTimestamp) external onlyOwner {
        require(newLockTimestamp > LockTimestamp);
        LockTimestamp = newLockTimestamp;
    }

    function getBalanceOfLP() public view returns (uint256 SDv2LPTokenAmount) {
        SDv2LPTokenAmount = getBalanceOfAnyTokenInThisAddress(LPTokenAddress);
    }

    function unLockLP() external {
        transferAnyERC20Token(LPTokenAddress, getBalanceOfLP());
    }

    fallback() external payable {}

    receive() external payable {}
}