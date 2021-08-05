pragma solidity ^0.6.6;

import "./Address.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./Strings.sol";

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
    event SetFactoryAdmin(address previousFactoryAdmin, address newFactoryAdmin);
    
    /**
     * @dev Emitted when the ACO token implementation has been changed.
     * @param previousAcoTokenImplementation Address of the previous ACO token implementation.
     * @param newAcoTokenImplementation Address of the new ACO token implementation.
     */
    event SetAcoTokenImplementation(address previousAcoTokenImplementation, address newAcoTokenImplementation);
    
    /**
     * @dev Emitted when the ACO fee has been changed.
     * @param previousAcoFee Value of the previous ACO fee.
     * @param newAcoFee Value of the new ACO fee.
     */
    event SetAcoFee(uint256 previousAcoFee, uint256 newAcoFee);
    
    /**
     * @dev Emitted when the ACO fee destination address has been changed.
     * @param previousAcoFeeDestination Address of the previous ACO fee destination.
     * @param newAcoFeeDestination Address of the new ACO fee destination.
     */
    event SetAcoFeeDestination(address previousAcoFeeDestination, address newAcoFeeDestination);
    
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
     */
    function createAcoToken(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime
    ) onlyFactoryAdmin external virtual {
        address acoToken = _deployAcoToken(_getAcoTokenInitData(underlying, strikeAsset, isCall, strikePrice, expiryTime));
        emit NewAcoToken(underlying, strikeAsset, isCall, strikePrice, expiryTime, acoToken, acoTokenImplementation);   
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
     * @dev Internal function to get the ACO token initialize data.
     * @param underlying Address of the underlying asset (0x0 for Ethereum).
     * @param strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param isCall True if the type is CALL, false for PUT.
     * @param strikePrice The strike price with the strike asset precision.
     * @param expiryTime The UNIX time for the ACO token expiration.
     * @return ABI encoded with signature for initializing ACO token.
     */
    function _getAcoTokenInitData(
        address underlying, 
        address strikeAsset, 
        bool isCall,
        uint256 strikePrice, 
        uint256 expiryTime
    ) internal view virtual returns(bytes memory) {
        return abi.encodeWithSignature("init(address,address,bool,uint256,uint256,uint256,address)",
            underlying,
            strikeAsset,
            isCall,
            strikePrice,
            expiryTime,
            acoFee,
            acoFeeDestination
        );
    }
    
    /**
     * @dev Internal function to deploy a minimal proxy using ACO token implementation.
     * @param initData ABI encoded with signature for initializing the new ACO token.
     * @return Address of the new minimal proxy deployed for the ACO token.
     */
    function _deployAcoToken(bytes memory initData) internal virtual returns(address) {
        require(initData.length > 0, "ACOFactory::_deployToken: Invalid init data");
        bytes20 implentationBytes = bytes20(acoTokenImplementation);
        address proxy;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), implentationBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        (bool success, bytes memory returnData) = proxy.call(initData);
        require(success, _acoTokenInititalizeError(returnData));
        return proxy;
    }
    
    /**
     * @dev Internal function to handle the return data on initializing ACO token with an error.
     * 4 bytes (function signature) + 32 bytes (offset) + 32 bytes (error string length) + X bytes (error string)
     * @param data Returned data with an error.
     * @return String with the error.
     */
    function _acoTokenInititalizeError(bytes memory data) internal pure virtual returns(string memory) {
        if (data.length >= 100) {
            bytes memory buffer = new bytes(data.length - 68);
            uint256 index = 0;
            for (uint256 i = 68; i < data.length; ++i) {
                buffer[index++] = data[i];
            }
            return string(buffer);
        } else {
            return "ACOFactory::_acoTokenInititalizeError";
        }  
    }
}