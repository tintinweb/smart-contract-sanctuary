/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_10 {
    uint password = 10429;
    // bytes32 hash = keccak256(bytes32(pw));
    function key () public view returns(uint){
        uint pw = password;
        uint unknown = pw%100;
        for(uint i=0; i<=99; i++){
            if(unknown==i){
                return (i);
            }
        }
    }
}