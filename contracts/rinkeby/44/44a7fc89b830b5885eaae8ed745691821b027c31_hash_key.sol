/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.4.24;

contract hash_key{

    mapping(bytes32 => string)public value;

    function set_hash(string key, string word)public {
         bytes32 mark =  keccak256(abi.encodePacked(word));   
         value[mark] = key;
    }


    function get_key(string word)public view returns(string){
        bytes32 mark =  keccak256(abi.encodePacked(word));  
        return value[mark];
    }




}