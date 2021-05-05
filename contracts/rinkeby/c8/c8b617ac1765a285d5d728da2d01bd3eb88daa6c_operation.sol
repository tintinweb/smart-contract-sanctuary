/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
contract operation{
    //1. 1+...+n or 1*..*n operation
    //2. 查詢sender 的 address
    //3. 查詢使用的 value
    
    address public sender;  //用來查sender的address
    uint public value;  //用來查value
    
    int public pro = 1;
    function op(int n) public payable{
        for(int i = 1 ; i <= n ; i++){
            pro = pro * i ;
        }
        sender = msg.sender;
        value = msg.value;
    }
    
}