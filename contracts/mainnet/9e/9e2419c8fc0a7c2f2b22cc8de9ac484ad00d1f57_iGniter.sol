pragma solidity ^0.4.21;

contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }

    function safeDiv(uint256 x, uint256 y) constant internal returns (uint256 z) {
        uint256 f = x / y;
        return f;
      }
    }

contract ERC223ReceivingContract {

    struct inr {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

      function tokenFallback(address _from, uint _value, bytes _data){
      inr memory igniter;
      igniter.sender = _from;
      igniter.value = _value;
      igniter.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      igniter.sig = bytes4(u);

    }
  }

contract iGniter is SafeMath {

  struct serPayment {
    uint256 unlockedBlockNumber;
    uint256 unlockedTime;
  }

  struct dividends {
    uint256 diviReg;
    uint256 diviBlocks;
    uint256 diviPayout;
    uint256 diviBalance;
    uint256 _tier1Reg;
    uint256 _tier2Reg;
    uint256 _tier3Reg;
    uint256 _tier4Reg;
    uint256 _tier5Reg;
    uint256 _tier1Payout;
    uint256 _tier2Payout;
    uint256 _tier3Payout;
    uint256 _tier4Payout;
    uint256 _tier5Payout;
    uint256 _tier1Blocks;
    uint256 _tier2Blocks;
    uint256 _tier3Blocks;
    uint256 _tier4Blocks;
    uint256 _tier5Blocks;
    uint256 _tierPayouts;
    uint256 hodlPayout;
    uint256 _hodlReg;
    uint256 _hodlBlocks;
    uint256 INRpayout;
    uint256 INR_lastbal;
    uint256 INRpaid;
    uint256 INRtransfers;
    uint256 INRbalance;
    uint256 transDiff;
    uint256 individualRewards;
  }

    string public name;
    bytes32 public symbol;
    uint8 public decimals;
    uint256 private dividendsPerBlockPerAddress;
    uint256 private T1DividendsPerBlockPerAddress;
    uint256 private T2DividendsPerBlockPerAddress;
    uint256 private T3DividendsPerBlockPerAddress;
    uint256 private T4DividendsPerBlockPerAddress;
    uint256 private T5DividendsPerBlockPerAddress;
    uint256 private hodlersDividendsPerBlockPerAddress;
    uint256 private totalInitialAddresses;
    uint256 private initialBlockCount;
    uint256 private minedBlocks;
    uint256 private iGniting;
    uint256 private totalRewards;
    uint256 private initialSupplyPerAddress;
    uint256 private availableAmount;
    uint256 private burnt;
    uint256 private inrSessions;
    uint256 private initialSupply;
    uint256 public currentCost;
    uint256 private blockStats;
    uint256 private blockAverage;
    uint256 private blockAvgDiff;
    uint256 private divRewards;
    uint256 private diviClaims;
    uint256 private Tier1Amt;
    uint256 private Tier2Amt;
    uint256 private Tier3Amt;
    uint256 private Tier4Amt;
    uint256 private Tier5Amt;
    uint256 private Tier1blocks;
    uint256 private Tier2blocks;
    uint256 private Tier3blocks;
    uint256 private Tier4blocks;
    uint256 private Tier5blocks;
    uint256 private hodlBlocks;
    uint256 private hodlersReward;
    uint256 private hodlAmt;

    uint256 private _tier1Avg;
    uint256 private _tier1AvgDiff;
    uint256 private _tier1Rewards;
    uint256 private _tier2Avg;
    uint256 private _tier2AvgDiff;
    uint256 private _tier2Rewards;
    uint256 private _tier3Avg;
    uint256 private _tier3AvgDiff;
    uint256 private _tier3Rewards;
    uint256 private _tier4Avg;
    uint256 private _tier4AvgDiff;
    uint256 private _tier4Rewards;
    uint256 private _tier5Avg;
    uint256 private _tier5AvgDiff;
    uint256 private _tier5Rewards;
    uint256 private _hodlAvg;

    uint256 private _hodlAvgDiff;
    uint256 private _hodlRewards;

    bool private t1active;
    bool private t2active;
    bool private t3active;
    bool private t4active;
    bool private t5active;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public initialAddress;
    mapping(address => bool) public dividendAddress;
    mapping(address => bool) public qualifiedAddress;
    mapping(address => bool) public TierStarterDividendAddress;
    mapping(address => bool) public TierBasicDividendAddress;
    mapping(address => bool) public TierClassicDividendAddress;
    mapping(address => bool) public TierWildcatDividendAddress;
    mapping(address => bool) public TierRainmakerDividendAddress;
    mapping(address => bool) public HODLERAddress;
    mapping(address => mapping (address => uint)) internal _allowances;
    mapping(address => serPayment) inrPayments;
    mapping(address => dividends) INRdividends;

    address private _Owner1;
    address private _Owner2;
    address private _Owner3;

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    modifier isOwner() {

      require(msg.sender == _Owner1 || msg.sender == _Owner2 || msg.sender == _Owner3);
      _;
    }

    function iGniter() {

        initialSupplyPerAddress = 10000000000; //10000 INR
        initialBlockCount = 5150000;
        dividendsPerBlockPerAddress = 7;
        hodlersDividendsPerBlockPerAddress = 9000;
        T1DividendsPerBlockPerAddress = 30;
        T2DividendsPerBlockPerAddress = 360;
        T3DividendsPerBlockPerAddress = 4200;
        T4DividendsPerBlockPerAddress = 60000;
        T5DividendsPerBlockPerAddress = 1200000;
        totalInitialAddresses = 5000;
        initialSupply = initialSupplyPerAddress * totalInitialAddresses;
        minedBlocks = block.number - initialBlockCount;
        availableAmount = dividendsPerBlockPerAddress * minedBlocks;
        iGniting = availableAmount * totalInitialAddresses;
        _Owner1 = 0x4804D96B17B03B2f5F65a4AaA4b5DB360e22909A;
        _Owner2 = 0x16C890b06FE52e27ed514e7086378a355F1aB28a;
        _Owner3 = 0xa4F78852c7F854b4585491a55FE1594913C2C05D;
    }

    function currentBlock() constant returns (uint256 blockNumber)
    {
        return block.number;
    }

    function blockDiff() constant returns (uint256 blockNumber)
    {
        return block.number - initialBlockCount;
    }

    function assignInitialAddresses(address[] _address) isOwner public returns (bool success)
    {
        if (block.number < 10000000)
        {
          for (uint i = 0; i < _address.length; i++)
          {
            balanceOf[_address[i]] = balanceOf[_address[i]] + initialSupplyPerAddress;
            initialAddress[_address[i]] = true;
          }

          return true;
        }
        return false;
    }

    function balanceOf(address _address) constant returns (uint256 Balance)
    {
        if((qualifiedAddress[_address]) == true || (initialAddress[_address]) == true)
        {
            if (minedBlocks > 105120000) return balanceOf[_address]; //app. 2058

            INRdividends[_address].INRpayout = dividendRewards(_address);

            if (INRdividends[_address].INRpayout < INRdividends[_address].INRtransfers)
            {
                INRdividends[_address].INRpaid = 0;
            }

            if (INRdividends[_address].INRpayout >= INRdividends[_address].INRtransfers)
            {
                INRdividends[_address].transDiff = INRdividends[_address].INRpayout - INRdividends[_address].INRtransfers;
                INRdividends[_address].INRpaid = INRdividends[_address].transDiff;
            }

            INRdividends[_address].INRbalance = balanceOf[_address] + INRdividends[_address].INRpaid;

            return INRdividends[_address].INRbalance;
        }

        else {
            return balanceOf[_address] + INRdividends[_address].INRpaid;
        }
    }

    function name() constant returns (string _name)
    {
        name = "iGniter";
        return name;
    }

    function symbol() constant returns (bytes32 _symbol)
    {
        symbol = "INR";
        return symbol;
    }

    function decimals() constant returns (uint8 _decimals)
    {
        decimals = 6;
        return decimals;
    }

    function totalSupply() constant returns (uint256 totalSupply)
    {
        if(t1active == true)
        {
          _tier1Avg = Tier1blocks/Tier1Amt;
          _tier1AvgDiff = block.number - _tier1Avg;
          _tier1Rewards = _tier1AvgDiff * T1DividendsPerBlockPerAddress * Tier1Amt;
        }

        if(t2active == true)
        {
          _tier2Avg = Tier2blocks/Tier2Amt;
          _tier2AvgDiff = block.number - _tier2Avg;
          _tier2Rewards = _tier2AvgDiff * T2DividendsPerBlockPerAddress * Tier2Amt;
        }

        if(t3active == true)
        {
          _tier3Avg = Tier3blocks/Tier3Amt;
          _tier3AvgDiff = block.number - _tier3Avg;
          _tier3Rewards = _tier3AvgDiff * T3DividendsPerBlockPerAddress * Tier3Amt;
        }

        if(t4active == true)
        {
          _tier4Avg = Tier4blocks/Tier4Amt;
          _tier4AvgDiff = block.number - _tier4Avg;
          _tier4Rewards = _tier4AvgDiff * T4DividendsPerBlockPerAddress * Tier4Amt;
        }

        if(t5active == true)
        {
          _tier5Avg = Tier5blocks/Tier5Amt;
          _tier5AvgDiff = block.number - _tier5Avg;
          _tier5Rewards = _tier5AvgDiff * T5DividendsPerBlockPerAddress * Tier5Amt;
        }

        _hodlAvg = hodlBlocks/hodlAmt;
        _hodlAvgDiff = block.number - _hodlAvg;
        _hodlRewards = _hodlAvgDiff * hodlersDividendsPerBlockPerAddress * hodlAmt;

        blockAverage = blockStats/diviClaims;
        blockAvgDiff = block.number - blockAverage;
        divRewards = blockAvgDiff * dividendsPerBlockPerAddress * diviClaims;

        totalRewards = _tier1Rewards + _tier2Rewards + _tier3Rewards + _tier4Rewards + _tier5Rewards
                       + _hodlRewards + divRewards;

        return initialSupply + iGniting + totalRewards - burnt;
    }

    function burn(uint256 _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        burnt += _value;
        Burn(msg.sender, _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        if (_value > 0 && _value <= balanceOf[msg.sender] && !isContract(_to)) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            INRdividends[msg.sender].INRtransfers += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        if (_value > 0 && _value <= balanceOf[msg.sender] && isContract(_to)) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            INRdividends[msg.sender].INRtransfers += _value;
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
                _contract.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }

    function isContract(address _addr) returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (_allowances[_from][msg.sender] > 0 && _value > 0 && _allowances[_from][msg.sender] >= _value &&
            balanceOf[_from] >= _value) {
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            INRdividends[msg.sender].INRtransfers += _value;
            _allowances[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return _allowances[_owner][_spender];
    }

    function PaymentStatusBlockNum(address _address) constant returns (uint256 blockno) {

      return inrPayments[_address].unlockedBlockNumber;
    }

    function PaymentStatusTimeStamp(address _address) constant returns (uint256 ut) {

      return inrPayments[_address].unlockedTime;
    }

    function updateCost(uint256 _currCost) isOwner public {

      currentCost = _currCost;
    }

    function servicePayment(uint _value) public {

      require(_value >= currentCost);
      require(balanceOf[msg.sender] >= currentCost);

      inrPayments[msg.sender].unlockedBlockNumber = block.number;
      inrSessions++;

      balanceOf[msg.sender] -= _value;
      burnt += _value;
      Burn(msg.sender, _value);
    }

    function withdrawal(uint quantity) isOwner returns(bool) {

           require(quantity <= this.balance);

           if(msg.sender == _Owner1)
           {
             _Owner1.transfer(quantity);
           }

           if(msg.sender == _Owner2)
           {
             _Owner2.transfer(quantity);
           }

           if(msg.sender == _Owner3)
           {
             _Owner3.transfer(quantity);
           }

           return true;
   }

    function dividendRegistration() public {

      require (dividendAddress[msg.sender] == false);

      INRdividends[msg.sender].diviReg = block.number;
      dividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      blockStats += block.number;
      diviClaims++;
    }

    function HODLRegistration() public {

      require (HODLERAddress[msg.sender] == false);

          INRdividends[msg.sender]._hodlReg = block.number;
          HODLERAddress[msg.sender] = true;
          qualifiedAddress[msg.sender] = true;
          hodlBlocks += block.number;
          hodlAmt++;
    }

    function Tier_Starter_Registration() public payable {

      require(msg.value == 0.01 ether);

      INRdividends[msg.sender]._tier1Reg = block.number;
      TierStarterDividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      Tier1blocks += block.number;
      Tier1Amt++;
      t1active = true;
    }

    function Tier_Basic_Registration() public payable {

      require(msg.value >= 0.1 ether);

      INRdividends[msg.sender]._tier2Reg = block.number;
      TierBasicDividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      Tier2blocks += block.number;
      Tier2Amt++;
      t2active = true;
    }

    function Tier_Classic_Registration() public payable {

      require(msg.value >= 1 ether);

      INRdividends[msg.sender]._tier3Reg = block.number;
      TierClassicDividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      Tier3blocks += block.number;
      Tier3Amt++;
      t3active = true;
    }

    function Tier_Wildcat_Registration() public payable {

      require(msg.value >= 10 ether);

      INRdividends[msg.sender]._tier4Reg = block.number;
      TierWildcatDividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      Tier4blocks += block.number;
      Tier4Amt++;
      t4active = true;
    }

    function Tier_Rainmaker_Registration() public payable {

      require(msg.value >= 100 ether);

      INRdividends[msg.sender]._tier5Reg = block.number;
      TierRainmakerDividendAddress[msg.sender] = true;
      qualifiedAddress[msg.sender] = true;
      Tier5blocks += block.number;
      Tier5Amt++;
      t5active = true;
    }

    function claimINRDividends() public
    {
        INRdividends[msg.sender].INRpayout = dividendRewards(msg.sender);

        if (INRdividends[msg.sender].INRpayout < INRdividends[msg.sender].INRtransfers)
        {
            INRdividends[msg.sender].INRpaid = 0;
        }

        if (INRdividends[msg.sender].INRpayout >= INRdividends[msg.sender].INRtransfers)
        {
            INRdividends[msg.sender].transDiff = INRdividends[msg.sender].INRpayout - INRdividends[msg.sender].INRtransfers;
            INRdividends[msg.sender].INRpaid = INRdividends[msg.sender].transDiff;
        }

        balanceOf[msg.sender] += INRdividends[msg.sender].INRpaid;
    }

    function dividendRewards(address _address) constant returns (uint)
    {
        if(dividendAddress[_address] == true)
        {
          INRdividends[_address].diviBlocks = block.number - INRdividends[_address].diviReg;
          INRdividends[_address].diviPayout = dividendsPerBlockPerAddress * INRdividends[_address].diviBlocks;
        }

        if(TierStarterDividendAddress[_address] == true)
        {
          INRdividends[_address]._tier1Blocks = block.number - INRdividends[_address]._tier1Reg;
          INRdividends[_address]._tier1Payout = T1DividendsPerBlockPerAddress * INRdividends[_address]._tier1Blocks;
        }

        if(TierBasicDividendAddress[_address] == true)
        {
          INRdividends[_address]._tier2Blocks = block.number - INRdividends[_address]._tier2Reg;
          INRdividends[_address]._tier2Payout = T2DividendsPerBlockPerAddress * INRdividends[_address]._tier2Blocks;
        }

        if(TierClassicDividendAddress[_address] == true)
        {
          INRdividends[_address]._tier3Blocks = block.number - INRdividends[_address]._tier3Reg;
          INRdividends[_address]._tier3Payout = T3DividendsPerBlockPerAddress * INRdividends[_address]._tier3Blocks;
        }

        if(TierWildcatDividendAddress[_address] == true)
        {
          INRdividends[_address]._tier4Blocks = block.number - INRdividends[_address]._tier4Reg;
          INRdividends[_address]._tier4Payout = T4DividendsPerBlockPerAddress * INRdividends[_address]._tier4Blocks;
        }

        if(TierRainmakerDividendAddress[_address] == true)
        {
          INRdividends[_address]._tier5Blocks = block.number - INRdividends[_address]._tier5Reg;
          INRdividends[_address]._tier5Payout = T5DividendsPerBlockPerAddress * INRdividends[_address]._tier5Blocks;
        }

        if ((balanceOf[_address]) >= 100000000000 && (HODLERAddress[_address] == true)) { //100000INR
          INRdividends[_address]._hodlBlocks = block.number - INRdividends[_address]._hodlReg;
          INRdividends[_address].hodlPayout = hodlersDividendsPerBlockPerAddress * INRdividends[_address]._hodlBlocks;
        }

        INRdividends[_address]._tierPayouts = INRdividends[_address]._tier1Payout + INRdividends[_address]._tier2Payout +
                                              INRdividends[_address]._tier3Payout + INRdividends[_address]._tier4Payout +
                                              INRdividends[_address]._tier5Payout + INRdividends[_address].hodlPayout +
                                              INRdividends[_address].diviPayout;

        if ((initialAddress[_address]) == true)
        {
            INRdividends[_address].individualRewards = availableAmount + INRdividends[_address]._tierPayouts;

            return INRdividends[_address].individualRewards;
        }

        if ((qualifiedAddress[_address]) == true)
        {
            INRdividends[_address].individualRewards = INRdividends[_address]._tierPayouts;

            return INRdividends[_address].individualRewards;
        }
    }
}