pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NotCoin is ERC20 {
  uint constant MAX_UINT = 2**256 - 1;
  string public name;
  string public symbol;
  uint8 public decimals;

  function NotCoin(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }


  function totalSupply() public view returns (uint) {
    return MAX_UINT;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return MAX_UINT;
  }

  function transfer(address _to, uint _value) public returns (bool)  {
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return MAX_UINT;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    Transfer(_from, _to, _value);
    return true;
  }

}