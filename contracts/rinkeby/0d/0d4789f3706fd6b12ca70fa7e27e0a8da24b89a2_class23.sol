/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.4.24;

contract class23 {
    
    uint256 public integer_1 = 1 ;
    uint256 public integer_2 = 2 ;
    string public string_1 ;
    
    // 事件  事件名稱  要紀錄的東西
    event setNumber(string indexed _from) ;
    
    // pure 不讀也不修改鏈上資料
    function function_1(uint a, uint b) public pure returns(uint256) {
        return a + 2*b ;
    }
    
    // view 讀鏈上資料，但不修改
    function function_2() public view returns(uint256) {
        return integer_1 + integer_2 ;
    }
    
    // 修改鏈上資料，需要 gas
    function function_3(string x) public returns(string) {
        string_1 = x ;
        emit setNumber(string_1) ;
        return string_1 ;
    }
}