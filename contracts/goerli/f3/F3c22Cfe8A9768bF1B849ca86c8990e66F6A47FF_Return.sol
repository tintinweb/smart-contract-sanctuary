/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.8.0;

contract Return {
    function ret(address arg) public returns (bytes memory){
        return abi.encode(arg);
    }
}