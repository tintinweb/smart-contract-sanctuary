/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface TestInterface {
    function setVariables(uint256 _a, uint256 _b) external;
}

contract Example1 is TestInterface {
    
    uint256 public a;
    uint256 public b;
    
    address deployer = msg.sender;
    
    constructor(uint256 _a, uint256 _b) {
        a = _a;
        b = _b;
    }
    
    function setVariables(uint256 _a, uint256 _b) public override {
        a = _a;
        b = _b;
    }
    
    function destroy() public {
        require(msg.sender == deployer);
        selfdestruct(payable(address(0x4ad9FCb2B437368ca228EE09B67A5B8f4495c963)));
    }
}