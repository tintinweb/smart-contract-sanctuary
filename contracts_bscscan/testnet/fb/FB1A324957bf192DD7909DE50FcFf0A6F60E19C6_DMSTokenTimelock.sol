// SPDX-License-Identifier: MIT

import "./access/Ownable.sol";
import "./IERC20.sol";

pragma solidity >=0.8.0;

contract DMSTokenTimelock is Ownable {
    address public recipient =
        address(0xAe2d8BF6333b00f7e3675Ad30Db0565cD7A29e8A);
    IERC20 private _dmsToken =
        IERC20(address(0x1275b8448ED49730b1F897AB5a3E2995B237E3d9));

    uint256 public start = 0;
    uint256 public cycle = 0;
    uint256 public released = 0;
    uint256 public lock = 60 * 1;
    uint256 private _wei = 10**6;

    constructor() {
        start = block.timestamp + (lock * 3);
    }

    modifier onlyBalance() {
        require(balance() > 0, "Token balance is zero");
        _;
    }

    function balance() public view returns (uint256) {
        return _dmsToken.balanceOf(address(this));
    }

    function amounts() public view returns (uint256) {
        if (cycle == 0) {
            return 300 * _wei;
        }
        if (balance() > 0) {
            return 200 * _wei;
        }
        return 0;
    }

    function times() public view returns (uint256) {
        return start + cycle * lock;
    }

    function setRecipient(address _recipient) public onlyOwner returns (bool) {
        require(address(_recipient) != address(0), "recipient is zero address");
        recipient = address(_recipient);
        return true;
    }

    function setStart(uint256 _start) public onlyOwner returns (bool) {
        require(_start > 0, "start > 0");
        start = _start;
        return true;
    }

    function calc() public view returns (uint256, uint256) {
        uint256 _curr = times();
        if (block.timestamp < _curr) {
            return (0, cycle);
        }
        uint256 _amount = amounts();
        return (_amount, cycle + 1);
    }

    function release() external onlyBalance returns (uint256) {
        uint256 _amount;
        uint256 _cycle;
        (_amount, _cycle) = calc();
        require(_amount > 0, "Amount is zero");
        cycle = _cycle;
        released = released + _amount;
        bool sent = _dmsToken.transfer(recipient, _amount);
        require(sent, "Token transfer failed");
        return _amount;
    }

    function complete() external onlyOwner onlyBalance returns (bool) {
        require(cycle >= 7, "Time lock not end");
        uint256 _balance = balance();
        bool sent = _dmsToken.transfer(recipient, _balance);
        require(sent, "Token transfer failed");
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

