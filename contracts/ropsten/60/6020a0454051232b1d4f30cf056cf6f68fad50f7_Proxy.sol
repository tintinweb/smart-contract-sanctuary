/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.0;




contract Proxy  {

    address private _implementation; 
    event Upgraded(address indexed implementation); 

    function implementation() public view returns (address) {
    return _implementation;
    }

    function upgradeTo(address impl) public  {
    _implementation = impl;
    emit Upgraded(impl);
    }


    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize) 
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
       }
   }
}