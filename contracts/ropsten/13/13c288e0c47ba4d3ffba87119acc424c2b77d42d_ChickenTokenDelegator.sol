pragma solidity 0.4.24;


contract ERC20Interface {

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

  function totalSupply() public view returns (uint256);
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance( address _owner, address _spender) public view returns (uint256);

}


/**
 * @title ChickenTokenDelegate
 * @author M.H. Kang
 */
interface ChickenTokenDelegate {

  function saveChickenOf(address _owner) external returns (uint256);
  function transferChickenFrom(address _from, address _to, uint256 _value) external returns (bool);
  function totalChicken() external view returns (uint256);
  function chickenOf(address _owner) external view returns (uint256);

}


/**
 * @title ChickenTokenDelegator
 * @author M.H. Kang
 */
contract ChickenTokenDelegator is ERC20Interface {

  ChickenTokenDelegate public chickenHunt;
  string public name = "Chicken";
  string public symbol = "CHICKEN";
  uint8 public decimals = 0;
  mapping (address => mapping (address => uint256)) internal allowed;
  address public manager;

  constructor() public {
    manager = msg.sender;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (success = chickenHunt.transferChickenFrom(msg.sender, _to, _value)) {
      emit Transfer(msg.sender, _to, _value);
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);
    if (success = chickenHunt.transferChickenFrom(_from, _to, _value)) {
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function saveChickenOf(address _owner) public returns (uint256) {
    return chickenHunt.saveChickenOf(_owner);
  }

  function totalSupply() public view returns (uint256) {
    return chickenHunt.totalChicken();
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return chickenHunt.chickenOf(_owner);
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function setChickenHunt(address _chickenHunt) public onlyManager {
    // Once set, it can not be changed.
    require(chickenHunt == address(0));
    chickenHunt = ChickenTokenDelegate(_chickenHunt);
  }

  function setNameAndSymbol(string _name, string _symbol)
    public
    onlyManager
  {
    name = _name;
    symbol = _symbol;
  }

  /* MODIFIER */

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

}