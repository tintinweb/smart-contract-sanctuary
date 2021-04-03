/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.4.18;
contract hello {
    string greeting="hello,world!";

    function hello(string _greeting) public {
        greeting = _greeting;
    }

    function say() constant public returns (string) {
        return greeting;
    }
}