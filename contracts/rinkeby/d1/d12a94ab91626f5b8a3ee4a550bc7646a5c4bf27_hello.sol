/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.4.18;
contract hello {
    string greeting;

    function hello(string _greeting) public {
        greeting = _greeting;
    }

    function say() constant public returns (string) {
        return greeting;
    }
}