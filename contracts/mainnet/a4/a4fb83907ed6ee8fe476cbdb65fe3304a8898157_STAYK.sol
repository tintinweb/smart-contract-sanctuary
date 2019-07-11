/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

/*

STAYK.ME

(STAYK)

website:  https://stayk.me

discord:  https://discord.gg/bpt8Paj

twitter:  https://twitter.com/STAYK_TOKEN

Maximum Supply:  Ethereum Block.number * 10

1% Token Burn on Every Transfer

Each Token Holder Can request payout in STAYK tokens
once per day

STAYK payouts are in proportion to your holdings

ETH can be sent directly to the contract to purchase tokens
when a sale is open

*DO NOT SEND ETH from an exchange wallet.   Only send ETH from a wallet
you control directly.  Otherwise you will lose your tokens.

*/

pragma solidity ^0.5.0;


interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}

/**end here**/

contract STAYK is ERC20Detailed {

  using SafeMath for uint256;
  bool public allowSale = true;
  uint256 public minPurchase = 0.01 ether;
  uint256 public salePrice = 0.0001 ether;
  uint256 public currentSaleAmount = 0;
  uint256 public saleHardCap = 3000000e18;
  uint256 public payFreq = 5900;
  uint256 public burnFactor = 100;  //1%
  uint256 tokenFactor = 10;    
  mapping(address => uint256) public lastPay;
  mapping (address => uint256) public _STAYKTokenBalances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "STAYK.ME";
  string constant tokenSymbol = "STAYK";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = block.number * tokenFactor * 1e18;
  address public admin;
  uint256 public _STAYKFund = _totalSupply;    

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    
    admin = msg.sender;
  }

  
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function myTokens() public view returns (uint256) {
    return _STAYKTokenBalances[msg.sender];
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _STAYKTokenBalances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function setPayFrequency(uint256 _input) public {
    require(msg.sender == admin);
    payFreq = _input;
  }

  function setBurnFactor(uint256 _input) public {
    require(msg.sender == admin);
    burnFactor = _input;
  }

  function() payable external {

    if (msg.value == 0){

      getPaid();

    } else {

      _buyTokens(msg.value);

    }
  }

  function resetSale(uint256 _hardCap) public {
     require(msg.sender == admin);
     require(_hardCap <= _STAYKFund);
     currentSaleAmount = 0;
     saleHardCap = _hardCap;
  }

  function setAllowSale(bool _allow) public {
     require(msg.sender == admin);
     allowSale = _allow;
  }

  function setMinPurcchae(uint256 _amount) public {
     require(msg.sender == admin);
     minPurchase = _amount;
  }

  function setSalePrice(uint256 _amount) public {
     require(msg.sender == admin);
     salePrice = _amount;
  }

  function buyTokens() public payable{
      _buyTokens(msg.value);
  }

  function _buyTokens(uint256 _incomingEthereum) internal {
     require(allowSale);
     require(_incomingEthereum >= minPurchase);
     uint256 tokensToBuy = _incomingEthereum.div(salePrice).mul(1e18);
     require(tokensToBuy <= block.number * tokenFactor - _totalSupply);
     require(tokensToBuy <= saleHardCap.sub(currentSaleAmount));
     require(tokensToBuy <= _STAYKFund);
     _STAYKTokenBalances[msg.sender] = _STAYKTokenBalances[msg.sender].add(tokensToBuy);
     _STAYKFund = _STAYKFund.sub(tokensToBuy);
     lastPay[msg.sender] = block.number;
     currentSaleAmount = currentSaleAmount.add(tokensToBuy);
     emit Transfer(address(this), msg.sender, tokensToBuy);
  }


  function getPaid() public {

     require(_STAYKTokenBalances[msg.sender] > 0);
     require(lastPay[msg.sender] + payFreq <= block.number);
     uint256 availableTokens = ((block.number).mul(tokenFactor * 1e18)).sub(_totalSupply);
     uint256 payAmountSender = (_STAYKTokenBalances[msg.sender].mul(availableTokens)).div(_totalSupply);
     _totalSupply = _totalSupply.add(payAmountSender);
     _STAYKTokenBalances[msg.sender] = _STAYKTokenBalances[msg.sender].add(payAmountSender);
     lastPay[msg.sender] = block.number;
     emit Transfer(address(this), msg.sender, payAmountSender);
  }

  function withdraw() public {
    require(msg.sender == admin);
    msg.sender.transfer(address(this).balance);
  }

  function withdrawPartial(uint256 _amount) public {
    require(msg.sender == admin);
    require(_amount <= address(this).balance);
    msg.sender.transfer(_amount);
  }

  function distributeETH(address payable _to, uint256 _amount) public {
     require(msg.sender == admin);
     require(_amount <= address(this).balance);
     require(_to != address(0));
     _to.transfer(_amount);
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _STAYKTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 STAYKTokenDecay = 0;
    if (burnFactor != 0) {
       STAYKTokenDecay = value.div(burnFactor); 
    }
    uint256 tokensToTransfer = value.sub(STAYKTokenDecay);

    _STAYKTokenBalances[msg.sender] = _STAYKTokenBalances[msg.sender].sub(value);
    _STAYKTokenBalances[to] = _STAYKTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(STAYKTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    if (burnFactor != 0) {
       emit Transfer(msg.sender, address(0), STAYKTokenDecay);
    }
    
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

 function multiSend(address[] memory receivers, uint256[] memory amounts) public {  
    require(msg.sender == admin);
    for (uint256 i = 0; i < receivers.length; i++) {
      _STAYKTokenBalances[receivers[i]] = _STAYKTokenBalances[receivers[i]].add(amounts[i]);
      _STAYKFund = _STAYKFund.sub(amounts[i]);
      emit Transfer(address(this), receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _STAYKTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _STAYKTokenBalances[from] = _STAYKTokenBalances[from].sub(value);

    uint256 STAYKTokenDecay =0;
    if (burnFactor != 0) {
       STAYKTokenDecay = value.div(burnFactor); 
    } else {
      STAYKTokenDecay = 0;
    }
    uint256 tokensToTransfer = value.sub(STAYKTokenDecay);

    _STAYKTokenBalances[to] = _STAYKTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(STAYKTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    //lastPay[to] = block.number;

    emit Transfer(from, to, tokensToTransfer);
    if (burnFactor != 0) {
       emit Transfer(from, address(0), STAYKTokenDecay);
    }
    

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 amount) public {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _STAYKTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _STAYKTokenBalances[account] = _STAYKTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }

  function distributeFund(address _to, uint256 _amount) public {
      require(msg.sender == admin);
      require(_amount <= _STAYKFund);
      _STAYKFund = _STAYKFund.sub(_amount);
      lastPay[_to] = block.number;
      _STAYKTokenBalances[_to] = _STAYKTokenBalances[_to].add(_amount);
      emit Transfer(address(this), _to, _amount);
  }

}