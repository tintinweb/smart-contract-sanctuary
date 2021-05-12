/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// Lee GyungHwan

pragma solidity 0.8.0;

contract likelion_11 {
    string[] names;
    
    function pushName(string memory _name) public {
        names.push(_name);
    }
    
    function callNumber() public view returns(uint, uint) {
        return (names.length, 10 - names.length);
    }
    
    function looking() public view returns(string memory) {
        for(uint i=0; i<names.length; i++) {
            if(keccak256(bytes(names[i]))==keccak256(bytes("Sophia"))) {
                return ("true");
            }
        }
        return ("false");
    }
}