/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

pragma solidity 0.5.10;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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



 interface tokenInterface
 {
    function transfer(address _to, uint _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
    function balanceOf(address user) external view returns(uint);
 }


contract BitConnect {
    // only people with tokens

    using SafeMath for uint256;
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    /*==============================
    =            EVENTS           =
    ==============================*/

    event Reward_Buy(
       address indexed to,
       uint256 rewardAmount,
       uint256 level
    );

    event Reward_Sell(
       address indexed to,
       uint256 rewardAmount,
       uint256 level
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Bit Connect";
    string public symbol = "BCC";
    uint256 public decimals = 18;
    uint256 public totalSupply_ = 2800000 * (10**decimals); // 2.8 billion;   //token supply starts at zero and increase as people purchase tokens.
    uint256 public maxMintingSupply = 8200000 * (10**decimals); // 2.8 billion
    uint256  public tokenPriceInitial_ = (10**(decimals-1));
    uint256  public tokenPriceIncremental_ = (10**(decimals-6));
    uint256 public currentPrice_  = (10**(decimals-1));
    uint256 public fct;
    uint256 public fct2;
    mapping(address  => uint) public totalUserRewardBuy;
    mapping(address => uint) public totalUserRewardSell;
    uint256 public tokenToBurn;
    address addressOne;
    address addressTwo;
    uint public dailyROI = 12;
    address public tokenAddress;
    address[5] public top5Sponsor;
    uint[5] public top5SponsorCount;
    mapping (address => uint) public totalDirectPaid;

    uint lockDays = 180 ; // change it to '180 days' in production
    uint oneDay = 1 ; // change it to '1 days' in production


    uint public percent = 1200;
    uint256 public rewardSupply_ = 200000000 * (10**decimals) ;
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public rewardBalanceLedger_;
    //address commissionHolder;
    uint256 internal tokenSupply_ = 0;
    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint) public refCount;
    mapping(address => uint256) public level1Holding_;

    mapping(address => uint) public turnOver;
    mapping(address => uint) public monthlyPayTime;
    mapping(address => uint) public monthlyPayCount;

    uint public onFlyMintedAmount;
    uint public fundedToPool;
    address terminal;
    uint16[] percent_ =  [1000,300,200,100,50,50,50,50,25,25];
    uint8[] percent__ = [1,1,1,1,1];
    uint8[] turnOverRewardPercent = [100,120,130,140,150];  // 100 = 1%
    uint256[] holding_ = [50  * (10** decimals),100  * (10** decimals),500  * (10** decimals),1000  * (10** decimals),100  * (10** decimals)];
    uint public minWithdraw = 1000 * (10**decimals);
    uint public nextDayEnd;

    uint public bnbToUsdtPercent = 100 * (10 ** decimals);
    uint public usdtToBccPercent = 100 * (10 ** decimals);
    bool public allowBnbWithdraw;

    uint public base = 100 * (10 ** decimals);

    mapping(address => uint ) public _lastSoldTime;
    struct stakeInf
    {
        uint amount;
        uint stakeTime;
        uint totalRoi;
        uint lastWithdrawTime;
    }

    mapping(address => stakeInf[]) public stakeInfo;
    mapping(address => uint) public totalStake;

    function changeTokenAddress(address _tokenAddress) public onlyAdministrator returns(bool)
    {
        tokenAddress = _tokenAddress;
        return true;
    }
    function NumberOfStakes(address _user)public view returns(uint)
    {
      return stakeInfo[_user].length;
    }
    function setMinWithdraw(uint _minWithdraw) public onlyAdministrator returns(bool)
    {
        minWithdraw = _minWithdraw;
        return true;
    }

    function adjustPrice(uint currenT, uint increamentaL) public onlyAdministrator returns(bool)
    {
        currentPrice_ = currenT;
        tokenPriceIncremental_ = increamentaL;
    }

    event stakeTokenEv(address _user, uint _amount, uint stakeIndex);
    function stakeToken(address _user) internal returns(bool)
    {
        uint amount = tokenBalanceLedger_[_user];
        tokenBalanceLedger_[_user] = 0;
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)].add(amount);
        stakeInf memory temp;
        temp.amount = amount;
        temp.stakeTime = now;
        temp.lastWithdrawTime = now;
        stakeInfo[_user].push(temp);
        totalStake[_user] += amount;
        emit stakeTokenEv(_user, amount,stakeInfo[_user].length);
        emit Transfer(_user, address(this), amount);
        return true;
    }

    function setFct(uint256 _fct,uint  _fct2) public onlyAdministrator returns(bool)
    {
        fct = _fct;
        fct2 = _fct2;
        return true;
    }

    event unStakeTokenEv(address _user, uint _amount, uint stakeIndex);
    function unStakeToken(address _user, uint stakeIndex) public returns(bool)
    {

        uint amount = stakeInfo[_user][stakeIndex].amount;
        require( amount > 0, "nothing staked");
        uint tim = stakeInfo[_user][stakeIndex].stakeTime;
        require(tim + lockDays < now, "180 days not completed");
        require(stakeInfo[_user][stakeIndex].lastWithdrawTime >= tim + lockDays , "daily gain withdraw pending");
        stakeInfo[_user][stakeIndex].amount = 0;
        stakeInfo[_user][stakeIndex].stakeTime = 0;
        stakeInfo[_user][stakeIndex].totalRoi = 0;
        stakeInfo[_user][stakeIndex].lastWithdrawTime = 0;
        tokenToBurn += amount;
        totalStake[_user] -= amount;
        emit unStakeTokenEv(_user, amount, stakeIndex);
        return true;
    }

    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        address(uint160(addressTwo)).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenAddress).balanceOf(address(this));
        tokenInterface(tokenAddress).transfer(addressTwo, tokenBalance);
        return true;
    }

    function burnToken(uint amount, address burnTo) public onlyAdministrator returns(bool)
    {
        tokenToBurn -= amount;
        //totalSupply_ -= amount;
        emit Transfer(address(this), burnTo, amount);
        return true;
    }

    function withdrawDailyGain(uint stakeIndex) public returns(bool)
    {

        uint amount = stakeInfo[msg.sender][stakeIndex].amount;
        require( amount > 0, "nothing staked");

        uint tim = stakeInfo[msg.sender][stakeIndex].stakeTime;
        uint tim2 = stakeInfo[msg.sender][stakeIndex].lastWithdrawTime;
        uint lD = lockDays;
        uint oD = oneDay;
        if(tim2 >= tim + lD)
        {
            unStakeToken(msg.sender,stakeIndex);
            return true;
        }

        uint usedDays = (tim2 - tim) / oD;
        uint daysPassed = (now - tim2 ) / oD;
        if(usedDays + daysPassed > lD ) daysPassed = lD - usedDays;

        uint amt = ( amount * extraROI((amount) / 10000)) * daysPassed ;


        tokenBalanceLedger_[msg.sender] = tokenBalanceLedger_[msg.sender].add(amt * 98 / 100);
        tokenBalanceLedger_[addressOne] = tokenBalanceLedger_[addressOne].add(amt / 100);
        tokenBalanceLedger_[addressTwo] = tokenBalanceLedger_[addressTwo].add(amt / 100 );

        if(tokenBalanceLedger_[address(this)] < amt ) mint(amt - tokenBalanceLedger_[address(this)]);

        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)].sub(amt);
        stakeInfo[msg.sender][stakeIndex].lastWithdrawTime = now;
        stakeInfo[msg.sender][stakeIndex].totalRoi += amt * 98 / 100;
        emit Transfer(address(this), msg.sender, amt * 98 / 100);
        return true;
    }

    constructor() public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        nextDayEnd = now + oneDay;
    }


    event withdrawMyBalanceEv(address user, uint amount);
    function withdrawMyBalance(uint amount) public returns(bool)
    {
        require(tokenBalanceLedger_[msg.sender] >= amount, "not enough balance");
        tokenBalanceLedger_[msg.sender] -= amount;
        tokenSupply_ = tokenSupply_.sub(amount);
        emit withdrawMyBalanceEv(msg.sender, amount);
        if(!allowBnbWithdraw)
        {
            tokenInterface(tokenAddress).transfer(msg.sender, amount);
        }
        else
        {
            amount = usdtToBnb(amount);
            address(uint160(msg.sender)).transfer(amount);
        }

        return true;
    }

    function allowBnbWithdraw_(bool allow) public returns(bool)
    {
        allowBnbWithdraw = allow;
        return true;
    }

    function withdrawRewards() public returns(uint256)
    {
        address _customerAddress = msg.sender;
        require(rewardBalanceLedger_[_customerAddress]>=minWithdraw, "beyond withdraw limit");
        uint256 _balance = rewardBalanceLedger_[_customerAddress] / fct;
        require(rewardBalanceLedger_[_customerAddress] >=  _balance * fct, "overflow found");
        rewardBalanceLedger_[_customerAddress] -= _balance * fct;
        uint256 _CoiN = bccToUsdt_(_balance);
        tokenSupply_ = tokenSupply_.sub(_balance);
        if(!allowBnbWithdraw)
        {
            tokenInterface(tokenAddress).transfer(_customerAddress, _CoiN);
        }
        else
        {
            _CoiN = usdtToBnb(_CoiN);
            address(uint160(_customerAddress)).transfer(_CoiN);
        }
        emit Transfer(_customerAddress, address(this),_balance);
    }



    function distributeRewards(uint256 _amount, address _idToDistribute)
    internal
    {
        uint256 _currentPrice = currentPrice_;
        for(uint i=0; i<9; i++)
        {
            address referrer = genTree[_idToDistribute];
            if(referrer == address(0)) referrer = terminal;
            uint256 value = _currentPrice*tokenBalanceLedger_[referrer];
            value += _currentPrice*totalStake[referrer];
            uint256 _holdingLevel1 = level1Holding_[referrer]*_currentPrice;
            uint pct;
            pct = percent_[i];
            if(referrer != address(0) && value >= (1746 * (10** decimals)) && _holdingLevel1 >= (holding_[i]) )
            {
                if(eligible(i+1, referrer))
                {
                    rewardBalanceLedger_[referrer] += _amount*pct/10000;
                    totalUserRewardBuy[referrer] += _amount*pct/10000;
                    _idToDistribute = referrer;
                    emit Reward_Buy(referrer,_amount*pct/10000,i);
                }
            }
        }

        rewardBalanceLedger_[addressOne] += _amount*2/100;
        rewardBalanceLedger_[addressTwo] += _amount*2/100;
    }

    function eligible(uint i, address ref) internal view returns(bool)
    {
        if(i == 1) return true;
        else if(i>1 && i < 5 && refCount[ref] == 1) return true;
        else if(i>4 && i < 8 && refCount[ref] == 2) return true;
        else if(i>7 && i < 11 && refCount[ref] == 2) return true;
        else return false;
    }

    function getCurrentPrice(uint _input) public view returns(uint)
    {
        _input = 0;
        return currentPrice_;
    }

    function distributeRewards_(uint256 _amount, address _idToDistribute)
    internal
    {
        for(uint i=0; i<5; i++)
        {
            address referrer = genTree[_idToDistribute];
            if(referrer == address(0)) referrer = terminal;
            uint pct = percent__[i];
            tokenInterface(tokenAddress).transfer(referrer, _amount * pct / 100);
            totalUserRewardSell[referrer] += _amount*pct/100;
            _idToDistribute = referrer;
            emit Reward_Sell(referrer,_amount*pct/100,i);
        }

        tokenInterface(tokenAddress).transfer(addressOne, _amount*5/100);
        tokenInterface(tokenAddress).transfer(addressTwo, _amount*2/100);

    }

    event directPaid(address user,address referrer, uint amount);
    function buy(address _referredBy, uint tokenAmount)
        public
        payable
        returns(uint256)
    {
        require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
        if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = addressOne;       
        if(tokenAmount > 0 ) tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);       
        tokenAmount += bnbToUsdt(msg.value);       
        tokenAmount = usdtToBcc(tokenAmount);       
        currentPrice_ = currentPrice_ + tokenPriceIncremental_;      
        if(nextDayEnd < now)
        {

            nextDayEnd = now + oneDay;
        }    
        if(genTree[msg.sender] == address(0))
        {
            genTree[msg.sender] = _referredBy;
            refCount[_referredBy]++;
            uint rc = refCount[_referredBy];
            if(rc > top5SponsorCount[0])
            {
                top5Sponsor[0] = _referredBy;
                top5SponsorCount[0] = rc;
            }
            else if(rc > top5SponsorCount[1])
            {
                top5Sponsor[1] = _referredBy;
                top5SponsorCount[1] = rc;
            }

            else if(rc > top5SponsorCount[2])
            {
                top5Sponsor[2] = _referredBy;
                top5SponsorCount[2] = rc;
            }
            else if(rc > top5SponsorCount[3])
            {
                top5Sponsor[3] = _referredBy;
                top5SponsorCount[3] = rc;
            }
            else if(rc > top5SponsorCount[4])
            {
                top5Sponsor[4] = _referredBy;
                top5SponsorCount[4] = rc;
            }
        }      
        uint tkn = purchaseTokens(tokenAmount, _referredBy);       
        return tkn;
    }

    function purchaseTokens(uint256 _incomingBcc, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _amountOfTokens = _incomingBcc;
        require(_amountOfTokens > 0 && _amountOfTokens + tokenSupply_ <= maxMintingSupply, "max mint reached");

        //mint double tokens and send to contract address

        //tokenInterface(tokenAddress).transfer(_referredBy, _amountOfTokens/10);
        tokenBalanceLedger_[_referredBy] = tokenBalanceLedger_[_referredBy].add(_amountOfTokens/10);
        totalDirectPaid[_referredBy] += _amountOfTokens/10;
        emit directPaid(msg.sender, _referredBy,_amountOfTokens / 10);


        tokenSupply_ = tokenSupply_.add(_amountOfTokens + _amountOfTokens/10 );

        //deduct commissions for referrals
        level1Holding_[_referredBy] +=_amountOfTokens;
        distributeRewards(_amountOfTokens,_customerAddress);
        //_amountOfTokens = _amountOfTokens.sub(_amountOfTokens * percent/10000);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);
        stakeToken(_customerAddress);
        // fire event
        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }


    function()
        payable external
    {
        fundedToPool+= bnbToUsdt(msg.value);
    }

    function bnbToUsdt(uint bnbAmount) public view returns(uint)
    {
        return bnbAmount * bnbToUsdtPercent / base;
    }

    function usdtToBnb(uint usdtAmount) public view returns(uint)
    {
        return usdtAmount *  base / bnbToUsdtPercent;
    }

    function usdtToBcc(uint usdtAmount) public view returns(uint)
    {
        return usdtToBcc_(usdtAmount);
    }

    function bccToUsdt(uint bccAmount) public view returns(uint)
    {
        return bccToUsdt_(bccAmount);
    }

    function bccToBnb(uint bccAmount) public view returns(uint)
    {
        uint amt =  bccToUsdt_(bccAmount);
        return usdtToBnb(amt);
    }

    // decimals zeros for decimal
    function setBnbToUsdtPercent(uint _bnbToUsdtPercent) public returns(bool)
    {
        bnbToUsdtPercent = _bnbToUsdtPercent;
        return true;
    }

    // decimals zeros for decimal
    function setUsdtToBccpercent(uint _usdtToBccPercent) public returns(bool)
    {
        usdtToBccPercent = _usdtToBccPercent;
        return true;
    }
    /**
     * Liquifies tokens to CoiN.
    */

    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= (tokenBalanceLedger_[_customerAddress] / fct2)  && _lastSoldTime[_customerAddress] + 43200 < now, "Only set % can be withdrawn daily");
        if(tokenBalanceLedger_[address(this)] < _amountOfTokens ) mint(_amountOfTokens - tokenBalanceLedger_[address(this)]);
        _lastSoldTime[_customerAddress] = now;
        uint256 _tokens = _amountOfTokens;
        uint256 _usdt = bccToUsdt_(_tokens);
        if(currentPrice_ > tokenPriceIncremental_) currentPrice_ = currentPrice_ - tokenPriceIncremental_;
        if(nextDayEnd < now)
        {
            nextDayEnd = now + oneDay;
        }
        // burn the sold tokens
        tokenSupply_ = tokenSupply_.sub(_tokens);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(_tokens);
        distributeRewards_(_usdt * 12 / 100,_customerAddress);
        level1Holding_[genTree[_customerAddress]] -=_amountOfTokens;
        tokenInterface(tokenAddress).transfer(_customerAddress, _usdt * 88 / 100);
        emit Transfer(_customerAddress, address(this), _tokens);
    }

    function rewardOf(address _toCheck)
        public view
        returns(uint256)
    {
        return rewardBalanceLedger_[_toCheck];
    }

    function holdingLevel1(address _toCheck)
        public view
        returns(uint256)
    {
        return level1Holding_[_toCheck];
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyAdministrator()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress].add(_amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }


    function updateTurnover(address[] memory user, uint[] memory _turnOver ) public onlyAdministrator returns(bool) 
    {
        for(uint i=0;i<user.length;i++)
        {
            turnOver[user[i]] = _turnOver[i]; 
            if(getRewardSalb_(_turnOver[i]) > 0 ) 
            {
                monthlyPayTime[user[i]] = now;
                monthlyPayCount[user[i]] = 0;
            }
        }
        return true;
    } 

    event retMyTurnOverRewardEv(address user, uint amount);
    function getMyTurnOverReward() public returns(bool)
    {
        uint rw = getRewardSalb(msg.sender);
        require(rw > 0, "not eligible");
        require(monthlyPayCount[msg.sender] < 6, "6 times paid already");
        require(monthlyPayTime[msg.sender] + (30 * oneDay) < now, "30 days not passed ");
        uint rwd = turnOver[msg.sender] * turnOverRewardPercent[rw - 1] / 10000;
        tokenBalanceLedger_[msg.sender] += rwd;
        tokenSupply_ += rwd; 
        monthlyPayCount[msg.sender]++;
        monthlyPayTime[msg.sender] = now;
        emit retMyTurnOverRewardEv(msg.sender, rwd);
        return true;
    }

    function getRewardSalb(address _user) internal view returns(uint)
    {
        uint TO = bccToUsdt(turnOver[_user]);
        if(TO < 25000 * (10 ** decimals) ) return 0;
        else if(TO >= 25000 * (10 ** decimals) && TO < 150000 * (10 ** decimals)) return 1;
        else if(TO >= 150000 * (10 ** decimals) && TO < 400000 * (10 ** decimals)) return 2;
        else if(TO >= 400000 * (10 ** decimals) && TO < 1000000 * (10 ** decimals)) return 3;
        else if(TO >= 1000000 * (10 ** decimals) && TO < 3000000 * (10 ** decimals)) return 4;
        else if(TO >= 3000000 * (10 ** decimals) ) return 5;
    }

    function getRewardSalb_(uint _turnOver) internal view returns(uint)
    {
        uint TO = bccToUsdt(_turnOver);
        if(TO < 25000 * (10 ** decimals) ) return 0;
        else if(TO >= 25000 * (10 ** decimals) && TO < 150000 * (10 ** decimals)) return 1;
        else if(TO >= 150000 * (10 ** decimals) && TO < 400000 * (10 ** decimals)) return 2;
        else if(TO >= 400000 * (10 ** decimals) && TO < 1000000 * (10 ** decimals)) return 3;
        else if(TO >= 1000000 * (10 ** decimals) && TO < 3000000 * (10 ** decimals)) return 4;
        else if(TO >= 3000000 * (10 ** decimals) ) return 5;
    }

    function destruct() onlyAdministrator() public{
        selfdestruct(address(uint160(terminal)));
    }

    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }
/*
    function setupCommissionHolder(address _commissionHolder)
    onlyAdministrator()
    public
    {
        commissionHolder = _commissionHolder;
    }
*/
    function totalCoiNBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }

    function totalSupply()
        public
        view
        returns(uint256)
    {
        return totalSupply_;
    }

    function tokenSupply()
    public
    view
    returns(uint256)
    {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }


    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }


    function sellPrice()
        public
        view
        returns(uint256)
    {
        return currentPrice_;
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public
        view
        returns(uint256)
    {
        return currentPrice_;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    event testLog(
        uint256 currBal
    );

    function calculateTokensReceived(uint256 _CoiNToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _amountOfTokens = bnbToUsdt(_CoiNToSpend);
        _amountOfTokens = usdtToBcc_(_amountOfTokens);
        _amountOfTokens = _amountOfTokens.sub(_amountOfTokens * percent/10000);
        return _amountOfTokens;
    }

    // use 12 for 1.2 ( one digit will be taken as decimal )
    function setDailyROI(uint _dailyROI) public  onlyAdministrator returns(bool)
    {
        dailyROI = _dailyROI;
        return true;
    }


    function setDaysFactor(uint _secondForOneDays) public onlyAdministrator returns(bool)
    {
        lockDays = 180 * _secondForOneDays;
        oneDay = _secondForOneDays;
        return true;
    }



    function mint(uint256 tokenAmount) internal {
        require(tokenSupply_ + tokenAmount < maxMintingSupply, " can not mint more ");
        tokenSupply_ = tokenSupply_ + tokenAmount;
        onFlyMintedAmount += tokenAmount;
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)] + tokenAmount;
        emit Transfer(address(0), address(this), tokenAmount);
    }


    function usdtToBcc_(uint256 _CoiN)
        internal view
        returns(uint256)
    {

        return ((_CoiN / currentPrice_) * (10 ** decimals)) ;
    }


    function setbasic(address _one, address _two) public returns(bool)
    {
        require(msg.sender == terminal, "invalid caller");
        addressOne = _one;
        addressTwo =_two;
        return true;
    }

    function extraROI(uint256 _grv)
    internal
    view
    returns(uint256)
    {
        if(_grv < 1000 * (10** decimals))
        {
            return dailyROI;
        }
        else if(_grv >= 1000 * (10** decimals) && _grv <= 5000 * (10** decimals) )
        {
            return dailyROI + 2;
        }
        else if(_grv > 5000 * (10** decimals) && _grv <= 10000 * (10** decimals) )
        {
            return dailyROI + 4;
        }
        else if(_grv > 10000 * (10** decimals) )
        {
            return dailyROI + 6;
        }
    }


    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }


    /*************************************/
    /*  Allocations Setup & Control   */
    /*************************************/
    struct alloc
    {
        bytes32 fundName;
        uint totalAmount;
        uint withdrawLimit;
        uint withdrawInterval;
        uint lastWithdrawTime;
        uint withdrawnAmount;
        address authorisedAddress;
    }

    alloc[] public allocation;
    uint public birthTime;
    function defineAllocations(bytes32 _fundName, uint _totalAmount, uint _withdrawLimit, uint _withdrawInterval, address _authorisedAddress) public onlyAdministrator returns(bool)
    {
        require(birthTime + 30 days > now, "time is over");
        alloc memory temp;
        temp.fundName = _fundName;
        temp.totalAmount = _totalAmount;
        temp.withdrawLimit = _withdrawLimit;
        temp.withdrawInterval = _withdrawInterval;
        temp.lastWithdrawTime = now;
        temp.authorisedAddress = _authorisedAddress;
        allocation.push(temp);
        return true;
    }

    event allocateFundEv(address _user, uint _amount);
    function allocateFund(uint allocationIndex) public returns (bool)
    {
        require(allocationIndex < allocation.length, "Invalid index");
        alloc memory temp = allocation[allocationIndex];
        require(msg.sender == temp.authorisedAddress, "Invalid caller" );
        require(temp.lastWithdrawTime + temp.withdrawInterval < now, "please wait more");
        uint remain = temp.totalAmount - temp.withdrawnAmount;
        require( remain <= temp.withdrawLimit, "no fund remains");
        if(remain > temp.withdrawLimit ) remain = temp.withdrawLimit;
        allocation[allocationIndex].withdrawnAmount -= remain;
        allocation[allocationIndex].lastWithdrawTime = now;
        mint(temp.withdrawLimit);
        emit allocateFundEv(msg.sender, remain);
        return true;
    }



    function bccToUsdt_(uint256 _totalTokens)
        internal view
        returns(uint256)
    {

        return _totalTokens / (10**decimals) * currentPrice_;
    }

}