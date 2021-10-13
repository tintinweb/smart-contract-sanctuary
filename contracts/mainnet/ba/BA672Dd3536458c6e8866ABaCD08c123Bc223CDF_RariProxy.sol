/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity 0.6.7;

abstract contract RariPool {
    function _acceptAdmin() public virtual returns (uint);
    
}

contract RariProxy {
    function acceptAdmin(address target) public {
        RariPool(target)._acceptAdmin();
    }    
}