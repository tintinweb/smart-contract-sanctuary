/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity 0.5.16;

contract Proxy {

    constructor() public {
        address contractLogic = address(0x0);
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
    }

    function() external payable {
        assembly {
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize)
            let success := delegatecall(gas, contractLogic, ptr, calldatasize, 0, 0)
            let retSz := returndatasize
            returndatacopy(ptr, 0, retSz)
            switch success
            case 0 {
                revert(ptr, retSz)
            }
            default {
                return(ptr, retSz)
            }
        }
    }
}