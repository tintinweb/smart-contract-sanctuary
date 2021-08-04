/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity 0.6.10;

contract A2{
    function helloWorld() public pure returns(string memory){
        return "hello world!";
    }
}

contract A1 is A2{
    function byeWorld() public pure returns(string memory){
        return "bye world!";
    }
}