/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/lib/SafeMath.sol


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant TWO = 2*10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/lib/ReentrancyGuard.sol


/**
 * @title ReentrancyGuard
 * @author DODO Breeder
 *
 * @notice Protect functions from Reentrancy Attack
 */
contract ReentrancyGuard {
    // https://solidity.readthedocs.io/en/latest/control-structures.html?highlight=zero-state#scoping-and-declarations
    // zero-state of _ENTERED_ is false
    bool private _ENTERED_;

    modifier preventReentrant() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/AggregatorV3Interface.sol


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/DODOPrivatePool/intf/IOracle.sol


interface IOracle {
    function getPrice(address base) external view returns (uint256 latestPrice, bool feasible);
    function getState(address base) external view returns (uint256 latestPrice, uint64 spread, uint64 coefficient,
    bool feasible);
    function getTimestamp() external view returns (uint256 timestamp);
}

// File: contracts/WooPP.sol

contract WooPP is InitializableOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using DecimalMath for uint256;
    using SafeERC20 for IERC20;

    bool public isOpenTWAP = false;

    event LpFeeRateChange(address baseToken, uint256 newLpFeeRate);
    event WooSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address to
    );

    modifier isOraclePriceValid(address baseToken) {
        // TODO：security -- double check the swap price with multiple 3rd party oracles
        (, bool isFeasible) = IOracle(priceOracle).getPrice(baseToken);
        require(isFeasible, "ORACLE_PRICE_NOT_FEASIBLE");
        _;
    }

    mapping(address => bool) public isStrategist;

    modifier onlyStrategist() {
        require(isStrategist[msg.sender], "NOT_STRATEGIST");
        _;
    }

    // ============ Core Address ============

    address public quoteToken;

    // uint256 public _BASE_PRICE_CUMULATIVE_LAST_;

    // ============ Variables for Pricing ============

    struct TokenInfo {
        uint112 baseSold;
        uint112 quoteSold;
        uint32 lastResetTimestamp;
        uint64 lpFeeRate;
        uint64 R;
        bool isValid;
        address chainlinkRefOracle; // Reference
    }

    address public priceOracle; // WooOracle
    mapping (address => TokenInfo) public tokenInfo;

    string public pairsInfo;

    address public quoteChainlinkRefOracle; // Reference

    function getPairInfo() external view returns (string memory) {
        return pairsInfo;
    }

    function setPairsInfo(string calldata _pairsInfo) external onlyStrategist {
        pairsInfo = _pairsInfo;
    }

    function autoUpdate(TokenInfo memory info) internal view {
        uint32 priceTimestamp = uint32(IOracle(priceOracle).getTimestamp() % 2**32);
        if (priceTimestamp != info.lastResetTimestamp) {
            // TODO add the condition about minimal pool size
            info.baseSold = 0;
            info.quoteSold = 0;
            info.lastResetTimestamp = priceTimestamp;
        }
    }

    // When baseSold >= 0
    function getQuoteAmountLowBaseSide(uint256 p0, uint256 s, uint256 k, uint256 f, uint256 r, uint256 baseAmount) internal pure returns (uint256) {
        // priceFactor = (1 - s/2 - f) / (1 + k * baseAmount * p * r);
        uint256 priceFactor = DecimalMath.ONE.sub(DecimalMath.divCeil(s, DecimalMath.TWO)).sub(f).divFloor(
            DecimalMath.ONE.add(k.mulCeil(baseAmount).mulCeil(p0).mulCeil(r)));
        // return p0 * baseAmount * priceFactor;
        return p0.mulFloor(baseAmount.mulFloor(priceFactor)); // round down
    }

    // When baseSold >= 0
    function getBaseAmountLowBaseSide(uint256 p0, uint256 s, uint256 k, uint256 f, uint256 r, uint256 quoteAmount) internal pure returns (uint256) {
        // priceFactor = 1 - s/2 - f - k * quoteAmount * r;
        uint256 priceFactor = DecimalMath.ONE.sub(DecimalMath.divFloor(s, DecimalMath.TWO)).sub(f).sub(
            k.mulFloor(quoteAmount).mulFloor(r));
        // return quoteAmount * p0^{-1} / priceFactor;
        return DecimalMath.divFloor(DecimalMath.divFloor(quoteAmount, p0), priceFactor); // round down
    }

    // When quoteSold >= 0
    function getBaseAmountLowQuoteSide(uint256 p0, uint256 s, uint256 k, uint256 f, uint256 r, uint256 quoteAmount) internal pure returns (uint256) {
        // priceFactor = (1 - s/2 - f) / (1 + k * quoteAmount * r);
        uint256 priceFactor = DecimalMath.ONE.sub(DecimalMath.divCeil(s, DecimalMath.TWO)).sub(f).divFloor(
            DecimalMath.ONE.add(k.mulCeil(quoteAmount).mulCeil(r)));
        // return p0 * quoteAmount * priceFactor;
        return DecimalMath.reciprocalFloor(p0).mulFloor(quoteAmount.mulFloor(priceFactor)); // round down
    }

    // When quoteSold >= 0
    function getQuoteAmountLowQuoteSide(uint256 p0, uint256 s, uint256 k, uint256 f, uint256 r, uint256 baseAmount) internal pure returns (uint256) {
        // priceFactor = 1 - s/2 - f - k * baseAmount * p * r;
        uint256 priceFactor = DecimalMath.ONE.sub(DecimalMath.divFloor(s, DecimalMath.TWO)).sub(f).sub(
            k.mulFloor(baseAmount).mulFloor(p0).mulFloor(r));
        // return baseAmount * p0 / priceFactor;
        return DecimalMath.divFloor(baseAmount.mulFloor(p0), priceFactor); // round down
    }

    function getQuoteAmountSellBase(address baseToken, uint256 baseAmount, TokenInfo memory info) internal view returns (uint256 realQuoteAmount) {
        uint256 p0;
        uint256 s;
        uint256 k;
        (p0, s, k, ) = IOracle(priceOracle).getState(baseToken);
        uint256 f = info.lpFeeRate;

        ensurePriceReliable(p0, info);

        if(info.quoteSold == 0) {
            uint256 oldBaseSold = uint256(info.baseSold);
            uint256 newBaseSold = oldBaseSold.add(baseAmount);
            realQuoteAmount = getQuoteAmountLowBaseSide(p0, s, k, f, DecimalMath.ONE, newBaseSold).sub(
                    getQuoteAmountLowBaseSide(p0, s, k, f, DecimalMath.ONE, oldBaseSold));

            require(newBaseSold <= type(uint112).max);
            info.baseSold = uint112(newBaseSold);
        }
        else {
            uint256 baseBought = getBaseAmountLowQuoteSide(p0, s, k, f, info.R, info.quoteSold);
            if (baseAmount > baseBought) {
                baseAmount = baseAmount.sub(baseBought);
                realQuoteAmount = uint256(info.quoteSold).add(getQuoteAmountLowBaseSide(p0, s, k, f, DecimalMath.ONE, baseAmount));

                info.quoteSold = 0;
                require(baseAmount <= type(uint112).max);
                info.baseSold = uint112(baseAmount);
            }
            else {
                uint256 newBaseBought = baseBought.sub(baseAmount);
                realQuoteAmount = uint256(info.quoteSold).sub(
                        getQuoteAmountLowQuoteSide(p0, s, k, info.lpFeeRate, info.R, newBaseBought));

                info.quoteSold = uint112(uint256(info.quoteSold).sub(realQuoteAmount));
            }
        }
    }

    function getBaseAmountSellQuote(address baseToken, uint256 quoteAmount, TokenInfo memory info) internal view returns (uint256 realBaseAmount) {
        uint256 p0;
        uint256 s;
        uint256 k;
        (p0, s, k, ) = IOracle(priceOracle).getState(baseToken);
        uint256 f = info.lpFeeRate;

        ensurePriceReliable(p0, info);

        if(info.baseSold == 0) {
            uint256 oldQuoteSold = uint256(info.quoteSold);
            uint256 newQuoteSold = oldQuoteSold.add(quoteAmount);
            realBaseAmount = getBaseAmountLowQuoteSide(p0, s, k, f, DecimalMath.ONE, newQuoteSold).sub(
                    getBaseAmountLowQuoteSide(p0, s, k, f, DecimalMath.ONE, oldQuoteSold));

            require(newQuoteSold <= type(uint112).max);
            info.quoteSold = uint112(newQuoteSold);
        }
        else {
            uint256 quoteBought = getQuoteAmountLowBaseSide(p0, s, k, f, info.R, info.baseSold);
            if (quoteAmount > quoteBought) {
                quoteAmount = quoteAmount.sub(quoteBought);
                realBaseAmount = uint256(info.baseSold).add(realBaseAmount.add(getBaseAmountLowQuoteSide(p0, s, k, f, DecimalMath.ONE, quoteAmount)));

                info.baseSold = 0;
                require(quoteAmount <= type(uint112).max);
                info.quoteSold = uint112(quoteAmount);
            }
            else {
                uint256 newQuoteBought = quoteBought.sub(quoteAmount);
                realBaseAmount = uint256(info.baseSold).sub(
                        getBaseAmountLowQuoteSide(p0, s, k, info.lpFeeRate, info.R, newQuoteBought));

                info.baseSold = uint112(uint256(info.baseSold).sub(realBaseAmount));
            }
        }
    }

    function sellBase(address baseToken, uint256 baseAmount, uint256 minQuoteAmount, address from, address to)
        external
        preventReentrant
        isOraclePriceValid(baseToken)
        returns (uint256 realQuoteAmount)
    {
        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        autoUpdate(info);

        realQuoteAmount = getQuoteAmountSellBase(baseToken, baseAmount, info);

        require(realQuoteAmount >= minQuoteAmount, "PRICE_EXCEEDS_LIMIT");
        IERC20(baseToken).safeTransferFrom(from, address(this), baseAmount);
        IERC20(quoteToken).safeTransfer(to, realQuoteAmount);

        tokenInfo[baseToken] = info;

        emit WooSwap(
            baseToken,
            quoteToken,
            baseAmount,
            realQuoteAmount,
            from,
            to
        );
    }

    function sellQuote(address baseToken, uint256 quoteAmount, uint256 minBaseAmount, address from, address to)
        external
        preventReentrant
        isOraclePriceValid(baseToken)
        returns (uint256 realBaseAmount)
    {
        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        autoUpdate(info);

        realBaseAmount = getBaseAmountSellQuote(baseToken, quoteAmount, info);

        require(realBaseAmount >= minBaseAmount, "PRICE_EXCEEDS_LIMIT");
        IERC20(quoteToken).safeTransferFrom(from, address(this), quoteAmount);
        IERC20(baseToken).safeTransfer(to, realBaseAmount);

        tokenInfo[baseToken] = info;

        emit WooSwap(
            quoteToken,
            baseToken,
            quoteAmount,
            realBaseAmount,
            from,
            to
        );
    }

    function querySellBase(address baseToken, uint256 baseAmount)
        external
        view
        isOraclePriceValid(baseToken)
        returns (uint256 quoteAmount)
    {
        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        autoUpdate(info);

        quoteAmount = getQuoteAmountSellBase(baseToken, baseAmount, info);
    }

    function querySellQuote(address baseToken, uint256 quoteAmount)
        external
        view
        isOraclePriceValid(baseToken)
        returns (uint256 baseAmount)
    {
        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        autoUpdate(info);

        baseAmount = getBaseAmountSellQuote(baseToken, quoteAmount, info);
    }

    function getPoolSize(address token) external view returns (uint256 poolSize) {
        poolSize = IERC20(token).balanceOf(address(this));
    }

    function init(
        address owner,
        address _quoteToken,
        // address mtFeeRateModel,
        address _priceOracle
        // bool isOpenTWAP
    ) external {
        initOwner(owner);
        isStrategist[owner] = true;

        quoteToken = _quoteToken;

        require(_priceOracle !=  address(0), "INVALID_ORACLE");
        priceOracle = _priceOracle;

        // emit LpFeeRateChange(lpFeeRate);
        // isOpenTWAP = isOpenTWAP;
        // if(isOpenTWAP) _BLOCK_TIMESTAMP_LAST_ = uint32(block.timestamp % 2**32);
    }

    function setQuoteChainlinkRefOracle(address newQuoteChainlinkRefOracle) external preventReentrant onlyStrategist {
        require(newQuoteChainlinkRefOracle != address(0), "INVALID_REFERNECE_ORACLE");
        quoteChainlinkRefOracle = newQuoteChainlinkRefOracle;
    }

    function addBaseToken(
        address baseToken,
        uint256 lpFeeRate,
        uint256 R,
        address chainlinkRefOracle
    ) public preventReentrant onlyStrategist {
        require(lpFeeRate <= 1e18, "LP_FEE_RATE_OUT_OF_RANGE");
        require(R <= 1e18, "R_OUT_OF_RANGE");

        require(baseToken != quoteToken, "BASE_QUOTE_CAN_NOT_BE_SAME");

        TokenInfo memory info = tokenInfo[baseToken];
        require(!info.isValid, "TOKEN_ALREADY_EXISTS");

        info.isValid = true;
        info.lpFeeRate = uint64(lpFeeRate);
        info.R = uint64(R);
        info.chainlinkRefOracle = chainlinkRefOracle;
        tokenInfo[baseToken] = info;
    }

    function removeBaseToken(
        address baseToken
    ) public preventReentrant onlyStrategist {
        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");

        info.isValid = false;
        info.baseSold = 0;
        info.quoteSold = 0;
        info.lastResetTimestamp = 0;
        info.lpFeeRate = 0;
        info.R = 0;
        info.chainlinkRefOracle = address(0);
        tokenInfo[baseToken] = info;
    }

    function setBaseReferenecOracle1(address baseToken, address chainlinkRefOracle) external preventReentrant onlyStrategist {
        TokenInfo storage info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        info.chainlinkRefOracle = chainlinkRefOracle;
    }

    function tuneParameters(
        address baseToken,
        uint256 newLpFeeRate,
        uint256 newR
        // uint256 minBaseReserve,
        // uint256 minQuoteReserve
    ) public preventReentrant onlyStrategist returns (bool) {
        // require(
        //     _BASE_RESERVE_ >= minBaseReserve && _QUOTE_RESERVE_ >= minQuoteReserve,
        //     "RESERVE_AMOUNT_IS_NOT_ENOUGH"
        // );
        require(newLpFeeRate <= 1e18, "LP_FEE_RATE_OUT_OF_RANGE");
        require(newR <= 1e18, "K_OUT_OF_RANGE");

        TokenInfo memory info = tokenInfo[baseToken];
        require(info.isValid, "TOKEN_DOES_NOT_EXIST");
        info.lpFeeRate = uint64(newLpFeeRate);
        info.R = uint64(newR);

        tokenInfo[baseToken] = info;

        emit LpFeeRateChange(baseToken, newLpFeeRate);
        return true;
    }

    // ========== Administrative functions ==========

    function setStrategist(address strategist, bool flag) external onlyOwner {
        isStrategist[strategist] = flag;
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(_OWNER_, amount);
    }

    // ========== Internal functions ==========
    function ensurePriceReliable(uint256 p0, TokenInfo memory info) internal view {
        // check Chainlink
        if (info.chainlinkRefOracle != address(0)) {
            (, int256 rawReferencePrice, , , ) = AggregatorV3Interface(info.chainlinkRefOracle).latestRoundData();
            require(rawReferencePrice >= 0, "INVALID_CHAINLINK_PRICE");
            (, int256 quoteReferenecPrice, , , ) = AggregatorV3Interface(quoteChainlinkRefOracle).latestRoundData();
            require(quoteReferenecPrice >= 0, "INVALID_CHAINLINK_QUOTE_PRICE");
            // referencePrice = rawReferencePrice * 10 ** (18 - decimals);
            require(AggregatorV3Interface(info.chainlinkRefOracle).decimals() == AggregatorV3Interface(quoteChainlinkRefOracle).decimals(),
                "CHAINLINK_DECIMALS_MISMATCH");
            uint256 referencePrice = uint256(rawReferencePrice).divFloor(uint256(quoteReferenecPrice));
            require(referencePrice.mulFloor(1e18-1e16) <= p0 && p0 <= referencePrice.mulCeil(1e18+1e16), "PRICE_UNRELIABLE");
        }
    }
}