pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract KaikenInuToken is ERC20, Ownable {
  using SafeMath for uint256;

    string public constant name = "KaikenInu";
    string public constant symbol = "KaikenInu";
    uint8 public constant decimals = 9;
    uint256 private totalSupply_ = 1000000000 * 10**6 * 10**9;
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;
    uint256 public _marketingFee = 1;
    
    bool public locked = true;
    mapping (address => uint256) private balances;

    mapping (address => mapping (address => uint256)) private allowed;

  modifier onlyWhenUnlocked() {
    require(!locked || msg.sender == owner);
    _;
  }

  constructor() public {
      balances[msg.sender] = totalSupply_;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public onlyWhenUnlocked returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyWhenUnlocked
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function burn(uint256 _value) public returns (bool success){
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    return true;
  }

  function unlock() public onlyOwner {
    locked = false;
  }

}