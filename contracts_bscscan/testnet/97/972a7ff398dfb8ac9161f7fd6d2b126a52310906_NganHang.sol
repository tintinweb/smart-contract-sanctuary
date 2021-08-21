/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NganHang {
    address owner;
    IERC20 public KhoTien;
    
    uint PhanTramPhiGiaoDichTu = 5;
    uint PhanTramPhiGiaoDichMau = 10000;
    
    constructor(address addrKhoTien, address addrOwner) {
        KhoTien = IERC20(addrKhoTien);
        owner = addrOwner;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    function ThayDoiKhoTien(address addrKhoTien) public onlyOwner {
        KhoTien = IERC20(addrKhoTien);
    }
    
    uint TongSoGiaoDich;
    struct GiaoDich
    {
        address TaiKhoanNguoiGui;
        address TaiKhoanNguoiNhan;
        uint SoTien;
    }
    mapping(uint => GiaoDich) DanhSachGiaoDich;
    
    mapping(address => uint[]) LichSuGiaoDichCuaNguoiDung; 
    
    event TaoGiaoDichRoi(uint sttGiaoDich);
    function TaoGiaoDich(address addrTaiKhoanNguoiNhan,uint intSoTien ) public {
        uint PhiGiaoDich = mulDiv(intSoTien, PhanTramPhiGiaoDichTu, PhanTramPhiGiaoDichMau);
        
        KhoTien.transferFrom(msg.sender, owner, PhiGiaoDich);
        KhoTien.transferFrom(msg.sender, addrTaiKhoanNguoiNhan, intSoTien - PhiGiaoDich);
        
        TongSoGiaoDich++;
        GiaoDich storage objGiaoDich = DanhSachGiaoDich[TongSoGiaoDich];
        objGiaoDich.TaiKhoanNguoiGui = msg.sender;
        objGiaoDich.TaiKhoanNguoiNhan = addrTaiKhoanNguoiNhan;
        objGiaoDich.SoTien = intSoTien;
        
        LichSuGiaoDichCuaNguoiDung[msg.sender].push(TongSoGiaoDich);
        
        emit TaoGiaoDichRoi(TongSoGiaoDich);
    }
    
    function XemGiaoDich(uint sttGiaoDich) public view returns(GiaoDich memory objGiaoDich) {
        return DanhSachGiaoDich[sttGiaoDich];
    }
    
    function XemGiaoDichCuaTaiKhoan(address addrTaiKhoan) public view returns(GiaoDich[] memory) {
        uint[] memory DanhSachMaGiaoDich = LichSuGiaoDichCuaNguoiDung[addrTaiKhoan];
        GiaoDich[] memory arrDanhSachGiaoDich = new GiaoDich[](DanhSachMaGiaoDich.length);
        for(uint i=0; i<DanhSachMaGiaoDich.length; i++) {
            arrDanhSachGiaoDich[i] = (DanhSachGiaoDich[DanhSachMaGiaoDich[i]]);
        }
        return arrDanhSachGiaoDich;
    }
    
    
    function mulDiv (uint x, uint y, uint z)
    private pure returns (uint)
    {
      uint a = x / z; uint b = x % z; // x = a * z + b
      uint c = y / z; uint d = y % z; // y = c * z + d
    return a * b * z + a * d + b * c + b * d / z;
    }
}