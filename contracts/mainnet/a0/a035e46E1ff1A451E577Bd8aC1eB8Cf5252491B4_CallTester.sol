/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract CallTester  {
    
    struct CallDesc {
        address to;
        bytes data;
        uint256 value;
    }

    struct Return {
        bytes data;
        uint256 gas;
        bool success;
    }
    
    function makeCalls(CallDesc[] memory calls) external payable returns (Return[] memory rets) {
        rets = new Return[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            CallDesc memory c = calls[i];
            uint gas = gasleft();
            (bool ok, bytes memory data) = c.to.call{value: c.value}(c.data);
            rets[i] = Return({
                data: data,
                success: ok,
                gas: gas - gasleft()
            });
        }
    }

}