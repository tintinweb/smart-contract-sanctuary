// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';
import {ERC20, ERC20Burnable} from '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {
  PermissionAdmin,
  PermissionOperators
} from '@kyber.network/utils-sc/contracts/PermissionOperators.sol';
import {IKyberStaking} from '../interfaces/staking/IKyberStaking.sol';
import {IRewardsDistributor} from '../interfaces/rewardDistribution/IRewardsDistributor.sol';
import {IKyberGovernance} from '../interfaces/governance/IKyberGovernance.sol';

interface INewKNC {
  function mintWithOldKnc(uint256 amount) external;

  function oldKNC() external view returns (address);
}

interface IKyberNetworkProxy {
  function swapEtherToToken(IERC20Ext token, uint256 minConversionRate)
    external
    payable
    returns (uint256 destAmount);

  function swapTokenToToken(
    IERC20Ext src,
    uint256 srcAmount,
    IERC20Ext dest,
    uint256 minConversionRate
  ) external returns (uint256 destAmount);
}

contract PoolMaster is PermissionAdmin, PermissionOperators, ReentrancyGuard, ERC20Burnable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Ext;
  struct Fees {
    uint256 mintFeeBps;
    uint256 claimFeeBps;
    uint256 burnFeeBps;
  }
  event FeesSet(uint256 mintFeeBps, uint256 burnFeeBps, uint256 claimFeeBps);
  enum FeeTypes {MINT, CLAIM, BURN}
  IERC20Ext internal constant ETH_ADDRESS = IERC20Ext(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  uint256 internal constant PRECISION = (10**18);
  uint256 internal constant BPS = 10000;
  uint256 internal constant MAX_FEE_BPS = 1000; // 10%
  uint256 internal constant INITIAL_SUPPLY_MULTIPLIER = 10;
  Fees public adminFees;
  uint256 public withdrawableAdminFees;
  IKyberNetworkProxy public kyberProxy;
  IKyberStaking public immutable kyberStaking;
  IRewardsDistributor public rewardsDistributor;
  IKyberGovernance public kyberGovernance;
  IERC20Ext public immutable newKnc;
  IERC20Ext private immutable oldKnc;

  receive() external payable {}

  constructor(
    string memory _name,
    string memory _symbol,
    IKyberNetworkProxy _kyberProxy,
    IKyberStaking _kyberStaking,
    IKyberGovernance _kyberGovernance,
    IRewardsDistributor _rewardsDistributor,
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) ERC20(_name, _symbol) PermissionAdmin(msg.sender) {
    kyberProxy = _kyberProxy;
    kyberStaking = _kyberStaking;
    kyberGovernance = _kyberGovernance;
    rewardsDistributor = _rewardsDistributor;
    address _newKnc = address(_kyberStaking.kncToken());
    newKnc = IERC20Ext(_newKnc);
    IERC20Ext _oldKnc = IERC20Ext(INewKNC(_newKnc).oldKNC());
    oldKnc = _oldKnc;
    _oldKnc.safeApprove(_newKnc, type(uint256).max);
    IERC20Ext(_newKnc).safeApprove(address(_kyberStaking), type(uint256).max);
    _changeFees(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  function changeKyberProxy(IKyberNetworkProxy _kyberProxy) external onlyAdmin {
    kyberProxy = _kyberProxy;
  }

  function changeRewardsDistributor(IRewardsDistributor _rewardsDistributor) external onlyAdmin {
    rewardsDistributor = _rewardsDistributor;
  }

  function changeGovernance(IKyberGovernance _kyberGovernance) external onlyAdmin {
    kyberGovernance = _kyberGovernance;
  }

  function changeFees(
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) external onlyAdmin {
    _changeFees(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  function depositWithOldKnc(uint256 tokenWei) external {
    oldKnc.safeTransferFrom(msg.sender, address(this), tokenWei);
    INewKNC(address(newKnc)).mintWithOldKnc(tokenWei);
    _deposit(tokenWei, msg.sender);
  }

  function depositWithNewKnc(uint256 tokenWei) external {
    newKnc.safeTransferFrom(msg.sender, address(this), tokenWei);
    _deposit(tokenWei, msg.sender);
  }

  /*
   * @notice Called by users burning their token
   * @dev Calculates pro rata KNC and redeems from staking contract
   * @param tokensToRedeem
   */
  function withdraw(uint256 tokensToRedeemTwei) external nonReentrant {
    require(balanceOf(msg.sender) >= tokensToRedeemTwei, 'insufficient balance');
    uint256 proRataKnc = getLatestStake().mul(tokensToRedeemTwei).div(totalSupply());
    _unstake(proRataKnc);
    proRataKnc = _administerAdminFee(FeeTypes.BURN, proRataKnc);
    super._burn(msg.sender, tokensToRedeemTwei);
    newKnc.safeTransfer(msg.sender, proRataKnc);
  }

  /*
   * @notice Vote on KyberDAO campaigns
   * @dev Admin calls with relevant params for each campaign in an epoch
   * @param proposalIds: DAO proposalIds
   * @param optionBitMasks: corresponding voting options
   */
  function vote(uint256[] calldata proposalIds, uint256[] calldata optionBitMasks)
    external
    onlyOperator
  {
    require(proposalIds.length == optionBitMasks.length, 'invalid length');
    for (uint256 i = 0; i < proposalIds.length; i++) {
      kyberGovernance.submitVote(proposalIds[i], optionBitMasks[i]);
    }
  }

  /*
   * @notice Claim accumulated reward thus far
   * @notice Will apply admin fee to KNC token.
   * Admin fee for other tokens applied after liquidation to KNC
   * @dev Admin or operator calls with relevant params
   * @param cycle - sourced from Kyber API
   * @param index - sourced from Kyber API
   * @param tokens - ERC20 fee tokens
   * @param merkleProof - sourced from Kyber API
   */
  function claimReward(
    uint256 cycle,
    uint256 index,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external onlyOperator {
    rewardsDistributor.claim(cycle, index, address(this), tokens, cumulativeAmounts, merkleProof);
    uint256 availableKnc = _administerAdminFee(FeeTypes.CLAIM, getAvailableNewKncBalanceTwei());
    _stake(availableKnc);
  }

  /*
   * @notice Will liquidate ETH or ERC20 tokens to KNC
   * @notice Will apply admin fee after liquidations
   * @notice Token allowance should have been given to proxy for liquidation
   * @dev Admin or operator calls with relevant params
   * @param tokens - ETH / ERC20 tokens to be liquidated to KNC
   * @param minRates - kyberProxy.getExpectedRate(eth/token => knc)
   */
  function liquidateTokensToKnc(IERC20Ext[] calldata tokens, uint256[] calldata minRates)
    external
    onlyOperator
  {
    require(tokens.length == minRates.length, 'unequal lengths');
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == ETH_ADDRESS) {
        // leave 1 wei for gas optimizations
        kyberProxy.swapEtherToToken{value: address(this).balance.sub(1)}(newKnc, minRates[i]);
      } else if (tokens[i] != newKnc) {
        // token allowance should have been given
        // leave 1 twei for gas optimizations
        kyberProxy.swapTokenToToken(
          tokens[i],
          tokens[i].balanceOf(address(this)).sub(1),
          newKnc,
          minRates[i]
        );
      }
    }
    uint256 availableKnc = _administerAdminFee(FeeTypes.CLAIM, getAvailableNewKncBalanceTwei());
    _stake(availableKnc);
  }

  /*
   * @notice Called by admin on deployment for KNC
   * @dev Approves Kyber Proxy contract to trade KNC
   * @param Token to approve on proxy contract
   * @param Pass _giveAllowance as true to give max allowance, otherwise resets to zero
   */
  function approveKyberProxyContract(IERC20Ext token, bool giveAllowance) external onlyOperator {
    require(token != newKnc, 'knc not allowed');
    uint256 amount = giveAllowance ? type(uint256).max : 0;
    token.safeApprove(address(kyberProxy), amount);
  }

  function withdrawAdminFee() external onlyOperator {
    uint256 fee = withdrawableAdminFees.sub(1);
    withdrawableAdminFees = 1;
    newKnc.safeTransfer(admin, fee);
  }

  function stakeAdminFee() external onlyOperator {
    uint256 fee = withdrawableAdminFees.sub(1);
    withdrawableAdminFees = 1;
    _deposit(fee, admin);
  }

  /*
   * @notice Returns KNC balance staked to the DAO
   */
  function getLatestStake() public view returns (uint256 latestStake) {
    (latestStake, , ) = kyberStaking.getLatestStakerData(address(this));
  }

  /*
   * @notice Returns KNC balance available to stake
   */
  function getAvailableNewKncBalanceTwei() public view returns (uint256) {
    return newKnc.balanceOf(address(this)).sub(withdrawableAdminFees);
  }

  /*
   * @notice Returns fee (in basis points) depending on fee type
   */
  function getFeeRate(FeeTypes _type) public view returns (uint256) {
    if (_type == FeeTypes.MINT) return adminFees.mintFeeBps;
    else if (_type == FeeTypes.CLAIM) return adminFees.claimFeeBps;
    return adminFees.burnFeeBps;
  }

  /*
   * @notice For APY calculation, returns rate of 1 pool master token to KNC
   */
  function getProRataKnc() public view returns (uint256) {
    if (totalSupply() == 0) return 0;
    return getLatestStake().mul(PRECISION).div(totalSupply());
  }

  function _changeFees(
    uint256 _mintFeeBps,
    uint256 _claimFeeBps,
    uint256 _burnFeeBps
  ) internal {
    require(_mintFeeBps <= MAX_FEE_BPS, 'bad mint bps');
    require(_claimFeeBps <= MAX_FEE_BPS, 'bad claim bps');
    require(_burnFeeBps >= 10 && _burnFeeBps <= MAX_FEE_BPS, 'bad burn bps');
    adminFees = Fees({
      mintFeeBps: _mintFeeBps,
      claimFeeBps: _claimFeeBps,
      burnFeeBps: _burnFeeBps
    });
    emit FeesSet(_mintFeeBps, _claimFeeBps, _burnFeeBps);
  }

  /*
   * @notice returns the amount after fee deduction
   */
  function _administerAdminFee(FeeTypes _feeType, uint256 rewardAmount)
    internal
    returns (uint256)
  {
    uint256 adminFeeToDeduct = rewardAmount.mul(getFeeRate(_feeType)).div(BPS);
    withdrawableAdminFees = withdrawableAdminFees.add(adminFeeToDeduct);
    return rewardAmount.sub(adminFeeToDeduct);
  }

  /*
   * @notice Calculate and stake new KNC to staking contract
   * then mints appropriate amount to user
   */
  function _deposit(uint256 tokenWei, address user) internal {
    uint256 balanceBefore = getLatestStake();
    if (user != admin) _administerAdminFee(FeeTypes.MINT, tokenWei);
    uint256 depositAmount = getAvailableNewKncBalanceTwei();
    _stake(depositAmount);
    uint256 mintAmount = _calculateMintAmount(balanceBefore, depositAmount);
    return super._mint(user, mintAmount);
  }

  /*
   * @notice KyberDAO deposit
   */
  function _stake(uint256 amount) private {
    if (amount > 0) kyberStaking.deposit(amount);
  }

  /*
   * @notice KyberDAO withdraw
   */
  function _unstake(uint256 amount) private {
    kyberStaking.withdraw(amount);
  }

  /*
   * @notice Calculates proportional issuance according to KNC contribution
   * @notice Fund starts at ratio of INITIAL_SUPPLY_MULTIPLIER/1 == token supply/ KNC balance
   * and approaches 1/1 as rewards accrue in KNC
   * @param kncBalanceBefore used to determine ratio of incremental to current KNC
   */
  function _calculateMintAmount(uint256 kncBalanceBefore, uint256 depositAmount)
    private
    view
    returns (uint256 mintAmount)
  {
    uint256 totalSupply = totalSupply();
    if (totalSupply == 0)
      return (kncBalanceBefore.add(depositAmount)).mul(INITIAL_SUPPLY_MULTIPLIER);
    mintAmount = depositAmount.mul(totalSupply).div(kncBalanceBefore);
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
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
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

import "./PermissionAdmin.sol";


abstract contract PermissionOperators is PermissionAdmin {
    uint256 private constant MAX_GROUP_SIZE = 50;

    mapping(address => bool) internal operators;
    address[] internal operatorsGroup;

    event OperatorAdded(address newOperator, bool isAdd);

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IEpochUtils} from './IEpochUtils.sol';

interface IKyberStaking is IEpochUtils {
  event Delegated(
    address indexed staker,
    address indexed representative,
    uint256 indexed epoch,
    bool isDelegated
  );
  event Deposited(uint256 curEpoch, address indexed staker, uint256 amount);
  event Withdraw(uint256 indexed curEpoch, address indexed staker, uint256 amount);

  function initAndReturnStakerDataForCurrentEpoch(address staker)
    external
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function deposit(uint256 amount) external;

  function delegate(address dAddr) external;

  function withdraw(uint256 amount) external;

  /**
   * @notice return combine data (stake, delegatedStake, representative) of a staker
   * @dev allow to get staker data up to current epoch + 1
   */
  function getStakerData(address staker, uint256 epoch)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function getLatestStakerData(address staker)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  /**
   * @notice return raw data of a staker for an epoch
   *         WARN: should be used only for initialized data
   *          if data has not been initialized, it will return all 0
   *          pool master shouldn't use this function to compute/distribute rewards of pool members
   */
  function getStakerRawData(address staker, uint256 epoch)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function kncToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';


interface IRewardsDistributor {
  event Claimed(
    uint256 indexed cycle,
    address indexed user,
    IERC20Ext[] tokens,
    uint256[] claimAmounts
  );

  /**
   * @dev Claim accumulated rewards for a set of tokens at a given cycle number
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return claimAmounts actual claimed token amounts sent to the reward beneficiary
   **/
  function claim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external returns (uint256[] memory claimAmounts);

  /**
   * @dev Checks whether a claim is valid or not
   * @param cycle cycle number
   * @param index user reward info index in the array of reward info
   * during merkle tree generation
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimable by reward beneficiary
   * @param cumulativeAmounts cumulative token amounts claimable by reward beneficiary
   * @param merkleProof merkle proof of claim
   * @return true if valid claim, false otherwise
   **/
  function isValidClaim(
    uint256 cycle,
    uint256 index,
    address user,
    IERC20Ext[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32[] calldata merkleProof
  ) external view returns (bool);

  /**
   * @dev Fetch accumulated claimed rewards for a set of tokens since the first cycle
   * @param user wallet address of reward beneficiary
   * @param tokens array of tokens claimed by reward beneficiary
   * @return userClaimedAmounts claimed token amounts by reward beneficiary since the first cycle
   **/
  function getClaimedAmounts(address user, IERC20Ext[] calldata tokens)
    external
    view
    returns (uint256[] memory userClaimedAmounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IExecutorWithTimelock} from './IExecutorWithTimelock.sol';
import {IVotingPowerStrategy} from './IVotingPowerStrategy.sol';

interface IKyberGovernance {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed,
    Finalized
  }
  enum ProposalType {Generic, Binary}

  /// For Binary proposal, optionBitMask is 0/1/2
  /// For Generic proposal, optionBitMask is bitmask of voted options
  struct Vote {
    uint32 optionBitMask;
    uint224 votingPower;
  }

  struct ProposalWithoutVote {
    uint256 id;
    ProposalType proposalType;
    address creator;
    IExecutorWithTimelock executor;
    IVotingPowerStrategy strategy;
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    string[] options;
    uint256[] voteCounts;
    uint256 totalVotes;
    uint256 maxVotingPower;
    uint256 startTime;
    uint256 endTime;
    uint256 executionTime;
    string link;
    bool executed;
    bool canceled;
  }

  struct Proposal {
    ProposalWithoutVote proposalData;
    mapping(address => Vote) votes;
  }

  struct BinaryProposalParams {
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
  }

  /**
   * @dev emitted when a new binary proposal is created
   * @param proposalId id of the binary proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param targets list of contracts called by proposal's associated transactions
   * @param weiValues list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used
   *     when created the callData
   * @param calldatas list of calldatas: if associated signature empty,
   *     calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *    else calls the target
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event BinaryProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    address[] targets,
    uint256[] weiValues,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a new generic proposal is created
   * @param proposalId id of the generic proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event GenericProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    string[] options,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param proposalId id of the proposal
   **/
  event ProposalCanceled(uint256 proposalId);

  /**
   * @dev emitted when a proposal is queued
   * @param proposalId id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(
    uint256 indexed proposalId,
    uint256 executionTime,
    address indexed initiatorQueueing
  );
  /**
   * @dev emitted when a proposal is executed
   * @param proposalId id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 proposalId, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 votingPower
  );

  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param oldVotingPower Old power of the voter/vote
   * @param newVotingPower New power of the voter/vote
   **/
  event VotingPowerChanged(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 oldVotingPower,
    uint224 newVotingPower
  );

  event DaoOperatorTransferred(address indexed newDaoOperator);

  event ExecutorAuthorized(address indexed executor);

  event ExecutorUnauthorized(address indexed executor);

  event VotingPowerStrategyAuthorized(address indexed strategy);

  event VotingPowerStrategyUnauthorized(address indexed strategy);

  /**
   * @dev Function is triggered when users withdraw from staking and change voting power
   */
  function handleVotingPowerChanged(
    address staker,
    uint256 newVotingPower,
    uint256[] calldata proposalIds
  ) external;

  /**
   * @dev Creates a Binary Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param executionParams data for execution, includes
   *   targets list of contracts called by proposal's associated transactions
   *   weiValues list of value in wei for each proposal's associated transaction
   *   signatures list of function signatures (can be empty)
   *        to be used when created the callData
   *   calldatas list of calldatas: if associated signature empty,
   *        calldata ready, else calldata is arguments
   *   withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *        else calls the target
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createBinaryProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    BinaryProposalParams memory executionParams,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Creates a Generic Proposal
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   **/
  function createGenericProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    string[] memory options,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param optionBitMask vote option(s) selected
   **/
  function submitVote(uint256 proposalId, uint256 optionBitMask) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param choice the bit mask of voted options
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    uint256 choice,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Add new addresses to the list of authorized strategies
   * @param strategies list of new addresses to be authorized strategies
   **/
  function authorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Remove addresses to the list of authorized strategies
   * @param strategies list of addresses to be removed as authorized strategies
   **/
  function unauthorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Returns whether an address is an authorized strategy
   * @param strategy address to evaluate as authorized strategy
   * @return true if authorized
   **/
  function isVotingPowerStrategyAuthorized(address strategy) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getDaoOperator() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVote memory object
   **/
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVote memory);

  /**
   * @dev Getter of the vote data of a proposal by id
   * including totalVotes, voteCounts and options
   * @param proposalId id of the proposal
   * @return (totalVotes, voteCounts, options)
   **/
  function getProposalVoteDataById(uint256 proposalId)
    external
    view
    returns (
      uint256,
      uint256[] memory,
      string[] memory
    );

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({uint32 bitOptionMask, uint224 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
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


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IEpochUtils {
  function epochPeriodInSeconds() external view returns (uint256);

  function firstEpochStartTime() external view returns (uint256);

  function getCurrentEpochNumber() external view returns (uint256);

  function getEpochNumber(uint256 timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IKyberGovernance} from './IKyberGovernance.sol';

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IWithdrawHandler} from '../staking/IWithdrawHandler.sol';

interface IVotingPowerStrategy is IWithdrawHandler {
  /**
   * @dev call by governance when create a proposal
   */
  function handleProposalCreation(
    uint256 proposalId,
    uint256 startTime,
    uint256 endTime
  ) external;

  /**
   * @dev call by governance when cancel a proposal
   */
  function handleProposalCancellation(uint256 proposalId) external;

  /**
   * @dev call by governance when submitting a vote
   * @param choice: unused param for future usage
   * @return votingPower of voter
   */
  function handleVote(
    address voter,
    uint256 proposalId,
    uint256 choice
  ) external returns (uint256 votingPower);

  /**
   * @dev get voter's voting power given timestamp
   * @dev for reading purposes and validating voting power for creating/canceling proposal in the furture
   * @dev when submitVote, should call 'handleVote' instead
   */
  function getVotingPower(address voter, uint256 timestamp)
    external
    view
    returns (uint256 votingPower);

  /**
   * @dev validate that startTime and endTime are suitable for calculating voting power
   * @dev with current version, startTime and endTime must be in the sameEpcoh
   */
  function validateProposalCreation(uint256 startTime, uint256 endTime)
    external
    view
    returns (bool);

  /**
   * @dev getMaxVotingPower at current time
   * @dev call by governance when creating a proposal
   */
  function getMaxVotingPower() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title Interface for callbacks hooks when user withdraws from staking contract
 */
interface IWithdrawHandler {
  function handleWithdrawal(address staker, uint256 reduceAmount) external;
}

