/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_6_1 {
     string[] names;

    function pushName(string memory _name) public  {
        names.push(_name);
        for(uint i=0; i<names.length; i++) {
            if(keccak256(bytes(names[i]))==keccak256(bytes("James"))) {
                return;
            }
        }
    }
        function getName(uint i) public view returns(string memory) {
        return names[i];
    }
}