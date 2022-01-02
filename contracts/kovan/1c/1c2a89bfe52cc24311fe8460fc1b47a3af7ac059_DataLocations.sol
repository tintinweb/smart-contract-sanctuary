/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

struct MyStruct {
    uint foo;
}

contract DataLocations {
    // 這邊都是 storage 的
    uint[] public arr;
    mapping(uint => address) map;
    mapping(uint => MyStruct) myStructs;

    function f() public {
        // 使用內部方法, 傳遞 state 變數
        _f(arr, map, myStructs[1]);

        // 從 state 中取值, 故需宣告為 storage
        MyStruct storage myStruct = myStructs[1];
        // 在 local 建 struct, 故需宣告為 memory
        MyStruct memory myMemStruct = MyStruct(0);
    }

    // 因為是使用用區域變數, 故資料位置皆為 storage
    function _f(
        uint[] storage _arr,
        mapping(uint => address) storage _map,
        MyStruct storage _myStruct
    ) internal {

    }

    // 可以回傳儲存於 local 的 memory 變數
    function g(uint[] memory _arr) public returns (uint[] memory) {
    }

    // calldata 變數只能由外部方法使用
    function h(uint[] calldata _arr) external {
        
    }
}