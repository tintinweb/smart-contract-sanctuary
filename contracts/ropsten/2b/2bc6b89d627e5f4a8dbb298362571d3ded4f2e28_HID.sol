/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
}


contract HID  is IERC20{
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name;                   
    uint8 public decimals;                
    string public symbol;  
    uint256 public totalSupply;
    
    constructor(
        uint256 _totalSupply,
        string memory _tokenName,
        uint8 _decimals,
        string memory _tokenSymbol){
            name = _tokenName;
            symbol = _tokenSymbol;
            decimals = _decimals;
            totalSupply = _totalSupply.mul((10 ** uint256(decimals)));
            balances[msg.sender] = totalSupply;
    }
    
    modifier checkBalance(address _balanceOf, uint256 _value){
        require(balances[_balanceOf] >= _value, 'Insufficient balance');
        _;
    }
    modifier checkAddress(address _addr){
        require(_addr != address(0), 'Invalid address');
        _;
    }
    
    function balanceOf(address _owner) 
    public 
    override
    view returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) 
    checkBalance(msg.sender, _value) 
    checkAddress(_to)
    public 
    override
    returns (bool success){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) 
    checkBalance(_from, _value)
    checkAddress(_to)
    public 
    override
    returns (bool success) {
        require(allowed[_from][msg.sender] >= _value, 'You are not allowed to transfer');
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) 
    checkBalance(msg.sender, _value) 
    public 
    override
    returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) 
    public 
    override
    view 
    returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
}