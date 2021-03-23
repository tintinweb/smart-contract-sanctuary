/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity >=0.4.22 <0.7.0;

contract TestReverter {

    function foo() external {
        require(false, "hi mom");
    }
    
    function bar() external {
        require(false, "hi mom 2");
    }
}