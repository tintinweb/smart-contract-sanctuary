pragma solidity ^0.4.18;

/*
TTTTTTTTTTTTTTTTTTTTTTT  iiii                                                                                              
T:::::::::::::::::::::T i::::i                                                                                             
T:::::::::::::::::::::T  iiii                                                                                              
T:::::TT:::::::TT:::::T                                                                                                    
TTTTTT  T:::::T  TTTTTTiiiiiii xxxxxxx      xxxxxxxggggggggg   ggggguuuuuu    uuuuuu rrrrr   rrrrrrrrr   uuuuuu    uuuuuu  
        T:::::T        i:::::i  x:::::x    x:::::xg:::::::::ggg::::gu::::u    u::::u r::::rrr:::::::::r  u::::u    u::::u  
        T:::::T         i::::i   x:::::x  x:::::xg:::::::::::::::::gu::::u    u::::u r:::::::::::::::::r u::::u    u::::u  
        T:::::T         i::::i    x:::::xx:::::xg::::::ggggg::::::ggu::::u    u::::u rr::::::rrrrr::::::ru::::u    u::::u  
        T:::::T         i::::i     x::::::::::x g:::::g     g:::::g u::::u    u::::u  r:::::r     r:::::ru::::u    u::::u  
        T:::::T         i::::i      x::::::::x  g:::::g     g:::::g u::::u    u::::u  r:::::r     rrrrrrru::::u    u::::u  
        T:::::T         i::::i      x::::::::x  g:::::g     g:::::g u::::u    u::::u  r:::::r            u::::u    u::::u  
        T:::::T         i::::i     x::::::::::x g::::::g    g:::::g u:::::uuuu:::::u  r:::::r            u:::::uuuu:::::u  
      TT:::::::TT      i::::::i   x:::::xx:::::xg:::::::ggggg:::::g u:::::::::::::::uur:::::r            u:::::::::::::::uu
      T:::::::::T      i::::::i  x:::::x  x:::::xg::::::::::::::::g  u:::::::::::::::ur:::::r             u:::::::::::::::u
      T:::::::::T      i::::::i x:::::x    x:::::xgg::::::::::::::g   uu::::::::uu:::ur:::::r              uu::::::::uu:::u
      TTTTTTTTTTT      iiiiiiiixxxxxxx      xxxxxxx gggggggg::::::g     uuuuuuuu  uuuurrrrrrr                uuuuuuuu  uuuu
                                                            g:::::g                                                        
                                                gggggg      g:::::g                                                        
                                                g:::::gg   gg:::::g                                                        
                                                 g::::::ggg:::::::g                                                        
                                                  gg:::::::::::::g                                                         
                                                    ggg::::::ggg                                                           
                                                       gggggg                                                              
*/

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
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  function getOwner() public view returns (address) {
    return owner;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract TIX is StandardToken, Ownable {

  using SafeMath for uint256;

  string public constant name = "Tixguru Token";
  string public constant symbol = "TIX";
  uint256 public constant decimals = 3;
  uint256 internal constant wei_to_token = 10 ** 15;

  uint256 public rate = 10000;
  uint256 public minimum = 1 * 10 ** 11;
  uint256 public wei_raised = 0;
  uint256 public token_issued = 0;
  uint256 public start_time = 0;
  uint256 public end_time = 0;
  uint256 public period = 0;
  uint256[] public discount_period;
  uint256[] public discount;
  bool public tradeable = false;
  bool public issuable = false;

  address internal vault;


  event LogTokenBought(address indexed sender, address indexed buyer, uint256 value, uint256 tokens, uint256 timestamp);
  event LogVaultChanged(address indexed new_vault, uint256 timestamp);
  event LogStarted(uint256 timestamp);
  event LogTradingEnabled(uint256 timestamp);
  event LogTradingDisabled(uint256 timestamp);
  event LogTokenBurned(address indexed burner, uint256 indexed tokens, uint256 timestamp);
  event LogPreSaled(address indexed buyer, uint256 tokens, uint256 timestamp);
  event LogDiscountSet(uint256[] indexed period, uint256[] indexed discount, uint256 timestamp);


  modifier validAddress(address addr) {
    require(addr != address(0));
    _;
  }

  function disableTrading() external onlyOwner returns (bool) {
    tradeable = false;
    LogTradingDisabled(now);
    return true;
  }


  function TIX(uint256 cap, address _vault, uint256[] _period, uint256[] _discount)
  public
  validAddress(_vault)
  validArray(_period)
  validArray(_discount) {

    uint256 decimal_unit = 10 ** 3;
    totalSupply_ = cap.mul(decimal_unit);
    vault = _vault;
    discount_period = _period;
    discount = _discount;

    balances[0x8b26E715fF12B0Bf37D504f7Bf0ee918Cd83C67B] = totalSupply_.mul(3).div(10);
    balances[owner] = totalSupply_.mul(7).div(10);

    for (uint256 i = 0; i < discount_period.length; i++) {
      period = period.add(discount_period[i]);
    }
  }

  function deposit() internal {
    vault.transfer(msg.value);
  }

  modifier validArray(uint[] array) {
    require(array.length > 0);
    _;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address buyer) public validAddress(buyer) payable {
    require(issuable);

    uint256 tokens = getTokenAmount(msg.value);

    require(canIssue(tokens));

    wei_raised = wei_raised.add(msg.value);
    token_issued = token_issued.add(tokens);
    balances[owner] = balances[owner].sub(tokens);
    balances[buyer] = balances[buyer].add(tokens);

    LogTokenBought(msg.sender, buyer, msg.value, tokens, now);

    deposit();
  }

  function setDiscount(uint256[] _period, uint256[] _discount)
  external
  onlyVault
  validArray(_period)
  validArray(_discount)
  returns (bool) {

    discount_period = _period;
    discount = _discount;

    period = 0;
    for (uint256 i = 0; i < discount_period.length; i++) {
      period = period.add(discount_period[i]);
    }

    if (start_time != 0) {
      uint256 time_point = now;
      start_time = time_point;
      end_time = time_point + period;

      uint256 tmp_time = time_point;
      for (i = 0; i < discount_period.length; i++) {
        tmp_time = tmp_time.add(discount_period[i]);
        discount_period[i] = tmp_time;
      }
    }

    LogDiscountSet( _period, _discount, time_point);
    return true;
  }

  function getTokenAmount(uint256 _value) public view returns (uint256) {
    require(_value >= minimum);

    uint256 buy_time = now;
    uint256 numerator = 0;

    for (uint256 i = 0; i < discount_period.length; i++) {
      if (buy_time <= discount_period[i]) {
        numerator = discount[i];
        break;
      }
    }

    if (numerator == 0) {
      numerator = 100;
    }

    return _value.mul(rate).mul(numerator).div(100).div(wei_to_token);
  }

  function enableTrading() external onlyOwner returns (bool) {
    tradeable = true;
    LogTradingEnabled(now);
    return true;
  }

  function transferOwnership(address newOwner) public onlyOwner {

    balances[newOwner] = balances[owner];
    delete balances[owner];
    super.transferOwnership(newOwner);
  }

  function start() external onlyOwner returns (bool) {
    require(start_time == 0);

    uint256 time_point = now;

    start_time = time_point;
    end_time = time_point + period;

    for (uint256 i = 0; i < discount_period.length; i++) {
      time_point = time_point.add(discount_period[i]);
      discount_period[i] = time_point;
    }

    issuable = true;

    LogStarted(start_time);

    return true;
  }


  function changeVault(address _vault) external onlyVault returns (bool) {
    vault = _vault;
    LogVaultChanged(_vault, now);
    return true;
  }

  function burnTokens(uint256 tokens) external onlyVault returns (bool) {
    balances[owner] = balances[owner].sub(tokens);
    totalSupply_ = totalSupply_.sub(tokens);
    LogTokenBurned(owner, tokens, now);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 tokens) public returns (bool) {
    require(tradeable == true);
    return super.transferFrom(_from, _to, tokens);
  }


  function transfer(address _to, uint256 tokens) public returns (bool) {
    require(tradeable == true);
    return super.transfer(_to, tokens);
  }


  function canIssue(uint256 tokens) internal returns (bool){
    if (start_time == 0 || end_time <= now) {
      issuable = false;
      return false;
    }
    if (token_issued.add(tokens) > balances[owner]) {
      issuable = false;
      return false;
    }

    return true;
  }
  modifier onlyVault() {
    require(msg.sender == vault);
    _;
  }
}