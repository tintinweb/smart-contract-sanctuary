/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.4.24;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string indexed _from);
        
        
        function function_1(uint a, uint b)public pure returns(uint256){
            return a+2*b;
            
        }
  
        function fuction_2()public view returns(uint256){
            return integer_1 + integer_2;
        }
        
        function function_3(string x)public returns(string) {
            string_1 = x;
            emit setNumber(string_1);
            return string_1;
        }
}