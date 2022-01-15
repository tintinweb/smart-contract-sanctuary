/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.7.0;
contract pig{
    uint public number;
    

    constructor (uint goal ){
        number=goal;
       
       
    }
    // address maker;
    uint  public balanc;
    function pigg()public {
        
        balanc =address(this).balance;
        //  address maker=msg.sender;
        if (balanc>=number){
            selfdestruct(msg.sender);
        }
    }

}