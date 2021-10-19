/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

pragma solidity ^0.6.12;

contract Test{

    function TestError() external{
        require(false,"Test");
    }
}