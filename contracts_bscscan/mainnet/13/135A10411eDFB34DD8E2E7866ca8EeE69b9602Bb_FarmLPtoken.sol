/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _amount) external returns(bool);
    function burn(address _customer,uint256 _amount) external;
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IFarmUsdt{
    function updateRecommendAmount(address _customer,uint256 _amount)external;
    function getUserInfo(address _customer)external view returns(uint256 _usdt,uint256 _recoUsdt,uint256 _recoPower,uint256 _debt);
    //function userIncome(address _user) external view returns(uint256 income);
    //function mappingInfo(address _customer,uint256 _stake,uint256 _recoUsdt,uint256 _power,uint256 _debt) external;
}

interface IBing{
    function getUserInfo(address _customer)external view returns(address _recommend,uint8 level,address[] memory _members);
    function updateMyLevel(address _customer,uint8 _level,uint8 _sign,uint256 _amount)external;
    function out(address _customer) external;
    function mappingBing(address _customer,uint8 _level,address _recommend)external;
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IFarmLPtoken{
    function updateRecommendUp(address _customer,uint256 _amount) external;
    function updateRecommendDown(address _customer,uint256 _amount) external;
}

contract FarmLPtoken is IFarmLPtoken{
    using SafeMath for uint256;
    struct User{
        uint256 stakeAmount;
        uint256 recommendPower;
        uint256 rewardDebt;
        uint256 reward;
    }
    mapping(address=>User) userInfo;
    uint256 totalStakeAmount;
    uint256 totalRecommendPower;
    uint256 public dhdPerBlock;
    uint256 public basePerBlock;
    uint256 public lastRewardBlock;
    uint256 public startBlock;
    uint256 public decimals = 1e20;
    uint256 public accPreReward;
    address public lpToken;
    address public uToken;
    address public bing;
    address public manager;
    address public fee;

    constructor(){
        manager = msg.sender;
    }

    modifier onlyBing() {
        require(bing == msg.sender,"UCN:No permission");
        _;
    }

    function changeOwner(address _customer) public{
        require(msg.sender==manager,"UCN:No permit");
        manager = _customer;
    }

    function getPoolInfo()public view returns(uint256 _stake,uint256 _reco){
        _stake = totalStakeAmount;
        _reco = totalRecommendPower;
    }

    function initialize(address _lpToken,address _uToken,address _bing) external {
        require(msg.sender == manager , "UCN: FORBIDDEN");
        lpToken = _lpToken;
        uToken = _uToken;
        bing = _bing;
    }
    
    function setFee(address _fee) public {
        require(msg.sender == manager , "UCN: FORBIDDEN");
        fee = _fee;
    }
    
    function setPoolInfo(uint256 _base,uint256 _dhdPerBlock,uint256 _startBlock) public{
        require(msg.sender==manager,"UCN:No permit");
        basePerBlock = _base;
        dhdPerBlock = _dhdPerBlock;
        startBlock = _startBlock;
    }

    function getApprove(address _customer) public view returns(bool){
        uint256 amount = IBEP20(lpToken).allowance(_customer, address(this));
        if(amount >=30000e18){
            return true;
        }else{
            return false;
        }
    }

    function getUserInfo(address _customer) public view returns(uint256 _stake,uint256 _reco,uint256 _debt,
        uint256 _reward){
        User storage user = userInfo[_customer];
        _stake = user.stakeAmount;
        _reco = user.recommendPower;
        _debt = user.rewardDebt;
        _reward = user.reward;
    }

    function provide(address _customer,uint256 _amount) public{
        updateFarm();
        updateDhdPerBlock();
        require(_customer !=address(0) && _amount>0 ,"UCN:Wrong address and amount");
        (address _recommend,,) = IBing(bing).getUserInfo(_customer);
        require(_recommend != address(0),"UCN:No code");
        User storage user = userInfo[_customer];
        require(IBEP20(lpToken).transferFrom(msg.sender, address(this), _amount),"UCN:Transfer is failed");
        //记录用户之前的收益
        uint256 stakeReward = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward).sub(user.rewardDebt);
        user.reward = user.reward.add(stakeReward);
        //更新用户质押
        user.stakeAmount = user.stakeAmount.add(_amount);
        //记录当前的负债
        user.rewardDebt = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward);
        totalStakeAmount = totalStakeAmount.add(_amount);
        IBing(bing).updateMyLevel(_customer,0,0,_amount);
    }

    function withdraw(address _customer,uint256 _amount) public{
        updateFarm();
        require(_customer !=address(0) && _amount>0 ,"UCN:Wrong address and amount");
        User storage user = userInfo[_customer];
        require(_amount <= user.stakeAmount,"UCN:Asset is enough");
        require(IBEP20(lpToken).transfer(_customer, _amount.mul(99).div(100)),"UCN:Transfer is failed");
        require(IBEP20(lpToken).transfer(_customer, _amount.mul(1).div(100)),"UCN:Transfer is failed");
        uint256 _reward = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward).sub(user.rewardDebt);
        user.reward = user.reward.add(_reward);
        user.stakeAmount = user.stakeAmount.sub(_amount);
        user.rewardDebt = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward);
        totalStakeAmount = totalStakeAmount.sub(_amount);
        IBing(bing).updateMyLevel(_customer,0,1,_amount);
    }

    function updateRecommendUp(address _customer,uint256 _amount) public override onlyBing{
        User storage user = userInfo[_customer];
        uint256 _reward = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward).sub(user.rewardDebt);
        user.reward = user.reward.add(_reward);
        user.recommendPower = user.recommendPower.add(_amount);
        user.rewardDebt = (user.recommendPower.add(user.stakeAmount)).mul(accPreReward);
        totalRecommendPower = totalRecommendPower.add(_amount);
    }   

    function updateRecommendDown(address _customer,uint256 _amount) public override onlyBing{
        User storage user = userInfo[_customer];
        uint256 _reward = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward).sub(user.rewardDebt);
        user.reward = user.reward.add(_reward);
        user.recommendPower = user.recommendPower.sub(_amount);
        user.rewardDebt = (user.recommendPower.add(user.stakeAmount)).mul(accPreReward);
        totalRecommendPower = totalRecommendPower.sub(_amount);
    } 

    
    function updateDhdPerBlock() internal {
        if(totalStakeAmount>=10000e18 && totalStakeAmount<5000000e18){
            uint256 _surplus = totalStakeAmount.sub(10000e18);
            uint256 _up = _surplus.div(1000e18);
            if(dhdPerBlock<_up.mul(1e18).div(28800).add(basePerBlock)){
                dhdPerBlock = _up.mul(1e18).div(28800).add(basePerBlock);
            } 
        }
        if(totalStakeAmount>=5000000e18 && dhdPerBlock>150486110000000000){
            dhdPerBlock = dhdPerBlock.div(2);
        }
    }

    function getDhdFarmReward(uint256 _lastRewardBlock) public view returns (uint256) {
        if(block.number < startBlock){
          return 0;
        }else if(block.number < lastRewardBlock){
          return 0;
        }else{
          uint256 blockReward = 0;
          blockReward = blockReward.add((block.number.sub(_lastRewardBlock).mul(dhdPerBlock)));
          return blockReward;
        }
    }

    function updateFarm() public {
        if(block.number < lastRewardBlock){
          return ;
        }
        if(totalStakeAmount == 0){
          lastRewardBlock = block.number;
          return;
        }
        uint256 farmReward = getDhdFarmReward(lastRewardBlock);
        if(farmReward <= 0){
          return;
        }
        bool isMint = IBEP20(uToken).mint(address(this),farmReward);
        if(isMint==true){
            uint256 transition = farmReward.mul(decimals).div(totalStakeAmount.add(totalRecommendPower));
            accPreReward = accPreReward.add(transition);
            lastRewardBlock = block.number;
          }
    }

    function userIncome(address _user) public view returns(uint256 income){
      uint256 mints = getDhdFarmReward(lastRewardBlock);
      User storage user = userInfo[_user];
      if(user.stakeAmount.add(user.recommendPower)>0){
          if(mints >0){
              uint256 currentAccReward = mints.mul(decimals).div(totalStakeAmount.add(totalRecommendPower));
              uint256 preReward = accPreReward.add(currentAccReward);
              uint256 current = preReward.mul(user.stakeAmount.add(user.recommendPower));
              income = (current.add(user.reward).sub(user.rewardDebt)).div(decimals);
          }else{
              uint256 currentReward = (user.stakeAmount.add(user.recommendPower)).mul(accPreReward).add(user.reward).sub(user.rewardDebt);
              income =currentReward.div(decimals);
          }
      }else{
          if(user.reward>0){
              income = user.reward.div(decimals);
          }else{
              income = 0;
          }
          
      }
    }

    function claim(address customer,uint256 amount) public {
        updateFarm();
        User storage user = userInfo[customer];
        uint256 _userIncome = userIncome(customer);
        require(amount <= _userIncome,"DHD:User asset is not enough!");
        require(IBEP20(uToken).transfer(customer,amount),"DHD:Transfer failed!");
        uint256 _reward = user.reward.div(decimals);
        if(amount>_reward){
            uint256 middle = amount.sub(_reward);
            user.rewardDebt = user.rewardDebt.add(middle.mul(decimals));
            user.reward = 0;
        }else{
            user.reward = decimals.mul(_reward.sub(amount));
        }
    }

}