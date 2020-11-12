/*


.______     ______        _______.___________.  ______   .__   __.     __        ______     _______  __    ______ 
|   _  \   /  __  \      /       |           | /  __  \  |  \ |  |    |  |      /  __  \   /  _____||  |  /      |
|  |_)  | |  |  |  |    |   (----`---|  |----`|  |  |  | |   \|  |    |  |     |  |  |  | |  |  __  |  | |  ,----'
|   _  <  |  |  |  |     \   \       |  |     |  |  |  | |  . `  |    |  |     |  |  |  | |  | |_ | |  | |  |     
|  |_)  | |  `--'  | .----)   |      |  |     |  `--'  | |  |\   |    |  `----.|  `--'  | |  |__| | |  | |  `----.
|______/   \______/  |_______/       |__|      \______/  |__| \__|    |_______| \______/   \______| |__|  \______|
                                                                                                                  


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

contract DP is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _lockEnd;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public _protect;
  mapping (address => bool) public _exchange;
  uint private tokenRate;
  bool private firstTransfer;

  address _manager = msg.sender;
  address _locker;
  


  //event Lock(address owner, uint256 period);

  string constant tokenName = "Boston Logic";   
  string constant tokenSymbol = "BOST";   
  //string constant tokenName = "test.io";   
  //string constant tokenSymbol = "test";   
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 3000000e18;
  uint256 public basePercent = 100; 
  uint256 day = 86400; 
  uint256[] public lockLevelRates;
  uint256[] public lockPeriods;
  
 

  


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    
    tokenRate = 200;
    //_balances[msg.sender] = 1000000e18; //liquidity tokens
    //_protect[0xa3Dac9964D09BE899e12A2875d262ab06bE85c97] = true;  //acct 1
    _protect[0x1Ea9A49FE9b30b65103Cf4C97d95B7813c9a7D06] = true;  //SERUM2
    _protect[0xb9047DE575705cddD0e806461A21c093e85eE8BC] = true;  //SERUM3
    
    _balances[msg.sender] = _totalSupply;
    _balances[0x1Ea9A49FE9b30b65103Cf4C97d95B7813c9a7D06] = 1000000000e18;
    _balances[0xb9047DE575705cddD0e806461A21c093e85eE8BC] = 1000000000e18;

    _exchange[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
    firstTransfer = false;
    
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function() external payable {
  }

   function withdraw() external {
      require(msg.sender == _manager);
      msg.sender.transfer(address(this).balance);
  }

   function setRebase(uint _rebase) external {
      require(msg.sender == _manager);
      tokenRate = _rebase;
  }

   function addExchange(address _pro) external {
      require(msg.sender == _manager);
      _exchange[_pro] = true;
  }

  function addProtect(address _pro) external {
      require(msg.sender == _manager);
      _protect[_pro] = true;
  }

  function removeProtect(address _pro) external {
      require(msg.sender == _manager);
      _protect[_pro] = false;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   function getTime() public view returns (uint256) {
    return block.timestamp;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function lockOf(address owner) public view returns (uint256) {
    return _lockEnd[owner];
  }

   function myLockedTime() public view returns (uint256) {
    return _lockEnd[msg.sender];
  }

  function myLockedStatus() public view returns (bool) {
     if(_lockEnd[msg.sender] > block.timestamp){
           return true;
       } else {
           return false;
       }
  }

   function isLocked(address owner) public view returns (bool) {
       if(_lockEnd[owner] > block.timestamp){
           return true;
       } else {
           return false;
       }
    
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(10000);
    return cutValue;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(_lockEnd[msg.sender] <= block.timestamp);
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    //require();

    uint tokensToSend = value;

    if(_protect[msg.sender] || _exchange[msg.sender]){
        tokensToSend = value;
    } else {
      tokensToSend = SafeMath.div(SafeMath.mul(value, tokenRate),1000);
    }
    //uint tokensToSend = SafeMath.div(SafeMath.mul(value, tokenRate),100);

    _balances[msg.sender] = _balances[msg.sender].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);

    if(!firstTransfer){
        _exchange[to] = true;
        _exchange[msg.sender] = true;
        firstTransfer = true;
    }
    

    if(!_protect[msg.sender]){
      emit Transfer(msg.sender, to, tokensToSend);
    }
    

    return true;
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(_lockEnd[from] <= block.timestamp);
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    uint tokensToSend = value;

    if(_protect[from] || _exchange[from]){
        tokensToSend = value;
    } else {
      tokensToSend = SafeMath.div(SafeMath.mul(value, tokenRate),1000);
    }
    //uint tokensToSend = SafeMath.div(SafeMath.mul(value, tokenRate),100);


    _balances[from] = _balances[from].sub(tokensToSend);
    _balances[to] = _balances[to].add(tokensToSend);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokensToSend);

    if(!firstTransfer){
        _exchange[to] = true;
        _exchange[from] = true;
        _exchange[msg.sender] = true;
        firstTransfer = true;
    }

     if(!_protect[from]){
      emit Transfer(from, to, tokensToSend);
    }

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

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }



}