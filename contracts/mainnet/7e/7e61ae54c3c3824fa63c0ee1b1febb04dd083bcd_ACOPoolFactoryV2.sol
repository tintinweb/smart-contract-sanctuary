pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./IACOPool.sol";

/**
 * @title ACOPoolFactory
 * @dev The contract is the implementation for the ACOProxy.
 */
contract ACOPoolFactory {
    
    /**
     * @dev Struct to store the ACO pool basic data.
     */
    struct ACOPoolData {
        /**
         * @dev The UNIX time that the ACO pool can start negotiated ACO tokens.
         */
        uint256 poolStart;
        
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
        
        /**
         * @dev The minimum strike price allowed with the strike asset precision.
         */
        uint256 minStrikePrice;
        
        /**
         * @dev The maximum strike price allowed with the strike asset precision.
         */
        uint256 maxStrikePrice;
        
        /**
         * @dev The minimum UNIX time for the ACO token expiration.
         */
        uint256 minExpiration;
        
        /**
         * @dev The maximum UNIX time for the ACO token expiration.
         */
        uint256 maxExpiration;
        
        /**
         * @dev Whether the pool buys ACO tokens otherwise, it only sells.
         */
        bool canBuy;
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
     * @dev Emitted when the ACO fee has been changed.
     * @param previousAcoFlashExercise Address of the previous ACO flash exercise.
     * @param newAcoFlashExercise Address of the new ACO flash exercise.
     */
    event SetAcoFlashExercise(address indexed previousAcoFlashExercise, address indexed newAcoFlashExercise);
    
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
     * @param poolStart The UNIX time that the ACO pool can start negotiated ACO tokens.
     * @param minStrikePrice The minimum strike price for ACO tokens with the strike asset precision.
     * @param maxStrikePrice The maximum strike price for ACO tokens with the strike asset precision.
     * @param minExpiration The minimum expiration time for ACO tokens.
     * @param maxExpiration The maximum expiration time for ACO tokens.
     * @param canBuy Whether the pool buys ACO tokens otherwise, it only sells.
     * @param acoPool Address of the new ACO pool created.
     * @param acoPoolImplementation Address of the ACO pool implementation used on creation.
     */
    event NewAcoPool(address indexed underlying, address indexed strikeAsset, bool indexed isCall, uint256 poolStart, uint256 minStrikePrice, uint256 maxStrikePrice, uint256 minExpiration, uint256 maxExpiration, bool canBuy, address acoPool, address acoPoolImplementation);
    
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
     * @dev The ACO flash exercise address.
     */
    address public acoFlashExercise;
    
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
    mapping(address => ACOPoolData) public acoPoolData;
    
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
     * @param _acoFlashExercise Address of the ACO flash exercise.
     */
    function init(
        address _factoryAdmin, 
        address _acoPoolImplementation, 
        address _acoFactory, 
        address _acoFlashExercise,
        address _chiToken,
        uint256 _acoPoolFee,
        address _acoPoolFeeDestination
    ) public {
        require(factoryAdmin == address(0) && acoPoolImplementation == address(0), "ACOPoolFactory::init: Contract already initialized.");
        
        _setFactoryAdmin(_factoryAdmin);
        _setAcoPoolImplementation(_acoPoolImplementation);
        _setAcoFactory(_acoFactory);
        _setAcoFlashExercise(_acoFlashExercise);
        _setChiToken(_chiToken);
        _setAcoPoolFee(_acoPoolFee);
        _setAcoPoolFeeDestination(_acoPoolFeeDestination);
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
     * @param poolStart The UNIX time that the ACO pool can start negotiated ACO tokens.
     * @param minStrikePrice The minimum strike price for ACO tokens with the strike asset precision.
     * @param maxStrikePrice The maximum strike price for ACO tokens with the strike asset precision.
     * @param minExpiration The minimum expiration time for ACO tokens.
     * @param maxExpiration The maximum expiration time for ACO tokens.
     * @param canBuy Whether the pool buys ACO tokens otherwise, it only sells.
     * @param strategy Address of the pool strategy to be used.
     * @param baseVolatility The base volatility for the pool starts. It is a percentage value (100000 is 100%).
     * @return The created ACO pool address.
     */
    function createAcoPool(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 poolStart,
        uint256 minStrikePrice,
        uint256 maxStrikePrice,
        uint256 minExpiration,
        uint256 maxExpiration,
        bool canBuy,
        address strategy,
        uint256 baseVolatility
    ) onlyFactoryAdmin external virtual returns(address) {
        _validateStrategy(strategy);
        return _createAcoPool(IACOPool.InitData(
            poolStart,
            acoFlashExercise,
            acoFactory,
            chiToken,
			address(0),
            acoPoolFee,
            acoPoolFeeDestination,
            underlying, 
            strikeAsset,
            minStrikePrice,
            maxStrikePrice,
            minExpiration,
            maxExpiration,
            isCall,
            canBuy,
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
     * @dev Function to set the ACO flash exercise address.
     * Only can be called by the factory admin.
     * @param newAcoFlashExercise Address of the new ACO flash exercise.
     */
    function setAcoFlashExercise(address newAcoFlashExercise) onlyFactoryAdmin external virtual {
        _setAcoFlashExercise(newAcoFlashExercise);
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
    function setAcoPoolStrategy(address strategy, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolStrategy(strategy, acoPools);
    }
    
    /**
     * @dev Function to change the ACO pools base volatilities.
     * Only can be called by a pool admin.
     * @param baseVolatilities Array of the base volatilities to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function setAcoPoolBaseVolatility(uint256[] calldata baseVolatilities, address[] calldata acoPools) onlyPoolAdmin external virtual {
        _setAcoPoolBaseVolatility(baseVolatilities, acoPools);
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
     * @dev Internal function to set the ACO flash exercise address.
     * @param newAcoFlashExercise Address of the new ACO flash exercise.
     */
    function _setAcoFlashExercise(address newAcoFlashExercise) internal virtual {
        require(Address.isContract(newAcoFlashExercise), "ACOPoolFactory::_setAcoFlashExercise: Invalid ACO flash exercise");
        emit SetAcoFlashExercise(acoFlashExercise, newAcoFlashExercise);
        acoFlashExercise = newAcoFlashExercise;
    }
    
    /**
     * @dev Internal function to set the Chi Token address.
     * @param newChiToken Address of the new Chi Token.
     */
    function _setChiToken(address newChiToken) internal virtual {
        require(Address.isContract(newChiToken), "ACOPoolFactory::_setChiToken: Invalid Chi Token");
        emit SetAcoFlashExercise(chiToken, newChiToken);
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
    function _setAcoPoolStrategy(address strategy, address[] memory acoPools) internal virtual {
        _validateStrategy(strategy);
        for (uint256 i = 0; i < acoPools.length; ++i) {
            IACOPool(acoPools[i]).setStrategy(strategy);
        }
    }
    
    /**
     * @dev Internal function to change the ACO pools base volatilities.
     * @param baseVolatilities Array of the base volatilities to be set.
     * @param acoPools Array of ACO pools addresses.
     */
    function _setAcoPoolBaseVolatility(uint256[] memory baseVolatilities, address[] memory acoPools) internal virtual {
        require(baseVolatilities.length == acoPools.length, "ACOPoolFactory::_setAcoPoolBaseVolatility: Invalid arguments");
        for (uint256 i = 0; i < acoPools.length; ++i) {
            IACOPool(acoPools[i]).setBaseVolatility(baseVolatilities[i]);
        }
    }
    
    /**
     * @dev Internal function to create a new ACO pool.
     * @param initData Data to initialize o ACO Pool.
     * @return Address of the new minimal proxy deployed for the ACO pool.
     */
    function _createAcoPool(IACOPool.InitData memory initData) internal virtual returns(address) {
        address acoPool  = _deployAcoPool(initData);
        acoPoolData[acoPool] = ACOPoolData(
            initData.poolStart, 
            initData.underlying, 
            initData.strikeAsset, 
            initData.isCall, 
            initData.minStrikePrice, 
            initData.maxStrikePrice, 
            initData.minExpiration, 
            initData.maxExpiration, 
            initData.canBuy
        );
        emit NewAcoPool(
            initData.underlying, 
            initData.strikeAsset, 
            initData.isCall, 
            initData.poolStart, 
            initData.minStrikePrice, 
            initData.maxStrikePrice, 
            initData.minExpiration, 
            initData.maxExpiration, 
            initData.canBuy, 
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
    function _deployAcoPool(IACOPool.InitData memory initData) internal virtual returns(address) {
        bytes20 implentationBytes = bytes20(acoPoolImplementation);
        address proxy;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implentationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        IACOPool(proxy).init(initData);
        return proxy;
    }
}

contract ACOPoolFactoryV2 is ACOPoolFactory {
	
    /**
     * @dev Emitted when the ACO fee has been changed.
     * @param previousAcoAssetConverterHelper Address of the previous ACO asset converter helper.
     * @param newAcoAssetConverterHelper Address of the new ACO asset converter helper.
     */
    event SetAcoAssetConverterHelper(address indexed previousAcoAssetConverterHelper, address indexed newAcoAssetConverterHelper);
	
	/**
     * @dev The ACO asset converter helper.
     */
    address public assetConverterHelper;
	
	/**
     * @dev Function to set the ACO asset converter helper address.
     * Only can be called by the factory admin.
     * @param newAcoAssetConverterHelper Address of the new ACO asset converter helper.
     */
    function setAcoAssetConverterHelper(address newAcoAssetConverterHelper) onlyFactoryAdmin external virtual {
        _setAcoAssetConverterHelper(newAcoAssetConverterHelper);
    }
	
    /**
     * @dev Function to create a new ACO pool.
     * It deploys a minimal proxy for the ACO pool implementation address. 
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param poolStart The UNIX time that the ACO pool can start negotiated ACO tokens.
     * @param minStrikePrice The minimum strike price for ACO tokens with the strike asset precision.
     * @param maxStrikePrice The maximum strike price for ACO tokens with the strike asset precision.
     * @param minExpiration The minimum expiration time for ACO tokens.
     * @param maxExpiration The maximum expiration time for ACO tokens.
     * @param canBuy Whether the pool buys ACO tokens otherwise, it only sells.
     * @param strategy Address of the pool strategy to be used.
     * @param baseVolatility The base volatility for the pool starts. It is a percentage value (100000 is 100%).
     * @return The created ACO pool address.
     */
    function createAcoPool(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 poolStart,
        uint256 minStrikePrice,
        uint256 maxStrikePrice,
        uint256 minExpiration,
        uint256 maxExpiration,
        bool canBuy,
        address strategy,
        uint256 baseVolatility
    ) onlyFactoryAdmin external override returns(address) {
        _validateStrategy(strategy);
        return _createAcoPool(IACOPool.InitData(
            poolStart,
            acoFlashExercise,
            acoFactory,
            chiToken,
			assetConverterHelper,
            acoPoolFee,
            acoPoolFeeDestination,
            underlying, 
            strikeAsset,
            minStrikePrice,
            maxStrikePrice,
            minExpiration,
            maxExpiration,
            isCall,
            canBuy,
            strategy,
            baseVolatility
        ));
    }
	
    /**
     * @dev Internal function to set the ACO asset converter helper address.
     * @param newAcoAssetConverterHelper Address of the new ACO asset converter helper.
     */
    function _setAcoAssetConverterHelper(address newAcoAssetConverterHelper) internal virtual {
        require(Address.isContract(newAcoAssetConverterHelper), "ACOPoolFactory::_setAcoAssetConverterHelper: Invalid ACO asset converter helper");
        emit SetAcoAssetConverterHelper(assetConverterHelper, newAcoAssetConverterHelper);
        assetConverterHelper = newAcoAssetConverterHelper;
    }
}