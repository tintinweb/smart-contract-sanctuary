/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.24;
contract class30{
    uint8 public aaa = 0;
    function keccak_256(string str)public returns(bytes32){
        aaa += 1;
        return keccak256(abi.encodePacked(str));
    }
    
    function keccak_256_2(string str1,string str2)public pure returns(bytes32){
        return keccak256(abi.encodePacked(str1,str2));
    }
        //keccak256(abi.encodePacked("hello world")) == keccak256(abi.encodePacked("hello", " world"));兩者相等
    
    function sha_3(string str)public pure returns(bytes32){
        return sha3(abi.encodePacked(str));
    }
    
    //sha3(abi.encodePacked(str)) == keccak256(abi.encodePacked(str)); always use keccak256

    function sha_256(string str)public pure returns(bytes32){
        return sha256(abi.encodePacked(str));
    }
    //亂數產生
    function random()public view returns(uint){
         bytes32 result = keccak256(abi.encodePacked(block.coinbase,
blockhash(block.number-1)));
         return uint(result) % 1000 + 1;
    }
}