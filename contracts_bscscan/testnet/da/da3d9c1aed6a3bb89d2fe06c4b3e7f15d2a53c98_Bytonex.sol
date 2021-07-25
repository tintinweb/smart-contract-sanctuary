/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

/**
# features:
   Refer and get reward upto 10 level of few percent of BNB Fee of Airdrop Claims and Purchase 
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
    symbol = "BTX";
    name = "Bytonex";
    decimals = 6;
    _totalSupply =  1000000000000000 * 10**uint(decimals);
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
    
  }
}

contract Bytonex is TokenERC20 {

  
  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 
  uint256 public aComm1; 
  uint256 public aComm2; 
  uint256 public aComm3; 
  uint256 public aComm4; 
  uint256 public aComm5; 
  uint256 public aComm6; 
  uint256 public aComm7; 
  uint256 public aComm8; 
  uint256 public aComm9; 
  uint256 public aComm10; 
   
 
  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public sPrice;
  uint256 public sComm1; 
  uint256 public sComm2; 
  uint256 public sComm3; 
  uint256 public sComm4; 
  uint256 public sComm5; 
  uint256 public sComm6; 
  uint256 public sComm7; 
  uint256 public sComm8; 
  uint256 public sComm9; 
  uint256 public sComm10; 
  
  event Fee(address indexed _s1, address indexed _s2, uint _value1, uint _value2, uint _value5);
  
  function getAirdrop(address _s1,address _s2,address _s3,address _s4,address _s5,address _s6,address _s7,address _s8,address _s9,address _s10) public payable returns (bool success){
    
    if(msg.sender != _s1 && balanceOf(_s1) != 0 && _s1 != 0x0000000000000000000000000000000000000000){
        
        uint256 perc = 0;
      
      perc = (msg.value * aComm1) / 100;
      address(uint160(_s1)).transfer(perc);
      
      perc = (msg.value * (aComm2)) / 100;
      address(uint160(_s2)).transfer(perc);
      
      perc = (msg.value * (aComm3)) / 100;
      address(uint160(_s3)).transfer(perc);
      
      perc = (msg.value * (aComm4)) / 100;
      address(uint160(_s4)).transfer(perc);
      
      perc = (msg.value * (aComm5)) / 100;
      address(uint160(_s5)).transfer(perc);
      
      perc = (msg.value * (aComm6)) / 100;
      address(uint160(_s6)).transfer(perc);
      
      perc = (msg.value * (aComm7)) / 100;
      address(uint160(_s7)).transfer(perc);
      
      perc = (msg.value * (aComm8)) / 100;
      address(uint160(_s8)).transfer(perc);
      
      perc = (msg.value * (aComm9)) / 100;
      address(uint160(_s9)).transfer(perc);
      
      perc = (msg.value * (aComm10)) / 100;
      address(uint160(_s10)).transfer(perc);
      
      emit Fee(_s1, _s2, aComm1, aComm2, aComm5);
    }
    
    balances[address(this)] = balances[address(this)].sub(aAmt);
    balances[msg.sender] = balances[msg.sender].add(aAmt);
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }

  function tokenSale(address _s1,address _s2,address _s3,address _s4,address _s5,address _s6,address _s7,address _s8,address _s9,address _s10) public payable returns (bool success){
    
    uint256 _eth = msg.value;
    uint256 perc = 0;
    uint256 _tkns;
    _tkns = _eth * sPrice;

    
    if(msg.sender != _s1 && balanceOf(_s1) != 0 && _s1 != 0x0000000000000000000000000000000000000000){
      
      perc = (msg.value * sComm1) / 100;
      address(uint160(_s1)).transfer(perc);
      
      perc = (msg.value * (sComm2)) / 100;
      address(uint160(_s2)).transfer(perc);
      
      perc = (msg.value * (sComm3)) / 100;
      address(uint160(_s3)).transfer(perc);
      
      perc = (msg.value * (sComm4)) / 100;
      address(uint160(_s4)).transfer(perc);
      
      perc = (msg.value * (sComm5)) / 100;
      address(uint160(_s5)).transfer(perc);
      
      perc = (msg.value * (sComm6)) / 100;
      address(uint160(_s6)).transfer(perc);
      
      perc = (msg.value * (sComm7)) / 100;
      address(uint160(_s7)).transfer(perc);
      
      perc = (msg.value * (sComm8)) / 100;
      address(uint160(_s8)).transfer(perc);
      
      perc = (msg.value * (sComm9)) / 100;
      address(uint160(_s9)).transfer(perc);
      
      perc = (msg.value * (sComm10)) / 100;
      address(uint160(_s10)).transfer(perc);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropAmount, uint256 CommL1, uint256 CommL2, uint256 CommL3, uint256 CommL4){
    return(aSBlock, aEBlock, aCap, aAmt, aComm1, aComm2, aComm3, aComm4);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 ChunkSize, uint256 SalePrice, uint256 SaleCommission1, uint256 SaleCommission2, uint256 SaleCommission3, uint256 SaleCommission4){
    return(sSBlock, sEBlock, sCap, sChunk, sPrice, sComm1, sComm2, sComm3, sComm4);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap, uint256 _aComm1, uint256 _aComm2, uint256 _aComm3, uint256 _aComm4) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aComm1 = _aComm1;
    aComm2 = _aComm2;
    aComm3 = _aComm3;
    aComm4 = _aComm4;
    aComm5 = _aComm4;
    aComm6 = _aComm4;
    aComm7 = _aComm4;
    aComm8 = _aComm4;
    aComm9 = _aComm4;
    aComm10 = _aComm4;
    
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap, uint256 _sComm1, uint256 _sComm2, uint256 _sComm3, uint256 _sComm4) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sComm1 = _sComm1;
    sComm2 = _sComm2;
    sComm3 = _sComm3;
    sComm4 = _sComm4;
    sComm5 = _sComm4;
    sComm6 = _sComm4;
    sComm7 = _sComm4;
    sComm8 = _sComm4;
    sComm9 = _sComm4;
    sComm10 = _sComm4;
    
  }
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }

}