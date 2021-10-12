/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.4.24;

interface InterfaceERC20{
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract TokenEEM is InterfaceERC20 {
   
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
   
    constructor () public {
        balances[msg.sender] = 1000000; 
        _totalSupply = 1000000;
        name = "EEM";
        decimals = 0;
        symbol = "EEM";
    }
    
   
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
   
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
   
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
   
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        require(balances[from] >= tokens && allowance >= tokens);
        balances[to] += tokens;
        balances[from] -= tokens;
        if (allowance < MAX_UINT256) {
            allowed[from][msg.sender] -= tokens;
        }
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
   
}