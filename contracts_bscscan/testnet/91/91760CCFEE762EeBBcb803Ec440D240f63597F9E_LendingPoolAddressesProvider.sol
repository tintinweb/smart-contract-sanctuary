pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../libraries/openzeppelin-upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "./AddressStorage.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

/**
* LendingPoolAddressesProvider contract
* -
* Is the main registry of the protocol. All the different components of the protocol are accessible
* through the addresses provider.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

/**


 */

contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider, AddressStorage {
    //events
    event LendingPoolUpdated(address indexed newAddress);
    event LendingPoolCoreUpdated(address indexed newAddress);
    event LendingPoolParametersProviderUpdated(address indexed newAddress);
    event LendingPoolManagerUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolLiquidationManagerUpdated(address indexed newAddress);
    event LendingPoolDataProviderUpdated(address indexed newAddress);
    event EthereumAddressUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event FeeProviderUpdated(address indexed newAddress);
    event TokenDistributorUpdated(address indexed newAddress);

    event ProxyCreated(bytes32 id, address indexed newAddress);

    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant LENDING_POOL_CORE = "LENDING_POOL_CORE";
    bytes32 private constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant LENDING_POOL_PARAMETERS_PROVIDER = "PARAMETERS_PROVIDER";
    bytes32 private constant LENDING_POOL_MANAGER = "LENDING_POOL_MANAGER";
    bytes32 private constant LENDING_POOL_LIQUIDATION_MANAGER = "LIQUIDATION_MANAGER";
    bytes32 private constant LENDING_POOL_FLASHLOAN_PROVIDER = "FLASHLOAN_PROVIDER";
    bytes32 private constant DATA_PROVIDER = "DATA_PROVIDER";
    bytes32 private constant ETHEREUM_ADDRESS = "ETHEREUM_ADDRESS";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";
    bytes32 private constant FEE_PROVIDER = "FEE_PROVIDER";
    bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";
    bytes32 private constant TOKEN_DISTRIBUTOR = "TOKEN_DISTRIBUTOR";


    /**
    * @dev returns the address of the LendingPool proxy
    * @return the lending pool proxy address
    **/
    function getLendingPool() public view returns (address) {
        return getAddress(LENDING_POOL);
    }


    /**
    * @dev updates the implementation of the lending pool
    * @param _pool the new lending pool implementation
    **/
    function setLendingPoolImpl(address _pool) public onlyOwner {
        updateImplInternal(LENDING_POOL, _pool);
        emit LendingPoolUpdated(_pool);
    }

    /**
    * @dev returns the address of the LendingPoolCore proxy
    * @return the lending pool core proxy address
     */
    function getLendingPoolCore() public view returns (address payable) {
        address payable core = address(uint160(getAddress(LENDING_POOL_CORE)));
        return core;
    }

    /**
    * @dev updates the implementation of the lending pool core
    * @param _lendingPoolCore the new lending pool core implementation
    **/
    function setLendingPoolCoreImpl(address _lendingPoolCore) public onlyOwner {
        updateImplInternal(LENDING_POOL_CORE, _lendingPoolCore);
        emit LendingPoolCoreUpdated(_lendingPoolCore);
    }

    /**
    * @dev returns the address of the LendingPoolConfigurator proxy
    * @return the lending pool configurator proxy address
    **/
    function getLendingPoolConfigurator() public view returns (address) {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    /**
    * @dev updates the implementation of the lending pool configurator
    * @param _configurator the new lending pool configurator implementation
    **/
    function setLendingPoolConfiguratorImpl(address _configurator) public onlyOwner {
        updateImplInternal(LENDING_POOL_CONFIGURATOR, _configurator);
        emit LendingPoolConfiguratorUpdated(_configurator);
    }

    /**
    * @dev returns the address of the LendingPoolDataProvider proxy
    * @return the lending pool data provider proxy address
     */
    function getLendingPoolDataProvider() public view returns (address) {
        return getAddress(DATA_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool data provider
    * @param _provider the new lending pool data provider implementation
    **/
    function setLendingPoolDataProviderImpl(address _provider) public onlyOwner {
        updateImplInternal(DATA_PROVIDER, _provider);
        emit LendingPoolDataProviderUpdated(_provider);
    }

    /**
    * @dev returns the address of the LendingPoolParametersProvider proxy
    * @return the address of the Lending pool parameters provider proxy
    **/
    function getLendingPoolParametersProvider() public view returns (address) {
        return getAddress(LENDING_POOL_PARAMETERS_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool parameters provider
    * @param _parametersProvider the new lending pool parameters provider implementation
    **/
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public onlyOwner {
        updateImplInternal(LENDING_POOL_PARAMETERS_PROVIDER, _parametersProvider);
        emit LendingPoolParametersProviderUpdated(_parametersProvider);
    }

    /**
    * @dev returns the address of the FeeProvider proxy
    * @return the address of the Fee provider proxy
    **/
    function getFeeProvider() public view returns (address) {
        return getAddress(FEE_PROVIDER);
    }

    /**
    * @dev updates the implementation of the FeeProvider proxy
    * @param _feeProvider the new lending pool fee provider implementation
    **/
    function setFeeProviderImpl(address _feeProvider) public onlyOwner {
        updateImplInternal(FEE_PROVIDER, _feeProvider);
        emit FeeProviderUpdated(_feeProvider);
    }

    /**
    * @dev returns the address of the LendingPoolLiquidationManager. Since the manager is used
    * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
    * the addresses are changed directly.
    * @return the address of the Lending pool liquidation manager
    **/

    function getLendingPoolLiquidationManager() public view returns (address) {
        return getAddress(LENDING_POOL_LIQUIDATION_MANAGER);
    }

    /**
    * @dev updates the address of the Lending pool liquidation manager
    * @param _manager the new lending pool liquidation manager address
    **/
    function setLendingPoolLiquidationManager(address _manager) public onlyOwner {
        _setAddress(LENDING_POOL_LIQUIDATION_MANAGER, _manager);
        emit LendingPoolLiquidationManagerUpdated(_manager);
    }

    /**
    * @dev the functions below are storing specific addresses that are outside the context of the protocol
    * hence the upgradable proxy pattern is not used
    **/


    function getLendingPoolManager() public view returns (address) {
        return getAddress(LENDING_POOL_MANAGER);
    }

    function setLendingPoolManager(address _lendingPoolManager) public onlyOwner {
        _setAddress(LENDING_POOL_MANAGER, _lendingPoolManager);
        emit LendingPoolManagerUpdated(_lendingPoolManager);
    }

    function getPriceOracle() public view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address _priceOracle) public onlyOwner {
        _setAddress(PRICE_ORACLE, _priceOracle);
        emit PriceOracleUpdated(_priceOracle);
    }

    function getLendingRateOracle() public view returns (address) {
        return getAddress(LENDING_RATE_ORACLE);
    }

    function setLendingRateOracle(address _lendingRateOracle) public onlyOwner {
        _setAddress(LENDING_RATE_ORACLE, _lendingRateOracle);
        emit LendingRateOracleUpdated(_lendingRateOracle);
    }


    function getTokenDistributor() public view returns (address) {
        return getAddress(TOKEN_DISTRIBUTOR);
    }

    function setTokenDistributor(address _tokenDistributor) public onlyOwner {
        _setAddress(TOKEN_DISTRIBUTOR, _tokenDistributor);
        emit TokenDistributorUpdated(_tokenDistributor);
    }


    /**
    * @dev internal function to update the implementation of a specific component of the protocol
    * @param _id the id of the contract to be updated
    * @param _newAddress the address of the new implementation
    **/
    function updateImplInternal(bytes32 _id, address _newAddress) internal {
        address payable proxyAddress = address(uint160(getAddress(_id)));

        InitializableAdminUpgradeabilityProxy proxy = InitializableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableAdminUpgradeabilityProxy();
            proxy.initialize(_newAddress, address(this), params);
            _setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
        } else {
            proxy.upgradeToAndCall(_newAddress, params);
        }

    }
}

pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    constructor(address _logic, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
    /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
    function() external payable {
        _fallback();
    }

    /**
   * @return The Address of the implementation.
   */
    function _implementation() internal view returns (address);

    /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }

    /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
    function _willFallback() internal {}

    /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

pragma solidity ^0.5.0;

import "./BaseAdminUpgradeabilityProxy.sol";
import "./InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
    /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, address _admin, bytes memory _data) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(_logic, _data);
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }
}

pragma solidity ^0.5.0;

import "./Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
    event Upgraded(address indexed implementation);

    /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

pragma solidity ^0.5.0;

import "./UpgradeabilityProxy.sol";

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
   * @return The address of the proxy admin.
   */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
   * @return The address of the implementation.
   */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
   * @return The admin slot.
   */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            adm := sload(slot)
        }
    }

    /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
   * @dev Only fall back when the sender is not the admin.
   */
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}

pragma solidity ^0.5.0;

/**
* ILendingPoolAddressesProvider interface
* -
* Provides the interface to fetch the LendingPoolCore address
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

contract ILendingPoolAddressesProvider {

    function getLendingPool() public view returns (address);
    function setLendingPoolImpl(address _pool) public;

    function getLendingPoolCore() public view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public;

    function getLendingPoolConfigurator() public view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public;

    function getLendingPoolDataProvider() public view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public;

    function getLendingPoolParametersProvider() public view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public;

    function getTokenDistributor() public view returns (address);
    function setTokenDistributor(address _tokenDistributor) public;


    function getFeeProvider() public view returns (address);
    function setFeeProviderImpl(address _feeProvider) public;

    function getLendingPoolLiquidationManager() public view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public;

    function getLendingPoolManager() public view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public;

    function getPriceOracle() public view returns (address);
    function setPriceOracle(address _priceOracle) public;

    function getLendingRateOracle() public view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public;

}

pragma solidity ^0.5.0;

contract AddressStorage {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
    }

}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}