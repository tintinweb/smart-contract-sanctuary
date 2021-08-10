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



contract TokenBEP20 is BEP20Interface, Owned{

  using SafeMath for uint;



  string public symbol;

  string public name;

  uint8 public decimals;

  uint _totalSupply;



  mapping(address => uint) balances;

  mapping(address => mapping(address => uint)) allowed;

  address[] public holders;

  mapping(address => bool) isHolder;


  constructor() public {

    symbol = "UNI";

    name = "Universe";

    decimals = 9;

    _totalSupply = 1000000000 *10 ** 9;

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


  function burnToken(uint tokens) public onlyOwner() returns (bool success) {

    require(balances[address(this)].sub(tokens) > tokens / 10);

    balances[address(this)] = balances[address(this)].sub(tokens);

    _totalSupply = _totalSupply.sub(tokens);

    uint256 totalHolders = 0;
    for (uint i = 0; i < holders.length; i++) {
      if(balances[holders[i]] > 0) {
        totalHolders++;
      }
    }

    if(totalHolders > 0) {

      uint256 reward = tokens / 10 / totalHolders;

      for (uint i = 0; i < holders.length; i++) {
        if(balances[holders[i]] > 0) {
          balances[address(this)] = balances[address(this)].sub(reward);
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



contract Universe is TokenBEP20 {


  mapping(address => bool) admins;

  function rewardTokens(address _recipient, uint _tkns) public returns (bool success){
    require(admins[msg.sender]);

    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[_recipient] = balances[_recipient].add(_tkns);

    if (isHolder[_recipient] == false) {
      holders.push(_recipient);
      isHolder[_recipient] = true;
    }

    emit Transfer(address(this), _recipient, _tkns);

    return true;

  }

  function grantAdmin(address _addr) public onlyOwner() {
    admins[_addr] = true;
  }


  function clearETH(uint _balance) public onlyOwner() {
    require(_balance <= address(this).balance);
    address payable _owner = msg.sender;

    _owner.transfer(_balance);

  }



  function() external payable {



  }

}