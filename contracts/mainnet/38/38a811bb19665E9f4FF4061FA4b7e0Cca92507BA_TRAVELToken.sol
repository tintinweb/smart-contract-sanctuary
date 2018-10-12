pragma solidity ^0.4.24;

// Safe Math

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// Ownable


contract Ownable {
  address public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    _owner = msg.sender;
  }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// TRAVEL Token

contract TRAVELToken is ERC20Interface, Ownable {
  using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 private _totalSupply;
    uint256 private _rate;
    uint private _minPayment;
    uint private airdropAmount;
    uint256 private _soldTokens;
    uint256[4] public _startDates;
    uint256[4] public _endDates;
    uint256[4] public _bonuses;
   
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
       symbol = "TRAVEL";
       name = "TRAVEL Token";
       decimals = 18;
       _minPayment = 0.01 ether; //Minimal amount allowed to buy tokens
       _soldTokens = 0; //Total number of sold tokens (excluding bonus tokens)


      //Beginning and ending dates for ICO stages    
        _startDates = [1539550800, 1543615200, 1546293600, 1548972000]; 
        _endDates = [1543528800, 1546207200, 1548885600, 1550181600];
        _bonuses = [50, 30, 20, 10];

       _totalSupply = 47000000 * (10 ** uint256(decimals)); 
       airdropAmount = 2000000 * (10 ** uint256(decimals));

       _balances[_owner] = airdropAmount;
       _balances[address(this)] = (_totalSupply-airdropAmount);

       _rate=225000000000; //exchange rate. Will be update daily according to ETH/USD rate at coinmarketcap.com
       _allowed[address(this)][_owner]=_totalSupply;
       emit Transfer(address(0), _owner, airdropAmount);
    }

    
    // Method for batch distribution of airdrop tokens.
    function sendBatchCS(address[] _recipients, uint[] _values) external onlyOwner returns (bool) {
        require(_recipients.length == _values.length);
        uint senderBalance = _balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            senderBalance = senderBalance - value;
            _balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        _balances[msg.sender] = senderBalance;
        return true;
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
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

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }
  

  function sendTokens(address from, address to, uint256 value) internal returns (bool) {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
    return true;
  }


// Function to burn undistributed amount of tokens after ICO is finished
    function burn() external onlyOwner {
      require(now >_endDates[3]);
      _burn(address(this),_balances[address(this)]);
    }

  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);

    emit Transfer(account, 0x0000000000000000000000000000000000000000, amount);
  }


  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);
    require(amount <=_balances[account]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function getRate() public view returns(uint256) {
    return _rate;
  }

  function _setRate(uint newrate) external onlyOwner {
    require (newrate > 0);
    _rate = newrate;
  }

  function soldTokens() public view returns (uint256) {
    return _soldTokens;
  }

  // Method to check current ICO stage

  function currentStage() public view returns (uint256) {
    require(now >=_startDates[0] && now <= _endDates[3]);
    if (now >= _startDates[0] && now <= _endDates[0]) return 0;
    if (now >= _startDates[1] && now <= _endDates[1]) return 1;
    if (now >= _startDates[2] && now <= _endDates[2]) return 2;
    if (now >= _startDates[3] && now <= _endDates[3]) return 3;
  }

// Show current bonus tokens percentage

 function currentBonus() public view returns (uint256) {
    require(now >=_startDates[0] && now <= _endDates[3]);
    return _bonuses[currentStage()];
  }

  function _setLastDate(uint _date) external onlyOwner returns (bool){
    require (_date > now);
    require (_date > _startDates[3]);
    require (_date < 2147483647);
    _endDates[3] = _date;
    return true;
  }

  // Returns date of ICO finish
  function _getLastDate() public view returns (uint256) {
    return uint256(_endDates[3]);
  }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256 tokens, uint256 bonus) {
    tokens = uint256(weiAmount * _rate / (10**9));
    bonus = uint256(tokens * _bonuses[currentStage()]/100);
    return (tokens, bonus);
  }

  function _forwardFunds(uint256 amount) external onlyOwner {
    require (address(this).balance > 0);
    require (amount <= address(this).balance);
    require (amount > 0);
    _owner.transfer(amount);
  }

  function buyTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 bonus;
    uint256 weiAmount = msg.value;

    _preValidatePurchase(beneficiary, weiAmount);

    (tokens, bonus) = _getTokenAmount(weiAmount);
   
    uint256 total = tokens.add(bonus);

    _soldTokens = _soldTokens.add(tokens);
    
    _processPurchase(beneficiary, total);

    emit TokensPurchased(msg.sender, beneficiary,  weiAmount, total);

  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    require (now >= _startDates[0]);
    require (now <= _endDates[3]);
    require(beneficiary != address(0));
    require(weiAmount >= _minPayment);
    require (_balances[address(this)] > 0);
  }


  function _preICOSale(address beneficiary, uint256 tokenAmount) internal {
    require(_soldTokens < 1000000 * (10 ** uint256(decimals)));
    require(_soldTokens.add(tokenAmount) <= 1000000 * (10 ** uint256(decimals)));
    sendTokens(address(this), beneficiary, tokenAmount);
  }

  function _ICOSale(address beneficiary, uint256 tokenAmount) internal {
    require(_soldTokens < 30000000 * (10 ** uint256(decimals)));
    require(_soldTokens.add(tokenAmount) <= 30000000 * (10 ** uint256(decimals)));
    sendTokens(address(this), beneficiary, tokenAmount);
  }


  function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
    require(_balances[address(this)]>=tokenAmount);
    if (currentStage() == 0) {
      _preICOSale(beneficiary, tokenAmount);
    } else {
      _ICOSale(beneficiary, tokenAmount);

    }
  }
}