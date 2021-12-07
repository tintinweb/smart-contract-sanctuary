pragma solidity ^0.8.0;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
interface IBEP20 { 
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval( address indexed owner, address indexed spender, uint256 value );
}
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        // uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
} 
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom( address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data ) external;

    struct GearInfo {string gearName; string gearType; string gearClass1; string gearClass2; string gearClass3; string gearTier;}
    function getGear(uint256 _tokenId) external view returns (GearInfo memory);
    function safeMint(address _to, uint256 _tokenId) external;
    function burn(address _from, uint256 _tokenId) external;
    function addGear(uint256 tokenId, string memory gearName, string memory gearType, string memory gearClass1, string memory gearClass2, string memory gearClass3, string memory gearTier) external;
    function editTier(uint256 tokenId, string memory _tier) external;
    function deleteGear(uint256 tokenId) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; }
}
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) { return _roles[role].members[account]; }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }
    function grantRole(bytes32 role, address account) public virtual override { 
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override
    {
        require( account == _msgSender(), "AccessControl: can only renounce roles for self" );
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual { _grantRole(role, account); }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
contract UpgradeGear is AccessControl {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IERC721 public gearNFT;
    bytes32 public constant CREATOR_ADMIN_SERVER = keccak256("CREATOR_ADMIN_SERVER");
    string stringNull = "";
    constructor( address minter, address _gearNFT) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN_SERVER, minter);
		gearNFT = IERC721(_gearNFT); // Gear Assets
	}
    event addadmin(
        address _admin,
        uint256 timeAdmin
    );
    event mintgear(
        address Owner,
        uint256 tokenId,
        string gearName,
        string gearType,
        string gearClass1,
        string gearClass2,
        string gearClass3,
        string gearTier
    );
    event ascend(
        address Owner,
        uint256 tokenId,
        string tier
    );
    string[] public gearTier; // tier information
    string[] public gearType; // type information
    string[] public gearClass; // class information
    mapping(uint256 => bool) public usedMintId;
    function addGearTier(string[] memory _gearTier) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _gearTier.length ; i++) {
            gearTier.push(_gearTier[i]);
        }
    }
    function editGearTier(uint256 _id, string memory _gearTier) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        gearTier[_id] = _gearTier;
    }
    function addGearType(string[] memory _gearType) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _gearType.length ; i++) {
            gearType.push(_gearType[i]);
        }
    }
    function editGearType(uint256 _id, string memory _gearType) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        gearType[_id] = _gearType;
    }
    function addGearClass(string[] memory _gearClass) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _gearClass.length ; i++) {
            gearClass.push(_gearClass[i]);
        }
    }
    function editGearClass(uint256 _id, string memory _gearClass) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        gearClass[_id] = _gearClass;
    }
    function queryNumberTier(string memory _tier) public view returns(uint256) {
        uint256 result = 100;
        for(uint256 i = 0 ; i < gearTier.length ; i ++) {
            if( keccak256(bytes(gearTier[i])) == keccak256(bytes(_tier)) ) {
                result = i;
            }
        }
        return result;
    }
    function findClass(uint256[3] memory _class) public view returns(bool){
        bool result = true;
        for(uint256 i = 0; i < 3; i++){
            if(_class[i] < 0 || _class[i] >= gearClass.length){
                result = false;
            }
        }
        return result; 
    }
    function mintGear(
        uint256 _id,
        address _owner,
        uint256 _gearId,
        string memory _gearName,
        uint256 _gearType,
        uint256[3] memory _gearClass,
        uint256 _gearTier
    ) external {
        require(hasRole(CREATOR_ADMIN_SERVER, address(msg.sender)), "Caller is not a admin");
        require(_gearType >= 0 && _gearType <  gearType.length, "Gear Type not found");
        require(findClass(_gearClass), "Gear Class is wrong");
        require(!usedMintId[_id], "Id used");
        gearNFT.safeMint(address(_owner), _gearId);
        gearNFT.addGear(_gearId, _gearName, gearType[_gearType], gearClass[_gearClass[0]], gearClass[_gearClass[1]], gearClass[_gearClass[2]] , gearTier[_gearTier]);
        usedMintId[_id] = true;
        emit mintgear(
            _owner,
            _gearId,
            _gearName,
            gearType[_gearType],
            gearClass[_gearClass[0]],
            gearClass[_gearClass[1]],
            gearClass[_gearClass[2]],
            gearTier[_gearTier]
        );
    }
    function Upgrade(uint256[] memory listGear, address owner, uint256 datainput) public {
        require(hasRole(CREATOR_ADMIN_SERVER, address(msg.sender)), "Caller is not a admin");
        require(datainput == 1 || datainput == 2 || datainput == 3, "Input wrong");
        if(datainput == 1){
            for(uint256 i = 0; i < listGear.length; i++){
                gearNFT.burn(owner, listGear[i]);
                gearNFT.deleteGear(listGear[i]);
            }
        }
        if(datainput == 2){
            require(listGear.length == 1,"List Gear is wrong");
            //upgrade
            EditTier(listGear[0], owner);
        }
        if(datainput == 3){
            require(listGear.length > 1, "List Gear is wrong");
            for(uint256 i = 1; i < listGear.length; i++){
                gearNFT.burn(owner, listGear[i]);
                gearNFT.deleteGear(listGear[i]);
            }
            //upgrade
            EditTier(listGear[0], owner);
        }
    }
    function EditTier(uint256 gearId, address owner) internal {
        uint256 gearTierMain = queryNumberTier(gearNFT.getGear(gearId).gearTier);
        require(gearTierMain != 100 && gearTierMain < gearTier.length, "Gear Tier is wrong");
        require(gearNFT.ownerOf(gearId) ==  owner, "You are not the owner");
        gearNFT.editTier(gearId, gearTier[gearTierMain + 1]);
        emit ascend(
            owner,
            gearId,
            gearTier[gearTierMain + 1]
        );
    }
}