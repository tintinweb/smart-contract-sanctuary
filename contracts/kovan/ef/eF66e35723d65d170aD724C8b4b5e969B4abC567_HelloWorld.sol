/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.8.0;

contract HelloWorldBase {
    function hello() public pure virtual returns (uint256) {
        return 1;
    }
}

contract HelloWorld is HelloWorldBase {
    function hello() public pure override returns (uint256) {
        return 2;
    }
}