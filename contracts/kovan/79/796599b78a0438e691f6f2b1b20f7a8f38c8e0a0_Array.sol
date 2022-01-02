/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract Array {
    // 初始化數組的方式
    uint[] public arr;
    uint[] public arr2 = [1, 2, 3];
    // 固定大小的數組, 每個值都被初始為 default(T)
    uint[10] public myFixedSizeArr;

    // 取得數組 index 為 i 的值
    function get(uint i) public view returns (uint) {
        return arr[i];
    }

    // Solidity 可以回傳整個數組
    // 但這樣的函式使用上要注意, 要避免可無限增長的數組
    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    // 擴展數組, 長度(length)+1
    function push(uint i) public {
        arr.push(i);
    }

    // 縮減數組, 長度(length)-1
    function pop() public {
        arr.pop();
    }

    // 取得數組長度
    function getLength() public view returns (uint) {
        return arr.length;
    }

    // 移除數組 index 位置的值, 不會影響數組長度, 並其值置換為 default(T)
    function remove(uint index) public {
        delete arr[index];
    }

    // 在記憶體中創建數組, 但只能創建固定大小的數組
    function examples() external pure {
        uint[] memory a = new uint[](5);
    }
}