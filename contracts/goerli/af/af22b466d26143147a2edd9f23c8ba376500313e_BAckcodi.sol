/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

contract BAckcodi {
    string _data;
    
    function fuckMeDaddy(string memory data) external {
        _data = data;
    }
    
    function callMeBitch() public view returns(string memory) {
        return _data;
    }
}