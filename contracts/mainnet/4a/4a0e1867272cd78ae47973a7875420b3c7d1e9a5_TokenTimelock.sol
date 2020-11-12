// SPDX-License-Identifier: MIT

pragma solidity ^0.4.23;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    struct Timelock {
      uint256 amount; // amount of tokens to lock
      uint256 releaseTime; // timestamp when token release is enabled
    }

    // tokenAddress => ( ownerAddress => { amount, releaseTime } )
    mapping(address => mapping(address => Timelock)) public timelockMap;

    event TokenTimelocked(ERC20 indexed token, address indexed tokenOwner, uint256 amount, uint256 releaseTime);
    event TokenTimelockReleased(ERC20 indexed token, address indexed tokenOwner, uint256 amount, uint256 releaseTime, uint256 blockTime);

    constructor () public {}

    /**
     * @return the amount of tokens locked by the tokenOwner.
     */
    function getTokenOwnerLockAmount(ERC20 token, address tokenOwner) public view returns (uint256) {
        return timelockMap[address(token)][tokenOwner].amount;
    }
    /**
     * @return the releaseTime set by the tokenOwner.
     */
    function getTokenOwnerLockReleaseTime(ERC20 token, address tokenOwner) public view returns (uint256) {
        return timelockMap[address(token)][tokenOwner].releaseTime;
    }

    /**
     * @notice Locks senders tokens for the specified time
     * Must approve the contract for transfering tokens before calling this function
     */
    function lock(ERC20 token, uint256 amount, uint256 releaseTime) public returns (bool) {
        require(releaseTime > block.timestamp, "release time is before current time");
        require(amount > 0, "token amount is invalid");
        
        address _tokenOwner = msg.sender;
        address _tokenAddr = address(token);
        require(_tokenAddr != address(0), "token address is invalid");
        
        Timelock storage _lock = timelockMap[_tokenAddr][_tokenOwner];
        require(_lock.amount == 0 && _lock.releaseTime == 0, "a lock for the token & sender already exists");
        require(token.transferFrom(_tokenOwner, address(this), amount), "transferFrom failed");

        timelockMap[_tokenAddr][_tokenOwner] = Timelock(amount, releaseTime);
        
        emit TokenTimelocked(token, _tokenOwner, amount, releaseTime);
        
        return true;
    }

    /**
     * @notice Transfers tokens held by timelock to tokenOwner.
     */
    function release(ERC20 token) public returns (bool) {
        address _tokenAddr = address(token);
        address _tokenOwner = msg.sender;
        require(_tokenAddr != address(0), "token address is invalid");

        Timelock storage _lock = timelockMap[_tokenAddr][_tokenOwner];
        require(_lock.amount > 0 && _lock.releaseTime > 0, "a lock for the token & sender doesn't exist");
        require(block.timestamp >= _lock.releaseTime, "current time is before release time");

        uint256 balance = token.balanceOf(address(this));
        require(_lock.amount <= balance, "not enough tokens to release");
        require(token.transfer(_tokenOwner, _lock.amount), "transfer failed");

        timelockMap[_tokenAddr][_tokenOwner].amount = 0;
        timelockMap[_tokenAddr][_tokenOwner].releaseTime = 0;

        emit TokenTimelockReleased(token, _tokenOwner, _lock.amount, _lock.releaseTime, block.timestamp);
        
        return true;
    }
}