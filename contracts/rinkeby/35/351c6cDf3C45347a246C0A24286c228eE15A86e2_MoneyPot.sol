pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './libs/SafeMath.sol';
import './interfaces/I_sDFIANCE.sol';

/*
* The MoneyPot is used like the center of control of the reward for holding sDFIANCE share token
* (note : the MoneyPot computes rewards with a system of virtual token that represents the right to have a reward, reward
*         are consider as a buyer of this token to make all holders win this gain)
*/

contract MoneyPot {
    using SafeMath for uint256;

    struct holderInfo {
        uint256 buyPrice; // average virtual price where the holder received his sDFIANCE
        uint256 tokenAmount; // amount of sDFIANCE token the holder has (note : the tokenAmount can be up to the real holded amount due to bonus)
    }
    uint256 totalTokenAmount; // total token amount from all holders
    uint256 globalAverageBuyPrice; // average of the buy price from all holders

    mapping(address => holderInfo) private sDFIANCE_holders; // all the informations that the virtual pool need about holders

    address public sDFIANCE;
    address public rewardToken;
    address public feeManager;
    address public operator;
    address public papr;

    // global unix time average swap time of all holders
    uint256 public globalAverageSwapTime;

    uint256 public PAPR_STACKED_REWARD_PERCENT; // between 0 and 255 (255 => 255%) (note : 1/100 ratio)
    uint256 public MAX_PAPER_AMOUNT_PER_SHARE_PERCENT; // maximum papr amount per share taken in account in the bonus (ex : 10000 = 1 papr max per share) (note : 1/10000 ratio)
    uint256 public BONUS_SHARE_PER_PAPER; // share given as bonus per paper (ex : 10000 = 1 share per paper) (note : 1/10000 ratio)
    uint256 public HOLDING_MULTIPLIER; // importance of holding (the higher the value, the more important the holding will be in the calculation of the rewards)

    constructor (address _sDFIANCE, address _rewardToken, address _feeManager, address _papr) public {
        sDFIANCE = _sDFIANCE;
        rewardToken = _rewardToken;
        feeManager = _feeManager;
        operator = msg.sender;
        papr = _papr;

        globalAverageSwapTime = block.number;
    }

    struct pool {
        uint256 nb_RewardToken;
        uint256 nb_sDFIANCE;
    }

    pool private virtualLiquidityPool;

    function getVirtualPrice() internal view returns (uint256) {
        return virtualLiquidityPool.nb_RewardToken.div(virtualLiquidityPool.nb_sDFIANCE); // return number of rewardToken per sDFIANCE
    }

    function giftVirtualPool(uint256 _giftAmount) internal {
        virtualLiquidityPool.nb_RewardToken.add(_giftAmount);
    }

    function getRewardToken() external returns (address) {
        return rewardToken;
    }

    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "caller is not the fee manager contract");
        _;
    }

    modifier only_sDFIANCE() {
        require(msg.sender == sDFIANCE, "caller is not sDFIANCE contract");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the master-chef contract");
        _;
    }

    function set_PAPR_STACKED_REWARD_PERCENT(uint8 _newAmount) external onlyOperator {
        PAPR_STACKED_REWARD_PERCENT = _newAmount;
    }

    function set_MAX_PAPER_AMOUNT_PER_SHARE_PERCENT(uint16 _newAmount) external onlyOperator {
        MAX_PAPER_AMOUNT_PER_SHARE_PERCENT = _newAmount;
    }

    function set_BONUS_SHARE_PER_PAPER(uint256 _newAmount) external onlyOperator {
        BONUS_SHARE_PER_PAPER = _newAmount;
    }

    function set_HOLDING_MULTIPLIER(uint256 _newAmount) external onlyOperator {
        HOLDING_MULTIPLIER = _newAmount;
    }

    // allow everyone to make additional reward gift
    function giftMoneyPot(uint256 _amount) external {
        ERC20(rewardToken).approve(address(this), _amount);
        ERC20(rewardToken).transferFrom(msg.sender, address(this), _amount);
        giftVirtualPool(_amount);
    }

    // function called when there is a new reward (note : no need additionals safety checks : feeManager is completely trusted)
    function updateReceived(uint256 _amount) external onlyFeeManager {
        giftVirtualPool(_amount);
    }

    /*
    * update bonus share of _account
    * (note : this function is initially create to be used by papr contract, to dynamically update bonus only when a swap, a mint or a burn occurs => it permit gas saving)
    */
    function updateBonusShare(address _account) external {
        uint256 shareAmount = ERC20(sDFIANCE).balanceOf(_account);
        uint256 paprAmount = ERC20(papr).balanceOf(_account);
        uint256 maxPaprAmount = MAX_PAPER_AMOUNT_PER_SHARE_PERCENT.mul(shareAmount).div(10000); // maximum papr amount taken into account for bonus computation

        uint256 paprAmountBonus = (paprAmount < maxPaprAmount) ? paprAmount : maxPaprAmount; // papr amount used to compute bonus
        
        // give to the user a bonus for holding papr
        _setHolderBonus(_account, BONUS_SHARE_PER_PAPER.mul(paprAmountBonus).div(10000)); // set holder info with new virtual share amount (considering the share bonus)
    }
 
    // function called by the MasterChef contract when new sDFIANCE token are withdraw from pools
    function newHolder(address _from, uint256 _amount) external only_sDFIANCE {
        _newHolder(_from, _amount);
    }

    // private newHolder function
    function _newHolder(address _from, uint256 _amount) private {
        uint256 actualPrice = getVirtualPrice();
        
        virtualLiquidityPool.nb_sDFIANCE = virtualLiquidityPool.nb_sDFIANCE.add(_amount);
        sDFIANCE_holders[_from].tokenAmount = sDFIANCE_holders[_from].tokenAmount.add(_amount);

        // add to global variable to be abble to compute global reward
        totalTokenAmount = totalTokenAmount.add(_amount); 
        globalAverageBuyPrice = actualPrice.mul(_amount).add(globalAverageBuyPrice.mul(totalTokenAmount)).div(_amount.add(totalTokenAmount)); // compute new global average buy price

        // calculate the amount of A token we need to borrow to keep the virtual price when we adding more sDFIANCE share token
        uint256 virtualCollateralAmount = _amount.div(virtualLiquidityPool.nb_sDFIANCE.sub(_amount)).mul(virtualLiquidityPool.nb_RewardToken);
        virtualLiquidityPool.nb_RewardToken = virtualLiquidityPool.nb_RewardToken.add(virtualCollateralAmount);

        if (sDFIANCE_holders[_from].tokenAmount == 0) {
            
            // set the buy price to the actual price
            sDFIANCE_holders[_from].buyPrice = actualPrice;
        } 
        else {
            uint lastTokenAmount = sDFIANCE_holders[_from].tokenAmount;

            // calculate the average buy price with weighted token
            sDFIANCE_holders[_from].buyPrice = actualPrice.mul(_amount).add(sDFIANCE_holders[_from].buyPrice.mul(lastTokenAmount)).div(_amount.add(lastTokenAmount));
        }
    }

    // allow caller to set exact tokenAmount of a holder
    function _setHolderBonus(address _from, uint256 _newAmount) private {
        uint256 tokenAmount = sDFIANCE_holders[_from].tokenAmount;
        require(_newAmount != tokenAmount);

        if (_newAmount > tokenAmount) { // if the new _newAmount is strictly more than the actual, we can just add the difference
            _newHolder(_from, _newAmount.sub(tokenAmount));
        } 
        else {
            _lessHolder(_from, tokenAmount.sub(_newAmount)); // else, we simply remove the difference
        }
    }

    // function called by the sDFIANCE token contract when share are burned
    function lessHolder(address _from, uint256 _amount) external only_sDFIANCE {
        _lessHolder(_from, _amount);
    }
    
    // private lessHolder function
    function _lessHolder(address _from, uint256 _amount) private {
        uint256 actualPrice = getVirtualPrice();

        harvestReward(_from); // harvest _from's reward
        
        virtualLiquidityPool.nb_sDFIANCE = virtualLiquidityPool.nb_sDFIANCE.sub(_amount);
        sDFIANCE_holders[_from].tokenAmount = sDFIANCE_holders[_from].tokenAmount.sub(_amount);

        // add to global variable to be abble to compute global reward
        totalTokenAmount = totalTokenAmount.sub(_amount); 

        // remove the collateral token (=> - (amount token to withdraw * pool virtual price))            
        virtualLiquidityPool.nb_RewardToken = virtualLiquidityPool.nb_RewardToken.sub(_amount.mul(actualPrice));
    }

    // used to transfer sDFIANCE from a share holder to another
    function transferHolder(address _from, address _to, uint256 _amount) external only_sDFIANCE {
        uint256 actualPrice = getVirtualPrice();
        holderInfo storage _toInfo = sDFIANCE_holders[_to];
        
        sDFIANCE_holders[_from].tokenAmount = sDFIANCE_holders[_from].tokenAmount.sub(_amount);

        globalAverageBuyPrice = actualPrice.mul(_amount).add(globalAverageBuyPrice.mul(totalTokenAmount)).div(_amount.add(totalTokenAmount)); // update the total global average buy price

        // note : need to keep this line before the tokenAmount add
        _toInfo.buyPrice = actualPrice.mul(_amount).add(_toInfo.buyPrice.mul(_toInfo.tokenAmount)).div(_amount.add(_toInfo.tokenAmount));
        _toInfo.tokenAmount = _toInfo.tokenAmount.add(_amount);
    }

    function totalRewardAllowedToClaim() public view returns (uint256) {
        return getVirtualPrice().sub(globalAverageBuyPrice).mul(totalTokenAmount); // get reward of _account
    }

    // get the total reward amount that the user can claim (used in the front-end and for harvest reward)
    function getPendingReward(address _account) public view returns (uint256) {
        uint256 reward = getVirtualPrice().sub(sDFIANCE_holders[_account].buyPrice).mul(sDFIANCE_holders[_account].tokenAmount); // get reward of _account
        uint256 globalReward = totalRewardAllowedToClaim();
        uint256 denominatorMultiplier = globalReward.div(getGlobalTotalHoldingHoursShares());

        // formula :  ((bonus _account * denominatorMultiplier * BONUS_MULTIPLIER + reward) / (globalReward * BONUS_MULTIPLIER + globalReward)) * globalReward

        uint256 rewardWithBonus = reward.add(getTotalHoldingHoursShares(_account).mul(denominatorMultiplier).mul(HOLDING_MULTIPLIER)); // get reward of _account in addition to his holding hours (multiplied by denominatorMultiplier and BONUS MULTIPLIER)
        uint256 globalRewardWithTotalBonus = globalReward.add(globalReward.mul(HOLDING_MULTIPLIER));

        uint256 finalPercentageOfReward = rewardWithBonus.div(globalRewardWithTotalBonus);
        uint256 finalUserReward = finalPercentageOfReward.mul(globalReward);

        return finalUserReward;
    }

    function getGlobalAvgSwapTimeInHours() private view returns (uint256) {
        return block.timestamp.sub(globalAverageSwapTime) / 1 hours;
    }

    // return the total average number of hours of holding for all share
    function getGlobalTotalHoldingHoursShares() private view returns (uint256) {
        return getGlobalAvgSwapTimeInHours().mul(ERC20(sDFIANCE).totalSupply());
    } 

    // return the total average number of hours of holding for all share of _account
    function getTotalHoldingHoursShares(address _account) private view returns (uint256) {
        I_sDFIANCE(sDFIANCE).getAvgSwapTimeInHours(_account).mul(ERC20(sDFIANCE).balanceOf(_account));
    }

    // NOTICE : function must be call after every token movement
    function updateGlobalAverageSwapTime(uint256 lastTotalSupply, uint256 resetedShareAmount, uint256 swapTime) public only_sDFIANCE {
        // get last and new total supply because every burn or mint can influence global avg swap time
        uint256 newTotalSupply = ERC20(sDFIANCE).totalSupply();

        // get the total non reseted share token if there was a burn and if there was a mint (note : if there was a transfer, the 2 cases can work, its why there are only 2 options)
        uint256 nonResetedShareAmount = (newTotalSupply < lastTotalSupply) ? lastTotalSupply.sub(resetedShareAmount) : newTotalSupply.sub(resetedShareAmount);

        // the formula is : (NonResetedShare * globalAvgSwapTime + ResetedShare * ResetedShareSwapTime) / TotalSupply
        globalAverageSwapTime = (nonResetedShareAmount.mul(globalAverageSwapTime)).add(resetedShareAmount.mul(swapTime)).div(newTotalSupply);
    }

    function harvestReward(address _from) public {
        uint256 reward = getPendingReward(_from);
        uint256 _tokenAmount = sDFIANCE_holders[_from].tokenAmount;

        require(reward > 0, "MoneyPot : reward must be up to 0");
        ERC20(rewardToken).transfer(_from, reward);

        globalAverageBuyPrice = getVirtualPrice().mul(_tokenAmount).add(globalAverageBuyPrice.mul(totalTokenAmount)).div(_tokenAmount.add(totalTokenAmount)); // compute new global average buy price
        sDFIANCE_holders[_from].buyPrice = getVirtualPrice();
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

pragma solidity =0.8.0;

interface I_sDFIANCE {
    function mint(address _to, uint256 _amount) external;
    function getAvgSwapTimeInHours(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

