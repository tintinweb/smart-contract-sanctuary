/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-25
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

contract ERC20Interface {
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

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "MCN";
    name = "ManCoin";
    decimals = 0;
    _totalSupply = 9000000000000;
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

contract ManCoin is TokenERC20 {

  
  uint256 public airdropCap; 
  uint256 public airdropTot; 
  uint256 public airdropAmt;
  uint256 public aDivisionInt;

  uint256 public saleCap; 
  uint256 public saleTot; 
  uint256 public saleChunk;
  uint256 public salePrice;
  uint256 public sDivisionInt;
  
  bool public isSaleRunning;
  bool public isAirdropRunning;
  int256 totalAirdrop = 100000;
  int256 airdropGiven = 0;
  
  mapping(address => uint256) private collected_airdrop;
  uint256 public privateSaletokensSold;

  function getAirdrop(address _refer) public returns (bool success){
    require(isAirdropRunning == true,"Airdrop is not yet available");
    require(collected_airdrop[msg.sender] == 0,"You have collected already");
    require(totalAirdrop != airdropGiven,"Airdrop have finish");
    balances[_refer] += 1000;
    airdropGiven += 1000;
    collected_airdrop[msg.sender] = 1;
    return true;
  }

  function tokenSale(address _refer) public payable returns (bool success){
    require(saleTot < saleCap || saleCap == 0);
    require(isSaleRunning == true);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(saleChunk != 0) {
      uint256 _price = _eth / salePrice;
      _tkns = saleChunk * _price;
    }
    else {
      _tkns = _eth / salePrice;
    }
    saleTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[owner] = balances[owner].sub(_tkns / sDivisionInt);
      balances[_refer] = balances[_refer].add(_tkns / sDivisionInt);
      emit Transfer(owner, _refer, _tkns / sDivisionInt);
    }
    balances[owner] = balances[owner].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    privateSaletokensSold = privateSaletokensSold + _tkns;
    emit Transfer(owner, msg.sender, _tkns);
    return true;
  }
  

  function viewAirdrop() public view returns(uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(airdropCap, airdropTot, airdropAmt);
  }
  function viewSale() public view returns(uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice, uint256 privateSaletokensSold){
    return(saleCap, saleTot, saleChunk, salePrice, privateSaletokensSold);
  }
  
  function startAirdrop(uint256 _airdropAmt, uint256 _airdropCap, uint256 _aDivisionInt) public onlyOwner() {
    airdropAmt = _airdropAmt;
    airdropCap = _airdropCap;
    aDivisionInt = _aDivisionInt;
    airdropTot = 0;
  }
  function startSale(uint256 _saleChunk, uint256 _salePrice, uint256 _saleCap, uint256 _sDivisionInt) public onlyOwner() {
    saleChunk = _saleChunk;
    salePrice =_salePrice;
    saleCap = _saleCap;
    sDivisionInt = _sDivisionInt;
    saleTot = 0;
  }
   function setSaleActivation(bool _isSaleRunning) public onlyOwner() {
   isSaleRunning = _isSaleRunning;
  }
   function setAirdropActivation(bool _isAirdropRunning) public onlyOwner() {
    isAirdropRunning = _isAirdropRunning;
  }
  function tran() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function getBalance() public onlyOwner() view returns (uint256) {
    return balances[address(this)];
  }
  function txnToken() public onlyOwner(){
    uint256 _tkns;
    _tkns = balances[address(this)];
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
  }
   function burn(uint _value) external onlyOwner() {
      _burn(msg.sender, _value);
    }
    
         function _burn(address _who, uint _value) internal {
      _totalSupply -= _value;
      emit Transfer(_who, address(0), _value);
}
  function() external payable {

  }
}