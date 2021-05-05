/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//young do jang


pragma solidity 0.8.0;

contract Likelion_6_1 {
    bytes32 hash;
   string [] names;
   string a;
    
    function setName(string memory _name) public {
        names.push(_name);
    }
    
    function deleteName() public {
        for (uint i = 0;i < names.length; i++) {
            a = names[i];
            hash = keccak256(abi.encodePacked(a));
            if((hash) == keccak256(bytes("James"))) {
                delete names[i];
            }
    }
}

    function showlist(uint i) public view returns(string memory) {
     return (names[i]);
 }
}