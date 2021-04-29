/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity 0.8.0;

contract Class_1_3 {
     
    // list
    // type[] name;
    
    uint[] numbers;
    
    string[] names;
    
    function pushstring1() public {
        
        names.push("a");
        
    }
    
    function pushstring2() public {
        
        names.push("b");
        
    }
    
    function pushstring3() public {
        
        names.push("c");
        
    }
    
    
    function getstring(uint a) public view returns(string memory) {
        
    }
    
    function pusheven(uint a) public {
        
        if(a%2 == 0) {
            
            numbers. push(a);

        }

    }
    function get(uint a) public view returns(uint) {
        
         return numbers[a-1];
    }
}