/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
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
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}

  contract BBRStaking {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
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
    event Withdraw(
        address indexed user,
        uint256 tokens
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "BBR Stake";
    uint256 public decimals = 18;
    uint public monthlyROI= 16;
    address public tokenBUSDAddress;
    address public tokenBBRAddress;
    address public tokenAffiliateAddress;
    address public EACAggregatorProxyAddress;

    uint lockDays = 730 ; // change it to '790 days' in production
    uint oneDay = 1 ; // change it to '1 days' in production

    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public rewardBalanceLedger_;
    uint256 public tokenSupply_ = 0;

    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint) public refCount;

    uint public minimumBuyAmount = 50 * (10**decimals);

    uint public onFlyMintedAmount;
    address public terminal;

    uint public minWithdraw = 10 * (10**decimals);
    uint256 public tokenPriceInitial_ = 1 * (10**(decimals-1));
    uint256 public tokenPriceIncremental_ = 0 * (10**(decimals-6));
    uint256 public currentPrice_  = (10**(decimals-1));
    uint256 public sellPrice  = (10**(decimals-1));
    uint public busdToBBRPercent = 1 * (10 ** (decimals-1));
    uint public base = 100 * (10 ** decimals);
    bool isSell;
    struct stakeInf
    {
        uint amount;
        uint stakeTime;
        uint totalRoi;
        uint lastWithdrawTime;
        uint referralCnt;
    }

    struct user
    {
      address referrer;
      uint referralplace;
      uint256 wid_limit;
      bool isactive;
      uint256 total_payouts;
    }
    mapping(address => user) public userInfo;
    mapping(address => stakeInf[]) public stakeInfo;
    mapping(address => uint) public totalStake;
    mapping(address => uint) public claimeddailyROIGain;
    uint16[] percent_ =  [0,100,20,10,10,10,10,10,10,10,10];
    uint16[] lvlpercent_ =[500,300,200,100,50];
    uint16[] percenteligible_ =  [0,0,2,3,4,5,6,7,8,9,10];
    bool isReferrerComm ;
    event stakeTokenEv(address _user, uint _amount, uint stakeIndex);

    constructor(address _tokenBUSDAddress,address _tokenBBRAddress,address _EACAggregatorProxyAddress) public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenBUSDAddress = _tokenBUSDAddress;
        tokenBBRAddress = _tokenBBRAddress;
        //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
    }



    /*==========================================
    =            VIEW FUNCTIONS            =
    ==========================================*/

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function NumberOfStakes(address _user) public view returns(uint)
    {
      return stakeInfo[_user].length;
    }

    function checklimit(address _addr, uint256 amount) public view returns(uint)
    {
      if(((userInfo[_addr].total_payouts + amount) <= userInfo[_addr].wid_limit) || _addr == terminal)
      {
         return amount;
      }
      else
      {
        uint remainamount = userInfo[_addr].wid_limit - userInfo[_addr].total_payouts;
        return remainamount;

      }
    }
    function BNBToBUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** (decimals-8)) / (10 ** (decimals));
    }

    function BUSDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount *  (10 ** (decimals)) / bnbpreice * (10 ** (decimals-8));
    }

    function BUSDToBBR(uint busdAmount) public view returns(uint)
    {
       return ((busdAmount / currentPrice_) * (10 ** decimals)) ;      
    }

    function BBRToBUSD(uint BBRAmount) public view returns(uint)
    {
        return BBRAmount / (10**decimals) * currentPrice_;
    }
    function BBRToBNB(uint BBRAmount) public view returns(uint)
    {
        uint amt =  BBRToBUSD(BBRAmount);
        return BUSDToBNB(amt);
    }
    /*==========================================
    =            WRITE FUNCTIONS            =
    ==========================================*/
    function buy_(address _user,address _referredBy, uint256 tokenAmount) external returns(uint256)
    {
      require(msg.sender == tokenAffiliateAddress,  'Invalid caller');
      require(tokenAmount > 0, "invalid amount sent");
      uint256 BUSDToken;
      if(tokenAmount > 0 )
      {
        tokenAmount = BBRToBUSD(tokenAmount);
        BUSDToken = tokenAmount;
      }
      require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
      uint256 BBRToken = BUSDToBBR(tokenAmount);
      uint lastindex= NumberOfStakes(_user);
      if(lastindex>0){
        uint256 laststake = stakeInfo[_user][lastindex].amount;
        require(BBRToken > laststake, "Stake must be equivalent or greater than last stake");
      }
      currentPrice_ = currentPrice_ + tokenPriceIncremental_;
      if(_referredBy == address(0) || _user == _referredBy) _referredBy = terminal;
      if(genTree[_user] == address(0))
      {
        genTree[_user] = _referredBy;
        refCount[_referredBy]++;
      }
      uint tkn = purchaseTokens(_user, BBRToken);
      return tkn;
    }

    function buy(address _referredBy, uint256 tokenAmount) public payable returns(uint256)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
      require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
      uint256 BUSDToken;
      if(tokenAmount > 0 )
      {
        tokenAmount = BBRToBUSD(tokenAmount);
        BUSDToken = tokenAmount;
      }
      if(msg.value > 0)
      {
        tokenAmount += BNBToBUSD(msg.value);
      }
      require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
      uint256 BBRToken = BUSDToBBR(tokenAmount);
      uint lastindex= NumberOfStakes(msg.sender);
      if(lastindex>0){
        uint256 laststake = stakeInfo[msg.sender][lastindex].amount;
        require(BBRToken > laststake, "Stake must be equivalent or greater than last stake");
      }
      tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), BUSDToken);
      currentPrice_ = currentPrice_ + tokenPriceIncremental_;
      if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = terminal;
      if(genTree[msg.sender] == address(0))
      {
        genTree[msg.sender] = _referredBy;
        refCount[_referredBy]++;
      }

      uint tkn = purchaseTokens(msg.sender, BBRToken);
      return tkn;
    }

    function withdrawAll() public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
      address _customerAddress = msg.sender;
      uint256 totaldaily= claimeddailyROIGain[_customerAddress];
      uint256 _rewardbalance = rewardBalanceLedger_[_customerAddress] ;
      require(_rewardbalance + totaldaily >= 0, "No balance to withdraw");
      require(_rewardbalance + totaldaily >= minWithdraw, "Does not reach to minimum withdraw limit");
      uint256 _balance = _rewardbalance + totaldaily ;
      require(tokenInterface(tokenBBRAddress).balanceOf(address(this)) >=  _balance , "Insufficient fund");
      if(_rewardbalance>0){
        require(rewardBalanceLedger_[_customerAddress] >=  _rewardbalance , "overflow found");
      }

      uint userbalance = _balance * 98 /100;
      uint adminfee = _balance * 2 /100;

      rewardBalanceLedger_[_customerAddress] -= _rewardbalance ;
      claimeddailyROIGain[_customerAddress] -= totaldaily ;

      tokenInterface(tokenBBRAddress).transfer(_customerAddress, userbalance);
      tokenInterface(tokenBBRAddress).transfer(terminal, adminfee);
      emit Transfer(address(this) , _customerAddress , userbalance);
      emit Withdraw(_customerAddress, userbalance);
      return true;
    }
    function Claim(uint stakeIndex) public returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed to withdraw');
        uint amount = stakeInfo[msg.sender][stakeIndex].amount;
        require( amount > 0, "nothing staked");
        uint tim = stakeInfo[msg.sender][stakeIndex].stakeTime;
        uint tim2 = stakeInfo[msg.sender][stakeIndex].lastWithdrawTime;
        uint lD = lockDays;
        uint oD = oneDay;
        require(tim2 < tim + lD,"Stake time period has been over.");
        uint usedDays = (tim2 - tim) / oD;
        uint daysPassed = (block.timestamp - tim2 ) / oD;
        if(usedDays + daysPassed > lD ) daysPassed = lD - usedDays;
        uint256 busdAmount = BBRToBUSD(amount);
        uint256 amt = (busdAmount * monthlyROI/ 300000) * daysPassed ;
        amt = BUSDToBBR(amt);
        stakeInfo[msg.sender][stakeIndex].lastWithdrawTime = block.timestamp;
        uint256 checkedamt=checklimit(msg.sender,amt);
        if(checkedamt==amt){
          stakeInfo[msg.sender][stakeIndex].totalRoi += amt ;
          claimeddailyROIGain[msg.sender] += amt ;
          userInfo[msg.sender].total_payouts += amt ;
        }
        else
        {
          uint remamt = amt - checkedamt;
          stakeInfo[msg.sender][stakeIndex].totalRoi += checkedamt ;
          claimeddailyROIGain[msg.sender]+= checkedamt;
          claimeddailyROIGain[terminal] += remamt;
          userInfo[msg.sender].total_payouts = 0;
        }

        return true;
    }
    function sell(uint256 _amountOfTokens, bool isBNB ) external
    {
        require(isSell,"Sell is not enabled");
        address _customerAddress = msg.sender;
        uint256 userbalance = tokenInterface(tokenBBRAddress).balanceOf(_customerAddress);
        require(userbalance > 0 ,"No balance");
        require(userbalance >= _amountOfTokens ,"Not enough balance");
        uint256 _busd = BBRToBUSD(_amountOfTokens) * sellPrice;
        tokenInterface(tokenBBRAddress).transferFrom(_customerAddress,address(this),_amountOfTokens);
        if(isBNB)
        {
          uint256 bnbamt = BUSDToBNB(_busd);
           payable(_customerAddress).transfer(bnbamt);
        }
        else
        {
          tokenInterface(tokenBUSDAddress).transfer(_customerAddress,_busd);
        }
        emit Transfer(_customerAddress, address(this), _amountOfTokens);
    }

      receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function distributeRewards(uint256 _amount, address _idToDistribute)
    internal
    {
        for(uint i=0; i< lvlpercent_.length; i++)
        {
            _idToDistribute = genTree[_idToDistribute];
            if(_idToDistribute == address(0)) _idToDistribute = terminal;
            uint pct;
            pct = lvlpercent_[i];
            uint256 amt = _amount*pct/10000;
            uint256 checkedamt=checklimit(_idToDistribute,amt);
            if(checkedamt==amt){
              rewardBalanceLedger_[_idToDistribute] += amt ;
              userInfo[_idToDistribute].total_payouts += amt ;
            }
            else
            {
              uint remamt = amt - checkedamt;
              rewardBalanceLedger_[_idToDistribute]+= checkedamt;
              rewardBalanceLedger_[terminal] += remamt;
              userInfo[_idToDistribute].total_payouts = 0;
            }
            if(checkedamt > 0){
              emit Reward_Buy(_idToDistribute, checkedamt ,i);
            }
        }
    }
    function purchaseTokens(address _customerAddress, uint256 _amountOfTokens) internal returns(uint256)
    {
        tokenSupply_ = tokenSupply_.add(_amountOfTokens);
        if(isReferrerComm)
        {
          distributeRewards(_amountOfTokens, _customerAddress);
        }
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);
        stakeToken(_customerAddress);
        // fire event
        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    function stakeToken(address _user) internal returns(bool)
    {
        uint amount = tokenBalanceLedger_[_user];
        tokenBalanceLedger_[_user] = 0;
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)].add(amount);
        stakeInf memory temp;
        temp.amount = amount;
        temp.stakeTime = block.timestamp;
        temp.referralCnt = 0;
        userInfo[_user].wid_limit = amount * 2 ;
        temp.lastWithdrawTime = block.timestamp;
        stakeInfo[_user].push(temp);
        totalStake[_user] += amount;
        userInfo[_user].total_payouts=0 ;
        emit stakeTokenEv(_user, amount, stakeInfo[_user].length);
        emit Transfer(_user, address(this), amount);
        return true;
    }

    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function adjustPrice(uint currenT, uint increamentaL) public onlyAdministrator returns(bool)
    {
        currentPrice_ = currenT;
        tokenPriceIncremental_ = increamentaL;
        return true;
    }
    function adjustSellPrice(uint _sellprice) public onlyAdministrator returns(bool)
    {
        sellPrice = _sellprice;
        return true;
    }

    function changeBUSDTokenAddress(address _tokenBUSDAddress) public onlyAdministrator returns(bool)
    {
        tokenBUSDAddress = _tokenBUSDAddress;
        return true;
    }
    function changeAffiliateTokenAddress(address _tokenAffiliateAddress) public onlyAdministrator returns(bool)
    {
        tokenAffiliateAddress = _tokenAffiliateAddress;
        return true;
    }
    function changeBBRTokenAddress(address _tokenBBRAddress) public onlyAdministrator returns(bool)
    {
        tokenBBRAddress = _tokenBBRAddress;
        return true;
    }
    function setMinWithdraw(uint _minWithdraw) public onlyAdministrator returns(bool)
    {
        minWithdraw = _minWithdraw * (10** decimals);
        return true;
    }

    function setMinimumBuyAmount(uint _minimumBuyAmount) public onlyAdministrator returns(bool)
    {
        minimumBuyAmount = _minimumBuyAmount * (10** decimals);
        return true;
    }

    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenBUSDAddress).balanceOf(address(this));
        tokenBalanceLedger_[address(this)] = 0 ;
        tokenInterface(tokenBUSDAddress).transfer(terminal, tokenBalance);
        tokenBalanceLedger_[terminal]  += tokenBalance;
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
    // use 12 for 1.2 ( one digit will be taken as decimal )
    function setMonthlyROI(uint _monthlyROI) public  onlyAdministrator returns(bool)
    {
        monthlyROI= _monthlyROI;
        return true;
    }
    function setDaysFactor(uint _secondForOneDays) public onlyAdministrator returns(bool)
    {
        lockDays = 730 * _secondForOneDays;
        oneDay = _secondForOneDays;
        return true;
    }
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          //transfer(recipients[i], tokenAmount[i]);
          tokenInterface(tokenBUSDAddress).transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }
    //set 2 decimal values-- for 2 set 200
    function updatelvlPercent_(uint16[] memory values) public onlyAdministrator returns(bool)
    {
      require(values.length>0 && values.length <10, "Array length must be greater than 0 and less than 10");
        for(uint i = 0 ; i < values.length; i++)
        {
            lvlpercent_[i] = values[i];
        }
        return true;
    }
    function setReferrerComm(bool _isReferrerComm) public  onlyAdministrator returns(bool)
    {
        isReferrerComm = _isReferrerComm;
        return true;
    }
    function setSell(bool _isSell) public  onlyAdministrator returns(bool)
    {
        isSell = _isSell;
        return true;
    }

    // decimals zeros for decimal
    function setBusdToBBRpercent(uint _busdToBBRPercent) public onlyAdministrator returns(bool)
    {
        busdToBBRPercent = _busdToBBRPercent;
        return true;
    }
}