/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.4.15;


contract Dispatcher {
    address target;

    constructor(address _target) public {
        target = _target;
    }

    function() public {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let retval := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            let returnsize := returndatasize
            returndatacopy(0x0, 0x0, returnsize)
        }
    }
}