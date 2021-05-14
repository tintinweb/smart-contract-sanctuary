/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/library/Util.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0;

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/interfaces/IERC20Details.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IERC20Details is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

}

////// contracts/interfaces/IMapleGlobals.sol
/* pragma solidity 0.6.11; */

interface IMapleGlobals {

    function pendingGovernor() external view returns (address);

    function governor() external view returns (address);

    function globalAdmin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validCalcs(address) external view returns (bool);

    function isValidCalc(address, uint8) external view returns (bool);

    function getLpCooldownParams() external view returns (uint256, uint256);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns (uint256);

    function lpCooldownPeriod() external view returns (uint256);

    function stakerUnstakeWindow() external view returns (uint256);

    function lpWithdrawWindow() external view returns (uint256);

    function oracleFor(address) external view returns (address);

    function validSubFactories(address, address) external view returns (bool);

    function setStakerCooldownPeriod(uint256) external;

    function setLpCooldownPeriod(uint256) external;

    function setStakerUnstakeWindow(uint256) external;

    function setLpWithdrawWindow(uint256) external;

    function setMaxSwapSlippage(uint256) external;

    function setGlobalAdmin(address) external;

    function setValidBalancerPool(address, bool) external;

    function setProtocolPause(bool) external;

    function setValidPoolFactory(address, bool) external;

    function setValidLoanFactory(address, bool) external;

    function setValidSubFactory(address, address, bool) external;

    function setDefaultUniswapPath(address, address, address) external;

    function setPoolDelegateAllowlist(address, bool) external;

    function setCollateralAsset(address, bool) external;

    function setLiquidityAsset(address, bool) external;

    function setCalc(address, bool) external;

    function setInvestorFee(uint256) external;

    function setTreasuryFee(uint256) external;

    function setMapleTreasury(address) external;

    function setDefaultGracePeriod(uint256) external;

    function setMinLoanEquity(uint256) external;

    function setFundingPeriod(uint256) external;

    function setSwapOutRequired(uint256) external;

    function setPriceOracle(address, address) external;

    function setPendingGovernor(address) external;

    function acceptGovernor() external;

}

////// lib/openzeppelin-contracts/contracts/math/SafeMath.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/library/Util.sol
/* pragma solidity 0.6.11; */

/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title Util is a library that contains utility functions.
library Util {

    using SafeMath for uint256;

    /**
        @dev    Calculates the minimum amount from a swap (adjustable for price slippage).
        @param  globals   Instance of a MapleGlobals.
        @param  fromAsset Address of ERC-20 that will be swapped.
        @param  toAsset   Address of ERC-20 that will returned from swap.
        @param  swapAmt   Amount of `fromAsset` to be swapped.
        @return Expected amount of `toAsset` to receive from swap based on current oracle prices.
    */
    function calcMinAmount(IMapleGlobals globals, address fromAsset, address toAsset, uint256 swapAmt) external view returns (uint256) {
        return 
            swapAmt
                .mul(globals.getLatestPrice(fromAsset))           // Convert from `fromAsset` value.
                .mul(10 ** IERC20Details(toAsset).decimals())     // Convert to `toAsset` decimal precision.
                .div(globals.getLatestPrice(toAsset))             // Convert to `toAsset` value.
                .div(10 ** IERC20Details(fromAsset).decimals());  // Convert from `fromAsset` decimal precision.
    }
}