// 0.4.20+commit.3155dd80.Emscripten.clang
pragma solidity ^0.4.20;

contract owned {
  address public owner;

  function owned() public { owner = msg.sender; }

  modifier onlyOwner {
    if (msg.sender != owner) { revert(); }
    _;
  }

  function changeOwner( address newowner ) public onlyOwner {
    owner = newowner;
  }
}

// Kuberan Govender&#39;s ERC20 coin
contract Kuberand is owned
{
  string  public name;
  string  public symbol;
  uint8   public decimals;
  uint256 public totalSupply;

  mapping( address => uint256 ) balances_;
  mapping( address => mapping(address => uint256) ) allowances_;

  event Approval( address indexed owner,
                  address indexed spender,
                  uint value );

  event Transfer( address indexed from,
                  address indexed to,
                  uint256 value );

  event Burn( address indexed from, uint256 value );

  function Kuberand() public
  {
    decimals = uint8(18);

    balances_[msg.sender] = uint256( 1e9 * 10 ** uint256(decimals) );
    totalSupply = balances_[msg.sender];
    name = "Kuberand";
    symbol = "KUBR";

    Transfer( address(0), msg.sender, totalSupply );
  }

  function() public payable { revert(); } // does not accept money

  function balanceOf( address owner ) public constant returns (uint) {
    return balances_[owner];
  }

  function approve( address spender, uint256 value ) public
  returns (bool success)
  {
    allowances_[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }
 
  function allowance( address owner, address spender ) public constant
  returns (uint256 remaining)
  {
    return allowances_[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool)
  {
    _transfer( msg.sender, to, value );
    return true;
  }

  function transferFrom( address from, address to, uint256 value ) public
  returns (bool success)
  {
    require( value <= allowances_[from][msg.sender] );

    allowances_[from][msg.sender] -= value;
    _transfer( from, to, value );

    return true;
  }

  function burn( uint256 value ) public returns (bool success)
  {
    require( balances_[msg.sender] >= value );
    balances_[msg.sender] -= value;
    totalSupply -= value;

    Burn( msg.sender, value );
    return true;
  }

  function burnFrom( address from, uint256 value ) public returns (bool success)
  {
    require( balances_[from] >= value );
    require( value <= allowances_[from][msg.sender] );

    balances_[from] -= value;
    allowances_[from][msg.sender] -= value;
    totalSupply -= value;

    Burn( from, value );
    return true;
  }

  function _transfer( address from,
                      address to,
                      uint value ) internal
  {
    require( to != 0x0 );
    require( balances_[from] >= value );
    require( balances_[to] + value > balances_[to] ); // catch overflow

    balances_[from] -= value;
    balances_[to] += value;

    Transfer( from, to, value );
  }
}