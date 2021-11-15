// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from '../dependencies/open-zeppelin/SafeMath.sol';
import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {VersionedInitializable} from '../utils/VersionedInitializable.sol';

/**
 * @title IDO Agri Token
 * @dev Contract
 * - Validate whitelist seller
 * - Validate timelock
 * @author Agri
 **/
contract AgriIDO is VersionedInitializable{

  using SafeMath for uint256;

  uint256 public constant REVISION = 3;
  address public tokenAdmin;
  address public priceSource;
  address public SELL_TOKEN;
  uint256 public tokenPrice;
  uint256 public remainTokenAmount;

  event buyTokenExecuted(address indexed buyer, uint256 bnbAmount, uint256 usdtAmount, uint256 tokenAmount, uint256 price);
  event buyStableTokenExecuted(address indexed buyer, uint256 usdtAmount, uint256 tokenAmount);

  modifier onlyAdmin() {
    require(msg.sender == tokenAdmin, 'INVALID ADMIN');
    _;
  }  

  constructor() {
  }

  /**
   * @dev Called by the proxy contract
   **/
  function initialize(
    address _tokenAdmin, address _priceFeed
  ) external initializer {
    tokenAdmin = _tokenAdmin;
    priceSource = _priceFeed;
  }

  /**
   * @dev returns the revision of the implementation contract
   * @return The revision
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }


  /**
   * @dev Withdraw Token in contract to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param token token withdraw
   */
  function withdrawFunc(address recipient, address token) public onlyAdmin {
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }

  /**
   * @dev Withdraw BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param amountBNB amount of the transfer
   */
  function withdrawBNB(address recipient, uint256 amountBNB) public onlyAdmin {
    if (amountBNB > 0) {
      _safeTransferBNB(recipient, amountBNB);
    } else {
      _safeTransferBNB(recipient, address(this).balance);
    }
  }

  /**
   * @dev transfer BNB to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'BNB_TRANSFER_FAILED');
  }  

  /**
   * @dev Set Token for sale.
   * @param sell_token token for sale
   */
  function setSellToken(address sell_token) public onlyAdmin {
    SELL_TOKEN = sell_token;
  }

  /**
   * @dev Set Token Price for sale.
   * @param _tokenPrice price token for sale
   */
  function setSellTokenPrice(uint256 _tokenPrice) public onlyAdmin {
    tokenPrice = _tokenPrice;
  }

  /**
    @dev Set total token amount for sale
    @param _amount total token amount for sale
   */
  function setRemainTokenAmount(uint256 _amount) public onlyAdmin {
    remainTokenAmount = _amount;
  }

  /**
   * @dev Get BNB Price
   * @return true current BNB price
   **/
  function getBNBPrice() public view returns (uint256) {
    int256 price = IChainlinkAggregator(priceSource).latestAnswer();
    require(price > 0, 'PRICE FEED ERROR!');
    return uint256(price * 1e10);
  }  

  /**
   * @dev execute buy token
   * @return true if the transfer succeeds, false otherwise
   **/
  function buyToken() public payable returns (bool) {
    uint256 price = getBNBPrice();
    uint256 usdtAmount = msg.value * price / 1e18;
    uint256 tokenAmount = usdtAmount * 1e18 / tokenPrice;
    uint256 soldToken = tokenAmount > remainTokenAmount ? remainTokenAmount : tokenAmount;
    if (tokenAmount > soldToken) {
      uint256 repayBNB =(tokenAmount.sub(soldToken) * tokenPrice) / price;
      _safeTransferBNB(msg.sender, repayBNB);
    }
    if (soldToken > 0) {
        IERC20(SELL_TOKEN).transfer(msg.sender, soldToken);
        emit buyTokenExecuted(msg.sender, msg.value, usdtAmount, soldToken, price);
    }
    return (true);
  }

  /**
   * @dev execute buy token
   * @param usdAmount USD Amount 
   * @return true if the transfer succeeds, false otherwise
   **/
  function buyTokenByUSD(uint256 usdAmount, address usdToken) public returns (bool) {
    uint256 tokenAmount = usdAmount * 1e18 / tokenPrice;
    uint256 soldToken = tokenAmount > remainTokenAmount ? remainTokenAmount : tokenAmount;
    uint256 soldUsdtAmount = soldToken * tokenPrice / 1e18;
    if (soldToken > 0) {
        IERC20(usdToken).transferFrom(msg.sender, address(this), usdAmount);
        IERC20(SELL_TOKEN).transfer(msg.sender, tokenAmount);
        emit buyStableTokenExecuted(msg.sender, soldUsdtAmount, soldToken);
    }
    return (true);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
pragma solidity 0.7.5;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Bitcoinnami, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 internal lastInitializedRevision = 0;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(revision > lastInitializedRevision, 'Contract instance has already been initialized');

    lastInitializedRevision = revision;

    _;
  }

  /// @dev returns the revision number of the contract.
  /// Needs to be defined in the inherited class as a constant.
  function getRevision() internal pure virtual returns (uint256);

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

