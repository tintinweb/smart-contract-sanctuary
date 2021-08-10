/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.4.24;




contract test{
    
    
    function get_number()public returns(uint){
        uint aa = block.number;
        return aa;
    }
    
    function Get_Number()public view returns(uint){
        uint aa = block.number;
        return aa;
    }

    
    
}