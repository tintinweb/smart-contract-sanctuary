// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract LockToken is Context {
    struct LockInfo {
        bool isActive;
        uint256 amount;
        uint256 startCliffTime;
        uint256 cliff;
    }

    IERC20 public token;
    mapping(address => LockInfo) locks;

    constructor(IERC20 _token) {
        token = _token;
    }

    function lockToken(uint256 _amount, uint256 _cliff) external {
        require(_cliff != 0, "Cliff must greater 0");
        require(_amount != 0, "Amount must greater 0");
        require(!locks[_msgSender()].isActive, "Duplicate lock");
        require(token.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        LockInfo memory lockInfo = LockInfo(true, _amount, block.timestamp, _cliff);
        locks[_msgSender()] = lockInfo;
    }

    function getLockInfo(address _user) external view returns (LockInfo memory) {
        return locks[_user];
    }

    function updateLockInfo(uint256 _amount, uint256 _cliff) external {
        LockInfo memory lockInfo = locks[_msgSender()];

        require(lockInfo.isActive, "No lock info");
        require(lockInfo.amount >= _amount, "Amount must greater or equal old amount");
        require(lockInfo.cliff >= _cliff, "Cliff must greater or equal old cliff");
        require(token.transferFrom(msg.sender, address(this), _amount - lockInfo.amount), "transfer failed");

        locks[_msgSender()].amount = _amount;
        locks[_msgSender()].cliff = _cliff;
    }

    function claimToken() external {
        LockInfo memory lockInfo = locks[_msgSender()];

        require(lockInfo.isActive, "No lock info");
        require(lockInfo.startCliffTime + lockInfo.cliff >= block.timestamp, "Cliff time not over yet");
        require(token.transfer(_msgSender(), lockInfo.amount), "transfer failed");

        locks[_msgSender()].isActive = false;
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

