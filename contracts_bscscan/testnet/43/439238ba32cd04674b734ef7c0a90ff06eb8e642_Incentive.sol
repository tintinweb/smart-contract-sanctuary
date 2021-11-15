// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import './Ownable.sol';
import './ALIToken.sol';

contract Incentive is Owner {

    using SafeMath for uint256;
    // using SafeBEP20 for IBEP20;

    address public claimableAdress; // the only address can claim airdrop token and then distribute to other users

    AliToken public ali; // claimed token address

    uint public startBlock;

    uint public lastRewardBlock; // record last reward block
    
    event Claim(uint indexed lastBlock, uint indexed currentBlock, uint indexed amount, address add);
    event ChangeNumberTokenperBlock(uint indexed oldNumer, uint indexed newNumber);

    constructor(AliToken _ali, address add, uint256 _startBlock) public {
        ali = _ali;
        claimableAdress = add;
        lastRewardBlock = _startBlock;
        startBlock = _startBlock;
    }

    function claim() external{
        require(msg.sender == claimableAdress, "not allow to claim");
        
        uint claimableAmount = getClaimableReward();

        if(claimableAmount == 0){
            return;
        }
        
        ali.mint(msg.sender, claimableAmount);
        emit Claim(lastRewardBlock, block.number, claimableAmount, msg.sender);
        lastRewardBlock = block.number;
    }

    /**
     * @notice Returns the result of (base ** exponent) with SafeMath
     * @param base The base number. Example: 2
     * @param exponent The exponent used to raise the base. Example: 3
     * @return A number representing the given base taken to the power of the given exponent. Example: 2 ** 3 = 8
     */
    function pow(uint base, uint exponent) internal pure returns (uint) {
        if (exponent == 0) {
            return 1;
        } else if (exponent == 1) {
            return base;
        } else if (base == 0 && exponent != 0) {
            return 0;
        } else {
            uint result = base;
            for (uint i = 1; i < exponent; i++) {
                result = result.mul(base);
            }
            return result;
        }
    }

    /**
     * @notice Caculate the reward per block at the period: (keepPercent / 100) ** period * initialRewardPerBlock
     * @param periodIndex The period index. The period index must be between [0, maximumPeriodIndex]
     * @return A number representing the reward token per block at specific period. Result is scaled by 1e18.
     */
    function getRewardPerBlock(uint periodIndex) public view returns (uint) {
        if(periodIndex > ali.getMaximumPeriodIndex()){
            return 0;
        }
        else{
            return pow(ali.getKeepPercent(), periodIndex).mul(ali.getInitialRewardPerBlock()).div(pow(100, periodIndex));
        }
    }

    /**
     * @notice Calculate the block number corresponding to each milestone at the beginning of each period.
     * @param periodIndex The period index. The period index must be between [0, maximumPeriodIndex]
     * @return A number representing the block number of the milestone at the beginning of the period.
     */
    function getBlockNumberOfMilestone(uint periodIndex) public view returns (uint) {
        return ali.getBlockPerPeriod().mul(periodIndex).add(startBlock);
    }

    /**
     * @notice Determine the period corresponding to any block number.
     * @param blockNumber The block number. The block number must be >= startBlock
     * @return A number representing period index of the input block number.
     */
    function getPeriodIndexByBlockNumber(uint blockNumber) public view returns (uint) {
        require(blockNumber >= startBlock, 'Incentive: blockNumber must be greater or equal startBlock');
        return blockNumber.sub(startBlock).div(ali.getBlockPerPeriod());
    }

    /**
     * @notice Calculate the reward that can be claimed from the last received time to the present time.
     * @return A number representing the reclamable ALI tokens. Result is scaled by 1e18.
     */
    function getClaimableReward() public view returns (uint) {
        uint maxBlock = getBlockNumberOfMilestone(ali.getMaximumPeriodIndex() + 1); 
        uint currentBlock = block.number > maxBlock ? maxBlock: block.number;
        
        require(currentBlock >= startBlock, 'Incentive: currentBlock must be greater or equal startBlock');
        
        uint lastClaimPeriod = getPeriodIndexByBlockNumber(lastRewardBlock);
        uint currentPeriod = getPeriodIndexByBlockNumber(currentBlock);
        
        uint startCalculationBlock = lastRewardBlock;
        uint sum = 0;
        
        for(uint i = lastClaimPeriod ; i  <= currentPeriod ; i++) { 
            uint nextBlock = i < currentPeriod ? getBlockNumberOfMilestone(i+1) : currentBlock;
            uint delta = nextBlock.sub(startCalculationBlock);
            sum = sum.add(delta.mul(getRewardPerBlock(i)));
            startCalculationBlock = nextBlock;
        } 
        return sum.mul(ali.getIncentiveWeight()).div(100);
    }
}

pragma solidity >=0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

interface AliToken is IBEP20 {

    function getKeepPercent() external view returns(uint);

    function getInitialRewardPerBlock() external view returns(uint);

    function getMaximumPeriodIndex() external view returns(uint);

    function getBlockPerPeriod() external view returns(uint);

    function getMasterChefWeight() external view returns(uint);

    function getIncentiveWeight() external view returns(uint);

    function mint(address _to, uint256 _amount) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

