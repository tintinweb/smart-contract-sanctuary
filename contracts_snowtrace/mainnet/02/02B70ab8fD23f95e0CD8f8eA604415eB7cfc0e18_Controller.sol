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
pragma solidity =0.6.10;

import "../interfaces/AddressBookInterface.sol";
import "../packages/oz/Ownable.sol";

/**
 * @author Opyn Team
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid oToken addresses, product hashes, collateral addresses, and callee addresses.
 */
contract Whitelist is Ownable {
    /// @notice AddressBook module address
    address public addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track whitelisted collateral
    mapping(address => bool) internal whitelistedCollateral;
    /// @dev mapping to track whitelisted oTokens
    mapping(address => bool) internal whitelistedOtoken;
    /// @dev mapping to track whitelisted callee addresses for the call action
    mapping(address => bool) internal whitelistedCallee;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address indexed collateral);
    /// @notice emits an event when an oToken is whitelisted by the OtokenFactory module
    event OtokenWhitelisted(address indexed otoken);
    /// @notice emits an event when an oToken is blacklisted by the OtokenFactory module
    event OtokenBlacklisted(address indexed otoken);
    /// @notice emits an event when a callee address is whitelisted by the owner address
    event CalleeWhitelisted(address indexed _callee);
    /// @notice emits an event when a callee address is blacklisted by the owner address
    event CalleeBlacklisted(address indexed _callee);

    /**
     * @notice check if the sender is the oTokenFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getOtokenFactory(),
            "Whitelist: Sender is not OtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collateral asset that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollateral(address _collateral) external view returns (bool) {
        return whitelistedCollateral[_collateral];
    }

    /**
     * @notice check if an oToken is whitelisted
     * @param _otoken oToken address
     * @return boolean, True if the oToken is whitelisted
     */
    function isWhitelistedOtoken(address _otoken) external view returns (bool) {
        return whitelistedOtoken[_otoken];
    }

    /**
     * @notice check if a callee address is whitelisted for the call action
     * @param _callee callee destination address
     * @return boolean, True if the address is whitelisted
     */
    function isWhitelistedCallee(address _callee) external view returns (bool) {
        return whitelistedCallee[_callee];
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        require(whitelistedCollateral[_collateral], "Whitelist: Collateral is not whitelisted");
        require(
            (_isPut && (_strike == _collateral)) || (!_isPut && (_collateral == _underlying)),
            "Whitelist: Only allow fully collateralized products"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than Otoken as collateral. WhitelistOtoken() is used to whitelist Otoken contracts.
     * @param _collateral collateral asset address
     */
    function whitelistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = true;

        emit CollateralWhitelisted(_collateral);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collateral collateral asset address
     */
    function blacklistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = false;

        emit CollateralBlacklisted(_collateral);
    }

    /**
     * @notice allows the OtokenFactory module to whitelist a new option
     * @dev can only be called from the OtokenFactory address
     * @param _otokenAddress oToken
     */
    function whitelistOtoken(address _otokenAddress) external onlyFactory {
        whitelistedOtoken[_otokenAddress] = true;

        emit OtokenWhitelisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _otokenAddress oToken
     */
    function blacklistOtoken(address _otokenAddress) external onlyOwner {
        whitelistedOtoken[_otokenAddress] = false;

        emit OtokenBlacklisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to whitelist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function whitelistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = true;

        emit CalleeWhitelisted(_callee);
    }

    /**
     * @notice allows the owner to blacklist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function blacklistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = false;

        emit CalleeBlacklisted(_callee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

pragma solidity =0.6.10;

import {ERC20PermitUpgradeable} from "../packages/oz/upgradeability/erc20-permit/ERC20PermitUpgradeable.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @dev The Otoken inherits ERC20PermitUpgradeable because we need to use the init instead of constructor
 * This is V1 implementation, with no getOtokenDetails()
 */
contract OtokenImplV1 is ERC20PermitUpgradeable {
    address public addressBook;
    address public controller;
    address public underlyingAsset;
    address public strikeAsset;
    address public collateralAsset;

    uint256 public strikePrice;
    uint256 public expiryTimestamp;

    bool public isPut;

    bool public inited = false;

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external initializer {
        inited = true;
        controller = AddressBookInterface(_addressBook).getController();
        underlyingAsset = _underlyingAsset;
        strikeAsset = _strikeAsset;
        collateralAsset = _collateralAsset;
        strikePrice = _strikePrice;
        expiryTimestamp = _expiryTimestamp;
        isPut = _isPut;
        string memory tokenName = "ETHUSDC/1597511955/200P/USDC";
        string memory tokenSymbol = "oETHUSDCP";
        __ERC20_init_unchained(tokenName, tokenSymbol);
        __ERC20Permit_init(tokenName);
        _setupDecimals(8);
    }

    function mintOtoken(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burnOtoken(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function getChainId() external view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.5 <0.8.0;

import "../ERC20Upgradeable.sol";
import "./IERC20PermitUpgradeable.sol";
import "../cryptography/ECDSAUpgradeable.sol";
import "../utils/CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "../Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20PermitUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

import "./GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./math/SafeMathUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;
import "../Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

/* solhint-disable */
pragma solidity >=0.4.24 <0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

import "../Initializable.sol";

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

    function __Context_init_unchained() internal initializer {}

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
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20PermitUpgradeable} from "../packages/oz/upgradeability/erc20-permit/ERC20PermitUpgradeable.sol";

contract MockPermitERC20 is ERC20PermitUpgradeable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        __ERC20_init_unchained(_name, _symbol);
        __ERC20Permit_init(_name);
        _setupDecimals(_decimals);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

pragma solidity =0.6.10;

import {ERC20PermitUpgradeable} from "../packages/oz/upgradeability/erc20-permit/ERC20PermitUpgradeable.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @dev The Otoken inherits ERC20PermitUpgradeable because we need to use the init instead of constructor.
 */
contract MockOtoken is ERC20PermitUpgradeable {
    address public addressBook;
    address public controller;
    address public underlyingAsset;
    address public strikeAsset;
    address public collateralAsset;

    uint256 public strikePrice;
    uint256 public expiryTimestamp;

    bool public isPut;

    bool public inited = false;

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external initializer {
        inited = true;
        controller = AddressBookInterface(_addressBook).getController();
        underlyingAsset = _underlyingAsset;
        strikeAsset = _strikeAsset;
        collateralAsset = _collateralAsset;
        strikePrice = _strikePrice;
        expiryTimestamp = _expiryTimestamp;
        isPut = _isPut;
        string memory tokenName = "ETHUSDC/1597511955/200P/USDC";
        string memory tokenSymbol = "oETHUSDCP";
        __ERC20_init_unchained(tokenName, tokenSymbol);
        __ERC20Permit_init(tokenName);
        _setupDecimals(8);
    }

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        return (collateralAsset, underlyingAsset, strikeAsset, strikePrice, expiryTimestamp, isPut);
    }

    function mintOtoken(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burnOtoken(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function getChainId() external view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {Initializable} from "../packages/oz/upgradeability/Initializable.sol";

/**
 * @author Opyn Team
 * @notice Upgradeable testing contract
 */
contract UpgradeableContractV1 is Initializable {
    /// @notice addressbook address
    address public addressBook;
    /// @notice owner address
    address public owner;

    /**
     * @dev this function is invoked by the proxy contract when this contract is added to the
     * AddressBook.
     * @param _addressBook the address of the AddressBook
     **/
    function initialize(address _addressBook, address _owner) public initializer {
        addressBook = _addressBook;
        owner = _owner;
    }

    function getV1Version() external pure returns (uint256) {
        return 1;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {UpgradeableContractV1} from "./UpgradeableContractV1.sol";

/**
 * @author Opyn Team
 * @notice Upgradeable testing contract
 */
contract UpgradeableContractV2 is UpgradeableContractV1 {
    function getV2Version() external pure returns (uint256) {
        return 2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";

contract MockYToken is ERC20Upgradeable {
    uint256 public pricePerShare;

    constructor(string memory _name, string memory _symbol) public {
        __ERC20_init_unchained(_name, _symbol);
        _setupDecimals(8);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function setPricePerShare(uint256 _pricePerShare) external {
        pricePerShare = _pricePerShare;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";

contract MockWSTETHToken is ERC20Upgradeable {
    uint256 public stEthPerToken;

    constructor(string memory _name, string memory _symbol) public {
        __ERC20_init_unchained(_name, _symbol);
        _setupDecimals(18);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function setStEthPerToken(uint256 _stEthPerToken) external {
        stEthPerToken = _stEthPerToken;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";

contract MockERC20 is ERC20Upgradeable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        __ERC20_init_unchained(_name, _symbol);
        _setupDecimals(_decimals);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

contract MockCUSDC is ERC20Upgradeable {
    uint256 public exchangeRateStored;
    address public underlying;
    uint256 public scale = 1e18;

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlying,
        uint256 _initExchangeRateStored
    ) public {
        __ERC20_init_unchained(_name, _symbol);
        _setupDecimals(8);

        underlying = _underlying;
        exchangeRateStored = _initExchangeRateStored;
    }

    function mint(uint256 amount) public returns (uint256) {
        uint256 numerator = scale.mul(amount);
        uint256 cTokenAmount = numerator.div(exchangeRateStored);
        _mint(msg.sender, cTokenAmount);
        ERC20Interface(underlying).transferFrom(msg.sender, address(this), amount);
        return 0;
    }

    function redeem(uint256 amount) public returns (uint256) {
        _burn(msg.sender, amount);
        uint256 underlyingAmount = amount.mul(exchangeRateStored).div(scale);
        ERC20Interface(underlying).transfer(msg.sender, underlyingAmount);
    }

    function setExchangeRate(uint256 _exchangeRateStored) external {
        exchangeRateStored = _exchangeRateStored;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {YearnVaultInterface} from "../interfaces/YearnVaultInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @notice A Pricer contract for a Yearn yToken
 */
contract YearnPricer is OpynPricerInterface {
    using SafeMath for uint256;

    /// @notice opyn oracle address
    OracleInterface public oracle;

    /// @notice yToken that this pricer will a get price for
    YearnVaultInterface public yToken;

    /// @notice underlying asset for this yToken
    ERC20Interface public underlying;

    /**
     * @param _yToken yToken asset
     * @param _underlying underlying asset for this yToken
     * @param _oracle Opyn Oracle contract address
     */
    constructor(
        address _yToken,
        address _underlying,
        address _oracle
    ) public {
        require(_yToken != address(0), "YearnPricer: yToken address can not be 0");
        require(_underlying != address(0), "YearnPricer: underlying address can not be 0");
        require(_oracle != address(0), "YearnPricer: oracle address can not be 0");

        yToken = YearnVaultInterface(_yToken);
        underlying = ERC20Interface(_underlying);
        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice get the live price for the asset
     * @dev overrides the getPrice function in OpynPricerInterface
     * @return price of 1e8 yToken in USD, scaled by 1e8
     */
    function getPrice() external view override returns (uint256) {
        uint256 underlyingPrice = oracle.getPrice(address(underlying));
        require(underlyingPrice > 0, "YearnPricer: underlying price is 0");
        return _underlyingPriceToYtokenPrice(underlyingPrice);
    }

    /**
     * @notice set the expiry price in the oracle
     * @dev requires that the underlying price has been set before setting a yToken price
     * @param _expiryTimestamp expiry to set a price for
     */
    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 underlyingPriceExpiry, ) = oracle.getExpiryPrice(address(underlying), _expiryTimestamp);
        require(underlyingPriceExpiry > 0, "YearnPricer: underlying price not set yet");
        uint256 yTokenPrice = _underlyingPriceToYtokenPrice(underlyingPriceExpiry);
        oracle.setExpiryPrice(address(yToken), _expiryTimestamp, yTokenPrice);
    }

    /**
     * @dev convert underlying price to yToken price with the yToken to underlying exchange rate
     * @param _underlyingPrice price of 1 underlying token (ie 1e6 USDC, 1e18 WETH) in USD, scaled by 1e8
     * @return price of 1e8 yToken in USD, scaled by 1e8
     */
    function _underlyingPriceToYtokenPrice(uint256 _underlyingPrice) private view returns (uint256) {
        uint256 pricePerShare = yToken.pricePerShare();
        uint8 underlyingDecimals = underlying.decimals();

        return pricePerShare.mul(_underlyingPrice).div(10**uint256(underlyingDecimals));
    }

    function getHistoricalPrice(uint80 _roundId) external view override returns (uint256, uint256) {
        revert("YearnPricer: Deprecated");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(uint80 _roundId) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface YearnVaultInterface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256) external;

    function withdraw(uint256) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {CalleeInterface} from "../interfaces/CalleeInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeERC20} from "../packages/oz/SafeERC20.sol";
import {WETH9} from "../external/canonical-weth/WETH9.sol";

/**
 * @author Opyn Team
 * @title FlashUnwrap
 * @notice contract To unwrap WETH. This is just a contract to test the Call action
 */
contract FlashUnwrap is CalleeInterface {
    using SafeERC20 for ERC20Interface;

    // Number of bytes in a CallFunctionData struct
    uint256 private constant NUM_CALLFUNCTIONDATA_BYTES = 32;

    WETH9 public WETH;

    struct CallFunctionData {
        uint256 amount;
    }

    constructor(address payable weth) public {
        WETH = WETH9(weth);
    }

    event WrappedETH(address indexed to, uint256 amount);
    event UnwrappedETH(address to, uint256 amount);

    receive() external payable {}

    // flash unwrap
    function callFunction(address payable _sender, bytes memory _data) external override {
        require(_data.length == NUM_CALLFUNCTIONDATA_BYTES, "FlashUnwrap: cannot parse CallFunctionData");

        CallFunctionData memory cfd = abi.decode(_data, (CallFunctionData));

        WETH.transferFrom(_sender, address(this), cfd.amount);
        WETH.withdraw(cfd.amount);

        _sender.transfer(cfd.amount);

        emit UnwrappedETH(_sender, cfd.amount);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Contract interface that can be called from Controller as a call action.
 */
interface CalleeInterface {
    /**
     * Allows users to send this contract arbitrary data.
     * @param _sender The msg.sender to Controller
     * @param _data Arbitrary data given by the sender
     */
    function callFunction(address payable _sender, bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

import "../../interfaces/ERC20Interface.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20Interface;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        ERC20Interface token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        ERC20Interface token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {ERC20Interface-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        ERC20Interface token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        ERC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        ERC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20Interface token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Copyright (C) 2015, 2016, 2017 Dapphub

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
// SPDX-License-Identifier:  GNU GPL
pragma solidity 0.6.10;

/**
 * @title WETH contract
 * @author Opyn Team
 * @dev A wrapper to use ETH as collateral
 */
contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    /// @notice emits an event when a sender approves WETH
    event Approval(address indexed src, address indexed guy, uint256 wad);
    /// @notice emits an event when a sender transfers WETH
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    /// @notice emits an event when a sender deposits ETH into this contract
    event Deposit(address indexed dst, uint256 wad);
    /// @notice emits an event when a sender withdraws ETH from this contract
    event Withdrawal(address indexed src, uint256 wad);

    /// @notice mapping between address and WETH balance
    mapping(address => uint256) public balanceOf;
    /// @notice mapping between addresses and allowance amount
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @notice fallback function that receives ETH
     * @dev will get called in a tx with ETH
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice wrap deposited ETH into WETH
     */
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice withdraw ETH from contract
     * @dev Unwrap from WETH to ETH
     * @param _wad amount WETH to unwrap and withdraw
     */
    function withdraw(uint256 _wad) public {
        require(balanceOf[msg.sender] >= _wad, "WETH9: insufficient sender balance");
        balanceOf[msg.sender] -= _wad;
        msg.sender.transfer(_wad);
        emit Withdrawal(msg.sender, _wad);
    }

    /**
     * @notice get ETH total supply
     * @return total supply
     */
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice approve transfer
     * @param _guy address to approve
     * @param _wad amount of WETH
     * @return True if tx succeeds, False if not
     */
    function approve(address _guy, uint256 _wad) public returns (bool) {
        allowance[msg.sender][_guy] = _wad;
        emit Approval(msg.sender, _guy, _wad);
        return true;
    }

    /**
     * @notice transfer WETH
     * @param _dst destination address
     * @param _wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transfer(address _dst, uint256 _wad) public returns (bool) {
        return transferFrom(msg.sender, _dst, _wad);
    }

    /**
     * @notice transfer from address
     * @param _src source address
     * @param _dst destination address
     * @param _wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transferFrom(
        address _src,
        address _dst,
        uint256 _wad
    ) public returns (bool) {
        require(balanceOf[_src] >= _wad, "WETH9: insufficient source balance");

        if (_src != msg.sender && allowance[_src][msg.sender] != uint256(-1)) {
            require(allowance[_src][msg.sender] >= _wad, "WETH9: invalid allowance");
            allowance[_src][msg.sender] -= _wad;
        }

        balanceOf[_src] -= _wad;
        balanceOf[_dst] += _wad;

        emit Transfer(_src, _dst, _wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {WETH9} from "../canonical-weth/WETH9.sol";
import {ReentrancyGuard} from "../../packages/oz/ReentrancyGuard.sol";
import {SafeERC20} from "../../packages/oz/SafeERC20.sol";
import {ERC20Interface} from "../../interfaces/ERC20Interface.sol";
import {Actions} from "../../libs/Actions.sol";
import {Controller} from "../../core/Controller.sol";
import {Address} from "../../packages/oz/Address.sol";

/**
 * @title PayableProxyController
 * @author Opyn Team
 * @dev Contract for wrapping/unwrapping ETH before/after interacting with the Gamma Protocol
 */
contract PayableProxyController is ReentrancyGuard {
    using SafeERC20 for ERC20Interface;
    using Address for address payable;

    WETH9 public weth;
    Controller public controller;

    constructor(
        address _controller,
        address _marginPool,
        address payable _weth
    ) public {
        controller = Controller(_controller);
        weth = WETH9(_weth);
        ERC20Interface(address(weth)).safeApprove(_marginPool, uint256(-1));
    }

    /**
     * @notice fallback function which disallows ETH to be sent to this contract without data except when unwrapping WETH
     */
    fallback() external payable {
        require(msg.sender == address(weth), "PayableProxyController: Cannot receive ETH");
    }

    /**
     * @notice execute a number of actions
     * @dev a wrapper for the Controller operate function, to wrap WETH and the beginning and unwrap WETH at the end of the execution
     * @param _actions array of actions arguments
     * @param _sendEthTo address to send the remaining eth to
     */
    function operate(Actions.ActionArgs[] memory _actions, address payable _sendEthTo) external payable nonReentrant {
        // create WETH from ETH
        if (msg.value != 0) {
            weth.deposit{value: msg.value}();
        }

        // verify sender
        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];

            // check that msg.sender is an owner or operator
            if (action.owner != address(0)) {
                require(
                    (msg.sender == action.owner) || (controller.isOperator(action.owner, msg.sender)),
                    "PayableProxyController: cannot execute action "
                );
            }

            if (action.actionType == Actions.ActionType.Call) {
                // our PayableProxy could ends up approving amount > total eth received.
                ERC20Interface(address(weth)).safeIncreaseAllowance(action.secondAddress, msg.value);
            }
        }

        controller.operate(_actions);

        // return all remaining WETH to the sendEthTo address as ETH
        uint256 remainingWeth = weth.balanceOf(address(this));
        if (remainingWeth != 0) {
            require(_sendEthTo != address(0), "PayableProxyController: cannot send ETH to address zero");

            weth.withdraw(remainingWeth);
            _sendEthTo.sendValue(remainingWeth);
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity =0.6.10;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {MarginVault} from "./MarginVault.sol";

/**
 * @title Actions
 * @author Opyn Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 * errorCode
 * A1 can only parse arguments for open vault actions
 * A2 cannot open vault for an invalid account
 * A3 cannot open vault with an invalid type
 * A4 can only parse arguments for mint actions
 * A5 cannot mint from an invalid account
 * A6 can only parse arguments for burn actions
 * A7 cannot burn from an invalid account
 * A8 can only parse arguments for deposit actions
 * A9 cannot deposit to an invalid account
 * A10 can only parse arguments for withdraw actions
 * A11 cannot withdraw from an invalid account
 * A12 cannot withdraw to an invalid account
 * A13 can only parse arguments for redeem actions
 * A14 cannot redeem to an invalid account
 * A15 can only parse arguments for settle vault actions
 * A16 cannot settle vault for an invalid account
 * A17 cannot withdraw payout to an invalid account
 * A18 can only parse arguments for liquidate action
 * A19 cannot liquidate vault for an invalid account owner
 * A20 cannot send collateral to an invalid account
 * A21 cannot parse liquidate action with no round id
 * A22 can only parse arguments for call actions
 * A23 target address cannot be address(0)
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
        // vault type, 0 for spread/max loss and 1 for naked margin vault
        uint256 vaultType;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    struct LiquidateArgs {
        // address of the vault owner to liquidate
        address owner;
        // address of the liquidated collateral receiver
        address receiver;
        // vault id to liquidate
        uint256 vaultId;
        // amount of debt(otoken) to repay
        uint256 amount;
        // chainlink round id
        uint256 roundId;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "A1");
        require(_args.owner != address(0), "A2");

        // if not _args.data included, vault type will be 0 by default
        uint256 vaultType;

        if (_args.data.length == 32) {
            // decode vault type from _args.data
            vaultType = abi.decode(_args.data, (uint256));
        }

        // for now we only have 2 vault types
        require(vaultType < 2, "A3");

        return OpenVaultArgs({owner: _args.owner, vaultId: _args.vaultId, vaultType: vaultType});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "A4");
        require(_args.owner != address(0), "A5");

        return
            MintArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "A6");
        require(_args.owner != address(0), "A7");

        return
            BurnArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositArgs(ActionArgs memory _args) internal pure returns (DepositArgs memory) {
        require(
            (_args.actionType == ActionType.DepositLongOption) || (_args.actionType == ActionType.DepositCollateral),
            "A8"
        );
        require(_args.owner != address(0), "A9");

        return
            DepositArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawArgs(ActionArgs memory _args) internal pure returns (WithdrawArgs memory) {
        require(
            (_args.actionType == ActionType.WithdrawLongOption) || (_args.actionType == ActionType.WithdrawCollateral),
            "A10"
        );
        require(_args.owner != address(0), "A11");
        require(_args.secondAddress != address(0), "A12");

        return
            WithdrawArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "A13");
        require(_args.secondAddress != address(0), "A14");

        return RedeemArgs({receiver: _args.secondAddress, otoken: _args.asset, amount: _args.amount});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(_args.actionType == ActionType.SettleVault, "A15");
        require(_args.owner != address(0), "A16");
        require(_args.secondAddress != address(0), "A17");

        return SettleVaultArgs({owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress});
    }

    function _parseLiquidateArgs(ActionArgs memory _args) internal pure returns (LiquidateArgs memory) {
        require(_args.actionType == ActionType.Liquidate, "A18");
        require(_args.owner != address(0), "A19");
        require(_args.secondAddress != address(0), "A20");
        require(_args.data.length == 32, "A21");

        // decode chainlink round id from _args.data
        uint256 roundId = abi.decode(_args.data, (uint256));

        return
            LiquidateArgs({
                owner: _args.owner,
                receiver: _args.secondAddress,
                vaultId: _args.vaultId,
                amount: _args.amount,
                roundId: roundId
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a call action
     * @param _args general action arguments structure
     * @return arguments for a call action
     */
    function _parseCallArgs(ActionArgs memory _args) internal pure returns (CallArgs memory) {
        require(_args.actionType == ActionType.Call, "A22");
        require(_args.secondAddress != address(0), "A23");

        return CallArgs({callee: _args.secondAddress, data: _args.data});
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {OwnableUpgradeSafe} from "../packages/oz/upgradeability/OwnableUpgradeSafe.sol";
import {ReentrancyGuardUpgradeSafe} from "../packages/oz/upgradeability/ReentrancyGuardUpgradeSafe.sol";
import {Initializable} from "../packages/oz/upgradeability/Initializable.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {MarginVault} from "../libs/MarginVault.sol";
import {Actions} from "../libs/Actions.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {MarginCalculatorInterface} from "../interfaces/MarginCalculatorInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {WhitelistInterface} from "../interfaces/WhitelistInterface.sol";
import {MarginPoolInterface} from "../interfaces/MarginPoolInterface.sol";
import {CalleeInterface} from "../interfaces/CalleeInterface.sol";

/**
 * Controller Error Codes
 * C1: sender is not full pauser
 * C2: sender is not partial pauser
 * C3: callee is not a whitelisted address
 * C4: system is partially paused
 * C5: system is fully paused
 * C6: msg.sender is not authorized to run action
 * C7: invalid addressbook address
 * C8: invalid owner address
 * C9: invalid input
 * C10: fullPauser cannot be set to address zero
 * C11: partialPauser cannot be set to address zero
 * C12: can not run actions for different owners
 * C13: can not run actions on different vaults
 * C14: invalid final vault state
 * C15: can not run actions on inexistent vault
 * C16: cannot deposit long otoken from this address
 * C17: otoken is not whitelisted to be used as collateral
 * C18: otoken used as collateral is already expired
 * C19: can not withdraw an expired otoken
 * C20: cannot deposit collateral from this address
 * C21: asset is not whitelisted to be used as collateral
 * C22: can not withdraw collateral from a vault with an expired short otoken
 * C23: otoken is not whitelisted to be minted
 * C24: can not mint expired otoken
 * C25: cannot burn from this address
 * C26: can not burn expired otoken
 * C27: otoken is not whitelisted to be redeemed
 * C28: can not redeem un-expired otoken
 * C29: asset prices not finalized yet
 * C30: can't settle vault with no otoken
 * C31: can not settle vault with un-expired otoken
 * C32: can not settle undercollateralized vault
 * C33: can not liquidate vault
 * C34: can not leave less than collateral dust
 * C35: invalid vault id
 * C36: cap amount should be greater than zero
 * C37: collateral exceed naked margin cap
 */

/**
 * @title Controller
 * @author Opyn Team
 * @notice Contract that controls the Gamma Protocol and the interaction of all sub contracts
 */
contract Controller is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;

    AddressBookInterface public addressbook;
    WhitelistInterface public whitelist;
    OracleInterface public oracle;
    MarginCalculatorInterface public calculator;
    MarginPoolInterface public pool;

    ///@dev scale used in MarginCalculator
    uint256 internal constant BASE = 8;

    /// @notice address that has permission to partially pause the system, where system functionality is paused
    /// except redeem and settleVault
    address public partialPauser;

    /// @notice address that has permission to fully pause the system, where all system functionality is paused
    address public fullPauser;

    /// @notice True if all system functionality is paused other than redeem and settle vault
    bool public systemPartiallyPaused;

    /// @notice True if all system functionality is paused
    bool public systemFullyPaused;

    /// @notice True if a call action can only be executed to a whitelisted callee
    bool public callRestricted;

    /// @dev mapping between an owner address and the number of owner address vaults
    mapping(address => uint256) internal accountVaultCounter;
    /// @dev mapping between an owner address and a specific vault using a vault id
    mapping(address => mapping(uint256 => MarginVault.Vault)) internal vaults;
    /// @dev mapping between an account owner and their approved or unapproved account operators
    mapping(address => mapping(address => bool)) internal operators;

    /******************************************************************** V2.0.0 storage upgrade ******************************************************/

    /// @dev mapping to map vault by each vault type, naked margin vault should be set to 1, spread/max loss vault should be set to 0
    mapping(address => mapping(uint256 => uint256)) internal vaultType;
    /// @dev mapping to store the timestamp at which the vault was last updated, will be updated in every action that changes the vault state or when calling sync()
    mapping(address => mapping(uint256 => uint256)) internal vaultLatestUpdate;

    /// @dev mapping to store cap amount for naked margin vault per options collateral asset (scaled by collateral asset decimals)
    mapping(address => uint256) internal nakedCap;

    /// @dev mapping to store amount of naked margin vaults in pool
    mapping(address => uint256) internal nakedPoolBalance;

    /// @notice emits an event when an account operator is updated for a specific account owner
    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);
    /// @notice emits an event when a new vault is opened
    event VaultOpened(address indexed accountOwner, uint256 vaultId, uint256 indexed vaultType);
    /// @notice emits an event when a long oToken is deposited into a vault
    event LongOtokenDeposited(
        address indexed otoken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a long oToken is withdrawn from a vault
    event LongOtokenWithdrawed(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is deposited into a vault
    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is withdrawn from a vault
    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short oToken is minted from a vault
    event ShortOtokenMinted(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short oToken is burned
    event ShortOtokenBurned(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when an oToken is redeemed
    event Redeem(
        address indexed otoken,
        address indexed redeemer,
        address indexed receiver,
        address collateralAsset,
        uint256 otokenBurned,
        uint256 payout
    );
    /// @notice emits an event when a vault is settled
    event VaultSettled(
        address indexed accountOwner,
        address indexed oTokenAddress,
        address to,
        uint256 payout,
        uint256 vaultId,
        uint256 indexed vaultType
    );
    /// @notice emits an event when a vault is liquidated
    event VaultLiquidated(
        address indexed liquidator,
        address indexed receiver,
        address indexed vaultOwner,
        uint256 auctionPrice,
        uint256 auctionStartingRound,
        uint256 collateralPayout,
        uint256 debtAmount,
        uint256 vaultId
    );
    /// @notice emits an event when a call action is executed
    event CallExecuted(address indexed from, address indexed to, bytes data);
    /// @notice emits an event when the fullPauser address changes
    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);
    /// @notice emits an event when the partialPauser address changes
    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);
    /// @notice emits an event when the system partial paused status changes
    event SystemPartiallyPaused(bool isPaused);
    /// @notice emits an event when the system fully paused status changes
    event SystemFullyPaused(bool isPaused);
    /// @notice emits an event when the call action restriction changes
    event CallRestricted(bool isRestricted);
    /// @notice emits an event when a donation transfer executed
    event Donated(address indexed donator, address indexed asset, uint256 amount);
    /// @notice emits an event when naked cap is updated
    event NakedCapUpdated(address indexed collateral, uint256 cap);

    /**
     * @notice modifier to check if the system is not partially paused, where only redeem and settleVault is allowed
     */
    modifier notPartiallyPaused() {
        _isNotPartiallyPaused();

        _;
    }

    /**
     * @notice modifier to check if the system is not fully paused, where no functionality is allowed
     */
    modifier notFullyPaused() {
        _isNotFullyPaused();

        _;
    }

    /**
     * @notice modifier to check if sender is the fullPauser address
     */
    modifier onlyFullPauser() {
        require(msg.sender == fullPauser, "C1");

        _;
    }

    /**
     * @notice modifier to check if the sender is the partialPauser address
     */
    modifier onlyPartialPauser() {
        require(msg.sender == partialPauser, "C2");

        _;
    }

    /**
     * @notice modifier to check if the sender is the account owner or an approved account operator
     * @param _sender sender address
     * @param _accountOwner account owner address
     */
    modifier onlyAuthorized(address _sender, address _accountOwner) {
        _isAuthorized(_sender, _accountOwner);

        _;
    }

    /**
     * @notice modifier to check if the called address is a whitelisted callee address
     * @param _callee called address
     */
    modifier onlyWhitelistedCallee(address _callee) {
        if (callRestricted) {
            require(_isCalleeWhitelisted(_callee), "C3");
        }

        _;
    }

    /**
     * @dev check if the system is not in a partiallyPaused state
     */
    function _isNotPartiallyPaused() internal view {
        require(!systemPartiallyPaused, "C4");
    }

    /**
     * @dev check if the system is not in an fullyPaused state
     */
    function _isNotFullyPaused() internal view {
        require(!systemFullyPaused, "C5");
    }

    /**
     * @dev check if the sender is an authorized operator
     * @param _sender msg.sender
     * @param _accountOwner owner of a vault
     */
    function _isAuthorized(address _sender, address _accountOwner) internal view {
        require((_sender == _accountOwner) || (operators[_accountOwner][_sender]), "C6");
    }

    /**
     * @notice initalize the deployed contract
     * @param _addressBook addressbook module
     * @param _owner account owner address
     */
    function initialize(address _addressBook, address _owner) external initializer {
        require(_addressBook != address(0), "C7");
        require(_owner != address(0), "C8");

        __Ownable_init(_owner);
        __ReentrancyGuard_init_unchained();

        addressbook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();

        callRestricted = true;
    }

    /**
     * @notice send asset amount to margin pool
     * @dev use donate() instead of direct transfer() to store the balance in assetBalance
     * @param _asset asset address
     * @param _amount amount to donate to pool
     */
    function donate(address _asset, uint256 _amount) external {
        pool.transferToPool(_asset, msg.sender, _amount);

        emit Donated(msg.sender, _asset, _amount);
    }

    /**
     * @notice allows the partialPauser to toggle the systemPartiallyPaused variable and partially pause or partially unpause the system
     * @dev can only be called by the partialPauser
     * @param _partiallyPaused new boolean value to set systemPartiallyPaused to
     */
    function setSystemPartiallyPaused(bool _partiallyPaused) external onlyPartialPauser {
        require(systemPartiallyPaused != _partiallyPaused, "C9");

        systemPartiallyPaused = _partiallyPaused;

        emit SystemPartiallyPaused(systemPartiallyPaused);
    }

    /**
     * @notice allows the fullPauser to toggle the systemFullyPaused variable and fully pause or fully unpause the system
     * @dev can only be called by the fullyPauser
     * @param _fullyPaused new boolean value to set systemFullyPaused to
     */
    function setSystemFullyPaused(bool _fullyPaused) external onlyFullPauser {
        require(systemFullyPaused != _fullyPaused, "C9");

        systemFullyPaused = _fullyPaused;

        emit SystemFullyPaused(systemFullyPaused);
    }

    /**
     * @notice allows the owner to set the fullPauser address
     * @dev can only be called by the owner
     * @param _fullPauser new fullPauser address
     */
    function setFullPauser(address _fullPauser) external onlyOwner {
        require(_fullPauser != address(0), "C10");
        require(fullPauser != _fullPauser, "C9");
        emit FullPauserUpdated(fullPauser, _fullPauser);
        fullPauser = _fullPauser;
    }

    /**
     * @notice allows the owner to set the partialPauser address
     * @dev can only be called by the owner
     * @param _partialPauser new partialPauser address
     */
    function setPartialPauser(address _partialPauser) external onlyOwner {
        require(_partialPauser != address(0), "C11");
        require(partialPauser != _partialPauser, "C9");
        emit PartialPauserUpdated(partialPauser, _partialPauser);
        partialPauser = _partialPauser;
    }

    /**
     * @notice allows the owner to toggle the restriction on whitelisted call actions and only allow whitelisted
     * call addresses or allow any arbitrary call addresses
     * @dev can only be called by the owner
     * @param _isRestricted new call restriction state
     */
    function setCallRestriction(bool _isRestricted) external onlyOwner {
        require(callRestricted != _isRestricted, "C9");

        callRestricted = _isRestricted;

        emit CallRestricted(callRestricted);
    }

    /**
     * @notice allows a user to give or revoke privileges to an operator which can act on their behalf on their vaults
     * @dev can only be updated by the vault owner
     * @param _operator operator that the sender wants to give privileges to or revoke them from
     * @param _isOperator new boolean value that expresses if the sender is giving or revoking privileges for _operator
     */
    function setOperator(address _operator, bool _isOperator) external {
        require(operators[msg.sender][_operator] != _isOperator, "C9");

        operators[msg.sender][_operator] = _isOperator;

        emit AccountOperatorUpdated(msg.sender, _operator, _isOperator);
    }

    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /**
     * @notice set cap amount for collateral asset used in naked margin
     * @dev can only be called by owner
     * @param _collateral collateral asset address
     * @param _cap cap amount, should be scaled by collateral asset decimals
     */
    function setNakedCap(address _collateral, uint256 _cap) external onlyOwner {
        require(_cap > 0, "C36");

        nakedCap[_collateral] = _cap;

        emit NakedCapUpdated(_collateral, _cap);
    }

    /**
     * @notice execute a number of actions on specific vaults
     * @dev can only be called when the system is not fully paused
     * @param _actions array of actions arguments
     */
    function operate(Actions.ActionArgs[] memory _actions) external nonReentrant notFullyPaused {
        (bool vaultUpdated, address vaultOwner, uint256 vaultId) = _runActions(_actions);
        if (vaultUpdated) {
            _verifyFinalState(vaultOwner, vaultId);
            vaultLatestUpdate[vaultOwner][vaultId] = now;
        }
    }

    /**
     * @notice sync vault latest update timestamp
     * @dev anyone can update the latest time the vault was touched by calling this function
     * vaultLatestUpdate will sync if the vault is well collateralized
     * @param _owner vault owner address
     * @param _vaultId vault id
     */
    function sync(address _owner, uint256 _vaultId) external nonReentrant notFullyPaused {
        _verifyFinalState(_owner, _vaultId);
        vaultLatestUpdate[_owner][_vaultId] = now;
    }

    /**
     * @notice check if a specific address is an operator for an owner account
     * @param _owner account owner address
     * @param _operator account operator address
     * @return True if the _operator is an approved operator for the _owner account
     */
    function isOperator(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }

    /**
     * @notice returns the current controller configuration
     * @return whitelist, the address of the whitelist module
     * @return oracle, the address of the oracle module
     * @return calculator, the address of the calculator module
     * @return pool, the address of the pool module
     */
    function getConfiguration()
        external
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        return (address(whitelist), address(oracle), address(calculator), address(pool));
    }

    /**
     * @notice return a vault's proceeds pre or post expiry, the amount of collateral that can be removed from a vault
     * @param _owner account owner of the vault
     * @param _vaultId vaultId to return balances for
     * @return amount of collateral that can be taken out
     */
    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256) {
        (MarginVault.Vault memory vault, uint256 typeVault, ) = getVaultWithDetails(_owner, _vaultId);

        (uint256 netValue, bool isExcess) = calculator.getExcessCollateral(vault, typeVault);

        if (!isExcess) return 0;

        return netValue;
    }

    /**
     * @notice check if a vault is liquidatable in a specific round id
     * @param _owner vault owner address
     * @param _vaultId vault id to check
     * @param _roundId chainlink round id to check vault status at
     * @return isUnderCollat, true if vault is undercollateralized, the price of 1 repaid otoken and the otoken collateral dust amount
     */
    function isLiquidatable(
        address _owner,
        uint256 _vaultId,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        (, bool isUnderCollat, uint256 price, uint256 dust) = _isLiquidatable(_owner, _vaultId, _roundId);
        return (isUnderCollat, price, dust);
    }

    /**
     * @notice get an oToken's payout/cash value after expiry, in the collateral asset
     * @param _otoken oToken address
     * @param _amount amount of the oToken to calculate the payout for, always represented in 1e8
     * @return amount of collateral to pay out
     */
    function getPayout(address _otoken, uint256 _amount) public view returns (uint256) {
        return calculator.getExpiredPayoutRate(_otoken).mul(_amount).div(10**BASE);
    }

    /**
     * @dev return if an expired oToken is ready to be settled, only true when price for underlying,
     * strike and collateral assets at this specific expiry is available in our Oracle module
     * @param _otoken oToken
     */
    function isSettlementAllowed(address _otoken) external view returns (bool) {
        (address underlying, address strike, address collateral, uint256 expiry) = _getOtokenDetails(_otoken);
        return _canSettleAssets(underlying, strike, collateral, expiry);
    }

    /**
     * @dev return if underlying, strike, collateral are all allowed to be settled
     * @param _underlying oToken underlying asset
     * @param _strike oToken strike asset
     * @param _collateral oToken collateral asset
     * @param _expiry otoken expiry timestamp
     * @return True if the oToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function canSettleAssets(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool) {
        return _canSettleAssets(_underlying, _strike, _collateral, _expiry);
    }

    /**
     * @notice get the number of vaults for a specified account owner
     * @param _accountOwner account owner address
     * @return number of vaults
     */
    function getAccountVaultCounter(address _accountOwner) external view returns (uint256) {
        return accountVaultCounter[_accountOwner];
    }

    /**
     * @notice check if an oToken has expired
     * @param _otoken oToken address
     * @return True if the otoken has expired, False if not
     */
    function hasExpired(address _otoken) external view returns (bool) {
        return now >= OtokenInterface(_otoken).expiryTimestamp();
    }

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner
     */
    function getVault(address _owner, uint256 _vaultId) external view returns (MarginVault.Vault memory) {
        return (vaults[_owner][_vaultId]);
    }

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner, vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        public
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        )
    {
        return (vaults[_owner][_vaultId], vaultType[_owner][_vaultId], vaultLatestUpdate[_owner][_vaultId]);
    }

    /**
     * @notice get cap amount for collateral asset
     * @param _asset collateral asset address
     * @return cap amount
     */
    function getNakedCap(address _asset) external view returns (uint256) {
        return nakedCap[_asset];
    }

    /**
     * @notice get amount of collateral deposited in all naked margin vaults
     * @param _asset collateral asset address
     * @return naked pool balance
     */
    function getNakedPoolBalance(address _asset) external view returns (uint256) {
        return nakedPoolBalance[_asset];
    }

    /**
     * @notice execute a variety of actions
     * @dev for each action in the action array, execute the corresponding action, only one vault can be modified
     * for all actions except SettleVault, Redeem, and Call
     * @param _actions array of type Actions.ActionArgs[], which expresses which actions the user wants to execute
     * @return vaultUpdated, indicates if a vault has changed
     * @return owner, the vault owner if a vault has changed
     * @return vaultId, the vault Id if a vault has changed
     */
    function _runActions(Actions.ActionArgs[] memory _actions)
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        address vaultOwner;
        uint256 vaultId;
        bool vaultUpdated;

        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];
            Actions.ActionType actionType = action.actionType;

            // actions except Settle, Redeem, Liquidate and Call are "Vault-updating actinos"
            // only allow update 1 vault in each operate call
            if (
                (actionType != Actions.ActionType.SettleVault) &&
                (actionType != Actions.ActionType.Redeem) &&
                (actionType != Actions.ActionType.Liquidate) &&
                (actionType != Actions.ActionType.Call)
            ) {
                // check if this action is manipulating the same vault as all other actions, if a vault has already been updated
                if (vaultUpdated) {
                    require(vaultOwner == action.owner, "C12");
                    require(vaultId == action.vaultId, "C13");
                }
                vaultUpdated = true;
                vaultId = action.vaultId;
                vaultOwner = action.owner;
            }

            if (actionType == Actions.ActionType.OpenVault) {
                _openVault(Actions._parseOpenVaultArgs(action));
            } else if (actionType == Actions.ActionType.DepositLongOption) {
                _depositLong(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawLongOption) {
                _withdrawLong(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.DepositCollateral) {
                _depositCollateral(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawCollateral) {
                _withdrawCollateral(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.MintShortOption) {
                _mintOtoken(Actions._parseMintArgs(action));
            } else if (actionType == Actions.ActionType.BurnShortOption) {
                _burnOtoken(Actions._parseBurnArgs(action));
            } else if (actionType == Actions.ActionType.Redeem) {
                _redeem(Actions._parseRedeemArgs(action));
            } else if (actionType == Actions.ActionType.SettleVault) {
                _settleVault(Actions._parseSettleVaultArgs(action));
            } else if (actionType == Actions.ActionType.Liquidate) {
                _liquidate(Actions._parseLiquidateArgs(action));
            } else if (actionType == Actions.ActionType.Call) {
                _call(Actions._parseCallArgs(action));
            }
        }

        return (vaultUpdated, vaultOwner, vaultId);
    }

    /**
     * @notice verify the vault final state after executing all actions
     * @param _owner account owner address
     * @param _vaultId vault id of the final vault
     */
    function _verifyFinalState(address _owner, uint256 _vaultId) internal view {
        (MarginVault.Vault memory vault, uint256 typeVault, ) = getVaultWithDetails(_owner, _vaultId);
        (, bool isValidVault) = calculator.getExcessCollateral(vault, typeVault);

        require(isValidVault, "C14");
    }

    /**
     * @notice open a new vault inside an account
     * @dev only the account owner or operator can open a vault, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args OpenVaultArgs structure
     */
    function _openVault(Actions.OpenVaultArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        uint256 vaultId = accountVaultCounter[_args.owner].add(1);

        require(_args.vaultId == vaultId, "C15");

        // store new vault
        accountVaultCounter[_args.owner] = vaultId;
        vaultType[_args.owner][vaultId] = _args.vaultType;

        emit VaultOpened(_args.owner, vaultId, _args.vaultType);
    }

    /**
     * @notice deposit a long oToken into a vault
     * @dev only the account owner or operator can deposit a long oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositLong(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");
        // only allow vault owner or vault operator to deposit long otoken
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C16");

        require(whitelist.isWhitelistedOtoken(_args.asset), "C17");

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "C18");

        vaults[_args.owner][_args.vaultId].addLong(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit LongOtokenDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a long oToken from a vault
     * @dev only the account owner or operator can withdraw a long oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawLong(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "C19");

        vaults[_args.owner][_args.vaultId].removeLong(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit LongOtokenWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice deposit a collateral asset into a vault
     * @dev only the account owner or operator can deposit collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositCollateral(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");
        // only allow vault owner or vault operator to deposit collateral
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C20");

        require(whitelist.isWhitelistedCollateral(_args.asset), "C21");

        (, uint256 typeVault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        if (typeVault == 1) {
            nakedPoolBalance[_args.asset] = nakedPoolBalance[_args.asset].add(_args.amount);

            require(nakedPoolBalance[_args.asset] <= nakedCap[_args.asset], "C37");
        }

        vaults[_args.owner][_args.vaultId].addCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit CollateralAssetDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a collateral asset from a vault
     * @dev only the account owner or operator can withdraw collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawCollateral(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");

        (MarginVault.Vault memory vault, uint256 typeVault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        if (_isNotEmpty(vault.shortOtokens)) {
            OtokenInterface otoken = OtokenInterface(vault.shortOtokens[0]);

            require(now < otoken.expiryTimestamp(), "C22");
        }

        if (typeVault == 1) {
            nakedPoolBalance[_args.asset] = nakedPoolBalance[_args.asset].sub(_args.amount);
        }

        vaults[_args.owner][_args.vaultId].removeCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit CollateralAssetWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice mint short oTokens from a vault which creates an obligation that is recorded in the vault
     * @dev only the account owner or operator can mint an oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _mintOtoken(Actions.MintArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");
        require(whitelist.isWhitelistedOtoken(_args.otoken), "C23");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now < otoken.expiryTimestamp(), "C24");

        vaults[_args.owner][_args.vaultId].addShort(_args.otoken, _args.amount, _args.index);

        otoken.mintOtoken(_args.to, _args.amount);

        emit ShortOtokenMinted(_args.otoken, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice burn oTokens to reduce or remove the minted oToken obligation recorded in a vault
     * @dev only the account owner or operator can burn an oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _burnOtoken(Actions.BurnArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        // check that vault id is valid for this vault owner
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");
        // only allow vault owner or vault operator to burn otoken
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C25");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        // do not allow burning expired otoken
        require(now < otoken.expiryTimestamp(), "C26");

        // remove otoken from vault
        vaults[_args.owner][_args.vaultId].removeShort(_args.otoken, _args.amount, _args.index);

        // burn otoken
        otoken.burnOtoken(_args.from, _args.amount);

        emit ShortOtokenBurned(_args.otoken, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice redeem an oToken after expiry, receiving the payout of the oToken in the collateral asset
     * @dev cannot be called when system is fullyPaused
     * @param _args RedeemArgs structure
     */
    function _redeem(Actions.RedeemArgs memory _args) internal {
        OtokenInterface otoken = OtokenInterface(_args.otoken);

        // check that otoken to redeem is whitelisted
        require(whitelist.isWhitelistedOtoken(_args.otoken), "C27");

        (address collateral, address underlying, address strike, uint256 expiry) = _getOtokenDetails(address(otoken));

        // only allow redeeming expired otoken
        require(now >= expiry, "C28");

        require(_canSettleAssets(underlying, strike, collateral, expiry), "C29");

        uint256 payout = getPayout(_args.otoken, _args.amount);

        otoken.burnOtoken(msg.sender, _args.amount);

        pool.transferToUser(collateral, _args.receiver, payout);

        emit Redeem(_args.otoken, msg.sender, _args.receiver, collateral, _args.amount, payout);
    }

    /**
     * @notice settle a vault after expiry, removing the net proceeds/collateral after both long and short oToken payouts have settled
     * @dev deletes a vault of vaultId after net proceeds/collateral is removed, cannot be called when system is fullyPaused
     * @param _args SettleVaultArgs structure
     */
    function _settleVault(Actions.SettleVaultArgs memory _args) internal onlyAuthorized(msg.sender, _args.owner) {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");

        (MarginVault.Vault memory vault, uint256 typeVault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        OtokenInterface otoken;

        // new scope to avoid stack too deep error
        // check if there is short or long otoken in vault
        // do not allow settling vault that have no short or long otoken
        // if there is a long otoken, burn it
        // store otoken address outside of this scope
        {
            bool hasShort = _isNotEmpty(vault.shortOtokens);
            bool hasLong = _isNotEmpty(vault.longOtokens);

            require(hasShort || hasLong, "C30");

            otoken = hasShort ? OtokenInterface(vault.shortOtokens[0]) : OtokenInterface(vault.longOtokens[0]);

            if (hasLong) {
                OtokenInterface longOtoken = OtokenInterface(vault.longOtokens[0]);

                longOtoken.burnOtoken(address(pool), vault.longAmounts[0]);
            }
        }

        (address collateral, address underlying, address strike, uint256 expiry) = _getOtokenDetails(address(otoken));

        // do not allow settling vault with un-expired otoken
        require(now >= expiry, "C31");
        require(_canSettleAssets(underlying, strike, collateral, expiry), "C29");

        (uint256 payout, bool isValidVault) = calculator.getExcessCollateral(vault, typeVault);

        // require that vault is valid (has excess collateral) before settling
        // to avoid allowing settling undercollateralized naked margin vault
        require(isValidVault, "C32");

        delete vaults[_args.owner][_args.vaultId];

        if (typeVault == 1) {
            nakedPoolBalance[collateral] = nakedPoolBalance[collateral].sub(payout);
        }

        pool.transferToUser(collateral, _args.to, payout);

        uint256 vaultId = _args.vaultId;
        address payoutRecipient = _args.to;

        emit VaultSettled(_args.owner, address(otoken), payoutRecipient, payout, vaultId, typeVault);
    }

    /**
     * @notice liquidate naked margin vault
     * @dev can liquidate different vaults id in the same operate() call
     * @param _args liquidation action arguments struct
     */
    function _liquidate(Actions.LiquidateArgs memory _args) internal notPartiallyPaused {
        require(_checkVaultId(_args.owner, _args.vaultId), "C35");

        // check if vault is undercollateralized
        // the price is the amount of collateral asset to pay per 1 repaid debt(otoken)
        // collateralDust is the minimum amount of collateral that can be left in the vault when a partial liquidation occurs
        (MarginVault.Vault memory vault, bool isUnderCollat, uint256 price, uint256 collateralDust) = _isLiquidatable(
            _args.owner,
            _args.vaultId,
            _args.roundId
        );

        require(isUnderCollat, "C33");

        // amount of collateral to offer to liquidator
        uint256 collateralToSell = _args.amount.mul(price).div(1e8);

        // if vault is partially liquidated (amount of short otoken is still greater than zero)
        // make sure remaining collateral amount is greater than dust amount
        if (vault.shortAmounts[0].sub(_args.amount) > 0) {
            require(vault.collateralAmounts[0].sub(collateralToSell) >= collateralDust, "C34");
        }

        // burn short otoken from liquidator address, index of short otoken hardcoded at 0
        // this should always work, if vault have no short otoken, it will not reach this step
        OtokenInterface(vault.shortOtokens[0]).burnOtoken(msg.sender, _args.amount);

        // decrease amount of collateral in liquidated vault, index of collateral to decrease is hardcoded at 0
        vaults[_args.owner][_args.vaultId].removeCollateral(vault.collateralAssets[0], collateralToSell, 0);

        // decrease amount of short otoken in liquidated vault, index of short otoken to decrease is hardcoded at 0
        vaults[_args.owner][_args.vaultId].removeShort(vault.shortOtokens[0], _args.amount, 0);

        // decrease internal naked margin collateral amount
        nakedPoolBalance[vault.collateralAssets[0]] = nakedPoolBalance[vault.collateralAssets[0]].sub(collateralToSell);

        pool.transferToUser(vault.collateralAssets[0], _args.receiver, collateralToSell);

        emit VaultLiquidated(
            msg.sender,
            _args.receiver,
            _args.owner,
            price,
            _args.roundId,
            collateralToSell,
            _args.amount,
            _args.vaultId
        );
    }

    /**
     * @notice execute arbitrary calls
     * @dev cannot be called when system is partiallyPaused or fullyPaused
     * @param _args Call action
     */
    function _call(Actions.CallArgs memory _args) internal notPartiallyPaused onlyWhitelistedCallee(_args.callee) {
        CalleeInterface(_args.callee).callFunction(msg.sender, _args.data);

        emit CallExecuted(msg.sender, _args.callee, _args.data);
    }

    /**
     * @notice check if a vault id is valid for a given account owner address
     * @param _accountOwner account owner address
     * @param _vaultId vault id to check
     * @return True if the _vaultId is valid, False if not
     */
    function _checkVaultId(address _accountOwner, uint256 _vaultId) internal view returns (bool) {
        return ((_vaultId > 0) && (_vaultId <= accountVaultCounter[_accountOwner]));
    }

    function _isNotEmpty(address[] memory _array) internal pure returns (bool) {
        return (_array.length > 0) && (_array[0] != address(0));
    }

    /**
     * @notice return if a callee address is whitelisted or not
     * @param _callee callee address
     * @return True if callee address is whitelisted, False if not
     */
    function _isCalleeWhitelisted(address _callee) internal view returns (bool) {
        return whitelist.isWhitelistedCallee(_callee);
    }

    /**
     * @notice check if a vault is liquidatable in a specific round id
     * @param _owner vault owner address
     * @param _vaultId vault id to check
     * @param _roundId chainlink round id to check vault status at
     * @return vault struct, isLiquidatable, true if vault is undercollateralized, the price of 1 repaid otoken and the otoken collateral dust amount
     */
    function _isLiquidatable(
        address _owner,
        uint256 _vaultId,
        uint256 _roundId
    )
        internal
        view
        returns (
            MarginVault.Vault memory,
            bool,
            uint256,
            uint256
        )
    {
        (MarginVault.Vault memory vault, uint256 typeVault, uint256 latestUpdateTimestamp) = getVaultWithDetails(
            _owner,
            _vaultId
        );
        (bool isUnderCollat, uint256 price, uint256 collateralDust) = calculator.isLiquidatable(
            vault,
            typeVault,
            latestUpdateTimestamp,
            _roundId
        );

        return (vault, isUnderCollat, price, collateralDust);
    }

    /**
     * @dev get otoken detail, from both otoken versions
     */
    function _getOtokenDetails(address _otoken)
        internal
        view
        returns (
            address,
            address,
            address,
            uint256
        )
    {
        OtokenInterface otoken = OtokenInterface(_otoken);
        try otoken.getOtokenDetails() returns (
            address collateral,
            address underlying,
            address strike,
            uint256,
            uint256 expiry,
            bool
        ) {
            return (collateral, underlying, strike, expiry);
        } catch {
            return (otoken.collateralAsset(), otoken.underlyingAsset(), otoken.strikeAsset(), otoken.expiryTimestamp());
        }
    }

    /**
     * @dev return if an expired oToken is ready to be settled, only true when price for underlying,
     * strike and collateral assets at this specific expiry is available in our Oracle module
     * @return True if the oToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function _canSettleAssets(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) internal view returns (bool) {
        return
            oracle.isDisputePeriodOver(_underlying, _expiry) &&
            oracle.isDisputePeriodOver(_strike, _expiry) &&
            oracle.isDisputePeriodOver(_collateral, _expiry);
    }

    /**
     * @dev updates the internal configuration of the controller
     */
    function _refreshConfigInternal() internal {
        whitelist = WhitelistInterface(addressbook.getWhitelist());
        oracle = OracleInterface(addressbook.getOracle());
        calculator = MarginCalculatorInterface(addressbook.getMarginCalculator());
        pool = MarginPoolInterface(addressbook.getMarginPool());
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short otoken amount
 * V2: invalid short otoken index
 * V3: short otoken address mismatch
 * V4: invalid long otoken amount
 * V5: invalid long otoken index
 * V6: long otoken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 */

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V1");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require((_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length), "V2");
            address existingShort = _vault.shortOtokens[_index];
            require((existingShort == _shortOtoken) || (existingShort == address(0)), "V3");

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index].add(_amount);
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "V2");
        require(_vault.shortOtokens[_index] == _shortOtoken, "V3");

        uint256 newShortAmount = _vault.shortAmounts[_index].sub(_amount);

        if (newShortAmount == 0) {
            delete _vault.shortOtokens[_index];
        }
        _vault.shortAmounts[_index] = newShortAmount;
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V4");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require((_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length), "V5");
            address existingLong = _vault.longOtokens[_index];
            require((existingLong == _longOtoken) || (existingLong == address(0)), "V6");

            _vault.longAmounts[_index] = _vault.longAmounts[_index].add(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "V5");
        require(_vault.longOtokens[_index] == _longOtoken, "V6");

        uint256 newLongAmount = _vault.longAmounts[_index].sub(_amount);

        if (newLongAmount == 0) {
            delete _vault.longOtokens[_index];
        }
        _vault.longAmounts[_index] = newLongAmount;
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V7");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require((_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length), "V8");
            address existingCollateral = _vault.collateralAssets[_index];
            require((existingCollateral == _collateralAsset) || (existingCollateral == address(0)), "V9");

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].add(_amount);
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "V8");
        require(_vault.collateralAssets[_index] == _collateralAsset, "V9");

        uint256 newCollateralAmount = _vault.collateralAmounts[_index].sub(_amount);

        if (newCollateralAmount == 0) {
            delete _vault.collateralAssets[_index];
        }
        _vault.collateralAmounts[_index] = newCollateralAmount;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity ^0.6.0;

import "./GSN/ContextUpgradeable.sol";
import "./Initializable.sol";

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init(address _sender) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(_sender);
    }

    function __Ownable_init_unchained(address _sender) internal initializer {
        _owner = _sender;
        emit OwnershipTransferred(address(0), _sender);
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

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts-upgradeable v3.0.0

pragma solidity ^0.6.0;

import "./Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {MarginVault} from "../libs/MarginVault.sol";

interface MarginCalculatorInterface {
    function addressBook() external view returns (address);

    function getExpiredPayoutRate(address _otoken) external view returns (uint256);

    function getExcessCollateral(MarginVault.Vault calldata _vault, uint256 _vaultType)
        external
        view
        returns (uint256 netValue, bool isExcess);

    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOtoken(address _otoken) external;

    function blacklistOtoken(address _otoken) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface MarginPoolInterface {
    /* Getters */
    function addressBook() external view returns (address);

    function farmer() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Admin-only functions */
    function setFarmer(address _farmer) external;

    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external;

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function batchTransferToPool(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;

    function batchTransferToUser(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {CalleeInterface} from "../interfaces/CalleeInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeERC20} from "../packages/oz/SafeERC20.sol";

/**
 * @author Opyn Team
 * @title CalleeAllowanceTester
 * @notice contract test if we can successfully pull weth from the payable proxy
 */
contract CalleeAllowanceTester is CalleeInterface {
    using SafeERC20 for ERC20Interface;
    ERC20Interface public weth;

    constructor(address _weth) public {
        weth = ERC20Interface(_weth);
    }

    // tset pull token
    function callFunction(address payable, bytes memory _data) external override {
        (address from, uint256 amount) = abi.decode(_data, (address, uint256));

        weth.safeTransferFrom(from, address(this), amount);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

// import "../packages/oz/upgradeability/VersionedInitializable.sol";
import "../interfaces/OtokenInterface.sol";
import "../interfaces/CalleeInterface.sol";
import "../interfaces/ERC20Interface.sol";

/**
 * @author Opyn Team
 * @notice Upgradeable Controller that can mock minting and burning calls from controller.
 */
contract MockController {
    /// @notice addressbook address
    address public addressBook;
    address public owner;

    /**
     * @dev this function is invoked by the proxy contract when this contract is added to the
     * AddressBook.
     * @param _addressBook the address of the AddressBook
     **/
    function initialize(address _addressBook, address _owner) external {
        addressBook = _addressBook;
        owner = _owner;
    }

    /**
     * @dev this function is used to test if controller can mint otokens
     */
    function testMintOtoken(
        address _otoken,
        address _account,
        uint256 _amount
    ) external {
        OtokenInterface(_otoken).mintOtoken(_account, _amount);
    }

    /**
     * @dev this function is used to test if controller can burn otokens
     */
    function testBurnOtoken(
        address _otoken,
        address _account,
        uint256 _amount
    ) external {
        OtokenInterface(_otoken).burnOtoken(_account, _amount);
    }

    /**
     * @dev this function is used to test if controller can be the only msg.sender to the 0xcallee
     */
    function test0xCallee(address _callee, bytes memory _data) external {
        CalleeInterface(_callee).callFunction(msg.sender, _data);
    }
}

pragma solidity =0.6.10;

import {OtokenSpawner} from "./OtokenSpawner.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {WhitelistInterface} from "../interfaces/WhitelistInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @title A factory to create Opyn oTokens
 * @author Opyn Team
 * @notice Create new oTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for oToken logic contract
 */
contract OtokenFactory is OtokenSpawner {
    using SafeMath for uint256;
    /// @notice Opyn AddressBook contract that records the address of the Whitelist module and the Otoken impl address. */
    address public addressBook;

    /// @notice array of all created otokens */
    address[] public otokens;

    /// @dev mapping from parameters hash to its deployed address
    mapping(bytes32 => address) private idToAddress;

    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    constructor(address _addressBook) public {
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    /**
     * @notice create new oTokens
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newOtoken address of the newly created option
     */
    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address) {
        require(_expiry > now, "OtokenFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "OtokenFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        require(_expiry.sub(28800).mod(86400) == 0, "OtokenFactory: Option has to expire 08:00 UTC");
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        require(idToAddress[id] == address(0), "OtokenFactory: Option already created");

        address whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAsset,
                _isPut
            ),
            "OtokenFactory: Unsupported Product"
        );

        require(!_isPut || _strikePrice > 0, "OtokenFactory: Can't create a $0 strike put option");

        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        address newOtoken = _spawn(otokenImpl, initializationCalldata);

        idToAddress[id] = newOtoken;
        otokens.push(newOtoken);
        WhitelistInterface(whitelist).whitelistOtoken(newOtoken);

        emit OtokenCreated(
            newOtoken,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        return newOtoken;
    }

    /**
     * @notice get the total oTokens created by the factory
     * @return length of the oTokens array
     */
    function getOtokensLength() external view returns (uint256) {
        return otokens.length;
    }

    /**
     * @notice get the oToken address for an already created oToken, if no oToken has been created with these parameters, it will return address(0)
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return the address of target otoken.
     */
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        return idToAddress[id];
    }

    /**
     * @notice get the address at which a new oToken with these parameters would be deployed
     * @dev return the exact address that will be deployed at with _computeAddress
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return targetAddress the address this oToken would be deployed at
     */
    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );
        return _computeAddress(otokenImpl, initializationCalldata);
    }

    /**
     * @dev hash oToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an oToken
     */
    function _getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut)
            );
    }
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity =0.6.10;

import {Spawn} from "../packages/Spawn.sol";
import {Create2} from "../packages/oz/Create2.sol";

/**
 * @title OtokenSpawner
 * @author Opyn Team
 * @notice This contract spawns and initializes eip-1167 minimal proxies that
 * point to existing logic contracts.
 * @notice This contract was modified from Spawner.sol
 * https://github.com/0age/Spawner/blob/master/contracts/Spawner.sol to fit into OtokenFactory
 */
contract OtokenSpawner {
    // fixed salt value because we will only deploy an oToken with the same init value once
    bytes32 private constant SALT = bytes32(0);

    /**
     * @notice internal function for spawning an eip-1167 minimal proxy using `CREATE2`
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return spawnedContract the address of the newly-spawned contract
     */
    function _spawn(address logicContract, bytes memory initializationCalldata) internal returns (address) {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );

        // spawn the contract using `CREATE2`
        return Create2.deploy(0, SALT, initCode);
    }

    /**
     * @notice internal view function for finding the address of the standard
     * eip-1167 minimal proxy created using `CREATE2` with a given logic contract
     * and initialization calldata payload
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return target address of the next spawned minimal proxy contract with the
     * given parameters.
     */
    function _computeAddress(address logicContract, bytes memory initializationCalldata)
        internal
        view
        returns (address target)
    {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );
        // get target address using the constructed initialization code
        bytes32 initCodeHash = keccak256(initCode);

        target = Create2.computeAddress(SALT, initCodeHash);
    }
}

/* solhint-disable avoid-low-level-calls, indent, no-inline-assembly */
/* This contract is copied from Spawner package: https://github.com/0age/Spawner */
pragma solidity =0.6.10;

/**
 * @title Spawn
 * @author 0age
 * @notice This contract provides creation code that is used by Spawner in order
 * to initialize and deploy eip-1167 minimal proxies for a given logic contract.
 * SPDX-License-Identifier: MIT
 */
// version: https://github.com/0age/Spawner/blob/1b342afda0c1ec47e6a2d65828a6ca50f0a442fe/contracts/Spawner.sol
contract Spawn {
    constructor(address logicContract, bytes memory initializationCalldata) public payable {
        // delegatecall into the logic contract to perform initialization.
        (bool ok, ) = logicContract.delegatecall(initializationCalldata);
        if (!ok) {
            // pass along failure message from delegatecall and revert.
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode = abi.encodePacked(
            bytes10(0x363d3d373d3d3d363d73),
            logicContract,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );

        // return eip-1167 code to write it to spawned contract runtime.
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0
/* solhint-disable */

pragma solidity =0.6.10;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.10;

import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {WSTETHInterface} from "../interfaces/WSTETHInterface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * Error Codes
 * W1: cannot deploy pricer, wstETH address cannot be 0
 * W2: cannot deploy pricer, underlying address cannot be 0
 * W3: cannot deploy pricer, oracle address cannot be 0
 * W4: cannot retrieve price, underlying price is 0
 * W5: cannot set expiry price in oracle, underlying price is 0 and has not been set
 * W6: cannot retrieve historical prices, getHistoricalPrice has been deprecated
 */

/**
 * @title WstethPricer
 * @author Opyn Team
 * @notice A Pricer contract for a wstETH token
 */
contract WstethPricer is OpynPricerInterface {
    using SafeMath for uint256;

    /// @notice opyn oracle address
    OracleInterface public oracle;

    /// @notice wstETH token
    WSTETHInterface public wstETH;

    /// @notice underlying asset (WETH)
    address public underlying;

    /**
     * @param _wstETH wstETH
     * @param _underlying underlying asset for wstETH
     * @param _oracle Opyn Oracle contract address
     */
    constructor(
        address _wstETH,
        address _underlying,
        address _oracle
    ) public {
        require(_wstETH != address(0), "W1");
        require(_underlying != address(0), "W2");
        require(_oracle != address(0), "W3");

        wstETH = WSTETHInterface(_wstETH);
        oracle = OracleInterface(_oracle);
        underlying = _underlying;
    }

    /**
     * @notice get the live price for the asset
     * @dev overrides the getPrice function in OpynPricerInterface
     * @return price of 1 wstETH in USD, scaled by 1e8
     */
    function getPrice() external view override returns (uint256) {
        uint256 underlyingPrice = oracle.getPrice(underlying);
        require(underlyingPrice > 0, "W4");
        return _underlyingPriceToWstethPrice(underlyingPrice);
    }

    /**
     * @notice set the expiry price in the oracle
     * @dev requires that the underlying price has been set before setting a wstETH price
     * @param _expiryTimestamp expiry to set a price for
     */
    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 underlyingPriceExpiry, ) = oracle.getExpiryPrice(underlying, _expiryTimestamp);
        require(underlyingPriceExpiry > 0, "W5");
        uint256 wstEthPrice = _underlyingPriceToWstethPrice(underlyingPriceExpiry);
        oracle.setExpiryPrice(address(wstETH), _expiryTimestamp, wstEthPrice);
    }

    /**
     * @dev convert underlying price to wstETH price with the wstETH to stETH exchange rate (1 stETH ≈ 1 ETH)
     * @param _underlyingPrice price of 1 underlying token (ie 1e18 WETH) in USD, scaled by 1e8
     * @return price of 1 wstETH in USD, scaled by 1e8
     */
    function _underlyingPriceToWstethPrice(uint256 _underlyingPrice) private view returns (uint256) {
        uint256 stEthPerWsteth = wstETH.stEthPerToken();

        return stEthPerWsteth.mul(_underlyingPrice).div(1e18);
    }

    function getHistoricalPrice(uint80) external view override returns (uint256, uint256) {
        revert("W6");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.10;

interface WSTETHInterface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function stEthPerToken() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {AggregatorInterface} from "../interfaces/AggregatorInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @notice A Pricer contract for one asset as reported by Chainlink
 */
contract ChainLinkPricer is OpynPricerInterface {
    using SafeMath for uint256;

    /// @dev base decimals
    uint256 internal constant BASE = 8;

    /// @notice chainlink response decimals
    uint256 public aggregatorDecimals;

    /// @notice the opyn oracle address
    OracleInterface public oracle;
    /// @notice the aggregator for an asset
    AggregatorInterface public aggregator;

    /// @notice asset that this pricer will a get price for
    address public asset;
    /// @notice bot address that is allowed to call setExpiryPriceInOracle
    address public bot;

    /**
     * @param _bot priveleged address that can call setExpiryPriceInOracle
     * @param _asset asset that this pricer will get a price for
     * @param _aggregator Chainlink aggregator contract for the asset
     * @param _oracle Opyn Oracle address
     */
    constructor(
        address _bot,
        address _asset,
        address _aggregator,
        address _oracle
    ) public {
        require(_bot != address(0), "ChainLinkPricer: Cannot set 0 address as bot");
        require(_oracle != address(0), "ChainLinkPricer: Cannot set 0 address as oracle");
        require(_aggregator != address(0), "ChainLinkPricer: Cannot set 0 address as aggregator");

        bot = _bot;
        oracle = OracleInterface(_oracle);
        aggregator = AggregatorInterface(_aggregator);
        asset = _asset;

        aggregatorDecimals = uint256(aggregator.decimals());
    }

    /**
     * @notice modifier to check if sender address is equal to bot address
     */
    modifier onlyBot() {
        require(msg.sender == bot, "ChainLinkPricer: unauthorized sender");

        _;
    }

    /**
     * @notice set the expiry price in the oracle, can only be called by Bot address
     * @dev a roundId must be provided to confirm price validity, which is the first Chainlink price provided after the expiryTimestamp
     * @param _expiryTimestamp expiry to set a price for
     * @param _roundId the first roundId after expiryTimestamp
     */
    function setExpiryPriceInOracle(uint256 _expiryTimestamp, uint80 _roundId) external onlyBot {
        (, int256 price, , uint256 roundTimestamp, ) = aggregator.getRoundData(_roundId);

        require(_expiryTimestamp <= roundTimestamp, "ChainLinkPricer: invalid roundId");

        oracle.setExpiryPrice(asset, _expiryTimestamp, uint256(price));
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice() external view override returns (uint256) {
        (, int256 answer, , , ) = aggregator.latestRoundData();
        require(answer > 0, "ChainLinkPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        return _scaleToBase(uint256(answer));
    }

    /**
     * @notice get historical chainlink price
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(uint80 _roundId) external view override returns (uint256, uint256) {
        (, int256 price, , uint256 roundTimestamp, ) = aggregator.getRoundData(_roundId);
        return (_scaleToBase(uint256(price)), roundTimestamp);
    }

    /**
     * @notice scale aggregator response to base decimals (1e8)
     * @param _price aggregator price
     * @return price scaled to 1e8
     */
    function _scaleToBase(uint256 _price) internal view returns (uint256) {
        if (aggregatorDecimals > BASE) {
            uint256 exp = aggregatorDecimals.sub(BASE);
            _price = _price.div(10**exp);
        } else if (aggregatorDecimals < BASE) {
            uint256 exp = BASE.sub(aggregatorDecimals);
            _price = _price.mul(10**exp);
        }

        return _price;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of the Chainlink aggregator
 */
interface AggregatorInterface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

pragma solidity =0.6.10;

import {SafeMath} from "../packages/oz/SafeMath.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @dev The MockOracle contract let us easily manipulate the oracle state in testings.
 */
contract MockOracle {
    struct Price {
        uint256 price;
        uint256 timestamp; // timestamp at which the price is pushed to this oracle
    }

    using SafeMath for uint256;

    mapping(address => uint256) public realTimePrice;
    mapping(address => mapping(uint256 => uint256)) public storedPrice;
    mapping(address => uint256) internal stablePrice;
    mapping(address => mapping(uint256 => bool)) public isFinalized;

    mapping(address => uint256) internal pricerLockingPeriod;
    mapping(address => uint256) internal pricerDisputePeriod;
    mapping(address => address) internal assetPricer;

    // asset => expiry => bool
    mapping(address => mapping(uint256 => bool)) private _isDisputePeriodOver;
    mapping(address => mapping(uint256 => bool)) private _isLockingPeriodOver;

    // chainlink historic round data, asset => round => price/timestamp
    mapping(address => mapping(uint80 => uint256)) private _roundPrice;
    mapping(address => mapping(uint80 => uint256)) private _roundTimestamp;

    function setRealTimePrice(address _asset, uint256 _price) external {
        realTimePrice[_asset] = _price;
    }

    // get chainlink historic round data
    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256) {
        uint256 price = _roundPrice[_asset][_roundId];
        uint256 timestamp = _roundTimestamp[_asset][_roundId];

        return (price, timestamp);
    }

    function getPrice(address _asset) external view returns (uint256) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            price = realTimePrice[_asset];
        }

        return price;
    }

    // set chainlink historic data for specific round id
    function setChainlinkRoundData(
        address _asset,
        uint80 _roundId,
        uint256 _price,
        uint256 _timestamp
    ) external returns (uint256, uint256) {
        _roundPrice[_asset][_roundId] = _price;
        _roundTimestamp[_asset][_roundId] = _timestamp;
    }

    // set bunch of things at expiry in 1 function
    function setExpiryPriceFinalizedAllPeiodOver(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price,
        bool _isFinalized
    ) external {
        storedPrice[_asset][_expiryTimestamp] = _price;
        isFinalized[_asset][_expiryTimestamp] = _isFinalized;
        _isDisputePeriodOver[_asset][_expiryTimestamp] = _isFinalized;
        _isLockingPeriodOver[_asset][_expiryTimestamp] = _isFinalized;
    }

    // let the pricer set expiry price to oracle.
    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external {
        storedPrice[_asset][_expiryTimestamp] = _price;
    }

    function setIsFinalized(
        address _asset,
        uint256 _expiryTimestamp,
        bool _isFinalized
    ) external {
        isFinalized[_asset][_expiryTimestamp] = _isFinalized;
    }

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool) {
        uint256 price = stablePrice[_asset];
        bool _isFinalized = true;

        if (price == 0) {
            price = storedPrice[_asset][_expiryTimestamp];
            _isFinalized = isFinalized[_asset][_expiryTimestamp];
        }

        return (price, _isFinalized);
    }

    function getPricer(address _asset) external view returns (address) {
        return assetPricer[_asset];
    }

    function getPricerLockingPeriod(address _pricer) external view returns (uint256) {
        return pricerLockingPeriod[_pricer];
    }

    function getPricerDisputePeriod(address _pricer) external view returns (uint256) {
        return pricerDisputePeriod[_pricer];
    }

    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) public view returns (bool) {
        return _isLockingPeriodOver[_asset][_expiryTimestamp];
    }

    function setIsLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp,
        bool _result
    ) external {
        _isLockingPeriodOver[_asset][_expiryTimestamp] = _result;
    }

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool) {
        return _isDisputePeriodOver[_asset][_expiryTimestamp];
    }

    function setIsDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp,
        bool _result
    ) external {
        _isDisputePeriodOver[_asset][_expiryTimestamp] = _result;
    }

    function setAssetPricer(address _asset, address _pricer) external {
        assetPricer[_asset] = _pricer;
    }

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external {
        pricerLockingPeriod[_pricer] = _lockingPeriod;
    }

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external {
        pricerDisputePeriod[_pricer] = _disputePeriod;
    }

    function setStablePrice(address _asset, uint256 _price) external {
        stablePrice[_asset] = _price;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {Ownable} from "../packages/oz/Ownable.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @author Opyn Team
 * @title Oracle Module
 * @notice The Oracle module sets, retrieves, and stores USD prices (USD per asset) for underlying, collateral, and strike assets
 * manages pricers that are used for different assets
 */
contract Oracle is Ownable {
    using SafeMath for uint256;

    /// @dev structure that stores price of asset and timestamp when the price was stored
    struct Price {
        uint256 price;
        uint256 timestamp; // timestamp at which the price is pushed to this oracle
    }

    //// @dev disputer is a role defined by the owner that has the ability to dispute a price during the dispute period
    address internal disputer;

    bool migrated;

    /// @dev mapping of asset pricer to its locking period
    /// locking period is the period of time after the expiry timestamp where a price can not be pushed
    mapping(address => uint256) internal pricerLockingPeriod;
    /// @dev mapping of asset pricer to its dispute period
    /// dispute period is the period of time after an expiry price has been pushed where a price can be disputed
    mapping(address => uint256) internal pricerDisputePeriod;
    /// @dev mapping between an asset and its pricer
    mapping(address => address) internal assetPricer;
    /// @dev mapping between asset, expiry timestamp, and the Price structure at the expiry timestamp
    mapping(address => mapping(uint256 => Price)) internal storedPrice;
    /// @dev mapping between stable asset and price
    mapping(address => uint256) internal stablePrice;

    /// @notice emits an event when the disputer is updated
    event DisputerUpdated(address indexed newDisputer);
    /// @notice emits an event when the pricer is updated for an asset
    event PricerUpdated(address indexed asset, address indexed pricer);
    /// @notice emits an event when the locking period is updated for a pricer
    event PricerLockingPeriodUpdated(address indexed pricer, uint256 lockingPeriod);
    /// @notice emits an event when the dispute period is updated for a pricer
    event PricerDisputePeriodUpdated(address indexed pricer, uint256 disputePeriod);
    /// @notice emits an event when an expiry price is updated for a specific asset
    event ExpiryPriceUpdated(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 price,
        uint256 onchainTimestamp
    );
    /// @notice emits an event when the disputer disputes a price during the dispute period
    event ExpiryPriceDisputed(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 disputedPrice,
        uint256 newPrice,
        uint256 disputeTimestamp
    );
    /// @notice emits an event when a stable asset price changes
    event StablePriceUpdated(address indexed asset, uint256 price);

    /**
     * @notice function to mgirate asset prices from old oracle to new deployed oracle
     * @dev this can only be called by owner, should be used at the deployment time before setting Oracle module into AddressBook
     * @param _asset asset address
     * @param _expiries array of expiries timestamps
     * @param _prices array of prices
     */
    function migrateOracle(
        address _asset,
        uint256[] calldata _expiries,
        uint256[] calldata _prices
    ) external onlyOwner {
        require(!migrated, "Oracle: migration already done");
        require(_expiries.length == _prices.length, "Oracle: invalid migration data");

        for (uint256 i; i < _expiries.length; i++) {
            storedPrice[_asset][_expiries[i]] = Price(_prices[i], now);
        }
    }

    /**
     * @notice end migration process
     * @dev can only be called by owner, should be called before setting Oracle module into AddressBook
     */
    function endMigration() external onlyOwner {
        migrated = true;
    }

    /**
     * @notice sets the pricer for an asset
     * @dev can only be called by the owner
     * @param _asset asset address
     * @param _pricer pricer address
     */
    function setAssetPricer(address _asset, address _pricer) external onlyOwner {
        require(_pricer != address(0), "Oracle: cannot set pricer to address(0)");
        require(stablePrice[_asset] == 0, "Oracle: could not set a pricer for stable asset");

        assetPricer[_asset] = _pricer;

        emit PricerUpdated(_asset, _pricer);
    }

    /**
     * @notice sets the locking period for a pricer
     * @dev can only be called by the owner
     * @param _pricer pricer address
     * @param _lockingPeriod locking period
     */
    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external onlyOwner {
        pricerLockingPeriod[_pricer] = _lockingPeriod;

        emit PricerLockingPeriodUpdated(_pricer, _lockingPeriod);
    }

    /**
     * @notice sets the dispute period for a pricer
     * @dev can only be called by the owner
     * for a composite pricer (ie CompoundPricer) that depends on or calls other pricers, ensure
     * that the dispute period for the composite pricer is longer than the dispute period for the
     * asset pricer that it calls to ensure safe usage as a dispute in the other pricer will cause
     * the need for a dispute with the composite pricer's price
     * @param _pricer pricer address
     * @param _disputePeriod dispute period
     */
    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external onlyOwner {
        pricerDisputePeriod[_pricer] = _disputePeriod;

        emit PricerDisputePeriodUpdated(_pricer, _disputePeriod);
    }

    /**
     * @notice set the disputer address
     * @dev can only be called by the owner
     * @param _disputer disputer address
     */
    function setDisputer(address _disputer) external onlyOwner {
        disputer = _disputer;

        emit DisputerUpdated(_disputer);
    }

    /**
     * @notice set stable asset price
     * @dev price should be scaled by 1e8
     * @param _asset asset address
     * @param _price price
     */
    function setStablePrice(address _asset, uint256 _price) external onlyOwner {
        require(assetPricer[_asset] == address(0), "Oracle: could not set stable price for an asset with pricer");

        stablePrice[_asset] = _price;

        emit StablePriceUpdated(_asset, _price);
    }

    /**
     * @notice dispute an asset price during the dispute period
     * @dev only the disputer can dispute a price during the dispute period, by setting a new one
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @param _price the correct price
     */
    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external {
        require(msg.sender == disputer, "Oracle: caller is not the disputer");
        require(!isDisputePeriodOver(_asset, _expiryTimestamp), "Oracle: dispute period over");

        Price storage priceToUpdate = storedPrice[_asset][_expiryTimestamp];

        require(priceToUpdate.timestamp != 0, "Oracle: price to dispute does not exist");

        uint256 oldPrice = priceToUpdate.price;
        priceToUpdate.price = _price;

        emit ExpiryPriceDisputed(_asset, _expiryTimestamp, oldPrice, _price, now);
    }

    /**
     * @notice submits the expiry price to the oracle, can only be set from the pricer
     * @dev asset price can only be set after the locking period is over and before the dispute period has started
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @param _price asset price at expiry
     */
    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external {
        require(msg.sender == assetPricer[_asset], "Oracle: caller is not authorized to set expiry price");
        require(isLockingPeriodOver(_asset, _expiryTimestamp), "Oracle: locking period is not over yet");
        require(storedPrice[_asset][_expiryTimestamp].timestamp == 0, "Oracle: dispute period started");

        storedPrice[_asset][_expiryTimestamp] = Price(_price, now);
        emit ExpiryPriceUpdated(_asset, _expiryTimestamp, _price, now);
    }

    /**
     * @notice get a live asset price from the asset's pricer contract
     * @param _asset asset address
     * @return price scaled by 1e8, denominated in USD
     * e.g. 17568900000 => 175.689 USD
     */
    function getPrice(address _asset) external view returns (uint256) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            require(assetPricer[_asset] != address(0), "Oracle: Pricer for this asset not set");

            price = OpynPricerInterface(assetPricer[_asset]).getPrice();
        }

        return price;
    }

    /**
     * @notice get the asset price at specific expiry timestamp
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return price scaled by 1e8, denominated in USD
     * @return isFinalized True, if the price is finalized, False if not
     */
    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool) {
        uint256 price = stablePrice[_asset];
        bool isFinalized = true;

        if (price == 0) {
            price = storedPrice[_asset][_expiryTimestamp].price;
            isFinalized = isDisputePeriodOver(_asset, _expiryTimestamp);
        }

        return (price, isFinalized);
    }

    /**
     * @notice get the pricer for an asset
     * @param _asset asset address
     * @return pricer address
     */
    function getPricer(address _asset) external view returns (address) {
        return assetPricer[_asset];
    }

    /**
     * @notice get the disputer address
     * @return disputer address
     */
    function getDisputer() external view returns (address) {
        return disputer;
    }

    /**
     * @notice get a pricer's locking period
     * locking period is the period of time after the expiry timestamp where a price can not be pushed
     * @dev during the locking period an expiry price can not be submitted to this contract
     * @param _pricer pricer address
     * @return locking period
     */
    function getPricerLockingPeriod(address _pricer) external view returns (uint256) {
        return pricerLockingPeriod[_pricer];
    }

    /**
     * @notice get a pricer's dispute period
     * dispute period is the period of time after an expiry price has been pushed where a price can be disputed
     * @dev during the dispute period, the disputer can dispute the submitted price and modify it
     * @param _pricer pricer address
     * @return dispute period
     */
    function getPricerDisputePeriod(address _pricer) external view returns (uint256) {
        return pricerDisputePeriod[_pricer];
    }

    /**
     * @notice get historical asset price and timestamp
     * @dev if asset is a stable asset, will return stored price and timestamp equal to now
     * @param _asset asset address to get it's historical price
     * @param _roundId chainlink round id
     * @return price and round timestamp
     */
    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256) {
        uint256 price = stablePrice[_asset];
        uint256 timestamp = now;

        if (price == 0) {
            require(assetPricer[_asset] != address(0), "Oracle: Pricer for this asset not set");

            (price, timestamp) = OpynPricerInterface(assetPricer[_asset]).getHistoricalPrice(_roundId);
        }

        return (price, timestamp);
    }

    /**
     * @notice check if the locking period is over for setting the asset price at a particular expiry timestamp
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return True if locking period is over, False if not
     */
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) public view returns (bool) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            address pricer = assetPricer[_asset];
            uint256 lockingPeriod = pricerLockingPeriod[pricer];

            return now > _expiryTimestamp.add(lockingPeriod);
        }

        return true;
    }

    /**
     * @notice check if the dispute period is over
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return True if dispute period is over, False if not
     */
    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) public view returns (bool) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            // check if the pricer has a price for this expiry timestamp
            Price memory price = storedPrice[_asset][_expiryTimestamp];
            if (price.timestamp == 0) {
                return false;
            }

            address pricer = assetPricer[_asset];
            uint256 disputePeriod = pricerDisputePeriod[pricer];

            return now > price.timestamp.add(disputePeriod);
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {CTokenInterface} from "../interfaces/CTokenInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @notice A Pricer contract for a Compound cToken
 */
contract CompoundPricer {
    using SafeMath for uint256;

    /// @notice opyn oracle address
    OracleInterface public oracle;

    /// @notice cToken that this pricer will a get price for
    CTokenInterface public cToken;

    /// @notice underlying asset for this cToken
    ERC20Interface public underlying;

    /**
     * @param _cToken cToken asset
     * @param _underlying underlying asset for this cToken
     * @param _oracle Opyn Oracle contract address
     */
    constructor(
        address _cToken,
        address _underlying,
        address _oracle
    ) public {
        require(_cToken != address(0), "CompoundPricer: cToken address can not be 0");
        require(_underlying != address(0), "CompoundPricer: underlying address can not be 0");
        require(_oracle != address(0), "CompoundPricer: oracle address can not be 0");

        cToken = CTokenInterface(_cToken);
        underlying = ERC20Interface(_underlying);
        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice get the live price for the asset
     * @return price of 1e8 cToken in USD, scaled by 1e8
     */
    function getPrice() external view returns (uint256) {
        uint256 underlyingPrice = oracle.getPrice(address(underlying));
        require(underlyingPrice > 0, "CompoundPricer: underlying price is 0");
        return _underlyingPriceToCtokenPrice(underlyingPrice);
    }

    /**
     * @notice set the expiry price in the oracle
     * @dev requires that the underlying price has been set before setting a cToken price
     * @param _expiryTimestamp expiry to set a price for
     */
    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 underlyingPriceExpiry, ) = oracle.getExpiryPrice(address(underlying), _expiryTimestamp);
        require(underlyingPriceExpiry > 0, "CompoundPricer: underlying price not set yet");
        uint256 cTokenPrice = _underlyingPriceToCtokenPrice(underlyingPriceExpiry);
        oracle.setExpiryPrice(address(cToken), _expiryTimestamp, cTokenPrice);
    }

    /**
     * @dev convert underlying price to cToken price with the cToken to underlying exchange rate
     * @param _underlyingPrice price of 1 underlying token (ie 1e6 USDC, 1e18 WETH) in USD, scaled by 1e8
     * @return price of 1e8 cToken in USD, scaled by 1e8
     */
    function _underlyingPriceToCtokenPrice(uint256 _underlyingPrice) internal view returns (uint256) {
        uint256 underlyingDecimals = uint256(underlying.decimals());
        uint256 cTokenDecimals = uint256(cToken.decimals());
        uint256 exchangeRate = cToken.exchangeRateStored();
        return exchangeRate.mul(_underlyingPrice).mul(10**(cTokenDecimals)).div(10**(underlyingDecimals.add(18)));
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of Compound cToken
 */
interface CTokenInterface {
    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {OracleInterface} from "../interfaces/OracleInterface.sol";

contract MockPricer {
    OracleInterface public oracle;

    uint256 internal price;
    address public asset;

    constructor(address _asset, address _oracle) public {
        asset = _asset;
        oracle = OracleInterface(_oracle);
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp, uint256 _price) external {
        oracle.setExpiryPrice(asset, _expiryTimestamp, _price);
    }

    function getHistoricalPrice(uint80 _roundId) external view returns (uint256, uint256) {
        return (price, now);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";
import {Ownable} from "../packages/oz/Ownable.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {FixedPointInt256 as FPI} from "../libs/FixedPointInt256.sol";
import {MarginVault} from "../libs/MarginVault.sol";

/**
 * @title MarginCalculator
 * @author Opyn
 * @notice Calculator module that checks if a given vault is valid, calculates margin requirements, and settlement proceeds
 */
contract MarginCalculator is Ownable {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    /// @dev decimals option upper bound value, spot shock and oracle deviation
    uint256 internal constant SCALING_FACTOR = 27;

    /// @dev decimals used by strike price and oracle price
    uint256 internal constant BASE = 8;

    /// @notice auction length
    uint256 public constant AUCTION_TIME = 3600;

    /// @dev struct to store all needed vault details
    struct VaultDetails {
        address shortUnderlyingAsset;
        address shortStrikeAsset;
        address shortCollateralAsset;
        address longUnderlyingAsset;
        address longStrikeAsset;
        address longCollateralAsset;
        uint256 shortStrikePrice;
        uint256 shortExpiryTimestamp;
        uint256 shortCollateralDecimals;
        uint256 longStrikePrice;
        uint256 longExpiryTimestamp;
        uint256 longCollateralDecimals;
        uint256 collateralDecimals;
        uint256 vaultType;
        bool isShortPut;
        bool isLongPut;
        bool hasLong;
        bool hasShort;
        bool hasCollateral;
    }

    /// @dev oracle deviation value (1e27)
    uint256 internal oracleDeviation;

    /// @dev FixedPoint 0
    FPI.FixedPointInt internal ZERO = FPI.fromScaledUint(0, BASE);

    /// @dev mapping to store dust amount per option collateral asset (scaled by collateral asset decimals)
    mapping(address => uint256) internal dust;

    /// @dev mapping to store array of time to expiry for a given product
    mapping(bytes32 => uint256[]) internal timesToExpiryForProduct;

    /// @dev mapping to store option upper bound value at specific time to expiry for a given product (1e27)
    mapping(bytes32 => mapping(uint256 => uint256)) internal maxPriceAtTimeToExpiry;

    /// @dev mapping to store shock value for spot price of a given product (1e27)
    mapping(bytes32 => uint256) internal spotShock;

    /// @dev oracle module
    OracleInterface public oracle;

    /// @notice emits an event when collateral dust is updated
    event CollateralDustUpdated(address indexed collateral, uint256 dust);
    /// @notice emits an event when new time to expiry is added for a specific product
    event TimeToExpiryAdded(bytes32 indexed productHash, uint256 timeToExpiry);
    /// @notice emits an event when new upper bound value is added for a specific time to expiry timestamp
    event MaxPriceAdded(bytes32 indexed productHash, uint256 timeToExpiry, uint256 value);
    /// @notice emits an event when updating upper bound value at specific expiry timestamp
    event MaxPriceUpdated(bytes32 indexed productHash, uint256 timeToExpiry, uint256 oldValue, uint256 newValue);
    /// @notice emits an event when spot shock value is updated for a specific product
    event SpotShockUpdated(bytes32 indexed product, uint256 spotShock);
    /// @notice emits an event when oracle deviation value is updated
    event OracleDeviationUpdated(uint256 oracleDeviation);

    /**
     * @notice constructor
     * @param _oracle oracle module address
     */
    constructor(address _oracle) public {
        require(_oracle != address(0), "MarginCalculator: invalid oracle address");

        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice set dust amount for collateral asset
     * @dev can only be called by owner
     * @param _collateral collateral asset address
     * @param _dust dust amount, should be scaled by collateral asset decimals
     */
    function setCollateralDust(address _collateral, uint256 _dust) external onlyOwner {
        require(_dust > 0, "MarginCalculator: dust amount should be greater than zero");

        dust[_collateral] = _dust;

        emit CollateralDustUpdated(_collateral, _dust);
    }

    /**
     * @notice set product upper bound values
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timesToExpiry array of times to expiry timestamp
     * @param _values upper bound values array
     */
    function setUpperBoundValues(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256[] calldata _timesToExpiry,
        uint256[] calldata _values
    ) external onlyOwner {
        require(_timesToExpiry.length > 0, "MarginCalculator: invalid times to expiry array");
        require(_timesToExpiry.length == _values.length, "MarginCalculator: invalid values array");

        // get product hash
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        uint256[] storage expiryArray = timesToExpiryForProduct[productHash];

        // check that this is the first expiry to set
        // if not, the last expiry should be less than the new one to insert (to make sure the array stay in order)
        require(
            (expiryArray.length == 0) || (_timesToExpiry[0] > expiryArray[expiryArray.length.sub(1)]),
            "MarginCalculator: expiry array is not in order"
        );

        for (uint256 i = 0; i < _timesToExpiry.length; i++) {
            // check that new times array is in order
            if (i.add(1) < _timesToExpiry.length) {
                require(_timesToExpiry[i] < _timesToExpiry[i.add(1)], "MarginCalculator: time should be in order");
            }

            require(_values[i] > 0, "MarginCalculator: no expiry upper bound value found");

            // add new upper bound value for this product at specific time to expiry
            maxPriceAtTimeToExpiry[productHash][_timesToExpiry[i]] = _values[i];

            // add new time to expiry to array
            expiryArray.push(_timesToExpiry[i]);

            emit TimeToExpiryAdded(productHash, _timesToExpiry[i]);
            emit MaxPriceAdded(productHash, _timesToExpiry[i], _values[i]);
        }
    }

    /**
     * @notice set option upper bound value for specific time to expiry (1e27)
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @param _value upper bound value
     */
    function updateUpperBoundValue(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry,
        uint256 _value
    ) external onlyOwner {
        require(_value > 0, "MarginCalculator: invalid option upper bound value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);
        uint256 oldMaxPrice = maxPriceAtTimeToExpiry[productHash][_timeToExpiry];

        require(oldMaxPrice != 0, "MarginCalculator: upper bound value not found");

        // update upper bound value for the time to expiry
        maxPriceAtTimeToExpiry[productHash][_timeToExpiry] = _value;

        emit MaxPriceUpdated(productHash, _timeToExpiry, oldMaxPrice, _value);
    }

    /**
     * @notice set spot shock value, scaled to 1e27
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _shockValue spot shock value
     */
    function setSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _shockValue
    ) external onlyOwner {
        require(_shockValue > 0, "MarginCalculator: invalid spot shock value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        spotShock[productHash] = _shockValue;

        emit SpotShockUpdated(productHash, _shockValue);
    }

    /**
     * @notice set oracle deviation (1e27)
     * @dev can only be called by owner
     * @param _deviation deviation value
     */
    function setOracleDeviation(uint256 _deviation) external onlyOwner {
        oracleDeviation = _deviation;

        emit OracleDeviationUpdated(_deviation);
    }

    /**
     * @notice get dust amount for collateral asset
     * @param _collateral collateral asset address
     * @return dust amount
     */
    function getCollateralDust(address _collateral) external view returns (uint256) {
        return dust[_collateral];
    }

    /**
     * @notice get times to expiry for a specific product
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return array of times to expiry
     */
    function getTimesToExpiry(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256[] memory) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);
        return timesToExpiryForProduct[productHash];
    }

    /**
     * @notice get option upper bound value for specific time to expiry
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @return option upper bound value (1e27)
     */
    function getMaxPrice(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return maxPriceAtTimeToExpiry[productHash][_timeToExpiry];
    }

    /**
     * @notice get spot shock value
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return _shockValue spot shock value (1e27)
     */
    function getSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return spotShock[productHash];
    }

    /**
     * @notice get oracle deviation
     * @return oracle deviation value (1e27)
     */
    function getOracleDeviation() external view returns (uint256) {
        return oracleDeviation;
    }

    /**
     * @notice return the collateral required for naked margin vault, in collateral asset decimals
     * @dev _shortAmount, _strikePrice and _underlyingPrice should be scaled by 1e8
     * @param _underlying underlying asset address
     * @param _strike strike asset address
     * @param _collateral collateral asset address
     * @param _shortAmount amount of short otoken
     * @param  _strikePrice otoken strike price
     * @param _underlyingPrice otoken underlying price
     * @param _shortExpiryTimestamp otoken expiry timestamp
     * @param _collateralDecimals otoken collateral asset decimals
     * @param _isPut otoken type
     * @return collateral required for a naked margin vault, in collateral asset decimals
     */
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        // scale short amount from 1e8 to 1e27 (oToken is always in 1e8)
        FPI.FixedPointInt memory shortAmount = FPI.fromScaledUint(_shortAmount, BASE);
        // scale short strike from 1e8 to 1e27
        FPI.FixedPointInt memory shortStrike = FPI.fromScaledUint(_strikePrice, BASE);
        // scale short underlying price from 1e8 to 1e27
        FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(_underlyingPrice, BASE);

        // return required margin, scaled by collateral asset decimals, explicitly rounded up
        return
            FPI.toScaledUint(
                _getNakedMarginRequired(
                    productHash,
                    shortAmount,
                    shortUnderlyingPrice,
                    shortStrike,
                    _shortExpiryTimestamp,
                    _isPut
                ),
                _collateralDecimals,
                false
            );
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in collateral
     * @param _otoken oToken address
     * @return how much collateral can be taken out by 1 otoken unit, scaled by 1e8,
     * or how much collateral can be taken out for 1 (1e8) oToken
     */
    function getExpiredPayoutRate(address _otoken) external view returns (uint256) {
        require(_otoken != address(0), "MarginCalculator: Invalid token address");

        (
            address collateral,
            address underlying,
            address strikeAsset,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut
        ) = _getOtokenDetails(_otoken);

        require(now >= expiry, "MarginCalculator: Otoken not expired yet");

        FPI.FixedPointInt memory cashValueInStrike = _getExpiredCashValue(
            underlying,
            strikeAsset,
            expiry,
            strikePrice,
            isPut
        );

        FPI.FixedPointInt memory cashValueInCollateral = _convertAmountOnExpiryPrice(
            cashValueInStrike,
            strikeAsset,
            collateral,
            expiry
        );

        // the exchangeRate was scaled by 1e8, if 1e8 otoken can take out 1 USDC, the exchangeRate is currently 1e8
        // we want to return: how much USDC units can be taken out by 1 (1e8 units) oToken
        uint256 collateralDecimals = uint256(ERC20Interface(collateral).decimals());
        return cashValueInCollateral.toScaledUint(collateralDecimals, true);
    }

    // structs to avoid stack too deep error
    // struct to store shortAmount, shortStrike and shortUnderlyingPrice scaled to 1e27
    struct ShortScaledDetails {
        FPI.FixedPointInt shortAmount;
        FPI.FixedPointInt shortStrike;
        FPI.FixedPointInt shortUnderlyingPrice;
    }

    /**
     * @notice check if a specific vault is undercollateralized at a specific chainlink round
     * @dev if the vault is of type 0, the function will revert
     * @param _vault vault struct
     * @param _vaultType vault type (0 for max loss/spread and 1 for naked margin vault)
     * @param _vaultLatestUpdate vault latest update (timestamp when latest vault state change happened)
     * @param _roundId chainlink round id
     * @return isLiquidatable, true if vault is undercollateralized, liquidation price and collateral dust amount
     */
    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        // liquidation is only supported for naked margin vault
        require(_vaultType == 1, "MarginCalculator: invalid vault type to liquidate");

        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // can not liquidate vault that have no short position
        if (!vaultDetails.hasShort) return (false, 0, 0);

        require(now < vaultDetails.shortExpiryTimestamp, "MarginCalculator: can not liquidate expired position");

        (uint256 price, uint256 timestamp) = oracle.getChainlinkRoundData(
            vaultDetails.shortUnderlyingAsset,
            uint80(_roundId)
        );

        // check that price timestamp is after latest timestamp the vault was updated at
        require(
            timestamp > _vaultLatestUpdate,
            "MarginCalculator: auction timestamp should be post vault latest update"
        );

        // another struct to store some useful short otoken details, to avoid stack to deep error
        ShortScaledDetails memory shortDetails = ShortScaledDetails({
            shortAmount: FPI.fromScaledUint(_vault.shortAmounts[0], BASE),
            shortStrike: FPI.fromScaledUint(vaultDetails.shortStrikePrice, BASE),
            shortUnderlyingPrice: FPI.fromScaledUint(price, BASE)
        });

        bytes32 productHash = _getProductHash(
            vaultDetails.shortUnderlyingAsset,
            vaultDetails.shortStrikeAsset,
            vaultDetails.shortCollateralAsset,
            vaultDetails.isShortPut
        );

        // convert vault collateral to a fixed point (1e27) from collateral decimals
        FPI.FixedPointInt memory depositedCollateral = FPI.fromScaledUint(
            _vault.collateralAmounts[0],
            vaultDetails.collateralDecimals
        );

        FPI.FixedPointInt memory collateralRequired = _getNakedMarginRequired(
            productHash,
            shortDetails.shortAmount,
            shortDetails.shortUnderlyingPrice,
            shortDetails.shortStrike,
            vaultDetails.shortExpiryTimestamp,
            vaultDetails.isShortPut
        );

        // if collateral required <= collateral in the vault, the vault is not liquidatable
        if (collateralRequired.isLessThanOrEqual(depositedCollateral)) {
            return (false, 0, 0);
        }

        FPI.FixedPointInt memory cashValue = _getCashValue(
            shortDetails.shortStrike,
            shortDetails.shortUnderlyingPrice,
            vaultDetails.isShortPut
        );

        // get the amount of collateral per 1 repaid otoken
        uint256 debtPrice = _getDebtPrice(
            depositedCollateral,
            shortDetails.shortAmount,
            cashValue,
            shortDetails.shortUnderlyingPrice,
            timestamp,
            vaultDetails.collateralDecimals,
            vaultDetails.isShortPut
        );

        return (true, debtPrice, dust[vaultDetails.shortCollateralAsset]);
    }

    /**
     * @notice calculate required collateral margin for a vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault, scaled to 1e27
     */
    function getMarginRequired(MarginVault.Vault memory _vault, uint256 _vaultType)
        external
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        VaultDetails memory vaultDetail = _getVaultDetails(_vault, _vaultType);
        return _getMarginRequired(_vault, vaultDetail);
    }

    /**
     * @notice returns the amount of collateral that can be removed from an actual or a theoretical vault
     * @dev return amount is denominated in the collateral asset for the oToken in the vault, or the collateral asset in the vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type (0 for spread/max loss, 1 for naked margin)
     * @return excessCollateral the amount by which the margin is above or below the required amount
     * @return isExcess True if there is excess margin in the vault, False if there is a deficit of margin in the vault
     * if True, collateral can be taken out from the vault, if False, additional collateral needs to be added to vault
     */
    function getExcessCollateral(MarginVault.Vault memory _vault, uint256 _vaultType)
        public
        view
        returns (uint256, bool)
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // include all the checks for to ensure the vault is valid
        _checkIsValidVault(_vault, vaultDetails);

        // if the vault contains no oTokens, return the amount of collateral
        if (!vaultDetails.hasShort && !vaultDetails.hasLong) {
            uint256 amount = vaultDetails.hasCollateral ? _vault.collateralAmounts[0] : 0;
            return (amount, true);
        }

        // get required margin, denominated in collateral, scaled in 1e27
        (FPI.FixedPointInt memory collateralAmount, FPI.FixedPointInt memory collateralRequired) = _getMarginRequired(
            _vault,
            vaultDetails
        );
        FPI.FixedPointInt memory excessCollateral = collateralAmount.sub(collateralRequired);

        bool isExcess = excessCollateral.isGreaterThanOrEqual(ZERO);
        uint256 collateralDecimals = vaultDetails.hasLong
            ? vaultDetails.longCollateralDecimals
            : vaultDetails.shortCollateralDecimals;
        // if is excess, truncate the tailing digits in excessCollateralExternal calculation
        uint256 excessCollateralExternal = excessCollateral.toScaledUint(collateralDecimals, isExcess);
        return (excessCollateralExternal, isExcess);
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in strike asset
     * @dev for a call, return Max (0, underlyingPriceInStrike - otoken.strikePrice)
     * @dev for a put, return Max(0, otoken.strikePrice - underlyingPriceInStrike)
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _expiryTimestamp otoken expiry timestamp
     * @param _strikePrice otoken strike price
     * @param _strikePrice true if otoken is put otherwise false
     * @return cash value of an expired otoken, denominated in the strike asset
     */
    function _getExpiredCashValue(
        address _underlying,
        address _strike,
        uint256 _expiryTimestamp,
        uint256 _strikePrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // strike price is denominated in strike asset
        FPI.FixedPointInt memory strikePrice = FPI.fromScaledUint(_strikePrice, BASE);
        FPI.FixedPointInt memory one = FPI.fromScaledUint(1, 0);

        // calculate the value of the underlying asset in terms of the strike asset
        FPI.FixedPointInt memory underlyingPriceInStrike = _convertAmountOnExpiryPrice(
            one, // underlying price is 1 (1e27) in term of underlying
            _underlying,
            _strike,
            _expiryTimestamp
        );

        return _getCashValue(strikePrice, underlyingPriceInStrike, _isPut);
    }

    /// @dev added this struct to avoid stack-too-deep error
    struct OtokenDetails {
        address otokenUnderlyingAsset;
        address otokenCollateralAsset;
        address otokenStrikeAsset;
        uint256 otokenExpiry;
        bool isPut;
    }

    /**
     * @notice calculate the amount of collateral needed for a vault
     * @dev vault passed in has already passed the checkIsValidVault function
     * @param _vault theoretical vault that needs to be checked
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault,
     * scaled to 1e27
     */
    function _getMarginRequired(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        FPI.FixedPointInt memory shortAmount = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vault.shortAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory longAmount = _vaultDetails.hasLong
            ? FPI.fromScaledUint(_vault.longAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory collateralAmount = _vaultDetails.hasCollateral
            ? FPI.fromScaledUint(_vault.collateralAmounts[0], _vaultDetails.collateralDecimals)
            : ZERO;
        FPI.FixedPointInt memory shortStrike = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vaultDetails.shortStrikePrice, BASE)
            : ZERO;

        // struct to avoid stack too deep error
        OtokenDetails memory otokenDetails = OtokenDetails(
            _vaultDetails.hasShort ? _vaultDetails.shortUnderlyingAsset : _vaultDetails.longUnderlyingAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortCollateralAsset : _vaultDetails.longCollateralAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortStrikeAsset : _vaultDetails.longStrikeAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortExpiryTimestamp : _vaultDetails.longExpiryTimestamp,
            _vaultDetails.hasShort ? _vaultDetails.isShortPut : _vaultDetails.isLongPut
        );

        if (now < otokenDetails.otokenExpiry) {
            // it's not expired, return amount of margin required based on vault type
            if (_vaultDetails.vaultType == 1) {
                // this is a naked margin vault
                // fetch dust amount for otoken collateral asset as FixedPointInt, assuming dust is already scaled by collateral decimals
                FPI.FixedPointInt memory dustAmount = FPI.fromScaledUint(
                    dust[_vaultDetails.shortCollateralAsset],
                    _vaultDetails.collateralDecimals
                );

                // check that collateral deposited in naked margin vault is greater than dust amount for that particular collateral asset
                if (collateralAmount.isGreaterThan(ZERO)) {
                    require(
                        collateralAmount.isGreaterThan(dustAmount),
                        "MarginCalculator: naked margin vault should have collateral amount greater than dust amount"
                    );
                }

                // get underlying asset price for short option
                FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(
                    oracle.getPrice(_vaultDetails.shortUnderlyingAsset),
                    BASE
                );

                // encode product hash
                bytes32 productHash = _getProductHash(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortCollateralAsset,
                    _vaultDetails.isShortPut
                );

                // return amount of collateral in vault and needed collateral amount for margin
                return (
                    collateralAmount,
                    _getNakedMarginRequired(
                        productHash,
                        shortAmount,
                        shortUnderlyingPrice,
                        shortStrike,
                        otokenDetails.otokenExpiry,
                        otokenDetails.isPut
                    )
                );
            } else {
                // this is a fully collateralized vault
                FPI.FixedPointInt memory longStrike = _vaultDetails.hasLong
                    ? FPI.fromScaledUint(_vaultDetails.longStrikePrice, BASE)
                    : ZERO;

                if (otokenDetails.isPut) {
                    FPI.FixedPointInt memory strikeNeeded = _getPutSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            strikeNeeded,
                            otokenDetails.otokenStrikeAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                } else {
                    FPI.FixedPointInt memory underlyingNeeded = _getCallSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            underlyingNeeded,
                            otokenDetails.otokenUnderlyingAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                }
            }
        } else {
            // the vault has expired. calculate the cash value of all the minted short options
            FPI.FixedPointInt memory shortCashValue = _vaultDetails.hasShort
                ? _getExpiredCashValue(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortExpiryTimestamp,
                    _vaultDetails.shortStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;
            FPI.FixedPointInt memory longCashValue = _vaultDetails.hasLong
                ? _getExpiredCashValue(
                    _vaultDetails.longUnderlyingAsset,
                    _vaultDetails.longStrikeAsset,
                    _vaultDetails.longExpiryTimestamp,
                    _vaultDetails.longStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;

            FPI.FixedPointInt memory valueInStrike = _getExpiredSpreadCashValue(
                shortAmount,
                longAmount,
                shortCashValue,
                longCashValue
            );

            // convert amount to be denominated in collateral
            return (
                collateralAmount,
                _convertAmountOnExpiryPrice(
                    valueInStrike,
                    otokenDetails.otokenStrikeAsset,
                    otokenDetails.otokenCollateralAsset,
                    otokenDetails.otokenExpiry
                )
            );
        }
    }

    /**
     * @notice get required collateral for naked margin position
     * if put:
     * a = min(strike price, spot shock * underlying price)
     * b = max(strike price - spot shock * underlying price, 0)
     * marginRequired = ( option upper bound value * a + b) * short amount
     * if call:
     * a = min(1, strike price / (underlying price / spot shock value))
     * b = max(1- (strike price / (underlying price / spot shock value)), 0)
     * marginRequired = (option upper bound value * a + b) * short amount
     * @param _productHash product hash
     * @param _shortAmount short amount in vault, in FixedPointInt type
     * @param _strikePrice strike price of short otoken, in FixedPointInt type
     * @param _underlyingPrice underlying price of short otoken underlying asset, in FixedPointInt type
     * @param _shortExpiryTimestamp short otoken expiry timestamp
     * @param _isPut otoken type, true if put option, false for call option
     * @return required margin for this naked vault, in FixedPointInt type (scaled by 1e27)
     */
    function _getNakedMarginRequired(
        bytes32 _productHash,
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _underlyingPrice,
        FPI.FixedPointInt memory _strikePrice,
        uint256 _shortExpiryTimestamp,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // find option upper bound value
        FPI.FixedPointInt memory optionUpperBoundValue = _findUpperBoundValue(_productHash, _shortExpiryTimestamp);
        // convert spot shock value of this product to FixedPointInt (already scaled by 1e27)
        FPI.FixedPointInt memory spotShockValue = FPI.FixedPointInt(int256(spotShock[_productHash]));

        FPI.FixedPointInt memory a;
        FPI.FixedPointInt memory b;
        FPI.FixedPointInt memory marginRequired;

        if (_isPut) {
            a = FPI.min(_strikePrice, spotShockValue.mul(_underlyingPrice));
            b = FPI.max(_strikePrice.sub(spotShockValue.mul(_underlyingPrice)), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        } else {
            FPI.FixedPointInt memory one = FPI.fromScaledUint(1e27, SCALING_FACTOR);
            a = FPI.min(one, _strikePrice.mul(spotShockValue).div(_underlyingPrice));
            b = FPI.max(one.sub(_strikePrice.mul(spotShockValue).div(_underlyingPrice)), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        }

        return marginRequired;
    }

    /**
     * @notice find upper bound value for product by specific expiry timestamp
     * @dev should return the upper bound value that correspond to option time to expiry, of if not found should return the next greater one, revert if no value found
     * @param _productHash product hash
     * @param _expiryTimestamp expiry timestamp
     * @return option upper bound value
     */
    function _findUpperBoundValue(bytes32 _productHash, uint256 _expiryTimestamp)
        internal
        view
        returns (FPI.FixedPointInt memory)
    {
        // get time to expiry array of this product hash
        uint256[] memory timesToExpiry = timesToExpiryForProduct[_productHash];

        // check that this product have upper bound values stored
        require(timesToExpiry.length != 0, "MarginCalculator: product have no expiry values");

        uint256 optionTimeToExpiry = _expiryTimestamp.sub(now);

        // check that the option time to expiry is in the expiry array
        require(
            timesToExpiry[timesToExpiry.length.sub(1)] >= optionTimeToExpiry,
            "MarginCalculator: product have no upper bound value"
        );

        // loop through the array and return the upper bound value in FixedPointInt type (already scaled by 1e27)
        for (uint8 i = 0; i < timesToExpiry.length; i++) {
            if (timesToExpiry[i] >= optionTimeToExpiry)
                return FPI.fromScaledUint(maxPriceAtTimeToExpiry[_productHash][timesToExpiry[i]], SCALING_FACTOR);
        }
    }

    /**
     * @dev returns the strike asset amount of margin required for a put or put spread with the given short oTokens, long oTokens and amounts
     *
     * marginRequired = max( (short amount * short strike) - (long strike * min (short amount, long amount)) , 0 )
     *
     * @return margin requirement denominated in the strike asset
     */
    function _getPutSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        return FPI.max(_shortAmount.mul(_shortStrike).sub(_longStrike.mul(FPI.min(_shortAmount, _longAmount))), ZERO);
    }

    /**
     * @dev returns the underlying asset amount required for a call or call spread with the given short oTokens, long oTokens, and amounts
     *
     *                           (long strike - short strike) * short amount
     * marginRequired =  max( ------------------------------------------------- , max (short amount - long amount, 0) )
     *                                           long strike
     *
     * @dev if long strike = 0, return max( short amount - long amount, 0)
     * @return margin requirement denominated in the underlying asset
     */
    function _getCallSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        // max (short amount - long amount , 0)
        if (_longStrike.isEqual(ZERO)) {
            return FPI.max(_shortAmount.sub(_longAmount), ZERO);
        }

        /**
         *             (long strike - short strike) * short amount
         * calculate  ----------------------------------------------
         *                             long strike
         */
        FPI.FixedPointInt memory firstPart = _longStrike.sub(_shortStrike).mul(_shortAmount).div(_longStrike);

        /**
         * calculate max ( short amount - long amount , 0)
         */
        FPI.FixedPointInt memory secondPart = FPI.max(_shortAmount.sub(_longAmount), ZERO);

        return FPI.max(firstPart, secondPart);
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on a live price
     * @dev function includes the amount and applies .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on an expiry price
     * @dev function includes the amount and apply .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnExpiryPrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB,
        uint256 _expiry
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        (uint256 priceA, bool priceAFinalized) = oracle.getExpiryPrice(_assetA, _expiry);
        (uint256 priceB, bool priceBFinalized) = oracle.getExpiryPrice(_assetB, _expiry);
        require(priceAFinalized && priceBFinalized, "MarginCalculator: price at expiry not finalized yet");
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice return debt price, how much collateral asset per 1 otoken repaid in collateral decimal
     * ending price = vault collateral / vault debt
     * if auction ended, return ending price
     * else calculate starting price
     * for put option:
     * starting price = max(cash value - underlying price * oracle deviation, 0)
     * for call option:
     *                      max(cash value - underlying price * oracle deviation, 0)
     * starting price =  ---------------------------------------------------------------
     *                                          underlying price
     *
     *
     *                  starting price + (ending price - starting price) * auction elapsed time
     * then price = --------------------------------------------------------------------------
     *                                      auction time
     *
     *
     * @param _vaultCollateral vault collateral amount
     * @param _vaultDebt vault short amount
     * @param _cashValue option cash value
     * @param _spotPrice option underlying asset price (in USDC)
     * @param _auctionStartingTime auction starting timestamp (_spotPrice timestamp from chainlink)
     * @param _collateralDecimals collateral asset decimals
     * @param _isPut otoken type, true for put, false for call option
     * @return price of 1 debt otoken in collateral asset scaled by collateral decimals
     */
    function _getDebtPrice(
        FPI.FixedPointInt memory _vaultCollateral,
        FPI.FixedPointInt memory _vaultDebt,
        FPI.FixedPointInt memory _cashValue,
        FPI.FixedPointInt memory _spotPrice,
        uint256 _auctionStartingTime,
        uint256 _collateralDecimals,
        bool _isPut
    ) internal view returns (uint256) {
        // price of 1 repaid otoken in collateral asset, scaled to 1e27
        FPI.FixedPointInt memory price;
        // auction ending price
        FPI.FixedPointInt memory endingPrice = _vaultCollateral.div(_vaultDebt);

        // auction elapsed time
        uint256 auctionElapsedTime = now.sub(_auctionStartingTime);

        // if auction ended, return ending price
        if (auctionElapsedTime >= AUCTION_TIME) {
            price = endingPrice;
        } else {
            // starting price
            FPI.FixedPointInt memory startingPrice;

            {
                // store oracle deviation in a FixedPointInt (already scaled by 1e27)
                FPI.FixedPointInt memory fixedOracleDeviation = FPI.fromScaledUint(oracleDeviation, SCALING_FACTOR);

                if (_isPut) {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO);
                } else {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO).div(_spotPrice);
                }
            }

            // store auctionElapsedTime in a FixedPointInt scaled by 1e27
            FPI.FixedPointInt memory auctionElapsedTimeFixedPoint = FPI.fromScaledUint(auctionElapsedTime, 18);
            // store AUCTION_TIME in a FixedPointInt (already scaled by 1e27)
            FPI.FixedPointInt memory auctionTime = FPI.fromScaledUint(AUCTION_TIME, 18);

            // calculate price of 1 repaid otoken, scaled by the collateral decimals, expilictly rounded down
            price = startingPrice.add(
                (endingPrice.sub(startingPrice)).mul(auctionElapsedTimeFixedPoint).div(auctionTime)
            );

            // cap liquidation price to ending price
            if (price.isGreaterThan(endingPrice)) price = endingPrice;
        }

        return price.toScaledUint(_collateralDecimals, true);
    }

    /**
     * @notice get vault details to save us from making multiple external calls
     * @param _vault vault struct
     * @param _vaultType vault type, 0 for max loss/spreads and 1 for naked margin vault
     * @return vault details in VaultDetails struct
     */
    function _getVaultDetails(MarginVault.Vault memory _vault, uint256 _vaultType)
        internal
        view
        returns (VaultDetails memory)
    {
        VaultDetails memory vaultDetails = VaultDetails(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            false,
            false
        );

        // check if vault has long, short otoken and collateral asset
        vaultDetails.hasLong = _isNotEmpty(_vault.longOtokens);
        vaultDetails.hasShort = _isNotEmpty(_vault.shortOtokens);
        vaultDetails.hasCollateral = _isNotEmpty(_vault.collateralAssets);

        vaultDetails.vaultType = _vaultType;

        // get vault long otoken if available
        if (vaultDetails.hasLong) {
            OtokenInterface long = OtokenInterface(_vault.longOtokens[0]);
            (
                vaultDetails.longCollateralAsset,
                vaultDetails.longUnderlyingAsset,
                vaultDetails.longStrikeAsset,
                vaultDetails.longStrikePrice,
                vaultDetails.longExpiryTimestamp,
                vaultDetails.isLongPut
            ) = _getOtokenDetails(address(long));
            vaultDetails.longCollateralDecimals = uint256(ERC20Interface(vaultDetails.longCollateralAsset).decimals());
        }

        // get vault short otoken if available
        if (vaultDetails.hasShort) {
            OtokenInterface short = OtokenInterface(_vault.shortOtokens[0]);
            (
                vaultDetails.shortCollateralAsset,
                vaultDetails.shortUnderlyingAsset,
                vaultDetails.shortStrikeAsset,
                vaultDetails.shortStrikePrice,
                vaultDetails.shortExpiryTimestamp,
                vaultDetails.isShortPut
            ) = _getOtokenDetails(address(short));
            vaultDetails.shortCollateralDecimals = uint256(
                ERC20Interface(vaultDetails.shortCollateralAsset).decimals()
            );
        }

        if (vaultDetails.hasCollateral) {
            vaultDetails.collateralDecimals = uint256(ERC20Interface(_vault.collateralAssets[0]).decimals());
        }

        return vaultDetails;
    }

    /**
     * @dev calculate the cash value obligation for an expired vault, where a positive number is an obligation
     *
     * Formula: net = (short cash value * short amount) - ( long cash value * long Amount )
     *
     * @return cash value obligation denominated in the strike asset
     */
    function _getExpiredSpreadCashValue(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortCashValue,
        FPI.FixedPointInt memory _longCashValue
    ) internal pure returns (FPI.FixedPointInt memory) {
        return _shortCashValue.mul(_shortAmount).sub(_longCashValue.mul(_longAmount));
    }

    /**
     * @dev check if asset array contain a token address
     * @return True if the array is not empty
     */
    function _isNotEmpty(address[] memory _assets) internal pure returns (bool) {
        return _assets.length > 0 && _assets[0] != address(0);
    }

    /**
     * @dev ensure that:
     * a) at most 1 asset type used as collateral
     * b) at most 1 series of option used as the long option
     * c) at most 1 series of option used as the short option
     * d) asset array lengths match for long, short and collateral
     * e) long option and collateral asset is acceptable for margin with short asset
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     */
    function _checkIsValidVault(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails) internal pure {
        // ensure all the arrays in the vault are valid
        require(_vault.shortOtokens.length <= 1, "MarginCalculator: Too many short otokens in the vault");
        require(_vault.longOtokens.length <= 1, "MarginCalculator: Too many long otokens in the vault");
        require(_vault.collateralAssets.length <= 1, "MarginCalculator: Too many collateral assets in the vault");

        require(
            _vault.shortOtokens.length == _vault.shortAmounts.length,
            "MarginCalculator: Short asset and amount mismatch"
        );
        require(
            _vault.longOtokens.length == _vault.longAmounts.length,
            "MarginCalculator: Long asset and amount mismatch"
        );
        require(
            _vault.collateralAssets.length == _vault.collateralAmounts.length,
            "MarginCalculator: Collateral asset and amount mismatch"
        );

        // ensure the long asset is valid for the short asset
        require(
            _isMarginableLong(_vault, _vaultDetails),
            "MarginCalculator: long asset not marginable for short asset"
        );

        // ensure that the collateral asset is valid for the short asset
        require(
            _isMarginableCollateral(_vault, _vaultDetails),
            "MarginCalculator: collateral asset not marginable for short asset"
        );
    }

    /**
     * @dev if there is a short option and a long option in the vault, ensure that the long option is able to be used as collateral for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if long is marginable or false if not
     */
    function _isMarginableLong(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        if (_vaultDetails.vaultType == 1)
            require(!_vaultDetails.hasLong, "MarginCalculator: naked margin vault cannot have long otoken");

        // if vault is missing a long or a short, return True
        if (!_vaultDetails.hasLong || !_vaultDetails.hasShort) return true;

        return
            _vault.longOtokens[0] != _vault.shortOtokens[0] &&
            _vaultDetails.longUnderlyingAsset == _vaultDetails.shortUnderlyingAsset &&
            _vaultDetails.longStrikeAsset == _vaultDetails.shortStrikeAsset &&
            _vaultDetails.longCollateralAsset == _vaultDetails.shortCollateralAsset &&
            _vaultDetails.longExpiryTimestamp == _vaultDetails.shortExpiryTimestamp &&
            _vaultDetails.isLongPut == _vaultDetails.isShortPut;
    }

    /**
     * @dev if there is short option and collateral asset in the vault, ensure that the collateral asset is valid for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if marginable or false
     */
    function _isMarginableCollateral(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        bool isMarginable = true;

        if (!_vaultDetails.hasCollateral) return isMarginable;

        if (_vaultDetails.hasShort) {
            isMarginable = _vaultDetails.shortCollateralAsset == _vault.collateralAssets[0];
        } else if (_vaultDetails.hasLong) {
            isMarginable = _vaultDetails.longCollateralAsset == _vault.collateralAssets[0];
        }

        return isMarginable;
    }

    /**
     * @notice get a product hash
     * @param _underlying option underlying asset
     * @param _strike option strike asset
     * @param _collateral option collateral asset
     * @param _isPut option type
     * @return product hash
     */
    function _getProductHash(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));
    }

    /**
     * @notice get option cash value
     * @dev this assume that the underlying price is denominated in strike asset
     * cash value = max(underlying price - strike price, 0)
     * @param _strikePrice option strike price
     * @param _underlyingPrice option underlying price
     * @param _isPut option type, true for put and false for call option
     */
    function _getCashValue(
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_isPut) return _strikePrice.isGreaterThan(_underlyingPrice) ? _strikePrice.sub(_underlyingPrice) : ZERO;

        return _underlyingPrice.isGreaterThan(_strikePrice) ? _underlyingPrice.sub(_strikePrice) : ZERO;
    }

    /**
     * @dev get otoken detail, from both otoken versions
     */
    function _getOtokenDetails(address _otoken)
        internal
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        OtokenInterface otoken = OtokenInterface(_otoken);
        try otoken.getOtokenDetails() returns (
            address collateral,
            address underlying,
            address strike,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut
        ) {
            return (collateral, underlying, strike, strikePrice, expiry, isPut);
        } catch {
            // v1 otoken
            return (
                otoken.collateralAsset(),
                otoken.underlyingAsset(),
                otoken.strikeAsset(),
                otoken.strikePrice(),
                otoken.expiryTimestamp(),
                otoken.isPut()
            );
        }
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import "../packages/oz/SignedSafeMath.sol";
import "../libs/SignedConverter.sol";
import "../packages/oz/SafeMath.sol";

/**
 * @title FixedPointInt256
 * @author Opyn Team
 * @notice FixedPoint library
 */
library FixedPointInt256 {
    using SignedSafeMath for int256;
    using SignedConverter for int256;
    using SafeMath for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 5.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.05 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @title SignedConverter
 * @author Opyn Team
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
        }
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import {MarginCalculator} from "../core/MarginCalculator.sol";
import {FixedPointInt256} from "../libs/FixedPointInt256.sol";

contract CalculatorTester is MarginCalculator {
    constructor(address _addressBook) public MarginCalculator(_addressBook) {}

    function getExpiredCashValue(
        address _underlying,
        address _strike,
        uint256 _expiryTimestamp,
        uint256 _strikePrice,
        bool _isPut
    ) external view returns (uint256) {
        return
            FixedPointInt256.toScaledUint(
                _getExpiredCashValue(_underlying, _strike, _expiryTimestamp, _strikePrice, _isPut),
                BASE,
                true
            );
    }

    function findUpperBoundValue(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _expiryTimestamp
    ) external view returns (uint256) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return FixedPointInt256.toScaledUint(_findUpperBoundValue(productHash, _expiryTimestamp), 27, false);
    }

    function price(
        uint256 _vaultCollateral,
        uint256 _vaultDebt,
        uint256 _cv,
        uint256 _spotPrice,
        uint256 _auctionStartingTime,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256) {
        FixedPointInt256.FixedPointInt memory vaultCollateral = FixedPointInt256.fromScaledUint(
            _vaultCollateral,
            _collateralDecimals
        );
        FixedPointInt256.FixedPointInt memory vaultDebt = FixedPointInt256.fromScaledUint(_vaultDebt, BASE);
        FixedPointInt256.FixedPointInt memory cv = FixedPointInt256.fromScaledUint(_cv, BASE);
        FixedPointInt256.FixedPointInt memory spotPrice = FixedPointInt256.fromScaledUint(_spotPrice, BASE);

        return
            _getDebtPrice(vaultCollateral, vaultDebt, cv, spotPrice, _auctionStartingTime, _collateralDecimals, _isPut);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import "../libs/FixedPointInt256.sol";

/**
 * @author Opyn Team
 * @notice FixedPointInt256 contract tester
 */
contract FixedPointInt256Tester {
    using FixedPointInt256 for FixedPointInt256.FixedPointInt;

    function testFromUnscaledInt(int256 a) external pure returns (FixedPointInt256.FixedPointInt memory) {
        return FixedPointInt256.fromUnscaledInt(a);
    }

    function testAdd(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return a.add(b);
    }

    function testSub(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return a.sub(b);
    }

    function testMul(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return a.mul(b);
    }

    function testDiv(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return a.div(b);
    }

    function testMin(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return FixedPointInt256.min(a, b);
    }

    function testMax(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (FixedPointInt256.FixedPointInt memory)
    {
        return FixedPointInt256.max(a, b);
    }

    function testIsEqual(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (bool)
    {
        return a.isEqual(b);
    }

    function testIsGreaterThan(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (bool)
    {
        return a.isGreaterThan(b);
    }

    function testIsGreaterThanOrEqual(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (bool)
    {
        return a.isGreaterThanOrEqual(b);
    }

    function testIsLessThan(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (bool)
    {
        return a.isLessThan(b);
    }

    function testIsLessThanOrEqual(FixedPointInt256.FixedPointInt memory a, FixedPointInt256.FixedPointInt memory b)
        external
        pure
        returns (bool)
    {
        return a.isLessThanOrEqual(b);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import "../libs/SignedConverter.sol";

/**
 * @author Opyn Team
 * @notice SignedConverter contract tester
 */
contract SignedConverterTester {
    using SignedConverter for int256;
    using SignedConverter for uint256;

    function testFromInt(int256 a) external pure returns (uint256) {
        return SignedConverter.intToUint(a);
    }

    function testFromUint(uint256 a) external pure returns (int256) {
        return SignedConverter.uintToInt(a);
    }
}

pragma solidity =0.6.10;

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;

import {MarginVault} from "../libs/MarginVault.sol";

contract MarginVaultTester {
    using MarginVault for MarginVault.Vault;

    mapping(address => mapping(uint256 => MarginVault.Vault)) private vault;

    function getVault(uint256 _vaultIndex) external view returns (MarginVault.Vault memory) {
        return vault[msg.sender][_vaultIndex];
    }

    function testAddShort(
        uint256 _vaultIndex,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].addShort(_shortOtoken, _amount, _index);
    }

    function testRemoveShort(
        uint256 _vaultIndex,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].removeShort(_shortOtoken, _amount, _index);
    }

    function testAddLong(
        uint256 _vaultIndex,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].addLong(_longOtoken, _amount, _index);
    }

    function testRemoveLong(
        uint256 _vaultIndex,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].removeLong(_longOtoken, _amount, _index);
    }

    function testAddCollateral(
        uint256 _vaultIndex,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].addCollateral(_collateralAsset, _amount, _index);
    }

    function testRemoveCollateral(
        uint256 _vaultIndex,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        vault[msg.sender][_vaultIndex].removeCollateral(_collateralAsset, _amount, _index);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {Actions} from "../libs/Actions.sol";

contract ActionTester {
    Actions.OpenVaultArgs private openVaultArgs;
    Actions.DepositArgs private depositArgs;
    Actions.WithdrawArgs private withdrawArgs;
    Actions.MintArgs private mintArgs;
    Actions.BurnArgs private burnArgs;
    Actions.RedeemArgs private redeemArgs;
    Actions.SettleVaultArgs private settleVaultArgs;
    Actions.CallArgs private callArgs;
    Actions.LiquidateArgs private liquidateArgs;

    function testParseDespositAction(Actions.ActionArgs memory _args) external {
        depositArgs = Actions._parseDepositArgs(_args);
    }

    function getDepositArgs() external view returns (Actions.DepositArgs memory) {
        return depositArgs;
    }

    function testParseWithdrawAction(Actions.ActionArgs memory _args) external {
        withdrawArgs = Actions._parseWithdrawArgs(_args);
    }

    function getWithdrawArgs() external view returns (Actions.WithdrawArgs memory) {
        return withdrawArgs;
    }

    function testParseOpenVaultAction(Actions.ActionArgs memory _args) external {
        openVaultArgs = Actions._parseOpenVaultArgs(_args);
    }

    function getOpenVaultArgs() external view returns (Actions.OpenVaultArgs memory) {
        return openVaultArgs;
    }

    function testParseRedeemAction(Actions.ActionArgs memory _args) external {
        redeemArgs = Actions._parseRedeemArgs(_args);
    }

    function getRedeemArgs() external view returns (Actions.RedeemArgs memory) {
        return redeemArgs;
    }

    function testParseSettleVaultAction(Actions.ActionArgs memory _args) external {
        settleVaultArgs = Actions._parseSettleVaultArgs(_args);
    }

    function testParseLiquidateActions(Actions.ActionArgs memory _args) external {
        liquidateArgs = Actions._parseLiquidateArgs(_args);
    }

    function getSettleVaultArgs() external view returns (Actions.SettleVaultArgs memory) {
        return settleVaultArgs;
    }

    function testParseMintAction(Actions.ActionArgs memory _args) external {
        mintArgs = Actions._parseMintArgs(_args);
    }

    function getMintArgs() external view returns (Actions.MintArgs memory) {
        return mintArgs;
    }

    function testParseBurnAction(Actions.ActionArgs memory _args) external {
        burnArgs = Actions._parseBurnArgs(_args);
    }

    function getBurnArgs() external view returns (Actions.BurnArgs memory) {
        return burnArgs;
    }

    function testParseCallAction(Actions.ActionArgs memory _args) external {
        callArgs = Actions._parseCallArgs(_args);
    }

    function getCallArgs() external view returns (Actions.CallArgs memory) {
        return callArgs;
    }

    function getLiquidateArgs() external view returns (Actions.LiquidateArgs memory) {
        return liquidateArgs;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {CalleeInterface} from "../../interfaces/CalleeInterface.sol";
import {IERC20PermitUpgradeable} from "../../packages/oz/upgradeability/erc20-permit/IERC20PermitUpgradeable.sol";

/**
 * @title PermitCallee
 * @author Opyn Team
 * @dev Contract for executing permit signature
 */
contract PermitCallee is CalleeInterface {
    function callFunction(address payable _sender, bytes memory _data) external override {
        (
            address token,
            address owner,
            address spender,
            uint256 amount,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(_data, (address, address, address, uint256, uint256, uint8, bytes32, bytes32));

        IERC20PermitUpgradeable(token).permit(owner, spender, amount, deadline, v, r, s);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {ZeroXExchangeInterface} from "../interfaces/ZeroXExchangeInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeERC20} from "../packages/oz/SafeERC20.sol";
import {Mock0xERC20Proxy} from "./Mock0xERC20Proxy.sol";

/**
 * @notice Mock 0x Exchange
 */
contract Mock0xExchange {
    using SafeERC20 for ERC20Interface;
    uint256 public called = 0;
    uint256 public takerAmount;
    uint256 public makerAmount;
    bytes public signature;
    uint256 public fillAmount;
    Mock0xERC20Proxy public proxy;

    constructor() public {
        proxy = new Mock0xERC20Proxy(); //TODO: what is this? do we need it?
    }

    function fillLimitOrder(
        ZeroXExchangeInterface.LimitOrder memory _order,
        ZeroXExchangeInterface.Signature memory _signature,
        uint128 _takerTokenFillAmount
    ) public payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        return (0, 0);
    }

    function batchFillLimitOrders(
        ZeroXExchangeInterface.LimitOrder[] memory _orders,
        ZeroXExchangeInterface.Signature[] memory _signatures,
        uint128[] memory _takerTokenFillAmounts,
        bool _revertIfIncomplete
    ) external payable returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts) {
        for (uint256 i = 0; i < _orders.length; i++) {
            (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) = fillLimitOrder(
                _orders[i],
                _signatures[i],
                _takerTokenFillAmounts[i]
            );
        }
        return (takerTokenFilledAmounts, makerTokenFilledAmounts);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

/**
 * @dev ZeroX Exchange contract interface.
 */
interface ZeroXExchangeInterface {
    // solhint-disable max-line-length
    /// @dev Canonical order structure
    struct LimitOrder {
        address makerToken; // The ERC20 token the maker is selling and the maker is selling to the taker.
        address takerToken; // The ERC20 token the taker is selling and the taker is selling to the maker.
        uint128 makerAmount; // The amount of makerToken being sold by the maker.
        uint128 takerAmount; // The amount of takerToken being sold by the taker.
        uint128 takerTokenFeeAmount; // Amount of takerToken paid by the taker to the feeRecipient.
        address maker; // The address of the maker, and signer, of this order.
        address taker; // Allowed taker address. Set to zero to allow any taker.
        address sender; // Allowed address to call fillLimitOrder() (msg.sender). This is the same as taker, expect when using meta-transactions. Set to zero to allow any caller.
        address feeRecipient; // Recipient of maker token or taker token fees (if non-zero).
        bytes32 pool; // The staking pool to attribute the 0x protocol fee from this order. Set to zero to attribute to the default pool, not owned by anyone.
        uint64 expiry; // The Unix timestamp in seconds when this order expires.
        uint256 salt; // Arbitrary number to facilitate uniqueness of the order's hash.
    }

    struct Signature {
        uint8 signatureType; // Either 2 (EIP712) or 3 (EthSign)
        uint8 v; // Signature data.
        bytes32 r; // Signature data.
        bytes32 s; // Signature data.
    }

    /// @dev Executes multiple calls of fillLimitOrder.
    /// @param orders Array of order specifications.
    /// @param takerTokenFillAmounts Array of desired amounts of takerToken to sell in orders.
    /// @param signatures Array of proofs that orders have been created by makers.
    /// @return takerTokenFilledAmounts Array of amount of takerToken(s) filled.
    /// @return makerTokenFilledAmounts Array of amount of makerToken(s) filled.
    function batchFillLimitOrders(
        LimitOrder[] memory orders,
        Signature[] memory signatures,
        uint128[] memory takerTokenFillAmounts,
        bool revertIfIncomplete
    ) external payable returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts);
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {SafeERC20} from "../packages/oz/SafeERC20.sol";

/**
 * @notice Mock 0x ERC20 Proxy

 */
contract Mock0xERC20Proxy {
    using SafeERC20 for ERC20Interface;

    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        ERC20Interface(token).safeTransferFrom(from, to, amount);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {SafeERC20} from "../packages/oz/SafeERC20.sol";
import {Ownable} from "../packages/oz/Ownable.sol";

/**
 * @author Opyn Team
 * @title MarginPool
 * @notice Contract that holds all protocol funds
 */
contract MarginPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Interface;

    /// @notice AddressBook module
    address public addressBook;
    /// @dev the address that has the ability to withdraw excess assets in the pool
    address public farmer;
    /// @dev mapping between an asset and the amount of the asset in the pool
    mapping(address => uint256) internal assetBalance;

    /**
     * @notice contructor
     * @param _addressBook AddressBook module
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event when marginpool receive funds from controller
    event TransferToPool(address indexed asset, address indexed user, uint256 amount);
    /// @notice emits an event when marginpool transfer funds to controller
    event TransferToUser(address indexed asset, address indexed user, uint256 amount);
    /// @notice emit event after updating the farmer address
    event FarmerUpdated(address indexed oldAddress, address indexed newAddress);
    /// @notice emit event when an asset gets harvested from the pool
    event AssetFarmed(address indexed asset, address indexed receiver, uint256 amount);

    /**
     * @notice check if the sender is the Controller module
     */
    modifier onlyController() {
        require(
            msg.sender == AddressBookInterface(addressBook).getController(),
            "MarginPool: Sender is not Controller"
        );

        _;
    }

    /**
     * @notice check if the sender is the farmer address
     */
    modifier onlyFarmer() {
        require(msg.sender == farmer, "MarginPool: Sender is not farmer");

        _;
    }

    /**
     * @notice transfers an asset from a user to the pool
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets from
     * @param _amount amount of the token to transfer from _user
     */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) public onlyController {
        require(_amount > 0, "MarginPool: transferToPool amount is equal to 0");
        assetBalance[_asset] = assetBalance[_asset].add(_amount);

        // transfer _asset _amount from _user to pool
        ERC20Interface(_asset).safeTransferFrom(_user, address(this), _amount);
        emit TransferToPool(_asset, _user, _amount);
    }

    /**
     * @notice transfers an asset from the pool to a user
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets to
     * @param _amount amount of the token to transfer to _user
     */
    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) public onlyController {
        require(_user != address(this), "MarginPool: cannot transfer assets to oneself");
        assetBalance[_asset] = assetBalance[_asset].sub(_amount);

        // transfer _asset _amount from pool to _user
        ERC20Interface(_asset).safeTransfer(_user, _amount);
        emit TransferToUser(_asset, _user, _amount);
    }

    /**
     * @notice get the stored balance of an asset
     * @param _asset asset address
     * @return asset balance
     */
    function getStoredBalance(address _asset) external view returns (uint256) {
        return assetBalance[_asset];
    }

    /**
     * @notice transfers multiple assets from users to the pool
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to pool
     */
    function batchTransferToPool(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external onlyController {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToPool array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from _user to pool
            transferToPool(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice transfers multiple assets from the pool to users
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to _user
     */
    function batchTransferToUser(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external onlyController {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToUser array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from pool to _user
            transferToUser(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice function to collect the excess balance of a particular asset
     * @dev can only be called by the farmer address. Do not farm otokens.
     * @param _asset asset address
     * @param _receiver receiver address
     * @param _amount amount to remove from pool
     */
    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external onlyFarmer {
        require(_receiver != address(0), "MarginPool: invalid receiver address");

        uint256 externalBalance = ERC20Interface(_asset).balanceOf(address(this));
        uint256 storedBalance = assetBalance[_asset];

        require(_amount <= externalBalance.sub(storedBalance), "MarginPool: amount to farm exceeds limit");

        ERC20Interface(_asset).safeTransfer(_receiver, _amount);

        emit AssetFarmed(_asset, _receiver, _amount);
    }

    /**
     * @notice function to set farmer address
     * @dev can only be called by MarginPool owner
     * @param _farmer farmer address
     */
    function setFarmer(address _farmer) external onlyOwner {
        emit FarmerUpdated(farmer, _farmer);

        farmer = _farmer;
    }
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity ^0.6.0;

import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * ERC20 Token that return false when operation failed
 */
contract MockDumbERC20 {
    using SafeMath for uint256;

    bool internal _locked;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        if (_locked) return false;
        if (_balances[msg.sender] < amount) {
            return false;
        }
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        if (_locked) return false;
        if (_balances[sender] < amount) {
            return false;
        }
        if (_allowances[sender][msg.sender] < amount) {
            return false;
        }
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function mint(address recipient, uint256 amount) public {
        _balances[recipient] = _balances[recipient].add(amount);
    }

    function burn(address recipient, uint256 amount) public {
        _balances[recipient] = _balances[recipient].sub(amount);
    }

    function setLocked(bool locked_) public {
        _locked = locked_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";

contract MockCToken is ERC20Upgradeable {
    uint256 public exchangeRateStored;

    constructor(string memory _name, string memory _symbol) public {
        __ERC20_init_unchained(_name, _symbol);
        _setupDecimals(8);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function setExchangeRate(uint256 _exchangeRateStored) external {
        exchangeRateStored = _exchangeRateStored;
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity =0.6.10;

import {ERC20Upgradeable} from "../packages/oz/upgradeability/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "../packages/oz/upgradeability/erc20-permit/ERC20PermitUpgradeable.sol";
import {Strings} from "../packages/oz/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "../packages/BokkyPooBahsDateTimeLibrary.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * @title Otoken
 * @author Opyn Team
 * @notice Otoken is the ERC20 token for an option
 * @dev The Otoken inherits ERC20Upgradeable because we need to use the init instead of constructor
 */
contract Otoken is ERC20PermitUpgradeable {
    /// @notice address of the Controller module
    address public controller;

    /// @notice asset that the option references
    address public underlyingAsset;

    /// @notice asset that the strike price is denominated in
    address public strikeAsset;

    /// @notice asset that is held as collateral against short/written options
    address public collateralAsset;

    /// @notice strike price with decimals = 8
    uint256 public strikePrice;

    /// @notice expiration timestamp of the option, represented as a unix timestamp
    uint256 public expiryTimestamp;

    /// @notice True if a put option, False if a call option
    bool public isPut;

    uint256 private constant STRIKE_PRICE_SCALE = 1e8;
    uint256 private constant STRIKE_PRICE_DIGITS = 8;

    /**
     * @notice initialize the oToken
     * @param _addressBook addressbook module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 8
     * @param _expiryTimestamp expiration timestamp of the option, represented as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     */
    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external initializer {
        controller = AddressBookInterface(_addressBook).getController();
        underlyingAsset = _underlyingAsset;
        strikeAsset = _strikeAsset;
        collateralAsset = _collateralAsset;
        strikePrice = _strikePrice;
        expiryTimestamp = _expiryTimestamp;
        isPut = _isPut;
        (string memory tokenName, string memory tokenSymbol) = _getNameAndSymbol();
        __ERC20_init_unchained(tokenName, tokenSymbol);
        __ERC20Permit_init(tokenName);
        _setupDecimals(8);
    }

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        return (collateralAsset, underlyingAsset, strikeAsset, strikePrice, expiryTimestamp, isPut);
    }

    /**
     * @notice mint oToken for an account
     * @dev Controller only method where access control is taken care of by _beforeTokenTransfer hook
     * @param account account to mint token to
     * @param amount amount to mint
     */
    function mintOtoken(address account, uint256 amount) external {
        require(msg.sender == controller, "Otoken: Only Controller can mint Otokens");
        _mint(account, amount);
    }

    /**
     * @notice burn oToken from an account.
     * @dev Controller only method where access control is taken care of by _beforeTokenTransfer hook
     * @param account account to burn token from
     * @param amount amount to burn
     */
    function burnOtoken(address account, uint256 amount) external {
        require(msg.sender == controller, "Otoken: Only Controller can burn Otokens");
        _burn(account, amount);
    }

    /**
     * @notice generates the name and symbol for an option
     * @dev this function uses a named return variable to avoid the stack-too-deep error
     * @return tokenName (ex: ETHUSDC 05-September-2020 200 Put USDC Collateral)
     * @return tokenSymbol (ex: oETHUSDC-05SEP20-200P)
     */
    function _getNameAndSymbol() internal view returns (string memory tokenName, string memory tokenSymbol) {
        string memory underlying = ERC20Upgradeable(underlyingAsset).symbol();
        string memory strike = ERC20Upgradeable(strikeAsset).symbol();
        string memory collateral = ERC20Upgradeable(collateralAsset).symbol();
        string memory displayStrikePrice = _getDisplayedStrikePrice(strikePrice);

        // convert expiry to a readable string
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(expiryTimestamp);

        // get option type string
        (string memory typeSymbol, string memory typeFull) = _getOptionType(isPut);

        //get option month string
        (string memory monthSymbol, string memory monthFull) = _getMonth(month);

        // concatenated name string: ETHUSDC 05-September-2020 200 Put USDC Collateral
        tokenName = string(
            abi.encodePacked(
                underlying,
                strike,
                " ",
                _uintTo2Chars(day),
                "-",
                monthFull,
                "-",
                Strings.toString(year),
                " ",
                displayStrikePrice,
                typeFull,
                " ",
                collateral,
                " Collateral"
            )
        );

        // concatenated symbol string: oETHUSDC/USDC-05SEP20-200P
        tokenSymbol = string(
            abi.encodePacked(
                "o",
                underlying,
                strike,
                "/",
                collateral,
                "-",
                _uintTo2Chars(day),
                monthSymbol,
                _uintTo2Chars(year),
                "-",
                displayStrikePrice,
                typeSymbol
            )
        );
    }

    /**
     * @dev convert strike price scaled by 1e8 to human readable number string
     * @param _strikePrice strike price scaled by 1e8
     * @return strike price string
     */
    function _getDisplayedStrikePrice(uint256 _strikePrice) internal pure returns (string memory) {
        uint256 remainder = _strikePrice.mod(STRIKE_PRICE_SCALE);
        uint256 quotient = _strikePrice.div(STRIKE_PRICE_SCALE);
        string memory quotientStr = Strings.toString(quotient);

        if (remainder == 0) return quotientStr;

        uint256 trailingZeroes;
        while (remainder.mod(10) == 0) {
            remainder = remainder / 10;
            trailingZeroes += 1;
        }

        // pad the number with "1 + starting zeroes"
        remainder += 10**(STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory tmpStr = Strings.toString(remainder);
        tmpStr = _slice(tmpStr, 1, 1 + STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory completeStr = string(abi.encodePacked(quotientStr, ".", tmpStr));
        return completeStr;
    }

    /**
     * @dev return a representation of a number using 2 characters, adds a leading 0 if one digit, uses two trailing digits if a 3 digit number
     * @return 2 characters that corresponds to a number
     */
    function _uintTo2Chars(uint256 number) internal pure returns (string memory) {
        if (number > 99) number = number % 100;
        string memory str = Strings.toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /**
     * @dev return string representation of option type
     * @return shortString a 1 character representation of option type (P or C)
     * @return longString a full length string of option type (Put or Call)
     */
    function _getOptionType(bool _isPut) internal pure returns (string memory shortString, string memory longString) {
        if (_isPut) {
            return ("P", "Put");
        } else {
            return ("C", "Call");
        }
    }

    /**
     * @dev cut string s into s[start:end]
     * @param _s the string to cut
     * @param _start the starting index
     * @param _end the ending index (excluded in the substring)
     */
    function _slice(
        string memory _s,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            a[i] = bytes(_s)[_start + i];
        }
        return string(a);
    }

    /**
     * @dev return string representation of a month
     * @return shortString a 3 character representation of a month (ex: SEP, DEC, etc)
     * @return longString a full length string of a month (ex: September, December, etc)
     */
    function _getMonth(uint256 _month) internal pure returns (string memory shortString, string memory longString) {
        if (_month == 1) {
            return ("JAN", "January");
        } else if (_month == 2) {
            return ("FEB", "February");
        } else if (_month == 3) {
            return ("MAR", "March");
        } else if (_month == 4) {
            return ("APR", "April");
        } else if (_month == 5) {
            return ("MAY", "May");
        } else if (_month == 6) {
            return ("JUN", "June");
        } else if (_month == 7) {
            return ("JUL", "July");
        } else if (_month == 8) {
            return ("AUG", "August");
        } else if (_month == 9) {
            return ("SEP", "September");
        } else if (_month == 10) {
            return ("OCT", "October");
        } else if (_month == 11) {
            return ("NOV", "November");
        } else {
            return ("DEC", "December");
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity =0.6.10;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.6.0;

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

// version v1.01
library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

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
}