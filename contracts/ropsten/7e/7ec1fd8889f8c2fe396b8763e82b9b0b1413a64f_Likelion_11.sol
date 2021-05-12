/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//young do jang
pragma solidity 0.8.0;

contract Likelion_11 {
   
    uint count;
    uint newcount;
    bytes32 hash;
    bytes32 hash2;
    string [] students;
    
    function setstudents(string memory _Name) public  {
        students.push(_Name);
    }
    
    function Howmany() public returns(uint) {
        for(uint i =0;i < students.length;i++) {
            count++;
        }
        return count;
    }
    
    function transfer(string memory _NewName) public {
        students.push(_NewName);
        
        for(uint j =0; j < students.length; j++) {
            newcount++;
        }
        
    }
    
    function check(string memory) public returns(bool) {
        hash = keccak256(bytes("Sophia"));
        for(uint k =0;k < students.length; k++) {
           
            hash2 = keccak256(bytes(students[k]));
           
            if ((hash) == (hash2)) {
                return true;
            }
            break;
        }
    }
    function Morestudents() public returns(uint) {
        return(10 - newcount);
    }
        
}