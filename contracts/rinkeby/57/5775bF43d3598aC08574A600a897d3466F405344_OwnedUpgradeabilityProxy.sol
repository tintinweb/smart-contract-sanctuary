// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UpgradeabilityProxy.sol";

contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
     
    bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");
    
    constructor() {
        setProxyOwner(msg.sender);
    }
     
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "OwnedUpgradeabilityProxy::Only Proxy Owner Can Do This");
        _;
    }

    
    function proxyOwner() public view returns(address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    
    function setProxyOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
    
    function transferProxyOwnership(address _newProxyOwner) public onlyProxyOwner {
        address currentOwner = proxyOwner();
        require(currentOwner != _newProxyOwner && _newProxyOwner != address(0), "OwnedUpgradeabilityProxy::Fail To Transfer Ownership");
        setProxyOwner(_newProxyOwner);
        emit ProxyOwnershipTransferred(currentOwner, _newProxyOwner);
    }
    
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }
    
    function upgradeToAndCall(address _implementation, bytes memory data) public payable onlyProxyOwner {
        upgradeTo(_implementation);
        (bool sent, ) = address(this).call{ value: msg.value }(data);
        require(sent, "OwnedUpgradeabilityProxy::Fail To Upgrade And Call");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";


contract UpgradeabilityProxy is Proxy {
     /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
    event Upgraded(address indexed implementation);
  
   bytes32 private constant implementationPosition = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    
    function implementation() public view override returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }
    
    function setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "UpgradeabilityProxy::Address of new implementation must be different.");
        setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxy {
      /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view virtual returns (address);
  
  fallback() external payable {
    address _impl = implementation();
    require(_impl != address(0));
    
    assembly {
        let ptr := mload(0x40)
        
        calldatacopy(ptr, 0, calldatasize())
        
        let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
        
        let size := returndatasize()
        returndatacopy(ptr, 0, size)
        
        switch result
        case 0 { revert(ptr, size) }
        case 1 { return(ptr, size) }
    }
  }
  
  receive() external payable {
      
  }
}

