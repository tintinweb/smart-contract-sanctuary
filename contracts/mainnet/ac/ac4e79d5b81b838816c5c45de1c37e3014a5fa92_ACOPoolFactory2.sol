pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./IACOPool2.sol";

/**
 * @title ACOPoolFactory
 * @dev The contract is the implementation for the ACOProxy.
 */
contract ACOPoolFactory2 {
    
    /**
     * @dev Struct to store the ACO pool basic data.
     */
    struct ACOPoolBasicData {
        
        /**
         * @dev Address of the underlying asset (0x0 for Ethereum).
         */
        address underlying;
        
        /**
         * @dev Address of the strike asset (0x0 for Ethereum).
         */
        address strikeAsset;
        
        /**
         * @dev True if the type is CALL, false for PUT.
         */
        bool isCall;
    }
    
    /**
     * @dev Emitted when the factory admin address has been changed.
     * @param previousFactoryAdmin Address of the previous factory admin.
     * @param newFactoryAdmin Address of the new factory admin.
     */
    event SetFactoryAdmin(address indexed previousFactoryAdmin, address indexed newFactoryAdmin);
    
    /**
     * @dev Emitted when the ACO pool implementation has been changed.
     * @param previousAcoPoolImplementation Address of the previous ACO pool implementation.
     * @param previousAcoPoolImplementation Address of the new ACO pool implementation.
     */
    event SetAcoPoolImplementation(address indexed previousAcoPoolImplementation, address indexed newAcoPoolImplementation);
    
    /**
     * @dev Emitted when the ACO factory has been changed.
     * @param previousAcoFactory Address of the previous ACO factory.
     * @param newAcoFactory Address of the new ACO factory.
     */
    event SetAcoFactory(address indexed previousAcoFactory, address indexed newAcoFactory);
    
    /**
     * @dev Emitted when the Chi Token has been changed.
     * @param previousChiToken Address of the previous Chi Token.
     * @param newChiToken Address of the new Chi Token.
     */
    event SetChiToken(address indexed previousChiToken, address indexed newChiToken);
    
    /**
     * @dev Emitted when the asset converter helper has been changed.
     * @param previousAssetConverterHelper Address of the previous asset converter helper.
     * @param newAssetConverterHelper Address of the new asset converter helper.
     */
    event SetAssetConverterHelper(address indexed previousAssetConverterHelper, address indexed newAssetConverterHelper);
    
    /**
     * @dev Emitted when the ACO Pool fee has been changed.
     * @param previousAcoFee Value of the previous ACO Pool fee.
     * @param newAcoFee Value of the new ACO Pool fee.
     */
    event SetAcoPoolFee(uint256 indexed previousAcoFee, uint256 indexed newAcoFee);
    
    /**
     * @dev Emitted when the ACO Pool fee destination address has been changed.
     * @param previousAcoPoolFeeDestination Address of the previous ACO Pool fee destination.
     * @param newAcoPoolFeeDestination Address of the new ACO Pool fee destination.
     */
    event SetAcoPoolFeeDestination(address indexed previousAcoPoolFeeDestination, address indexed newAcoPoolFeeDestination);
     
    /**
     * @dev Emitted when the ACO Pool penalty percentage on withdrawing open positions has been changed.
     * @param previousWithdrawOpenPositionPenalty Value of the previous penalty percentage on withdrawing open positions.
     * @param newWithdrawOpenPositionPenalty Value of the new penalty percentage on withdrawing open positions.
     */
    event SetAcoPoolWithdrawOpenPositionPenalty(uint256 indexed previousWithdrawOpenPositionPenalty, uint256 indexed newWithdrawOpenPositionPenalty);
	
    /**
     * @dev Emitted when the ACO Pool underlying price percentage adjust has been changed.
     * @param previousUnderlyingPriceAdjustPercentage Value of the previous ACO Pool underlying price percentage adjust.
     * @param newUnderlyingPriceAdjustPercentage Value of the new ACO Pool underlying price percentage adjust.
     */
    event SetAcoPoolUnderlyingPriceAdjustPercentage(uint256 indexed previousUnderlyingPriceAdjustPercentage, uint256 indexed newUnderlyingPriceAdjustPercentage);
	
    /**
     * @dev Emitted when the ACO Pool maximum number of open ACOs allowed has been changed.
     * @param previousMaximumOpenAco Value of the previous ACO Pool maximum number of open ACOs allowed.
     * @param newMaximumOpenAco Value of the new ACO Pool maximum number of open ACOs allowed.
     */
    event SetAcoPoolMaximumOpenAco(uint256 indexed previousMaximumOpenAco, uint256 indexed newMaximumOpenAco);
	
    /**
     * @dev Emitted when permission for an ACO pool admin has been changed.
     * @param poolAdmin Address of the ACO pool admin.
     * @param previousPermission The previous permission situation.
     * @param newPermission The new permission situation.
     */
    event SetAcoPoolPermission(address indexed poolAdmin, bool indexed previousPermission, bool indexed newPermission);
    
    /**
     * @dev Emitted when a strategy permission has been changed.
     * @param strategy Address of the strategy.
     * @param previousPermission The previous strategy permission.
     * @param newPermission The new strategy permission.
     */
    event SetStrategyPermission(address indexed strategy, bool indexed previousPermission, bool newPermission);

    /**
     * @dev Emitted when a new ACO pool has been created.
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param acoPool Address of the new ACO pool created.
     * @param acoPoolImplementation Address of the ACO pool implementation used on creation.
     */
    event NewAcoPool(address indexed underlying, address indexed strikeAsset, bool indexed isCall, address acoPool, address acoPoolImplementation);
    
    /**
     * @dev The factory admin address.
     */
    address public factoryAdmin;
    
    /**
     * @dev The ACO pool implementation address.
     */
    address public acoPoolImplementation;
    
    /**
     * @dev The ACO factory address.
     */
    address public acoFactory;
    
	/**
     * @dev The ACO asset converter helper.
     */
    address public assetConverterHelper;
    
    /**
     * @dev The Chi Token address.
     */
    address public chiToken;
    
    /**
     * @dev The ACO Pool fee value. 
     * It is a percentage value (100000 is 100%).
     */
    uint256 public acoPoolFee;
    
    /**
     * @dev The ACO Pool fee destination address.
     */
    address public acoPoolFeeDestination;
      
    /**
     * @dev The ACO Pool penalty percentage on withdrawing open positions.
     */
    uint256 public acoPoolWithdrawOpenPositionPenalty;
	  
    /**
     * @dev The ACO Pool underlying price percentage adjust.
     */
    uint256 public acoPoolUnderlyingPriceAdjustPercentage;

    /**
     * @dev The ACO Pool maximum number of open ACOs allowed.
     */
    uint256 public acoPoolMaximumOpenAco;

    /**
     * @dev The ACO pool admin permissions.
     */
    mapping(address => bool) public poolAdminPermission;
    
    /**
     * @dev The strategies permitted.
     */
    mapping(address => bool) public strategyPermitted;
    
    /**
     * @dev The ACO pool basic data.
     */
    mapping(address => ACOPoolBasicData) public acoPoolBasicData;
    
    /**
     * @dev Modifier to check if the `msg.sender` is the factory admin.
     * Only factory admin address can execute.
     */
    modifier onlyFactoryAdmin() {
        require(msg.sender == factoryAdmin, "ACOPoolFactory::onlyFactoryAdmin");
        _;
    }
    
    /**
     * @dev Modifier to check if the `msg.sender` is a pool admin.
     * Only a pool admin address can execute.
     */
    modifier onlyPoolAdmin() {
        require(poolAdminPermission[msg.sender], "ACOPoolFactory::onlyPoolAdmin");
        _;
    }
    
    /**
     * @dev Function to initialize the contract.
     * It should be called through the `data` argument when creating the proxy.
     * It must be called only once. The first `require` is to guarantee that behavior.
     * @param _factoryAdmin Address of the factory admin.
     * @param _acoPoolImplementation Address of the ACO pool implementation.
     * @param _acoFactory Address of the ACO token factory.
     * @param _assetConverterHelper Address of the asset converter helper.
	 * @param _chiToken Address of the Chi token.
	 * @param _acoPoolFee ACO pool fee percentage.
	 * @param _acoPoolFeeDestination ACO pool fee destination.
	 * @param _acoPoolWithdrawOpenPositionPenalty ACO pool penalty percentage on withdrawing open positions.
	 * @param _acoPoolUnderlyingPriceAdjustPercentage ACO pool underlying price percentage adjust.
     * @param _acoPoolMaximumOpenAco ACO pool maximum number of open ACOs allowed.
     */
    function init(
        address _factoryAdmin, 
        address _acoPoolImplementation, 
        address _acoFactory, 
        address _assetConverterHelper,
        address _chiToken,
        uint256 _acoPoolFee,
        address _acoPoolFeeDestination,
		uint256 _acoPoolWithdrawOpenPositionPenalty,
		uint256 _acoPoolUnderlyingPriceAdjustPercentage,
        uint256 _acoPoolMaximumOpenAco
    ) public {
        require(factoryAdmin == address(0) && acoPoolImplementation == address(0), "ACOPoolFactory::init: Contract already initialized.");
        
        _setFactoryAdmin(_factoryAdmin);
        _setAcoPoolImplementation(_acoPoolImplementation);
        _setAcoFactory(_acoFactory);
        _setAssetConverterHelper(_assetConverterHelper);
        _setChiToken(_chiToken);
        _setAcoPoolFee(_acoPoolFee);
        _setAcoPoolFeeDestination(_acoPoolFeeDestination);
		_setAcoPoolWithdrawOpenPositionPenalty(_acoPoolWithdrawOpenPositionPenalty);
		_setAcoPoolUnderlyingPriceAdjustPercentage(_acoPoolUnderlyingPriceAdjustPercentage);
        _setAcoPoolMaximumOpenAco(_acoPoolMaximumOpenAco);
        _setAcoPoolPermission(_factoryAdmin, true);
    }

    /**
     * @dev Function to guarantee that the contract will not receive ether.
     */
    receive() external payable virtual {
        revert();
    }

    /**
     * @dev Function to create a new ACO pool.
     * It deploys a minimal proxy for the ACO pool implementation address. 
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param tolerancePriceBelow The below tolerance price percentage for ACO tokens.
     * @param tolerancePriceAbove The above tolerance price percentage for ACO tokens.
     * @param minExpiration The minimum expiration seconds after the current time for ACO tokens.
     * @param maxExpiration The maximum expiration seconds after the current time for ACO tokens.
     * @param strategy Address of the pool strategy to be used.
     * @param baseVolatility The base volatility for the pool starts. It is a percentage value (100000 is 100%).
     * @return The created ACO pool address.
     */
    function createAcoPool(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 tolerancePriceBelow,
        uint256 tolerancePriceAbove,
        uint256 minExpiration,
        uint256 maxExpiration,
        address strategy,
        uint256 baseVolatility
    ) onlyFactoryAdmin external virtual returns(address) {
        _validateStrategy(strategy);
        return _createAcoPool(IACOPool2.InitData(
            acoFactory,
            chiToken,
            underlying, 
            strikeAsset,
            isCall,
			assetConverterHelper,
            acoPoolFee,
            acoPoolFeeDestination,
			acoPoolWithdrawOpenPositionPenalty,
			acoPoolUnderlyingPriceAdjustPercentage,
            acoPoolMaximumOpenAco,
            tolerancePriceBelow,
            tolerancePriceAbove,
            minExpiration,
            maxExpiration,
            strategy,
            baseVolatility
        ));
    }

    /**
     * @dev Function to set the factory admin address.
     * Only can be called by the factory admin.
     * @param newFactoryAdmin Address of the new factory admin.
     */
    function setFactoryAdmin(address newFactoryAdmin) onlyFactoryAdmin external virtual {
        _setFactoryAdmin(newFactoryAdmin);
    }
    
    /**
     * @dev Function to set the ACO pool implementation address.
     * Only can be called by the factory admin.
     * @param newAcoPoolImplementation Address of the new ACO pool implementation.
     */
    function setAcoPoolImplementation(address newAcoPoolImplementation) onlyFactoryAdmin external virtual {
        _setAcoPoolImplementation(newAcoPoolImplementation);
    }
    
    /**
     * @dev Function to set the ACO factory address.
     * Only can be called by the factory admin.
     * @param newAcoFactory Address of the ACO token factory.
     */
    function setAcoFactory(address newAcoFactory) onlyFactoryAdmin external virtual {
        _setAcoFactory(newAcoFactory);
    }
    
    /**
     * @dev Function to set the Chi Token address.
     * Only can be called by the factory admin.
     * @param newChiToken Address of the new Chi Token.
     */
    function setChiToken(address newChiToken) onlyFactoryAdmin external virtual {
        _setChiToken(newChiToken);
    }
    
	/**
     * @dev Function to set the asset converter helper address.
     * Only can be called by the factory admin.
     * @param newAssetConverterHelper Address of the new asset converter helper.
     */
    function setAssetConverterHelper(address newAssetConverterHelper) onlyFactoryAdmin external virtual {
        _setAssetConverterHelper(newAssetConverterHelper);
    }
    
    /**
     * @dev Function to set the ACO Pool fee.
     * Only can be called by the factory admin.
     * @param newAcoPoolFee Value of the new ACO Pool fee. It is a percentage value (100000 is 100%).
     */
    function setAcoPoolFee(uint256 newAcoPoolFee) onlyFactoryAdmin external virtual {
        _setAcoPoolFee(newAcoPoolFee);
    }
    
    /**
     * @dev Function to set the ACO Pool destination address.
     * Only can be called by the factory admin.
     * @param newAcoPoolFeeDestination Address of the new ACO Pool destination.
     */
    function setAcoPoolFeeDestination(address newAcoPoolFeeDestination) onlyFactoryAdmin external virtual {
        _setAcoPoolFeeDestination(newAcoPoolFeeDestination);
    }
    
	/**
     * @dev Function to set the ACO Pool penalty percentage on withdrawing open positions.
     * Only can be called by the factory admin.
     * @param newWithdrawOpenPositionPenalty Value of the new ACO Pool penalty percentage on withdrawing open positions. It is a percentage value (100000 is 100%).
     */
    function setAcoPoolWithdrawOpenPositionPenalty(uint256 newWithdrawOpenPositionPenalty) onlyFactoryAdmin external virtual {
        _setAcoPoolWithdrawOpenPositionPenalty(newWithdrawOpenPositionPenalty);
    }
	
	/**
     * @dev Function to set the ACO Pool underlying price percentage adjust.
     * Only can be called by the factory admin.
     * @param newUnderlyingPriceAdjustPercentage Value of the new ACO Pool underlying price percentage adjust. It is a percentage value (100000 is 100%).
     */
    function setAcoPoolUnderlyingPriceAdjustPercentage(uint256 newUnderlyingPriceAdjustPercentage) onlyFactoryAdmin external virtual {
        _setAcoPoolUnderlyingPriceAdjustPercentage(newUnderlyingPriceAdjustPercentage);
    }

    /**
     * @dev Function to set the ACO Pool maximum number of open ACOs allowed.
     * Only can be called by the factory admin.
     * @param newMaximumOpenAco Value of the new ACO Pool maximum number of open ACOs allowed.
     */
    function setAcoPoolMaximumOpenAco(uint256 newMaximumOpenAco) onlyFactoryAdmin external virtual {
        _setAcoPoolMaximumOpenAco(newMaximumOpenAco);
    }
	
    /**
     * @dev Function to set the ACO pool permission.
     * Only can be called by the factory admin.
     * @param poolAdmin Address of the pool admin.
     * @param newPermission The permission to be set.
     */
    function setAcoPoolPermission(address poolAdmin, bool newPermission) onlyFactoryAdmin external virtual {
        _setAcoPoolPermission(poolAdmin, newPermission);
    }
    
    /**
     * @dev Function to set the ACO pool strategies permitted.
     * Only can be called by the factory admin.
     * @param strategy Address of the strategy.
     * @param newPermission The permission to be set.
     */
    function setAcoPoolStrategyPermission(address strategy, bool newPermission) onlyFactoryAdmin external virtual {
        _setAcoPoolStrategyPermission(strategy, newPermission);
    }
	
	/**
     * @dev Function to change the ACO pools strategy.
     * Only can be called by a pool admin.
     * @param strategy Address of the strategy to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setStrategyOnAcoPool(address strategy, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setStrategyOnAcoPool(strategy, acoPools);
    }
    
    /**
     * @dev Function to change the ACO pools base volatilities.
     * Only can be called by a pool admin.
     * @param baseVolatilities Array of the base volatilities to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setBaseVolatilityOnAcoPool(uint256[] calldata baseVolatilities, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setBaseVolatility.selector, baseVolatilities, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools penalties percentages on withdrawing open positions.
     * Only can be called by a pool admin.
     * @param withdrawOpenPositionPenalties Array of the penalties percentages on withdrawing open positions to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setWithdrawOpenPositionPenaltyOnAcoPool(uint256[] calldata withdrawOpenPositionPenalties, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setWithdrawOpenPositionPenalty.selector, withdrawOpenPositionPenalties, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools underlying prices percentages adjust.
     * Only can be called by a pool admin.
     * @param underlyingPriceAdjustPercentages Array of the underlying prices percentages to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setUnderlyingPriceAdjustPercentageOnAcoPool(uint256[] calldata underlyingPriceAdjustPercentages, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setUnderlyingPriceAdjustPercentage.selector, underlyingPriceAdjustPercentages, acoPools);
    }

    /**
     * @dev Function to change the ACO pools maximum number of open ACOs allowed.
     * Only can be called by a pool admin.
     * @param maximumOpenAcos Array of the maximum number of open ACOs allowed.
     * @param acoPools Array of ACO pools addresses.
     */
    function setMaximumOpenAcoOnAcoPool(uint256[] calldata maximumOpenAcos, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setMaximumOpenAco.selector, maximumOpenAcos, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools below tolerance prices percentages.
     * Only can be called by a pool admin.
     * @param tolerancePricesBelow Array of the below tolerance prices percentages to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setTolerancePriceBelowOnAcoPool(uint256[] calldata tolerancePricesBelow, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setTolerancePriceBelow.selector, tolerancePricesBelow, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools above tolerance prices percentages.
     * Only can be called by a pool admin.
     * @param tolerancePricesAbove Array of the above tolerance prices percentages to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setTolerancePriceAboveOnAcoPool(uint256[] calldata tolerancePricesAbove, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setTolerancePriceAbove.selector, tolerancePricesAbove, acoPools);
    }

	/**
     * @dev Function to change the ACO pools minimum expirations.
     * Only can be called by a pool admin.
     * @param minExpirations Array of the minimum expirations.
     * @param acoPools Array of ACO pools addresses.
     */
    function setMinExpirationOnAcoPool(uint256[] calldata minExpirations, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setMinExpiration.selector, minExpirations, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools maximum expirations.
     * Only can be called by a pool admin.
     * @param maxExpirations Array of the maximum expirations to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setMaxExpirationOnAcoPool(uint256[] calldata maxExpirations, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setMaxExpiration.selector, maxExpirations, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools fee.
     * Only can be called by a pool admin.
     * @param fees Array of the fees.
     * @param acoPools Array of ACO pools addresses.
     */
    function setFeeOnAcoPool(uint256[] calldata fees, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolUint256Data(IACOPool2.setFee.selector, fees, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools fee destinations.
     * Only can be called by a pool admin.
     * @param feeDestinations Array of the fee destinations.
     * @param acoPools Array of ACO pools addresses.
     */
    function setFeeDestinationOnAcoPool(address[] calldata feeDestinations, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolAddressData(IACOPool2.setFeeDestination.selector, feeDestinations, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools asset converters.
     * Only can be called by a pool admin.
     * @param assetConverters Array of the asset converters.
     * @param acoPools Array of ACO pools addresses.
     */
    function setAssetConverterOnAcoPool(address[] calldata assetConverters, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolAddressData(IACOPool2.setAssetConverter.selector, assetConverters, acoPools);
    }
	
	/**
     * @dev Function to change the ACO pools ACO creator permission.
     * Only can be called by a pool admin.
     * @param acoCreator Address of the ACO creator.
	 * @param permission Permission situation.
     * @param acoPools Array of ACO pools addresses.
     */
	function setValidAcoCreatorOnAcoPool(address acoCreator, bool permission, address[] calldata acoPools) onlyPoolAdmin external virtual {
		_setValidAcoCreatorOnAcoPool(acoCreator, permission, acoPools);
	}
	
	/**
     * @dev Function to withdraw the ACO pools stucked asset.
     * @param asset Address of the asset.
	 * @param destination Address of the destination.
     * @param acoPools Array of ACO pools addresses.
     */
    function withdrawStuckAssetOnAcoPool(address asset, address destination, address[] calldata acoPools) onlyPoolAdmin external virtual {
		_withdrawStuckAssetOnAcoPool(asset, destination, acoPools);
	}
	
    /**
     * @dev Internal function to set the factory admin address.
     * @param newFactoryAdmin Address of the new factory admin.
     */
    function _setFactoryAdmin(address newFactoryAdmin) internal virtual {
        require(newFactoryAdmin != address(0), "ACOPoolFactory::_setFactoryAdmin: Invalid factory admin");
        emit SetFactoryAdmin(factoryAdmin, newFactoryAdmin);
        factoryAdmin = newFactoryAdmin;
    }
    
    /**
     * @dev Internal function to set the ACO pool implementation address.
     * @param newAcoPoolImplementation Address of the new ACO pool implementation.
     */
    function _setAcoPoolImplementation(address newAcoPoolImplementation) internal virtual {
        require(Address.isContract(newAcoPoolImplementation), "ACOPoolFactory::_setAcoPoolImplementation: Invalid ACO pool implementation");
        emit SetAcoPoolImplementation(acoPoolImplementation, newAcoPoolImplementation);
        acoPoolImplementation = newAcoPoolImplementation;
    }
    
    /**
     * @dev Internal function to set the ACO factory address.
     * @param newAcoFactory Address of the new ACO token factory.
     */
    function _setAcoFactory(address newAcoFactory) internal virtual {
        require(Address.isContract(newAcoFactory), "ACOPoolFactory::_setAcoFactory: Invalid ACO factory");
        emit SetAcoFactory(acoFactory, newAcoFactory);
        acoFactory = newAcoFactory;
    }
    
    /**
     * @dev Internal function to set the asset converter helper address.
     * @param newAssetConverterHelper Address of the new asset converter helper.
     */
    function _setAssetConverterHelper(address newAssetConverterHelper) internal virtual {
        require(Address.isContract(newAssetConverterHelper), "ACOPoolFactory::_setAssetConverterHelper: Invalid asset converter helper");
        emit SetAssetConverterHelper(assetConverterHelper, newAssetConverterHelper);
        assetConverterHelper = newAssetConverterHelper;
    }
    
    /**
     * @dev Internal function to set the Chi Token address.
     * @param newChiToken Address of the new Chi Token.
     */
    function _setChiToken(address newChiToken) internal virtual {
        require(Address.isContract(newChiToken), "ACOPoolFactory::_setChiToken: Invalid Chi Token");
        emit SetChiToken(chiToken, newChiToken);
        chiToken = newChiToken;
    }
    
    /**
     * @dev Internal function to set the ACO Pool fee.
     * @param newAcoPoolFee Value of the new ACO Pool fee. It is a percentage value (100000 is 100%).
     */
    function _setAcoPoolFee(uint256 newAcoPoolFee) internal virtual {
        emit SetAcoPoolFee(acoPoolFee, newAcoPoolFee);
        acoPoolFee = newAcoPoolFee;
    }
    
    /**
     * @dev Internal function to set the ACO Pool destination address.
     * @param newAcoPoolFeeDestination Address of the new ACO Pool destination.
     */
    function _setAcoPoolFeeDestination(address newAcoPoolFeeDestination) internal virtual {
        require(newAcoPoolFeeDestination != address(0), "ACOFactory::_setAcoPoolFeeDestination: Invalid ACO Pool fee destination");
        emit SetAcoPoolFeeDestination(acoPoolFeeDestination, newAcoPoolFeeDestination);
        acoPoolFeeDestination = newAcoPoolFeeDestination;
    }
    
    /**
     * @dev Internal function to set the ACO Pool penalty percentage on withdrawing open positions.
     * @param newWithdrawOpenPositionPenalty Value of the new ACO Pool penalty percentage on withdrawing open positions. It is a percentage value (100000 is 100%).
     */
    function _setAcoPoolWithdrawOpenPositionPenalty(uint256 newWithdrawOpenPositionPenalty) internal virtual {
        emit SetAcoPoolWithdrawOpenPositionPenalty(acoPoolWithdrawOpenPositionPenalty, newWithdrawOpenPositionPenalty);
        acoPoolWithdrawOpenPositionPenalty = newWithdrawOpenPositionPenalty;
    }
    
    /**
     * @dev Internal function to set the ACO Pool underlying price percentage adjust.
     * @param newUnderlyingPriceAdjustPercentage Value of the new ACO Pool underlying price percentage adjust. It is a percentage value (100000 is 100%).
     */
    function _setAcoPoolUnderlyingPriceAdjustPercentage(uint256 newUnderlyingPriceAdjustPercentage) internal virtual {
        emit SetAcoPoolUnderlyingPriceAdjustPercentage(acoPoolUnderlyingPriceAdjustPercentage, newUnderlyingPriceAdjustPercentage);
        acoPoolUnderlyingPriceAdjustPercentage = newUnderlyingPriceAdjustPercentage;
    }

    /**
     * @dev Internal function to set the ACO Pool maximum number of open ACOs allowed.
     * @param newMaximumOpenAco Value of the new ACO Pool maximum number of open ACOs allowed.
     */
    function _setAcoPoolMaximumOpenAco(uint256 newMaximumOpenAco) internal virtual {
        emit SetAcoPoolMaximumOpenAco(acoPoolMaximumOpenAco, newMaximumOpenAco);
        acoPoolMaximumOpenAco = newMaximumOpenAco;
    }
    
    /**
     * @dev Internal function to set the ACO pool permission.
     * @param poolAdmin Address of the pool admin.
     * @param newPermission The permission to be set.
     */
    function _setAcoPoolPermission(address poolAdmin, bool newPermission) internal virtual {
        emit SetAcoPoolPermission(poolAdmin, poolAdminPermission[poolAdmin], newPermission);
        poolAdminPermission[poolAdmin] = newPermission;
    }
    
    /**
     * @dev Internal function to set the ACO pool strategies permitted.
     * @param strategy Address of the strategy.
     * @param newPermission The permission to be set.
     */
    function _setAcoPoolStrategyPermission(address strategy, bool newPermission) internal virtual {
        require(Address.isContract(strategy), "ACOPoolFactory::_setAcoPoolStrategy: Invalid strategy");
        emit SetStrategyPermission(strategy, strategyPermitted[strategy], newPermission);
        strategyPermitted[strategy] = newPermission;
    }
    
    /**
     * @dev Internal function to validate strategy.
     * @param strategy Address of the strategy.
     */
    function _validateStrategy(address strategy) view internal virtual {
        require(strategyPermitted[strategy], "ACOPoolFactory::_validateStrategy: Invalid strategy");
    }
    
    /**
     * @dev Internal function to change the ACO pools strategy.
     * @param strategy Address of the strategy to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function _setStrategyOnAcoPool(address strategy, address[] memory acoPools) internal virtual {
        _validateStrategy(strategy);
        for (uint256 i = 0; i < acoPools.length; ++i) {
            IACOPool2(acoPools[i]).setStrategy(strategy);
        }
    }
	
	/**
     * @dev Internal function to change the ACO pools ACO creator permission.
     * @param acoCreator Address of the ACO creator.
	 * @param permission Permission situation.
     * @param acoPools Array of ACO pools addresses.
     */
    function _setValidAcoCreatorOnAcoPool(address acoCreator, bool permission, address[] memory acoPools) internal virtual {
        for (uint256 i = 0; i < acoPools.length; ++i) {
            IACOPool2(acoPools[i]).setValidAcoCreator(acoCreator, permission);
        }
    }
	
	/**
     * @dev Internal function to withdraw the ACO pools stucked asset.
     * @param asset Address of the asset.
	 * @param destination Address of the destination.
     * @param acoPools Array of ACO pools addresses.
     */
    function _withdrawStuckAssetOnAcoPool(address asset, address destination, address[] memory acoPools) internal virtual {
        for (uint256 i = 0; i < acoPools.length; ++i) {
            IACOPool2(acoPools[i]).withdrawStuckToken(asset, destination);
        }
    }
    
    /**
     * @dev Internal function to change the ACO pools an uint256 data.
	 * @param selector Function selector to be called on the ACO pool.
     * @param numbers Array of the numbers to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function _setAcoPoolUint256Data(bytes4 selector, uint256[] memory numbers, address[] memory acoPools) internal virtual {
        require(numbers.length == acoPools.length, "ACOPoolFactory::_setAcoPoolUint256Data: Invalid arguments");
        for (uint256 i = 0; i < acoPools.length; ++i) {
			(bool success,) = acoPools[i].call(abi.encodeWithSelector(selector, numbers[i]));
			require(success, "ACOPoolFactory::_setAcoPoolUint256Data");
        }
    }
    
    /**
     * @dev Internal function to change the ACO pools an address data.
	 * @param selector Function selector to be called on the ACO pool.
     * @param addresses Array of the addresses to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function _setAcoPoolAddressData(bytes4 selector, address[] memory addresses, address[] memory acoPools) internal virtual {
        require(addresses.length == acoPools.length, "ACOPoolFactory::_setAcoPoolAddressData: Invalid arguments");
        for (uint256 i = 0; i < acoPools.length; ++i) {
			(bool success,) = acoPools[i].call(abi.encodeWithSelector(selector, addresses[i]));
			require(success, "ACOPoolFactory::_setAcoPoolAddressData");
        }
    }
    
    /**
     * @dev Internal function to create a new ACO pool.
     * @param initData Data to initialize o ACO Pool.
     * @return Address of the new minimal proxy deployed for the ACO pool.
     */
    function _createAcoPool(IACOPool2.InitData memory initData) internal virtual returns(address) {
        address acoPool  = _deployAcoPool(initData);
        acoPoolBasicData[acoPool] = ACOPoolBasicData(initData.underlying, initData.strikeAsset, initData.isCall);
        emit NewAcoPool(
            initData.underlying, 
            initData.strikeAsset, 
            initData.isCall, 
            acoPool, 
            acoPoolImplementation
        );
        return acoPool;
    }
    
    /**
     * @dev Internal function to deploy a minimal proxy using ACO pool implementation.
     * @param initData Data to initialize o ACO Pool.
     * @return Address of the new minimal proxy deployed for the ACO pool.
     */
    function _deployAcoPool(IACOPool2.InitData memory initData) internal virtual returns(address) {
        bytes20 implentationBytes = bytes20(acoPoolImplementation);
        address proxy;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implentationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        IACOPool2(proxy).init(initData);
        return proxy;
    }
}