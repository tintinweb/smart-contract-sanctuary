/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.5.0;

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

library SafeMath {

  
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }


  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }


  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;


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

 
  function transfer(address _to, uint256 _value) public returns (bool) {
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


  function _mint(address _account, uint256 _amount) internal {
   
    require(_account != address(0), "ERC20: mint to the zero address");
        
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }


  function _burn(address _account, uint256 _amount) internal {
    
        
    require(_account != address(0), "ERC20: mint to the zero address");
        
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }


  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);


    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}


contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);


  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }


  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

  
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit Burn(_who, _value);
  }
}


contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );



  constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

 
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract TurexToken is BurnableToken, Ownable {

  string constant public name = "Turex"; 
  string constant public symbol = "TUR"; 
  uint256 constant public decimals = 18; 
  uint256 constant public initial = 5 ether * 10 ** 6; 

  mapping (address=>bool) public allowedAddresses;
  bool public unfrozen;

  event Unfreeze();

  constructor() public {
    _mint(msg.sender, initial);
  }


  function allowTransfer(address _for) public onlyOwner returns (bool) {
    allowedAddresses[_for] = true;
    return true;
  }

  function disableTransfer(address _for) public onlyOwner returns (bool) {
    allowedAddresses[_for] = false;
    return true;
  }
  
  modifier isTrasferAllowed(address a, address b) {
    require(unfrozen || allowedAddresses[a] || allowedAddresses[b]);
    _;
  }


  function unfreeze() public onlyOwner returns (bool) {
    require(!unfrozen);
    unfrozen = true;
    emit Unfreeze();
    return true;
  }


  /// @dev Overrides burnable interface to prevent interaction before finalization
  function burn(uint256 _value) public isTrasferAllowed(msg.sender, address(0x0)) {
    super.burn(_value);
  }

  /// @dev Overrides burnable interface to prevent interaction before finalization
  function burnFrom(address _from, uint256 _value) isTrasferAllowed(_from, address(0x0)) public {
    super.burnFrom(_from, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function transferFrom(address _from, address _to, uint256 _value) public isTrasferAllowed(_from, _to) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function transfer(address _to, uint256 _value) public isTrasferAllowed(msg.sender, _to) returns (bool) {
    return super.transfer(_to, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function approve(address _spender, uint256 _value) public isTrasferAllowed(msg.sender, _spender) returns (bool) {
    return super.approve(_spender, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function increaseApproval(address _spender, uint256 _addedValue) public isTrasferAllowed(msg.sender, _spender) returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function decreaseApproval(address _spender, uint256 _subtractedValue) public isTrasferAllowed(msg.sender, _spender) returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}