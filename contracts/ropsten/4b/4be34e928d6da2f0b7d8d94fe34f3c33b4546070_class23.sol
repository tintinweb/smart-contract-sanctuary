/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.24;
    contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
    //  事件    事件名稱   你要記錄的東西,通常是Uint,Address,string

    //pure 不讀鏈上資料 不改鏈上資料     計算東西...
        function function_1(uint a,uint b) public pure returns(uint256){
            return a + 2*b; //加pure代表這個方法不會用到所有鏈上的資料,a是自己帶的,b也是自己帶的
        }
    
    //view 讀鏈上資料 不改鏈上資料   getName...
        function function_2() public view returns(uint256){
            return integer_1 + integer_2;
        }
  
        function function_3(string x)public returns(string){
            string_1 = x;//x設到String_1裡面,我就emit給他,然後他會幫我記錄(string_1)在鏈上
            emit setNumber(string_1); //每次呼叫這一個事件,就會用emit呼叫這個event,然後用SetNumber把它記錄起來
            //             這次紀錄的事
            return string_1;
        } //我透過呼叫function_3,function_3的emit這一行會幫我記錄這個事件,就可以在區塊鏈網站的event查到
    }