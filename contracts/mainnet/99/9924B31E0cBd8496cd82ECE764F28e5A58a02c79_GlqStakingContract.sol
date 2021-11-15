// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/maths/SafeMath.sol";
import "./libs/string.sol";
import "./interfaces/IERC20.sol";
import "./libs/sort.sol";

struct GlqStaker {
    address wallet;
    uint256 block_number;
    uint256 amount;
    uint256 index_at;
    bool already_withdrawn;
}

struct GraphLinqApyStruct {
    uint256 tier1Apy;
    uint256 tier2Apy;
    uint256 tier3Apy;      
}

contract GlqStakingContract {

    using SafeMath for uint256;
    using strings for *;
    using QuickSorter for *;

    event NewStakerRegistered (
        address staker_address,
        uint256 at_block,
        uint256 amount_registered
    );

    /*
    ** Address of the GLQ token hash: 0x9F9c8ec3534c3cE16F928381372BfbFBFb9F4D24
    */
    address private _glqTokenAddress;

    /*
    ** Manager of the contract to add/remove APYs bonuses into the staking contract
    */
    address private _glqDeployerManager;

    /*
    ** Current amount of GLQ available in the pool as rewards
    */
    uint256 private _totalGlqIncentive;

    GlqStaker[]                     private _stakers;
    uint256                         private _stakersIndex;
    uint256                         private _totalStaked;
    bool                            private _emergencyWithdraw;

    mapping(address => uint256)     private _indexStaker;
    uint256                         private _blocksPerYear;
    GraphLinqApyStruct              private _apyStruct;

    constructor(address glqAddr, address manager) {
        _glqTokenAddress = glqAddr;
        _glqDeployerManager = manager;

        _totalStaked = 0;
        _stakersIndex = 1;
        
        _blocksPerYear = 2250000;
        
        // default t1: 30%, t2: 15%, t3: 7.5%
        _apyStruct = GraphLinqApyStruct(50*1e18, 25*1e18, 12500000000000000000);
    }


    /* Getter ---- Read-Only */

    /*
    ** Return the sender wallet position from the tier system
    */
    function getWalletCurrentTier(address wallet) public view returns (uint256) {
        uint256 currentTier = 3;
        uint256 index = _indexStaker[wallet];
        require(
            index != 0,
            "You dont have any tier rank currently in the Staking contract."
        );
        uint256 walletAggregatedIndex = (index).mul(1e18);

        // Total length of stakers
        uint256 totalIndex = _stakers.length.mul(1e18);
        // 15% of hodlers in T1 
        uint256 t1MaxIndex = totalIndex.div(100).mul(15);
        // 55% of hodlers in T2
        uint256 t2MaxIndex = totalIndex.div(100).mul(55);

        if (walletAggregatedIndex <= t1MaxIndex) {
            currentTier = 1;
        } else if (walletAggregatedIndex > t1MaxIndex && walletAggregatedIndex <= t2MaxIndex) {
            currentTier = 2;
        }

        return currentTier;
    }

    /*
    ** Return rank position of a wallet
    */
    function getPosition(address wallet) public view returns (uint256) {
         uint256 index = _indexStaker[wallet];
         return index;
    }

    /*
    ** Return the amount of GLQ that a wallet can currently claim from the staking contract
    */
    function getGlqToClaim(address wallet) public view returns(uint256) {
        uint256 index = _indexStaker[wallet];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];

        uint256 calculatedApr = getWaitingPercentAPR(wallet);
        return staker.amount.mul(calculatedApr.div(1e16)).div(10000);
    }

    /*
    ** Return the current percent winnable for a staker wallet
    */
    function getWaitingPercentAPR(address wallet) public view returns(uint256) {
        uint256 index = _indexStaker[wallet];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];

        uint256 walletTier = getWalletCurrentTier(msg.sender);
        uint256 blocksSpent = block.number.sub(staker.block_number);
        if (blocksSpent == 0) { return 0; }
        uint256 percentYearSpent = percent(blocksSpent, _blocksPerYear, 2);

        uint256 percentAprGlq = _apyStruct.tier3Apy;
        if (walletTier == 1) {
            percentAprGlq = _apyStruct.tier1Apy;
        } else if (walletTier == 2) { 
            percentAprGlq = _apyStruct.tier2Apy;
        }

        return percentAprGlq.mul(percentYearSpent).div(100);
    }

    /*
    ** Return the total amount of GLQ as incentive rewards in the contract
    */
    function getTotalIncentive() public view returns (uint256) {
        return _totalGlqIncentive;
    }

    /*
    ** Return the total amount in staking for an hodler.
    */
    function getDepositedGLQ(address wallet) public view returns (uint256) {
        uint256 index = _indexStaker[wallet];
        if (index == 0) { return 0; }
        return _stakers[index-1].amount;
    }

    /*
    ** Count the total numbers of stakers in the contract
    */
    function getTotalStakers() public view returns(uint256) {
        return _stakers.length;
    }

    /*
    ** Return all APY per different Tier
    */
    function getTiersAPY() public view returns(uint256, uint256, uint256) {
        return (_apyStruct.tier1Apy, _apyStruct.tier2Apy, _apyStruct.tier3Apy);
    }

    /*
    ** Return the Total staked amount
    */
    function getTotalStaked() public view returns(uint256) {
        return _totalStaked;
    }

    /*
    ** Return the top 3 of stakers (by age)
    */
    function getTopStakers() public view returns(address[] memory, uint256[] memory) {
        uint256 len = _stakers.length;
        address[] memory addresses = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        for (uint i = 0; i < len && i <= 2; i++) {
            addresses[i] = _stakers[i].wallet;
            amounts[i] = _stakers[i].amount;
        }

        return (addresses, amounts);
    }

    /*
    ** Return the total amount deposited on a rank tier
    */
    function getTierTotalStaked(uint tier) public view returns (uint256) {
        uint256 totalAmount = 0;

        // Total length of stakers
        uint256 totalIndex = _stakers.length.mul(1e18);
        // 15% of hodlers in T1 
        uint256 t1MaxIndex = totalIndex.div(100).mul(15);
        // 55% of hodlers in T2
        uint256 t2MaxIndex = totalIndex.div(100).mul(55);

        uint startIndex = (tier == 1) ? 0 : t1MaxIndex.div(1e18);
        uint endIndex = (tier == 1) ? t1MaxIndex.div(1e18) : t2MaxIndex.div(1e18);
        
        if (tier == 3) {
            startIndex = t2MaxIndex.div(1e18);
            endIndex = _stakers.length;
        }

        for (uint i = startIndex; i <= endIndex && i < _stakers.length; i++) {
            totalAmount +=  _stakers[i].amount;
        }
      
        return totalAmount;
    }

    /* Getter ---- Read-Only */


    /* Setter - Read & Modifications */


    /*
    ** Enable emergency withdraw by GLQ Deployer
    */
    function setEmergencyWithdraw(bool state) public {
        require (
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can change the state of the emergency withdraw"
        );
        _emergencyWithdraw = state;
    }

    /*
    ** Set numbers of blocks spent per year to calculate claim rewards
    */
    function setBlocksPerYear(uint256 blocks) public {
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can change blocks spent per year");
        _blocksPerYear = blocks;
    }

    /*
    ** Update the APY rewards for each tier in percent per year
    */
    function setApyPercentRewards(uint256 t1, uint256 t2, uint256 t3) public {
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can APY rewards");
        GraphLinqApyStruct memory newApy = GraphLinqApyStruct(t1, t2, t3);
        _apyStruct = newApy;
    }

    /*
    ** Add GLQ liquidity in the staking contract for stakers rewards 
    */
    function addIncentive(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can add incentive into the smart-contract");
        require(
            glqToken.balanceOf(msg.sender) >= glqAmount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transferFrom(msg.sender, address(this), glqAmount) == true,
            "Error transferFrom on the contract"
        );
        _totalGlqIncentive += glqAmount;
    }

    /*
    ** Remove GLQ liquidity from the staking contract for stakers rewards 
    */
    function removeIncentive(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            msg.sender == _glqDeployerManager,
            "Only the Glq Deployer can remove incentive from the smart-contract");
        require(
            glqToken.balanceOf(address(this)) >= glqAmount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transfer(msg.sender, glqAmount) == true,
            "Error transfer on the contract"
        );

        _totalGlqIncentive -= glqAmount;
    }


    /*
    ** Deposit GLQ in the staking contract to stake & earn
    */
    function depositGlq(uint256 glqAmount) public {
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            glqToken.balanceOf(msg.sender) >= glqAmount,
            "Insufficient funds from the sender");
        require(
           glqToken.transferFrom(msg.sender, address(this), glqAmount) == true,
           "Error transferFrom on the contract"
        );

        uint256 index = _indexStaker[msg.sender];
        _totalStaked += glqAmount;

        if (index == 0) {
            GlqStaker memory staker = GlqStaker(msg.sender, block.number, glqAmount, _stakersIndex, false);
            _stakers.push(staker);
            _indexStaker[msg.sender] = _stakersIndex;

            // emit event of a new staker registered at current block position
            emit NewStakerRegistered(msg.sender, block.number, glqAmount);
            _stakersIndex = _stakersIndex.add(1);
        }
        else {
            // claim rewards before adding new staking amount
            if (_stakers[index-1].amount > 0) {
                claimGlq();
            }
            _stakers[index-1].amount += glqAmount;
        }
    }

    function removeStaker(GlqStaker storage staker) private {
        uint256 currentIndex = _indexStaker[staker.wallet]-1;
        _indexStaker[staker.wallet] = 0;
        for (uint256 i= currentIndex ; i < _stakers.length-1 ; i++) {
            _stakers[i] = _stakers[i+1];
            _stakers[i].index_at = _stakers[i].index_at.sub(1);
            _indexStaker[_stakers[i].wallet] = _stakers[i].index_at;
        }
        _stakers.pop();

        // Remove the staker and decrease stakers index
        _stakersIndex = _stakersIndex.sub(1);
        if (_stakersIndex == 0) { _stakersIndex = 1; }
    }

    /*
    ** Emergency withdraw enabled by GLQ team in an emergency case
    */
    function emergencyWithdraw() public {
        require(
            _emergencyWithdraw == true,
            "The emergency withdraw feature is not enabled"
        );
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        IERC20 glqToken = IERC20(_glqTokenAddress);

        require(
            staker.amount > 0,
         "Not funds deposited in the staking contract");

        require(
            glqToken.transfer(msg.sender, staker.amount) == true,
            "Error transfer on the contract"
        );
        staker.amount = 0;
    }

    /*
    ** Withdraw Glq from the staking contract (reduce the tier position)
    */
    function withdrawGlq() public {
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        IERC20 glqToken = IERC20(_glqTokenAddress);
        require(
            staker.amount > 0,
         "Not funds deposited in the staking contract");
    
        //auto claim when withdraw
        claimGlq();

        _totalStaked -= staker.amount;
        require(
            glqToken.balanceOf(address(this)) >= staker.amount,
            "Insufficient funds from the deployer contract");
        require(
            glqToken.transfer(msg.sender, staker.amount) == true,
            "Error transfer on the contract"
        );
        staker.amount = 0;
        
        if (staker.already_withdrawn) {
            removeStaker(staker);
        } else {
            staker.already_withdrawn = true;
        }
    }

    function percent(uint256 numerator, uint256 denominator, uint256 precision) private pure returns(uint256) {
        uint256 _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    /*
    ** Claim waiting rewards from the staking contract
    */
    function claimGlq() public returns(uint256) {
        uint256 index = _indexStaker[msg.sender];
        require (index > 0, "Invalid staking index");
        GlqStaker storage staker = _stakers[index - 1];
        uint256 glqToClaim = getGlqToClaim(msg.sender);
        IERC20 glqToken = IERC20(_glqTokenAddress);

        require(
            glqToClaim > 0,
            "No rewards to claim."
        );
        require(
            glqToken.balanceOf(address(this)) > glqToClaim,
            "Not enough funds in the staking program to claim rewards"
        );

        staker.block_number = block.number;

        require(
            glqToken.transfer(msg.sender, glqToClaim) == true,
            "Error transfer on the contract"
        );
        return (glqToClaim);
    }

    /* Setter - Read & Modifications */

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

    function decimals() external view returns (uint8);

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

library QuickSorter {


  function sort(uint[] storage data) internal {

    uint n = data.length;
    uint[] memory arr = new uint[](n);
    uint i;

    for(i=0; i<n; i++) {
      arr[i] = data[i];
    }

    uint[] memory stack = new uint[](n+2);

    //Push initial lower and higher bound
    uint top = 1;
    stack[top] = 0;
    top = top + 1;
    stack[top] = n-1;

    //Keep popping from stack while is not empty
    while (top > 0) {

      uint h = stack[top];
      top = top - 1;
      uint l = stack[top];
      top = top - 1;

      i = l;
      uint x = arr[h];

      for(uint j=l; j<h; j++){
        if  (arr[j] <= x) {
          //Move smaller element
          (arr[i], arr[j]) = (arr[j],arr[i]);
          i = i + 1;
        }
      }
      (arr[i], arr[h]) = (arr[h],arr[i]);
      uint p = i;

      //Push left side to stack
      if (p > l + 1) {
        top = top + 1;
        stack[top] = l;
        top = top + 1;
        stack[top] = p - 1;
      }

      //Push right side to stack
      if (p+1 < h) {
        top = top + 1;
        stack[top] = p + 1;
        top = top + 1;
        stack[top] = h;
      }
    }

    for(i=0; i<n; i++) {
      data[i] = arr[i];
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library strings {
    using strings for *;
    
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len_cpy) private pure {
        // Copy word-length chunks while possible
        for(; len_cpy >= 32; len_cpy -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len_cpy) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }


    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    event log_bytemask(bytes32 mask);


    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) 
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

     function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint lenn;
        while (j != 0) {
            lenn++;
            j /= 10;
        }
        bytes memory bstr = new bytes(lenn);
        uint k = lenn - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

 function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function split_string(string memory raw, string memory by) pure internal returns(string[] memory)
	{
		strings.slice memory s = raw.toSlice();
		strings.slice memory delim = by.toSlice();
		string[] memory parts = new string[](s.count(delim));
		for (uint i = 0; i < parts.length; i++) {
			parts[i] = s.split(delim).toString();
		}
		return parts;
	}
}

