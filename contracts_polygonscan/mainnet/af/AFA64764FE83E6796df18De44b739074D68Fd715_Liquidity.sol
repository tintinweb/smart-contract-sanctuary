// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../infiniteProxy/proxy.sol";


contract Liquidity is Proxy {

    constructor(address admin_, address dummyImplementation_) Proxy(admin_, dummyImplementation_) {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
contract Internals is Events{

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

    /**
     * @dev Storage slot with the address of the current dummy-implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _DUMMY_IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _getSlotImplSigsSlot(address implementation_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", implementation_));
    }

    function _getSlotSigsImplSlot(bytes4 sig_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", sig_));
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot_) internal pure returns (AddressSlot storage _r) {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Returns an `SigsSlot` with member `value` located at `slot`.
     */
    function getSigsSlot(bytes32 slot_) internal pure returns (SigsSlot storage _r) {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Sets new implementation and adds mapping from implementation to sigs and sig to implementation.
     */
    function _setImplementationSigs(address implementation_, bytes4[] memory sigs_) internal {
        require(sigs_.length != 0, "no-sigs");
        bytes32 slot_ = _getSlotImplSigsSlot(implementation_);
        bytes4[] memory sigsCheck_ = getSigsSlot(slot_).value;
        require(sigsCheck_.length == 0, "implementation-already-exist");
        for (uint i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSlotSigsImplSlot(sigs_[i]);
            require(getAddressSlot(sigSlot_).value == address(0), "sig-already-exist");
            getAddressSlot(sigSlot_).value = implementation_;
        }
        getSigsSlot(slot_).value = sigs_;
        emit setImplementationLog(implementation_, sigs_);
    }

    /**
     * @dev removes implementation and the mappings corresponding to it.
     */
    function _removeImplementationSigs(address implementation_) internal {
        bytes32 slot_ = _getSlotImplSigsSlot(implementation_);
        bytes4[] memory sigs_ = getSigsSlot(slot_).value;
        require(sigs_.length != 0, "implementation-not-exist");
        for (uint i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSlotSigsImplSlot(sigs_[i]);
            delete getAddressSlot(sigSlot_).value;
        }
        delete getSigsSlot(slot_).value;
        emit removeImplementationLog(implementation_);
    }

    function _getImplementationSigs(address implementation_) internal view returns (bytes4[] memory) {
        bytes32 slot_ = _getSlotImplSigsSlot(implementation_);
        return getSigsSlot(slot_).value;
    }

    function _getSigImplementation(bytes4 sig_) internal view returns (address implementation_) {
        bytes32 slot_ = _getSlotSigsImplSlot(sig_);
        return getAddressSlot(slot_).value;
    }

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Returns the current dummy-implementation.
     */
    function _getDummyImplementation() internal view returns (address) {
        return getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin_) internal {
        address oldAdmin_ = _getAdmin();
        require(newAdmin_ != address(0), "ERC1967: new admin is the zero address");
        getAddressSlot(_ADMIN_SLOT).value = newAdmin_;
        emit setAdminLog(oldAdmin_, newAdmin_);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setDummyImplementation(address newDummyImplementation_) internal {
        address oldDummyImplementation_ = _getDummyImplementation();
        getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT).value = newDummyImplementation_;
        emit setDummyImplementationLog(oldDummyImplementation_, newDummyImplementation_);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

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
    function _fallback(bytes4 sig_) internal {
        address implementation_ = _getSigImplementation(sig_);
        require(implementation_ != address(0), "Liquidity: Not able to find implementation_");
        _delegate(implementation_);
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
    function setAdmin(address newAdmin_) onlyAdmin external {
        _setAdmin(newAdmin_);
    }

    /**
     * @dev sets new dummy-implementation.
     */
    function setDummyImplementation(address newDummyImplementation_) onlyAdmin external {
        _setDummyImplementation(newDummyImplementation_);
    }

    /**
     * @dev adds new implementation address.
     */
    function addImplementation(address implementation_, bytes4[] calldata sigs_) onlyAdmin external {
        _setImplementationSigs(implementation_, sigs_);
    }

    /**
     * @dev removes an existing implementation address.
     */
    function removeImplementation(address implementation_) onlyAdmin external {
        _removeImplementationSigs(implementation_);
    }

    constructor(address admin_, address dummyImplementation_) {
        _setAdmin(admin_);
        _setDummyImplementation(dummyImplementation_);
    }

}


abstract contract Proxy is AdminStuff {

    constructor(address admin_, address dummyImplementation_) AdminStuff(admin_, dummyImplementation_) {}

    /**
     * @dev returns admin's address.
     */
    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * @dev returns dummy-implementations's address.
     */
    function getDummyImplementation() external view returns (address) {
        return _getDummyImplementation();
    }

    /**
     * @dev returns bytes4[] sigs from implementation address If not registered then returns empty array.
     */
    function getImplementationSigs(address impl_) external view returns (bytes4[] memory) {
        return _getImplementationSigs(impl_);
    }

    /**
     * @dev returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function getSigsImplementation(bytes4 sig_) external view returns (address) {
        return _getSigImplementation(sig_);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Events {

    event setAdminLog(address oldAdmin_, address newAdmin_);

    event setDummyImplementationLog(address oldDummyImplementation_, address newDummyImplementation_);

    event setImplementationLog(address implementation_, bytes4[] sigs_);

    event removeImplementationLog(address implementation_);

}