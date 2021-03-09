// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Pausable} from "../roles/Pausable.sol";
import {ProxyFactory} from "./ProxyFactory.sol";
import {VersionManager} from "../registries/VersionManager.sol";

import {ILoan} from "../Loan.sol";
import {IOffer} from "../Offer.sol";
import {IRequest} from "../Request.sol";
import {ILoanFactory} from "./LoanFactory.sol";

import {ITokenManager} from "../managers/TokenManager.sol";
import {IFeeBurnManager} from "../managers/FeeBurnManager.sol";

import {IOracle} from "../Oracle.sol";


interface IMainFactory
{
  event NewOffer(address indexed lender, address offer);
  event NewRequest(address indexed borrower, address request);
}


contract MainFactory is IMainFactory, Pausable, ReentrancyGuard, VersionManager
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private constant _DECIMALS = 1e18;
  uint256 private constant _MIN_INTEREST = 200; // 2%,
  uint256 private constant _MAX_INTEREST = 1250; // 12.5%
  uint256 private constant _MAX_DURATION = 60 days;
  uint256 private constant _MIN_DURATION = 10 days;

  address[] private _offers;
  address[] private _requests;

  mapping(address => address[]) private _offersOf;
  mapping(address => address[]) private _requestsOf;


  function getOffers() external view returns (address[] memory)
  {
    return _offers;
  }

  function getRequests() external view returns (address[] memory)
  {
    return _requests;
  }

  function getOffersOf(address account) external view returns (address[] memory)
  {
    return _offersOf[account];
  }

  function getRequestsOf(address account) external view returns (address[] memory)
  {
    return _requestsOf[account];
  }


  function createOffer(address lendingToken, uint256 principal, uint256 interest, uint256 duration) external nonReentrant
  {
    Pausable._isNotPaused();
    require(ITokenManager(VersionManager._tokenMgr()).isWhitelisted(lendingToken), "Bad token");

     _isValid(lendingToken, principal, interest, duration);

    uint256 feeOnInterest = IFeeBurnManager(VersionManager._feeBurnMgr()).getFeeOnInterest(msg.sender, lendingToken, principal, interest);

    bytes memory initData = abi.encodeWithSelector(IOffer.__Offer_init.selector, msg.sender, lendingToken, principal, interest, duration, feeOnInterest);

    address offer = ProxyFactory._deployMinimal(VersionManager._offerImplementation(), initData);

    IERC20(lendingToken).safeTransferFrom(msg.sender, offer, principal.add(feeOnInterest));

    _offers.push(offer);
    ILoanFactory(VersionManager._loanFactory()).addLoaner(offer);
    _offersOf[msg.sender].push(offer);

    emit NewOffer(msg.sender, offer);
  }

  function createRequest(address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral) external nonReentrant
  {
    Pausable._isNotPaused();
    _isValid(lendingToken, principal, interest, duration);

    uint256 feeOnPrincipal = IFeeBurnManager(VersionManager._feeBurnMgr()).getFeeOnPrincipal(msg.sender, lendingToken, principal, collateralToken);

    bytes memory initData = abi.encodeWithSelector(IRequest.__Request_init.selector, msg.sender, lendingToken, principal, interest, duration, collateralToken, collateral, feeOnPrincipal);

    address request = ProxyFactory._deployMinimal(VersionManager._requestImplementation(), initData);

    IERC20(collateralToken).safeTransferFrom(msg.sender, request, collateral.add(feeOnPrincipal));

    _requests.push(request);
    ILoanFactory(VersionManager._loanFactory()).addLoaner(request);
    _requestsOf[msg.sender].push(request);

    emit NewRequest(msg.sender, request);
  }


  function _isValid(address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view
  {
    require(_hasValidTerms(lendingToken, principal, interest, duration), "Bad terms");
  }

  function _hasValidTerms(address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view returns (bool)
  {
    uint256 principalInUSD = IOracle(VersionManager._oracle()).convertToUSD(lendingToken, principal);

    // $1000; ~1000 DAI tokens i.e. 1000 * 10^18 && < $50K
    return principalInUSD >= (1000 * _DECIMALS) && principalInUSD <= (50000 * _DECIMALS) && interest >= _MIN_INTEREST && interest <= _MAX_INTEREST && duration >= _MIN_DURATION && duration <= _MAX_DURATION;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

    constructor () {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {PauserRole} from "./PauserRole.sol";


contract Pausable is PauserRole
{
  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor()
  {
    _paused = false;
  }

  function _isPaused() internal view
  {
    require(_paused, "!paused");
  }

  function _isNotPaused() internal view
  {
    require(!_paused, "Paused");
  }

  function paused() public view returns (bool)
  {
    return _paused;
  }

  function pause() public onlyPauser
  {
    _isNotPaused();

    _paused = true;

    emit Paused(msg.sender);
  }

  function unpause() public onlyPauser
  {
    _isPaused();

    _paused = false;

    emit Unpaused(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";


library ProxyFactory
{
  event ProxyCreated(address proxy);


  function _deployMinimal(address logic, bytes memory data) internal returns (address proxy)
  {
    // deploy clone
    proxy = Clones.clone(logic);

    // attempt initialization
    if (data.length > 0)
    {
      (bool success,) = proxy.call(data);
      require(success, "ProxyFactory: init err");
    }

    emit ProxyCreated(proxy);

    return proxy;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IVersionBeacon} from "./VersionBeacon.sol";


contract VersionManager
{
  address private constant _versionBeacon = address(0xfc90c4ae4343f958215b82ff4575b714294Cdd75);


  function getVersionBeacon() public pure returns (address versionBeacon)
  {
    return _versionBeacon;
  }


  function _oracle() internal view returns (address oracle)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Oracle"));
  }

  function _tokenMgr() internal view returns (address tokenMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("TokenManager"));
  }

  function _discountMgr() internal view returns (address discountMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("DiscountManager"));
  }

  function _feeBurnMgr() internal view returns (address feeBurnMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("FeeBurnManager"));
  }

  function _rewardMgr() internal view returns (address rewardMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("RewardManager"));
  }

  function _collateralMgr() internal view returns (address collateralMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("CollateralManager"));
  }

  function _loanFactory() internal view returns (address loanFactory)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("LoanFactory"));
  }

  function _offerImplementation() internal view returns (address offerImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Offer"));
  }

  function _requestImplementation() internal view returns (address requestImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Request"));
  }

  function _loanImplementation() internal view returns (address loanImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Loan"));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ICollateralManager} from "./managers/CollateralManager.sol";
import {IFeeBurnManager} from "./managers/FeeBurnManager.sol";
import {ITokenManager} from "./managers/TokenManager.sol";
import {IOracle} from "./Oracle.sol";
import {VersionManager} from "./registries/VersionManager.sol";


interface ILoan
{
  enum Status {Active, Repaid, Defaulted}

  struct LoanDetails
  {
    address lender;
    address borrower;
    address lendingToken;
    address collateralToken;
    uint256 principal;
    uint256 interest;
    uint256 duration;
    uint256 collateral;
  }

  struct LoanMetadata
  {
    ILoan.Status status;
    uint256 timestampStart;
    uint256 timestampRepaid;
    uint256 liquidatableTimeAllowance;
  }


  event Repay(address indexed lender, address indexed borrower, address loan);
  event Default(address indexed lender, address indexed borrower, address loan);
  event Liquidate(address indexed loan, address liquidator, uint256 amountRepaid);


  function __Loan_init(LoanDetails memory loanDetails) external;


  function isDefaulted() external view returns (bool);

  function getLoanDetails() external view returns (LoanDetails memory details);

  function getLoanMetadata() external view returns (LoanMetadata memory metadata);
}


contract Loan is ILoan, ReentrancyGuardUpgradeable, VersionManager
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private constant _COMPENSATION_THRESHOLD = 10650; // 106.5%
  uint256 private constant _BASIS_POINT = 10000;

  LoanDetails private _loanDetails;
  LoanMetadata private _loanMetadata;


  modifier onlyLender
  {
    require(msg.sender == _loanDetails.lender, "!lender");
    _;
  }

  modifier onlyBorrower
  {
    require(msg.sender == _loanDetails.borrower, "!borrower");
    _;
  }



  function __Loan_init(LoanDetails memory loanDetails) external override initializer
  {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    _loanDetails = loanDetails;

    _loanMetadata.timestampStart = block.timestamp;
  }

  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function _isActive() private view
  {
    require(_loanMetadata.status == ILoan.Status.Active, "!active");
  }

  function isDefaulted() public view override returns (bool)
  {
    (bool sufficient,) = ICollateralManager(VersionManager._collateralMgr()).isSufficientCollateral(_loanDetails.borrower, _loanDetails.lendingToken, _loanDetails.principal, _loanDetails.collateralToken, _getCollateralBalance());

    return !sufficient || block.timestamp > getTimestampDue();
  }

  function _hasDefaulted() private view
  {
    require(isDefaulted(), "!defaulted");
  }

  function _hasNotDefaulted() private view
  {
    require(!isDefaulted(), "Defaulted");
  }

  function getTimestampDue() public view returns (uint256)
  {
    return _loanMetadata.timestampStart.add(_loanDetails.duration);
  }

  function getCollateralBalance() public view returns (uint256)
  {
    return _getCollateralBalance();
  }

  function _getFullCollateralBalance() private view returns (uint256)
  {
    return IERC20(_loanDetails.collateralToken).balanceOf(address(this));
  }

  function _getCollateralBalance() private view returns (uint256)
  {
    if (ITokenManager(VersionManager._tokenMgr()).isDynamicToken(_loanDetails.collateralToken))
    {
      return _getFullCollateralBalance();
    }

    return _loanDetails.collateral;
  }

  function _repaymentAmount() private view returns (uint256 amount)
  {
    return _loanDetails.principal.add(_calcPercentOf(_loanDetails.principal, _loanDetails.interest));
  }

  function getLoanDetails() public view override returns (LoanDetails memory details)
  {
    return _loanDetails;
  }

  function getLoanMetadata() public view override returns (LoanMetadata memory metadata)
  {
    return _loanMetadata;
  }


  function _increaseCollateralBalance (uint amount) private
  {
    if (!ITokenManager(VersionManager._tokenMgr()).isDynamicToken(_loanDetails.collateralToken))
    {
      _loanDetails.collateral = _loanDetails.collateral.add(amount);
    }
  }

  function topUpCollateral(uint256 amount) external nonReentrant onlyBorrower
  {
    _isActive();
    _hasNotDefaulted();
    require(amount > 0 && amount < type(uint256).max, "Invalid val");

    _increaseCollateralBalance(amount);

    // deposit tokens
    IERC20(_loanDetails.collateralToken).safeTransferFrom(_loanDetails.borrower, address(this), amount);
  }

  function _handleRepayment() private
  {
    LoanDetails memory loanDetails = getLoanDetails();

    _loanMetadata.status = ILoan.Status.Repaid;

    IERC20(loanDetails.lendingToken).safeTransferFrom(loanDetails.borrower, loanDetails.lender, _repaymentAmount());

    IERC20(loanDetails.collateralToken).safeTransfer(loanDetails.borrower, _getFullCollateralBalance());

    _loanMetadata.timestampRepaid = block.timestamp;

    emit Repay(loanDetails.lender, loanDetails.borrower, address(this));
  }

  function repay() external nonReentrant onlyBorrower
  {
    require(block.timestamp > _loanMetadata.timestampStart.add(5 minutes), "fresh");

    _isActive();
    _hasNotDefaulted();
    _handleRepayment();
  }

  function _txDefaultingFee() internal
  {
    IERC20(_loanDetails.collateralToken).safeTransfer(IFeeBurnManager(VersionManager._feeBurnMgr()).burner(), IFeeBurnManager(VersionManager._feeBurnMgr()).getDefaultingFee(_getFullCollateralBalance()));
  }

  function _handleDefault() private
  {
    _loanMetadata.status = ILoan.Status.Defaulted;

    _txDefaultingFee();

    IERC20(_loanDetails.collateralToken).safeTransfer(_loanDetails.lender, _getFullCollateralBalance());

    emit Default(_loanDetails.lender, _loanDetails.borrower, address(this));
  }

  function setLiquidatableTimeAllowance() public nonReentrant
  {
    _isActive();
    _hasDefaulted();
    require(_loanMetadata.liquidatableTimeAllowance == 0, "Set");

    _loanMetadata.liquidatableTimeAllowance = block.timestamp.add(10 minutes);
  }

  function seizeCollateral() external nonReentrant onlyLender
  {
    _isActive();
    _hasDefaulted();
    _handleDefault();
  }

  function seizeForLender() public nonReentrant
  {
    _isActive();
    _hasDefaulted();
    require(_loanMetadata.liquidatableTimeAllowance != 0 && block.timestamp >= _loanMetadata.liquidatableTimeAllowance, "Liquidatable");

    // ~$5; 5 * 10^18 DAI (USD)
    uint256 compensation = IOracle(VersionManager._oracle()).convertFromUSD(_loanDetails.collateralToken, 5 * 1e18);

    IERC20(_loanDetails.collateralToken).safeTransfer(msg.sender, compensation);

    _handleDefault();
  }

  function liquidate() external nonReentrant
  {
    _isActive();
    _hasDefaulted();

    LoanDetails memory loanDetails = getLoanDetails();

    _loanMetadata.status = ILoan.Status.Defaulted;

    _txDefaultingFee();

    uint256 collateralBalance = _getFullCollateralBalance();
    uint256 amountToRepay = loanDetails.principal.add(_repaymentAmount().sub(loanDetails.principal).div(2));

    // calculate principal + half of interest equivalent + kicker
    uint256 maxCompensation = IOracle(VersionManager._oracle()).convert(loanDetails.lendingToken, loanDetails.collateralToken, _calcPercentOf(amountToRepay, _COMPENSATION_THRESHOLD));

    // calculate min(collateral, principal + half of interest)
    uint256 compensation = collateralBalance > maxCompensation ? maxCompensation : collateralBalance;


    // return principal + half of interest to lender
    IERC20(loanDetails.lendingToken).safeTransferFrom(msg.sender, loanDetails.lender, amountToRepay);

    // pay min(collateral, principal + half of interest) to liquidator
    IERC20(loanDetails.collateralToken).safeTransfer(msg.sender, compensation);

    if (collateralBalance > maxCompensation)
    {
      IERC20(loanDetails.collateralToken).safeTransfer(loanDetails.lender, _getFullCollateralBalance());
    }

    emit Default(loanDetails.lender, loanDetails.borrower, address(this));
    emit Liquidate(address(this), msg.sender, amountToRepay);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ICollateralManager} from "./managers/CollateralManager.sol";
import {IFeeBurnManager} from "./managers/FeeBurnManager.sol";
import {ILoan} from "./Loan.sol";
import {Escrow} from "./Escrow.sol";


interface IOffer
{
  function __Offer_init(address lender, address lendingToken, uint256 principal, uint256 interest, uint256 duration, uint256 feeOnInterest) external;

  function claim(address collateralToken, uint256 collateral) external returns (address loan);

  function cancel() external;
}

contract Offer is IOffer, Escrow
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private _feeOnInterest;


  function __Offer_init(address lender, address lendingToken, uint256 principal, uint256 interest, uint256 duration, uint256 feeOnInterest) external override initializer
  {
    Escrow._initialize();

    _loanDetails.lender = lender;
    _loanDetails.duration = duration;

    _loanDetails.lendingToken = lendingToken;
    _loanDetails.principal = principal;
    _loanDetails.interest = interest;

    _feeOnInterest = feeOnInterest;
  }


  function claim(address collateralToken, uint256 collateral) external override nonReentrant returns (address loan)
  {
    require(msg.sender != _loanDetails.lender, "Own Offer");

    require(ICollateralManager(_collateralMgr()).isSufficientInitialCollateral(_loanDetails.lendingToken, _loanDetails.principal, collateralToken, collateral), "Inadequate collateral");

    // calculate fee amounts
    uint256 feeOnPrincipal = IFeeBurnManager(_feeBurnMgr()).getFeeOnPrincipal(msg.sender, _loanDetails.lendingToken, _loanDetails.principal, collateralToken);

    // tx collateral and fee from borrower
    IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateral.add(feeOnPrincipal));

    _loanDetails.borrower = msg.sender;
    _loanDetails.collateralToken = collateralToken;
    _loanDetails.collateral = collateral;

    return Escrow._accept(_feeOnInterest, feeOnPrincipal, true);
  }

  function cancel() external override nonReentrant
  {
    Escrow._isPending();
    require(msg.sender == _loanDetails.lender, "!lender");

    _status = Status.Canceled;

    IERC20(_loanDetails.lendingToken).safeTransfer(msg.sender, _getPrincipalBalance());

    emit Cancel(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ICollateralManager} from "./managers/CollateralManager.sol";
import {IFeeBurnManager} from "./managers/FeeBurnManager.sol";
import {ILoan} from "./Loan.sol";
import {Escrow} from "./Escrow.sol";


interface IRequest
{
  function __Request_init(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral, uint256 feeOnPrincipal) external;

  function fund() external returns (address loan);

  function cancel() external;
}

contract Request is IRequest, Escrow
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private _feeOnPrincipal;


  function __Request_init(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral, uint256 feeOnPrincipal) external override initializer
  {
    Escrow._initialize();

    require(ICollateralManager(_collateralMgr()).isSufficientInitialCollateral(lendingToken, principal, collateralToken, collateral), "Inadequate collateral");

    _loanDetails.borrower = borrower;
    _loanDetails.duration = duration;

    _loanDetails.lendingToken = lendingToken;
    _loanDetails.principal = principal;
    _loanDetails.interest = interest;

    _loanDetails.collateralToken = collateralToken;
    _loanDetails.collateral = collateral;

    _feeOnPrincipal = feeOnPrincipal;
  }


  function fund() external override nonReentrant returns (address loan)
  {
    require(msg.sender != _loanDetails.borrower, "Own Request");

    _loanDetails.lender = msg.sender;

    // calculate fee amounts
    uint256 feeOnInterest = IFeeBurnManager(_feeBurnMgr()).getFeeOnInterest(msg.sender, _loanDetails.lendingToken, _loanDetails.principal, _loanDetails.interest);

    // tx principal and fee from lender
    IERC20(_loanDetails.lendingToken).safeTransferFrom(msg.sender, address(this), _loanDetails.principal.add(feeOnInterest));

    return Escrow._accept(feeOnInterest, _feeOnPrincipal, false);
  }

  function cancel() external override nonReentrant
  {
    Escrow._isPending();
    require(msg.sender == _loanDetails.borrower, "!borrower");

    _status = Status.Canceled;

    IERC20(_loanDetails.collateralToken).safeTransfer(msg.sender, _getCollateralBalance());

    emit Cancel(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {ILoan} from "../Loan.sol";
import {IDiscountManager} from "../managers/DiscountManager.sol";
import {IRewardManager} from "../managers/RewardManager.sol";

import {ProxyFactory} from "./ProxyFactory.sol";
import {Pausable} from "../roles/Pausable.sol";
import {LoanerRole} from "../roles/LoanerRole.sol";
import {VersionManager} from "../registries/VersionManager.sol";


interface ILoanFactory
{
  event NewLoan(address indexed lender, address indexed borrower, address loan);


  function addLoaner(address account) external;

  function createLoan(ILoan.LoanDetails memory loanDetails) external returns (address);
}


contract LoanFactory is ILoanFactory, Pausable, LoanerRole, VersionManager
{
  using SafeMath for uint256;


  address[] private _loans;
  mapping(address => address[]) private _loansOf;


  function getLoans() external view returns (address[] memory)
  {
    return _loans;
  }

  function getLoansOf(address account) external view returns (address[] memory)
  {
    return _loansOf[account];
  }


  function addLoaner(address account) public override(ILoanFactory, LoanerRole)
  {
    LoanerRole.addLoaner(account);
  }

  function createLoan(ILoan.LoanDetails memory loanDetails) external override onlyLoaner returns (address)
  {
    Pausable._isNotPaused();

    bytes memory initData = abi.encodeWithSelector(ILoan.__Loan_init.selector, loanDetails);

    address loan = ProxyFactory._deployMinimal(VersionManager._loanImplementation(), initData);

    require(IRewardManager(VersionManager._rewardMgr()).trackLoan(loan, loanDetails.borrower, loanDetails.lendingToken, loanDetails.principal, loanDetails.interest, loanDetails.duration), "Track err");

    _loans.push(loan);
    _loansOf[loanDetails.lender].push(loan);
    _loansOf[loanDetails.borrower].push(loan);

    IDiscountManager(VersionManager._discountMgr()).updateUnlockTime(loanDetails.lender, loanDetails.borrower, loanDetails.duration);

    emit NewLoan(loanDetails.lender, loanDetails.borrower, loan);

    return loan;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Ownable} from "../roles/Ownable.sol";


interface ITokenManager
{
  function isWhitelisted(address token) external view returns (bool);

  function isStableToken(address token) external view returns (bool);

  function isDynamicToken(address token) external view returns (bool);

  function isBothStable(address tokenA, address tokenB) external view returns (bool);

  function isBothWhitelisted(address tokenA, address tokenB) external view returns (bool);
}

contract TokenManager is ITokenManager, Ownable
{
  using SafeMath for uint256;


  address[] private _stableTokens;
  address[] private _dynamicTokens;
  address[] private _whitelistedTokens;

  uint256 private _tokenID;
  uint256 private _stableTokenID;
  uint256 private _dynamicTokenID;
  mapping(address => uint256) private _tokenIDOf;
  mapping(address => bool) private _whitelistedToken;
  mapping(address => bool) private _stableToken;
  mapping(address => uint256) private _stableTokenIDOf;
  mapping(address => bool) private _dynamicToken;
  mapping(address => uint256) private _dynamicTokenIDOf;


  constructor ()
  {
    _handleAddition(0x6B175474E89094C44Da98b954EedeAC495271d0F, false);
    _handleAddition(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, false);

    _handleAddition(0x111111111117dC0aa78b770fA6A738034120C302, false);
    _handleAddition(0xD46bA6D942050d489DBd938a2C909A5d5039A161, false);
    _handleAddition(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C, false);
    _handleAddition(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, false);
    _handleAddition(0xa117000000f279D81A1D3cc75430fAA017FA5A2e, false);
    _handleAddition(0xba100000625a3754423978a60c9317c58a424e3D, false);
    _handleAddition(0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55, false);
    _handleAddition(0x0D8775F648430679A709E98d2b0Cb6250d2887EF, false);
    _handleAddition(0xc00e94Cb662C3520282E6f5717214004A7f26888, false);
    _handleAddition(0x2ba592F78dB6436527729929AAf6c908497cB200, false);
    _handleAddition(0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b, false);
    _handleAddition(0xD533a949740bb3306d119CC777fa900bA034cd52, false);
    _handleAddition(0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c, false);
    _handleAddition(0xc944E90C64B2c07662A292be6244BDf05Cda44a7, false);
    _handleAddition(0xdd974D5C2e2928deA5F71b9825b8b646686BD200, false);
    _handleAddition(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44, false);
    _handleAddition(0x514910771AF9Ca656af840dff83E8264EcF986CA, false);
    _handleAddition(0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD, false);
    _handleAddition(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942, false);
    _handleAddition(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, false);
    _handleAddition(0x408e41876cCCDC0F92210600ef50372656052a38, false);
    _handleAddition(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, false);

    _handleAddition(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, false);
    _handleAddition(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, true);

    _handleAddition(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2, false);

    _handleAddition(0x0000000000085d4780B73119b644AE5ecd22b376, false);
    _handleAddition(0x0000000000085d4780B73119b644AE5ecd22b376, true);

    _handleAddition(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, false);

    _handleAddition(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, false);
    _handleAddition(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, true);

    _handleAddition(0xdAC17F958D2ee523a2206206994597C13D831ec7, false);
    _handleAddition(0xdAC17F958D2ee523a2206206994597C13D831ec7, true);

    _handleAddition(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, false);
    _handleAddition(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, false);
    _handleAddition(0xE41d2489571d322189246DaFA5ebDe1F4699F498, false);
  }


  function isWhitelisted(address token) public view override returns (bool)
  {
    return token != address(0) && _whitelistedToken[token];
  }

  function isStableToken(address token) public view override returns (bool)
  {
    return token != address(0) && _stableToken[token];
  }

  function isDynamicToken(address token) public view override returns (bool)
  {
    return token != address(0) && _dynamicToken[token];
  }

  function isBothStable(address tokenA, address tokenB) external view override returns (bool)
  {
    return _stableToken[tokenA] && _stableToken[tokenB];
  }

  function isBothWhitelisted(address tokenA, address tokenB) external view override returns (bool)
  {
    return _whitelistedToken[tokenA] && _whitelistedToken[tokenB];
  }

  function getDynamicTokens() external view returns (address[] memory)
  {
    return _dynamicTokens;
  }

  function getStableTokens() external view returns (address[] memory)
  {
    return _stableTokens;
  }

  function getWhitelistedTokens() external view returns (address[] memory)
  {
    return _whitelistedTokens;
  }


  function whitelistToken(address token) external onlyOwner
  {
    require(!isWhitelisted(token), "Whitelisted");

    _handleAddition(token, false);
  }

  function whitelistTokens(address[] calldata tokens) external onlyOwner
  {
    for (uint256 i = 0; i < tokens.length; i++)
    {
      if (!isWhitelisted(tokens[i]))
      {
        _handleAddition(tokens[i], false);
      }
    }
  }

  function unwhitelistToken(address token) external onlyOwner
  {
    require(isWhitelisted(token), "!whitelisted");

    _handleRemoval(token, false);

    if (isStableToken(token))
    {
      _handleRemoval(token, true);
    }

    if (isDynamicToken(token))
    {
      _handleDynamicRemoval(token);
    }
  }

  function setAsStableToken(address token) external onlyOwner
  {
    require(!isStableToken(token), "Set");
    require(isWhitelisted(token), "!whitelisted");

    _handleAddition(token, true);
  }

  function unsetAsStableToken(address token) external onlyOwner
  {
    require(isStableToken(token), "!stabletoken");

    _handleRemoval(token, true);
  }

  function setAsDynamicToken(address token) external onlyOwner
  {
    require(!isDynamicToken(token), "Set");
    require(isWhitelisted(token), "!whitelisted");

    _dynamicTokenID = _dynamicTokenID.add(1);
    _dynamicTokenIDOf[token] = _dynamicTokenID;
    _dynamicToken[token] = true;
    _dynamicTokens.push(token);
  }

  function unsetAsDynamicToken(address token) external onlyOwner
  {
    require(isDynamicToken(token), "!dynamic");

    _handleDynamicRemoval(token);
  }


  function _handleAddition(address token, bool forStableToken) private
  {
    if (!forStableToken)
    {
      _tokenID = _tokenID.add(1);
      _tokenIDOf[token] = _tokenID;
      _whitelistedToken[token] = true;
      _whitelistedTokens.push(token);
    }
    else
    {
      _stableTokenID = _stableTokenID.add(1);
      _stableTokenIDOf[token] = _stableTokenID;
      _stableToken[token] = true;
      _stableTokens.push(token);
    }
  }

  function _handleRemoval(address token, bool forStableToken) private
  {
    if (!forStableToken)
    {
      uint256 tokenIndex = _tokenIDOf[token].sub(1);

      _tokenIDOf[token] = 0;
      _whitelistedToken[token] = false;
      delete _whitelistedTokens[tokenIndex];
    }
    else
    {
      uint256 stableTokenIndex = _stableTokenIDOf[token].sub(1);

      _stableTokenIDOf[token] = 0;
      _stableToken[token] = false;
      delete _stableTokens[stableTokenIndex];
    }
  }

  function _handleDynamicRemoval(address token) private
  {
    uint256 dynamicTokenIndex = _dynamicTokenIDOf[token].sub(1);

    _dynamicTokenIDOf[token] = 0;
    _dynamicToken[token] = false;
    delete _dynamicTokens[dynamicTokenIndex];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Ownable} from "../roles/Ownable.sol";

import {IOracle} from "../Oracle.sol";
import {IDiscountManager} from "./DiscountManager.sol";
import {VersionManager} from "../registries/VersionManager.sol";


interface IFeeBurnManager
{
  function burner() external view returns (address);

  function getDefaultingFee(uint256 collateral) external view returns (uint256);

  function getFeeOnInterest(address lender, address lendingToken, uint256 principal, uint256 interest) external view returns (uint256);

  function getFeeOnPrincipal(address borrower, address lendingToken, uint256 principal, address collateralToken) external view returns (uint256);
}


contract FeeBurnManager is IFeeBurnManager, Ownable, VersionManager
{
  using SafeMath for uint256;


  uint256 private constant _BASIS_POINT = 10000;

  address private _burner;
  uint256 private _defaultingFeePct = 700;
  uint256 private _lenderInterestFeePct = 750;
  uint256 private _borrowerPrincipalFeePct = 100;


  constructor()
  {
    _burner = msg.sender;
  }

  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function burner() external view override returns (address burnerAddress)
  {
    return _burner;
  }

  function getFeePcts () public view returns (uint256, uint256, uint256)
  {
    return (_lenderInterestFeePct, _borrowerPrincipalFeePct, _defaultingFeePct);
  }

  function getFeeOnInterest(address lender, address lendingToken, uint256 principal, uint256 interest) external view override returns (uint256)
  {
    uint256 interestAmount = _calcPercentOf(principal, interest);
    uint256 oneUSDOfToken = IOracle(VersionManager._oracle()).convertFromUSD(lendingToken, 1e18);

    uint256 discountedFeePct = _calcPercentOf(_lenderInterestFeePct, 7500); // 7500 = 75%

    uint256 fee = _calcPercentOf(interestAmount, IDiscountManager(VersionManager._discountMgr()).isDiscounted(lender) ? discountedFeePct : _lenderInterestFeePct);

    return fee < oneUSDOfToken ? oneUSDOfToken : fee;
  }

  function getFeeOnPrincipal(address borrower, address lendingToken, uint256 principal, address collateralToken) external view override returns (uint256)
  {
    return _calcPercentOf(IOracle(VersionManager._oracle()).convert(lendingToken, collateralToken, principal), IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower) ? _borrowerPrincipalFeePct.sub(25) : _borrowerPrincipalFeePct);
  }

  function getDefaultingFee(uint256 collateral) external view override returns (uint256)
  {
    return _calcPercentOf(collateral, _defaultingFeePct);
  }

  function setBurner(address newBurner) external onlyOwner
  {
    require(newBurner != address(0), "0 addy");

    _burner = newBurner;
  }

  function setDefaultingFeePct(uint256 newPct) external onlyOwner
  {
    require(newPct > 0 && newPct <= 750, "Invalid val"); // 750 = 7.5%

    _defaultingFeePct = newPct;
  }

  function setPeerFeePcts(uint256 newLenderFeePct, uint256 newBorrowerFeePct) external onlyOwner
  {
    require(newLenderFeePct > 0 && newBorrowerFeePct > 0, "0% fee");
    require(newLenderFeePct <= 1000 && newBorrowerFeePct <= 150, "Too high"); // 1000 = 10%

    _lenderInterestFeePct = newLenderFeePct;
    _borrowerPrincipalFeePct = newBorrowerFeePct;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "./roles/Ownable.sol";


interface IFeed
{
  function latestAnswer() external view returns (int256);
}

interface IOracle
{
  function getRate(address from, address to) external view returns (uint256);

  function convertFromUSD(address to, uint256 amount) external view returns (uint256);

  function convertToUSD(address from, uint256 amount) external view returns (uint256);

  function convert(address from, address to, uint256 amount) external view returns (uint256);
}

contract Oracle is IOracle, Ownable
{
  using SafeMath for uint256;


  address private constant _DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint256 private constant _DECIMALS = 1e18;

  mapping(address => address) private _ETHFeeds;
  mapping(address => address) private _USDFeeds;


  constructor()
  {
    // address INCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    // address AMPL = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
    // address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    // address AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    // address ANT = 0xa117000000f279D81A1D3cc75430fAA017FA5A2e;
    // address BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    // address BAND = 0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55;
    // address BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    // address COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // address CREAM = 0x2ba592F78dB6436527729929AAf6c908497cB200;
    // address CRO = 0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b;
    // address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    // address ENJ = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
    // address GRT = 0xc944E90C64B2c07662A292be6244BDf05Cda44a7;
    // address KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    // address KEEPER = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
    // address LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    // address LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    // address MANA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
    // address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    // address REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    // address SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    // address SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    // address SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    // address TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    // address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // address YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    // address ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    _ETHFeeds[_DAI] = address(0x773616E4d11A78F511299002da57A0a94577F1f4);
    _ETHFeeds[0x111111111117dC0aa78b770fA6A738034120C302] = address(0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8);
    _ETHFeeds[0xD46bA6D942050d489DBd938a2C909A5d5039A161] = address(0x492575FDD11a0fCf2C6C719867890a7648d526eB);
    _ETHFeeds[0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C] = address(0xCf61d1841B178fe82C8895fe60c2EDDa08314416);
    _ETHFeeds[0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9] = address(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
    _ETHFeeds[0xa117000000f279D81A1D3cc75430fAA017FA5A2e] = address(0x8f83670260F8f7708143b836a2a6F11eF0aBac01);
    _ETHFeeds[0xba100000625a3754423978a60c9317c58a424e3D] = address(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    _ETHFeeds[0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55] = address(0x0BDb051e10c9718d1C29efbad442E88D38958274);
    _ETHFeeds[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = address(0x0d16d4528239e9ee52fa531af613AcdB23D88c94);
    _ETHFeeds[0xc00e94Cb662C3520282E6f5717214004A7f26888] = address(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);
    _ETHFeeds[0x2ba592F78dB6436527729929AAf6c908497cB200] = address(0x82597CFE6af8baad7c0d441AA82cbC3b51759607);
    _ETHFeeds[0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b] = address(0xcA696a9Eb93b81ADFE6435759A29aB4cf2991A96);
    _ETHFeeds[0xD533a949740bb3306d119CC777fa900bA034cd52] = address(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    _ETHFeeds[0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c] = address(0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B);
    _ETHFeeds[0xc944E90C64B2c07662A292be6244BDf05Cda44a7] = address(0x17D054eCac33D91F7340645341eFB5DE9009F1C1);
    _ETHFeeds[0xdd974D5C2e2928deA5F71b9825b8b646686BD200] = address(0x656c0544eF4C98A6a98491833A89204Abb045d6b);
    _ETHFeeds[0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44] = address(0xe7015CCb7E5F788B8c1010FC22343473EaaC3741);
    _ETHFeeds[0x514910771AF9Ca656af840dff83E8264EcF986CA] = address(0xDC530D9457755926550b59e8ECcdaE7624181557);
    _ETHFeeds[0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD] = address(0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4);
    _ETHFeeds[0x0F5D2fB29fb7d3CFeE444a200298f468908cC942] = address(0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9);
    _ETHFeeds[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = address(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
    _ETHFeeds[0x408e41876cCCDC0F92210600ef50372656052a38] = address(0x3147D7203354Dc06D9fd350c7a2437bcA92387a4);
    _ETHFeeds[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = address(0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c);
    _ETHFeeds[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = address(0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757);
    _ETHFeeds[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = address(0xe572CeF69f43c2E488b33924AF04BDacE19079cf);
    _ETHFeeds[0x0000000000085d4780B73119b644AE5ecd22b376] = address(0x3886BA987236181D98F2401c507Fb8BeA7871dF2);
    _ETHFeeds[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = address(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
    _ETHFeeds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = address(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    _ETHFeeds[0xdAC17F958D2ee523a2206206994597C13D831ec7] = address(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
    _ETHFeeds[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = address(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    _ETHFeeds[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = address(0x7c5d4F8345e66f68099581Db340cd65B078C41f4);
    _ETHFeeds[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = address(0x2Da4983a622a8498bb1a21FaE9D8F6C664939962);

    _USDFeeds[_WETH] = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
  }

  function getFeeds(address token) external view returns (address, address)
  {
    return (_ETHFeeds[token], _USDFeeds[token]);
  }

  function setFeeds(address[] calldata tokens, address[] calldata feeds, bool is_USDFeeds) external onlyOwner
  {
    require(tokens.length == feeds.length, "!=");

    if (is_USDFeeds)
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _USDFeeds[token] = feeds[i];
      }
    }
    else
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _ETHFeeds[token] = feeds[i];
      }
    }
  }


  function uintify(int256 val) private pure returns (uint256)
  {
    require(val > 0, "Feed err");

    return uint256(val);
  }

  function getTokenETHRate(address token) private view returns (uint256)
  {
    if (_ETHFeeds[token] != address(0))
    {
      return uintify(IFeed(_ETHFeeds[token]).latestAnswer());
    }
    else if (_USDFeeds[token] != address(0))
    {
      return uintify(IFeed(_USDFeeds[token]).latestAnswer()).mul(_DECIMALS).div(uintify(IFeed(_USDFeeds[_WETH]).latestAnswer()));
    }
    else
    {
      return 0;
    }
  }

  function getRate(address from, address to) public view override returns (uint256)
  {
    if (from == to && to == _DAI)
    {
      return _DECIMALS;
    }

    uint256 srcRate = from == _WETH ? _DECIMALS : getTokenETHRate(from);
    uint256 destRate = to == _WETH ? _DECIMALS : getTokenETHRate(to);

    require(srcRate > 0 && destRate > 0 && srcRate < type(uint256).max && destRate < type(uint256).max, "No oracle");

    return srcRate.mul(_DECIMALS).div(destRate);
  }

  function calcDestQty(uint256 srcQty, address from, address to, uint256 rate) private view returns (uint256)
  {
    uint256 srcDecimals = ERC20(from).decimals();
    uint256 destDecimals = ERC20(to).decimals();

    uint256 difference;

    if (destDecimals >= srcDecimals)
    {
      difference = 10 ** destDecimals.sub(srcDecimals);

      return srcQty.mul(rate).mul(difference).div(_DECIMALS);
    }
    else
    {
      difference = 10 ** srcDecimals.sub(destDecimals);

      return srcQty.mul(rate).div(_DECIMALS.mul(difference));
    }
  }

  function convertFromUSD(address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, _DAI, to, getRate(_DAI, to));
  }

  function convertToUSD(address from, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, _DAI, getRate(from, _DAI));
  }

  function convert(address from, address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, to, getRate(from, to));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
pragma solidity 0.7.6;

import {Roles} from "./Roles.sol";


contract PauserRole
{
  using Roles for Roles.Role;

  Roles.Role private _pausers;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  modifier onlyPauser()
  {
    require(isPauser(msg.sender), "!pauser");
    _;
  }

  constructor()
  {
    _pausers.add(msg.sender);

    emit PauserAdded(msg.sender);
  }

  function isPauser(address account) public view returns (bool)
  {
    return _pausers.has(account);
  }

  function addPauser(address account) public onlyPauser
  {
    _pausers.add(account);

    emit PauserAdded(account);
  }

  function renouncePauser() public
  {
    _pausers.remove(msg.sender);

    emit PauserRemoved(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles
{
  struct Role
  {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal
  {
    require(!has(role, account), "has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal
  {
    require(has(role, account), "!has role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool)
  {
    require(account != address(0), "Roles: 0 addy");

    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";


interface IVersionBeacon
{
  event Registered(bytes32 entity, uint256 version, address implementation);


  function exists(bytes32 entity) external view returns (bool status);

  function getLatestVersion(bytes32 entity) external view returns (uint256 version);

  function getLatestImplementation(bytes32 entity) external view returns (address implementation);

  function getImplementationAt(bytes32 entity, uint256 version) external view returns (address implementation);


  function register(bytes32 entity, address implementation) external returns (uint256 version);
}

contract VersionBeacon is IVersionBeacon, Ownable
{
  using EnumerableSet for EnumerableSet.Bytes32Set;


  EnumerableSet.Bytes32Set private _entitySet;
  mapping(bytes32 => address[]) private _versions;


  function getKey (string calldata name) external pure returns (bytes32)
  {
    return keccak256(bytes(name));
  }


  function exists(bytes32 entity) public view override returns (bool status)
  {
    return _entitySet.contains(entity);
  }

  function getImplementationAt(bytes32 entity, uint256 version) public view override returns (address implementation)
  {
    require(exists(entity) && version < _versions[entity].length, "no ver reg'd");

    // return implementation
    return _versions[entity][version];
  }

  function getLatestVersion(bytes32 entity) public view override returns (uint256 version)
  {
    require(exists(entity), "no ver reg'd");

    // get latest version
    return _versions[entity].length - 1;
  }

  function getLatestImplementation(bytes32 entity) public view override returns (address implementation)
  {
    uint256 latestVersion = getLatestVersion(entity);

    // return implementation
    return getImplementationAt(entity, latestVersion);
  }


  function register(bytes32 entity, address implementation) external override onlyOwner returns (uint256 version)
  {
    // get version number
    version = _versions[entity].length;

    // register entity
    _entitySet.add(entity);

    _versions[entity].push(implementation);

    emit Registered(entity, version, implementation);

    return version;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
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

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Ownable} from "../roles/Ownable.sol";

import {IOracle} from "../Oracle.sol";
import {ITokenManager} from "./TokenManager.sol";
import {IDiscountManager} from "./DiscountManager.sol";
import {VersionManager} from "../registries/VersionManager.sol";


interface ICollateralManager
{
  function isSufficientInitialCollateral(address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view returns (bool);

  // returns (bool isSufficient, uint collateralRatio%);
  function isSufficientCollateral(address borrower, address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view returns (bool, uint256);
}

contract CollateralManager is ICollateralManager, Ownable, VersionManager
{
  using SafeMath for uint256;


  uint256 private constant _BASIS_POINT = 10000; // 100%

  mapping(address => uint256) private _initThreshold;
  mapping(address => uint256) private _liquidationThreshold;



  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function getThresholds(address token) external view returns (uint256, uint256)
  {
    return (_initThreshold[token], _liquidationThreshold[token]);
  }

  function setInitThresholds(address[] calldata tokens, uint256[] calldata thresholds) external onlyOwner
  {
    require(tokens.length == thresholds.length, "!=");

    for (uint256 i = 0; i < tokens.length; i++)
    {
      address token = tokens[i];
      uint256 threshold = thresholds[i];

      require(token != address(0), "0 addy");
      require(threshold > 10000, "Invalid val"); // 100%

      _initThreshold[token] = threshold;
    }
  }

  function setLiquidationThresholds(address[] calldata tokens, uint256[] calldata thresholds) external onlyOwner
  {
    require(tokens.length == thresholds.length, "!=");

    for (uint256 i = 0; i < tokens.length; i++)
    {
      address token = tokens[i];
      uint256 threshold = thresholds[i];

      require(token != address(0), "0 addy");
      require(threshold > 10000 && threshold <= 17500, "Invalid val");

      _liquidationThreshold[token] = threshold;
    }
  }


  function _convert(address from, address to, uint256 amount) private view returns (uint256)
  {
    return IOracle(VersionManager._oracle()).convert(from, to, amount);
  }

  function _isValidPairing(address lendingToken, address collateralToken) private view returns (bool)
  {
    return (lendingToken != collateralToken) && ITokenManager(VersionManager._tokenMgr()).isBothWhitelisted(lendingToken, collateralToken) && !ITokenManager(VersionManager._tokenMgr()).isBothStable(lendingToken, collateralToken);
  }

  function isSufficientInitialCollateral(address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view override returns (bool)
  {
    require(_isValidPairing(lendingToken, collateralToken), "Bad pair");

    uint256 convertedPrincipal = _convert(lendingToken, collateralToken, _calcPercentOf(principal, _initThreshold[collateralToken]));

    return collateralAmount >= convertedPrincipal;
  }

  function isSufficientCollateral(address borrower, address lendingToken, uint256 principal, address collateralToken, uint256 collateralAmount) external view override returns (bool, uint256)
  {
    uint256 collateralThreshold = _liquidationThreshold[collateralToken];

    if (IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower))
    {
      collateralThreshold = ITokenManager(VersionManager._tokenMgr()).isStableToken(collateralToken) ? collateralThreshold.sub(250) : collateralThreshold.sub(500);
    }

    uint256 convertedPrincipal = _convert(lendingToken, collateralToken, _calcPercentOf(principal, collateralThreshold));

    return (collateralAmount > convertedPrincipal, collateralAmount.div(convertedPrincipal.div(collateralThreshold)));
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity 0.7.6;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner()
  {
    require(isOwner(), "!owner");
    _;
  }

  constructor()
  {
    _owner = msg.sender;

    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address)
  {
    return _owner;
  }

  function isOwner() public view returns (bool)
  {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addy");

    emit OwnershipTransferred(_owner, newOwner);

    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {DiscounterRole} from "../roles/DiscounterRole.sol";
import {IYLD} from "../interfaces/IYLD.sol";


interface IDiscountManager
{
  event Enroll(address indexed account, uint256 amount);
  event Exit(address indexed account);


  function isDiscounted(address account) external view returns (bool);

  function updateUnlockTime(address lender, address borrower, uint256 duration) external;
}


contract DiscountManager is IDiscountManager, DiscounterRole, ReentrancyGuard
{
  using SafeMath for uint256;


  address private immutable _YLD;

  uint256 private _requiredAmount = 50 * 1e18; // 50 YLD
  bool private _discountsActivated = true;

  mapping(address => uint256) private _balanceOf;
  mapping(address => uint256) private _unlockTimeOf;


  constructor()
  {
    _YLD = address(0xDcB01cc464238396E213a6fDd933E36796eAfF9f);
  }

  function requiredAmount () public view returns (uint256)
  {
    return _requiredAmount;
  }

  function discountsActivated () public view returns (bool)
  {
    return _discountsActivated;
  }

  function balanceOf (address account) public view returns (uint256)
  {
    return _balanceOf[account];
  }

  function unlockTimeOf (address account) public view returns (uint256)
  {
    return _unlockTimeOf[account];
  }

  function isDiscounted(address account) public view override returns (bool)
  {
    return _discountsActivated ? _balanceOf[account] >= _requiredAmount : false;
  }


  function enroll() external nonReentrant
  {
    require(_discountsActivated, "Discounts off");
    require(!isDiscounted(msg.sender), "In");

    require(IERC20(_YLD).transferFrom(msg.sender, address(this), _requiredAmount));

    _balanceOf[msg.sender] = _requiredAmount;
    _unlockTimeOf[msg.sender] = block.timestamp.add(4 weeks);

    emit Enroll(msg.sender, _requiredAmount);
  }

  function exit() external nonReentrant
  {
    require(_balanceOf[msg.sender] >= _requiredAmount, "!in");
    require(block.timestamp > _unlockTimeOf[msg.sender], "Discounting");

    require(IERC20(_YLD).transfer(msg.sender, _balanceOf[msg.sender]));

    _balanceOf[msg.sender] = 0;
    _unlockTimeOf[msg.sender] = 0;

    emit Exit(msg.sender);
  }


  function updateUnlockTime(address lender, address borrower, uint256 duration) external override onlyDiscounter
  {
    uint256 lenderUnlockTime = _unlockTimeOf[lender];
    uint256 borrowerUnlockTime = _unlockTimeOf[borrower];

    if (isDiscounted(lender))
    {
      _unlockTimeOf[lender] = (block.timestamp >= lenderUnlockTime || lenderUnlockTime.sub(block.timestamp) < duration) ? lenderUnlockTime.add(duration.add(4 weeks)) : lenderUnlockTime;
    }
    else if (isDiscounted(borrower))
    {
      _unlockTimeOf[borrower] = (block.timestamp >= borrowerUnlockTime || borrowerUnlockTime.sub(block.timestamp) < duration) ? borrowerUnlockTime.add(duration.add(4 weeks)) : borrowerUnlockTime;
    }
  }

  function activateDiscounts() external onlyDiscounter
  {
    require(!_discountsActivated, "Activated");

    _discountsActivated = true;
  }

  function deactivateDiscounts() external onlyDiscounter
  {
    require(_discountsActivated, "Deactivated");

    _discountsActivated = false;
  }

  function setRequiredAmount(uint256 newAmount) external onlyDiscounter
  {
    require(newAmount > (0.75 * 1e18) && newAmount < type(uint256).max, "Invalid val");

    _requiredAmount = newAmount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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
pragma solidity 0.7.6;

import {Roles} from "./Roles.sol";


contract DiscounterRole
{
  using Roles for Roles.Role;

  Roles.Role private _discounters;

  event DiscounterAdded(address indexed account);
  event DiscounterRemoved(address indexed account);

  modifier onlyDiscounter()
  {
    require(isDiscounter(msg.sender), "!discounter");
    _;
  }

  constructor()
  {
    _discounters.add(msg.sender);

    emit DiscounterAdded(msg.sender);
  }

  function isDiscounter(address account) public view returns (bool)
  {
    return _discounters.has(account);
  }

  function addDiscounter(address account) public onlyDiscounter
  {
    _discounters.add(account);

    emit DiscounterAdded(account);
  }

  function renounceDiscounter() public
  {
    _discounters.remove(msg.sender);

    emit DiscounterRemoved(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IYLD
{
  function renounceMinter() external;

  function mint(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IFeeBurnManager} from "./managers/FeeBurnManager.sol";
import {ILoanFactory} from "./factories/LoanFactory.sol";
import {ILoan} from "./Loan.sol";

import {VersionManager} from "./registries/VersionManager.sol";


interface IEscrow
{
  enum Status {Pending, Accepted, Canceled}


  event Accept(address lender, address borrower, address loan);
  event Cancel(address caller);


  function getLoanDetails() external view returns (ILoan.LoanDetails memory details);
}

contract Escrow is IEscrow, ReentrancyGuardUpgradeable, VersionManager
{
  using SafeERC20 for IERC20;


  Status internal _status;
  ILoan.LoanDetails internal _loanDetails;


  function _initialize() internal initializer
  {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  function _isPending() internal view
  {
    require(_status == Status.Pending, "!pending");
  }

  function _getBurner() internal view returns (address)
  {
    return IFeeBurnManager(VersionManager._feeBurnMgr()).burner();
  }

  function _getPrincipalBalance() internal view returns (uint256)
  {
    return IERC20(_loanDetails.lendingToken).balanceOf(address(this));
  }

  function _getCollateralBalance() internal view returns (uint256)
  {
    return IERC20(_loanDetails.collateralToken).balanceOf(address(this));
  }

  function getStatus () external view returns (Status)
  {
    return _status;
  }

  function getLoanDetails() external view override returns (ILoan.LoanDetails memory details)
  {
    return _loanDetails;
  }


  function _accept(uint256 feeOnInterest, uint256 feeOnPrincipal, bool isOffer) internal returns (address loan)
  {
    _isPending();

    _status = Status.Accepted;

    // tx burn fees
    IERC20(_loanDetails.lendingToken).safeTransfer(Escrow._getBurner(), feeOnInterest);
    IERC20(_loanDetails.collateralToken).safeTransfer(Escrow._getBurner(), feeOnPrincipal);


    if (isOffer)
    {
      _loanDetails.principal = _getPrincipalBalance();
    }
    else
    {
      _loanDetails.collateral = _getCollateralBalance();
    }


    loan = ILoanFactory(VersionManager._loanFactory()).createLoan(_loanDetails);

    // tx collateral to loan
    IERC20(_loanDetails.collateralToken).safeTransfer(loan, _loanDetails.collateral);

    // tx principal to borrower
    IERC20(_loanDetails.lendingToken).safeTransfer(_loanDetails.borrower, _loanDetails.principal);

    emit Accept(_loanDetails.lender, _loanDetails.borrower, loan);

    return loan;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {RewarderRole} from "../roles/RewarderRole.sol";

import {ILoan} from "../Loan.sol";
import {IOracle} from "../Oracle.sol";
import {IYLD} from "../interfaces/IYLD.sol";
import {IDiscountManager} from "./DiscountManager.sol";
import {VersionManager} from "../registries/VersionManager.sol";


interface IRewardManager
{
  event Claim(address indexed borrower, address indexed loan, uint256 amount);


  function trackLoan(address loan, address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) external returns (bool);
}


contract RewardManager is IRewardManager, RewarderRole, ReentrancyGuard, VersionManager
{
  using SafeMath for uint256;


  address private immutable _YLD;

  uint256 private constant _basePrice = 1e18; // $1 scaled
  uint256 private constant _baseRewardCap = 350 * 1e18; // 350 YLD

  uint256 private _lastPrice = 100 * 1e18;
  uint256 private _rewardCostPct = 1 * 1e18; // 1% scaled
  uint256 private _shortDurationPct = 100 * 1e18; // 100%
  uint256 private _rebasingFactor; // 100%
  uint256 private _currentRewardCap;

  mapping(address => bool) private _claimed;
  mapping(address => bool) private _trackedLoan;
  mapping(address => uint256) private _fullRewardOf;


  constructor()
  {
    _YLD = address(0xDcB01cc464238396E213a6fDd933E36796eAfF9f);

    _rebasingFactor = _basePrice.mul(100 * 1e18).div(_lastPrice);
    _currentRewardCap = _calcPercentOf(_baseRewardCap, _rebasingFactor);
  }


  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(100 * 1e18);
  }


  function getRewardOf(address loan) external view returns (uint256)
  {
    return _fullRewardOf[loan];
  }

  function getDetails() external view returns (uint256, uint256, uint256, uint256, uint256)
  {
    return (_rewardCostPct, _shortDurationPct, _rebasingFactor, _lastPrice, _currentRewardCap);
  }


  function hasClaimed(address loan) public view returns (bool)
  {
    return _claimed[loan];
  }

  function calcUnlockDuration(uint256 duration, uint256 timestampStart, uint256 timestampRepaid) public pure returns (uint256 unlockDuration)
  {
    if (duration <= 12 days)
    {
      unlockDuration = timestampRepaid.add(2 days) >= timestampStart.add(duration) ? 10 days : 90 days;
    }
    else
    {
      unlockDuration = (timestampRepaid > timestampStart.add(12 days) && timestampRepaid >= timestampStart.add(10 days).add(_calcPercentOf(duration, 2500))) ? 10 days : 90 days;
    }
  }


  function _getMintableReward(address loan, uint256 timestampRepaid, uint256 timestampFullUnlock) private view returns (uint256)
  {
    uint256 fullReward = _fullRewardOf[loan];
    uint256 mintRate = fullReward.div(timestampFullUnlock.sub(timestampRepaid));

    uint256 secondsSinceRepaid = block.timestamp.sub(timestampRepaid);
    uint256 mintableReward = block.timestamp >= timestampFullUnlock ? fullReward : secondsSinceRepaid.mul(mintRate);

    return mintableReward > _currentRewardCap ? _currentRewardCap : mintableReward;
  }

  function _isEligibleLoan(address loan, ILoan.Status loanStatus) private view returns (bool)
  {
    return _trackedLoan[loan] && loanStatus == ILoan.Status.Repaid;
  }

  function claimReward(address loan) external nonReentrant
  {
    ILoan.LoanMetadata memory loanMetadata = ILoan(loan).getLoanMetadata();
    ILoan.LoanDetails memory loanDetails = ILoan(loan).getLoanDetails();

    require(msg.sender == loanDetails.borrower, "Go borrow");
    require(!hasClaimed(loan), "Claimed");
    require(_isEligibleLoan(loan, loanMetadata.status), "!eligible");


    uint256 unlockDuration = calcUnlockDuration(loanDetails.duration, loanMetadata.timestampStart, loanMetadata.timestampRepaid);

    uint256 reward = _getMintableReward(loan, loanMetadata.timestampRepaid, loanMetadata.timestampRepaid.add(unlockDuration));

    require(IYLD(_YLD).mint(msg.sender, reward));

    _claimed[loan] = true;

    emit Claim(msg.sender, loan, reward);
  }

  /*
   * ((interest - 1) * principalInUSD) / 100;
   * if discounted: ((interest - 0.75) * principalInUSD) / 100;
   */
  function _calcFullReward(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) private view returns (uint256)
  {
    uint256 maxReward = _currentRewardCap;

    uint256 interestPct = interest.mul(1e18).div(100); // BP (coming from LoanFac) -> 1e18
    uint256 multiplier = interestPct.sub(_rewardCostPct);
    uint256 principalInUSD = IOracle(VersionManager._oracle()).convertToUSD(lendingToken, principal);

    if (IDiscountManager(VersionManager._discountMgr()).isDiscounted(borrower))
    {
      multiplier = multiplier.add(0.25 * 1e18);
    }

    multiplier = _calcPercentOf(multiplier, _rebasingFactor);

    if (duration <= 12 days)
    {
      maxReward = _calcPercentOf(maxReward, _shortDurationPct);
    }

    uint256 reward = _calcPercentOf(principalInUSD, multiplier);

    return reward > maxReward ? maxReward : reward;
  }

  function trackLoan(address loan, address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration) external override onlyRewarder returns (bool)
  {
    require(!_trackedLoan[loan], "Tracked");

    _fullRewardOf[loan] = _calcFullReward(borrower, lendingToken, principal, interest, duration);

    require(_fullRewardOf[loan] > 0 && _fullRewardOf[loan] < type(uint256).max, "Err setting reward");

    _trackedLoan[loan] = true;

    return true;
  }


  // below in 1e18
  function setRewardCostPct(uint256 newPct) external onlyRewarder
  {
    require(newPct > 0 && newPct < type(uint256).max, "Invalid x%");

    _rewardCostPct = newPct;
  }

  function setShortDurationPct(uint256 newPct) external onlyRewarder
  {
    require(newPct > 0 && newPct < type(uint256).max, "Invalid x%");

    _shortDurationPct = newPct;
  }

  function setLastPrice(uint256 lastPrice) external onlyRewarder
  {
    require(lastPrice > 0 && lastPrice < type(uint256).max, "Invalid $x");

    _lastPrice = lastPrice;
    _rebasingFactor = _basePrice.mul(100 * 1e18).div(lastPrice);
    _currentRewardCap = _calcPercentOf(_baseRewardCap, _rebasingFactor);
  }

  function renounceMinter() external onlyRewarder
  {
    IYLD(_YLD).renounceMinter();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Roles} from "./Roles.sol";


contract LoanerRole
{
  using Roles for Roles.Role;

  Roles.Role private _loaners;

  event LoanerAdded(address indexed account);
  event LoanerRemoved(address indexed account);

  modifier onlyLoaner()
  {
    require(isLoaner(msg.sender), "!loaner");
    _;
  }

  constructor()
  {
    _loaners.add(msg.sender);

    emit LoanerAdded(msg.sender);
  }

  function isLoaner(address account) public view returns (bool)
  {
    return _loaners.has(account);
  }

  function addLoaner(address account) public virtual onlyLoaner
  {
    _loaners.add(account);

    emit LoanerAdded(account);
  }

  function renounceLoaner() public
  {
    _loaners.remove(msg.sender);

    emit LoanerRemoved(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Roles} from "./Roles.sol";


contract RewarderRole
{
  using Roles for Roles.Role;

  Roles.Role private _rewarders;

  event RewarderAdded(address indexed account);
  event RewarderRemoved(address indexed account);

  modifier onlyRewarder()
  {
    require(isRewarder(msg.sender), "!rewarder");
    _;
  }

  constructor()
  {
    _rewarders.add(msg.sender);

    emit RewarderAdded(msg.sender);
  }

  function isRewarder(address account) public view returns (bool)
  {
    return _rewarders.has(account);
  }

  function addRewarder(address account) public onlyRewarder
  {
    _rewarders.add(account);
    emit RewarderAdded(account);
  }

  function renounceRewarder() public
  {
    _rewarders.remove(msg.sender);
    emit RewarderRemoved(msg.sender);
  }
}