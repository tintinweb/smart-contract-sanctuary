// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./upgradableProxy.sol";

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
    constructor(address _logic, address _admin, address _incognito, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        assert(_SUCCESSOR_SLOT == bytes32(uint256(keccak256("eip1967.proxy.successor")) - 1));
        assert(_PAUSED_SLOT == bytes32(uint256(keccak256("eip1967.proxy.paused")) - 1));
        assert(_INCOGNITO_SLOT == bytes32(uint256(keccak256("eip1967.proxy.incognito.")) - 1));
        _setAdmin(_admin);
        _setIncognito(_incognito);
    }

    /**
     * @dev Emitted when the successor account has changed.
     */
    event SuccessorChanged(address previousSuccessor, address newSuccessor);
    
    /**
     * @dev Emitted when the incognito proxy has changed.
     */
    event IncognitoChanged(address previousIncognito, address newIncognito);

    /**
     * @dev Emitted when the successor claimed thronze.
     **/
    event Claim(address claimer);
    
    /**
     * @dev Emitted when the admin pause contract.
     **/
    event Paused(address admin);
    
    /**
     * @dev Emitted when the admin unpaused contract.
     **/
    event Unpaused(address admin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.successor" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _SUCCESSOR_SLOT = 0x7b13fc932b1063ca775d428558b73e20eab6804d4d9b5a148d7cbae4488973f8;

    /**
     * @dev Storage slot with status paused or not.
     * This is the keccak-256 hash of "eip1967.proxy.paused" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _PAUSED_SLOT = 0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450;
    
    /**
     * @dev Storage slot with the incognito proxy.
     * This is the keccak-256 hash of "eip1967.proxy.incognito." subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _INCOGNITO_SLOT = 0x62135fc083646fdb4e1a9d700e351b886a4a5a39da980650269edd1ade91ffd2;

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
    function admin() external ifAdmin returns (address) {
        return _admin();
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
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Returns the current successor.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x7b13fc932b1063ca775d428558b73e20eab6804d4d9b5a148d7cbae4488973f8`
     */
    function successor() external ifAdmin returns (address) {
        return _successor();
    }

    /**
     * @dev Returns the current paused value.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450`
     */
    function paused() external ifAdmin returns (bool) {
        return _paused();
    }
    
    /**
     * @dev Returns the current incognito proxy.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x6c1fc16c781d41e11abf5619c272a94b10ccafab380060da4bd63325467b854e`
     */
    function incognito() external ifAdmin returns (address) {
        return _incognito();
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success, "DELEGATECALL failed");
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
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
     * @dev Returns the current successor.
     */
    function _successor() internal view returns (address sor) {
        bytes32 slot = _SUCCESSOR_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sor := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 successor slot.
     */
    function _setSuccesor(address newSuccessor) private {
        bytes32 slot = _SUCCESSOR_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newSuccessor)
        }
    }

    /**
     * @dev Returns the current paused value.
     */
    function _paused() internal view returns (bool psd) {
        bytes32 slot = _PAUSED_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            psd := sload(slot)
        }
    }

    /**
     * @dev Stores a new paused value in the EIP1967 paused slot.
     */
    function _setPaused(bool psd) private {
        bytes32 slot = _PAUSED_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, psd)
        }
    }
    
    /**
     * @dev Returns the current incognito proxy.
     */
    function _incognito() internal view returns (address icg) {
        bytes32 slot = _INCOGNITO_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            icg := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 incognito proxy slot.
     */
    function _setIncognito(address newIncognito) private {
        bytes32 slot = _INCOGNITO_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newIncognito)
        }
    }

    /**
     * @dev Admin retire to prepare transfer thronze to successor.
     */
    function retire(address newSuccessor) external ifAdmin {
        require(newSuccessor != address(0), "TransparentUpgradeableProxy: successor is the zero address");
        emit SuccessorChanged(_successor(), newSuccessor);
        _setSuccesor(newSuccessor);
    }

    /**
     * @dev Successor claims thronze.
     */
    function claim() external {
        if (msg.sender == _successor()) {
            emit Claim(_successor());
            _setAdmin(_successor());
        } else{
            _fallback();
        }
    }
    
    /**
     * @dev Admin pause contract.
     */
    function pause() external ifAdmin {
        require(!_paused(), "TransparentUpgradeableProxy: contract paused already");
        _setPaused(true);
    }
    
    /**
     * @dev Admin unpause contract.
     */
    function unpause() external ifAdmin {
        require(_paused(), "TransparentUpgradeableProxy: contract not paused");
        _setPaused(false);
    }
    
     /**
     * @dev Admin upgrade incognito proxy.
     */
    function upgradeIncognito(address newIncognito) external ifAdmin {
        require(newIncognito != address(0), "TransparentUpgradeableProxy: incognito proxy is the zero address");
        emit IncognitoChanged(_incognito(), newIncognito);
        _setIncognito(newIncognito);
    }
    
    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal override virtual {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        require(!_paused(), "TransparentUpgradeableProxy: contract is paused");
        super._beforeFallback();
    }
}