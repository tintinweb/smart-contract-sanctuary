// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './libs/complifi/tokens/IERC20Metadata.sol';
import './libs/complifi/tokens/EIP20NonStandardInterface.sol';
import './libs/complifi/tokens/TokenMetadataGenerator.sol';

import './Token.sol';
import './Math.sol';
import './repricers/IVolmexRepricer.sol';
import './libs/complifi/IVault.sol';
import './interfaces/IVolmexProtocol.sol';

contract Pool is Ownable, Pausable, Bronze, Token, Math, TokenMetadataGenerator {
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut,
        uint256 fee,
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenLeverageIn,
        uint256 tokenLeverageOut
    );

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

    event LOG_REPRICE(
        uint256 repricingBlock,
        uint256 balancePrimary,
        uint256 balanceComplement,
        uint256 leveragePrimary,
        uint256 leverageComplement,
        uint256 newLeveragePrimary,
        uint256 newLeverageComplement,
        uint256 estPricePrimary,
        uint256 estPriceComplement
    );

    event LOG_SET_FEE_PARAMS(
        uint256 baseFee,
        uint256 maxFee,
        uint256 feeAmpPrimary,
        uint256 feeAmpComplement
    ); // TODO: Understand what is Amp here.

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    bool private _mutex;

    address private controller; // has CONTROL role

    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool private _finalized;

    uint256 public constant BOUND_TOKENS = 2;
    address[BOUND_TOKENS] private _tokens;
    // This is mapped by token addresses
    mapping(address => Record) internal _records;

    uint256 public repricingBlock;
    uint256 public upperBoundary;

    uint256 public baseFee;
    uint256 public feeAmpPrimary;
    uint256 public feeAmpComplement;
    uint256 public maxFee;

    // TODO: Understand the pMin
    uint256 public pMin;
    uint256 public qMin;
    // TODO: Need to understand exposureLimitPrimary
    uint256 public exposureLimitPrimary;
    // TODO: Need to understand exposureLimitComplement
    uint256 public exposureLimitComplement;

    uint256 private denomination;

    // Currently not is use. Required in x5Repricer and callOption
    // TODO: Need to understand the use of these args in repricer
    // uint256 public repricerParam1;
    // uint256 public repricerParam2;

    IVolmexRepricer public repricer;
    IVolmexProtocol public protocol;

    string public volatilitySymbol;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        requireLock();
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        requireLock();
        _;
    }

    modifier onlyFinalized() {
        require(_finalized, 'NOT_FINALIZED');
        _;
    }

    modifier onlyNotSettled() {
        require(!protocol.isSettled(), 'PROTOCOL_SETTLED');
        _;
    }

    function requireLock() internal view {
        require(!_mutex, 'REENTRY');
    }

    constructor(
        IVolmexRepricer _repricer,
        IVolmexProtocol _protocol,
        address _controller
    ) public {
        repricer = _repricer;

        require(Address.isContract(address(_protocol)), 'NOT_CONTRACT');
        protocol = _protocol;

        require(_controller != address(0), 'NOT_CONTROLLER');
        controller = _controller;

        upperBoundary = protocol.volatilityCapRatio() * VOLATILITY_PRICE_PRECISION;

        volatilitySymbol = protocol.volatilityToken().symbol();

        denomination = protocol.volatilityCapRatio();

        setName(makeTokenName(protocol.volatilityToken().name(), ' LP'));
        setSymbol(makeTokenSymbol(protocol.volatilityToken().symbol(), '-LP'));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function getTokens() external view _viewlock_ returns (address[BOUND_TOKENS] memory tokens) {
        return _tokens;
    }

    function getLeverage(address token) external view _viewlock_ returns (uint256) {
        return _records[token].leverage;
    }

    function getBalance(address token) external view _viewlock_ returns (uint256) {
        return _records[token].balance;
    }

    function setFeeParams(
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement
    ) external _logs_ _lock_ onlyNotSettled {
        require(!_finalized, 'IS_FINALIZED');
        require(msg.sender == controller, 'NOT_CONTROLLER');

        baseFee = _baseFee;
        maxFee = _maxFee;
        feeAmpPrimary = _feeAmpPrimary;
        feeAmpComplement = _feeAmpComplement;

        emit LOG_SET_FEE_PARAMS(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);
    }

    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin
    ) external _logs_ _lock_ onlyNotSettled {
        require(!_finalized, 'IS_FINALIZED');
        require(msg.sender == controller, 'NOT_CONTROLLER');

        require(_primaryBalance == _complementBalance, 'NOT_SYMMETRIC');

        require(baseFee > 0, 'NOT_SET_FEE_PARAMS');

        pMin = _pMin;
        qMin = _qMin;
        exposureLimitPrimary = _exposureLimitPrimary;
        exposureLimitComplement = _exposureLimitComplement;

        _finalized = true;

        bind(0, address(protocol.volatilityToken()), _primaryBalance, _primaryLeverage);
        bind(
            1,
            address(protocol.inverseVolatilityToken()),
            _complementBalance,
            _complementLeverage
        );

        uint256 initPoolSupply = getDerivativeDenomination() * _primaryBalance;

        uint256 collateralDecimals = uint256(
            protocol.collateral().decimals()
        );
        if (collateralDecimals >= 0 && collateralDecimals < 18) {
            initPoolSupply = initPoolSupply * (10**(18 - collateralDecimals));
        }

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(msg.sender, initPoolSupply);
    }

    function bind(
        uint256 index,
        address token,
        uint256 balance,
        uint256 leverage
    ) internal {
        require(balance >= qMin, 'MIN_BALANCE');
        require(leverage > 0, 'ZERO_LEVERAGE');

        _records[token] = Record({ leverage: leverage, balance: balance });

        _tokens[index] = token;

        _pullUnderlying(token, msg.sender, balance);
    }

    function joinPool(uint256 poolAmountOut, uint256[2] calldata maxAmountsIn)
        external
        _logs_
        _lock_
        onlyFinalized
    {
        uint256 poolTotal = totalSupply();
        uint256 ratio = div(poolAmountOut, poolTotal);
        require(ratio != 0, 'MATH_APPROX');

        for (uint256 i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint256 bal = _records[token].balance;
            require(bal > 0, 'NO_BALANCE');
            uint256 tokenAmountIn = mul(ratio, bal);
            require(tokenAmountIn <= maxAmountsIn[i], 'LIMIT_IN');
            _records[token].balance = add(_records[token].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, token, tokenAmountIn);
            _pullUnderlying(token, msg.sender, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[2] calldata minAmountsOut)
        external
        _logs_
        _lock_
        onlyFinalized
    {
        uint256 poolTotal = totalSupply();
        uint256 ratio = div(poolAmountIn, poolTotal);
        require(ratio != 0, 'MATH_APPROX');

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);

        for (uint256 i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint256 bal = _records[token].balance;
            require(bal > 0, 'NO_BALANCE');
            uint256 tokenAmountOut = mul(ratio, bal);
            require(tokenAmountOut >= minAmountsOut[i], 'LIMIT_OUT');
            _records[token].balance = sub(_records[token].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, token, tokenAmountOut);
            _pushUnderlying(token, msg.sender, tokenAmountOut);
        }
    }

    function reprice() internal virtual {
        if (repricingBlock == block.number) return;
        repricingBlock = block.number;

        Record storage primaryRecord = _records[_getPrimaryDerivativeAddress()];
        Record storage complementRecord = _records[_getComplementDerivativeAddress()];

        uint256 estPricePrimary;
        uint256 estPriceComplement;
        uint256 estPrice;
        (estPricePrimary, estPriceComplement, estPrice) = repricer.reprice(volatilitySymbol);

        uint256 primaryRecordLeverageBefore = primaryRecord.leverage;
        uint256 complementRecordLeverageBefore = complementRecord.leverage;

        uint256 leveragesMultiplied = mul(
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore
        );

        // TODO: Need to lookover the sqrtWrapped equation and calculation
        primaryRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    div(
                        mul(leveragesMultiplied, mul(complementRecord.balance, estPrice)),
                        primaryRecord.balance
                    )
                )
            )
        );
        complementRecord.leverage = div(leveragesMultiplied, primaryRecord.leverage);

        emit LOG_REPRICE(
            repricingBlock,
            primaryRecord.balance,
            complementRecord.balance,
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore,
            primaryRecord.leverage,
            complementRecord.leverage,
            estPricePrimary,
            estPriceComplement
            // underlyingStarts: Value of underlying assets (derivative) in USD in the beginning
            // derivativeVault.underlyingStarts(0)
        );
    }

    function spow3(int256 _value) internal pure returns (int256) {
        return (((_value * _value) / iBONE) * _value) / iBONE;
    }

    function calcExpEndFee(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _expEnd
    ) internal pure returns (int256) {
        int256 inBalanceLeveraged = getLeveragedBalanceOfFee(_inRecord[0], _inRecord[1]);
        int256 tokenAmountIn1 =
            inBalanceLeveraged * (_outRecord[0] - _inRecord[0]) /
                (inBalanceLeveraged + getLeveragedBalanceOfFee(_outRecord[0], _outRecord[1]));

        int256 inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int256 tokenAmountIn2 =
            inBalanceLeveragedChanged * (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) /
            (inBalanceLeveragedChanged + getLeveragedBalanceOfFee(_outRecord[0], _outRecord[1]) - _outRecord[2] * iBONE);

        return (tokenAmountIn1 * _baseFee + tokenAmountIn2 * (_baseFee + _feeAmp * (_expEnd * _expEnd / iBONE) / 3)) /
            (tokenAmountIn1 + tokenAmountIn2);
    }

    function getLeveragedBalanceOfFee(int256 _balance, int256 _leverage)
        internal
        pure
        returns (int256)
    {
        return _balance * _leverage;
    }

    function calc(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _maxFee
    ) internal pure returns (int256 fee, int256 expStart) {
        expStart = calcExpStart(_inRecord[0], _outRecord[0]);

        int256 _expEnd =
            ((_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE) /
                (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if (expStart >= 0) {
            fee =
                _baseFee +
                (((_feeAmp) * (spow3(_expEnd) - spow3(expStart))) * iBONE) /
                (3 * (_expEnd - expStart));
        } else if (_expEnd <= 0) {
            fee = _baseFee;
        } else {
            fee = calcExpEndFee(_inRecord, _outRecord, _baseFee, _feeAmp, _expEnd);
        }

        if (_maxFee < fee) {
            fee = _maxFee;
        }

        if (iBONE / 1000 > fee) {
            fee = iBONE / 1000;
        }
    }

    function calcFee(
        Record memory inRecord,
        uint256 tokenAmountIn,
        Record memory outRecord,
        uint256 tokenAmountOut,
        uint256 feeAmp
    ) internal returns (uint256 fee, int256 expStart) {
        int256 ifee;
        (ifee, expStart) = calc(
            [int256(inRecord.balance), int256(inRecord.leverage), int256(tokenAmountIn)],
            [int256(outRecord.balance), int256(outRecord.leverage), int256(tokenAmountOut)],
            int256(baseFee),
            int256(feeAmp),
            int256(maxFee)
        );
        require(ifee > 0, 'BAD_FEE');
        fee = uint256(ifee);
    }

    function calcExpStart(int256 _inBalance, int256 _outBalance) internal pure returns (int256) {
        return ((_inBalance - _outBalance) * iBONE) / (_inBalance + _outBalance);
    }

    function performSwap(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 spotPriceBefore,
        uint256 fee
    ) internal returns (uint256 spotPriceAfter) {
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];

        // TODO: Need to understand this and it's sub/used method
        requireBoundaryConditions(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut,
            _getPrimaryDerivativeAddress() == tokenIn
                ? exposureLimitPrimary
                : exposureLimitComplement
        );

        updateLeverages(inRecord, tokenAmountIn, outRecord, tokenAmountOut);

        inRecord.balance = add(inRecord.balance, tokenAmountIn);
        outRecord.balance = sub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            0
        );

        require(spotPriceAfter >= spotPriceBefore, 'MATH_APPROX');
        require(spotPriceBefore <= div(tokenAmountIn, tokenAmountOut), 'MATH_APPROX_OTHER');

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut,
            fee,
            inRecord.balance,
            outRecord.balance,
            inRecord.leverage,
            outRecord.leverage
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut
    )
        external
        _logs_
        _lock_
        whenNotPaused
        onlyFinalized
        onlyNotSettled
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(tokenIn != tokenOut, 'SAME_TOKEN');
        require(tokenAmountIn >= qMin, 'MIN_TOKEN_IN');

        reprice();

        Record memory inRecord = _records[tokenIn];
        Record memory outRecord = _records[tokenOut];

        require(
            tokenAmountIn <=
                mul(min(getLeveragedBalance(inRecord), inRecord.balance), MAX_IN_RATIO),
            'MAX_IN_RATIO'
        );

        tokenAmountOut = calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            tokenAmountIn,
            0
        );

        (uint256 fee,) = calcFee(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut,
            _getPrimaryDerivativeAddress() == tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        uint256 spotPriceBefore =
            calcSpotPrice(
                getLeveragedBalance(inRecord),
                getLeveragedBalance(outRecord),
                0
            );

        tokenAmountOut = calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            tokenAmountIn,
            fee
        );
        require(tokenAmountOut >= minAmountOut, 'LIMIT_OUT');

        spotPriceAfter = performSwap(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            tokenAmountOut,
            spotPriceBefore,
            fee
        );
    }

//    // Method temporary is not available for external usage.
//    function swapExactAmountOut(
//        address tokenIn,
//        uint256 maxAmountIn,
//        address tokenOut,
//        uint256 tokenAmountOut
//    )
//        private
//        _logs_
//        _lock_
//        whenNotPaused
//        onlyFinalized
//        onlyLiveDerivative
//        returns (uint256 tokenAmountIn, uint256 spotPriceAfter)
//    {
//        require(tokenIn != tokenOut, 'SAME_TOKEN');
//        require(tokenAmountOut >= qMin, 'MIN_TOKEN_OUT');
//
//        reprice();
//
//        Record memory inRecord = _records[tokenIn];
//        Record memory outRecord = _records[tokenOut];
//
//        require(
//            tokenAmountOut <=
//                mul(min(getLeveragedBalance(outRecord), outRecord.balance), MAX_OUT_RATIO),
//            'MAX_OUT_RATIO'
//        );
//
//        tokenAmountIn = calcInGivenOut(
//            getLeveragedBalance(inRecord),
//            getLeveragedBalance(outRecord),
//            tokenAmountOut,
//            0
//        );
//
//        uint256 fee;
//        int256 expStart;
//        (fee, expStart) = calcFee(
//            inRecord,
//            tokenAmountIn,
//            outRecord,
//            tokenAmountOut,
//            _getPrimaryDerivativeAddress() == tokenIn ? feeAmpPrimary : feeAmpComplement
//        );
//
//        uint256 spotPriceBefore =
//            calcSpotPrice(
//                getLeveragedBalance(inRecord),
//                getLeveragedBalance(outRecord),
//                0
//            );
//
//        tokenAmountIn = calcInGivenOut(
//            getLeveragedBalance(inRecord),
//            getLeveragedBalance(outRecord),
//            tokenAmountOut,
//            fee
//        );
//
//        require(tokenAmountIn <= maxAmountIn, 'LIMIT_IN');
//
//        spotPriceAfter = performSwap(
//            tokenIn,
//            tokenAmountIn,
//            tokenOut,
//            tokenAmountOut,
//            spotPriceBefore,
//            fee
//        );
//    }

    function getLeveragedBalance(Record memory r) internal pure returns (uint256) {
        return mul(r.balance, r.leverage);
    }

    function requireBoundaryConditions(
        Record storage inToken,
        uint256 tokenAmountIn,
        Record storage outToken,
        uint256 tokenAmountOut,
        uint256 exposureLimit
    ) internal view {
        require(sub(getLeveragedBalance(outToken), tokenAmountOut) > qMin, 'BOUNDARY_LEVERAGED');
        require(sub(outToken.balance, tokenAmountOut) > qMin, 'BOUNDARY_NON_LEVERAGED');

        uint256 lowerBound = div(pMin, sub(upperBoundary, pMin));
        uint256 upperBound = div(sub(upperBoundary, pMin), pMin);
        uint256 value = div(
            add(getLeveragedBalance(inToken), tokenAmountIn),
            sub(getLeveragedBalance(outToken), tokenAmountOut)
        );

        require(lowerBound < value, 'BOUNDARY_LOWER');
        require(value < upperBound, 'BOUNDARY_UPPER');

        (uint256 numerator, bool sign) = subSign(
            add(add(inToken.balance, tokenAmountIn), tokenAmountOut),
            outToken.balance
        );

        if (!sign) {
            uint256 denominator = sub(
                add(add(inToken.balance, tokenAmountIn), outToken.balance),
                tokenAmountOut
            );

            require(div(numerator, denominator) < exposureLimit, 'BOUNDARY_EXPOSURE');
        }
    }

    function updateLeverages(
        Record memory inToken,
        uint256 tokenAmountIn,
        Record memory outToken,
        uint256 tokenAmountOut
    ) internal pure {
        outToken.leverage = div(
            sub(getLeveragedBalance(outToken), tokenAmountOut),
            sub(outToken.balance, tokenAmountOut)
        );
        require(outToken.leverage > 0, 'ZERO_OUT_LEVERAGE');

        inToken.leverage = div(
            add(getLeveragedBalance(inToken), tokenAmountIn),
            add(inToken.balance, tokenAmountIn)
        );
        require(inToken.leverage > 0, 'ZERO_IN_LEVERAGE');
    }

    function getDerivativeDenomination() internal view returns (uint256) {
        // TODO: As per the inspection denomination equals 2,
        // the amount of collateral used to mint both derivatives.
        // denomination =
        //     derivativeVault
        //         .derivativeSpecification()
        //         .primaryNominalValue() +
        //     derivativeVault
        //         .derivativeSpecification()
        //         .complementNominalValue();

        return denomination;
    }

    function _getPrimaryDerivativeAddress() internal view returns (address) {
        return _tokens[0];
    }

    function _getComplementDerivativeAddress() internal view returns (address) {
        return _tokens[1];
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullPoolShare(address from, uint256 amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }

    /// @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
    /// This will revert due to insufficient balance or insufficient allowance.
    /// This function returns the actual amount received,
    /// which may be less than `amount` if there is a fee attached to the transfer.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC20(erc20).balanceOf(address(this));
        EIP20NonStandardInterface(erc20).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, 'TOKEN_TRANSFER_IN_FAILED');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(erc20).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, 'TOKEN_TRANSFER_IN_OVERFLOW');
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /// @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    /// error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    /// insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    /// it is >= amount, this should not revert in normal conditions.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        EIP20NonStandardInterface(erc20).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, 'TOKEN_TRANSFER_OUT_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title EIP20NonStandardInterface
/// @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
/// See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
interface EIP20NonStandardInterface {
    /// @notice Get the total number of tokens in circulation
    /// @return The supply of tokens
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of the specified address
    /// @param owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address owner) external view returns (uint256 balance);

    //
    // !!!!!!!!!!!!!!
    // !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    // !!!!!!!!!!!!!!
    //

    /// @notice Transfer `amount` tokens from `msg.sender` to `dst`
    /// @param dst The address of the destination account
    /// @param amount The number of tokens to transfer
    function transfer(address dst, uint256 amount) external;

    //
    // !!!!!!!!!!!!!!
    // !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    // !!!!!!!!!!!!!!
    //

    /// @notice Transfer `amount` tokens from `src` to `dst`
    /// @param src The address of the source account
    /// @param dst The address of the destination account
    /// @param amount The number of tokens to transfer
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /// @notice Approve `spender` to transfer up to `amount` from `src`
    /// @dev This will overwrite the approval amount for `spender`
    ///  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
    /// @param spender The address of the account which may transfer tokens
    /// @param amount The number of tokens that are approved
    /// @return success Whether or not the approval succeeded
    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    /// @notice Get the current allowance from `owner` for `spender`
    /// @param owner The address of the account which owns the tokens to be spent
    /// @param spender The address of the account which may transfer tokens
    /// @return remaining The number of tokens allowed to be spent
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "../libs/BokkyPooBahsDateTimeLibrary/BokkyPooBahsDateTimeLibrary.sol";

contract TokenMetadataGenerator {
    function formatDate(uint256 _posixDate)
        internal
        view
        returns (string memory)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(
            _posixDate
        );

        return
            concat(
                uint2str(day),
                concat(
                    getMonthShortName(month),
                    uint2str(getCenturyYears(year))
                )
            );
    }

    function formatMeta(
        string memory _prefix,
        string memory _concatenator,
        string memory _postfix
    ) internal pure returns (string memory) {
        return concat(_prefix, concat(_concatenator, _postfix));
    }

    function makeTokenName(
        string memory _baseName,
        string memory _postfix
    ) internal pure returns (string memory) {
        return formatMeta(_baseName, " ", _postfix);
    }

    function makeTokenSymbol(
        string memory _baseName,
        string memory _postfix
    ) internal pure returns (string memory) {
        return formatMeta(_baseName, "-", _postfix);
    }

    function getCenturyYears(uint256 _year) internal pure returns (uint256) {
        return _year % 100;
    }

    function concat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function getMonthShortName(uint256 _month)
        internal
        pure
        returns (string memory)
    {
        if (_month == 1) {
            return "Jan";
        }
        if (_month == 2) {
            return "Feb";
        }
        if (_month == 3) {
            return "Mar";
        }
        if (_month == 4) {
            return "Apr";
        }
        if (_month == 5) {
            return "May";
        }
        if (_month == 6) {
            return "Jun";
        }
        if (_month == 7) {
            return "Jul";
        }
        if (_month == 8) {
            return "Aug";
        }
        if (_month == 9) {
            return "Sep";
        }
        if (_month == 10) {
            return "Oct";
        }
        if (_month == 11) {
            return "Nov";
        }
        if (_month == 12) {
            return "Dec";
        }
        return "NaN";
    }
}

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

pragma solidity 0.7.6;

import './Num.sol';

// Highly opinionated token implementation

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);
}

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = add(_balance[address(this)], amt);
        _totalSupply = add(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, 'INSUFFICIENT_BAL');
        _balance[address(this)] = sub(_balance[address(this)], amt);
        _totalSupply = sub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, 'INSUFFICIENT_BAL');
        _balance[src] = sub(_balance[src], amt);
        _balance[dst] = add(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function setName(string memory name) internal {
        _name = name;
    }

    function setSymbol(string memory symbol) internal {
        _symbol = symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = add(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = sub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[src][msg.sender];
        require(msg.sender == src || amt <= oldValue, 'TOKEN_BAD_CALLER');
        _move(src, dst, amt);
        if (msg.sender != src && oldValue != uint256(-1)) {
            _allowance[src][msg.sender] = sub(oldValue, amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

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

pragma solidity 0.7.6;

import './Num.sol';

contract Math is Bronze, Const, Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                 bI          1                                         //
    // bO = tokenBalanceOut         sP =  ----  *  ----------                                    //
    // sF = swapFee                        bO      ( 1 - sF )                                    //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 ratio = div(tokenBalanceIn, tokenBalanceOut);
        uint256 scale = div(BONE, sub(BONE, swapFee));
        spotPrice = mul(ratio, scale);
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \   \                 //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  |  |                 //
    // sF = swapFee                     \      \ ( bI + ( aI * ( 1 - sF )) /   /                 //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 adjustedIn = sub(BONE, swapFee);
        adjustedIn = mul(tokenAmountIn, adjustedIn);
        uint256 y = div(tokenBalanceIn, add(tokenBalanceIn, adjustedIn));
        uint256 bar = sub(BONE, y);
        tokenAmountOut = mul(tokenBalanceOut, bar);
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \       \                             //
    // bI = tokenBalanceIn          bI * |  | ------------  | - 1  |                             //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /       /                             //
    // sF = swapFee                 --------------------------------                             //
    //                                              ( 1 - sF )                                   //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 diff = sub(tokenBalanceOut, tokenAmountOut);
        uint256 y = div(tokenBalanceOut, diff);
        uint256 foo = sub(y, BONE);
        tokenAmountIn = sub(BONE, swapFee);
        tokenAmountIn = div(mul(tokenBalanceIn, foo), tokenAmountIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

interface IVolmexRepricer {
    function protocolVolatilityCapRatio() external view returns (uint256);

    function reprice(string calldata _volatilitySymbol)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );

    function sqrtWrapped(int256 value) external pure returns (int256);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "./IDerivativeSpecification.sol";

/// @title Derivative implementation Vault
/// @notice A smart contract that references derivative specification and enables users to mint and redeem the derivative
interface IVault {
    enum State { Created, Live, Settled }

    /// @notice start of live period
    function liveTime() external view returns (uint256);

    /// @notice end of live period
    function settleTime() external view returns (uint256);

    /// @notice redeem function can only be called after the end of the Live period + delay
    function settlementDelay() external view returns (uint256);

    /// @notice underlying value at the start of live period
    function underlyingStarts(uint256 index) external view returns (int256);

    /// @notice underlying value at the end of live period
    function underlyingEnds(uint256 index) external view returns (int256);

    /// @notice primary token conversion rate multiplied by 10 ^ 12
    function primaryConversion() external view returns (uint256);

    /// @notice complement token conversion rate multiplied by 10 ^ 12
    function complementConversion() external view returns (uint256);

    /// @notice protocol fee multiplied by 10 ^ 12
    function protocolFee() external view returns (uint256);

    /// @notice limit on author fee multiplied by 10 ^ 12
    function authorFeeLimit() external view returns (uint256);

    // @notice protocol's fee receiving wallet
    function feeWallet() external view returns (address);

    // @notice current state of the vault
    function state() external view returns (State);

    // @notice derivative specification address
    function derivativeSpecification()
        external
        view
        returns (IDerivativeSpecification);

    // @notice collateral token address
    function collateralToken() external view returns (address);

    // @notice oracle address
    function oracles(uint256 index) external view returns (address);

    function oracleIterators(uint256 index) external view returns (address);

    // @notice collateral split address
    function collateralSplit() external view returns (address);

    // @notice derivative's token builder strategy address
    function tokenBuilder() external view returns (address);

    function feeLogger() external view returns (address);

    // @notice primary token address
    function primaryToken() external view returns (address);

    // @notice complement token address
    function complementToken() external view returns (address);

    /// @notice Switch to Settled state if appropriate time threshold is passed and
    /// set underlyingStarts value and set underlyingEnds value,
    /// calculate primaryConversion and complementConversion params
    /// @dev Reverts if underlyingStart or underlyingEnd are not available
    /// Vault cannot settle when it paused
    function settle(uint256[] calldata _underlyingEndRoundHints) external;

    function mintTo(address _recipient, uint256 _collateralAmount) external;

    /// @notice Mints primary and complement derivative tokens
    /// @dev Checks and switches to the right state and does nothing if vault is not in Live state
    function mint(uint256 _collateralAmount) external;

    /// @notice Refund equal amounts of derivative tokens for collateral at any time
    function refund(uint256 _tokenAmount) external;

    function refundTo(address _recipient, uint256 _tokenAmount) external;

    function redeemTo(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external;

    /// @notice Redeems unequal amounts previously calculated conversions if the vault is in Settled state
    function redeem(
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    // State variables
    function minimumCollateralQty() external view returns (uint256);

    function active() external view returns (bool);

    function isSettled() external view returns (bool);

    function volatilityToken() external view returns (IERC20Modified);

    function inverseVolatilityToken()
        external
        view
        returns (IERC20Modified);

    function collateral() external view returns (IERC20Modified);

    function issuanceFees() external view returns (uint256);

    function redeemFees() external view returns (uint256);

    function accumulatedFees() external view returns (uint256);

    function volatilityCapRatio() external view returns (uint256);

    function settlementPrice() external view returns (uint256);

    // External functions
    function initialize(
        IERC20Modified _collateralTokenAddress,
        IERC20Modified _volatilityToken,
        IERC20Modified _inverseVolatilityToken,
        uint256 _minimumCollateralQty,
        uint256 _volatilityCapRatio
    ) external;

    function toggleActive() external;

    function updateMinimumCollQty(uint256 _newMinimumCollQty)
        external;

    function updatePositionToken(
        address _positionToken,
        bool _isVolatilityIndex
    ) external;

    function collateralize(uint256 _collateralQty) external;

    function redeem(uint256 _positionTokenQty) external;

    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external;

    function settle(uint256 _settlementPrice) external;

    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;

    function updateFees(uint256 _issuanceFees, uint256 _redeemFees)
        external;

    function claimAccumulatedFees() external;

    function togglePause(bool _isPause) external;
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

pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days =
            _day -
                32075 +
                (1461 * (_year + 4800 + (_month - 14) / 12)) /
                4 +
                (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
                12 -
                (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
                4 -
                OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        (uint256 year, uint256 month, ) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _years)
    {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) =
            _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) =
            _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

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

pragma solidity 0.7.6;

import './Const.sol';

contract Num is Const {
    function toi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function floor(uint256 a) internal pure returns (uint256) {
        return toi(a) * BONE;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, 'ADD_OVERFLOW');
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, 'SUB_UNDERFLOW');
    }

    function subSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, 'MUL_OVERFLOW');
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, 'MUL_OVERFLOW');
        c = c1 / BONE;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0, 'DIV_ZERO');
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, 'DIV_INTERNAL'); // mul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, 'DIV_INTERNAL'); //  add require
        c = c1 / b;
    }

    // DSMath.wpow
    function powi(uint256 a, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_POW_BASE, 'POW_BASE_TOO_LOW');
        require(base <= MAX_POW_BASE, 'POW_BASE_TOO_HIGH');

        uint256 whole = floor(exp);
        uint256 remain = sub(exp, whole);

        uint256 wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = powApprox(base, remain, POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256 sum) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = subSign(base, BONE);
        uint256 term = BONE;
        sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = subSign(a, sub(bigK, BONE));
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
    }

    function min(uint256 first, uint256 second) internal pure returns (uint256) {
        if (first < second) {
            return first;
        }
        return second;
    }
}

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

pragma solidity 0.7.6;

import './Color.sol';

contract Const is Bronze {
    uint256 public constant BONE = 10**18;
    int256 public constant iBONE = int256(BONE);

    uint256 public constant MIN_POW_BASE = 1 wei;
    uint256 public constant MAX_POW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant POW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;

    uint256 public constant VOLATILITY_PRICE_PRECISION = 10**4;
}

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

pragma solidity 0.7.6;

abstract contract Color {
    function getColor() external view virtual returns (bytes32);
}

contract Bronze is Color {
    function getColor() external view override returns (bytes32) {
        return bytes32('BRONZE');
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
    /// @notice Proof of a derivative specification
    /// @dev Verifies that contract is a derivative specification
    /// @return true if contract is a derivative specification
    function isDerivativeSpecification() external pure returns (bool);

    /// @notice Set of oracles that are relied upon to measure changes in the state of the world
    /// between the start and the end of the Live period
    /// @dev Should be resolved through OracleRegistry contract
    /// @return oracle symbols
    function oracleSymbols() external view returns (bytes32[] memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    /// finds the value closest to a given timestamp
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbols
    function oracleIteratorSymbols() external view returns (bytes32[] memory);

    /// @notice Type of collateral that users submit to mint the derivative
    /// @dev Should be resolved through CollateralTokenRegistry contract
    /// @return collateral token symbol
    function collateralTokenSymbol() external view returns (bytes32);

    /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
    /// and the initial collateral split to the final collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split symbol
    function collateralSplitSymbol() external view returns (bytes32);

    /// @notice Lifecycle parameter that define the length of the derivative's Live period.
    /// @dev Set in seconds
    /// @return live period value
    function livePeriod() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of primary asset
    /// @dev Units of collateral theoretically swappable for 1 unit of primary asset
    /// @return primary nominal value
    function primaryNominalValue() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of complement asset
    /// @dev Units of collateral theoretically swappable for 1 unit of complement asset
    /// @return complement nominal value
    function complementNominalValue() external view returns (uint256);

    /// @notice Minting fee rate due to the author of the derivative specification.
    /// @dev Percentage fee multiplied by 10 ^ 12
    /// @return author fee
    function authorFee() external view returns (uint256);

    /// @notice Symbol of the derivative
    /// @dev Should be resolved through DerivativeSpecificationRegistry contract
    /// @return derivative specification symbol
    function symbol() external view returns (string memory);

    /// @notice Return optional long name of the derivative
    /// @dev Isn't used directly in the protocol
    /// @return long name
    function name() external view returns (string memory);

    /// @notice Optional URI to the derivative specs
    /// @dev Isn't used directly in the protocol
    /// @return URI to the derivative specs
    function baseURI() external view returns (string memory);

    /// @notice Derivative spec author
    /// @dev Used to set and receive author's fee
    /// @return address of the author
    function author() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

/**
 * @dev Modified Interface of the OpenZeppelin's IERC20 extra functions to add features in position token.
 */
interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function mint(address _toWhom, uint256 amount) external;

    function burn(address _whose, uint256 amount) external;

    function grantRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function pause() external;

    function unpause() external;
}

