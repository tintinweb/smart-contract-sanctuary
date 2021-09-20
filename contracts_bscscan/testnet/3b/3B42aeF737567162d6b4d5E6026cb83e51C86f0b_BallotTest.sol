/**
 *Submitted for verification at BscScan.com on 2021-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


contract BallotTest {
    
    string noidung;
    
    function getNoiDung() view public returns(string memory) {
        return noidung;
    }
    
    function setNoiDung(string memory _noidung) public {
        noidung = _noidung;
    }
   
    
}