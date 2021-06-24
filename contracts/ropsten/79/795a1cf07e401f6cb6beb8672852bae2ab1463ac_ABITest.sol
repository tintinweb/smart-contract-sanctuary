/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.12;
 


 
contract ABITest {
   

    
    function getHash(
    string memory txKey, address to,bool isERC20, address ERC20,uint8 version) public view returns (bytes32) {
        return keccak256(abi.encodePacked(txKey, to, isERC20, ERC20, version));
    }
}