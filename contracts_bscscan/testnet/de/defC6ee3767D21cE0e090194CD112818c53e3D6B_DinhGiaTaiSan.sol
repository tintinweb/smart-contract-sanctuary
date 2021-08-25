/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAccessControl {
   
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

   
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) external view returns (bool);

   
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

   
    function grantRole(bytes32 role, address account) external;

    
    function revokeRole(bytes32 role, address account) external;

    
    function renounceRole(bytes32 role, address account) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
    function toString(uint256 value) internal pure returns (string memory) {
       

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
interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


abstract contract ERC165 is IERC165 {
   
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

   
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    
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

   
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

   
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

   
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

   
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
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

    address admin;
    bytes32 hashThonTin;
    bytes32 public constant newRole = keccak256("Nha_Tham_Dinh");
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        admin = msg.sender;
    }
   
    enum enRole{ChuaDuyet, DaDuyet}
    enum TrangThaiSanpHam{TaoSanPham, DaThamDinh ,HuyBo}
    struct user{
        string thongtin;
        enRole Role;
    }
    
    
    struct NhaThamDinh{
        bytes32 Hashtt;
    }
    
    struct SanPham {
        string thontin;
        address adNguoiTaoSanPham;

    }
    
    enum enNhan{DaThamDinhRoi, HuyBo}
    struct SanPhamDaDuyet{
        enNhan Nhan;
        
        string ThongTinBoXung;
        uint GiaTri;
        bytes32 maHash;
        
    }
    
    struct SanPhamHuyBo{
        enNhan NhanHuy;
        string ThonTinBoXung;
    }
    uint numSanPham;
    uint numSanPhamDaDuyet;
    uint numSanPhamHuy;
    mapping(uint=>SanPhamHuyBo) public SanPhamHuyBos;
    
    mapping(uint=>SanPhamDaDuyet) public SanPhamDaDuyets;
    
    mapping(uint=> SanPham) public SanPhams;
    
    mapping(address=> NhaThamDinh) public NhaThamDinhs;
    
    
    mapping(address=> user) public users;
    
     function ThemNhaThamDinh(address _user,string memory _thongtinUser) public {
        require(admin == msg.sender);
        _setupRole(newRole,_user);
        bytes32 hashTt = keccak256(abi.encodePacked(_thongtinUser));
        NhaThamDinhs[_user] = NhaThamDinh(hashTt);
        
    }
    
    function ThuHoiQuyen(address _NhaThamDinh) public{
        require(admin == msg.sender);
        revokeRole(newRole,_NhaThamDinh);
        
        bytes32 hashTtt = keccak256(abi.encodePacked("Da Thu Hoi Quyen"));
        NhaThamDinhs[_NhaThamDinh] = NhaThamDinh(hashTtt);
    }
    
    
    
    function YeuCauTroThanhNhaThamDinh(string memory _thongtin) public{
        require(msg.sender != admin);
        hashThonTin = keccak256(abi.encodePacked(_thongtin));
        users[msg.sender] = user(_thongtin,enRole.ChuaDuyet);
    }
    
    function DuyetYeuCau(address _adNguoiYeuCau) public{
      require(msg.sender == admin);
      require(users[_adNguoiYeuCau].Role == enRole.ChuaDuyet);
      _setupRole(newRole,_adNguoiYeuCau);
      users[_adNguoiYeuCau].Role = enRole.DaDuyet;
      NhaThamDinhs[_adNguoiYeuCau] = NhaThamDinh(hashThonTin);
      
    }
    
    
    function YeuCauTaoTaiSan(string memory _ThonTinTaiSan) public{
        SanPhams[numSanPham++] = SanPham(_ThonTinTaiSan,msg.sender);
    }
    
    bool XacNhan;
    function isOke(uint _MaSanPhamOke,string memory _ThongTinBoXung, uint _GiaTri) public onlyRole(newRole)
    {
        require(XacNhan== true);
        require(msg.sender != admin);
        require(msg.sender != SanPhams[_MaSanPhamOke].adNguoiTaoSanPham);
        bytes32 hsh = keccak256(abi.encodePacked(SanPhams[_MaSanPhamOke].thontin, hashThonTin));
        SanPhamDaDuyets[numSanPhamDaDuyet++] = SanPhamDaDuyet(enNhan.DaThamDinhRoi,_ThongTinBoXung,_GiaTri,hsh);
        
    }
    
    function notOke(uint _MaSanPhamNotOke, string memory _LyDo) public onlyRole(newRole){
        require(XacNhan== false);
        require(msg.sender != admin);
        require(msg.sender != SanPhams[_MaSanPhamNotOke].adNguoiTaoSanPham);
        SanPhamHuyBos[numSanPhamHuy++] = SanPhamHuyBo(enNhan.HuyBo,_LyDo);
        
    }
    

    
    function DuyetTaiSan(uint _MaSanPham, bool _XacNhan) public onlyRole(newRole)
    {
        require(msg.sender != admin);
        require(msg.sender != SanPhams[_MaSanPham].adNguoiTaoSanPham);
        XacNhan = _XacNhan;
        
    }

    function CheckSanPham() public view returns(SanPham memory objSanPham){
        for(uint i=0;i<numSanPham;i++)
        {
            if(SanPhams[i].adNguoiTaoSanPham == msg.sender)
            {
                return objSanPham;
            }
            
        }
        
    }
    
}