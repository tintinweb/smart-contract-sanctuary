/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Product_storage {

    Sanpham[] public arrSanpham;

    struct Sanpham{
    string _ID;
    address _VI;
    string _TENSP;
    string _TGTRONG;
    string _PHANBON;
    string _THUONGHIEU;
    string _CHUNGNHAN;
    }

    event SM_gui_data(address _vi, string _id);

    function KHDangKy(
        string memory _id, 
        string calldata _tensp, 
        string calldata _tgtrong, 
        string calldata _phanbon, 
        string calldata _thuonghieu,
        string calldata _chungnhan) 
        public {
	    Sanpham memory sanphamMoi = Sanpham (_id, msg.sender, _tensp, _tgtrong, _phanbon, _thuonghieu, _chungnhan);
        arrSanpham.push(sanphamMoi);
        emit SM_gui_data(msg.sender, _id);
    }
}