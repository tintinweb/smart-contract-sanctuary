/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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

// File: contracts/LiquidityLock.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;


contract LiquidityLock {
    event Deposit(
        address owner,
        address token,
        uint256 amount,
        uint256 deadline,
        uint256 lockID
    );

    event Withdraw(address owner, address token, uint256 amount);

    struct Lock {
        address owner;
        address token;
        uint256 amount;
        uint256 deadline;
    }

    mapping(uint256 => Lock) public locks;

    uint256 public lockCount = 0;

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _length
    ) public returns (uint256) {
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount)
        );

        lockCount += 1;

        uint256 _deadline = block.timestamp + _length;

        locks[lockCount] = Lock({
            owner: msg.sender,
            token: _token,
            amount: _amount,
            deadline: _deadline
        });

        emit Deposit(msg.sender, _token, _amount, _deadline, lockCount);
        
        return lockCount;
    }

    function withdraw(uint256 _lockID) public {
        Lock storage currentLock = locks[_lockID];

        require(currentLock.owner == msg.sender, "Not owner");
        require(currentLock.deadline <= block.timestamp, "Not reached deadline");

        IERC20(currentLock.token).transfer(msg.sender, currentLock.amount);

        emit Withdraw(currentLock.owner, currentLock.token, currentLock.amount);

        delete locks[_lockID];
    }
    
    function currentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}