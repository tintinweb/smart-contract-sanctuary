/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity ^0.5.0;

contract test{
    
    
    uint[10] public number;
    
    constructor()public {
        number[0] = 100;
        number[1] = 200;
        number[2] = 300;
        number[3] = 400;
        number[4] = 500;
        number[5] = 600;
        number[6] = 700;
        number[7] = 800;
        number[8] = 100;
        number[9] = 100;
    }
    
    
    function read(uint no)public view returns(uint){
        return number[no];
    }
    
    
    
}