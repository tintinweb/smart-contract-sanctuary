/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity ^0.5.7;

contract greeter{

        string greeting;

        function greet(string memory _greeting)public{
                greeting=_greeting;
        }
        
        function getGreeting() public view returns(string memory) {
                return greeting;
        }
}