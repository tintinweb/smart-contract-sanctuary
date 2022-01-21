/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DevCarn2{

   uint8[] numbers;
   
    // this function will be recursively called, so must be public.
   function splitAndAdd(uint256 initial) public returns(uint8){
       uint8 finalNumber;
       delete numbers;

       while(initial > 0){
           uint8 single = uint8(initial % 10);
           initial = initial / 10;
           numbers.push(single);
       }

    
        for(uint i=0; i < numbers.length; i++ ){
            finalNumber = finalNumber + numbers[i];
        }

        if(finalNumber >= 10){
            finalNumber = splitAndAdd(finalNumber);
        }

            

       return finalNumber;
   }
   
}