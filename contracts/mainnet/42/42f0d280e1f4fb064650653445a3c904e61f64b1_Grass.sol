pragma solidity ^0.4.21;

contract Math 
{
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
}

contract Grass is Math
{
  uint256 public availableTokens;
  uint256 currentTokenPriceInDollar;

  uint256 public lastUpdateEtherPrice;
  uint256 public etherPriceInDollarIn;
  uint256 public etherPriceInDollarOut;

  function getCurrentTokenPrice() public constant returns (uint256)
  {
      uint256 today = getToday();
      return (tokenPriceHistory[today] == 0)?currentTokenPriceInDollar:tokenPriceHistory[today];
  }

  mapping(uint256 => uint256) public tokenPriceHistory;
  struct ExtraTokensInfo
  {
    uint256 timestamp;
    uint256 extraTokens;
    string  proofLink;
    uint256 videoFileHash;
  }

  ExtraTokensInfo[] public extraTokens;

  struct TokenInfo 
  {    
    uint256 amount;
    bool isReturnedInPool;    
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value); 

  // address => day => amount  
  mapping(address => mapping(uint256 => TokenInfo)) timeTable;
  mapping(address => mapping(uint256 => uint256)) bonuses;
  mapping (address => uint256) public balances;  
  uint256 public totalSupply;

  string public name;
  uint8 public decimals;
  string public symbol;
  
  bool isCanBuy = true;

  modifier canBuy()
  {
      assert(isCanBuy);
      _;
  }

  function changeState(bool bNewState) public onlyAdmin
  {
      isCanBuy = bNewState;
  }
  
  address owner;
  mapping(address => bool) admins;
  modifier onlyAdmin()
  {
      assert(admins[msg.sender] == true || msg.sender == owner);
      _;
  }

  modifier onlyOwner()
  {
      assert(msg.sender == owner);
      _;
  }
  function addAdmin(address addr) public onlyOwner
  {
      admins[addr] = true;
  }
  function removeAdmin(address addr) public onlyOwner
  {
      admins[addr] = false;
  }
    
  function Grass() public
  {   
    // startTime = block.timestamp;
    owner = msg.sender;
    admins[msg.sender] = true;
    totalSupply = 0;                        
    name = &#39;GRASS Token&#39;;                   
    decimals = 18;                          
    symbol = &#39;GRASS&#39;;
    availableTokens = 800 * 10**18;
    currentTokenPriceInDollar = 35 * 100; // 35.00$ (price may change) 

    etherPriceInDollarIn = 530 * 100;  // 550.00 $  (price may change)
    etherPriceInDollarOut = 530 * 100; // 550.00 $  (price may change)
    lastUpdateEtherPrice = block.timestamp;
  }

  function increaseMaxAvailableTokens(uint256 amount, string link, uint256 videoFileHash) onlyAdmin public
  {
    extraTokens.push(ExtraTokensInfo(block.timestamp, amount, link, videoFileHash));
    availableTokens = add(availableTokens, amount);
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
  }

  function updateEtherPrice (uint256 newPriceIn, uint256 newPriceOut) onlyAdmin public 
  {   
    etherPriceInDollarIn = newPriceIn;
    etherPriceInDollarOut = newPriceOut;
    lastUpdateEtherPrice = block.timestamp;
  }

  modifier isEtherPriceUpdated() 
  {
      require(now - lastUpdateEtherPrice < 24 hours);
      _;
  }

  function updateTokenPrice (uint256 newPrice) onlyAdmin public 
  {   
    currentTokenPriceInDollar = newPrice;   
  }
  
  function getToday() public constant returns (uint256)
  {
      return block.timestamp / 24 hours;
  }

  function() isEtherPriceUpdated canBuy payable public
  {
      buyInternal(msg.sender);
  }

  function buyFor(address addr) isEtherPriceUpdated canBuy payable public
  {
      buyInternal(addr);
      // 
      if (addr.balance == 0) addr.transfer(1 finney);
  }

  function buy() isEtherPriceUpdated canBuy payable public
  {
    buyInternal(msg.sender);
  }
  
  function getPartnerBalance (address addr) public view returns(uint256)  
  {
    return partners[addr];
  }

  function partnerWithdraw () public 
  {
    assert (partners[msg.sender] > 0);
    uint256 ethToWidthdraw = partners[msg.sender];
    partners[msg.sender] = 0;
    msg.sender.transfer(ethToWidthdraw);
  }  
  
  mapping(address => uint256) partners;
  // refferal => partner
  mapping(address => address) referrals;

  function takeEther(address dest, uint256 amount) onlyAdmin public
  {
      dest.transfer(amount);
  }
  
  function addEther() payable onlyAdmin public
  {
  }

  function buyWithPromo(address partner) isEtherPriceUpdated canBuy payable public
  {
      if (referrals[msg.sender] == 0 && partner != msg.sender)
      {
        referrals[msg.sender] = partner;
      }

      buyInternal(msg.sender);
  }
  
  function buyInternal(address addr) internal
  {
    if (referrals[addr] != 0)
    {
        partners[referrals[addr]] += msg.value / 100; // 1% to partner
    }  
      
    // проверка lastUpdateEtherPrice
    uint256 today = getToday();
    if (tokenPriceHistory[today] == 0) tokenPriceHistory[today] = currentTokenPriceInDollar;

    // timeTable
    uint256 amount = msg.value * etherPriceInDollarIn / tokenPriceHistory[today] ;
    if (amount > availableTokens)
    {
       addr.transfer((amount - availableTokens) * tokenPriceHistory[today] / etherPriceInDollarIn);
       amount = availableTokens;
    }
      
    assert(amount > 0);
      
    availableTokens = sub(availableTokens, amount);

    // is new day ?
    if (timeTable[addr][today].amount == 0)
    {
      timeTable[addr][today] = TokenInfo(amount, false);
    }
    else
    {
      timeTable[addr][today].amount += amount;
    }

    //                  < 30.03.2018
    if (block.timestamp < 1522357200 && bonuses[addr][today] == 0)
    {
      bonuses[addr][today] = 1;
    }

    balances[addr] = add(balances[addr], amount);
    totalSupply = add(totalSupply, amount);
    emit Transfer(0, addr, amount);
  }

  function calculateProfit (uint256 day) public constant returns(int256) 
  {
    uint256 today = getToday();
    assert(today >= day);
    uint256 daysLeft = today - day;
    int256 extraProfit = 0;

    // is referral ?
    if (referrals[msg.sender] != 0) extraProfit++;
    // participant until March 30
    if (bonuses[msg.sender][day] > 0) extraProfit++;

    if (daysLeft <= 7) return -10;
    if (daysLeft <= 14) return -5;
    if (daysLeft <= 21) return 1 + extraProfit;
    if (daysLeft <= 28) return 3 + extraProfit;
    if (daysLeft <= 60) return 5 + extraProfit;
    if (daysLeft <= 90) return 12 + extraProfit;
    return 18 + extraProfit;  
  }
  
  function getTokensPerDay(uint256 _day) public view returns (uint256)
  {
      return timeTable[msg.sender][_day].amount;
  }

  // returns amount, ether  
  function getProfitForDay(uint256 day, uint256 amount) isEtherPriceUpdated public constant returns(uint256, uint256)
  {      
    assert (day <= getToday());
    
    uint256 tokenPrice = tokenPriceHistory[day];
    if (timeTable[msg.sender][day].amount < amount) amount = timeTable[msg.sender][day].amount;    

    assert (amount > 0);
          
    return (amount, amount * tokenPrice * uint256(100 + calculateProfit(day)) / 100 / etherPriceInDollarOut);
  }

  function returnTokensInPool (address[] addr, uint256[] _days) public
  {
    assert (addr.length == _days.length);
    
    TokenInfo storage info; 
    for(uint256 i = 0; i < addr.length;i++)
    {
      assert(_days[i] + 92 < getToday() && info.amount > 0);
      info = timeTable[addr[i]][_days[i]];
      info.isReturnedInPool = true;
      availableTokens = add(availableTokens, info.amount);      
    }
  }

  function getInfo(address addr, uint256 start, uint256 end) public constant returns (uint256[30] _days, uint256[30] _amounts, int256[30] _profits, uint256[30] _etherAmounts)
  {
      if (addr == 0) addr = msg.sender;

      uint256 j = 0;
      for(uint256 iDay = start; iDay < end; iDay++)
      {
        if (timeTable[addr][iDay].amount > 0)
        {
          _days[j] = iDay;
          _profits[j] = calculateProfit(iDay);
          _amounts[j] = timeTable[addr][iDay].amount;
          (_amounts[j], _etherAmounts[j]) = getProfitForDay(iDay, _amounts[j]);
          j++;
          if (j == 30) break;
        }
      }
  }
  
  function returnTokensForDay(uint256 day, uint256 userTokensAmount) public 
  {
    uint256 tokensAmount;
    uint256 etherAmount;
    (tokensAmount, etherAmount) = getProfitForDay(day, userTokensAmount);

    require(day > 0);
    require(balances[msg.sender] >= tokensAmount);
    
    balances[msg.sender] = sub(balances[msg.sender], tokensAmount);
    totalSupply = sub(totalSupply, tokensAmount);
    timeTable[msg.sender][day].amount = sub(timeTable[msg.sender][day].amount, tokensAmount);
    
    if (!timeTable[msg.sender][day].isReturnedInPool)
    {
      availableTokens = add(availableTokens, tokensAmount);      
    }

    msg.sender.transfer(etherAmount);
    emit Transfer(msg.sender, 0, tokensAmount);
  }
  
}