/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity >=0.4.22 <0.7.0;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
    //  事件   事件名稱   要紀錄的東西
    
        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
        }
}