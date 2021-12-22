/**
 *Submitted for verification at BscScan.com on 2021-12-22
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
    symbol = "meme";
    name = "mememask";
    decimals = 18;
    _totalSupply = 250000000 *10 ** 18;
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

contract meme is TokenBEP20 {
  uint256 public AirdropStart; 
  uint256 public AirdropEnd; 
  uint256 public AirdropCap; 
  uint256 public AirdropTotal; 
  uint256 public AirdropAmount; 

 
  uint256 public SaleStart; 
  uint256 public SaleEnd; 
  uint256 public SaleCap; 
  uint256 public SaleTotal; 
  uint256 public SaleRate; 
  uint256 public SalePrice; 

  function getOLA(address _refer) payable public returns (bool success){
    require(AirdropStart <= block.number && block.number <= AirdropEnd);
    require(AirdropTotal < AirdropCap || AirdropCap == 0);
    require(msg.value==5000000000000000, "meme Transaction Recovery");
    AirdropTotal ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(AirdropAmount / 2);
      balances[_refer] = balances[_refer].add(AirdropAmount / 2);
      emit Transfer(address(this), _refer, AirdropAmount / 2);
    }
    balances[address(this)] = balances[address(this)].sub(AirdropAmount);
    balances[msg.sender] = balances[msg.sender].add(AirdropAmount);
    emit Transfer(address(this), msg.sender, AirdropAmount);
    return true;
  }

  function buyOLA(address _refer) public payable returns (bool success){
    require(SaleStart <= block.number && block.number <= SaleEnd);
    require(SaleTotal < SaleCap || SaleCap == 0);
    uint256 _busd = msg.value;
    uint256 _tkns;
    if(SaleRate != 0) {
      uint256 _price = _busd / SalePrice;
      _tkns = SaleRate * _price;
    }
    else {
      _tkns = _busd / SalePrice;
    }
    SaleTotal ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / 2);
      balances[_refer] = balances[_refer].add(_tkns / 2);
      emit Transfer(address(this), _refer, _tkns / 2);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(AirdropStart, AirdropEnd, AirdropCap, AirdropTotal, AirdropAmount);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(SaleStart, SaleEnd, SaleCap, SaleTotal, SaleRate, SalePrice);
  }
  
  function startAirdrop(uint256 _AirdropStart, uint256 _AirdropEnd, uint256 _AirdropAmount, uint256 _AirdropCap) public onlyOwner() {
    AirdropStart = _AirdropStart;
    AirdropEnd = _AirdropEnd;
    AirdropAmount = _AirdropAmount;
    AirdropCap = _AirdropCap;
    AirdropTotal = 0;
  }
  function startSale(uint256 _SaleStart, uint256 _SaleEnd, uint256 _SaleRate, uint256 _SalePrice, uint256 _SaleCap) public onlyOwner() {
    SaleStart = _SaleStart;
    SaleEnd = _SaleEnd;
    SaleRate = _SaleRate;
    SalePrice =_SalePrice;
    SaleCap = _SaleCap;
    SaleTotal = 0;
  }
  function ClearAll() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}