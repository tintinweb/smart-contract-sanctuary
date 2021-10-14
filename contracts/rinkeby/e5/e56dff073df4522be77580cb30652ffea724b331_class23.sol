/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.4.24;
contract class23{
        uint256 public integer_1 = 1;
        
        uint256 public integer_2 = 2;
        
        string public string_1;
    
        event setNumber(string _from);
  
        function function_3(string x)public {
            
            string_1 = x;
        
            
            emit setNumber(string_1);
        }
}