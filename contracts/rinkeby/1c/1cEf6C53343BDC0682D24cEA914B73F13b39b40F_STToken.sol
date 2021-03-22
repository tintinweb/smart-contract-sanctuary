//SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/**
@dev STToken is ERC20 compatible token with following extra feature:
1. Locking Amount: Amount once locked cannot be spend or transferred
and can only be unlocked (by calling decreaseLockedAmount) by Owner of contract
@notice Not rigoursly tested. Might be unsafe for prodcution.
*/
contract STToken is IERC20, Ownable{
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public _totalSupply;

  mapping (address => uint256) private locked;
  mapping (address => uint256) private balances;
  mapping (address => mapping(address => uint)) internal allowed;

  ///Emitted when locked amount is altered
  event Locked(address indexed owner, uint256 indexed amount);

  constructor() public {
    name = "STToken";
    symbol = "STT";
    decimals = 18;
    _totalSupply = 100 * 10**(8+6);
    //Creator of contract have full supply
    balances[msg.sender] = _totalSupply;
  }
  
  /**@dev Total Supply of STToken Available
  @return totalSupply (uint256)
  */
  function totalSupply() override external view returns (uint256){
    return _totalSupply;
  }

  /**
  @dev Balance of account
  @param _account (address)
  @return balance (uint256)
   */
  function balanceOf(address _account) override external view returns (uint256){
    require(_account != address(0), "Address is null");
    return balances[_account];
  }

  /**
  @dev How much a third party can spend
  @param _owner (address)
  @param _spender (address)
  @return allowed (uint256)
  */
  function allowance(address _owner, address _spender) override external view returns (uint256){
    require(_owner != address(0), "Owner address is null");
    require(_spender != address(0), "Spender address is null");
    return allowed[_owner][_spender];
  }

  /**
  @dev How much balance of owner is in locked mode (i.e cannot be spent or transfer)
  @param _owner (address)
  @return locked (uint256)
  */
  function getLockedAmount(address _owner) public onlyOwner view returns (uint256){
    return locked[_owner];
  }

  /**
  @dev How much balance of owner is free to transfer i.e Unclocked.
  @param _owner (address)
  @return locked (uint256)
  */
  function getUnlockedAmount(address _owner) public onlyOwner view returns (uint256){
    return balances[_owner].sub(locked[_owner]);
  }

  /**
  @dev Transfer amount from onr account to another. Emits Transfer event.
  @param _recipient (address)
  @param _amount (uint256)
  @return status (boolean)
  */
  function transfer(address _recipient, uint256 _amount) override external returns (bool){
    require(_recipient != address(0), "Receipient address is null"); //address is valid
    require(_amount > 0, "Amount must be greater than or equal Zero"); //valid amount
    require(balances[msg.sender] - locked[msg.sender] >= _amount); //balance is okay
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_recipient] = balances[_recipient].add(_amount);
    emit Transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /**
  @dev Transfer amount from onr account to another. Can be called by third party as long
  as third party is allowed to spend! Emits Transfer event.
  @param _sender (address)
  @param _recipient (address)
  @param _amount (uint256)
  @return status (boolean)
  */
  function transferFrom(address _sender, address _recipient,uint256 _amount) override external returns (bool){
    require(_sender != address(0), "Sender address is null");
    require(_recipient != address(0), "Recipient address is null");
    require(_amount > 0);
    require(balances[_sender] - locked[_sender] >= _amount);
    balances[_sender] = balances[_sender].sub(_amount);
    balances[_recipient] = balances[_recipient].add(_amount);
    emit Transfer(_sender, _recipient, _amount);
    return true;
  }

  /**
  @dev Approve amount to third party for spending. Must be less than balance - lockedAmount
  @param _spender (address)
  @param _amount (address)
  @return status (boolean)
   */
  function approve(address _spender, uint256 _amount) override external returns (bool){
    require(_spender !=  address(0), "Spender address is null");
    require(_amount > 0, "Amount must be greater than zero"); 
    uint256 availableBalance = balances[msg.sender].sub(locked[msg.sender]);
    //Might wanna check for other allowances
    require(_amount < availableBalance, "Insufficient Balance");
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
  @dev increase approval of third party. Emits Approval event.
  @param _spender (address)
  @param _amount (address)
  @return updated allowance (uint256)
  */
  function increaseApproval(address _spender, uint256 _amount) public returns (uint256){
    require(_amount >= 0, "Amount must be greater than or equal to 0");
    uint256 newAmount = _amount.add(allowed[msg.sender][_spender]);
    require(newAmount < (balances[msg.sender].sub(locked[msg.sender])),"Insufficient Balance");
    allowed[msg.sender][_spender] = newAmount;
    emit Approval(msg.sender, _spender, _amount);
    return allowed[msg.sender][_spender];
  }

  /**
  @dev decrease approval of third party. If _amount to be decreas by is greater than allowed amount 
  then allowed amount is zeroed. Emits Approval event.
  @param _spender (address)
  @param _amount (address)
  @return updated allowance (uint256)
  */  
  function decreaseApproval(address _spender, uint256 _amount) public returns (uint256) {
    require(_amount >= 0, "Amount must be greater than or equal to 0" );
    uint256 amount = allowed[msg.sender][_spender];
    if (_amount > amount){
      _amount = amount;
    }
    allowed[msg.sender][_spender] = amount.sub(_amount);
    emit Approval(msg.sender, _spender, _amount);
    return allowed[msg.sender][_spender];
  }

  /**
  @dev increases locked amount. Can only be called by owner of the contract. Emits Locked amount event
  @param _owner (address)
  @param _amount (address)
  @return updated locked (uint256)
  */
  function increaseLockedAmount(address _owner, uint256 _amount) public onlyOwner returns (uint256) {
    require(_owner != address(0), "Address is null");
    require(_amount >= 0, "Amount must be greater than or equal to 0");
    uint256 lockingAmount = locked[_owner].add(_amount);
    require(balances[_owner] > lockingAmount);
    locked[_owner] = lockingAmount;
    emit Locked(_owner, _amount);
    return locked[_owner];
  }

 /**
  @dev decreases locked amount. Can only be called by owner of the contract. If _amount to be decreased by 
  is greater than locked amount then locked amount is zeroed. Emits Locked amount event
  @param _owner (address)
  @param _amount (address)
  @return updated locked (uint256)
  */
  function decreaseLockedAmount(address _owner, uint256 _amount) public onlyOwner returns (uint256) {
    require(_owner != address(0), "Owner address is null");
    require(_amount >= 0, "Amount must be greater than or equal to 0");
    uint256 amount = locked[_owner];
    if (_amount > amount){
      _amount = amount;
    }
    locked[_owner] = amount.sub(_amount);
    emit Locked(_owner, locked[_owner]);
    return locked[_owner];
  }
}