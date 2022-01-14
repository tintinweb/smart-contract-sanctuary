/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MiniGame{

    HocVien[] public arrHocVien;

    struct HocVien{
        string _ID;
        address _VI;
    }
    event SM_ban_data(address _vi, string _id);
    function DangKy(string memory _id) public{
        HocVien memory hocVienMoi = HocVien(_id,msg.sender);
        arrHocVien.push(hocVienMoi);
        emit SM_ban_data(msg.sender, _id);
    }
}