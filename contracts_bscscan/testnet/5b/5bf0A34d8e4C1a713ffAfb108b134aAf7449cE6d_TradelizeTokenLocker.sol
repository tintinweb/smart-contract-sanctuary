/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library ExtraMath {
    using SafeMath for uint;
  
    function toUInt8(uint _a) internal pure returns(uint8) {
        require(_a <= uint8(-1), 'uint8 overflow');
        return uint8(_a);
    }

    function toUInt32(uint _a) internal pure returns(uint32) {
        require(_a <= uint32(-1), 'uint32 overflow');
        return uint32(_a);
    }

    function toUInt96(uint _a) internal pure returns(uint96) {
        require(_a <= uint96(-1), 'uint96 overflow');
        return uint96(_a);
    }
    
    function toUInt120(uint _a) internal pure returns(uint120) {
        require(_a <= uint120(-1), 'uint120 overflow');
        return uint120(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= uint128(-1), 'uint128 overflow');
        return uint128(_a);
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract TradelizeTokenLocker is Ownable {
    using ExtraMath for *;
    using SafeMath for *;
  
    uint private constant BLOCKS_PER_MONTH = 100; // 866125
    
    enum LockType {
        Liquidity,
        Strategic,
        Private,
        Public,
        FoundersAndTeam,
        StakingRewards,
        CopytradingRewards,
        OtherRewards,
        Community,
        Ecosystem,
        Advisors,
        Foundation
    }
    
    struct LockConfig {
        uint96 supply;
        uint32 startLinearVestingAfter; // number of blocks
        uint32 linearVestingPeriod; // number of blocks
        uint96 linearVestingAmount;
        uint32 holderCount;
    }
    
    struct Holder {
        uint96 totalClaimedAmount;
        LockType lockType;
        bool exists;
    }
    
    mapping(LockType => LockConfig) public lockConfigs;
    mapping(address => Holder) public holders;
    
    bool public holderListIsFrozen;
    uint32 public distributionStartBlock; // number of block
    
    IERC20 public tradelizeToken;
    
    event AddHolder(address holder, LockType lockType);
    event Claimed(address holder, uint96 amount);
    
    constructor(address tradelizeTokenAddress) public {
        tradelizeToken = IERC20(tradelizeTokenAddress);
        
        // Liquidity
        lockConfigs[LockType.Liquidity].supply = 30_000_000e18.toUInt96();
        
        // Strategic
        lockConfigs[LockType.Strategic].supply = 41_500_000e18.toUInt96(); // 4.15% of total token supply
        lockConfigs[LockType.Strategic].startLinearVestingAfter = 3*BLOCKS_PER_MONTH.toUInt32(); // 3 month
        lockConfigs[LockType.Strategic].linearVestingPeriod = 12*BLOCKS_PER_MONTH.toUInt32(); // 12 month
        lockConfigs[LockType.Strategic].linearVestingAmount = 38_180_000e18.toUInt96(); // 92% of supply
        
        // Private
        lockConfigs[LockType.Private].supply = 120_000_000e18.toUInt96(); // 12.00% of total token supply
        lockConfigs[LockType.Private].startLinearVestingAfter = 2*BLOCKS_PER_MONTH.toUInt32(); // 2 month
        lockConfigs[LockType.Private].linearVestingPeriod = 12*BLOCKS_PER_MONTH.toUInt32(); // 12 month
        lockConfigs[LockType.Private].linearVestingAmount = 110_400_000e18.toUInt96(); // 92% of supply
        
        // Public
        lockConfigs[LockType.Public].supply = 3_500_000e18.toUInt96(); // 0.35% of total token supply
        
        // FoundersAndTeam
        lockConfigs[LockType.FoundersAndTeam].supply = 200_000_000e18.toUInt96(); // 20.00% of total token supply
        lockConfigs[LockType.FoundersAndTeam].startLinearVestingAfter = 6*BLOCKS_PER_MONTH.toUInt32(); // 6 month
        lockConfigs[LockType.FoundersAndTeam].linearVestingPeriod = 12*BLOCKS_PER_MONTH.toUInt32(); // 12 month
        lockConfigs[LockType.FoundersAndTeam].linearVestingAmount = 200_000_000e18.toUInt96(); // 100% of supply
        
        // StakingRewards
        lockConfigs[LockType.StakingRewards].supply = 280_000_000e18.toUInt96(); // 28.00% of total token supply
        
        // CopytradingRewards
        lockConfigs[LockType.CopytradingRewards].supply = 205_000_000e18.toUInt96(); // 20.50% of total token supply
        
        // OtherRewards
        lockConfigs[LockType.OtherRewards].supply = 30_000_000e18.toUInt96(); // 3.00% of total token supply
        
        // Community
        lockConfigs[LockType.Community].supply = 20_000_000e18.toUInt96(); // 2.00% of total token supply
        lockConfigs[LockType.Community].startLinearVestingAfter = 1*BLOCKS_PER_MONTH.toUInt32(); // 1 month
        lockConfigs[LockType.Community].linearVestingPeriod = 9*BLOCKS_PER_MONTH.toUInt32(); // 9 month
        lockConfigs[LockType.Community].linearVestingAmount = 20_000_000e18.toUInt96(); // 100% of supply
        
        // Ecosystem
        lockConfigs[LockType.Ecosystem].supply = 20_000_000e18.toUInt96(); // 2.00% of total token supply
        lockConfigs[LockType.Ecosystem].startLinearVestingAfter = 1*BLOCKS_PER_MONTH.toUInt32(); // 1 month
        lockConfigs[LockType.Ecosystem].linearVestingPeriod = 9*BLOCKS_PER_MONTH.toUInt32(); // 9 month
        lockConfigs[LockType.Ecosystem].linearVestingAmount = 20_000_000e18.toUInt96(); // 100% of supply
        
        // Advisors
        lockConfigs[LockType.Advisors].supply = 20_000_000e18.toUInt96(); // 2.00% of total token supply
        lockConfigs[LockType.Advisors].startLinearVestingAfter = 1*BLOCKS_PER_MONTH.toUInt32(); // 1 month
        lockConfigs[LockType.Advisors].linearVestingPeriod = 9*BLOCKS_PER_MONTH.toUInt32(); // 9 month
        lockConfigs[LockType.Advisors].linearVestingAmount = 20_000_000e18.toUInt96(); // 100% of supply
        
        // Foundation
        lockConfigs[LockType.Foundation].supply = 30_000_000e18.toUInt96(); // 3.00% of total token supply
        lockConfigs[LockType.Foundation].startLinearVestingAfter = 1*BLOCKS_PER_MONTH.toUInt32(); // 1 month
        lockConfigs[LockType.Foundation].linearVestingPeriod = 9*BLOCKS_PER_MONTH.toUInt32(); // 9 month
        lockConfigs[LockType.Foundation].linearVestingAmount = 30_000_000e18.toUInt96(); // 100% of supply
    }
    
    function addHolder(address _holder, LockType lockType) public onlyOwner {
        require(!holderListIsFrozen, "TradelizeTokenLocker::claim: holder list is frozen");
      
        Holder storage holder = holders[_holder];
        
        holder.lockType = lockType;
        holder.exists = true;
        lockConfigs[lockType].holderCount = lockConfigs[lockType].holderCount.add(1).toUInt32();
        
        emit AddHolder(_holder, lockType);
    }
    
    function freezeHolderList() public onlyOwner {
        require(tradelizeToken.balanceOf(address(this)) == 1_000_000_000e18.toUInt96(), "TradelizeTokenLocker::claim: balance is insufficient");
        
        holderListIsFrozen = true;
        distributionStartBlock = block.number.toUInt32();
    }
    
    function claim() public {
        require(holderListIsFrozen, "TradelizeTokenLocker::claim: holder list is not frozen, distribution has not started yet");
        require(holders[msg.sender].exists, "TradelizeTokenLocker::claim: sender address is not in holder list");
      
        uint96 unClaimedAmount = unClaimedAmount(msg.sender);
        
        require(tradelizeToken.balanceOf(address(this)) >= unClaimedAmount, "TradelizeTokenLocker::claim: balance is insufficient");
        require(unClaimedAmount > 0, "TradelizeTokenLocker::claim: no unclaimed amount");
        
        tradelizeToken.transfer(msg.sender, unClaimedAmount);
        holders[msg.sender].totalClaimedAmount = holders[msg.sender].totalClaimedAmount.add(unClaimedAmount).toUInt96();
        
        emit Claimed(msg.sender, unClaimedAmount);
    }
    
    function unClaimedAmount(address _holder) public view returns (uint96) {
        require(holderListIsFrozen, "TradelizeTokenLocker::claim: holder list is not frozen, distribution has not started yet");
        require(holders[_holder].exists, "TradelizeTokenLocker::claim: address is not in holder list");
        
        LockConfig memory lockConfig = lockConfigs[holders[_holder].lockType];
        uint32 linearVestingStartBlock = distributionStartBlock.add(lockConfig.startLinearVestingAfter).toUInt32();
        
        // initial approved total amount (for all holders of this lock type and before linear vesting)
        uint96 initialApprovedTotalAmount = lockConfig.supply.sub(lockConfig.linearVestingAmount).toUInt96();
        
        uint96 linearVestingTotalAmount;
        
        // computation linear vesting total Amount
        if (block.number > linearVestingStartBlock) {
            linearVestingTotalAmount = (Math.min(block.number, linearVestingStartBlock.add(lockConfig.linearVestingPeriod)).sub(linearVestingStartBlock)).
                mul(lockConfig.linearVestingAmount.div(lockConfig.linearVestingPeriod)).toUInt96();
        }
        
        return initialApprovedTotalAmount.add(linearVestingTotalAmount).div(lockConfig.holderCount).sub(holders[_holder].totalClaimedAmount).toUInt96();
    }
}