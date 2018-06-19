pragma solidity ^0.4.21;

contract ABXToken 
{
  mapping(address => uint256) public balanceOf;
  function transfer(address newTokensHolder, uint256 tokensNumber) 
    public 
    returns(bool);
}

contract VestingContractABX
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
  ABXToken public abx_token;
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
  function VestingContractABX(ABXToken _abx_token)
    public
  {
    owner = msg.sender;
    abx_token = _abx_token;
    
    periods.push(1524355200);  //2018-04-22
    periods.push(1526947200);  //2018-05-22
    periods.push(2**256 - 1);  //very far future
    current_period = 0;
    
    initData(0xB99f9Ff7349A74f74Ee78bA76F692381925B4372, 192998805 * 10**16);
    initData(0x6f15F81d3726dEc1c7D8db7c7C139de5B8a5DCdA, 50000 * 10**18);
    initData(0x0339Db6d5827cFf0271a5bd3EEe991bE1DCe2AD9, 50000 * 10**18);
    initData(0x4477A5b0Bd59E4661008D07938293e61A95cbC9D, 25725 * 10**18);
    initData(0x1c8dBee998C6B905B46e517Cf5A6E935673b7c8F, 33650 * 10**18);
    initData(0xF3E33Ee85414Cb9b2D1EcFf9508BD24285fD3194, 46350 * 10**18);
    initData(0x70d370528cd58A2531Db49e477964D760cf9fE56, 413950 * 10**18);
    initData(0xd2A64d99025b1b0B0Eb8C65d7a89AD6444842E60, 500000 * 10**18);
    initData(0xf8767ced61c1f86f5572e64289247b1c86083ef1, 33333333 * 10**16);
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
    return abx_token.balanceOf(this);
  }

  function initData(address a, uint v) 
    private
  {
    accounts.push(a);
    account_data[a].original_balance = v;
    account_data[a].current_balance = account_data[a].original_balance;
    account_data[a].limit_per_period = account_data[a].original_balance / 3;
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
    if (abx_token.transfer(to, value))
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
    require(value <= abx_token.balanceOf(this) 
      && value <= account_data[msg.sender].current_balance 
      && account_data[msg.sender].current_transferred + value <= account_data[msg.sender].current_limit);

    if (abx_token.transfer(to, value)) 
    {
      account_data[msg.sender].current_transferred += value;
      account_data[msg.sender].current_balance -= value;
      emit Transfer(to, value);
    }
  }
}