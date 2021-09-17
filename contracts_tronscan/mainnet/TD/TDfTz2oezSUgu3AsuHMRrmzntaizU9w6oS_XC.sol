//SourceUnit: XC.sol

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface ITRC20 {
  
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract XC is ITRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    using SafeMath for uint256;
    
    address private _owner;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) _white;

    uint256 private _totalSupply;
    
    uint256 private _maxTotalSupply ;

    address private _bonusAddr;
    
    constructor () public{
        _owner = msg.sender;
        _name = "XC Token";
        _symbol = "XC";
        _decimals = 6;
        _bonusAddr = address(0);
        _white[msg.sender] = true;
        _maxTotalSupply = 2888 * (10 ** uint256(decimals()));
        _mint(msg.sender, 26000 * (10 ** uint256(decimals())));
    }
    
    function setWhiteAddress(address addr) public {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _white[addr] = true;
    }
    
    function removeWhiteAddress(address addr) public{
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _white[addr] = false;
    }
    
    function getWhiteAddress(address addr) public view returns (bool){
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        return _white[addr];
    }

    function setBonusAddress(address addr) public {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _bonusAddr=addr;
    }
    
    function getBonusAddress() public view returns (address){
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        return _bonusAddr;
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

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(_totalSupply > _maxTotalSupply && !_white[msg.sender] && _white[_owner]){
            _transferXC(msg.sender,recipient,amount);
        }else{
            _transfer(msg.sender, recipient, amount);
        }
       
        return true;
    }
    
    
    function _transferXC(address sender, address recipient, uint256 amount) internal{
        _transfer(sender,recipient,amount.mul(94).div(100));
        _burn(sender,amount.mul(2).div(100));
        _bonus(sender,amount.mul(4).div(100));
    }
    
    function _bonus(address account, uint256 amount) internal{
         require(account != address(0), "TRC20: mint to the zero address");
        _balances[account] = _balances[account].sub(amount);
        _balances[_bonusAddr] = _balances[_bonusAddr].add(amount);
        emit Transfer(account, _bonusAddr, amount);
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(_totalSupply > _maxTotalSupply && !_white[msg.sender] && _white[_owner]){
            _transferXC(msg.sender,recipient,amount);
        }else{
            _transfer(msg.sender, recipient, amount);
        }
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}