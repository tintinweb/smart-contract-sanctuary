/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Encode
{
    function encode(bytes32 _type, string calldata _name, string calldata _symbol, uint256 _fee) external pure returns (bytes memory _encoded)
    {
        return abi.encode(_type, _name, _symbol, _fee);
    }
}