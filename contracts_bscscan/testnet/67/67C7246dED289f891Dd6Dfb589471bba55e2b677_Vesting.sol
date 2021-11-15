// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting {
    IERC20 public immutable token;

    struct Lock {
        address receiver;
        uint256 amount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 withdrawn;
    }

    mapping(address => Lock) public receiverLock;

    event OnLock(address indexed sender, address indexed receiver, uint256 amount, uint256 startTimestamp, uint256 endTimestamp);
    event OnWithdraw(address indexed receiver, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Vesting: Token must not be 0x0");
        token = IERC20(_token);
    }

    // @notice locks tokens. The only one lock for a receiver can exist.
    // @param receiver address what tokens are vested to.
    // @param amount of locked tokens.
    // @param startTimestamp when vesting starts. Representing the UNIX timestamp and must not be earlier then now.
    // @param endTimestamp when vesting ends. Representing the UNIX timestamp and must not be earlier then `startTimestamp`.
    function lockTokens(address receiver, uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external {
        require(receiver != address(0), "Vesting: must not be 0x0");
        require(amount > 0, "Vesting: locked amount must be > 0");
        require(startTimestamp >= block.timestamp, "Vesting: startTimestamp must be later then now");
        require(startTimestamp < endTimestamp, "Vesting: endTimestamp must be later then startTimestamp");
        require(endTimestamp < 10000000000, "Vesting: Invalid unlock time, it must be unix time in seconds");
        require(receiverLock[receiver].amount == 0, "Vesting: lock for receiver already exists");

        receiverLock[receiver] = Lock(receiver, amount, startTimestamp, endTimestamp, 0);

        require(token.transferFrom(msg.sender, address(this), amount), "Vesting: unable to transfer tokens to the contract's address");
        emit OnLock(msg.sender, receiver, amount, startTimestamp, endTimestamp);
    }

    // @notice withdraws tokens which were vested and weren't withdrawn before
    function withdraw() external {
        Lock storage lock = receiverLock[msg.sender];
        require(block.timestamp > lock.startTimestamp, "Vesting: vesting hasn't been started yet");

        uint256 amountToWithdraw = _allowedToWithdraw(lock);

        lock.withdrawn += amountToWithdraw;

        require(token.transfer(msg.sender, amountToWithdraw), "Vesting: Transfer was fallen");
        emit OnWithdraw(msg.sender, amountToWithdraw);
    }

    function _allowedToWithdraw(Lock storage lock) private view returns (uint256) {
        uint256 timePassed = block.timestamp - lock.startTimestamp;
        uint256 timeVesting = lock.endTimestamp - lock.startTimestamp;

        if (timePassed >= timeVesting) {
            return lock.amount - lock.withdrawn;
        }
        return ((lock.amount * timePassed) / timeVesting) - lock.withdrawn;
    }

    // @notice calculates amount of tokens which a user is allowed to withdraw.
    // @param receiver user's address.
    // @return amount of tokens which `receiver` is allowed to withdraw.
    function allowedToWithdraw(address receiver) public view returns (uint256) {
        Lock storage lock = receiverLock[receiver];
        return _allowedToWithdraw(lock);
    }

    // @notice returns parameters of a user's lock
    // @param receiver user's address.
    // @return parameters of the `receiver`'s lock: amount, startTimestamp, end timeStamp
    // and withdrawn(how many tokens were already withdrawn).
    function lockOf(address receiver) external view returns (uint256, uint256, uint256, uint256) {
        Lock storage lock = receiverLock[receiver];
        return (lock.amount, lock.startTimestamp, lock.endTimestamp, lock.withdrawn);
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

