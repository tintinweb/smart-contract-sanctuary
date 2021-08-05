pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './Address.sol';
import './ACOAssetHelper.sol';
import './ERC20.sol';
import './IACOFactory.sol';
import './IACOAssetConverterHelper.sol';
import './IACOToken.sol';
import './IChiToken.sol';
import './IACOPoolStrategy.sol';
import './IACOPool2.sol';

/**
 * @title ACOPool2
 * @dev A pool contract to trade ACO tokens.
 * 
 * The SC errors are defined as code to shrunk the SC bytes size and work around the EIP170.
 * The codes are explained in the table below:
 ********************************************************************************************
 * CODE | FUNCTION                            | DESCRIPTION						            *
 *------------------------------------------------------------------------------------------*
 * E00  | init                                | SC is already initialized                   *
 *------------------------------------------------------------------------------------------*
 * E01  | init                                | Invalid ACO Factory address                 *
 *------------------------------------------------------------------------------------------*
 * E02  | init                                | Invalid Chi Token address                   *
 *------------------------------------------------------------------------------------------*
 * E03  | init                                | Underlying and strike asset are the same    *
 *------------------------------------------------------------------------------------------*
 * E04  | init                                | Invalid underlying address                  *
 *------------------------------------------------------------------------------------------*
 * E05  | init                                | Invalid strike asset address                *
 *------------------------------------------------------------------------------------------*
 * E10  | _deposit                            | Invalid collateral amount                   *
 *------------------------------------------------------------------------------------------*
 * E11  | _deposit                            | Invalid destination address                 *
 *------------------------------------------------------------------------------------------*
 * E12  | _deposit                            | The minimum shares were not satisfied       *
 *------------------------------------------------------------------------------------------*
 * E20  | _withdrawWithLocked                 | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E30  | _withdrawNoLocked                   | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E31  | _withdrawNoLocked                   | Collateral balance is not sufficient        *
 *------------------------------------------------------------------------------------------*
 * E32  | _withdrawNoLocked                   | The minimum collateral was not satisfied    *
 *------------------------------------------------------------------------------------------*
 * E33  | _withdrawNoLocked                   | Collateral balance is not sufficient        *
 *------------------------------------------------------------------------------------------*
 * E34  | _withdrawNoLocked                   | Collateral balance is not sufficient        *
 *------------------------------------------------------------------------------------------*
 * E40  | _swap                               | Swap deadline reached                       *
 *------------------------------------------------------------------------------------------*
 * E41  | _swap                               | Invalid destination address                 *
 *------------------------------------------------------------------------------------------*
 * E42  | _internalSelling                    | The maximum payment restriction was reached *
 *------------------------------------------------------------------------------------------*
 * E43  | _internalSelling                    | The maximum number of open ACOs was reached *
 *------------------------------------------------------------------------------------------*
 * E50  | _quote                              | Invalid token amount                        *
 *------------------------------------------------------------------------------------------*
 * E51  | _quote                              | Invalid ACO token                           *
 *------------------------------------------------------------------------------------------*
 * E52  | _quote                              | Invalid ACO token expiration                *
 *------------------------------------------------------------------------------------------*
 * E53  | _quote                              | Invalid ACO token strike price              *
 *------------------------------------------------------------------------------------------*
 * E54  | _quote                              | ACO token expired                           *
 *------------------------------------------------------------------------------------------*
 * E55  | _internalQuote                      | Invalid quoted price                        *
 *------------------------------------------------------------------------------------------*
 * E56  | _getSizeData                        | The token amount is too small               *
 *------------------------------------------------------------------------------------------*
 * E57  | _getSizeData                        | Insufficient liquidity                      *
 *------------------------------------------------------------------------------------------*
 * E60  | restoreCollateral                   | No balance to restore                       *
 *------------------------------------------------------------------------------------------*
 * E80  | withdrawStuckToken                  | The token is forbidden to withdraw          *
 *------------------------------------------------------------------------------------------*
 * E81  | _setStrategy                        | Invalid strategy address                    *
 *------------------------------------------------------------------------------------------*
 * E82  | _setBaseVolatility                  | Invalid base volatility                     *
 *------------------------------------------------------------------------------------------*
 * E83  | _setAssetConverter                  | Invalid asset converter address             *
 *------------------------------------------------------------------------------------------*
 * E84  | _setAssetConverter                  | No price on the Oracle                      *
 *------------------------------------------------------------------------------------------*
 * E85  | _setTolerancePriceAbove             | Invalid above tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E86  | _setTolerancePriceBelow             | Invalid below tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E87  | _setMinExpiration                   | Invalid minimum seconds for expiration      *
 *------------------------------------------------------------------------------------------*
 * E88  | _setMaxExpiration                   | Invalid maximum seconds for expiration      *
 *------------------------------------------------------------------------------------------*
 * E89  | _setFeeDestination                  | Invalid fee destination address             *
 *------------------------------------------------------------------------------------------*
 * E90  | onlyFactory                         | Only the pool factory can call the method   *
 *------------------------------------------------------------------------------------------*
 * E91  | _setFee                             | Invalid fee value                           *
 *------------------------------------------------------------------------------------------*
 * E92  | _setWithdrawOpenPositionPenalty     | Invalid penalty percentage                  *
 *------------------------------------------------------------------------------------------*
 * E93  | _setUnderlyingPriceAdjustPercentage | Invalid underlying price adjust percentage  *
 *------------------------------------------------------------------------------------------*
 * E94  | _setMaximumOpenAco                  | Invalid maximum number of open ACOs allowed *
 ********************************************************************************************
 */
contract ACOPool2 is Ownable, ERC20, IACOPool2 {
    using Address for address;
    
    uint256 internal constant PERCENTAGE_PRECISION = 100000;
    uint256 internal constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	/**
     * @dev Emitted when the asset converter address has been changed.
     * @param oldAssetConverter Address of the previous asset converter.
     * @param newAssetConverter Address of the new asset converter.
     */
    event SetAssetConverter(address indexed oldAssetConverter, address indexed newAssetConverter);
	
	/**
     * @dev Emitted when the above tolerance price has been changed.
     * @param oldTolerancePriceAbove Value of the previous above tolerance price.
     * @param newTolerancePriceAbove Value of the new above tolerance price.
     */
    event SetTolerancePriceAbove(uint256 indexed oldTolerancePriceAbove, uint256 indexed newTolerancePriceAbove);
	
	/**
     * @dev Emitted when the below tolerance price has been changed.
     * @param oldTolerancePriceBelow Value of the previous below tolerance price.
     * @param newTolerancePriceBelow Value of the new below tolerance price.
     */
    event SetTolerancePriceBelow(uint256 indexed oldTolerancePriceBelow, uint256 indexed newTolerancePriceBelow);
	
	/**
     * @dev Emitted when the minimum expiration has been changed.
     * @param oldMinExpiration Value of the previous minimum expiration.
     * @param newMinExpiration Value of the new minimum expiration.
     */
    event SetMinExpiration(uint256 indexed oldMinExpiration, uint256 indexed newMinExpiration);
	
	/**
     * @dev Emitted when the maximum expiration has been changed.
     * @param oldMaxExpiration Value of the previous maximum expiration.
     * @param newMaxExpiration Value of the new maximum expiration.
     */
    event SetMaxExpiration(uint256 indexed oldMaxExpiration, uint256 indexed newMaxExpiration);
	
	/**
     * @dev Emitted when the penalty percentage on withdrawing open positions has been changed.
     * @param oldWithdrawOpenPositionPenalty Value of the previous penalty percentage on withdrawing open positions.
     * @param newWithdrawOpenPositionPenalty Value of the new penalty percentage on withdrawing open positions.
     */
	event SetWithdrawOpenPositionPenalty(uint256 indexed oldWithdrawOpenPositionPenalty, uint256 indexed newWithdrawOpenPositionPenalty);
	
	/**
     * @dev Emitted when the underlying price percentage adjust has been changed.
     * @param oldUnderlyingPriceAdjustPercentage Value of the previous underlying price percentage adjust.
     * @param newUnderlyingPriceAdjustPercentage Value of the new underlying price percentage adjust.
     */
	event SetUnderlyingPriceAdjustPercentage(uint256 indexed oldUnderlyingPriceAdjustPercentage, uint256 indexed newUnderlyingPriceAdjustPercentage);
	
    /**
     * @dev Emitted when the number of maximum open ACOs allowed has been changed.
     * @param oldMaximumOpenAco Value of the previous maximum number of open ACOs allowed.
     * @param newMaximumOpenAco Value of the new maximum number of open ACOs allowed.
     */
	event SetMaximumOpenAco(uint256 indexed oldMaximumOpenAco, uint256 indexed newMaximumOpenAco);
	
	/**
     * @dev Emitted when the fee has been changed.
     * @param oldFee Value of the previous fee.
     * @param newFee Value of the new fee.
     */
    event SetFee(uint256 indexed oldFee, uint256 indexed newFee);
	
	/**
     * @dev Emitted when the fee destination has been changed.
     * @param oldFeeDestination Address of the previous fee destination.
     * @param newFeeDestination Address of the new fee destination.
     */
    event SetFeeDestination(address indexed oldFeeDestination, address indexed newFeeDestination);
	
	/**
     * @dev Emitted when an valid creator permission has been changed.
	 * @param creator Address of the creator.
     * @param previousPermission Value of the previous permission.
     * @param newPermission Value of the new permission.
     */
    event SetValidAcoCreator(address indexed creator, bool indexed previousPermission, bool indexed newPermission);
	
	/**
     * @dev Emitted when the strategy address has been changed.
     * @param oldStrategy Address of the previous strategy.
     * @param newStrategy Address of the new strategy.
     */
	event SetStrategy(address indexed oldStrategy, address indexed newStrategy);
	
	/**
     * @dev Emitted when the base volatility has been changed.
     * @param oldBaseVolatility Value of the previous base volatility.
     * @param newBaseVolatility Value of the new base volatility.
     */
    event SetBaseVolatility(uint256 indexed oldBaseVolatility, uint256 indexed newBaseVolatility);
	
	/**
     * @dev Emitted when the collateral has been restored on the pool.
     * @param amountOut Amount of the premium sold.
     * @param collateralRestored Amount of collateral restored.
     */
    event RestoreCollateral(uint256 amountOut, uint256 collateralRestored);
	
	/**
     * @dev Emitted when an ACO token has been redeemed.
     * @param acoToken Address of the ACO token.
     * @param valueSold Total amount sold by the pool.
     * @param collateralLocked Total amount of collateral locked.
     * @param collateralRedeemed Total amount of collateral redeemed.
     */
	event ACORedeem(address indexed acoToken, uint256 valueSold, uint256 collateralLocked, uint256 collateralRedeemed);
	
	/**
     * @dev Emitted when a collateral has been deposited on the pool.
     * @param account Address of the account.
	 * @param shares Amount of the shares minted.
     * @param collateralAmount Collateral amount deposited.
     */
    event Deposit(address indexed account, uint256 shares, uint256 collateralAmount);
	
	/**
     * @dev Emitted when an account has been withdrawn from the pool.
     * @param account Address of the account.
	 * @param shares Amount of the shares withdrawn.
	 * @param noLocked TRUE if the withdrawal request is with NO locked collateral, otherwise FALSE.
     * @param underlyingWithdrawn Amount of underlying withdrawn.
	 * @param strikeAssetWithdrawn Amount of strike asset withdrawn.
	 * @param acos Array of ACOs addresses with locked collateral transferred.
	 * @param acosAmount Array of amount of ACOs with locked collateral transferred.
     */
    event Withdraw(
		address indexed account, 
		uint256 shares, 
		bool noLocked, 
		uint256 underlyingWithdrawn, 
		uint256 strikeAssetWithdrawn, 
		address[] acos, 
		uint256[] acosAmount
	);
	
	/**
     * @dev Emitted when an ACO token has been sold by the pool.
     * @param account Address of the account that is doing the swap.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens swapped.
     * @param price Value of the premium paid in strike asset.
     * @param protocolFee Value of the protocol fee paid in strike asset.
     * @param underlyingPrice The underlying price in strike asset.
	 * @param volatility The volatility used on the option price calculation.
     */
	event Swap(
        address indexed account, 
        address indexed acoToken, 
        uint256 tokenAmount, 
        uint256 price, 
        uint256 protocolFee,
        uint256 underlyingPrice,
		uint256 volatility
    );

	/**
	 * @dev Address of the ACO factory contract.
	 */
    IACOFactory public acoFactory;
	
	/**
	 * @dev Address of the Chi gas token.
	 */
	IChiToken public chiToken;
	
	/**
	 * @dev Address of the underlying asset accepts by the pool.
	 */
    address public underlying;
	
	/**
	 * @dev Address of the strike asset accepts by the pool.
	 */
    address public strikeAsset;
	
	/**
	 * @dev True whether the pool accepts CALL options, otherwise the pool accepts only PUT options. 
	 */
    bool public isCall;
    
	/**
	 * @dev Address of the asset converter helper.
	 */
    IACOAssetConverterHelper public assetConverter;
	
	/**
	 * @dev Address of the strategy. 
	 */
	IACOPoolStrategy public strategy;
	
	/**
	 * @dev Address of the protocol fee destination.
	 */
	address public feeDestination;
	
	/**
	 * @dev Percentage value for the base volatility. (100000 = 100%) 
	 */
    uint256 public baseVolatility;
	
	/**
	 * @dev Percentage value for the above tolerance on the current price. Zero is ignored. (100000 = 100%) 
	 */
    uint256 public tolerancePriceAbove;
	
	/**
	 * @dev Percentage value for the below tolerance on the current price. Zero is ignored. (100000 = 100%) 
	 */
    uint256 public tolerancePriceBelow;
	
	/**
	 * @dev Minimum expiration seconds after current time to the pool accepts an ACO based on its expiry time. 
	 */
    uint256 public minExpiration;
	
	/**
	 * @dev Maximum expiration seconds after current time to the pool accepts an ACO based on its expiry time. 
	 */
    uint256 public maxExpiration;
	
	/**
	 * @dev The protocol fee percentage. (100000 = 100%)
	 */
    uint256 public fee;
	
	/**
	 * @dev Percentage value for the penalty percentage on withdrawing open positions. (100000 = 100%)
	 */
	uint256 public withdrawOpenPositionPenalty;
	
	/**
	 * @dev Percentage value for the underlying price adjust. (100000 = 100%)
	 */
	uint256 public underlyingPriceAdjustPercentage;

    /**
	 * @dev Maximum number of open ACOs allowed.
	 */
	uint256 public maximumOpenAco;
	
	/**
	 * @dev Array of ACO tokens negotiated.  
	 */
    address[] public acoTokens;
	
	/**
	 * @dev Array of ACO tokens negotiated and currently active.  
	 */
    address[] public openAcos;
	
	/**
	 * @dev Mapping for the valid ACO creators allowed by th pool.  
	 */
    mapping(address => bool) public validAcoCreators;
	
	/**
	 * @dev Mapping for ACO tokens data negotiated.  
	 */
    mapping(address => AcoData) public acoData;
	
	/**
	 * @dev Underlying asset precision. (18 decimals = 1000000000000000000)
	 */
	uint256 internal underlyingPrecision;
    
	/**
     * @dev Modifier to apply the Chi gas token and save gas.
     */
	modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
	
    /**
     * @dev Function to initialize the contract.
     * It should be called by the ACO pool factory when creating the pool.
     * It must be called only once. The first `require` is to guarantee that behavior.
     * @param initData The initialize data.
     */
    function init(InitData calldata initData) external override {
		require(underlying == address(0) && strikeAsset == address(0), "E00");
        
        require(initData.acoFactory.isContract(), "E01");
        require(initData.chiToken.isContract(), "E02");
        require(initData.underlying != initData.strikeAsset, "E03");
        require(ACOAssetHelper._isEther(initData.underlying) || initData.underlying.isContract(), "E04");
        require(ACOAssetHelper._isEther(initData.strikeAsset) || initData.strikeAsset.isContract(), "E05");
        
        super.init();

        acoFactory = IACOFactory(initData.acoFactory);
        chiToken = IChiToken(initData.chiToken);
        underlying = initData.underlying;
        strikeAsset = initData.strikeAsset;
        isCall = initData.isCall;
		
        _setAssetConverter(initData.assetConverter);
        _setFee(initData.fee);
        _setFeeDestination(initData.feeDestination);
		_setWithdrawOpenPositionPenalty(initData.withdrawOpenPositionPenalty);
		_setUnderlyingPriceAdjustPercentage(initData.underlyingPriceAdjustPercentage);
        _setMaximumOpenAco(initData.maximumOpenAco);
        _setMaxExpiration(initData.maxExpiration);
        _setMinExpiration(initData.minExpiration);
        _setTolerancePriceAbove(initData.tolerancePriceAbove);
        _setTolerancePriceBelow(initData.tolerancePriceBelow);
        _setStrategy(initData.strategy);
        _setBaseVolatility(initData.baseVolatility);
		
		underlyingPrecision = 10 ** uint256(ACOAssetHelper._getAssetDecimals(initData.underlying));
    }

    receive() external payable {
    }

    /**
     * @dev Function to get the token name.
     */
    function name() public override view returns(string memory) {
        return _name();
    }
	
    /**
     * @dev Function to get the token symbol, that it is equal to the name.
     */
	function symbol() public override view returns(string memory) {
        return _name();
    }

	/**
     * @dev Function to get the token decimals.
     */
    function decimals() public override view returns(uint8) {
        return ACOAssetHelper._getAssetDecimals(collateral());
    }

	/**
     * @dev Function to get the number of ACO tokens negotiated.
     */
    function numberOfAcoTokensNegotiated() external view override returns(uint256) {
        return acoTokens.length;
    }

	/**
     * @dev Function to get the number of ACO tokens negotiated and currently active.
     */
    function numberOfOpenAcoTokens() external view override returns(uint256) {
        return openAcos.length;
    }
	
	/**
     * @dev Function to get the pool collateral asset.
     */
	function collateral() public view override returns(address) {
        if (isCall) {
            return underlying;
        } else {
            return strikeAsset;
        }
    }

	/**
     * @dev Function to get whether the pool can swap an ACO token.
	 * @param acoToken Address of the ACO token.
	 * @return TRUE whether it is possible, otherwise FALSE.
     */
    function canSwap(address acoToken) external view override returns(bool) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime) = acoFactory.acoTokenData(acoToken);
		if (_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall) && _acoExpirationIsValid(_expiryTime)) {
            uint256 price = assetConverter.getPrice(_underlying, _strikeAsset);
            return _acoStrikePriceIsValid(_strikePrice, price);
        }
        return false;
    }
	
	/**
     * @dev Function to quote an ACO token swap.
     * @param acoToken Address of the ACO token.
     * @param tokenAmount Amount of ACO tokens to swap.
     * @return swapPrice The swap price
     * protocolFee the protocol fee charged on the swap
     * underlyingPrice the underlying price in strike asset 
     * volatility the volatility used on the option price calculation.
     */
	function quote(address acoToken, uint256 tokenAmount) external view override returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility
    ) {
        (swapPrice, protocolFee, underlyingPrice, volatility,) = _quote(acoToken, tokenAmount);
    }
	
    /**
     * @dev Function to get the shares for a collateral amount on deposit.
     * @param collateralAmount Amount of collateral to be deposited.
     * @return The shares to be received on the deposit.
     */
	function getDepositShares(uint256 collateralAmount) external view override returns(uint256) {
        return _getDepositShares(collateralAmount);
    }

	/**
     * @dev Function to get the withdrawal data for a shares amount considering that there is NO locked collateral on the operation.
     * @param shares Amount of shares to be withdrawn.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * isPossible TRUE whether it is possible to withdraw from that way (NO locked) or FALSE otherwise.
     */
	function getWithdrawNoLockedData(uint256 shares) external view override returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
    ) {
        (underlyingWithdrawn, strikeAssetWithdrawn, isPossible) = _getWithdrawNoLockedData(shares);
    }
	
	/**
     * @dev Function to get the withdrawal data for a shares amount considering that there is locked collateral on the operation.
     * @param shares Amount of shares to be withdrawn.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * acos addresses of the ACOs with locked collateral that will be transferred
     * acosAmount the respective ACOs amount to be transferred.
     */
	function getWithdrawWithLocked(uint256 shares) external view override returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
    ) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _getWithdrawWithLocked(shares);
    }

	/**
     * @dev Function to set the asset converter address.
	 * Only can be called by the pool factory.
     * @param newAssetConverter Address of the new asset converter.
     */
    function setAssetConverter(address newAssetConverter) external override {
        onlyFactory();
        _setAssetConverter(newAssetConverter);
    }

	/**
     * @dev Function to set the percentage of the below price tolerance.
	 * Only can be called by the pool factory.
     * @param newTolerancePriceBelow Value of the new below price tolerance.
     */
    function setTolerancePriceBelow(uint256 newTolerancePriceBelow) external override {
        onlyFactory();
        _setTolerancePriceBelow(newTolerancePriceBelow);
    }

	/**
     * @dev Function to set the percentage of the above price tolerance.
	 * Only can be called by the pool factory.
     * @param newTolerancePriceAbove Value of the new above price tolerance.
     */
    function setTolerancePriceAbove(uint256 newTolerancePriceAbove) external override {
        onlyFactory();
        _setTolerancePriceAbove(newTolerancePriceAbove);
    }

	/**
     * @dev Function to set the minimum expiration seconds after current time to the pool accepts an ACO based on its expiry time.
	 * Only can be called by the pool factory.
     * @param newMinExpiration Value of the new minimum expiration.
     */
    function setMinExpiration(uint256 newMinExpiration) external override {
        onlyFactory();
        _setMinExpiration(newMinExpiration);
    }

	/**
     * @dev Function to set the maximum expiration seconds after current time to the pool accepts an ACO based on its expiry time.
	 * Only can be called by the pool factory.
     * @param newMaxExpiration Value of the new maximum expiration.
     */
    function setMaxExpiration(uint256 newMaxExpiration) external override {
        onlyFactory();
        _setMaxExpiration(newMaxExpiration);
    }
    
	/**
     * @dev Function to set the protocol fee percentage.
	 * Only can be called by the pool factory.
     * @param newFee Value of the new protocol fee.
     */
    function setFee(uint256 newFee) external override {
        onlyFactory();
        _setFee(newFee);
    }
    
	/**
     * @dev Function to set the fee destination.
	 * Only can be called by the pool factory.
     * @param newFeeDestination Value of the new fee destination.
     */
    function setFeeDestination(address newFeeDestination) external override {
        onlyFactory();
        _setFeeDestination(newFeeDestination);
    }
	
	/**
     * @dev Function to set the penalty percentage on withdrawing open positions.
	 * Only can be called by the pool factory.
     * @param newWithdrawOpenPositionPenalty Value of the new penalty percentage on withdrawing open positions.
     */
	function setWithdrawOpenPositionPenalty(uint256 newWithdrawOpenPositionPenalty) external override {
        onlyFactory();
		_setWithdrawOpenPositionPenalty(newWithdrawOpenPositionPenalty);
	}
	
	/**
     * @dev Function to set the underlying price percentage adjust.
	 * Only can be called by the pool factory.
     * @param newUnderlyingPriceAdjustPercentage Value of the new underlying price percentage adjust.
     */
	function setUnderlyingPriceAdjustPercentage(uint256 newUnderlyingPriceAdjustPercentage) external override {
        onlyFactory();
		_setUnderlyingPriceAdjustPercentage(newUnderlyingPriceAdjustPercentage);
	}
	
    /**
     * @dev Function to set the  maximum number of open ACOs allowed.
	 * Only can be called by the pool factory.
     * @param newMaximumOpenAco Value of the new maximum number of open ACOs allowed.
     */
	function setMaximumOpenAco(uint256 newMaximumOpenAco) external override {
        onlyFactory();
		_setMaximumOpenAco(newMaximumOpenAco);
	}

	/**
     * @dev Function to set the strategy address.
	 * Only can be called by the pool factory.
     * @param newStrategy Address of the new strategy address.
     */
	function setStrategy(address newStrategy) external override {
        onlyFactory();
		_setStrategy(newStrategy);
	}
	
	/**
     * @dev Function to set the base volatility.
	 * Only can be called by the pool factory.
     * @param newBaseVolatility Value of the new base volatility.
     */
	function setBaseVolatility(uint256 newBaseVolatility) external override {
        onlyFactory();
		_setBaseVolatility(newBaseVolatility);
	}
	
	/**
     * @dev Function to set an valid creator permission.
	 * Only can be called by the pool factory.
     * @param newAcoCreator Address of the creator.
	 * @param newPermission Value of the new permission.
     */
	function setValidAcoCreator(address newAcoCreator, bool newPermission) external override {
        onlyFactory();
        _setValidAcoCreator(newAcoCreator, newPermission);
    }
	
	/**
     * @dev Function to withdraw a stucked token.
	 * Only can be called by the pool factory.
     * @param token Address of the token.
	 * @param destination Address of the token destination.
     */
    function withdrawStuckToken(address token, address destination) external override {
        onlyFactory();
        require(token != underlying && token != strikeAsset && !acoData[token].open, "E80");
        uint256 _balance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
        if (_balance > 0) {
            ACOAssetHelper._transferAsset(token, destination, _balance);
        }
    }

	/**
     * @dev Function to deposit on the pool.
     * @param collateralAmount Amount of collateral to be deposited.
     * @param minShares The minimum amount of shares acceptable.
     * @param to Address of the destination of the pool token.
     * @return The amount of pool tokens minted.
     */
	function deposit(uint256 collateralAmount, uint256 minShares, address to) external payable override returns(uint256) {
        return _deposit(collateralAmount, minShares, to);
    }
	
	/**
     * @dev Function to deposit on the pool using Chi gas token to saving gas.
     * @param collateralAmount Amount of collateral to be deposited.
     * @param minShares The minimum amount of shares acceptable.
     * @param to Address of the destination of the pool token.
     * @return The amount of pool tokens minted.
     */
	function depositWithGasToken(uint256 collateralAmount, uint256 minShares, address to) discountCHI external payable override returns(uint256) {
        return _deposit(collateralAmount, minShares, to);
    }

	/**
     * @dev Function to withdraw from the pool with NO locked collateral.
     * @param shares Amount of the account shares to be withdrawn.
     * @param minCollateral The minimum collateral amount acceptable on the withdrawal.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw.
     */
	function withdrawNoLocked(uint256 shares, uint256 minCollateral, address account) external override returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account);
    }
	
	/**
     * @dev Function to withdraw from the pool with NO locked collateral using Chi gas token to save gas.
     * @param shares Amount of the account shares to be withdrawn.
     * @param minCollateral The minimum collateral amount acceptable on the withdrawal.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw.
     */
	function withdrawNoLockedWithGasToken(uint256 shares, uint256 minCollateral, address account) discountCHI external override returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account);
    }
	
	/**
     * @dev Function to withdraw from the pool and transferring the locked collateral and the obligation to redeem it on the expiration.
     * @param shares Amount of the account shares to be withdrawn.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * acos addresses of the ACOs with locked collateral that will be transferred
     * acosAmount the respective ACOs amount to be transferred.
     */
    function withdrawWithLocked(uint256 shares, address account) external override returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account);
    }
	
	/**
     * @dev Function to withdraw from the pool and transferring the locked collateral and the obligation to redeem it on the expiration using Chi gas token to save gas.
     * @param shares Amount of the account shares to be withdrawn.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * acos addresses of the ACOs with locked collateral that will be transferred
     * acosAmount the respective ACOs amount to be transferred.
     */
	function withdrawWithLockedWithGasToken(uint256 shares, address account) discountCHI external override returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account);
    }
	
	/**
     * @dev Function to swap an ACO token with the pool.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction The maximum value to pay on the ACO purchase.
     * @param to Address of the destination of the ACO tokens.
     * @param deadline UNIX deadline for the swap to be executed.
     */
	function swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) external override {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }

	/**
     * @dev Function to swap an ACO token with the pool using Chi gas token to save gas.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction The maximum value to pay on the ACO purchase.
     * @param to Address of the destination of the ACO tokens.
     * @param deadline UNIX deadline for the swap to be executed.
     */
    function swapWithGasToken(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) discountCHI external override {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }
    
	/**
     * @dev Function to redeem the collateral from the active ACO tokens negotiated on the pool.
     * It redeems the collateral only if the respective ACO token is expired.
     */
    function redeemACOTokens() public override {
        for (uint256 i = openAcos.length; i > 0; --i) {
            address acoToken = openAcos[i - 1];
            _redeemACOToken(acoToken);
        }
    }

	/**
     * @dev Function to redeem the collateral from an ACO token.
     * It redeems the collateral only if the ACO token is expired.
     * @param acoToken Address of the ACO token.
     */
	function redeemACOToken(address acoToken) external override {
		_redeemACOToken(acoToken);
    }
	
	/**
     * @dev Function to restore the collateral on the pool by selling the other asset balance.
     */
	function restoreCollateral() external override {
        address _strikeAsset = strikeAsset;
        address _underlying = underlying;
        bool _isCall = isCall;
        
        uint256 balanceOut;
        address assetIn;
        address assetOut;
        if (_isCall) {
            balanceOut = _getPoolBalanceOf(_strikeAsset);
            assetIn = _underlying;
            assetOut = _strikeAsset;
        } else {
            balanceOut = _getPoolBalanceOf(_underlying);
            assetIn = _strikeAsset;
            assetOut = _underlying;
        }
        require(balanceOut > 0, "E60");
        
		uint256 etherAmount = 0;
        if (ACOAssetHelper._isEther(assetOut)) {
			etherAmount = balanceOut;
        }
        uint256 collateralRestored = assetConverter.swapExactAmountOut{value: etherAmount}(assetOut, assetIn, balanceOut);

        emit RestoreCollateral(balanceOut, collateralRestored);
    }

	/**
     * @dev Internal function to deposit on the pool.
     * @param collateralAmount Amount of collateral to be deposited.
     * @param minShares The minimum amount of shares acceptable.
     * @param to Address of the destination of the pool token.
     * @return shares The amount of pool tokens minted.
     */
	function _deposit(uint256 collateralAmount, uint256 minShares, address to) internal returns(uint256 shares) {
        require(collateralAmount > 0, "E10");
        require(to != address(0) && to != address(this), "E11");
		
		(,,uint256 collateralBalance, uint256 collateralOnOpenPosition,) = _getTotalCollateralBalance(true);
		collateralBalance = collateralBalance.sub(collateralOnOpenPosition);

		address _collateral = collateral();
		if (ACOAssetHelper._isEther(_collateral)) {
            collateralBalance = collateralBalance.sub(msg.value);
		}
        
        if (collateralBalance == 0) {
            shares = collateralAmount;
        } else {
            shares = collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
        require(shares >= minShares, "E12");

        ACOAssetHelper._receiveAsset(_collateral, collateralAmount);

        super._mintAction(to, shares);
        
        emit Deposit(to, shares, collateralAmount);
    }
	
	/**
     * @dev Internal function to get the withdrawal data for a shares amount considering that there is locked collateral on the operation.
     * @param shares Amount of shares to be withdrawn.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * acos addresses of the ACOs with locked collateral that will be transferred
     * acosAmount the respective ACOs amount to be transferred.
     */
	function _getWithdrawWithLocked(uint256 shares) internal view returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        uint256 _totalSupply = totalSupply();	
        if (shares > 0 && shares <= _totalSupply) {
        
			uint256 underlyingBalance = _getPoolBalanceOf(underlying);
			uint256 strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		
            acos = new address[](openAcos.length);
            acosAmount = new uint256[](openAcos.length);
			for (uint256 i = 0; i < openAcos.length; ++i) {
				address acoToken = openAcos[i];
				uint256 tokens = IACOToken(acoToken).currentCollateralizedTokens(address(this));
				
				acos[i] = acoToken;
				acosAmount[i] = tokens.mul(shares).div(_totalSupply);
			}
			
			underlyingWithdrawn = underlyingBalance.mul(shares).div(_totalSupply);
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(_totalSupply);
		}
    }

    /**
     * @dev Internal function to get the shares for a collateral amount on deposit.
     * @param collateralAmount Amount of collateral to be deposited.
     * @return The shares to be received on the deposit.
     */
	function _getDepositShares(uint256 collateralAmount) internal view returns(uint256) {
        (,,uint256 collateralBalance, uint256 collateralOnOpenPosition,) = _getTotalCollateralBalance(true);
		collateralBalance = collateralBalance.sub(collateralOnOpenPosition);

        if (collateralBalance == 0) {
            return collateralAmount;
        } else {
            return collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
    }
	
	/**
     * @dev Internal function to get the withdrawal data for a shares amount considering that there is NO locked collateral on the operation.
     * @param shares Amount of shares to be withdrawn.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * isPossible TRUE whether it is possible to withdraw from that way (NO locked) or FALSE otherwise.
     */
	function _getWithdrawNoLockedData(uint256 shares) internal view returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
	) {
        uint256 _totalSupply = totalSupply();
		if (shares > 0 && shares <= _totalSupply) {
			
			(uint256 underlyingBalance, 
             uint256 strikeAssetBalance, 
             uint256 collateralBalance, 
             uint256 collateralOnOpenPosition,
             uint256 collateralLockedRedeemable) = _getTotalCollateralBalance(false);

			if (collateralBalance > collateralOnOpenPosition) {
				
				uint256 collateralAmount = shares.mul(collateralBalance.sub(collateralOnOpenPosition)).div(_totalSupply);
				
				if (isCall) {
					if (collateralAmount <= underlyingBalance.add(collateralLockedRedeemable)) {
						underlyingWithdrawn = collateralAmount;
						strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(_totalSupply);
						isPossible = true;
					}
				} else if (collateralAmount <= strikeAssetBalance.add(collateralLockedRedeemable)) {
					strikeAssetWithdrawn = collateralAmount;
					underlyingWithdrawn = underlyingBalance.mul(shares).div(_totalSupply);
					isPossible = true;
				}
			}
		}
	}

	/**
     * @dev Internal function to withdraw from the pool with NO locked collateral.
     * @param shares Amount of the account shares to be withdrawn.
     * @param minCollateral The minimum collateral amount acceptable on the withdrawal.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw.
     */
    function _withdrawNoLocked(uint256 shares, uint256 minCollateral, address account) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        require(shares > 0, "E30");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
		(uint256 underlyingBalance, 
         uint256 strikeAssetBalance, 
         uint256 collateralBalance,
         uint256 collateralOnOpenPosition,) = _getTotalCollateralBalance(false);
		require(collateralBalance > collateralOnOpenPosition, "E31");

		uint256 collateralAmount = shares.mul(collateralBalance.sub(collateralOnOpenPosition)).div(_totalSupply);
		require(collateralAmount >= minCollateral, "E32");

        if (isCall) {
			require(collateralAmount <= underlyingBalance, "E33");
			underlyingWithdrawn = collateralAmount;
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(_totalSupply);
        } else {
			require(collateralAmount <= strikeAssetBalance, "E34");
			strikeAssetWithdrawn = collateralAmount;
			underlyingWithdrawn = underlyingBalance.mul(shares).div(_totalSupply);
		}
        
		ACOAssetHelper._transferAsset(underlying, msg.sender, underlyingWithdrawn);
		ACOAssetHelper._transferAsset(strikeAsset, msg.sender, strikeAssetWithdrawn);
		
        emit Withdraw(account, shares, true, underlyingWithdrawn, strikeAssetWithdrawn, new address[](0), new uint256[](0));
    }
	
	/**
     * @dev Internal function to withdraw from the pool and transferring the locked collateral and the obligation to redeem it on the expiration.
     * @param shares Amount of the account shares to be withdrawn.
     * @param account Address of the account to withdraw.
     * @return underlyingWithdrawn The underlying amount on the withdraw
     * strikeAssetWithdrawn the strike asset amount on the withdraw
     * acos addresses of the ACOs with locked collateral that will be transferred
     * acosAmount the respective ACOs amount to be transferred.
     */
	function _withdrawWithLocked(uint256 shares, address account) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        require(shares > 0, "E20");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
		address _underlying = underlying;
		address _strikeAsset = strikeAsset;
		uint256 underlyingBalance = _getPoolBalanceOf(_underlying);
		uint256 strikeAssetBalance = _getPoolBalanceOf(_strikeAsset);
		
		(acos, acosAmount) = _transferOpenPositions(shares, _totalSupply);
		
		underlyingWithdrawn = underlyingBalance.mul(shares).div(_totalSupply);
		strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(_totalSupply);
		
		ACOAssetHelper._transferAsset(_underlying, msg.sender, underlyingWithdrawn);
		ACOAssetHelper._transferAsset(_strikeAsset, msg.sender, strikeAssetWithdrawn);
		
        emit Withdraw(account, shares, false, underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount);
    }
	
	/**
     * @dev Internal function to get the total collateral balance from the pool.
     * @param isDeposit TRUE whether is a deposit operation, FALSE otherwise it is a withdraw.
     * @return underlyingBalance The pool underlying balance
     * strikeAssetBalance the pool strike asset balance 
     * collateralBalance the pool collateral balance considering the available, locked collateral and the open position
     * collateralOnOpenPosition the pool collateral on open positions calculated using the options current price
     * collateralLockedRedeemable the pool collateral locked that already can be redeem.
     */
	function _getTotalCollateralBalance(bool isDeposit) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		underlyingBalance = _getPoolBalanceOf(underlying);
		strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		
		uint256 underlyingPrice = assetConverter.getPrice(underlying, strikeAsset);
		
		if (isCall) {
			collateralBalance = underlyingBalance;
			if (isDeposit && strikeAssetBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, false); 
				collateralBalance = collateralBalance.add(strikeAssetBalance.mul(underlyingPrecision).div(priceAdjusted));
			}
		} else {
			collateralBalance = strikeAssetBalance;
			if (isDeposit && underlyingBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, true); 
				collateralBalance = collateralBalance.add(underlyingBalance.mul(priceAdjusted).div(underlyingPrecision));
			}
		}
		
        uint256 collateralLocked;
		(collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _poolOpenPositionCollateralBalance(underlyingPrice, isDeposit);
		
        collateralBalance = collateralBalance.add(collateralLocked);
	}
	
	/**
     * @dev Internal function to burn pool tokens.
     * @param account Address of the account.
     * @param tokenAmount Amount of pool tokens to be burned.
     */
	function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }
	
	/**
     * @dev Internal function to swap an ACO token with the pool.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction The maximum value to pay on the purchase.
     * @param to Address of the ACO tokens destination.
     * @param deadline UNIX deadline for the swap to be executed.
     */
	function _swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) internal {
        require(block.timestamp <= deadline, "E40");
        require(to != address(0) && to != acoToken && to != address(this), "E41");
        
        (uint256 swapPrice, uint256 protocolFee, uint256 underlyingPrice, uint256 volatility, uint256 collateralAmount) = _quote(acoToken, tokenAmount);
        
        _internalSelling(to, acoToken, collateralAmount, tokenAmount, restriction, swapPrice, protocolFee);

        if (protocolFee > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, feeDestination, protocolFee);
        }
        
        emit Swap(msg.sender, acoToken, tokenAmount, swapPrice, protocolFee, underlyingPrice, volatility);
    }

	/**
     * @dev Internal function to quote an ACO token price.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @return swapPrice The quoted price
     * protocolFee the protocol fee charged
     * underlyingPrice the underlying price
     * volatility the volatility used on the calculation
     * collateralAmount the collateral amount.
     */
	function _quote(address acoToken, uint256 tokenAmount) internal view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        require(tokenAmount > 0, "E50");
        
        (address _underlying, address _strikeAsset, bool _isCall, uint256 strikePrice, uint256 expiryTime) = acoFactory.acoTokenData(acoToken);
        
		require(_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall), "E51");
		require(_acoExpirationIsValid(expiryTime), "E52");
		
		underlyingPrice = assetConverter.getPrice(_underlying, _strikeAsset);
		require(_acoStrikePriceIsValid(strikePrice, underlyingPrice), "E53");

        require(expiryTime > block.timestamp, "E54");
        (swapPrice, protocolFee, volatility, collateralAmount) = _internalQuote(acoToken, tokenAmount, strikePrice, expiryTime, underlyingPrice);
    }
	
	/**
     * @dev Internal function to quote an ACO token price.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
	 * @param strikePrice ACO strike price.
	 * @param expiryTime ACO expiry time on UNIX.
	 * @param underlyingPrice The current underlying price.
     * @return swapPrice The quoted price
     * protocolFee the protocol fee charged
     * volatility the volatility used on the calculation
     * collateralAmount the collateral amount.
     */
	function _internalQuote(
		address acoToken, 
		uint256 tokenAmount, 
		uint256 strikePrice, 
		uint256 expiryTime, 
		uint256 underlyingPrice
	) internal view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        uint256 collateralAvailable;
        (collateralAmount, collateralAvailable) = _getSizeData(acoToken, tokenAmount);
        (swapPrice, volatility) = _strategyQuote(strikePrice, expiryTime, underlyingPrice, collateralAmount, collateralAvailable);
        
        swapPrice = swapPrice.mul(tokenAmount).div(underlyingPrecision);
        
        if (fee > 0) {
            protocolFee = swapPrice.mul(fee).div(PERCENTAGE_PRECISION);
			swapPrice = swapPrice.add(protocolFee);
        }
        require(swapPrice > 0, "E55");
    }

	/**
     * @dev Internal function to the size data for a quote.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @return collateralAmount The collateral amount 
     * collateralAvailable the collateral available on the pool.
     */
    function _getSizeData(address acoToken, uint256 tokenAmount) internal view returns(
        uint256 collateralAmount, 
        uint256 collateralAvailable
    ) {
        if (isCall) {
            collateralAvailable = _getPoolBalanceOf(underlying);
            collateralAmount = tokenAmount; 
        } else {
            collateralAvailable = _getPoolBalanceOf(strikeAsset);
            collateralAmount = IACOToken(acoToken).getCollateralAmount(tokenAmount);
            require(collateralAmount > 0, "E56");
        }
        require(collateralAmount <= collateralAvailable, "E57");
    }

	/**
     * @dev Internal function to quote on the strategy contract.
	 * @param strikePrice ACO token strike price.
     * @param expiryTime ACO token expiry time on UNIX.
	 * @param underlyingPrice The current underlying price.
     * @param collateralAmount Amount of collateral for the order size.
     * @param collateralAvailable Amount of collateral available on the pool.
     * @return swapPrice The quoted price
     * volatility the volatility used on te option price calculation.
     */
    function _strategyQuote(
        uint256 strikePrice,
        uint256 expiryTime,
        uint256 underlyingPrice,
        uint256 collateralAmount,
        uint256 collateralAvailable
    ) internal view returns(uint256 swapPrice, uint256 volatility) {
        (swapPrice, volatility) = strategy.quote(IACOPoolStrategy.OptionQuote(
			underlyingPrice,
            underlying, 
            strikeAsset, 
            isCall, 
            strikePrice, 
            expiryTime, 
            baseVolatility, 
            collateralAmount, 
            collateralAvailable
        ));
    }

	/**
     * @dev Internal function to sell ACO tokens.
     * @param to Address of the destination of the ACO tokens.
     * @param acoToken Address of the ACO token.
	 * @param collateralAmount Order collateral amount.
     * @param tokenAmount Order token amount.
     * @param maxPayment Maximum value to be paid for the ACO tokens.
     * @param swapPrice The swap price quoted.
     * @param protocolFee The protocol fee amount.
     */
    function _internalSelling(
        address to,
        address acoToken, 
        uint256 collateralAmount, 
        uint256 tokenAmount,
        uint256 maxPayment,
        uint256 swapPrice,
        uint256 protocolFee
    ) internal {
        require(swapPrice <= maxPayment, "E42");
        
        ACOAssetHelper._callTransferFromERC20(strikeAsset, msg.sender, address(this), swapPrice);

		address _collateral = collateral();
        AcoData storage data = acoData[acoToken];
		if (ACOAssetHelper._isEther(_collateral)) {
			tokenAmount = IACOToken(acoToken).mintPayable{value: collateralAmount}();
		} else {
			if (!data.open) {
				_setAuthorizedSpender(_collateral, acoToken);    
			}
			tokenAmount = IACOToken(acoToken).mint(collateralAmount);
		}

		if (!data.open) {
            require(openAcos.length < maximumOpenAco, "E43");
			acoData[acoToken] = AcoData(true, swapPrice.sub(protocolFee), collateralAmount, 0, acoTokens.length, openAcos.length);
            acoTokens.push(acoToken);    
            openAcos.push(acoToken);   
        } else {
			data.collateralLocked = collateralAmount.add(data.collateralLocked);
			data.valueSold = swapPrice.sub(protocolFee).add(data.valueSold);
		}
        
        ACOAssetHelper._callTransferERC20(acoToken, to, tokenAmount);
    }
	
	/**
     * @dev Internal function to get the pool colletaral balance from the active ACOs.
	 * @param underlyingPrice The current underlying price.
	 * @param isDeposit TRUE whether it is a deposit operation, otherwise FALSE for a withdraw.
	 * @return collateralLocked Total amount of collateral locked
     * collateralOnOpenPosition the total collateral on open positions calculated using the options current price
     * collateralLockedRedeemable the pool collateral locked that already can be redeem.
     */
	function _poolOpenPositionCollateralBalance(uint256 underlyingPrice, bool isDeposit) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		bool _collateralIsUnderlying = isCall;
        uint256 _underlyingPrecision = underlyingPrecision;
        IACOFactory _acoFactory = acoFactory;
		for (uint256 i = 0; i < openAcos.length; ++i) {
			address acoToken = openAcos[i];

            (uint256 locked, uint256 openPosition, uint256 lockedRedeemable) = _getOpenPositionCollateralBalance(
                acoToken,
                underlyingPrice,
                _underlyingPrecision,
                _acoFactory,
                _collateralIsUnderlying
            );
            
            collateralLocked = collateralLocked.add(locked);
            collateralOnOpenPosition = collateralOnOpenPosition.add(openPosition);
            collateralLockedRedeemable = collateralLockedRedeemable.add(lockedRedeemable);
		}
		if (!isDeposit) {
			collateralOnOpenPosition = collateralOnOpenPosition.mul(PERCENTAGE_PRECISION.add(withdrawOpenPositionPenalty)).div(PERCENTAGE_PRECISION);
		}
	}

	/**
     * @dev Internal function to get the colletaral balance from the active ACO.
     * @param acoToken Address of the ACO.
	 * @param underlyingPrice The current underlying price.
	 * @param _underlyingPrecision The underlying precision.
	 * @param _acoFactory The ACO factory.
	 * @param _collateralIsUnderlying TRUE whether the collateral is the underlying, otherwise FALSE for the strike asset as collateral.
	 * @return collateralLocked Amount of collateral locked
     * collateralOnOpenPosition the collateral on open positions calculated using the options current price
     * collateralLockedRedeemable the collateral locked that already can be redeem
     */
    function _getOpenPositionCollateralBalance(
        address acoToken,
        uint256 underlyingPrice,
        uint256 _underlyingPrecision,
        IACOFactory _acoFactory,
        bool _collateralIsUnderlying
    ) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        (,,,uint256 _strikePrice, uint256 _expiryTime) = _acoFactory.acoTokenData(acoToken);
			
        uint256 tokenAmount = IACOToken(acoToken).currentCollateralizedTokens(address(this));
        
        if (_collateralIsUnderlying) {
            collateralLocked = tokenAmount;
        } else {
            collateralLocked = tokenAmount.mul(_strikePrice).div(_underlyingPrecision);
        }
		
        if (_expiryTime > block.timestamp) {
            (uint256 price,) = _strategyQuote(_strikePrice, _expiryTime, underlyingPrice, 0, 1);
            if (_collateralIsUnderlying) {
                uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, false); 
                collateralOnOpenPosition = price.mul(tokenAmount).div(priceAdjusted);
            } else {
                collateralOnOpenPosition = price.mul(tokenAmount).div(_underlyingPrecision);
            }
        } else {
            collateralLockedRedeemable = collateralLocked;
        }
    }
	
	/**
     * @dev Internal function to transfer the locked position.
     * @param shares Amount of shares.
	 * @param _totalSupply The pool total shares.
	 * @return acos Addresses of the ACOs with locked collateral transferred
     * acosAmount the respective ACOs amount transferred.
     */
	function _transferOpenPositions(uint256 shares, uint256 _totalSupply) internal returns(
        address[] memory acos, 
        uint256[] memory acosAmount
    ) {
        uint256 size = openAcos.length;
        acos = new address[](size);
        acosAmount = new uint256[](size);
		for (uint256 i = 0; i < size; ++i) {
			address acoToken = openAcos[i];
			uint256 tokens = IACOToken(acoToken).currentCollateralizedTokens(address(this));
			
			acos[i] = acoToken;
			acosAmount[i] = tokens.mul(shares).div(_totalSupply);
			
            if (acosAmount[i] > 0) {
			    IACOToken(acoToken).transferCollateralOwnership(msg.sender, acosAmount[i]);
            }
		}
	}
	
	/**
     * @dev Internal function to get the current underlying price adjusted to consider the Oracle delay to update.
     * @param underlyingPrice The current underlying price.
	 * @param isMaximum TRUE whether it is a maximum price, otherwise FALSE for a minimum price.
	 * @return The underlying price adjusted.
     */
	function _getUnderlyingPriceAdjusted(uint256 underlyingPrice, bool isMaximum) internal view returns(uint256) {
		if (isMaximum) {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.add(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		} else {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.sub(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		}
    }
	
	/**
     * @dev Internal function to remove an active ACO token from the array.
     * @param data The ACO data for the token.
     */
    function _removeFromOpenAcos(AcoData storage data) internal {
        uint256 lastIndex = openAcos.length - 1;
		uint256 index = data.openIndex;
		if (lastIndex != index) {
		    address last = openAcos[lastIndex];
			openAcos[index] = last;
			acoData[last].openIndex = index;
		}
		data.openIndex = 0;
        openAcos.pop();
    }
	
	/**
     * @dev Internal function to redeem the collateral from an ACO token.
     * It redeems the collateral only if the ACO token is expired.
     * @param acoToken Address of the ACO token.
     */
	function _redeemACOToken(address acoToken) internal {
		AcoData storage data = acoData[acoToken];
		if (data.open && IACOToken(acoToken).expiryTime() <= block.timestamp) {
			
            data.open = false;

            if (IACOToken(acoToken).currentCollateralizedTokens(address(this)) > 0) {	
			    data.collateralRedeemed = IACOToken(acoToken).redeem();
            }
            
			_removeFromOpenAcos(data);
			
			emit ACORedeem(acoToken, data.valueSold, data.collateralLocked, data.collateralRedeemed);
		}
    }
	
	/**
     * @dev Internal function to check whether the ACO assets and creator is valid for the pool.
     * @param acoToken Address of the ACO token.
	 * @param _underlying Address of the underlying.
	 * @param _strikeAsset Address of the strike asset.
	 * @param _isCall TRUE whether the ACO is a CALL option, FALSE for a PUT option.
     * @return TRUE whether it is valid, otherwise FALSE.
     */
	function _acoBasicDataIsValid(address acoToken, address _underlying, address _strikeAsset, bool _isCall) internal view returns(bool) {
		return _underlying == underlying && _strikeAsset == strikeAsset && _isCall == isCall && validAcoCreators[acoFactory.creators(acoToken)];
	}
	
	/**
     * @dev Internal function to check whether the ACO expiration is valid for the pool.
     * @param _expiryTime ACO expiry time.
     * @return TRUE whether it is valid, otherwise FALSE.
     */
	function _acoExpirationIsValid(uint256 _expiryTime) internal view returns(bool) {
		return _expiryTime >= block.timestamp.add(minExpiration) && _expiryTime <= block.timestamp.add(maxExpiration);
	}
	
	/**
     * @dev Internal function to check whether the ACO strike asset is valid for the pool.
     * @param _strikePrice ACO strike price.
     * @param price Current underlying price.
     * @return TRUE whether it is valid, otherwise FALSE.
     */
	function _acoStrikePriceIsValid(uint256 _strikePrice, uint256 price) internal view returns(bool) {
		uint256 _tolerancePriceAbove = tolerancePriceAbove;
		uint256 _tolerancePriceBelow = tolerancePriceBelow;
		return (_tolerancePriceBelow == 0 && _tolerancePriceAbove == 0) ||
			(_tolerancePriceBelow == 0 && _strikePrice > price.mul(PERCENTAGE_PRECISION.add(_tolerancePriceAbove)).div(PERCENTAGE_PRECISION)) ||
			(_tolerancePriceAbove == 0 && _strikePrice < price.mul(PERCENTAGE_PRECISION.sub(_tolerancePriceBelow)).div(PERCENTAGE_PRECISION)) ||
			(_strikePrice >= price.mul(PERCENTAGE_PRECISION.sub(_tolerancePriceBelow)).div(PERCENTAGE_PRECISION) && 
			 _strikePrice <= price.mul(PERCENTAGE_PRECISION.add(_tolerancePriceAbove)).div(PERCENTAGE_PRECISION));
	}
	
	/**
     * @dev Internal function to infinite authorize the pool assets on the asset converter helper.
     * @param _isCall True whether it is a CALL option, otherwise it is PUT.
     * @param _assetConverterHelper Address of the asset converter helper.
     * @param _underlying Address of the underlying asset.
     * @param _strikeAsset Address of the strike asset.
     */
	function _approveAssetsOnConverterHelper(
        bool _isCall, 
        address _assetConverterHelper,
        address _underlying,
        address _strikeAsset
    ) internal {
        if (_isCall) {
            if (!ACOAssetHelper._isEther(_strikeAsset)) {
                _setAuthorizedSpender(_strikeAsset, _assetConverterHelper);
            }
        } else if (!ACOAssetHelper._isEther(_underlying)) {
            _setAuthorizedSpender(_underlying, _assetConverterHelper);
        }
    }
	
	/**
     * @dev Internal function to get the pool balance of an asset.
     * @param asset Address of the asset.
     * @return The pool balance.
     */
	function _getPoolBalanceOf(address asset) internal view returns(uint256) {
        return ACOAssetHelper._getAssetBalanceOf(asset, address(this));
    }
	
	/**
     * @dev Internal function to infinite authorize a spender on an asset.
     * @param asset Address of the asset.
     * @param spender Address of the spender to be authorized.
     */
	function _setAuthorizedSpender(address asset, address spender) internal {
        ACOAssetHelper._callApproveERC20(asset, spender, MAX_UINT);
    }
	
	/**
     * @dev Internal function to set the strategy address.
     * @param newStrategy Address of the new strategy address.
     */
	function _setStrategy(address newStrategy) internal {
        require(newStrategy.isContract(), "E81");
        emit SetStrategy(address(strategy), newStrategy);
        strategy = IACOPoolStrategy(newStrategy);
    }

	/**
     * @dev Internal function to set the base volatility.
     * @param newBaseVolatility Value of the new base volatility.
     */
    function _setBaseVolatility(uint256 newBaseVolatility) internal {
        require(newBaseVolatility > 0, "E82");
        emit SetBaseVolatility(baseVolatility, newBaseVolatility);
        baseVolatility = newBaseVolatility;
    }

	/**
     * @dev Internal function to set the asset converter address.
     * @param newAssetConverter Address of the new asset converter.
     */
    function _setAssetConverter(address newAssetConverter) internal {
        require(newAssetConverter.isContract(), "E83");
		require(IACOAssetConverterHelper(newAssetConverter).getPrice(underlying, strikeAsset) > 0, "E84");
		
		_approveAssetsOnConverterHelper(isCall, newAssetConverter, underlying, strikeAsset);
		
        emit SetAssetConverter(address(assetConverter), newAssetConverter);
        assetConverter = IACOAssetConverterHelper(newAssetConverter);
    }

	/**
     * @dev Internal function to set the percentage of the above price tolerance.
     * @param newTolerancePriceAbove Value of the new above price tolerance.
     */
    function _setTolerancePriceAbove(uint256 newTolerancePriceAbove) internal {
        require(newTolerancePriceAbove < PERCENTAGE_PRECISION, "E85");
        emit SetTolerancePriceAbove(tolerancePriceAbove, newTolerancePriceAbove);
        tolerancePriceAbove = newTolerancePriceAbove;
    }
    
	/**
     * @dev Internal function to set the percentage of the below price tolerance.
     * @param newTolerancePriceBelow Value of the new below price tolerance.
     */
    function _setTolerancePriceBelow(uint256 newTolerancePriceBelow) internal {
        require(newTolerancePriceBelow < PERCENTAGE_PRECISION, "E86");
        emit SetTolerancePriceBelow(tolerancePriceBelow, newTolerancePriceBelow);
        tolerancePriceBelow = newTolerancePriceBelow;
    }
    
	/**
     * @dev Internal function to set the minimum expiration seconds after current time to the pool accepts an ACO based on its expiry time.
     * @param newMinExpiration Value of the new minimum expiration.
     */
    function _setMinExpiration(uint256 newMinExpiration) internal {
        require(newMinExpiration <= maxExpiration, "E87");
        emit SetMinExpiration(minExpiration, newMinExpiration);
        minExpiration = newMinExpiration;
    }
    
	/**
     * @dev Internal function to set the maximum expiration seconds after current time to the pool accepts an ACO based on its expiry time.
     * @param newMaxExpiration Value of the new maximum expiration.
     */
    function _setMaxExpiration(uint256 newMaxExpiration) internal {
        require(newMaxExpiration >= minExpiration, "E88");
        emit SetMaxExpiration(maxExpiration, newMaxExpiration);
        maxExpiration = newMaxExpiration;
    }
    
	/**
     * @dev Internal function to set the fee destination.
     * @param newFeeDestination Value of the new fee destination.
     */
    function _setFeeDestination(address newFeeDestination) internal {
        require(newFeeDestination != address(0), "E89");
        emit SetFeeDestination(feeDestination, newFeeDestination);
        feeDestination = newFeeDestination;
    }
    
	/**
     * @dev Internal function to set the protocol fee percentage.
     * @param newFee Value of the new protocol fee.
     */
    function _setFee(uint256 newFee) internal {
        require(newFee <= 12500, "E91");
        emit SetFee(fee, newFee);
        fee = newFee;
    }
	
	/**
     * @dev Internal function to set the penalty percentage on withdrawing open positions.
     * @param newWithdrawOpenPositionPenalty Value of the new penalty percentage on withdrawing open positions.
     */
    function _setWithdrawOpenPositionPenalty(uint256 newWithdrawOpenPositionPenalty) internal {
        require(newWithdrawOpenPositionPenalty <= PERCENTAGE_PRECISION, "E92");
        emit SetWithdrawOpenPositionPenalty(withdrawOpenPositionPenalty, newWithdrawOpenPositionPenalty);
        withdrawOpenPositionPenalty = newWithdrawOpenPositionPenalty;
    }
	
	/**
     * @dev Internal function to set the underlying price percentage adjust.
     * @param newUnderlyingPriceAdjustPercentage Value of the new underlying price percentage adjust.
     */
	function _setUnderlyingPriceAdjustPercentage(uint256 newUnderlyingPriceAdjustPercentage) internal {
        require(newUnderlyingPriceAdjustPercentage < PERCENTAGE_PRECISION, "E93");
        emit SetUnderlyingPriceAdjustPercentage(underlyingPriceAdjustPercentage, newUnderlyingPriceAdjustPercentage);
        underlyingPriceAdjustPercentage = newUnderlyingPriceAdjustPercentage;
    }

    /**
     * @dev Internal function to set the maximum number of open ACOs allowed.
     * @param newMaximumOpenAco Value of the new maximum number of open ACOs allowed.
     */
	function _setMaximumOpenAco(uint256 newMaximumOpenAco) internal {
        require(newMaximumOpenAco > 0, "E94");
        emit SetMaximumOpenAco(maximumOpenAco, newMaximumOpenAco);
        maximumOpenAco = newMaximumOpenAco;
    }
	
	/**
     * @dev Internal function to set an valid creator permission.
     * @param creator Address of the creator.
	 * @param newPermission Value of the new permission.
     */
    function _setValidAcoCreator(address creator, bool newPermission) internal {
        emit SetValidAcoCreator(creator, validAcoCreators[creator], newPermission);
        validAcoCreators[creator] = newPermission;
    }

	/**
     * @dev Internal function to check whether the transaction sender is the pool factory.
     */
    function onlyFactory() internal view {
        require(owner() == msg.sender, "E90");
    }
	
	/**
     * @dev Internal function to get the token name.
     * The token name is assembled with the token data:
     * ACO POOL WRITE UNDERLYING_SYMBOL-STRIKE_ASSET_SYMBOL-TYPE
     * @return The token name.
     */
	function _name() internal view returns(string memory) {
        return string(abi.encodePacked(
            "ACO POOL WRITE ",
            ACOAssetHelper._getAssetSymbol(underlying),
            "-",
            ACOAssetHelper._getAssetSymbol(strikeAsset),
            "-",
            (isCall ? "CALL" : "PUT")
        ));
    }
}