/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File: artifacts/sample.sol



pragma solidity >=0.7.0 <0.8.0;

contract HelloWorld {

    string public massage;

    constructor (){
        massage = 'HelloWorld';
    }

    function update (string memory _msg) public {
        massage = _msg;
    }
}