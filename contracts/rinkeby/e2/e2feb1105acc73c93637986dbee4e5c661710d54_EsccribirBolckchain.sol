/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract EsccribirBolckchain{
    string data;
    
    function set(string calldata _data) public {
        data = _data;
    }
    
    function get() public view returns(string memory) {
        return data;
    }
    
}