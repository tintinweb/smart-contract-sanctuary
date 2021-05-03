/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_5 {
    string[] To_do;
    uint did=0;
    
    function Add_Tast(string memory task) public {
        To_do.push(task);
    }
    
    function Remove_Task(string memory task) public {
        To_do.pop();
        did++;
        
    }
    
    function Count_Task() public view returns(uint) {
        return To_do.length;
    }
    
    function Last_Task() public view returns (uint) {
        return did;
    }
    
}