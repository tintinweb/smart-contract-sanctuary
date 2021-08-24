/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.6.0 <0.9.0;

pragma experimental ABIEncoderV2;

// File: contracts\patterns\Initializable.sol
interface Initializable {
    /// @dev Initialize contract's storage context.
    function initialize(bytes calldata) external;
}
// File: contracts\patterns\Proxiable.sol
interface Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() external pure returns (bytes32);
}
// File: contracts\patterns\Upgradable.sol
/* solhint-disable var-name-mixedcase */




abstract contract Upgradable is Initializable, Proxiable {

    address internal immutable _BASE;
    bytes32 internal immutable _CODEHASH;
    bool internal immutable _UPGRADABLE;

    /// Emitted every time the contract gets upgraded.
    /// @param from The address who ordered the upgrading. Namely, the WRB operator in "trustable" implementations.
    /// @param baseAddr The address of the new implementation contract.
    /// @param baseCodehash The EVM-codehash of the new implementation contract.
    /// @param versionTag Ascii-encoded version literal with which the implementation deployer decided to tag it.
    event Upgraded(
        address indexed from,
        address indexed baseAddr,
        bytes32 indexed baseCodehash,
        bytes32 versionTag
    );

    constructor (bool _isUpgradable) {
        address _base = address(this);
        bytes32 _codehash;        
        assembly {
            _codehash := extcodehash(_base)
        }
        _BASE = _base;
        _CODEHASH = _codehash;        
        _UPGRADABLE = _isUpgradable;
    }

    /// @dev Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address from) virtual external view returns (bool);


    /// TODO: the following methods should be all declared as pure 
    ///       whenever this Solidity's PR gets merged and released: 
    ///       https://github.com/ethereum/solidity/pull/10240

    /// @dev Retrieves base contract. Differs from address(this) when via delegate-proxy pattern.
    function base() public view returns (address) {
        return _BASE;
    }

    /// @dev Retrieves the immutable codehash of this contract, even if invoked as delegatecall.
    /// @return _codehash This contracts immutable codehash.
    function codehash() public view returns (bytes32 _codehash) {
        return _CODEHASH;
    }
    
    /// @dev Determines whether current instance allows being upgraded.
    /// @dev Returned value should be invariant from whoever is calling.
    function isUpgradable() public view returns (bool) {        
        return _UPGRADABLE;
    }

    /// @dev Retrieves human-redable named version of current implementation.
    function version() virtual public view returns (bytes32); 
}
// File: contracts\impls\WitnetProxy.sol
/// @title WitnetProxy: upgradable delegate-proxy contract that routes Witnet data requests coming from a 
/// `UsingWitnet`-inheriting contract to a currently active `WitnetRequestBoard` implementation. 
/// https://github.com/witnet/witnet-ethereum-bridge/tree/0.3.x
/// @author The Witnet Foundation.
contract WitnetProxy {

    struct WitnetProxySlot {
        address implementation;
    }

    /// Event emitted when a new DR is posted.
    event Upgraded(address indexed implementation);  

    /// Constructor with no params as to ease eventual support of Singleton pattern (i.e. ERC-2470).
    constructor () {}

    /// WitnetProxies will never accept direct transfer of ETHs.
    receive() external payable {
        revert("WitnetProxy: no transfers accepted");
    }

    /// Payable fallback accepts delegating calls to payable functions.  
    fallback() external payable { /* solhint-disable no-complex-fallback */
        address _implementation = implementation();

        assembly { /* solhint-disable avoid-low-level-calls */
            // Gas optimized delegate call to 'implementation' contract.
            // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
            //       to actual implementation of `msg.sig` within `implementation` contract.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
                case 0  { 
                    // pass back revert message:
                    revert(ptr, size) 
                }
                default {
                  // pass back same data as returned by 'implementation' contract:
                  return(ptr, size) 
                }
        }
    }

    /// Returns proxy's current implementation address.
    function implementation() public view returns (address) {
        return _proxySlot().implementation;
    }

    /// Upgrades the `implementation` address.
    /// @param _newImplementation New implementation address.
    /// @param _initData Raw data with which new implementation will be initialized.
    /// @return Returns whether new implementation would be further upgradable, or not.
    function upgradeTo(address _newImplementation, bytes memory _initData)
        public returns (bool)
    {
        // New implementation cannot be null:
        require(_newImplementation != address(0), "WitnetProxy: null implementation");

        address _oldImplementation = implementation();
        if (_oldImplementation != address(0)) {
            // New implementation address must differ from current one:
            require(_newImplementation != _oldImplementation, "WitnetProxy: nothing to upgrade");

            // Assert whether current implementation is intrinsically upgradable:
            try Upgradable(_oldImplementation).isUpgradable() returns (bool _isUpgradable) {
                require(_isUpgradable, "WitnetProxy: not upgradable");
            } catch {
                revert("WitnetProxy: unable to check upgradability");
            }

            // Assert whether current implementation allows `msg.sender` to upgrade the proxy:
            (bool _wasCalled, bytes memory _result) = _oldImplementation.delegatecall(
                abi.encodeWithSignature(
                    "isUpgradableFrom(address)",
                    msg.sender
                )
            );
            require(_wasCalled, "WitnetProxy: not compliant");
            require(abi.decode(_result, (bool)), "WitnetProxy: not authorized");
            require(
                Upgradable(_oldImplementation).proxiableUUID() == Upgradable(_newImplementation).proxiableUUID(),
                "WitnetProxy: proxiableUUIDs mismatch"
            );
        }

        // Initialize new implementation within proxy-context storage:
        (bool _wasInitialized,) = _newImplementation.delegatecall(
            abi.encodeWithSignature(
                "initialize(bytes)",
                _initData
            )
        );
        require(_wasInitialized, "WitnetProxy: unable to initialize");

        // If all checks and initialization pass, update implementation address:
        _proxySlot().implementation = _newImplementation;
        emit Upgraded(_newImplementation);

        // Asserts new implementation complies w/ minimal implementation of Upgradable interface:
        try Upgradable(_newImplementation).isUpgradable() returns (bool _isUpgradable) {
            return _isUpgradable;
        }
        catch {
            revert ("WitnetProxy: not compliant");
        }
    }

    /// @dev Complying with EIP-1967, retrieves storage struct containing proxy's current implementation address.
    function _proxySlot() private pure returns (WitnetProxySlot storage _slot) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            _slot.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }

}