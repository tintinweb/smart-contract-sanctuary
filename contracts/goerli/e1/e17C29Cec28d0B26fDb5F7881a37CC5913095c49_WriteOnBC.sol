/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract WriteOnBC{
    string sTexto;
    
    function fWrite(string calldata _sTexto) public {
        sTexto = _sTexto;
    }
    
    function fRead() public view returns(string memory) {
        return sTexto;
    }
}