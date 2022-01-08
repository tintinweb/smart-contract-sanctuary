// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol';

import './libs/tokens/TokenMetadataGenerator.sol';
import './libs/tokens/Token.sol';
import './maths/Math.sol';
import './interfaces/IEIP20NonStandard.sol';
import './interfaces/IVolmexRepricer.sol';
import './interfaces/IVolmexProtocol.sol';
import './interfaces/IVolmexPool.sol';
import './interfaces/IFlashLoanReceiver.sol';
import './interfaces/IVolmexController.sol';

/**
 * @title Volmex Pool Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexPool is
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC165StorageUpgradeable,
    Token,
    Math,
    TokenMetadataGenerator,
    IVolmexPool
{
    // Interface ID of VolmexRepricer contract
    bytes4 private constant _IVOLMEX_REPRICER_ID = type(IVolmexRepricer).interfaceId;
    // Interface ID of VolmexPool contract
    bytes4 private constant _IVOLMEX_POOL_ID = type(IVolmexPool).interfaceId;
    // Interface ID of VolmexController contract
    bytes4 private constant _IVOLMEX_CONTROLLER_ID = type(IVolmexController).interfaceId;
    // Number of tokens the pool can hold
    uint256 private constant _BOUND_TOKENS = 2;

    // Used to prevent the re-entry
    bool private _mutex;
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool public finalized;
    // Address of the pool tokens
    address[_BOUND_TOKENS] public tokens;

    // This is mapped by token addresses
    mapping(address => Record) public records;

    // Address of the pool controller
    IVolmexController public controller;
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
    // Minimum amount of tokens in the pool
    uint256 public pMin;
    // Minimum amount of token required for swap
    uint256 public qMin;
    // Difference in the primary token amount while swapping with the complement token
    uint256 public exposureLimitPrimary;
    // Difference in the complement token amount while swapping with the primary token
    uint256 public exposureLimitComplement;
    // The amount of collateral required to mint both the volatility tokens
    uint256 public denomination;
    // Address of the volmex repricer contract
    IVolmexRepricer public repricer;
    // Address of the volmex protocol contract
    IVolmexProtocol public protocol;
    // Number value of the volatility token index at oracle { 0 - ETHV, 1 - BTCV }
    uint256 public volatilityIndex;
    // Percentage of fee deducted for admin
    uint256 public adminFee;
    // Percentage of fee deducted for flash loan
    uint256 public flashLoanPremium;

    /**
     * @notice Used to log the callee's sig, address and data
     */
    modifier logs() {
        emit Called(msg.sig, msg.sender, msg.data);
        _;
    }

    /**
     * @notice Used to prevent the re-entry
     */
    modifier lock() {
        require(!_mutex, 'VolmexPool: REENTRY');
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @notice Used to prevent multiple call to view methods
     */
    modifier viewlock() {
        require(!_mutex, 'VolmexPool: REENTRY');
        _;
    }

    /**
     * @notice Used to check the pool is finalised
     */
    modifier onlyFinalized() {
        require(finalized, 'VolmexPool: Pool is not finalized');
        _;
    }

    /**
     * @notice Used to check the protocol is not settled
     */
    modifier onlyNotSettled() {
        require(!protocol.isSettled(), 'VolmexPool: Protocol is settled');
        _;
    }

    /**
     * @notice Used to check the caller is controller
     */
    modifier onlyController() {
        require(msg.sender == address(controller), 'VolmexPool: Caller is not controller');
        _;
    }

    /**
     * @notice Initialize the pool contract with required elements
     *
     * @dev Checks, the protocol is a contract
     * @dev Sets repricer, protocol and controller addresses
     * @dev Sets upperBoundary, volatilityIndex and denomination
     * @dev Make the Pool token name and symbol
     *
     * @param _repricer Address of the volmex repricer contract
     * @param _protocol Address of the volmex protocol contract
     * @param _volatilityIndex Index of the volatility price in oracle
     * @param _baseFee Fee of the pool contract
     * @param _maxFee Max fee of the pool while swap
     * @param _feeAmpPrimary Fee on the primary token
     * @param _feeAmpComplement Fee on the complement token
     *
     * NOTE: The baseFee is set 0.02 * 10^18 currently, and it can only be set once. Be cautious
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
            IERC165Upgradeable(address(_repricer)).supportsInterface(_IVOLMEX_REPRICER_ID),
            'VolmexPool: Repricer does not supports interface'
        );
        require(address(_protocol) != address(0), "VolmexPool: protocol address can't be zero");

        repricer = _repricer;
        protocol = _protocol;
        upperBoundary = protocol.volatilityCapRatio() * BONE;
        volatilityIndex = _volatilityIndex;
        denomination = protocol.volatilityCapRatio();
        adminFee = 30;
        flashLoanPremium = 9;
        tokens[0] = address(protocol.volatilityToken());
        tokens[1] = address(protocol.inverseVolatilityToken());

        _setName(_makeTokenName(protocol.volatilityToken().name(), protocol.collateral().name()));
        _setSymbol(
            _makeTokenSymbol(protocol.volatilityToken().symbol(), protocol.collateral().symbol())
        );

        _setFeeParams(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);

        __Ownable_init();
        __Pausable_init_unchained(); // Used this, because ownable init is calling context init
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_POOL_ID);
    }

    /**
     * @notice Set controller of the Pool
     *
     * @param _controller Address of the pool contract controller
     */
    function setController(IVolmexController _controller) external onlyOwner {
        require(
            IERC165Upgradeable(address(_controller)).supportsInterface(_IVOLMEX_CONTROLLER_ID),
            'VolmexPool: Not Controller'
        );
        controller = _controller;

        emit ControllerSet(address(controller));
    }

    /**
     * @notice Used to update the flash loan premium percent
     */
    function updateFlashLoanPremium(uint256 _premium) external onlyOwner {
        require(_premium > 0 && _premium <= 10000, 'VolmexPool: _premium value not in range');
        flashLoanPremium = _premium;

        emit FlashLoanPremiumUpdated(flashLoanPremium);
    }

    /**
     * @notice Used to finalise the pool with the required attributes and operations
     *
     * @dev Checks, pool is finalised, caller is owner, supplied token balance
     * should be equal
     * @dev Binds the token, and its leverage and balance
     * @dev Calculates the initial pool supply, mints and transfer to the controller
     *
     * @param _primaryBalance Balance amount of primary token
     * @param _primaryLeverage Leverage value of primary token
     * @param _complementBalance  Balance amount of complement token
     * @param _complementLeverage  Leverage value of complement token
     * @param _exposureLimitPrimary Primary to complement swap difference limit
     * @param _exposureLimitComplement Complement to primary swap difference limit
     * @param _pMin Minimum amount of tokens in the pool
     * @param _qMin Minimum amount of token required for swap
     */
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external logs lock onlyNotSettled onlyController {
        require(!finalized, 'VolmexPool: Pool is finalized');

        require(
            _primaryBalance == _complementBalance,
            'VolmexPool: Assets balance should be same'
        );

        require(baseFee > 0, 'VolmexPool: baseFee should be larger than 0');

        pMin = _pMin;
        qMin = _qMin;
        exposureLimitPrimary = _exposureLimitPrimary;
        exposureLimitComplement = _exposureLimitComplement;

        finalized = true;

        _bind(
            address(protocol.volatilityToken()),
            _primaryBalance,
            _primaryLeverage,
            _receiver
        );
        _bind(
            address(protocol.inverseVolatilityToken()),
            _complementBalance,
            _complementLeverage,
            _receiver
        );

        uint256 initPoolSupply = denomination * _primaryBalance;

        uint256 collateralDecimals = uint256(protocol.collateral().decimals());
        if (collateralDecimals < 18) {
            initPoolSupply = initPoolSupply * (10**(18 - collateralDecimals));
        }

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(_receiver, initPoolSupply);
    }

    /**
     * @notice Used to get flash loan
     *
     * @dev Decrease the token amount from the record before transfer
     * @dev Calculate the premium (fee) on the flash loan
     * @dev Check if executor is valid
     * @dev Increase the token amount of the record after pulling
     *
     * @param _receiverAddress Address of the receiver contract
     * @param _assetToken Address of the token required.
     * NOTE: For invalid asset token the records balance subtraction will throw underflow
     * @param _amount Amount of token required
     * @param _params msg.data value passed in the method, eg `0x10`
     */
    function flashLoan(
        address _receiverAddress,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params
    ) external lock whenNotPaused onlyController {
        records[_assetToken].balance = records[_assetToken].balance - _amount;
        IERC20Modified(_assetToken).transfer(_receiverAddress, _amount);

        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiverAddress);
        uint256 premium = _div(_mul(_amount, flashLoanPremium), 10000);

        require(
            receiver.executeOperation(_assetToken, _amount, premium, _params),
            'VolmexPool: Invalid flash loan executor'
        );

        uint256 amountWithPremium = _amount + premium;

        IERC20Modified(_assetToken).transferFrom(
            _receiverAddress,
            address(this),
            amountWithPremium
        );

        records[_assetToken].balance = records[_assetToken].balance + amountWithPremium;

        emit Loaned(_receiverAddress, _assetToken, _amount, premium);
    }

    /**
     * @notice Used to add liquidity to the pool
     *
     * @dev The token amount in of the pool will be calculated and pulled from LP
     *
     * @param _poolAmountOut Amount of pool token mint and transfer to LP
     * @param _maxAmountsIn Max amount of pool assets an LP can supply
     */
    function joinPool(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        address _receiver
    ) external logs lock onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = _div(_poolAmountOut, poolTotal);
        require(ratio != 0, 'VolmexPool: Invalid math approximation');

        for (uint256 i = 0; i < _BOUND_TOKENS; i++) {
            address token = tokens[i];
            uint256 bal = records[token].balance;
            // This can't be tested, as the div method will fail, due to zero supply of lp token
            // The supply of lp token is greater than zero, means token reserve is greater than zero
            // Also, in the case of swap, there's some amount of tokens available pool more than qMin
            require(bal > 0, 'VolmexPool: Insufficient balance in Pool');
            uint256 tokenAmountIn = _mul(ratio, bal);
            require(tokenAmountIn <= _maxAmountsIn[i], 'VolmexPool: Amount in limit exploit');
            records[token].balance = records[token].balance + tokenAmountIn;
            emit Joined(_receiver, token, tokenAmountIn);
            _pullUnderlying(token, _receiver, tokenAmountIn);
        }

        _mintPoolShare(_poolAmountOut);
        _pushPoolShare(_receiver, _poolAmountOut);
    }

    /**
     * @notice Used to remove liquidity from the pool
     *
     * @dev The token amount out of the pool will be calculated and pushed to LP,
     * and pool token are pulled and burned
     *
     * @param _poolAmountIn Amount of pool token transfer to the pool
     * @param _minAmountsOut Min amount of pool assets an LP wish to redeem
     */
    function exitPool(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        address _receiver
    ) external logs lock onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = _div(_poolAmountIn, poolTotal);
        require(ratio != 0, 'VolmexPool: Invalid math approximation');

        for (uint256 i = 0; i < _BOUND_TOKENS; i++) {
            address token = tokens[i];
            uint256 bal = records[token].balance;
            require(bal > 0, 'VolmexPool: Insufficient balance in Pool');
            uint256 tokenAmountOut = _calculateAmountOut(
                _poolAmountIn,
                ratio,
                bal,
                upperBoundary,
                adminFee
            );
            require(tokenAmountOut >= _minAmountsOut[i], 'VolmexPool: Amount out limit exploit');
            records[token].balance = records[token].balance - tokenAmountOut;
            emit Exited(_receiver, token, tokenAmountOut);
            _pushUnderlying(token, _receiver, tokenAmountOut);
        }

        _pullPoolShare(_receiver, _poolAmountIn);
        _burnPoolShare(_poolAmountIn);
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
     * @param _tokenIn Address of the pool asset which the user supply
     * @param _tokenAmountIn Amount of asset the user supply
     * @param _tokenOut Address of the pool asset which the user wants
     * @param _minAmountOut Minimum amount of asset the user wants
     * @param _receiver Address of the contract/user from tokens are pulled
     * @param _toController Bool value, if `true` push to controller, else to `_receiver`
     */
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    )
        external
        logs
        lock
        whenNotPaused
        onlyFinalized
        onlyNotSettled
        onlyController
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(_tokenIn != _tokenOut, 'VolmexPool: Passed same token addresses');
        require(_tokenAmountIn >= qMin, 'VolmexPool: Amount in quantity should be larger');

        reprice();

        Record memory inRecord = records[_tokenIn];
        Record memory outRecord = records[_tokenOut];

        require(
            _tokenAmountIn <=
                _mul(_min(getLeveragedBalance(inRecord), inRecord.balance), MAX_IN_RATIO),
            'VolmexPool: Amount in max ratio exploit'
        );

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            0
        );

        uint256 fee = _calcFee(
            inRecord,
            _tokenAmountIn,
            outRecord,
            tokenAmountOut,
            tokens[0] == _tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            fee
        );
        require(tokenAmountOut >= _minAmountOut, 'VolmexPool: Amount out limit exploit');

        uint256 _spotPriceBefore = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            0
        );

        spotPriceAfter = _performSwap(
            _tokenIn,
            _tokenAmountIn,
            _tokenOut,
            tokenAmountOut,
            _spotPriceBefore,
            fee,
            _receiver,
            _toController
        );
    }

    /**
     * @notice Used to pause the contract
     */
    function pause() external onlyController {
        _pause();
    }

    /**
     * @notice Used to unpause the contract, if paused
     */
    function unpause() external onlyController {
        _unpause();
    }

    /**
     * @notice getter, used to fetch the token amount out and fee
     *
     * @param _tokenIn Address of the token in
     * @param _tokenAmountIn Amount of in token
     */
    function getTokenAmountOut(address _tokenIn, uint256 _tokenAmountIn)
        external
        view
        returns (uint256 tokenAmountOut, uint256 fee)
    {
        (Record memory inRecord, Record memory outRecord) = _getRepriced(_tokenIn);

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            0
        );

        fee = _calcFee(
            inRecord,
            _tokenAmountIn,
            outRecord,
            tokenAmountOut,
            tokens[0] == _tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            fee
        );
    }

    /**
     * @notice Used to get the leverage of provided token address
     *
     * @param _token Address of the token, either primary or complement
     *
     * Can't remove this method, because struct of this contract can't be fetched in controller contract.
     * We will need to unpack the struct.
     */
    function getLeverage(address _token) external view viewlock returns (uint256) {
        return records[_token].leverage;
    }

    /**
     * @notice Used to get the balance of provided token address
     *
     * @param _token Address of the token. either primary or complement
     */
    function getBalance(address _token) external view viewlock returns (uint256) {
        return records[_token].balance;
    }

    /**
     * @notice Used to calculate the leverage of primary and complement token
     *
     * @dev checks if the repricing block is same, returns for true
     * @dev Fetches the est price of primary, complement and averaged
     * @dev Calculates the primary and complement leverage
     */
    function reprice() public {
        if (repricingBlock == block.number) return;
        repricingBlock = block.number;

        Record storage primaryRecord = records[tokens[0]];
        Record storage complementRecord = records[tokens[1]];

        uint256 estPricePrimary;
        uint256 estPriceComplement;
        uint256 estPrice;
        (estPricePrimary, estPriceComplement, estPrice) = repricer.reprice(volatilityIndex);

        uint256 primaryRecordLeverageBefore = primaryRecord.leverage;
        uint256 complementRecordLeverageBefore = complementRecord.leverage;

        uint256 leveragesMultiplied = _mul(
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore
        );

        primaryRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    _div(
                        _mul(leveragesMultiplied, _mul(complementRecord.balance, estPrice)),
                        primaryRecord.balance
                    )
                )
            )
        );
        complementRecord.leverage = _div(leveragesMultiplied, primaryRecord.leverage);
        emit Repriced(
            repricingBlock,
            primaryRecord.balance,
            complementRecord.balance,
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore,
            primaryRecord.leverage,
            complementRecord.leverage,
            estPricePrimary,
            estPriceComplement
        );
    }

    function getLeveragedBalance(Record memory r) public pure returns (uint256) {
        return _mul(r.balance, r.leverage);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     * This will revert due to insufficient balance or insufficient allowance.
     * This function returns the actual amount received,
     * which may be less than `amount` if there is a fee attached to the transfer.
     * @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     * See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _pullUnderlying(
        address _erc20,
        address _from,
        uint256 _amount
    ) internal virtual returns (uint256) {
        uint256 balanceBefore = IERC20(_erc20).balanceOf(address(this));
        controller.transferAssetToPool(IERC20Modified(_erc20), _from, _amount);

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
        require(success, 'VolmexPool: Token transfer failed');

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(_erc20).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, 'VolmexPool: Token transfer overflow met');
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getRepriced(address _tokenIn)
        private
        view
        returns (Record memory inRecord, Record memory outRecord)
    {
        Record memory primaryRecord = records[tokens[0]];
        Record memory complementRecord = records[tokens[1]];

        (, , uint256 estPrice) = repricer.reprice(volatilityIndex);

        uint256 primaryRecordLeverageBefore = primaryRecord.leverage;
        uint256 complementRecordLeverageBefore = complementRecord.leverage;

        uint256 leveragesMultiplied = _mul(
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore
        );

        primaryRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    _div(
                        _mul(leveragesMultiplied, _mul(complementRecord.balance, estPrice)),
                        primaryRecord.balance
                    )
                )
            )
        );
        complementRecord.leverage = _div(leveragesMultiplied, primaryRecord.leverage);

        inRecord = tokens[0] == _tokenIn ? primaryRecord : complementRecord;
        outRecord = tokens[1] == _tokenIn ? primaryRecord : complementRecord;
    }

    function _calcFee(
        Record memory _inRecord,
        uint256 _tokenAmountIn,
        Record memory _outRecord,
        uint256 _tokenAmountOut,
        uint256 _feeAmp
    ) private view returns (uint256 fee) {
        int256 ifee;
        (ifee, ) = _calc(
            [int256(_inRecord.balance), int256(_inRecord.leverage), int256(_tokenAmountIn)],
            [int256(_outRecord.balance), int256(_outRecord.leverage), int256(_tokenAmountOut)],
            int256(baseFee),
            int256(_feeAmp),
            int256(maxFee)
        );
        require(ifee > 0, 'VolmexPool: Fee should be greater than 0');
        fee = uint256(ifee);
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
    function _setFeeParams(
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement
    ) private logs lock onlyNotSettled {
        baseFee = _baseFee;
        maxFee = _maxFee;
        feeAmpPrimary = _feeAmpPrimary;
        feeAmpComplement = _feeAmpComplement;

        emit FeeParamsSet(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);
    }

    function _performSwap(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _spotPriceBefore,
        uint256 _fee,
        address _receiver,
        bool _toController
    ) private returns (uint256 spotPriceAfter) {
        Record storage inRecord = records[_tokenIn];
        Record storage outRecord = records[_tokenOut];

        _requireBoundaryConditions(
            inRecord,
            _tokenAmountIn,
            outRecord,
            _tokenAmountOut,
            tokens[0] == _tokenIn ? exposureLimitPrimary : exposureLimitComplement
        );

        _updateLeverages(inRecord, _tokenAmountIn, outRecord, _tokenAmountOut);

        inRecord.balance = inRecord.balance + _tokenAmountIn;
        outRecord.balance = outRecord.balance - _tokenAmountOut;

        spotPriceAfter = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            0
        );

        // spotPriceAfter will remain larger, becasue after swap, the out token
        // balance will decrease. equation -> leverageBalance(_inToken) / leverageBalance(outToken)
        require(spotPriceAfter >= _spotPriceBefore, 'VolmexPool: Amount max in ratio exploit');
        // _spotPriceBefore will remain smaller, because _tokenAmountOut will be smaller than _tokenAmountIn
        // because of the fee and oracle price.
        require(
            _spotPriceBefore <= _div(_tokenAmountIn, _tokenAmountOut),
            'VolmexPool: Amount in max in ratio exploit other'
        );

        emit Swapped(
            _tokenIn,
            _tokenOut,
            _tokenAmountIn,
            _tokenAmountOut,
            _fee,
            inRecord.balance,
            outRecord.balance,
            inRecord.leverage,
            outRecord.leverage
        );

        _pullUnderlying(_tokenIn, _receiver, _tokenAmountIn);
        _pushUnderlying(
            _tokenOut,
            _toController ? address(controller) : _receiver,
            _tokenAmountOut
        );
    }

    function _requireBoundaryConditions(
        Record storage _inToken,
        uint256 _tokenAmountIn,
        Record storage _outToken,
        uint256 _tokenAmountOut,
        uint256 _exposureLimit
    ) private view {
        require(
            getLeveragedBalance(_outToken) - _tokenAmountOut > qMin,
            'VolmexPool: Leverage boundary exploit'
        );
        require(
            _outToken.balance - _tokenAmountOut > qMin,
            'VolmexPool: Non leverage boundary exploit'
        );

        uint256 lowerBound = _div(pMin, upperBoundary - pMin);
        uint256 upperBound = _div(upperBoundary - pMin, pMin);
        uint256 value = _div(
            getLeveragedBalance(_inToken) + _tokenAmountIn,
            getLeveragedBalance(_outToken) - _tokenAmountOut
        );

        require(lowerBound < value, 'VolmexPool: Lower boundary');
        require(value < upperBound, 'VolmexPool: Upper boundary');

        (uint256 numerator, bool sign) = _subSign(
            _inToken.balance + _tokenAmountIn + _tokenAmountOut,
            _outToken.balance
        );

        if (!sign) {
            uint256 denominator = (_inToken.balance + _tokenAmountIn + _outToken.balance) -
                _tokenAmountOut;

            require(_div(numerator, denominator) < _exposureLimit, 'VolmexPool: Exposure boundary');
        }
    }

    function _updateLeverages(
        Record storage _inToken,
        uint256 _tokenAmountIn,
        Record storage _outToken,
        uint256 _tokenAmountOut
    ) private {
        _outToken.leverage = _div(
            getLeveragedBalance(_outToken) - _tokenAmountOut,
            _outToken.balance - _tokenAmountOut
        );
        require(_outToken.leverage > 0, 'VolmexPool: Out token leverage can not be zero');

        _inToken.leverage = _div(
            getLeveragedBalance(_inToken) + _tokenAmountIn,
            _inToken.balance + _tokenAmountIn
        );
        require(_inToken.leverage > 0, 'VolmexPool: In token leverage can not be zero');
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     * error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     * insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     * it is >= amount, this should not revert in normal conditions.
     * @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     * See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _pushUnderlying(
        address _erc20,
        address _to,
        uint256 _amount
    ) private {
        IEIP20NonStandard(_erc20).transfer(_to, _amount);

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
        require(success, 'VolmexPool: Token out transfer failed');
    }

    /**
     * @notice Used to bind the token, and its leverage and balance
     *
     * @dev This method will transfer the provided assets balance to pool from controller
     */
    function _bind(
        address _token,
        uint256 _balance,
        uint256 _leverage,
        address _receiver
    ) private {
        require(_balance >= qMin, 'VolmexPool: Unsatisfied min balance supplied');
        require(_leverage > 0, 'VolmexPool: Token leverage should be greater than 0');

        records[_token] = Record({ leverage: _leverage, balance: _balance });

        _pullUnderlying(_token, _receiver, _balance);
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `lock` or otherwise ensure reentry-safety

    function _pullPoolShare(address _from, uint256 _amount) private {
        _pull(_from, _amount);
    }

    function _pushPoolShare(address _to, uint256 _amount) private {
        _push(_to, _amount);
    }

    function _mintPoolShare(uint256 _amount) private {
        _mint(_amount);
    }

    function _burnPoolShare(uint256 _amount) private {
        _burn(_amount);
    }

    function _spow3(int256 _value) private pure returns (int256) {
        return (((_value * _value) / iBONE) * _value) / iBONE;
    }

    function _calcExpEndFee(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _expEnd
    ) private pure returns (int256) {
        int256 inBalanceLeveraged = _inRecord[0] * _inRecord[1];
        int256 tokenAmountIn1 = (inBalanceLeveraged * (_outRecord[0] - _inRecord[0])) /
            (inBalanceLeveraged + (_outRecord[0] * _outRecord[1]));

        int256 inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int256 tokenAmountIn2 = (inBalanceLeveragedChanged *
            (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2])) /
            (inBalanceLeveragedChanged + (_outRecord[0] * _outRecord[1]) - _outRecord[2] * iBONE);

        return
            (tokenAmountIn1 *
                _baseFee +
                tokenAmountIn2 *
                (_baseFee + (_feeAmp * ((_expEnd * _expEnd) / iBONE)) / 3)) /
            (tokenAmountIn1 + tokenAmountIn2);
    }

    function _calc(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _maxFee
    ) private pure returns (int256 fee, int256 expStart) {
        expStart = _calcExpStart(_inRecord[0], _outRecord[0]);

        int256 _expEnd = ((_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE) /
            (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if (expStart >= 0) {
            fee =
                _baseFee +
                (_feeAmp * (_spow3(_expEnd) - _spow3(expStart))) /
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

    function _calcExpStart(int256 _inBalance, int256 _outBalance) private pure returns (int256) {
        return ((_inBalance - _outBalance) * iBONE) / (_inBalance + _outBalance);
    }

    uint256[10] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

pragma solidity =0.8.11;

contract TokenMetadataGenerator {
    function _formatMeta(
        string memory _prefix,
        string memory _concatenator,
        string memory _postfix
    ) internal pure returns (string memory) {
        return _concat(_prefix, _concat(_concatenator, _postfix));
    }

    function _makeTokenName(string memory _baseName, string memory _postfix)
        internal
        pure
        returns (string memory)
    {
        return _formatMeta(_baseName, ' ', _postfix);
    }

    function _makeTokenSymbol(string memory _baseName, string memory _postfix)
        internal
        pure
        returns (string memory)
    {
        return _formatMeta(_baseName, '-', _postfix);
    }

    function _concat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../../maths/Num.sol';
import '../../interfaces/IERC20.sol';

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed _src, address indexed _dst, uint256 _amt);
    event Transfer(address indexed _src, address indexed _dst, uint256 _amt);

    function _mint(uint256 _amt) internal {
        _balance[address(this)] = _balance[address(this)] + _amt;
        _totalSupply = _totalSupply + _amt;
        emit Transfer(address(0), address(this), _amt);
    }

    function _burn(uint256 _amt) internal {
        require(_balance[address(this)] >= _amt, 'INSUFFICIENT_BAL');
        _balance[address(this)] = _balance[address(this)] - _amt;
        _totalSupply = _totalSupply - _amt;
        emit Transfer(address(this), address(0), _amt);
    }

    function _move(
        address _src,
        address _dst,
        uint256 _amt
    ) internal {
        require(_balance[_src] >= _amt, 'INSUFFICIENT_BAL');
        _balance[_src] = _balance[_src] - _amt;
        _balance[_dst] = _balance[_dst] + _amt;
        emit Transfer(_src, _dst, _amt);
    }

    function _push(address _to, uint256 _amt) internal {
        _move(address(this), _to, _amt);
    }

    function _pull(address _from, uint256 _amt) internal {
        _move(_from, address(this), _amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function approve(address _dst, uint256 _amt) external override returns (bool) {
        _allowance[msg.sender][_dst] = _amt;
        emit Approval(msg.sender, _dst, _amt);
        return true;
    }

    function increaseApproval(address _dst, uint256 _amt) external returns (bool) {
        _allowance[msg.sender][_dst] = _allowance[msg.sender][_dst] + _amt;
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function decreaseApproval(address _dst, uint256 _amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][_dst];
        if (_amt > oldValue) {
            _allowance[msg.sender][_dst] = 0;
        } else {
            _allowance[msg.sender][_dst] = oldValue - _amt;
        }
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function transfer(address _dst, uint256 _amt) external override returns (bool) {
        _move(msg.sender, _dst, _amt);
        return true;
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[_src][msg.sender];
        require(msg.sender == _src || _amt <= oldValue, 'TOKEN_BAD_CALLER');
        _move(_src, _dst, _amt);
        if (msg.sender != _src && oldValue != type(uint128).max) {
            _allowance[_src][msg.sender] = oldValue - _amt;
            emit Approval(msg.sender, _dst, _allowance[_src][msg.sender]);
        }
        return true;
    }

    function allowance(address _src, address _dst) external view override returns (uint256) {
        return _allowance[_src][_dst];
    }

    function balanceOf(address _whom) external view override returns (uint256) {
        return _balance[_whom];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _setName(string memory _poolName) internal {
        _name = _poolName;
    }

    function _setSymbol(string memory _poolSymbol) internal {
        _symbol = _poolSymbol;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './Num.sol';

contract Math is Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                 bI          1                                         //
    // bO = tokenBalanceOut         sP =  ----  *  ----------                                    //
    // sF = swapFee                        bO      ( 1 - sF )                                    //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 ratio = _div(_tokenBalanceIn, _tokenBalanceOut);
        uint256 scale = _div(BONE, BONE - _swapFee);
        spotPrice = _mul(ratio, scale);
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \   \                 //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  |  |                 //
    // sF = swapFee                     \      \ ( bI + ( aI * ( 1 - sF )) /   /                 //
    **********************************************************************************************/
    function _calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256 tokenAmountOut) {
        uint256 adjustedIn = BONE - _swapFee;
        adjustedIn = _mul(_tokenAmountIn, adjustedIn);
        uint256 y = _div(_tokenBalanceIn, _tokenBalanceIn + adjustedIn);
        uint256 bar = BONE - y;
        tokenAmountOut = _mul(_tokenBalanceOut, bar);
    }

    /**
     * @notice Used to calculate the out amount after fee deduction
     */
    function _calculateAmountOut(
        uint256 _poolAmountIn,
        uint256 _ratio,
        uint256 _tokenReserve,
        uint256 _upperBoundary,
        uint256 _adminFee
    ) internal pure returns (uint256 amountOut) {
        uint256 tokenAmount = _mul(_div(_poolAmountIn, _upperBoundary), BONE);
        amountOut = _mul(_ratio, _tokenReserve);
        if (amountOut > tokenAmount) {
            uint256 feeAmount = _div(_mul(tokenAmount, _adminFee), 10000);
            amountOut = amountOut - feeAmount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

/*
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 * See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);
    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /** 
    *
    * !!!!!!!!!!!!!!
    * !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    * !!!!!!!!!!!!!!
    *
    * @notice Transfer `amount` tokens from `msg.sender` to `dst`
    * @param dst The address of the destination account
    * @param amount The number of tokens to transfer
    */
    function transfer(address dst, uint256 amount) external;
    /** 
    *
    * !!!!!!!!!!!!!!
    * !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    * !!!!!!!!!!!!!!
    *
    * @notice Transfer `amount` tokens from `src` to `dst`
    * @param src The address of the source account
    * @param dst The address of the destination account
    * @param amount The number of tokens to transfer
    */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;
    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);
    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexOracle.sol';

interface IVolmexRepricer {
    // Getter method
    function oracle() external view returns (IVolmexOracle);

    // Setter methods
    function sqrtWrapped(int256 value) external pure returns (int256);
    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
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
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../libs/tokens/Token.sol';
import './IVolmexProtocol.sol';
import './IVolmexRepricer.sol';
import './IVolmexController.sol';

interface IVolmexPool is IERC20 {
    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    event Swapped(
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
    event Joined(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
    event Exited(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
    event Repriced(
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
    event Called(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event Loaned(
        address indexed target,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );
    event FlashLoanPremiumUpdated(uint256 premium);
    event ControllerSet(address indexed controller);
    event FeeParamsSet(
        uint256 baseFee,
        uint256 maxFee,
        uint256 feeAmpPrimary,
        uint256 feeAmpComplement
    );

    // Getter methods
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
    function volatilityIndex() external view returns (uint256);
    function finalized() external view returns (bool);
    function upperBoundary() external view returns (uint256);
    function adminFee() external view returns (uint256);
    function getLeverage(address _token) external view returns (uint256);
    function getBalance(address _token) external view returns (uint256);
    function tokens(uint256 _index) external view returns (address);
    function flashLoanPremium() external view returns (uint256);
    function getLeveragedBalance(Record memory r) external pure returns (uint256);
    function getTokenAmountOut(
        address _tokenIn,
        uint256 _tokenAmountIn
    ) external view returns (uint256, uint256);

    // Setter methods
    function setController(IVolmexController _controller) external;
    function updateFlashLoanPremium(uint256 _premium) external;
    function joinPool(uint256 _poolAmountOut, uint256[2] calldata _maxAmountsIn, address _receiver) external;
    function exitPool(uint256 _poolAmountIn, uint256[2] calldata _minAmountsOut, address _receiver) external;
    function pause() external;
    function unpause() external;
    function reprice() external;
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    ) external returns (uint256, uint256);
    function flashLoan(
        address _receiverAddress,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params
    ) external;
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexPool.sol';

interface IFlashLoanReceiver {
    function executeOperation(
        address assetToken,
        uint256 amounts,
        uint256 premiums,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';
import './IVolmexPool.sol';
import './IPausablePool.sol';
import './IVolmexProtocol.sol';
import './IVolmexOracle.sol';

interface IVolmexController {
    event AdminFeeUpdated(uint256 adminFee);
    event CollateralSwapped(
        uint256 volatilityInAmount,
        uint256 collateralOutAmount,
        uint256 protocolFee,
        uint256 poolFee,
        uint256 indexed stableCoinIndex,
        address indexed token
    );
    event PoolSwapped(
        uint256 volatilityInAmount,
        uint256 volatilityOutAmount,
        uint256 protocolFee,
        uint256[2] poolFee,
        uint256 indexed stableCoinIndex,
        address[2] tokens
    );
    event PoolAdded(uint256 indexed poolIndex, address indexed pool);
    event StableCoinAdded(uint256 indexed stableCoinIndex, address indexed stableCoin);
    event ProtocolAdded(uint256 poolIndex, uint256 stableCoinIndex, address indexed protocol);
    event PoolTokensCollected(address indexed owner, uint256 amount);

    // Getter methods
    function stableCoinIndex() external view returns (uint256);
    function poolIndex() external view returns (uint256);
    function pools(uint256 _index) external view returns (IVolmexPool);
    function stableCoins(uint256 _index) external view returns (IERC20Modified);
    function isPool(address _pool) external view returns (bool);
    function oracle() external view returns (IVolmexOracle);
    function protocols(
        uint256 _poolIndex,
        uint256 _stableCoinIndex
    ) external view returns (IVolmexProtocol);

    // Setter methods
    function addPool(IVolmexPool _pool) external;
    function addStableCoin(IERC20Modified _stableCoin) external;
    function pausePool(IPausablePool _pool) external;
    function unpausePool(IPausablePool _pool) external;
    function collect(IVolmexPool _pool) external;
    function addProtocol(
        uint256 _poolIndex,
        uint256 _stableCoinIndex,
        IVolmexProtocol _protocol
    ) external;
    function swapCollateralToVolatility(
        uint256[2] calldata _amounts,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external;
    function swapVolatilityToCollateral(
        uint256[2] calldata _amounts,
        uint256[2] calldata _indices,
        IERC20Modified _tokenIn
    ) external;
    function swapBetweenPools(
        address[2] calldata _tokens,
        uint256[2] calldata _amounts,
        uint256[3] calldata _indices
    ) external;
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external;
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external;
    function makeFlashLoan(
        address _receiver,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params,
        uint256 _poolIndex
    ) external;
    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external;
    function getCollateralToVolatility(
        uint256 _collateralAmount,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external view returns (uint256, uint256[2] memory);
    function getVolatilityToCollateral(
        address _tokenIn,
        uint256 _amount,
        uint256[2] calldata _indices,
        bool _isInverse
    ) external view returns (uint256, uint256[2] memory);
    function getSwapAmountBetweenPools(
        address[2] calldata _tokens,
        uint256 _amountIn,
        uint256[3] calldata _indices
    ) external view returns (uint256, uint256[3] memory);
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './Const.sol';

contract Num is Const {
    function _subSign(uint256 _a, uint256 _b) internal pure returns (uint256, bool) {
        if (_a >= _b) {
            return (_a - _b, false);
        } else {
            return (_b - _a, true);
        }
    }

    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        uint256 c0 = _a * _b;
        uint256 c1 = c0 + (BONE / 2);
        c = c1 / BONE;
    }

    function _div(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, 'DIV_ZERO');
        uint256 c0 = _a * BONE;
        uint256 c1 = c0 + (_b / 2);
        c = c1 / _b;
    }

    function _min(uint256 _first, uint256 _second) internal pure returns (uint256) {
        if (_first < _second) {
            return _first;
        }
        return _second;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _whom) external view returns (uint256);
    function allowance(address _src, address _dst) external view returns (uint256);
    function approve(address _dst, uint256 _amt) external returns (bool);
    function transfer(address _dst, uint256 _amt) external returns (bool);
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

contract Const {
    uint256 public constant BONE = 10**18;

    int256 public constant iBONE = int256(BONE);

    uint256 public constant MAX_IN_RATIO = BONE / 2;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexProtocol.sol';

interface IVolmexOracle {
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );

    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );

    event SymbolIndexUpdated(uint256 indexed _index);

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function indexCount() external view returns (uint256);

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (uint256, uint256);
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (uint256 volatilityTokenPrice, uint256 iVolatilityTokenPrice);
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IPausablePool {
    // Getter method
    function paused() external view returns (bool);

    // Setter methods
    function pause() external;
    function unpause() external;
}