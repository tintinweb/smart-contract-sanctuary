/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity >=0.4.16 < 0.9.0;
pragma experimental ABIEncoderV2;

contract Demo {
    struct Test {
        string name;
        string policies;
        uint num;
    }

    uint public x;
    function test1(bytes3) public {x = 1;}
    function test2(bytes3[2] memory) public  { x = 1; }
    function test3(uint32 x, bool y) public  { x = 1; }
    function test4(uint, uint32[] memory, bytes10, bytes memory) public { x = 1; }
    function test5(uint, Test memory test) public { x = 1; }
    function test6(uint, Test[] memory tests) public { x = 1; }
    function test7(uint[][] memory,string[] memory) public { x = 1; }
}

/* 函数选择器
{
    "0d2032f1": "test1(bytes3)",
    "2b231dad": "test2(bytes3[2])",
    "92e92919": "test3(uint32,bool)",
    "4d189ce2": "test4(uint256,uint32[],bytes10,bytes)",
    "4ca373dc": "test5(uint256,(string,string,uint256))",
    "ccc5bdd2": "test6(uint256,(string,string,uint256)[])",
    "cc80bc65": "test7(uint256[][],string[])",
    "0c55699c": "x()"
}
*/