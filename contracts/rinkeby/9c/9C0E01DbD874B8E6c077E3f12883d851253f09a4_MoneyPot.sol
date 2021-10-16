// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libs/BlockReentrancyGuard.sol';
import './libs/SafeMath.sol';
import './interfaces/I_sDFIANCE.sol';

/*
* The MoneyPot is used like a center of control of the reward for holding sDFIANCE share token
* (note : bonus virtual share (to get more reward) are added for holding its sDFIANCE for a long time and owning papr)
*/
contract MoneyPot is BlockReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many sDFIANCE tokens the user has provided + the bonus amount (Bonus from papr and bonus from holding time)
        uint256 rewardDebt; // Reward debt. See explanation below.//is rewarddept is how much reward he received tillnow or how much reward he needs to
    }

    // pool computation variables :
    uint256 public accRewardPerShare;
    uint256 public rewardableShare; // total number of share that are allowed to earn rewards

    // mapping of all address that are excluded from money pot reward distribution :
    mapping (address => bool) public addressUnrewardable; // (note : if an address is set to true, then receive token, and is reset to false -> there will be a problem to swap its sDFIANCE (see _lessHolder), but we assume that the operator will do the swap before potentially setting it to false)
    mapping (address => UserInfo) public userInfo; // information for reward computation of all sDFIANCE holder

    struct HoldingMilestone {
        uint256 minimumHoldingHours; // minimum holding hours needed to achieve the milestone
        uint256 percentBonus; // percentage bonus share of user total share amount (note : 1/10000 ratio)
    }

    HoldingMilestone[] public milestones; // list of all the milestone (editable by the operator)
    mapping (address => uint256) public usersHoldingBonus; // current holding bonus related to the holding time of each user

    mapping (address => uint256) public usersShareBonusFromPapr; // user actual bonus from holding of papr
    mapping (address => uint256) public usersShareBonusFromHoldingTime; // user actual bonus from sDFIANCE holding time

    IERC20 public rewardToken;
    address public operator;
    address public sDFIANCE;
    address public feeManager;
    address public papr;

    uint256 public MAX_PAPER_AMOUNT_PER_SHARE_PERCENT; // maximum papr amount per share taken in account in the bonus (ex : 10000 = 1 papr max per share) (note : 1/10000 ratio)
    uint256 public BONUS_SHARE_PER_PAPER; // share given as bonus per paper (ex : 10000 = 1 share per paper) (note : 1/10000 ratio)
    
    uint256 public constant ACC_REWARD_PRECISION = 1e12;

    event NewHolder(address indexed user, uint256 amount);
    event LessHolder(address indexed user, uint256 amount);
    event TransferHolder(address indexed from, address indexed to, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor (address _sDFIANCE, address _rewardToken, address _feeManager, address _papr, uint256 _MAX_PAPER_AMOUNT_PER_SHARE_PERCENT, uint256 _BONUS_SHARE_PER_PAPER) {
        operator = msg.sender;

        sDFIANCE = _sDFIANCE;
        rewardToken = IERC20(_rewardToken);
        feeManager = _feeManager;
        papr = _papr;
        
        MAX_PAPER_AMOUNT_PER_SHARE_PERCENT = _MAX_PAPER_AMOUNT_PER_SHARE_PERCENT;
        BONUS_SHARE_PER_PAPER = _BONUS_SHARE_PER_PAPER;
    }

    function getRewardToken() external view returns (address) {
        return address(rewardToken);
    }

    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "caller is not the fee manager contract");
        _;
    }

    modifier only_sDFIANCE() {
        require(msg.sender == sDFIANCE, "caller is not sDFIANCE contract");
        _;
    }

    modifier onlyPaprOrsDFIANCE() {
        require(msg.sender == papr || msg.sender == sDFIANCE, "caller is not papr or sDFIANCE contract");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the master-chef contract");
        _;
    }

    function set_MAX_PAPER_AMOUNT_PER_SHARE_PERCENT(uint16 _newAmount) external onlyOperator {
        MAX_PAPER_AMOUNT_PER_SHARE_PERCENT = _newAmount;
    }

    function set_BONUS_SHARE_PER_PAPER(uint256 _newAmount) external onlyOperator {
        BONUS_SHARE_PER_PAPER = _newAmount;
    }

    // add a new milestones (push)
    function addMilestone(uint256 _minimumHoldingHours, uint256 _percentBonus) external onlyOperator {
        if (milestones.length > 0) {
            uint lastId = milestones.length - 1;
            require(_minimumHoldingHours > milestones[lastId].minimumHoldingHours, "New milestone does not fit");
            require(_percentBonus > milestones[lastId].percentBonus, "New milestones does not fit");

            milestones.push(HoldingMilestone({
                minimumHoldingHours : _minimumHoldingHours, 
                percentBonus : _percentBonus
            }));
        } else {
            milestones.push(HoldingMilestone({
                minimumHoldingHours : _minimumHoldingHours, 
                percentBonus : _percentBonus
            }));
        }
    }

    // set new milestones list directly by passing a new list
    function setMilestones(HoldingMilestone[] memory _milestones) external onlyOperator {
        // when the operator change the milestones while actual users use existing milestones, users keep their actual bonus until any update

        delete milestones;
        HoldingMilestone[] storage milestones;
        uint256 minT;
        uint256 minB;

        // verify the concordance of the list
        for (uint i=0; i < _milestones.length; i++) {
            uint256 _minHoldingHours = _milestones[i].minimumHoldingHours;
            uint256 _percentBonus = _milestones[i].percentBonus;

            require(_minHoldingHours > minT, "Milestones list does not fit");
            minT = _minHoldingHours;


            require(_percentBonus > minB, "Milestones list does not fit");
            minB = _percentBonus;

            milestones.push(HoldingMilestone({
                minimumHoldingHours : _minHoldingHours, 
                percentBonus : _percentBonus
            }));
        }
    }

    /* 
      /!/ => USED BY THE FRONT END
      
      return (newMilestoneAvailable, percentBonus) if there is a new holding bonus milestone that the _account can get
      -if newMilestoneAvailable = false, the actual milestone is the best that the user can get, if it's = true, there is a better milestone
      -percentBonus indicate the percentBonus of the best milestone whose user has access (if there is one, else, its at 0)
    */
    function getUpdateMilestone(address _account) public view returns (bool _a, uint _b) {
        uint256 holdingTime = getAvgSwapTimeInHours(_account);
        uint256 userPercentBonus = usersHoldingBonus[_account]; // user's actual percent bonus (according to his actual milestone)
        
        for (uint i=0; i < milestones.length; i++) {
            if (holdingTime >= milestones[i].minimumHoldingHours) { // if the milestone [i] is low enough for the user ..
                if (userPercentBonus < milestones[i].percentBonus) {
                    _a = true; 
                    _b = milestones[i].percentBonus;
                }
            }
        }
    }

    // return (bool : if true, the user has a milestone, if false he hasn't) (uint : id of the actual milestone)
    function getRealMilestone(address _account) public view returns (bool _a, uint _b) {
        uint256 holdingTime = getAvgSwapTimeInHours(_account);

        for (uint i=0; i < milestones.length; i++) {
            if (holdingTime >= milestones[i].minimumHoldingHours) { // if the milestone [i] is low enough for the user ..
                _a = true;
                _b = i;
            }
        }
    }

    // function called by the user to move up a milestone if there is a higher one available (it can also go down a milestone, but updateMilestoneOf is called automatically if the bonus is lower than actual)
    function updateMilestone() public nonBlockReentrant {
        _updateMilestone(msg.sender);
    }

    // function called automatically by the sDFIANCE contract when a user -mint, burn or transfer- token to update holding bonus to the real milestone 
    function updateMilestoneOf(address _of) external only_sDFIANCE {
        _updateMilestone(_of);
    }

    // update _account milestone to the real one
    function _updateMilestone(address _account) private {
        if (addressUnrewardable[_account] == false) { // gas saving if the _account is unrewardable

            uint256 shareAmount = IERC20(sDFIANCE).balanceOf(_account); // get the real share balance (to not accumulate bonus from papr and this one)

            (bool isAvalaible, uint256 milestoneId) = getRealMilestone(_account); // get the real actual milestone of _account

            uint256 newShareHoldingBonus = (isAvalaible) ? milestones[milestoneId].percentBonus.mul(shareAmount).div(10000) : 0; // if _account had reach a milestone, calculate the share amount bonus, else, set the bonus to 0

            if (newShareHoldingBonus != usersShareBonusFromHoldingTime[_account]) { // if the new bonus is different from the last (note : gas saving ..)
                uint256 newTotalAmount = userInfo[_account].amount.sub(usersShareBonusFromHoldingTime[_account]).add(newShareHoldingBonus); // get the final new total share of _account (actual share amount - last bonus + new bonus)

                usersShareBonusFromHoldingTime[_account] = newShareHoldingBonus; // set the new actual holding bonus
                usersHoldingBonus[_account] = milestones[milestoneId].percentBonus; // set the actual percentBonus (for getUpdateMilestone function)

                // give to the user a bonus for the holding time
                _setHolderExactAmount(_account, newTotalAmount); // set holder info with new virtual share amount (considering the share bonus)
            }
        }
    }

    // allow user to manually update their papr bonus share for some reason => add nonBlockReentrant beause users can be really evil-minded :(
    function manualUpdatePaprBonusShare(address _account) external nonBlockReentrant {
        _updatePaprBonusShare(_account);
    }

    function updatePaprBonusShare(address _account) external onlyPaprOrsDFIANCE {
        _updatePaprBonusShare(_account);
    }

    /*
      update share bonus of _account from holding papr
      (note : this function is initially created to be used by papr contract, to dynamically update bonus only when a swap, a mint or a burn occurs => it permit gas saving)
    */
    function _updatePaprBonusShare(address _account) private {
        if (addressUnrewardable[_account] == false) { // gas saving if the _account is unrewardable

            uint256 shareAmount = IERC20(sDFIANCE).balanceOf(_account); // get the real share balance (to not accumulate bonus from holding time and this one)
            uint256 paprAmount = IERC20(papr).balanceOf(_account); // get papr amount of _account
            uint256 maxPaprAccountedAmount = MAX_PAPER_AMOUNT_PER_SHARE_PERCENT.mul(shareAmount).div(10000); // get the amount MAX of papr which can be counted in the rewards calculation 

            uint256 paprAccountedAmount = (paprAmount < maxPaprAccountedAmount) ? paprAmount : maxPaprAccountedAmount; // final papr accounted amount for the rewards calculation
            uint256 newShareBonusFromPapr = BONUS_SHARE_PER_PAPER.mul(paprAccountedAmount).div(10000); // get the share bonus from the final papr accounted amount (using BONUS_SHARE_PER_PAPER)

            if (newShareBonusFromPapr != usersShareBonusFromPapr[_account]) { // if the new bonus is different from the last (note : gas saving ..)
                uint256 newTotalAmount = userInfo[_account].amount.sub(usersShareBonusFromPapr[_account]).add(newShareBonusFromPapr); // get the final new total share of _account (actual share amount - last bonus + new bonus)

                usersShareBonusFromPapr[_account] = newShareBonusFromPapr; // set to the actual bonus

                // give to the user a bonus for holding papr
                _setHolderExactAmount(_account, newTotalAmount); // set holder info with new virtual share amount (considering the share bonus)
            }
        }
    }

    // set the exact share amount of "_from" (used to add or remove a reward)
    function _setHolderExactAmount(address _from, uint256 _newAmount) private {
        uint256 tokenAmount = userInfo[_from].amount;

        if (_newAmount > tokenAmount) { // if the new _newAmount is strictly more than the actual, we can just add the difference
            _newHolder(_from, _newAmount.sub(tokenAmount));
        } 
        else {
            _lessHolder(_from, tokenAmount.sub(_newAmount)); // else, we simply remove the opposed difference
        }
    }

    // Update accRewardPerShare of the pot => distribute _amount reward to all share holders (note : called privately when new reward token are deposited)
    function updatePot(uint256 _amount) private {

        // here, we use rewardableShare because excluded reward address won't take any part of the _amount reward (so we need to distribute it only between rewards takers)
        accRewardPerShare = accRewardPerShare.add(_amount.mul(ACC_REWARD_PRECISION).div(rewardableShare)); // update moneyPot accumulated reward
    }

    // allow everyone to make additional reward gift
    function giftMoneyPot(uint256 _amount) external {
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        updatePot(_amount);
    }

    // function called when there is a new reward (note : no need additionals safety checks : feeManager is completely trusted)
    function updateReceived(uint256 _amount) external onlyFeeManager {
        updatePot(_amount);
    }

    // function called by the MasterChef contract when new sDFIANCE token are withdraw from pools
    function newHolder(address _from, uint256 _amount) external only_sDFIANCE nonBlockReentrant {
        _newHolder(_from, _amount);
    }

    // adding a "_amount" of tokens to the data of the money pot (it can be "fake amount" like a new bonus from any user)
    function _newHolder(address _from, uint256 _amount) private {

        // (if the "_from" address is excluded from the money pot, 0 update is required)
        if (addressUnrewardable[_from] == false) {
            UserInfo storage user = userInfo[_from];
            uint userAmount = user.amount;

            if (userAmount > 0) {
                _harvestReward(_from); // harvest user reward
            }
            if (_amount > 0) {
                user.amount = userAmount.add(_amount); // add _amount to the user data of the money pot
            }
            
            // update the total rewardable share amount (except if the address is excluded from rewards)
            rewardableShare += _amount;

            //updates the user reward dept
            user.rewardDebt = userAmount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);

            _updateMilestone(_from); // just update milestone to increase precision and automation (no direct relation to this function)

            emit NewHolder(_from, _amount);
        }
    }

    // function called by the sDFIANCE token contract when share are burned
    function lessHolder(address _from, uint256 _amount) external only_sDFIANCE nonBlockReentrant {
        _lessHolder(_from, _amount);
    }
    
    // private lessHolder function
    function _lessHolder(address _from, uint256 _amount) private {

        // (if the "_from" address is excluded from the money pot, 0 update is required)
        if (addressUnrewardable[_from] == false) {
            UserInfo storage user = userInfo[_from];
            uint userAmount = user.amount;

            require(userAmount >= _amount, "Money pot : cannot withdraw more than the actual user amount"); // even if safety checks are performed beforehand, it is always more prudent

            if (userAmount > 0) {
                _harvestReward(_from); // harvest user reward
            }

            if(_amount > 0) {
                user.amount = userAmount.sub(_amount); // sub _amount to the user data of the money pot
            }

            // update the total rewardable share amount (except if the address is excluded from rewards)
            rewardableShare -= _amount;

            // reinitialize his reward
            user.rewardDebt = userAmount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);

            _updateMilestone(_from); // just update milestone to increase precision and automation (no direct relation to this function)

            emit LessHolder(_from, _amount);
        }
    }

    // used to transfer sDFIANCE from a share holder to another
    function transferHolder(address _from, address _to, uint256 _amount) external only_sDFIANCE nonBlockReentrant {
        UserInfo storage _fromUser = userInfo[_from];
        UserInfo storage _toUser = userInfo[_to];
        
        // if the "_from" address is excluded from the money pot, 0 update is required)
        if (addressUnrewardable[_from] == false) {

            require(_fromUser.amount >= _amount, "Money pot : cannot transfer more than the actual user amount"); // even if safety checks are performed beforehand, it is always more prudent

            // harvest the "_from" reward
            _harvestReward(_from);

            _fromUser.amount -= _amount; // sub _amount to the _from user data of the money pot

            //updates rewards depts
            _fromUser.rewardDebt = _fromUser.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);

            if (addressUnrewardable[_to] == true) rewardableShare -= _amount; // if _to address is excluded, "_amount" token diseapear from total claimable reward

            _updateMilestone(_from); // just update milestone to increase precision and automation (no direct relation to this function)
        }

        // if the "_to" address is excluded from the money pot, 0 update is required)
        if (addressUnrewardable[_to] == false) {

            // harvest the "_to" reward
            _harvestReward(_to);

            _toUser.amount += _amount; // add _amount to the _to user data of the money pot

            //updates rewards depts
            _toUser.rewardDebt = _toUser.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);

            if (addressUnrewardable[_from] == true) rewardableShare += _amount; // if _from address is excluded, "_amount" token appear in total claimable reward

            _updateMilestone(_to); // just update milestone to increase precision and automation (no direct relation to this function)
        }

        emit TransferHolder(_from, _to, _amount);
    }

    // get average hours of holding of _account (see in sDFIANCE contract)
    function getAvgSwapTimeInHours(address _account) public view returns (uint256) {
        return I_sDFIANCE(sDFIANCE).getAvgSwapTimeInHours(_account);
    }

    // get the total reward amount that the user can claim (used in the front-end and for harvest reward)
    function getPendingReward(address _account) public view returns (uint256 _pendingReward) {
        UserInfo memory user = userInfo[_account];

        _pendingReward = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION).sub(user.rewardDebt); // basic reward computation
    }

    // claim reward of _from
    function harvestReward() public nonBlockReentrant {
        address _from = msg.sender;
        UserInfo storage user = userInfo[_from];

        require(_harvestReward(_from), "MoneyPot : reward must be up to 0");
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PRECISION);

        _updateMilestone(_from); // just update milestone to increase precision and automation (no direct relation to this function)
    }

    // all harvest reward function except reward debt modification (because this function is called when user.amount is modified)
    function _harvestReward(address _from) private returns (bool) {
        uint256 reward = getPendingReward(_from);

        if (reward > 0) {
            emit Harvest(_from, reward);
            IERC20(rewardToken).safeTransfer(_from, reward);

            return true;
        } else {
            return false;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/* 
* note : This contract prevents from executing more than 1 "nonBlockReentrant" function during the same block, so any form of 
* inter-block manipulation with an external contract is blocked.
*/

abstract contract BlockReentrancyGuard {

    mapping (address => uint256) userLastCall;

    modifier nonBlockReentrant() {
        uint256 _blockCount = block.number;
        address _sender = msg.sender;

        require(userLastCall[_sender] != _blockCount, "Multiple calls in the same block are not allow");

        // Any calls to nonBlockReentrant after this point will fail
        userLastCall[_sender] = _blockCount;

        _;
    }
}

pragma solidity =0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface I_sDFIANCE is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function getAvgSwapTimeInHours(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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