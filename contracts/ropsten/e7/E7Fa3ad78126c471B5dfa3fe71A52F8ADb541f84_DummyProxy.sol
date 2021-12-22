/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity 0.5.16;

// File: DummyProxy.sol
// Copyright (C) 2020 Dummy
pragma solidity = 0.5.16;
contract DummyProxy {
    address public implementation;
    constructor(address _impl) public {
        implementation = _impl;
    }
    /**
     * Proxy all other calls to implementation.
     */
    function ()
        external
        payable
    {
        address impl_m = implementation;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let res := call(sub(gas(), 10000), impl_m, callvalue(), ptr, calldatasize(), 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())
            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}
// File: Dummy.sol
// Copyright (C) 2020 Dummy
contract DummyImpl {
    bool public value = false;
    address public proxy;
    constructor () public {
        proxy = address(new DummyProxy(address(this)));
    }
    function setValue(bool _value) external {
        value = _value;
    }
    function getValue() external view returns (bool) {
        return value;
    }
}