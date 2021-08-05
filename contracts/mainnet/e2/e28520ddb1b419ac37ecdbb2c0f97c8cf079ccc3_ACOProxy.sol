pragma solidity ^0.6.6;

import "./Address.sol";

/**
 * @title ACOProxy
 * @dev A proxy contract that implements delegation of calls to other contracts.
 */
contract ACOProxy {
    
    /**
     * @dev Emitted when the admin address has been changed.
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     */
    event ProxyAdminUpdated(address previousAdmin, address newAdmin);
    
    /**
     * @dev Emitted when the proxy implementation has been changed.
     * @param previousImplementation Address of the previous proxy implementation.
     * @param newImplementation Address of the new proxy implementation.
     */
    event SetImplementation(address previousImplementation, address newImplementation);
    
    /**
     * @dev Storage position for the admin address.
     */
    bytes32 private constant adminPosition = keccak256("acoproxy.admin");
    
    /**
     * @dev Storage position for the proxy implementation address.
     */
    bytes32 private constant implementationPosition = keccak256("acoproxy.implementation");

    /**
     * @dev Modifier to check if the `msg.sender` is the admin.
     * Only admin address can execute.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin(), "ACOProxy::onlyAdmin");
        _;
    }
    
    constructor(address _admin, address _implementation, bytes memory _initdata) public {
        _setAdmin(_admin);
        _setImplementation(_implementation, _initdata);
    }

    /**
     * @dev Fallback function that delegates the execution to the proxy implementation contract.
     */
    fallback() external payable {
        address addr = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    /**
     * @dev Function to be compliance with EIP 897.
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md
     * It is an "upgradable proxy".
     */
    function proxyType() public pure returns(uint256) {
        return 2; 
    }
    
    /**
     * @dev Function to get the proxy admin address.
     * @return adm The proxy admin address.
     */
    function admin() public view returns (address adm) {
        bytes32 position = adminPosition;
        assembly {
            adm := sload(position)
        }
    }
    
    /**
     * @dev Function to get the proxy implementation address.
     * @return impl The proxy implementation address.
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Function to set the proxy admin address.
     * Only can be called by the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function transferProxyAdmin(address newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }
    
    /**
     * @dev Function to set the proxy implementation address.
     * Only can be called by the proxy admin.
     * @param newImplementation Address of the new proxy implementation.
     * @param initData ABI encoded with signature data that will be delegated over the new implementation.
     */
    function setImplementation(address newImplementation, bytes calldata initData) external onlyAdmin {
        _setImplementation(newImplementation, initData);
    }

    /**
     * @dev Internal function to set the proxy admin address.
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "ACOProxy::_setAdmin: Invalid admin");
        
        emit ProxyAdminUpdated(admin(), newAdmin);
        
        bytes32 position = adminPosition;
        assembly {
            sstore(position, newAdmin)
        }
    }
    
    /**
     * @dev Internal function to set the proxy implementation address.
     * The implementation address must be a contract.
     * @param newImplementation Address of the new proxy implementation.
     * @param initData ABI encoded with signature data that will be delegated over the new implementation.
     */
    function _setImplementation(address newImplementation, bytes memory initData) internal {
        require(Address.isContract(newImplementation), "ACOProxy::_setImplementation: Invalid implementation");
        
        emit SetImplementation(implementation(), newImplementation);
        
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
        if (initData.length > 0) {
            (bool success,) = newImplementation.delegatecall(initData);
            assert(success);
        }
    }
}
