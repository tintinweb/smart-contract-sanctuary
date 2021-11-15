// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/MathExt.sol";
import "./libraries/FeeFomula.sol";
import "./libraries/ERC20Permit.sol";

import "./interfaces/IDMMFactory.sol";
import "./interfaces/IDMMCallee.sol";
import "./interfaces/IDMMPool.sol";
import "./VolumeTrendRecorder.sol";

contract DMMPool is IDMMPool, ERC20Permit, ReentrancyGuard, VolumeTrendRecorder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_UINT112 = 2**112 - 1;
    uint256 internal constant BPS = 10000;

    struct ReserveData {
        uint256 reserve0;
        uint256 reserve1;
        uint256 vReserve0;
        uint256 vReserve1; // only used when isAmpPool = true
    }

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    /// @dev To make etherscan auto-verify new pool, these variables are not immutable
    IDMMFactory public override factory;
    IERC20 public override token0;
    IERC20 public override token1;

    /// @dev uses single storage slot, accessible via getReservesData
    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 public override ampBps;
    /// @dev addition param only when amplification factor > 1
    uint112 internal vReserve0;
    uint112 internal vReserve1;

    /// @dev vReserve0 * vReserve1, as of immediately after the most recent liquidity event
    uint256 public override kLast;
    

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to,
        uint256 feeInPrecision
    );
    event Sync(uint256 vReserve0, uint256 vReserve1, uint256 reserve0, uint256 reserve1);

    constructor() public ERC20Permit("KyberDMM LP", "DMM-LP", "1") VolumeTrendRecorder(0) {
        factory = IDMMFactory(msg.sender);
    }

    // called once by the factory at time of deployment
    function initialize(
        IERC20 _token0,
        IERC20 _token1,
        uint32 _ampBps
    ) external {
        require(msg.sender == address(factory), "DMM: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
        ampBps = _ampBps;
    }

    /// @dev this low-level function should be called from a contract
    ///                 which performs important safety checks
    function mint(address to) external override nonReentrant returns (uint256 liquidity) {
        (bool isAmpPool, ReserveData memory data) = getReservesData();
        ReserveData memory _data;
        _data.reserve0 = token0.balanceOf(address(this));
        _data.reserve1 = token1.balanceOf(address(this));
        uint256 amount0 = _data.reserve0.sub(data.reserve0);
        uint256 amount1 = _data.reserve1.sub(data.reserve1);

        bool feeOn = _mintFee(isAmpPool, data);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            if (isAmpPool) {
                uint32 _ampBps = ampBps;
                _data.vReserve0 = _data.reserve0.mul(_ampBps) / BPS;
                _data.vReserve1 = _data.reserve1.mul(_ampBps) / BPS;
            }
            liquidity = MathExt.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(-1), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / data.reserve0,
                amount1.mul(_totalSupply) / data.reserve1
            );
            if (isAmpPool) {
                uint256 b = liquidity.add(_totalSupply);
                _data.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, _data.reserve0);
                _data.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, _data.reserve1);
            }
        }
        require(liquidity > 0, "DMM: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(isAmpPool, _data);
        if (feeOn) kLast = getK(isAmpPool, _data);
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @dev this low-level function should be called from a contract
    /// @dev which performs important safety checks
    /// @dev user must transfer LP token to this contract before call burn
    function burn(address to)
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        (bool isAmpPool, ReserveData memory data) = getReservesData(); // gas savings
        IERC20 _token0 = token0; // gas savings
        IERC20 _token1 = token1; // gas savings

        uint256 balance0 = _token0.balanceOf(address(this));
        uint256 balance1 = _token1.balanceOf(address(this));
        require(balance0 >= data.reserve0 && balance1 >= data.reserve1, "DMM: UNSYNC_RESERVES");
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(isAmpPool, data);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "DMM: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _token0.safeTransfer(to, amount0);
        _token1.safeTransfer(to, amount1);
        ReserveData memory _data;
        _data.reserve0 = _token0.balanceOf(address(this));
        _data.reserve1 = _token1.balanceOf(address(this));
        if (isAmpPool) {
            uint256 b = Math.min(
                _data.reserve0.mul(_totalSupply) / data.reserve0,
                _data.reserve1.mul(_totalSupply) / data.reserve1
            );
            _data.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, _data.reserve0);
            _data.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, _data.reserve1);
        }
        _update(isAmpPool, _data);
        if (feeOn) kLast = getK(isAmpPool, _data); // data are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @dev this low-level function should be called from a contract
    /// @dev which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata callbackData
    ) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "DMM: INSUFFICIENT_OUTPUT_AMOUNT");
        (bool isAmpPool, ReserveData memory data) = getReservesData(); // gas savings
        require(
            amount0Out < data.reserve0 && amount1Out < data.reserve1,
            "DMM: INSUFFICIENT_LIQUIDITY"
        );

        ReserveData memory newData;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            IERC20 _token0 = token0;
            IERC20 _token1 = token1;
            require(to != address(_token0) && to != address(_token1), "DMM: INVALID_TO");
            if (amount0Out > 0) _token0.safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _token1.safeTransfer(to, amount1Out); // optimistically transfer tokens
            if (callbackData.length > 0)
                IDMMCallee(to).dmmSwapCall(msg.sender, amount0Out, amount1Out, callbackData);
            newData.reserve0 = _token0.balanceOf(address(this));
            newData.reserve1 = _token1.balanceOf(address(this));
            if (isAmpPool) {
                newData.vReserve0 = data.vReserve0.add(newData.reserve0).sub(data.reserve0);
                newData.vReserve1 = data.vReserve1.add(newData.reserve1).sub(data.reserve1);
            }
        }
        uint256 amount0In = newData.reserve0 > data.reserve0 - amount0Out
            ? newData.reserve0 - (data.reserve0 - amount0Out)
            : 0;
        uint256 amount1In = newData.reserve1 > data.reserve1 - amount1Out
            ? newData.reserve1 - (data.reserve1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "DMM: INSUFFICIENT_INPUT_AMOUNT");
        uint256 feeInPrecision = verifyBalanceAndUpdateEma(
            amount0In,
            amount1In,
            isAmpPool ? data.vReserve0 : data.reserve0,
            isAmpPool ? data.vReserve1 : data.reserve1,
            isAmpPool ? newData.vReserve0 : newData.reserve0,
            isAmpPool ? newData.vReserve1 : newData.reserve1
        );

        _update(isAmpPool, newData);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to, feeInPrecision);
        {
            IERC20 tokenFee;
            uint256 amountIn;
            if (amount0In > 0) {
                tokenFee = token0;
                amountIn = amount0In;
            } else {
                tokenFee = token1;
                amountIn = amount1In;
            }
            sendFeeToPlatform(feeInPrecision, tokenFee, amountIn);
        }
    }

    /// @dev force balances to match reserves
    function skim(address to) external nonReentrant {
        token0.safeTransfer(to, token0.balanceOf(address(this)).sub(reserve0));
        token1.safeTransfer(to, token1.balanceOf(address(this)).sub(reserve1));
    }

    /// @dev force reserves to match balances
    function sync() external override nonReentrant {
       (bool isAmpPool, ReserveData memory data) = getReservesData();
        bool feeOn = _mintFee(isAmpPool, data);
        ReserveData memory newData;
        newData.reserve0 = IERC20(token0).balanceOf(address(this));
        newData.reserve1 = IERC20(token1).balanceOf(address(this));
        // update virtual reserves if this is amp pool
        if (isAmpPool) {
            uint256 _totalSupply = totalSupply();
            uint256 b = Math.min(
                newData.reserve0.mul(_totalSupply) / data.reserve0,
                newData.reserve1.mul(_totalSupply) / data.reserve1
            );
            newData.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, newData.reserve0);
            newData.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, newData.reserve1);
        }
        _update(isAmpPool, newData);
        if (feeOn) kLast = getK(isAmpPool, newData);
    }

    function _sync() private {
        (bool isAmpPool, ReserveData memory data) = getReservesData();
        ReserveData memory newData;
        newData.reserve0 = IERC20(token0).balanceOf(address(this));
        newData.reserve1 = IERC20(token1).balanceOf(address(this));
        // update virtual reserves if this is amp pool
        if (isAmpPool) {
            uint256 _totalSupply = totalSupply();
            uint256 b = Math.min(
                newData.reserve0.mul(_totalSupply) / data.reserve0,
                newData.reserve1.mul(_totalSupply) / data.reserve1
            );
            newData.vReserve0 = Math.max(data.vReserve0.mul(b) / _totalSupply, newData.reserve0);
            newData.vReserve1 = Math.max(data.vReserve1.mul(b) / _totalSupply, newData.reserve1);
        }
        _update(isAmpPool, newData);
    }

    /// @dev returns data to calculate amountIn, amountOut
    function getTradeInfo()
        external
        virtual
        override
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint256 feeInPrecision
        )
    {
        // gas saving to read reserve data
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        uint32 _ampBps = ampBps;
        _vReserve0 = vReserve0;
        _vReserve1 = vReserve1;
        if (_ampBps == BPS) {
            _vReserve0 = _reserve0;
            _vReserve1 = _reserve1;
        }
        uint256 rFactorInPrecision = getRFactor(block.number);
        feeInPrecision = FeeFomula.getFeeSwap(rFactorInPrecision, _ampBps);
    }

    /// @dev returns reserve data to calculate amount to add liquidity
    function getReserves() external override view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function name() public override view returns (string memory) {
        return FeeFomula.name(address(token0), address(token1));
    }

    function symbol() public override view returns (string memory) {
        return FeeFomula.symbol(address(token0), address(token1));
    }

    function verifyBalanceAndUpdateEma(
        uint256 amount0In,
        uint256 amount1In,
        uint256 beforeReserve0,
        uint256 beforeReserve1,
        uint256 afterReserve0,
        uint256 afterReserve1
    ) internal virtual returns (uint256 feeInPrecision) {
        // volume = beforeReserve0 * amount1In / beforeReserve1 + amount0In (normalized into amount in token 0)
        uint256 volume = beforeReserve0.mul(amount1In).div(beforeReserve1).add(amount0In);
        uint256 rFactorInPrecision = recordNewUpdatedVolume(block.number, volume);
        feeInPrecision = FeeFomula.getFeeSwap(rFactorInPrecision, ampBps);
        // verify balance update matches with fomula
        uint256 balance0Adjusted = afterReserve0.mul(PRECISION);
        balance0Adjusted = balance0Adjusted.sub(amount0In.mul(feeInPrecision));
        balance0Adjusted = balance0Adjusted / PRECISION;
        uint256 balance1Adjusted = afterReserve1.mul(PRECISION);
        balance1Adjusted = balance1Adjusted.sub(amount1In.mul(feeInPrecision));
        balance1Adjusted = balance1Adjusted / PRECISION;
        require(
            balance0Adjusted.mul(balance1Adjusted) >= beforeReserve0.mul(beforeReserve1),
            "DMM: INVALID K"
        );
    }


    function getFeeBeforeSwap(
        uint256 amount0In,
        uint256 amount1In
    ) public override view returns (uint256 fee, uint256 rFactorInPrecision) {
        uint256 beforeReserve0 = vReserve0;
        uint256 beforeReserve1 = vReserve1;
        if (beforeReserve0 == 0 || beforeReserve1 == 0) {
            beforeReserve0 = uint256(reserve0).mul(ampBps).div(BPS);
            beforeReserve1 = uint256(reserve1).mul(ampBps).div(BPS);
        }
        uint256 afterReserve0 = beforeReserve0.add(amount0In);
        uint256 afterReserve1 = beforeReserve1.add(amount1In);
        uint256 volume = beforeReserve0.mul(amount1In).div(beforeReserve1).add(amount0In);
        rFactorInPrecision = calculateRFactorByNewVolume(block.number, volume);
        uint256 feeInPrecision = FeeFomula.getFeeSwap(rFactorInPrecision, ampBps);
        uint256 amount = amount0In > 0 ? amount0In : amount1In;
        fee = feeInPrecision.mul(amount).div(PRECISION);
        uint256 balance0Adjusted = afterReserve0.mul(PRECISION);
        balance0Adjusted = balance0Adjusted.sub(amount0In.mul(feeInPrecision));
        balance0Adjusted = balance0Adjusted / PRECISION;
        uint256 balance1Adjusted = afterReserve1.mul(PRECISION);
        balance1Adjusted = balance1Adjusted.sub(amount1In.mul(feeInPrecision));
        balance1Adjusted = balance1Adjusted / PRECISION;
        require(
            balance0Adjusted.mul(balance1Adjusted) >= beforeReserve0.mul(beforeReserve1),
            "DMM: INVALID K"
        );
    }


    /// @dev update reserves
    function _update(bool isAmpPool, ReserveData memory data) internal {
        reserve0 = safeUint112(data.reserve0);
        reserve1 = safeUint112(data.reserve1);
        if (isAmpPool) {
            assert(data.vReserve0 >= data.reserve0 && data.vReserve1 >= data.reserve1); // never happen
            vReserve0 = safeUint112(data.vReserve0);
            vReserve1 = safeUint112(data.vReserve1);
        }
        emit Sync(data.vReserve0, data.vReserve1, data.reserve0, data.reserve1);
    }

    /// @dev if fee is on, mint liquidity equivalent to configured fee of the growth in sqrt(k)
    function _mintFee(bool isAmpPool, ReserveData memory data) internal returns (bool feeOn) {
        (address feeTo, uint16 governmentFeeBps,) = factory.getFeeConfiguration();
        feeOn = (feeTo != address(0) && governmentFeeBps != 0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = MathExt.sqrt(getK(isAmpPool, data));
                uint256 rootKLast = MathExt.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply().mul(rootK.sub(rootKLast)).mul(
                        governmentFeeBps
                    );
                    uint256 denominator = rootK.add(rootKLast).mul(5000);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /// @dev gas saving to read reserve data
    function getReservesData() internal view returns (bool isAmpPool, ReserveData memory data) {
        data.reserve0 = reserve0;
        data.reserve1 = reserve1;
        isAmpPool = ampBps != BPS;
        if (isAmpPool) {
            data.vReserve0 = vReserve0;
            data.vReserve1 = vReserve1;
        }
    }

    function getK(bool isAmpPool, ReserveData memory data) internal pure returns (uint256) {
        return isAmpPool ? data.vReserve0 * data.vReserve1 : data.reserve0 * data.reserve1;
    }

    function safeUint112(uint256 x) internal pure returns (uint112) {
        require(x <= MAX_UINT112, "DMM: OVERFLOW");
        return uint112(x);
    }

    function feeForPlatform(uint256 _feeInPrecision, uint256 amount, uint16 platformFeeBps) private view returns (uint256) {
        uint256 precision = 10 ** 18;
        return _feeInPrecision.mul(amount).div(precision).mul(platformFeeBps).div(BPS);
    }

    function sendFeeToPlatform(uint256 _feeInPrecision, IERC20 token, uint256 amount) private {
        (address feeTo,, uint16 platformFeeBps) = factory.getFeeConfiguration();
        if (feeTo != address(0) && platformFeeBps!= 0) {
            token.safeTransfer(feeTo, feeForPlatform(_feeInPrecision, amount, platformFeeBps));
            _sync();
        }
    }

}

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathExt {
    using SafeMath for uint256;

    uint256 public constant PRECISION = (10**18);

    /// @dev Returns x*y in precision
    function mulInPrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / PRECISION;
    }

    /// @dev source: dsMath
    /// @param xInPrecision should be < PRECISION, so this can not overflow
    /// @return zInPrecision = (x/PRECISION) ^k * PRECISION
    function unsafePowInPrecision(uint256 xInPrecision, uint256 k)
        internal
        pure
        returns (uint256 zInPrecision)
    {
        require(xInPrecision <= PRECISION, "MathExt: x > PRECISION");
        zInPrecision = k % 2 != 0 ? xInPrecision : PRECISION;

        for (k /= 2; k != 0; k /= 2) {
            xInPrecision = (xInPrecision * xInPrecision) / PRECISION;

            if (k % 2 != 0) {
                zInPrecision = (zInPrecision * xInPrecision) / PRECISION;
            }
        }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./MathExt.sol";
import "../interfaces/IERC20Metadata.sol";

library FeeFomula {
    using SafeMath for uint256;
    using MathExt for uint256;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant R0 = 1477405064814996100; // 1.4774050648149961

    uint256 private constant C0 = (60 * PRECISION) / 10000;

    uint256 private constant A = uint256(PRECISION * 20000) / 27;
    uint256 private constant B = uint256(PRECISION * 250) / 9;
    uint256 private constant C1 = uint256(PRECISION * 985) / 27;
    uint256 private constant U = (120 * PRECISION) / 100;

    uint256 private constant G = (836 * PRECISION) / 1000;
    uint256 private constant F = 5 * PRECISION;
    uint256 private constant L = (2 * PRECISION) / 10000;
    // C2 = 25 * PRECISION - (F * (PRECISION - G)**2) / ((PRECISION - G)**2 + L * PRECISION)
    uint256 private constant C2 = 20036905816356657810;

    /// @dev calculate fee from rFactorInPrecision, see section 3.2 in dmmSwap white paper
    /// @dev fee in [15, 60] bps
    /// @return fee percentage in Precision
    function getFee(uint256 rFactorInPrecision) internal pure returns (uint256) {
        if (rFactorInPrecision >= R0) {
            return C0;
        } else if (rFactorInPrecision >= PRECISION) {
            // C1 + A * (r-U)^3 + b * (r-U)
            if (rFactorInPrecision > U) {
                uint256 tmp = rFactorInPrecision - U;
                uint256 tmp3 = tmp.unsafePowInPrecision(3);
                return (C1.add(A.mulInPrecision(tmp3)).add(B.mulInPrecision(tmp))) / 10000;
            } else {
                uint256 tmp = U - rFactorInPrecision;
                uint256 tmp3 = tmp.unsafePowInPrecision(3);
                return C1.sub(A.mulInPrecision(tmp3)).sub(B.mulInPrecision(tmp)) / 10000;
            }
        } else {
            // [ C2 + sign(r - G) *  F * (r-G) ^2 / (L + (r-G) ^2) ] / 10000
            uint256 tmp = (
                rFactorInPrecision > G ? (rFactorInPrecision - G) : (G - rFactorInPrecision)
            );
            tmp = tmp.unsafePowInPrecision(2);
            uint256 tmp2 = F.mul(tmp).div(tmp.add(L));
            if (rFactorInPrecision > G) {
                return C2.add(tmp2) / 10000;
            } else {
                return C2.sub(tmp2) / 10000;
            }
        }
    }

    function getFinalFee(uint256 feeInPrecision, uint32 _ampBps) internal pure returns (uint256) {
        if (_ampBps <= 20000) {
            return feeInPrecision;
        } else if (_ampBps <= 50000) {
            return (feeInPrecision * 20) / 30;
        } else if (_ampBps <= 200000) { // < 20
            return (feeInPrecision * 10) / 30;
        } else { // > 20 
            return (feeInPrecision * 4) / 30;
        }
    }

    function getFeeSwap(uint256 rFactorInPrecision, uint32 _ampBps)
        internal
        pure
        returns (uint256)
    {
        return getFinalFee(getFee(rFactorInPrecision), _ampBps);
    }

    function name(address token0, address token1) public view returns (string memory) {
        IERC20Metadata _token0 = IERC20Metadata(token0);
        IERC20Metadata _token1 = IERC20Metadata(token1);
        return string(abi.encodePacked("KyberDMM LP ", _token0.symbol(), "-", _token1.symbol()));
    }

    function symbol(address token0, address token1) public view returns (string memory) {
        IERC20Metadata _token0 = IERC20Metadata(token0);
        IERC20Metadata _token1 = IERC20Metadata(token1);
        return string(abi.encodePacked("DMM-LP ", _token0.symbol(), "-", _token1.symbol()));
    }

    function decimal(address token0) public view returns (uint8) {
        IERC20Metadata _token0 = IERC20Metadata(token0);
        return _token0.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IERC20Permit.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-2612
contract ERC20Permit is ERC20, IERC20Permit {
    /// @dev To make etherscan auto-verify new pool, this variable is not immutable
    bytes32 public domainSeparator;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERC20(name, symbol) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "ERC20Permit: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20Permit: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function getFeeConfiguration() external view returns (address _feeAddress, uint16 _governmentFeeBps, uint16 _platformFeeBps);

    function getUnamplifiedPool(IERC20 token0, IERC20 token1) external view returns (address);

    function isPool(
        IERC20 token0,
        IERC20 token1,
        address pool
    ) external view returns (bool);

    function feeSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    event PoolCreated(
        IERC20 indexed token0,
        IERC20 indexed token1,
        address pool,
        uint32 ampBps,
        uint256 totalPool
    );

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

interface IDMMCallee {
    function dmmSwapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDMMFactory.sol";

interface IDMMPool {
    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint112 reserve0,
            uint112 reserve1,
            uint256 feeInPrecision
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function ampBps() external view returns (uint32);

    function factory() external view returns (IDMMFactory);

    function kLast() external view returns (uint256);

    function getFeeBeforeSwap(
        uint256 amount0In,
        uint256 amount1In
    ) external view returns (uint256 fee, uint256 rFactorInPrecision);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./libraries/MathExt.sol";

/// @dev contract to calculate volume trend. See secion 3.1 in the white paper
/// @dev EMA stands for Exponential moving average
/// @dev https://en.wikipedia.org/wiki/Moving_average
contract VolumeTrendRecorder {
    using MathExt for uint256;
    using SafeMath for uint256;

    uint256 private constant MAX_UINT128 = 2**128 - 1;
    uint256 internal constant PRECISION = 10**18;
    uint256 private constant SHORT_ALPHA = (2 * PRECISION) / 5401;
    uint256 private constant LONG_ALPHA = (2 * PRECISION) / 10801;

    uint128 internal shortEMA;
    uint128 internal longEMA;
    // total volume in current block
    uint128 internal currentBlockVolume;
    uint128 internal lastTradeBlock;

    event UpdateEMA(uint256 shortEMA, uint256 longEMA, uint128 lastBlockVolume, uint256 skipBlock);

    constructor(uint128 _emaInit) public {
        shortEMA = _emaInit;
        longEMA = _emaInit;
        lastTradeBlock = safeUint128(block.number);
    }

    function getVolumeTrendData()
        external
        view
        returns (
            uint128 _shortEMA,
            uint128 _longEMA,
            uint128 _currentBlockVolume,
            uint128 _lastTradeBlock
        )
    {
        _shortEMA = shortEMA;
        _longEMA = longEMA;
        _currentBlockVolume = currentBlockVolume;
        _lastTradeBlock = lastTradeBlock;
    }

    /// @dev records a new trade, update ema and returns current rFactor for this trade
    /// @return rFactor in Precision for this trade
    function recordNewUpdatedVolume(uint256 blockNumber, uint256 value)
        internal
        returns (uint256)
    {
        // this can not be underflow because block.number always increases
        uint256 skipBlock = blockNumber - lastTradeBlock;
        if (skipBlock == 0) {
            currentBlockVolume = safeUint128(
                uint256(currentBlockVolume).add(value),
                "volume exceeds valid range"
            );
            return calculateRFactor(uint256(shortEMA), uint256(longEMA));
        }
        uint128 _currentBlockVolume = currentBlockVolume;
        uint256 _shortEMA = newEMA(shortEMA, SHORT_ALPHA, currentBlockVolume);
        uint256 _longEMA = newEMA(longEMA, LONG_ALPHA, currentBlockVolume);
        // ema = ema * (1-aplha) ^(skipBlock -1)
        _shortEMA = _shortEMA.mulInPrecision(
            (PRECISION - SHORT_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        _longEMA = _longEMA.mulInPrecision(
            (PRECISION - LONG_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        shortEMA = safeUint128(_shortEMA);
        longEMA = safeUint128(_longEMA);
        currentBlockVolume = safeUint128(value);
        lastTradeBlock = safeUint128(blockNumber);

        emit UpdateEMA(_shortEMA, _longEMA, _currentBlockVolume, skipBlock);

        return calculateRFactor(_shortEMA, _longEMA);
    }

    function calculateRFactorByNewVolume(uint256 blockNumber, uint256 value)
        internal
        view
        returns (uint256) {

        uint256 skipBlock = blockNumber - lastTradeBlock;
        if (skipBlock == 0) {
            safeUint128(
                uint256(currentBlockVolume).add(value),
                "volume exceeds valid range"
            );
            return calculateRFactor(uint256(shortEMA), uint256(longEMA));
        }

        uint256 _shortEMA = newEMA(shortEMA, SHORT_ALPHA, currentBlockVolume);
        uint256 _longEMA = newEMA(longEMA, LONG_ALPHA, currentBlockVolume);
        // ema = ema * (1-aplha) ^(skipBlock -1)
        _shortEMA = _shortEMA.mulInPrecision(
            (PRECISION - SHORT_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        _longEMA = _longEMA.mulInPrecision(
            (PRECISION - LONG_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        return calculateRFactor(_shortEMA, _longEMA);

    }

    /// @return rFactor in Precision for this trade
    function getRFactor(uint256 blockNumber) internal view returns (uint256) {
        // this can not be underflow because block.number always increases
        uint256 skipBlock = blockNumber - lastTradeBlock;
        if (skipBlock == 0) {
            return calculateRFactor(shortEMA, longEMA);
        }
        uint256 _shortEMA = newEMA(shortEMA, SHORT_ALPHA, currentBlockVolume);
        uint256 _longEMA = newEMA(longEMA, LONG_ALPHA, currentBlockVolume);
        _shortEMA = _shortEMA.mulInPrecision(
            (PRECISION - SHORT_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        _longEMA = _longEMA.mulInPrecision(
            (PRECISION - LONG_ALPHA).unsafePowInPrecision(skipBlock - 1)
        );
        return calculateRFactor(_shortEMA, _longEMA);
    }

    function calculateRFactor(uint256 _shortEMA, uint256 _longEMA)
        internal
        pure
        returns (uint256)
    {
        if (_longEMA == 0) {
            return 0;
        }
        return (_shortEMA * MathExt.PRECISION) / _longEMA;
    }

    /// @dev return newEMA value
    /// @param ema previous ema value in wei
    /// @param alpha in Precicion (required < Precision)
    /// @param value current value to update ema
    /// @dev ema and value is uint128 and alpha < Percison
    /// @dev so this function can not overflow and returned ema is not overflow uint128
    function newEMA(
        uint128 ema,
        uint256 alpha,
        uint128 value
    ) internal pure returns (uint256) {
        assert(alpha < PRECISION);
        return ((PRECISION - alpha) * uint256(ema) + alpha * uint256(value)) / PRECISION;
    }

    function safeUint128(uint256 v) internal pure returns (uint128) {
        require(v <= MAX_UINT128, "overflow uint128");
        return uint128(v);
    }

    function safeUint128(uint256 v, string memory errorMessage) internal pure returns (uint128) {
        require(v <= MAX_UINT128, errorMessage);
        return uint128(v);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

