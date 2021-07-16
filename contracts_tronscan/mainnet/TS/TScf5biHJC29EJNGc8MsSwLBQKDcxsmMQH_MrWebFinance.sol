//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//SourceUnit: Stake.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.9 <0.8.0;
import "./IERC20.sol";
import "./SafeMath.sol";

/**  
* @title Staking Platform for MrWebFinance
*/

/**
* @author Laxman Rai, Sangya Sherpa, laxmanrai2058@gmail.com, sangyasherpa2058@gmail.com, +9779849092326, +9779813130596
*/

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

contract MrWebFinance {
    /**
    * @dev Implementation of the {SafeMath}
    * Wrappers over Solidity's arithmetic operations with added overflow
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
    using SafeMath for uint256;
    
    /**
    * @dev User struct contains data of staking platform users.
    */
    struct User 
    {
        uint256 initialInvestment;
        uint256 APYModel;
        uint256 finalCompoundAsset;
        uint256 investmentPeriodEndsAt;
    }

    /**
    * @dev List of users are mapped into users with @param of user address
    */
    mapping(address => User) public users;
    
    /**
    * @dev totalInvestors & totalInvestment gradually increases when new staker stakes $AMA
    */
    uint256 private totalInvestors;
    uint256 private totalInvestment;
    uint256 public currentPoolAmount;

    /**
    * @dev function to get universal data
    * @return integer data of universal data i.e. totalInvestors & totalInvestment
    */
    function getUniversalData()
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        return (totalInvestors, totalInvestment);
    }
    
    /**
    * @dev mrwebfinance, tokenOwner, tokenAddr_ is used for ERC20Interface defined 
    * later in staking function for approvance & allowance of AMA token
    */
    address private mrwebfinance;
    address public tokenOwner;
    address public tokenAddr_;
    
    /**
    * @dev set default mrwebfinance while deployment
    */
    constructor() public {
        mrwebfinance = msg.sender;
    }

    /**
    * @dev function to set token owner and token address
    * @param _owner the address of mrwebfinance project owner 
    * @param _token is AMA contract address
    */
    function setTokenOwner(address _owner, address _token) onlyMrwebfinance public {
        tokenOwner = _owner;
        tokenAddr_ = _token;
    }
    
    /**
    * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
    * the optional functions; to access them see {ERC20Detailed}.
    */
    IERC20 ERC20Interface;
    
    /**
    * @dev modifier to validate the null or 0x0 address
    * @param _addressToValidate address which needs to be validated
    */
    modifier validateNullAddress(address _addressToValidate) 
    {
        require(
            _addressToValidate != msg.sender,
            "User can not indicate themselves!"
        );
        require(_addressToValidate != address(0x0), "Address can not be null!");
        _;
    }
    
    /**
    * @dev modifier to validate minimum investment amount
    * @param _amount minimum amount user need to stake
    */
    modifier _minInvestment(uint256 _amount) 
    {
        require(_amount >= 100000000, "Minimum investment is 100AMA");
        _;
    }
    
    /**
    * @dev modifier to validate apymodel
    * @param _apyModel valid apymodel
    */
    modifier _validApyModel(uint256 _apyModel)
    {
        require(_apyModel == 30 || _apyModel == 60 || _apyModel == 90, "Invalid APY Model!");
        _;    
    }
    
    /**
    * @dev modifier to validate functions only runned by the mrwebfinance project owner
    */
    modifier onlyMrwebfinance 
    {
        require(
            msg.sender == mrwebfinance, "mrwebfinance");
        _;
    }
    
    /**
    * @dev modifier to initialize the ERC20Interface and validate amount
    * @param _amount amount can not be zero
    */
    modifier stakeTokenModifier(uint256 _amount) {
        require(_amount > 0, "Amount can not be 0!");
        require(msg.sender != address(0x0), "User address is null!");
        
        address contract_ = tokenAddr_;
        ERC20Interface =  IERC20(contract_);
        _;
    }
    
    /**
    * @dev modifier to validate if staking period is over or not
    */
    modifier _withdraw 
    {
        require(
            block.timestamp >= users[msg.sender].investmentPeriodEndsAt,
            "Withdraw request before time!"
        );
        _;
    }
    
    /**
    * @dev function to initialize the user after token stake
    */
    function _setUser(uint256 _apyModel, uint256 _amount) private 
    {
        User storage user = users[msg.sender];
        
        user.initialInvestment = _amount;
        user.APYModel = _apyModel;
        if(_apyModel == 30) user.finalCompoundAsset = _amount + (_amount * 7)/100;
        if(_apyModel == 60) user.finalCompoundAsset = _amount + (_amount * 17)/100;
        if(_apyModel == 90) user.finalCompoundAsset = _amount + (_amount * 36)/100;
        
        user.investmentPeriodEndsAt = block.timestamp.add(_apyModel * 86400);
    }
    
    function StakeTokens(uint256 _apyModel, uint256 _amount) stakeTokenModifier(_amount) _validApyModel(_apyModel) _minInvestment(_amount) public payable{
        if(_amount > ERC20Interface.allowance(msg.sender, address(this))) {
            revert();
        }

        bool status = ERC20Interface.transferFrom(msg.sender, address(this), _amount);
        require(status, "Transfer failed!");

        _setUser(_apyModel, _amount);
        totalInvestors += 1;
        totalInvestment += _amount;
        currentPoolAmount += _amount;
    }

    //--------------------------------------------------------------------------------------------------
    // Pay on Withdraw request
    //--------------------------------------------------------------------------------------------------
    
    function payTo(uint256 _amount, address payable _toAddress)
        public
        payable
        onlyMrwebfinance
        stakeTokenModifier(_amount)
    {
        ERC20Interface.transfer(_toAddress, _amount);
    }

    function withdraw() public payable _withdraw stakeTokenModifier(users[msg.sender].finalCompoundAsset)
    {
        bool status = ERC20Interface.transfer(msg.sender, users[msg.sender].finalCompoundAsset);
        require(status, "Transfer failed!");

        currentPoolAmount -= users[msg.sender].initialInvestment;
        
        users[msg.sender].initialInvestment = 0;
        users[msg.sender].APYModel = 0;
        users[msg.sender].finalCompoundAsset = 0;
        users[msg.sender].investmentPeriodEndsAt = 0;
    }
}