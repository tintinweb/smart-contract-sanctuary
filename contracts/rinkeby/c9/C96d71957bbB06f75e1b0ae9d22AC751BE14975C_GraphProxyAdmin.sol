// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../governance/Governed.sol";

import "./IGraphProxy.sol";
import "./GraphUpgradeable.sol";

/** 
 * @title GraphProxyAdmin
 * @dev This is the owner of upgradeable proxy contracts.
 * Proxy contracts use a TransparentProxy pattern, any admin related call
 * like upgrading a contract or changing the admin needs to be send through
 * this contract.
 */
contract GraphProxyAdmin is Governed {

    /** 
     * @dev Contract constructor.
     */
    constructor() {
        Governed._initialize(msg.sender);
    }

    /**
     * @dev Returns the current implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @return The address of the current implementation of the proxy.
     */
    function getProxyImplementation(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the pending implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @return The address of the pending implementation of the proxy.
     */
    function getProxyPendingImplementation(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("pendingImplementation()")) == 0x396f7b23
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"396f7b23");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the admin of a proxy. Only the admin can query it.
     * @return The address of the current admin of the proxy.
     */
    function getProxyAdmin(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of a proxy.
     * @param _proxy Proxy to change admin.
     * @param _newAdmin Address to transfer proxy administration to.
     */
    function changeProxyAdmin(IGraphProxy _proxy, address _newAdmin) public onlyGovernor {
        _proxy.setAdmin(_newAdmin);
    }

    /**
     * @dev Upgrades a proxy to the newest implementation of a contract.
     * @param _proxy Proxy to be upgraded.
     * @param _implementation the address of the Implementation.
     */
    function upgrade(IGraphProxy _proxy, address _implementation) public onlyGovernor {
        _proxy.upgradeTo(_implementation);
    }

    /**
     * @dev Accepts a proxy.
     * @param _implementation Address of the implementation accepting the proxy.
     * @param _proxy Address of the proxy being accepted.
     */
    function acceptProxy(GraphUpgradeable _implementation, IGraphProxy _proxy) public onlyGovernor {
        _implementation.acceptProxy(_proxy);
    }

    /**
     * @dev Accepts a proxy and call a function on the implementation.
     * @param _implementation Address of the implementation accepting the proxy.
     * @param _proxy Address of the proxy being accepted.
     * @param _data Encoded function to call on the implementation after accepting the proxy.
     */
    function acceptProxyAndCall(
        GraphUpgradeable _implementation,
        IGraphProxy _proxy,
        bytes calldata _data
    ) external onlyGovernor {
        _implementation.acceptProxyAndCall(_proxy, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Graph Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
    // -- State --

    address public governor;
    address public pendingGovernor;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl {
        require(msg.sender == _implementation(), "Caller must be the implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Accept to be an implementation of proxy.
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @dev Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}