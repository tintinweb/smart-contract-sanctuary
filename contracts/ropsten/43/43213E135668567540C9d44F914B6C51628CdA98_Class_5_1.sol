/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// 6-1 daehyuk

pragma solidity 0.8.0;

contract Class_5_1 {    
    
    string[] names;
    

    function pushname(string memory _name) public {
        
        names.push(_name);
        
    }
    
    function deletejames() public {
        
        for(uint i=0; i<names.length; i++) {
            
            if(keccak256(bytes(names[i])) == keccak256(bytes("james"))) {
                
                delete names[i];
                
            }
        }
        
    }
    
    function getname(uint i) public view returns(string memory) {
        
        return names[i];
        
    }
    
}