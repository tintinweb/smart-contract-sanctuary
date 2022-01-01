/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

// 資料類型 boolean、uint、int、address
contract Primitives {

    // 資料類型預設值
    string public default_str;      //
    bool public defualt_bool;       // false
    uint public default_uint;       // 0
    int public default_int;         // 0
    address public default_addr;    // 0x0000000000000000000000000000000000000000

    // 字串
    string public str = "QQ";

    // 布林
    bool public boo = true;

    // 無符號整數
    // uint8    範圍 0 ~ 2**8-1
    // uint16   範圍 0 ~ 2**16-1
    // 依此類推
    // 若不宣告大小則為 uint256
    uint8 public u8 = 1;
    uint public u256 = 456;
    uint public u = 123;

    // 有符號整數
    // int8     範圍 -2**7 ~ 2**7-1
    // int16    範圍 -2**15 ~ 2**15-1
    // 依此類推
    // 若不宣告大小則為 int256
    int8 public i8 = -1;
    int public i256 = 456;
    int public i = -123;

    // 有符號整數最大最小值
    int public minInt = type(int).min;
    int public maxInt = type(int).max;

    // 地址
    address public addr = 0x56cEbE970CACDE7aD8d780Cf98f4B7E5117eDE80;

    // 位元
    // byte[8]
    // bytes = byte[]
    // 可以指定大小, 或動態大小
    bytes1 public a = 0xb5; // [10110101]
    bytes1 public b = 0x56; // [01010110]
}