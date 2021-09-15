/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Proxy {

    // verify the data and execute the data at the target address
    function forward(address _to, address _from, bytes calldata _data) external returns (bool success, bytes memory ret) {

        bytes memory callData = abi.encodePacked(_data, _from);
        
        // solhint-disable-next-line avoid-low-level-calls
        (success,ret) = _to.call{gas : 4000000}(callData);
        
        return (success,ret);
    }
}