// SPDX-License-Identifier: MIT

/*
PermaVault is based on TokenVault https://gist.github.com/rstormsf/7cfb0c6b7a835c0c67b4a394b4fd9383

The PermaVault, different from a VestingVault, will lock a token ammount and release
the token to the treasury wallet during a period of time. Treasury wallet still has to be parsed 
on lock.

These tokens will be released daily during a timespam that starts at _lockCliffInDays
and ends at _lockDurationInDays

Once the token ammount is deposited to PermaVault, it can't be reverted. Not even by
the contract owner.

The tokens released daily is equal to (_amount)/(_lockDurationInDays - _lockCliffInDays)
*/

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract PermaVault is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct Lock {
        uint256 startTime;
        uint256 amount;
        uint16 lockDuration;
        uint16 daysClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event Deposit(address indexed recipient);
    event tokenReleased(address indexed recipient, uint256 amountClaimed);

    ERC20 public token;
    
    mapping (address => Lock) private tokenLocks;

    constructor(ERC20 _token) {
        require(address(_token) != address(0));
        token = _token;
    }
    
    function addTokentoVault(
        address _recipient,
        uint256 _amount,
        uint16 _lockDurationInDays,
        uint16 _lockCliffInDays    
    ) 
        external
        onlyOwner
    {
        require(tokenLocks[_recipient].amount == 0, "Tokens already added to PermaVault.");
        require(_lockCliffInDays <= 10*365, "Cliff greater than 10 years");
        require(_lockDurationInDays <= 25*365, "Duration greater than 25 years");
        
        uint256 amountReleasedPerDay = _amount.div(_lockDurationInDays);
        require(amountReleasedPerDay > 0, "amountReleasedPerDay > 0");

        // Transfer the locked tokens under the control of the PermaVault
        require(token.transferFrom(owner(), address(this), _amount));

        Lock memory lock = Lock({
            startTime: currentTime() + _lockCliffInDays * 1 days,
            amount: _amount,
            lockDuration: _lockDurationInDays,
            daysClaimed: 0,
            totalClaimed: 0,
            recipient: _recipient
        });
        tokenLocks[_recipient] = lock;
        emit Deposit(_recipient);
    }

    /// @notice Allows treasury to claim their unlocked tokens. Errors if no tokens have been unlocked
    function releaseUnlockedTokens() external {
        uint16 daysLocked;
        uint256 amountLocked;
        (daysLocked, amountLocked) = calculateRelease(msg.sender);
        require(amountLocked > 0, "0 Tokens to release");

        Lock storage tokenLock = tokenLocks[msg.sender];
        tokenLock.daysClaimed = uint16(tokenLock.daysClaimed.add(daysLocked));
        tokenLock.totalClaimed = uint256(tokenLock.totalClaimed.add(amountLocked));
        
        require(token.transfer(tokenLock.recipient, amountLocked), "no tokens");
        emit tokenReleased(tokenLock.recipient, amountLocked);
    }

    function getReleaseStartTime(address _recipient) private view returns(uint256) {
        Lock storage tokenLock = tokenLocks[_recipient];
        return tokenLock.startTime;
    }

    function getReleaseAmount(address _recipient) public view returns(uint256) {
        Lock storage tokenLock = tokenLocks[_recipient];
        return tokenLock.amount;
    }

    /// @notice Calculate the locked tokens and time remaining for full unlock
    /// Due to rounding errors once total lock duration is reached, returns the entire left unlocked amount
    /// Returns (0, 0) if cliff has not been reached
    function calculateRelease(address _recipient) public view returns (uint16, uint256) {
        Lock storage tokenLock = tokenLocks[_recipient];

        require(tokenLock.totalClaimed < tokenLock.amount, "Tokens fully released");

        // For locks created with a future start date, that hasn't been reached, return 0, 0
        if (currentTime() < tokenLock.startTime) {
            return (0, 0);
        }

        // Check cliff was reached
        uint elapsedDays = currentTime().sub(tokenLock.startTime - 1 days).div(1 days);

        // If over unlocking duration, all tokens unlock
        if (elapsedDays >= tokenLock.lockDuration) {
            uint256 remainingGrant = tokenLock.amount.sub(tokenLock.totalClaimed);
            return (tokenLock.lockDuration, remainingGrant);
        } else {
            uint16 daysLocked = uint16(elapsedDays.sub(tokenLock.daysClaimed));
            uint256 amountReleasedPerDay = tokenLock.amount.div(uint256(tokenLock.lockDuration));
            uint256 amountLocked = uint256(daysLocked.mul(amountReleasedPerDay));
            return (daysLocked, amountLocked);
        }
    }

    function currentTime() private view returns(uint256) {
        return block.timestamp;
    }
}