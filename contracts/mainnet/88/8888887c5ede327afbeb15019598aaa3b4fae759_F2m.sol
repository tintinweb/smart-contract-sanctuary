pragma solidity ^0.4.24;

/*
*   gibmireinbier
*   0xA4a799086aE18D7db6C4b57f496B081b44888888
*   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4b2c22292622392e222529222e390b2c262a222765282426">[email&#160;protected]</a>
*/

interface WhitelistInterface {
    function joinNetwork(address[6] _contract) public;
    function isLimited(address _address, uint256 _invested) public view returns(bool);
}

interface NewTokenInterface {
    function swapToken(uint256 _amount, address _invester) public payable;
}

interface BankInterface {
    function joinNetwork(address[6] _contract) public;
    // Core functions
    function pushToBank(address _player) public payable;
}


interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
    // call one time
    function activeFirstRound() public;
    // Core Functions
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
    // bounty
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
    //function withdraw() public;
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
    // EarlyIncome
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // included claimed amount
    // function getEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // function getCurEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurRoundId() public view returns(uint256);
    // set endRound, prepare to upgrade new version
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
}
interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function devTeamWithdraw() public;

    /*----------  WRITE FUNCTIONS  ----------*/
    function updateUsername(string _sNewUsername) public;
    //Sources: Token contract, DApps
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

    /*----------  READ FUNCTIONS  ----------*/
    function getRefWallet(address _address) public view returns(uint256);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract F2m{
    using SafeMath for *;

    // only token holder

    modifier onlyTokenHolders() {
        require(balances[msg.sender] > 0, "not own any token");
        _;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == devTeam, "admin required");
        _;
    }

    modifier withdrawRight(){
        require((msg.sender == address(bankContract)), "Bank Only");
        _;
    }

    modifier swapNotActived() {
        require(swapActived == false, "swap actived, stop minting new tokens");
        _;
    }

    modifier buyable() {
        require(buyActived == true, "token sale not ready");
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/  
    // ERC20
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    /*=====================================
    =                 ERC20               =
    =====================================*/
    uint256 public totalSupply;  
    string public name;  
    string public symbol;  
    uint32 public decimals;
    uint256 public unitRate;
    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
   /*================================
    =            DATASETS            =
    ================================*/
    CitizenInterface public citizenContract;
    LotteryInterface public lotteryContract;
    BankInterface public bankContract;
    NewTokenInterface public newTokenContract;
    WhitelistInterface public whitelistContract;

    uint256 constant public ONE_HOUR= 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR; // seconds
    uint256 constant public FIRST_POT_MAXIMUM = 360 ether; // 800 * 45%
    uint256 constant public ROUND0_MIN_DURATION = ONE_DAY; // minimum
    uint256 constant public SWAP_DURATION = 30 * ONE_DAY;
    uint256 constant public BEFORE_SLEEP_DURAION = 7 * ONE_DAY;

    uint256 public HARD_TOTAL_SUPPLY = 8000000;

    uint256 constant public refPercent = 15;
    uint256 constant public divPercent = 10;
    uint256 constant public fundPercent = 2;

    //Start Price
    uint256 constant public startPrice = 0.002 ether;
    //Most Tolerable Break-Even Period (MTBEP)
    uint256 constant public BEP = 30;

    uint256 public potPercent = 45; // set to 0 in func disableRound0()

    // amount of shares for each address (scaled number)
    mapping(address => int256) public credit;
    mapping(address => uint256) public withdrawnAmount;
    mapping(address => uint256) public fromSellingAmount;

    mapping(address => uint256) public lastActiveDay;
    mapping(address => int256) public todayCredit;

    mapping(address => uint256) public pInvestedSum;

    uint256 public investedAmount;
    uint256 public totalBuyVolume;
    uint256 public totalSellVolume;
    uint256 public totalDividends;
    mapping(uint256 => uint256) public totalDividendsByRound;

    //Profit Per Share 
    uint256 public pps = 0;

    //log by round
    mapping(uint256 => uint256) rPps;
    mapping(address => mapping (uint256 => int256)) rCredit; 

    uint256 public deployedTime;
    uint256 public deployedDay;

    // on/off auto buy Token
    bool public autoBuy;

    bool public round0 = true; //raise for first round

    //pps added in day
    mapping(uint256 => uint256) public ppsInDay; //Avarage pps in a day
    mapping(uint256 => uint256) public divInDay;
    mapping(uint256 => uint256) public totalBuyVolumeInDay;
    mapping(uint256 => uint256) public totalSellVolumeInDay;

    address public devTeam; //Smart contract address

    uint256 public swapTime;
    bool public swapActived = false;
    bool public buyActived = false;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor (address _devTeam)
        public
    {
        symbol = "F2M";  
        name = "Fomo2Moon";  
        decimals = 10;
        unitRate = 10**uint256(decimals);
        HARD_TOTAL_SUPPLY = HARD_TOTAL_SUPPLY * unitRate;
        totalSupply = 0; 
        //deployedTime = block.timestamp;
        DevTeamInterface(_devTeam).setF2mAddress(address(this));
        devTeam = _devTeam;
        autoBuy = true;
    }

    // _contract = [f2mAddress, bankAddress, citizenAddress, lotteryAddress, rewardAddress, whitelistAddress];
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0, "already setup");
        bankContract = BankInterface(_contract[1]);
        citizenContract = CitizenInterface(_contract[2]);
        lotteryContract = LotteryInterface(_contract[3]);
        whitelistContract = WhitelistInterface(_contract[5]);
    }
 
    function()
        public
        payable
    {
        // Thanks for Donation
    }

    // one time called, manuell called in case not reached 360ETH for totalPot
    function disableRound0() 
        public 
        onlyAdmin() 
    {
        require(buyActived && block.timestamp > ROUND0_MIN_DURATION.add(deployedTime), "too early to disable Round0");
        round0 = false;
        potPercent = 0;
    }

    function activeBuy()
        public
        onlyAdmin()
    {
        require(buyActived == false, "already actived");
        buyActived = true;
        deployedTime = block.timestamp;
        deployedDay = getToday();
    }

    // Dividends from all sources (DApps, Donate ...)
    function pushDividends() 
        public 
        payable 
    {
        // shared to fund and dividends only
        uint256 ethAmount = msg.value;
        uint256 dividends = ethAmount * divPercent / (divPercent + fundPercent);
        uint256 fund = ethAmount.sub(dividends);
        uint256 _buyPrice = getBuyPrice();
        distributeTax(fund, dividends, 0, 0);
        if (autoBuy) devTeamAutoBuy(0, _buyPrice);
    }

    function addFund(uint256 _fund)
        private
    {
        credit[devTeam] = credit[devTeam].sub(int256(_fund));
    }

    function addDividends(uint256 _dividends)
        private
    {
        if (_dividends == 0) return;
        totalDividends += _dividends;
        uint256 today = getToday();
        divInDay[today] = _dividends.add(divInDay[today]);

        if (totalSupply == 0) {
            addFund(_dividends);
        } else {
            // increased profit with each token
            // gib mir n bier
            addFund(_dividends % totalSupply);
            uint256 deltaShare = _dividends / totalSupply;
            pps = pps.add(deltaShare);

            // logs
            uint256 curRoundId = getCurRoundId();
            rPps[curRoundId] += deltaShare;
            totalDividendsByRound[curRoundId] += _dividends;
            ppsInDay[today] = deltaShare + ppsInDay[today];
        }
    }

    function addToRef(uint256 _toRef)
        private
    {
        if (_toRef == 0) return;
        address sender = msg.sender;
        citizenContract.pushRefIncome.value(_toRef)(sender);
    }

    function addToPot(uint256 _toPot)
        private
    {
        if (_toPot == 0) return;
        lotteryContract.pushToPot.value(_toPot)();
        uint256 _totalPot = lotteryContract.getTotalPot();

        // auto disable Round0 if reached 360ETH for first round
        if (_totalPot >= FIRST_POT_MAXIMUM) {
            round0 = false;
            potPercent = 0;
        }
    }

    function distributeTax(
        uint256 _fund,
        uint256 _dividends,
        uint256 _toRef,
        uint256 _toPot)
        private
    {
        addFund(_fund);
        addDividends(_dividends);
        addToRef(_toRef);
        addToPot(_toPot);
    }

    function updateCredit(address _owner, uint256 _currentEthAmount, uint256 _rDividends, uint256 _todayDividends) 
        private 
    {
        // basicly to keep ethBalance not changed, after token balances changed (minted or burned)
        // ethBalance = pps * tokens -credit
        uint256 curRoundId = getCurRoundId();
        credit[_owner] = int256(pps.mul(balances[_owner])).sub(int256(_currentEthAmount));
        // logs
        rCredit[_owner][curRoundId] = int256(rPps[curRoundId] * balances[_owner]) - int256(_rDividends);
        todayCredit[_owner] = int256(ppsInDay[getToday()] * balances[_owner]) - int256(_todayDividends);
    }

    function mintToken(address _buyer, uint256 _taxedAmount, uint256 _buyPrice) 
        private 
        swapNotActived()
        buyable()
        returns(uint256) 
    {
        uint256 revTokens = ethToToken(_taxedAmount, _buyPrice);
        investedAmount = investedAmount.add(_taxedAmount);
        // lottery ticket buy could be blocked without this
        // the 1% from ticket buy will increases tokenSellPrice when totalSupply capped
        if (revTokens + totalSupply > HARD_TOTAL_SUPPLY) 
            revTokens = HARD_TOTAL_SUPPLY.sub(totalSupply);
        balances[_buyer] = balances[_buyer].add(revTokens);
        totalSupply = totalSupply.add(revTokens);
        return revTokens;
    }

    function burnToken(address _seller, uint256 _tokenAmount) 
        private 
        returns (uint256) 
    {
        require(balances[_seller] >= _tokenAmount, "not enough to burn");
        uint256 revEthAmount = tokenToEth(_tokenAmount);
        investedAmount = investedAmount.sub(revEthAmount);
        balances[_seller] = balances[_seller].sub(_tokenAmount);
        totalSupply = totalSupply.sub(_tokenAmount);
        return revEthAmount;
    }

    function devTeamAutoBuy(uint256 _reserved, uint256 _buyPrice)
        private
    {
        uint256 _refClaim = citizenContract.devTeamReinvest();
        credit[devTeam] -= int256(_refClaim);
        uint256 _ethAmount = ethBalance(devTeam);
        if ((_ethAmount + _reserved) / _buyPrice + totalSupply > HARD_TOTAL_SUPPLY) return;

        uint256 _rDividends = getRDividends(devTeam);
        uint256 _todayDividends = getTodayDividendsByAddress(devTeam);
        mintToken(devTeam, _ethAmount, _buyPrice);
        updateCredit(devTeam, 0, _rDividends, _todayDividends);
    }

    function buy()
        public
        payable
    {
        address _buyer = msg.sender;
        buyFor(_buyer);
    }

    function checkLimit(address _buyer)
        private
        view
    {
        require(!round0 || !whitelistContract.isLimited(_buyer, pInvestedSum[_buyer]), "Limited");
    }

    function buyFor(address _buyer) 
        public 
        payable
    {
        //ADD Round0 WHITE LIST
        // tax = fund + dividends + toRef + toPot;
        updateLastActive(_buyer);
        uint256 _buyPrice = getBuyPrice();
        uint256 ethAmount = msg.value;
        pInvestedSum[_buyer] += ethAmount;
        checkLimit(_buyer);
        uint256 onePercent = ethAmount / 100;
        uint256 fund = onePercent.mul(fundPercent);
        uint256 dividends = onePercent.mul(divPercent);
        uint256 toRef = onePercent.mul(refPercent);
        uint256 toPot = onePercent.mul(potPercent);
        uint256 tax = fund + dividends + toRef + toPot;
        uint256 taxedAmount = ethAmount.sub(tax);
        
        totalBuyVolume = totalBuyVolume + ethAmount;
        totalBuyVolumeInDay[getToday()] += ethAmount;

        distributeTax(fund, dividends, toRef, toPot);
        if (autoBuy) devTeamAutoBuy(taxedAmount, _buyPrice);

        uint256 curEthBalance = ethBalance(_buyer);
        uint256 _rDividends = getRDividends(_buyer);
        uint256 _todayDividends = getTodayDividendsByAddress(_buyer);

        mintToken(_buyer, taxedAmount, _buyPrice);
        updateCredit(_buyer, curEthBalance, _rDividends, _todayDividends);
    }

    function sell(uint256 _tokenAmount)
        public
        onlyTokenHolders()
    {
        // tax = fund only
        updateLastActive(msg.sender);
        address seller = msg.sender;
        uint256 curEthBalance = ethBalance(seller);
        uint256 _rDividends = getRDividends(seller);
        uint256 _todayDividends = getTodayDividendsByAddress(seller);

        uint256 ethAmount = burnToken(seller, _tokenAmount);
        uint256 fund = ethAmount.mul(fundPercent) / 100;
        //uint256 tax = fund;
        uint256 taxedAmount = ethAmount.sub(fund);

        totalSellVolume = totalSellVolume + ethAmount;
        totalSellVolumeInDay[getToday()] += ethAmount;
        curEthBalance = curEthBalance.add(taxedAmount);
        fromSellingAmount[seller] += taxedAmount;
        
        updateCredit(seller, curEthBalance, _rDividends, _todayDividends);
        distributeTax(fund, 0, 0, 0);
    }

    function devTeamWithdraw()
        public
        returns(uint256)
    {
        address sender = msg.sender;
        require(sender == devTeam, "dev. Team only");
        uint256 amount = ethBalance(sender);
        if (amount == 0) return 0;
        credit[sender] += int256(amount);
        withdrawnAmount[sender] = amount.add(withdrawnAmount[sender]);
        devTeam.transfer(amount);
        return amount;
    }

    function withdrawFor(address sender)
        public
        withdrawRight()
        returns(uint256)
    {
        uint256 amount = ethBalance(sender);
        if (amount == 0) return 0;
        credit[sender] = credit[sender].add(int256(amount));
        withdrawnAmount[sender] = amount.add(withdrawnAmount[sender]);
        bankContract.pushToBank.value(amount)(sender);
        return amount;
    }

    function updateAllowed(address _from, address _to, uint256 _tokenAmount)
        private
    {
        require(balances[_from] >= _tokenAmount, "not enough to transfer");
        if (_from != msg.sender)
        allowed[_from][_to] = allowed[_from][_to].sub(_tokenAmount);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenAmount)
        public
        returns(bool)
    {   
        updateAllowed(_from, _to, _tokenAmount);
        updateLastActive(_from);
        updateLastActive(_to);
        // tax = 0

        uint256 curEthBalance_from = ethBalance(_from);
        uint256 _rDividends_from = getRDividends(_from);
        uint256 _todayDividends_from = getTodayDividendsByAddress(_from);

        uint256 curEthBalance_to = ethBalance(_to);
        uint256 _rDividends_to = getRDividends(_to);
        uint256 _todayDividends_to = getTodayDividendsByAddress(_to);

        uint256 taxedTokenAmount = _tokenAmount;
        balances[_from] -= taxedTokenAmount;
        balances[_to] += taxedTokenAmount;
        updateCredit(_from, curEthBalance_from, _rDividends_from, _todayDividends_from);
        updateCredit(_to, curEthBalance_to, _rDividends_to, _todayDividends_to);
        // distributeTax(tax, 0, 0, 0);
        // fire event
        emit Transfer(_from, _to, taxedTokenAmount);
        
        return true;
    }

    function transfer(address _to, uint256 _tokenAmount)
        public 
        returns (bool) 
    {
        transferFrom(msg.sender, _to, _tokenAmount);
        return true;
    }

    function approve(address spender, uint tokens) 
        public 
        returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function updateLastActive(address _sender) 
        private
    {
        if (lastActiveDay[_sender] != getToday()) {
            lastActiveDay[_sender] = getToday();
            todayCredit[_sender] = 0;
        }
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    function setAutoBuy() 
        public
        onlyAdmin()
    {
        //require(buyActived && block.timestamp > ROUND0_MIN_DURATION.add(deployedTime), "too early to disable autoBuy");
        autoBuy = !autoBuy;
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    function totalEthBalance()
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }
    
    function ethBalance(address _address)
        public
        view
        returns(uint256)
    {
        return (uint256) ((int256)(pps.mul(balances[_address])).sub(credit[_address]));
    }

    function getTotalDividendsByAddress(address _invester)
        public
        view
        returns(uint256)
    {

        return (ethBalance(_invester)) + (withdrawnAmount[_invester]) - (fromSellingAmount[_invester]);
    }

    function getTodayDividendsByAddress(address _invester)
        public
        view
        returns(uint256)
    {
        int256 _todayCredit = (getToday() == lastActiveDay[_invester]) ? todayCredit[_invester] : 0;
        return (uint256) ((int256)(ppsInDay[getToday()] * balances[_invester]) - _todayCredit);
    }
    
    /*==========================================
    =            public FUNCTIONS            =
    ==========================================*/

    /**
     * Return the sell price of 1 individual token.
     */
    function getSellPrice() 
        public 
        view 
        returns(uint256)
    {
        if (totalSupply == 0) {
            return 0;
        } else {
            return investedAmount / totalSupply;
        }
    }

    function getSellPriceAfterTax() 
        public 
        view 
        returns(uint256)
    {
        uint256 _sellPrice = getSellPrice();
        uint256 taxPercent = fundPercent;
        return _sellPrice * (100 - taxPercent) / 100;
    }
    
    /**
     * Return the buy price of 1 individual token.
     * Start Price + (7-day Average Dividend Payout) x BEP x HARD_TOTAL_SUPPLY / (Total No. of Circulating Tokens) / (HARD_TOTAL_SUPPLY - Total No. of Circulating Tokens + 1)
     */
    function getBuyPrice() 
        public 
        view 
        returns(uint256)
    {
        // average profit per share of a day in week
        uint256 taxPercent = fundPercent + potPercent + divPercent + refPercent;
        if (round0) return startPrice * (100 - taxPercent) / 100 / unitRate;
        uint256 avgPps = getAvgPps();
        uint256 _sellPrice = getSellPrice();
        uint256 _buyPrice = (startPrice / unitRate + avgPps * BEP * HARD_TOTAL_SUPPLY / (HARD_TOTAL_SUPPLY + unitRate - totalSupply)) * (100 - taxPercent) / 100;
        if (_buyPrice < _sellPrice) return _sellPrice;
        return _buyPrice;
    }

    function getBuyPriceAfterTax()
        public 
        view 
        returns(uint256)
    {
        // average profit per share of a day in week
        uint256 _buyPrice = getBuyPrice();
        uint256 taxPercent = fundPercent + potPercent + divPercent + refPercent;
        return _buyPrice * 100 / (100 - taxPercent);
    }

    function ethToToken(uint256 _ethAmount, uint256 _buyPrice)
        public
        pure
        returns(uint256)
    {
        return _ethAmount / _buyPrice;
    }

/*     function ethToTokenRest(uint256 _ethAmount, uint256 _buyPrice)
        public
        pure
        returns(uint256)
    {
        return _ethAmount % _buyPrice;
    } */
    
    function tokenToEth(uint256 _tokenAmount)
        public
        view
        returns(uint256)
    {
        uint256 sellPrice = getSellPrice();
        return _tokenAmount.mul(sellPrice);
    }
    
    function getToday() 
        public 
        view 
        returns (uint256) 
    {
        return (block.timestamp / ONE_DAY);
    }

    //Avarage Profit per Share in last 7 Days
    function getAvgPps() 
        public 
        view 
        returns (uint256) 
    {
        uint256 divSum = 0;
        uint256 _today = getToday();
        uint256 _fromDay = _today - 6;
        if (_fromDay < deployedDay) _fromDay = deployedDay;
        for (uint256 i = _fromDay; i <= _today; i++) {
            divSum = divSum.add(divInDay[i]);
        }
        if (totalSupply == 0) return 0;
        return divSum / (_today + 1 - _fromDay) / totalSupply;
    }

    function getTotalVolume() 
        public
        view
        returns(uint256)
    {
        return totalBuyVolume + totalSellVolume;
    }

    function getWeeklyBuyVolume() 
        public
        view
        returns(uint256)
    {
        uint256 _total = 0;
        uint256 _today = getToday();
        for (uint256 i = _today; i + 7 > _today; i--) {
            _total = _total + totalBuyVolumeInDay[i];
        }
        return _total;
    }

    function getWeeklySellVolume() 
        public
        view
        returns(uint256)
    {
        uint256 _total = 0;
        uint256 _today = getToday();
        for (uint256 i = _today; i + 7 > _today; i--) {
            _total = _total + totalSellVolumeInDay[i];
        }
        return _total;
    }

    function getWeeklyVolume()
        public
        view
        returns(uint256)
    {
        return getWeeklyBuyVolume() + getWeeklySellVolume();
    }

    function getTotalDividends()
        public
        view
        returns(uint256)
    {
        return totalDividends;
    }

    function getRDividends(address _invester)
        public
        view
        returns(uint256)
    {
        uint256 curRoundId = getCurRoundId();
        return uint256(int256(rPps[curRoundId] * balances[_invester]) - rCredit[_invester][curRoundId]);
    }

    function getWeeklyDividends()
        public
        view
        returns(uint256)
    {
        uint256 divSum = 0;
        uint256 _today = getToday();
        uint256 _fromDay = _today - 6;
        if (_fromDay < deployedDay) _fromDay = deployedDay;
        for (uint256 i = _fromDay; i <= _today; i++) {
            divSum = divSum.add(divInDay[i]);
        }
        
        return divSum;
    }

    function getMarketCap()
        public
        view
        returns(uint256)
    {
        return totalSupply.mul(getBuyPriceAfterTax());
    }

    function totalSupply()
        public
        view
        returns(uint)
    {
        return totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns(uint256)
    {
        return balances[tokenOwner];
    }

    function myBalance() 
        public 
        view 
        returns(uint256)
    {
        return balances[msg.sender];
    }

    function myEthBalance() 
        public 
        view 
        returns(uint256) 
    {
        return ethBalance(msg.sender);
    }

    function myCredit() 
        public 
        view 
        returns(int256) 
    {
        return credit[msg.sender];
    }

    function getRound0MinDuration()
        public
        view
        returns(uint256)
    {
        if (!round0) return 0;
        if (block.timestamp > ROUND0_MIN_DURATION.add(deployedTime)) return 0;
        return ROUND0_MIN_DURATION + deployedTime - block.timestamp;
    }

    // Lottery

    function getCurRoundId()
        public
        view
        returns(uint256)
    {
        return lotteryContract.getCurRoundId();
    }

    //SWAP TOKEN, PUBLIC SWAP_DURAION SECONDS BEFORE
    function swapToken()
        public
        onlyTokenHolders()
    {
        require(swapActived, "swap not actived");
        address _invester = msg.sender;
        uint256 _tokenAmount = balances[_invester];
        // burn all token
        uint256 _ethAmount = burnToken(_invester, _tokenAmount);
        // swapToken function in new contract accepts only sender = this old contract
        newTokenContract.swapToken.value(_ethAmount)(_tokenAmount, _invester);
    }

    // start swapping, disable buy
    function setNewToken(address _newTokenAddress)
        public
        onlyAdmin()
    {
        bool _isLastRound = lotteryContract.isLastRound();
        require(_isLastRound, "too early");
        require(swapActived == false, "already set");
        swapTime = block.timestamp;
        swapActived = true;
        newTokenContract = NewTokenInterface(_newTokenAddress);
        autoBuy = false;
    }

    // after 90 days from swapTime, devteam withdraw whole eth.
    function sleep()
        public
    {
        require(swapActived, "swap not actived");
        require(swapTime + BEFORE_SLEEP_DURAION < block.timestamp, "too early");
        uint256 _ethAmount = address(this).balance;
        devTeam.transfer(_ethAmount);
        //ICE
    }

}