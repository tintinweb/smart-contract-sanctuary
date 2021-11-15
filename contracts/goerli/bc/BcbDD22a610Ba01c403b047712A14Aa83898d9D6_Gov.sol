// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import 'diamond-2/contracts/libraries/LibDiamond.sol';

import '../interfaces/IGov.sol';

import '../storage/GovStorage.sol';
import '../storage/PoolStorage.sol';
import '../storage/SherXStorage.sol';

contract Gov is IGov {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //
  // Modifiers
  //

  modifier onlyGovMain() {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');
    _;
  }

  //
  // View methods
  //

  function getGovMain() external view override returns (address) {
    return GovStorage.gs().govMain;
  }

  function getWatsons() external view override returns (address) {
    return GovStorage.gs().watsonsAddress;
  }

  function getWatsonsSherXWeight() external view override returns (uint256) {
    return GovStorage.gs().watsonsSherxWeight;
  }

  function getWatsonsSherxLastAccrued() external view override returns (uint256) {
    return GovStorage.gs().watsonsSherxLastAccrued;
  }

  function getWatsonsSherXPerBlock() public view override returns (uint256) {
    GovStorage.Base storage gs = GovStorage.gs();
    SherXStorage.Base storage sx = SherXStorage.sx();

    return sx.sherXPerBlock.mul(gs.watsonsSherxWeight).div(10**18);
  }

  function getWatsonsUnmintedSherX() external view override returns (uint256) {
    GovStorage.Base storage gs = GovStorage.gs();

    return block.number.sub(gs.watsonsSherxLastAccrued).mul(getWatsonsSherXPerBlock());
  }

  function getUnstakeWindow() external view override returns (uint256) {
    return GovStorage.gs().unstakeWindow;
  }

  function getCooldown() external view override returns (uint256) {
    return GovStorage.gs().unstakeCooldown;
  }

  function getTokensStaker() external view override returns (IERC20[] memory) {
    return GovStorage.gs().tokensStaker;
  }

  function getTokensSherX() external view override returns (IERC20[] memory) {
    return GovStorage.gs().tokensSherX;
  }

  function getProtocolIsCovered(bytes32 _protocol) external view override returns (bool) {
    return GovStorage.gs().protocolIsCovered[_protocol];
  }

  function getProtocolManager(bytes32 _protocol) external view override returns (address) {
    // NOTE: UNUSED
    return GovStorage.gs().protocolManagers[_protocol];
  }

  function getProtocolAgent(bytes32 _protocol) external view override returns (address) {
    return GovStorage.gs().protocolAgents[_protocol];
  }

  //
  // State changing methods
  //

  function setInitialGovMain(address _govMain) external override {
    GovStorage.Base storage gs = GovStorage.gs();

    require(_govMain != address(0), 'ZERO_GOV');
    require(msg.sender == LibDiamond.contractOwner(), 'NOT_DEV');
    require(gs.govMain == address(0), 'ALREADY_SET');

    gs.govMain = _govMain;
  }

  function transferGovMain(address _govMain) external override onlyGovMain {
    require(_govMain != address(0), 'ZERO_GOV');
    require(GovStorage.gs().govMain != _govMain, 'SAME_GOV');
    GovStorage.gs().govMain = _govMain;
  }

  function setWatsonsAddress(address _watsons) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();

    require(_watsons != address(0), 'ZERO_WATS');
    require(gs.watsonsAddress != _watsons, 'SAME_WATS');
    gs.watsonsAddress = _watsons;
  }

  function setUnstakeWindow(uint256 _unstakeWindow) external override onlyGovMain {
    GovStorage.gs().unstakeWindow = _unstakeWindow;
  }

  function setCooldown(uint256 _period) external override onlyGovMain {
    GovStorage.gs().unstakeCooldown = _period;
  }

  function protocolAdd(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager,
    IERC20[] memory _tokens
  ) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();
    require(!gs.protocolIsCovered[_protocol], 'COVERED');
    gs.protocolIsCovered[_protocol] = true;

    protocolUpdate(_protocol, _eoaProtocolAgent, _eoaManager);
    protocolDepositAdd(_protocol, _tokens);
  }

  function protocolUpdate(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager
  ) public override onlyGovMain {
    require(_protocol != bytes32(0), 'ZERO_PROTOCOL');
    require(_eoaProtocolAgent != address(0), 'ZERO_AGENT');
    require(_eoaManager != address(0), 'ZERO_MANAGER');

    GovStorage.Base storage gs = GovStorage.gs();
    require(gs.protocolIsCovered[_protocol], 'NOT_COVERED');

    // NOTE: UNUSED
    gs.protocolManagers[_protocol] = _eoaManager;
    gs.protocolAgents[_protocol] = _eoaProtocolAgent;
  }

  function protocolDepositAdd(bytes32 _protocol, IERC20[] memory _tokens)
    public
    override
    onlyGovMain
  {
    require(_protocol != bytes32(0), 'ZERO_PROTOCOL');
    require(_tokens.length > 0, 'ZERO');

    GovStorage.Base storage gs = GovStorage.gs();
    require(gs.protocolIsCovered[_protocol], 'NOT_COVERED');

    for (uint256 i; i < _tokens.length; i++) {
      PoolStorage.Base storage ps = PoolStorage.ps(_tokens[i]);
      require(ps.premiums, 'INIT');
      require(!ps.isProtocol[_protocol], 'ALREADY_ADDED');

      ps.isProtocol[_protocol] = true;
      ps.protocols.push(_protocol);
    }
  }

  function protocolRemove(bytes32 _protocol) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();
    require(gs.protocolIsCovered[_protocol], 'NOT_COVERED');

    for (uint256 i; i < gs.tokensSherX.length; i++) {
      IERC20 token = gs.tokensSherX[i];

      PoolStorage.Base storage ps = PoolStorage.ps(token);
      // basically need to check if accruedDebt > 0, but this is true in case protocolPremium > 0
      require(ps.protocolPremium[_protocol] == 0, 'DEBT');
      require(!ps.isProtocol[_protocol], 'POOL_PROTOCOL');
    }
    delete gs.protocolIsCovered[_protocol];
    delete gs.protocolManagers[_protocol];
    delete gs.protocolAgents[_protocol];
  }

  function tokenInit(
    IERC20 _token,
    address _govPool,
    ILock _lock,
    bool _protocolPremium
  ) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    require(address(_token) != address(0), 'ZERO_TOKEN');

    if (_govPool != address(0)) {
      ps.govPool = _govPool;
    }
    require(ps.govPool != address(0), 'ZERO_GOV');

    if (address(_lock) != address(0)) {
      if (address(ps.lockToken) == address(0)) {
        require(_lock.getOwner() == address(this), 'OWNER');
        require(_lock.totalSupply() == 0, 'SUPPLY');
        // If not native (e.g. NOT SherX), verify underlying mapping
        if (address(_token) != address(this)) {
          require(_lock.underlying() == _token, 'UNDERLYING');
        }
        ps.lockToken = _lock;
      }
      if (address(ps.lockToken) == address(_lock)) {
        require(!ps.stakes, 'STAKES_SET');
        ps.stakes = true;
        gs.tokensStaker.push(_token);
      } else {
        revert('WRONG_LOCK');
      }
    }

    if (_protocolPremium) {
      require(!ps.premiums, 'PREMIUMS_SET');
      ps.premiums = true;
      gs.tokensSherX.push(_token);
    }
  }

  function tokenDisableStakers(IERC20 _token, uint256 _index) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    require(gs.tokensStaker[_index] == _token, 'INDEX');
    require(ps.sherXWeight == 0, 'ACTIVE_WEIGHT');

    delete ps.stakes;
    // lockToken is kept, as stakers should be able to unstake
    // staking can be reenabled by calling tokenInit
    gs.tokensStaker[_index] = gs.tokensStaker[gs.tokensStaker.length - 1];
    gs.tokensStaker.pop();
  }

  function tokenDisableProtocol(IERC20 _token, uint256 _index) external override onlyGovMain {
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    require(gs.tokensSherX[_index] == _token, 'INDEX');
    require(ps.totalPremiumPerBlock == 0, 'ACTIVE_PREMIUM');
    // Can not remove with active underlying, SherX holders will see drop in underlying value
    require(ps.sherXUnderlying == 0, 'ACTIVE_SHERX');

    delete ps.premiums;
    gs.tokensSherX[_index] = gs.tokensSherX[gs.tokensSherX.length - 1];
    gs.tokensSherX.pop();
  }

  // Unloading all tokens, likely before calling tokenRemove
  function tokenUnload(
    IERC20 _token,
    IRemove _native,
    address _remaining
  ) external override onlyGovMain {
    require(address(_native) != address(0), 'ZERO_NATIVE');
    require(_remaining != address(0), 'ZERO_REMAIN');
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    require(ps.govPool != address(0), 'EMPTY');

    // Protocol are technically still able to deposit, ps.premiums is still true
    // This makes sure the sherx underlying doesn't grow anymore
    // this function is called before the disable protocol
    // disable stakes --> unload tokens --> disable protocol (sherx) --> remove

    require(!ps.stakes, 'STAKES_SET');
    require(ps.totalPremiumPerBlock == 0, 'ACTIVE_PREMIUM');

    uint256 totalToken = ps.firstMoneyOut.add(ps.sherXUnderlying);

    if (totalToken > 0) {
      _token.approve(address(_native), totalToken);

      (IERC20 newToken, uint256 newFmo, uint256 newSherxUnderlying) =
        _native.swap(_token, ps.firstMoneyOut, ps.sherXUnderlying);

      PoolStorage.Base storage ps2 = PoolStorage.ps(newToken);
      require(ps2.govPool != address(0), 'EMPTY_SWAP');

      ps2.firstMoneyOut = ps2.firstMoneyOut.add(newFmo);
      ps2.sherXUnderlying = ps2.sherXUnderlying.add(newSherxUnderlying);
    }
    delete ps.sherXUnderlying;
    delete ps.firstMoneyOut;

    uint256 totalFee = ps.unallocatedSherX;
    if (totalFee > 0) {
      IERC20(address(this)).safeTransfer(_remaining, totalFee);
      delete ps.unallocatedSherX;
    }

    uint256 balance = ps.stakeBalance;
    if (balance > 0) {
      _token.safeTransfer(_remaining, balance);
      delete ps.stakeBalance;
    }
  }

  function tokenRemove(IERC20 _token) external override onlyGovMain {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    require(ps.govPool != address(0), 'EMPTY');
    require(!ps.stakes, 'STAKES_SET');
    require(!ps.premiums, 'PREMIUMS_SET');
    require(ps.protocols.length == 0, 'ACTIVE_PROTOCOLS');
    require(ps.stakeBalance == 0, 'BALANCE_SET');
    require(ps.firstMoneyOut == 0, 'FMO_SET');
    require(ps.unallocatedSherX == 0, 'SHERX_SET');

    delete ps.govPool;
    delete ps.lockToken;
    delete ps.activateCooldownFee;
    delete ps.sherXWeight;
    delete ps.sherXLastAccrued;

    // NOTE: storage variables need to be kept. To make sure readding the token works
    // IF readding the token, verify off chain if the storage is sufficient.
    // Create re-adding plan off chain if this isn't the case. (e.g. clean storage by doing calls)
    //delete ps.sWithdrawn
    //delete ps.sWeight;

    delete ps.totalPremiumLastPaid;
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
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
*
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';
import '../interfaces/IRemove.sol';

/**
  @title Sherlock Main Governance
  @author Evert Kors
  @notice This contract is used for managing tokens, protocols and more in Sherlock
  @dev Contract is meant to be included as a facet in the diamond
  @dev Storage library is used
*/
interface IGov {
  //
  // Events
  //

  //
  // View methods
  //

  /**
    @notice Returns the main governance address
    @return Main governance address
  */
  function getGovMain() external view returns (address);

  /**
    @notice Returns the compensation address for the Watsons
    @return Watsons address
  */
  function getWatsons() external view returns (address);

  /**
    @notice Returns the weight for the Watsons compensation
    @return Watsons compensation weight
    @dev Value is scaled by 10**18
  */
  function getWatsonsSherXWeight() external view returns (uint256);

  /**
    @notice Returns the last block number the SherX was accrued to the Watsons
    @return Block number
  */
  function getWatsonsSherxLastAccrued() external view returns (uint256);

  /**
    @notice Returns the last block number the SherX was accrued to the Watsons
    @return Block number
  */
  function getWatsonsSherXPerBlock() external view returns (uint256);

  /**
    @notice Returns the total amount of uminted SherX for the Watsons
    @return SherX to be minted
    @dev Based on current block, last accrued and the SherX per block
  */
  function getWatsonsUnmintedSherX() external view returns (uint256);

  /**
    @notice Returns the window of opportunity in blocks to unstake funds
    @notice Cooldown period has to be expired first to start the unstake window
    @return Amount of blocks
  */
  function getUnstakeWindow() external view returns (uint256);

  /**
    @notice Returns the cooldown period in blocks
    @notice After the cooldown period funds can be unstaked
    @return Amount of blocks
  */
  function getCooldown() external view returns (uint256);

  /**
    @notice Returns an array of tokens accounts are allowed to stake in
    @return Array of ERC20 tokens
  */
  function getTokensStaker() external view returns (IERC20[] memory);

  /**
    @notice Returns an array of tokens that are included in the SherX as underlying
    @notice Registered protocols use one or more of these tokens to compensate Sherlock
    @return Array of ERC20 tokens
  */
  function getTokensSherX() external view returns (IERC20[] memory);

  /**
    @notice Verify if a protocol is included in Sherlock
    @param _protocol Protocol identifier
    @return Boolean indicating if protocol is included
  */
  function getProtocolIsCovered(bytes32 _protocol) external view returns (bool);

  /**
    @notice Returns address responsible on behalf of Sherlock for the protocol
    @param _protocol Protocol identifier
    @return Address of account
  */
  function getProtocolManager(bytes32 _protocol) external view returns (address);

  /**
    @notice Returns address responsible on behalf of the protocol
    @param _protocol Protocol identifier
    @return Address of account
    @dev Account is able to withdraw protocol balance
  */
  function getProtocolAgent(bytes32 _protocol) external view returns (address);

  //
  // State changing methods
  //

  /**
    @notice Set initial main governance address
    @param _govMain The address of the main governance
    @dev Diamond deployer - GovDev - is able to call this function
  */
  function setInitialGovMain(address _govMain) external;

  /**
    @notice Transfer the main governance
    @param _govMain New address for the main governance
  */
  function transferGovMain(address _govMain) external;

  /**
    @notice Set the compensation address for the Watsons
    @param _watsons Address for Watsons
  */
  function setWatsonsAddress(address _watsons) external;

  /**
    @notice Set unstake window
    @param _unstakeWindow Unstake window in amount of blocks
  */
  function setUnstakeWindow(uint256 _unstakeWindow) external;

  /**
    @notice Set cooldown period
    @param _period Cooldown period in amount of blocks
  */
  function setCooldown(uint256 _period) external;

  /**
    @notice Add a new protocol to Sherlock
    @param _protocol Protocol identifier
    @param _eoaProtocolAgent Account to be registered as the agent
    @param _eoaManager Account to be registered as the manager
    @param _tokens Initial array of tokens the protocol is allowed to pay in
    @dev _tokens should first be initialized by calling tokenInit()
  */
  function protocolAdd(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager,
    IERC20[] memory _tokens
  ) external;

  /**
    @notice Update protocol agent and/or manager
    @param _protocol Protocol identifier
    @param _eoaProtocolAgent Account to be registered as the agent
    @param _eoaManager Account to be registered as the manager
  */
  function protocolUpdate(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager
  ) external;

  /**
    @notice Add tokens the protocol is allowed to pay in
    @param _protocol Protocol identifier
    @param _tokens Array of tokens to be added as valid protocol payment
    @dev _tokens should first be initialized by calling tokenInit()
  */
  function protocolDepositAdd(bytes32 _protocol, IERC20[] memory _tokens) external;

  /**
    @notice Remove protocol from the Sherlock registry
    @param _protocol Protocol identifier
  */
  function protocolRemove(bytes32 _protocol) external;

  /**
    @notice Initialize a new token
    @param _token Address of the token
    @param _govPool Account responsible for the token
    @param _lock Corresponding lock token, indicating staker token
    @param _protocolPremium Boolean indicating if token should be registered as protocol payment
    @dev Token can be reinitialiezd
    @dev Zero address for _lock will not enable stakers to deposit with the _token
  */
  function tokenInit(
    IERC20 _token,
    address _govPool,
    ILock _lock,
    bool _protocolPremium
  ) external;

  /**
    @notice Disable a token for stakers
    @param _token Address of the token
    @param _index Index of the token in storage array
  */
  function tokenDisableStakers(IERC20 _token, uint256 _index) external;

  /**
    @notice Disable a token for protocols
    @param _token Address of the token
    @param _index Index of the token in storage array
    @dev Removes the token as underlying from SherX
  */
  function tokenDisableProtocol(IERC20 _token, uint256 _index) external;

  /**
    @notice Unload tokens from Sherlock
    @param _token Address of the token
    @param _native Contract being used to swap existing token in Sherlock
    @param _remaining Account used to send the unallocated SherX and remaining balance for _token
  */
  function tokenUnload(
    IERC20 _token,
    IRemove _native,
    address _remaining
  ) external;

  /**
    @notice Remove a token from storage
    @param _token Address of the token
  */
  function tokenRemove(IERC20 _token) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library GovStorage {
  bytes32 constant GOV_STORAGE_POSITION = keccak256('diamond.sherlock.gov');

  struct Base {
    address govMain;
    // NOTE: UNUSED
    mapping(bytes32 => address) protocolManagers;
    mapping(bytes32 => address) protocolAgents;
    uint256 unstakeCooldown;
    uint256 unstakeWindow;
    mapping(bytes32 => bool) protocolIsCovered;
    IERC20[] tokensStaker;
    IERC20[] tokensSherX;
    address watsonsAddress;
    uint256 watsonsSherxWeight;
    uint256 watsonsSherxLastAccrued;
  }

  function gs() internal pure returns (Base storage gsx) {
    bytes32 position = GOV_STORAGE_POSITION;
    assembly {
      gsx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';

// TokenStorage
library PoolStorage {
  string constant POOL_STORAGE_PREFIX = 'diamond.sherlock.pool.';

  struct Base {
    address govPool;
    //
    // Staking
    //
    bool stakes;
    ILock lockToken;
    uint256 activateCooldownFee;
    uint256 stakeBalance;
    mapping(address => UnstakeEntry[]) unstakeEntries;
    uint256 firstMoneyOut;
    uint256 unallocatedSherX;
    // How much sherX is distributed to stakers of this token
    uint256 sherXWeight;
    uint256 sherXLastAccrued;
    // Non-native variables
    mapping(address => uint256) sWithdrawn;
    uint256 sWeight;
    //
    // Protocol payments
    //
    bool premiums;
    mapping(bytes32 => uint256) protocolBalance;
    mapping(bytes32 => uint256) protocolPremium;
    uint256 totalPremiumPerBlock;
    uint256 totalPremiumLastPaid;
    // How much token (this) is available for sherX holders
    uint256 sherXUnderlying;
    mapping(bytes32 => bool) isProtocol;
    bytes32[] protocols;
  }

  struct UnstakeEntry {
    uint256 blockInitiated;
    uint256 lock;
  }

  function ps(IERC20 _token) internal pure returns (Base storage psx) {
    bytes32 position = keccak256(abi.encode(POOL_STORAGE_PREFIX, _token));
    assembly {
      psx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library SherXStorage {
  bytes32 constant SHERX_STORAGE_POSITION = keccak256('diamond.sherlock.x');

  struct Base {
    mapping(IERC20 => uint256) tokenUSD;
    uint256 totalUsdPerBlock;
    uint256 totalUsdPool;
    uint256 totalUsdLastSettled;
    uint256 sherXPerBlock;
    uint256 internalTotalSupply;
    uint256 internalTotalSupplySettled;
  }

  function sx() internal pure returns (Base storage sxx) {
    bytes32 position = SHERX_STORAGE_POSITION;
    assembly {
      sxx.slot := position
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
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
  @title Lock Token
  @author Evert Kors
  @notice Lock tokens represent a stake in Sherlock
*/
interface ILock is IERC20 {
  /**
    @notice Returns the owner of this contract
    @return Owner address
    @dev Should be equal to the Sherlock address
  */
  function getOwner() external view returns (address);

  /**
    @notice Returns token it represents
    @return Token address
  */
  function underlying() external view returns (IERC20);

  /**
    @notice Mint `_amount` tokens for `_account`
    @param _account Account to receive tokens
    @param _amount Amount to be minted
  */
  function mint(address _account, uint256 _amount) external;

  /**
    @notice Burn `_amount` tokens for `_account`
    @param _account Account to be burned
    @param _amount Amount to be burned
  */
  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IRemove {
  /**
    @notice Swap `_token` amounts
    @param _token Token to swap
    @param _fmo Amount of first money out pool swapped
    @param _sherXUnderlying Amount of underlying being swapped
    @return newToken Token being swapped to
    @return newFmo Share of `_fmo` in newToken
    @return newSherxUnderlying Share of `_sherXUnderlying` in newToken
  */
  function swap(
    IERC20 _token,
    uint256 _fmo,
    uint256 _sherXUnderlying
  )
    external
    returns (
      IERC20 newToken,
      uint256 newFmo,
      uint256 newSherxUnderlying
    );
}

