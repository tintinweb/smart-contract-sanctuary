/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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


// File contracts/library/BasisPoints.sol

pragma solidity =0.6.6;
library BasisPoints {
    using SafeMathUpgradeable for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}


// File contracts/interfaces/ILiftoffEngine.sol

pragma solidity =0.6.6;

interface ILiftoffEngine {
    function launchToken(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _totalSupply,
        string calldata _name,
        string calldata _symbol,
        address _projectDev
    ) external returns (uint256 tokenId);

    function launchTokenWithFixedRate(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _fixedRate,
        string calldata _name,
        string calldata _symbol,
        address _projectDev
    ) external returns (uint256 tokenId);

    function igniteEth(uint256 _tokenSaleId) external payable;

    function ignite(
        uint256 _tokenSaleId,
        address _for,
        uint256 _amountXEth
    ) external;

    function undoIgniteEth(uint256 _tokenSaleId) external;

    function undoIgnite(uint256 _tokenSaleId) external;

    function claimReward(uint256 _tokenSaleId, address _for) external;

    function spark(uint256 _tokenSaleId) external;

    function claimRefundEth(uint256 _tokenSaleId, address _for) external;

    function claimRefund(uint256 _tokenSaleId, address _for) external;

    function getTokenSale(uint256 _tokenSaleId)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 softCap,
            uint256 hardCap,
            uint256 totalIgnited,
            uint256 totalSupply,
            uint256 rewardSupply,
            address projectDev,
            address deployed,
            bool isSparked
        );

    function getTokenSaleForInsurance(uint256 _tokenSaleId)
        external
        view
        returns (
            uint256 totalIgnited,
            uint256 rewardSupply,
            address projectDev,
            address pair,
            address deployed
        );

    function getTokenSaleProjectDev(uint256 _tokenSaleId)
        external
        view
        returns (address projectDev);

    function getTokenSaleStartTime(uint256 _tokenSaleId)
        external
        view
        returns (uint256 startTime);

    function isSparkReady(
        uint256 endTime,
        uint256 totalIgnited,
        uint256 hardCap,
        uint256 softCap,
        bool isSparked
    ) external view returns (bool);

    function isIgniting(
        uint256 startTime,
        uint256 endTime,
        uint256 totalIgnited,
        uint256 hardCap
    ) external view returns (bool);

    function isRefunding(
        uint256 endTime,
        uint256 softCap,
        uint256 totalIgnited
    ) external view returns (bool);

    function getReward(
        uint256 ignited,
        uint256 rewardSupply,
        uint256 totalIgnited
    ) external pure returns (uint256 reward);
}


// File contracts/interfaces/ILiftoffSettings.sol

pragma solidity =0.6.6;

interface ILiftoffSettings {
    function setAllUints(
        uint256 _ethXLockBP,
        uint256 _tokenUserBP,
        uint256 _insurancePeriod,
        uint256 _baseFeeBP,
        uint256 _ethBuyBP,
        uint256 _projectDevBP,
        uint256 _mainFeeBP,
        uint256 _lidPoolBP
    ) external;

    function setAllAddresses(
        address _liftoffInsurance,
        address _liftoffRegistration,
        address _liftoffEngine,
        address _liftoffPartnerships,
        address _xEth,
        address _xLocker,
        address _uniswapRouter,
        address _lidTreasury,
        address _lidPoolManager
    ) external;

    function setEthXLockBP(uint256 _val) external;

    function getEthXLockBP() external view returns (uint256);

    function setTokenUserBP(uint256 _val) external;

    function getTokenUserBP() external view returns (uint256);

    function setLiftoffInsurance(address _val) external;

    function getLiftoffInsurance() external view returns (address);

    function setLiftoffRegistration(address _val) external;

    function getLiftoffRegistration() external view returns (address);

    function setLiftoffEngine(address _val) external;

    function getLiftoffEngine() external view returns (address);

    function setLiftoffPartnerships(address _val) external;

    function getLiftoffPartnerships() external view returns (address);

    function setXEth(address _val) external;

    function getXEth() external view returns (address);

    function setXLocker(address _val) external;

    function getXLocker() external view returns (address);

    function setUniswapRouter(address _val) external;

    function getUniswapRouter() external view returns (address);

    function setInsurancePeriod(uint256 _val) external;

    function getInsurancePeriod() external view returns (uint256);

    function setLidTreasury(address _val) external;

    function getLidTreasury() external view returns (address);

    function setLidPoolManager(address _val) external;

    function getLidPoolManager() external view returns (address);

    function setXethBP(
        uint256 _baseFeeBP,
        uint256 _ethBuyBP,
        uint256 _projectDevBP,
        uint256 _mainFeeBP,
        uint256 _lidPoolBP
    ) external;

    function getBaseFeeBP() external view returns (uint256);

    function getEthBuyBP() external view returns (uint256);

    function getProjectDevBP() external view returns (uint256);

    function getMainFeeBP() external view returns (uint256);

    function getLidPoolBP() external view returns (uint256);
}


// File contracts/interfaces/ILiftoffInsurance.sol

pragma solidity =0.6.6;

interface ILiftoffInsurance {
    function register(uint256 _tokenSaleId) external;

    function redeem(uint256 _tokenSaleId, uint256 _amount) external;

    function claim(uint256 _tokenSaleId) external;

    function createInsurance(uint256 _tokenSaleId) external;

    function canCreateInsurance(
        bool insuranceIsInitialized,
        bool tokenIsRegistered
    ) external pure returns (bool);

    function getTotalTokenClaimable(
        uint256 baseTokenLidPool,
        uint256 cycles,
        uint256 claimedTokenLidPool
    ) external pure returns (uint256);

    function getTotalXethClaimable(
        uint256 totalIgnited,
        uint256 redeemedXEth,
        uint256 claimedXEth,
        uint256 cycles
    ) external pure returns (uint256);

    function getRedeemValue(uint256 amount, uint256 tokensPerEthWad)
        external
        pure
        returns (uint256);

    function isInsuranceExhausted(
        uint256 currentTime,
        uint256 startTime,
        uint256 insurancePeriod,
        uint256 xEthValue,
        uint256 baseXEth,
        uint256 redeemedXEth,
        uint256 claimedXEth,
        bool isUnwound
    ) external pure returns (bool);

    function getTokenInsuranceUints(uint256 _tokenSaleId)
        external
        view
        returns (
            uint256 startTime,
            uint256 totalIgnited,
            uint256 tokensPerEthWad,
            uint256 baseXEth,
            uint256 baseTokenLidPool,
            uint256 redeemedXEth,
            uint256 claimedXEth,
            uint256 claimedTokenLidPool
        );

    function getTokenInsuranceOthers(uint256 _tokenSaleId)
        external
        view
        returns (
            address pair,
            address deployed,
            address projectDev,
            bool isUnwound,
            bool hasBaseFeeClaimed
        );
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File @lidprotocol/xlock-contracts/contracts/interfaces/[email protected]

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.6.6;
// Copyright (C) udev 2020
interface IXEth is IERC20 {
    function deposit() external payable;

    function xlockerMint(uint256 wad, address dst) external;

    function withdraw(uint256 wad) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
    event XlockerMint(uint256 wad, address dst);
}


// File @lidprotocol/xlock-contracts/contracts/interfaces/[email protected]

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.6.6;

// Copyright (C) udev 2020
interface IXLocker {
    function launchERC20(
        string calldata name,
        string calldata symbol,
        uint256 wadToken,
        uint256 wadXeth
    ) external returns (address token_, address pair_);

    function launchERC20TransferTax(
        string calldata name,
        string calldata symbol,
        uint256 wadToken,
        uint256 wadXeth,
        uint256 taxBips,
        address taxMan
    ) external returns (address token_, address pair_);

    function launchERC20Blacklist(
        string calldata name,
        string calldata symbol,
        uint256 wadToken,
        uint256 wadXeth,
        address blacklistManager
    ) external returns (address token_, address pair_);

    function setBlacklistUniswapBuys(
        address pair,
        address token,
        bool isBlacklisted
    ) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/libraries/[email protected]

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// File @uniswap/v2-periphery/contracts/libraries/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// File @openzeppelin/contracts-upgradeable/GSN/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/LiftoffEngine.sol

pragma solidity =0.6.6;
contract LiftoffEngine is
    ILiftoffEngine,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using BasisPoints for uint256;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    struct TokenSale {
        uint256 startTime;
        uint256 endTime;
        uint256 softCap;
        uint256 hardCap;
        uint256 totalIgnited;
        uint256 totalSupply;
        uint256 rewardSupply;
        address projectDev;
        address deployed;
        address pair;
        bool isSparked;
        string name;
        string symbol;
        mapping(address => Ignitor) ignitors;
    }

    struct Ignitor {
        uint256 ignited;
        bool hasClaimed;
        bool hasRefunded;
    }

    ILiftoffSettings public liftoffSettings;

    mapping(uint256 => TokenSale) public tokens;
    uint256 public totalTokenSales;
    mapping(uint256 => uint256) public fixedRates;

    event LaunchToken(
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 softCap,
        uint256 hardCap,
        uint256 totalSupply,
        string name,
        string symbol,
        address dev
    );
    event LaunchTokenWithFixedRate(
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 softCap,
        uint256 hardCap,
        uint256 fixedRate,
        string name,
        string symbol,
        address dev
    );
    event Spark(uint256 tokenId, address deployed, uint256 rewardSupply);
    event Ignite(uint256 tokenId, address igniter, uint256 toIgnite);
    event ClaimReward(uint256 tokenId, address igniter, uint256 reward);
    event ClaimRefund(uint256 tokenId, address igniter);
    event UpdateEndTime(uint256 tokenId, uint256 endTime);
    event UndoIgnite(
        uint256 _tokenSaleId,
        address igniter,
        uint256 wadUnIgnited
    );

    receive() external payable {}

    function initialize(ILiftoffSettings _liftoffSettings)
        external
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        liftoffSettings = _liftoffSettings;
    }

    function setLiftoffSettings(ILiftoffSettings _liftoffSettings)
        public
        onlyOwner
    {
        liftoffSettings = _liftoffSettings;
    }

    function updateEndTime(uint256 _delta, uint256 _tokenId)
        external
        onlyOwner
    {
        TokenSale storage tokenSale = tokens[_tokenId];
        uint256 endTime = tokenSale.startTime.add(_delta);
        tokenSale.endTime = endTime;
        emit UpdateEndTime(_tokenId, endTime);
    }

    function launchToken(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _totalSupply,
        string calldata _name,
        string calldata _symbol,
        address _projectDev
    ) external override whenNotPaused returns (uint256 tokenId) {
        require(
            msg.sender == liftoffSettings.getLiftoffRegistration(),
            "Sender must be LiftoffRegistration"
        );
        require(_endTime > _startTime, "Must end after start");
        require(_startTime > now, "Must start in the future");
        require(_hardCap >= _softCap, "Hardcap must be at least softCap");
        require(_softCap >= 10 ether, "Softcap must be at least 10 ether");
        require(
            _totalSupply >= 1000 * (10**18),
            "TotalSupply must be at least 1000 tokens"
        );
        require(
            _totalSupply < (10**12) * (10**18),
            "TotalSupply must be less than 1 trillion tokens"
        );

        tokenId = totalTokenSales;

        tokens[tokenId] = TokenSale({
            startTime: _startTime,
            endTime: _endTime,
            softCap: _softCap,
            hardCap: _hardCap,
            totalIgnited: 0,
            totalSupply: _totalSupply,
            rewardSupply: 0,
            projectDev: _projectDev,
            deployed: address(0),
            pair: address(0),
            name: _name,
            symbol: _symbol,
            isSparked: false
        });

        totalTokenSales++;

        emit LaunchToken(
            tokenId,
            _startTime,
            _endTime,
            _softCap,
            _hardCap,
            _totalSupply,
            _name,
            _symbol,
            _projectDev
        );
    }

    function launchTokenWithFixedRate(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _fixedRate,
        string calldata _name,
        string calldata _symbol,
        address _projectDev
    ) external override whenNotPaused returns (uint256 tokenId) {
        require(
            msg.sender == liftoffSettings.getLiftoffRegistration(),
            "Sender must be LiftoffRegistration"
        );
        require(_endTime > _startTime, "Must end after start");
        require(_startTime > now, "Must start in the future");
        require(_hardCap >= _softCap, "Hardcap must be at least softCap");
        require(_softCap >= 10 ether, "Softcap must be at least 10 ether");
        require(_fixedRate >= (10**9), "FixedRate is less than minimum");
        require(_fixedRate <= (10**27), "FixedRate is more than maximum");

        tokenId = totalTokenSales;

        tokens[tokenId] = TokenSale({
            startTime: _startTime,
            endTime: _endTime,
            softCap: _softCap,
            hardCap: _hardCap,
            totalIgnited: 0,
            totalSupply: 0,
            rewardSupply: 0,
            projectDev: _projectDev,
            deployed: address(0),
            pair: address(0),
            name: _name,
            symbol: _symbol,
            isSparked: false
        });

        fixedRates[tokenId] = _fixedRate;

        totalTokenSales++;

        emit LaunchTokenWithFixedRate(
            tokenId,
            _startTime,
            _endTime,
            _softCap,
            _hardCap,
            _fixedRate,
            _name,
            _symbol,
            _projectDev
        );
    }

    function igniteEth(uint256 _tokenSaleId)
        external
        payable
        override
        whenNotPaused
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        require(
            isIgniting(
                tokenSale.startTime,
                tokenSale.endTime,
                tokenSale.totalIgnited,
                tokenSale.hardCap
            ),
            "Not igniting."
        );
        uint256 toIgnite =
            getAmountToIgnite(
                msg.value,
                tokenSale.hardCap,
                tokenSale.totalIgnited
            );

        IXEth(liftoffSettings.getXEth()).deposit{value: toIgnite}();
        _addIgnite(tokenSale, msg.sender, toIgnite);

        msg.sender.transfer(msg.value.sub(toIgnite));

        emit Ignite(_tokenSaleId, msg.sender, toIgnite);
    }

    function ignite(
        uint256 _tokenSaleId,
        address _for,
        uint256 _amountXEth
    ) external override whenNotPaused {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        require(
            isIgniting(
                tokenSale.startTime,
                tokenSale.endTime,
                tokenSale.totalIgnited,
                tokenSale.hardCap
            ),
            "Not igniting."
        );
        uint256 toIgnite =
            getAmountToIgnite(
                _amountXEth,
                tokenSale.hardCap,
                tokenSale.totalIgnited
            );

        require(
            IXEth(liftoffSettings.getXEth()).transferFrom(
                msg.sender,
                address(this),
                toIgnite
            ),
            "Transfer Failed"
        );
        _addIgnite(tokenSale, _for, toIgnite);

        emit Ignite(_tokenSaleId, _for, toIgnite);
    }

    function undoIgniteEth(uint256 _tokenSaleId)
        external
        override
        whenNotPaused
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        require(
            isIgniting(
                tokenSale.startTime,
                tokenSale.endTime,
                tokenSale.totalIgnited,
                tokenSale.hardCap
            ),
            "Not igniting."
        );
        uint256 wadToUndo = tokenSale.ignitors[msg.sender].ignited;
        tokenSale.ignitors[msg.sender].ignited = 0;
        delete tokenSale.ignitors[msg.sender];
        tokenSale.totalIgnited = tokenSale.totalIgnited.sub(wadToUndo);

        IXEth(liftoffSettings.getXEth()).withdraw(wadToUndo);
        require(address(this).balance >= wadToUndo, "Less eth than expected.");

        msg.sender.transfer(wadToUndo);

        emit UndoIgnite(_tokenSaleId, msg.sender, wadToUndo);
    }

    function undoIgnite(uint256 _tokenSaleId) external override whenNotPaused {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        require(
            isIgniting(
                tokenSale.startTime,
                tokenSale.endTime,
                tokenSale.totalIgnited,
                tokenSale.hardCap
            ),
            "Not igniting."
        );
        uint256 wadToUndo = tokenSale.ignitors[msg.sender].ignited;
        tokenSale.ignitors[msg.sender].ignited = 0;
        delete tokenSale.ignitors[msg.sender];
        tokenSale.totalIgnited = tokenSale.totalIgnited.sub(wadToUndo);
        require(
            IXEth(liftoffSettings.getXEth()).transfer(msg.sender, wadToUndo),
            "Transfer failed"
        );
        emit UndoIgnite(_tokenSaleId, msg.sender, wadToUndo);
    }

    function claimReward(uint256 _tokenSaleId, address _for)
        external
        override
        whenNotPaused
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        Ignitor storage ignitor = tokenSale.ignitors[_for];

        require(tokenSale.isSparked, "Token must have been sparked.");
        require(!ignitor.hasClaimed, "Ignitor has already claimed");

        uint256 reward =
            getReward(
                ignitor.ignited,
                tokenSale.rewardSupply,
                tokenSale.totalIgnited
            );
        require(reward > 0, "Must have some rewards to claim.");

        ignitor.hasClaimed = true;
        require(
            IERC20(tokenSale.deployed).transfer(_for, reward),
            "Transfer failed"
        );

        emit ClaimReward(_tokenSaleId, _for, reward);
    }

    function spark(uint256 _tokenSaleId) external override whenNotPaused {
        TokenSale storage tokenSale = tokens[_tokenSaleId];

        require(
            isSparkReady(
                tokenSale.endTime,
                tokenSale.totalIgnited,
                tokenSale.hardCap,
                tokenSale.softCap,
                tokenSale.isSparked
            ),
            "Not spark ready"
        );
        require(
            tokenSale.totalSupply != 0 || fixedRates[_tokenSaleId] > 0,
            "Undefined fixedRate for no supply token"
        );

        tokenSale.isSparked = true;
        if (tokenSale.totalSupply == 0) {
            tokenSale.totalSupply =
                uint256(10000).mul(fixedRates[_tokenSaleId]).mul(
                    tokenSale.totalIgnited
                ) /
                liftoffSettings.getTokenUserBP() /
                (10**18);
        }

        uint256 xEthBuy = _deployViaXLock(tokenSale);
        _allocateTokensPostDeploy(tokenSale);
        _insuranceRegistration(tokenSale, _tokenSaleId, xEthBuy);

        emit Spark(_tokenSaleId, tokenSale.deployed, tokenSale.rewardSupply);
    }

    function claimRefundEth(uint256 _tokenSaleId, address _for)
        external
        override
        whenNotPaused
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        Ignitor storage ignitor = tokenSale.ignitors[_for];

        require(
            isRefunding(
                tokenSale.endTime,
                tokenSale.softCap,
                tokenSale.totalIgnited
            ),
            "Not refunding"
        );

        require(!ignitor.hasRefunded, "Ignitor has already refunded");
        ignitor.hasRefunded = true;

        IXEth(liftoffSettings.getXEth()).withdraw(ignitor.ignited);
        require(
            address(this).balance >= ignitor.ignited,
            "Less eth than expected."
        );

        payable(_for).transfer(ignitor.ignited);

        emit ClaimRefund(_tokenSaleId, _for);
    }

    function claimRefund(uint256 _tokenSaleId, address _for)
        external
        override
        whenNotPaused
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        Ignitor storage ignitor = tokenSale.ignitors[_for];

        require(
            isRefunding(
                tokenSale.endTime,
                tokenSale.softCap,
                tokenSale.totalIgnited
            ),
            "Not refunding"
        );

        require(!ignitor.hasRefunded, "Ignitor has already refunded");
        ignitor.hasRefunded = true;

        require(
            IXEth(liftoffSettings.getXEth()).transfer(_for, ignitor.ignited),
            "Transfer failed"
        );

        emit ClaimRefund(_tokenSaleId, _for);
    }

    function getTokenSale(uint256 _tokenSaleId)
        external
        view
        override
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 softCap,
            uint256 hardCap,
            uint256 totalIgnited,
            uint256 totalSupply,
            uint256 rewardSupply,
            address projectDev,
            address deployed,
            bool isSparked
        )
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];

        startTime = tokenSale.startTime;
        endTime = tokenSale.endTime;
        softCap = tokenSale.softCap;
        hardCap = tokenSale.hardCap;
        totalIgnited = tokenSale.totalIgnited;
        totalSupply = tokenSale.totalSupply;
        rewardSupply = tokenSale.rewardSupply;
        projectDev = tokenSale.projectDev;
        deployed = tokenSale.deployed;
        isSparked = tokenSale.isSparked;
    }

    function getTokenSaleForInsurance(uint256 _tokenSaleId)
        external
        view
        override
        returns (
            uint256 totalIgnited,
            uint256 rewardSupply,
            address projectDev,
            address pair,
            address deployed
        )
    {
        TokenSale storage tokenSale = tokens[_tokenSaleId];
        totalIgnited = tokenSale.totalIgnited;
        rewardSupply = tokenSale.rewardSupply;
        projectDev = tokenSale.projectDev;
        pair = tokenSale.pair;
        deployed = tokenSale.deployed;
    }

    function getTokenSaleProjectDev(uint256 _tokenSaleId)
        external
        view
        override
        returns (address projectDev)
    {
        projectDev = tokens[_tokenSaleId].projectDev;
    }

    function getTokenSaleStartTime(uint256 _tokenSaleId)
        external
        view
        override
        returns (uint256 startTime)
    {
        startTime = tokens[_tokenSaleId].startTime;
    }

    function isSparkReady(
        uint256 endTime,
        uint256 totalIgnited,
        uint256 hardCap,
        uint256 softCap,
        bool isSparked
    ) public view override returns (bool) {
        if (
            (now <= endTime && totalIgnited < hardCap) ||
            totalIgnited < softCap ||
            isSparked
        ) {
            return false;
        } else {
            return true;
        }
    }

    function isIgniting(
        uint256 startTime,
        uint256 endTime,
        uint256 totalIgnited,
        uint256 hardCap
    ) public view override returns (bool) {
        if (now < startTime || now > endTime || totalIgnited >= hardCap) {
            return false;
        } else {
            return true;
        }
    }

    function isRefunding(
        uint256 endTime,
        uint256 softCap,
        uint256 totalIgnited
    ) public view override returns (bool) {
        if (totalIgnited >= softCap || now <= endTime) {
            return false;
        } else {
            return true;
        }
    }

    function getReward(
        uint256 ignited,
        uint256 rewardSupply,
        uint256 totalIgnited
    ) public pure override returns (uint256 reward) {
        return ignited.mul(rewardSupply).div(totalIgnited);
    }

    function getAmountToIgnite(
        uint256 amountXEth,
        uint256 hardCap,
        uint256 totalIgnited
    ) public pure returns (uint256 toIgnite) {
        uint256 maxIgnite = hardCap.sub(totalIgnited);

        if (maxIgnite < amountXEth) {
            toIgnite = maxIgnite;
        } else {
            toIgnite = amountXEth;
        }
    }

    function _deployViaXLock(TokenSale storage tokenSale)
        internal
        returns (uint256 xEthBuy)
    {
        uint256 xEthLocked =
            tokenSale.totalIgnited.mulBP(liftoffSettings.getEthXLockBP());
        xEthBuy = tokenSale.totalIgnited.mulBP(liftoffSettings.getEthBuyBP());

        (address deployed, address pair) =
            IXLocker(liftoffSettings.getXLocker()).launchERC20Blacklist(
                tokenSale.name,
                tokenSale.symbol,
                tokenSale.totalSupply,
                xEthLocked,
                liftoffSettings.getLiftoffInsurance()
            );

        _swapExactXEthForTokens(
            xEthBuy,
            IERC20(liftoffSettings.getXEth()),
            IUniswapV2Pair(pair)
        );

        tokenSale.pair = pair;
        tokenSale.deployed = deployed;

        return xEthBuy;
    }

    function _allocateTokensPostDeploy(TokenSale storage tokenSale) internal {
        IERC20 deployed = IERC20(tokenSale.deployed);
        uint256 balance = deployed.balanceOf(address(this));
        tokenSale.rewardSupply = balance.mulBP(
            liftoffSettings.getTokenUserBP()
        );
    }

    function _insuranceRegistration(
        TokenSale storage tokenSale,
        uint256 _tokenSaleId,
        uint256 _xEthBuy
    ) internal {
        IERC20 deployed = IERC20(tokenSale.deployed);
        uint256 toInsurance =
            deployed.balanceOf(address(this)).sub(tokenSale.rewardSupply);
        address liftoffInsurance = liftoffSettings.getLiftoffInsurance();
        deployed.transfer(liftoffInsurance, toInsurance);
        IXEth(liftoffSettings.getXEth()).transfer(
            liftoffInsurance,
            tokenSale.totalIgnited.sub(_xEthBuy)
        );

        ILiftoffInsurance(liftoffInsurance).register(_tokenSaleId);
    }

    function _addIgnite(
        TokenSale storage tokenSale,
        address _for,
        uint256 toIgnite
    ) internal {
        Ignitor storage ignitor = tokenSale.ignitors[_for];
        ignitor.ignited = ignitor.ignited.add(toIgnite);
        tokenSale.totalIgnited = tokenSale.totalIgnited.add(toIgnite);
    }

    //WARNING: Not tested with transfer tax tokens. Will probably fail with such.
    function _swapExactXEthForTokens(
        uint256 amountIn,
        IERC20 xEth,
        IUniswapV2Pair pair
    ) internal {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        bool token0IsXEth = pair.token0() == address(xEth);
        (uint256 reserveIn, uint256 reserveOut) =
            token0IsXEth ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountOut =
            UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        require(xEth.transfer(address(pair), amountIn), "Transfer failed");
        (uint256 amount0Out, uint256 amount1Out) =
            token0IsXEth ? (uint256(0), amountOut) : (amountOut, uint256(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
}


// File contracts/interfaces/ILiftoffPartnerships.sol

pragma solidity =0.6.6;

interface ILiftoffPartnerships {
    function setPartner(
        uint256 _ID,
        address _controller,
        string calldata _IPFSConfigHash
    ) external;

    function requestPartnership(
        uint256 _partnerId,
        uint256 _tokenSaleId,
        uint256 _feeBP
    ) external;

    function acceptPartnership(uint256 _tokenSaleId, uint8 _requestId) external;

    function cancelPartnership(uint256 _tokenSaleId, uint8 _requestId) external;

    function addFees(uint256 _tokenSaleId, uint256 _wad) external;

    function getTotalBP(uint256 _tokenSaleId)
        external
        view
        returns (uint256 totalBP);

    function getTokenSalePartnerships(uint256 _tokenSaleId)
        external
        view
        returns (uint8 totalPartnerships, uint256 totalBPForPartnerships);

    function getPartnership(uint256 _tokenSaleId, uint8 _partnershipId)
        external
        view
        returns (
            uint256 partnerId,
            uint256 tokenSaleId,
            uint256 feeBP,
            bool isApproved
        );
}


// File contracts/LiftoffInsurance.sol

pragma solidity =0.6.6;
contract LiftoffInsurance is
    ILiftoffInsurance,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using BasisPoints for uint256;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    struct TokenInsurance {
        uint256 startTime;
        uint256 totalIgnited;
        uint256 tokensPerEthWad;
        uint256 baseXEth;
        uint256 baseTokenLidPool;
        uint256 redeemedXEth;
        uint256 claimedXEth;
        uint256 claimedTokenLidPool;
        address pair;
        address deployed;
        address projectDev;
        bool isUnwound;
        bool hasBaseFeeClaimed;
    }

    ILiftoffSettings public liftoffSettings;

    mapping(uint256 => TokenInsurance) public tokenInsurances;
    mapping(uint256 => bool) public tokenIsRegistered;
    mapping(uint256 => bool) public insuranceIsInitialized;

    event Register(uint256 tokenId);
    event CreateInsurance(
        uint256 tokenId,
        uint256 startTime,
        uint256 tokensPerEthWad,
        uint256 baseXEth,
        uint256 baseTokenLidPool,
        uint256 totalIgnited,
        address deployed,
        address dev
    );
    event ClaimBaseFee(uint256 tokenId, uint256 baseFee);
    event Claim(uint256 tokenId, uint256 xEthClaimed, uint256 tokenClaimed);
    event Redeem(uint256 tokenId, uint256 redeemEth);

    function initialize(ILiftoffSettings _liftoffSettings)
        external
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        liftoffSettings = _liftoffSettings;
    }

    function setLiftoffSettings(ILiftoffSettings _liftoffSettings)
        public
        onlyOwner
    {
        liftoffSettings = _liftoffSettings;
    }

    function emptyToken(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function register(uint256 _tokenSaleId) external override {
        address liftoffEngine = liftoffSettings.getLiftoffEngine();
        require(msg.sender == liftoffEngine, "Sender must be Liftoff Engine");
        require(!tokenIsRegistered[_tokenSaleId], "Token already registered");
        tokenIsRegistered[_tokenSaleId] = true;

        emit Register(_tokenSaleId);
    }

    function redeem(uint256 _tokenSaleId, uint256 _amount) external override {
        TokenInsurance storage tokenInsurance = tokenInsurances[_tokenSaleId];
        require(
            insuranceIsInitialized[_tokenSaleId],
            "Insurance not initialized"
        );

        IERC20 token = IERC20(tokenInsurance.deployed);
        IERC20 xeth = IXEth(liftoffSettings.getXEth());

        uint256 xEthValue =
            _pullTokensForRedeem(tokenInsurance, token, _amount);

        require(
            !isInsuranceExhausted(
                now,
                tokenInsurance.startTime,
                liftoffSettings.getInsurancePeriod(),
                xEthValue,
                tokenInsurance.baseXEth,
                tokenInsurance.redeemedXEth.add(xEthValue),
                tokenInsurance.claimedXEth,
                tokenInsurance.isUnwound
            ),
            "Redeem request exceeds available insurance."
        );

        if (
            //Still in the first period (1 week)
            now <=
            tokenInsurance.startTime.add(
                liftoffSettings.getInsurancePeriod()
            ) &&
            //Already reached the baseXEth
            tokenInsurance.baseXEth < tokenInsurance.redeemedXEth.add(xEthValue)
        ) {
            //Trigger unwind
            tokenInsurance.isUnwound = true;
            IXLocker(liftoffSettings.getXLocker()).setBlacklistUniswapBuys(
                tokenInsurance.pair,
                address(token),
                true
            );
        }

        if (tokenInsurance.isUnwound) {
            //All tokens are sold on market during unwind, to maximize insurance returns.
            _swapExactTokensForXEth(
                token.balanceOf(address(this)),
                token,
                IUniswapV2Pair(tokenInsurance.pair)
            );
        }
        tokenInsurance.redeemedXEth = tokenInsurance.redeemedXEth.add(
            xEthValue
        );
        require(xeth.transfer(msg.sender, xEthValue), "Transfer failed.");

        emit Redeem(_tokenSaleId, xEthValue);
    }

    function claim(uint256 _tokenSaleId) external override {
        TokenInsurance storage tokenInsurance = tokenInsurances[_tokenSaleId];
        require(
            insuranceIsInitialized[_tokenSaleId],
            "Insurance not initialized"
        );

        uint256 cycles =
            now.sub(tokenInsurance.startTime).div(
                liftoffSettings.getInsurancePeriod()
            );

        IXEth xeth = IXEth(liftoffSettings.getXEth());

        bool didBaseFeeClaim =
            _baseFeeClaim(tokenInsurance, xeth, _tokenSaleId);
        if (didBaseFeeClaim) {
            return; //If claiming base fee, ONLY claim base fee.
        }
        require(!tokenInsurance.isUnwound, "Token insurance is unwound.");

        //For first 7 days, only claim base fee
        require(cycles > 0, "Cannot claim until after first cycle ends.");

        uint256 totalXethClaimed =
            _xEthClaimDistribution(tokenInsurance, _tokenSaleId, cycles, xeth);

        uint256 totalTokenClaimed =
            _tokenClaimDistribution(tokenInsurance, cycles);

        emit Claim(_tokenSaleId, totalXethClaimed, totalTokenClaimed);
    }

    function createInsurance(uint256 _tokenSaleId) external override {
        require(
            canCreateInsurance(
                insuranceIsInitialized[_tokenSaleId],
                tokenIsRegistered[_tokenSaleId]
            ),
            "Cannot create insurance"
        );

        insuranceIsInitialized[_tokenSaleId] = true;

        (
            uint256 totalIgnited,
            uint256 rewardSupply,
            address projectDev,
            address pair,
            address deployed
        ) =
            ILiftoffEngine(liftoffSettings.getLiftoffEngine())
                .getTokenSaleForInsurance(_tokenSaleId);

        require(
            rewardSupply.mul(1 ether).div(1000) > totalIgnited,
            "Must have at least 3 digits"
        );

        tokenInsurances[_tokenSaleId] = TokenInsurance({
            startTime: now,
            totalIgnited: totalIgnited,
            tokensPerEthWad: rewardSupply
                .mul(1 ether)
                .div(totalIgnited.subBP(liftoffSettings.getBaseFeeBP()))
                .add(1), //division error safety margin,
            baseXEth: totalIgnited.sub(
                totalIgnited.mulBP(liftoffSettings.getEthBuyBP())
            ),
            baseTokenLidPool: IERC20(deployed).balanceOf(address(this)),
            redeemedXEth: 0,
            claimedXEth: 0,
            claimedTokenLidPool: 0,
            pair: pair,
            deployed: deployed,
            projectDev: projectDev,
            isUnwound: false,
            hasBaseFeeClaimed: false
        });

        emit CreateInsurance(
            _tokenSaleId,
            tokenInsurances[_tokenSaleId].startTime,
            tokenInsurances[_tokenSaleId].tokensPerEthWad,
            tokenInsurances[_tokenSaleId].baseXEth,
            tokenInsurances[_tokenSaleId].baseTokenLidPool,
            totalIgnited,
            deployed,
            projectDev
        );
    }

    function getTokenInsuranceUints(uint256 _tokenSaleId)
        external
        view
        override
        returns (
            uint256 startTime,
            uint256 totalIgnited,
            uint256 tokensPerEthWad,
            uint256 baseXEth,
            uint256 baseTokenLidPool,
            uint256 redeemedXEth,
            uint256 claimedXEth,
            uint256 claimedTokenLidPool
        )
    {
        TokenInsurance storage t = tokenInsurances[_tokenSaleId];

        startTime = t.startTime;
        totalIgnited = t.totalIgnited;
        tokensPerEthWad = t.tokensPerEthWad;
        baseXEth = t.baseXEth;
        baseTokenLidPool = t.baseTokenLidPool;
        redeemedXEth = t.redeemedXEth;
        claimedXEth = t.claimedXEth;
        claimedTokenLidPool = t.claimedTokenLidPool;
    }

    function getTokenInsuranceOthers(uint256 _tokenSaleId)
        external
        view
        override
        returns (
            address pair,
            address deployed,
            address projectDev,
            bool isUnwound,
            bool hasBaseFeeClaimed
        )
    {
        TokenInsurance storage t = tokenInsurances[_tokenSaleId];

        pair = t.pair;
        deployed = t.deployed;
        projectDev = t.projectDev;
        isUnwound = t.isUnwound;
        hasBaseFeeClaimed = t.hasBaseFeeClaimed;
    }

    function isInsuranceExhausted(
        uint256 currentTime,
        uint256 startTime,
        uint256 insurancePeriod,
        uint256 xEthValue,
        uint256 baseXEth,
        uint256 redeemedXEth,
        uint256 claimedXEth,
        bool isUnwound
    ) public pure override returns (bool) {
        if (isUnwound) {
            //Never exhausted when unwound
            return false;
        }
        if (
            //After the first period (1 week)
            currentTime > startTime.add(insurancePeriod) &&
            //Already reached the baseXEth
            baseXEth < redeemedXEth.add(claimedXEth).add(xEthValue)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function canCreateInsurance(
        bool _insuranceIsInitialized,
        bool _tokenIsRegistered
    ) public pure override returns (bool) {
        if (!_insuranceIsInitialized && _tokenIsRegistered) {
            return true;
        }
        return false;
    }

    function getRedeemValue(uint256 amount, uint256 tokensPerEthWad)
        public
        pure
        override
        returns (uint256)
    {
        return amount.mul(1 ether).div(tokensPerEthWad);
    }

    function getTotalTokenClaimable(
        uint256 baseTokenLidPool,
        uint256 cycles,
        uint256 claimedTokenLidPool
    ) public pure override returns (uint256) {
        uint256 totalMaxTokenClaim = baseTokenLidPool.mul(cycles).div(10);
        if (totalMaxTokenClaim > baseTokenLidPool)
            totalMaxTokenClaim = baseTokenLidPool;
        return totalMaxTokenClaim.sub(claimedTokenLidPool);
    }

    function getTotalXethClaimable(
        uint256 totalIgnited,
        uint256 redeemedXEth,
        uint256 claimedXEth,
        uint256 cycles
    ) public pure override returns (uint256) {
        if (cycles == 0) return 0;
        uint256 totalFinalClaim =
            totalIgnited.sub(redeemedXEth).sub(claimedXEth);
        uint256 totalMaxClaim = totalFinalClaim.mul(cycles).div(10); //10 periods hardcoded
        if (totalMaxClaim > totalFinalClaim) totalMaxClaim = totalFinalClaim;
        return totalMaxClaim;
    }

    function _pullTokensForRedeem(
        TokenInsurance storage tokenInsurance,
        IERC20 token,
        uint256 _amount
    ) internal returns (uint256 xEthValue) {
        uint256 initialBalance = token.balanceOf(address(this));
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        //In case token has a transfer tax or burn.
        uint256 amountReceived =
            token.balanceOf(address(this)).sub(initialBalance);

        xEthValue = getRedeemValue(
            amountReceived,
            tokenInsurance.tokensPerEthWad
        );
        require(
            xEthValue >= 0.001 ether,
            "Amount must have value of at least 0.001 xETH"
        );
        return xEthValue;
    }

    function _xEthClaimDistribution(
        TokenInsurance storage tokenInsurance,
        uint256 tokenId,
        uint256 cycles,
        IERC20 xeth
    ) internal returns (uint256 totalClaimed) {
        uint256 totalClaimable =
            getTotalXethClaimable(
                tokenInsurance.totalIgnited,
                tokenInsurance.redeemedXEth,
                tokenInsurance.claimedXEth,
                cycles
            );

        tokenInsurance.claimedXEth = tokenInsurance.claimedXEth.add(
            totalClaimable
        );

        uint256 projectDevBP = liftoffSettings.getProjectDevBP();

        //For payments to partners
        address liftoffPartnerships = liftoffSettings.getLiftoffPartnerships();
        (, uint256 totalBPForParnterships) =
            ILiftoffPartnerships(liftoffPartnerships).getTokenSalePartnerships(
                tokenId
            );

        if (totalBPForParnterships > 0) {
            projectDevBP = projectDevBP.sub(totalBPForParnterships);
            uint256 wad = totalClaimable.mulBP(totalBPForParnterships);
            require(
                xeth.transfer(liftoffPartnerships, wad),
                "Transfer xEth projectDev failed"
            );
            ILiftoffPartnerships(liftoffPartnerships).addFees(tokenId, wad);
        }

        //NOTE: The totals are not actually held by insurance.
        //The ethBuyBP was used by liftoffEngine, and baseFeeBP is seperate above.
        //So the total BP transferred here will always be 10000-ethBuyBP-baseFeeBP
        require(
            xeth.transfer(
                tokenInsurance.projectDev,
                totalClaimable.mulBP(projectDevBP)
            ),
            "Transfer xEth projectDev failed"
        );
        require(
            xeth.transfer(
                liftoffSettings.getLidTreasury(),
                totalClaimable.mulBP(liftoffSettings.getMainFeeBP())
            ),
            "Transfer xEth lidTreasury failed"
        );
        require(
            xeth.transfer(
                liftoffSettings.getLidPoolManager(),
                totalClaimable.mulBP(liftoffSettings.getLidPoolBP())
            ),
            "Transfer xEth lidPoolManager failed"
        );
        return totalClaimable;
    }

    function _tokenClaimDistribution(
        TokenInsurance storage tokenInsurance,
        uint256 cycles
    ) internal returns (uint256 totalClaimed) {
        uint256 totalTokenClaimable =
            getTotalTokenClaimable(
                tokenInsurance.baseTokenLidPool,
                cycles,
                tokenInsurance.claimedTokenLidPool
            );
        tokenInsurance.claimedTokenLidPool = tokenInsurance
            .claimedTokenLidPool
            .add(totalTokenClaimable);

        require(
            IERC20(tokenInsurance.deployed).transfer(
                liftoffSettings.getLidPoolManager(),
                totalTokenClaimable
            ),
            "Transfer token to lidPoolManager failed"
        );
        return totalTokenClaimable;
    }

    function _baseFeeClaim(
        TokenInsurance storage tokenInsurance,
        IERC20 xeth,
        uint256 _tokenSaleId
    ) internal returns (bool didClaim) {
        if (!tokenInsurance.hasBaseFeeClaimed) {
            uint256 baseFee =
                tokenInsurance.totalIgnited.mulBP(
                    liftoffSettings.getBaseFeeBP() - 30 //30 BP is taken by uniswap during unwind
                );
            require(
                xeth.transfer(liftoffSettings.getLidTreasury(), baseFee),
                "Transfer failed"
            );
            tokenInsurance.hasBaseFeeClaimed = true;

            emit ClaimBaseFee(_tokenSaleId, baseFee);

            return true;
        } else {
            return false;
        }
    }

    function _swapExactTokensForXEth(
        uint256 amountIn,
        IERC20 token,
        IUniswapV2Pair pair
    ) internal {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        bool token0IsToken = pair.token0() == address(token);
        (uint256 reserveIn, uint256 reserveOut) =
            token0IsToken ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountOut =
            UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        require(token.transfer(address(pair), amountIn), "Transfer failed");
        (uint256 amount0Out, uint256 amount1Out) =
            token0IsToken ? (uint256(0), amountOut) : (amountOut, uint256(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
}


// File contracts/LiftoffPartnerships.sol

pragma solidity =0.6.6;
contract LiftoffPartnerships is ILiftoffPartnerships, OwnableUpgradeable {
    using BasisPoints for uint256;
    using SafeMathUpgradeable for uint256;

    uint256 totalPartnerControllers;
    mapping(uint256 => address) public partnerController;
    mapping(uint256 => string) public partnerIPFSConfigHash;
    mapping(uint256 => TokenSalePartnerships) public tokenSalePartnerships;

    struct TokenSalePartnerships {
        uint8 totalPartnerships;
        uint256 totalBPForPartners;
        mapping(uint8 => Partnership) partnershipRequests;
    }

    struct Partnership {
        uint256 partnerId;
        uint256 tokenSaleId;
        uint256 feeBP;
        bool isApproved;
    }

    ILiftoffSettings public liftoffSettings;

    event SetPartner(uint256 ID, address controller, string IPFSConfigHash);
    event RequestPartnership(
        uint256 partnerId,
        uint256 tokenSaleId,
        uint256 feeBP
    );
    event AcceptPartnership(uint256 tokenSaleId, uint8 requestId);
    event CancelPartnership(uint256 tokenSaleId, uint8 requestId);
    event AddFees(uint256 tokenSaleId, uint256 wad);
    event ClaimFees(uint256 tokenSaleId, uint256 feeWad, uint8 requestId);
    event UpdatePartnershipFee(
        uint8 partnerId,
        uint256 tokenSaleId,
        uint256 feeBP
    );

    modifier onlyBeforeSaleStart(uint256 _tokenSaleId) {
        require(
            ILiftoffEngine(liftoffSettings.getLiftoffEngine())
                .getTokenSaleStartTime(_tokenSaleId) >= now,
            "Sale already started."
        );
        _;
    }

    modifier isLiftoffInsurance() {
        require(
            liftoffSettings.getLiftoffInsurance() == _msgSender(),
            "Sender must be LiftoffInsurance"
        );
        _;
    }

    modifier isOwnerOrTokenSaleDev(uint256 _tokenSaleId) {
        address projectDev =
            ILiftoffEngine(liftoffSettings.getLiftoffEngine())
                .getTokenSaleProjectDev(_tokenSaleId);
        require(
            _msgSender() == owner() || _msgSender() == projectDev,
            "Sender must be Owner or TokenSaleDev"
        );
        _;
    }

    modifier isOwnerOrPartnerController(
        uint256 _tokenSaleId,
        uint8 _requestId
    ) {
        address partner =
            partnerController[
                tokenSalePartnerships[_tokenSaleId].partnershipRequests[
                    _requestId
                ]
                    .partnerId
            ];
        require(
            _msgSender() == owner() || _msgSender() == partner,
            "Sender must be Owner or PartnerController"
        );
        _;
    }

    function initialize(ILiftoffSettings _liftoffSettings)
        external
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        liftoffSettings = _liftoffSettings;
    }

    function setLiftoffSettings(ILiftoffSettings _liftoffSettings)
        public
        onlyOwner
    {
        liftoffSettings = _liftoffSettings;
    }

    function updatePartnershipFee(
        uint8 _partnerId,
        uint256 _tokenSaleId,
        uint256 _feeBP
    ) external onlyOwner {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        Partnership storage partnership =
            partnerships.partnershipRequests[_partnerId];
        require(partnership.isApproved, "Partnership not yet approved");
        uint256 originalFeeBP = partnership.feeBP;
        partnerships.totalBPForPartners = partnerships
            .totalBPForPartners
            .add(_feeBP)
            .sub(originalFeeBP);
        partnership.feeBP = _feeBP;
        emit UpdatePartnershipFee(_partnerId, _tokenSaleId, _feeBP);
    }

    function setPartner(
        uint256 _ID,
        address _controller,
        string calldata _IPFSConfigHash
    ) external override onlyOwner {
        require(_ID <= totalPartnerControllers, "Must increment partnerId.");
        if (_ID == totalPartnerControllers) totalPartnerControllers++;
        if (_controller == address(0x0)) {
            delete partnerController[_ID];
            delete partnerIPFSConfigHash[_ID];
        } else {
            partnerController[_ID] = _controller;
            partnerIPFSConfigHash[_ID] = _IPFSConfigHash;
        }
        emit SetPartner(_ID, _controller, _IPFSConfigHash);
    }

    function requestPartnership(
        uint256 _partnerId,
        uint256 _tokenSaleId,
        uint256 _feeBP
    )
        external
        override
        isOwnerOrTokenSaleDev(_tokenSaleId)
        onlyBeforeSaleStart(_tokenSaleId)
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        partnerships.partnershipRequests[
            partnerships.totalPartnerships
        ] = Partnership({
            partnerId: _partnerId,
            tokenSaleId: _tokenSaleId,
            feeBP: _feeBP,
            isApproved: false
        });
        require(
            partnerships.totalPartnerships < 15,
            "Cannot have more than 16 total partnerships"
        );
        partnerships.totalPartnerships++;
        emit RequestPartnership(_partnerId, _tokenSaleId, _feeBP);
    }

    function acceptPartnership(uint256 _tokenSaleId, uint8 _requestId)
        external
        override
        isOwnerOrPartnerController(_tokenSaleId, _requestId)
        onlyBeforeSaleStart(_tokenSaleId)
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        Partnership storage partnership =
            partnerships.partnershipRequests[_requestId];
        partnership.isApproved = true;
        partnerships.totalBPForPartners = partnerships.totalBPForPartners.add(
            partnership.feeBP
        );
        require(
            partnerships.totalBPForPartners <= liftoffSettings.getProjectDevBP()
        );
        emit AcceptPartnership(_tokenSaleId, _requestId);
    }

    function cancelPartnership(uint256 _tokenSaleId, uint8 _requestId)
        external
        override
        isOwnerOrPartnerController(_tokenSaleId, _requestId)
        onlyBeforeSaleStart(_tokenSaleId)
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        Partnership storage partnership =
            partnerships.partnershipRequests[_requestId];
        partnership.isApproved = false;
        partnerships.totalBPForPartners = partnerships.totalBPForPartners.sub(
            partnership.feeBP
        );
        emit CancelPartnership(_tokenSaleId, _requestId);
    }

    function addFees(uint256 _tokenSaleId, uint256 _wad)
        external
        override
        isLiftoffInsurance
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        for (uint8 i; i < partnerships.totalPartnerships; i++) {
            Partnership storage request = partnerships.partnershipRequests[i];
            if (request.isApproved) {
                uint256 fee =
                    request.feeBP.mul(_wad).div(
                        partnerships.totalBPForPartners
                    );
                IXEth(liftoffSettings.getXEth()).transfer(
                    partnerController[request.partnerId],
                    fee
                );
                emit ClaimFees(_tokenSaleId, fee, i);
            }
        }
        emit AddFees(_tokenSaleId, _wad);
    }

    function getTotalBP(uint256 _tokenSaleId)
        external
        view
        override
        returns (uint256 totalBP)
    {
        totalBP = tokenSalePartnerships[_tokenSaleId].totalBPForPartners;
    }

    function getTokenSalePartnerships(uint256 _tokenSaleId)
        external
        view
        override
        returns (uint8 totalPartnerships, uint256 totalBPForPartnerships)
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        totalPartnerships = partnerships.totalPartnerships;
        totalBPForPartnerships = partnerships.totalBPForPartners;
    }

    function getPartnership(uint256 _tokenSaleId, uint8 _partnershipId)
        external
        view
        override
        returns (
            uint256 partnerId,
            uint256 tokenSaleId,
            uint256 feeBP,
            bool isApproved
        )
    {
        TokenSalePartnerships storage partnerships =
            tokenSalePartnerships[_tokenSaleId];
        Partnership storage partnership =
            partnerships.partnershipRequests[_partnershipId];
        partnerId = partnership.partnerId;
        tokenSaleId = partnership.tokenSaleId;
        feeBP = partnership.feeBP;
        isApproved = partnership.isApproved;
    }
}


// File contracts/interfaces/ILiftoffRegistration.sol

pragma solidity =0.6.6;

interface ILiftoffRegistration {
    function registerProject(
        string calldata ipfsHash,
        uint256 launchTime,
        uint256 softCap,
        uint256 hardCap,
        uint256 totalSupplyWad,
        string calldata name,
        string calldata symbol
    ) external;
}


// File contracts/LiftoffRegistration.sol

pragma solidity =0.6.6;
contract LiftoffRegistration is
    ILiftoffRegistration,
    Initializable,
    OwnableUpgradeable
{
    ILiftoffEngine public liftoffEngine;
    uint256 public minLaunchTime;
    uint256 public maxLaunchTime;
    uint256 public softCapTimer;

    mapping(uint256 => string) tokenIpfsHashes;

    event TokenIpfsHash(uint256 tokenId, string ipfsHash);

    function initialize(
        uint256 _minTimeToLaunch,
        uint256 _maxTimeToLaunch,
        uint256 _softCapTimer,
        ILiftoffEngine _liftoffEngine
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        setLaunchTimeWindow(_minTimeToLaunch, _maxTimeToLaunch);
        setLiftoffEngine(_liftoffEngine);
        setSoftCapTimer(_softCapTimer);
    }

    function registerProject(
        string calldata ipfsHash,
        uint256 launchTime,
        uint256 softCap,
        uint256 hardCap,
        uint256 totalSupplyWad,
        string calldata name,
        string calldata symbol
    ) external override {
        require(
            launchTime >= block.timestamp + minLaunchTime,
            "Not allowed to launch before minLaunchTime"
        );
        require(
            launchTime <= block.timestamp + maxLaunchTime,
            "Not allowed to launch after maxLaunchTime"
        );
        require(
            totalSupplyWad < (10**12) * (10**18),
            "Cannot launch more than 1 trillion tokens"
        );
        require(
            totalSupplyWad >= 1000 * (10**18),
            "Cannot launch less than 1000 tokens"
        );
        require(
            softCap >= 10 ether,
            "Cannot launch if softcap is less than 10 ether"
        );

        uint256 tokenId =
            liftoffEngine.launchToken(
                launchTime,
                launchTime + softCapTimer,
                softCap,
                hardCap,
                totalSupplyWad,
                name,
                symbol,
                msg.sender
            );

        tokenIpfsHashes[tokenId] = ipfsHash;

        emit TokenIpfsHash(tokenId, ipfsHash);
    }

    function setSoftCapTimer(uint256 _seconds) public onlyOwner {
        softCapTimer = _seconds;
    }

    function setLaunchTimeWindow(uint256 _min, uint256 _max) public onlyOwner {
        minLaunchTime = _min;
        maxLaunchTime = _max;
    }

    function setLiftoffEngine(ILiftoffEngine _liftoffEngine) public onlyOwner {
        liftoffEngine = _liftoffEngine;
    }
}


// File contracts/LiftoffSettings.sol

pragma solidity =0.6.6;
contract LiftoffSettings is
    ILiftoffSettings,
    Initializable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 private ethXLockBP;
    uint256 private tokenUserBP;

    uint256 private insurancePeriod;

    uint256 private ethBuyBP;
    uint256 private baseFee;
    uint256 private projectDevBP;
    uint256 private mainFeeBP;
    uint256 private lidPoolBP;

    address private liftoffInsurance;
    address private liftoffRegistration;
    address private liftoffEngine;
    address private xEth;
    address private xLocker;
    address private uniswapRouter;

    address private lidTreasury;
    address private lidPoolManager;

    address private liftoffPartnerships;

    event LogEthXLockBP(uint256 ethXLockBP);
    event LogTokenUserBP(uint256 tokenUserBP);
    event LogInsurancePeriod(uint256 insurancePeriod);
    event LogXethBP(
        uint256 baseFee,
        uint256 ethBuyBP,
        uint256 projectDevBP,
        uint256 mainFeeBP,
        uint256 lidPoolBP
    );
    event LogLidTreasury(address lidTreasury);
    event LogLidPoolManager(address lidPoolManager);
    event LogLiftoffInsurance(address liftoffInsurance);
    event LogLiftoffLauncher(address liftoffLauncher);
    event LogLiftoffEngine(address liftoffEngine);
    event LogLiftoffPartnerships(address liftoffPartnerships);
    event LogXEth(address xEth);
    event LogXLocker(address xLocker);
    event LogUniswapRouter(address uniswapRouter);

    function initialize() external initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function setAllUints(
        uint256 _ethXLockBP,
        uint256 _tokenUserBP,
        uint256 _insurancePeriod,
        uint256 _baseFeeBP,
        uint256 _ethBuyBP,
        uint256 _projectDevBP,
        uint256 _mainFeeBP,
        uint256 _lidPoolBP
    ) external override onlyOwner {
        setEthXLockBP(_ethXLockBP);
        setTokenUserBP(_tokenUserBP);
        setInsurancePeriod(_insurancePeriod);
        setXethBP(_baseFeeBP, _ethBuyBP, _projectDevBP, _mainFeeBP, _lidPoolBP);
    }

    function setAllAddresses(
        address _liftoffInsurance,
        address _liftoffRegistration,
        address _liftoffEngine,
        address _liftoffPartnerships,
        address _xEth,
        address _xLocker,
        address _uniswapRouter,
        address _lidTreasury,
        address _lidPoolManager
    ) external override onlyOwner {
        setLiftoffInsurance(_liftoffInsurance);
        setLiftoffRegistration(_liftoffRegistration);
        setLiftoffEngine(_liftoffEngine);
        setLiftoffPartnerships(_liftoffPartnerships);
        setXEth(_xEth);
        setXLocker(_xLocker);
        setUniswapRouter(_uniswapRouter);
        setLidTreasury(_lidTreasury);
        setLidPoolManager(_lidPoolManager);
    }

    function setEthXLockBP(uint256 _val) public override onlyOwner {
        ethXLockBP = _val;

        emit LogEthXLockBP(ethXLockBP);
    }

    function getEthXLockBP() external view override returns (uint256) {
        return ethXLockBP;
    }

    function setTokenUserBP(uint256 _val) public override onlyOwner {
        tokenUserBP = _val;

        emit LogTokenUserBP(tokenUserBP);
    }

    function getTokenUserBP() external view override returns (uint256) {
        return tokenUserBP;
    }

    function setLiftoffInsurance(address _val) public override onlyOwner {
        liftoffInsurance = _val;

        emit LogLiftoffInsurance(liftoffInsurance);
    }

    function getLiftoffInsurance() external view override returns (address) {
        return liftoffInsurance;
    }

    function setLiftoffRegistration(address _val) public override onlyOwner {
        liftoffRegistration = _val;

        emit LogLiftoffLauncher(liftoffRegistration);
    }

    function getLiftoffRegistration() external view override returns (address) {
        return liftoffRegistration;
    }

    function setLiftoffEngine(address _val) public override onlyOwner {
        liftoffEngine = _val;

        emit LogLiftoffEngine(liftoffEngine);
    }

    function getLiftoffEngine() external view override returns (address) {
        return liftoffEngine;
    }

    function setLiftoffPartnerships(address _val) public override onlyOwner {
        liftoffPartnerships = _val;

        emit LogLiftoffPartnerships(liftoffPartnerships);
    }

    function getLiftoffPartnerships() external view override returns (address) {
        return liftoffPartnerships;
    }

    function setXEth(address _val) public override onlyOwner {
        xEth = _val;

        emit LogXEth(xEth);
    }

    function getXEth() external view override returns (address) {
        return xEth;
    }

    function setXLocker(address _val) public override onlyOwner {
        xLocker = _val;

        emit LogXLocker(xLocker);
    }

    function getXLocker() external view override returns (address) {
        return xLocker;
    }

    function setUniswapRouter(address _val) public override onlyOwner {
        uniswapRouter = _val;

        emit LogUniswapRouter(uniswapRouter);
    }

    function getUniswapRouter() external view override returns (address) {
        return uniswapRouter;
    }

    function setInsurancePeriod(uint256 _val) public override onlyOwner {
        insurancePeriod = _val;

        emit LogInsurancePeriod(insurancePeriod);
    }

    function getInsurancePeriod() external view override returns (uint256) {
        return insurancePeriod;
    }

    function setLidTreasury(address _val) public override onlyOwner {
        lidTreasury = _val;

        emit LogLidTreasury(lidTreasury);
    }

    function getLidTreasury() external view override returns (address) {
        return lidTreasury;
    }

    function setLidPoolManager(address _val) public override onlyOwner {
        lidPoolManager = _val;

        emit LogLidPoolManager(lidPoolManager);
    }

    function getLidPoolManager() external view override returns (address) {
        return lidPoolManager;
    }

    function setXethBP(
        uint256 _baseFeeBP,
        uint256 _ethBuyBP,
        uint256 _projectDevBP,
        uint256 _mainFeeBP,
        uint256 _lidPoolBP
    ) public override onlyOwner {
        require(
            _baseFeeBP.add(_ethBuyBP).add(_projectDevBP).add(_mainFeeBP).add(
                _lidPoolBP
            ) == 10000,
            "Must allocate 100% of eth raised"
        );
        baseFee = _baseFeeBP;
        ethBuyBP = _ethBuyBP;
        projectDevBP = _projectDevBP;
        mainFeeBP = _mainFeeBP;
        lidPoolBP = _lidPoolBP;

        emit LogXethBP(baseFee, ethBuyBP, projectDevBP, mainFeeBP, lidPoolBP);
    }

    function getBaseFeeBP() external view override returns (uint256) {
        return baseFee;
    }

    function getEthBuyBP() external view override returns (uint256) {
        return ethBuyBP;
    }

    function getProjectDevBP() external view override returns (uint256) {
        return projectDevBP;
    }

    function getMainFeeBP() external view override returns (uint256) {
        return mainFeeBP;
    }

    function getLidPoolBP() external view override returns (uint256) {
        return lidPoolBP;
    }
}


// File contracts/interfaces/ILiftoffSwap.sol

pragma solidity =0.6.6;

interface ILiftoffSwap {
    function acceptIgnite(address _token) external payable;

    function acceptSpark(address _token) external payable;
}


// File contracts/weth/WETH9.sol

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.6.6;

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}


/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/