/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyBlockchainShop {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier checkMaster {
        require(msg.sender == owner, "[001] Sorry, you are not allowed.");
        _;
    }

    event Co_Nguoi_Moi_Thanh_Toan_Kia(string donHangID, uint money);

    function thanhToan(string memory donHangID) public payable {
        require(msg.value > 0, "[002] Money must not be zero");
        emit Co_Nguoi_Moi_Thanh_Toan_Kia(donHangID, msg.value);
    }

    function rutTien(address nguoiNhan) public checkMaster{
        require(address(this).balance > 0, "[003] Sorry, do not have money to withdraw");
        payable(nguoiNhan).transfer(address(this).balance);
    }
}