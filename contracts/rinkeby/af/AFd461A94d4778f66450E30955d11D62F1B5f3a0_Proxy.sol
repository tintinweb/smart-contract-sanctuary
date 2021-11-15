pragma solidity 0.6.12;

contract Proxy  {

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        
    constructor(address _impl) public {
        setAdmin(msg.sender);
        setImplementation(_impl);
    }
    
    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function setImplementation(address newImplementation) public {
        require(msg.sender == admin());
        require(isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function setAdmin(address newAdmin) public {
        require(newAdmin != address(0));
        require(msg.sender == admin() || address(0) == admin());
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Returns the current admin.
     */
    function admin() public view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

     /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }
   
   function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    fallback() external {
        address impl = implementation();
        assembly {
            let ptr := mload(0x40)
 
            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())
 
             // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
 
            // (3) retrieve return data
            returndatacopy(ptr, 0, size)
 
            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }   
    }
}

