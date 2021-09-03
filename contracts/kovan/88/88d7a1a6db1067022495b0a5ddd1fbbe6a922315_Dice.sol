/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogAddress(string s, address a);
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


contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        //emit LogAddress("msg.sender=", msg.sender);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        emit LogAddress("msg.sender=", msg.sender);
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


contract DOGKINGERC20Token is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address payable feeReceiver, address tokenOwnerAddress) public payable {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;
      _mint(tokenOwnerAddress, totalSupply);
      feeReceiver.transfer(msg.value);
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
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


contract Dice {
    
    address private owner = 0x1D30DFa6028837fDD557d7DCf5F28C5d36F2E83B;
    address internal tokenAddress = 0xBEA4E88Ed1c7BA86B3D182f3Cf046B6507297994;
    DOGKINGERC20Token token;
    
    uint256 private poolBalance;
    uint256 private id;
    uint256 [] private resultList;
    uint256 [] private resultAmountList;
    address [] private addressList;
    bool private locked = false;
    
    constructor() public {
        token = DOGKINGERC20Token(tokenAddress);
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(_to != address(0), "_to is the zero address");
        require(locked == false, "transfer locked");
        
        token.transferFrom(_from, _to, _value);
    }
    
    function transfer(address _to, uint _value) public {
        require(_to != address(0), "_to is the zero address");
        require(locked == false, "transfer locked");
        
        token.transfer(_to, _value);
       
    }
 
    function bet(uint _result, address _betAddress, uint256 _betAmount, uint256 _winAmount) public {
        token.transferFrom(_betAddress, address(this), _betAmount);
        if (_result == 1) {
            token.transfer(_betAddress, _winAmount); 
            setResult(_betAddress, _result, _winAmount);
        } 
        if (_result == 0) {
            setResult(_betAddress, _result, _betAmount);
        }
        
    }
    
    function getPoolBalance() public view returns (uint256){
        return token.balanceOf(address(this));
    }
    
    function setResult(address _betAddress, uint256 _result, uint256 _resultAmount) internal {
        id = id + 1;
        addressList.push(_betAddress);
        resultList.push(_result);
        resultAmountList.push(_resultAmount);
    }
     
    function getId() public view returns (uint256) {
        return id;
    }
    
    function getResult(uint256 _id) public view returns (uint256) {
        return resultList[_id];
    }
    
    function getResultAmount(uint256 _id) public view returns (uint256) {
        return resultAmountList[_id];
    }
    
    function getBetAddress(uint256 _id) public view returns (address) {
        return addressList[_id];
    }
    
    function getResultInfo(uint256 _id) public view returns (address, uint256, uint256) {
        return (addressList[_id], resultList[_id], resultAmountList[_id]);
    }
    
    function setLocked(bool _isLocked) public {
        if (msg.sender == owner) {
            locked = _isLocked;
        }
        
    }
    
}