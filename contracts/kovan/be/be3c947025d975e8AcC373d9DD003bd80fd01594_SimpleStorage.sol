// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage{
    uint256 fnumber;
    function storeNum(uint256 _num) public {
        fnumber = _num;
    }

    function retrieve() public view returns(uint256){
        return fnumber;
    }
}