pragma solidity ~0.4.19;
/**+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            abcLotto: a Block Chain Lottery

                            Don&#39;t trust anyone but the CODE!
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/**
 * @title SafeMath : it&#39;s from openzeppelin.
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Subtracts two 32 bit numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub_32(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  /**
  * @dev Adds two 32 bit numbers, throws on overflow.
  */
  function add_32(uint32 a, uint32 b) internal pure returns (uint32 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
* @title abcLotto : data structure, bet and reward functions.
* @dev a decentralized lottery application. 
 */ 
 contract abcLotto{
     using SafeMath for *;
     
     //global varibles
     address owner;
     address public controller;

     uint32 public currentRound;   //current bet round, plus 1 every day;
     uint8 public currentState; //1 - bet period, 2 - freeze period, 3 - draw period.
     uint32[] public amounts;	//bet amount per round.
     uint32[] public bets;	//bet numbers per round.
     uint32[] public addrs; //bet addresses per round.
     bool[] public drawed;    //lottery draw finished mark.
     
     uint public rollover = 0;
     uint[] public rolloverUsed;
     
     uint public abcGasConsume = 50; //this abc Dapp cost, default 50/1000 gas price.
     uint public abcIncome = 0;
     
     //constant
     uint constant SINGLE_BET_PRICE = 50000000000000000;    // single bet price is 0.05 ether
     uint constant THISDAPP_DIV = 1000;
     uint constant POOL_ALLOCATION_WEEK = 500;
     uint constant POOL_ALLOCATION_FIRST = 618;       //pool allocation to first prize.
     uint32 constant MAX_BET_AMOUNT = 20;   //per address can bet amount must be less than 20 per round.
     uint8 constant MAX_BET_NUM = 9;
     uint8 constant MIN_BET_NUM = 1;
     uint8 constant FIRST_PRIZE = 1;     //first prize.
     uint8 constant SECOND_PRIZE = 2;    //second prize.

     //data structures
     struct UnitBet{
         uint32 _amount;
         uint8[4] _nums;
		 bool _payed1;  //daily
         bool _payed2;  //weekly
     }
     
     struct AddrBets{
         UnitBet[] _unitBets;
     }    
     
     struct RoundBets{
         mapping (address=>AddrBets) _roundBets;
     }
     RoundBets[] allBets;
     
     struct BetStat{
	     uint32 amount;
	     uint8 prize;   //1 - first prize, 2 - second prize;
     }
     
     struct BetKeyEntity{
         mapping (bytes4=>BetStat) _entity;
     }     
     BetKeyEntity[] betDaily;
     BetKeyEntity[] betWeekly;

     struct Jackpot{
	     uint8[4] _results;
	     uint32	amountFirst;
	     uint32	amountSecond;
     }
     Jackpot[] dailyJackpot;
     Jackpot[] weeklyJackpot;
     
     //events
     event OnBet(address user, uint32 round, uint32 index, uint32 amount, uint8[4] nums);
     event OnRewardDaily(address user, uint32 round, uint32 index, uint8 prize, uint amount);
     event OnRewardWeekly(address user, uint32 round, uint32 index, uint8 prize, uint amount);
     event OnRewardFailed(address user, uint32 round, uint32 index);
     event OnNewRound(uint32 round);
     event OnFreeze(uint32 round);
     event OnUnFreeze(uint32 round);
     event OnDrawStart(uint32 round);
     event OnDrawFinished(uint32 round, uint8[4] jackpot);
     event BalanceNotEnough();
 
      //modifier
     modifier onlyOwner {
         require(msg.sender == owner);
         _;
     }

     modifier onlyController {
         require(msg.sender == controller);
         _;
     }     
     modifier onlyBetPeriod {
         require(currentState == 1);
         _;
     }
     
     /**
     * @dev constructor
     */
     function abcLotto() public payable{
         owner = msg.sender;
     }
     
     /**
     * @dev fallback funtion, the contract don&#39;t accept ether.
     */
     function() public payable { 
         revert();
     }
     
     //+++++++++++++++++++++++++                  public functions               +++++++++++++++++++++++++++++++++++++
     //operation functions
    /**
    * @dev bet: a new bet.
     */
    function bet(uint32 amount, uint8[4] nums) 
        public
        payable
        onlyBetPeriod
        returns (uint)
     {
         //check number range 1-9, no repeat number.
         if(!isValidBet(nums)) revert();
         //doesn&#39;t offer enough value ?
         if(msg.value < SINGLE_BET_PRICE.mul(amount)) revert();
         
         //check daily amount is less than MAX_BET_AMOUNT
         uint32 _am = 0;
         for(uint i=0; i<allBets[currentRound-1]._roundBets[msg.sender]._unitBets.length; i++){
             _am += allBets[currentRound-1]._roundBets[msg.sender]._unitBets[i]._amount;
         }
      
         if( _am.add_32(amount) > MAX_BET_AMOUNT) revert();
         
         //update global varibles.
         amounts[currentRound-1] = amount.add_32(amounts[currentRound-1]);
         bets[currentRound-1]++;
         if(allBets[currentRound-1]._roundBets[msg.sender]._unitBets.length <= 0)
            addrs[currentRound-1]++;
            
         //insert bet record.
         UnitBet memory _bet;
         _bet._amount = amount;
         _bet._nums = nums;
         _bet._payed1 = false;
         _bet._payed2 = false;
         allBets[currentRound-1]._roundBets[msg.sender]._unitBets.push(_bet);
         
         //increase key-map records.
         bytes4 _key;
         _key = generateCombinationKey(nums);
         betDaily[currentRound-1]._entity[_key].amount = amount.add_32(betDaily[currentRound-1]._entity[_key].amount);
         _key = generatePermutationKey(nums);
         uint32 week = (currentRound-1) / 7;
         betWeekly[week]._entity[_key].amount = amount.add_32(betWeekly[week]._entity[_key].amount);
         
         //refund extra value.
         if(msg.value > SINGLE_BET_PRICE.mul(amount)){
             msg.sender.transfer( msg.value.sub( SINGLE_BET_PRICE.mul(amount)));
         }
         //emit event
         OnBet(msg.sender, currentRound, uint32(allBets[currentRound-1]._roundBets[msg.sender]._unitBets.length), amount, nums);
         return allBets[currentRound-1]._roundBets[msg.sender]._unitBets.length;
     }

     /**
     * @dev rewardDaily: apply for daily reward.
     */     
     function rewardDaily(uint32 round, uint32 index) public onlyBetPeriod returns(uint) {
         require(round>0 && round<=currentRound);
         require(drawed[round-1]);
         require(index>0 && index<=allBets[round-1]._roundBets[msg.sender]._unitBets.length);
         require(!allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed1);

         uint8[4] memory nums = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._nums;
         bytes4 key = generateCombinationKey(nums);
         uint8 prize = betDaily[round-1]._entity[key].prize;
         if(prize == 0) return;

         uint32 _self = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._amount;
         uint32 win_amount = betDaily[round-1]._entity[key].amount;
         uint32 amount = amounts[round-1];
         
         uint pay = 0;
         uint total = 0;
         total =  SINGLE_BET_PRICE.mul(amount);
         total =  total.mul(THISDAPP_DIV - POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
         if(prize == FIRST_PRIZE)
             total =  total.mul(POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
         else
             total =  total.mul(THISDAPP_DIV - POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
             
         total =  (total / win_amount).mul(_self);
         pay =  total.mul(THISDAPP_DIV - abcGasConsume) / THISDAPP_DIV;
         abcIncome = abcIncome.add(total - pay);

         //pay action
         if(pay > address(this).balance){
             BalanceNotEnough();
             return;             
         }
         allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed1 = true;
         if(!msg.sender.send(pay)){
             OnRewardFailed(msg.sender, round, index);
             revert();
         }
         
         OnRewardDaily(msg.sender, round, index, prize, pay);
         return pay;
     }      
     
     /**
     * @dev rewardWeekly: apply for weekly reward.
      */
     function rewardWeekly(uint32 round, uint32 index) public onlyBetPeriod returns(uint) {
         require(round>0 && round<=currentRound);
         require(drawed[round-1]);
         require(index>0 && index<=allBets[round-1]._roundBets[msg.sender]._unitBets.length);
         require(!allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed2);

         uint32 week = (round-1)/7 + 1;
         uint8[4] memory nums = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._nums;
         bytes4 key = generatePermutationKey(nums);
         uint8 prize = betWeekly[week-1]._entity[key].prize;
         if(prize == 0) return;     

         uint32 _self = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._amount;
         uint32 win_amount = betWeekly[week-1]._entity[key].amount;
         uint32 amount = getAmountWeekly(week);

         uint pay = 0;
         uint total = 0;
         total =  SINGLE_BET_PRICE.mul(amount);
         total =  total.mul(POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
         if(prize == FIRST_PRIZE){
             total =  total.mul(POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
             total = total.add(rolloverUsed[week - 1]);
         }
         else
             total =  total.mul(THISDAPP_DIV - POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
             
         total =  (total / win_amount).mul(_self);
         pay =  total.mul(THISDAPP_DIV - abcGasConsume) / THISDAPP_DIV;
         abcIncome = abcIncome.add(total - pay);

         //pay action
         if(pay > address(this).balance){
             BalanceNotEnough();
             return;             
         }
         allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed2 = true;
         if(!msg.sender.send(pay)){
             OnRewardFailed(msg.sender, round, index);
             revert();
         }
         
         OnRewardWeekly(msg.sender, round, index, prize, pay);
         return pay;
     }

     //pure or view funtions
     /**
     * @dev getSingleBet: get self&#39;s bet record.
      */
    function getSingleBet(uint32 round, uint32 index) public view returns(uint32 amount, uint8[4] nums, bool payed1, bool payed2)
     {
         if(round == 0 || round > currentRound) return;

         uint32 iLen = uint32(allBets[round-1]._roundBets[msg.sender]._unitBets.length);
         if(iLen <= 0) return;
         if(index == 0 || index > iLen) return;
         
         amount = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._amount;
         nums = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._nums;
         payed1 = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed1;
         payed2 = allBets[round-1]._roundBets[msg.sender]._unitBets[index-1]._payed2;
     }
     /**
     * @dev getAmountDailybyNum: get the daily bet amount of a set of numbers.
      */
     function getAmountDailybyNum(uint32 round, uint8[4] nums) public view returns(uint32){
         if(round == 0 || round > currentRound) return 0;       
         bytes4 _key = generateCombinationKey(nums);
         
         return betDaily[round-1]._entity[_key].amount;
     }

     /**
     * @dev getAmountWeeklybyNum: get the weekly bet amount of a set of numbers.
      */     
     function getAmountWeeklybyNum(uint32 week, uint8[4] nums) public view returns(uint32){
         if(week == 0 || currentRound < (week-1)*7) return 0;
         
         bytes4 _key = generatePermutationKey(nums);
         return betWeekly[week-1]._entity[_key].amount;
     }
     
     /**
     * @dev getDailyJackpot: some day&#39;s Jackpot.
      */
     function getDailyJackpot(uint32 round) public view returns(uint8[4] jackpot, uint32 first, uint32 second){
         if(round == 0 || round > currentRound) return;
         jackpot = dailyJackpot[round-1]._results;
         first = dailyJackpot[round-1].amountFirst;
         second = dailyJackpot[round-1].amountSecond;
     }

     /**
     * @dev getWeeklyJackpot: some week&#39;s Jackpot.
      */
     function getWeeklyJackpot(uint32 week) public view returns(uint8[4] jackpot, uint32 first, uint32 second){
         if(week == 0 || week > currentRound/7) return;
         jackpot = weeklyJackpot[week - 1]._results;
         first = weeklyJackpot[week - 1].amountFirst;
         second = weeklyJackpot[week - 1].amountSecond;
     }

     //+++++++++++++++++++++++++                  authorized functions               +++++++++++++++++++++++++++++++++++++
     /**
      * @dev start new round.
     */ 
    function nextRound() onlyController public {
         //current round must be drawed.
         if(currentRound > 0)
            require(drawed[currentRound-1]);
         
         currentRound++;
         currentState = 1;
         
         amounts.length++;
         bets.length++;
         addrs.length++;
         drawed.length++;
         
         RoundBets memory _rb;
         allBets.push(_rb);
         
         BetKeyEntity memory _en1;
         betDaily.push(_en1);
         
         Jackpot memory _b1;
         dailyJackpot.push(_b1);
         //if is a weekend or beginning.
         if((currentRound-1) % 7 == 0){
             BetKeyEntity memory _en2;
             betWeekly.push(_en2);
             Jackpot memory _b2;
             weeklyJackpot.push(_b2);
             rolloverUsed.length++;
         }
         OnNewRound(currentRound);
     }

    /**
    * @dev freeze: enter freeze period.
     */
    function freeze() onlyController public {
        currentState = 2;
        OnFreeze(currentRound);
    }

    /**
    * @dev freeze: enter freeze period.
     */
    function unfreeze() onlyController public {
        require(currentState == 2);
        currentState = 1;
        OnUnFreeze(currentRound);
    }
    
    /**
    * @dev draw: enter freeze period.
     */
    function draw() onlyController public {
        require(!drawed[currentRound-1]);
        currentState = 3;
        OnDrawStart(currentRound);
    }

    /**
    * @dev controller have generated and set Jackpot.
     */
    function setJackpot(uint8[4] jackpot) onlyController public {
        require(!drawed[currentRound-1]);
        //check jackpot range 1-9, no repeat number.
        if(!isValidBet(jackpot)) return;
        
        uint8 i;
        uint32 _sum = 0;
        bytes4 _first;
        bytes4[20] memory _second1;
        bytes4[10] memory _second2;
        bytes4 _b;
        uint temp;

        //mark daily entity&#39;s prize.-----------------------------------------------------------------------------------
        uint8[4] memory _jackpot1 = sort(jackpot);
        dailyJackpot[currentRound-1]._results = _jackpot1;

        _first = generateCombinationKey(_jackpot1);
        _second1 = genDailySecondPrizeKey(_jackpot1);
        
        //mark secondary prize.
        for(i=0; i<20; i++){
            _b = _second1[i];
            betDaily[currentRound-1]._entity[_b].prize = SECOND_PRIZE; 
            _sum += betDaily[currentRound-1]._entity[_b].amount;
        }
        if(_sum == 0){
            temp = SINGLE_BET_PRICE.mul(amounts[currentRound-1]);
            temp = temp.mul(THISDAPP_DIV - POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
            temp = temp.mul(THISDAPP_DIV - POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
            rollover = rollover.add(temp); 
        }
        else{
            dailyJackpot[currentRound-1].amountSecond = _sum;
        }

        //mark first prize.
        betDaily[currentRound-1]._entity[_first].prize = FIRST_PRIZE; 
        if(betDaily[currentRound-1]._entity[_first].amount > 0){
            dailyJackpot[currentRound-1].amountFirst = betDaily[currentRound-1]._entity[_first].amount;
        }
        else{
            temp = SINGLE_BET_PRICE.mul(amounts[currentRound-1]);
            temp = temp.mul(THISDAPP_DIV - POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
            temp = temp.mul(POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
            rollover = rollover.add(temp);
        }
         //end mark.-----------------------------------------------------------------------------------


        //mark weekly entity&#39;s prize.---------------------------------------------------------------------------------------
        if((currentRound > 0) && (currentRound % 7 == 0)){
            uint32 _week = currentRound/7;
            weeklyJackpot[_week-1]._results = jackpot;

            _sum = 0;
            _first = generatePermutationKey(jackpot);
            _second2 = genWeeklySecondPrizeKey(jackpot);
            uint32 amounts_;

            //mark secondary prize
            for(i=0; i<10; i++){
                _b = _second2[i];
                betWeekly[_week-1]._entity[_b].prize = SECOND_PRIZE;
                _sum += betWeekly[_week-1]._entity[_b].amount;
            }
            if(_sum == 0){
                amounts_ = getAmountWeekly(_week);
                temp = SINGLE_BET_PRICE.mul(amounts_);
                temp = temp.mul(POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
                temp = temp.mul(THISDAPP_DIV - POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
                rollover = rollover.add(temp);
            }
            else{
                weeklyJackpot[_week-1].amountSecond = _sum;
            }

            //mark first prize.
            betWeekly[_week-1]._entity[_first].prize = FIRST_PRIZE;
            if(betWeekly[_week-1]._entity[_first].amount > 0){
                rolloverUsed[_week-1] = rollover.sub(1000000000);
                rollover = 1000000000;   //keep rollover 1 gwei to next round. can&#39;t be reset to 0.
                weeklyJackpot[_week-1].amountFirst = betWeekly[_week-1]._entity[_first].amount;
            }
            else{
                amounts_ = getAmountWeekly(_week);
                temp = SINGLE_BET_PRICE.mul(amounts_);
                temp = temp.mul(POOL_ALLOCATION_WEEK) / THISDAPP_DIV;
                temp = temp.mul(POOL_ALLOCATION_FIRST) / THISDAPP_DIV;
                rollover = rollover.add(temp); 
            }        
        }
        //end mark.-----------------------------------------------------------------------------------
        drawed[currentRound-1] = true;
        OnDrawFinished(currentRound, jackpot);
    }

     /**
      * @dev set new owner      
      * @param newOwner The address to transfer ownership to.
      */
      function setNewOwner(address newOwner) public onlyOwner{
          require(newOwner != address(0x0));
          owner = newOwner;
      }
     /**
      * @dev set state controller
      * @param addr new state controller contract address.
      */
      function setController(address addr) public onlyOwner{
          require(addr != address(0x0));
          controller = addr;
      }
     /**
     * @dev set new gas consume.
      */
      function setGasConsume(uint consume) public onlyOwner{
          abcGasConsume = consume;
      }
      /**
      * @dev transfer abcIncome to a wallet.
      */     
      function transferIncome(address to, uint amount) public onlyOwner{
         require(amount < address(this).balance);
         require(amount < abcIncome);
         abcIncome = abcIncome.sub(amount);
         if(!to.send(amount))
            revert();
      }
     //+++++++++++++++++++++++++                  internal functions               +++++++++++++++++++++++++++++++++++++
     /**
     * @dev check if is a valid set of number.
     * @param nums : chosen number.
     */
     function isValidBet(uint8[4] nums) internal pure returns(bool){
         for(uint i = 0; i<4; i++){
             if(nums[i] < MIN_BET_NUM || nums[i] > MAX_BET_NUM) 
                return false;
         }
         if(hasRepeat(nums)) return false;
         
         return true;
    }
    
     /**
     * @dev sort 4 bet numbers.
     *      we don&#39;t want to change input numbers sequence, so copy it at first.
     * @param nums : input numbers.
     */
    function sort(uint8[4] nums) internal pure returns(uint8[4]){
        uint8[4] memory _nums;
        uint8 i;
        for(i=0;i<4;i++)
            _nums[i] = nums[i];
            
        uint8 j;
        uint8 temp;
        for(i =0; i<4-1; i++){
            for(j=0; j<4-i-1;j++){
                if(_nums[j]>_nums[j+1]){
                    temp = _nums[j];
                    _nums[j] = _nums[j+1];
                    _nums[j+1] = temp;
                }
            }
        }
        return _nums;
    }
    
    /**
     * @dev does has repeat number?
     * @param nums : input numbers.
     */
    function hasRepeat(uint8[4] nums) internal pure returns(bool){
         uint8 i;
         uint8 j;
         for(i =0; i<4-1; i++){
             for(j=i; j<4-1;j++){
                 if(nums[i]==nums[j+1]) return true;
             }
         }
        return false;       
    }
    
    /**
     * @dev generate Combination key, need sort at first.
     */ 
    function generateCombinationKey(uint8[4] nums) internal pure returns(bytes4){
        uint8[4] memory temp = sort(nums);
        bytes4 ret;
        ret = (ret | byte(temp[3])) >> 8;
        ret = (ret | byte(temp[2])) >> 8;
        ret = (ret | byte(temp[1])) >> 8;
        ret = ret | byte(temp[0]);
        
        return ret; 
    }
    
    /**
     * @dev generate Permutation key.
     */ 
    function generatePermutationKey(uint8[4] nums) internal pure returns(bytes4){
        bytes4 ret;
        ret = (ret | byte(nums[3])) >> 8;
        ret = (ret | byte(nums[2])) >> 8;
        ret = (ret | byte(nums[1])) >> 8;
        ret = ret | byte(nums[0]);
        
        return ret;         
    }

    /**
     * @dev generate daily secondary prize key.
     */ 
    function genDailySecondPrizeKey(uint8[4] nums) internal pure returns(bytes4[20]){
        uint8[5] memory _others = generateOtherNums(nums);
        bytes4[20] memory ret;
        uint8 i;
        uint8 j;
        uint8 _index = 0;
        uint8[4] memory _nums;
        
        for(i=0; i<4; i++){
            for(j=0; j<4; j++)
                _nums[j] = nums[j];
                
            for(j=0; j<5; j++){
                _nums[i] = _others[j];
                ret[_index++] = generateCombinationKey(_nums);
            }
        }
        return ret;
    }

     /**
     * @dev generate weekly secondary prize key.
     */    
    function genWeeklySecondPrizeKey(uint8[4] nums) internal pure returns(bytes4[10]){
        uint8[5] memory _others = generateOtherNums(nums);
        bytes4[10] memory ret;
        uint8 i;
        uint8 _index = 0;
        uint8[4] memory _nums;
        
        //replace first number;
        for(i=0; i<4; i++)
            _nums[i] = nums[i];
        for(i=0; i<5; i++){
            _nums[0] = _others[i];
            ret[_index++] = generatePermutationKey(_nums);
        }
        //replace last number;
        for(i=0; i<4; i++)
            _nums[i] = nums[i];
        for(i=0; i<5; i++){
            _nums[3] = _others[i];
            ret[_index++] = generatePermutationKey(_nums);
        }
        
        return ret;
    }

    /**
     * @dev find other 5 numbers.
     */ 
    function generateOtherNums(uint8[4] nums) internal pure returns(uint8[5]){
        uint8 _index = 0;
        uint8 i;
        uint8 j;
        uint8[5] memory ret;
        for(i=1; i<=9; i++){
            if(_index >= 5) break;
            bool _exist = false;
            for(j=0; j<4; j++){
                if(i==nums[j])
                    _exist = true;
            }
            if(!_exist){
                ret[_index] = i;
                _index++;
            }
        }
        return ret;
    }   
     
     /**
     * @dev getAmountWeekly: the bet amount of a week.
      */
     function getAmountWeekly(uint32 week) internal view returns(uint32){
         if(week == 0 || currentRound < (week-1)*7) return 0;

         uint32 _ret;
         uint8 i;
         if(currentRound > week*7){
             for(i=0; i<7; i++){
                 _ret += amounts[(week-1)*7+i];
             }
         }
         else{
             uint8 j = uint8((currentRound-1) % 7);
             for(i=0;i<=j;i++){
                 _ret += amounts[(week-1)*7+i];
             }
         }
         return _ret;
     }
 }