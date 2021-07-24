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

contract MoneyMaker {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    /*==============================
    =            EVENTS           =
    ==============================*/

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
    string public name = "Money Maker";
    uint256 public decimals = 18;
    uint public dailyROI = 10;
    address public tokenAddress;

    uint lockDays = 365 ; // change it to '365 days' in production
    uint oneDay = 1 ; // change it to '1 days' in production

    mapping(address => uint256) public tokenBalanceLedger_;
    uint256 public tokenSupply_ = 0;

    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint) public refCount;
    mapping(address => uint) public sponsordailyGain;

    uint public minimumBuyAmount = 50 * (10**decimals);

    uint public onFlyMintedAmount;
    address public terminal;

    uint public minWithdraw = 10 * (10**decimals);
    mapping(address => uint256) public totalwithdrawn;
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
      bool isActiveStake;
    }
    mapping(address => user) public userInfo;
    mapping(address => stakeInf[]) public stakeInfo;
    mapping(address => uint) public totalStake;
    uint256 public totalInvested;
    uint256 public totalWithdraw;
    mapping(address => uint) public claimeddailyROIGain;
    uint16[] percent_ =  [0,100,20,10,10,10,10,10,10,10,10];
    uint16[] percenteligible_ =  [0,0,2,3,4,5,6,7,8,9,10];
    event stakeTokenEv(address _user, uint _amount, uint stakeIndex);

    constructor(address _tokenAddress) public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenAddress = _tokenAddress;
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

    /*==========================================
    =            WRITE FUNCTIONS            =
    ==========================================*/

    function buy(address _referredBy, uint256 tokenAmount) public returns(uint256)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
      require(!userInfo[msg.sender].isActiveStake,  "You cannot stake while active staking");
      require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
      if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = terminal;
      tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
      if(genTree[msg.sender] == address(0))
      {
          genTree[msg.sender] = _referredBy;
          refCount[_referredBy]++;
          userInfo[msg.sender].referrer = _referredBy;

          if(!userInfo[msg.sender].isactive){
            userInfo[msg.sender].referralplace = refCount[_referredBy];
            if(userInfo[_referredBy].isActiveStake){

              uint lastindex= NumberOfStakes(_referredBy).sub(1);
              stakeInfo[_referredBy][lastindex].referralCnt += 1;
              uint lastreferralCnt = stakeInfo[_referredBy][lastindex].referralCnt ;
              uint laststake =stakeInfo[_referredBy][lastindex].amount;
              uint laststaketime =stakeInfo[_referredBy][lastindex].lastWithdrawTime;
              if(tokenAmount >= laststake){
                if((laststaketime + (120 * 86400) >= block.timestamp) &&  lastreferralCnt>=10){
                  userInfo[_referredBy].wid_limit = 10 * (laststake) ;
                }
                else if((laststaketime + (105 * 86400) >= block.timestamp) &&  lastreferralCnt>=9){
                  userInfo[_referredBy].wid_limit = 9 * (laststake) ;
                }
                else if((laststaketime + (90 * 86400) >= block.timestamp) &&  lastreferralCnt>=8){
                  userInfo[_referredBy].wid_limit = 8 * (laststake) ;
                }
                else if((laststaketime + (75 * 86400) >= block.timestamp) &&  lastreferralCnt>=7){
                  userInfo[_referredBy].wid_limit = 7 * (laststake) ;
                }
                else if((laststaketime + (60 * 86400) >= block.timestamp) &&  lastreferralCnt>=6){
                  userInfo[_referredBy].wid_limit = 6 * (laststake) ;
                }
                else if((laststaketime + (45 * 86400) >= block.timestamp) &&  lastreferralCnt>=5){
                  userInfo[_referredBy].wid_limit = 5 * (laststake) ;
                }
                else if((laststaketime + (30 * 86400) >= block.timestamp) &&  lastreferralCnt>=4){
                  userInfo[_referredBy].wid_limit = 4 * (laststake) ;
                }
                else if((laststaketime + (15 * 86400) >= block.timestamp) &&  lastreferralCnt>=3){
                  userInfo[_referredBy].wid_limit = 3 * (laststake) ;
                }
              }
            }
          }
      }
      totalInvested += tokenAmount;
      uint tkn = purchaseTokens(msg.sender, tokenAmount);
      return tkn;
    }

    function withdrawAll() public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
      address _customerAddress = msg.sender;
      //uint256 totaldaily= claimeddailyROIGain[_customerAddress];
      uint256 totaldaily = Claimable();
      uint lastindex= NumberOfStakes(msg.sender).sub(1);
      stakeInfo[msg.sender][lastindex].lastWithdrawTime = block.timestamp;
      uint256 checkedamt=checklimit(msg.sender,totaldaily);
      if(checkedamt==totaldaily){
        stakeInfo[msg.sender][lastindex].totalRoi += totaldaily ;
      }
      else
      {
        uint remamt = totaldaily - checkedamt;
        stakeInfo[msg.sender][lastindex].totalRoi += checkedamt ;
        tokenBalanceLedger_[terminal] += remamt;
        userInfo[msg.sender].total_payouts = 0;
        userInfo[msg.sender].isActiveStake = false;
      }

      uint256 _rewardbalance = sponsordailyGain[_customerAddress] ;
      uint256 _balance = _rewardbalance + checkedamt ;
      require(_balance >= 0, "No balance to withdraw");
      require(_balance >= minWithdraw, "Does not reach to minimum withdraw limit");
      require(tokenInterface(tokenAddress).balanceOf(address(this)) >=  _balance , "Insufficient fund");
      if(_rewardbalance>0){
        require(sponsordailyGain[_customerAddress] >=  _rewardbalance , "overflow found");
      }
      if(checkedamt>0)
      {
        address ref =_customerAddress ;
        uint perc;
        uint eligiblerefcount;
        uint256 amt;
        uint256 checkedamtref;
        for(uint i =1 ; i < percent_.length;i++)
        {
          ref = genTree[ref];
          perc = percent_[i];
          eligiblerefcount = percenteligible_[i];
          if(refCount[ref] >= eligiblerefcount){
            amt= checkedamt * perc/100;
            checkedamtref=checklimit(msg.sender,amt);
            if(checkedamtref==amt){
              sponsordailyGain[ref]+= amt;
            }
            else
            {
              uint remamt = amt - checkedamtref;
              sponsordailyGain[ref] += checkedamtref;
              sponsordailyGain[terminal] += remamt;
              userInfo[ref].total_payouts = 0;
              userInfo[ref].isActiveStake = false;
            }
          }
        }
      }
      uint userbalance = _balance * 95 /100;
      uint adminfee = _balance * 5 /100;
      sponsordailyGain[_customerAddress] -= _rewardbalance ;
      userInfo[_customerAddress].total_payouts += userbalance ;
      totalwithdrawn[_customerAddress] += _balance;
      totalWithdraw += _balance ;
      tokenInterface(tokenAddress).transfer(_customerAddress, userbalance);
      tokenInterface(tokenAddress).transfer(terminal, adminfee);
      emit Transfer(address(this) , _customerAddress , userbalance);
      emit Withdraw(_customerAddress, userbalance);
      return true;
    }
    function Claimable() public view returns(uint256)
      {
          uint lastindex= NumberOfStakes(msg.sender).sub(1);
          uint256 amt = 0;
          if(userInfo[msg.sender].isActiveStake)
          {
            uint amount = stakeInfo[msg.sender][lastindex].amount;
            if(amount > 0){
            uint tim = stakeInfo[msg.sender][lastindex].stakeTime;
            uint tim2 = stakeInfo[msg.sender][lastindex].lastWithdrawTime;
            uint lD = lockDays;
            uint oD = oneDay;
            if(tim2 < tim + lD){
              uint usedDays = (tim2 - tim) / oD;
              uint daysPassed = (block.timestamp - tim2 ) / oD;
              if(usedDays + daysPassed > lD ) daysPassed = lD - usedDays;
              amt = (amount * extraROI(amount) / 10000) * daysPassed ;

              }
            }
          }
          return amt;
      }
  /*  function Claim(uint stakeIndex) public returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed to withdraw');
        uint lastindex= NumberOfStakes(msg.sender).sub(1);
        require(lastindex == stakeIndex,  "You cannot claim for old staking");
        require(userInfo[msg.sender].isActiveStake,  "You don't have active staking");
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
        uint256 amt = (amount * extraROI(amount) / 10000) * daysPassed ;
        stakeInfo[msg.sender][stakeIndex].lastWithdrawTime = block.timestamp;
        uint256 checkedamt=checklimit(msg.sender,amt);
        if(checkedamt==amt){
          stakeInfo[msg.sender][stakeIndex].totalRoi += amt ;
          claimeddailyROIGain[msg.sender] += amt ;
        }
        else
        {
          uint remamt = amt - checkedamt;
          stakeInfo[msg.sender][stakeIndex].totalRoi += checkedamt ;
          claimeddailyROIGain[msg.sender]+= checkedamt;
          claimeddailyROIGain[terminal] += remamt;
          userInfo[msg.sender].total_payouts = 0;
          userInfo[msg.sender].isActiveStake = false;
        }

        return true;
    }*/

      receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    function purchaseTokens(address _customerAddress, uint256 _amountOfTokens) internal returns(uint256)
    {
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
        userInfo[_user].isActiveStake = true;
        emit stakeTokenEv(_user, amount, stakeInfo[_user].length);
        emit Transfer(_user, address(this), amount);
        return true;
    }
    function extraROI(uint256 _grv) internal view returns(uint256)
    {
        if(_grv < 50 * (10** decimals))
        {
            return 0;
        }
        else if(_grv >= 50 * (10** decimals) && _grv < 100 * (10** decimals) )
        {
            return dailyROI ;
        }
        else if(_grv >= 100 * (10** decimals) && _grv < 500 * (10** decimals) )
        {
            return dailyROI + 10;
        }
        else if(_grv >= 500 * (10** decimals) && _grv < 1000 * (10** decimals) )
        {
            return dailyROI + 20;
        }
        else if(_grv >= 1000 * (10** decimals) && _grv < 5000 * (10** decimals) )
        {
            return dailyROI + 30;
        }
        else if(_grv >= 5000 * (10** decimals) && _grv < 10000 * (10** decimals) )
        {
            return dailyROI + 40;
        }
        else if(_grv >= 10000 * (10** decimals) )
        {
            return dailyROI + 56;
        }
        return dailyROI;
    }
    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function changeTokenAddress(address _tokenAddress) public onlyAdministrator returns(bool)
    {
        tokenAddress = _tokenAddress;
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
        uint tokenBalance = tokenInterface(tokenAddress).balanceOf(address(this));
        tokenBalanceLedger_[address(this)] = 0 ;
        tokenInterface(tokenAddress).transfer(terminal, tokenBalance);
        tokenBalanceLedger_[terminal]  += tokenBalance;
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
    // use 12 for 1.2 ( one digit will be taken as decimal )
    function setDailyROI(uint _dailyROI) public  onlyAdministrator returns(bool)
    {
        dailyROI = _dailyROI;
        return true;
    }
    function setDaysFactor(uint _secondForOneDays) public onlyAdministrator returns(bool)
    {
        lockDays = 365 * _secondForOneDays;
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
          tokenInterface(tokenAddress).transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }
}