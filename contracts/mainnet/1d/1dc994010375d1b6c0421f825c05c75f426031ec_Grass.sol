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

    etherPriceInDollarIn = 388 * 100;
    etherPriceInDollarOut = 450 * 100;
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

  function() isEtherPriceUpdated canBuy isInitialized payable public
  {
    buyInternal(msg.sender);
  }

  function buyFor(address addr) isEtherPriceUpdated canBuy onlyAdmin isInitialized payable public
  {
    buyInternal(addr);
  }

  function buy() isEtherPriceUpdated canBuy payable isInitialized public
  {
    buyInternal(msg.sender);
  }

  function getPartnerBalance (address addr) public view returns(uint256)
  {
    return partners[addr];
  }

  function partnerWithdraw () isInitialized public
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

  function buyWithPromo(address partner) isEtherPriceUpdated canBuy isInitialized payable public
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

    assert (isContract(addr) == false);

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

  function returnTokensForDay(uint256 day, uint256 userTokensAmount) isInitialized public
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

  function isContract(address addr) internal returns (bool)
  {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  bool public initialized = false;

  modifier isInitialized()
  {
      assert(initialized);
      _;
  }

  uint8 balancesTransferred = 0;
  // restore tokens from previous contract 
  function restoreBalances(address[60] addr, uint256[60] _days, uint256[60] _amounts) external onlyAdmin
  {
    // call when contract is not initialized
    assert(initialized == false);

    if (totalSupply == 0)
    {
        balances[0x9d4f1d5c6da16f28405cb8b063500606e41b8279] = 151428571428571428571;
        balances[0x35497d9c2beaa5debc48da2208d6b03222f5e753] = 75714285714285714285;
        balances[0xb43f0c8ad004f7fdd50bc9b1c2ca06cad653f56d] = 60571428571428571428;
        balances[0x006f2e159f3e3f2363a64b952122d27df1b307cd] = 49453400000000000000;
        balances[0xb8c180dd09e611ac253ab321650b8b5393d6a00c] = 31972285714285714284;
        balances[0xa209e963d089f03c26fff226a411028700fb6009] = 29281428571428571427;
        balances[0xec185474a0c593f741cca00995aa22f078ec02e2] = 25000000000000000514;
        balances[0x1c1a6b49bccb8b2c12ddf874fc69e14c4371343b] = 14655428571428571428;
        balances[0x38aeeb7e8390632e45f44c01a7b982a9e03a1b10] = 11671422857142857142;
        balances[0xfeff4cd1fc9273848c0cbabacc688c5e5707ddd5] = 9999999999999999428;
        balances[0x1c0c4d7961c96576c21b63b0b892b88ec5b86742] = 8227208857142857142;
        balances[0xdae0aca4b9b38199408ffab32562bf7b3b0495fe] = 5999999999999999957;
        balances[0x2c46fb6e390d90f5742877728d81a5e354c2be0c] = 5990527428571428570;
        balances[0x3c9e6d9a10956f29ec20d797c26ba720e4f0f327] = 5013159428571428571;
        balances[0xb9621f1a9402fa3119fd6b011a23dd007e05b7af] = 5000108571428571427;
        balances[0xae2856a1ea65093852b8828efcaabb16ac987d6b] = 4174942857142857142;
        balances[0xb9507bfc17d6b70177d778ead1cd581c2572b6c1] = 3022857142857142857;
        balances[0x2e983528f19633cf25eee2aa93c78542d660a20f] = 3000000000000000131;
        balances[0xf4b733ff2f2eab631e2860bb60dc596074b9912d] = 3000000000000000131;
        balances[0x431d78c14b570aafb4940c8df524b5a7f5373f46] = 2999999999999999851;
        balances[0xda43b71d5ba11b61f315867ff8fc29db7d34ed31] = 3000000000000000131;
        balances[0x7d9c012ea8e111cec46e89e01b7cd63687696862] = 2771866285714285714;
        balances[0x1c1d8b576c7354dccd20d017b1cde68a942353b6] = 2490045714285714285;
        balances[0x024c07e4e9631763d8db8294bfc8f4fd82113ef5] = 2109977142857142857;
        balances[0x64f482e94e9781c42ada16742780709613ea7fe0] = 2031377142857142857;
        balances[0x0c371ce4b7dcc1da7d68b004d5dea49667af7320] = 1999999999999999885;
        balances[0x709b1599cfe4b06ff4fce1cc4fe8a72ac55c2f10] = 1999999999999999885;
        balances[0xe217aee24b3181540d17f872d3d791b41224bc31] = 1999999999999999885;
        balances[0x0d85570eef6baa41a8f918e48973ea54a9385ee7] = 2000000000000000120;
        balances[0xcf1a033ae5b48def61c8ceb21d41c293a9e5d3c0] = 2000000000000000057;
        balances[0xbc202f5082e403090d7dd483545f680a37efb7e5] = 1999999999999999885;
        balances[0xdf18736dcafaa40b8880b481c5bfab5196089535] = 1999999999999999885;
        balances[0x83da64ffdfe4f6c3a4cf9891d840096ee984b456] = 1271428571428571428;
        balances[0x3babede4f2275762f1c6b4a8185a0056ceee4f5f] = 1051428571428571428;
        balances[0x2f4f98d2489bec1c98515e0f75596e0b135a6023] = 1000480000000000000;
        balances[0xe89156e5694f94b86fabfefab173cf6dd1f2ee00] = 1000000000000000125;
        balances[0x890430d3dbc99846b72c77de7ec10e91ad956619] = 1000000000000000125;
        balances[0x4ee63ad9a151d7c8360561bc00cbe9d7f81c4677] = 1000000000000000125;
        balances[0xc5398714592750850693b56e74c8a5618ae14d38] = 1000000000000000125;
        balances[0xab4a42f7a9ada127858c2e054778e000ea0b8325] = 1000000000000000125;
        balances[0xfcc9b4658b296fe9d667c5a264f4da209dec13db] = 1000000000000000125;
        balances[0x36a93d56e175947be686f0a65bb328d400c1a8b9] = 1000000000000000125;
        balances[0x362a979afe6e5b6acb57d075be9e6f462acacc85] = 1000000000000000125;
        balances[0xe50f079b8f9d67002c787cf9dbd456fc11bd5779] = 999999999999999942;
        balances[0x68afff1424c27246647969dee18e7150124b2b28] = 999999999999999942;
        balances[0x44aba76f01b6498a485dd8f8ee1615d422b8cbf8] = 999999999999999942;
        balances[0x1d51752cd228c3d71714f16401ccdaecfe6d52c3] = 999999999999999942;
        balances[0x5eb72c2bbd74d3e9cb61f5d43002104403a16b43] = 999999999999999942;
        balances[0xa0a0d04bb08051780e5a6cba3080b623fc8404a6] = 999999999999999942;
        balances[0xec49706126ae73db0ca54664d8b0feeb67c3c777] = 999999999999999942;
        balances[0xa95413cd1bc9bdf336e9c2c074fb9ffa91bb89a6] = 999999999999999942;
        balances[0x884a7cc58132ca80897d98bfae87ce72e0eaf461] = 999999999999999942;
        balances[0xb6593630850c56aee328be42038fc6d347b37440] = 999999999999999942;
        balances[0x324ddd8b98b23cb2b6ffaeb84b9bb99ec3de9db6] = 999999999999999942;
        balances[0x1013809376254288325a7b49d60c395da80eeef5] = 1000000000000000028;
        balances[0x3f6753388a491e958b2de57634060e28c7ff2c1e] = 1000000000000000062;
        balances[0xe7800dc7166f11decd415c3a74ec9d0cfa3ceb06] = 431405714285714285;
        totalSupply = 557335064857142857325;
        availableTokens = availableTokens - totalSupply;
        
        uint256 today = getToday();
        for(uint256 j=17614;j <= today;j++)
        {
            tokenPriceHistory[j] = currentTokenPriceInDollar;
        }
    }
    else
    {
        uint8 start = balancesTransferred;
        for(uint8 i=start; i < start+30; i++)
        {
            assert(addr[i] != 0 && _days[i] !=0 && _amounts[i] !=0);
            timeTable[addr[i]][_days[i]] = TokenInfo(_amounts[i], false);
            emit Transfer(0, addr[i], _amounts[i]);
            if (_days[i] < 17620 && bonuses[addr[i]][_days[i]] == 0)
            {
                bonuses[addr[i]][_days[i]] = 1;
            }
        }
        balancesTransferred += 30;

        if (balancesTransferred == 60) initialized = true;
    }
  }
}