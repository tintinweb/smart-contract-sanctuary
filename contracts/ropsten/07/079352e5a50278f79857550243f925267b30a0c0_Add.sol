/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;

contract Add{
    uint256 a;
    uint256 b;
    /***
     * 여기에 들어가는 매개변수가 진짜 a,b 인지 
여기에 a,b랑 상관 없는 건지 물어보기 아마 후자일 듯
     ***/
    function add(uint256 a, uint256 b) public view returns(uint256) {
        return a+b;
    }
    
        function minus(uint256 a, uint256 b) public view returns(uint256) {
        return a-b;
    }
        function multiple(uint256 a, uint256 b) public view returns(uint256) {
        return a*b;
    }
    
        function divide(uint256 a, uint256 b) public view returns(uint256) {
        return a/b;
    }
    
    
    
}