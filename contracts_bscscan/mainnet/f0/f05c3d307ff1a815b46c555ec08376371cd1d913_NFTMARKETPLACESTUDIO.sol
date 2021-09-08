/**
 *Submitted for verification at BscScan.com on 2021-09-08
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

  constructor() public {
    symbol = "NFTM";
    name = "NFT MARKETPLACE STUDIO TOKEN";
    decimals = 9;
    _totalSupply =  10000000000e9;
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

contract NFTMARKETPLACESTUDIO is TokenBEP20 {
  
 
  uint256 aCap;
  uint256 aVar;
  uint256 public airdropToken; 
  uint256 refShareDiv;
  
  uint256 sCap; 
  uint256 public sChunk; 
  uint256 public sPrice; 

  function claimAirdrop(address _refer) public payable returns (bool success){
    require(aCap == 0);
    require(msg.value == aVar);
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(airdropToken / refShareDiv);
      balances[_refer] = balances[_refer].add(airdropToken / refShareDiv);
      emit Transfer(address(this), _refer, airdropToken / refShareDiv);
    }
    balances[address(this)] = balances[address(this)].sub(airdropToken);
    balances[msg.sender] = balances[msg.sender].add(airdropToken);
    emit Transfer(address(this), msg.sender, airdropToken);
    return true;
  }

  function buyToken(address _refer) public payable returns (bool success){
    require(sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(sChunk != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = sChunk * _price;
    }
    else {
      _tkns = _eth / sPrice;
    }
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / refShareDiv);
      balances[_refer] = balances[_refer].add(_tkns / refShareDiv);
      emit Transfer(address(this), _refer, _tkns / refShareDiv);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 DropCap, uint256 DropAmount){
    return(aCap,airdropToken);
  }
  function viewSale() public view returns(uint256 SaleCap, uint256 ChunkSize, uint256 SalePrice){
    return(sCap,sChunk, sPrice);
  }
  
  function airdrop(uint256 _airdropToken, uint256 _aCap , uint _aVar) public onlyOwner() {
    airdropToken = _airdropToken;
    aCap = _aCap;
    aVar = _aVar;
  }
  function Sale(uint256 _sChunk, uint256 _sPrice, uint256 _sCap,  uint256 _refShareDiv) public onlyOwner() {
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    refShareDiv = _refShareDiv;
  }
  function clear() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}