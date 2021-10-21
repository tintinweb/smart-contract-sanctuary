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

    function safeMint(address _to, uint256 _tokenId) external;
    function burn(address _from, uint256 _tokenId) external;
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
contract SellPackages is AccessControl {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IERC721 public PHE;
    IBEP20 public HE;
    bytes32 public constant CREATOR_ADMIN = keccak256("CREATOR_ADMIN");
    address payable receiveFee = payable(0xa6f6346fa66e8138ABB19dbB497cf0a7A36c29fb);
    mapping(uint256 => uint256) public maxPackages;
    mapping(uint256 => uint256) public maxPackagesOfAddress;
    mapping(uint256 => uint256) public duration;
    mapping(uint256 =>uint256) public feePackage;
    mapping(uint256 =>uint256) public startSell;
    mapping(uint256 => uint256) public currentSellPackage;
    mapping(uint256 => mapping(address => bool)) public whitelistAddress;
    mapping(uint256 => mapping(address => uint256)) public packageOfAddress;
    mapping(uint256 => bool) public section;
    constructor( address minter, address _HE, address _PHE ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN, minter);
		PHE = IERC721(_PHE); // NFT 
        HE = IBEP20(_HE); // HE
	}
    event SellPackage(
        uint256 section,
        address owner,
        uint256 tokenId,
        uint256 price,
        uint256 timeSell
    );
    event BatchPackages(
        address owner,
        uint256 tokenId,
        uint256 timeTransfer
    );
    function turnOffSection(uint256 _section) public {
        require(hasRole(CREATOR_ADMIN, address(msg.sender)), "Caller is not a admin");
        section[_section] = false;
    }
    function changeReceiveFee(address _receive) public {
        require(hasRole(CREATOR_ADMIN, address(msg.sender)), "Caller is not a admin");
        require(_receive != address(0));
        receiveFee = payable(_receive);
    }
    function addWhiteList(uint256 _section, address[] memory _address) public {
        require(hasRole(CREATOR_ADMIN, address(msg.sender)), "Caller is not a admin");
        for(uint256 i = 0; i < _address.length; i++){
            whitelistAddress[_section][_address[i]] = true;
        }
    }
    function setSellPackages(uint256 _section, uint256 _maxPackages, uint256 _maxPackagesOfAddress, uint256 _startSell, uint256 _duration, uint256 _feePackage) public {
        require(hasRole(CREATOR_ADMIN, address(msg.sender)), "Caller is not a admin");
        maxPackages[_section] = _maxPackages;
        maxPackagesOfAddress[_section] = _maxPackagesOfAddress;
        startSell[_section] = _startSell;
        duration[_section] = _duration;
        feePackage[_section] = _feePackage;
        section[_section] = true;
    }

    function buyPackage(uint256 _section, uint256[] memory listPackage) public {
        require( packageOfAddress[_section][msg.sender].add(listPackage.length) <= maxPackagesOfAddress[_section], "The number of packages is more than the limit of address");
        require( currentSellPackage[_section].add(listPackage.length) <= maxPackages[_section], "The number of packages is more than the limit");
        require(whitelistAddress[_section][msg.sender], "Not found in whitelist");
        require(section[_section], "section not found");
        require( (startSell[_section] <= block.timestamp) && (startSell[_section].add(duration[_section]) >=block.timestamp), "Not in the sale period" );
        packageOfAddress[_section][msg.sender] = packageOfAddress[_section][msg.sender].add(listPackage.length);
        currentSellPackage[_section] = currentSellPackage[_section].add(listPackage.length);
        uint256 amountHe = feePackage[_section].mul(listPackage.length);
        HE.safeTransferFrom(address(msg.sender), address(receiveFee), amountHe);
        for(uint256 i = 0; i < listPackage.length; i++){
            PHE.safeMint(address(msg.sender), listPackage[i]);
            emit SellPackage(
                _section,
                msg.sender,
                listPackage[i],
                feePackage[_section],
                block.timestamp
            );
        }
    }
}