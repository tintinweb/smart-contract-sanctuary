/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.5;

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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

contract Chieftains is AccessControl, ReentrancyGuard, Pausable {

    IERC20 public busd;
    IERC1155 public _SporeNFT;
    
    address private _daoWallet;
  
    uint256 public _daoKeyNft;
    uint256 public _chieftainFee;
    
    address[] private _applicantList;
    address[] private _chieftainList;
    
    struct Applicant { 
        address addr;
        string name;
        string email;
        string twitter;
        string telegram;
        string discord;
        uint256 created;
   }
   
    mapping(address => Applicant) private _applicants;
    mapping(address => Applicant) private _chieftains;
    
    event KeyTokenChanged(uint256 oldID, uint256 newID);
    event FeeChanged(uint256 oldFEE, uint256 newFEE);
    event DeleteApplicant(address addr);
    event NewApplicant(address addr, string name, string email, string twitter, string telegram, string discord, uint256 date_created);
    event NewChieftain(address addr);
    event DeleteChieftain(address addr);
    
    constructor(uint256 daoKeyNft, IERC20 _busd, IERC1155 nft, address daoWallet, uint256 chieftainFee) {
        _chieftainFee = chieftainFee;
        _daoKeyNft = daoKeyNft;
        _SporeNFT = IERC1155(nft);
        _daoWallet = address(daoWallet);
        busd = IERC20(_busd);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function getChieftainsTotal() public view returns (uint256) {
        return _chieftainList.length;
    }
    
    function getApplicantsTotal() public view returns (uint256) {
        return _applicantList.length;
    }
    
    function getApplicantList() public view returns (address[] memory) {
        return _applicantList;
    }
    
    function getChieftainList() public view returns (address[] memory) {
        return _chieftainList;
    }
    
    function getApplicant(address applicant) public view returns (Applicant memory) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        return _applicants[applicant];
    }
    
    function getChieftain(address chieftain) public view returns (Applicant memory) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        return _chieftains[chieftain];
    }
    
    function totalBalance() public view returns (uint256) {
        return busd.balanceOf(address(this));
    }
    
    function changeDaoKeyNft(uint256 id) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        
        uint256 old = _daoKeyNft;
        _daoKeyNft = id;

        emit KeyTokenChanged(old, id);
        return true;
    }
    
    function changeChieftainFee(uint256 fee) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        
        uint256 old = _chieftainFee;
        _chieftainFee = fee;

        emit FeeChanged(old, fee);
        return true;
    }
    
    function newApplicant(string memory name, string memory email, string memory twitter, string memory telegram, string memory discord) public nonReentrant whenNotPaused  {
        require(_SporeNFT.balanceOf(_msgSender(), _daoKeyNft) > 0, "You need the NFT key to sign up");
        require(busd.balanceOf(_msgSender()) >= _chieftainFee, "You dont have enough funds to sign up");
        require(busd.transferFrom(_msgSender(), address(this), _chieftainFee), "busd transfer failed");
        require(_applicants[_msgSender()].addr != _msgSender(), "you are already on the waiting list");
        require(_chieftains[_msgSender()].addr != _msgSender(), "you are already a chieftain");
        
        Applicant storage applicant = _applicants[_msgSender()];
        
        applicant.addr = _msgSender();
        applicant.name = name;
        applicant.email = email;
        applicant.twitter = twitter;
        applicant.telegram = telegram;
        applicant.discord = discord;
        applicant.created = block.timestamp;
        
        _applicantList.push(_msgSender());
        
        emit NewApplicant(_msgSender(),  name,  email,  twitter,  telegram,  discord, block.timestamp);
    }
    
    function deleteApplicant() public nonReentrant whenNotPaused  {
        require(_applicants[_msgSender()].addr == _msgSender(), "you are not the account owner");
        require(busd.balanceOf(address(this)) >= _chieftainFee, "Contract doesnt have enough funds");
        require(busd.transfer(_msgSender(), _chieftainFee), "busd transfer failed");
        
        address[] memory newArray = _applicantList;
        delete _applicantList;
        delete _applicants[_msgSender()];
        
        for (uint i = 0; i < newArray.length; i++) {
            if(newArray[i] != _msgSender()) {
                _applicantList.push(newArray[i]);
            }
        }

        emit DeleteApplicant(_msgSender());
    }
    
    function newChieftain(address addr) public nonReentrant whenNotPaused  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        require(_applicants[addr].addr == addr, "that application doesnt exist");
        require(_chieftains[addr].addr != addr, "you are already a chieftain");
        require(busd.balanceOf(address(this)) >= _chieftainFee, "Contract doesnt have enough funds");
        require(busd.transfer(_daoWallet, _chieftainFee), "busd transfer failed");

        Applicant storage applicant = _applicants[addr];
        Applicant storage chieftain = _chieftains[addr];
        
        chieftain.addr = applicant.addr;
        chieftain.name = applicant.name;
        chieftain.email = applicant.email;
        chieftain.twitter = applicant.twitter;
        chieftain.telegram = applicant.telegram;
        chieftain.discord = applicant.discord;
        chieftain.created = block.timestamp;
        
        address[] memory newArray = _applicantList;
        delete _applicantList;
        delete _applicants[addr];
        
        for (uint i = 0; i < newArray.length; i++) {
            if(newArray[i] != addr) {
                _applicantList.push(newArray[i]);
            }
        }
        
        _chieftainList.push(addr);
        
        emit NewChieftain(addr);
    }
    
    function deleteChieftain(address addr) public nonReentrant whenNotPaused {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        require(_chieftains[addr].addr == addr, "that chieftain doesnt exist");
        
        address[] memory newArray = _chieftainList;
        delete _chieftainList;
        delete _chieftains[addr];
        
        for (uint i = 0; i < newArray.length; i++) {
            if(newArray[i] != addr) {
                _chieftainList.push(newArray[i]);
            }
        }
        
        emit DeleteChieftain(addr);
    }
}