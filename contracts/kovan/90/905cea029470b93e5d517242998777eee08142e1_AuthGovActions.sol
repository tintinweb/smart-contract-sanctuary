/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function setRootUser(address, bool) external virtual;
    function setOwner(address) external virtual;
}

contract AuthGovActions {
    function setRootUser(Setter target, address account, bool isRoot) public {
        target.setRootUser(account, isRoot);
    }

    function setOwner(Setter target, address account) public {
        target.setOwner(account);
    }
}