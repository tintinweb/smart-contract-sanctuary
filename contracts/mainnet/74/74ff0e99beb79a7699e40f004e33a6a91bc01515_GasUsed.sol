/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

pragma solidity ^0.6.12;

contract GasUsed {
    function getUsedGas(
        address target,
        bytes calldata data
    )  external returns (uint256) {
        
        uint256 initialGas = gasleft();
        (bool success,) = target.call(data);
        uint256 endGas = gasleft();
        if (!success) {
            revert("Inner call failed");
        }
        return initialGas - endGas;
    }
}