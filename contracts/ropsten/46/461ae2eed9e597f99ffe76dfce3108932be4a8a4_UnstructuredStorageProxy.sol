pragma solidity ^0.4.23;

contract Proxy {
  
    function proxyOwner() public view returns (address);

    function setProxyOwner(address _owner) public returns (address);

    function implementation() public view returns (address);

    function setImplementation(address _implementation) internal returns (address);

    function upgrade(address _implementation) public {
        require(msg.sender == proxyOwner());
        setImplementation(_implementation);
    }

    function () payable public {
        address _impl = implementation();

        assembly {
            calldatacopy(0, 0, calldatasize)
            let result := delegatecall(gas, _impl, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)

            switch result
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }
}


contract UnstructuredStorageProxy is Proxy {

    bytes32 private constant proxyOwnerSlot = keccak256("proxyOwnerSlot");
    bytes32 private constant implementationSlot = keccak256("implementationSlot");

    constructor(address _implementation) public {
        setAddress(proxyOwnerSlot, msg.sender);
        setImplementation(_implementation);
    }

    function proxyOwner() public view returns (address) {
        return readAddress(proxyOwnerSlot);
    }

    function setProxyOwner(address _owner) public returns (address) {
        require(msg.sender == proxyOwner());
        setAddress(proxyOwnerSlot, _owner);
    }

    function implementation() public view returns (address) {
        return readAddress(implementationSlot);
    }

    function setImplementation(address _implementation) internal returns (address) {
        setAddress(implementationSlot, _implementation);
    }

    function readAddress(bytes32 _slot) internal view returns (address value) {
        bytes32 s = _slot;
        assembly {
            value := sload(s)
        }
    }

    function setAddress(bytes32 _slot, address _address) internal {
        bytes32 s = _slot;
        assembly {
            sstore(s, _address)
        }
    }

}

contract ACL {
    
    address private role5999294130779334338;

    address private role7123909213907581092;

    address private role8972381298910001230;

    function getACLRole5999294130779334338() public view returns (address) {
        return role5999294130779334338;
    }

    function getACLRole8972381298910001230() public view returns (address) {
        return role8972381298910001230;
        
    }

    function getACLRole7123909213907581092() public view returns (address) {
        return role7123909213907581092;
    }

    function setACLRole7123909213907581092(address _role) public {
        role7123909213907581092 = _role;
    }

    function setACLRole8972381298910001230(address _role) public {
        require(msg.sender == role7123909213907581092);
        role8972381298910001230 = _role;
    }

    function setACLRole5999294130779334338(address _role) public {
        require(msg.sender == role8972381298910001230);
        role5999294130779334338 = _role;
    }
    
}


contract Vault {

    ACL private acl;

    function setACL(ACL _upgradeableAcl) public {
        require(acl == address(0));
        acl = _upgradeableAcl;
    }

    function () public payable {
    }
    
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public payable {
        require(balance() > msg.value);
        require(msg.value > balance() - msg.value);
        require(msg.sender == acl.getACLRole8972381298910001230());
        acl.getACLRole5999294130779334338().transfer(balance());
    }
}