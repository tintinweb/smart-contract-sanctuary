pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. using constant string instead of enums
*/

contract ControllerErrorReporter {
    string internal constant MARKET_NOT_LISTED = "MARKET_NOT_LISTED";
    string internal constant MARKET_ALREADY_LISTED = "MARKET_ALREADY_LISTED";
    string internal constant MARKET_ALREADY_ADDED = "MARKET_ALREADY_ADDED";
    string internal constant EXIT_MARKET_BALANCE_OWED = "EXIT_MARKET_BALANCE_OWED";
    string internal constant EXIT_MARKET_REJECTION = "EXIT_MARKET_REJECTION";
    string internal constant MINT_PAUSED = "MINT_PAUSED";
    string internal constant BORROW_PAUSED = "BORROW_PAUSED";
    string internal constant SEIZE_PAUSED = "SEIZE_PAUSED";
    string internal constant TRANSFER_PAUSED = "TRANSFER_PAUSED";
    string internal constant MARKET_BORROW_CAP_REACHED = "MARKET_BORROW_CAP_REACHED";
    string internal constant MARKET_SUPPLY_CAP_REACHED = "MARKET_SUPPLY_CAP_REACHED";
    string internal constant REDEEM_TOKENS_ZERO = "REDEEM_TOKENS_ZERO";
    string internal constant INSUFFICIENT_LIQUIDITY = "INSUFFICIENT_LIQUIDITY";
    string internal constant INSUFFICIENT_SHORTFALL = "INSUFFICIENT_SHORTFALL";
    string internal constant TOO_MUCH_REPAY = "TOO_MUCH_REPAY";
    string internal constant CONTROLLER_MISMATCH = "CONTROLLER_MISMATCH";
    string internal constant INVALID_COLLATERAL_FACTOR = "INVALID_COLLATERAL_FACTOR";
    string internal constant INVALID_CLOSE_FACTOR = "INVALID_CLOSE_FACTOR";
    string internal constant INVALID_LIQUIDATION_INCENTIVE = "INVALID_LIQUIDATION_INCENTIVE";
}

contract KTokenErrorReporter {
    string internal constant BAD_INPUT = "BAD_INPUT";
    string internal constant TRANSFER_NOT_ALLOWED = "TRANSFER_NOT_ALLOWED";
    string internal constant TRANSFER_NOT_ENOUGH = "TRANSFER_NOT_ENOUGH";
    string internal constant TRANSFER_TOO_MUCH = "TRANSFER_TOO_MUCH";
    string internal constant MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED = "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED";
    string internal constant MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED = "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED";
    string internal constant REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED = "REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED";
    string internal constant REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED = "REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED";
    string internal constant BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED = "BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED";
    string internal constant BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED = "BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED";
    string internal constant REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED = "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED";
    string internal constant REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED = "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED";
    string internal constant INVALID_CLOSE_AMOUNT_REQUESTED = "INVALID_CLOSE_AMOUNT_REQUESTED";
    string internal constant LIQUIDATE_SEIZE_TOO_MUCH = "LIQUIDATE_SEIZE_TOO_MUCH";
    string internal constant TOKEN_INSUFFICIENT_CASH = "TOKEN_INSUFFICIENT_CASH";
    string internal constant INVALID_ACCOUNT_PAIR = "INVALID_ACCOUNT_PAIR";
    string internal constant LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED = "LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED";
    string internal constant LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED = "LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED";
    string internal constant TOKEN_TRANSFER_IN_FAILED = "TOKEN_TRANSFER_IN_FAILED";
    string internal constant TOKEN_TRANSFER_IN_OVERFLOW = "TOKEN_TRANSFER_IN_OVERFLOW";
    string internal constant TOKEN_TRANSFER_OUT_FAILED = "TOKEN_TRANSFER_OUT_FAILED";

}

pragma solidity ^0.5.16;

import "./KineSafeMath.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. use SafeMath instead of CarefulMath to fail fast and loudly
*/

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential {
    using KineSafeMath for uint;
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale / 2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     */
    function getExp(uint num, uint denom) pure internal returns (Exp memory) {
        uint rational = num.mul(expScale).div(denom);
        return Exp({mantissa : rational});
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint result = a.mantissa.add(b.mantissa);
        return Exp({mantissa : result});
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint result = a.mantissa.sub(b.mantissa);
        return Exp({mantissa : result});
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        uint scaledMantissa = a.mantissa.mul(scalar);
        return Exp({mantissa : scaledMantissa});
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        uint descaledMantissa = a.mantissa.div(scalar);
        return Exp({mantissa : descaledMantissa});
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (Exp memory) {
        /*
          We are doing this as:
          getExp(expScale.mul(scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        uint numerator = expScale.mul(scalar);
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (uint) {
        Exp memory fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint doubleScaledProduct = a.mantissa.mul(b.mantissa);

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        uint doubleScaledProductWithHalfScale = halfExpScale.add(doubleScaledProduct);
        uint product = doubleScaledProductWithHalfScale.div(expScale);
        return Exp({mantissa : product});
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (Exp memory) {
        return mulExp(Exp({mantissa : a}), Exp({mantissa : b}));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return getExp(a.mantissa, b.mantissa);
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
        require(n < 2 ** 224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : add_(a.mantissa, b.mantissa)});
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
        return Exp({mantissa : sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa : mul_(a.mantissa, b)});
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
        return Exp({mantissa : div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa : div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa : div_(a.mantissa, b)});
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
        return Double({mantissa : div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";
import "./KMCDInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./KTokenInterfaces.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed mint, redeem logics. users can only supply kTokens (see KToken) and borrow Kine MCD.
*   4. removed transfer logics. MCD can't be transferred.
*   5. removed error code propagation mechanism, using revert to fail fast and loudly.
*/

/**
 * @title Kine's KMCD Contract
 * @notice Kine Market Connected Debt (MCD) contract. Users are allowed to call KUSDMinter to borrow Kine MCD and mint KUSD
 * after they supply collaterals in KTokens. One should notice that Kine MCD is not ERC20 token since it can't be transferred by user.
 * @author Kine
 */
contract KMCD is KMCDInterface, Exponential, KTokenErrorReporter {
    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin can call this function");
        _;
    }

    /// @notice Prevent anyone other than minter from borrow/repay Kine MCD
    modifier onlyMinter {
        require(
            msg.sender == minter,
            "Only minter can call this function."
        );
        _;
    }

    /**
     * @notice Initialize the money market
     * @param controller_ The address of the Controller
     * @param name_ Name of this MCD token
     * @param symbol_ Symbol of this MCD token
     * @param decimals_ Decimal precision of this token
     */
    function initialize(KineControllerInterface controller_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address minter_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(initialized == false, "market may only be initialized once");

        // Set the controller
        _setController(controller_);

        minter = minter_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        initialized = true;
    }

    /*** User Interface ***/

    /**
      * @notice Only minter can borrow Kine MCD on behalf of user from the protocol
      * @param borrowAmount Amount of Kine MCD to borrow on behalf of user
      */
    function borrowBehalf(address payable borrower, uint borrowAmount) onlyMinter external {
        borrowInternal(borrower, borrowAmount);
    }

    /**
     * @notice Only minter can repay Kine MCD on behalf of borrower to the protocol
     * @param borrower Account with the MCD being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) onlyMinter external {
        repayBorrowBehalfInternal(borrower, repayAmount);
    }

    /**
     * @notice Only minter can liquidates the borrowers collateral on behalf of user
     *  The collateral seized is transferred to the liquidator
     * @param borrower The borrower of MCD to be liquidated
     * @param repayAmount The amount of the MCD to repay
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrowBehalf(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) onlyMinter external {
        liquidateBorrowInternal(liquidator, borrower, repayAmount, kTokenCollateral);
    }

    /**
     * @notice Get a snapshot of the account's balances
     * @dev This is used by controller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint) {
        return (0, accountBorrows[account]);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice get account's borrow balance
     * @param account The address whose balance should be get
     * @return The balance
     */
    function borrowBalance(address account) public view returns (uint) {
        return accountBorrows[account];
    }

    /**
      * @notice Sender borrows MCD from the protocol to their own address
      * @param borrowAmount The amount of MCD to borrow
      */
    function borrowInternal(address payable borrower, uint borrowAmount) internal nonReentrant {
        borrowFresh(borrower, borrowAmount);
    }

    struct BorrowLocalVars {
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    /**
      * @notice Sender borrow MCD from the protocol to their own address
      * @param borrowAmount The amount of the MCD to borrow
      */
    function borrowFresh(address payable borrower, uint borrowAmount) internal {
        /* Fail if borrow not allowed */
        (bool allowed, string memory reason) = controller.borrowAllowed(address(this), borrower, borrowAmount);
        require(allowed, reason);

        BorrowLocalVars memory vars;

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        vars.accountBorrows = accountBorrows[borrower];

        vars.accountBorrowsNew = vars.accountBorrows.add(borrowAmount, BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED);
        vars.totalBorrowsNew = totalBorrows.add(borrowAmount, BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower] = vars.accountBorrowsNew;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        controller.borrowVerify(address(this), borrower, borrowAmount);
    }

    /**
     * @notice Sender repays MCD belonging to borrower
     * @param borrower the account with the MCD being payed off
     * @param repayAmount The amount to repay
     * @return the actual repayment amount.
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint) {
        return repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    struct RepayBorrowLocalVars {
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    /**
     * @notice Borrows are repaid by another user, should be the minter.
     * @param payer the account paying off the MCD
     * @param borrower the account with the MCD being payed off
     * @param repayAmount the amount of MCD being returned
     * @return the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint) {
        /* Fail if repayBorrow not allowed */
        (bool allowed, string memory reason) = controller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        require(allowed, reason);

        RepayBorrowLocalVars memory vars;

        /* We fetch the amount the borrower owes */
        vars.accountBorrows = accountBorrows[borrower];

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        vars.accountBorrowsNew = vars.accountBorrows.sub(repayAmount, REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED);
        vars.totalBorrowsNew = totalBorrows.sub(repayAmount, REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower] = vars.accountBorrowsNew;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, repayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        controller.repayBorrowVerify(address(this), payer, borrower, repayAmount);

        return repayAmount;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this MCD to be liquidated
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the MCD asset to repay
     * @return the actual repayment amount.
     */
    function liquidateBorrowInternal(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) internal nonReentrant returns (uint) {
        return liquidateBorrowFresh(liquidator, borrower, repayAmount, kTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this MCD to be liquidated
     * @param liquidator The address repaying the MCD and seizing collateral
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the borrowed MCD to repay
     * @return the actual repayment amount.
     */
    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) internal returns (uint) {
        /* Revert if trying to seize MCD */
        require(address(kTokenCollateral) != address(this), "Kine MCD can't be seized");

        /* Fail if liquidate not allowed */
        (bool allowed, string memory reason) = controller.liquidateBorrowAllowed(address(this), address(kTokenCollateral), liquidator, borrower, repayAmount);
        require(allowed, reason);

        /* Fail if borrower = liquidator */
        require(borrower != liquidator, INVALID_ACCOUNT_PAIR);

        /* Fail if repayAmount = 0 */
        require(repayAmount != 0, INVALID_CLOSE_AMOUNT_REQUESTED);

        /* Fail if repayAmount = -1 */
        require(repayAmount != uint(- 1), INVALID_CLOSE_AMOUNT_REQUESTED);

        /* Fail if repayBorrow fails */
        uint actualRepayAmount = repayBorrowFresh(liquidator, borrower, repayAmount);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /* We calculate the number of collateral tokens that will be seized */
        uint seizeTokens = controller.liquidateCalculateSeizeTokens(address(this), address(kTokenCollateral), actualRepayAmount);

        /* Revert if borrower collateral token balance < seizeTokens */
        require(kTokenCollateral.balanceOf(borrower) >= seizeTokens, LIQUIDATE_SEIZE_TOO_MUCH);

        /* Seize borrower tokens to liquidator */
        kTokenCollateral.seize(liquidator, borrower, seizeTokens);

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(kTokenCollateral), seizeTokens);

        /* We call the defense hook */
        controller.liquidateBorrowVerify(address(this), address(kTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

        return actualRepayAmount;
    }

    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external onlyAdmin() {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
      * @notice Sets a new controller for the market
      * @dev Admin function to set a new controller
      */
    function _setController(KineControllerInterface newController) public onlyAdmin() {
        KineControllerInterface oldController = controller;
        // Ensure invoke controller.isController() returns true
        require(newController.isController(), "marker method returned false");

        // Set market's controller to newController
        controller = newController;

        // Emit NewController(oldController, newController)
        emit NewController(oldController, newController);
    }

    function _setMinter(address newMinter) public onlyAdmin() {
        address oldMinter = minter;
        minter = newMinter;

        emit NewMinter(oldMinter, newMinter);
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
        // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./KMCD.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @title Kine's KMCDDelegate Contract
 * @author Kine
 */
contract KMCDDelegate is KMCD, KDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";

contract KMCDStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
    * @notice flag that Kine MCD has been initialized;
    */
    bool public initialized;

    /**
    * @notice Only KUSDMinter can borrow/repay Kine MCD on behalf of users;
    */
    address public minter;

    /**
     * @notice Name for this MCD
     */
    string public name;

    /**
     * @notice Symbol for this MCD
     */
    string public symbol;

    /**
     * @notice Decimals for this MCD
     */
    uint8 public decimals;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-kToken operations
     */
    KineControllerInterface public controller;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint)) internal transferAllowances;

    /**
     * @notice Total amount of outstanding borrows of the MCD
     */
    uint public totalBorrows;

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => uint) internal accountBorrows;
}

contract KMCDInterface is KMCDStorage {
    /**
     * @notice Indicator that this is a KToken contract (for inspection)
     */
    bool public constant isKToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when MCD is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address kTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(KineControllerInterface oldController, KineControllerInterface newController);

    /**
     * @notice Event emitted when minter is changed
     */
    event NewMinter(address oldMinter, address newMinter);


    /*** User Interface ***/

    function getAccountSnapshot(address account) external view returns (uint, uint);

    function borrowBalance(address account) public view returns (uint);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external;

    function _acceptAdmin() external;

    function _setController(KineControllerInterface newController) public;
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";

contract KTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
    * @notice flag that kToken has been initialized;
    */
    bool public initialized;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-kToken operations
     */
    KineControllerInterface public controller;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

}

contract KTokenInterface is KTokenStorage {
    /**
     * @notice Indicator that this is a KToken contract (for inspection)
     */
    bool public constant isKToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(KineControllerInterface oldController, KineControllerInterface newController);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint);
    function getCash() external view returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external;


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external;
    function _acceptAdmin() external;
    function _setController(KineControllerInterface newController) public;
}

contract KErc20Storage {
    /**
     * @notice Underlying asset for this KToken
     */
    address public underlying;
}

contract KErc20Interface is KErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external;

}

contract KDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract KDelegatorInterface is KDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract KDelegateInterface is KDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerInterface.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed error code propagation mechanism to fail fast and loudly
*/

contract KineControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /// @notice oracle getter function
    function getOracle() external view returns (address);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata kTokens) external;

    function exitMarket(address kToken) external;

    /*** Policy Hooks ***/

    function mintAllowed(address kToken, address minter, uint mintAmount) external returns (bool, string memory);

    function mintVerify(address kToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address kToken, address redeemer, uint redeemTokens) external returns (bool, string memory);

    function redeemVerify(address kToken, address redeemer, uint redeemTokens) external;

    function borrowAllowed(address kToken, address borrower, uint borrowAmount) external returns (bool, string memory);

    function borrowVerify(address kToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function repayBorrowVerify(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external;

    function liquidateBorrowAllowed(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function liquidateBorrowVerify(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (bool, string memory);

    function seizeVerify(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address kToken, address src, address dst, uint transferTokens) external returns (bool, string memory);

    function transferVerify(address kToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address kTokenBorrowed,
        address kTokenCollateral,
        uint repayAmount) external view returns (uint);
}

pragma solidity ^0.5.0;

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

/**
 * Original work from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol
 * changes we made:
 * 1. add two methods that take errorMessage as input parameter
 */

library KineSafeMath {
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     * added by Kine
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

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
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     * added by Kine
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