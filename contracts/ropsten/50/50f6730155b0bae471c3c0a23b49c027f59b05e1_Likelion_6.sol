/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity 0.8.0;


contract Likelion_6 {
    //YunJun Lee
    
    string[] names;
    
    //1번 문제
    function pushNames(string memory name) public {
        if(keccak256(bytes(name)) != keccak256(bytes("james")))
            names.push(name);
    }
    function getName(uint i) public view returns(string memory){
        return names[i];
    }
    

    
    
    string[] ids;
    bytes32[] hashes;

    function join(string memory id, string memory pawd) public {
        bytes32 hash = keccak256(abi.encodePacked(id, pawd) ) ;
        hashes.push(hash);
    }
    

    function login(string memory id, string memory pawd) public view returns(string memory) {
        bytes32 hash = keccak256(abi.encodePacked(id, pawd) ) ;

        for(uint a=0;a<hashes.length;a++){
            if(hashes[a] == hash)
                return "Login Success!";
        }
        
        
        return("Fail");
        
    }
    
    
}