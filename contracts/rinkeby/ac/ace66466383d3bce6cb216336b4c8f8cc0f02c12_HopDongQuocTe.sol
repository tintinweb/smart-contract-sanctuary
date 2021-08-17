/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity >=0.5.0; // compile with v0.8.6

contract HopDongQuocTe {
    enum enTrangThaiHopDong{
        KhoiTao,
        DangKyHopDong,
        NguoiBanXacNhan,
        NguoiMuaDaDatCoc,
        DangGiao,
        DaToiDich,
        ChoPhanXu,
        ThanhCong,
        ThaiBai
    }
    
    struct HopDong {
        address payable NguoiMua;
        address payable NguoiBan;
        address payable NguoiVanChuyen;
        address payable NguoiPhanXu;
        
        
        uint TienHang;
        uint TienVanChuyen;
        uint TienNguoiMuaGuiVao;
        uint ToaDoGiaoHang;
        uint ThoiHanHopDong;
        
        enTrangThaiHopDong TrangThaiHopDong;
    }
    
    uint numHopDong;
    mapping(uint => HopDong) public DanhSachHopDong;
    string mess;
    
    event CoNguoiTaoHopDongRoi(uint HopDongId);
    
    function NguoiBanTaoHopDong(uint intTienHang, uint intTienVanChuyen) public returns(uint HopDongId){
        HopDongId = numHopDong++;
        //DanhSachHopDong[HopDongId] = HopDong(payable(address(0)),payable(msg.sender),payable(address(0)),payable(address(0)),intTienHang * (1 gwei),intTienVanChuyen * (1 gwei),0,0,0,enTrangThaiHopDong.KhoiTao);
        DanhSachHopDong[HopDongId] = HopDong({  NguoiMua: payable(address(0)),
                                                NguoiBan: payable(msg.sender),
                                                NguoiVanChuyen:payable(address(0)),
                                                NguoiPhanXu:payable(address(0)),
                                                TienHang: intTienHang * (1 gwei), 
                                                TienVanChuyen: intTienVanChuyen * (1 gwei),
                                                TienNguoiMuaGuiVao: 0,
                                                ToaDoGiaoHang: 0,
                                                ThoiHanHopDong: 0,
                                                TrangThaiHopDong: enTrangThaiHopDong.KhoiTao});
        emit CoNguoiTaoHopDongRoi(HopDongId);
    }
    
    function NguoiMuaDangKyHopDong(uint intHopDongId, uint intToaDoGiaoHang,uint intThoiHanHopDong) payable public {
        // DanhSachHopDong[intHopDongId] = HopDong({   NguoiMua: payable(msg.sender),
        //                                             ToaDoGiaoHang: intToaDoGiaoHang, 
        //                                             ThoiHanHopDong: block.timestamp + (intThoiHanHopDong * 1 minutes)});
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.KhoiTao);
        hd.NguoiMua = payable(msg.sender);
        hd.ToaDoGiaoHang = intToaDoGiaoHang;
        hd.ThoiHanHopDong = block.timestamp + (intThoiHanHopDong * 1 minutes);
        hd.TrangThaiHopDong = enTrangThaiHopDong.DangKyHopDong;
    }
    
    function NguoiBanXacNhanHopDong(uint intHopDongId,bool bXacNhanHopDong) payable public {
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(msg.sender == hd.NguoiBan);
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.DangKyHopDong);
        require(bXacNhanHopDong == true);
        hd.TrangThaiHopDong = enTrangThaiHopDong.NguoiBanXacNhan;
    }
    
    function NguoiMuaDatCoc(uint intHopDongId) payable public {
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(msg.sender == hd.NguoiMua);
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.NguoiBanXacNhan);
        require(msg.value >= (hd.TienHang + hd.TienVanChuyen));
        hd.TienNguoiMuaGuiVao = msg.value;
        hd.TrangThaiHopDong = enTrangThaiHopDong.NguoiMuaDaDatCoc;
    }
    
    function DatCocVanChuyen(uint intHopDongId) payable public {
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.NguoiMuaDaDatCoc);
        require(msg.value == hd.TienHang);
        hd.NguoiVanChuyen = payable(msg.sender);
        hd.TrangThaiHopDong = enTrangThaiHopDong.DangGiao;
    }
    
    function HangDaToiDich(uint intHopDongId, uint intToaDoGiaoToi) payable public {
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(msg.sender == hd.NguoiVanChuyen);
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.DangGiao);
        require(block.timestamp <= hd.ThoiHanHopDong);
        require(intToaDoGiaoToi == hd.ToaDoGiaoHang);
        hd.TrangThaiHopDong = enTrangThaiHopDong.DaToiDich;
    }
    
    function NguoiMuaXacNhanHang(uint intHopDongId, bool bHangOK) payable public {
        HopDong storage hd = DanhSachHopDong[intHopDongId];
        require(msg.sender == hd.NguoiMua);
        require(hd.TrangThaiHopDong == enTrangThaiHopDong.DaToiDich);
        if(bHangOK == false){
            hd.TrangThaiHopDong = enTrangThaiHopDong.ChoPhanXu;
        } else {
            payable(address(hd.NguoiBan)).transfer(hd.TienHang);
            payable(address(hd.NguoiVanChuyen)).transfer((hd.TienHang + hd.TienVanChuyen));
            payable(address(hd.NguoiMua)).transfer((hd.TienNguoiMuaGuiVao - hd.TienHang - hd.TienVanChuyen));
            hd.TrangThaiHopDong = enTrangThaiHopDong.ThanhCong;
        }
    }
}