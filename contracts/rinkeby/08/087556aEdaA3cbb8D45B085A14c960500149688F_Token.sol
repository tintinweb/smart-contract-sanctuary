/**
 *Submitted for verification at Etherscan.io on 2021-11-07
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
        paused = true;
        emit Pause();
    }

    function unpause() public onlyPauser {
        paused = false;
        emit Unpause();
    }
}

contract Taxable is Ownable {

    event TaxerChanged(address account);

    address private _taxer;

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
}

contract Blacklistable is Ownable {
    using SafeMath for uint256;

    event Blacklisted(address account);
    event UnBlacklisted(address account);
    event BlacklisterChanged(address account);

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

contract Upgradeable is Ownable {

    event Deprecate(address newContract);
    event UpgraderChanged(address account);

    address private _upgrader;
    
    address public upgradedContract;
    bool public deprecated;

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
        deprecated = true;
        upgradedContract = newContract;
        emit Deprecate(newContract);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

contract ERC20Token is IERC20, Ownable, Pausable, Taxable, Blacklistable {
    using SafeMath for uint256;
    
    event Params(uint basisPoints, uint maximumFee);

    uint public _totalSupply;
    uint public _basisPoints;
    uint public _maximumFee;
    
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

    function transfer(address recipient, uint256 amount) override virtual public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(recipient) returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) override virtual public view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) override virtual public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(spender) returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override virtual public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(sender) notBlacklisted(recipient) returns (bool) {
        require(amount <= allowed[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        return true;
    }

    function setParams(uint newBasisPoints, uint newMaximumFee) public onlyOwner {
        require(newBasisPoints < 20);
        require(newMaximumFee < 50);
        _basisPoints = newBasisPoints;
        _maximumFee = newMaximumFee.mul(10**decimals);
        emit Params(newBasisPoints, newMaximumFee);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[sender],"ERC20: transfer amount exceeds balance");
        address taxer = taxer();
        uint fee = 0;
        if (sender != taxer) {
            fee = (amount.mul(_basisPoints)).div(10000);
        }
        if (fee > _maximumFee) {
            fee = _maximumFee;
        }
        if (fee > 0) {
            balances[taxer] = balances[taxer].add(fee);
            emit Transfer(sender, taxer, fee);
        }
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount.sub(fee));
        emit Transfer(sender, recipient, amount);
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

    function mint(address recipient, uint256 amount) public whenNotPaused onlyMinter notBlacklisted(msg.sender) notBlacklisted(recipient) returns (bool) {
        require(recipient != address(0), "Mintable: mint to the zero address");
        require(amount > 0, "Mintable: mint amount not greater than 0");
        _totalSupply = _totalSupply.add(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Mint(msg.sender, recipient, amount);
        emit Transfer(address(0), recipient, amount);
        return true;
    }

    function burn(address spender, uint256 amount) public whenNotPaused onlyMinter notBlacklisted(msg.sender) returns (bool) {
        require(spender != address(0), "Mintable: burn to the zero address");
        uint256 balance = balances[spender];
        require(amount > 0, "Mintable: burn amount not greater than 0");
        require(balance >= amount, "Mintable: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        balances[spender] = balance.sub(amount);
        emit Burn(msg.sender, spender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}

interface ERC20Upgradeable is IERC20 {
    function transferByLegacy(address caller, address recipient, uint amount) external returns (bool);
    function transferFromByLegacy(address caller, address sender, address recipient, uint amount) external returns (bool);
    function approveByLegacy(address caller, address spender, uint amount) external returns (bool);
}

contract Token is ERC20Token, Mintable, Upgradeable {

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }

    function totalSupply() override public view returns (uint256) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function balanceOf(address account) override public view returns (uint256) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).balanceOf(account);
        } else {
            return super.balanceOf(account);
        }
    }

    function transfer(address recipient, uint256 amount) override public returns (bool) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).transferByLegacy(msg.sender, recipient, amount);
        } else {
            return super.transfer(recipient, amount);
        }
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).allowance(owner, spender);
        } else {
            return super.allowance(owner, spender);
        }
    }

    function approve(address spender, uint256 amount) override public returns (bool) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).approveByLegacy(msg.sender, spender, amount);
        } else {
            return super.approve(spender, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public returns (bool) {
        if (deprecated) {
            return ERC20Upgradeable(upgradedContract).transferFromByLegacy(msg.sender, sender, recipient, amount);
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}