/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

// ----------------------------------------------------------------------------
// 'HAPPYHOUR' Staking smart contract
//
// Enter our universe : cocktailbar.finance
//
// Come join the disscussion: https://t.me/cocktailbar_discussion
//
//                                          Sincerely, Mr. Martini
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------

/**
* @dev Wrappers over Solidity's arithmetic operations with added overflow
* checks.
*
* Arithmetic operations in Solidity wrap on overflow. This can easily result
* in bugs, because programmers usually assume that an overflow raises an
* error, which is the standard behavior in high level programming languages.
* `SafeMath` restores this intuition by reverting the transaction when an
* operation overflows.
*
* Using this library instead of the unchecked operations eliminates an entire
* class of bugs, so it's recommended to use it always.
*/
library SafeMath {
   /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
    */
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");

       return c;
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return sub(a, b, "SafeMath: subtraction overflow");
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b <= a, errorMessage);
       uint256 c = a - b;

       return c;
   }

   /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    *
    * - Multiplication cannot overflow.
    */
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
       // benefit is lost if 'b' is also tested.
       // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
       if (a == 0) {
           return 0;
       }

       uint256 c = a * b;
       require(c / a == b, "SafeMath: multiplication overflow");

       return c;
   }


   /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       return div(a, b, "SafeMath: division by zero");
   }

   /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b > 0, errorMessage);
       uint256 c = a / b;
       // assert(a == b * c + a % b); // There is no case in which this doesn't hold

       return c;
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return mod(a, b, "SafeMath: modulo by zero");
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
       require(b != 0, errorMessage);
       return a % b;
   }

   function ceil(uint a, uint m) internal pure returns (uint r) {
       return (a + m - 1) / m * m;
   }

}

contract ReentrancyGuard {
   bool private _notEntered;

   constructor () {
       // Storing an initial non-zero value makes deployment a bit more
       // expensive, but in exchange the refund on every call to nonReentrant
       // will be lower in amount. Since refunds are capped to a percetange of
       // the total transaction's gas, it is best to keep them low in cases
       // like this one, to increase the likelihood of the full refund coming
       // into effect.
       _notEntered = true;
   }

   /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * Calling a `nonReentrant` function from another `nonReentrant`
    * function is not supported. It is possible to prevent this from happening
    * by making the `nonReentrant` function external, and make it call a
    * `private` function that does the actual work.
    */
   modifier nonReentrant() {
       // On the first call to nonReentrant, _notEntered will be true
       require(_notEntered, "ReentrancyGuard: reentrant call");

       // Any calls to nonReentrant after this point will fail
       _notEntered = false;

       _;

       // By storing the original value once again, a refund is triggered (see
       // https://eips.ethereum.org/EIPS/eip-2200)
       _notEntered = true;
   }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------

contract Owned {
   modifier onlyOwner() virtual{
       require(msg.sender==owner);
       _;
   }
   address payable owner;
   address payable newOwner;
   function changeOwner(address payable _newOwner) external onlyOwner {
       require(_newOwner!=address(0));
       newOwner = _newOwner;
   }
   function acceptOwnership() external {
       if (msg.sender==newOwner) {
           owner = newOwner;
       }
   }
}

interface ERC20 {
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function transfer(address _to, uint256 _value) external  returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract Token is Owned, ERC20 {
   using SafeMath for uint256;
   uint256 public totalSupply;
   string public symbol;
   string public name;
   uint8 public decimals;
   mapping (address=>uint256) balances;
   mapping (address=>mapping (address=>uint256)) allowed;
   uint256 public rewardfee;

   event TransferFee(address indexed _from, address indexed _to, uint256 _value);

   function balanceOf(address _owner) view public override   returns (uint256 balance) {return balances[_owner];}

   function transfer(address _to, uint256 _amount) public override  returns (bool success) {
       require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
       balances[msg.sender]-=_amount;


       uint256 fee = onehalfPercent(_amount);
       uint256 amountto = _amount.sub(fee);
       rewardfee = rewardfee.add(fee);

       balances[address(this)]+=fee;
       balances[_to]+=amountto;


       emit Transfer(msg.sender,_to,amountto);
       emit TransferFee(msg.sender,address(this),fee);
       return true;
   }



   function transferFrom(address _from,address _to,uint256 _amount) public override  returns (bool success) {
       require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
       balances[_from]-=_amount;
       allowed[_from][msg.sender]-=_amount;

       uint256 fee = onehalfPercent(_amount);
       uint256 amountto = _amount.sub(fee);


       rewardfee = rewardfee.add(fee);
       balances[address(this)]+=fee;
       balances[_to]+=amountto;


       emit Transfer(msg.sender,_to,amountto);
       emit TransferFee(msg.sender,address(this),fee);
       return true;
   }

   function approve(address _spender, uint256 _amount) public override  returns (bool success) {
       allowed[msg.sender][_spender]=_amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
   }

   function allowance(address _owner, address _spender) view public override  returns (uint256 remaining) {
     return allowed[_owner][_spender];
   }

       function onehalfPercent(uint256 _tokens) private pure returns (uint256){
       uint256 roundValue = _tokens.ceil(100);
       uint onehalfofTokens = roundValue.mul(100).div(100 * 10**uint(2));
       return onehalfofTokens;
   }

}


contract Mojito is Token{
   using SafeMath for uint256;
   constructor() {
       symbol = "MOJITO";
       name = "Mojito";
       decimals = 18;
       totalSupply = 5000000000000000000000;
       owner = msg.sender;
       balances[owner] = totalSupply;

   }

   receive () payable external {
       require(msg.value>0);
       owner.transfer(msg.value);
   }

}

interface REWARDTOKEN {
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   function transfer(address _to, uint256 _amount) external  returns (bool success);
   function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
   function approve(address _to, uint256 _amount) external  returns (bool success);
   function _mint(address account, uint256 amount) external ;

}



// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Stake is Mojito, ReentrancyGuard {
   using SafeMath for uint256;
   address public rewtkn= 0x39FB7AF42ef12D92A0d577ca44cd54a0f24c4915;
   uint256 public totalStakes = 0;
   uint256 stakingFee = 10; // 1%
   uint256 unstakingFee = 30; // 3%
   uint256 public prevreward = 0;
   REWARD  public reward;


   struct REWARD
   {
       uint256 rewardstart;
       uint256 rewardend;
       uint256 totalreward;
   }

   struct USER{
       uint256 stakedTokens;
       uint256 remainder;
       uint256 creationTime;
       uint256 lastClaim;
       uint256 totalEarned;
   }

   mapping(address => USER) public stakers;


   event STAKED(address staker, uint256 tokens, uint256 stakingFee);
   event UNSTAKED(address staker, uint256 tokens, uint256 unstakingFee);

   event CLAIMEDREWARD(address staker, uint256 reward);

     constructor() {
       owner=msg.sender;
       reward = REWARD(block.timestamp,block.timestamp + 24 hours,0);

   }
      modifier onlyOwner() override{
       require(msg.sender==owner,"only owner can run this");
       _;
   }


   // ------------------------------------------------------------------------
   // Token holders can stake their tokens using this function
   // @param tokens number of tokens to stake
   // ------------------------------------------------------------------------
   function STAKE(uint256 tokens) external nonReentrant {
       require(REWARDTOKEN(rewtkn).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
       uint256 _stakingFee = (onePercent(tokens).mul(stakingFee)).div(10);
       reward.totalreward = (reward.totalreward).add(stakingFee);
       stakers[msg.sender].stakedTokens = (tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedTokens);
       stakers[msg.sender].creationTime = block.timestamp;
       totalStakes = totalStakes.add(tokens.sub(_stakingFee));
       emit STAKED(msg.sender, tokens.sub(_stakingFee), _stakingFee);
   }


   // ------------------------------------------------------------------------
   // Stakers can claim their pending rewards using this function
   // ------------------------------------------------------------------------
   // ------------------------------------------------------------------------
   // Stakers can unstake the staked tokens using this function
   // @param tokens the number of tokens to withdraw
   // ------------------------------------------------------------------------
   function WITHDRAW(uint256 tokens) external nonReentrant {

       require(stakers[msg.sender].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");

       uint256 _unstakingFee = (onePercent(tokens).mul(unstakingFee)).div(10);

       // add pending rewards to remainder to be claimed by user later, if there is any existing stake


       reward.totalreward = (reward.totalreward).add(_unstakingFee);
       require(REWARDTOKEN(rewtkn).transfer(msg.sender, tokens.sub(_unstakingFee)), "Error in un-staking tokens");

       stakers[msg.sender].stakedTokens = stakers[msg.sender].stakedTokens.sub(tokens);

       if (stakers[msg.sender].stakedTokens == 0)
       {
           stakers[msg.sender].creationTime = block.timestamp ;
       }
       totalStakes = totalStakes.sub(tokens);
       emit UNSTAKED(msg.sender, tokens.sub(_unstakingFee), _unstakingFee);


   }

   // ------------------------------------------------------------------------
   // Private function to calculate 1% percentage
   // ------------------------------------------------------------------------
   function onePercent(uint256 _tokens) private pure returns (uint256){
       uint256 roundValue = _tokens.ceil(100);
       uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
       return onePercentofTokens;
   }

   // ------------------------------------------------------------------------
   // Get the number of tokens staked by a staker
   // @param _staker the address of the staker
   // ------------------------------------------------------------------------
   function yourStakedREWARDTOKEN(address staker) external view returns(uint256 stakedTOKEN){
       return stakers[staker].stakedTokens;
   }

   // ------------------------------------------------------------------------
   // Get the TOKEN balance of the token holder
   // @param user the address of the token holder
   // ------------------------------------------------------------------------
   function yourREWARDTOKENBalance(address user) external view returns(uint256 TOKENBalance){
       return REWARDTOKEN(rewtkn).balanceOf(user);
   }

   function CurrEsstematedRew(address user) external view returns (uint256 MojitoReward)
   {

       if(stakers[user].stakedTokens >0)
       {

          uint256 time = block.timestamp - reward.rewardstart;
          uint256 hour=time.div(3600);
          uint256 newrewardstarttime=reward.rewardstart;

       while(hour >= 24) //alligning days with outer clock
       {
           newrewardstarttime = newrewardstarttime.add(24 hours) ;
           time = block.timestamp - newrewardstarttime;
           hour=time.div(3600);

       }

         if(stakers[user].lastClaim == newrewardstarttime)
         {
             return 0;
         }else{

           uint256 prevrewards=0;
            if(prevreward == 0 )
           {
               prevrewards = rewardfee;
           }

           uint256 Cstaked = (stakers[user].stakedTokens).mul(10000000000);
           uint256 CTS = totalStakes.mul(10000000000);
           uint256 percent = (Cstaked.mul(prevrewards));
           uint256 rewardcal =  percent.div(CTS);


            if(newrewardstarttime < stakers[user].creationTime) //how mch difference
            {

           time =  stakers[user].creationTime - newrewardstarttime;
           uint256 stketime = time.div(3600);

            if(stketime < 20)
           {
            uint256 a = (stketime.mul(10**uint(2))).div(20);
            uint256 finalreward =  (a.mul(rewardcal)).div(10**uint(2));

            if(rewardfee >= rewardcal)
            {

                return finalreward;
            }else{
                return 0;
            }


           }else
           {
               if(rewardfee >= rewardcal )
               {
                    return rewardcal;
               }
               else
               {
                   return 0;
               }

           }


            }else{
                  if(rewardfee >= rewardcal )
               {
                    return rewardcal;
               }else
               {
                   return 0;
               }

            }




         }






       }else
       {
           return 0;
       }

   }



   function CLAIMREWARD() external  {


       uint256 time = block.timestamp - reward.rewardstart;
       uint256 hour=time.div(3600);



       if(hour >= 24)
       {
           prevreward = 0;
       }
       while(hour >= 24) //alligning days with outer clock
       {
           reward.rewardstart = reward.rewardstart.add(24 hours) ;
           time = block.timestamp - reward.rewardstart;
           hour=time.div(3600);

       }

       require(stakers[msg.sender].lastClaim != reward.rewardstart,"You have Already Claimed");
       {

       //this line is basically  checking which hour is currently user trying to claim (can only claim at hour 20 - 24 )
       time  = (block.timestamp).sub(reward.rewardstart) ;  //now can be greater than rewardend
       uint256 rewhour = time.div(3600);
       if((rewhour < 24) && (rewhour >= 20))  // checking if person is illigebal for reward
       {

           if(prevreward == 0 )
           {
               prevreward = rewardfee;
           }


           //calculating percent of staked tokens user has in the total pool
           uint256 Cstaked = (stakers[msg.sender].stakedTokens).mul(10000000000);
           uint256 CTS = totalStakes.mul(10000000000);
           uint256 percent = (Cstaked.mul(prevreward));
           uint256 rewardcal =  percent.div(CTS);


            if(reward.rewardstart < stakers[msg.sender].creationTime) //how mch difference
            {

           time =  stakers[msg.sender].creationTime - reward.rewardstart;
           uint256 stketime = time.div(3600);

           //checking what was the stake time of the user. User should not get all amount if his stake time is less than 20 hours
           //will change wif we go with starttime

           //checktime
           if(stketime < 20)
           {
            uint256 a = (stketime.mul(10**uint(2))).div(20);
            uint256 finalreward =  (a.mul(rewardcal)).div(10**uint(2));

            if(rewardfee >= rewardcal)
            {
              Mojito(address(this)).transfer(msg.sender,finalreward);
             rewardfee = rewardfee.sub(finalreward);
             stakers[msg.sender].lastClaim = reward.rewardstart;
             stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(finalreward);
             emit CLAIMEDREWARD(msg.sender,finalreward);
            }


           }else
           {
               if(rewardfee >= rewardcal )
               {
                    Mojito(address(this)).transfer(msg.sender,rewardcal);
                      rewardfee = rewardfee.sub(rewardcal);
                       stakers[msg.sender].lastClaim = reward.rewardstart;
                        stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(rewardcal);
                      emit CLAIMEDREWARD(msg.sender,rewardcal);

               }

           }


            }else{
                  if(rewardfee >= rewardcal )
               {
                    Mojito(address(this)).transfer(msg.sender,rewardcal);
                      rewardfee = rewardfee.sub(rewardcal);
                        stakers[msg.sender].lastClaim = reward.rewardstart ;
                           stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(rewardcal);
                     emit CLAIMEDREWARD(msg.sender,rewardcal);

               }

            }



       }

       }

       reward.rewardend = reward.rewardstart + 24 hours;

   }








   function WatchClaimTime() public  view  returns (uint ClaimTimeHours)
   {



       uint256 time  = block.timestamp - reward.rewardstart;
       uint rewhour = time.div(3600);
       return rewhour;


   }



    function WatchClaimTimeMins() public view returns (uint ClaimTimeHours)
   {

           uint256 time  = block.timestamp - reward.rewardstart;
           uint rewhour = time.div(1);
           return rewhour;


   }


}