/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-07
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ParamsT2 {
    function num() external returns (uint n);
}

contract ParamsT1 {
    function openBox(address _contract, uint256 _num) public {
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(success, string(data));
        uint num = ParamsT2(_contract).num();
        require(num > 10, "num is low");
    }
}