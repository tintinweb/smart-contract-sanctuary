/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;
/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/
*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function priceOf(address asset) external view returns (uint);

    function pricesOf(address[] memory assets) external view returns (uint[] memory);

    function getUnderlyingPrice(address qToken) external view returns (uint);

    function getUnderlyingPrices(address[] memory qTokens) external view returns (uint[] memory);

    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
}
pragma solidity ^0.8;


interface IQToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint);

    function accountSnapshot(address account) external view returns (QConstant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint);

    function borrowBalanceOf(address account) external view returns (uint);

    function borrowRatePerSec() external view returns (uint);

    function supplyRatePerSec() external view returns (uint);

    function totalBorrow() external view returns (uint);

    function exchangeRate() external view returns (uint);

    function getCash() external view returns (uint);

    function getAccInterestIndex() external view returns (uint);

    function accruedAccountSnapshot(address account) external returns (QConstant.AccountSnapshot memory);

    function accruedUnderlyingBalanceOf(address account) external returns (uint);

    function accruedBorrowBalanceOf(address account) external returns (uint);

    function accruedTotalBorrow() external returns (uint);

    function accruedExchangeRate() external returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external returns (bool);

    function supply(address account, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address account, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address account, uint underlyingAmount) external returns (uint);

    function borrow(address account, uint amount) external returns (uint);

    function repayBorrow(address account, uint amount) external payable returns (uint);

    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable returns (uint);

    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable returns (uint qAmountToSeize);

    function seize(
        address liquidator,
        address borrower,
        uint qTokenAmount
    ) external;
}
pragma solidity ^0.8;

library QConstant {
    uint public constant CLOSE_FACTOR_MIN = 5e16;
    uint public constant CLOSE_FACTOR_MAX = 9e17;
    uint public constant COLLATERAL_FACTOR_MAX = 9e17;

    struct MarketInfo {
        bool isListed;
        uint borrowCap;
        uint collateralFactor;
    }

    struct BorrowInfo {
        uint borrow;
        uint interestIndex;
    }

    struct AccountSnapshot {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
    }
    
    struct AccountSnapshot2 {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
        uint price_per_token;
        
    }

    struct AccrueSnapshot {
        uint totalBorrow;
        uint totalReserve;
        uint accInterestIndex;
    }
    
        struct MarketData {
        uint apySupply;
        uint apySupplyQBT;
        uint apyMySupplyQBT;
        uint apyBorrow;
        uint apyBorrowQBT;
        uint apyMyBorrowQBT;
        uint liquidity;
        uint collateralFactor;
        bool membership;
        uint supply;
        uint borrow;
        uint totalSupply;
        uint totalBorrow;
        uint supplyBoosted;
        uint borrowBoosted;
        uint totalSupplyBoosted;
        uint totalBorrowBoosted;
    }

    struct PortfolioData {
        int userApy;
        uint userApySupply;
        uint userApySupplyQBT;
        uint userApyBorrow;
        uint userApyBorrowQBT;
        uint supplyInUSD;
        uint borrowInUSD;
        uint limitInUSD;
    }

    struct AccountLiquidityData {
        address account;
        uint marketCount;
        uint collateralUSD;
        uint borrowUSD;
    }
}
pragma solidity ^0.8;


interface IQore {
    function qValidator() external view returns (address);

    function getTotalUserList() external view returns (address[] memory);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address qToken) external view returns (QConstant.MarketInfo memory);

    function liquidationIncentive() external view returns (uint);

    function checkMembership(address account, address qToken) external view returns (bool);

    function enterMarkets(address[] memory qTokens) external;

    function exitMarket(address qToken) external;
    
    function totalUserList(uint input) external view returns (address);

    function supply(address qToken, uint underlyingAmount) external payable returns (uint);

    function redeemToken(address qToken, uint qTokenAmount) external returns (uint);

    function redeemUnderlying(address qToken, uint underlyingAmount) external returns (uint);

    function borrow(address qToken, uint amount) external;

    function repayBorrow(address qToken, uint amount) external payable;
    
    function closeFactor() external view returns (uint);

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable;

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable;
}
pragma solidity ^0.8;


interface IQValidator {
    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external returns (bool);

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external returns (bool);

    function liquidateAllowed(
        address qTokenBorrowed,
        address borrower,
        uint repayAmount,
        uint closeFactor
    ) external returns (bool);

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint actualRepayAmount
    ) external returns (uint qTokenAmount);

    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view returns (uint liquidity, uint shortfall);

    function getAccountLiquidityValue(address account) external view returns (uint collateralUSD, uint borrowUSD);
}

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.6;



//import "./interfaces/IQDashboard.sol";



contract RemixedDashboard{

using SafeMath for uint;

address private constant QBT_CONTROLLER = 0xb3f98A31A02d133f65da961086EcDa4133bdf48e;
address private constant QBT_VALIDATOR = 0xf512C21E691297361df143920d4eC2A98b17cC07;
//address private constant QBT_DASHBOARD = 0x5bA1B272D60f46371279aE7a1C13227Fb93F99c1;
address private constant QBT_PRICE_CHECKER = 0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6;

event Log(string message);

function getUserLiquidityData(uint page, uint resultPerPage, uint arrayLength) external view returns(QConstant.AccountLiquidityData[] memory, uint next)
{
    uint index = page.mul(resultPerPage);
    uint limit = page.add(1).mul(resultPerPage);
    next = page.add(1);
    
    if (limit > arrayLength) {
    limit = arrayLength;
    next = 0;
    }
    
    if (arrayLength == 0 || index > arrayLength - 1) {
    return (new QConstant.AccountLiquidityData[](0), 0);
    }
    
    QConstant.AccountLiquidityData[] memory segment = new QConstant.AccountLiquidityData[](limit.sub(index));
    
    uint cursor = 0;
    for (index; index < limit; index++) {
    if (index < arrayLength) {
        address account = IQore(QBT_CONTROLLER).totalUserList(index);
        uint marketCount = IQore(QBT_CONTROLLER).marketListOf(account).length;
        (uint collateralUSD, uint borrowUSD) = IQValidator(QBT_VALIDATOR).getAccountLiquidityValue(account);
        segment[cursor] = QConstant.AccountLiquidityData({
            account: account,
            marketCount: marketCount,
            collateralUSD: collateralUSD,
            borrowUSD: borrowUSD
        });
    }
    cursor++;
    }
    return (segment, next);
    }

function getBorrowData(address account) public view returns (QConstant.AccountSnapshot[] memory, address[] memory, uint[] memory){

    address[] memory _listmarkets = IQore(QBT_CONTROLLER).marketListOf(account);
    
    QConstant.AccountSnapshot[] memory snappies = new QConstant.AccountSnapshot[](_listmarkets.length);
    
    uint[] memory prices =  new uint[](_listmarkets.length);
    
    for (uint i = 0; i < _listmarkets.length; i++)
    {
        snappies[i] = IQToken(_listmarkets[i]).accountSnapshot(account);
        QConstant.MarketInfo memory _marketinfo = IQore(QBT_CONTROLLER).marketInfoOf(_listmarkets[i]);
        snappies[i].qTokenBalance = snappies[i].qTokenBalance.mul(snappies[i].exchangeRate).mul(_marketinfo.collateralFactor).div(1e36);
        snappies[i].borrowBalance = snappies[i].borrowBalance;
        //mul(snappies[i].exchangeRate).div(1e18)
        prices[i] = IPriceCalculator(QBT_PRICE_CHECKER).getUnderlyingPrice(_listmarkets[i]);
    }

    
    return (snappies, _listmarkets, prices);
    
}

function getBorrowData2(address account) public view returns (address bestCollateral, address bestBorrow, uint liq_amount){

    address[] memory _listmarkets = IQore(QBT_CONTROLLER).marketListOf(account);
    
    QConstant.AccountSnapshot[] memory snappies = new QConstant.AccountSnapshot[](_listmarkets.length);
    
    uint[] memory prices =  new uint[](_listmarkets.length);
    
    address _bestCollateral = address(0);
    address _bestBorrow = address(0);
    
    uint _best_collat_amount = 0;
    uint _best_collat_value = 0;
    uint _best_borrow_value = 0;
    uint _best_borrow_amount = 0;
    
    for (uint i = 0; i < _listmarkets.length; i++)
    {
        snappies[i] = IQToken(_listmarkets[i]).accountSnapshot(account);
        QConstant.MarketInfo memory _marketinfo = IQore(QBT_CONTROLLER).marketInfoOf(_listmarkets[i]);
        snappies[i].qTokenBalance = snappies[i].qTokenBalance.mul(snappies[i].exchangeRate).mul(_marketinfo.collateralFactor).div(1e36);
        snappies[i].borrowBalance = snappies[i].borrowBalance.mul(snappies[i].exchangeRate).div(1e18);
        prices[i] = IPriceCalculator(QBT_PRICE_CHECKER).getUnderlyingPrice(_listmarkets[i]);
        
        if (snappies[i].qTokenBalance.mul(prices[i]).div(1e18) >  _best_collat_value)
        {
            _bestCollateral = _listmarkets[i];
            _best_collat_value = snappies[i].qTokenBalance.mul(prices[i]).div(1e18);
            _best_collat_amount = snappies[i].qTokenBalance;
        }
        
        if (snappies[i].borrowBalance.mul(prices[i]).div(1e18) >  _best_borrow_value)
        {
            _bestBorrow = _listmarkets[i];
            _best_borrow_value = snappies[i].borrowBalance.mul(prices[i]).div(1e18);
            _best_borrow_amount = snappies[i].borrowBalance;
        }
    }
    
    _best_borrow_value = _best_borrow_value.mul(IQore(QBT_CONTROLLER).closeFactor()).div(1e18);
    _best_borrow_value -=1;
    _best_borrow_amount = _best_borrow_amount.mul(IQore(QBT_CONTROLLER).closeFactor()).div(1e18);
    _best_borrow_amount -=1;
    
    if (_best_collat_value < _best_borrow_value)
    {   
        require(false, "nope");
         _best_borrow_amount = _best_collat_value.mul(_best_borrow_amount).div(_best_borrow_value);
         _best_borrow_amount -=1;
         _best_borrow_value = _best_collat_value - 1;
    }
    require(_best_borrow_amount > 0 &&  _best_borrow_value > 0, "Borrow amount or borrow value was was 0");
    return (_bestCollateral, _bestBorrow, _best_borrow_amount);
    
    //All liquidate with these params
    
}

function getBorrowDataAuto(address account) public view returns (address bestCollateral, address bestBorrow, uint liq_amount){

    address[] memory _listmarkets = IQore(QBT_CONTROLLER).marketListOf(account);
    
    QConstant.AccountSnapshot[] memory snappies = new QConstant.AccountSnapshot[](_listmarkets.length);
    
    uint[] memory prices =  new uint[](_listmarkets.length);
    
    address _bestCollateral = address(0);
    address _bestBorrow = address(0);
    
    uint _best_collat_amount = 0;
    uint _best_collat_value = 0;
    uint _best_borrow_value = 0;
    uint _best_borrow_amount = 0;
    
    for (uint i = 0; i < _listmarkets.length; i++)
    {
        snappies[i] = IQToken(_listmarkets[i]).accountSnapshot(account);
        QConstant.MarketInfo memory _marketinfo = IQore(QBT_CONTROLLER).marketInfoOf(_listmarkets[i]);
        snappies[i].qTokenBalance = snappies[i].qTokenBalance.mul(snappies[i].exchangeRate).mul(_marketinfo.collateralFactor).div(1e36);
        snappies[i].borrowBalance = snappies[i].borrowBalance.mul(snappies[i].exchangeRate).div(1e18);
        prices[i] = IPriceCalculator(QBT_PRICE_CHECKER).getUnderlyingPrice(_listmarkets[i]);
        
        if (snappies[i].qTokenBalance.mul(prices[i]).div(1e18) >  _best_collat_value)
        {
            _bestCollateral = _listmarkets[i];
            _best_collat_value = snappies[i].qTokenBalance.mul(prices[i]).div(1e18);
            _best_collat_amount = snappies[i].qTokenBalance;
        }
        
        if (snappies[i].borrowBalance.mul(prices[i]).div(1e18) >  _best_borrow_value)
        {
            _bestBorrow = _listmarkets[i];
            _best_borrow_value = snappies[i].borrowBalance.mul(prices[i]).div(1e18);
            _best_borrow_amount = snappies[i].borrowBalance;
        }
    }
    
    _best_borrow_value = _best_borrow_value.mul(IQore(QBT_CONTROLLER).closeFactor()).div(1e18);
    _best_borrow_value -=1;
    _best_borrow_amount = _best_borrow_amount.mul(IQore(QBT_CONTROLLER).closeFactor()).div(1e18);
    _best_borrow_amount -=1;
    
    if (_best_collat_value < _best_borrow_value)
    {   
        require(false, "nope");
         _best_borrow_amount = _best_collat_value.mul(_best_borrow_amount).div(_best_borrow_value);
         _best_borrow_amount -=1;
         _best_borrow_value = _best_collat_value - 1;
    }
    require(_best_borrow_amount > 0 &&  _best_borrow_value > 0, "Borrow amount or borrow value was was 0");
    return (_bestCollateral, _bestBorrow, _best_borrow_amount);
    
    //All liquidate with these params
    
}


}