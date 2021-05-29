// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ScheduleCalc.sol";

// interface with ERC20 and the burn function interface from the associated Token contract
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function decimals() external view returns (uint8);
}

contract TokenLockup {
    IERC20Burnable public token;
    string private _name;
    string private _symbol;

    ReleaseSchedule[] public releaseSchedules;
    uint public minReleaseScheduleAmount;
    uint public maxReleaseDelay;

    mapping(address => Timelock[]) public timelocks;
    mapping(address => uint) internal _totalTokensUnlocked;
    mapping(address => mapping(address => uint)) internal _allowances;

    event Approval(address indexed from, address indexed spender, uint amount);
    event TimelockBurned(address indexed from, uint timelockId);
    event ScheduleCreated(address indexed from, uint scheduleId);
    event ScheduleFunded(address indexed from, address indexed to, uint indexed scheduleId, uint amount, uint commencementTimestamp, uint timelockId);

    /*  The constructor that specifies the token, name and symbol
        The name should specify that it is an unlock contract
        The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
    */
    constructor (
        address _token,
        string memory name_,
        string memory symbol_,
        uint _minReleaseScheduleAmount,
        uint _maxReleaseDelay
    ) {
        _name = name_;
        _symbol = symbol_;
        token = IERC20Burnable(_token);

        require(_minReleaseScheduleAmount > 0, "Min schedule amount > 0");
        minReleaseScheduleAmount = _minReleaseScheduleAmount;
        maxReleaseDelay = _maxReleaseDelay;
    }

    function createReleaseSchedule(
        uint releaseCount, // total number of releases including any initial "cliff'
        uint delayUntilFirstReleaseInSeconds, // "cliff" or 0 for immediate relase
        uint initialReleasePortionInBips, // in 100ths of 1%
        uint periodBetweenReleasesInSeconds
    )
    external
    returns
    (
        uint unlockScheduleId
    ) {
        require(delayUntilFirstReleaseInSeconds <= maxReleaseDelay, "first release > max");

        require(releaseCount >= 1, "< 1 release");
        require(initialReleasePortionInBips <= ScheduleCalc.BIPS_PRECISION, "release > 100%");
        if (releaseCount > 1) {
            require(periodBetweenReleasesInSeconds > 0, "period = 0");
        }
        if (releaseCount == 1) {
            require(initialReleasePortionInBips == ScheduleCalc.BIPS_PRECISION, "released < 100%");
        }

        releaseSchedules.push(ReleaseSchedule(
                releaseCount,
                delayUntilFirstReleaseInSeconds,
                initialReleasePortionInBips,
                periodBetweenReleasesInSeconds
            ));

        emit ScheduleCreated(msg.sender, unlockScheduleId);
        // returning the index of the newly added schedule
        return releaseSchedules.length - 1;
    }

    function fundReleaseSchedule(
        address to,
        uint amount,
        uint commencementTimestamp, // unix timestamp
        uint scheduleId
    ) public returns(bool) {
        require(amount >= minReleaseScheduleAmount, "amount < min funding");
        require(to != address(0), "to 0 address");
        require(scheduleId < releaseSchedules.length, "bad scheduleId");
        require(amount >= releaseSchedules[scheduleId].releaseCount, "< 1 token per release");
        // It will revert via ERC20 implementation if there's no allowance
        require(token.transferFrom(msg.sender, address(this), amount));
        require(
            commencementTimestamp <= block.timestamp + maxReleaseDelay
        , "commencement time out of range");

        require(
            commencementTimestamp + releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds  <=
            block.timestamp + maxReleaseDelay
        , "initial release out of range");

        Timelock memory timelock;
        timelock.scheduleId = scheduleId;
        timelock.commencementTimestamp = commencementTimestamp;
        timelock.totalAmount = amount;

        timelocks[to].push(timelock);

        emit ScheduleFunded(msg.sender, to, scheduleId, amount, commencementTimestamp, timelocks[to].length - 1);
        return true;
    }

    function batchFundReleaseSchedule(
        address[] memory recipients,
        uint[] memory amounts,
        uint[] memory commencementTimestamps, // unix timestamp
        uint[] memory scheduleIds
    ) external returns (bool) {
        require(amounts.length == recipients.length, "mismatched array length");
        for (uint i; i < recipients.length; i++) {
            require(fundReleaseSchedule(recipients[i], amounts[i], commencementTimestamps[i], scheduleIds[i]));
        }

        return true;
    }

    function lockedBalanceOf(address who) public view returns (uint amount) {
        for (uint i = 0; i < timelocks[who].length; i++) {
            amount += lockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    function unlockedBalanceOf(address who) public view returns (uint amount) {
        for (uint i = 0; i < timelocks[who].length; i++) {
            amount += unlockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    function lockedBalanceOfTimelock(address who, uint timelockIndex) public view returns (uint locked) {
        return timelocks[who][timelockIndex].totalAmount - totalUnlockedToDateOfTimelock(who, timelockIndex);
    }

    function unlockedBalanceOfTimelock(address who, uint timelockIndex) public view returns (uint unlocked) {
        return totalUnlockedToDateOfTimelock(who, timelockIndex) - timelocks[who][timelockIndex].tokensTransferred;
    }

    function totalUnlockedToDateOfTimelock(address who, uint timelockIndex) public view returns (uint unlocked) {
        return calculateUnlocked(
            timelocks[who][timelockIndex].commencementTimestamp,
            block.timestamp,
            timelocks[who][timelockIndex].totalAmount,
            timelocks[who][timelockIndex].scheduleId
        );
    }

    function viewTimelock(address who, uint256 index) public view
    returns (Timelock memory timelock) {
        return timelocks[who][index];
    }

    function balanceOf(address who) external view returns (uint) {
        return unlockedBalanceOf(who) + lockedBalanceOf(who);
    }

    function transfer(address to, uint value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(_allowances[from][msg.sender] >= value, "value > allowance");
        _allowances[from][msg.sender] -= value;
        return _transfer(from, to, value);
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "decrease > allowance");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function decimals() public view returns (uint8) {
        return token.decimals();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function burn(uint timelockIndex, uint confirmationIdPlusOne) external returns(bool) {
        require(timelockIndex < timelocks[msg.sender].length, "No schedule");

        // this also protects from overflow below
        require(confirmationIdPlusOne == timelockIndex + 1, "Burn not confirmed");

        // actually burning the remaining tokens from the unlock
        token.burn(lockedBalanceOfTimelock(msg.sender, timelockIndex) + unlockedBalanceOfTimelock(msg.sender, timelockIndex));

        // overwrite the timelock to delete with the timelock on the end which will be discarded
        // if the timelock to delete is on the end, it will just be deleted in the step after the if statement
        if (timelocks[msg.sender].length - 1 != timelockIndex) {
            timelocks[msg.sender][timelockIndex] = timelocks[msg.sender][timelocks[msg.sender].length - 1];
        }
        // delete the timelock on the end
        timelocks[msg.sender].pop();

        emit TimelockBurned(msg.sender, timelockIndex);
        return true;
    }

    function _transfer(address from, address to, uint value) internal returns (bool) {
        require(unlockedBalanceOf(from) >= value, "amount > unlocked");

        uint remainingTransfer = value;

        // transfer from unlocked tokens
        for (uint i = 0; i < timelocks[from].length; i++) {
            // if the timelock has no value left
            if (timelocks[from][i].tokensTransferred == timelocks[from][i].totalAmount) {
                continue;
            } else if (remainingTransfer > unlockedBalanceOfTimelock(from, i)) {
                // if the remainingTransfer is more than the unlocked balance use it all
                remainingTransfer -= unlockedBalanceOfTimelock(from, i);
                timelocks[from][i].tokensTransferred += unlockedBalanceOfTimelock(from, i);
            } else {
                // if the remainingTransfer is less than or equal to the unlocked balance
                // use part or all and exit the loop
                timelocks[from][i].tokensTransferred += remainingTransfer;
                remainingTransfer = 0;
                break;
            }
        }

        // should never have a remainingTransfer amount at this point
        require(remainingTransfer == 0, "bad transfer");

        require(token.transfer(to, value));
        return true;
    }

    function transferTimelock(address to, uint value, uint timelockId) external returns (bool) {
        require(unlockedBalanceOfTimelock(msg.sender, timelockId) >= value, "amount > unlocked");
        timelocks[msg.sender][timelockId].tokensTransferred += value;
        require(token.transfer(to, value));
        return true;
    }

    function calculateUnlocked(uint commencedTimestamp, uint currentTimestamp, uint amount, uint scheduleId) public view returns (uint unlocked) {
        return ScheduleCalc.calculateUnlocked(commencedTimestamp, currentTimestamp, amount, releaseSchedules[scheduleId]);
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0));
        require(spender != address(0), "spender is 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function scheduleCount() external view returns (uint count) {
        return releaseSchedules.length;
    }

    function timelockOf(address who, uint index) external view returns (Timelock memory timelock) {
        return timelocks[who][index];
    }

    function timelockCountOf(address who) external view returns (uint) {
        return timelocks[who].length;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

struct ReleaseSchedule {
    uint releaseCount;
    uint delayUntilFirstReleaseInSeconds;
    uint initialReleasePortionInBips;
    uint periodBetweenReleasesInSeconds;
}

struct Timelock {
    uint scheduleId;
    uint commencementTimestamp;
    uint tokensTransferred;
    uint totalAmount;
}

library ScheduleCalc {
    uint constant BIPS_PRECISION = 10000;

    function calculateUnlocked(uint commencedTimestamp, uint currentTimestamp, uint amount, ReleaseSchedule memory releaseSchedule) external pure returns (uint unlocked) {
        if(commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint secondsElapsed = currentTimestamp - commencedTimestamp;

        // return the full amount if the total lockup period has expired
        // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        // unlocking the full amount unlocks any remainder amounts in the final unlock period
        // this is done first to reduce computation
        if (secondsElapsed >= releaseSchedule.delayUntilFirstReleaseInSeconds +
        (releaseSchedule.periodBetweenReleasesInSeconds * (releaseSchedule.releaseCount - 1))) {
            return amount;
        }

        // unlock the initial release if the delay has elapsed
        if (secondsElapsed >= releaseSchedule.delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * releaseSchedule.initialReleasePortionInBips) / BIPS_PRECISION;

            // if at least one period after the delay has passed
            if (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds
                >= releaseSchedule.periodBetweenReleasesInSeconds) {

                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint additionalUnlockedPeriods =
                (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds) /
                releaseSchedule.periodBetweenReleasesInSeconds;

                // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                // multiplication is applied before division to delay truncating to the smallest unit
                // this distributes unlocked tokens more evenly across unlock periods
                // than truncated division followed by multiplication
                unlocked += ((amount - unlocked) * additionalUnlockedPeriods) / (releaseSchedule.releaseCount - 1);
            }
        }

        return unlocked;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/ScheduleCalc.sol": {
      "ScheduleCalc": "0x80a61e417c51c49fb02c8f77cd62cdcd4fb8332d"
    }
  }
}