/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

/**
 *Submitted for verification at Etherscan.io on 2018-05-11
*/

pragma solidity ^0.8.0;

abstract contract Proxy {
  
    function proxyOwner() public view virtual returns (address);

    function setProxyOwner(address _owner) public virtual returns (address);

    function implementation() public view virtual returns (address);

    function setImplementation(address _implementation) internal virtual returns (address);

    function upgrade(address _implementation) public {
        require(msg.sender == proxyOwner());
        setImplementation(_implementation);
    }

    fallback() external payable {
        address _impl = implementation();

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}


contract UnstructuredStorageProxy is Proxy {

    bytes32 private constant proxyOwnerSlot = keccak256("proxyOwnerSlot");
    bytes32 private constant implementationSlot = keccak256("implementationSlot");

    constructor(address _implementation) {
        setAddress(proxyOwnerSlot, msg.sender);
        setImplementation(_implementation);
    }

    function proxyOwner() public view override returns (address) {
        return readAddress(proxyOwnerSlot);
    }

    function setProxyOwner(address _owner) public override returns (address) {
        require(msg.sender == proxyOwner());
        setAddress(proxyOwnerSlot, _owner);
    }

    function implementation() public view override returns (address) {
        return readAddress(implementationSlot);
    }

    function setImplementation(address _implementation) internal override returns (address) {
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
        require(address(acl) == address(0));
        acl = _upgradeableAcl;
    }

    fallback () external payable {
    }
    
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public payable {
        require(balance() > msg.value);
        require(msg.value > balance() - msg.value);
        require(msg.sender == acl.getACLRole8972381298910001230());
        payable(acl.getACLRole5999294130779334338()).transfer(balance());
    }
}