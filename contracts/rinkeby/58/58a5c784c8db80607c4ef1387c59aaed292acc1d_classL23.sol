/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.4.24;
contract classL23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        //事件  事件名稱  你要記錄的東西
        event setNumber(string _from);
  
        function function_3(string x)public {
            string_1 = x;
            
            //emit呼叫事件
            emit setNumber(string_1);
        }

}