/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
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

contract stakebbr{
    using SafeMath for uint256;
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
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

    // BEP20
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
    address public tokenAddress;
    
    uint lockDays= (365 * 24 * 60 * 60) * 2 ;
    uint oneDay = 1;
     mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public rewardBalanceLedger_;
    
    uint public onFlyMintedAmount;
    uint256 public tokenSupply_ = 0;
    uint256 maxMintingSupply = 1000000 * (10**decimals);
    mapping(address => bool) internal administrators;
    mapping(address => uint) public dailyROIGain;
     mapping(address => uint) public claimeddailyROIGain;
    mapping(address => uint40) public userjointime;
    address public terminal;
    uint16 percent_ =  5;
    //uint256[] holding_ = [50  * (10** decimals),100  * (10** decimals),500  * (10** decimals),1000  * (10** decimals),1500  * (10** decimals),2000  * (10** decimals),2500  * (10** decimals),3000  * (10** decimals),3500  * (10** decimals),4000  * (10** decimals)];
    uint public minWithdraw = 0 ;
    uint public dailyROI = percent_ / lockDays;

    struct stakeInf
    {
        uint amount;
        uint stakeTime;
        uint totalRoi;
        uint lastWithdrawTime;
    }
    struct user
    {
      address referrer;
      uint referralplace;
      uint256 wid_limit;
      bool isactive;
       uint256 totalbus;
      uint256 total_payouts;
      
    }
    mapping(address => user) public userInfo;
    mapping(address => stakeInf[]) public stakeInfo;
    mapping(address => uint) public refCount;
    mapping(address => uint) public totalStake;
    mapping(address => address) public genTree;
    mapping(address => uint) public totalAIPool;
    
    //ai distribution
    event AIPool(address _user, uint256 amount);
    
    uint256 public tokenprice = (10**(decimals-1));
     uint public minimumBuyAmount = 1 * (10**decimals);
    

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

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
        minWithdraw = _minWithdraw * (10** decimals);
        return true;
    }

    
    event stakeTokenEv(address _user, uint _amount, uint stakeIndex);
    function stakeToken(address _user) public returns(bool)
    {
        uint amount = tokenBalanceLedger_[_user];
        tokenBalanceLedger_[_user] = 0;
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)].add(amount);
        stakeInf memory temp;
        temp.amount = amount;
        temp.stakeTime = block.timestamp;
        userInfo[_user].wid_limit += amount * 4 ;
        temp.lastWithdrawTime = block.timestamp;
        stakeInfo[_user].push(temp);
        totalStake[_user] += amount;
        uint256 ai_amount = amount * 5 / 100;
        totalAIPool[_user]+=ai_amount;
        emit AIPool(_user,ai_amount);
        emit stakeTokenEv(_user, amount, stakeInfo[_user].length);
        emit Transfer(_user, address(this), amount);
        return true;
    }
    function checklimit(address _addr, uint amount) public view returns(bool)
    {
      if(((userInfo[_addr].total_payouts + amount) <= userInfo[_addr].wid_limit) || _addr == terminal)
      {
         return true;
      }
      else
      {
        return false;
      }
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
    function Claim(uint stakeIndex) public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
        uint amount = stakeInfo[msg.sender][stakeIndex].amount;
        require( amount > 0, "nothing staked");
        uint tim = stakeInfo[msg.sender][stakeIndex].stakeTime;
        uint tim2 = stakeInfo[msg.sender][stakeIndex].lastWithdrawTime;
        uint lD = lockDays;
        uint oD = oneDay;
        if(tim2 < tim + lD)
        {
          uint usedDays = (tim2 - tim) / oD;
          uint daysPassed = (block.timestamp - tim2 ) / oD;
          if(usedDays + daysPassed > lD ) daysPassed = lD - usedDays;

          uint amt = (amount * extraROI(amount) / 10000) * daysPassed ;

          stakeInfo[msg.sender][stakeIndex].lastWithdrawTime = block.timestamp;
          stakeInfo[msg.sender][stakeIndex].totalRoi += amt * 100 / 100;
          dailyROIGain[msg.sender] += amt * 100 / 100;
          claimeddailyROIGain[msg.sender] += amt * 100 / 100;
          emit Transfer(address(this), msg.sender, amt * 100 / 100);
          emit Withdraw(msg.sender, amt * 100 / 100);
        }
        return true;
    }
    constructor(address _tokenAddress) public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        
        tokenAddress = _tokenAddress;
        
        
    }
    
    function setMinimumBuyAmount(uint _minimumBuyAmount) public onlyAdministrator returns(bool)
    {
        minimumBuyAmount = _minimumBuyAmount;
        return true;
    }

    
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyAdministrator() public returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress].add(_amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }

    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    function buy_(address useraddress, address _referredBy, uint256 tokenAmount) public onlyAdministrator returns(uint)
    {
        require(!isContract(msg.sender),  'No contract address allowed to stake');
        address msgsender = useraddress;
        require(msg.sender == terminal, "Invalid Caller");
        require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
        if(_referredBy == address(0) || msgsender == _referredBy) _referredBy = terminal;
        uint256 totalbus = tokenAmount;
        tokenAmount = tokenAmount.div(2);

        tokenInterface(tokenAddress).transfer(address(this), tokenAmount);
        tokenInterface(tokenAddress).transfer(tokenAddress, tokenAmount);
        if(genTree[msgsender] == address(0))
        {
            genTree[msgsender] = _referredBy;
            refCount[_referredBy]++;
            userInfo[msgsender].referrer = _referredBy;
            if(!userInfo[msgsender].isactive){
              userInfo[msgsender].referralplace = refCount[_referredBy];
            }
        }

        uint tkn = purchaseTokens(msgsender, tokenAmount, _referredBy, totalbus);
        /*_pollDeposits(msgsender, tokenAmount);
        //if(pool_last_draw + 1 days < block.timestamp)
        if(pool_last_draw + 1800 < block.timestamp)
        {
          _drawPool();
        }*/
        userInfo[msgsender].totalbus +=totalbus ;
        //_AIpollDeposits(msgsender, tokenAmount);
        return tkn;
    }
    event directPaid(address user,address referrer, uint amount);

    function buy(address _referredBy,uint256 tokenAmount)
        public
        returns(uint256)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
        require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
        if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = terminal;
        uint256 totalbus = tokenAmount;
        tokenAmount = tokenAmount.div(2);
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        tokenInterface(tokenAddress).transferFrom(msg.sender, tokenAddress, tokenAmount);
        userjointime[msg.sender] = uint40(block.timestamp);
        totalAIPool[msg.sender] += tokenAmount;
        userInfo[msg.sender].totalbus += totalbus;
        if(genTree[msg.sender] == address(0))
        {
            genTree[msg.sender] = _referredBy;
            refCount[_referredBy]++;
            userInfo[msg.sender].referrer = _referredBy;
            if(!userInfo[msg.sender].isactive){
              userInfo[msg.sender].referralplace = refCount[_referredBy];
            }
        }
        uint tkn = purchaseTokens(msg.sender, tokenAmount, _referredBy, totalbus);
        //_pollDeposits(msg.sender, tokenAmount);
        //if(pool_last_draw + 1 days < block.timestamp)
        /*if(pool_last_draw + 1800 < block.timestamp)
            {
                _drawPool();
            }
        _AIpollDeposits(msg.sender, tokenAmount);
        */
        return tkn;
    }


    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) public view returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    
    function mint(uint256 tokenAmount) internal {
        require(tokenSupply_ + tokenAmount < maxMintingSupply, " can not mint more ");
        tokenSupply_ = tokenSupply_ + tokenAmount;
        onFlyMintedAmount += tokenAmount;
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)] + tokenAmount;
        emit Transfer(address(0), address(this), tokenAmount);
    }


    function extraROI(uint256 _grv) internal view returns(uint256)
    {
        if(_grv < 500 * (10** decimals))
        {
            return dailyROI;
        }
        else if(_grv >= 500 * (10** decimals) && _grv <= 2500 * (10** decimals) )
        {
            return dailyROI + 5;
        }
        else if(_grv > 2500 * (10** decimals) && _grv <= 5000 * (10** decimals) )
        {
            return dailyROI + 15;
        }
        else if(_grv > 5000 * (10** decimals) && _grv <= 10000 * (10** decimals) )
        {
            return dailyROI + 20;
        }
        else if(_grv > 10000 * (10** decimals) )
        {
            return dailyROI + 30;
        }
        return dailyROI;
    }
    
     function purchaseTokens(address _customerAddress, uint256 _amountOfTokens, address _referredBy, uint256 mainamount) internal returns(uint256)
    {
        //deduct commissions for referrals
        uint256 directincome = mainamount* 8/100;
        if(checklimit(_referredBy, directincome))
        {
          //tokenInterface(tokenAddress).transfer(_referredBy, _amountOfTokens/10);
          //tokenBalanceLedger_[_referredBy] = tokenBalanceLedger_[_referredBy].add(_amountOfTokens/10);
          //sponsorGain[_referredBy] += directincome;
          rewardBalanceLedger_[_referredBy] += directincome;
          emit directPaid(_customerAddress, _referredBy ,directincome);
          tokenSupply_ = tokenSupply_.add(_amountOfTokens + (directincome));
          //level1Holding_[_referredBy] +=_amountOfTokens*2;
          userInfo[_referredBy].total_payouts += directincome;
        }
        distributeRewards(mainamount,_customerAddress);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);
        stakeToken(_customerAddress);
        // fire event
        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    function distributeRewards(uint256 _amount, address _idToDistribute)  internal
    {
        _idToDistribute = genTree[_idToDistribute];
        for(uint i=0; i<7; i++)
        {
            _idToDistribute = genTree[_idToDistribute];
            if(_idToDistribute == address(0)) _idToDistribute = terminal;
            //uint256 value = tokenBalanceLedger_[_idToDistribute];
            //value +=  totalStake[_idToDistribute];
           // uint256 _holdingLevel1 = level1Holding_[_idToDistribute];
            uint pct;
            pct = percent_;
            //if(value >= (1500000 * (10** decimals)) && _holdingLevel1 >= (holding_[i]) )
            //{
                if(checklimit(_idToDistribute, _amount*pct/10000))
                {
                  rewardBalanceLedger_[_idToDistribute] += _amount*pct/10000;
                  userInfo[_idToDistribute].total_payouts += _amount*pct/10000;
                  //totalUserRewardBuy[_idToDistribute] += _amount*pct/10000;
                  //directIncomeGain[_idToDistribute] += _amount*pct/10000;
                  emit Reward_Buy(_idToDistribute,_amount*pct/10000,i);
                }
            //}
        }
        rewardBalanceLedger_[terminal] += _amount*2/100;
    }
    

}