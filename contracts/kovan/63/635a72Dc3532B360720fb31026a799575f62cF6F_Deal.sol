pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20Metadata.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IDealCreator.sol";
import "./interfaces/IVerifier.sol";

import "./Pausable.sol";

// import "./Whitelist.sol";

// import "./interfaces/IERC20.sol";

 contract Deal is Ownable, Pausable, ReentrancyGuard  { //Whitelist
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IVerifier public verifier;
    IDealCreator public dealCreator;

    address public paymentToken;
    uint256 public tokenPrice;
    IERC20 public rewardToken;
    uint256 public decimals;
    uint256 public startTimestamp;
    uint256 public finishTimestamp;
    uint256 public startClaimTimestamp;
    uint256 public maxDistributedTokenAmount; 
    uint256 public totalRaise; // Sum of all payments (in payment token)
    uint256 public tokensForDistribution;
    uint256 public minimumRaise;
    uint256 public distributedTokens;
    bool public allowRefund;
    
    struct UserInfo {
        uint debt;
        uint total;
        uint totalPayment; //User's payment sum
    }

    mapping(address => UserInfo) public userInfo;

    event TokensDebt(
        address indexed holder,
        uint256 payAmount,
        uint256 tokenAmount
    );
    
    event Refund(address indexed holder, uint256 amount);

    event TokensWithdrawn(address indexed holder, uint256 amount);
    event FundsWithdrawn(uint256 amount);
    event FundsFeeWithdrawn(uint256 amount);
    event NotSoldWithdrawn(uint256 amount);

    uint256 public vestingPercent;
    uint256 public vestingStart;
    uint256 public vestingInterval;
    uint256 public vestingDuration;

    event VestingUpdated(uint256 _vestingPercent,
                    uint256 _vestingStart,
                    uint256 _vestingInterval,
                    uint256 _vestingDuration);
    event VestingCreated(address indexed holder, uint256 amount);
    event VestingReleased(address indexed holder, uint256 amount);

    struct Vesting {
        uint256 balance;
        uint256 released;
    }

    mapping (address => Vesting) private _vestings;

    TierInfo[] public allTiers;

    struct TierInfo {
        uint256 blpAmount; //min amount of BLP
        uint256 ticketSize; //in payment amount
        uint256 allocation; //tier's allocation amount (in IDO tokens)
        uint256 purchasedTokens; //all purchased tokens of tier
    }

    modifier isActive {
        require(now >= startTimestamp, "Not started");
        require(now < finishTimestamp, "Ended");
        _;
    }

    modifier allowClaimCondition {
        require(now >= startClaimTimestamp, "Claim not started");
        require(!allowRefund || allowRefund && totalRaise >= minimumRaise, "Claim disabled");
        _;
    }

    modifier allowRefundCondition {
        require(now >= startClaimTimestamp, "Refund not started");
        require(allowRefund && totalRaise < minimumRaise, "Refund disabled");
        _;
    }

    constructor(
        IVerifier _verifier,
        address _paymentToken,
        uint256 _tokenPrice,        
        IERC20 _rewardToken,
        uint256 _startTimestamp,
        uint256 _finishTimestamp,
        uint256 _startClaimTimestamp,
        uint256 _minimumRaise,
        uint256 _maxDistributedTokenAmount,
        bool _allowRefund
        // uint256[] memory _tiersAmount
    ) public //Whitelist(true) 
    {
        dealCreator = IDealCreator(msg.sender);
        verifier = _verifier;
        paymentToken = _paymentToken;
        tokenPrice = _tokenPrice;
        rewardToken = _rewardToken;
        decimals = IERC20Metadata(address(_rewardToken)).decimals();

        require( _startTimestamp < _finishTimestamp,  "Start must be less than finish");
        require( _finishTimestamp > now, "Finish must be more than now");
        require( _startClaimTimestamp >= _finishTimestamp,  "Claim must be more than finish");

        startTimestamp = _startTimestamp;
        finishTimestamp = _finishTimestamp;
        startClaimTimestamp = _startClaimTimestamp;
        minimumRaise = _minimumRaise;
        maxDistributedTokenAmount = _maxDistributedTokenAmount;
        allowRefund = _allowRefund;

        // for (uint256 i = 0; i < _tiersAmount.length; i++) {
        //     allTiers.push(TierInfo(_tiersAmount[i], 0, 0, 0));
        // }
    }

    function pay(uint256 _amount, bytes memory _signature) payable external nonReentrant isActive whenNotPaused{ 
        bytes32 message = keccak256(abi.encodePacked(msg.sender, address(this)));
        require(verifier.verify(message, _signature), "INVALID_SIGNATURE");

        if (paymentToken == address(0)) {
            require(_amount == msg.value, "send: amount mismatch");
        } else {
            IERC20(paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        //Find tier
        (bool successTier, uint tierIndex) = getTierIndex(msg.sender);        
        require(successTier, "Tier not found");
        TierInfo storage tier = allTiers[tierIndex];
        require(_amount == tier.ticketSize, "Not correct ticket size");
        dealCreator.userParticipate(msg.sender ,tierIndex);
        uint256 tokenAmount = getTokenAmount(_amount);

        tokensForDistribution = tokensForDistribution.add(tokenAmount);
        require(tokensForDistribution <= maxDistributedTokenAmount, "Overfilled");
       
        tier.purchasedTokens += tokenAmount;
        require(tier.purchasedTokens <= tier.allocation, "Tier filled");
        totalRaise = totalRaise.add(_amount);

        UserInfo storage user = userInfo[msg.sender];
        user.totalPayment = user.totalPayment.add(_amount);
        require(user.totalPayment == tier.ticketSize, "Exceed ticket size");

        user.total = user.total.add(tokenAmount);
        user.debt = user.debt.add(tokenAmount);        

        emit TokensDebt(msg.sender, _amount, tokenAmount);
    }

    function getTierIndex(address user) public view
             returns (bool, uint)
    {
        uint256 blpBalance = dealCreator.getLockedBLP(user);
        uint tierIndex;
        bool success;
        for (uint256 i = 0; i < allTiers.length; i++) {            
            if (blpBalance >= allTiers[i].blpAmount
                //Check that next level is higher than previous
                && allTiers[i].blpAmount >= allTiers[tierIndex].blpAmount) {
                tierIndex = i;
                success = true;
            }
        }
        return (success, tierIndex);
    }

    /// @dev Return amount of purchased tokens for payment
    function getTokenAmount(uint256 paymentAmount) public view
             returns (uint256)
    {
        return paymentAmount.mul(10**decimals).div(tokenPrice);
    }


    /// @dev Allows to claim tokens for the specific user.
    /// @param _addresses Token receivers.
    function claimFor(address[] memory _addresses) external whenNotPaused
    {
         for (uint i = 0; i < _addresses.length; i++) {
            proccessClaim(_addresses[i]);
        }
    }

    /// @dev Allows to claim tokens for themselves.
    function claim() external whenNotPaused
    {
        proccessClaim(msg.sender);
    }

    /// @dev Proccess the claim.
    /// @param _receiver Token receiver.
    function proccessClaim(address _receiver) internal nonReentrant allowClaimCondition
    {
        UserInfo storage user = userInfo[_receiver];
        uint256 _amount = user.debt;
        if (_amount > 0) {
            user.debt = 0;            
            distributedTokens = distributedTokens.add(_amount);

            if(vestingPercent > 0)
            {   
                uint256 vestingAmount = _amount.mul(vestingPercent).div(100);
                createVesting(_receiver, vestingAmount);
                _amount = _amount.sub(vestingAmount);
            }

            rewardToken.safeTransfer(_receiver, _amount);
            emit TokensWithdrawn(_receiver,_amount);
        }
    }

    /// @dev Proccess the refund.
    function refund() external whenNotPaused nonReentrant allowRefundCondition
    {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.totalPayment;
        user.totalPayment = 0;

        if (paymentToken == address(0)) {
            msg.sender.transfer(amount);
        } else {
            IERC20(paymentToken).safeTransfer(msg.sender, amount);
        }   
        emit TokensWithdrawn(msg.sender, amount);
    }

    /* VESTING */

    function getVesting(address beneficiary) public view 
             returns (uint256, uint256) {
        Vesting memory v = _vestings[beneficiary];
        return (v.balance, v.released);
    }

    function createVesting(address beneficiary, uint256 amount) private 
    {
        Vesting storage vest = _vestings[beneficiary];
        require(vest.balance == 0, "Vesting already created");

        vest.balance = amount;

        emit VestingCreated(beneficiary, amount);
    }

     function release(address beneficiary) external nonReentrant 
     {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0, "Nothing to release");

        Vesting storage vest = _vestings[beneficiary];

        vest.released = vest.released.add(unreleased);
        vest.balance = vest.balance.sub(unreleased);

        rewardToken.safeTransfer(beneficiary, unreleased);
        emit VestingReleased(beneficiary, unreleased);
    }

    function releasableAmount(address beneficiary) public view 
             returns (uint256) 
    {
        return vestedAmount(beneficiary).sub(_vestings[beneficiary].released);
    }

    function vestedAmount(address beneficiary) public view 
             returns (uint256) 
    {
        if (now < vestingStart) {
            return 0;
        }

        Vesting memory vest = _vestings[beneficiary];
        uint256 currentBalance = vest.balance;
        uint256 totalBalance = currentBalance.add(vest.released);

        if (now >= vestingStart.add(vestingDuration)) {
            return totalBalance;
        } else {
            uint256 numberOfInvervals = now.sub(vestingStart).div(vestingInterval);
            uint256 totalIntervals = vestingDuration.div(vestingInterval);
            return totalBalance.mul(numberOfInvervals).div(totalIntervals);
        }
    }

    /* TIERS */

    // function getTier(uint256 index) public view
    //          returns (uint256, uint256, uint256)
    // {
    //     TierInfo memory tier = allTiers[index];
    //     return (tier.blpAmount, tier.ticketSize, tier.purchasedTokens);
    // }

    function getTiersLength() public view
             returns (uint256)
    {
        return allTiers.length;
    }

    /* OWNER UPDATE SETTINGS */

    function withdrawFunds() external onlyOwner nonReentrant allowClaimCondition
    {
        uint256 amount;
        if (paymentToken == address(0)) {
            amount = address(this).balance;
            msg.sender.transfer(amount);
        } else {
            amount = IERC20(paymentToken).balanceOf(address(this));
            IERC20(paymentToken).safeTransfer(msg.sender, amount);
        }   
        emit FundsWithdrawn(amount);
    }
     
    function withdrawNotSoldTokens() external onlyOwner nonReentrant
    {
        require(now > finishTimestamp, "Allow after finish time");
        uint256 amount = rewardToken.balanceOf(address(this)).add(distributedTokens).sub(tokensForDistribution);
        if(allowRefund && totalRaise < minimumRaise){
            amount = rewardToken.balanceOf(address(this));
        }

        rewardToken.safeTransfer(msg.sender, amount);
        emit NotSoldWithdrawn(amount);
    }
    
    function setVesting(uint256 _percent,
                        uint256 _start,
                        uint256 _interval,
                        uint256 _duration) external onlyOwner 
    {

        require(now < startTimestamp, "Already started");

        require(_percent <= 100, "Percent <= 100");
        if(_percent > 0)
        {
            require(_interval > 0 , "interval > 0");
            require(_duration >= _interval, "interval >= duration");
        }

        vestingPercent = _percent;
        vestingStart = _start;
        vestingInterval = _interval;
        vestingDuration = _duration;

        emit VestingUpdated(vestingPercent,
                            vestingStart,
                            vestingInterval,
                            vestingDuration);
    }

    function updateTier(uint256 index, uint256 blpAmount, uint256 ticketSize, uint256 allocation) external onlyOwner{
        require(index < allTiers.length , "Incorrect index");
        TierInfo storage tier = allTiers[index];
        require(allocation >= tier.purchasedTokens, "Allocation less purchased");
        tier.blpAmount = blpAmount;
        tier.ticketSize = ticketSize;
        tier.allocation = allocation;
        checkExceedTiers();
    }

    function addTier(uint256 blpAmount, uint256 ticketSize, uint256 allocation) external onlyOwner{
        allTiers.push(TierInfo(blpAmount, ticketSize, allocation, 0));
        checkExceedTiers();
    }

    // Contract code size exceeds 24576 bytes 
    // function addTier(uint256[] memory blpAmount, uint256[] memory ticketSize, uint256[] memory allocation) external onlyOwner{
    //     for (uint256 i = 0; i < blpAmount.length; i++) {
    //         allTiers.push(TierInfo(blpAmount[i], ticketSize[i], allocation[i], 0));
    //     }
    //     checkExceedTiers();
    // }

    function checkExceedTiers() private view
    {
        //check that sum of allocation < maxDistributedTokenAmount
        uint256 sumAmount;
        for (uint256 i = 0; i < allTiers.length; i++) {            
            sumAmount += allTiers[i].allocation;
        }
        require(sumAmount <= maxDistributedTokenAmount, "Exceed"); //Exceed max token for distribution
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Has to be unpaused");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Has to be paused");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

pragma solidity 0.6.12;

interface IDealCreator {
    function userParticipate(address user, uint256 tierIndex) external;

    function getLockedBLP(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "../IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity 0.6.12;

interface IVerifier {
    
    function verify(bytes32 _message, bytes memory _signature) external view returns (bool);
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

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.2 <0.8.0;

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

