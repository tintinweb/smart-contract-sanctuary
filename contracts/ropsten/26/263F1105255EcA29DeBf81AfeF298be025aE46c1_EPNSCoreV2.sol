// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

contract EPNSAdmin is ProxyAdmin {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract EPNSBravoProxy is TransparentUpgradeableProxy {

    constructor(
        address _logic,
        address _admin,
        address _timelock,
        address _push,
        uint _votingPeriod,
        uint _votingDelay,
        uint _proposalThreshold
    ) public payable TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature('initialize(address,address,address,uint,uint,uint)', _admin, _timelock, _push, _votingPeriod, _votingDelay, _proposalThreshold)) {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract EPNSCoreProxy is TransparentUpgradeableProxy {


    constructor(
        address _logic,
        address _governance,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint _referralCode
    ) public payable TransparentUpgradeableProxy(_logic, _governance, abi.encodeWithSignature('initialize(address,address,address,address,address,address,address,uint256)', _governance, _pushTokenAddress, _wethAddress, _uniswapRouterAddress, _lendingPoolProviderAddress, _daiAddress, _aDaiAddress,_referralCode)) {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract EPNSCommProxy is TransparentUpgradeableProxy {


    constructor(
        address _logic,
        address _admin
    ) public payable TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature('initialize(address)', _admin)) {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

/**
 * EPNS Core is the main protocol that deals with the imperative
 * features and functionalities like Channel Creation, pushChannelAdmin etc.
 *
 * This protocol will be specifically deployed on Ethereum Blockchain while the Communicator
 * protocols can be deployed on Multiple Chains.
 * The EPNS Core is more inclined towards the storing and handling the Channel related
 * Functionalties.
 **/

import "./interfaces/IPUSH.sol";
import "./interfaces/IADai.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IEPNSCommV1.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "hardhat/console.sol";

contract EPNSCoreV2 is Initializable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ***************

      DEFINE ENUMS AND CONSTANTS

     *************** */

    // For Message Type
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual
    }
    enum ChannelAction {
        ChannelRemoved,
        ChannelAdded,
        ChannelUpdated
    }

    /**
     * @notice Channel Struct that includes imperative details about a specific Channel.
    **/
    struct Channel {
        // @notice Denotes the Channel Type
        ChannelType channelType;

        /** @notice Symbolizes Channel's State:
         * 0 -> INACTIVE,
         * 1 -> ACTIVATED
         * 2 -> DeActivated By Channel Owner,
         * 3 -> BLOCKED by pushChannelAdmin/Governance
        **/
        uint8 channelState;

        /** @notice Symbolizes Channel's Verification Status:
         *   0 -> UnVerified Channels,
         *   1 -> Verified by pushChannelAdmin,
         *   2 -> Verified by other Channel Owners
        **/
        address verifiedBy;

        // @notice Total Amount of Dai deposited during Channel Creation
        uint256 poolContribution;

        // @notice Represents the Historical Constant
        uint256 channelHistoricalZ;

        // @notice Represents the FS Count
        uint256 channelFairShareCount;

        // @notice The last update block number, used to calculate fair share
        uint256 channelLastUpdate;

        // @notice Helps in defining when channel started for pool and profit calculation
        uint256 channelStartBlock;

        // @notice Helps in outlining when channel was updated
        uint256 channelUpdateBlock;

        // @notice The individual weight to be applied as per pool contribution
        uint256 channelWeight;
    }

    /* ***************
        MAPPINGS
     *************** */

    mapping(address => Channel) public channels;
    mapping(uint256 => address) public mapAddressChannels;
    mapping(address => string) public channelNotifSettings;
    mapping(address => uint256) public usersInterestClaimed;


    /* ***************
        STATE VARIABLES
     *************** */
    string public constant name = "EPNS CORE V1";
    bool oneTimeCheck;
    bool public isMigrationComplete;

    address public pushChannelAdmin;
    address public governance;
    address public daiAddress;
    address public aDaiAddress;
    address public WETH_ADDRESS;
    address public epnsCommunicator;
    address public UNISWAP_V2_ROUTER;
    address public PUSH_TOKEN_ADDRESS;
    address public lendingPoolProviderAddress;

    uint256 public REFERRAL_CODE;
    uint256 ADJUST_FOR_FLOAT;
    uint256 public channelsCount;

    //  @notice Helper Variables for FSRatio Calculation | GROUPS = CHANNELS
    uint256 public groupNormalizedWeight;
    uint256 public groupHistoricalZ;
    uint256 public groupLastUpdate;
    uint256 public groupFairShareCount;

    // @notice Necessary variables for Keeping track of Funds and Fees
    uint256 public POOL_FUNDS;
    uint256 public PROTOCOL_POOL_FEES;
    uint256 public ADD_CHANNEL_MIN_FEES;
    uint256 public CHANNEL_DEACTIVATION_FEES;
    uint256 public ADD_CHANNEL_MIN_POOL_CONTRIBUTION;

    /* ***************
        EVENTS
     *************** */
    event UpdateChannel(address indexed channel, bytes identity);
    event Withdrawal(address indexed to, address token, uint256 amount);
    event InterestClaimed(address indexed user, uint256 indexed interestAmount);

    event ChannelVerified(address indexed channel, address indexed verifier);
    event ChannelVerificationRevoked(address indexed channel, address indexed revoker);

    event DeactivateChannel(
        address indexed channel,
        uint256 indexed amountRefunded
    );
    event ReactivateChannel(
        address indexed channel,
        uint256 indexed amountDeposited
    );
    event ChannelBlocked(
        address indexed channel
    );
    event AddChannel(
        address indexed channel,
        ChannelType indexed channelType,
        bytes identity
    );
    event ChannelNotifcationSettingsAdded(
        address _channel,
        uint256 totalNotifOptions,
        string _notifSettings,
        string _notifDescription
    );

    /* **************
        MODIFIERS
    ***************/
    modifier onlyPushChannelAdmin() {
        require(msg.sender == pushChannelAdmin, "EPNSCoreV1::onlyPushChannelAdmin: Caller not pushChannelAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == pushChannelAdmin, "EPNSCoreV1::onlyGovernance: Caller not Governance");
        _;
    }

    modifier onlyInactiveChannels(address _channel) {
        require(
            channels[_channel].channelState == 0,
            "EPNSCoreV1::onlyInactiveChannels: Channel already Activated"
        );
        _;
    }
    modifier onlyActivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 1,
            "EPNSCoreV1::onlyActivatedChannels: Channel Deactivated, Blocked or Does Not Exist"
        );
        _;
    }

    modifier onlyDeactivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 2,
            "EPNSCoreV1::onlyDeactivatedChannels: Channel is not Deactivated Yet"
        );
        _;
    }

    modifier onlyUnblockedChannels(address _channel) {
        require(
            ((channels[_channel].channelState != 3) &&
              (channels[_channel].channelState != 0)),
            "EPNSCoreV1::onlyUnblockedChannels: Channel is BLOCKED Already or Not Activated Yet"
        );
        _;
    }

    modifier onlyChannelOwner(address _channel) {
        require(
            ((channels[_channel].channelState == 1 && msg.sender == _channel) ||
                (msg.sender == pushChannelAdmin &&
                    _channel == address(0x0))),
            "EPNSCoreV1::onlyChannelOwner: Channel not Exists or Invalid Channel Owner"
        );
        _;
    }

    modifier onlyUserAllowedChannelType(ChannelType _channelType) {
        require(
            (_channelType == ChannelType.InterestBearingOpen ||
                _channelType == ChannelType.InterestBearingMutual),
            "EPNSCoreV1::onlyUserAllowedChannelType: Channel Type Invalid"
        );

        _;
    }

    /* ***************
        INITIALIZER
    *************** */

    function initialize(
        address _pushChannelAdmin,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint256 _referralCode
    ) public initializer returns (bool success) {
        // setup addresses
        pushChannelAdmin = _pushChannelAdmin;
        governance = pushChannelAdmin; // Will be changed on-Chain governance Address later
        daiAddress = _daiAddress;
        aDaiAddress = _aDaiAddress;
        WETH_ADDRESS = _wethAddress;
        REFERRAL_CODE = _referralCode;
        PUSH_TOKEN_ADDRESS = _pushTokenAddress;
        UNISWAP_V2_ROUTER = _uniswapRouterAddress;
        lendingPoolProviderAddress = _lendingPoolProviderAddress;

        CHANNEL_DEACTIVATION_FEES = 10 ether; // 10 DAI out of total deposited DAIs is charged for Deactivating a Channel
        ADD_CHANNEL_MIN_POOL_CONTRIBUTION = 50 ether; // 50 DAI or above to create the channel
        ADD_CHANNEL_MIN_FEES = 50 ether; // can never be below ADD_CHANNEL_MIN_POOL_CONTRIBUTION

        ADJUST_FOR_FLOAT = 10**7;
        groupLastUpdate = block.number;
        groupNormalizedWeight = ADJUST_FOR_FLOAT; // Always Starts with 1 * ADJUST FOR FLOAT

        // Create Channel
        success = true;
    }

    /* ***************

    SETTER FUNCTIONS

    *************** */
    function updateWETHAddress(address _newAddress) external onlyPushChannelAdmin() {
        WETH_ADDRESS = _newAddress;
    }

    function updateUniswapRouterAddress(address _newAddress) external onlyPushChannelAdmin() {
        UNISWAP_V2_ROUTER = _newAddress;
    }

    function setEpnsCommunicatorAddress(address _commAddress)
        external
        onlyPushChannelAdmin()
    {
        epnsCommunicator = _commAddress;
    }

    function setGovernanceAddress(address _governanceAddress)
        external
        onlyPushChannelAdmin()
    {
      governance = _governanceAddress;
    }

    function setMigrationComplete() external onlyPushChannelAdmin() {
        isMigrationComplete = true;
    }

    function setChannelDeactivationFees(uint256 _newFees) external onlyGovernance() {
        require(
            _newFees > 0,
            "EPNSCoreV1::setChannelDeactivationFees: Channel Deactivation Fees must be greater than ZERO"
        );
        CHANNEL_DEACTIVATION_FEES = _newFees;
    }
    /**
      * @notice Allows to set the Minimum amount threshold for Creating Channels
      *
      * @dev    Minimum required amount can never be below ADD_CHANNEL_MIN_POOL_CONTRIBUTION
      *
      * @param _newFees new minimum fees required for Channel Creation
    **/
    function setMinChannelCreationFees(uint256 _newFees) external onlyGovernance() {
        require(
            _newFees > ADD_CHANNEL_MIN_POOL_CONTRIBUTION,
            "EPNSCoreV1::setMinChannelCreationFees: Fees should be greater than ADD_CHANNEL_MIN_POOL_CONTRIBUTION"
        );
        ADD_CHANNEL_MIN_FEES = _newFees;
    }


    function transferPushChannelAdminControl(address _newAdmin) public onlyPushChannelAdmin() {
        require(_newAdmin != address(0), "EPNSCoreV1::transferPushChannelAdminControl: Invalid Address");
        require(_newAdmin != pushChannelAdmin, "EPNSCoreV1::transferPushChannelAdminControl: Admin address is same");
        pushChannelAdmin = _newAdmin;
    }

    /* ***********************************

        CHANNEL RELATED FUNCTIONALTIES

    **************************************/
    function getChannelState(address _channel) external view returns(uint256 state) {
        state = channels[_channel].channelState;
    }
    /**
     * @notice Allows Channel Owner to update their Channel Description/Detail
     *
     * @dev    Emits an event with the new identity for the respective Channel Address
     *         Records the Block Number of the Block at which the Channel is being updated with a New Identity
     *
     * @param _channel     address of the Channel
     * @param _newIdentity bytes Value for the New Identity of the Channel
     **/
    function updateChannelMeta(address _channel, bytes calldata _newIdentity)
        external
        onlyChannelOwner(_channel)
    {
        emit UpdateChannel(_channel, _newIdentity);

        _updateChannelMeta(_channel);
    }

    function _updateChannelMeta(address _channel) internal {
        channels[_channel].channelUpdateBlock = block.number;
    }

    function createChannelForPushChannelAdmin() external onlyPushChannelAdmin() {
        require (!oneTimeCheck, "EPNSCoreV1::createChannelForPushChannelAdmin: Channel for Admin is already Created");

        // Add EPNS Channels
        // First is for all users
        // Second is all channel alerter, amount deposited for both is 0
        // to save gas, emit both the events out
        // identity = payloadtype + payloadhash

        // EPNS ALL USERS

        _createChannel(pushChannelAdmin, ChannelType.ProtocolNonInterest, 0); // should the owner of the contract be the channel? should it be pushChannelAdmin in this case?
         emit AddChannel(
            pushChannelAdmin,
            ChannelType.ProtocolNonInterest,
            "1+QmSbRT16JVF922yAB26YxWFD6DmGsnSHm8VBrGUQnXTS74"
        );

        // EPNS ALERTER CHANNEL
        _createChannel(
            address(0x0),
            ChannelType.ProtocolNonInterest,
            0
        );
        emit AddChannel(
        address(0x0),
        ChannelType.ProtocolNonInterest,
        "1+QmTCKYL2HRbwD6nGNvFLe4wPvDNuaYGr6RiVeCvWjVpn5s"
        );

        oneTimeCheck = true;
    }

    /**
     * @notice An external function that allows users to Create their Own Channels by depositing a valid amount of DAI
     * @dev    Only allows users to Create One Channel for a specific address.
     *         Only allows a Valid Channel Type to be assigned for the Channel Being created.
     *         Validates and Transfers the amount of DAI from the Channel Creator to this Contract Address
     *         Deposits the Funds the Lending Pool and creates the Channel for the msg.sender.
     * @param  _channelType the type of the Channel Being created
     * @param  _identity the bytes value of the identity of the Channel
     * @param  _amount Amount of DAI to be deposited before Creating the Channel
     **/
    function createChannelWithFees(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount
    )
        external
        onlyInactiveChannels(msg.sender)
        onlyUserAllowedChannelType(_channelType)
    {
        // Save gas, Emit the event out
        emit AddChannel(msg.sender, _channelType, _identity);

        // Bubble down to create channel
        _createChannelWithFees(msg.sender, _channelType, _amount);
    }

    function _createChannelWithFees(
        address _channel,
        ChannelType _channelType,
        uint256 _amount
    ) private {
        // Check if it's equal or above Channel Pool Contribution
        require(
            _amount >= ADD_CHANNEL_MIN_FEES,
            "EPNSCoreV1::_createChannelWithFees: Insufficient Funds"
        );
        IERC20(daiAddress).safeTransferFrom(_channel, address(this), _amount);
        _depositFundsToPool(_amount);
        _createChannel(_channel, _channelType, _amount);
    }

      /**
     * @notice Migration function that allows pushChannelAdmin to migrate the previous Channel Data to this protocol
     *
     * @dev   can only be Called by the pushChannelAdmin
     *        Channel's identity is simply emitted out
     *        Channel's on-Chain details are stored by calling the "_crateChannel" function
     *        DAI required for Channel Creation will be PAID by pushChannelAdmin
     *
     * @param _startIndex       starting Index for the LOOP
     * @param _endIndex         Last Index for the LOOP
     * @param _channelAddresses array of address of the Channel
     * @param _channelTypeLst   array of type of the Channel being created
     * @param _amountList       array of amount of DAI to be depositeds
    **/
    function migrateChannelData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelAddresses,
        ChannelType[] calldata _channelTypeLst,
        bytes[] calldata _identityList,
        uint256[] calldata _amountList
    ) external onlyPushChannelAdmin returns (bool) {
        require(
            !isMigrationComplete,
            "EPNSCoreV1::migrateChannelData: Migration is already done"
        );

        require(
            (_channelAddresses.length == _channelTypeLst.length) &&
            (_channelAddresses.length == _channelAddresses.length),
            "EPNSCoreV1::migrateChannelData: Unequal Arrays passed as Argument"
        );

        for (uint256 i = _startIndex; i < _endIndex; i++) {
                if(channels[_channelAddresses[i]].channelState != 0){
                    continue;
            }else{
                IERC20(daiAddress).safeTransferFrom(pushChannelAdmin, address(this), _amountList[i]);
                _depositFundsToPool(_amountList[i]);
                emit AddChannel(_channelAddresses[i], _channelTypeLst[i], _identityList[i]);
                _createChannel(_channelAddresses[i], _channelTypeLst[i], _amountList[i]);
            }
        }
        return true;
    }

    /**
     * @notice Base Channel Creation Function that allows users to Create Their own Channels and Stores crucial details about the Channel being created
     * @dev    -Initializes the Channel Struct
     *         -Subscribes the Channel's Owner to Imperative EPNS Channels as well as their Own Channels
     *         -Increases Channel Counts and Readjusts the FS of Channels
     * @param _channel         address of the channel being Created
     * @param _channelType     The type of the Channel
     * @param _amountDeposited The total amount being deposited while Channel Creation
     **/
    function _createChannel(
        address _channel,
        ChannelType _channelType,
        uint256 _amountDeposited
    ) private {
        // Calculate channel weight
        uint256 _channelWeight = _amountDeposited.mul(ADJUST_FOR_FLOAT).div(
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );

        // Next create the channel and mark user as channellized
        channels[_channel].channelState = 1;

        channels[_channel].poolContribution = _amountDeposited;
        channels[_channel].channelType = _channelType;
        channels[_channel].channelStartBlock = block.number;
        channels[_channel].channelUpdateBlock = block.number;
        channels[_channel].channelWeight = _channelWeight;

        // Add to map of addresses and increment channel count
        mapAddressChannels[channelsCount] = _channel;
        channelsCount = channelsCount.add(1);

        // Readjust fair share if interest bearing
        if (
            _channelType == ChannelType.ProtocolPromotion ||
            _channelType == ChannelType.InterestBearingOpen ||
            _channelType == ChannelType.InterestBearingMutual
        ) {
            (
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            ) = _readjustFairShareOfChannels(
                ChannelAction.ChannelAdded,
                _channelWeight,
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            );
        }

        // Subscribe them to their own channel as well
        if (_channel != pushChannelAdmin) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                _channel,
                _channel
            );
        }

        // All Channels are subscribed to EPNS Alerter as well, unless it's the EPNS Alerter channel iteself
        if (_channel != address(0x0)) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                address(0x0),
                _channel
            );
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                _channel,
                pushChannelAdmin
            );
        }
    }

    /** @notice - Deliminated Notification Settings string contains -> Total Notif Options + Notification Settings
     * For instance: 5+1-0+2-50-20-100+1-1+2-78-10-150
     *  5 -> Total Notification Options provided by a Channel owner
     *
     *  For Boolean Type Notif Options
     *  1-0 -> 1 stands for BOOLEAN type - 0 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case FALSE.
     *  1-1 stands for BOOLEAN type - 1 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case TRUE.
     *
     *  For SLIDER TYPE Notif Options
     *   2-50-20-100 -> 2 stands for SLIDER TYPE - 50 stands for Default Value for that Option - 20 is the Start Range of that SLIDER - 100 is the END Range of that SLIDER Option
     *  2-78-10-150 -> 2 stands for SLIDER TYPE - 78 stands for Default Value for that Option - 10 is the Start Range of that SLIDER - 150 is the END Range of that SLIDER Option
     *
     *  @param _notifOptions - Total Notification options provided by the Channel Owner
     *  @param _notifSettings- Deliminated String of Notification Settings
     *  @param _notifDescription - Description of each Notification that depicts the Purpose of that Notification
    **/
    function createChannelSettings(
        uint256 _notifOptions,
        string calldata _notifSettings,
        string calldata _notifDescription
    ) external onlyActivatedChannels(msg.sender) {
        string memory notifSetting = string(
            abi.encodePacked(
                Strings.toString(_notifOptions),
                "+",
                _notifSettings
            )
        );
        channelNotifSettings[msg.sender] = notifSetting;
        emit ChannelNotifcationSettingsAdded(
            msg.sender,
            _notifOptions,
            notifSetting,
            _notifDescription
        );
    }

    /**
     * @notice Allows Channel Owner to Deactivate his/her Channel for any period of Time. Channels Deactivated can be Activated again.
     * @dev    - Function can only be Called by Already Activated Channels
     *         - Calculates the Total DAI Deposited by Channel Owner while Channel Creation.
     *         - Deducts CHANNEL_DEACTIVATION_FEES from the total Deposited DAI and Transfers back the remaining amount of DAI in the form of PUSH tokens.
     *         - Calculates the New Channel Weight and Readjusts the FS Ratio accordingly.
     *         - Updates the State of the Channel(channelState) and the New Channel Weight in the Channel's Struct
     *         - In case, the Channel Owner wishes to reactivate his/her channel, they need to Deposit at least the Minimum required DAI while reactivating.
     **/

    function deactivateChannel() external onlyActivatedChannels(msg.sender) {
        Channel memory channelData = channels[msg.sender];

        uint256 totalAmountDeposited = channelData.poolContribution;
        uint256 totalRefundableAmount = totalAmountDeposited.sub(
            CHANNEL_DEACTIVATION_FEES
        );

        uint256 _newChannelWeight = CHANNEL_DEACTIVATION_FEES
            .mul(ADJUST_FOR_FLOAT)
            .div(ADD_CHANNEL_MIN_POOL_CONTRIBUTION);

        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _newChannelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channelData.channelState = 2;
        POOL_FUNDS = POOL_FUNDS.sub(totalRefundableAmount);
        channelData.channelWeight = _newChannelWeight;

        channels[msg.sender] = channelData;
        swapAndTransferPUSH(msg.sender, totalRefundableAmount);
        emit DeactivateChannel(msg.sender, totalRefundableAmount);
    }

    /**
     * @notice Allows Channel Owner to Reactivate his/her Channel again.
     * @dev    - Function can only be called by previously Deactivated Channels
     *         - Channel Owner must Depost at least minimum amount of DAI to reactivate his/her channel.
     *         - Deposited Dai goes thorugh similar procedure and is deposited to AAVE .
     *         - Calculation of the new Channel Weight is performed and the FairShare is Readjusted once again with relevant details
     *         - Updates the State of the Channel(channelState) in the Channel's Struct.
     * @param _amount Amount of Dai to be deposited
     **/

    function reactivateChannel(uint256 _amount)
        external
        onlyDeactivatedChannels(msg.sender)
    {
        require(
            _amount >= ADD_CHANNEL_MIN_POOL_CONTRIBUTION,
            "EPNSCoreV1::reactivateChannel: Insufficient Funds Passed for Channel Reactivation"
        );
        IERC20(daiAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _depositFundsToPool(_amount);

        uint256 _channelWeight = _amount.mul(ADJUST_FOR_FLOAT).div(
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );
        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _channelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channels[msg.sender].channelState = 1;
        channels[msg.sender].channelWeight = _channelWeight;

        emit ReactivateChannel(msg.sender, _amount);
    }

    /**
     * @notice ALlows the pushChannelAdmin to Block any particular channel Completely.
     *
     * @dev    - Can only be called by pushChannelAdmin
     *         - Can only be Called for Activated Channels
     *         - Can only Be Called for NON-BLOCKED Channels
     *
     *         - Updates channel's state to BLOCKED ('3')
     *         - Updates Channel's Pool Contribution to ZERO
     *         - Updates Channel's Weight to ZERO
     *         - Increases the Protocol Fee Pool
     *         - Decreases the Channel Count
     *         - Readjusts the FS Ratio
     *         - Emit 'ChannelBlocked' Event
     * @param _channelAddress Address of the Channel to be blocked
     **/

     function blockChannel(address _channelAddress)
     external
     onlyPushChannelAdmin()
     onlyUnblockedChannels(_channelAddress){
       Channel memory channelData = channels[_channelAddress];

       uint256 totalAmountDeposited = channelData.poolContribution;
       uint256 totalRefundableAmount = totalAmountDeposited.sub(
           CHANNEL_DEACTIVATION_FEES
       );

       uint256 _newChannelWeight = CHANNEL_DEACTIVATION_FEES
           .mul(ADJUST_FOR_FLOAT)
           .div(ADD_CHANNEL_MIN_POOL_CONTRIBUTION);

       channelsCount = channelsCount.sub(1);

       channelData.channelState = 3;
       channelData.channelWeight = _newChannelWeight;
       channelData.channelUpdateBlock = block.number;
       channelData.poolContribution = CHANNEL_DEACTIVATION_FEES;
       PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(totalRefundableAmount);
       (
           groupFairShareCount,
           groupNormalizedWeight,
           groupHistoricalZ,
           groupLastUpdate
       ) = _readjustFairShareOfChannels(
           ChannelAction.ChannelRemoved,
           _newChannelWeight,
           groupFairShareCount,
           groupNormalizedWeight,
           groupHistoricalZ,
           groupLastUpdate
       );

       channels[_channelAddress] = channelData;
       emit ChannelBlocked(_channelAddress);
     }

    /* **************
    => CHANNEL VERIFICATION FUNCTIONALTIES <=
    *************** */

    /**
     * @notice    Function is designed to tell if a channel is verified or not
     * @dev       Get if channel is verified or not
     * @param    _channel Address of the channel to be Verified
     * @return   verificationStatus  Returns 0 for not verified, 1 for primary verification, 2 for secondary verification
     **/
    function getChannelVerfication(address _channel)
      public
      view
      returns (uint8 verificationStatus)
    {
      address verifiedBy = channels[_channel].verifiedBy;
      bool logicComplete = false;

      // Check if it's primary verification
      if (verifiedBy == pushChannelAdmin || _channel == address(0x0) || _channel == pushChannelAdmin) {
        // primary verification, mark and exit
        verificationStatus = 1;
        logicComplete = true;
      }
      else {
        // can be secondary verification or not verified, dig deeper
        while (!logicComplete) {
          if (verifiedBy == address(0x0)) {
            verificationStatus = 0;
            logicComplete = true;
          }
          else if (verifiedBy == pushChannelAdmin) {
            verificationStatus = 2;
            logicComplete = true;
          }
          else {
            // Upper drill exists, go up
            verifiedBy = channels[verifiedBy].verifiedBy;
          }
        }
      }
    }

    /**
     * @notice    Function is designed to verify a channel
     * @dev       Channel will be verified by primary or secondary verification, will fail or upgrade if already verified
     * @param    _channel Address of the channel to be Verified
     **/
    function verifyChannel(address _channel) external onlyActivatedChannels(_channel) {
      // Check if caller is verified first
      uint8 callerVerified = getChannelVerfication(msg.sender);
      require(callerVerified > 0, "EPNSCoreV1::verifyChannel: Caller is not verified");

      // Check if channel is verified
      uint8 channelVerified = getChannelVerfication(_channel);
      require(
        (callerVerified >= 1 && channelVerified == 0) ||
        (msg.sender == pushChannelAdmin),
        "EPNSCoreV1::verifyChannel: Channel already verified"
      );

      // Verify channel
      channels[_channel].verifiedBy = msg.sender;

      // Emit event
      emit ChannelVerified(_channel, msg.sender);
    }

    /**
     * @notice    Function is designed to unverify a channel
     * @dev       Channel who verified this channel or Push Channel Admin can only revoke
     * @param    _channel Address of the channel to be unverified
     **/
    function unverifyChannel(address _channel) external {
      require(
        channels[_channel].verifiedBy == msg.sender || msg.sender == pushChannelAdmin,
        "EPNSCoreV1::unverifyChannel: Only channel who verified this or Push Channel Admin can revoke"
      );

      // Unverify channel
      channels[_channel].verifiedBy = address(0x0);

      // Emit Event
      emit ChannelVerificationRevoked(_channel, msg.sender);
    }

    /* **************

    => DEPOSIT & WITHDRAWAL of FUNDS<=

    *************** */
    /**
     * @notice  Function is used for Handling the entire procedure of Depositing the DAI to Lending POOl
     *
     * @dev     Updates the Relevant state variable during Deposit of DAI
     *          Lends the DAI to AAVE protocol.
     * @param   amount - Amount that is to be deposited
     **/
    function _depositFundsToPool(uint256 amount) private {
        POOL_FUNDS = POOL_FUNDS.add(amount);

        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
            lendingPoolProviderAddress
        );
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        IERC20(daiAddress).approve(provider.getLendingPoolCore(), amount);
        // Deposit to AAVE
        lendingPool.deposit(daiAddress, amount, uint16(REFERRAL_CODE)); // set to 0 in constructor presently
    }

    /**
     * @notice Swaps aDai to PUSH Tokens and Transfers to the USER Address
     *
     * @param _user address of the user that will recieve the PUSH Tokens
     * @param _userAmount the amount of aDai to be swapped and transferred
     **/
    function swapAndTransferPUSH(address _user, uint256 _userAmount)
        internal
        returns (bool)
    {
        swapADaiForDai(_userAmount);
        IERC20(daiAddress).approve(UNISWAP_V2_ROUTER, _userAmount);

        address[] memory path = new address[](3);
        path[0] = daiAddress;
        path[1] = WETH_ADDRESS;
        path[2] = PUSH_TOKEN_ADDRESS;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _userAmount,
            1,
            path,
            _user,
            block.timestamp
        );
        return true;
    }

    function swapADaiForDai(uint256 _amount) private{
      ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
        lendingPoolProviderAddress
      );
      IERC20(aDaiAddress).approve(provider.getLendingPoolCore(), _amount);

      IADai(aDaiAddress).redeem(_amount);
    }

    /**
     * @notice Function to claim Rewards generated for indivudual users
     * NOTE   The EPNSCore Protocol must be approved as a Delegtate for Resetting the HOLDER's WEIGHT on PUSH Token Contract.
     *
     * @dev - Gets the User's Holder weight from the PUSH token contract
     *      - Gets the totalSupply and Start Block of PUSH Token
     *      - Calculates the totalHolder weight w.r.t to the current block number
     *      - Gets the ratio of token holder by dividing individual User's weight tp totalWeight (also adjusts for the FLOAT)
     *      - Gets the Total ADAI Interest accumulated for the protocol
     *      - Calculates the amount the User should recieve considering the user's ratio calculated before
     *      - The claim function resets the Holder's Weight on the PUSH Contract by setting it to the current block.number
     *      - The Claimable ADAI Amount amount is SWapped for PUSH Tokens.
     *      - The PUSH token is then transferred to the USER as the interest.
    **/
    function claimInterest() external returns(bool success){
      address _user = msg.sender;
      // Reading necessary PUSH details
      uint pushStartBlock = IPUSH(PUSH_TOKEN_ADDRESS).born();
      uint pushTotalSupply = IPUSH(PUSH_TOKEN_ADDRESS).totalSupply();
      uint256 userHolderWeight = IPUSH(PUSH_TOKEN_ADDRESS).returnHolderUnits(_user, block.number);

      // Calculating total holder weight at the current Block Number
      uint blockGap = block.number.sub(pushStartBlock);
      uint totalHolderWeight = pushTotalSupply.mul(blockGap);

      //Calculating individual User's Ratio
      uint userRatio = userHolderWeight.mul(ADJUST_FOR_FLOAT).div(totalHolderWeight);

      // Calculating aDai Interest Generated and CLaimable Amount
      uint256 aDaiBalanceWithInterest = IADai(aDaiAddress).balanceOf(address(this));
      uint256 totalADAIInterest = aDaiBalanceWithInterest.sub(POOL_FUNDS);
      uint256 totalClaimableRewards = totalADAIInterest.mul(userRatio).div(ADJUST_FOR_FLOAT).div(100);
      require(totalClaimableRewards > 0, "EPNSCoreV1::claimInterest: No Claimable Rewards at the Moment");

      // Reset the User's Weight and Transfer the Tokens
      IPUSH(PUSH_TOKEN_ADDRESS).resetHolderWeight(_user);
      usersInterestClaimed[_user] = usersInterestClaimed[_user].add(totalClaimableRewards);
      swapAndTransferPUSH(_user, totalClaimableRewards);

      emit InterestClaimed(msg.sender, totalClaimableRewards);
      success = true;
    }

    /* **************

    => FAIR SHARE RATIO CALCULATIONS <=

    *************** */
    /**
     * @notice  Helps keeping trakc of the FAIR Share Details whenever a specific Channel Action occur
     * @dev     Updates some of the imperative Fair Share Data based whenever a paricular channel action is performed.
     *          Takes into consideration 3 major Channel Actions, i.e., Channel Creation, Channel Removal or Channel Deactivation/Reactivation.
     *
     * @param _action                 The type of Channel action for which the Fair Share is being adjusted
     * @param _channelWeight          Weight of the channel on which the Action is being performed.
     * @param _groupFairShareCount    Fair share count
     * @param _groupNormalizedWeight  Normalized weight value
     * @param _groupHistoricalZ       The Historical Constant - Z
     * @param _groupLastUpdate        Holds the block number of the last update.
     **/
    function _readjustFairShareOfChannels(
        ChannelAction _action,
        uint256 _channelWeight,
        uint256 _groupFairShareCount,
        uint256 _groupNormalizedWeight,
        uint256 _groupHistoricalZ,
        uint256 _groupLastUpdate
    )
        private
        view
        returns (
            uint256 groupNewCount,
            uint256 groupNewNormalizedWeight,
            uint256 groupNewHistoricalZ,
            uint256 groupNewLastUpdate
        )
    {
        // readjusts the group count and do deconstruction of weight
        uint256 groupModCount = _groupFairShareCount;
        uint256 prevGroupCount = groupModCount;

        uint256 totalWeight;
        uint256 adjustedNormalizedWeight = _groupNormalizedWeight; //_groupNormalizedWeight;

        // Increment or decrement count based on flag
        if (_action == ChannelAction.ChannelAdded) {
            groupModCount = groupModCount.add(1);
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.add(_channelWeight);

        } else if (_action == ChannelAction.ChannelRemoved) {
            groupModCount = groupModCount.sub(1);
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.sub(_channelWeight);

        } else if (_action == ChannelAction.ChannelUpdated) {
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount.sub(1));
            totalWeight = totalWeight.add(_channelWeight);

        } else {
            revert("EPNSCoreV1::_readjustFairShareOfChannels: Invalid Channel Action");
        }
        // now calculate the historical constant
        // z = z + nxw
        // z is the historical constant
        // n is the previous count of group fair share
        // x is the differential between the latest block and the last update block of the group
        // w is the normalized average of the group (ie, groupA weight is 1 and groupB is 2 then w is (1+2)/2 = 1.5)
        uint256 n = groupModCount;
        uint256 x = block.number.sub(_groupLastUpdate);
        uint256 w = totalWeight.div(groupModCount);
        uint256 z = _groupHistoricalZ;

        uint256 nx = n.mul(x);
        uint256 nxw = nx.mul(w);

        // Save Historical Constant and Update Last Change Block
        z = z.add(nxw);

        if (n == 1) {
            // z should start from here as this is first channel
            z = 0;
        }

        // Update return variables
        groupNewCount = groupModCount;
        groupNewNormalizedWeight = w;
        groupNewHistoricalZ = z;
        groupNewLastUpdate = block.number;
    }

    function getVersion() external pure returns(uint8 version){
      version = 2;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity >=0.6.0 <0.7.0;

interface IPUSH {
  function born() external view returns(uint);
  function totalSupply() external view returns(uint);
  function resetHolderWeight(address holder) external;
  function returnHolderUnits(address account, uint atBlock) external view returns (uint);
}

pragma solidity >=0.6.0 <0.7.0;

interface IADai {
    function redeem(uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256) ;
    function principalBalanceOf(address _user) external view returns(uint256);
    function getInterestRedirectionAddress(address _user) external view returns(address);
}

pragma solidity >=0.6.0 <0.7.0;

interface ILendingPool {
    function addressesProvider() external view returns (address);
    
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;

    function redeemUnderlying(address _reserve, address _user, uint256 _amount) external;

    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;

    function repay(address _reserve, uint256 _amount, address _onBehalfOf) external payable;

    function swapBorrowRateMode(address _reserve) external;

    function rebalanceFixedBorrowRate(address _reserve, address _user) external;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;

    function liquidationCall(address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken) external payable;

    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;

    function getReserveConfigurationData(address _reserve) external view returns (uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive);

    function getReserveData(address _reserve) external view returns (uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp);

    function getUserAccountData(address _user) external view returns (uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);

    function getUserReserveData(address _reserve, address _user) external view returns (uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled);

    function getReserves() external view;
}

pragma solidity >=0.6.0 <0.7.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts); 
}

pragma solidity >=0.6.0 <0.7.0;

interface IEPNSCommV1 {
 	function subscribeViaCore(address _channel, address _user) external returns(bool);
}

pragma solidity >=0.6.0 <0.7.0;

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);

    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

/**
 * EPNS Core is the main protocol that deals with the imperative
 * features and functionalities like Channel Creation, pushChannelAdmin etc.
 *
 * This protocol will be specifically deployed on Ethereum Blockchain while the Communicator
 * protocols can be deployed on Multiple Chains.
 * The EPNS Core is more inclined towards the storing and handling the Channel related
 * Functionalties.
 **/

import "./interfaces/IPUSH.sol";
import "./interfaces/IADai.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IEPNSCommV1.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "hardhat/console.sol";

contract EPNSCoreV1 is Initializable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ***************

      DEFINE ENUMS AND CONSTANTS

     *************** */

    // For Message Type
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual
    }
    enum ChannelAction {
        ChannelRemoved,
        ChannelAdded,
        ChannelUpdated
    }

    /**
     * @notice Channel Struct that includes imperative details about a specific Channel.
    **/
    struct Channel {
        // @notice Denotes the Channel Type
        ChannelType channelType;

        /** @notice Symbolizes Channel's State:
         * 0 -> INACTIVE,
         * 1 -> ACTIVATED
         * 2 -> DeActivated By Channel Owner,
         * 3 -> BLOCKED by pushChannelAdmin/Governance
        **/
        uint8 channelState;

        /** @notice Symbolizes Channel's Verification Status:
         *   0 -> UnVerified Channels,
         *   1 -> Verified by pushChannelAdmin,
         *   2 -> Verified by other Channel Owners
        **/
        address verifiedBy;

        // @notice Total Amount of Dai deposited during Channel Creation
        uint256 poolContribution;

        // @notice Represents the Historical Constant
        uint256 channelHistoricalZ;

        // @notice Represents the FS Count
        uint256 channelFairShareCount;

        // @notice The last update block number, used to calculate fair share
        uint256 channelLastUpdate;

        // @notice Helps in defining when channel started for pool and profit calculation
        uint256 channelStartBlock;

        // @notice Helps in outlining when channel was updated
        uint256 channelUpdateBlock;

        // @notice The individual weight to be applied as per pool contribution
        uint256 channelWeight;
    }

    /* ***************
        MAPPINGS
     *************** */

    mapping(address => Channel) public channels;
    mapping(uint256 => address) public mapAddressChannels;
    mapping(address => string) public channelNotifSettings;
    mapping(address => uint256) public usersInterestClaimed;


    /* ***************
        STATE VARIABLES
     *************** */
    string public constant name = "EPNS CORE V1";
    bool oneTimeCheck;
    bool public isMigrationComplete;

    address public pushChannelAdmin;
    address public governance;
    address public daiAddress;
    address public aDaiAddress;
    address public WETH_ADDRESS;
    address public epnsCommunicator;
    address public UNISWAP_V2_ROUTER;
    address public PUSH_TOKEN_ADDRESS;
    address public lendingPoolProviderAddress;

    uint256 public REFERRAL_CODE;
    uint256 ADJUST_FOR_FLOAT;
    uint256 public channelsCount;

    //  @notice Helper Variables for FSRatio Calculation | GROUPS = CHANNELS
    uint256 public groupNormalizedWeight;
    uint256 public groupHistoricalZ;
    uint256 public groupLastUpdate;
    uint256 public groupFairShareCount;

    // @notice Necessary variables for Keeping track of Funds and Fees
    uint256 public POOL_FUNDS;
    uint256 public PROTOCOL_POOL_FEES;
    uint256 public ADD_CHANNEL_MIN_FEES;
    uint256 public CHANNEL_DEACTIVATION_FEES;
    uint256 public ADD_CHANNEL_MIN_POOL_CONTRIBUTION;

    /* ***************
        EVENTS
     *************** */
    event UpdateChannel(address indexed channel, bytes identity);
    event Withdrawal(address indexed to, address token, uint256 amount);
    event InterestClaimed(address indexed user, uint256 indexed interestAmount);

    event ChannelVerified(address indexed channel, address indexed verifier);
    event ChannelVerificationRevoked(address indexed channel, address indexed revoker);

    event DeactivateChannel(
        address indexed channel,
        uint256 indexed amountRefunded
    );
    event ReactivateChannel(
        address indexed channel,
        uint256 indexed amountDeposited
    );
    event ChannelBlocked(
        address indexed channel
    );
    event AddChannel(
        address indexed channel,
        ChannelType indexed channelType,
        bytes identity
    );
    event ChannelNotifcationSettingsAdded(
        address _channel,
        uint256 totalNotifOptions,
        string _notifSettings,
        string _notifDescription
    );

    /* **************
        MODIFIERS
    ***************/
    modifier onlyPushChannelAdmin() {
        require(msg.sender == pushChannelAdmin, "EPNSCoreV1::onlyPushChannelAdmin: Caller not pushChannelAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == pushChannelAdmin, "EPNSCoreV1::onlyGovernance: Caller not Governance");
        _;
    }

    modifier onlyInactiveChannels(address _channel) {
        require(
            channels[_channel].channelState == 0,
            "EPNSCoreV1::onlyInactiveChannels: Channel already Activated"
        );
        _;
    }
    modifier onlyActivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 1,
            "EPNSCoreV1::onlyActivatedChannels: Channel Deactivated, Blocked or Does Not Exist"
        );
        _;
    }

    modifier onlyDeactivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 2,
            "EPNSCoreV1::onlyDeactivatedChannels: Channel is not Deactivated Yet"
        );
        _;
    }

    modifier onlyUnblockedChannels(address _channel) {
        require(
            ((channels[_channel].channelState != 3) &&
              (channels[_channel].channelState != 0)),
            "EPNSCoreV1::onlyUnblockedChannels: Channel is BLOCKED Already or Not Activated Yet"
        );
        _;
    }

    modifier onlyChannelOwner(address _channel) {
        require(
            ((channels[_channel].channelState == 1 && msg.sender == _channel) ||
                (msg.sender == pushChannelAdmin &&
                    _channel == address(0x0))),
            "EPNSCoreV1::onlyChannelOwner: Channel not Exists or Invalid Channel Owner"
        );
        _;
    }

    modifier onlyUserAllowedChannelType(ChannelType _channelType) {
        require(
            (_channelType == ChannelType.InterestBearingOpen ||
                _channelType == ChannelType.InterestBearingMutual),
            "EPNSCoreV1::onlyUserAllowedChannelType: Channel Type Invalid"
        );

        _;
    }

    /* ***************
        INITIALIZER
    *************** */

    function initialize(
        address _pushChannelAdmin,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint256 _referralCode
    ) public initializer returns (bool success) {
        // setup addresses
        pushChannelAdmin = _pushChannelAdmin;
        governance = pushChannelAdmin; // Will be changed on-Chain governance Address later
        daiAddress = _daiAddress;
        aDaiAddress = _aDaiAddress;
        WETH_ADDRESS = _wethAddress;
        REFERRAL_CODE = _referralCode;
        PUSH_TOKEN_ADDRESS = _pushTokenAddress;
        UNISWAP_V2_ROUTER = _uniswapRouterAddress;
        lendingPoolProviderAddress = _lendingPoolProviderAddress;

        CHANNEL_DEACTIVATION_FEES = 10 ether; // 10 DAI out of total deposited DAIs is charged for Deactivating a Channel
        ADD_CHANNEL_MIN_POOL_CONTRIBUTION = 50 ether; // 50 DAI or above to create the channel
        ADD_CHANNEL_MIN_FEES = 50 ether; // can never be below ADD_CHANNEL_MIN_POOL_CONTRIBUTION

        ADJUST_FOR_FLOAT = 10**7;
        groupLastUpdate = block.number;
        groupNormalizedWeight = ADJUST_FOR_FLOAT; // Always Starts with 1 * ADJUST FOR FLOAT

        // Create Channel
        success = true;
    }

    /* ***************

    SETTER FUNCTIONS

    *************** */
    function updateWETHAddress(address _newAddress) external onlyPushChannelAdmin() {
        WETH_ADDRESS = _newAddress;
    }

    function updateUniswapRouterAddress(address _newAddress) external onlyPushChannelAdmin() {
        UNISWAP_V2_ROUTER = _newAddress;
    }

    function setEpnsCommunicatorAddress(address _commAddress)
        external
        onlyPushChannelAdmin()
    {
        epnsCommunicator = _commAddress;
    }

    function setGovernanceAddress(address _governanceAddress)
        external
        onlyPushChannelAdmin()
    {
      governance = _governanceAddress;
    }

    function setMigrationComplete() external onlyPushChannelAdmin() {
        isMigrationComplete = true;
    }

    function setChannelDeactivationFees(uint256 _newFees) external onlyGovernance() {
        require(
            _newFees > 0,
            "EPNSCoreV1::setChannelDeactivationFees: Channel Deactivation Fees must be greater than ZERO"
        );
        CHANNEL_DEACTIVATION_FEES = _newFees;
    }
    /**
      * @notice Allows to set the Minimum amount threshold for Creating Channels
      *
      * @dev    Minimum required amount can never be below ADD_CHANNEL_MIN_POOL_CONTRIBUTION
      *
      * @param _newFees new minimum fees required for Channel Creation
    **/
    function setMinChannelCreationFees(uint256 _newFees) external onlyGovernance() {
        require(
            _newFees > ADD_CHANNEL_MIN_POOL_CONTRIBUTION,
            "EPNSCoreV1::setMinChannelCreationFees: Fees should be greater than ADD_CHANNEL_MIN_POOL_CONTRIBUTION"
        );
        ADD_CHANNEL_MIN_FEES = _newFees;
    }


    function transferPushChannelAdminControl(address _newAdmin) public onlyPushChannelAdmin() {
        require(_newAdmin != address(0), "EPNSCoreV1::transferPushChannelAdminControl: Invalid Address");
        require(_newAdmin != pushChannelAdmin, "EPNSCoreV1::transferPushChannelAdminControl: Admin address is same");
        pushChannelAdmin = _newAdmin;
    }

    /* ***********************************

        CHANNEL RELATED FUNCTIONALTIES

    **************************************/
    function getChannelState(address _channel) external view returns(uint256 state) {
        state = channels[_channel].channelState;
    }
    /**
     * @notice Allows Channel Owner to update their Channel Description/Detail
     *
     * @dev    Emits an event with the new identity for the respective Channel Address
     *         Records the Block Number of the Block at which the Channel is being updated with a New Identity
     *
     * @param _channel     address of the Channel
     * @param _newIdentity bytes Value for the New Identity of the Channel
     **/
    function updateChannelMeta(address _channel, bytes calldata _newIdentity)
        external
        onlyChannelOwner(_channel)
    {
        emit UpdateChannel(_channel, _newIdentity);

        _updateChannelMeta(_channel);
    }

    function _updateChannelMeta(address _channel) internal {
        channels[_channel].channelUpdateBlock = block.number;
    }

    function createChannelForPushChannelAdmin() external onlyPushChannelAdmin() {
        require (!oneTimeCheck, "EPNSCoreV1::createChannelForPushChannelAdmin: Channel for Admin is already Created");

        // Add EPNS Channels
        // First is for all users
        // Second is all channel alerter, amount deposited for both is 0
        // to save gas, emit both the events out
        // identity = payloadtype + payloadhash

        // EPNS ALL USERS

        _createChannel(pushChannelAdmin, ChannelType.ProtocolNonInterest, 0); // should the owner of the contract be the channel? should it be pushChannelAdmin in this case?
         emit AddChannel(
            pushChannelAdmin,
            ChannelType.ProtocolNonInterest,
            "1+QmSbRT16JVF922yAB26YxWFD6DmGsnSHm8VBrGUQnXTS74"
        );

        // EPNS ALERTER CHANNEL
        _createChannel(
            address(0x0),
            ChannelType.ProtocolNonInterest,
            0
        );
        emit AddChannel(
        address(0x0),
        ChannelType.ProtocolNonInterest,
        "1+QmTCKYL2HRbwD6nGNvFLe4wPvDNuaYGr6RiVeCvWjVpn5s"
        );

        oneTimeCheck = true;
    }

    /**
     * @notice An external function that allows users to Create their Own Channels by depositing a valid amount of DAI
     * @dev    Only allows users to Create One Channel for a specific address.
     *         Only allows a Valid Channel Type to be assigned for the Channel Being created.
     *         Validates and Transfers the amount of DAI from the Channel Creator to this Contract Address
     *         Deposits the Funds the Lending Pool and creates the Channel for the msg.sender.
     * @param  _channelType the type of the Channel Being created
     * @param  _identity the bytes value of the identity of the Channel
     * @param  _amount Amount of DAI to be deposited before Creating the Channel
     **/
    function createChannelWithFees(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount
    )
        external
        onlyInactiveChannels(msg.sender)
        onlyUserAllowedChannelType(_channelType)
    {
        // Save gas, Emit the event out
        emit AddChannel(msg.sender, _channelType, _identity);

        // Bubble down to create channel
        _createChannelWithFees(msg.sender, _channelType, _amount);
    }

    function _createChannelWithFees(
        address _channel,
        ChannelType _channelType,
        uint256 _amount
    ) private {
        // Check if it's equal or above Channel Pool Contribution
        require(
            _amount >= ADD_CHANNEL_MIN_FEES,
            "EPNSCoreV1::_createChannelWithFees: Insufficient Funds"
        );
        IERC20(daiAddress).safeTransferFrom(_channel, address(this), _amount);
        _depositFundsToPool(_amount);
        _createChannel(_channel, _channelType, _amount);
    }

      /**
     * @notice Migration function that allows pushChannelAdmin to migrate the previous Channel Data to this protocol
     *
     * @dev   can only be Called by the pushChannelAdmin
     *        Channel's identity is simply emitted out
     *        Channel's on-Chain details are stored by calling the "_crateChannel" function
     *        DAI required for Channel Creation will be PAID by pushChannelAdmin
     *
     * @param _startIndex       starting Index for the LOOP
     * @param _endIndex         Last Index for the LOOP
     * @param _channelAddresses array of address of the Channel
     * @param _channelTypeLst   array of type of the Channel being created
     * @param _amountList       array of amount of DAI to be depositeds
    **/
    function migrateChannelData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelAddresses,
        ChannelType[] calldata _channelTypeLst,
        bytes[] calldata _identityList,
        uint256[] calldata _amountList
    ) external onlyPushChannelAdmin returns (bool) {
        require(
            !isMigrationComplete,
            "EPNSCoreV1::migrateChannelData: Migration is already done"
        );

        require(
            (_channelAddresses.length == _channelTypeLst.length) &&
            (_channelAddresses.length == _channelAddresses.length),
            "EPNSCoreV1::migrateChannelData: Unequal Arrays passed as Argument"
        );

        for (uint256 i = _startIndex; i < _endIndex; i++) {
                if(channels[_channelAddresses[i]].channelState != 0){
                    continue;
            }else{
                IERC20(daiAddress).safeTransferFrom(pushChannelAdmin, address(this), _amountList[i]);
                _depositFundsToPool(_amountList[i]);
                emit AddChannel(_channelAddresses[i], _channelTypeLst[i], _identityList[i]);
                _createChannel(_channelAddresses[i], _channelTypeLst[i], _amountList[i]);
            }
        }
        return true;
    }

    /**
     * @notice Base Channel Creation Function that allows users to Create Their own Channels and Stores crucial details about the Channel being created
     * @dev    -Initializes the Channel Struct
     *         -Subscribes the Channel's Owner to Imperative EPNS Channels as well as their Own Channels
     *         -Increases Channel Counts and Readjusts the FS of Channels
     * @param _channel         address of the channel being Created
     * @param _channelType     The type of the Channel
     * @param _amountDeposited The total amount being deposited while Channel Creation
     **/
    function _createChannel(
        address _channel,
        ChannelType _channelType,
        uint256 _amountDeposited
    ) private {
        // Calculate channel weight
        uint256 _channelWeight = _amountDeposited.mul(ADJUST_FOR_FLOAT).div(
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );

        // Next create the channel and mark user as channellized
        channels[_channel].channelState = 1;

        channels[_channel].poolContribution = _amountDeposited;
        channels[_channel].channelType = _channelType;
        channels[_channel].channelStartBlock = block.number;
        channels[_channel].channelUpdateBlock = block.number;
        channels[_channel].channelWeight = _channelWeight;

        // Add to map of addresses and increment channel count
        mapAddressChannels[channelsCount] = _channel;
        channelsCount = channelsCount.add(1);

        // Readjust fair share if interest bearing
        if (
            _channelType == ChannelType.ProtocolPromotion ||
            _channelType == ChannelType.InterestBearingOpen ||
            _channelType == ChannelType.InterestBearingMutual
        ) {
            (
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            ) = _readjustFairShareOfChannels(
                ChannelAction.ChannelAdded,
                _channelWeight,
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            );
        }

        // Subscribe them to their own channel as well
        if (_channel != pushChannelAdmin) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                _channel,
                _channel
            );
        }

        // All Channels are subscribed to EPNS Alerter as well, unless it's the EPNS Alerter channel iteself
        if (_channel != address(0x0)) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                address(0x0),
                _channel
            );
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                _channel,
                pushChannelAdmin
            );
        }
    }

    /** @notice - Deliminated Notification Settings string contains -> Total Notif Options + Notification Settings
     * For instance: 5+1-0+2-50-20-100+1-1+2-78-10-150
     *  5 -> Total Notification Options provided by a Channel owner
     *
     *  For Boolean Type Notif Options
     *  1-0 -> 1 stands for BOOLEAN type - 0 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case FALSE.
     *  1-1 stands for BOOLEAN type - 1 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case TRUE.
     *
     *  For SLIDER TYPE Notif Options
     *   2-50-20-100 -> 2 stands for SLIDER TYPE - 50 stands for Default Value for that Option - 20 is the Start Range of that SLIDER - 100 is the END Range of that SLIDER Option
     *  2-78-10-150 -> 2 stands for SLIDER TYPE - 78 stands for Default Value for that Option - 10 is the Start Range of that SLIDER - 150 is the END Range of that SLIDER Option
     *
     *  @param _notifOptions - Total Notification options provided by the Channel Owner
     *  @param _notifSettings- Deliminated String of Notification Settings
     *  @param _notifDescription - Description of each Notification that depicts the Purpose of that Notification
    **/
    function createChannelSettings(
        uint256 _notifOptions,
        string calldata _notifSettings,
        string calldata _notifDescription
    ) external onlyActivatedChannels(msg.sender) {
        string memory notifSetting = string(
            abi.encodePacked(
                Strings.toString(_notifOptions),
                "+",
                _notifSettings
            )
        );
        channelNotifSettings[msg.sender] = notifSetting;
        emit ChannelNotifcationSettingsAdded(
            msg.sender,
            _notifOptions,
            notifSetting,
            _notifDescription
        );
    }

    /**
     * @notice Allows Channel Owner to Deactivate his/her Channel for any period of Time. Channels Deactivated can be Activated again.
     * @dev    - Function can only be Called by Already Activated Channels
     *         - Calculates the Total DAI Deposited by Channel Owner while Channel Creation.
     *         - Deducts CHANNEL_DEACTIVATION_FEES from the total Deposited DAI and Transfers back the remaining amount of DAI in the form of PUSH tokens.
     *         - Calculates the New Channel Weight and Readjusts the FS Ratio accordingly.
     *         - Updates the State of the Channel(channelState) and the New Channel Weight in the Channel's Struct
     *         - In case, the Channel Owner wishes to reactivate his/her channel, they need to Deposit at least the Minimum required DAI while reactivating.
     **/

    function deactivateChannel() external onlyActivatedChannels(msg.sender) {
        Channel memory channelData = channels[msg.sender];

        uint256 totalAmountDeposited = channelData.poolContribution;
        uint256 totalRefundableAmount = totalAmountDeposited.sub(
            CHANNEL_DEACTIVATION_FEES
        );

        uint256 _newChannelWeight = CHANNEL_DEACTIVATION_FEES
            .mul(ADJUST_FOR_FLOAT)
            .div(ADD_CHANNEL_MIN_POOL_CONTRIBUTION);

        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _newChannelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channelData.channelState = 2;
        POOL_FUNDS = POOL_FUNDS.sub(totalRefundableAmount);
        channelData.channelWeight = _newChannelWeight;

        channels[msg.sender] = channelData;
        swapAndTransferPUSH(msg.sender, totalRefundableAmount);
        emit DeactivateChannel(msg.sender, totalRefundableAmount);
    }

    /**
     * @notice Allows Channel Owner to Reactivate his/her Channel again.
     * @dev    - Function can only be called by previously Deactivated Channels
     *         - Channel Owner must Depost at least minimum amount of DAI to reactivate his/her channel.
     *         - Deposited Dai goes thorugh similar procedure and is deposited to AAVE .
     *         - Calculation of the new Channel Weight is performed and the FairShare is Readjusted once again with relevant details
     *         - Updates the State of the Channel(channelState) in the Channel's Struct.
     * @param _amount Amount of Dai to be deposited
     **/

    function reactivateChannel(uint256 _amount)
        external
        onlyDeactivatedChannels(msg.sender)
    {
        require(
            _amount >= ADD_CHANNEL_MIN_POOL_CONTRIBUTION,
            "EPNSCoreV1::reactivateChannel: Insufficient Funds Passed for Channel Reactivation"
        );
        IERC20(daiAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _depositFundsToPool(_amount);

        uint256 _channelWeight = _amount.mul(ADJUST_FOR_FLOAT).div(
            ADD_CHANNEL_MIN_POOL_CONTRIBUTION
        );
        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _channelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channels[msg.sender].channelState = 1;
        channels[msg.sender].channelWeight = _channelWeight;

        emit ReactivateChannel(msg.sender, _amount);
    }

    /**
     * @notice ALlows the pushChannelAdmin to Block any particular channel Completely.
     *
     * @dev    - Can only be called by pushChannelAdmin
     *         - Can only be Called for Activated Channels
     *         - Can only Be Called for NON-BLOCKED Channels
     *
     *         - Updates channel's state to BLOCKED ('3')
     *         - Updates Channel's Pool Contribution to ZERO
     *         - Updates Channel's Weight to ZERO
     *         - Increases the Protocol Fee Pool
     *         - Decreases the Channel Count
     *         - Readjusts the FS Ratio
     *         - Emit 'ChannelBlocked' Event
     * @param _channelAddress Address of the Channel to be blocked
     **/

     function blockChannel(address _channelAddress)
     external
     onlyPushChannelAdmin()
     onlyUnblockedChannels(_channelAddress){
       Channel memory channelData = channels[_channelAddress];

       uint256 totalAmountDeposited = channelData.poolContribution;
       uint256 totalRefundableAmount = totalAmountDeposited.sub(
           CHANNEL_DEACTIVATION_FEES
       );

       uint256 _newChannelWeight = CHANNEL_DEACTIVATION_FEES
           .mul(ADJUST_FOR_FLOAT)
           .div(ADD_CHANNEL_MIN_POOL_CONTRIBUTION);

       channelsCount = channelsCount.sub(1);

       channelData.channelState = 3;
       channelData.channelWeight = _newChannelWeight;
       channelData.channelUpdateBlock = block.number;
       channelData.poolContribution = CHANNEL_DEACTIVATION_FEES;
       PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(totalRefundableAmount);
       (
           groupFairShareCount,
           groupNormalizedWeight,
           groupHistoricalZ,
           groupLastUpdate
       ) = _readjustFairShareOfChannels(
           ChannelAction.ChannelRemoved,
           _newChannelWeight,
           groupFairShareCount,
           groupNormalizedWeight,
           groupHistoricalZ,
           groupLastUpdate
       );

       channels[_channelAddress] = channelData;
       emit ChannelBlocked(_channelAddress);
     }

    /* **************
    => CHANNEL VERIFICATION FUNCTIONALTIES <=
    *************** */

    /**
     * @notice    Function is designed to tell if a channel is verified or not
     * @dev       Get if channel is verified or not
     * @param    _channel Address of the channel to be Verified
     * @return   verificationStatus  Returns 0 for not verified, 1 for primary verification, 2 for secondary verification
     **/
    function getChannelVerfication(address _channel)
      public
      view
      returns (uint8 verificationStatus)
    {
      address verifiedBy = channels[_channel].verifiedBy;
      bool logicComplete = false;

      // Check if it's primary verification
      if (verifiedBy == pushChannelAdmin || _channel == address(0x0) || _channel == pushChannelAdmin) {
        // primary verification, mark and exit
        verificationStatus = 1;
        logicComplete = true;
      }
      else {
        // can be secondary verification or not verified, dig deeper
        while (!logicComplete) {
          if (verifiedBy == address(0x0)) {
            verificationStatus = 0;
            logicComplete = true;
          }
          else if (verifiedBy == pushChannelAdmin) {
            verificationStatus = 2;
            logicComplete = true;
          }
          else {
            // Upper drill exists, go up
            verifiedBy = channels[verifiedBy].verifiedBy;
          }
        }
      }
    }

    /**
     * @notice    Function is designed to verify a channel
     * @dev       Channel will be verified by primary or secondary verification, will fail or upgrade if already verified
     * @param    _channel Address of the channel to be Verified
     **/
    function verifyChannel(address _channel) external onlyActivatedChannels(_channel) {
      // Check if caller is verified first
      uint8 callerVerified = getChannelVerfication(msg.sender);
      require(callerVerified > 0, "EPNSCoreV1::verifyChannel: Caller is not verified");

      // Check if channel is verified
      uint8 channelVerified = getChannelVerfication(_channel);
      require(
        (callerVerified >= 1 && channelVerified == 0) ||
        (msg.sender == pushChannelAdmin),
        "EPNSCoreV1::verifyChannel: Channel already verified"
      );

      // Verify channel
      channels[_channel].verifiedBy = msg.sender;

      // Emit event
      emit ChannelVerified(_channel, msg.sender);
    }

    /**
     * @notice    Function is designed to unverify a channel
     * @dev       Channel who verified this channel or Push Channel Admin can only revoke
     * @param    _channel Address of the channel to be unverified
     **/
    function unverifyChannel(address _channel) external {
      require(
        channels[_channel].verifiedBy == msg.sender || msg.sender == pushChannelAdmin,
        "EPNSCoreV1::unverifyChannel: Only channel who verified this or Push Channel Admin can revoke"
      );

      // Unverify channel
      channels[_channel].verifiedBy = address(0x0);

      // Emit Event
      emit ChannelVerificationRevoked(_channel, msg.sender);
    }

    /* **************

    => DEPOSIT & WITHDRAWAL of FUNDS<=

    *************** */
    /**
     * @notice  Function is used for Handling the entire procedure of Depositing the DAI to Lending POOl
     *
     * @dev     Updates the Relevant state variable during Deposit of DAI
     *          Lends the DAI to AAVE protocol.
     * @param   amount - Amount that is to be deposited
     **/
    function _depositFundsToPool(uint256 amount) private {
        POOL_FUNDS = POOL_FUNDS.add(amount);

        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
            lendingPoolProviderAddress
        );
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        IERC20(daiAddress).approve(provider.getLendingPoolCore(), amount);
        // Deposit to AAVE
        lendingPool.deposit(daiAddress, amount, uint16(REFERRAL_CODE)); // set to 0 in constructor presently
    }

    /**
     * @notice Swaps aDai to PUSH Tokens and Transfers to the USER Address
     *
     * @param _user address of the user that will recieve the PUSH Tokens
     * @param _userAmount the amount of aDai to be swapped and transferred
     **/
    function swapAndTransferPUSH(address _user, uint256 _userAmount)
        internal
        returns (bool)
    {
        swapADaiForDai(_userAmount);
        IERC20(daiAddress).approve(UNISWAP_V2_ROUTER, _userAmount);

        address[] memory path = new address[](3);
        path[0] = daiAddress;
        path[1] = WETH_ADDRESS;
        path[2] = PUSH_TOKEN_ADDRESS;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _userAmount,
            1,
            path,
            _user,
            block.timestamp
        );
        return true;
    }

    function swapADaiForDai(uint256 _amount) private{
      ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
        lendingPoolProviderAddress
      );
      ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
      IERC20(aDaiAddress).approve(provider.getLendingPoolCore(), _amount);

      IADai(aDaiAddress).redeem(_amount);
    }

    /**
     * @notice Function to claim Rewards generated for indivudual users
     * NOTE   The EPNSCore Protocol must be approved as a Delegtate for Resetting the HOLDER's WEIGHT on PUSH Token Contract.
     *
     * @dev - Gets the User's Holder weight from the PUSH token contract
     *      - Gets the totalSupply and Start Block of PUSH Token
     *      - Calculates the totalHolder weight w.r.t to the current block number
     *      - Gets the ratio of token holder by dividing individual User's weight tp totalWeight (also adjusts for the FLOAT)
     *      - Gets the Total ADAI Interest accumulated for the protocol
     *      - Calculates the amount the User should recieve considering the user's ratio calculated before
     *      - The claim function resets the Holder's Weight on the PUSH Contract by setting it to the current block.number
     *      - The Claimable ADAI Amount amount is SWapped for PUSH Tokens.
     *      - The PUSH token is then transferred to the USER as the interest.
    **/
    function claimInterest() external returns(bool success){
      address _user = msg.sender;
      // Reading necessary PUSH details
      uint pushStartBlock = IPUSH(PUSH_TOKEN_ADDRESS).born();
      uint pushTotalSupply = IPUSH(PUSH_TOKEN_ADDRESS).totalSupply();
      uint256 userHolderWeight = IPUSH(PUSH_TOKEN_ADDRESS).returnHolderUnits(_user, block.number);

      // Calculating total holder weight at the current Block Number
      uint blockGap = block.number.sub(pushStartBlock);
      uint totalHolderWeight = pushTotalSupply.mul(blockGap);

      //Calculating individual User's Ratio
      uint userRatio = userHolderWeight.mul(ADJUST_FOR_FLOAT).div(totalHolderWeight);

      // Calculating aDai Interest Generated and CLaimable Amount
      uint256 aDaiBalanceWithInterest = IADai(aDaiAddress).balanceOf(address(this));
      uint256 totalADAIInterest = aDaiBalanceWithInterest.sub(POOL_FUNDS);
      uint256 totalClaimableRewards = totalADAIInterest.mul(userRatio).div(ADJUST_FOR_FLOAT).div(100);
      require(totalClaimableRewards > 0, "EPNSCoreV1::claimInterest: No Claimable Rewards at the Moment");

      // Reset the User's Weight and Transfer the Tokens
      IPUSH(PUSH_TOKEN_ADDRESS).resetHolderWeight(_user);
      usersInterestClaimed[_user] = usersInterestClaimed[_user].add(totalClaimableRewards);
      swapAndTransferPUSH(_user, totalClaimableRewards);

      emit InterestClaimed(msg.sender, totalClaimableRewards);
      success = true;
    }

    /* **************

    => FAIR SHARE RATIO CALCULATIONS <=

    *************** */
    /**
     * @notice  Helps keeping trakc of the FAIR Share Details whenever a specific Channel Action occur
     * @dev     Updates some of the imperative Fair Share Data based whenever a paricular channel action is performed.
     *          Takes into consideration 3 major Channel Actions, i.e., Channel Creation, Channel Removal or Channel Deactivation/Reactivation.
     *
     * @param _action                 The type of Channel action for which the Fair Share is being adjusted
     * @param _channelWeight          Weight of the channel on which the Action is being performed.
     * @param _groupFairShareCount    Fair share count
     * @param _groupNormalizedWeight  Normalized weight value
     * @param _groupHistoricalZ       The Historical Constant - Z
     * @param _groupLastUpdate        Holds the block number of the last update.
     **/
    function _readjustFairShareOfChannels(
        ChannelAction _action,
        uint256 _channelWeight,
        uint256 _groupFairShareCount,
        uint256 _groupNormalizedWeight,
        uint256 _groupHistoricalZ,
        uint256 _groupLastUpdate
    )
        private
        view
        returns (
            uint256 groupNewCount,
            uint256 groupNewNormalizedWeight,
            uint256 groupNewHistoricalZ,
            uint256 groupNewLastUpdate
        )
    {
        // readjusts the group count and do deconstruction of weight
        uint256 groupModCount = _groupFairShareCount;
        uint256 prevGroupCount = groupModCount;

        uint256 totalWeight;
        uint256 adjustedNormalizedWeight = _groupNormalizedWeight; //_groupNormalizedWeight;

        // Increment or decrement count based on flag
        if (_action == ChannelAction.ChannelAdded) {
            groupModCount = groupModCount.add(1);
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.add(_channelWeight);

        } else if (_action == ChannelAction.ChannelRemoved) {
            groupModCount = groupModCount.sub(1);
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount);
            totalWeight = totalWeight.sub(_channelWeight);

        } else if (_action == ChannelAction.ChannelUpdated) {
            totalWeight = adjustedNormalizedWeight.mul(prevGroupCount.sub(1));
            totalWeight = totalWeight.add(_channelWeight);

        } else {
            revert("EPNSCoreV1::_readjustFairShareOfChannels: Invalid Channel Action");
        }
        // now calculate the historical constant
        // z = z + nxw
        // z is the historical constant
        // n is the previous count of group fair share
        // x is the differential between the latest block and the last update block of the group
        // w is the normalized average of the group (ie, groupA weight is 1 and groupB is 2 then w is (1+2)/2 = 1.5)
        uint256 n = groupModCount;
        uint256 x = block.number.sub(_groupLastUpdate);
        uint256 w = totalWeight.div(groupModCount);
        uint256 z = _groupHistoricalZ;

        uint256 nx = n.mul(x);
        uint256 nxw = nx.mul(w);

        // Save Historical Constant and Update Last Change Block
        z = z.add(nxw);

        if (n == 1) {
            // z should start from here as this is first channel
            z = 0;
        }

        // Update return variables
        groupNewCount = groupModCount;
        groupNewNormalizedWeight = w;
        groupNewHistoricalZ = z;
        groupNewLastUpdate = block.number;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

/**
 * EPNS Communicator, as the name suggests, is more of a Communictation Layer
 * between END USERS and EPNS Core Protocol.
 * The Communicator Protocol is comparatively much simpler & involves basic
 * details, specifically about the USERS of the Protocols

 * Some imperative functionalities that the EPNS Communicator Protocol allows
 * are Subscribing to a particular channel, Unsubscribing a channel, Sending
 * Notifications to a particular recipient or all subscribers of a Channel etc.
**/

// Essential Imports
// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EPNSCommV1 is Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice User Struct that involves imperative details about
     * a specific User.
     **/
    struct User {
        // @notice Depicts whether or not a user is ACTIVE
        bool userActivated;

        // @notice Will be false until public key is emitted
        bool publicKeyRegistered;

        // @notice Events should not be polled before this block as user doesn't exist
        uint256 userStartBlock;

        // @notice Keep track of subscribers
        uint256 subscribedCount;

        /**
         * Depicts if User subscribed to a Specific Channel Address
         * 1 -> User is Subscribed
         * 0 -> User is NOT SUBSCRIBED
         **/
        mapping(address => uint8) isSubscribed;

        // Keeps track of all subscribed channels
        mapping(address => uint256) subscribed;
        mapping(uint256 => address) mapAddressSubscribed;
    }

    /** MAPPINGS **/
    mapping(address => User) public users;
    mapping(address => uint256) public nonces;
    mapping(uint256 => address) public mapAddressUsers;
    mapping(address => mapping(address => string)) public userToChannelNotifs;
    mapping(address => mapping(address => bool)) public delegatedNotificationSenders;

    /** STATE VARIABLES **/
    address public governance;
    address public pushChannelAdmin;
    uint256 public usersCount;
    bool public isMigrationComplete;
    address public EPNSCoreAddress;
    string public constant name = "EPNS COMM V1";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSCRIBE_TYPEHASH =
        keccak256("Subscribe(address channel,uint256 nonce,uint256 expiry)");
    bytes32 public constant UNSUBSCRIBE_TYPEHASH =
        keccak256("Unsubscribe(address channel,uint256 nonce,uint256 expiry)");
    bytes32 public constant SEND_NOTIFICATION_TYPEHASH =
        keccak256(
            "SendNotification(address channel,address delegate,address recipient,bytes identity,uint256 nonce,uint256 expiry)"
        );
    /** EVENTS **/
    event SendNotification(
        address indexed channel,
        address indexed recipient,
        bytes identity
    );
    event UserNotifcationSettingsAdded(
        address _channel,
        address _user,
        uint256 _notifID,
        string _notifSettings
    );
    event AddDelegate(address channel, address delegate);
    event RemoveDelegate(address channel, address delegate);
    event Subscribe(address indexed channel, address indexed user);
    event Unsubscribe(address indexed channel, address indexed user);
    event PublicKeyRegistered(address indexed owner, bytes publickey);

    /** MODIFIERS **/

    modifier onlyPushChannelAdmin() {
        require(msg.sender == pushChannelAdmin, "EPNSCommV1::onlyPushChannelAdmin: user not pushChannelAdmin");
        _;
    }

    modifier onlyEPNSCore() {
        require(msg.sender == EPNSCoreAddress, "EPNSCommV1::onlyEPNSCore: Caller NOT EPNSCore");
        _;
    }

    modifier sendNotifViaSignReq(
        address _channel,
        address _notificationSender,
        address _recipient,
        address signatory
    ) {
        require(
            (_channel == signatory) ||
                (delegatedNotificationSenders[_channel][_notificationSender] &&
                    _notificationSender == signatory) ||
                (_recipient == signatory),
            "EPNSCommV1::sendNotifViaSignReq: Invalid Channel, Delegate Or Subscriber"
        );
        _;
    }

    /* ***************

        INITIALIZER

    *************** */
    function initialize(address _pushChannelAdmin) public initializer returns (bool) {
        pushChannelAdmin = _pushChannelAdmin;
        governance = pushChannelAdmin;
        return true;
    }

    /****************

    => SETTER FUNCTIONS <=

    ****************/

    function completeMigration() external onlyPushChannelAdmin{
        isMigrationComplete = true;
    }

    function setEPNSCoreAddress(address _coreAddress) external onlyPushChannelAdmin {
        EPNSCoreAddress = _coreAddress;
    }

    function setGovernanceAddress(address _governanceAddress) external onlyPushChannelAdmin{
      governance = _governanceAddress;
    }

    function transferPushChannelAdminControl(address _newAdmin) public onlyPushChannelAdmin {
        require(_newAdmin != address(0), "EPNSCommV1::transferPushChannelAdminControl: Invalid Address");
        require(_newAdmin != pushChannelAdmin, "EPNSCommV1::transferPushChannelAdminControl: Admin address is same");
        pushChannelAdmin = _newAdmin;
    }

    /****************

    => SUBSCRIBE FUNCTIOANLTIES <=

    ****************/

    /**
     * @notice Helper function to check if User is Subscribed to a Specific Address
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber
     * @return isSubscriber True if User is actually a subscriber of a Channel
     **/
    function isUserSubscribed(address _channel, address _user)
        public
        view
        returns (bool isSubscriber)
    {
        User storage user = users[_user];
        if (user.isSubscribed[_channel] == 1) {
            isSubscriber = true;
        }
    }

    /**
     * @notice External Subscribe Function that allows users to Diretly interact with the Base Subscribe function
     * @dev   Subscribes the caller of the function to a particular Channel
     *        Takes into Consideration the "msg.sender"
     * @param _channel address of the channel that the user is subscribing to
     **/
    function subscribe(address _channel) external returns (bool) {
        _subscribe(_channel, msg.sender);
        return true;
    }

    /**
     * @notice Allows users to subscribe a List of Channels at once
     *
     * @param _channelList array of addresses of the channels that the user wishes to Subscribe
     **/
    function batchSubscribe(address[] calldata _channelList)
        external
        returns (bool)
    {
        for (uint256 i = 0; i < _channelList.length; i++) {
            _subscribe(_channelList[i], msg.sender);
        }
        return true;
    }

    /**
     * @notice This Function helps in migrating the already existing Subscriber's data to the New protocol
     *
     * @dev     Can only be called by pushChannelAdmin
     *          Can only be called if the Migration is not yet complete, i.e., "isMigrationComplete" boolean must be false
     *          Subscribes the Users to the respective Channels as per the arguments passed to the function
     *
     * @param _startIndex  starting Index for the LOOP
     * @param _endIndex    Last Index for the LOOP
     * @param _channelList array of addresses of the channels
     * @param _usersList   array of addresses of the Users or Subscribers of the Channels
     **/

    function migrateSubscribeData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelList,
        address[] calldata _usersList
    ) external onlyPushChannelAdmin returns (bool) {
        require(
            !isMigrationComplete,
            "EPNSCommV1::migrateSubscribeData: Migration of Subscribe Data is Complete Already"
        );
        require(
            _channelList.length == _usersList.length,
            "EPNSCommV1::migrateSubscribeData: Unequal Arrays passed as Argument"
        );

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            if(isUserSubscribed(_channelList[i], _usersList[i])){
                continue;
            }else{
                _subscribe(_channelList[i], _usersList[i]);
            }
        }
        return true;
    }

    /**
     * @notice Base Subscribe Function that allows users to Subscribe to a Particular Channel
     *
     * @dev Initializes the User Struct with crucial details about the Channel Subscription
     *      Addes the caller as a an Activated User of the protocol. (Only if the user hasn't been added already)
     *
     * @param _channel address of the channel that the user is subscribing to
     * @param _user    address of the Subscriber
     **/
    function _subscribe(address _channel, address _user) private {
        require(
            !isUserSubscribed(_channel, _user),
            "EPNSCommV1::_subscribe: User already Subscribed"
        );

        _addUser(_user);

        User storage user = users[_user];

        user.isSubscribed[_channel] = 1;
        // treat the count as index and update user struct
        user.subscribed[_channel] = user.subscribedCount;
        user.mapAddressSubscribed[user.subscribedCount] = _channel;
        user.subscribedCount = user.subscribedCount.add(1); // Finally increment the subscribed count
        // Emit it
        emit Subscribe(_channel, _user);
    }

    /**
     * @notice Subscribe Function through Meta TX
     * @dev Takes into Consideration the Sign of the User
     **/
    function subscribeBySig(
        address channel,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(SUBSCRIBE_TYPEHASH, channel, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EPNSCommV1::subscribeBySig: Invalid signature");
        require(nonce == nonces[signatory]++, "EPNSCommV1::subscribeBySig: Invalid nonce");
        require(now <= expiry, "EPNSCommV1::subscribeBySig: Signature expired");
        _subscribe(channel, signatory);
    }

    /**
     * @notice Allows EPNSCore contract to call the Base Subscribe function whenever a User Creates his/her own Channel.
     *         This ensures that the Channel Owner is subscribed to imperative EPNS Channels as well as his/her own Channel.
     *
     * @dev    Only Callable by the EPNSCore. This is to ensure that Users should only able to Subscribe for their own addresses.
     *         The caller of the main Subscribe function should Either Be the USERS themselves(for their own addresses) or the EPNSCore contract
     *
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber of a Channel
     **/
    function subscribeViaCore(address _channel, address _user)
        external
        onlyEPNSCore
        returns (bool)
    {
        _subscribe(_channel, _user);
        return true;
    }

    /****************

    => USUBSCRIBE FUNCTIOANLTIES <=

    ****************/

    /**
     * @notice External Unsubcribe Function that allows users to directly unsubscribe from a particular channel
     *
     * @dev UnSubscribes the caller of the function from the particular Channel.
     *      Takes into Consideration the "msg.sender"
     *
     * @param _channel address of the channel that the user is subscribing to
     **/
    function unsubscribe(address _channel) external returns (bool){
        // Call actual unsubscribe
        _unsubscribe(_channel, msg.sender);
        return true;
    }

    /**
     * @notice Allows users to unsubscribe from a List of Channels at once
     *
     * @param _channelList array of addresses of the channels that the user wishes to Unsubscribe
     **/
    function batchUnsubscribe(address[] calldata _channelList)
        external
        returns (bool)
    {
        for (uint256 i = 0; i < _channelList.length; i++) {
            _unsubscribe(_channelList[i], msg.sender);
        }
        return true;
    }

    /**
     * @notice Base Usubscribe Function that allows users to UNSUBSCRIBE from a Particular Channel
     * @dev Modifies the User Struct with crucial details about the Channel Unsubscription
     * @param _channel address of the channel that the user is subscribing to
     * @param _user address of the Subscriber
     **/
    function _unsubscribe(address _channel, address _user) private {
        require(
            isUserSubscribed(_channel, _user),
            "EPNSCommV1::_unsubscribe: User not subscribed to channel"
        );
        // Add the channel to gray list so that it can't subscriber the user again as delegated
        User storage user = users[_user];

        user.isSubscribed[_channel] = 0;
        // Remove the mappings and cleanup
        // a bit tricky, swap and delete to maintain mapping
        // Remove From Users mapping
        // Find the id of the channel and swap it with the last id, use channel.memberCount as index
        // Slack too deep fix
        // address usrSubToSwapAdrr = user.mapAddressSubscribed[user.subscribedCount];
        // uint usrSubSwapID = user.subscribed[_channel];

        // // swap to last one and then
        // user.subscribed[usrSubToSwapAdrr] = usrSubSwapID;
        // user.mapAddressSubscribed[usrSubSwapID] = usrSubToSwapAdrr;

        user.subscribed[user.mapAddressSubscribed[user.subscribedCount]] = user
            .subscribed[_channel];
        user.mapAddressSubscribed[user.subscribed[_channel]] = user
            .mapAddressSubscribed[user.subscribedCount];

        // delete the last one and substract
        delete (user.subscribed[_channel]);
        delete (user.mapAddressSubscribed[user.subscribedCount]);
        user.subscribedCount = user.subscribedCount.sub(1);

        // Emit it
        emit Unsubscribe(_channel, _user);
    }

    /**
     * @notice Unsubscribe Function through Meta TX
     * @dev Takes into Consideration the Signer of the transactioner
     **/
    function unsubscribeBySig(
        address channel,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(UNSUBSCRIBE_TYPEHASH, channel, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EPNSCommV1::unsubscribeBySig: Invalid signature");
        require(nonce == nonces[signatory]++, "EPNSCommV1::unsubscribeBySig: Invalid nonce");
        require(now <= expiry, "EPNSCommV1::unsubscribeBySig: Signature expired");
        _unsubscribe(channel, signatory);
    }

    /* **************

    => PUBLIC KEY BROADCASTING & USER ADDING FUNCTIONALITIES <=

    *************** */

    /**
     * @notice Activates/Adds a particular User's Address in the Protocol.
     *         Keeps track of the Total User Count
     * @dev   Executes its main actions only if the User is not activated yet.
     *        Does nothing if an address has already been added.
     *
     * @param _user address of the user
     * @return userAlreadyAdded returns whether or not a user is already added.
     **/
    function _addUser(address _user) private returns (bool userAlreadyAdded) {
        if (users[_user].userActivated) {
            userAlreadyAdded = true;
        } else {
            // Activates the user
            users[_user].userStartBlock = block.number;
            users[_user].userActivated = true;
            mapAddressUsers[usersCount] = _user;

            usersCount = usersCount.add(1);
        }
    }

    /* @dev Internal system to handle broadcasting of public key,
     *     A entry point for subscribe, or create channel but is optional
     */
    function _broadcastPublicKey(address _userAddr, bytes memory _publicKey)
        private
    {
        // Add the user, will do nothing if added already, but is needed before broadcast
        _addUser(_userAddr);

        // get address from public key
        address userAddr = getWalletFromPublicKey(_publicKey);

        if (_userAddr == userAddr) {
            // Only change it when verification suceeds, else assume the channel just wants to send group message
            users[userAddr].publicKeyRegistered = true;

            // Emit the event out
            emit PublicKeyRegistered(userAddr, _publicKey);
        } else {
            revert("Public Key Validation Failed");
        }
    }

    /// @dev Don't forget to add 0x into it
    function getWalletFromPublicKey(bytes memory _publicKey)
        public
        pure
        returns (address wallet)
    {
        if (_publicKey.length == 64) {
            wallet = address(uint160(uint256(keccak256(_publicKey))));
        } else {
            wallet = 0x0000000000000000000000000000000000000000;
        }
    }

    /// @dev Performs action by the user themself to broadcast their public key
    function broadcastUserPublicKey(bytes calldata _publicKey) external {
        // Will save gas
        if (users[msg.sender].publicKeyRegistered) {
            // Nothing to do, user already registered
            return;
        }

        // broadcast it
        _broadcastPublicKey(msg.sender, _publicKey);
    }

    /* **************

    => SEND NOTIFICATION FUNCTIONALITIES <=

    *************** */

    /**
     * @notice Allows a Channel Owner to ADD a Delegate for sending Notifications
     *         Delegate shall be able to send Notification on the Channel's Behalf
     * @dev    This function will be only be callable by the Channel Owner from the EPNSCore contract.
     * NOTE:   Verification of whether or not a Channel Address is actually the owner of the Channel, will be done via the PUSH NODES.
     *
     * @param _delegate address of the delegate who is allowed to Send Notifications
     **/
    function addDelegate(address _delegate) external {
        delegatedNotificationSenders[msg.sender][_delegate] = true;
        emit AddDelegate(msg.sender, _delegate);
    }

    /**
     * @notice Allows a Channel Owner to Remove a Delegate's Permission to Send Notification
     * @dev    This function will be only be callable by the Channel Owner from the EPNSCore contract.
     * NOTE:   Verification of whether or not a Channel Address is actually the owner of the Channel, will be done via the PUSH NODES.
     * @param _delegate address of the delegate who is allowed to Send Notifications
     **/
    function removeDelegate(address _delegate) external {
        delegatedNotificationSenders[msg.sender][_delegate] = false;
        emit RemoveDelegate(msg.sender, _delegate);
    }

    /***
      THREE main CALLERS for this function-
        1. Channel Owner sends Notif to all Subscribers / Subset of Subscribers / Individual Subscriber
        2. Delegatee of Channel sends Notif to Recipients
        3. User sends Notifs to Themselvs via a Channel
           NOTE: A user can only send notification to their own address
    <---------------------------------------------------------------------------------------------->
     * When a CHANNEL OWNER Calls the Function and sends a Notif:
     *    -> We ensure -> "Channel Owner Must be Valid" && "Channel Owner is the Caller"
     *    -> NOTE - Validation of wether or not an address is a CHANNEL, is done via PUSH NODES
     *
     * When a Delegatee wants to send Notif to Recipient:
     *   -> We ensure "Delegate is the Caller" && "Delegatee is Approved by Chnnel Owner"
     *
     * When User wants to Send a Notif to themselves:
     *  ->  We ensure "Caller of the Function is the Recipient of the Notification"
    **/

    function _checkNotifReq
    (
      address _channel,
      address _notificationSender,
      address _recipient
    ) private view
    {
      require(
          (_channel == 0x0000000000000000000000000000000000000000 &&
              msg.sender == pushChannelAdmin) ||
              (_channel == msg.sender) ||
              (delegatedNotificationSenders[_channel][_notificationSender] &&
                  msg.sender == _notificationSender) ||
              (_recipient == msg.sender),
          "EPNSCommV1::_checkNotifReq: Invalid Channel, Delegate or Subscriber"
      );
    }
    /**
     * @notice Allows a Channel Owners, Delegates as well as Users to send Notifications
     * @dev Emits out notification details once all the requirements are passed.
     * @param _channel address of the Channel
     * @param _delegate address of the delegate who is allowed to Send Notifications
     * @param _recipient address of the reciever of the Notification
     * @param _identity Info about the Notification
     **/
    function sendNotification(
        address _channel,
        address _delegate,
        address _recipient,
        bytes memory _identity
    ) public{
        _checkNotifReq(_channel, _delegate, _recipient);
        // Emit the message out
        emit SendNotification(_channel, _recipient, _identity);
    }

    /**
     * @notice Base Notification Function that Allows a Channel Owners, Delegates as well as Users to send Notifications
     *
     * @dev   Specifically designed to be called via the EIP 712 send notif function.
     *        Takes into consideration the Signatory address to perform all the imperative checks
     *
     * @param _channel address of the Channel
     * @param _delegate address of the delegate who is allowed to Send Notifications
     * @param _recipient address of the reciever of the Notification
     * @param _signatory address of the SIGNER of the Send Notif Function call transaction
     * @param _identity Info about the Notification
     **/
    function _sendNotification(
        address _channel,
        address _delegate,
        address _recipient,
        address _signatory,
        bytes calldata _identity
    )
        private
        sendNotifViaSignReq(
            _channel,
            _delegate,
            _recipient,
            _signatory
        )
    {
        // Emit the message out
        emit SendNotification(_channel, _recipient, _identity);
    }

    /**
     * @notice Meta transaction function for Sending Notifications
     * @dev   Allows the Caller to Simply Sign the transaction to initiate the Send Notif Function
     **/

    function sendNotifBySig(
        address _channel,
        address _delegate,
        address _recipient,
        bytes calldata _identity,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                SEND_NOTIFICATION_TYPEHASH,
                _channel,
                _delegate,
                _recipient,
                _identity,
                nonce,
                expiry
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EPNSCommV1::sendNotifBySig: Invalid signature");
        require(nonce == nonces[signatory]++, "EPNSCommV1::sendNotifBySig: Invalid nonce");
        require(now <= expiry, "EPNSCommV1::sendNotifBySig: Signature expired");
        _sendNotification(
            _channel,
            _delegate,
            _recipient,
            signatory,
            _identity
        );
    }

    /* **************

    => User Notification Settings Function <=
    *************** */

    /**
     * @notice  Allows Users to Create and Subscribe to a Specific Notication Setting for a Channel.
     * @dev     Updates the userToChannelNotifs mapping to keep track of a User's Notification Settings for a Specific Channel
     *
     *          Deliminated Notification Settings string contains -> Decimal Representation Notif Settings + Notification Settings
     *          For instance, for a Notif Setting that looks like -> 3+1-0+2-0+3-1+4-98
     *          3 -> Decimal Representation of the Notification Options selected by the User
     *
     *          For Boolean Type Notif Options
     *          1-0 -> 1 stands for Option 1 - 0 Means the user didn't choose that Notif Option.
     *          3-1 stands for Option 3      - 1 Means the User Selected the 3rd boolean Option
     *
     *          For SLIDER TYPE Notif Options
     *          2-0 -> 2 stands for Option 2 - 0 is user's Choice
     *          4-98-> 4 stands for Option 4 - 98is user's Choice
     *
     * @param   _channel - Address of the Channel for which the user is creating the Notif settings
     * @param   _notifID- Decimal Representation of the Options selected by the user
     * @param   _notifSettings - Deliminated string that depicts the User's Notifcation Settings
     *
     **/

    function changeUserChannelSettings(
        address _channel,
        uint256 _notifID,
        string calldata _notifSettings
    ) external {
        require(
            isUserSubscribed(_channel, msg.sender),
            "EPNSCommV1::changeUserChannelSettings: User not Subscribed to Channel"
        );
        string memory notifSetting = string(
            abi.encodePacked(Strings.toString(_notifID), "+", _notifSettings)
        );
        userToChannelNotifs[msg.sender][_channel] = notifSetting;
        emit UserNotifcationSettingsAdded(
            _channel,
            msg.sender,
            _notifID,
            notifSetting
        );
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 *Submitted for verification at Etherscan.io on 2020-02-28
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
abstract contract MintableERC20 is ERC20 {
    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(msg.sender, value);
        return true;
    }
}

contract MockDAI is MintableERC20 {
    constructor () ERC20("DAI", "DAI") public {}
}

