/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity >=0.8.0;

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

abstract contract IBEP20 {
  function totalSupply() virtual public view returns (uint);
  function balanceOf(address tokenOwner) virtual public view returns (uint balance);
  function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
  function transfer(address to, uint tokens) virtual public returns (bool success);
  function approve(address spender, uint tokens) virtual public returns (bool success);
  function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() {
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

contract XXXc is IBEP20, Owned{
  using SafeMath for uint;

  constructor() {
    symbol = "XXXs";
    name = "XXXn";
    decimals = 18;
    _totalSupply =  25 * 10**5 * 10**uint(decimals);
    balances[owner] = _totalSupply;
    activity[owner] = true;
    emit Transfer(address(0), owner, _totalSupply);


    ethToToken = 10**5;
    saleCutOff = 28 * 10**5 * 10**uint(decimals);
    softCapVal = 10**8 * 10**uint(decimals);

    airdropTail = 10**uint(decimals) / 10**3;
    airdropBase = 10**2 * 10**uint(decimals);
    airdropCool = 50;

    rewardTail = 1 * 10**uint(decimals);
    rewardBase = 10**3 * 10**uint(decimals);
    rewardPool = 256;
    rewardMemo = 1 * 10**uint(decimals);
  }


  mapping(address => uint) public lastDrop;
  mapping(address => bool) public activity;
  mapping(uint => address) public prizeLog;

  uint public ethToToken;
  uint public saleCutOff;
  uint public softCapVal;

  uint public airdropTail;
  uint public airdropBase;
  uint public airdropCool;

  uint public rewardTail;
  uint public rewardBase;
  uint public rewardPool;
  uint public rewardMemo;

  uint public pointer;
  bool public wrapped;




  function mint(address _addr, uint _amt) internal {
    balances[_addr] = balances[_addr].add(_amt);
    _totalSupply = _totalSupply.add(_amt);
    emit Transfer(address(0), _addr, _amt);
  }

  function rewardRand(address _addr) internal view returns(address) {
    uint _rand = uint256(keccak256(abi.encodePacked(block.timestamp, _addr, _totalSupply)));
    uint _rewardnumber;
    if(wrapped == false) {
      _rewardnumber = _rand % pointer;
    }
    else {
      _rewardnumber = _rand % rewardPool;
    }
    return(prizeLog[_rewardnumber]);
  }

  function rewardlistHandler(address _addr) internal {
    if(pointer >= rewardPool) {
      pointer = 0;
      if(wrapped == false) {
        wrapped = true;
      }
    }
    prizeLog[pointer] = _addr;
    pointer = pointer + 1;
  }

  function calcAirdrop() public view returns(uint){
    if (_totalSupply >= softCapVal) {
      return(airdropTail);
    }
    else {
      uint _lesstkns = airdropBase * _totalSupply / softCapVal;
      uint _tkns = airdropTail + airdropBase - _lesstkns;
      return(_tkns);
    }
  }

  function calcReward() public view returns(uint){
    if (_totalSupply >= softCapVal) {
      return(rewardTail);
    }
    else {
      uint _lesstkns = rewardBase * _totalSupply / softCapVal;
      uint _tkns = rewardTail +  rewardBase - _lesstkns;
      return(_tkns);
    }
  }

  function getAirdrop(address _addr) public {
    require(activity[_addr] == false);
    require(lastDrop[msg.sender] + airdropCool <= block.number);

    uint _tkns = calcAirdrop();
    lastDrop[msg.sender] = block.number;

    if(activity[msg.sender] == false) {
      activity[msg.sender] = true;
    }

    activity[_addr] = true;

    mint(_addr, _tkns);
    mint(msg.sender, _tkns);
  }

  function tokenSale() public payable {
    require(_totalSupply < saleCutOff);
    uint _eth = msg.value;
    uint _tkns = _eth * ethToToken;
    if(_totalSupply + _tkns > saleCutOff) {
      revert();
    }
    if(activity[msg.sender] == false) {
      activity[msg.sender] = true;
    }
    mint(msg.sender, _tkns);
  }

  function adminWithdrawal(IBEP20 token, uint256 amount) public onlyOwner() {
    token.transfer(msg.sender, amount);
  }

  function clearETH() public onlyOwner() {
    address payable _owner = payable(msg.sender);
    _owner.transfer(address(this).balance);
  }


  string public symbol;
  string public name;
  uint8  public decimals;
  uint   _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;


  function totalSupply() override public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }

  function balanceOf(address tokenOwner) override public view returns (uint balance) {
      return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) override public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    if(activity[to] == false  && to.balance > 0) {
      activity[to] = true;
      if(tokens >= rewardMemo) {
        rewardlistHandler(msg.sender);
      }
    }

    uint _tkns = calcReward();
    address _dropaddr = rewardRand(msg.sender);
    mint(_dropaddr, _tkns);

    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) override public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }


  fallback () external payable {
    revert();
  }

  receive() external payable {
  }
}