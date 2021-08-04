/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IFactory{
     function addT()external;
}
contract Type {
    address public factory;
    function setFactory(address _factory) external {
        factory = _factory;
    }
    function addT() external {
        IFactory(factory).addT();
    }
}