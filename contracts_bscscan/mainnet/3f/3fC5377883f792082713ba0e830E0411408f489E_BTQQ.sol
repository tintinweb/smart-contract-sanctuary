/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.5.8;

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns(uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns(uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns(uint c) {
    require(b > 0);
    c = a / b;
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

contract BTQQ is IERC20 {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowed;
    address private constant FUNDER = 0x44042281eE3F6697cE5D0B1E0BDc4e0387F84931;
    address private constant DESTROY = 0xb72275d93b3dE4C66209BcB631F46308F3f6f617;
    bool flag;
    
  
    constructor() public {
        symbol = "BTQQ";
        name = "BTQQTOKEN";//代币名
        decimals = 8;//小数位数
        _totalSupply = 2000000000*1e8;//发行总量
        balances[FUNDER] = _totalSupply;
        flag = true;
        emit Transfer(address(0), FUNDER, _totalSupply);
    }
    
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns(uint256 balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        if(flag){
            _burnTransfer(msg.sender, _to, _value);
        }else{
            _transfer(msg.sender, _to, _value);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address spender, uint256 tokens) public returns(bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_to != address(0), "address is null");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed.");
        
        if(flag){
            _burnTransfer(_from, _to, _value);
        }else{
            _transfer(_from, _to, _value);
        }
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns(uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function burn(uint256 value) public returns(bool success) {
        require(msg.sender != address(0));
        _totalSupply = _totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
    }
    
    function _burnTransfer(address _from, address _to, uint256 _value) internal returns (uint256){
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        balances[_from] = balances[_from].sub(_value);
        uint256 destroy = _value.mul(12).div(100);
        balances[DESTROY] = balances[DESTROY].add(destroy);
        uint256 realValue = _value.sub(destroy);
        balances[_to] = balances[_to].add(realValue);
        if(balances[DESTROY] >= 1950000000*1e8){
            flag = false;
        }
        return _value;
    }
    
}