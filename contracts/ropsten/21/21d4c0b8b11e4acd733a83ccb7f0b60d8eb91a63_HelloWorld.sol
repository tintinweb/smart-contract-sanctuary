/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.10;

contract HelloWorld {
    

    function say(uint amount,uint conversionRate) public pure returns (uint convertedAmount){
        return amount * conversionRate;
    }
}