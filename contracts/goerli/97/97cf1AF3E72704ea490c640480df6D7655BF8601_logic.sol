/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity 0.6.12;

//import"https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
}


contract logic {

    using SafeMath for uint;
    
    /***System Funds***/
    uint public system;
    
    /***Jackpot Funds***/
    uint public jackpot;
    
    /***Total Users***/
    uint public totalUsers = 2;
    
    /***Level & Fees***/
    uint[6] public lvl=[0,30,40,70,100,150];
    
  
    /***Mapping address to a User***/
    mapping(address => user) User;

    

    
    /**
    User struct - defines the properties of the user in the process
     */ 
   struct user {
        uint id;
        uint pendingRewards;
        uint level;
        uint referalCode;
        address referedBy;
        uint referalIndex;
        bool levelEarnings;
    }
    
    
    constructor(address payable _initializer)public{
        user storage head = User[_initializer];
        head.id = 1;
        head.level= 1;
        head.referalIndex = 0;
    }
    
    /** 
    Registeration of the newly refered user
    Here ids,referal code etc., is assigned to the new user*/
    function enter(address _user,address _referer)public{
        // require(amount == 50,"should pay atleast 50");
        
      system += 30;
      
        
      user storage info = User[_user];
     
      totalUsers++;
       
      info.id = totalUsers;
      
      info.referalCode = totalUsers + 1011;
      
      info.referedBy = _referer;
      
      info.referalIndex = 0;
    
      info.pendingRewards = 0;
      //get index from referer refered list
      User[_referer].referalIndex += 1;
      //assigning this user to referer referedlist
      

      info.level = 1;

      User[_user].levelEarnings = false;
      
      
     
      
      totalUsers =totalUsers.add(1);

      //get index from referer refered list
    //   uint index = User[_referer].referalIndex;
      //assigning this user to referer referedlist
    //   User[_referer].referalList[index] = _user;
    
    if(User[_referer].pendingRewards <= 20){
       rewardDistribution_v1(_referer);
    }else{
       
       updatev2(_referer);
        }
    }
    

    function rewardDistribution_v1(address _user)public{
        
        //20*0.98 for referal
        uint reward = 20;
        User[_user].pendingRewards =User[_user].pendingRewards+reward;

        //20*0.02 for jackpot
        // jackpot= jackpot+ (20-reward) ;
       
    }
    
    
    function update(address _referer)public{
        
        user storage refererInfo = User[_referer];
        
        refererInfo.level = 112;
        
     
        if(refererInfo.referalIndex >=3){
            
            refererInfo.levelEarnings = true;
            uint level = refererInfo.level;
            uint checkfactor = 2*((2**level)-1);

            
            if(refererInfo.referalIndex == checkfactor){
               
              levelManager(lvl[refererInfo.level],_referer,refererInfo.pendingRewards);
              rewardDistribution_v2(_referer);
            }else{
                
            /**Carry on the distribution process*/
            rewardDistribution_v2(_referer);   
            
            }
        }
        
    }
    
    //level upgrade
    function levelManager(uint levelfactor,address _user,uint pendingReward)public{
        require(pendingReward >= levelfactor,"refer more");
        user storage userInfo = User[_user];
        //Level 2 Upgradation (deduct)
        //fees
        userInfo.pendingRewards = userInfo.pendingRewards-lvl[userInfo.level];
        system = system - lvl[userInfo.level];
        //Update the level from 1 to 2
        userInfo.level += 1;
        //mission 1 Passed
        // userInfo.levelPassed[identifier] = true;
        //90 levelFactor = 
    }
    
    function activateLevelearnings(address _user) public{
        user storage status = User[_user];
        status.levelEarnings = true;
    }

    function rewardDistribution_v2(address _user)public{
        user storage status = User[_user];
        uint levels = status.level;
        uint rewardAmount = lvl[levels];
        uint ReferalShare = rewardAmount*90/100;
        status.pendingRewards += ReferalShare;
        jackpot = jackpot +rewardAmount*2/100;
        system = system + rewardAmount*3/100;
        if(status.levelEarnings == true){
            status.pendingRewards = status.pendingRewards.add(rewardAmount.mul(5).div(100));
        }  
    }
    
    function getUser(address _user)public view 
    returns(uint id,
            uint pendingRewards,
            uint levels,
            uint referalCode,
            uint referalIndex,
            bool levelEarnings
            ){
                
        user storage g = User[_user];
        id = g.id;
        pendingRewards= g.pendingRewards;
        levels = g.level;
        referalCode = g.referalCode;
        referalIndex = g.referalIndex;
        levelEarnings = g.levelEarnings;
        // levelPassed = g.levelPassed[level];
    }
    
    function updatev2(address _referer)public{
        activateLevelearnings(_referer);
        user storage referer_2= User[_referer];
        uint level = referer_2.level;
        uint levelFactor= 2*((2**level)-1);
        
        rewardDistribution_v2(_referer);
        
        if(referer_2.referalIndex == levelFactor+1 && referer_2.pendingRewards>= lvl[referer_2.level]){
            
            levelManager(lvl[referer_2.level],_referer,referer_2.pendingRewards);
            
        }
    }
    
}