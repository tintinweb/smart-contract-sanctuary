/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GoldenTrio{
    
    uint public counter = 1;
    string public message = "Enojoying?";
    string public flag = "Not that easy :)";
    
    function increment() public {
        counter += 1;
    }
    
    function greet() public {
        
        if(counter%3 == 0){
            message = "6374627b3652344e3633525f48333444357d";
            counter += 1;
        }
        else{
            message = "Welcome to CTB !!!";
        }
    }
    
}