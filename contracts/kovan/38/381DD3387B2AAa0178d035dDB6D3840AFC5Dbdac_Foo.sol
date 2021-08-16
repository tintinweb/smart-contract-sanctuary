/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity 0.8.4;

contract Foo {
    event E1();
    event E2();

    function Boo() external {
        emit E1();
    }
    
    function Woo() external {
        emit E2();
    }
}