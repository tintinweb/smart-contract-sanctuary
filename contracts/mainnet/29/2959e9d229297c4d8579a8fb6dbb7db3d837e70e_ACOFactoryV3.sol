pragma solidity ^0.6.6;

import "./Address.sol";
import "./IACOToken.sol";

/**
 * @title ACOFactory
 * @dev The contract is the implementation for the ACOProxy.
 */
contract ACOFactory {
    
    /**
     * @dev Emitted when the factory admin address has been changed.
     * @param previousFactoryAdmin Address of the previous factory admin.
     * @param newFactoryAdmin Address of the new factory admin.
     */
    event SetFactoryAdmin(address indexed previousFactoryAdmin, address indexed newFactoryAdmin);
    
    /**
     * @dev Emitted when the ACO token implementation has been changed.
     * @param previousAcoTokenImplementation Address of the previous ACO token implementation.
     * @param newAcoTokenImplementation Address of the new ACO token implementation.
     */
    event SetAcoTokenImplementation(address indexed previousAcoTokenImplementation, address indexed newAcoTokenImplementation);
    
    /**
     * @dev Emitted when the ACO fee has been changed.
     * @param previousAcoFee Value of the previous ACO fee.
     * @param newAcoFee Value of the new ACO fee.
     */
    event SetAcoFee(uint256 indexed previousAcoFee, uint256 indexed newAcoFee);
    
    /**
     * @dev Emitted when the ACO fee destination address has been changed.
     * @param previousAcoFeeDestination Address of the previous ACO fee destination.
     * @param newAcoFeeDestination Address of the new ACO fee destination.
     */
    event SetAcoFeeDestination(address indexed previousAcoFeeDestination, address indexed newAcoFeeDestination);
    
    /**
     * @dev Emitted when a new ACO token has been created.
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param acoToken Address of the new ACO token created.
     * @param acoTokenImplementation Address of the ACO token implementation used on creation.
     */
    event NewAcoToken(address indexed underlying, address indexed strikeAsset, bool indexed isCall, uint256 strikePrice, uint256 expiryTime, address acoToken, address acoTokenImplementation);
    
    /**
     * @dev The ACO fee value. 
     * It is a percentage value (100000 is 100%).
     */
    uint256 public acoFee;
    
    /**
     * @dev The factory admin address.
     */
    address public factoryAdmin;
    
    /**
     * @dev The ACO token implementation address.
     */
    address public acoTokenImplementation;
    
    /**
     * @dev The ACO fee destination address.
     */
    address public acoFeeDestination;
    
    /**
     * @dev Modifier to check if the `msg.sender` is the factory admin.
     * Only factory admin address can execute.
     */
    modifier onlyFactoryAdmin() {
        require(msg.sender == factoryAdmin, "ACOFactory::onlyFactoryAdmin");
        _;
    }
    
    /**
     * @dev Function to initialize the contract.
     * It should be called through the `data` argument when creating the proxy.
     * It must be called only once. The `assert` is to guarantee that behavior.
     * @param _factoryAdmin Address of the factory admin.
     * @param _acoTokenImplementation Address of the ACO token implementation.
     * @param _acoFee Value of the ACO fee.
     * @param _acoFeeDestination Address of the ACO fee destination.
     */
    function init(address _factoryAdmin, address _acoTokenImplementation, uint256 _acoFee, address _acoFeeDestination) public {
        require(factoryAdmin == address(0) && acoTokenImplementation == address(0), "ACOFactory::init: Contract already initialized.");
        
        _setFactoryAdmin(_factoryAdmin);
        _setAcoTokenImplementation(_acoTokenImplementation);
        _setAcoFee(_acoFee);
        _setAcoFeeDestination(_acoFeeDestination);
    }

    /**
     * @dev Function to guarantee that the contract will not receive ether.
     */
    receive() external payable virtual {
        revert();
    }
    
    /**
     * @dev Function to create a new ACO token.
     * It deploys a minimal proxy for the ACO token implementation address. 
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall Whether the ACO token is the Call type.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param maxExercisedAccounts The maximum number of accounts that can be exercised by transaction.
     */
    function createAcoToken(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime,
        uint256 maxExercisedAccounts
    ) onlyFactoryAdmin external virtual returns(address) {
        address acoToken = _deployAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, maxExercisedAccounts);
        emit NewAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, acoToken, acoTokenImplementation);
        return acoToken;
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
     * @dev Function to set the ACO token implementation address.
     * Only can be called by the factory admin.
     * @param newAcoTokenImplementation Address of the new ACO token implementation.
     */
    function setAcoTokenImplementation(address newAcoTokenImplementation) onlyFactoryAdmin external virtual {
        _setAcoTokenImplementation(newAcoTokenImplementation);
    }
    
    /**
     * @dev Function to set the ACO fee.
     * Only can be called by the factory admin.
     * @param newAcoFee Value of the new ACO fee. It is a percentage value (100000 is 100%).
     */
    function setAcoFee(uint256 newAcoFee) onlyFactoryAdmin external virtual {
        _setAcoFee(newAcoFee);
    }
    
    /**
     * @dev Function to set the ACO destination address.
     * Only can be called by the factory admin.
     * @param newAcoFeeDestination Address of the new ACO destination.
     */
    function setAcoFeeDestination(address newAcoFeeDestination) onlyFactoryAdmin external virtual {
        _setAcoFeeDestination(newAcoFeeDestination);
    }
    
    /**
     * @dev Internal function to set the factory admin address.
     * @param newFactoryAdmin Address of the new factory admin.
     */
    function _setFactoryAdmin(address newFactoryAdmin) internal virtual {
        require(newFactoryAdmin != address(0), "ACOFactory::_setFactoryAdmin: Invalid factory admin");
        emit SetFactoryAdmin(factoryAdmin, newFactoryAdmin);
        factoryAdmin = newFactoryAdmin;
    }
    
    /**
     * @dev Internal function to set the ACO token implementation address.
     * @param newAcoTokenImplementation Address of the new ACO token implementation.
     */
    function _setAcoTokenImplementation(address newAcoTokenImplementation) internal virtual {
        require(Address.isContract(newAcoTokenImplementation), "ACOFactory::_setAcoTokenImplementation: Invalid ACO token implementation");
        emit SetAcoTokenImplementation(acoTokenImplementation, newAcoTokenImplementation);
        acoTokenImplementation = newAcoTokenImplementation;
    }
    
    /**
     * @dev Internal function to set the ACO fee.
     * @param newAcoFee Value of the new ACO fee. It is a percentage value (100000 is 100%).
     */
    function _setAcoFee(uint256 newAcoFee) internal virtual {
        emit SetAcoFee(acoFee, newAcoFee);
        acoFee = newAcoFee;
    }
    
    /**
     * @dev Internal function to set the ACO destination address.
     * @param newAcoFeeDestination Address of the new ACO destination.
     */
    function _setAcoFeeDestination(address newAcoFeeDestination) internal virtual {
        require(newAcoFeeDestination != address(0), "ACOFactory::_setAcoFeeDestination: Invalid ACO fee destination");
        emit SetAcoFeeDestination(acoFeeDestination, newAcoFeeDestination);
        acoFeeDestination = newAcoFeeDestination;
    }
    
    /**
     * @dev Internal function to deploy a minimal proxy using ACO token implementation.
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param maxExercisedAccounts The maximum number of accounts that can be exercised by transaction.
     * @return Address of the new minimal proxy deployed for the ACO token.
     */
    function _deployAcoToken(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime,
        uint256 maxExercisedAccounts
    ) internal virtual returns(address) {
        bytes20 implentationBytes = bytes20(acoTokenImplementation);
        address proxy;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implentationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        IACOToken(proxy).init(underlying, strikeAsset, isCall, strikePrice, expiryTime, acoFee, payable(acoFeeDestination), maxExercisedAccounts);
        return proxy;
    }
}

contract ACOFactoryV2 is ACOFactory {
	
	/**
     * @dev Struct to store the ACO Token basic data.
     */
    struct ACOTokenData {
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
         * @dev The strike price with the strike asset precision.
         */
        uint256 strikePrice;
        
        /**
         * @dev The UNIX time for the ACO token expiration.
         */
        uint256 expiryTime;
    }
	
    /**
     * @dev The ACO token basic data.
     */
    mapping(address => ACOTokenData) public acoTokenData;

    /**
     * @dev Function to create a new ACO token.
     * It deploys a minimal proxy for the ACO token implementation address. 
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall Whether the ACO token is the Call type.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param maxExercisedAccounts The maximum number of accounts that can be exercised by transaction.
     * @return The created ACO token address.
     */
    function createAcoToken(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime,
        uint256 maxExercisedAccounts
    ) onlyFactoryAdmin external override virtual returns(address) {
        address acoToken = _deployAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, maxExercisedAccounts);
        acoTokenData[acoToken] = ACOTokenData(underlying, strikeAsset, isCall, strikePrice, expiryTime);
        emit NewAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, acoToken, acoTokenImplementation);
        return acoToken;
    }
}

contract ACOFactoryV3 is ACOFactoryV2 {

    /**
     * @dev Emitted when the operator address permission has been changed.
     * @param operator Address of the operator.
     * @param previousPermission Whether the operator was authorized.
     * @param newPermission Whether the operator will be authorized.
     */
    event SetOperator(address indexed operator, bool indexed previousPermission, bool indexed newPermission);

    /**
     * @dev Emitted when a new ACO token has been created.
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param acoToken Address of the new ACO token created.
     * @param acoTokenImplementation Address of the ACO token implementation used on creation.
     * @param creator Address of the ACO creator.
     */
    event NewAcoTokenData(address indexed underlying, address indexed strikeAsset, bool indexed isCall, uint256 strikePrice, uint256 expiryTime, address acoToken, address acoTokenImplementation, address creator);
    
    /**
     * @dev A map to register the ACO Factory operators permissions.
     */
    mapping(address => bool) public operators;
    
    /**
     * @dev A map to register the ACO creator.
     */
    mapping(address => address) public creators;

    /**
     * @dev Function to set the operator permission.
     * @param operator Address of the operator.
     * @param newPermission Whether the operator will be authorized.
     */
    function setOperator(address operator, bool newPermission) onlyFactoryAdmin external virtual {
        _setOperator(operator, newPermission);
    }

	/**
     * @dev Function to create a new ACO token.
     * It deploys a minimal proxy for the ACO token implementation address. 
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall Whether the ACO token is the Call type.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @param maxExercisedAccounts The maximum number of accounts that can be exercised by transaction.
     * @return The created ACO token address.
     */
    function createAcoToken(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime,
        uint256 maxExercisedAccounts
    ) external override returns(address) {
        require(operators[msg.sender], "ACOFactory::createAcoToken: Only authorized operators");
        address acoToken = _deployAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, maxExercisedAccounts);
        acoTokenData[acoToken] = ACOTokenData(underlying, strikeAsset, isCall, strikePrice, expiryTime);
        creators[acoToken] = msg.sender;
        emit NewAcoTokenData(underlying, strikeAsset, isCall, strikePrice, expiryTime, acoToken, acoTokenImplementation, msg.sender);
        return acoToken;
    }

    /**
     * @dev Internal function to set the operator permission.
     * @param operator Address of the operator.
     * @param newPermission Whether the operator will be authorized.
     */
    function _setOperator(address operator, bool newPermission) internal virtual {
        emit SetOperator(operator, operators[operator], newPermission);
        operators[operator] = newPermission;
    }
}