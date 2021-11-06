/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0
// Author: Juan Pablo Crespi 

pragma solidity >=0.6.0 <0.9.0;

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
        if (a == 0) { return 0; }
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

contract Ownable {

    event OwnershipTransferred(address newOwner);

    address private _owner;

    constructor() {
        setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        setOwner(newOwner);
        emit OwnershipTransferred(newOwner);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();
    event PauserChanged(address indexed newAddress);

    address private _pauser;
    bool public paused = false;

    constructor() {
        setPauser(msg.sender);
    }

    modifier whenNotPaused() {
        require(paused == false, "Pausable: paused");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == _pauser, "Pausable: caller is not the pauser");
        _;
    }

    function pauser() external view returns (address) {
        return _pauser;
    }

    function setPauser(address newPauser) internal {
        _pauser = newPauser;
    }

    function updatePauser(address newPauser) external onlyOwner {
        require(newPauser != address(0), "Pausable: new pauser is the zero address");
        setPauser(newPauser);
        emit PauserChanged(newPauser);
    }

    function pause() external onlyPauser {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyPauser {
        paused = false;
        emit Unpause();
    }
}

contract Blacklistable is Ownable {

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event BlacklisterChanged(address indexed newBlacklister);

    address private _blacklister;
    mapping(address => bool) internal blacklisted;

    constructor() {
        setBlacklister(msg.sender);
    }

    modifier onlyBlacklister() {
        require(msg.sender == _blacklister, "Blacklistable: caller is not the blacklister");
        _;
    }

    modifier notBlacklisted(address account) {
        require(blacklisted[account] == false, "Blacklistable: account is blacklisted");
        _;
    }

    function blacklister() external view returns (address) {
        return _blacklister;
    }

    function setBlacklister(address newBlacklister) internal {
        _blacklister = newBlacklister;
    }

    function updateBlacklister(address newBlacklister) external onlyOwner {
        require(newBlacklister != address(0), "Blacklistable: new blacklister is the zero address");
        setBlacklister(newBlacklister);
        emit BlacklisterChanged(newBlacklister);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return blacklisted[account];
    }

    function blacklist(address account) external onlyBlacklister {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unBlacklist(address account) external onlyBlacklister {
        blacklisted[account] = false;
        emit UnBlacklisted(account);
    }
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

abstract contract AbstractToken is IERC20 {
    function _approve(address owner, address spender, uint256 value) internal virtual;
    function _transfer(address from, address to, uint256 value) internal virtual;
}

contract Token is AbstractToken, Ownable, Pausable, Blacklistable {
    using SafeMath for uint256;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterChanged(address indexed newMinter);

    string public name;
    string public symbol;
    uint8 public decimals;

    address private _minter;
    uint256 internal _totalSupply = 0;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        setMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "Token: caller is not a minter");
        _;
    }

    function minter() external view returns (address) {
        return _minter;
    }

    function setMinter(address newMinter) internal {
        _minter = newMinter;
    }

    function updateMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Token: new masterMinter is the zero address" );
        setMinter(newMinter);
        emit MinterChanged(newMinter);
    }

    function mint(address to, uint256 amount)external whenNotPaused onlyMinter notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        require(to != address(0), "Token: mint to the zero address");
        require(amount > 0, "Token: mint amount not greater than 0");
        _totalSupply = _totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Mint(msg.sender, to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return allowed[owner][spender];
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 value) external override whenNotPaused notBlacklisted(msg.sender) notBlacklisted(spender) returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) external override whenNotPaused notBlacklisted(msg.sender) notBlacklisted(from) notBlacklisted(to) returns (bool) {
        require(value <= allowed[from][msg.sender], "ERC20: transfer amount exceeds allowance" );
        _transfer(from, to, value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return true;
    }

    function transfer(address to, uint256 value) external override whenNotPaused notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value <= balances[from],"ERC20: transfer amount exceeds balance");
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function burn(uint256 amount) external whenNotPaused onlyMinter notBlacklisted(msg.sender) {
        uint256 balance = balances[msg.sender];
        require(amount > 0, "Token: burn amount not greater than 0");
        require(balance >= amount, "Token: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balance.sub(amount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}