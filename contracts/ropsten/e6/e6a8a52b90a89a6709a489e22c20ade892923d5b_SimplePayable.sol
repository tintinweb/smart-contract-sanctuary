/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;

contract SimplePayable {
    function invest() external payable {
        
            //optional:
            //to check if the amount is above a certain threshold:
            if(msg.value < 1000){
                revert();
            }
        
    }
    
    function balanceOf() external view returns(uint){
        //the keyword 'this' reffers to the address of the smart contrat
        return address(this).balance;
    }
    
}