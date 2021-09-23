/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract MNMToken
{
  uint256 internal constant _total_whole_tokens = 100000;
  uint8 public constant decimals = 18;

  mapping (address => uint256) internal _ledger;
  mapping (address => mapping (address => uint256)) _allowance;

  uint256 internal constant _hard_token_limit = (2**256-1) / 10 ** decimals;
  uint256 public totalSupply = _total_whole_tokens * 10 ** decimals;

  address internal _owner;
  string public constant name = "MNM Token";
  string public constant symbol = "MNM";

  uint256 public available;
  uint256 public tokenPrice;

  address _nft_contract;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor()
  {
    require(_total_whole_tokens <= _hard_token_limit, 'max token limit exceeded');
    _owner = msg.sender;
    uint256 reserved = 10000 * 10 ** decimals;
    _ledger[msg.sender] = reserved;
    available = totalSupply - reserved;
    tokenPrice = 10 ** 16;

    emit Transfer(address(0), msg.sender, reserved);
  }

  receive() external payable {}
  fallback() external payable {}

  function withdrawWhole(address from, uint256 num_whole_tokens)
    public
  {
    _only_nft_contract();
    uint256 full_quantity = num_whole_tokens * 10 ** decimals;
    require(_ledger[from] >= full_quantity, 'insufficient tokens');

    _ledger[from] -= full_quantity;
    totalSupply -= full_quantity;

    emit Transfer(from, address(0), full_quantity);
  }

  function depositWhole(address to, uint256 num_whole_tokens)
    public
  {
    _only_nft_contract();
    uint256 full_quantity = num_whole_tokens * 10 ** decimals;

    _ledger[to] += full_quantity;
    totalSupply += full_quantity;

    emit Transfer(address(0), to, full_quantity);
  }

  function setNFTContractAddress(address nft_contract)
    external
  {
    _only_owner();
    _nft_contract = nft_contract;
  }

  function setContractOwner(address new_owner)
    external
  {
    _only_owner();
    _owner = new_owner;
  }

  function balanceOf(address owner)
    external view returns(uint256)
  {
    require(owner != address(0), 'address 0 is not an owner');
    return _ledger[owner];
  }

  function setTokenPrice(uint256 price)
    external
  {
    _only_owner();
    tokenPrice = price;
  }

  function giftTokens(uint256 num_tokens, address to)
    external
  {
    _only_owner();
    require(num_tokens <= available, 'not enough tokens available');
    available -= num_tokens;
    _ledger[to] += num_tokens;

    emit Transfer(address(0), to, num_tokens);
  }

  function buyTokens()
    external payable
  {
    uint256 num_tokens = msg.value * 10 ** decimals / tokenPrice;
    require(num_tokens > 0, 'not enough eth sent');
    require(num_tokens <= available, 'not enough tokens available');
    available -= num_tokens;
    _ledger[msg.sender] += num_tokens;

    emit Transfer(address(0), msg.sender, num_tokens);
  }

  function withdrawEth()
    external
  {
    _only_owner();
    (bool success,) = msg.sender.call{value:address(this).balance}("");
    require(success, 'transfer failed');
  }

  function transfer(address to, uint256 value)
    external returns(bool)
  {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value)
    external returns(bool)
  {
    if (msg.sender != from) {
      uint256 allowance_val = _allowance[from][msg.sender];
      require(allowance_val >= value, 'you are not authorized to transfer that amount');
      _allowance[from][msg.sender] -= value;
    }
    _transfer(from, to, value);
    return true;
  }

  function _transfer(address from, address to, uint256 value)
    internal
  {
    require(_ledger[from] >= value, 'insufficient funds');

    _ledger[to] += value;
    _ledger[from] -= value;

    emit Transfer(from, to, value);
  }

  function approve(address spender, uint256 value)
    external returns(bool)
  {
    _allowance[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);
    return true;
  }

  function allowance(address owner, address spender)
    external view returns(uint256)
  {
    return _allowance[owner][spender];
  }

  function _only_nft_contract()
    internal view
  {
    require(msg.sender == _nft_contract, 'not the nft contract');
  }

  function _only_owner()
    internal view
  {
    require(msg.sender == _owner, 'not the contract owner');
  }
}