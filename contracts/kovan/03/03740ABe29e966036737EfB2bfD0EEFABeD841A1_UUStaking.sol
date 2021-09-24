/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// File: EIP20Interface.sol

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: SafeMath.sol

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: ExponentialNoError.sol

pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// File: UUStaking.sol

pragma solidity ^0.5.16;




contract UUStaking is ExponentialNoError {
    using SafeMath for uint;

    event OwnershipTransferred(address indexed preAdmin, address indexed newAdmin);
    event UUSpeedUpdated(uint oldUUSpeed, uint newUUSpeed);
    event Staked(address indexed user, uint amount);
    event Redeemed(address indexed user, uint amount);
    event DistributedStakerUU(address indexed user, uint delta, uint index);
    event UUGranted(address indexed recipient, uint amount);

    uint224 public constant uuInitialIndex = 1e36;

    address public admin;
    address public uu;
    uint public uuSpeed;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    uint224 public uuMarketIndex;
    uint32 public updatedBlock;
    mapping(address => uint) public uuStakerIndex;
    mapping(address => uint) public uuAccrued;
    
    uint internal totalClaimed;
    uint internal storedTotalRewards;
    bool internal _notEntered;

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    constructor(address _uu) public {
        admin = msg.sender;
        uu = _uu;
        _notEntered = true;
    }

    function transferOwnership(address newAdmin) external {
        require(newAdmin != address(0), "newAdmin is zero address");
        require(msg.sender == admin, "require admin");
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
    
    function getUURemaining() public view returns (uint) {
        EIP20Interface uuToken = EIP20Interface(uu);
        uint uuRemaining = uuToken.balanceOf(address(this)).sub(totalSupply);
        return uuRemaining;
    }
    
    function getTotalRewards() external view returns (uint) {
        uint result = storedTotalRewards;
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(updatedBlock));
        if (deltaBlocks > 0 && uuSpeed > 0) {
            uint accrued = mul_(deltaBlocks, uuSpeed);
            result = totalSupply > 0 ? add_(result, accrued) : result;
        }
        return result;
    }

    function getTotalClaimed() external view returns (uint) {
        return totalClaimed;
    }

    function setUUSpeed(uint newUUSpeed) public {
        require(msg.sender == admin, "require admin");
        if (uuSpeed != 0) {
            updateUUStakingIndex();
        } else if (newUUSpeed != 0) {
            updatedBlock = safe32(getBlockNumber(), "block number exceeds 32 bits");
            if (uuMarketIndex == 0 && updatedBlock == 0) {
                uuMarketIndex = uuInitialIndex;
            }
        }

        if (uuSpeed != newUUSpeed) {
            emit UUSpeedUpdated(uuSpeed, newUUSpeed);
            uuSpeed = newUUSpeed;
        }
    }

    function stake(uint amount) nonReentrant external {
        require(amount > 0, "Cannot stake 0");
        updateUUStakingIndex();
        distributeStakerUU(msg.sender);
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        safeTransferFrom(uu, msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function redeem(uint amount) nonReentrant external {
        require(amount > 0, "Cannot redeem 0");
        updateUUStakingIndex();
        distributeStakerUU(msg.sender);
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        safeTransfer(uu, msg.sender, amount);
        emit Redeemed(msg.sender, amount);
    }

    function getUnclaimedUU(address holder) external view returns (uint) {
        uint unclaimed = uuAccrued[holder];

        Double memory marketIndex = Double({mantissa: uuMarketIndex});
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(updatedBlock));
        if (deltaBlocks > 0 && uuSpeed > 0) {
            uint accrued = mul_(deltaBlocks, uuSpeed);
            Double memory ratio = totalSupply > 0 ? fraction(accrued, totalSupply) : Double({mantissa: 0});
            marketIndex = add_(Double({mantissa: uuMarketIndex}), ratio);
        } 

        Double memory stakerIndex = Double({mantissa: uuStakerIndex[holder]});
        if (stakerIndex.mantissa == 0 && marketIndex.mantissa > 0) {
            stakerIndex.mantissa = uuInitialIndex;
        }

        Double memory deltaIndex = sub_(marketIndex, stakerIndex);
        uint staking = balanceOf[holder];
        uint stakerDelta = mul_(staking, deltaIndex);
        unclaimed = add_(unclaimed, stakerDelta);
        
        return unclaimed;
    }

    function claimAllUU(address holder) external {
        updateUUStakingIndex();
        distributeStakerUU(holder);
        uint grantResult = grantUUInternal(holder, uuAccrued[holder]);
        if (grantResult == 0) {
            totalClaimed = totalClaimed.add(uuAccrued[holder]);
            uuAccrued[holder] = 0;
            
        }
        uuAccrued[holder] = grantUUInternal(holder, uuAccrued[holder]);
    }

    function claimUU(address holder, uint amount) external {
        require(amount > 0, "amount is zero");
        updateUUStakingIndex();
        distributeStakerUU(holder);
        require(uuAccrued[holder] >= amount, "not enougn unclaim uu");
        uint grantResult = grantUUInternal(holder, amount);
        if (grantResult == 0) {
            totalClaimed = totalClaimed.add(amount);
            uuAccrued[holder] = uuAccrued[holder].sub(amount);
        } 
    }

    function _grantUU(address recipient, uint amount) public {
        require(msg.sender == admin, "only admin can grant uu");
        uint amountLeft = grantUUInternal(recipient, amount);
        require(amountLeft == 0, "insufficient uu for grant");
        emit UUGranted(recipient, amount);
    }

    function grantUUInternal(address user, uint amount) internal returns (uint) {
        uint uuRemaining = getUURemaining();
        if (amount > 0 && amount <= uuRemaining) {
            safeTransfer(uu, user, amount);
            return 0;
        }
        return amount;
    }

    function updateUUStakingIndex() internal {
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(updatedBlock));
        if (deltaBlocks > 0 && uuSpeed > 0) {
            uint accrued = mul_(deltaBlocks, uuSpeed);
            storedTotalRewards = totalSupply > 0 ? add_(storedTotalRewards, accrued) : storedTotalRewards;
            Double memory ratio = totalSupply > 0 ? fraction(accrued, totalSupply) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: uuMarketIndex}), ratio);
            uuMarketIndex = safe224(index.mantissa, "new index exceeds 224 bits");
            updatedBlock = safe32(blockNumber, "block number exceeds 32 bits");
        } else if (deltaBlocks > 0) {
            updatedBlock = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    function distributeStakerUU(address staker) internal {
        Double memory marketIndex = Double({mantissa: uuMarketIndex});
        Double memory stakerIndex = Double({mantissa: uuStakerIndex[staker]});
        uuStakerIndex[staker] = marketIndex.mantissa;

        if (stakerIndex.mantissa == 0 && marketIndex.mantissa > 0) {
            stakerIndex.mantissa = uuInitialIndex;
        }

        Double memory deltaIndex = sub_(marketIndex, stakerIndex);
        uint staking = balanceOf[staker];
        uint stakerDelta = mul_(staking, deltaIndex);
        uint stakerAccrued = add_(uuAccrued[staker], stakerDelta);
        uuAccrued[staker] = stakerAccrued;
        emit DistributedStakerUU(staker, stakerDelta, marketIndex.mantissa);
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
}