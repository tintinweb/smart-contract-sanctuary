/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
    function issue(address _recipient, uint256 _value) returns (bool success) {}
    function issueAtIco(address _recipient, uint256 _value, uint256 _icoNumber) returns (bool success) {}
    function totalSupply() constant returns (uint256 supply) {}
    function unlock() returns (bool success) {}
}

contract RICHCrowdsale {

    using SafeMath for uint256;

    // Crowdsale addresses
    address public creator; // Creator (1% funding)
    address public buyBackFund; // Fund for buying back and burning (48% funding)
    address public humanityFund; // Humanity fund (51% funding)

    // Withdrawal rules
    uint256 public creatorWithdraw = 0; // Current withdrawed
    uint256 public maxCreatorWithdraw = 5 * 10 ** 3 * 10**18; // First 5.000 ETH
    uint256 public percentageHumanityFund = 51; // Percentage goes to Humanity fund
    uint256 public percentageBuyBackFund = 49; // Percentage goes to Buy-back fund

    // Eth to token rate
    uint256 public currentMarketRate = 1; // Current market price ETH/RCH. Will be updated before each ico
    uint256 public minimumIcoRate = 240; // ETH/dollar rate. Minimum rate at wich will be issued RICH token, 1$ = 1RCH
    uint256 public minAcceptedEthAmount = 4 finney; // 0.004 ether

    // ICOs specification
    uint256 public maxTotalSupply = 1000000000 * 10**8; // 1 mlrd. tokens

    mapping (uint256 => uint256) icoTokenIssued; // Issued in each ICO
    uint256 public totalTokenIssued; // Total of issued tokens

    uint256 public icoPeriod = 10 days;
    uint256 public noIcoPeriod = 10 days;
    uint256 public maxIssuedTokensPerIco = 10**6 * 10**8; // 1 mil.
    uint256 public preIcoPeriod = 30 days;

    uint256 public bonusPreIco = 50;
    uint256 public bonusFirstIco = 30;
    uint256 public bonusSecondIco = 10;

    uint256 public bonusSubscription = 5;
    mapping (address => uint256) subsriptionBonusTokensIssued;

    // Balances
    mapping (address => uint256) balances;
    mapping (address => uint256) tokenBalances;
    mapping (address => mapping (uint256 => uint256)) tokenBalancesPerIco;

    enum Stages {
        Countdown,
        PreIco,
        PriorityIco,
        OpenIco,
        Ico, // [PreIco, PriorityIco, OpenIco]
        NoIco,
        Ended
    }

    Stages public stage = Stages.Countdown;

    // Crowdsale times
    uint public start;
    uint public preIcoStart;

    // Rich token
    Token public richToken;

    /**
     * Throw if at stage other than current stage
     *
     * @param _stage expected stage to test for
     */
    modifier atStage(Stages _stage) {
        updateState();

        if (stage != _stage && _stage != Stages.Ico) {
            throw;
        }

        if (stage != Stages.PriorityIco && stage != Stages.OpenIco && stage != Stages.PreIco) {
            throw;
        }
        _;
    }


    /**
     * Throw if sender is not creator
     */
    modifier onlyCreator() {
        if (creator != msg.sender) {
            throw;
        }
        _;
    }

    /**
     * Get bonus for provided ICO number
     *
     * @param _currentIco current ico number
     * @return percentage
     */
    function getPercentageBonusForIco(uint256 _currentIco) returns (uint256 percentage) {
        updateState();

        if (stage == Stages.PreIco) {
            return bonusPreIco;
        }

        if (_currentIco == 1) {
            return bonusFirstIco;
        }

        if (_currentIco == 2) {
            return bonusSecondIco;
        }

        return 0;
    }

    /**
     * Get ethereum balance of `_investor`
     *
     * @param _investor The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }

    /**
     * Construct
     *
     * @param _tokenAddress The address of the Rich token contact
     * @param _creator Contract creator
     * @param _start Start of the first ICO
     * @param _preIcoStart Start of pre-ICO
     */
    function RICHCrowdsale(address _tokenAddress, address _creator, uint256 _start, uint256 _preIcoStart) {
        richToken = Token(_tokenAddress);
        creator = _creator;
        start = _start;
        preIcoStart = _preIcoStart;
    }

    /**
     * Set current market rate ETH/RICH. Will be caled by creator before each ICO
     *
     * @param _currentMarketRate current ETH/RICH rate at the market
     */
    function setCurrentMarketRate(uint256 _currentMarketRate) onlyCreator returns (uint256) {
        currentMarketRate = _currentMarketRate;
    }

    /**
     * Set minimum ICO rate (ETH/dollar) in order to achieve max price of 1$ for 1 RCH.
     * Will be called by creator before each ICO
     *
     * @param _minimumIcoRate current ETH/dollar rate at the market
     */
    function setMinimumIcoRate(uint256 _minimumIcoRate) onlyCreator returns (uint256) {
        minimumIcoRate = _minimumIcoRate;
    }

    /**
     * Set humanity fund address
     *
     * @param _humanityFund Humanity fund address
     */
    function setHumanityFund(address _humanityFund) onlyCreator {
        humanityFund = _humanityFund;
    }

    /**
     * Set buy back fund address
     *
     * @param _buyBackFund Bay back fund address
     */
    function setBuyBackFund(address _buyBackFund) onlyCreator {
        buyBackFund = _buyBackFund;
    }

    /**
     * Get current rate at which will be issued tokens
     *
     * @return rate How many tokens will be issued for one ETH
     */
    function getRate() returns (uint256 rate) {
        if (currentMarketRate * 12 / 10 < minimumIcoRate) {
            return minimumIcoRate;
        }

        return currentMarketRate * 12 / 10;
    }

    /**
     * Retrun pecentage of tokens owned by provided investor
     *
     * @param _investor address of investor
     * @param exeptInIco ICO number that will be excluded from calculation (usually current ICO number)
     * @return investor rate, 1000000 = 100%
     */
    function getInvestorTokenPercentage(address _investor, uint256 exeptInIco) returns (uint256 percentage) {
        uint256 deductionInvestor = 0;
        uint256 deductionIco = 0;

        if (exeptInIco >= 0) {
            deductionInvestor = tokenBalancesPerIco[_investor][exeptInIco];
            deductionIco = icoTokenIssued[exeptInIco];
        }

        if (totalTokenIssued - deductionIco == 0) {
            return 0;
        }

        return 1000000 * (tokenBalances[_investor] - deductionInvestor) / (totalTokenIssued - deductionIco);
    }

    /**
     * Convert `_wei` to an amount in RICH using
     * the current rate
     *
     * @param _wei amount of wei to convert
     * @return The amount in RICH
     */
    function toRICH(uint256 _wei) returns (uint256 amount) {
        uint256 rate = getRate();

        return _wei * rate * 10**8 / 1 ether; // 10**8 for 8 decimals
    }

    /**
     * Return ICO number (PreIco has index 0)
     *
     * @return ICO number
     */
    function getCurrentIcoNumber() returns (uint256 amount) {
        uint256 timeBehind = now - start;
        if (now < start) {
            return 0;
        }

        return 1 + ((timeBehind - (timeBehind % (icoPeriod + noIcoPeriod))) / (icoPeriod + noIcoPeriod));
    }

    /**
     * Update crowd sale stage based on current time and ICO periods
     */
    function updateState() {
        uint256 timeBehind = now - start;
        uint256 currentIcoNumber = getCurrentIcoNumber();

        if (icoTokenIssued[currentIcoNumber] >= maxIssuedTokensPerIco) {
            stage = Stages.NoIco;
            return;
        }

        if (totalTokenIssued >= maxTotalSupply) {
            stage = Stages.Ended;
            return;
        }

        if (now >= preIcoStart && now <= preIcoStart + preIcoPeriod) {
            stage = Stages.PreIco;
            return;
        }

        if (now < start) {
            stage = Stages.Countdown;
            return;
        }

        uint256 timeFromIcoStart = timeBehind - (currentIcoNumber - 1) * (icoPeriod + noIcoPeriod);

        if (timeFromIcoStart > icoPeriod) {
            stage = Stages.NoIco;
            return;
        }

        if (timeFromIcoStart > icoPeriod / 2) {
            stage = Stages.OpenIco;
            return;
        }

        stage = Stages.PriorityIco;
    }


    /**
     * Transfer appropriate percentage of raised amount to the company address and humanity and buy back fund
     */
    function withdraw() onlyCreator {
        uint256 ethBalance = this.balance;
        uint256 amountToSend = ethBalance - 100000000;

        if (creatorWithdraw < maxCreatorWithdraw) {
            if (amountToSend > maxCreatorWithdraw - creatorWithdraw) {
                amountToSend = maxCreatorWithdraw - creatorWithdraw;
            }

            if (!creator.send(amountToSend)) {
                throw;
            }

            creatorWithdraw += amountToSend;
            return;
        }

        uint256 ethForHumanityFund = amountToSend * percentageHumanityFund / 100;
        uint256 ethForBuyBackFund = amountToSend * percentageBuyBackFund / 100;

        if (!humanityFund.send(ethForHumanityFund)) {
            throw;
        }

        if (!buyBackFund.send(ethForBuyBackFund)) {
            throw;
        }
    }

    /**
     * Add additional bonus tokens for subscribed investors
     *
     * @param investorAddress Address of investor
     */
    function sendSubscriptionBonus(address investorAddress) onlyCreator {
        uint256 subscriptionBonus = tokenBalances[investorAddress] * bonusSubscription / 100;

        if (subsriptionBonusTokensIssued[investorAddress] < subscriptionBonus) {
            uint256 toBeIssued = subscriptionBonus - subsriptionBonusTokensIssued[investorAddress];
            if (!richToken.issue(investorAddress, toBeIssued)) {
                throw;
            }

            subsriptionBonusTokensIssued[investorAddress] += toBeIssued;
        }
    }

    /**
     * Receives Eth and issue RICH tokens to the sender
     */
    function () payable atStage(Stages.Ico) {
        uint256 receivedEth = msg.value;

        if (receivedEth < minAcceptedEthAmount) {
            throw;
        }

        uint256 tokensToBeIssued = toRICH(receivedEth);
        uint256 currentIco = getCurrentIcoNumber();

        //add bonus
        tokensToBeIssued = tokensToBeIssued + (tokensToBeIssued * getPercentageBonusForIco(currentIco) / 100);

        if (tokensToBeIssued == 0 || icoTokenIssued[currentIco] + tokensToBeIssued > maxIssuedTokensPerIco) {
            throw;
        }

        if (stage == Stages.PriorityIco) {
            uint256 alreadyBoughtInIco = tokenBalancesPerIco[msg.sender][currentIco];
            uint256 canBuyTokensInThisIco = maxIssuedTokensPerIco * getInvestorTokenPercentage(msg.sender, currentIco) / 1000000;

            if (tokensToBeIssued > canBuyTokensInThisIco - alreadyBoughtInIco) {
                throw;
            }
        }

        if (!richToken.issue(msg.sender, tokensToBeIssued)) {
            throw;
        }

        icoTokenIssued[currentIco] += tokensToBeIssued;
        totalTokenIssued += tokensToBeIssued;
        balances[msg.sender] += receivedEth;
        tokenBalances[msg.sender] += tokensToBeIssued;
        tokenBalancesPerIco[msg.sender][currentIco] += tokensToBeIssued;
    }
}