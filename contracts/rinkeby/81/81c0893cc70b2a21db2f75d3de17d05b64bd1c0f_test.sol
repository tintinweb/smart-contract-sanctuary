/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.5.0;

contract test{
    
    
    uint[] public number;
    
    constructor()public {
        number.push(100);
        number.push(200);
        number.push(300);
        number.push(400);
        number.push(500);
        number.push(600);
        number.push(700);
        
    }
    
    function set_array(uint _number)public {
        number.push(_number);
    }
    
    

    function getAllEmployees() public view returns (uint[]memory) {
        return number;
    }
    
    function get_data()public view returns (uint){
        return block.difficulty;
    }
    
}