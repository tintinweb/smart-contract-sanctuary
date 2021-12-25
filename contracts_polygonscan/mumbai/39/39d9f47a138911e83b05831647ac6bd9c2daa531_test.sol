/**
 *Submitted for verification at polygonscan.com on 2021-12-24
*/

pragma solidity ^0.8.0;

// 0xaf631d72653d784db1aa0a58a6f26516c125db0a
interface Dao{
    function abcei51243fdgjkh(bytes memory nickname) external returns(bytes32 hash);
}

contract test {
    function hashString(string memory name) public pure returns(bytes memory){
        return bytes(name);
    }

    function hashBytes(bytes memory name) public pure returns(bytes32 hash) {
        hash = keccak256(abi.encodePacked(name));
    }

    // 0x00000000
    function atest(bytes memory nickname) public {
        bytes32 hash = keccak256(abi.encodePacked(nickname));
   }
}