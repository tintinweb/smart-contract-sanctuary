/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SCDemo {
    
    string noidung;
    
    function setNoiDung(string memory _noidung) public  {
        noidung = _noidung;
    }
    
    function getNoiDung() view public returns(string memory){
        return noidung;
    }
    
    
}