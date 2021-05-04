/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//young do jang

pragma solidity 0.8.0;
    contract Likelion_6_2 {
       
    bytes32 hash;
    function join(uint a, uint b) public { //a = ID, b=password
        hash = keccak256(abi.encodePacked(a,b));
    }   
   
   
    function matching(uint c, uint d) public view returns(bool) {
        bytes32 password = keccak256(abi.encodePacked(c,d));
            if(password ==hash) {
                return (true);   
            }else return (false);
        }
    }