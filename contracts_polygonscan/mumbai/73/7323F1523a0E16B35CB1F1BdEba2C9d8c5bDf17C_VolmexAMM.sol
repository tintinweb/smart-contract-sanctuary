// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/introspection/ERC165CheckerUpgradeable.sol';

import './libs/tokens/EIP20NonStandardInterface.sol';
import './libs/tokens/TokenMetadataGenerator.sol';
import './libs/tokens/Token.sol';
import './maths/Math.sol';
import './interfaces/IVolmexRepricer.sol';
import './interfaces/IVolmexProtocol.sol';
import './interfaces/IVolmexAMM.sol';
import './interfaces/IFlashLoanReceiver.sol';
import './interfaces/IVolmexController.sol';

/**
 * @title Volmex AMM Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexAMM is
    OwnableUpgradeable,
    PausableUpgradeable,
    Token,
    Math,
    TokenMetadataGenerator
{
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

    event FlashLoan(
        address indexed target,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    event SetController(address indexed controller);

    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    // Used to prevent the re-entry
    bool private _mutex;

    // Address of the pool controller
    address private controller; // has CONTROL role

    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool private _finalized;

    // Number of tokens the pool can hold
    uint256 public constant BOUND_TOKENS = 2;
    // Address of the pool tokens
    address[BOUND_TOKENS] private _tokens;
    // This is mapped by token addresses
    mapping(address => Record) internal _records;

    // Value of the current block number while repricing
    uint256 public repricingBlock;
    // Value of upper boundary, set in reference of volatility cap ratio { 250 * 10**18 }
    uint256 public upperBoundary;

    // fee of the pool, used to calculate the swap fee
    uint256 public baseFee;
    // fee on the primary token, used to calculate swap fee, when the swap in asset is primary
    uint256 public feeAmpPrimary;
    // fee on the complement token, used to calculate swap fee, when the swap in asset is complement
    uint256 public feeAmpComplement;
    // Max fee on the swap operation
    uint256 public maxFee;

    // TODO: Understand the pMin
    uint256 public pMin;
    uint256 public qMin;
    // TODO: Need to understand exposureLimitPrimary
    uint256 public exposureLimitPrimary;
    // TODO: Need to understand exposureLimitComplement
    uint256 public exposureLimitComplement;
    // The amount of collateral required to mint both the volatility tokens
    uint256 private denomination;

    // Currently not is use. Required in x5Repricer and callOption
    // TODO: Need to understand the use of these args in repricer
    // uint256 public repricerParam1;
    // uint256 public repricerParam2;

    // Address of the volmex repricer contract
    IVolmexRepricer public repricer;
    // Address of the volmex protocol contract
    IVolmexProtocol public protocol;

    // Number value of the volatility token index at oracle { 0 - ETHV, 1 - BTCV }
    uint256 public volatilityIndex;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    uint256 public adminFee;

    uint256 public FLASHLOAN_PREMIUM_TOTAL;

    /**
     * @notice Used to log the callee's sig, address and data
     */
    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    /**
     * @notice Used to prevent the re-entry
     */
    modifier _lock_() {
        require(!_mutex, 'VolmexAMM: REENTRY');
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @notice Used to prevent multiple call to view methods
     */
    modifier _viewlock_() {
        require(!_mutex, 'VolmexAMM: REENTRY');
        _;
    }

    /**
     * @notice Used to check the pool is finalised
     */
    modifier onlyFinalized() {
        require(_finalized, 'VolmexAMM: AMM is not finalized');
        _;
    }

    /**
     * @notice Used to check the protocol is not settled
     */
    modifier onlyNotSettled() {
        require(!protocol.isSettled(), 'VolmexAMM: Protocol is settled');
        _;
    }

    /**
     * @notice Used to check the caller is controller
     */
    modifier onlyController() {
        require(msg.sender == controller, 'VolmexAMM: Caller is not controller');
        _;
    }

    /**
     * @notice Initialize the pool contract with required elements
     *
     * @dev Checks, the protocol is a contract
     * @dev Sets repricer, protocol and controller addresses
     * @dev Sets upperBoundary, volatilityIndex and denomination
     * @dev Make the AMM token name and symbol
     *
     * @param _repricer Address of the volmex repricer contract
     * @param _protocol Address of the volmex protocol contract
     * @param _volatilityIndex Index of the volatility price in oracle
     */
    function initialize(
        IVolmexRepricer _repricer,
        IVolmexProtocol _protocol,
        uint256 _volatilityIndex,
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement
    ) external initializer {
        require(
            ERC165CheckerUpgradeable.supportsInterface(address(_repricer), _INTERFACE_ID_ERC165),
            'VolmexAMM: Repricer does not supports interface'
        );
        repricer = _repricer;

        // NOTE: Intentionally skipped require check for protocol
        protocol = _protocol;

        __Ownable_init();
        __Pausable_init_unchained();

        upperBoundary = protocol.volatilityCapRatio() * BONE;

        volatilityIndex = _volatilityIndex;

        denomination = protocol.volatilityCapRatio();

        adminFee = 30;
        FLASHLOAN_PREMIUM_TOTAL = 9;

        setName(makeTokenName(protocol.volatilityToken().name(), protocol.collateral().name()));
        setSymbol(
            makeTokenSymbol(protocol.volatilityToken().symbol(), protocol.collateral().symbol())
        );

        setFeeParams(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);
    }

    /**
     * @notice Set controller of the AMM
     *
     * @param _controller Address of the pool contract controller
     */
    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), 'VolmexAMM: Deployer can not be zero address');
        controller = _controller;

        emit SetController(controller);
    }

    /**
     * @notice Used to update the flash loan premium percent
     */
    function updateFlashLoanPremium(uint256 _premium) external onlyOwner {
        FLASHLOAN_PREMIUM_TOTAL = _premium;
    }

    /**
     * @notice Used to get flash loan
     *
     * @dev Decrease the token amount from the record before transfer
     * @dev Calculate the premium (fee) on the flash loan
     * @dev Check if executor is valid
     * @dev Increase the token amount of the record after pulling
     */
    function flashLoan(
        address receiverAddress,
        address assetToken,
        uint256 amount,
        bytes calldata params
    ) external whenNotPaused onlyController {
        _records[assetToken].balance = sub(_records[assetToken].balance, amount);
        IERC20Modified(assetToken).transfer(receiverAddress, amount);

        IFlashLoanReceiver receiver = IFlashLoanReceiver(receiverAddress);
        uint256 premium = div(mul(amount, FLASHLOAN_PREMIUM_TOTAL), 10000);

        require(
            receiver.executeOperation(assetToken, amount, premium, receiverAddress, params),
            'VolmexAMM: Invalid flash loan executor'
        );

        uint256 amountWithPremium = add(amount, premium);

        IERC20Modified(assetToken).transferFrom(receiverAddress, address(this), amountWithPremium);

        _records[assetToken].balance = add(_records[assetToken].balance, amountWithPremium);

        emit FlashLoan(receiverAddress, assetToken, amount, premium);
    }

    /**
     * @notice Used to add liquidity to the pool
     *
     * @dev The token amount in of the pool will be calculated and pulled from LP
     *
     * @param poolAmountOut Amount of pool token mint and transfer to LP
     * @param maxAmountsIn Max amount of pool assets an LP can supply
     */
    function joinPool(
        uint256 poolAmountOut,
        uint256[2] calldata maxAmountsIn,
        address receiver
    ) external _logs_ _lock_ onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = div(poolAmountOut, poolTotal);
        require(ratio != 0, 'VolmexAMM: Invalid math approximation');

        for (uint256 i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint256 bal = _records[token].balance;
            // This can't be tested, as the div method will fail, due to zero supply of lp token
            // The supply of lp token is greater than zero, means token reserve is greater than zero
            // Also, in the case of swap, there's some amount of tokens available pool more than qMin
            require(bal > 0, 'VolmexAMM: Insufficient balance in AMM');
            uint256 tokenAmountIn = mul(ratio, bal);
            require(tokenAmountIn <= maxAmountsIn[i], 'VolmexAMM: Amount in limit exploit');
            _records[token].balance = add(_records[token].balance, tokenAmountIn);
            emit LOG_JOIN(receiver, token, tokenAmountIn);
            _pullUnderlying(token, receiver, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(receiver, poolAmountOut);
    }

    /**
     * @notice Used to remove liquidity from the pool
     *
     * @dev The token amount out of the pool will be calculated and pushed to LP,
     * and pool token are pulled and burned
     *
     * @param poolAmountIn Amount of pool token transfer to the pool
     * @param minAmountsOut Min amount of pool assets an LP wish to redeem
     */
    function exitPool(
        uint256 poolAmountIn,
        uint256[2] calldata minAmountsOut,
        address receiver
    ) external _logs_ _lock_ onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = div(poolAmountIn, poolTotal);
        require(ratio != 0, 'VolmexAMM: Invalid math approximation');

        for (uint256 i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint256 bal = _records[token].balance;
            require(bal > 0, 'VolmexAMM: Insufficient balance in AMM');
            uint256 tokenAmountOut = calculateAmountOut(poolAmountIn, ratio, bal);
            require(tokenAmountOut >= minAmountsOut[i], 'VolmexAMM: Amount out limit exploit');
            _records[token].balance = sub(_records[token].balance, tokenAmountOut);
            emit LOG_EXIT(receiver, token, tokenAmountOut);
            _pushUnderlying(token, receiver, tokenAmountOut);
        }

        _pullPoolShare(receiver, poolAmountIn);
        _burnPoolShare(poolAmountIn);
    }

    /**
     * @notice Used to swap the pool asset
     *
     * @dev Checks the token address, should be different
     * @dev token amount in should be greater than qMin
     * @dev reprices the assets
     * @dev Calculates the token amount out and spot price
     * @dev Perform swaps
     *
     * @param tokenIn Address of the pool asset which the user supply
     * @param tokenAmountIn Amount of asset the user supply
     * @param tokenOut Address of the pool asset which the user wants
     * @param minAmountOut Minimum amount of asset the user wants
     */
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        address receiver
    )
        external
        _logs_
        _lock_
        whenNotPaused
        onlyFinalized
        onlyNotSettled
        onlyController
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(tokenIn != tokenOut, 'VolmexAMM: Passed same token addresses');
        require(tokenAmountIn >= qMin, 'VolmexAMM: Amount in quantity should be larger');

        _reprice();

        Record memory inRecord = _records[tokenIn];
        Record memory outRecord = _records[tokenOut];

        require(
            tokenAmountIn <=
                mul(min(_getLeveragedBalance(inRecord), inRecord.balance), MAX_IN_RATIO),
            'VolmexAMM: Amount in max ratio exploit'
        );

        tokenAmountOut = calcOutGivenIn(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            tokenAmountIn,
            0
        );

        (uint256 fee, ) = calcFee(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut,
            _getPrimaryDerivativeAddress() == tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        uint256 spotPriceBefore = calcSpotPrice(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            0
        );

        tokenAmountOut = calcOutGivenIn(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            tokenAmountIn,
            fee
        );
        require(tokenAmountOut >= minAmountOut, 'VolmexAMM: Amount out limit exploit');

        spotPriceAfter = _performSwap(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            tokenAmountOut,
            spotPriceBefore,
            fee,
            receiver
        );
    }

    /**
     * @notice Used to finalise the pool with the required attributes and operations
     *
     * @dev Checks, pool is finalised, caller is controller, supplied token balance
     * should be equal
     * @dev Binds the token, and its leverage and balance
     * @dev Calculates the iniyial pool supply, mints and transfer to the controller
     *
     * @param _primaryBalance Balance amount of primary token
     * @param _primaryLeverage Leverage value of primary token
     * @param _complementBalance  Balance amount of complement token
     * @param _complementLeverage  Leverage value of complement token
     * @param _exposureLimitPrimary TODO: Need to check this
     * @param _exposureLimitComplement TODO: Need to check this
     * @param _pMin TODO: Need to check this
     * @param _qMin TODO: Need to check this
     */
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
        require(!_finalized, 'VolmexAMM: AMM is finalized');

        require(_primaryBalance == _complementBalance, 'VolmexAMM: Assets balance should be same');

        require(baseFee > 0, 'VolmexAMM: baseFee should be larger than 0');

        pMin = _pMin;
        qMin = _qMin;
        exposureLimitPrimary = _exposureLimitPrimary;
        exposureLimitComplement = _exposureLimitComplement;

        _finalized = true;

        _bind(0, address(protocol.volatilityToken()), _primaryBalance, _primaryLeverage);
        _bind(
            1,
            address(protocol.inverseVolatilityToken()),
            _complementBalance,
            _complementLeverage
        );

        uint256 initPoolSupply = getDerivativeDenomination() * _primaryBalance;

        uint256 collateralDecimals = uint256(protocol.collateral().decimals());
        if (collateralDecimals >= 0 && collateralDecimals < 18) {
            initPoolSupply = initPoolSupply * (10**(18 - collateralDecimals));
        }

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(msg.sender, initPoolSupply);
    }

    /**
     * @notice Sets all type of fees
     *
     * @dev Checks the contract is finalised and caller is controller of the pool
     *
     * @param _baseFee Fee of the pool contract
     * @param _maxFee Max fee of the pool while swap
     * @param _feeAmpPrimary Fee on the primary token
     * @param _feeAmpComplement Fee on the complement token
     */
    function setFeeParams(
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement
    ) internal _logs_ _lock_ onlyNotSettled {
        baseFee = _baseFee;
        maxFee = _maxFee;
        feeAmpPrimary = _feeAmpPrimary;
        feeAmpComplement = _feeAmpComplement;

        emit LOG_SET_FEE_PARAMS(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);
    }

    function getTokenAmountOut(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut
    ) external view returns (uint256 tokenAmountOut) {
        Record memory inRecord = _records[tokenIn];
        Record memory outRecord = _records[tokenOut];

        (,,uint256 estPrice) = repricer.reprice(volatilityIndex);

        uint256 leveragesMultiplied = mul(
            inRecord.leverage,
            outRecord.leverage
        );

        inRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    div(
                        mul(leveragesMultiplied, mul(outRecord.balance, estPrice)),
                        inRecord.balance
                    )
                )
            )
        );
        outRecord.leverage = div(leveragesMultiplied, inRecord.leverage);

        tokenAmountOut = calcOutGivenIn(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            tokenAmountIn,
            0
        );

        (uint256 fee, ) = calcFee(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut,
            _getPrimaryDerivativeAddress() == tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        tokenAmountOut = calcOutGivenIn(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            tokenAmountIn,
            fee
        );
    }

    /**
     * @notice Used to calculate the leverage of primary and complement token
     *
     * @dev checks if the repricing block is same, returns for true
     * @dev Fetches the est price of primary, complement and averaged
     * @dev Calculates the primary and complement leverage
     */
    function _reprice() internal virtual {
        if (repricingBlock == block.number) return;
        repricingBlock = block.number;

        Record storage primaryRecord = _records[_getPrimaryDerivativeAddress()];
        Record storage complementRecord = _records[_getComplementDerivativeAddress()];

        uint256 estPricePrimary;
        uint256 estPriceComplement;
        uint256 estPrice;
        (estPricePrimary, estPriceComplement, estPrice) = repricer.reprice(volatilityIndex);

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

    function _performSwap(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 spotPriceBefore,
        uint256 fee,
        address receiver
    ) internal returns (uint256 spotPriceAfter) {
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];

        // TODO: Need to understand this and it's sub/used method
        _requireBoundaryConditions(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut,
            _getPrimaryDerivativeAddress() == tokenIn
                ? exposureLimitPrimary
                : exposureLimitComplement
        );

        _updateLeverages(inRecord, tokenAmountIn, outRecord, tokenAmountOut);

        inRecord.balance = add(inRecord.balance, tokenAmountIn);
        outRecord.balance = sub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            _getLeveragedBalance(inRecord),
            _getLeveragedBalance(outRecord),
            0
        );

        // spotPriceAfter will remain larger, becasue after swap, the out token
        // balance will decrease. equation -> leverageBalance(inToken) / leverageBalance(outToken)
        require(spotPriceAfter >= spotPriceBefore, 'VolmexAMM: Amount max in ratio exploit');
        // spotPriceBefore will remain smaller, because tokenAmountOut will be smaller than tokenAmountIn
        // because of the fee and oracle price.
        require(
            spotPriceBefore <= div(tokenAmountIn, tokenAmountOut),
            'VolmexAMM: Amount in max in ratio exploit other'
        );

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

        address holder = receiver == address(0) ? msg.sender : receiver;
        _pullUnderlying(tokenIn, holder, tokenAmountIn);
        _pushUnderlying(tokenOut, holder, tokenAmountOut);
    }

    function _getLeveragedBalance(Record memory r) internal pure returns (uint256) {
        return mul(r.balance, r.leverage);
    }

    function _requireBoundaryConditions(
        Record storage inToken,
        uint256 tokenAmountIn,
        Record storage outToken,
        uint256 tokenAmountOut,
        uint256 exposureLimit
    ) internal view {
        require(
            sub(_getLeveragedBalance(outToken), tokenAmountOut) > qMin,
            'VolmexAMM: Leverage boundary exploit'
        );
        require(
            sub(outToken.balance, tokenAmountOut) > qMin,
            'VolmexAMM: Non leverage boundary exploit'
        );

        uint256 lowerBound = div(pMin, sub(upperBoundary, pMin));
        uint256 upperBound = div(sub(upperBoundary, pMin), pMin);
        uint256 value = div(
            add(_getLeveragedBalance(inToken), tokenAmountIn),
            sub(_getLeveragedBalance(outToken), tokenAmountOut)
        );

        require(lowerBound < value, 'VolmexAMM: Lower boundary');
        require(value < upperBound, 'VolmexAMM: Upper boundary');

        (uint256 numerator, bool sign) = subSign(
            add(add(inToken.balance, tokenAmountIn), tokenAmountOut),
            outToken.balance
        );

        if (!sign) {
            uint256 denominator = sub(
                add(add(inToken.balance, tokenAmountIn), outToken.balance),
                tokenAmountOut
            );

            require(div(numerator, denominator) < exposureLimit, 'VolmexAMM: Exposure boundary');
        }
    }

    function _updateLeverages(
        Record memory inToken,
        uint256 tokenAmountIn,
        Record memory outToken,
        uint256 tokenAmountOut
    ) internal pure {
        outToken.leverage = div(
            sub(_getLeveragedBalance(outToken), tokenAmountOut),
            sub(outToken.balance, tokenAmountOut)
        );
        require(outToken.leverage > 0, 'VolmexAMM: Out token leverage can not be zero');

        inToken.leverage = div(
            add(_getLeveragedBalance(inToken), tokenAmountIn),
            add(inToken.balance, tokenAmountIn)
        );
        require(inToken.leverage > 0, 'VolmexAMM: In token leverage can not be zero');
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
        IVolmexController(controller).transferAssetToPool(
            IERC20Modified(erc20),
            from,
            address(this),
            amount
        );

        bool success;
        //solium-disable-next-line security/no-inline-assembly
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
        require(success, 'VolmexAMM: Token transfer failed');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(erc20).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, 'VolmexAMM: Token transfer overflow met');
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
        //solium-disable-next-line security/no-inline-assembly
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
        require(success, 'VolmexAMM: Token out transfer failed');
    }

    /**
     * @notice Used to bind the token, and its leverage and balance
     *
     * @dev This method will transfer the provided assets balance to pool from controller
     */
    function _bind(
        uint256 index,
        address token,
        uint256 balance,
        uint256 leverage
    ) internal {
        require(balance >= qMin, 'VolmexAMM: Unsatisfied min balance supplied');
        require(leverage > 0, 'VolmexAMM: Token leverage should be greater than 0');

        _records[token] = Record({ leverage: leverage, balance: balance });

        _tokens[index] = token;

        _pullUnderlying(token, msg.sender, balance);
    }

    function _spow3(int256 _value) internal pure returns (int256) {
        return (((_value * _value) / iBONE) * _value) / iBONE;
    }

    function _calcExpEndFee(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _expEnd
    ) internal pure returns (int256) {
        int256 inBalanceLeveraged = _getLeveragedBalanceOfFee(_inRecord[0], _inRecord[1]);
        int256 tokenAmountIn1 = (inBalanceLeveraged * (_outRecord[0] - _inRecord[0])) /
            (inBalanceLeveraged + _getLeveragedBalanceOfFee(_outRecord[0], _outRecord[1]));

        int256 inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int256 tokenAmountIn2 = (inBalanceLeveragedChanged *
            (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2])) /
            (inBalanceLeveragedChanged +
                _getLeveragedBalanceOfFee(_outRecord[0], _outRecord[1]) -
                _outRecord[2] *
                iBONE);

        return
            (tokenAmountIn1 *
                _baseFee +
                tokenAmountIn2 *
                (_baseFee + (_feeAmp * ((_expEnd * _expEnd) / iBONE)) / 3)) /
            (tokenAmountIn1 + tokenAmountIn2);
    }

    function _getLeveragedBalanceOfFee(int256 _balance, int256 _leverage)
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

        int256 _expEnd = ((_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE) /
            (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if (expStart >= 0) {
            fee =
                _baseFee +
                (((_feeAmp) * (_spow3(_expEnd) - _spow3(expStart))) * iBONE) /
                (3 * (_expEnd - expStart));
        } else if (_expEnd <= 0) {
            fee = _baseFee;
        } else {
            fee = _calcExpEndFee(_inRecord, _outRecord, _baseFee, _feeAmp, _expEnd);
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
    ) internal view returns (uint256 fee, int256 expStart) {
        int256 ifee;
        (ifee, expStart) = calc(
            [int256(inRecord.balance), int256(inRecord.leverage), int256(tokenAmountIn)],
            [int256(outRecord.balance), int256(outRecord.leverage), int256(tokenAmountOut)],
            int256(baseFee),
            int256(feeAmp),
            int256(maxFee)
        );
        require(ifee > 0, 'VolmexAMM: Fee should be greater than 0');
        fee = uint256(ifee);
    }

    function calcExpStart(int256 _inBalance, int256 _outBalance) internal pure returns (int256) {
        return ((_inBalance - _outBalance) * iBONE) / (_inBalance + _outBalance);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == type(IVolmexAMM).interfaceId;
    }

    /**
     * @notice Used to calculate the out amount after fee deduction
     */
    function calculateAmountOut(
        uint256 _poolAmountIn,
        uint256 _ratio,
        uint256 _tokenReserve
    ) internal view returns (uint256 amountOut) {
        uint256 tokenAmount = mul(div(_poolAmountIn, upperBoundary), BONE);
        amountOut = mul(_ratio, _tokenReserve);
        if (amountOut > tokenAmount) {
            uint256 feeAmount = mul(tokenAmount, div(adminFee, 10000));
            amountOut = sub(amountOut, feeAmount);
        }
    }

    /**
     * @notice Used to puase the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Used to unpause the contract, if paused
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Used to check the pool is finalized
     */
    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    /**
     * @notice Used to get the token addresses
     */
    function getTokens() external view _viewlock_ returns (address[BOUND_TOKENS] memory tokens) {
        return _tokens;
    }

    /**
     * @notice Used to get the leverage of provided token address
     *
     * @param token Address of the token, either primary or complement
     */
    function getLeverage(address token) external view _viewlock_ returns (uint256) {
        return _records[token].leverage;
    }

    /**
     * @notice Used to get the balance of provided token address
     *
     * @param token Address of the token. either primary or complement
     */
    function getBalance(address token) external view _viewlock_ returns (uint256) {
        return _records[token].balance;
    }

    function getPrimaryDerivativeAddress() external view returns (address) {
        return _getPrimaryDerivativeAddress();
    }

    function getComplementDerivativeAddress() external view returns (address) {
        return _getComplementDerivativeAddress();
    }

    function getDerivativeDenomination() internal view returns (uint256) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
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

import "../BokkyPooBahsDateTimeLibrary/BokkyPooBahsDateTimeLibrary.sol";

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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '../../maths/Num.sol';

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
    bool public isLayer2;
    address public childChainManager;

    modifier _isOnLayer2() {
        require(isLayer2, "Token: cannot call function");
        _;
    }

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

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external _isOnLayer2 {
        require(msg.sender == childChainManager, "Token: you are not authoized");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(amount);
        _push(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external _isOnLayer2 {
        _pull(msg.sender, amount);
        _burn(amount);
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './Num.sol';

contract Math is Const, Num {
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

import '@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol';

interface IVolmexRepricer is IERC165Upgradeable {
    function protocolVolatilityCapRatio() external view returns (uint256);

    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );

    function sqrtWrapped(int256 value) external pure returns (int256);
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol';

import '../libs/tokens/Token.sol';
import './IVolmexProtocol.sol';
import './IVolmexRepricer.sol';

interface IVolmexAMM is IERC20, IERC165Upgradeable {
    function repricingBlock() external view returns (uint256);

    function baseFee() external view returns (uint256);

    function feeAmpPrimary() external view returns (uint256);

    function feeAmpComplement() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function pMin() external view returns (uint256);

    function qMin() external view returns (uint256);

    function exposureLimitPrimary() external view returns (uint256);

    function exposureLimitComplement() external view returns (uint256);

    function protocol() external view returns (IVolmexProtocol);

    function repricer() external view returns (IVolmexRepricer);

    function isFinalized() external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getTokens() external view returns (address[] memory tokens);

    function getLeverage(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getPrimaryDerivativeAddress() external view returns (address);

    function getComplementDerivativeAddress() external view returns (address);

    function joinPool(uint256 poolAmountOut, uint256[2] calldata maxAmountsIn, address receiver) external;

    function exitPool(uint256 poolAmountIn, uint256[2] calldata minAmountsOut, address receiver) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        address receiver
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function paused() external view returns (bool);

    function transferOwnership(address newOwner) external;

    function setController(address controller) external;

    function flashLoan(
        address receiverAddress,
        address assetToken,
        uint256 amount,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

import './IERC20Modified.sol';
import './IVolmexAMM.sol';

interface IFlashLoanReceiver {
    function POOL() external returns (IVolmexAMM);

    function executeOperation(
        address assetToken,
        uint256 amounts,
        uint256 premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

import './IERC20Modified.sol';

interface IVolmexController {
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        address _pool,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: BUSL-1.1

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
// SPDX-License-Identifier: BUSL-1.1

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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

contract Const {
    uint256 public constant BONE = 10**18;
    int256 public constant iBONE = int256(BONE);

    uint256 public constant MIN_POW_BASE = 1 wei;
    uint256 public constant MAX_POW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant POW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;

    uint256 public constant VOLATILITY_PRICE_PRECISION = 10**4;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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