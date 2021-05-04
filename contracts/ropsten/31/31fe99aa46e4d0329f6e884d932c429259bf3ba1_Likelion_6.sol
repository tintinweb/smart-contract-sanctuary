/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_6 {
    
    string[] namelist;
    bytes32[] idhash;
    
    function addlist(string memory _name) public returns(string memory) {
        if(keccak256(bytes(_name)) != keccak256(bytes("James"))) {
            namelist.push(_name);
            return("Succeed!");
        } else {
            return ("fail!");
        }
    }
    
    /*function getList(uint i) public view returns(string memory) {
        return namelist[i];
    }*/
    
    function Register(string memory _id, string memory _pwd) public {
        // blockExcept는 1,11 과 11,1을 넣은 결과가 같아서 추가함.
        idhash.push(keccak256(abi.encodePacked(_id, "blockExcept",_pwd)));
    }
    
    function Login(string memory _id, string memory _pwd) public view returns(string memory) {
        for(uint i=0; i<idhash.length; i++) {
            if(idhash[i] == keccak256(abi.encodePacked(_id,"blockExcept", _pwd))) {
                return ("Login Complete");
            }
        }
        return ("Error");
    }
    
    
}