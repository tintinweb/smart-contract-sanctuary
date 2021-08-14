/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

contract Test {
    
    string private _msg;
    
    constructor() {
        _msg = "day ne nhe";
    }
    
    function setMsg(string memory msgsss) external {
        _msg = msgsss;
    }
    
    function getMsg() external view returns(string memory) {
        
        return _msg;
    }
    
    receive() external payable {
        
    }
}