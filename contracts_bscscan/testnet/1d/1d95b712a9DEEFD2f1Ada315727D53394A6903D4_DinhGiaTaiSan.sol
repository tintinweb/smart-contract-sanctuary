/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

contract DinhGiaTaiSan is AccessControl{
    
   // tao role 
   bytes32 public constant NHATHAMDINH_ROLE = keccak256("NHATHAMDINH_ROLE");
   //bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
   
   //tong so yeu cau
   uint public TongSoYeuCau ;
   
   //enum trang thai nguoi yeu cau
   enum enTrangThaiYeuCauNTD{YeuCau, ChapNhan, KhongChapNhan}
   
   //thong tin nguoi yeu cau
   struct ThongTinNguoiYeuCau {
       address      DiaChiVi;
       string       HoVaTen;
       uint         Tuoi;
       uint         SoDienThoai;
       string       Email;
       enTrangThaiYeuCauNTD     TrangThai;
   }
   
   //map uint voi Thong tin nguoi yeu cau
    mapping(uint => ThongTinNguoiYeuCau) DanhSachYeuCau;
    
    //Mang address NhaThamDinh
    address[]       DanhSachNhaThamDinh;
    
    //map address NhaThamDinh voi ma hash thong tin;
    mapping(address => bytes32) DanhSachThongTinNhaThamDinh;
    
    //Tong so tai san yeu cau phe duyet
    uint public TongSoTaiSanYeuCauThamDinh ;
   
    // enum TrangThaiTaiSan
    enum enTrangThaiTaiSan {YeuCau, DaThamDinh, HuyBo}
    
    struct TaiSan {
        uint        MaTaiSan;
        string      TenTaiSan;
        string      MauSac; 
        uint8       TrongLuong;
        uint        ThoiGianTao;
        string      ThongTinBoXung;
        uint        Gia;
        bytes32     MaHashThongTinTaiSan;
        string      LyDoHuyBo;
        address     NguoiThamDinh;
        enTrangThaiTaiSan TrangThai; 
    }
    
    
    //map uint(so yeu cau tham dinh) voi TaiSan
    mapping(uint => TaiSan) DanhSachTaiSanYeuCauTao;
    
    //map uint(so yeu cau tham dinh voi TaiSan)
    mapping(uint => TaiSan) DanhSachTaiSanDaThamDinh;
    
    //map address nguoi dung voi danh sach tai san yeu cau 
    mapping(address => uint[]) DanhSachTaiSanSoHuu; 
    
    
    uint public TongSoTaiSanDaThamDinh;
    
    
    constructor()  {
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
    
    // modifier KiemTraNguoiTaoGoiHam(){
    //     require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ban khong co quyen truy cap");
    //     _;
    // }
    
    event evYeuCauThanhNhaThamDinhRoi(uint maYeuCau);
    event evPheDuyetYeuCauThanhNhaThamDinhRoi();
    event evThemMoiNhaThamDinhRoi();
    event evGoBoQuyenNhaThamDinhRoi();
    event evYeuCauThamDinhTaiSanRoi();
    event evThamDinhTaiSanRoi();
    event evHuyBoThamDinhTaiSanRoi();
    
    function YeuCauThanhNhaThamDinh (string memory _HoVaTen , uint _Tuoi, uint _SoDienThoai, string memory _Email) public returns (uint maYeuCau) {
        
        //kiem tra admin YeuCauThanhNhaThamDinh
        require(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ban khong co quyen truy cap");
        
        //kiem tra nha tham dinh YeuCauThanhNhaThamDinh
        require(!hasRole(NHATHAMDINH_ROLE, msg.sender), "Ban da la nha tham dinh");
        
        //Kiem tra Thong tin khong duoc rong
        require(bytes(_HoVaTen).length > 0,'Khong duoc bo trong _HoVaTen');
        require(_Tuoi > 0,'_Tuoi Khong duoc Nho ho hoac bang 0');
        require(bytes(_Email).length > 0,'Khong duoc bo trong _Email'); 
        
        uint MaYeuCau = TongSoYeuCau  + 1;
        TongSoYeuCau +=1 ;
        DanhSachYeuCau[MaYeuCau] =  ThongTinNguoiYeuCau({
                                    DiaChiVi :   msg.sender,
                                    HoVaTen :    _HoVaTen,
                                    Tuoi :       _Tuoi, 
                                    SoDienThoai: _SoDienThoai,
                                    Email :      _Email,
                                    TrangThai : enTrangThaiYeuCauNTD.YeuCau});  
                                    
        emit evYeuCauThanhNhaThamDinhRoi(MaYeuCau);
        return MaYeuCau;
        
    }
    
    function PheDuyetYeuCauThanhNhaThamDinh (uint _MaYeuCau) public {
        
        //kiem tra co phai la admin khong
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ban khong co quyen phe duyet");
         
        //Kiem tra Thong tin khong duoc rong
        require(_MaYeuCau >= 0,'MaYeuCau Khong Ton Tai');

        ThongTinNguoiYeuCau storage objNguoiYeuCau = DanhSachYeuCau[_MaYeuCau];
         
         address DiaChiViNYC = objNguoiYeuCau.DiaChiVi;
         
         bytes32 HashThongTinNTD = bytes32(keccak256(abi.encodePacked(objNguoiYeuCau.HoVaTen , objNguoiYeuCau.Tuoi , objNguoiYeuCau.SoDienThoai , objNguoiYeuCau.Email)));

         //Them vao mang Nha Tham Dinh
         DanhSachNhaThamDinh.push(DiaChiViNYC);
         
         //Them thong tin hash cua nguoi yeu cau vao danh sach thong tin 
         DanhSachThongTinNhaThamDinh[DiaChiViNYC] = HashThongTinNTD;
         
         //set quyen NHATHAMDINH_ROLE cho nguoi yeu cau
         grantRole(NHATHAMDINH_ROLE,DiaChiViNYC);
         
         //set trang thai nguoi yeu cau thanh ChapNhan
         objNguoiYeuCau.TrangThai = enTrangThaiYeuCauNTD(1);
         
         emit evPheDuyetYeuCauThanhNhaThamDinhRoi();
         
    }
    
    function ThemMoiNhaThamDinh (address _DiaChiVi, string memory _HoVaTen , uint _Tuoi, uint _SoDienThoai, string memory _Email) public {
        
        //kiem tra co phai la admin khong
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ban khong co quyen Them Moi Nha Tham Dinh");
         
         //Kiem tra Thong tin khong duoc rong
        require(_DiaChiVi != address(0) ,'Khong duoc bo trong _DiaChiVi');
        require(bytes(_HoVaTen).length > 0,'Khong duoc bo trong _HoVaTen');
        require(_Tuoi > 0,'_Tuoi Khong duoc Nho ho hoac bang 0');
        require(bytes(_Email).length > 0,'Khong duoc bo trong _Email'); 
         
         uint MaYeuCau = TongSoYeuCau  + 1;
         TongSoYeuCau +=1 ;
         DanhSachYeuCau[MaYeuCau] = ThongTinNguoiYeuCau({
                                    DiaChiVi :   _DiaChiVi,
                                    HoVaTen :    _HoVaTen,
                                    Tuoi :       _Tuoi, 
                                    SoDienThoai: _SoDienThoai,
                                    Email :      _Email,
                                    TrangThai :  enTrangThaiYeuCauNTD.YeuCau});  
        
        //Bam thong tin NhaThamDinh
        bytes32 HashThongTinNTD = bytes32(keccak256(abi.encodePacked(_HoVaTen , _Tuoi, _SoDienThoai ,_Email)));
        
        //them address NhaThamDinh vao mang nha tham dinh
        DanhSachNhaThamDinh.push(_DiaChiVi);
        
        //map address voi hash thong tin 
        DanhSachThongTinNhaThamDinh[_DiaChiVi] = HashThongTinNTD;
        
        //set quyen cho nguoi yeu cau; 
        grantRole(NHATHAMDINH_ROLE,_DiaChiVi);

        emit evPheDuyetYeuCauThanhNhaThamDinhRoi();
    }
    
    function GoBoQuyenNhaThamDinh(address _DiaChiNhaThamDinh) public   {
        
        //kiem tra nguoi goi co phai la admin
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Ban khong co quyen Go Bo Quyen Nha Tham Dinh");
        
        //go bo quyen cua nha tham dinh
        revokeRole(NHATHAMDINH_ROLE, _DiaChiNhaThamDinh);
        
        emit evGoBoQuyenNhaThamDinhRoi();
        
    }
    
    function YeuCauTaoTaiSan(string memory _TenTaiSan ,string memory _MauSac ,uint8 _TrongLuong) public returns(uint maTaiSan) {
        
        //Kiem tra Thong tin khong duoc rong
        require(bytes(_TenTaiSan).length > 0,'Khong duoc bo trong TenTaiSan');
        require(bytes(_MauSac).length > 0,'Khong duoc bo trong MauSac');
        require(_TrongLuong > 0,'TrongLuong Khong duoc Nho ho hoac bang 0');
        
        uint MaTaiSan = TongSoTaiSanYeuCauThamDinh  + 1;
        
        TongSoTaiSanYeuCauThamDinh +=1 ;
        
        DanhSachTaiSanYeuCauTao[MaTaiSan] = TaiSan({
                                            MaTaiSan        : MaTaiSan,
                                            TenTaiSan       : _TenTaiSan,
                                            MauSac          : _MauSac,
                                            TrongLuong      : _TrongLuong,
                                            ThoiGianTao     : block.timestamp,
                                            ThongTinBoXung  : '',
                                            Gia             : 0,
                                            MaHashThongTinTaiSan : 0x0 ,
                                            LyDoHuyBo       : "" ,
                                            NguoiThamDinh   : address(0), 
                                            TrangThai       : enTrangThaiTaiSan.YeuCau
                                            });
        
        //them MaTaiSan vao mang theo add nguoi tao
        DanhSachTaiSanSoHuu[msg.sender].push(MaTaiSan);                                        

        emit evYeuCauThamDinhTaiSanRoi();
        
        return MaTaiSan;
    }
    
    function ThamDinhTaiSan(uint _MaTaiSan ,string memory _ThongTinBoXung ,uint _GiaDuocDinh) public  {
        
        //check quyen tham dinh
        require(hasRole(NHATHAMDINH_ROLE, msg.sender), "Ban khong co quyen tham dinh");
        
        //check quyen tham dinh
        require(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin khong the tham dinh tai san ");
        
        //check nguoi tham dinh ,tham dinh tai san cua minh
        uint[] memory TaiSanSoHuu = DanhSachTaiSanSoHuu[msg.sender];
        
        for(uint i = 0 ; i < TaiSanSoHuu.length ; i++ ){
            if(TaiSanSoHuu[i] == _MaTaiSan){
                revert("Ban khong the tham dinh tai san cua minh");
            }
        }

        //check trang thai
        TaiSan storage objTaiSan = DanhSachTaiSanYeuCauTao[_MaTaiSan];
        
        require(objTaiSan.MaTaiSan == _MaTaiSan,'Ma tai san khong hop le');
        
        require(objTaiSan.TrangThai == enTrangThaiTaiSan.YeuCau, "Tai san da duoc tham dinh hoac huy bo" );
        
        bytes32 _MaHashThongTinTaiSan = bytes32(keccak256(abi.encodePacked(objTaiSan.MaTaiSan , 
                                                                           objTaiSan.TenTaiSan , 
                                                                           objTaiSan.MauSac ,
                                                                           objTaiSan.TrongLuong, 
                                                                           objTaiSan.ThoiGianTao)));
        
        objTaiSan.NguoiThamDinh = msg.sender;
        objTaiSan.ThongTinBoXung = _ThongTinBoXung;
        objTaiSan.Gia = _GiaDuocDinh; 
        objTaiSan.MaHashThongTinTaiSan = _MaHashThongTinTaiSan;
        objTaiSan.TrangThai = enTrangThaiTaiSan(1);
        
        TongSoTaiSanDaThamDinh +=1 ; 
        
        emit evThamDinhTaiSanRoi();
        
    }
    
    function HuyBoThamDinh(uint _MaTaiSan ,string memory _LyDoHuyBo ) public  {
        
        //check quyen tham dinh
        require(hasRole(NHATHAMDINH_ROLE, msg.sender), "Ban khong co quyen tham dinh");
        
        //check quyen tham dinh
        require(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin khong the tham dinh tai san ");
        
        //check trang thai
        TaiSan storage objTaiSan = DanhSachTaiSanYeuCauTao[_MaTaiSan];
        
        require(objTaiSan.MaTaiSan == _MaTaiSan,'Ma tai san khong hop le');
        
        require(objTaiSan.TrangThai == enTrangThaiTaiSan.YeuCau, "Tai san da duoc tham dinh hoac huy bo" );
        
        objTaiSan.TrangThai = enTrangThaiTaiSan(2);
        objTaiSan.LyDoHuyBo = _LyDoHuyBo;

        emit evHuyBoThamDinhTaiSanRoi();
        
    }
    
    // Lay Danh Sach Tai san
    function LayDanhSachTaiSan(address _NguoiDung) public view returns(uint[] memory) {
        return DanhSachTaiSanSoHuu[_NguoiDung];
    }
    
    // Lay Danh Sach Nha Tham Dinh
    function LayDanhSachNhaThanDinh() public view returns(address[] memory) {
        return DanhSachNhaThamDinh;
    }
    
    

}