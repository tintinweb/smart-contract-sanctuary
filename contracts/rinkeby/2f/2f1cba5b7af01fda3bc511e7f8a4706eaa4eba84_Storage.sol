/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity >=0.6.0 <0.8.0;

contract Storage {
    function getMessage() public pure returns(string memory) {
        string memory message = "TAF Chain官方公布全网总发行量预计3000000000 TAFT";
        return message;
    }
}