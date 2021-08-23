/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NganHang is Ownable{
    
    IERC20 public KhoTien;
    
    uint public TongSoGiaoDich;
    
    uint8 public TyLePhiGiaoDich;
    
    struct GiaoDichChuyenTien{
        address NguoiGui;
        address NguoiNhan;
        uint    ThoiGianGui;
        uint    SoTien;
        uint    PhiGiaoDich;
    }
    
    mapping (uint => GiaoDichChuyenTien) public DanhSachTatCaGiaoDich;
    
    mapping (address => uint[]) public DSGDNguoiGui;
    
    mapping (address => uint[]) public DSGDNguoiNhan;
    
    //khoi tao conytract can dien thong tin KhoTien va TyLePhiGiaoDich (la so nguyen 1-100)
    constructor(address _KhoTien,uint8 _TyLePhiGiaoDich){
        KhoTien = IERC20(_KhoTien);
        TongSoGiaoDich = 0;
        TyLePhiGiaoDich = _TyLePhiGiaoDich;
    }
    
    //thong bao doi ti le thanh cong
    event DoiTyLePhiGiaoDichThanhCong();
    
    //thong bao giao dich thanh cong
    event GiaoDichThanhCong();
    
    //thay doi ty le phi giao dich cho hop dong
    function DoiTyLePhiGiaoDich(uint8 _TyLePhiGiaoDich) public onlyOwner{
        
        require(_TyLePhiGiaoDich>0,"Pham tram giao dich phai lon hon 0 !");
        
        // set lai ty le phi giao dich
        TyLePhiGiaoDich = _TyLePhiGiaoDich;
        
        // Thong bao doi thanh cong
        emit DoiTyLePhiGiaoDichThanhCong();
    }
    
    // ChuyenTien
    function ChuyenTien(address _NguoiNhan, uint _SoTien) public{
        
        // Kiem tra so du trong tai khoan cua nguoi gui
        require ( KhoTien.balanceOf(msg.sender) >= _SoTien, "So tien trong vi khong du !");
        
        // Kiem tra nguoi gui co phai la nguoi nhan
        require ( msg.sender != _NguoiNhan,"Nguoi nhan va nguoi gui phai khac nhau!");
        
        // Tang ma cua gia dich
        uint _MaGiaoDich = TongSoGiaoDich +1;
        
        // Tang so luong giao dich
        TongSoGiaoDich +=1;
        
        //Tinh phi giao dich
        uint _PhiGiaoDich = _SoTien*TyLePhiGiaoDich/10000;
        
        //mapping giao dich vao danh sach bang ma giao dich
        DanhSachTatCaGiaoDich[_MaGiaoDich] = GiaoDichChuyenTien({NguoiGui: msg.sender, NguoiNhan:_NguoiNhan,ThoiGianGui:block.timestamp,SoTien:_SoTien,PhiGiaoDich:_PhiGiaoDich});
        
        //mapping dia chi nguoi gui voi ma giao dich
        DSGDNguoiGui[msg.sender].push(_MaGiaoDich);
        
        //mapping dia chi nguoi nhan voi ma giao dich
        DSGDNguoiNhan[_NguoiNhan].push(_MaGiaoDich);
        
        //Chuyen tien cho contract 
        KhoTien.transferFrom(msg.sender,address(this),_SoTien);
        
        //Chuyen lai phi giao dich cho chu contract
        KhoTien.transfer(owner(),_PhiGiaoDich);
        
        //So tien nguoi nhan se nhan duoc sau khi tru phi
        uint _SoTienGuiVe = _SoTien - _PhiGiaoDich;
        
        //Chuyen tien cho nguoi nhan so tien da tru chi giao dich
        KhoTien.transfer(_NguoiNhan,(_SoTienGuiVe));
        
        emit GiaoDichThanhCong();
    }
    
    // Lay Danh Sach Nhan Tien
     function LayDanhSachBienLaiNhanTien(address _NguoiNhan) public view returns(uint[] memory) {
        return DSGDNguoiNhan[_NguoiNhan];
    }
    
    // Lay Danh Sach Nhan Tien
     function LayDanhSachBienLaiGuiTien(address _NguoiGui) public view returns(uint[] memory) {
        return DSGDNguoiGui[_NguoiGui];
    }
}