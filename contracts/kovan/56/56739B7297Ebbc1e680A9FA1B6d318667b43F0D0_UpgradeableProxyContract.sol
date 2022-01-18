// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.8.11;

error NotOwner();

/**
 * @title UpgradeableProxyContract
 * @dev A more advanced proxy contract where the owner and implementation addresses can be mutated.
 */
contract UpgradeableProxyContract {

    // ERC1967

    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    bytes32 internal constant _IMP_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    bytes32 internal constant _OWN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; 

    /**
     * @param _owner Address of the initial owner of this contract
     * @param _implementation Address of the initial implementation for this contract.
     */
    constructor(
        address _owner,
        address _implementation
    ) {
        assembly
        {
            sstore(_OWN_SLOT, _owner)
            sstore(_IMP_SLOT, _implementation)
        }
    }

    fallback() external payable { _fallback(); }
    receive() external payable  { _fallback(); }

    /**
     * Called when no existing local function matches the hash fingerprint
     */
    function _fallback() internal {
        (bool success, bytes memory data) = getImplementation().delegatecall(msg.data);

        assembly
        {
            // how much data?
            let size := mload(data)

            // where's the data?
            let location := add(data, 0x20)

            // delegatecall bool is falsy on 0, truthy on non-zero
            if iszero(success) { revert(location, size) }

            // and as K said, return inside fallback must be in assembly
            return(location, size)
        }
    }



    /**
     * Check the sender has permission to execute the attached function
     */
    modifier isOwner() {
        if(msg.sender != getOwner()) revert NotOwner();
        _;
    }

    /**
     * Retreives the address of the owner of this contract.
     * @return _own_addr - address of the owner 
     */
    function getOwner() public view returns (address _own_addr) {
        assembly {
            _own_addr := sload(_OWN_SLOT)
        }
    }

    /**
     * Assigns the address of the owner of this contract.
     * @param _own_addr - address of the owner
     * Must be Owner
     */
    function setOwner(address _own_addr) public isOwner() {
        assembly {
            sstore(_OWN_SLOT, _own_addr)
        }
    }

    /**
     * Retrieves the address of the target implementation contract.
     * @return _impl_addr - address of the target implementation
     */
    function getImplementation() public view returns (address _impl_addr) {
        assembly {
            _impl_addr := sload(_IMP_SLOT)
        }
    }

    /**
     * Assigns the address of the target implementation contract.
     * @param _impl_addr - address of the target implementation
     * Must be Owner
     */
    function setImplementation(address _impl_addr) public isOwner() {
        assembly {
            sstore(_IMP_SLOT, _impl_addr)
        }
    }
}