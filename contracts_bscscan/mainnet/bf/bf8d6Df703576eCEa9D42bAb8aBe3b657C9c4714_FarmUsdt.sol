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
interface OldPool{
    function userIncome(address _user) external view returns(uint256 income);
}

contract FarmUsdt is IFarmUsdt{
    using SafeMath for uint256;
    struct User{
        uint256 usdt;
        uint256 recommendUsdt;
        uint256 recommendPower;
        uint256 rewardDebt;
        uint256 reward;
    }
    mapping(address=>User) userInfo;
    uint256  totalAmount;
    uint256 public dhdPerBlock;
    uint256 public lastRewardBlock;
    uint256 public startBlock;
    uint256 public decimals = 1e20;
    uint256 public accPreReward;
    uint256 public basePerBlock;
    address usdt;
    address uToken;
    address bing;
    address oldPool;
    address oldBing;
    address manager;
    uint256 totalPreBolck = 759131000000000000;

    constructor(){
        manager = msg.sender;
    }
    
    modifier onlyBing() {
        require(bing == msg.sender,"UCN:No permission");
        _;
    }

    function getOldInfo(address _customer) public view returns(address _reco,
        uint8 _lev,uint256 _us,uint256 _with,uint256 _pow,uint256 _deb){
        (address _oldRecommend,uint8 _oldLevel,) = IBing(oldBing).getUserInfo(_customer);
        (uint256 _usdt,uint256 _recoUsdt,uint256 _recoPower,uint256 _debt) = IFarmUsdt(oldPool).getUserInfo(_customer);
        _reco = _oldRecommend;
        _lev = _oldLevel;
        _us = _usdt;
        _with = _recoUsdt;
        _pow = _recoPower;
        _deb = _debt;
    }

    function getOldIncome(address _customer) public view returns(uint256 _incom){
        _incom = OldPool(oldPool).userIncome(_customer);
    }
    
    function bingCode(address _recommend,address _customer)public{
        updateFarm();
        updateDhdPerBlock();
        (address _reco,uint8 _lev,uint256 _us,uint256 _with,uint256 _pow,)=getOldInfo(_customer);
        (address _recommend0,,)=IBing(bing).getUserInfo(_recommend);
        (address _recommend1,,)=IBing(bing).getUserInfo(_customer);
        uint256 _amount = getOldIncome(_customer);
        User storage user = userInfo[_customer];
        if(_reco !=address(0)){
            require(_recommend1==address(0),"UCN:Only once");
            user.usdt = _us;
            user.recommendUsdt = _with;
            user.recommendPower = _pow;
            user.reward = _amount;
            user.rewardDebt = user.rewardDebt.add(_us.add(_pow)).mul(accPreReward);
            totalAmount = totalAmount.add(_us).add(_pow);
            IBing(bing).mappingBing(_customer,_lev,_reco);
        }else{
            require(_recommend0 != address(0) && _recommend != address(0),"UCN:Zero code");
            require(_recommend1==address(0),"UCN:Only once");
            IBing(bing).mappingBing(_customer,0,_recommend);
        }  
    }
    

    function changeOwner(address _customer) public{
        require(msg.sender==manager,"UCN:No permit");
        manager = _customer;
    }

    function getPoolInfo()public view returns(uint256 _total){
        _total = totalAmount;
    }

    function initialize(address _usdt,address _ucn,address _bing,address _ob,address _op) external {
        require(msg.sender == manager , "UCN: FORBIDDEN");
        usdt = _usdt;
        uToken = _ucn;
        bing = _bing;
        oldBing = _ob;
        oldPool = _op;
    }

    function setPoolInfo(uint256 _basePreBlock,uint256 _dhdPerBlock,uint256 _totalPreBlock,uint256 _startMinerBlock)public {
        require(msg.sender == manager,"DHD:No operation permission");
        basePerBlock = _basePreBlock;
        dhdPerBlock = _dhdPerBlock;
        totalPreBolck = _totalPreBlock;
        startBlock = _startMinerBlock;
    }

    function getUserInfo(address _customer)public override view returns(uint256 _usdt,uint256 _recoUsdt,
        uint256 _recoPower,uint256 _debt){
        User storage user = userInfo[_customer];
        _usdt = user.usdt;
        _recoUsdt = user.recommendUsdt;
        _recoPower = user.recommendPower;
        _debt = user.rewardDebt;
    }

    function manageWithdrawUsd(address _customer,uint256 _amount) public{
        require(msg.sender == manager,"UCN:No permit");
        require(IBEP20(usdt).transfer(_customer,_amount),"UCN:Transfer is failed");
    }

    function managerWithdrawUcn(address _customer,uint256 _amount) public{
        require(msg.sender == manager,"UCN:No permit");
        require(IBEP20(uToken).transfer(_customer,_amount),"UCN:Transfer is failed");
    }

    function getBuyAmount(address _customer,uint8 _level) public view returns(uint256 _amount){
        User storage user = userInfo[_customer];
        if(_level==1){
            if(user.usdt>=100e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(100e18).sub(user.usdt.mul(2));
            }
        }else if(_level==2){
            if(user.usdt>=300e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(300e18).sub(user.usdt.mul(2));
            }
        }else if(_level==3){
            if(user.usdt>=600e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(600e18).sub(user.usdt.mul(2));
            }
        }else if(_level==4){
            if(user.usdt>=1000e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(1000e18).sub(user.usdt.mul(2));
            }
        }else if(_level==5){
            if(user.usdt>=1400e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(1400e18).sub(user.usdt.mul(2));
            }
        }else if(_level==6){
            if(user.usdt>=1800e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(1800e18).sub(user.usdt.mul(2));
            }
        }else if(_level==7){
            if(user.usdt>=2200e18){
                _amount = 0;
            }else{
                _amount = user.usdt.add(2200e18).sub(user.usdt.mul(2));
            }
        }else{
            _amount = 0;
        }
        
    }

    function buyLevelUseUsdt(address _customer,uint8 _level,uint256 _amount) public{
        updateFarm();
        updateDhdPerBlock();
        User storage user = userInfo[_customer];
        (address _recommend,,) = IBing(bing).getUserInfo(_customer);
        require(_recommend != address(0),"UCN:No code");
        uint256 _buyAmount = getBuyAmount(_customer, _level);
        require(_amount==_buyAmount,"UCN:Buy amount is wrong");
        require(IBEP20(usdt).transferFrom(msg.sender,address(this),_amount),"UCN:TransferFrom is failed");
        user.usdt =user.usdt.add(_amount);
        totalAmount = totalAmount.add(_amount);
        user.rewardDebt = user.rewardDebt.add(_amount.mul(accPreReward));
        IBing(bing).updateMyLevel(_customer, _level,2, _amount.mul(70).div(100));
    }

    function updateRecommendAmount(address _customer,uint256 _amount) public override onlyBing{
        User storage user = userInfo[_customer];
        user.recommendPower = user.recommendPower.add(_amount);
        //user.recommendUsdt = user.recommendUsdt.add(_amount);
        user.rewardDebt = user.rewardDebt.add(_amount.mul(accPreReward));
        totalAmount = totalAmount.add(_amount);
        (,uint8 _level,) = IBing(bing).getUserInfo(_customer);
        if(_level !=0){
            user.recommendUsdt = user.recommendUsdt.add(_amount);
            if(_level==1 && user.recommendPower >=300e18){
                IBing(bing).out(_customer);
            }else if(_level==2 && user.recommendPower >= 900e18){
                IBing(bing).out(_customer);
            }else if(_level==3 && user.recommendPower >= 1800e18){
                IBing(bing).out(_customer);
            }else if(_level==4 && user.recommendPower >= 3000e18){
                IBing(bing).out(_customer);
            }else if(_level==5 && user.recommendPower >= 4200e18){
                IBing(bing).out(_customer);
            }else if(_level==6 && user.recommendPower >= 5400e18){
                IBing(bing).out(_customer);
            }else if(_level==7 && user.recommendPower >= 6600e18){
                IBing(bing).out(_customer);
            }
        }

    }

    function withdraw(address _customer,uint256 _amount) public{
        updateFarm();
        User storage user = userInfo[_customer];
        require(_amount<=user.recommendUsdt,"UCN:User asset is enough");
        require(IBEP20(usdt).transfer(_customer, _amount),"UCN:Transfer is failed");
        user.recommendUsdt = user.recommendUsdt.sub(_amount);
    }

    function updateDhdPerBlock() internal {
        if(totalAmount>=10000e18 && totalAmount<5000000e18){
            uint256 _surplus = totalAmount.sub(10000e18);
            uint256 _up = _surplus.div(1000e18);
            if(dhdPerBlock<_up.mul(1e18).div(28800).add(basePerBlock)){
                dhdPerBlock = _up.mul(1e18).div(28800).add(basePerBlock);
            } 
        }
        if(totalAmount>=5000000e18 && dhdPerBlock>150486110000000000){
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
        if(totalAmount == 0){
          lastRewardBlock = block.number;
          return;
        }
        uint256 farmReward = getDhdFarmReward(lastRewardBlock);
        if(farmReward <= 0){
          return;
        }
        uint256 totalReward = totalPreBolck.mul(block.number.sub(lastRewardBlock));
        bool isMint = IBEP20(uToken).mint(address(this),totalReward);
        if(isMint==true){
            uint256 transition = farmReward.mul(decimals).div(totalAmount);
            accPreReward = accPreReward.add(transition);
            uint256 burnAmount = totalReward.sub(farmReward);        
            IBEP20(uToken).burn(address(this), burnAmount);
            lastRewardBlock = block.number;
        }
    }

    function userIncome(address _user) public view returns(uint256 income){
      uint256 mints = getDhdFarmReward(lastRewardBlock);
      User storage user = userInfo[_user];
      if(user.usdt.add(user.recommendPower)>0){
          if(mints >0){
              uint256 currentAccReward = mints.mul(decimals).div(totalAmount);
              uint256 preReward = accPreReward.add(currentAccReward);
              uint256 current = preReward.mul(user.usdt.add(user.recommendPower));
              income = (current.sub(user.rewardDebt)).div(decimals).add(user.reward);
          }else{
              uint256 currentReward = (user.usdt.add(user.recommendPower)).mul(accPreReward).sub(user.rewardDebt);
              income =currentReward.div(decimals).add(user.reward);
          }
      }else{
          if(user.reward>0){
              income = user.reward;
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
        if(amount>=user.reward){
            uint256 middle = amount.sub(user.reward);
            user.rewardDebt = user.rewardDebt.add(middle.mul(decimals));
            user.reward = 0;
        }else{
            user.reward = user.reward.sub(amount);
        }
    }

    function getApprove(address _customer) public view returns(bool){
        uint256 amount = IBEP20(usdt).allowance(_customer, address(this));
        if(amount >10000e18){
            return true;
        }else{
            return false;
        }
    }


}