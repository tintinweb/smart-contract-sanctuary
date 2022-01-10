// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../infiniteProxy/proxy.sol";


contract Protocol2 is Proxy {

    constructor(address admin_) Proxy(admin_) {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
contract Internals {

    struct AddressSlot {
        address value;
    }

    struct SigsSlot {
        bytes4[] value;
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function _getSlotImplSigsSlot(address implementation) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", implementation));
    }

    function _getSlotSigsImplSlot(bytes4 sig) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", sig));
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `SigsSlot` with member `value` located at `slot`.
     */
    function getSigsSlot(bytes32 slot) internal pure returns (SigsSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Sets new implementation and adds mapping from implementation to sigs and sig to implementation.
     */
    function _setImplementationSigs(address implementation, bytes4[] memory sigs) internal {
        require(sigs.length != 0, "no-sigs");
        bytes32 slot = _getSlotImplSigsSlot(implementation);
        bytes4[] memory sigsCheck = getSigsSlot(slot).value;
        require(sigsCheck.length == 0, "implementation-already-exist");
        for (uint i = 0; i < sigs.length; i++) {
            bytes32 sigSlot = _getSlotSigsImplSlot(sigs[i]);
            require(getAddressSlot(sigSlot).value == address(0), "sig-already-exist");
            getAddressSlot(sigSlot).value = implementation;
        }
        getSigsSlot(slot).value = sigs;
    }

    /**
     * @dev removes implementation and the mappings corresponding to it.
     */
    function _removeImplementationSigs(address implementation) internal {
        bytes32 slot = _getSlotImplSigsSlot(implementation);
        bytes4[] memory sigs = getSigsSlot(slot).value;
        require(sigs.length != 0, "implementation-not-exist");
        for (uint i = 0; i < sigs.length; i++) {
            bytes32 sigSlot = _getSlotSigsImplSlot(sigs[i]);
            delete getAddressSlot(sigSlot).value;
        }
        delete getSigsSlot(slot).value;
    }

    function _getImplementationSigs(address implementation) internal view returns (bytes4[] memory) {
        bytes32 slot = _getSlotImplSigsSlot(implementation);
        return getSigsSlot(slot).value;
    }

    function _getSigImplementation(bytes4 _sig) internal view returns (address implementation) {
        bytes32 slot = _getSlotSigsImplSlot(_sig);
        return getAddressSlot(slot).value;
    }

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
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
     * @dev Delegates the current call to the address returned by Implementations registry.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback(bytes4 _sig) internal {
        address _implementation = _getSigImplementation(_sig);
        require(_implementation != address(0), "Liquidity: Not able to find _implementation");
        _delegate(_implementation);
    }

}


contract AdminStuff is Internals {

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "not-the-admin");
        _;
    }

    /**
     * @dev sets new admin.
     */
    function setAdmin(address newAdmin) onlyAdmin external {
        _setAdmin(newAdmin);
    }

    /**
     * @dev adds new implementation address.
     */
    function addImplementation(address _implementation, bytes4[] calldata _sigs) onlyAdmin external {
        _setImplementationSigs(_implementation, _sigs);
    }

    /**
     * @dev removes an existing implementation address.
     */
    function removeImplementation(address _implementation) onlyAdmin external {
        _removeImplementationSigs(_implementation);
    }

    constructor(address admin) {
        _setAdmin(admin);
    }

}


abstract contract Proxy is AdminStuff {

    constructor(address admin) AdminStuff(admin) {}

    /**
     * @dev returns admin's address.
     */
    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * @dev returns bytes4[] sigs from implementation address If not registered then returns empty array.
     */
    function getImplementationSigs(address _impl) external view returns (bytes4[] memory) {
        return _getImplementationSigs(_impl);
    }

    /**
     * @dev returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function getSigsImplementation(bytes4 _sig) external view returns (address) {
        return _getSigImplementation(_sig);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    fallback () external payable {
        _fallback(msg.sig);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    receive () external payable {
        if (msg.sig != 0x00000000) {
            _fallback(msg.sig);
        }
    }
    
}