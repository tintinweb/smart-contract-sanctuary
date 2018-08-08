pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AbstractERC20 {

  uint256 public totalSupply;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

contract Owned {

  address public owner;
  address public newOwner;

  event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public ownerOnly {
    require(_newOwner != owner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnerUpdate(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TydoPreIco is Owned {

  using SafeMath for uint256;

  uint256 public constant COINS_PER_ETH = 12000;
  uint256 public constant bonus = 25;
  mapping (address => uint256) public balances;
  mapping (address => uint256) ethBalances;
  uint256 public ethCollected;
  uint256 public tokenSold;
  uint256 constant tokenDecMult = 1 ether;
  uint8 public state = 0; // 0 - not started yet
                          // 1 - running
                          // 2 - closed mannually and not success
                          // 3 - closed and target reached success
                          // 4 - success & funds withdrawed
  AbstractERC20 public token;

  //event Debug(string _msg, address _addr);
  //event Debug(string _msg, uint256 _val);
  event SaleStart();
  event SaleClosedSuccess(uint256 _tokenSold);
  event SaleClosedFail(uint256 _tokenSold);

  constructor(address _coinToken) Owned() public {
    token = AbstractERC20(_coinToken);
  }

  function tokensLeft() public view returns (uint256 allowed) {
    return token.allowance(address(owner), address(this));
  }

  function () payable public {

    if ((state == 3 || state == 4) && msg.value == 0) {
      return withdrawTokens();
    } else if (state == 2 && msg.value == 0) {
      return refund();
    } else {
      return buy();
    }
  }

  function buy() payable public {

    require (canBuy());
    uint amount = msg.value.mul(COINS_PER_ETH).div(1 ether).mul(tokenDecMult);
    amount = addBonus(amount);
    //emit Debug("buy amount", amount);
    require(amount > 0, &#39;amount must be positive&#39;);
    token.transferFrom(address(owner), address(this), amount);
    //emit Debug(&#39;transfered &#39;, amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    ethBalances[msg.sender] += msg.value;
    ethCollected = ethCollected.add(msg.value);
    tokenSold = tokenSold.add(amount);
  }

  function addBonus(uint256 amount) internal pure returns(uint256 _newAmount) {
    
    uint256 mult = bonus.add(100);
    //emit Debug(&#39;mult &#39;, mult);
    amount = amount.mul(mult).div(100);
    return amount;
  }

  function canBuy() public constant returns(bool _canBuy) {
    return state == 1;
  }
  
  function refund() public {

    require(state == 2);

    uint256 tokenAmount = balances[msg.sender];
    require(tokenAmount > 0);
    uint256 weiAmount = ethBalances[msg.sender];

    msg.sender.transfer(weiAmount);
    token.transfer(owner, balances[msg.sender]);
    ethBalances[msg.sender] = 0;
    balances[msg.sender] = 0;
    ethCollected = ethCollected.sub(weiAmount);
  }
 
  function withdraw() ownerOnly public {
    
    require(state == 3);
    owner.transfer(ethCollected);
    ethCollected = 0;
    state = 4;
  }

  function withdrawTokens() public {
    require(state == 3 || state ==4);
    require(balances[msg.sender] > 0);
    token.transfer(msg.sender, balances[msg.sender]);
  }

  function open() ownerOnly public {
    require(state == 0);
    state = 1;
    emit SaleStart();
  }

  function closeSuccess() ownerOnly public {

    require(state == 1);
    state = 3;
    emit SaleClosedSuccess(tokenSold);
  }

  function closeFail() ownerOnly public {

    require(state == 1);
    state = 2;
    emit SaleClosedFail(tokenSold);
  }
}