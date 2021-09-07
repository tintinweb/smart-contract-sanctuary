// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./DNTfixedPointMath.sol";


// Interface for IERC20.
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

// Interface for IERC20Metadata.
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// Interface for IAccessControl.
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


// Interface for IERC165
interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Contract for Context.
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Contract for ERC165
abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Contract for ERC20.
contract ERC20 is Context, IERC20, IERC20Metadata {
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

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
    _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
    _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
    _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

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

// Contract for AccessControl.
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


// Library for SafeCast.
library SafeCast {

    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// Library for SafeMath
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Library for Strings.
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

// Smart contract for the Dynamic Network Token.
contract DynamicNetworkToken is ERC20, AccessControl
{
    // Declaration of roles in the network.
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant LIQ_PROVIDER = keccak256("LIQ_PROVIDER");

    // Govern the amount of tokens with a min and a max.
    uint256 private minimumSupply = 21000000 ether;
    uint256 private maximumSupply = 52500000 ether;

    // Keep track of total amount of burned and minted tokens.
    uint256 private totalBurned = 0;
    uint256 private totalMinted = 0;

    // Keep track of previous burn and mint transaction.
    uint256 private prevAmountMint = 0;
    uint256 private prevAmountBurn = 0;

    // Keep track of wallets in the network with balance > 0.
    uint256 private  totalWallets = 0;

    // Network Based Burn.
    uint256 private networkBasedBurn = 1000000 ether;
    uint256 private nextBurn = 100;

    // The reserve address.
    address private reserveAddress;

    // The minimum balance for the reserveAddress.
    uint256 private minimumReserve = 4200000 ether;

    // The initial supply of the token.
    uint256 private _initialSupply  = 42000000 ether;

    // The current supply of the token.
    uint256 private currentSupply  = _initialSupply;

    // Number of decimals for DNT.
    uint256 private _decimals = 18;

    // Booleans for exp burning and minting.
    bool private isExpBurn = false;
    bool private isExpMint = false;

    using SafeMath for uint256;

    constructor() ERC20("Dynamic Network Token", "DNT"){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LIQ_PROVIDER, _msgSender());
        _setupRole(ADMIN, _msgSender());
        _mint(_msgSender(),  _initialSupply);
        reserveAddress = _msgSender();
    }

    // Getter for nextBurn.
    function getNextBurn() public view returns(uint256){
        return(nextBurn);
    }

    // Getter for networkBasedBurn.
    function getNetworkBasedBurn() public view returns(uint256){
        return(networkBasedBurn/(10**18));
    }

    // Getter for currentSupply. Returns currentSupply with two decimals.
    function getCurrentSupply() public view returns(uint256){
        return(currentSupply/(10**16));
    }

    // Getter for totalBurned.
    function getTotalBurned() public view returns(uint256){
        return(totalBurned/(10**18));
    }

    // Getter for totalMinted.
    function getTotalMinted() public view returns(uint256){
        return(totalMinted/(10**18));
    }

    // Getter for totalWallets.
    function getTotalWallets() public view returns(uint256){
        return(totalWallets);
    }

    // Function for calculating mint.
    function calculateMint(uint256 amount) public returns(uint256){
        uint256 toBeMinted = SafeMath.add(prevAmountMint,amount);
        prevAmountMint = amount;
        uint256 uLog = DNTfixedPointMath.ln(toBeMinted);

        // Check if log < 1, if so calculate exp for minting.
        if(uLog<1)
        {
            isExpMint = true;
            int256 iExp = DNTfixedPointMath.exp(SafeCast.toInt256(toBeMinted));
            iExp = iExp * 8;
            iExp =  DNTfixedPointMath.div(SafeCast.toInt256(toBeMinted),iExp);
            uint256 uExp = SafeCast.toUint256(iExp);
            uExp = uExp * 10**4;
            return  uExp;
        }
        uint256 log = SafeMath.mul(uLog,8);
        uint256 logMint = SafeMath.div(toBeMinted,log);
        logMint = logMint * 10 ** _decimals;
        return logMint;
    }

    // Function for calculating burn.
    function calculateBurn(uint256 amount) public returns(uint256){
        uint256 toBeBurned = SafeMath.add(prevAmountBurn,amount);
        prevAmountBurn = amount;
        uint256 uLog = DNTfixedPointMath.ln(toBeBurned);

        // Check if log < 1, if so calculate exp for burning.
        if(uLog<1)
        {
            isExpBurn = true;
            int256 iExp = DNTfixedPointMath.exp(SafeCast.toInt256(toBeBurned));
            iExp = iExp * 4;
            iExp =  DNTfixedPointMath.div(SafeCast.toInt256(toBeBurned),iExp);
            uint256 uExp = SafeCast.toUint256(iExp);
            uExp = uExp * 10**4;
            return  uExp;
        }
        uint256 log = SafeMath.mul(uLog,4);
        uint256 logBurn = SafeMath.div(toBeBurned,log);
        logBurn = logBurn * 10 ** _decimals;
        return logBurn;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        // Calculate burn and mint.
        uint256 toBeBurned = calculateBurn(amount);
        uint256 toBeMinted = calculateMint(amount);
        uint256 currentSupplyAfterBurn = SafeMath.sub(currentSupply,toBeBurned);
        uint256 currentSupplyAfterMint = SafeMath.add(currentSupply,toBeMinted);
        // Add to totalWalelts if balance is 0.
        if(balanceOf(recipient)==0)
        {
            totalWallets += 1;
        }
        // Check if Network Based Burn.
        if(totalWallets>=nextBurn && SafeMath.sub(currentSupply,amount)>=minimumSupply && SafeMath.sub(balanceOf(reserveAddress),networkBasedBurn)>=minimumReserve)
        {
            _burn(reserveAddress,networkBasedBurn);
            currentSupply = SafeMath.sub(currentSupply,networkBasedBurn);
            totalBurned = SafeMath.add(totalBurned,networkBasedBurn);
            nextBurn = nextBurn*2;
            networkBasedBurn = networkBasedBurn/2;
        }
        if(hasRole(LIQ_PROVIDER, _msgSender()))
        {
            if(currentSupplyAfterMint<=maximumSupply && isExpMint)
            {
                _mint(reserveAddress,SafeMath.div(toBeMinted,10**4));
                isExpMint = false;
                currentSupply = SafeMath.add(currentSupply,SafeMath.div(toBeMinted,10**4));
                totalMinted = SafeMath.add(totalMinted,SafeMath.div(toBeMinted,10**4));
            }
            else if(currentSupplyAfterMint<=maximumSupply && toBeMinted > 0)
            {
                _mint(reserveAddress,toBeMinted);
                currentSupply = SafeMath.add(currentSupply,toBeMinted);
                totalMinted = SafeMath.add(totalMinted,toBeMinted);
            }
        }
        if(hasRole(LIQ_PROVIDER, recipient))
        {
            if(isExpBurn && currentSupplyAfterBurn>=minimumSupply)
            {
                if(SafeMath.sub(balanceOf(reserveAddress),SafeMath.div(toBeBurned,10**4))>= minimumReserve)
                {
                    _burn(reserveAddress,SafeMath.div(toBeBurned,10**4));
                    isExpBurn= false;
                    currentSupply = SafeMath.sub(currentSupply,SafeMath.div(toBeBurned,10**4));
                    totalBurned = SafeMath.add(totalBurned,SafeMath.div(toBeBurned,10**4));
                }
            }
            else if(currentSupplyAfterBurn>=minimumSupply && toBeBurned > 0)
            {
                if(SafeMath.sub(balanceOf(reserveAddress),toBeBurned)>= minimumReserve)
                {
                    _burn(reserveAddress,toBeBurned);
                    currentSupply = SafeMath.sub(currentSupply,toBeBurned);
                    totalBurned = SafeMath.add(totalBurned,toBeBurned);
                }
            }
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender,address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 toBeBurned = calculateBurn(amount);
        uint256 currentSupplyAfterBurn = SafeMath.sub(currentSupply,toBeBurned);
        if(hasRole(LIQ_PROVIDER, recipient))
        {
            if(isExpBurn && currentSupplyAfterBurn>=minimumSupply)
            {
                if(SafeMath.sub(balanceOf(reserveAddress),SafeMath.div(toBeBurned,10**4))>= minimumReserve)
                {
                    _burn(reserveAddress,SafeMath.div(toBeBurned,10**4));
                    isExpBurn= false;
                    currentSupply = SafeMath.sub(currentSupply,SafeMath.div(toBeBurned,10**4));
                    totalBurned = SafeMath.add(totalBurned,SafeMath.div(toBeBurned,10**4));
                }
            }
            else if(currentSupplyAfterBurn>=minimumSupply && toBeBurned > 0)
            {
                if(SafeMath.sub(balanceOf(reserveAddress), amount) >= minimumReserve)
                {
                    _burn(reserveAddress,toBeBurned);
                    currentSupply = SafeMath.sub(currentSupply,toBeBurned);
                    totalBurned = SafeMath.add(totalBurned,toBeBurned);
                }
            }
        }
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
    _approve(sender, _msgSender(), currentAllowance - amount);
    }
        return true;
    }
}