pragma solidity ^0.4.21;

contract WeToken 
{
  mapping(address => uint256) public balanceOf;
  function transfer(address newTokensHolder, uint256 tokensNumber) 
    public 
    returns(bool);
}

contract VestingContractWT
{
  //structures
  struct AccountData
  {
    uint original_balance;
    uint limit_per_period;
    uint current_balance;
    uint current_limit;
    uint current_transferred;
  }

  //storage
  address public owner;
  WeToken public we_token;
  mapping (address => AccountData) public account_data;
  uint public current_period;
  uint[] public periods;
  address[] public accounts;

  //modifiers
  modifier onlyOwner
  {
    require(owner == msg.sender);
    _;
  }
  
  //Events
  event Transfer(address indexed to, uint indexed value);
  event OwnerTransfer(address indexed to, uint indexed value);
  event OwnerChanged(address indexed owner);
  event CurrentPeriodChanged(uint indexed current_period);

  //functions

  //debug functions
  function setPeriod(uint i, uint v)
    public
  {
    periods[i] = v;
  }

  //constructor
  function VestingContractWT(WeToken _we_token)
    public
  {
    owner = msg.sender;
    we_token = _we_token;
    
    periods.push(1542499200);  //Sunday, 18 November 2018 г., 00:00:00
    periods.push(2**256 - 1);  //very far future
    current_period = 0;

    initData(0x41c936C0dC81F0c41b45A0069bc9E1A56F4d12B3, 1806343 * 10**18);
  }
  
  /// @dev Fallback function: don&#39;t accept ETH
  function()
    public
    payable
  {
    revert();
  }

  /// @dev Get current balance of the contract
  function getBalance()
    constant
    public
    returns(uint)
  {
    return we_token.balanceOf(this);
  }

  function initData(address a, uint v) 
    private
  {
    accounts.push(a);
    account_data[a].original_balance = v;
    account_data[a].current_balance = account_data[a].original_balance;
    account_data[a].limit_per_period = account_data[a].original_balance / 2;
    account_data[a].current_limit = account_data[a].limit_per_period;
    account_data[a].current_transferred = 0;
  }

  function setOwner(address _owner) 
    public 
    onlyOwner 
  {
    require(_owner != 0);
    
    owner = _owner;
    emit OwnerChanged(owner);
  }
  
  //allow owner to transfer surplus
  function ownerTransfer(address to, uint value)
    public
    onlyOwner
  {
    uint current_balance_all = 0;
    for (uint i = 0; i < accounts.length; i++)
      current_balance_all += account_data[accounts[i]].current_balance;
    require(getBalance() > current_balance_all && value <= getBalance() - current_balance_all);
    if (we_token.transfer(to, value))
      emit OwnerTransfer(to, value);
  }
  
  function updateCurrentPeriod()
    public
  {
    require(account_data[msg.sender].original_balance > 0 || msg.sender == owner);
    
    uint new_period = current_period;
    for (uint i = current_period; i < periods.length; i++)
      if (periods[i] > now)
      {
        new_period = i;
        break;
      }
    if (new_period != current_period)
    {
      current_period = new_period;
      for (i = 0; i < accounts.length; i++)
      {
        account_data[accounts[i]].current_transferred = 0;
        account_data[accounts[i]].current_limit = account_data[accounts[i]].limit_per_period;
        if (current_period == periods.length - 1)
          account_data[accounts[i]].current_limit = 2**256 - 1;  //unlimited
      }
      emit CurrentPeriodChanged(current_period);
    }
  }

  function transfer(address to, uint value) 
    public
  {
    updateCurrentPeriod();
    require(value <= we_token.balanceOf(this) 
      && value <= account_data[msg.sender].current_balance 
      && account_data[msg.sender].current_transferred + value <= account_data[msg.sender].current_limit);

    if (we_token.transfer(to, value)) 
    {
      account_data[msg.sender].current_transferred += value;
      account_data[msg.sender].current_balance -= value;
      emit Transfer(to, value);
    }
  }

  // ERC223
  // function in contract &#39;ContractReceiver&#39;
  function tokenFallback(address from, uint value, bytes data) {
    // dummy function
  }
}