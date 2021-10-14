// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/BEP20/IBEP20.sol";
import "../math/SafeMath.sol";
import "../interfaces/cream/CErc20Delegator.sol";
import "../interfaces/cream/InterestRateModel.sol";
import "../interfaces/cream/PriceOracleProxy.sol";

/// @title Cream execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library CreamExecution {
    
    // Addresss of Cream.
    struct CreamConfig {
        address oracle; // Address of Cream oracle contract.
    }
    
    /// @param crtoken_address Cream crToken address.
    function getAvailableBorrow(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).getCash();
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current borrow rate for the underlying token.
    function getBorrowRate(address crtoken_address) public view returns (uint) {
        uint cash = CErc20Delegator(crtoken_address).getCash();
        uint borrows = CErc20Delegator(crtoken_address).totalBorrows();
        uint reserves = CErc20Delegator(crtoken_address).totalReserves();
        uint decimals = CErc20Delegator(crtoken_address).decimals();
        
        address interest_rate_address = CErc20Delegator(crtoken_address).interestRateModel();
        
        uint borrowRate = InterestRateModel(interest_rate_address).getBorrowRate(cash, borrows, reserves);
        
        return SafeMath.div(borrowRate, 10**(decimals + 1));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current borrow rate for a token.
    function getSupplyRate(address crtoken_address) public view returns (uint) {
        uint cash = CErc20Delegator(crtoken_address).getCash();
        uint borrows = CErc20Delegator(crtoken_address).totalBorrows();
        uint reserves = CErc20Delegator(crtoken_address).totalReserves();
        uint mantissa = CErc20Delegator(crtoken_address).reserveFactorMantissa();
        uint decimals = CErc20Delegator(crtoken_address).decimals();
        
        address interest_rate_address = CErc20Delegator(crtoken_address).interestRateModel();
        
        uint supplyRate = InterestRateModel(interest_rate_address).getSupplyRate(cash, borrows, reserves, mantissa);
        
        return SafeMath.div(supplyRate, 10**(decimals + 1));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @param crWBNB_address Cream crWBNB address.
    /// @dev Gets the borrowed amount for a particular token.
    /// @return crToken amount
    function getBorrowAmount(address crtoken_address, address crWBNB_address) public view returns (uint) {
        if (crtoken_address == crWBNB_address) {
            revert("we never use WBNB (insufficient liquidity), so just use BNB instead");
        }
        return CErc20Delegator(crtoken_address).borrowBalanceStored(address(this));
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the borrowed amount for a particular token.
    /// @return crToken amount.
    function getUserTotalSupply(address crtoken_address) public returns (uint) {
        
        return CErc20Delegator(crtoken_address).balanceOfUnderlying(address(this));
    }
    
    /// @dev Gets the USDCBNB price.
    function getUSDCBNBPrice(CreamConfig memory self, address crUSDC_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crUSDC_address);
    }
    
    /// @dev Gets the bnb amount.
    function getCrTokenBalance(CreamConfig memory self, address crtoken_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crtoken_address);
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the crtoken/BNB price.
    function getTokenPrice(CreamConfig memory self, address crtoken_address) public view returns (uint) {
        
        return PriceOracleProxy(self.oracle).getUnderlyingPrice(crtoken_address);
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Gets the current exchange rate for a ctoken.
    function getExchangeRate(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).exchangeRateStored();
    }
    
    /// @return the current borrow limit on the platform.
    function getBorrowLimit(CreamConfig memory self, address borrow_crtoken_address, address crUSDC_address, address USDC_address, uint supply_amount, uint borrow_amount) public view returns (uint) {
        uint borrow_token_price = getTokenPrice(self, borrow_crtoken_address);
        uint usdc_bnb_price = getTokenPrice(self, crUSDC_address);
        uint usdc_decimals = IBEP20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        
        uint token_price = SafeMath.div(SafeMath.mul(borrow_token_price, one_unit_of_usdc), usdc_bnb_price);
        uint borrow_usdc_value = SafeMath.mul(token_price, borrow_amount);
        
        supply_amount = SafeMath.mul(supply_amount, 100);
        supply_amount = SafeMath.div(supply_amount, 75);
        
        return SafeMath.div(borrow_usdc_value, supply_amount);
    }
    
    /// @return the amount in the wallet for a given token.
    function getWalletAmount(address crtoken_address) public view returns (uint) {
        
        return CErc20Delegator(crtoken_address).balanceOf(address(this));
    }
    
    function borrow(address crtoken_address, uint borrow_amount) public returns (uint) {
        // TODO make sure don't borrow more than the limit
        return CErc20Delegator(crtoken_address).borrow(borrow_amount);
    }

    function getUnderlyingAddress(address crtoken_address) public view returns (address) {
        
        return CErc20Delegator(crtoken_address).underlying();
    }
    
    /// @param crtoken_address Cream crToken address.
    /// @dev Get the token/BNB price.
    function getUSDPrice(CreamConfig memory self, address crtoken_address, address crUSDC_address, address USDC_address) public view returns (uint) {
        uint token_bnb_price = getTokenPrice(self, crtoken_address);
        uint usd_bnb_price = getUSDCBNBPrice(self, crUSDC_address);
        
        uint usdc_decimals = IBEP20(USDC_address).decimals();
        uint one_unit_of_usdc = SafeMath.mul(1, 10**usdc_decimals);
        return SafeMath.div(SafeMath.mul(token_bnb_price, one_unit_of_usdc), usd_bnb_price);
    }
    
    function repay(address crtoken_address, uint repay_amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IBEP20(underlying_address).approve(crtoken_address, repay_amount);
        return CErc20Delegator(crtoken_address).repayBorrow(repay_amount);
    }
    
    function repayETH(address crBNB_address, uint repay_amount) public returns (uint) {
        
        return CErc20Delegator(crBNB_address).repayBorrow(repay_amount);
    }
    
    // TODO Johnny need to confirm this function again.
    function repayAll(address token_addr, address crtoken_address, address crWBNB_address) public returns (bool) {
        uint current_wallet_amount = getWalletAmount(token_addr);
        uint borrow_amount = getBorrowAmount(crtoken_address, crWBNB_address);
        
        require(current_wallet_amount >= borrow_amount, "Not enough funds in the wallet for the transaction");
        repay(crtoken_address, borrow_amount);
        
        return true;
    }

    /// @param crtoken_address Cream crToken address
    /// @param amount amount of tokens to mint.
    /// @dev Supplies amount worth of crtokens into cream.
    function supply(address crtoken_address, uint amount) public returns (uint) {
        address underlying_address = getUnderlyingAddress(crtoken_address);
        IBEP20(underlying_address).approve(crtoken_address, amount);
        return CErc20Delegator(crtoken_address).mint(amount);
    }
    
    /// @param crtoken_address Cream crToken address
    /// @param amount amount of crtokens to redeem.
    /// @dev Redeem amount worth of crtokens back.
    function redeemUnderlying(address crtoken_address, uint amount) public returns (uint) {
        IBEP20(crtoken_address).approve(crtoken_address, amount);
        return CErc20Delegator(crtoken_address).redeemUnderlying(amount);
    }
    
    function getTokenBalance(address token_address) public view returns (uint) {
        
        return IBEP20(token_address).balanceOf(address(this));
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface PriceOracleProxy {

    function getUnderlyingPrice(address cToken) external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface CErc20Delegator {

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and reserves.
     * @dev This calculates interest accrued from the last checkpointed block
     *      up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external returns (uint256);

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another cToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
    
    function interestRateModel() external view returns (address);
    
    function totalBorrows() external view returns (uint256);
    
    function totalReserves() external view returns (uint256);
    
    function decimals() external view returns (uint8);
    
    function reserveFactorMantissa() external view returns (uint256);

    function underlying() external view returns (address);
}