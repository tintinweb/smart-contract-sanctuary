/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

/** EthereumStake.Farm ETH 2.0 Validation pool
 *  
 * This contract is our early version of the pool for ETH 2.0 Phase 0. 
 * There are some important things you should be aware of before depositing to this pool:
 * - Currently this pool is custodial and centralized.
 * - Phase 0 of ETH 2.0 doesn't yet support withdrawals.
 * - This pool requires depositors to have some staked ETHYS.
 * 
 * When ETH 2.0 support withdrawing to smart contracts we will upgrade the pool.
 * You will be able to import your EVPS-V1 tokens into the decentralized system
 * once it is avaliable.
 *
 * Until we can migrate to a decentralized solution (when ETH 2.0 Supports this) the 
 * _owner address will have an incredible amount of power within this contract. 
 * This will be fully mitigated in the decentralized migration. 
 *  
 * - Team ETHY
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma experimental ABIEncoderV2;

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

interface IStakingPool {
    struct StakeInfo {
        uint256 reward;
        uint256 initial;
        uint256 stakePayday;
        uint256 startday;
    }

    function stakes(address addr) external view returns (StakeInfo memory);
}

// ETHYS Validator Pool Deposits Version 1
contract EthysV1ValidatorPool is Ownable {
    using SafeMath for uint256;

    IStakingPool public stakingPool;
    uint256 public minimumStakeRatio = 1e18;
    uint256 public minimumDeposit = 1e15;
    uint256 public maximumDeposits = 32e18;
    uint256 public totalDeposits = 0;

    address public withdrawer;

    struct UserInfo {
        uint256 stakeUtilized;
        uint256 stake;
        uint256 stakePayday;

        uint256 deposit;
        uint256 depositDate;
    }

    mapping(address => UserInfo) public user;
    
    constructor(address _stakingPool) public { 
        stakingPool = IStakingPool(_stakingPool);
    }

    // Calculates the minimum stake required for a given eth deposit.
    function calculateMinimumStakeFor(uint256 _wei) public view returns(uint256) {
        return _wei.mul(minimumStakeRatio).div(1e18);
    }

    function _syncUser(address addr) internal {
        UserInfo storage u = user[addr];
        // OPnly update expired stakes:
        if (block.timestamp < u.stakePayday) return;
        // Fetch stake info
        IStakingPool.StakeInfo memory info = stakingPool.stakes(addr);
        // Update user info with new stake info
        u.stakeUtilized = 0;
        u.stake = info.initial.add(info.reward);
        u.stakePayday = info.stakePayday;
    }

    // deposit ethereum for the ETH 2.0 pool. Requires an active stake in the ETHYS Staking pool
    function deposit() public payable {
        require(msg.value > minimumDeposit, "Minimum Deposit");
        require(totalDeposits.add(msg.value) <= maximumDeposits, "Maximum deposit limit hit");

        // Calculate stake required for this deposit
        uint256 stakeRequired = calculateMinimumStakeFor(msg.value);

        // Fetch users stake info if applicable
        _syncUser(msg.sender);
        UserInfo storage u = user[msg.sender];
        require(u.stakePayday > block.timestamp, "stake has expired");
        require(u.stake.sub(u.stakeUtilized) >= stakeRequired, "not enough staked to cover this deposit");

        //update the user
        u.stakeUtilized = u.stakeUtilized.add(stakeRequired);
        u.deposit = u.deposit.add(msg.value);
        u.depositDate = block.timestamp;

        // Deposit successful
        totalDeposits = totalDeposits.add(msg.value);
    }
    // clearUser only withdrawer can do this.
    function clearUser(address _user) public {
        require(msg.sender == withdrawer, "only withdrawer can do this");
        UserInfo storage u = user[_user];

        totalDeposits = totalDeposits.sub(u.deposit);
        
        // zero out stats
        u.stake         = 0;
        u.stakeUtilized = 0;
        u.stakePayday   = 0;
        u.deposit       = 0;
        u.depositDate   = 0;
    }
    // owner functions
    function setWithdrawer(address addr) public onlyOwner { withdrawer = addr; }
    function setStakingPool(address addr) public onlyOwner { stakingPool = IStakingPool(addr); }
    function setMinimum(uint256 amount) public onlyOwner { minimumDeposit = amount; }
    function setMaximum(uint256 amount) public onlyOwner { maximumDeposits = amount; }
    function setStakeRatio(uint256 ratio) public onlyOwner { minimumStakeRatio = ratio; }
    function sendToValidator(address payable validator, uint256 amount) public onlyOwner { validator.transfer(amount); }
}