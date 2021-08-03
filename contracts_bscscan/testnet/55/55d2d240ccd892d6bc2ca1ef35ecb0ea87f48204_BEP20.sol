/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }
}

abstract contract BEP20Detailed is IBEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
    constructor () internal {
        _addMinter(_msgSender());
    }
    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }
    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    function renounceMinter() public {
        _removeMinter(_msgSender());
    }
    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }
    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract BEP20Mintable is BEP20, MinterRole {
    function mint(address account, uint256 amount) internal onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

contract BEP20Burnable is Context, BEP20 {
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}


contract DRSKULL is BEP20, BEP20Detailed, BEP20Mintable, BEP20Burnable {
    constructor() 
    BEP20Detailed("DRSKULL", "DRSKULL", 18) public {
        for(uint i =0 ;i < VALIDATOR_NUMBERS; i++ )
        {
            validators[i] = _msgSender();
        }
        super.mint(_msgSender(), 10000000 * 10 ** 18);
    }
    uint256 constant VALIDATOR_NUMBERS = 20;
    address[VALIDATOR_NUMBERS]  public validators;
    bool[VALIDATOR_NUMBERS] public   enableMint;
    uint256 public pendingMintAmount;
    function mintRequest(uint256 _amount) onlyMinter public {
        if(pendingMintAmount == 0) {
            pendingMintAmount = _amount;
        }
        else{
            for(uint i =0 ;i < VALIDATOR_NUMBERS; i++ )
            {
                if(enableMint[i])
                {
                    enableMint[i] = false ;
                }
            }
             pendingMintAmount = _amount;
        }
    }
    modifier validIndex(uint _index) {
        require(_index < VALIDATOR_NUMBERS , "index should be less than 20");
        _;
    }
    modifier validValidatorAddress(uint256 _index) {
        require(_msgSender() == validators[_index], "this address is not commuinity member" );
        _;
    }
    function getValidatorAddress(uint256 _index) public view validIndex(_index) returns (address)
    {
        return validators[_index];
    }
    function getValidatorIndex(address _account) public view returns(uint256)
    {
        for(uint i =0 ;i < VALIDATOR_NUMBERS; i++ )
        {
            if(validators[i] == _account)
            {
                return i;
            }
        }
        return  VALIDATOR_NUMBERS;
    }
    function setMintEnable(uint256 _index, bool _mintEnable) public  validIndex(_index) validValidatorAddress(_index) {
        enableMint[_index] = _mintEnable ;
    }
    function transactValidatorRole(uint256 _index, address _account) public validIndex(_index) validValidatorAddress(_index)
    {
        require(_account != address(0) , "address of validator can't be zero");
        validators[_index] = _account;
    }
    function getMintable() public view returns (bool) {
        uint enableCount = 0 ;
        for(uint i = 0 ; i < VALIDATOR_NUMBERS; i++)
        {
            if(enableMint[i])
            {
                enableCount += 1;
            }
        }
        if(enableCount >= VALIDATOR_NUMBERS / 2 )
        {
            return true;
        }
        else{
            return false;
        }
    }
    function getMintEnableCount() public view returns (uint256)
    {
        uint enableCount = 0 ;
        for(uint i = 0 ; i < VALIDATOR_NUMBERS; i++)
        {
            if(enableMint[i])
            {
                enableCount += 1;
            }
        }
        return enableCount;
    }
    function mint(address account) public returns (bool) {
        require(pendingMintAmount > 0, "there is no pending mint amount");
        require(getMintable(), "the vote count of validator members should be greater than 10");
        super.mint(account, pendingMintAmount);
        for(uint i =0 ;i < VALIDATOR_NUMBERS; i++ )
        {
            if(enableMint[i])
            {
                enableMint[i] = false ;
            }
        }
        pendingMintAmount = 0;
    }
}