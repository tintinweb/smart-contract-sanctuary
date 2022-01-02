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
    string TENSANPHAM;
    string THOIGIANTRONG;
    string PHANBON;
    string THUONGHIEU;
    string LOAICHUNGNHAN;
    }

    event SM_gui_data(address _vi, string _id);

    function KHDangKy(
        string memory _id, 
        string memory Tensanpham, 
        string memory Thoigiantrong, 
        string memory Phanbon, 
        string memory Thuonghieu,
        string memory Loaichungnhan) 
        public {
	    Sanpham memory sanphamMoi = Sanpham (_id, msg.sender, Tensanpham, Thoigiantrong, Phanbon, Thuonghieu, Loaichungnhan);
        arrSanpham.push(sanphamMoi);
        emit SM_gui_data(msg.sender, _id);
    }
}