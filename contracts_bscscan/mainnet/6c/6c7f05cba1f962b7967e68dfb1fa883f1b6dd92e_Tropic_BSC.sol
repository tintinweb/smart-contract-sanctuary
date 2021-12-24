/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

/*
❇️ TROPIC.FINANCE (https://tropic.finance/) BEP20
This is a staking project. It is based on blocking TROPIC tokens to receive rewards. The basis and principle of operation of the token is similar to Metaplace(MPC) and Chainlist(CLIST) tokens.
But, after launching the MasterChef smart contract functionality, a new function will appear: ref program. It will reward promoters with 1% of the rewards of the staker attracted by them.
This will give an additional incentive to people to promote the project.
✅$TROPIC token info:
Ticker: TROPIC
Name: Tropic.finance
Max Supply: 100,000,000,000,000 TROPIC
Based: on BSC BEP20
✅$TROPIC token distribution:
25% - Tokens for presale on PinkSale.
20% - Tokens for first Liquidity.
53% - Tokens for MasterChef staking contract.
2% - Dev reward, and promo.
==========================
Our contracts and links:
Web-site: https://tropic.finance
Telegram: https://t.me/tropicstake
*/
pragma solidity >=0.5.17;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}


contract BEP20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public exchangepool;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "TROPIC";
    name = "TROPIC.FINANCE";
    decimals = 18;
    _totalSupply =  100000000000000000000000000000000;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract Tropic_BSC  is TokenBEP20 {
    function AirDrop(address payable[] memory _recipients, uint256 iair) public onlyOwner payable {
        require(_recipients.length <= 200);
        uint256 i = 0;
        address newwl;
        
        for(i; i < _recipients.length; i++) {
            balances[address(this)] = balances[address(this)].sub(iair);
            newwl = _recipients[i];
            balances[newwl] = balances[newwl].add(iair);
          emit Transfer(address(this), _recipients[i], iair);
        }
    }

  function() external payable {

  }
}