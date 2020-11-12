// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


// 
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

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Staker is Ownable {
    using SafeMath for uint256;

    string public name = "High Stakes Staking Game";

    // Constants determining the game timeframe.
    uint256 public constant maxWaitTime = 6 days;
    uint256 public constant minimalWaitTime = 3 days;
    uint256 public constant contractCoolDownTime = 1 days;
    uint256 public constant referralLockBonus = 1 days;

    // Total risk and total ETH, combined with the user's risk will determine the maximal amount the user can extract.
    uint256 public totalRisk = 0;
    uint256 public totalETH = 0;

    // Per user risk and staking balance.
    mapping(address => uint256) public stakerRisk;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public referralStake;

    // Each user has a different time lock (time when he can obtain the reward). This time is randomized on each stake.
    mapping(address => uint256) public timeLocked;

    uint256 public contractLaunchTime = now + contractCoolDownTime;

    // Dev has no way to tamper with the Aleatory game.
    // devFeesPercent determines the percentage of all tokens sent staked that are provided as dev incentives for future development.
    // After the game has ended e.g., once contractLaunchTime + maxWaitTime, then all remaining funds are considered a donation.
    uint256 private devETH;
    uint256 public constant devFeesPercent = 5;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function sqrt(uint y) internal pure returns (uint) {
        uint z = 0;
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    function randWaitTime() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
            block.number
        )));

        return minimalWaitTime + referralLockBonus + (seed - ((seed / maxWaitTime) * maxWaitTime)) * 1 seconds;
    }

    function getRisk(uint256 secondsPassed, uint256 ethAdded) private view returns(uint256) {
        // The risk is determined by how early the ETH is staked and how much ETH.
        // The risk is linearly decaying. Initial multiplier is x4. Get in early and you have a higher reward.
        uint256 timeLeft = (maxWaitTime - secondsPassed) * 3;
        if (secondsPassed > maxWaitTime) {
            timeLeft = 0;
        }
        timeLeft += maxWaitTime;
        return timeLeft * ethAdded;
    }


    modifier checkStart() {
        require(contractLaunchTime <= now, "Contract staking hasn't started yet.");
        _;
    }

    function stake(address referral) public payable checkStart returns (bool success) {
        require(msg.value >= 10000000000000000, "Cannot stake less than 0.01 ETH.");
        require(referral != msg.sender, "You can't refer yourself.");

        // Add current stake to the referral stake count. This is used to calculate the exit time reduction.
        referralStake[referral] += msg.value;

        // Get the risk of the current staking transaction.
        uint256 risk = getRisk(now - (contractLaunchTime), msg.value);

        // Add the risk to the user's total risk and to the grand total contract staked risk.
        stakerRisk[msg.sender] += risk;
        totalRisk += risk;

        // Randomize the user's unlock time.
        timeLocked[msg.sender] = randWaitTime();

        // Distribute ETH between the reward pool and the dev fund.
        uint256 valueMinusFees = msg.value * (100 - devFeesPercent) / 100;
        stakingBalance[msg.sender] += msg.value;
        totalETH += valueMinusFees;
        devETH += msg.value - valueMinusFees;
        emit Staked(msg.sender, msg.value);
        return true;
    }

    function unstakeTokens() public returns (bool success) {
        // First make sure the user can withdraw his tokens and that there is ETH to withdraw.
        uint256 balance = stakingBalance[msg.sender];
        require(getUserUnlockTime(msg.sender) <= now, "Your lock period has not yet ended");
        require(balance > 0, "Can't unstake 0 ETH.");

        // Calculate the amount of ETH the user is entitled to.
        uint256 risk = stakerRisk[msg.sender];
        uint256 exitValue = getCurrentUserExitValue(msg.sender);

        // Extract ETH.
        stakingBalance[msg.sender] = 0;
        stakerRisk[msg.sender] = 0;
        totalETH -= exitValue;
        totalRisk -= risk;
        if (!msg.sender.send(exitValue)) {
            stakingBalance[msg.sender] = balance;
            totalETH += exitValue;

            stakerRisk[msg.sender] = risk;
            totalRisk += risk;
            return false;
        }
        emit Withdrawn(msg.sender, exitValue);
        return true;
    }

    function getUserUnlockTime(address user) public view returns (uint256) {
        uint256 senderLock = timeLocked[user];
        uint256 referredETH = referralStake[user];

        // For each 1ETH referred into the contract, the user reduces his unlock time by 1 hour.
        senderLock -= referredETH * 36 seconds / 10000000000000000;
        if (senderLock < minimalWaitTime) {
            // The minimal lock time must hold. Referrals can't reduce lock lower than minimalWaitTime.
            senderLock = minimalWaitTime;
        }
        return contractLaunchTime + senderLock;
    }

    function getCurrentUserExitValue(address user) public view returns (uint256) {
        // User exit value is determined by the risk the user took and the total risk taken by all other users.
        if (totalRisk > 0) {
            if (stakerRisk[user] / sqrt(totalRisk) > 1) {
                return totalETH;
            }
            return totalETH * stakerRisk[user] / sqrt(totalRisk);
        }
        return 0;
    }

    function getUserEthStaked(address user) public view returns (uint256) {
        return stakingBalance[user];
    }

    function getCurrentPotential() public view returns (uint256) {
        // Current potential shows the potential ETH gained by staking 1 ETH NOW.
        uint256 currentRisk = getRisk(now - (contractLaunchTime), 1000000000000000000);
        if (totalRisk > 0) {
            uint256 potentialGains = totalETH * currentRisk / sqrt(totalRisk);
            if (potentialGains > totalETH) {
                potentialGains = totalETH;
            }
            return potentialGains;
        }
        return 0;
    }

    function withdrawDevFund() public payable onlyOwner returns (bool success) {
        // Dev fund can be withdrawn only AFTER everyone is unlocked.
        require(contractLaunchTime + maxWaitTime * 1 seconds <= now, "Contract hasn't ended yet.");
        devETH += totalETH;
        totalETH = 0;

        uint256 balance = devETH;
        devETH = 0;

        if (!msg.sender.send(balance)) {
            devETH = balance;
            return false;
        }
        return true;
    }
}