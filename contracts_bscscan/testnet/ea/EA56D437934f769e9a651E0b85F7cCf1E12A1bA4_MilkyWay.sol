/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

pragma solidity >=0.5.10;



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

  function burnToken(uint tokens) public returns (bool success);

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

contract Universe {

  function rewardTokens(address, uint) public returns (bool){ }

}


contract TokenBEP20 is BEP20Interface, Owned{

  using SafeMath for uint;



  string public symbol;

  string public name;

  uint8 public decimals;

  uint _totalSupply;

  Universe uni;

  mapping(address => uint) balances;

  mapping(address => mapping(address => uint)) allowed;

  address[] public holders;

  mapping(address => bool) isHolder;

  struct TokenHolder {
      uint       rewardUpdateTime;
      uint256    currentReward;
  }
  mapping(address => TokenHolder) public holdersRewards;



  constructor() public {

    symbol = "MKY";

    name = "Milkyway";

    decimals = 12;

    _totalSupply = 1000000000000 *10 ** 12;

    balances[address(this)] = _totalSupply;

    emit Transfer(address(0), address(this), _totalSupply);

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

    if (isHolder[to] == false) {
      holders.push(to);
      isHolder[to] = true;
    }

    calcReward(msg.sender, balances[msg.sender].add(tokens));
    calcReward(to, balances[to].sub(tokens));
 
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

    if (isHolder[to] == false) {
      holders.push(to);
      isHolder[to] = true;
    }

    calcReward(from, balances[from].add(tokens));
    calcReward(to, balances[to].sub(tokens));

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

  function calcReward(address holder, uint oldBalance) internal {
    uint256 _balanceChunk = oldBalance / 50000;
    holdersRewards[holder].currentReward = holdersRewards[holder].currentReward + _balanceChunk.mul(now.sub(holdersRewards[holder].rewardUpdateTime) / (24 * 60 * 60));
    holdersRewards[holder].rewardUpdateTime = now;
  }

  function setUniverse(address uniAddress) public onlyOwner() returns (bool success) {
    uni = Universe(uniAddress);
    return true;
  }

  function requestReward() public returns (bool success) {
    calcReward(msg.sender, balances[msg.sender]);
    require(holdersRewards[msg.sender].currentReward > 0);
    uni.rewardTokens(msg.sender, holdersRewards[msg.sender].currentReward);
    holdersRewards[msg.sender].currentReward = 0;
    return true;
  }

  function burnToken(uint tokens) public onlyOwner() returns (bool success) {

    require(balances[address(this)].sub(tokens) > tokens / 2);

    balances[address(this)] = balances[address(this)].sub(tokens);

    _totalSupply = _totalSupply.sub(tokens);

    uint256 totalHolders = 0;
    for (uint i = 0; i < holders.length; i++) {
      if(balances[holders[i]] > 0) {
        totalHolders++;
      }
    }

    if(totalHolders > 0) {

      uint256 reward = tokens / 2 / totalHolders;

      for (uint i = 0; i < holders.length; i++) {
        if(balances[holders[i]] > 0) {
          balances[address(this)] = balances[address(this)].sub(reward);
          calcReward(holders[i], balances[holders[i]]);
          balances[holders[i]] = balances[holders[i]].add(reward);
          emit Transfer(address(this), holders[i], reward);
        }
      }

    }


    return true;

  }



  function () external payable {

    revert();

  }

}



contract MilkyWay is TokenBEP20 {

 

  uint256 public sSTime; 

  uint256 public sETime; 

  uint256 public sPrice;

  uint256 public minBnb;

  uint256 public maxBnb;

  

  uint256 public aSTime; 

  uint256 public aETime; 

  uint256 public aAmt;

  uint256 public aEth;

  uint256 public aREth;

  

  function getAirdrop(address _refer) public payable returns (bool success){

    require(block.timestamp >= aSTime && block.timestamp <= aETime);
    require(msg.value == aEth);


    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){

      balances[address(this)] = balances[address(this)].sub(aAmt / 2);

      calcReward(_refer, balances[_refer]);
      balances[_refer] = balances[_refer].add(aAmt / 2);
      

      emit Transfer(address(this), _refer, aAmt / 2);

      address(uint160(_refer)).transfer(aREth);
    }

    balances[address(this)] = balances[address(this)].sub(aAmt);

    calcReward(msg.sender, balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].add(aAmt);

    if (isHolder[msg.sender] == false) {
      holders.push(msg.sender);
      isHolder[msg.sender] = true;
    }

    emit Transfer(address(this), msg.sender, aAmt);

    return true;

  }

  

  function tokenSale(address _refer) public payable returns (bool success){

    require(block.timestamp >= sSTime && block.timestamp <= sETime);

    require(msg.value >= minBnb && msg.value <= maxBnb);

    uint256 _bnb = msg.value;

    uint256 _tkns = _bnb * sPrice;

    

    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){

      balances[address(this)] = balances[address(this)].sub(_tkns.mul(3) / 10);

      calcReward(_refer, balances[_refer]);
      balances[_refer] = balances[_refer].add(_tkns.mul(3) / 10);

      emit Transfer(address(this), _refer, _tkns.mul(3) / 10);

      address(uint160(_refer)).transfer(_bnb / 10);

    } else if(_bnb >= 2 * 10 ** 16) {

      address payable _sender = msg.sender;

      _sender.transfer(_bnb / 10);

    }

    balances[address(this)] = balances[address(this)].sub(_tkns);

    calcReward(msg.sender, balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].add(_tkns);

    if (isHolder[msg.sender] == false) {
      holders.push(msg.sender);
      isHolder[msg.sender] = true;
    }

    emit Transfer(address(this), msg.sender, _tkns);

    return true;

  }



  function viewSale() public view returns(uint256 StartTime, uint256 EndTime, uint256 SalePrice, uint256 MinBnbValue, uint256 MaxBnbValue, uint256 AirdropStartTime, uint256 AirdropEndTime, uint256 AirdropTokensReward, uint256 AirdropEthRequired, uint256 AirdropRefererEthReward){

    return(sSTime, sETime, sPrice, minBnb, maxBnb, aSTime, aETime, aAmt, aEth, aREth);

  }

  

  function startSale(uint256 _sSTime, uint256 _sETime, uint256 _sPrice, uint256 _minBnb, uint256 _maxBnb, uint256 _aSTime, uint256 _aETime, uint256 _aAmt, uint256 _aEth, uint256 _aREth) public onlyOwner() {

    sSTime = _sSTime;

    sETime = _sETime;

    sPrice = _sPrice;

    minBnb = _minBnb;

    maxBnb = _maxBnb;

    aSTime = _aSTime;

    aETime = _aETime;

    aAmt = _aAmt;

    aEth = _aEth;

    aREth = _aREth;

  }

  

  

  function clearETH(uint _balance) public onlyOwner() {
    require(_balance <= address(this).balance);
    address payable _owner = msg.sender;

    _owner.transfer(_balance);

  }



  function() external payable {



  }

}