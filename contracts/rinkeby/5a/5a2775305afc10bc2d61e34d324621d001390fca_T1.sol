/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: SpaceSeven

pragma solidity >=0.7.0 <0.9.0;

contract T1 {
    mapping(uint256 => uint256) private data;

    function setData(uint256 _key, uint256 _val) public {
        data[_key] = _val;
    }

    function getData(uint256 _key) external view returns (uint256) {
        return data[_key];
    }
}