/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    mapping(uint256 => uint256) data;

    event StoreStart(uint256 indexed key, uint256 value);
    event StoreSuccess(uint256 indexed key, uint256 value);

    function store(uint256 key, uint256 value) public {
        emit StoreStart(key, value);
        require(key != 0, "key != 0");
        data[key] = value;
        emit StoreSuccess(key, value);
    }


    function retrieve(uint256 key) view public returns (uint256){
        return data[key];
    }
}