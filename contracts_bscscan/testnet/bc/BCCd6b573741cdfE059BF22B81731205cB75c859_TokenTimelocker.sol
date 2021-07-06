/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract TokenTimelocker {

    // ERC20 basic token contract being held
    IERC20 immutable private token;

    struct Timelock {
        address recipient;
        uint256 releaseTime;
        uint256 amount;
    }

    event TimelockCreated(
        address indexed creator,
        address indexed recipient,
        uint256 releaseTime,
        uint256 amount
    );

    event TokenClaimed(
        uint    index,
        address indexed recipient,
        uint256 amount
    );

    mapping (uint256 => Timelock) public timelocks;
    uint256 public timelockCount;

    address payable public owner;
    mapping(address => bool) public whiteList;
    
    constructor (IERC20 _token) {
        // solhint-disable-next-line not-rely-on-time
        token = _token;
        owner = payable(msg.sender);
    }

    function createTimelockFrom(
        address _recipient,
        address _from,
        uint256 _lockDurationInDays,
        uint256 _amount
    )
    external {
        uint releaseTime = block.timestamp + _lockDurationInDays * 1 days;

        Timelock memory timelock = Timelock({
            recipient: _recipient,
            releaseTime: releaseTime,
            amount: _amount
        });
        
        require(whiteList[msg.sender], "NOT_ON_THE_WHITELIST");
        require(token.transferFrom(_from, address(this), timelock.amount));

        
        timelocks[timelockCount] = timelock;
        timelockCount += 1;

        emit TimelockCreated(_from, _recipient, releaseTime, _amount);
    }
    
    function createTimelock(
        address _recipient,
        uint256 _lockDurationInDays,
        uint256 _amount
    )
    external {
        uint releaseTime = block.timestamp + _lockDurationInDays * 1 days;

        Timelock memory timelock = Timelock({
            recipient: _recipient,
            releaseTime: releaseTime,
            amount: _amount
        });

        require(token.transferFrom(msg.sender, address(this), timelock.amount));

        timelocks[timelockCount] = timelock;
        timelockCount += 1;

        emit TimelockCreated(msg.sender, _recipient, releaseTime, _amount);
    }

    function release(uint index)
    external {
        Timelock storage timelock = timelocks[index];

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= timelock.releaseTime, "TokenTimelock: current time is before release time");

        uint toSend = timelock.amount;
        timelock.amount = 0;

        require(token.transfer(timelock.recipient, toSend));
        emit TokenClaimed(index, timelock.recipient, toSend);
    }
    
        
    function addToWhiteList(address user)
    external
    {
        require(msg.sender == owner);
        whiteList[user] = true;
    }
    
    function removeFromWhiteList(address user)
    external
    {
        require(msg.sender == owner);
        whiteList[user] = false;
    }
        
    function transferOwnership(address newOwner) 
    public {
        require(msg.sender == owner);
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = payable(newOwner);
    }
}