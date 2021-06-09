pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
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
 * E43  | _internalSelling                    | Insufficient ether amount                   *
 *------------------------------------------------------------------------------------------*
 * E44  | _internalSelling                    | Ether is not expected                       *
 *------------------------------------------------------------------------------------------*
 * E45  | _internalSelling                    | The maximum number of open ACOs was reached *
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
 * E81  | _setAcoPermissionConfig             | Invalid below tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E82  | _setAcoPermissionConfig             | Invalid minimum below tolerance percentage  *
 *------------------------------------------------------------------------------------------*
 * E83  | _setAcoPermissionConfig             | Invalid minimum above tolerance percentage  *
 *------------------------------------------------------------------------------------------*
 * E84  | _setAcoPermissionConfig             | Invalid minimum strike price value          *
 *------------------------------------------------------------------------------------------*
 * E85  | _setAcoPermissionConfig             | Invalid expiration range                    *
 *------------------------------------------------------------------------------------------*
 * E86  | _setBaseVolatility                  | Invalid base volatility                     *
 *------------------------------------------------------------------------------------------*
 * E87  | _setStrategy                        | Invalid strategy address                    *
 *------------------------------------------------------------------------------------------*
 * E88  | _setPoolAdmin                       | Invalid pool admin address                  *
 *------------------------------------------------------------------------------------------*
 * E89  | _setProtocolConfig                  | No price on the Oracle                      *
 *------------------------------------------------------------------------------------------*
 * E90  | _setProtocolConfig                  | Invalid fee destination address             *
 *------------------------------------------------------------------------------------------*
 * E91  | _setProtocolConfig                  | Invalid fee value                           *
 *------------------------------------------------------------------------------------------*
 * E92  | _setProtocolConfig                  | Invalid penalty percentage                  *
 *------------------------------------------------------------------------------------------*
 * E93  | _setProtocolConfig                  | Invalid underlying price adjust percentage  *
 *------------------------------------------------------------------------------------------*
 * E94  | _setProtocolConfig                  | Invalid maximum number of open ACOs allowed *
 *------------------------------------------------------------------------------------------*
 * E97  | _privateValidation                  | The pool is public or it is a pool admin    *
 *------------------------------------------------------------------------------------------*
 * E98  | _onlyPoolAdmin                      | Only the pool admin can call the method     *
 *------------------------------------------------------------------------------------------*
 * E99  | _onlyProtocolOwner                  | Only the pool factory can call the method   *
 ********************************************************************************************
 */
contract ACOPool2 is Ownable, ERC20 {
    
    uint256 internal constant PERCENTAGE_PRECISION = 100000;

    event SetValidAcoCreator(address indexed creator, bool indexed previousPermission, bool indexed newPermission);
    
    event SetForbiddenAcoCreator(address indexed creator, bool indexed previousStatus, bool indexed newStatus);
    
    event SetProtocolConfig(IACOPool2.PoolProtocolConfig oldConfig, IACOPool2.PoolProtocolConfig newConfig);
	
	event SetAcoPermissionConfig(IACOPool2.PoolAcoPermissionConfig oldConfig, IACOPool2.PoolAcoPermissionConfig newConfig);

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

    address public poolAdmin;
	address public strategy;
    uint256 public baseVolatility;
    
    IACOPool2.PoolAcoPermissionConfig public acoPermissionConfig;
    IACOPool2.PoolProtocolConfig public protocolConfig;
    
    address[] public acoTokens;
    address[] public openAcos;

    mapping(address => bool) public forbiddenAcoCreators;
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
    
    function name() public override virtual view returns(string memory) {
        return "";
    }

	function symbol() public override virtual view returns(string memory) {
        return "";
    }

    function decimals() public override virtual view returns(uint8) {
        return 0;
    }
}

contract ACOPool2V2 is ACOPool2 {
    
	event SetAcoPermissionConfigV2(IACOPool2.PoolAcoPermissionConfigV2 oldConfig, IACOPool2.PoolAcoPermissionConfigV2 newConfig);
	
    bool public isPrivate;
    uint256 public poolId;
    IACOPool2.PoolAcoPermissionConfigV2 public acoPermissionConfigV2;

    function init(IACOPool2.InitData calldata initData) external {
		require(underlying == address(0) && strikeAsset == address(0), "E00");
        require(initData.underlying != initData.strikeAsset, "E01");
        
        super.init();

        acoFactory = IACOFactory(initData.acoFactory);
        lendingPool = ILendingPool(initData.lendingPool);
        underlying = initData.underlying;
        strikeAsset = initData.strikeAsset;
        isCall = initData.isCall;
        isPrivate = initData.isPrivate;
        poolId = initData.poolId;
		
		_setProtocolConfig(initData.protocolConfig);
		_setPoolAdmin(initData.admin);
		_setAcoPermissionConfig(initData.acoPermissionConfigV2);
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
        return ACOPoolLib.name(underlying, strikeAsset, isCall, poolId);
    }

	function symbol() public override view returns(string memory) {
        return name();
    }

    function decimals() public override view returns(uint8) {
        return ACOAssetHelper._getAssetDecimals(collateral());
    }

	function collateral() public view returns(address) {
        return (isCall ? underlying : strikeAsset);
    }

    function numberOfAcoTokensNegotiated() external view returns(uint256) {
        return acoTokens.length;
    }

    function numberOfOpenAcoTokens() external view returns(uint256) {
        return openAcos.length;
    }

    function canSwap(address acoToken) external view returns(bool) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime) = _getAcoData(acoToken);
		if (_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall)) {
            uint256 price = _getPrice(_underlying, _strikeAsset, protocolConfig.assetConverter);
            return ACOPoolLib.acoStrikeAndExpirationIsValid(_strikePrice, _expiryTime, price, acoPermissionConfigV2);
        }
        return false;
    }

	function quote(address acoToken, uint256 tokenAmount) external view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility
    ) {
        IACOPool2.PoolProtocolConfig storage _protocolConfig = protocolConfig;
        (swapPrice, protocolFee, underlyingPrice, volatility,) = _quote(acoToken, tokenAmount, _protocolConfig);
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
    
    function setAcoPermissionConfig(IACOPool2.PoolAcoPermissionConfigV2 calldata newConfig) external {
        _onlyPoolAdmin();
        _setAcoPermissionConfig(newConfig);
    }

	function setBaseVolatility(uint256 newBaseVolatility) external {
        _onlyPoolAdmin();
		_setBaseVolatility(newBaseVolatility);
	}
	
	function setStrategy(address newStrategy) external {
        _onlyPoolAdmin();
		_setStrategy(newStrategy);
	}
	
	function setPoolAdmin(address newAdmin) external {
	    _onlyPoolAdmin();
		_setPoolAdmin(newAdmin);
	}

	function setValidAcoCreator(address acoCreator, bool newPermission) external {
        _onlyProtocolOwner();
        emit SetValidAcoCreator(acoCreator, validAcoCreators[acoCreator], newPermission);
        validAcoCreators[acoCreator] = newPermission;
    }
    
    function setForbiddenAcoCreator(address acoCreator, bool isForbidden) external {
        _onlyProtocolOwner();
        emit SetForbiddenAcoCreator(acoCreator, forbiddenAcoCreators[acoCreator], isForbidden);
        forbiddenAcoCreators[acoCreator] = isForbidden;
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
    
    function withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) external returns (
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

	function swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) external payable {
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
        _onlyPoolAdmin();
        
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
        uint256 collateralRestored = IACOAssetConverterHelper(protocolConfig.assetConverter).swapExactAmountOut{value: etherAmount}(assetOut, assetIn, balanceOut);
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

    function _getAcoData(address acoToken) internal view returns(
        address _underlying, 
        address _strikeAsset, 
        bool _isCall, 
        uint256 strikePrice, 
        uint256 expiryTime
    ) {
        (_underlying, _strikeAsset, _isCall, strikePrice, expiryTime) = acoFactory.acoTokenData(acoToken);
    }

	function _quote(
	    address acoToken, 
	    uint256 tokenAmount, 
	    IACOPool2.PoolProtocolConfig storage _protocolConfig
    ) internal view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        require(tokenAmount > 0, "E50");
        
        ACOPoolLib.AcoData memory _acoData = _getAcoDataForQuote(acoToken, tokenAmount);
        
		require(_acoBasicDataIsValid(acoToken, _acoData.underlying, _acoData.strikeAsset, _acoData.isCall), "E51");
		
		underlyingPrice = _getPrice(_acoData.underlying, _acoData.strikeAsset, _protocolConfig.assetConverter);
		
		(swapPrice, protocolFee, volatility, collateralAmount) = ACOPoolLib.quote(ACOPoolLib.QuoteData(
    		lendingToken,
    		strategy,
    		baseVolatility,
    		_protocolConfig.fee,
    		underlyingPrice,
    		underlyingPrecision,
    		_acoData,
    		acoPermissionConfigV2));
    }
    
    function _getAcoDataForQuote(address acoToken, uint256 tokenAmount) internal view returns(ACOPoolLib.AcoData memory _acoData) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 strikePrice, uint256 expiryTime) = _getAcoData(acoToken);
        _acoData = ACOPoolLib.AcoData(_isCall, strikePrice, expiryTime, tokenAmount, _underlying, _strikeAsset); 
    }
    
	function _deposit(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to,
	    bool isLendingToken
    ) internal returns(uint256 shares) {
        _privateValidation();
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
        IACOPool2.PoolProtocolConfig storage _protocolConfig = protocolConfig;
	    uint256 underlyingPrice = _getPrice(underlying, strikeAsset, _protocolConfig.assetConverter);
        (underlyingBalance, strikeAssetBalance, collateralBalance, collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = ACOPoolLib.getCollateralData(
            ACOPoolLib.OpenPositionData(
                isDeposit,
    	        isCall,
    	        underlyingPrice,
    	        baseVolatility,
    	        _protocolConfig.underlyingPriceAdjustPercentage,
    	        _protocolConfig.withdrawOpenPositionPenalty,
    	        _protocolConfig.fee,
    	        underlyingPrecision,
    	        underlying,
    	        strikeAsset,
    	        strategy,
    	        address(acoFactory),
    	        lendingToken),
	        openAcos);
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
        
        IACOPool2.PoolProtocolConfig storage _protocolConfig = protocolConfig;
        (uint256 swapPrice, uint256 protocolFee, uint256 underlyingPrice, uint256 volatility, uint256 collateralAmount) = _quote(acoToken, tokenAmount, _protocolConfig);
        
        _internalSelling(to, acoToken, collateralAmount, tokenAmount, restriction, swapPrice, protocolFee);

        if (protocolFee > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, _protocolConfig.feeDestination, protocolFee);
        }
        
        emit Swap(to, acoToken, tokenAmount, swapPrice, protocolFee, underlyingPrice, volatility);
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
        
        address _strikeAsset = strikeAsset;
        uint256 extra = 0;
        if (ACOAssetHelper._isEther(_strikeAsset)) {
            require(msg.value >= swapPrice, "E43");
            extra = msg.value.sub(swapPrice);
        } else {
            require(msg.value == 0, "E44");
            ACOAssetHelper._callTransferFromERC20(_strikeAsset, msg.sender, address(this), swapPrice);
        }
        
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
            require(openAcos.length < protocolConfig.maximumOpenAco, "E45");
			acoData[acoToken] = IACOPool2.AcoData(true, remaining, collateralAmount, 0, acoTokens.length, openAcos.length);
            acoTokens.push(acoToken);    
            openAcos.push(acoToken);   
        } else {
			data.collateralLocked = collateralAmount.add(data.collateralLocked);
			data.valueSold = remaining.add(data.valueSold);
		}
        
        ACOAssetHelper._callTransferERC20(acoToken, to, tokenAmount);
        
        if (extra > 0) {
            ACOAssetHelper._transferAsset(_strikeAsset, msg.sender, extra);    
        }
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
        lendingPool.deposit(strikeAsset, amount, address(this), protocolConfig.lendingPoolReferral);
    }

    function _withdrawOnLendingPool(uint256 amount, address to) internal {
        lendingPool.withdraw(strikeAsset, amount, to);
    }

	function _acoBasicDataIsValid(address acoToken, address _underlying, address _strikeAsset, bool _isCall) internal view returns(bool) {
		if (_underlying == underlying && _strikeAsset == strikeAsset && _isCall == isCall) {
		    address creator = acoFactory.creators(acoToken);
		    return (!forbiddenAcoCreators[creator] && (validAcoCreators[address(0)] || validAcoCreators[creator])); 
	    } else {
	        return false;
	    }
	}

	function _getPoolBalanceOf(address asset) internal view returns(uint256) {
        return ACOAssetHelper._getAssetBalanceOf(asset, address(this));
    }
	
	function _getPrice(address _underlying, address _strikeAsset, address assetConverter) internal view returns(uint256) {
	    return IACOAssetConverterHelper(assetConverter).getPrice(_underlying, _strikeAsset);
	}

	function _setAuthorizedSpender(address asset, address spender) internal {
        ACOAssetHelper._callApproveERC20(asset, spender, ACOAssetHelper.MAX_UINT);
    }

    function _setAcoPermissionConfig(IACOPool2.PoolAcoPermissionConfigV2 memory newConfig) internal {
        require(newConfig.tolerancePriceBelowMax < int256(PERCENTAGE_PRECISION) && newConfig.tolerancePriceBelowMin < int256(PERCENTAGE_PRECISION), "E81");
        require(newConfig.tolerancePriceBelowMin < newConfig.tolerancePriceBelowMax || newConfig.tolerancePriceBelowMax < int256(0), "E82");
        require(newConfig.tolerancePriceAboveMin < newConfig.tolerancePriceAboveMax || newConfig.tolerancePriceAboveMax < int256(0), "E83");
        require(newConfig.minStrikePrice < newConfig.maxStrikePrice || newConfig.maxStrikePrice == 0, "E84");
        require(newConfig.minExpiration <= newConfig.maxExpiration, "E85");
        
        emit SetAcoPermissionConfigV2(acoPermissionConfigV2, newConfig);
        
        acoPermissionConfigV2 = newConfig;
    }

    function _setBaseVolatility(uint256 newBaseVolatility) internal {
        require(newBaseVolatility > 0, "E86");
        emit SetBaseVolatility(baseVolatility, newBaseVolatility);
        baseVolatility = newBaseVolatility;
    }
    
    function _setStrategy(address newStrategy) internal {
        require(IACOPoolFactory2(owner()).strategyPermitted(newStrategy), "E87");
        emit SetStrategy(address(strategy), newStrategy);
        strategy = newStrategy;
    }

    function _setPoolAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "E88");
        emit SetPoolAdmin(poolAdmin, newAdmin);
        poolAdmin = newAdmin;
    }

    function _setProtocolConfig(IACOPool2.PoolProtocolConfig memory newConfig) internal {
        address _underlying = underlying;
        address _strikeAsset = strikeAsset;
		require(IACOAssetConverterHelper(newConfig.assetConverter).getPrice(_underlying, _strikeAsset) > 0, "E89");
        require(newConfig.feeDestination != address(0), "E90");
        require(newConfig.fee <= 12500, "E91");
        require(newConfig.withdrawOpenPositionPenalty <= PERCENTAGE_PRECISION, "E92");
        require(newConfig.underlyingPriceAdjustPercentage < PERCENTAGE_PRECISION, "E93");
        require(newConfig.maximumOpenAco > 0, "E94");
        		
		if (isCall) {
            if (!ACOAssetHelper._isEther(_strikeAsset)) {
                _setAuthorizedSpender(_strikeAsset, newConfig.assetConverter);
            }
        } else if (!ACOAssetHelper._isEther(_underlying)) {
            _setAuthorizedSpender(_underlying, newConfig.assetConverter);
        }
        
        emit SetProtocolConfig(protocolConfig, newConfig);
        
        protocolConfig = newConfig;
    }
    
    function _privateValidation() internal view {
        require(!isPrivate || poolAdmin == msg.sender, "E97");
    }
    
    function _onlyPoolAdmin() internal view {
        require(poolAdmin == msg.sender, "E98");
    }
    
    function _onlyProtocolOwner() internal view {
        require(owner() == msg.sender, "E99");
    }
}