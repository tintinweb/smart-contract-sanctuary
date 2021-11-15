pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SDAOBondedTokenStake is Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    ERC20 public token; // Address of token contract and same used for rewards
    ERC20 public bonusToken; // Address of bonus token contract

    struct StakeInfo {
        bool exist;
        uint256 amount;
        uint256 rewardComputeIndex;
        uint256 bonusAmount;
    }

    // Staking period timestamp (Debatable on timestamp vs blocknumber - went with timestamp)
    struct StakePeriod {
        uint256 startPeriod;
        uint256 submissionEndPeriod;
        uint256 endPeriod;

        uint256 maxStake;

        uint256 windowRewardAmount;
        uint256 windowMaxAmount;
        
    }

    address public tokenOperator; // Address to manage the Stake 

    uint256 public maxAirDropStakeBlocks; // Block numbers to complete the airDrop Auto Stakes

    mapping (address => uint256) public balances; // Useer Token balance in the contract

    uint256 public currentStakeMapIndex; // Current Stake Index to avoid math calc in all methods

    mapping (uint256 => StakePeriod) public stakeMap;

    // List of Stake Holders
    address[] stakeHolders; 

    // All Stake Holders
    mapping(address => StakeInfo) stakeHolderInfo;

    // To store the total stake in a window
    uint256 public windowTotalStake;

    // Events
    event NewOperator(address tokenOperator);

    event WithdrawToken(address indexed tokenOperator, uint256 amount);

    event OpenForStake(uint256 indexed stakeIndex, address indexed tokenOperator, uint256 startPeriod, uint256 endPeriod, uint256 rewardAmount);
    event SubmitStake(uint256 indexed stakeIndex, address indexed staker, uint256 stakeAmount);
    event WithdrawStake(uint256 indexed stakeIndex, address indexed staker, uint256 stakeAmount, uint256 bonusAmount);
    event ClaimStake(uint256 indexed stakeIndex, address indexed staker, uint256 totalAmount, uint256 bonusAmount);
    event AddReward(address indexed staker, uint256 indexed stakeIndex, address tokenOperator, uint256 stakeAmount, uint256 rewardAmount, uint256 windowTotalStake);


    // Modifiers
    modifier onlyOperator() {
        require(
            msg.sender == tokenOperator,
            "Only operator can call this function."
        );
        _;
    }

    // Token Operator should be able to do auto renewal
    modifier allowSubmission() {        
        require(
            now >= stakeMap[currentStakeMapIndex].startPeriod && 
            now <= stakeMap[currentStakeMapIndex].submissionEndPeriod, 
            "Staking at this point not allowed"
        );
        _;
    }

    modifier validStakeLimit(address staker, uint256 stakeAmount) {

        uint256 stakerTotalStake;
        stakerTotalStake = stakeAmount.add(stakeHolderInfo[staker].amount);

        // Check for Max Stake per Wallet and stake window max limit 
        require(
            stakeAmount > 0 && 
            stakerTotalStake <= stakeMap[currentStakeMapIndex].maxStake && 
            windowTotalStake.add(stakeAmount) <= stakeMap[currentStakeMapIndex].windowMaxAmount,
            "Exceeding max limits"
        );
        _;

    }

    // Check for claim - Stake Window should be either in submission phase or after end period
    modifier allowClaimStake() {

        require(
          (now >= stakeMap[currentStakeMapIndex].startPeriod && now <= stakeMap[currentStakeMapIndex].submissionEndPeriod && stakeHolderInfo[msg.sender].amount > 0) || 
          (now > stakeMap[currentStakeMapIndex].endPeriod && stakeHolderInfo[msg.sender].amount > 0), "Invalid claim request");
        _;

    }

    constructor(address _token, uint256 _maxAirDropStakeBlocks)
    public
    {
        token = ERC20(_token);
        tokenOperator = msg.sender;
        currentStakeMapIndex = 0;
        windowTotalStake = 0;
        maxAirDropStakeBlocks = _maxAirDropStakeBlocks.add(block.number); 
    }

    function updateOperator(address newOperator) external onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        
        tokenOperator = newOperator;

        emit NewOperator(newOperator);
    }
    
    function withdrawToken(uint256 value) external onlyOperator
    {

        // Check if contract is having required balance 
        require(token.balanceOf(address(this)) >= value, "Not enough balance in the contract");
        require(token.transfer(msg.sender, value), "Unable to transfer token to the operator account");

        emit WithdrawToken(tokenOperator, value);
        
    }

    // To set the bonus token for future needs
    function setBonusToken(address _bonusToken) external onlyOwner {
        require(_bonusToken != address(0), "Invalid bonus token");
        bonusToken = ERC20(_bonusToken);
    }

    function openForStake(uint256 _startPeriod, uint256 _submissionEndPeriod, uint256 _endPeriod, uint256 _windowRewardAmount, uint256 _maxStake, uint256 _windowMaxAmount) external onlyOperator {

        // Check Input Parameters
        require(_startPeriod >= now && _startPeriod < _submissionEndPeriod && _submissionEndPeriod < _endPeriod, "Invalid stake period");
        require(_windowRewardAmount > 0 && _maxStake > 0 && _windowMaxAmount > 0, "Invalid inputs" );

        // Check Stake in Progress
        require(currentStakeMapIndex == 0 || (now > stakeMap[currentStakeMapIndex].submissionEndPeriod && _startPeriod >= stakeMap[currentStakeMapIndex].endPeriod), "Cannot have more than one stake request at a time");

        // Move the staking period to next one
        currentStakeMapIndex = currentStakeMapIndex + 1;
        StakePeriod memory stakePeriod;

        // Set Staking attributes
        stakePeriod.startPeriod = _startPeriod;
        stakePeriod.submissionEndPeriod = _submissionEndPeriod;
        stakePeriod.endPeriod = _endPeriod;
        stakePeriod.windowRewardAmount = _windowRewardAmount;
        stakePeriod.maxStake = _maxStake;
        stakePeriod.windowMaxAmount = _windowMaxAmount;

        stakeMap[currentStakeMapIndex] = stakePeriod;

        // Add the current window reward to the window total stake 
        windowTotalStake = windowTotalStake.add(_windowRewardAmount);

        emit OpenForStake(currentStakeMapIndex, msg.sender, _startPeriod, _endPeriod, _windowRewardAmount);

    }

    // To add the Stake Holder
    function _createStake(address staker, uint256 stakeAmount) internal returns(bool) {

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];

        // Check if the user already staked in the past
        if(stakeInfo.exist) {

            stakeInfo.amount = stakeInfo.amount.add(stakeAmount);

        } else {

            StakeInfo memory req;

            // Create a new stake request
            req.exist = true;
            req.amount = stakeAmount;
            req.rewardComputeIndex = 0;

            // Add to the Stake Holders List
            stakeHolderInfo[staker] = req;

            // Add to the Stake Holders List
            stakeHolders.push(staker);

        }

        return true;

    }


    // To submit a new stake for the current window
    function submitStake(uint256 stakeAmount) external allowSubmission validStakeLimit(msg.sender, stakeAmount) {

        // Transfer the Tokens to Contract
        require(token.transferFrom(msg.sender, address(this), stakeAmount), "Unable to transfer token to the contract");

        _createStake(msg.sender, stakeAmount);

        // Update the User balance
        balances[msg.sender] = balances[msg.sender].add(stakeAmount);

        // Update current stake period total stake - For Auto Approvals
        windowTotalStake = windowTotalStake.add(stakeAmount); 
       
        emit SubmitStake(currentStakeMapIndex, msg.sender, stakeAmount);

    }


    // To withdraw stake during submission phase
    function withdrawStake(uint256 stakeAmount) external allowClaimStake nonReentrant{

        //require(
        //    (now >= stakeMap[stakeMapIndex].startPeriod && now <= stakeMap[stakeMapIndex].submissionEndPeriod),
        //    "Stake withdraw at this point is not allowed"
        //);

        StakeInfo storage stakeInfo = stakeHolderInfo[msg.sender];

        // Validate the input Stake Amount
        require(stakeAmount > 0 && stakeInfo.amount >= stakeAmount, "Cannot withdraw beyond stake amount");

        uint256 bonusAmount;

        // Update the staker balance in the staking window
        stakeInfo.amount = stakeInfo.amount.sub(stakeAmount);
        bonusAmount = stakeInfo.bonusAmount;
        stakeInfo.bonusAmount = 0;

        // Update the User balance
        balances[msg.sender] = balances[msg.sender].sub(stakeAmount);

        // Update current stake period total stake - For Auto Approvals
        windowTotalStake = windowTotalStake.sub(stakeAmount); 

        // Return to User Wallet
        require(token.transfer(msg.sender, stakeAmount), "Unable to transfer token to the account");

        // Call the bonus transfer function - Should transfer only if set 
        if(address(bonusToken) != address(0) && bonusAmount > 0) {
            require(bonusToken.transfer(msg.sender, bonusAmount), "Unable to transfer bonus token to the account");
        }

        emit WithdrawStake(currentStakeMapIndex, msg.sender, stakeAmount, bonusAmount);
    }

    // To claim from the stake window
    function claimStake() external allowClaimStake nonReentrant{

        StakeInfo storage stakeInfo = stakeHolderInfo[msg.sender];

        uint256 stakeAmount;
        uint256 bonusAmount;

        // No more stake windows or in submission phase
        stakeAmount = stakeInfo.amount;
        bonusAmount = stakeInfo.bonusAmount;
        stakeInfo.amount = 0;
        stakeInfo.bonusAmount = 0;

        // Update current stake period total stake
        windowTotalStake = windowTotalStake.sub(stakeAmount);

        // Check for balance in the contract
        require(token.balanceOf(address(this)) >= stakeAmount, "Not enough balance in the contract");

        // Update the User Balance
        balances[msg.sender] = balances[msg.sender].sub(stakeAmount);

        // Call the transfer function
        require(token.transfer(msg.sender, stakeAmount), "Unable to transfer token back to the account");

        // Call the bonus transfer function - Should transfer only if set 
        if(address(bonusToken) != address(0) && bonusAmount > 0) {
            require(bonusToken.transfer(msg.sender, bonusAmount), "Unable to transfer bonus token to the account");
        }
        
        emit ClaimStake(currentStakeMapIndex, msg.sender, stakeAmount, bonusAmount);

    }


    function _calculateRewardAmount(uint256 stakeMapIndex, uint256 stakeAmount) internal view returns(uint256) {

        uint256 calcRewardAmount;
        if(windowTotalStake > stakeMap[stakeMapIndex].windowRewardAmount) {
            calcRewardAmount = stakeAmount.mul(stakeMap[stakeMapIndex].windowRewardAmount).div(windowTotalStake.sub(stakeMap[stakeMapIndex].windowRewardAmount));
        }
        
        return calcRewardAmount;
    }


    // Update reward for staker in the respective stake window
    function computeAndAddReward(uint256 stakeMapIndex, address staker, uint256 stakeBonusAmount) 
    public 
    onlyOperator
    returns(bool)
    {

        // Check for the Incubation Period
        require(
            now > stakeMap[stakeMapIndex].submissionEndPeriod && 
            now < stakeMap[stakeMapIndex].endPeriod, 
            "Reward cannot be added now"
        );

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];

        // Check if reward already computed
        require(stakeInfo.amount > 0 && stakeInfo.rewardComputeIndex != stakeMapIndex, "Invalid reward request");

        // Calculate the totalAmount
        uint256 totalAmount;
        uint256 rewardAmount;

        // Calculate the reward amount for the current window
        totalAmount = stakeInfo.amount;
        rewardAmount = _calculateRewardAmount(stakeMapIndex, totalAmount);
        totalAmount = totalAmount.add(rewardAmount);

        // Add the reward amount
        stakeInfo.amount = totalAmount;

        // Add the bonus Amount
        stakeInfo.bonusAmount = stakeInfo.bonusAmount.add(stakeBonusAmount);

        // Update the reward compute index to avoid mulitple addition
        stakeInfo.rewardComputeIndex = stakeMapIndex;

        // Update the User Balance
        balances[staker] = balances[staker].add(rewardAmount);

        emit AddReward(staker, stakeMapIndex, tokenOperator, totalAmount, rewardAmount, windowTotalStake);

        return true;
    }

    function updateRewards(uint256 stakeMapIndex, address[] calldata staker, uint256 stakeBonusAmount) 
    external 
    onlyOperator
    {
        for(uint256 indx = 0; indx < staker.length; indx++) {
            require(computeAndAddReward(stakeMapIndex, staker[indx], stakeBonusAmount));
        }
    }

    // AirDrop to Stake - Load existing stakes from Air Drop
    function airDropStakes(uint256 stakeMapIndex, address[] calldata staker, uint256[] calldata stakeAmount) external onlyOperator {

        // Add check for Block Number to restrict air drop auto stake phase after certain block number
        require(block.number < maxAirDropStakeBlocks, "Exceeds airdrop auto stake phase");

        // Check Input Parameters
        require(staker.length == stakeAmount.length, "Invalid Input Arrays");

        // Stakers should be for current window
        require(currentStakeMapIndex == stakeMapIndex, "Invalid Stake Window Index");

        for(uint256 indx = 0; indx < staker.length; indx++) {

            StakeInfo memory req;

            // Create a stake request with amount
            req.exist = true;
            req.amount = stakeAmount[indx];
            req.rewardComputeIndex = 0;

            // Add to the Stake Holders List
            stakeHolderInfo[staker[indx]] = req;

            // Add to the Stake Holders List
            stakeHolders.push(staker[indx]);

            // Update the User balance
            balances[staker[indx]] = stakeAmount[indx];

            // Update current stake period total stake - Along with Reward
            windowTotalStake = windowTotalStake.add(stakeAmount[indx]);

        }

    }


    // Getter Functions    
    function getStakeHolders() external view returns(address[] memory) {
        return stakeHolders;
    }

    function getStakeInfo(address staker) 
    external 
    view
    returns (bool found, uint256 amount, uint256 rewardComputeIndex, uint256 bonusAmount) 
    {

        StakeInfo memory stakeInfo = stakeHolderInfo[staker];
        
        found = false;
        if(stakeInfo.exist) {
            found = true;
        }

        amount = stakeInfo.amount;
        rewardComputeIndex = stakeInfo.rewardComputeIndex;
        bonusAmount = stakeInfo.bonusAmount;

    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

