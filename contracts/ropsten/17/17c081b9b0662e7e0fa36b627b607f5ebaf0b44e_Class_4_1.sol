/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//kim dong hyeon

pragma solidity 0.8.0;

contract Class_4_1{
    string[] names;
    
    
    function pushname(string memory _name)public{
        names.push(_name);
    }
    
    
    function deletename() public{
        for(uint i=0; i<names.length; i++){
            if(keccak256(bytes(names[i]))==keccak256(bytes("james"))){
                delete names[i];
                
            }
        }
    }
    
}