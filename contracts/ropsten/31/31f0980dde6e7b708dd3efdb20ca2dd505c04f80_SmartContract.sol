pragma solidity ^0.4.24;

contract SmartContract {  
    int i=0;

    function writeToStorage() public returns (int)  { 
         i=99;
        return i;
    }

    function contribute() public payable  returns (uint256)   { 
        return msg.value;
    } 
    
    function readFromStorageView() public view returns (int)  { 
        // As the view does not have write access to storage variable, 
        // i=1; will work for now // In future, it will not work. It will be enforced.
        int n=i;
        i=1;
        return i;
    } 

    function justPureFunction(int k) public pure returns (int)  {   
      // i=2;
       return k;
    }
 
}