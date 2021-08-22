/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

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

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract NganHang {
    
    using Address for address;
    
    IERC20 public KhoTien;
    
    address NguoiTao;
    
    struct GiaoDich {
        
        address payable nguoiChuyen;
        address payable nguoiNhan;
        uint            tienChuyen;
        uint            phiGiaoDich;
    }
    
    uint numGiaoDich;
    
    mapping(address => GiaoDich) public DanhSachGiaoDich;
    
    constructor(address adDiaChiKhoTien) public {
        NguoiTao = msg.sender;
        KhoTien = IERC20(adDiaChiKhoTien);
    }
    
    function ChuyenTien(address AddNguoiNhan, uint intTienChuyen) public  {
   
       // require(Address.isContract(msg.sender) || Address.isContract(AddNguoiNhan));
        
        DanhSachGiaoDich[address(msg.sender)] = GiaoDich({
            nguoiChuyen :payable(msg.sender),
            nguoiNhan : payable(AddNguoiNhan) ,
            tienChuyen : intTienChuyen,
            phiGiaoDich : 5
        }); 
        
        require(KhoTien.balanceOf(msg.sender) >= intTienChuyen * (1 ether));
        KhoTien.approve(address(this), intTienChuyen * (1 ether));
        
        KhoTien.transferFrom(msg.sender, address(this), ((intTienChuyen * 5) / 1000 * (1 ether) ));
        
        KhoTien.transfer(AddNguoiNhan, intTienChuyen * (1 ether));

    }
    
    // function DanhSachHopDong( address NguoiTaoGD) public returns(GiaoDich giaoDich) {
    //     GiaoDich giaodich = DanhSachGiaoDich[NguoiTaoGD];
    //     returns giaodich;
    // }
    
}