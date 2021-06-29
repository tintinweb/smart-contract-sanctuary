/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity >=0.7.0 <0.9.0;

contract Naming {
    
    
    string public myName;
    
    function setName(string memory newName) external returns(string memory){
        myName = newName;
        return myName;
    }
    
    function getName() external returns(string memory) {
        return myName;
    }
}

contract Another {
    
    Naming public instance;
    event Happy(string indexed status);
   
    
   
    function getOther() external returns(string memory){
        emit Happy("happyguy");
        return instance.getName();
    }
    
    
}