/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

pragma solidity "0.8.7";


contract A {
    event Mint();
    function mint () public{
        emit Mint();
    }
}