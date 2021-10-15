/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Minigame {
    Hocvien[] public arrHocvien;
    
    struct Hocvien {
        string _ID;
        address _VI;
    }
    
    event SM_ban_du_lieu(  string _id,address _vi);
    
    function Register(string memory _id) public {
        Hocvien memory hocvienMoi = Hocvien(_id, msg.sender);
        arrHocvien.push(hocvienMoi);
        emit SM_ban_du_lieu(_id, msg.sender);
    }
}