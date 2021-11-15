// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

contract ArcProxy {

    /**
    * @dev Emitted when the implementation is upgraded.
    * @param implementation Address of the new implementation.
    */
    event Upgraded(address indexed implementation);

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

    /* solium-disable-next-line */
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Storage slot with the address of the current implementation.
    * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    * validated in the constructor.
    */

    /* solium-disable-next-line */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
    * Contract constructor.
    * @param _logic address of the initial implementation.
    * @param _admin Address of the proxy administrator.
    * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
    * It should include the signature and the parameters of the function to be called, as described in
    * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
    * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
    */
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    )
        public
        payable
    {
        assert(
            IMPLEMENTATION_SLOT == bytes32(
                uint256(keccak256("eip1967.proxy.implementation")) - 1
            )
        );

        _setImplementation(_logic);

        if (_data.length > 0) {
            /* solium-disable-next-line */
            (bool success,) = _logic.delegatecall(_data);
            /* solium-disable-next-line */
            require(success);
        }

        assert(
            ADMIN_SLOT == bytes32(
                uint256(keccak256("eip1967.proxy.admin")) - 1
            )
        );

        _setAdmin(_admin);
    }

    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    function () external payable {
        _fallback();
    }

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _delegate(_implementation());
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        /* solium-disable-next-line */
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
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        /* solium-disable-next-line */
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
    * @dev Returns the current implementation.
    * @return Address of the current implementation
    */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        /* solium-disable-next-line */
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
            isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        /* solium-disable-next-line */
        assembly {
            sstore(slot, newImplementation)
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
        require(
            newAdmin != address(0),
            "Cannot change the admin of a proxy to the zero address"
        );

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
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    )
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        /* solium-disable-next-line */
        (bool success,) = newImplementation.delegatecall(data);
        /* solium-disable-next-line */
        require(success);
    }

    /**
    * @return The admin slot.
    */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;

        /* solium-disable-next-line */
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

        /* solium-disable-next-line */
        assembly {
            sstore(slot, newAdmin)
        }
    }

}

