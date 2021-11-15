// File: contracts\interfaces\IRouter01.sol

pragma solidity >=0.5.0;

interface IRouter01 {
	function factory() external pure returns (address);
	function bDeployer() external pure returns (address);
	function cDeployer() external pure returns (address);
	function WETH() external pure returns (address);
	
	function mint(address poolToken, uint amount, address to, uint deadline) external returns (uint tokens);
	function mintETH(address poolToken, address to, uint deadline) external payable returns (uint tokens);
	function mintCollateral(address poolToken, uint amount, address to, uint deadline, bytes calldata permitData) external returns (uint tokens);
	
	function redeem(address poolToken, uint tokens, address to, uint deadline, bytes calldata permitData) external returns (uint amount);
	function redeemETH(address poolToken, uint tokens, address to, uint deadline, bytes calldata permitData) external returns (uint amountETH);

	function borrow(address borrowable, uint amount, address to, uint deadline, bytes calldata permitData) external;
	function borrowETH(address borrowable, uint amountETH, address to, uint deadline, bytes calldata permitData) external;
	
	function repay(address borrowable, uint amountMax, address borrower, uint deadline) external returns (uint amount);
	function repayETH(address borrowable, address borrower, uint deadline) external payable returns (uint amountETH);

	function liquidate(address borrowable, uint amountMax, address borrower, address to, uint deadline) external returns (uint amount, uint seizeTokens);
	function liquidateETH(address borrowable, address borrower, address to, uint deadline) external payable returns (uint amountETH, uint seizeTokens);
	
	function leverage(
		address uniswapV2Pair, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin,
		address to, uint deadline, bytes calldata permitDataA, bytes calldata permitDataB
	) external;
	function deleverage(
		address uniswapV2Pair, uint redeemTokens, uint amountAMin, uint amountBMin, uint deadline, bytes calldata permitData
	) external;
	
	function getBorrowable(address uniswapV2Pair, uint8 index) external view returns (address borrowable);
	function getCollateral(address uniswapV2Pair) external view returns (address collateral);
	function getLendingPool(address uniswapV2Pair) external view returns (address collateral, address borrowableA, address borrowableB);
}

// File: contracts\interfaces\IPoolToken.sol

pragma solidity >=0.5.0;

interface IPoolToken {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
}

// File: contracts\interfaces\IBorrowable.sol

pragma solidity >=0.5.0;

interface IBorrowable {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Borrowable ***/

	event BorrowApproval(address indexed owner, address indexed spender, uint value);
	event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint borrowAmount, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	event Liquidate(address indexed sender, address indexed borrower, address indexed liquidator, uint seizeTokens, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	
	function BORROW_FEE() external pure returns (uint);
	function collateral() external view returns (address);
	function reserveFactor() external view returns (uint);
	function exchangeRateLast() external view returns (uint);
	function borrowIndex() external view returns (uint);
	function totalBorrows() external view returns (uint);
	function borrowAllowance(address owner, address spender) external view returns (uint);
	function borrowBalance(address borrower) external view returns (uint);	
	function borrowTracker() external view returns (address);
	
	function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);
	function borrowApprove(address spender, uint256 value) external returns (bool);
	function borrowPermit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	function borrow(address borrower, address receiver, uint borrowAmount, bytes calldata data) external;
	function liquidate(address borrower, address liquidator) external returns (uint seizeTokens);
	function trackBorrow(address borrower) external;
	
	/*** Borrowable Interest Rate Model ***/

	event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);
	event CalculateKink(uint kinkRate);
	event CalculateBorrowRate(uint borrowRate);
	
	function KINK_BORROW_RATE_MAX() external pure returns (uint);
	function KINK_BORROW_RATE_MIN() external pure returns (uint);
	function KINK_MULTIPLIER() external pure returns (uint);
	function borrowRate() external view returns (uint);
	function kinkBorrowRate() external view returns (uint);
	function kinkUtilizationRate() external view returns (uint);
	function adjustSpeed() external view returns (uint);
	function rateUpdateTimestamp() external view returns (uint32);
	function accrualTimestamp() external view returns (uint32);
	
	function accrueInterest() external;
	
	/*** Borrowable Setter ***/

	event NewReserveFactor(uint newReserveFactor);
	event NewKinkUtilizationRate(uint newKinkUtilizationRate);
	event NewAdjustSpeed(uint newAdjustSpeed);
	event NewBorrowTracker(address newBorrowTracker);

	function RESERVE_FACTOR_MAX() external pure returns (uint);
	function KINK_UR_MIN() external pure returns (uint);
	function KINK_UR_MAX() external pure returns (uint);
	function ADJUST_SPEED_MIN() external pure returns (uint);
	function ADJUST_SPEED_MAX() external pure returns (uint);
	
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _collateral
	) external;
	function _setReserveFactor(uint newReserveFactor) external;
	function _setKinkUtilizationRate(uint newKinkUtilizationRate) external;
	function _setAdjustSpeed(uint newAdjustSpeed) external;
	function _setBorrowTracker(address newBorrowTracker) external;
}

// File: contracts\interfaces\ICollateral.sol

pragma solidity >=0.5.0;

interface ICollateral {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Collateral ***/
	
	function borrowable0() external view returns (address);
	function borrowable1() external view returns (address);
	function simpleUniswapOracle() external view returns (address);
	function safetyMarginSqrt() external view returns (uint);
	function liquidationIncentive() external view returns (uint);
	
	function getPrices() external returns (uint price0, uint price1);
	function tokensUnlocked(address from, uint value) external returns (bool);
	function accountLiquidityAmounts(address account, uint amount0, uint amount1) external returns (uint liquidity, uint shortfall);
	function accountLiquidity(address account) external returns (uint liquidity, uint shortfall);
	function canBorrow(address account, address borrowable, uint accountBorrows) external returns (bool);
	function seize(address liquidator, address borrower, uint repayAmount) external returns (uint seizeTokens);
	function flashRedeem(address redeemer, uint redeemAmount, bytes calldata data) external;
	
	/*** Collateral Setter ***/
	
	event NewSafetyMargin(uint newSafetyMarginSqrt);
	event NewLiquidationIncentive(uint newLiquidationIncentive);

	function SAFETY_MARGIN_SQRT_MIN() external pure returns (uint);
	function SAFETY_MARGIN_SQRT_MAX() external pure returns (uint);
	function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint);
	function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint);
	
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _borrowable0, 
		address _borrowable1
	) external;
	function _setSafetyMarginSqrt(uint newSafetyMarginSqrt) external;
	function _setLiquidationIncentive(uint newLiquidationIncentive) external;
}

// File: contracts\interfaces\IImpermaxCallee.sol

pragma solidity >=0.5.0;

interface IImpermaxCallee {
    function impermaxBorrow(address sender, address borrower, uint borrowAmount, bytes calldata data) external;
    function impermaxRedeem(address sender, uint redeemAmount, bytes calldata data) external;
}

// File: contracts\interfaces\IERC20.sol

pragma solidity >=0.5.0;

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

// File: contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\libraries\SafeMath.sol

pragma solidity =0.6.6;

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

// File: contracts\libraries\TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.6.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts\libraries\UniswapV2Library.sol

pragma solidity >=0.5.0;

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts\Router01.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

contract Router01 is IRouter01, IImpermaxCallee {
	using SafeMath for uint;

	address public immutable override factory;
	address public immutable override bDeployer;
	address public immutable override cDeployer;
	address public immutable override WETH;

	modifier ensure(uint deadline) {
		require(deadline >= block.timestamp, "ImpermaxRouter: EXPIRED");
		_;
	}

	modifier checkETH(address poolToken) {
		require(WETH == IPoolToken(poolToken).underlying(), "ImpermaxRouter: NOT_WETH");
		_;
	}

	constructor(address _factory, address _bDeployer, address _cDeployer, address _WETH) public {
		factory = _factory;
		bDeployer = _bDeployer;
		cDeployer = _cDeployer;
		WETH = _WETH;
	}

	receive() external payable {
		assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
	}

	/*** Mint ***/
	
	function _mint(
		address poolToken, 
		address underlying, 
		uint amount,
		address from,
		address to
	) internal virtual returns (uint tokens) {
		if (from == address(this)) TransferHelper.safeTransfer(underlying, poolToken, amount);
		else TransferHelper.safeTransferFrom(underlying, from, poolToken, amount);
		tokens = IPoolToken(poolToken).mint(to);
	}
	function mint(
		address poolToken, 
		uint amount,
		address to,
		uint deadline
	) external virtual override ensure(deadline) returns (uint tokens) {
		return _mint(poolToken, IPoolToken(poolToken).underlying(), amount, msg.sender, to);
	}
	function mintETH(
		address poolToken, 
		address to,
		uint deadline
	) external virtual override payable ensure(deadline) checkETH(poolToken) returns (uint tokens) {
		IWETH(WETH).deposit{value: msg.value}();
		return _mint(poolToken, WETH, msg.value, address(this), to);
	}
	function mintCollateral(
		address poolToken, 
		uint amount,
		address to,
		uint deadline,
		bytes calldata permitData
	) external virtual override ensure(deadline) returns (uint tokens) {
		address uniswapV2Pair = IPoolToken(poolToken).underlying();
		_permitUniswapV2Pair(uniswapV2Pair, amount, deadline, permitData);
		return _mint(poolToken, uniswapV2Pair, amount, msg.sender, to);
	}
	
	/*** Redeem ***/
	
	function redeem(
		address poolToken,
		uint tokens,
		address to,
		uint deadline,
		bytes memory permitData
	) public virtual override ensure(deadline) returns (uint amount) {
		_permit(poolToken, tokens, deadline, permitData);
		IPoolToken(poolToken).transferFrom(msg.sender, poolToken, tokens);
		amount = IPoolToken(poolToken).redeem(to);
	}
	function redeemETH(
		address poolToken, 
		uint tokens,
		address to,
		uint deadline,
		bytes memory permitData
	) public virtual override ensure(deadline) checkETH(poolToken) returns (uint amountETH) {
		amountETH = redeem(poolToken, tokens, address(this), deadline, permitData);
		IWETH(WETH).withdraw(amountETH);
		TransferHelper.safeTransferETH(to, amountETH);
	}
			
	/*** Borrow ***/

	function borrow(
		address borrowable, 
		uint amount,
		address to,
		uint deadline,
		bytes memory permitData
	) public virtual override ensure(deadline) {
		_borrowPermit(borrowable, amount, deadline, permitData);
		IBorrowable(borrowable).borrow(msg.sender, to, amount, new bytes(0));
	}
	function borrowETH(
		address borrowable, 
		uint amountETH,
		address to,
		uint deadline,
		bytes memory permitData
	) public virtual override ensure(deadline) checkETH(borrowable) {
		borrow(borrowable, amountETH, address(this), deadline, permitData);
		IWETH(WETH).withdraw(amountETH);
		TransferHelper.safeTransferETH(to, amountETH);
	}
	
	/*** Repay ***/
	
	function _repayAmount(
		address borrowable, 
		uint amountMax,
		address borrower
	) internal virtual returns (uint amount) {
		IBorrowable(borrowable).accrueInterest();
		uint borrowedAmount = IBorrowable(borrowable).borrowBalance(borrower);
		amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
	}
	function repay(
		address borrowable, 
		uint amountMax,
		address borrower,
		uint deadline
	) external virtual override ensure(deadline) returns (uint amount) {
		amount = _repayAmount(borrowable, amountMax, borrower);
		TransferHelper.safeTransferFrom(IBorrowable(borrowable).underlying(), msg.sender, borrowable, amount);
		IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));
	}
	function repayETH(
		address borrowable, 
		address borrower,
		uint deadline
	) external virtual override payable ensure(deadline) checkETH(borrowable) returns (uint amountETH) {
		amountETH = _repayAmount(borrowable, msg.value, borrower);
		IWETH(WETH).deposit{value: amountETH}();
		assert(IWETH(WETH).transfer(borrowable, amountETH));
		IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));
		// refund surpluss eth, if any
		if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
	}
	
	/*** Liquidate ***/

	function liquidate(
		address borrowable, 
		uint amountMax,
		address borrower,
		address to,
		uint deadline
	) external virtual override ensure(deadline) returns (uint amount, uint seizeTokens) {
		amount = _repayAmount(borrowable, amountMax, borrower);
		TransferHelper.safeTransferFrom(IBorrowable(borrowable).underlying(), msg.sender, borrowable, amount);
		seizeTokens = IBorrowable(borrowable).liquidate(borrower, to);
	}
	function liquidateETH(
		address borrowable, 
		address borrower,
		address to,
		uint deadline
	) external virtual override payable ensure(deadline) checkETH(borrowable) returns (uint amountETH, uint seizeTokens) {
		amountETH = _repayAmount(borrowable, msg.value, borrower);
		IWETH(WETH).deposit{value: amountETH}();
		assert(IWETH(WETH).transfer(borrowable, amountETH));
		seizeTokens = IBorrowable(borrowable).liquidate(borrower, to);
		// refund surpluss eth, if any
		if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
	}
		
	/*** Leverage LP Token ***/
	
	function _leverage(
		address uniswapV2Pair, 
		uint amountA,
		uint amountB,
		address to
	) internal virtual {
		address borrowableA = getBorrowable(uniswapV2Pair, 0);
		// mint collateral
		bytes memory borrowBData = abi.encode(CalleeData({
			callType: CallType.ADD_LIQUIDITY_AND_MINT,
			uniswapV2Pair: uniswapV2Pair,
			borrowableIndex: 1,
			data: abi.encode(AddLiquidityAndMintCalldata({
				amountA: amountA,
				amountB: amountB,
				to: to
			}))
		}));	
		// borrow borrowableB
		bytes memory borrowAData = abi.encode(CalleeData({
			callType: CallType.BORROWB,
			uniswapV2Pair: uniswapV2Pair,
			borrowableIndex: 0,
			data: abi.encode(BorrowBCalldata({
				borrower: msg.sender,
				receiver: address(this),
				borrowAmount: amountB,
				data: borrowBData
			}))
		}));
		// borrow borrowableA
		IBorrowable(borrowableA).borrow(msg.sender, address(this), amountA, borrowAData);	
	}
	function leverage(
		address uniswapV2Pair,  
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline,
		bytes calldata permitDataA,
		bytes calldata permitDataB
	) external virtual override ensure(deadline) {
		_borrowPermit(getBorrowable(uniswapV2Pair, 0), amountADesired, deadline, permitDataA);
		_borrowPermit(getBorrowable(uniswapV2Pair, 1), amountBDesired, deadline, permitDataB);
		(uint amountA, uint amountB) = _optimalLiquidity(uniswapV2Pair, amountADesired, amountBDesired, amountAMin, amountBMin);
		_leverage(uniswapV2Pair, amountA, amountB, to);
	}

	function _addLiquidityAndMint(
		address uniswapV2Pair, 
		uint amountA,
		uint amountB,
		address to
	) internal virtual {
		(address collateral, address borrowableA, address borrowableB) = getLendingPool(uniswapV2Pair);
		// add liquidity to uniswap pair
		TransferHelper.safeTransfer(IBorrowable(borrowableA).underlying(), uniswapV2Pair, amountA);
		TransferHelper.safeTransfer(IBorrowable(borrowableB).underlying(), uniswapV2Pair, amountB);
		IUniswapV2Pair(uniswapV2Pair).mint(collateral);
		// mint collateral
		ICollateral(collateral).mint(to);
	}
		
	/*** Deleverage LP Token ***/
	
	function deleverage(
		address uniswapV2Pair,  
		uint redeemTokens,
		uint amountAMin,
		uint amountBMin,
		uint deadline,
		bytes calldata permitData
	) external virtual override ensure(deadline) {
		address collateral = getCollateral(uniswapV2Pair);
		uint exchangeRate = ICollateral(collateral).exchangeRate();
		require(redeemTokens > 0, "ImpermaxRouter: REDEEM_ZERO");		
		uint redeemAmount = (redeemTokens - 1).mul(exchangeRate).div(1e18);
		_permit(collateral, redeemTokens, deadline, permitData);
		bytes memory redeemData = abi.encode(CalleeData({
			callType: CallType.REMOVE_LIQ_AND_REPAY,
			uniswapV2Pair: uniswapV2Pair,
			borrowableIndex: 0,
			data: abi.encode(RemoveLiqAndRepayCalldata({
				borrower: msg.sender,
				redeemTokens: redeemTokens,
				redeemAmount: redeemAmount,
				amountAMin: amountAMin,
				amountBMin: amountBMin
			}))
		}));
		// flashRedeem
		ICollateral(collateral).flashRedeem(address(this), redeemAmount, redeemData);
	}

	function _removeLiqAndRepay(
		address uniswapV2Pair,
		address borrower,
		uint redeemTokens,
		uint redeemAmount,
		uint amountAMin,
		uint amountBMin
	) internal virtual {
		(address collateral, address borrowableA, address borrowableB) = getLendingPool(uniswapV2Pair);
		address tokenA = IBorrowable(borrowableA).underlying();
		address tokenB = IBorrowable(borrowableB).underlying();
		// removeLiquidity
		TransferHelper.safeTransfer(uniswapV2Pair, uniswapV2Pair, redeemAmount);
		(uint amountAMax, uint amountBMax) = IUniswapV2Pair(uniswapV2Pair).burn(address(this));
		require(amountAMax >= amountAMin, "ImpermaxRouter: INSUFFICIENT_A_AMOUNT");
		require(amountBMax >= amountBMin, "ImpermaxRouter: INSUFFICIENT_B_AMOUNT");
		// repay and refund
		_repayAndRefund(borrowableA, tokenA, borrower, amountAMax);
		_repayAndRefund(borrowableB, tokenB, borrower, amountBMax);
		// repay flash redeem
		ICollateral(collateral).transferFrom(borrower, collateral, redeemTokens);
	}
	
	function _repayAndRefund(
		address borrowable,
		address token,
		address borrower,
		uint amountMax
	) internal virtual {
		//repay
		uint amount = _repayAmount(borrowable, amountMax, borrower);
		TransferHelper.safeTransfer(token, borrowable, amount);
		IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));		
		// refund excess
		if (amountMax > amount) {
			uint refundAmount = amountMax - amount;
			if (token == WETH) {		
				IWETH(WETH).withdraw(refundAmount);
				TransferHelper.safeTransferETH(borrower, refundAmount);
			}
			else TransferHelper.safeTransfer(token, borrower, refundAmount);
		}
	}
	
	/*** Impermax Callee ***/
		
	enum CallType {ADD_LIQUIDITY_AND_MINT, BORROWB, REMOVE_LIQ_AND_REPAY}
	struct CalleeData {
		CallType callType;
		address uniswapV2Pair;
		uint8 borrowableIndex;
		bytes data;		
	}
	struct AddLiquidityAndMintCalldata {
		uint amountA;
		uint amountB;
		address to;
	}
	struct BorrowBCalldata {
		address borrower; 
		address receiver;
		uint borrowAmount;
		bytes data;
	}
	struct RemoveLiqAndRepayCalldata {
		address borrower;
		uint redeemTokens;
		uint redeemAmount;
		uint amountAMin;
		uint amountBMin;
	}
	
	function impermaxBorrow(address sender, address borrower, uint borrowAmount, bytes calldata data) external virtual override {
		borrower; borrowAmount;
		CalleeData memory calleeData = abi.decode(data, (CalleeData));
		address declaredCaller = getBorrowable(calleeData.uniswapV2Pair, calleeData.borrowableIndex);
		// only succeeds if called by a borrowable and if that borrowable has been called by the router
		require(sender == address(this), "ImpermaxRouter: SENDER_NOT_ROUTER");
		require(msg.sender == declaredCaller, "ImpermaxRouter: UNAUTHORIZED_CALLER");
		if (calleeData.callType == CallType.ADD_LIQUIDITY_AND_MINT) {
			AddLiquidityAndMintCalldata memory d = abi.decode(calleeData.data, (AddLiquidityAndMintCalldata));
			_addLiquidityAndMint(calleeData.uniswapV2Pair, d.amountA, d.amountB, d.to);
		}
		else if (calleeData.callType == CallType.BORROWB) {
			BorrowBCalldata memory d = abi.decode(calleeData.data, (BorrowBCalldata));
			address borrowableB = getBorrowable(calleeData.uniswapV2Pair, 1);
			IBorrowable(borrowableB).borrow(d.borrower, d.receiver, d.borrowAmount, d.data);
		}
		else revert();
	}
	
	function impermaxRedeem(address sender, uint redeemAmount, bytes calldata data) external virtual override {
		redeemAmount;
		CalleeData memory calleeData = abi.decode(data, (CalleeData));
		address declaredCaller = getCollateral(calleeData.uniswapV2Pair);
		// only succeeds if called by a collateral and if that collateral has been called by the router
		require(sender == address(this), "ImpermaxRouter: SENDER_NOT_ROUTER");
		require(msg.sender == declaredCaller, "ImpermaxRouter: UNAUTHORIZED_CALLER");
		if (calleeData.callType == CallType.REMOVE_LIQ_AND_REPAY) {
			RemoveLiqAndRepayCalldata memory d = abi.decode(calleeData.data, (RemoveLiqAndRepayCalldata));
			_removeLiqAndRepay(calleeData.uniswapV2Pair, d.borrower, d.redeemTokens, d.redeemAmount, d.amountAMin, d.amountBMin);
		}
		else revert();
	}
		
	/*** Utilities ***/
	
	function _permit(
		address poolToken, 
		uint amount, 
		uint deadline,
		bytes memory permitData
	) internal virtual {
		if (permitData.length == 0) return;
		(bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (bool, uint8, bytes32, bytes32));
		uint value = approveMax ? uint(-1) : amount;
		IPoolToken(poolToken).permit(msg.sender, address(this), value, deadline, v, r, s);
	}
	function _permitUniswapV2Pair(
		address uniswapV2Pair, 
		uint amount, 
		uint deadline,
		bytes memory permitData
	) internal virtual {
		if (permitData.length == 0) return;
		(bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (bool, uint8, bytes32, bytes32));
		uint value = approveMax ? uint(-1) : amount;
		IUniswapV2Pair(uniswapV2Pair).permit(msg.sender, address(this), value, deadline, v, r, s);
	}
	function _borrowPermit(
		address borrowable, 
		uint amount, 
		uint deadline,
		bytes memory permitData
	) internal virtual {
		if (permitData.length == 0) return;
		(bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (bool, uint8, bytes32, bytes32));
		uint value = approveMax ? uint(-1) : amount;
		IBorrowable(borrowable).borrowPermit(msg.sender, address(this), value, deadline, v, r, s);
	}
	
	function _optimalLiquidity(
		address uniswapV2Pair,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin
	) public virtual view returns (uint amountA, uint amountB) {
		(uint reserveA, uint reserveB,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
		uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
		if (amountBOptimal <= amountBDesired) {
			require(amountBOptimal >= amountBMin, "ImpermaxRouter: INSUFFICIENT_B_AMOUNT");
			(amountA, amountB) = (amountADesired, amountBOptimal);
		} else {
			uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
			assert(amountAOptimal <= amountADesired);
			require(amountAOptimal >= amountAMin, "ImpermaxRouter: INSUFFICIENT_A_AMOUNT");
			(amountA, amountB) = (amountAOptimal, amountBDesired);
		}
	}
	
	function getBorrowable(address uniswapV2Pair, uint8 index) public virtual override view returns (address borrowable) {
		require(index < 2, "ImpermaxRouter: INDEX_TOO_HIGH");
		borrowable = address(uint(keccak256(abi.encodePacked(
			hex"ff",
			bDeployer,
			keccak256(abi.encodePacked(factory, uniswapV2Pair, index)),
			hex"605ba1db56496978613939baf0ae31dccceea3f5ca53dfaa76512bc880d7bb8f" // Borrowable bytecode keccak256
		))));
	}
	function getCollateral(address uniswapV2Pair) public virtual override view returns (address collateral) {
		collateral = address(uint(keccak256(abi.encodePacked(
			hex"ff",
			cDeployer,
			keccak256(abi.encodePacked(factory, uniswapV2Pair)),
			hex"4b8788d8761647e6330407671d3c6c80afaed3d047800dba0e0e3befde047767" // Collateral bytecode keccak256
		))));
	}
	function getLendingPool(address uniswapV2Pair) public virtual override view returns (address collateral, address borrowableA, address borrowableB) {
		collateral = getCollateral(uniswapV2Pair);
		borrowableA = getBorrowable(uniswapV2Pair, 0);
		borrowableB = getBorrowable(uniswapV2Pair, 1);
	}
}

