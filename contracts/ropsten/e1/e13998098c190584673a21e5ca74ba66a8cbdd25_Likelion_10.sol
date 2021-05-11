/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//young do jang
pragma solidity 0.8.0;

contract Likelion_10 {
    bytes32 hash;
    bytes32 hash2;
    uint a;
    uint b;
    uint[] password = [0,4,a,b];
    
    function setpassword() public {
        hash = keccak256(abi.encodePacked("0429"));
        }
    
    function calculate() public returns(uint,uint) {

        
        for(a =0;a <10;a++) {
            for(b =0; b < 10; b++) {
                hash2 = keccak256(abi.encodePacked(password));
                if(hash == hash2) {
                    break;
                }
            }
        }
        
        return(a, b);
        
    }
}