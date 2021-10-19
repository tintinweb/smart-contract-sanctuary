/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.6.12;

contract Test{

    function TestError() external{
        require(false,"Test");
    }
}