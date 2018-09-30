pragma solidity ^0.4.23;

/**
*
* complied with .4.25+commit.59dbf8f1.Emscripten.clang
* 2018-09-07
* With Optimization disabled
*
* Contacts: support (at) bankofeth.app
*           https://twitter.com/bankofeth
*           https://discord.gg/d5c7pfn
*           http://t.me/bankofeth
*           http://reddit.com/r/bankofeth
*
* PLAY NOW: https:://bankofeth.app
*  
* --- BANK OF ETH --------------------------------------------------------------
*
* Provably fair Banking Game -> Invest your $ETH and gain daily returns on all 
* profits made!
*
* -- No false promises like many other (Unmentioned!!) dApps...
* -- Real, sustainable returns because we know business, we know banking, we 
*    know gaming!
* -- Returns based on INPUTS into the contract - not false promises or false 
*    gaurantees
* -- Gain a return when people play the game, not a false gauranteed endless 
*    profit with an exitscam at the end!
* -- Contract verified and open from day 1 so you know we can&#39;t "exitscam" you!
* -- Set to become the BIGGEST home of $ETH gaming where you can take OWNERSHIP 
*    and PROFIT
*
* --- GAMEPLAY -----------------------------------------------------------------
*
*   Every day 5% of ALL profits are put into the "Investor Pot":
*
*          profitDays[currentProfitDay].dailyProfit
*
*   This pot is then split up amongst EVERY investor in the game, proportional to the amount 
*   they have invested.  
*
*   EXAMPLE:
*
*   Daily Investments: 20 $ETH
*   Current Players  : 50 - All even investors with 1 $ETH in the pot
*
*   So the dailyProfit for the day would be 5% of 20 $ETH = 1 $ETH 
*   Split evenly in this case amongst the 50 players = 
*   1000000000000000000 wei / 50 = 0.02 $ETH profit for that day each!
*
*   EXAMPLE 2:
*
*   A more realistic example is a bigger profit per day and different 
*   distribtion of the pot, e.g.
*
*   Daily Investments: 100 $ETH
*   Current Players  : 200 - But our example player has 10% of the total amount 
*   invested
*
*   dailyProfit for this day is 5% of the 100 $ETH = 5 $ETH 
*   (5000000000000000000 wei)
* 
*   And our example player would receive 10% of that = 0.5 $ETH for the day
*   Not a bad return for having your $ETH just sitting there!
*
*   Remember you get a return EVERY DAY that people play any of our games 
*   or invest!
*
* -- INVESTMENT RULES --
*
*   The investment rules are simple:
*
*   When you invest into the game there is a minimum investment of 0.01 $ETH
*
*   Of that it is split as follows:
*
*      80% Goes directly into your personal investment fund
*      5%  Goes into the daily profit fund for that day
*      15% Goes into the marketing, development and admin fund
*
*   Simple as that!
*
*   By sitcking to these simple rules the games becomes self-sufficient!
*
*   The fees enable regular daily payments to all players.
*
*   When you choose to withdraw your investment the same fees apply (80/5/15) 
*   - this is again to ensure that the game is self-sufficient and sustainable!
* 
* 
* --- REFERRALS ----------------------------------------------------------------
*                                                                                        
*   Referrals allow you to earn a bonus 3% on every person you refer to 
*   BankOfEth!
*
* - All future games launched will feed into the Profit Share Mechanism 
*   (See receiveProfits() method)
*
* - PLAY NOW: https://BankOfEth.app
*
*
* --- COPYRIGHT ----------------------------------------------------------------
* 
*   This source code is provided for verification and audit purposes only and 
*   no license of re-use is granted.
*   
*   (C) Copyright 2018 BankOfEth.app
*   
*   
*   Sub-license, white-label, solidity or Ethereum development enquiries please 
*   contact support (at) bankofeth.app
*   
*   
* PLAY NOW: https:://bankofeth.app
* 
*/



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

contract BankOfEth {
    
    using SafeMath for uint256;
    using Percent for Percent.percent;
    using Zero for *;
    using ToAddress for *;

    // Events    
    event LogPayDividendsOutOfFunds(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    event LogPayDividendsSuccess(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    event LogInvestmentWithdrawn(address sender, uint256 total_value, uint256 timestamp);
    event LogReceiveExternalProfits(address sender, uint256 total_value, uint256 timestamp);
    event LogInsertInvestor(address sender, uint256 keyIndex, uint256 init_value, uint256 timestamp);
    event LogInvestment(address sender, uint256 total_value, uint256 value_after, uint16 profitDay, address referer, uint256 timestamp);
    event LogPayDividendsReInvested(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    
    
    address owner;
    address devAddress;
    
    // settings
    Percent.percent private m_devPercent = Percent.percent(15, 100); // 15/100*100% = 15%
    Percent.percent private m_investorFundPercent = Percent.percent(5, 100); // 5/100*100% = 5%
    Percent.percent private m_refPercent = Percent.percent(3, 100); // 3/100*100% = 3%
    Percent.percent private m_devPercent_out = Percent.percent(15, 100); // 15/100*100% = 15%
    Percent.percent private m_investorFundPercent_out = Percent.percent(5, 100); // 5/100*100% = 5%
    
    uint256 public minInvestment = 10 finney; // 0.1 eth
    uint256 public maxInvestment = 2000 ether; 
    uint256 public gameDuration = (24 hours);
    bool public gamePaused = false;
    
    // Investor details
    struct investor {
        uint256 keyIndex;
        uint256 value;
        uint256 refBonus;
        uint16 startDay;
        uint16 lastDividendDay;
        uint16 investmentsMade;
    }
    struct iteratorMap {
        mapping(address => investor) data;
        address[] keys;
    }
    iteratorMap private investorMapping;
    
    mapping(address => bool) private m_referrals; // we only pay out on the first set of referrals
    
    // profit days
    struct profitDay {
        uint256 dailyProfit;
        uint256 dailyInvestments; // number of investments
        uint256 dayStartTs;
        uint16 day;
    }
    
    // Game vars
    profitDay[] public profitDays;
    uint16 public currentProfitDay;

    uint256 public dailyInvestments;
    uint256 public totalInvestments;
    uint256 public totalInvestmentFund;
    uint256 public totalProfits;
    uint256 public latestKeyIndex;
    
    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notOnPause() {
        require(gamePaused == false, "Game Paused");
        _;
    }
    
    modifier checkDayRollover() {
        
        if(now.sub(profitDays[currentProfitDay].dayStartTs).div(gameDuration) > 0) {
            currentProfitDay++;
            dailyInvestments = 0;
            profitDays.push(profitDay(0,0,now,currentProfitDay));
        }
        _;
    }

    
    constructor() public {

        owner = msg.sender;
        devAddress = msg.sender;
        investorMapping.keys.length++;
        profitDays.push(profitDay(0,0,now,0));
        currentProfitDay = 0;
        dailyInvestments = 0;
        totalInvestments = 0;
        totalInvestmentFund = 0;
        totalProfits = 0;
        latestKeyIndex = 1;
    }
    
    function() public payable {

        if (msg.value == 0)
            withdrawDividends();
        else 
        {
            address a = msg.data.toAddr();
            address refs;
            if (a.notZero()) {
                refs = a;
                invest(refs); 
            } else {
                invest(refs);
            }
        }
    }
    
    function reinvestDividends() public {
        require(investor_contains(msg.sender));

        uint total_value;
        uint total_refBonus;
        
        (total_value, total_refBonus) = getDividends(false, msg.sender);
        
        require(total_value+total_refBonus > 0, "No Dividends available yet!");
        
        investorMapping.data[msg.sender].value = investorMapping.data[msg.sender].value.add(total_value + total_refBonus);
        
        
        
        investorMapping.data[msg.sender].lastDividendDay = currentProfitDay;
        investor_clearRefBonus(msg.sender);
        emit LogPayDividendsReInvested(msg.sender, total_value, total_refBonus, now);
        
    }
    
    
    function withdrawDividends() public {
        require(investor_contains(msg.sender));

        uint total_value;
        uint total_refBonus;
        
        (total_value, total_refBonus) = getDividends(false, msg.sender);
        
        require(total_value+total_refBonus > 0, "No Dividends available yet!");
        
        uint16 _origLastDividendDay = investorMapping.data[msg.sender].lastDividendDay;
        
        investorMapping.data[msg.sender].lastDividendDay = currentProfitDay;
        investor_clearRefBonus(msg.sender);
        
        if(total_refBonus > 0) {
            investorMapping.data[msg.sender].refBonus = 0;
            if (msg.sender.send(total_value+total_refBonus)) {
                emit LogPayDividendsSuccess(msg.sender, total_value, total_refBonus, now);
            } else {
                investorMapping.data[msg.sender].lastDividendDay = _origLastDividendDay;
                investor_addRefBonus(msg.sender, total_refBonus);
            }
        } else {
            if (msg.sender.send(total_value)) {
                emit LogPayDividendsSuccess(msg.sender, total_value, 0, now);
            } else {
                investorMapping.data[msg.sender].lastDividendDay = _origLastDividendDay;
                investor_addRefBonus(msg.sender, total_refBonus);
            }
        }
    }
    
    function showLiveDividends() public view returns(uint256 total_value, uint256 total_refBonus) {
        require(investor_contains(msg.sender));
        return getDividends(true, msg.sender);
    }
    
    function showDividendsAvailable() public view returns(uint256 total_value, uint256 total_refBonus) {
        require(investor_contains(msg.sender));
        return getDividends(false, msg.sender);
    }


    function invest(address _referer) public payable notOnPause checkDayRollover {
        require(msg.value >= minInvestment);
        require(msg.value <= maxInvestment);
        
        uint256 devAmount = m_devPercent.mul(msg.value);
        
        
        // calc referalBonus....
        // We pay any referal bonuses out of our devAmount = marketing spend
        // Could result in us not having much dev fund for heavy referrals

        // only pay referrals for the first investment of each player
        if(!m_referrals[msg.sender]) {
            if(notZeroAndNotSender(_referer) && investor_contains(_referer)) {
                // this user was directly refered by _referer
                // pay _referer commission...
                uint256 _reward = m_refPercent.mul(msg.value);
                devAmount.sub(_reward);
                assert(investor_addRefBonus(_referer, _reward));
                m_referrals[msg.sender] = true;

                
            }
        }
        
        // end referalBonus
        
        devAddress.transfer(devAmount);
        uint256 _profit = m_investorFundPercent.mul(msg.value);
        profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(_profit);
        
        totalProfits = totalProfits.add(_profit);

        uint256 _investorVal = msg.value;
        _investorVal = _investorVal.sub(m_devPercent.mul(msg.value));
        _investorVal = _investorVal.sub(m_investorFundPercent.mul(msg.value));
        
        if(investor_contains(msg.sender)) {
            investorMapping.data[msg.sender].value += _investorVal;
            investorMapping.data[msg.sender].investmentsMade ++;
        } else {
            assert(investor_insert(msg.sender, _investorVal));
        }
        totalInvestmentFund = totalInvestmentFund.add(_investorVal);
        profitDays[currentProfitDay].dailyInvestments = profitDays[currentProfitDay].dailyInvestments.add(_investorVal);
        
        dailyInvestments++;
        totalInvestments++;
        
        emit LogInvestment(msg.sender, msg.value, _investorVal, currentProfitDay, _referer, now);
        
    }
    
    // tested - needs confirming send completed
    function withdrawInvestment() public {
        require(investor_contains(msg.sender));
        require(investorMapping.data[msg.sender].value > 0);
        
        uint256 _origValue = investorMapping.data[msg.sender].value;
        investorMapping.data[msg.sender].value = 0;
        
        // There is a tax on the way out too...
        uint256 _amountToSend = _origValue.sub(m_devPercent_out.mul(_origValue));
        uint256 _profit = m_investorFundPercent_out.mul(_origValue);
        _amountToSend = _amountToSend.sub(m_investorFundPercent_out.mul(_profit));
        
        
        totalInvestmentFund = totalInvestmentFund.sub(_origValue);
        
        if(!msg.sender.send(_amountToSend)) {
            investorMapping.data[msg.sender].value = _origValue;
            totalInvestmentFund = totalInvestmentFund.add(_origValue);
        } else {
            
            devAddress.transfer(m_devPercent_out.mul(_origValue));
            profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(_profit);
            totalProfits = totalProfits.add(_profit);
            
            emit LogInvestmentWithdrawn(msg.sender, _origValue, now);
        }
    }
    
    
    // receive % of profits from other games
    function receiveExternalProfits() public payable checkDayRollover {
        // No checks on who is sending... if someone wants to send us free ETH let them!
        
        profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(msg.value);
        profitDays[currentProfitDay].dailyInvestments = profitDays[currentProfitDay].dailyInvestments.add(msg.value);
        emit LogReceiveExternalProfits(msg.sender, msg.value, now);
    }
    
    

    // investor management
    
    function investor_insert(address addr, uint value) internal returns (bool) {
        uint keyIndex = investorMapping.data[addr].keyIndex;
        if (keyIndex != 0) return false; // already exists
        investorMapping.data[addr].value = value;
        keyIndex = investorMapping.keys.length++;
        investorMapping.data[addr].keyIndex = keyIndex;
        investorMapping.data[addr].startDay = currentProfitDay;
        investorMapping.data[addr].lastDividendDay = currentProfitDay;
        investorMapping.data[addr].investmentsMade = 1;
        investorMapping.keys[keyIndex] = addr;
        emit LogInsertInvestor(addr, keyIndex, value, now);
        return true;
    }
    function investor_addRefBonus(address addr, uint refBonus) internal returns (bool) {
        if (investorMapping.data[addr].keyIndex == 0) return false;
        investorMapping.data[addr].refBonus += refBonus;
        return true;
    }
    function investor_clearRefBonus(address addr) internal returns (bool) {
        if (investorMapping.data[addr].keyIndex == 0) return false;
        investorMapping.data[addr].refBonus = 0;
        return true;
    }
    function investor_contains(address addr) public view returns (bool) {
        return investorMapping.data[addr].keyIndex > 0;
    }
    function investor_getShortInfo(address addr) public view returns(uint, uint) {
        return (
          investorMapping.data[addr].value,
          investorMapping.data[addr].refBonus
        );
    }
    function investor_getMediumInfo(address addr) public view returns(uint, uint, uint16) {
        return (
          investorMapping.data[addr].value,
          investorMapping.data[addr].refBonus,
          investorMapping.data[addr].investmentsMade
        );
    }
    
    // Owner only functions    
    

    

    function p_setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    function p_setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    function p_setDevPercent(uint num, uint dem) public onlyOwner {
        m_devPercent = Percent.percent(num, dem);
    }
    function p_setInvestorFundPercent(uint num, uint dem) public onlyOwner {
        m_investorFundPercent = Percent.percent(num, dem);
    }
    function p_setDevPercent_out(uint num, uint dem) public onlyOwner {
        m_devPercent_out = Percent.percent(num, dem);
    }
    function p_setInvestorFundPercent_out(uint num, uint dem) public onlyOwner {
        m_investorFundPercent_out = Percent.percent(num, dem);
    }
    function p_setRefPercent(uint num, uint dem) public onlyOwner {
        m_refPercent = Percent.percent(num, dem);
    }
    function p_setMinInvestment(uint _minInvestment) public onlyOwner {
        minInvestment = _minInvestment;
    }
    function p_setMaxInvestment(uint _maxInvestment) public onlyOwner {
        maxInvestment = _maxInvestment;
    }
    function p_setGamePaused(bool _gamePaused) public onlyOwner {
        gamePaused = _gamePaused;
    }
    function p_setGameDuration(uint256 _gameDuration) public onlyOwner {
        gameDuration = _gameDuration;
    }

    // Util functions
    function notZeroAndNotSender(address addr) internal view returns(bool) {
        return addr.notZero() && addr != msg.sender;
    }
    
    
    function getDividends(bool _includeCurrentDay, address _investor) internal view returns(uint256, uint256) {
        require(investor_contains(_investor));
        uint16 i = investorMapping.data[_investor].lastDividendDay;
        uint total_value;
        uint total_refBonus;
        total_value = 0;
        total_refBonus = 0;
        
        uint16 _option = 0;
        if(_includeCurrentDay)
            _option++;

        uint _value;
        (_value, total_refBonus) = investor_getShortInfo(_investor);

        uint256 _profitPercentageEminus7Multi = (_value*10000000 / totalInvestmentFund * 10000000) / 10000000;

        for(i; i< currentProfitDay+_option; i++) {

            if(profitDays[i].dailyProfit > 0){
                total_value = total_value.add(
                        (profitDays[i].dailyProfit / 10000000 * _profitPercentageEminus7Multi)
                    );
            }
        
        }
            
        return (total_value, total_refBonus);
    }
    uint256 a=0;
    function gameOp() public {
        a++;
    }

}