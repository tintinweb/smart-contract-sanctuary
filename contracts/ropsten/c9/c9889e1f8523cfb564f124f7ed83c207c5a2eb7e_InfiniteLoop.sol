/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.10;

contract InfiniteLoop {

    uint num = 0;

    event internal_called(uint num);

    function externalCall() public {
        internalCall();
    }

    function internalCall() private {
        num++;
        emit internal_called(num);
        require(num <= 10);
        internalCall();
    }
}