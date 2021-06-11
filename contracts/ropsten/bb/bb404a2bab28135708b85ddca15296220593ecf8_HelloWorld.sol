/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// My First Smart Contract 
pragma solidity >=0.5.0 <0.7.0;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}