/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;



contract POLContract {

    event Received(address, uint);
    event onDeposit(address, uint256, uint256);
    event onWithdraw(address, uint256);

    using SafeMath for uint256;

    struct VestingPeriod {
      uint256 epoch;
      uint256 amount;
    }

    struct UserTokenInfo {
      uint256 deposited; // incremented on successful deposit
      uint256 withdrawn; // incremented on successful withdrawl
      VestingPeriod[] vestingPeriods; // added to on successful deposit
    }

    // map erc20 token to user address to release schedule
    mapping(address => mapping(address => UserTokenInfo)) tokenUserMap;

    struct LiquidityTokenomics {
      uint256[] epochs;
      mapping (uint256 => uint256) releaseMap; // map epoch -> amount withdrawable
    }

    // map erc20 token to release schedule
    mapping(address => LiquidityTokenomics) tokenEpochMap;

    
    // Fast mapping to prevent array iteration in solidity
    mapping(address => bool) public lockedTokenLookup;

    // A dynamically-sized array of currently locked tokens
    address[] public lockedTokens;
    
    // fee variables
    uint256 public feeNumerator;
    uint256 public feeDenominator;
    
    address public feeReserveAddress;
    address public owner;
    
    constructor() public {                  
      feeNumerator = 3;
      feeDenominator = 1000;
      feeReserveAddress = address(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
      owner = address(0xfCdd591498e86876F086524C0b2E9Af41a0c9FCD);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    modifier onlyOwner {
      require(msg.sender == owner, "You are not the owner");
      _;
    }
    
    function updateFee(uint256 numerator, uint256 denominator) onlyOwner public {
      feeNumerator = numerator;
      feeDenominator = denominator;
    }
    
    function calculateFee(uint256 amount) public view returns (uint256){
      require(amount >= feeDenominator, 'Deposit is too small');    
      uint256 amountInLarge = amount.mul(feeDenominator.sub(feeNumerator));
      uint256 amountIn = amountInLarge.div(feeDenominator);
      uint256 fee = amount.sub(amountIn);
      return (fee);
    }
    
    function depositTokenMultipleEpochs(address token, uint256[] memory amounts, uint256[] memory dates) public payable {
      require(amounts.length == dates.length, 'Amount and date arrays have differing lengths');
      for (uint i=0; i<amounts.length; i++) {
        depositToken(token, amounts[i], dates[i]);
      }
    }

    function depositToken(address token, uint256 amount, uint256 unlock_date) public payable {
      require(unlock_date < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
      require(amount > 0, 'Your attempting to trasfer 0 tokens');
      uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
      require(allowance >= amount, 'You need to set a higher allowance');
      // charge a fee
      uint256 fee = calculateFee(amount);
      uint256 amountIn = amount.sub(fee);
      require(IERC20(token).transferFrom(msg.sender, address(this), amountIn), 'Transfer failed');
      require(IERC20(token).transferFrom(msg.sender, address(feeReserveAddress), fee), 'Transfer failed');
      if (!lockedTokenLookup[token]) {
        lockedTokens.push(token);
        lockedTokenLookup[token] = true;
      }
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[token];
      // amount is required to be above 0 in the start of this block, therefore this works
      if (liquidityTokenomics.releaseMap[unlock_date] > 0) {
        liquidityTokenomics.releaseMap[unlock_date] = liquidityTokenomics.releaseMap[unlock_date].add(amountIn);
      } else {
        liquidityTokenomics.epochs.push(unlock_date);
        liquidityTokenomics.releaseMap[unlock_date] = amountIn;
      }
      UserTokenInfo storage uto = tokenUserMap[token][msg.sender];
      uto.deposited = uto.deposited.add(amountIn);
      VestingPeriod[] storage vp = uto.vestingPeriods;
      vp.push(VestingPeriod(unlock_date, amountIn));
      
      emit onDeposit(token, amount, unlock_date);
    }

    function withdrawToken(address token, uint256 amount) public {
      require(amount > 0, 'Your attempting to withdraw 0 tokens');
      uint256 withdrawable = getWithdrawableBalance(token, msg.sender);
      UserTokenInfo storage uto = tokenUserMap[token][msg.sender];
      uto.withdrawn = uto.withdrawn.add(amount);
      require(amount <= withdrawable, 'Your attempting to withdraw more than you have available');
      require(IERC20(token).transfer(msg.sender, amount), 'Transfer failed');
      emit onWithdraw(token, amount);
    }

    function getWithdrawableBalance(address token, address user) public view returns (uint256) {
      UserTokenInfo storage uto = tokenUserMap[token][address(user)];
      uint arrayLength = uto.vestingPeriods.length;
      uint256 withdrawable = 0;
      for (uint i=0; i<arrayLength; i++) {
        VestingPeriod storage vestingPeriod = uto.vestingPeriods[i];
        if (vestingPeriod.epoch < block.timestamp) {
          withdrawable = withdrawable.add(vestingPeriod.amount);
        }
      }
      withdrawable = withdrawable.sub(uto.withdrawn);
      return withdrawable;
    }
    
    function getUserTokenInfo (address token, address user) public view returns (uint256, uint256, uint256) {
      UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
      uint256 deposited = uto.deposited;
      uint256 withdrawn = uto.withdrawn;
      uint256 length = uto.vestingPeriods.length;
      return (deposited, withdrawn, length);
    }

    function getUserVestingAtIndex (address token, address user, uint index) public view returns (uint256, uint256) {
      UserTokenInfo storage uto = tokenUserMap[address(token)][address(user)];
      VestingPeriod storage vp = uto.vestingPeriods[index];
      return (vp.epoch, vp.amount);
    }

    function getTokenReleaseLength (address token) public view returns (uint256) {
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
      return liquidityTokenomics.epochs.length;
    }

    function getTokenReleaseAtIndex (address token, uint index) public view returns (uint256, uint256) {
      LiquidityTokenomics storage liquidityTokenomics = tokenEpochMap[address(token)];
      uint256 epoch = liquidityTokenomics.epochs[index];
      uint256 amount = liquidityTokenomics.releaseMap[epoch];
      return (epoch, amount);
    }
    
    function lockedTokensLength() external view returns (uint) {
        return lockedTokens.length;
    }
}

pragma solidity 0.6.11;

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

pragma solidity 0.6.11;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}