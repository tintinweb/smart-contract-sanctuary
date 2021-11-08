/**
 *Submitted for verification at Etherscan.io on 2021-11-08
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

    event OwnershipTransferred(address account);

    address private _owner;

    constructor() {
        setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setOwner(address account) internal {
        _owner = account;
    }

    function transferOwnership(address account) public onlyOwner {
        require(account != address(0), "Ownable: new owner is the zero address");
        setOwner(account);
        emit OwnershipTransferred(account);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();
    event PauserChanged(address account);

    address private _pauser;
    bool private _paused = false;

    constructor() {
        setPauser(msg.sender);
    }

    modifier whenNotPaused() {
        require(_paused == false, "Pausable: paused");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == _pauser, "Pausable: caller is not the pauser");
        _;
    }

    function paused() public view returns (bool) {
        return _paused == true;
    }
    
    function pauser() public view returns (address) {
        return _pauser;
    }

    function setPauser(address account) internal {
        _pauser = account;
    }

    function updatePauser(address account) public onlyOwner {
        require(account != address(0), "Pausable: new pauser is the zero address");
        setPauser(account);
        emit PauserChanged(account);
    }

    function pause() public onlyPauser {
        _paused = true;
        emit Pause();
    }

    function unpause() public onlyPauser {
        _paused = false;
        emit Unpause();
    }
}

contract Taxable is Ownable {
    using SafeMath for uint256;

    event TaxerChanged(address account);
    event Params(uint256 basisPoints, uint256 maximumFee);

    address private _taxer;
    uint256 private _basisPoints;
    uint256 private _maximumFee;

    constructor() {
        setTaxer(msg.sender);
    }

    function taxer() public view returns (address) {
        return _taxer;
    }

    function setTaxer(address account) internal {
        _taxer = account;
    }

    function updateTaxer(address account) public onlyOwner {
        require(account != address(0), "Taxable: new feer is the zero address");
        setTaxer(account);
        emit TaxerChanged(account);
    }
    
    function setParams(uint256 newBasisPoints, uint256 newMaximumFee, uint256 decimals) public onlyOwner {
        require(newBasisPoints < 20);
        require(newMaximumFee < 50);
        _basisPoints = newBasisPoints;
        _maximumFee = newMaximumFee.mul(10**decimals);
        emit Params(newBasisPoints, newMaximumFee);
    }
    
    function basisPoints() public view returns (uint256) {
        return _basisPoints;
    }
    
    function maximumFee() public view returns (uint256) {
        return _maximumFee;
    }
}

contract Blacklistable is Ownable {
    using SafeMath for uint256;

    event Blacklisted(address account);
    event UnBlacklisted(address account);
    event BlacklisterChanged(address account);

    address private _blacklister;

    mapping(address => bool) private blacklisted;

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

    function blacklister() public view returns (address) {
        return _blacklister;
    }

    function setBlacklister(address account) internal {
        _blacklister = account;
    }

    function updateBlacklister(address account) public onlyOwner {
        require(account != address(0), "Blacklistable: new blacklister is the zero address");
        setBlacklister(account);
        emit BlacklisterChanged(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function blacklist(address account) public onlyBlacklister {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unBlacklist(address account) public onlyBlacklister {
        blacklisted[account] = false;
        emit UnBlacklisted(account);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

contract ERC20Token is IERC20, Ownable, Pausable, Taxable, Blacklistable {
    using SafeMath for uint256;
    
    uint256 private _totalSupply;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function totalSupply() override virtual public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override virtual public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) override virtual public {
        _transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address spender) override virtual public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) override virtual public {
        _approve(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) override virtual public {
        _transferFrom(msg.sender, sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused notBlacklisted(sender) notBlacklisted(recipient)  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[sender],"ERC20: transfer amount exceeds balance");
        address taxer = taxer();
        uint256 fee = 0;
        if (sender != taxer) {
            fee = (amount.mul(basisPoints())).div(10000);
        }
        if (fee > maximumFee()) {
            fee = maximumFee();
        }
        if (fee > 0) {
            balances[taxer] = balances[taxer].add(fee);
            emit Transfer(sender, taxer, fee);
        }
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount.sub(fee));
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address caller, address spender, uint256 amount) internal whenNotPaused notBlacklisted(caller) notBlacklisted(spender) {
        require(caller != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[caller][spender] = amount;
        emit Approval(caller, spender, amount);
    }
    
    function _transferFrom(address caller, address sender, address recipient, uint256 amount) internal whenNotPaused notBlacklisted(caller) notBlacklisted(sender) notBlacklisted(recipient) {
        require(amount <= allowed[sender][caller], "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        allowed[sender][caller] = allowed[sender][caller].sub(amount);
    }
    
    function _addTotalSupply(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
    }
    
    function _subTotalSupply(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
    }
}

contract Mintable is ERC20Token {
    using SafeMath for uint256;

    event Mint(address minter, address recipient, uint256 amount);
    event Burn(address burner, address spender, uint256 amount);
    event MinterChanged(address newMinter);

    address private _minter;

    constructor() {
        setMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "Mintable: caller is not a minter");
        _;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function setMinter(address account) internal {
        _minter = account;
    }

    function updateMinter(address account) public onlyOwner {
        require(account != address(0), "Mintable: new miner is the zero address" );
        setMinter(account);
        emit MinterChanged(account);
    }

    function mint(address recipient, uint256 amount) public {
        _mint(msg.sender, recipient, amount);
    }

    function burn(address spender, uint256 amount) public {
        _burn(msg.sender, spender, amount);
    }
    
    function _mint(address caller, address recipient, uint256 amount) internal whenNotPaused onlyMinter notBlacklisted(caller) notBlacklisted(recipient) {
        require(recipient != address(0), "Mintable: mint to the zero address");
        require(amount > 0, "Mintable: mint amount not greater than 0");
        _addTotalSupply(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Mint(caller, recipient, amount);
        emit Transfer(address(0), recipient, amount);
    }
    
    function _burn(address caller, address spender, uint256 amount) internal whenNotPaused onlyMinter notBlacklisted(caller) {
        require(spender != address(0), "Mintable: burn to the zero address");
        uint256 balance = balances[spender];
        require(amount > 0, "Mintable: burn amount not greater than 0");
        require(balance >= amount, "Mintable: burn amount exceeds balance");
        _subTotalSupply(amount);
        balances[spender] = balance.sub(amount);
        emit Burn(caller, spender, amount);
        emit Transfer(spender, address(0), amount);
    }
}

interface IERC20Upgradeable is IERC20 {
    function transferByLegacy(address caller, address recipient, uint256 amount) external;
    function transferFromByLegacy(address caller, address sender, address recipient, uint256 amount) external;
    function approveByLegacy(address caller, address spender, uint256 amount) external;
}

contract Upgradeable is ERC20Token, IERC20Upgradeable {

    event Deprecate(address newContract);
    event UpgraderChanged(address account);

    address private _upgrader;
    address private _upgradedContract;
    bool private _deprecated;

    constructor() {
        setUgrader(msg.sender);
    }

    modifier onlyUpgrader() {
        require(msg.sender == _upgrader, "Upgradeable: caller is not the upgrader");
        _;
    }

    function upgrader() public view returns (address) {
        return _upgrader;
    }

    function setUgrader(address account) internal {
        _upgrader = account;
    }

    function updateUpgrader(address account) public onlyOwner {
        require(account != address(0), "Upgradeable: new upgrader is the zero address");
        setUgrader(account);
        emit UpgraderChanged(account);
    }

    function deprecate(address newContract) public onlyUpgrader {
        _deprecated = true;
        _upgradedContract = newContract;
        emit Deprecate(newContract);
    }
    
    function upgradedContract() public view returns (address) {
        return _upgradedContract;
    }
    
    function deprecated() public view returns (bool) {
        return _deprecated;
    }

    function transferByLegacy(address caller, address recipient, uint256 amount) override public {
        _transfer(caller, recipient, amount);
    }

    function approveByLegacy(address caller, address spender, uint256 amount) override public {
        _approve(caller, spender, amount);
    }
    
    function transferFromByLegacy(address caller, address sender, address recipient, uint256 amount) override public {
        _transferFrom(caller, sender, recipient, amount);
    }
}

contract WareToken is ERC20Token, Mintable, Upgradeable {

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }

    function totalSupply() override public view returns (uint256) {
        if (deprecated()) {
            return IERC20Upgradeable(upgradedContract()).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function balanceOf(address account) override public view returns (uint256) {
        if (deprecated()) {
            return IERC20Upgradeable(upgradedContract()).balanceOf(account);
        } else {
            return super.balanceOf(account);
        }
    }

    function transfer(address recipient, uint256 amount) override public {
        if (deprecated()) {
            IERC20Upgradeable(upgradedContract()).transferByLegacy(msg.sender, recipient, amount);
        } else {
            super.transfer(recipient, amount);
        }
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        if (deprecated()) {
            return IERC20Upgradeable(upgradedContract()).allowance(owner, spender);
        } else {
            return super.allowance(owner, spender);
        }
    }

    function approve(address spender, uint256 amount) override public {
        if (deprecated()) {
            IERC20Upgradeable(upgradedContract()).approveByLegacy(msg.sender, spender, amount);
        } else {
            super.approve(spender, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public {
        if (deprecated()) {
            IERC20Upgradeable(upgradedContract()).transferFromByLegacy(msg.sender, sender, recipient, amount);
        } else {
            super.transferFrom(sender, recipient, amount);
        }
    }
}