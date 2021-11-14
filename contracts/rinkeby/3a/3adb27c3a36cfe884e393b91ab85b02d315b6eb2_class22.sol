/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity ^0.8.10;

contract class22{
    
    uint256 public integer_1 = 1;
    uint256 public integer_2 = 2;
    string public string_1;
    
    event setNumber(string _from);
    
    //pure 不讀鏈上資料 不改鏈上資料     計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
        return a + 2*b;
    }
    
    //view 讀鏈上資料 不改鏈上資料   getName...
    function function_2() public view returns(uint256){
        return integer_1 + integer_2;
    }

    //修改鏈上資料    setName...
    function function_3(string memory x) public returns(string memory){
        string_1 = x;
        return string_1;
    }
    
    //修改鏈上資料 需要gas
    function class(string memory x) public returns(string memory){
        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }
    
    //實作事件
    
}