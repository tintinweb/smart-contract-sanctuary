/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.4.24;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string  public string_1;
    
        event setNumber(string _from);
    //   事件   事件名稱   你要記錄的東西  （ adress , uint ... )

    //pure 不讀鏈上資料 不改鏈上資料 不需ggs    計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
            return a + 2*b;
        }
    
    //pure 讀鏈上資料 不改鏈上資料 不需ggs   getName...
    function function_2() public view returns(uint256){
            return integer_1 + integer_2;
        }

        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
        }   //emit 呼叫
        
        //實作事件
        }