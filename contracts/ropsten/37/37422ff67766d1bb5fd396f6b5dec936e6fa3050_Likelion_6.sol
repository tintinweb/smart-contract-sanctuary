/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_6 {
    struct member {
        string name;
        bytes32 hash;
    }
    member[] members;
    
    function setMember(string memory _name, string memory _id, string memory _pw) public {
        if(keccak256(bytes(_name))!=keccak256(bytes("James"))){
            bytes32 _hash = keccak256(abi.encodePacked(_id,_pw));
            members.push(member(_name,_hash));
        }
    }
    function matching(string memory a, string memory b) public view returns(string memory){
        bytes32 check = keccak256(abi.encodePacked(a,b));
        for(uint i=0; i<members.length; i++){
            if(check == members[i].hash){
                return ("login!");
            }
            else{
                return("error!");
            }
        }
    }
    
    // string[] names;
    // bytes32 hash = keccak256(abi.encodePacked("abc","de"));
    
    // function pushName(string memory name) public {
    //     if(keccak256(bytes(name))!=keccak256(bytes("James"))){
    //         names.push(name);
    //     }
    // }
    // function matching(string memory a, string memory b) public view returns(string memory){
    //     bytes32 check = keccak256(abi.encodePacked(a,b));
    //     if(check == hash){
    //         return ("login!");
    //     }
    //     else{
    //         return("error!");
    //     }
    // }
    function getName(uint i) public view returns(string memory){
        return members[i].name;
    }
}