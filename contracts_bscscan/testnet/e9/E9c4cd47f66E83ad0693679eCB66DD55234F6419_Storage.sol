/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint number; //state variable

    function store(uint num) public returns (uint) {
        return num;         
        
        }
    function storetest(uint num) public   {
        uint numnew=store(num);
        number=  numnew;
        //even this will not return any value in the decoded output field
                  
        
    }
        


    //the retrieve() view function will return a value in the 
   // "decodedoutput" field of the transaction

    function retrieve() public view returns (uint){ 
        return number;
    }

    // this method (not being a view method) will not return a value
    function retrieve2() public returns (uint){ 
        return number;
    }
}