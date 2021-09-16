/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity ^0.8.7;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
  
        function function_3(string memory x)public {
            string_1 = x;
            emit setNumber(string_1);
        }
}