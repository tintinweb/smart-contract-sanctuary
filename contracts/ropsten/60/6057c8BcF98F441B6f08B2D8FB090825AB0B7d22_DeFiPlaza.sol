// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IDeFiPlaza.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * DeFi Plaza is a single controct, multi token DEX which allows trades between any two tokens.
 * Trades between two tokens always follow the familiar localized bonding curve x*y=k
 * The number of tokens used is hardcoded to 16 for efficiency reasons.
 */
contract DeFiPlaza is IDeFiPlaza, Ownable, ERC20 {
  using SafeMath for uint256;

  // States that each token can be in
  enum State {Unlisted, PreListing, Delisting, Listed}

  // Configuration per token. Still some bits available if needed
  struct TokenSettings {
    State state;                      // What state the token is currently in
    uint112 listingTarget;            // Amount of tokens needed to activate listing
  }

  // Exchange configuration
  struct Config {
    bool unlocked;                    // Locked for trading to prevent re-entrancy misery
    uint64 oneMinusTradingFee;        // One minus the swap fee (0.64 fixed point integer)
    uint40 delistingBonus;            // Amount of additional tokens to encourage immediate delisting (0.40 fixed point)
  }

  // Keeps track of whether there is a listing change underway and if so between which tokens
  struct ListingUpdate {
    address tokenToDelist;            // Token to be removed
    address tokenToList;              // Token to be listed
  }

  // Mapping to keep track of the listed tokens
  mapping(address => TokenSettings) public listedTokens;
  Config public DFP_config;
  ListingUpdate public listingUpdate;

  /**
  * Sets up default configuration
  * Initialize with ordered list of 15 token addresses (ETH is always listed)
  * Doesn't do any checks. Make sure you ONLY add well behaved ERC20s!!
  */
  constructor(address[] memory tokensToList, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    // Basic exchange configureation
    Config memory config;
    config.unlocked = false;
    config.oneMinusTradingFee = 0xffbe76c8b4395800;   // approximately 0.999
    config.delistingBonus = 0;
    DFP_config = config;

    // Configure the listed tokens as such
    TokenSettings memory listed;
    listed.state = State.Listed;
    require(tokensToList.length == 15, "Incorrect number of tokens");
    address previous = address(0);
    address current = address(0);
    for (uint256 i = 0; i < 15; i++) {
      current = tokensToList[i];
      require(current > previous, "Require ordered list");
      listedTokens[current] = listed;
      previous = current;
    }

    // Generate the LP tokens reflecting the initial liquidity (to be added separately)
    _mint(msg.sender, 1600e18);
  }

  // For bootstrapping ETH liquidity
  receive() external payable {}

  // To safeguard some functionality is only applied to listed tokens
  modifier onlyListedToken(address token) {
    require(
      token == address(0) || listedTokens[token].state > State.Delisting,
      "DFP: Token not listed"
    );
    _;
  }

  /**
  * Allows users to swap between any two tokens listed on the DEX.
  * Follows the x*y=k swap invariant hyperbole
  * For ETH trades, send the ETH with the transaction and use the NULL address as inputToken.
  */
  function swap(
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 minOutputAmount
  )
    external
    payable
    onlyListedToken(inputToken)
    onlyListedToken(outputToken)
    override
    returns (uint256 outputAmount)
  {
    // Check that the exchange is unlocked and thus open for business
    Config memory _config = DFP_config;
    require(_config.unlocked, "DFP: Locked");

    // Pull in input token and check the exchange balance for that token
    uint256 initialInputBalance;
    if (inputToken == address(0)) {
      require(msg.value == inputAmount, "DFP: bad ETH amount");
      initialInputBalance = address(this).balance - inputAmount;
    } else {
      initialInputBalance = IERC20(inputToken).balanceOf(address(this));
      require(
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount),
        "DFP: Transfer failed"
      );
    }

    // Check dex balance of the output token
    uint256 initialOutputBalance;
    if (outputToken == address(0)) {
      initialOutputBalance = address(this).balance;
    } else {
      initialOutputBalance = IERC20(outputToken).balanceOf(address(this));
    }

    // Calculate the output amount through the x*y=k invariant
    // Can skip overflow/underflow checks on this calculation as they will always work against an attacker anyway.
    uint256 netInputAmount = inputAmount * _config.oneMinusTradingFee;
    outputAmount = netInputAmount * initialOutputBalance / ((initialInputBalance << 64) + netInputAmount);
    require(outputAmount > minOutputAmount, "DFP: No deal");

    // Send output tokens to whoever invoked the swap function
    if (outputToken == address(0)) {
      address payable sender = msg.sender;
      sender.transfer(outputAmount);
    } else {
      IERC20(outputToken).transfer(msg.sender, outputAmount);
    }

    // Emit swap event to enable better governance decision making
    emit Swapped(msg.sender, inputToken, outputToken, inputAmount, outputAmount);
  }

  /**
  * Single sided liquidity add. More economic at moderate liquidity amounts.
  * Mathematically works as adding all tokens and swapping back to 1 token at no fee.
  *
  *         R = (1 + X_supplied/X_initial)^(1/N) - 1
  *         LP_minted = R * LP_total
  *
  * When adding ETH, the inputToken address to be used is the NULL address.
  * A fee is applied to prevent zero fee swapping through liquidity add/remove.
  */
  function addLiquidity(address inputToken, uint256 inputAmount, uint256 minLP)
    external
    payable
    onlyListedToken(inputToken)
    override
    returns (uint256 actualLP)
  {
    // Check that the exchange is unlocked and thus open for business
    Config memory _config = DFP_config;
    require(_config.unlocked, "DFP: Locked");

    // Pull in input token and check the exchange balance for that token
    uint256 initialBalance;
    if (inputToken == address(0)) {
      require(msg.value == inputAmount, "DFP: Incorrect amount of ETH");
      initialBalance = address(this).balance - inputAmount;
    } else {
      initialBalance = IERC20(inputToken).balanceOf(address(this));
      require(
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount),
        "DFP: Transfer failed"
      );
    }

    // Prevent excessive liquidity add which runs of the approximation curve
    require(inputAmount < initialBalance, "DFP: Too much at once");

    // 6th power binomial series approximation of R
    uint256 X = (inputAmount * _config.oneMinusTradingFee) / initialBalance;  // 0.64 bits
    uint256 X_ = X * X;                                // X^2   0.128 bits
    uint256 R_ = (X >> 4) - (X_ * 15 >> 73);           // R2    0.64 bits
    X_ = X_ * X;                                       // X^3   0.192 bits
    R_ = R_ + (X_ * 155 >> 141);                       // R3    0.64 bits
    X_ = X_ * X >> 192;                                // X^4   0.64 bits
    R_ = R_ - (X_ * 7285 >> 19);                       // R4    0.64 bits
    X_ = X_ * X;                                       // X^5   0.128 bits
    R_ = R_ + (X_ * 91791 >> 87);                      // R5    0.64 bits
    X_ = X_ * X;                                       // X^6   0.192 bits
    R_ = R_ - (X_ * 2417163 >> 156);                   // R6    0.64 bits

    // Calculate and mint LPs to be awarded
    actualLP = R_ * totalSupply() >> 64;
    require(actualLP > minLP, "DFP: No deal");
    _mint(msg.sender, actualLP);

    // Emitting liquidity add event to enable better governance decisions
    emit LiquidityAdded(msg.sender, inputToken, inputAmount, actualLP);
  }

  /**
  * Multi-token liquidity add. More economic for large amounts of liquidity.
  * Simply takes in all 16 listed tokens in ratio and mints the LPs accordingly.
  * For ETH, the inputToken address to be used is the NULL address.
  * A fee is applied to prevent zero fee swapping through liquidity add/remove.
  */
  function addMultiple(address[] calldata tokens, uint256[] calldata maxAmounts)
    external
    payable
    override
    returns (uint256 actualLP)
  {
    // Perform basic checks
    Config memory _config = DFP_config;
    require(_config.unlocked, "DFP: Locked");
    require(tokens.length == 16, "DFP: Bad tokens array length");
    require(maxAmounts.length == 16, "DFP: Bad maxAmount array length");

    // Check ETH amount/ratio first
    require(tokens[0] == address(0), "DFP: No ETH found");
    require(maxAmounts[0] == msg.value, "DFP: Incorrect ETH amount");
    uint256 dexBalance = address(this).balance - msg.value;
    uint256 actualRatio = msg.value.mul(1<<128) / dexBalance;

    // Check ERC20 amounts/ratios
    uint256 currentRatio;
    address previous;
    address token;
    for (uint256 i = 1; i < 16; i++) {
      token = tokens[i];
      require(token > previous, "DFP: Require ordered list");
      require(
        listedTokens[token].state > State.Delisting,
        "DFP: Token not listed"
      );
      dexBalance = IERC20(token).balanceOf(address(this));
      currentRatio = maxAmounts[i].mul(1<<128) / dexBalance;
      if (currentRatio < actualRatio) {
        actualRatio = currentRatio;
      }
      previous = token;
    }

    // Calculate how many LP will be generated
    actualLP = actualRatio.mul(totalSupply()) >> 128;

    // Collect ERC20 tokens
    previous = address(0);
    for (uint256 i = 1; i < 16; i++) {
      token = tokens[i];
      dexBalance = IERC20(token).balanceOf(address(this));
      require(
        IERC20(token).transferFrom(msg.sender, address(this), dexBalance.mul(actualRatio) >> 128),
        "DFP: token transfer failed"
      );
      previous = token;
    }

    // Mint the LP tokens
    _mint(msg.sender, actualLP);

    // Refund ETH change
    dexBalance = address(this).balance - msg.value;
    address payable sender = msg.sender;
    sender.transfer(msg.value - (dexBalance.mul(actualRatio) >> 128));
  }

  /**
      Withdrawing liquidity from the DEX is a single sided operation. For fair LP token liquiadation
      the liquidity should be withdrawn from all tokens in the appropriate ratios. However, with up
      to 16 listed tokens this becomes impractical and expensive. Thus, liquidity is only withdrawn
      from a single token instead. Mathematically, the DEX behaves as if the liquidity was indeed
      withdrawn from all listed tokens, and then swapped back to the selected token at no fee.
      For N listed tokens, this works out to:

          R = LP_burnt / LP_initial
          X_out = X_initial * (1 - (1 - R)^N)

   */
  function removeLiquidity(uint256 LPamount, address outputToken, uint256 minOutputAmount)
    external
    onlyListedToken(outputToken)
    override
    returns (uint256 actualOutput)
  {
    // no lock check -- can remove liquidity even if exchange is locked for trading
    uint256 initialBalance;
    if (outputToken == address(0)) {
      initialBalance = address(this).balance;
    } else {
      initialBalance = IERC20(outputToken).balanceOf(address(this));
    }

    // Actual amount of output token calculation.
    uint256 F_;
    F_ = (1 << 64) - (LPamount << 64) / totalSupply();   // (1-R)      (0.64 bits)
    F_ = F_ * F_;                                       // (1-R)^2    (0.128 bits)
    F_ = F_ * F_ >> 192;                                // (1-R)^4    (0.64 bits)
    F_ = F_ * F_;                                       // (1-R)^8    (0.128 bits)
    F_ = F_ * F_ >> 192;                                // (1-R)^16   (0.64 bits)
    actualOutput = initialBalance * ((1 << 64) - F_) >> 64;
    require(actualOutput > minOutputAmount, "DFP: No deal");

    _burn(msg.sender, LPamount);
    if (outputToken == address(0)) {
      address payable sender = msg.sender;
      sender.transfer(actualOutput);
    } else {
      IERC20(outputToken).transfer(msg.sender, actualOutput);
    }
    // emitting events costs gas, but I feel it is needed to allow informed governance decisions
    emit LiquidityRemoved(msg.sender, outputToken, actualOutput, LPamount);
  }

  function removeMultiple(uint256 LPamount, address[] calldata tokens)
    external
    override
    returns (bool success)
  {
    // Perform basic checks
    Config memory _config = DFP_config;
    require(_config.unlocked, "DFP: Locked");
    require(tokens.length == 16, "DFP: Bad tokens array length");

    // Calculate fraction of total liquidity to be returned
    uint256 fraction = (LPamount << 128) / totalSupply();

    // Send the ETH first (use transfer to prevent reentrancy)
    uint256 dexBalance = address(this).balance;
    address payable sender = msg.sender;
    sender.transfer(fraction * dexBalance >> 128);

    // Send the ERC20 tokens
    address previous;
    for (uint256 i = 1; i < 16; i++) {
      address token = tokens[i];
      require(token > previous, "DFP: Require ordered list");
      require(
        listedTokens[token].state > State.Delisting,
        "DFP: Token not listed"
      );
      dexBalance = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(msg.sender, fraction * dexBalance >> 128);
      previous = token;
    }

    // Burn the LPs
    _burn(msg.sender, LPamount);

    // That's all folks
    return true;
  }


  /** When a token is delisted and another one gets listed in its place, the users can
      call this function to provide liquidity for the new token in exchange for the old
      token. The ratio should be set such that the users have a financial incentive to
      perform this transaction.
   */
  function bootstrapNewToken(
    address inputToken,
    uint256 maxInputAmount,
    address outputToken
  ) external override returns (uint256 outputAmount) {
    TokenSettings memory tokenToList = listedTokens[inputToken];
    require(
      tokenToList.state == State.PreListing,
      "DFP: Wrong token"
    );
    uint256 initialInputBalance = IERC20(inputToken).balanceOf(address(this));
    uint256 availableAmount = tokenToList.listingTarget - initialInputBalance;
    uint256 actualInputAmount = maxInputAmount > availableAmount ? availableAmount : maxInputAmount;

    require(
      IERC20(inputToken).transferFrom(msg.sender, address(this), actualInputAmount),
      "DFP: token transfer failed"
    );

    TokenSettings memory tokenToDelist = listedTokens[outputToken];
    require(
      tokenToDelist.state == State.Delisting,
      "DFP: Wrong token"
    );
    uint256 initialOutputBalance = IERC20(outputToken).balanceOf(address(this));
    outputAmount = actualInputAmount.mul(initialOutputBalance).div(availableAmount);
    IERC20(outputToken).transfer(msg.sender, outputAmount);

    emit LiquidityBootstrapped(
      msg.sender,
      inputToken,
      actualInputAmount,
      outputToken,
      outputAmount
    );

    if (actualInputAmount == availableAmount) {
      tokenToList.state = State.Listed;
      listedTokens[inputToken] = tokenToList;
      delete listedTokens[outputToken];
      delete listingUpdate;
      emit BootstrapCompleted(outputToken, inputToken);
    }
  }

  /**
   * @dev Update the fee structure for the exchange
   * @param tokenToDelist The token that is being delisted
   * @param tokenToList The token that is coming in its place
   * @param listingTarget The amount of tokens required for the listing to become active
   */
  function changeListing(
    address tokenToDelist,              // Address of token to be delisted
    address tokenToList,                // Address of token to be listed
    uint112 listingTarget               // Amount of tokens needed to activate listing
  ) external onlyListedToken(tokenToDelist) onlyOwner() {
    require(tokenToDelist != address(0), "DFP: Cannot delist ETH");
    ListingUpdate memory update = listingUpdate;
    require(update.tokenToDelist == address(0), "DFP: Previous update incomplete");

    TokenSettings memory _token = listedTokens[tokenToList];
    require(_token.state == State.Unlisted, "DFP: Token already listed");

    update.tokenToDelist = tokenToDelist;
    update.tokenToList = tokenToList;
    listingUpdate = update;

    _token.state = State.PreListing;
    _token.listingTarget = listingTarget;
    listedTokens[tokenToList] = _token;
    listedTokens[tokenToDelist].state = State.Delisting;
  }

  /**
      Sets exchange lock.
  */
  function lockExchange() external onlyOwner() {
    DFP_config.unlocked = false;
  }

  /**
      Resets exchange lock.
  */
  function unlockExchange() external onlyOwner() {
    DFP_config.unlocked = true;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.6;

interface IDeFiPlaza {
  function swap(
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 minOutputAmount
  ) external payable returns (uint256 outputAmount);

  function addLiquidity(
    address inputToken,
    uint256 inputAmount,
    uint256 minLP
  ) external payable returns (uint256 deltaLP);

  function addMultiple(
    address[] calldata tokens,
    uint256[] calldata maxAmounts
  ) external payable returns (uint256 actualLP);

  function removeLiquidity(
    uint256 LPamount,
    address outputToken,
    uint256 minOutputAmount
  ) external returns (uint256 actualOutput);

  function removeMultiple(
    uint256 LPamount,
    address[] calldata tokens
  ) external returns (bool success);

  function bootstrapNewToken(
    address inputToken,
    uint256 maxInputAmount,
    address outputToken
  ) external returns (uint256 outputAmount);

  event Swapped(
    address sender,
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 outputAmount
  );

  event LiquidityAdded(
    address sender,
    address token,
    uint256 tokenAmount,
    uint256 LPs
  );

  event LiquidityRemoved(
    address recipient,
    address token,
    uint256 tokenAmount,
    uint256 LPs
  );

  event LiquidityBootstrapped(
    address sender,
    address inputToken,
    uint256 inputAmount,
    address outputToken,
    uint256 outputAmount
  );

  event BootstrapCompleted(
    address delistedToken,
    address listedToken
  );
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

