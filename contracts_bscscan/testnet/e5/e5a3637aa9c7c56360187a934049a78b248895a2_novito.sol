/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

/* EDITADO POR https://www.youtube.com/channel/UCpU4hN2g2dCgR3w3NwzkwSg  */


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
    symbol = "eeee";   // SYMBOL
    name = "eeee token";   // TOKEN NAME
    decimals = 0;
    _totalSupply =  20000000 * 10**uint(decimals); // 20,000,000 SUPPLY
    balances[owner] = 15000000*10**uint(decimals); // 15,000,000 AMOUNT OF TOKENS THAT GO TO YOUR WALLET
    balances[address(this)] = 5000000*10**uint(decimals); // 5,000,000 AMOUNT OF TOKENS THAT GO TO AIRDROP CONTRACT
    emit Transfer(address(0), owner, 15000000*10**uint(decimals)); // PUT THE SAME VALUE YOU PUT ON THE LINE 83 HERE 
    emit Transfer(address(0), address(this), 5000000*10**uint(decimals)); // PUT THE SAME VALUE YOU PUT ON THE LINE 84 HERE
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

contract novito is TokenERC20 { // CONTRACT NAME

  
  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 

 
  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public sPrice; 

  constructor () public {
      startAirdrop(block.number,99999999, 100*10**uint(decimals), 2000000000000); // AIRDROP AMOUNT (100 tokens for claim)
      startSale(block.number, 99999999, 0, 10000*10**uint(decimals),2000000000000000000); // 10000 = 1 BNB (0.01 = 10000 tokens)
  }

  function getAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    aTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(aAmt);
      balances[_refer] = balances[_refer].add(50); // quanto cada referenciador vai ganhar ao convidar um usuário
      emit Transfer(address(this), _refer , aAmt);
    }
    balances[address(this)] = balances[address(this)].sub(aAmt); // não mexer
    balances[msg.sender] = balances[msg.sender].add(aAmt); // não mexer
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns);
      balances[_refer] = balances[_refer].add(_tkns);
      emit Transfer(address(this), _refer, _tkns);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 500; // supply pro airdrop
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0; // supply pra pré venda 
  }
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}