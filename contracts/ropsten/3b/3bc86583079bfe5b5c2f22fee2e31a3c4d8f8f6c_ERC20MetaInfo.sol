pragma solidity ^0.4.24;

/**
 * @title ERC20 Ownable
 * @dev ERC20 interface
 * @author Comps Pte. Ltd.
 */
contract ERC20 {
  address public owner;
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;

  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title  ERC20 Meta Info
 * @dev    Mata data storage for ERC20 compatible tokens
 */
contract ERC20MetaInfo {
  address public owner;
  mapping (address => mapping (string => string)) keyValues;

  // constructor
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev   setKeyValue Assign (key, value) pair to a token
   * @param _token      ERC20 compatible token contract&#39;s address
   * @param _key        Key in string
   * @param _value      Value in string
   */
  function setKeyValue(ERC20 _token, string _key, string _value) public returns (bool) {
    // If a value is empty, anybody can assign a pair of (key, value)
    // Otherwise, only token contract&#39;s "owner" (if the token contract is Ownable),
    // or ERC20MetaInfo contract owner can assign/update a value
    require(bytes(keyValues[_token][_key]).length == 0 || owner == msg.sender || _token.owner() == msg.sender);
    keyValues[_token][_key] = _value;
    return true;
  }

  /**
   * @dev   getKeyValue Get value correspoinding to a key
   * @param _token      ERC20 compatible token contract&#39;s address
   * @param _key        Specify a key in string
   */
  function getKeyValue(address _token, string _key) public view returns (string _value) {
    return keyValues[_token][_key];
  }
}