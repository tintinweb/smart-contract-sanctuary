pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './Address.sol';
import './ACOAssetHelper.sol';
import './ACOPoolLib.sol';
import './ERC20.sol';
import './IACOFactory.sol';
import './IACOPoolFactory2.sol';
import './IACOAssetConverterHelper.sol';
import './IACOToken.sol';
import './IChiToken.sol';
import './IACOPool2.sol';
import './ILendingPool.sol';

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
 * E01  | init                                | Underlying and strike asset are the same    *
 *------------------------------------------------------------------------------------------*
 * E02  | init                                | Invalid underlying address                  *
 *------------------------------------------------------------------------------------------*
 * E03  | init                                | Invalid strike asset address                *
 *------------------------------------------------------------------------------------------*
 * E10  | _deposit                            | Invalid collateral amount                   *
 *------------------------------------------------------------------------------------------*
 * E11  | _deposit                            | Invalid destination address                 *
 *------------------------------------------------------------------------------------------*
 * E12  | _deposit                            | Invalid deposit for lending pool token      *
 *------------------------------------------------------------------------------------------*
 * E13  | _deposit                            | The minimum shares were not satisfied       *
 *------------------------------------------------------------------------------------------*
 * E20  | _withdrawWithLocked                 | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E21  | _withdrawWithLocked                 | Invalid withdraw for lending pool token     *
 *------------------------------------------------------------------------------------------*
 * E30  | _withdrawNoLocked                   | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E31  | _withdrawNoLocked                   | Invalid withdraw for lending pool token     *
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
 * E60  | restoreCollateral                   | No balance to restore                       *
 *------------------------------------------------------------------------------------------*
 * E70  | lendCollateral                      | Lend is not available for this pool         *
 *------------------------------------------------------------------------------------------*
 * E80  | withdrawStuckToken                  | The token is forbidden to withdraw          *
 *------------------------------------------------------------------------------------------*
 * E81  | _setPoolDataForAcoPermission        | Invalid below tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E82  | _setPoolDataForAcoPermission        | Invalid above tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E83  | _setPoolDataForAcoPermission        | Invalid expiration range                    *
 *------------------------------------------------------------------------------------------*
 * E84  | _setBaseVolatility                  | Invalid base volatility                     *
 *------------------------------------------------------------------------------------------*
 * E85  | _setStrategy                        | Invalid strategy address                    *
 *------------------------------------------------------------------------------------------*
 * E86  | _setPoolAdmin                       | Invalid pool admin address                  *
 *------------------------------------------------------------------------------------------*
 * E87  | _setProtocolConfig                  | No price on the Oracle                      *
 *------------------------------------------------------------------------------------------*
 * E88  | _setProtocolConfig                  | Invalid fee destination address             *
 *------------------------------------------------------------------------------------------*
 * E89  | _setProtocolConfig                  | Invalid fee value                           *
 *------------------------------------------------------------------------------------------*
 * E90  | _setProtocolConfig                  | Invalid penalty percentage                  *
 *------------------------------------------------------------------------------------------*
 * E91  | _setProtocolConfig                  | Invalid underlying price adjust percentage  *
 *------------------------------------------------------------------------------------------*
 * E92  | _setProtocolConfig                  | Invalid maximum number of open ACOs allowed *
 *------------------------------------------------------------------------------------------*
 * E98  | _onlyAdmin                          | Only the pool admin can call the method     *
 *------------------------------------------------------------------------------------------*
 * E99  | _onlyProtocolOwner                  | Only the pool factory can call the method   *
 ********************************************************************************************
 */
contract ACOPool2 is Ownable, ERC20 {
    using Address for address;
    
    uint256 internal constant PERCENTAGE_PRECISION = 100000;

    event SetValidAcoCreator(address indexed creator, bool indexed previousPermission, bool indexed newPermission);
    
    event SetProtocolConfig(IACOPool2.PoolProtocolConfig oldConfig, IACOPool2.PoolProtocolConfig newConfig);
	
	event SetPoolDataForAcoPermission(uint256 oldTolerancePriceBelow, uint256 oldTolerancePriceAbove, uint256 oldMinExpiration, uint256 oldMaxExpiration, uint256 newTolerancePriceBelow, uint256 newTolerancePriceAbove, uint256 newMinExpiration, uint256 newMaxExpiration);

    event SetBaseVolatility(uint256 indexed oldBaseVolatility, uint256 indexed newBaseVolatility);

	event SetStrategy(address indexed oldStrategy, address indexed newStrategy);
	
    event SetPoolAdmin(address indexed oldAdmin, address indexed newAdmin);

    event RestoreCollateral(uint256 amountOut, uint256 collateralRestored);

    event LendCollateral(uint256 collateralAmount);

	event ACORedeem(address indexed acoToken, uint256 valueSold, uint256 collateralLocked, uint256 collateralRedeemed);

    event Deposit(address indexed account, uint256 shares, uint256 collateralAmount);

    event Withdraw(
		address indexed account, 
		uint256 shares, 
		bool noLocked, 
		uint256 underlyingWithdrawn, 
		uint256 strikeAssetWithdrawn, 
		address[] acos, 
		uint256[] acosAmount
	);

	event Swap(
        address indexed account, 
        address indexed acoToken, 
        uint256 tokenAmount, 
        uint256 price, 
        uint256 protocolFee,
        uint256 underlyingPrice,
		uint256 volatility
    );

    IACOFactory public acoFactory;
	IChiToken public chiToken;
	ILendingPool public lendingPool;
    address public underlying;
    address public strikeAsset;
    bool public isCall;

    address public admin;
	address public strategy;
    uint256 public baseVolatility;
    uint256 public tolerancePriceAbove;
    uint256 public tolerancePriceBelow;
    uint256 public minExpiration;
    uint256 public maxExpiration;
    
	uint16 public lendingPoolReferral;
	uint256 public withdrawOpenPositionPenalty;
	uint256 public underlyingPriceAdjustPercentage;
    uint256 public fee;
	uint256 public maximumOpenAco;
	address public feeDestination;
    IACOAssetConverterHelper public assetConverter;
    
    address[] public acoTokens;
    address[] public openAcos;

    mapping(address => bool) public validAcoCreators;
    mapping(address => IACOPool2.AcoData) public acoData;

    address internal lendingToken;
	uint256 internal underlyingPrecision;

	modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function init(IACOPool2.InitData calldata initData) external {
		require(underlying == address(0) && strikeAsset == address(0), "E00");
        
        require(initData.underlying != initData.strikeAsset, "E01");
        require(ACOAssetHelper._isEther(initData.underlying) || initData.underlying.isContract(), "E02");
        require(ACOAssetHelper._isEther(initData.strikeAsset) || initData.strikeAsset.isContract(), "E03");
        
        super.init();

        acoFactory = IACOFactory(initData.acoFactory);
        chiToken = IChiToken(initData.chiToken);
        lendingPool = ILendingPool(initData.lendingPool);
        underlying = initData.underlying;
        strikeAsset = initData.strikeAsset;
        isCall = initData.isCall;
		
		_setProtocolConfig(initData.config);
		_setPoolAdmin(initData.admin);
		_setPoolDataForAcoPermission(initData.tolerancePriceBelow, initData.tolerancePriceAbove, initData.minExpiration, initData.maxExpiration);
        _setBaseVolatility(initData.baseVolatility);
        _setStrategy(initData.strategy);
		
		if (!initData.isCall) {
		    lendingToken = ILendingPool(initData.lendingPool).getReserveData(initData.strikeAsset).aTokenAddress;
            _setAuthorizedSpender(initData.strikeAsset, initData.lendingPool);
        }
		underlyingPrecision = 10 ** uint256(ACOAssetHelper._getAssetDecimals(initData.underlying));
    }

    receive() external payable {
    }

    function name() public override view returns(string memory) {
        return ACOPoolLib.name(underlying, strikeAsset, isCall);
    }

	function symbol() public override view returns(string memory) {
        return name();
    }

    function decimals() public override view returns(uint8) {
        return ACOAssetHelper._getAssetDecimals(collateral());
    }

    function numberOfAcoTokensNegotiated() external view returns(uint256) {
        return acoTokens.length;
    }

    function numberOfOpenAcoTokens() external view returns(uint256) {
        return openAcos.length;
    }

	function collateral() public view returns(address) {
        return (isCall ? underlying : strikeAsset);
    }

    function canSwap(address acoToken) external view returns(bool) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime) = acoFactory.acoTokenData(acoToken);
		if (_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall) && 
		    ACOPoolLib.acoExpirationIsValid(_expiryTime, minExpiration, maxExpiration)) {
            uint256 price = _getPrice(_underlying, _strikeAsset);
            return ACOPoolLib.acoStrikePriceIsValid(tolerancePriceBelow, tolerancePriceAbove, _strikePrice, price);
        }
        return false;
    }

	function quote(address acoToken, uint256 tokenAmount) external view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility
    ) {
        (swapPrice, protocolFee, underlyingPrice, volatility,) = _quote(acoToken, tokenAmount);
    }

	function getDepositShares(uint256 collateralAmount) external view returns(uint256) {
        (,,uint256 collateralBalance,) = _getCollateralNormalized(true);

        if (collateralBalance == 0) {
            return collateralAmount;
        } else {
            return collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
    }

	function getWithdrawNoLockedData(uint256 shares) external view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
    ) {
        uint256 _totalSupply = totalSupply();
		if (shares > 0 && shares <= _totalSupply) {
			
			(uint256 underlyingBalance, 
             uint256 strikeAssetBalance, 
             uint256 collateralBalance, 
             uint256 collateralLockedRedeemable) = _getCollateralNormalized(false);
             
            (underlyingWithdrawn, strikeAssetWithdrawn, isPossible) = ACOPoolLib.getBaseWithdrawNoLockedData(
                shares,
                _totalSupply,
                isCall,
                underlyingBalance, 
                strikeAssetBalance, 
                collateralBalance, 
                collateralLockedRedeemable
            );
		}
    }

	function getWithdrawWithLocked(uint256 shares) external view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
    ) {
        uint256 _totalSupply = totalSupply();	
        if (shares > 0 && shares <= _totalSupply) {
        
            (underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getBaseAssetsWithdrawWithLocked(shares, underlying, strikeAsset, isCall, _totalSupply, lendingToken);
		
            acos = new address[](openAcos.length);
            acosAmount = new uint256[](openAcos.length);
			for (uint256 i = 0; i < openAcos.length; ++i) {
				address acoToken = openAcos[i];
				uint256 tokens = IACOToken(acoToken).currentCollateralizedTokens(address(this));
				
				acos[i] = acoToken;
				acosAmount[i] = tokens.mul(shares).div(_totalSupply);
			}
		}
    }

	function getGeneralData() external view returns(
        uint256 underlyingBalance,
		uint256 strikeAssetBalance,
		uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable,
		uint256 poolSupply
    ) {
        poolSupply = totalSupply();
        (underlyingBalance, strikeAssetBalance,, collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getCollateralData(true);
    }
    
    function setPoolDataForAcoPermission(
        uint256 newTolerancePriceBelow, 
        uint256 newTolerancePriceAbove,
        uint256 newMinExpiration,
        uint256 newMaxExpiration
    ) external {
        _onlyAdmin();
        _setPoolDataForAcoPermission(newTolerancePriceBelow, newTolerancePriceAbove, newMinExpiration, newMaxExpiration);
    }

	function setBaseVolatility(uint256 newBaseVolatility) external {
        _onlyAdmin();
		_setBaseVolatility(newBaseVolatility);
	}
	
	function setStrategy(address newStrategy) external {
        _onlyAdmin();
		_setStrategy(newStrategy);
	}
	
	function setPoolAdmin(address newAdmin) external {
	    _onlyAdmin();
		_setPoolAdmin(newAdmin);
	}

	function setValidAcoCreator(address newAcoCreator, bool newPermission) external {
        _onlyProtocolOwner();
        _setValidAcoCreator(newAcoCreator, newPermission);
    }
    
    function setProtocolConfig(IACOPool2.PoolProtocolConfig calldata newConfig) external {
        _onlyProtocolOwner();
        _setProtocolConfig(newConfig);
    }

    function withdrawStuckToken(address token, address destination) external {
        _onlyProtocolOwner();
        require(token != underlying && token != strikeAsset && !acoData[token].open && (isCall || token != lendingToken), "E80");
        uint256 _balance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
        if (_balance > 0) {
            ACOAssetHelper._transferAsset(token, destination, _balance);
        }
    }

	function deposit(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to, 
	    bool isLendingToken
    ) external payable returns(uint256) {
        return _deposit(collateralAmount, minShares, to, isLendingToken);
    }

	function depositWithGasToken(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to, 
	    bool isLendingToken
    ) discountCHI external payable returns(uint256) {
        return _deposit(collateralAmount, minShares, to, isLendingToken);
    }

    function withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account, withdrawLendingToken);
    }

	function withdrawWithLockedWithGasToken(uint256 shares, address account, bool withdrawLendingToken) discountCHI external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account, withdrawLendingToken);
    }

	function withdrawNoLocked(
	    uint256 shares, 
	    uint256 minCollateral, 
	    address account, 
	    bool withdrawLendingToken
    ) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account, withdrawLendingToken);
    }

	function withdrawNoLockedWithGasToken(
	    uint256 shares, 
	    uint256 minCollateral, 
	    address account, 
	    bool withdrawLendingToken
    ) discountCHI external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account, withdrawLendingToken);
    }

	function swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) external {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }

    function swapWithGasToken(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) discountCHI external {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }

    function redeemACOTokens() public {
        for (uint256 i = openAcos.length; i > 0; --i) {
            address acoToken = openAcos[i - 1];
            redeemACOToken(acoToken);
        }
    }

	function redeemACOToken(address acoToken) public {
		IACOPool2.AcoData storage data = acoData[acoToken];
		if (data.open && IACOToken(acoToken).expiryTime() <= block.timestamp) {
			
            data.open = false;
			uint256 lastIndex = openAcos.length - 1;
    		uint256 index = data.openIndex;
    		if (lastIndex != index) {
    		    address last = openAcos[lastIndex];
    			openAcos[index] = last;
    			acoData[last].openIndex = index;
    		}
    		data.openIndex = 0;
            openAcos.pop();

            if (IACOToken(acoToken).currentCollateralizedTokens(address(this)) > 0) {	
			    data.collateralRedeemed = IACOToken(acoToken).redeem();
			    if (!isCall) {
			        _depositOnLendingPool(data.collateralRedeemed);
			    }
            }
			
			emit ACORedeem(acoToken, data.valueSold, data.collateralLocked, data.collateralRedeemed);
		}
    }

	function restoreCollateral() external {
        _onlyAdmin();
        
        uint256 balanceOut;
        address assetIn;
        address assetOut;
        if (isCall) {
            balanceOut = _getPoolBalanceOf(strikeAsset);
            assetIn = underlying;
            assetOut = strikeAsset;
        } else {
            balanceOut = _getPoolBalanceOf(underlying);
            assetIn = strikeAsset;
            assetOut = underlying;
        }
        require(balanceOut > 0, "E60");
        
		uint256 etherAmount = 0;
        if (ACOAssetHelper._isEther(assetOut)) {
			etherAmount = balanceOut;
        }
        uint256 collateralRestored = assetConverter.swapExactAmountOut{value: etherAmount}(assetOut, assetIn, balanceOut);
        if (!isCall) {
            _depositOnLendingPool(collateralRestored);
        }

        emit RestoreCollateral(balanceOut, collateralRestored);
    }

	function lendCollateral() external {
		require(!isCall, "E70");
	    uint256 strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
	    if (strikeAssetBalance > 0) {
	        _depositOnLendingPool(strikeAssetBalance);
	        emit LendCollateral(strikeAssetBalance);
	    }
    }

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
		
		underlyingPrice = _getPrice(_underlying, _strikeAsset);
		
        (swapPrice, protocolFee, volatility, collateralAmount) = ACOPoolLib.quote(ACOPoolLib.QuoteData(
    		_isCall,
            tokenAmount, 
    		_underlying,
    		_strikeAsset,
    		strikePrice, 
    		expiryTime, 
    		lendingToken,
    		strategy,
    		baseVolatility,
    		fee,
    		minExpiration,
    		maxExpiration,
    		tolerancePriceBelow,
    		tolerancePriceAbove,
    		underlyingPrice,
    		underlyingPrecision));
    }
    
	function _deposit(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to,
	    bool isLendingToken
    ) internal returns(uint256 shares) {
        require(collateralAmount > 0, "E10");
        require(to != address(0) && to != address(this), "E11");
        require(!isLendingToken || !isCall, "E12");
		
		(,,uint256 collateralBalance,) = _getCollateralNormalized(true);

		address _collateral = collateral();
		if (ACOAssetHelper._isEther(_collateral)) {
            collateralBalance = collateralBalance.sub(msg.value);
		}
        
        if (collateralBalance == 0) {
            shares = collateralAmount;
        } else {
            shares = collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
        require(shares >= minShares, "E13");

        if (isLendingToken) {
            ACOAssetHelper._receiveAsset(lendingToken, collateralAmount);
        } else {
            ACOAssetHelper._receiveAsset(_collateral, collateralAmount);
            if (!isCall) {
                _depositOnLendingPool(collateralAmount);
            }
        }
        
        super._mintAction(to, shares);
        
        emit Deposit(to, shares, collateralAmount);
    }

	function _withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        require(shares > 0, "E20");
        require(!withdrawLendingToken || !isCall, "E21");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
		(underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getAmountToLockedWithdraw(shares, _totalSupply, lendingToken, underlying, strikeAsset, isCall);
		
		(acos, acosAmount) = _transferOpenPositions(shares, _totalSupply);

		_transferWithdrawnAssets(underlyingWithdrawn, strikeAssetWithdrawn, withdrawLendingToken);

        emit Withdraw(account, shares, false, underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount);
    }
    
    function _withdrawNoLocked(
        uint256 shares, 
        uint256 minCollateral, 
        address account, 
        bool withdrawLendingToken
    ) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        require(shares > 0, "E30");
        bool _isCall = isCall;
        require(!withdrawLendingToken || !_isCall, "E31");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
        (underlyingWithdrawn, strikeAssetWithdrawn) = _getAmountToNoLockedWithdraw(shares, _totalSupply, minCollateral, _isCall);
        
        _transferWithdrawnAssets(underlyingWithdrawn, strikeAssetWithdrawn, withdrawLendingToken);
		
        emit Withdraw(account, shares, true, underlyingWithdrawn, strikeAssetWithdrawn, new address[](0), new uint256[](0));
    }

    function _transferWithdrawnAssets(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn, 
        bool withdrawLendingToken
    ) internal {
        if (strikeAssetWithdrawn > 0) {
            if (withdrawLendingToken) {
    		    ACOAssetHelper._transferAsset(lendingToken, msg.sender, strikeAssetWithdrawn);
    		} else if (isCall) {
    		    ACOAssetHelper._transferAsset(strikeAsset, msg.sender, strikeAssetWithdrawn);
    		} else {
    		    _withdrawOnLendingPool(strikeAssetWithdrawn, msg.sender);
    		}
        }
        if (underlyingWithdrawn > 0) {
		    ACOAssetHelper._transferAsset(underlying, msg.sender, underlyingWithdrawn);
        }
    }

	function _getCollateralNormalized(bool isDeposit) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralLockedRedeemable
    ) {
        uint256 collateralLocked;
        uint256 collateralOnOpenPosition;
        (underlyingBalance, strikeAssetBalance, collateralBalance, collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getCollateralData(isDeposit);
        collateralBalance = collateralBalance.add(collateralLocked).sub(collateralOnOpenPosition);
    }

	function _getCollateralData(bool isDeposit) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		uint256 underlyingPrice = _getPrice(underlying, strikeAsset);
		(underlyingBalance, strikeAssetBalance, collateralBalance) = _getBaseCollateralData(underlyingPrice, isDeposit);
		(collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _poolOpenPositionCollateralBalance(underlyingPrice, isDeposit);
	}
	
	function _getBaseCollateralData(
	    uint256 underlyingPrice,
	    bool isDeposit
	) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance
    ) {
        (underlyingBalance, strikeAssetBalance, collateralBalance) = ACOPoolLib.getBaseCollateralData(
            lendingToken,
            underlying, 
            strikeAsset, 
            isCall, 
            underlyingPrice, 
            underlyingPriceAdjustPercentage, 
            underlyingPrecision, 
            isDeposit
        );
    }

	function _poolOpenPositionCollateralBalance(uint256 underlyingPrice, bool isDeposit) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        ACOPoolLib.OpenPositionData memory openPositionData = ACOPoolLib.OpenPositionData(
            underlyingPrice,
            baseVolatility,
            underlyingPriceAdjustPercentage,
            fee,
            underlyingPrecision,
            strategy,
            address(acoFactory),
            address(0)
        );
		for (uint256 i = 0; i < openAcos.length; ++i) {
			address acoToken = openAcos[i];
            
            openPositionData.acoToken = acoToken;
            (uint256 locked, uint256 openPosition, uint256 lockedRedeemable) = ACOPoolLib.getOpenPositionCollateralBalance(openPositionData);
            
            collateralLocked = collateralLocked.add(locked);
            collateralOnOpenPosition = collateralOnOpenPosition.add(openPosition);
            collateralLockedRedeemable = collateralLockedRedeemable.add(lockedRedeemable);
		}
		if (!isDeposit) {
			collateralOnOpenPosition = collateralOnOpenPosition.mul(PERCENTAGE_PRECISION.add(withdrawOpenPositionPenalty)).div(PERCENTAGE_PRECISION);
		}
	}
    
    function _getAmountToNoLockedWithdraw(
        uint256 shares, 
        uint256 _totalSupply, 
        uint256 minCollateral,
        bool _isCall
    ) internal view returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (uint256 underlyingBalance, 
         uint256 strikeAssetBalance, 
         uint256 collateralBalance,) = _getCollateralNormalized(false);

        (underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getAmountToNoLockedWithdraw(shares, _totalSupply, underlyingBalance, strikeAssetBalance, collateralBalance, minCollateral, _isCall);
    }

	function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }

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
        uint256 remaining = swapPrice.sub(protocolFee);
        
        if (!isCall) {
            _withdrawOnLendingPool(collateralAmount.sub(remaining), address(this));
        }
        
		address _collateral = collateral();
        IACOPool2.AcoData storage data = acoData[acoToken];
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
			acoData[acoToken] = IACOPool2.AcoData(true, remaining, collateralAmount, 0, acoTokens.length, openAcos.length);
            acoTokens.push(acoToken);    
            openAcos.push(acoToken);   
        } else {
			data.collateralLocked = collateralAmount.add(data.collateralLocked);
			data.valueSold = remaining.add(data.valueSold);
		}
        
        ACOAssetHelper._callTransferERC20(acoToken, to, tokenAmount);
    }

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

    function _depositOnLendingPool(uint256 amount) internal {
        lendingPool.deposit(strikeAsset, amount, address(this), lendingPoolReferral);
    }

    function _withdrawOnLendingPool(uint256 amount, address to) internal {
        lendingPool.withdraw(strikeAsset, amount, to);
    }

	function _acoBasicDataIsValid(address acoToken, address _underlying, address _strikeAsset, bool _isCall) internal view returns(bool) {
		return _underlying == underlying && _strikeAsset == strikeAsset && _isCall == isCall && validAcoCreators[acoFactory.creators(acoToken)];
	}

	function _getPoolBalanceOf(address asset) internal view returns(uint256) {
        return ACOAssetHelper._getAssetBalanceOf(asset, address(this));
    }
	
	function _getPrice(address _underlying, address _strikeAsset) internal view returns(uint256) {
	    return assetConverter.getPrice(_underlying, _strikeAsset);
	}

	function _setAuthorizedSpender(address asset, address spender) internal {
        ACOAssetHelper._callApproveERC20(asset, spender, ACOAssetHelper.MAX_UINT);
    }

    function _setPoolDataForAcoPermission(
        uint256 newTolerancePriceBelow, 
        uint256 newTolerancePriceAbove,
        uint256 newMinExpiration,
        uint256 newMaxExpiration
    ) internal {
        require(newTolerancePriceBelow < PERCENTAGE_PRECISION, "E81");
        require(newTolerancePriceAbove < PERCENTAGE_PRECISION, "E82");
        require(newMaxExpiration >= newMinExpiration, "E83");
        
        emit SetPoolDataForAcoPermission(tolerancePriceBelow, tolerancePriceAbove, minExpiration, maxExpiration, newTolerancePriceBelow, newTolerancePriceAbove, newMinExpiration, newMaxExpiration);
        
        tolerancePriceBelow = newTolerancePriceBelow;
        tolerancePriceAbove = newTolerancePriceAbove;
        minExpiration = newMinExpiration;
        maxExpiration = newMaxExpiration;
    }

    function _setBaseVolatility(uint256 newBaseVolatility) internal {
        require(newBaseVolatility > 0, "E84");
        emit SetBaseVolatility(baseVolatility, newBaseVolatility);
        baseVolatility = newBaseVolatility;
    }
    
    function _setStrategy(address newStrategy) internal {
        require(IACOPoolFactory2(owner()).strategyPermitted(newStrategy), "E85");
        emit SetStrategy(address(strategy), newStrategy);
        strategy = newStrategy;
    }

    function _setPoolAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "E86");
        emit SetPoolAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function _setValidAcoCreator(address creator, bool newPermission) internal {
        emit SetValidAcoCreator(creator, validAcoCreators[creator], newPermission);
        validAcoCreators[creator] = newPermission;
    }
    
    function _setProtocolConfig(IACOPool2.PoolProtocolConfig memory newConfig) internal {
        address _underlying = underlying;
        address _strikeAsset = strikeAsset;
		require(IACOAssetConverterHelper(newConfig.assetConverter).getPrice(_underlying, _strikeAsset) > 0, "E87");
        require(newConfig.feeDestination != address(0), "E88");
        require(newConfig.fee <= 12500, "E89");
        require(newConfig.withdrawOpenPositionPenalty <= PERCENTAGE_PRECISION, "E90");
        require(newConfig.underlyingPriceAdjustPercentage < PERCENTAGE_PRECISION, "E91");
        require(newConfig.maximumOpenAco > 0, "E92");
        		
		if (isCall) {
            if (!ACOAssetHelper._isEther(_strikeAsset)) {
                _setAuthorizedSpender(_strikeAsset, newConfig.assetConverter);
            }
        } else if (!ACOAssetHelper._isEther(_underlying)) {
            _setAuthorizedSpender(_underlying, newConfig.assetConverter);
        }
        
        emit SetProtocolConfig(IACOPool2.PoolProtocolConfig(lendingPoolReferral, withdrawOpenPositionPenalty, underlyingPriceAdjustPercentage, fee, maximumOpenAco, feeDestination, address(assetConverter)), newConfig);
        
        assetConverter = IACOAssetConverterHelper(newConfig.assetConverter);
        lendingPoolReferral = newConfig.lendingPoolReferral;
        feeDestination = newConfig.feeDestination;
        fee = newConfig.fee;
        withdrawOpenPositionPenalty = newConfig.withdrawOpenPositionPenalty;
        underlyingPriceAdjustPercentage = newConfig.underlyingPriceAdjustPercentage;
        maximumOpenAco = newConfig.maximumOpenAco;
    }
    
    function _onlyAdmin() internal view {
        require(admin == msg.sender, "E98");
    }
    
    function _onlyProtocolOwner() internal view {
        require(owner() == msg.sender, "E99");
    }
}