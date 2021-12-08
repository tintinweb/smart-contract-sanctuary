/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

import {Ownable} from "../packages/oz/Ownable.sol";
import {OwnedUpgradeabilityProxy} from "../packages/oz/upgradeability/OwnedUpgradeabilityProxy.sol";

/**
 * @author Opyn Team
 * @title AddressBook Module
 */
contract AddressBook is Ownable {
    /// @dev Otoken implementation key
    bytes32 private constant OTOKEN_IMPL = keccak256("OTOKEN_IMPL");
    /// @dev OtokenFactory key
    bytes32 private constant OTOKEN_FACTORY = keccak256("OTOKEN_FACTORY");
    /// @dev Whitelist key
    bytes32 private constant WHITELIST = keccak256("WHITELIST");
    /// @dev Controller key
    bytes32 private constant CONTROLLER = keccak256("CONTROLLER");
    /// @dev MarginPool key
    bytes32 private constant MARGIN_POOL = keccak256("MARGIN_POOL");
    /// @dev MarginCalculator key
    bytes32 private constant MARGIN_CALCULATOR = keccak256("MARGIN_CALCULATOR");
    /// @dev LiquidationManager key
    bytes32 private constant LIQUIDATION_MANAGER = keccak256("LIQUIDATION_MANAGER");
    /// @dev Oracle key
    bytes32 private constant ORACLE = keccak256("ORACLE");

    /// @dev mapping between key and address
    mapping(bytes32 => address) private addresses;

    /// @notice emits an event when a new proxy is created
    event ProxyCreated(bytes32 indexed id, address indexed proxy);
    /// @notice emits an event when a new address is added
    event AddressAdded(bytes32 indexed id, address indexed add);

    /**
     * @notice return Otoken implementation address
     * @return Otoken implementation address
     */
    function getOtokenImpl() external view returns (address) {
        return getAddress(OTOKEN_IMPL);
    }

    /**
     * @notice return oTokenFactory address
     * @return OtokenFactory address
     */
    function getOtokenFactory() external view returns (address) {
        return getAddress(OTOKEN_FACTORY);
    }

    /**
     * @notice return Whitelist address
     * @return Whitelist address
     */
    function getWhitelist() external view returns (address) {
        return getAddress(WHITELIST);
    }

    /**
     * @notice return Controller address
     * @return Controller address
     */
    function getController() external view returns (address) {
        return getAddress(CONTROLLER);
    }

    /**
     * @notice return MarginPool address
     * @return MarginPool address
     */
    function getMarginPool() external view returns (address) {
        return getAddress(MARGIN_POOL);
    }

    /**
     * @notice return MarginCalculator address
     * @return MarginCalculator address
     */
    function getMarginCalculator() external view returns (address) {
        return getAddress(MARGIN_CALCULATOR);
    }

    /**
     * @notice return LiquidationManager address
     * @return LiquidationManager address
     */
    function getLiquidationManager() external view returns (address) {
        return getAddress(LIQUIDATION_MANAGER);
    }

    /**
     * @notice return Oracle address
     * @return Oracle address
     */
    function getOracle() external view returns (address) {
        return getAddress(ORACLE);
    }

    /**
     * @notice set Otoken implementation address
     * @dev can only be called by the addressbook owner
     * @param _otokenImpl Otoken implementation address
     */
    function setOtokenImpl(address _otokenImpl) external onlyOwner {
        setAddress(OTOKEN_IMPL, _otokenImpl);
    }

    /**
     * @notice set OtokenFactory address
     * @dev can only be called by the addressbook owner
     * @param _otokenFactory OtokenFactory address
     */
    function setOtokenFactory(address _otokenFactory) external onlyOwner {
        setAddress(OTOKEN_FACTORY, _otokenFactory);
    }

    /**
     * @notice set Whitelist address
     * @dev can only be called by the addressbook owner
     * @param _whitelist Whitelist address
     */
    function setWhitelist(address _whitelist) external onlyOwner {
        setAddress(WHITELIST, _whitelist);
    }

    /**
     * @notice set Controller address
     * @dev can only be called by the addressbook owner
     * @param _controller Controller address
     */
    function setController(address _controller) external onlyOwner {
        updateImpl(CONTROLLER, _controller);
    }

    /**
     * @notice set MarginPool address
     * @dev can only be called by the addressbook owner
     * @param _marginPool MarginPool address
     */
    function setMarginPool(address _marginPool) external onlyOwner {
        setAddress(MARGIN_POOL, _marginPool);
    }

    /**
     * @notice set MarginCalculator address
     * @dev can only be called by the addressbook owner
     * @param _marginCalculator MarginCalculator address
     */
    function setMarginCalculator(address _marginCalculator) external onlyOwner {
        setAddress(MARGIN_CALCULATOR, _marginCalculator);
    }

    /**
     * @notice set LiquidationManager address
     * @dev can only be called by the addressbook owner
     * @param _liquidationManager LiquidationManager address
     */
    function setLiquidationManager(address _liquidationManager) external onlyOwner {
        setAddress(LIQUIDATION_MANAGER, _liquidationManager);
    }

    /**
     * @notice set Oracle address
     * @dev can only be called by the addressbook owner
     * @param _oracle Oracle address
     */
    function setOracle(address _oracle) external onlyOwner {
        setAddress(ORACLE, _oracle);
    }

    /**
     * @notice return an address for specific key
     * @param _key key address
     * @return address
     */
    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    /**
     * @notice set a specific address for a specific key
     * @dev can only be called by the addressbook owner
     * @param _key key
     * @param _address address
     */
    function setAddress(bytes32 _key, address _address) public onlyOwner {
        addresses[_key] = _address;

        emit AddressAdded(_key, _address);
    }

    /**
     * @dev function to update the implementation of a specific component of the protocol
     * @param _id id of the contract to be updated
     * @param _newAddress address of the new implementation
     **/
    function updateImpl(bytes32 _id, address _newAddress) public onlyOwner {
        address payable proxyAddress = address(uint160(getAddress(_id)));

        if (proxyAddress == address(0)) {
            bytes memory params = abi.encodeWithSignature("initialize(address,address)", address(this), owner());
            OwnedUpgradeabilityProxy proxy = new OwnedUpgradeabilityProxy();
            setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
            proxy.upgradeToAndCall(_newAddress, params);
        } else {
            OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(proxyAddress);
            proxy.upgradeTo(_newAddress);
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

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

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity 0.6.10;

import "./UpgradeabilityProxy.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /// @dev Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() public {
        setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     * @param _newProxyOwner address of new proxy owner
     */
    function setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        setUpgradeabilityOwner(_newOwner);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param _implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
     * to initialize whatever is needed through a low level call.
     * @param _implementation representing the address of the new implementation to be set.
     * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address _implementation, bytes calldata _data) public payable onlyProxyOwner {
        upgradeTo(_implementation);
        (bool success, ) = address(this).call{value: msg.value}(_data);
        require(success);
    }
}

// SPDX-License-Identifier: UNLICENSED
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity 0.6.10;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity 0.6.10;

import "./Proxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /// @dev Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

    /**
     * @dev Tells the address of the current implementation
     * @return impl address of the current implementation
     */
    function implementation() public view override returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address representing the new implementation to be set
     */
    function setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}