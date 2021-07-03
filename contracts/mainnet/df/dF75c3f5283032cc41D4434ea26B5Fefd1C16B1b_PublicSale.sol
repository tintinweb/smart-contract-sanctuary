//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import { InvestorsVesting, IVesting } from './InvestorsVesting.sol';
import { LiquidityProvider, ILiquidityProvider } from './LiquidityProvider.sol';
import './CliffVesting.sol';
import './interfaces/IPublicSale.sol';
import './interfaces/IOneUp.sol';


contract PublicSale is IPublicSale, Ownable {
    using SafeMath for uint256;

    bool public privateSaleFinished;
    bool public liquidityPoolCreated;

    IOneUp public oneUpToken;
    IVesting public immutable vesting;
    ILiquidityProvider public immutable lpProvider;

    address public reserveLockContract;
    address public marketingLockContract;
    address public developerLockContract;
    address payable public immutable publicSaleFund;

    uint256 public totalDeposits;
    uint256 public publicSaleStartTimestamp;
    uint256 public publicSaleFinishedAt;

    uint256 public constant PUBLIC_SALE_DELAY = 7 days;
    uint256 public constant LP_CREATION_DELAY = 30 minutes;
    uint256 public constant TRADING_BLOCK_DELAY = 15 minutes;
    uint256 public constant WHITELISTED_USERS_ACCESS = 2 hours;

    uint256 public constant PUBLIC_SALE_LOCK_PERCENT = 5000;  // 50% of tokens
    uint256 public constant PRIVATE_SALE_LOCK_PERCENT = 1500; // 15% of tokens
    uint256 public constant PUBLIC_SALE_PRICE = 151000;       // 1 ETH = 151,000 token

    uint256 public constant HARD_CAP_ETH_AMOUNT = 300 ether;
    uint256 public constant MIN_DEPOSIT_ETH_AMOUNT = 0.1 ether;
    uint256 public constant MAX_DEPOSIT_ETH_AMOUNT = 3 ether;

    mapping(address => uint256) internal _deposits;
    mapping(address => uint256) internal _whitelistedAmount;

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event EmergencyWithdrawn(address user, uint256 amount);
    event UsersWhitelisted(address[] users, uint256 maxAmount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address oneUpToken_, address payable publicSaleFund_, address uniswapRouter_) {
        require(oneUpToken_ != address(0), 'PublicSale: Empty token address!');
        require(publicSaleFund_ != address(0), 'PublicSale: Empty fund address!');
        require(uniswapRouter_ != address(0), 'PublicSale: Empty uniswap router address!');

        oneUpToken = IOneUp(oneUpToken_);
        publicSaleFund = publicSaleFund_;

        address vestingAddr = address(new InvestorsVesting(oneUpToken_));
        vesting = IVesting(vestingAddr);

        address lpProviderAddr = address(new LiquidityProvider(oneUpToken_, uniswapRouter_));
        lpProvider = ILiquidityProvider(lpProviderAddr);
    }

    // ------------------------
    // PAYABLE RECEIVE
    // ------------------------

    /// @notice Public receive method which accepts ETH
    /// @dev It can be called ONLY when private sale finished, and public sale is active
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(privateSaleFinished, 'PublicSale: Private sale not finished yet!');
        require(publicSaleFinishedAt == 0, 'PublicSale: Public sale already ended!');
        require(block.timestamp >= publicSaleStartTimestamp && block.timestamp <= publicSaleStartTimestamp.add(PUBLIC_SALE_DELAY), 'PublicSale: Time was reached!');
        require(totalDeposits.add(msg.value) <= HARD_CAP_ETH_AMOUNT, 'PublicSale: Deposit limits reached!');
        require(_deposits[msg.sender].add(msg.value) >= MIN_DEPOSIT_ETH_AMOUNT && _deposits[msg.sender].add(msg.value) <= MAX_DEPOSIT_ETH_AMOUNT, 'PublicSale: Limit is reached or not enough amount!');

        // Check the whitelisted status during the the first 2 hours
        if (block.timestamp < publicSaleStartTimestamp.add(WHITELISTED_USERS_ACCESS)) {
            require(_whitelistedAmount[msg.sender] > 0, 'PublicSale: Its time for whitelisted investors only!');
            require(_whitelistedAmount[msg.sender] >= msg.value, 'PublicSale: Sent amount should not be bigger from allowed limit!');
            _whitelistedAmount[msg.sender] = _whitelistedAmount[msg.sender].sub(msg.value);
        }

        _deposits[msg.sender] = _deposits[msg.sender].add(msg.value);
        totalDeposits = totalDeposits.add(msg.value);

        uint256 tokenAmount = msg.value.mul(PUBLIC_SALE_PRICE);
        vesting.submit(msg.sender, tokenAmount, PUBLIC_SALE_LOCK_PERCENT);

        emit Deposited(msg.sender, msg.value);
    }

    // ------------------------
    // SETTERS (PUBLIC)
    // ------------------------

    /// @notice Finish public sale
    /// @dev It can be called by anyone, if deadline or hard cap was reached
    function endPublicSale() external override {
        require(publicSaleFinishedAt == 0, 'endPublicSale: Public sale already finished!');
        require(privateSaleFinished, 'endPublicSale: Private sale not finished yet!');
        require(block.timestamp > publicSaleStartTimestamp.add(PUBLIC_SALE_DELAY) || totalDeposits.add(1 ether) >= HARD_CAP_ETH_AMOUNT, 'endPublicSale: Can not be finished!');
        publicSaleFinishedAt = block.timestamp;
    }

    /// @notice Distribute collected ETH between company/liquidity provider and create liquidity pool
    /// @dev It can be called by anyone, after LP_CREATION_DELAY from public sale finish
    function addLiquidity() external override  {
        require(!liquidityPoolCreated, 'addLiquidity: Pool already created!');
        require(publicSaleFinishedAt != 0, 'addLiquidity: Public sale not finished!');
        require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY), 'addLiquidity: Time was not reached!');

        liquidityPoolCreated = true;

        // Calculate distribution and liquidity amounts
        uint256 balance = address(this).balance;
        // Prepare 60% of all ETH for LP creation
        uint256 liquidityEth = balance.mul(6000).div(10000);

        // Transfer ETH to pre-sale address and liquidity provider
        publicSaleFund.transfer(balance.sub(liquidityEth));
        payable(address(lpProvider)).transfer(liquidityEth);

        // Create liquidity pool
        lpProvider.addLiquidity();

        // Start vesting for investors
        vesting.setStart();

        // Tokens will be tradable in TRADING_BLOCK_DELAY
        oneUpToken.setTradingStart(block.timestamp.add(TRADING_BLOCK_DELAY));
    }

    /// @notice Investor withdraw invested funds
    /// @dev Method will be available after 1 day if liquidity was not added
    function emergencyWithdrawFunds() external override {
      require(!liquidityPoolCreated, 'emergencyWithdrawFunds: Liquidity pool already created!');
      require(publicSaleFinishedAt != 0, 'emergencyWithdrawFunds: Public sale not finished!');
      require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY).add(1 days), 'emergencyWithdrawFunds: Not allowed to call now!');

      uint256 investedAmount = _deposits[msg.sender];
      require(investedAmount > 0, 'emergencyWithdrawFunds: No funds to receive!');

      // Reset user vesting information
      vesting.reset(msg.sender);

      // Transfer funds back to the user
      _deposits[msg.sender] = 0;
      payable(msg.sender).transfer(investedAmount);

      emit EmergencyWithdrawn(msg.sender, investedAmount);
    }

    // ------------------------
    // SETTERS (OWNABLE)
    // ------------------------

    /// @notice Admin can manually add private sale investors with this method
    /// @dev It can be called ONLY during private sale, also lengths of addresses and investments should be equal
    /// @param investors Array of investors addresses
    /// @param amounts Tokens Amount which investors needs to receive (INVESTED ETH * 200.000)
    function addPrivateAllocations(address[] memory investors, uint256[] memory amounts) external override onlyOwner {
        require(!privateSaleFinished, 'addPrivateAllocations: Private sale is ended!');
        require(investors.length > 0, 'addPrivateAllocations: Array can not be empty!');
        require(investors.length == amounts.length, 'addPrivateAllocations: Arrays should have the same length!');

        vesting.submitMulti(investors, amounts, PRIVATE_SALE_LOCK_PERCENT);
    }

    /// @notice Finish private sale and start public sale
    /// @dev It can be called once and ONLY during private sale, by admin
    function endPrivateSale() external override onlyOwner {
        require(!privateSaleFinished, 'endPrivateSale: Private sale is ended!');

        privateSaleFinished = true;
        publicSaleStartTimestamp = block.timestamp;
    }

    /// @notice Recover contract based tokens
    /// @dev Should be called by admin only to recover lost tokens
    function recoverERC20(address tokenAddress) external override onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
        emit Recovered(tokenAddress, balance);
    }

    /// @notice Recover locked LP tokens when time reached
    /// @dev Should be called by admin only, and tokens will be transferred to the owner address
    function recoverLpToken(address lPTokenAddress) external override onlyOwner {
        lpProvider.recoverERC20(lPTokenAddress, msg.sender);
    }

    /// @notice Mint and lock tokens for team, marketing, reserve
    /// @dev Only admin can call it once, after liquidity pool creation
    function lockCompanyTokens(address developerReceiver, address marketingReceiver, address reserveReceiver) external override {
        require(marketingReceiver != address(0) && reserveReceiver != address(0) && developerReceiver != address(0), 'lockCompanyTokens: Can not be zero address!');
        require(marketingLockContract == address(0) && reserveLockContract == address(0) && developerLockContract == address(0), 'lockCompanyTokens: Already locked!');
        require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY), 'lockCompanyTokens: Should be called after LP creation!');
        require(liquidityPoolCreated, 'lockCompanyTokens: Pool was not created!');

        developerLockContract = address(new CliffVesting(developerReceiver, 30 days, 180 days, address(oneUpToken)));    //  1 month cliff  6 months vesting
        marketingLockContract = address(new CliffVesting(marketingReceiver, 7 days, 90 days, address(oneUpToken)));      //  7 days cliff   3 months vesting
        reserveLockContract = address(new CliffVesting(reserveReceiver, 270 days, 360 days, address(oneUpToken)));        //  9 months cliff 3 months vesting

        oneUpToken.mint(developerLockContract, 2000000 ether);  // 2 mln tokens
        oneUpToken.mint(marketingLockContract, 2000000 ether);  // 2 mln tokens
        oneUpToken.mint(reserveLockContract, 500000 ether);    // 500k tokens
    }

    /// @notice Whitelist public sale privileged users
    /// @dev This users allowed to invest during the first 2 hours
    /// @param users list of addresses
    /// @param maxEthDeposit max amount of ETH which users allowed to invest during this period
    function whitelistUsers(address[] calldata users, uint256 maxEthDeposit) external override onlyOwner {
        require(users.length > 0, 'setWhitelistUsers: Empty array!');

        uint256 usersLength = users.length;
        for (uint256 i = 0; i < usersLength; i++) {
            address user = users[i];
            _whitelistedAmount[user] = _whitelistedAmount[user].add(maxEthDeposit);
        }

        emit UsersWhitelisted(users, maxEthDeposit);
    }


    // ------------------------
    // GETTERS
    // ------------------------

    /// @notice Returns how much provided user can invest during the first 2 hours (if whitelisted)
    /// @param user address
    function getWhitelistedAmount(address user) external override view returns (uint256) {
        return _whitelistedAmount[user];
    }

    /// @notice Returns how much user invested during the whole public sale
    /// @param user address
    function getUserDeposits(address user) external override view returns (uint256) {
        return _deposits[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IOneUp.sol';
import './interfaces/IVesting.sol';


contract InvestorsVesting is IVesting, Ownable {
    using SafeMath for uint256;

    uint256 public start;
    uint256 public finish;

    uint256 public constant RATE_BASE = 10000; // 100%
    uint256 public constant VESTING_DELAY = 90 days;

    IOneUp public immutable oneUpToken;

    struct Investor {
        // If user keep his tokens during the all vesting delay
        // He becomes privileged user and will be allowed to do some extra stuff
        bool isPrivileged;

        // Tge tokens will be available for claiming immediately after UNI liquidity creation
        // Users will receive all available TGE tokens with 1 transaction
        uint256 tgeTokens;

        // Released locked tokens shows amount of tokens, which user already received
        uint256 releasedLockedTokens;

        // Total locked tokens shows total amount, which user should receive in general
        uint256 totalLockedTokens;
    }

    mapping(address => Investor) internal _investors;

    event NewPrivilegedUser(address investor);
    event TokensReceived(address investor, uint256 amount, bool isLockedTokens);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address token_) {
        oneUpToken = IOneUp(token_);
    }

    // ------------------------
    // SETTERS (ONLY PRE-SALE)
    // ------------------------

    /// @notice Add investor and receivable amount for future claiming
    /// @dev This method can be called only by Public sale contract, during the public sale
    /// @param investor Address of investor
    /// @param amount Tokens amount which investor should receive in general
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submit(
        address investor,
        uint256 amount,
        uint256 lockPercent
    ) public override onlyOwner {
        require(start == 0, 'submit: Can not be added after liquidity pool creation!');

        uint256 tgeTokens = amount.mul(lockPercent).div(RATE_BASE);
        uint256 lockedAmount = amount.sub(tgeTokens);

        _investors[investor].tgeTokens = _investors[investor].tgeTokens.add(tgeTokens);
        _investors[investor].totalLockedTokens = _investors[investor].totalLockedTokens.add(lockedAmount);
    }

    /// @notice Remove investor data
    /// @dev Owner will remove investors data if they called emergency exit method
    /// @param investor Address of investor
    function reset(address investor) public override onlyOwner {
      delete _investors[investor];
    }

    /// @notice The same as submit, but for multiply investors
    /// @dev Provided arrays should have the same length
    /// @param investors Array of investors
    /// @param amounts Array of receivable amounts
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submitMulti(
        address[] memory investors,
        uint256[] memory amounts,
        uint256 lockPercent
    ) external override onlyOwner {
        uint256 investorsLength = investors.length;

        for (uint i = 0; i < investorsLength; i++) {
            submit(investors[i], amounts[i], lockPercent);
        }
    }

    /// @notice Start vesting process
    /// @dev After this method investors can claim their tokens
    function setStart() external override onlyOwner {
        start = block.timestamp;
        finish = start.add(VESTING_DELAY);
    }

    // ------------------------
    // SETTERS (ONLY CONTRIBUTOR)
    // ------------------------

    /// @notice Claim TGE tokens immediately after start
    /// @dev Can be called once for each investor
    function claimTgeTokens() external override {
        require(start > 0, 'claimTgeTokens: TGE tokens not available now!');

        // Get user available TGE tokens
        uint256 amount = _investors[msg.sender].tgeTokens;
        require(amount > 0, 'claimTgeTokens: No available tokens!');

        // Update user available TGE balance
        _investors[msg.sender].tgeTokens = 0;

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, amount);

        emit TokensReceived(msg.sender, amount, false);
    }

    /// @notice Claim locked tokens
    function claimLockedTokens() external override {
        require(start > 0, 'claimLockedTokens: Locked tokens not available now!');

        // Get user releasable tokens
        uint256 availableAmount = _releasableAmount(msg.sender);
        require(availableAmount > 0, 'claimLockedTokens: No available tokens!');

        // If investors claim all tokens after vesting finish they become privileged
        // No need to validate flag every time, as users will claim all tokens with this method
        if (_investors[msg.sender].releasedLockedTokens == 0 && block.timestamp > finish) {
            _investors[msg.sender].isPrivileged = true;

            emit NewPrivilegedUser(msg.sender);
        }

        // Update user released locked tokens amount
        _investors[msg.sender].releasedLockedTokens = _investors[msg.sender].releasedLockedTokens.add(availableAmount);

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, availableAmount);

        emit TokensReceived(msg.sender, availableAmount, true);
    }

    // ------------------------
    // GETTERS
    // ------------------------

    /// @notice Get current available locked tokens
    /// @param investor address
    function getReleasableLockedTokens(address investor) external override view returns (uint256) {
        return _releasableAmount(investor);
    }

    /// @notice Get investor data
    /// @param investor address
    function getUserData(address investor) external override view returns (
        uint256 tgeAmount,
        uint256 releasedLockedTokens,
        uint256 totalLockedTokens
    ) {
        return (
            _investors[investor].tgeTokens,
            _investors[investor].releasedLockedTokens,
            _investors[investor].totalLockedTokens
        );
    }

    /// @notice Is investor privileged or not, it will be used from external contracts
    /// @param account user address
    function isPrivilegedInvestor(address account) external override view returns (bool) {
        return _investors[account].isPrivileged;
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor).sub(_investors[investor].releasedLockedTokens);
    }

    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 userMaxTokens = _investors[investor].totalLockedTokens;

        if (start == 0 || block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= finish) {
            return userMaxTokens;
        } else {
            uint256 timeSinceStart = block.timestamp.sub(start);
            return userMaxTokens.mul(timeSinceStart).div(VESTING_DELAY);
        }
    }

    function getStartTime() external view returns (uint256) {
        return start;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/ILiquidityProvider.sol';
import './interfaces/IOneUp.sol';


contract LiquidityProvider is ILiquidityProvider, Ownable {
    using SafeMath for uint256;

    uint256 public lock;
    uint256 public constant UNISWAP_TOKEN_PRICE = 120000; // 1 ETH = 120,000 1-UP
    uint256 public constant LP_TOKENS_LOCK_DELAY = 180 days;

    IOneUp public immutable oneUpToken;
    IUniswapV2Router02 public immutable uniswap;

    event Provided(uint256 token, uint256 amount);
    event Recovered(address token, uint256 amount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address oneUpToken_, address uniswapRouter_) {
        oneUpToken = IOneUp(oneUpToken_);
        uniswap = IUniswapV2Router02(uniswapRouter_);
    }

    receive() external payable {
        // Silence
    }

    // ------------------------
    // SETTERS (OWNABLE)
    // ------------------------

    /// @notice Owner can add liquidity to the 1-UP/ETH pool
    /// @dev If ETH balance of the contract is 0 transaction will be declined
    function addLiquidity() public override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'addLiquidity: ETH balance is zero!');

        uint256 amountTokenDesired = balance.mul(UNISWAP_TOKEN_PRICE);
        oneUpToken.mint(address(this), amountTokenDesired);
        oneUpToken.approve(address(uniswap), amountTokenDesired);

        uniswap.addLiquidityETH{value: (balance)}(
            address(oneUpToken),
            amountTokenDesired,
            amountTokenDesired,
            balance,
            address(this),
            block.timestamp.add(2 hours)
        );

        lock = block.timestamp;
        emit Provided(amountTokenDesired, balance);
    }

    /// @notice Owner can recover LP tokens after LP_TOKENS_LOCK_DELAY from adding liquidity
    /// @dev If time does not reached method will be failed
    /// @param lpTokenAddress Address of 1-UP/ETH LP token
    /// @param receiver Address who should receive tokens
    function recoverERC20(address lpTokenAddress, address receiver) public override onlyOwner {
        require(lock != 0, 'recoverERC20: Liquidity not added yet!');
        require(block.timestamp >= lock.add(LP_TOKENS_LOCK_DELAY), 'recoverERC20: You can claim LP tokens after 180 days!');

        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(receiver, balance);

        emit Recovered(lpTokenAddress, balance);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CliffVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public released;

    // Beneficiary of token after they are released
    address public immutable beneficiary;
    IERC20 public immutable token;

    event TokensReleased(uint256 amount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    /// @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    /// beneficiary, gradually in a linear fashion until start + duration. By then all
    /// of the balance will have vested.
    /// @param beneficiary_ address of the beneficiary to whom vested token are transferred
    /// @param cliffDuration_ duration in seconds of the cliff in which token will begin to vest
    /// @param duration_ duration in seconds of the period in which the token will vest
    /// @param token_ address of the locked token
    constructor(
        address beneficiary_,
        uint256 cliffDuration_,
        uint256 duration_,
        address token_
    ) {
        require(beneficiary_ != address(0));
        require(token_ != address(0));
        require(cliffDuration_ <= duration_);
        require(duration_ > 0);

        beneficiary = beneficiary_;
        token = IERC20(token_);
        duration = duration_;
        start = block.timestamp;
        cliff = block.timestamp.add(cliffDuration_);
    }

    // ------------------------
    // SETTERS
    // ------------------------

    /// @notice Transfers vested tokens to beneficiary
    function release() external {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(unreleased);
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    /// @notice Calculates the amount that has already vested but hasn't been released yet
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(released);
    }

    /// @notice Calculates the amount that has already vested
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface IPublicSale {
    function addLiquidity() external;
    function endPublicSale() external;
    function endPrivateSale() external;
    function emergencyWithdrawFunds() external;
    function recoverERC20(address tokenAddress) external;
    function recoverLpToken(address lPTokenAddress) external;
    function addPrivateAllocations(address[] memory investors, uint256[] memory amounts) external;
    function lockCompanyTokens(address marketing, address reserve, address development) external;
    function whitelistUsers(address[] calldata users, uint256 maxEthDeposit) external;
    function getWhitelistedAmount(address user) external view returns (uint256);
    function getUserDeposits(address user) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IOneUp is IERC20 {
    function burn(uint256 amount) external;
    function setTradingStart(uint256 time) external;
    function mint(address to, uint256 value) external;
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface IVesting {
    function submit(address investor, uint256 amount, uint256 lockPercent) external;
    function submitMulti(address[] memory investors, uint256[] memory amounts, uint256 lockPercent) external;
    function setStart() external;
    function claimTgeTokens() external;
    function claimLockedTokens() external;
    function reset(address investor) external;
    function isPrivilegedInvestor(address account) external view returns (bool);
    function getReleasableLockedTokens(address investor) external view returns (uint256);
    function getUserData(address investor) external view returns (uint256 tgeAmount, uint256 releasedLockedTokens, uint256 totalLockedTokens);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface ILiquidityProvider {
    function addLiquidity() external;
    function recoverERC20(address lpTokenAddress, address receiver) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}