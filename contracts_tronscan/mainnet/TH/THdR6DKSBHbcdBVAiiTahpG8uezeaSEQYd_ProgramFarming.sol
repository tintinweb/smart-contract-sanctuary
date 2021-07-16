//SourceUnit: ProgramFarming.sol

pragma solidity ^0.5.8;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
// Special interface for calling TRC10 methods
// see more: https://developers.tron.network/docs/trc10-transfer-in-smart-contracts-2
// Have fun reading it. Hopefully it's bug-free. God bless.
*/
contract TRC10Integrator {
    trcToken internal programID;

    function _safeTRC10Transfer(address payable _to, uint256 _amount) internal {
        uint256 programBalance = address(this).tokenBalance(programID);

        if (_amount > programBalance) {
            _to.transferToken(programBalance, programID);
        } else {
            _to.transferToken(_amount, programID);
        }
    }

    function getTokenID() public view returns(trcToken) {
        return programID;
    }

}

/**
// Note that it's ownable and the owner wields tremendous power. The ownership
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
*/
contract ProgramFarming is Ownable, TRC10Integrator {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;     // How many GRM the user has provided in staking.
        uint256 rewardDebt; // Reward debt
        uint256 depositTime; // Time to first deposit
        //
        // We do some fancy math here. Basically, any point in time, the amount of GRM
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accProgramPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws  tokens to a pool. Here's what happens:
        //   1. The pool's `accProgramPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }



    // The block number when Program farming starts.
    uint256[] public phases;
    uint256 public lastRewardBlock;

    uint256 internal accProgramPerShare;  // Accumulated ProgramToken per share, times 1e11

    // Bonus multiplier for early prg makers.
    uint256 public BONUS_MULTIPLIER_1 = 174; // first 10,512,000 blocks - 2,0`Program in Block
    uint256 public BONUS_MULTIPLIER_2 = 87; // next  10,512,000 blocks - 1,0 Program in Block
    uint256 public BONUS_MULTIPLIER_3 = 43; //  next  10,512,000 blocks - 0,5 Program in BLock
    uint256 public BONUS_MULTIPLIER_4 = 37; //  last  77,360,000 blocks - 0,3 Program in Block

    uint256 public baseProgramPerBlock = 1e4; // 0,01 PRGRM

    // Info of each user that stakes GRM.
    mapping (address => UserInfo) public userInfo;

    uint256 public programSupply; // How much their ProgramTokens deposited users

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);


    constructor(uint256 _startBlock, uint256 _programID) public {
        programID = trcToken(_programID);
        phases.push(_startBlock);
        phases.push(phases[0].add(10512000));
        phases.push(phases[1].add(10512000));
        phases.push(phases[2].add(10512000));
        phases.push(phases[3].add(77360000));
    }


    function setProgramPerBlock(uint256 _newAmount) public onlyOwner{
        baseProgramPerBlock = _newAmount;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= phases[0]) {
            return  _to.sub(_from);
        }
        else if (_to <= phases[1]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_1);
        }
        else if (_to <= phases[2]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_2);
        }
        else if (_to <= phases[3]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_3);
        }
        else if (_to <= phases[4]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_4);
        }
        else if (_from >= phases[4]) {
            return _to.sub(_from);
        }
        else {
            return phases[4].sub(_from).mul(BONUS_MULTIPLIER_1).add(_to.sub(phases[4]));
        }
    }


    // View function to see pending ProgramTokens on frontend.
    function pendingProgram(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 programPerShare = accProgramPerShare;

        if (block.number > lastRewardBlock && programSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 programReward = (multiplier.mul(baseProgramPerBlock));
            programPerShare = programPerShare.add(programReward.mul(1e11).div(programSupply));
        }
        return user.amount.mul(programPerShare).div(1e11).sub(user.rewardDebt);
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (programSupply == 0) {
              lastRewardBlock = block.number;
              return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 programReward = multiplier.mul(baseProgramPerBlock);
        accProgramPerShare = accProgramPerShare.add(programReward.mul(1e11).div(programSupply));
        lastRewardBlock = block.number;
    }


    // Deposit Program
    function deposit() external payable {
        require(msg.tokenid == getTokenID(), "ProgramFarming: invalid ProgramToken ID");
        uint256 _amount = msg.tokenvalue;
        programSupply = programSupply.add(_amount);
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        user.depositTime = block.timestamp;

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accProgramPerShare).div(1e11);
        emit Deposit(msg.sender, _amount);
    }


    // Withdraw GRM from Interstellar.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "ProgramFarming: amount not good");
        require(user.depositTime.add(5 days) < now, "ProgramFarming: Less 5 days");

        updatePool();
        uint256 pending = user.amount.mul(accProgramPerShare).div(1e11).sub(user.rewardDebt);
        _safeProgramTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accProgramPerShare).div(1e11);
        programSupply = programSupply.sub(_amount);

        _safeProgramTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        _safeProgramTransfer(msg.sender, user.amount);
        programSupply = programSupply.sub(user.amount);

        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    // Safe ProgramTokens transfer function, just in case if rounding error causes pool to not have enough ProgramTokens.
     function _safeProgramTransfer(address payable _to, uint256 _amount) internal {
        _safeTRC10Transfer(_to, _amount);
     }


    function withdrawTRX(address payable _sender) public onlyOwner {
        _sender.transfer(address(this).balance);
    }


    function setPhases(uint256 _id, uint256 _newAmount) public onlyOwner {
        phases[_id] = _newAmount;
    }


    function setMultipliers(uint256 _multiplier, uint256 _newAmount) public onlyOwner {
        if (_multiplier == 1) {
            BONUS_MULTIPLIER_1 = _newAmount;
        }
        if (_multiplier == 2) {
            BONUS_MULTIPLIER_2 = _newAmount;
        }
        if (_multiplier == 3) {
            BONUS_MULTIPLIER_3 = _newAmount;
        }
        if (_multiplier == 4) {
            BONUS_MULTIPLIER_4 = _newAmount;
        }
    }

}