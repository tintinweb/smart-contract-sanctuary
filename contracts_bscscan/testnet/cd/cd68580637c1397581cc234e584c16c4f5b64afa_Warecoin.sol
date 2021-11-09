/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0
// Author: Juan Pablo Crespi 

pragma solidity >=0.6.0 <0.9.0;

library SafeMath {

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 _c = _a + _b;
        require(_c >= _a, "SafeMath: addition overflow");
        return _c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 _c = _a - _b;
        return _c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) { return 0; }
        uint256 _c = _a * _b;
        require(_c / _a == _b, "SafeMath: multiplication overflow");
        return _c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "SafeMath: division by zero");
    }

    function div(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 _c = _a / _b;
        return _c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return mod(_a, _b, "SafeMath: modulo by zero");
    }

    function mod(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b != 0, _errorMessage);
        return _a % _b;
    }
}

contract Ownable {

    event OwnershipTransferred(address indexed _account);

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address _account) public onlyOwner {
        require(_account != address(0), "Ownable: new owner is the zero address");
        _owner = _account;
        emit OwnershipTransferred(_account);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();
    event PauserChanged(address indexed _account);

    address private _pauser;
    bool private _paused = false;

    constructor() {
        _pauser = msg.sender;
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

    function updatePauser(address _account) public onlyOwner {
        require(_account != address(0), "Pausable: new pauser is the zero address");
        _pauser = _account;
        emit PauserChanged(_account);
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

contract Blacklistable is Ownable {
    using SafeMath for uint256;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed _account);

    address private _blacklister;
    mapping(address => bool) private _blacklisted;

    constructor() {
        _blacklister = msg.sender;
    }

    modifier onlyBlacklister() {
        require(msg.sender == _blacklister, "Blacklistable: caller is not the blacklister");
        _;
    }

    modifier notBlacklisted(address _account) {
        require(_blacklisted[_account] == false, "Blacklistable: account is blacklisted");
        _;
    }

    function blacklister() public view returns (address) {
        return _blacklister;
    }

    function updateBlacklister(address _account) public onlyOwner {
        require(_account != address(0), "Blacklistable: new blacklister is the zero address");
        _blacklister = _account;
        emit BlacklisterChanged(_account);
    }

    function isBlacklisted(address _account) public view returns (bool) {
        return _blacklisted[_account];
    }

    function blacklist(address _account) public onlyBlacklister {
        _blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) public onlyBlacklister {
        _blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }
}

contract Taxable is Ownable {
    using SafeMath for uint256;

    event Params(uint256 _basisPoints, uint256 _maximumFee);
    event TaxerChanged(address indexed _account);

    address private _taxer;
    uint256 private _basisPoints;
    uint256 private _maximumFee;

    constructor() {
        _taxer = msg.sender;
    }

    function taxer() public view returns (address) {
        return _taxer;
    }

    function updateTaxer(address _account) public onlyOwner {
        require(_account != address(0), "Taxable: new feer is the zero address");
        _taxer = _account;
        emit TaxerChanged(_account);
    }
    
    function setParams(uint256 _newBasisPoints, uint256 _newMaximumFee, uint256 _decimals) public onlyOwner {
        require(_newBasisPoints < 20);
        require(_newMaximumFee < 50);
        _basisPoints = _newBasisPoints;
        _maximumFee = _newMaximumFee.mul(10**_decimals);
        emit Params(_basisPoints, _maximumFee);
    }
    
    function basisPoints() public view returns (uint256) {
        return _basisPoints;
    }
    
    function maximumFee() public view returns (uint256) {
        return _maximumFee;
    }
    
    function _calculateFee(address _sender, uint256 _value) internal view returns (uint256) {
        if (_sender == _taxer) {
            return 0;
        }
        uint256 _fee = (_value.mul(_basisPoints).div(10000));
        if (_fee > _maximumFee) {
            _fee = _maximumFee;
        }
        return _fee;
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is IERC20, Ownable, Pausable, Blacklistable, Taxable {
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    function name() override virtual public view returns (string memory) {
        return _name;
    }

    function symbol() override virtual public view returns (string memory) {
        return _symbol;
    }

    function decimals() override virtual public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() override virtual public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) override virtual public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override virtual public view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) override virtual public returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        _transferFrom(msg.sender, _from, _to, _value);
        return true;
    }

    function _transfer(address _sender, address _to, uint256 _value) internal whenNotPaused notBlacklisted(_sender) notBlacklisted(_to)  {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= _balances[_sender],"ERC20: transfer amount exceeds balance");
        uint256 _fee = _calculateFee(_sender, _value);
        if (_fee > 0) {
            address _taxer = taxer();
            _balances[_taxer] = _balances[_taxer].add(_fee);
            emit Transfer(_sender, _taxer, _fee);
        }
        _balances[_sender] = _balances[_sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value.sub(_fee));
        emit Transfer(_sender, _to, _value);
    }
    
    function _approve(address _sender, address _spender, uint256 _value) internal whenNotPaused notBlacklisted(_sender) notBlacklisted(_spender) {
        require(_sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowed[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
    }
    
    function _transferFrom(address _sender, address _from, address _to, uint256 _value) internal whenNotPaused notBlacklisted(_sender) notBlacklisted(_from) notBlacklisted(_to) {
        require(_value <= _allowed[_from][_sender], "ERC20: transfer amount exceeds allowance");
        _transfer(_from, _to, _value);
        _allowed[_from][_sender] = _allowed[_from][_sender].sub(_value);
    }
}

contract Mintable is ERC20Token {
    using SafeMath for uint256;

    event Mint(address _minter, address indexed _to, uint256 _value);
    event Burn(address _burner, address indexed _from, uint256 _value);
    event MinterChanged(address indexed _account);

    address private _minter;

    constructor() {
        _minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "Mintable: caller is not a minter");
        _;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function updateMinter(address _account) public onlyOwner {
        require(_account != address(0), "Mintable: new miner is the zero address" );
        _minter = _account;
        emit MinterChanged(_account);
    }

    function mint(address _to, uint256 _value) public {
        _mint(msg.sender, _to, _value);
    }

    function burn(address _from, uint256 _value) public {
        _burn(msg.sender, _from, _value);
    }
    
    function _mint(address _sender, address _to, uint256 _value) internal whenNotPaused onlyMinter notBlacklisted(_sender) notBlacklisted(_to) {
        require(_to != address(0), "Mintable: mint to the zero address");
        require(_value > 0, "Mintable: mint amount not greater than 0");
        _totalSupply = _totalSupply.add(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Mint(_sender, _to, _value);
        emit Transfer(address(0), _to, _value);
    }
    
    function _burn(address _sender, address _from, uint256 _value) internal whenNotPaused onlyMinter notBlacklisted(_sender) {
        require(_from != address(0), "Mintable: burn to the zero address");
        uint256 _balance = _balances[_from];
        require(_value > 0, "Mintable: burn amount not greater than 0");
        require(_balance >= _value, "Mintable: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(_value);
        _balances[_from] = _balance.sub(_value);
        emit Burn(_sender, _from, _value);
        emit Transfer(_from, address(0), _value);
    }
}

interface IERC20Upgradeable is IERC20 {
    function legacyTransfer(address _sender, address _to, uint256 _value) external returns (bool success);
    function legacyTransferFrom(address _sender, address _from, address _to, uint256 _value) external returns (bool success);
    function legacyApprove(address _sender, address _spender, uint256 _value) external returns (bool success);
}

contract Upgradeable is ERC20Token, IERC20Upgradeable {

    event Upgraded(address indexed _newContract);
    event Legacy(address indexed _oldContract);
    event UpgraderChanged(address indexed _account);

    address private _upgrader;
    address private _legacyContract;
    address private _upgradedContract;
    bool private _upgraded;

    constructor() {
        _upgrader = msg.sender;
    }

    modifier onlyUpgrader() {
        require(msg.sender == _upgrader, "Upgradeable: caller is not the upgrader");
        _;
    }

    modifier onlyLegacy() {
        require(msg.sender != address(0), "Upgradeable: caller is the zero address");
        require(msg.sender == _legacyContract, "Upgradeable: caller is not the legacy contract");
        _;
    }

    function upgrader() public view returns (address) {
        return _upgrader;
    }

    function updateUpgrader(address _account) public onlyOwner {
        require(_account != address(0), "Upgradeable: new upgrader is the zero address");
        _upgrader = _account;
        emit UpgraderChanged(_account);
    }

    function legacyContract(address _oldContract) public onlyUpgrader {
        _legacyContract = _oldContract;
        emit Legacy(_oldContract);
    }

    function legacyContract() public view returns (address) {
        return _legacyContract;
    }
    
    function upgradedContract(address _newContract) public onlyUpgrader {
        _upgraded = true;
        _upgradedContract = _newContract;
        emit Upgraded(_newContract);
    }
    
    function upgradedContract() public view returns (address) {
        return _upgradedContract;
    }
    
    function upgraded() public view returns (bool) {
        return _upgraded;
    }

    function legacyTransfer(address _sender, address _to, uint256 _value) override public onlyLegacy returns (bool success) {
        _transfer(_sender, _to, _value);
        return true;
    }

    function legacyApprove(address _sender, address _spender, uint256 _value) override public onlyLegacy returns (bool success) {
        _approve(_sender, _spender, _value);
        return true;
    }
    
    function legacyTransferFrom(address _sender, address _from, address _to, uint256 _value) override public onlyLegacy returns (bool success) {
        _transferFrom(_sender, _from, _to, _value);
        return true;
    }
}

contract Token is ERC20Token, Mintable, Upgradeable {

    function name() override public view returns (string memory) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).name();
        } else {
            return super.name();
        }
    }

    function symbol() override public view returns (string memory) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).symbol();
        } else {
            return super.symbol();
        }
    }

    function decimals() override public view returns (uint8) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).decimals();
        } else {
            return super.decimals();
        }
    }

    function totalSupply() override public view returns (uint256) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).balanceOf(_owner);
        } else {
            return super.balanceOf(_owner);
        }
    }

    function transfer(address _to, uint256 _value) override public returns (bool success) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).legacyTransfer(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).legacyApprove(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        if (upgraded()) {
            return IERC20Upgradeable(upgradedContract()).legacyTransferFrom(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }
}

contract Warecoin is Token {

    constructor() {
        _name = "Warecoin";
        _symbol = "WC";
        _decimals = 8;
    }
}