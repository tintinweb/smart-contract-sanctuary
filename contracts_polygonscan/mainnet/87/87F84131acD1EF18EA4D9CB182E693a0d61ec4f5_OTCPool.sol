// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../utils/CollectableDustWithTokensManagement.sol';
import './OTCPoolTradeable.sol';
import './OTCPoolDesk.sol';

interface IOTCPool is IOTCPoolTradeable {}

contract OTCPool is IOTCPool, CollectableDustWithTokensManagement, Governable, OTCPoolDesk, OTCPoolTradeable {
  constructor(
    address _governor,
    address _tradeFactory,
    address _OTCProvider
  ) Governable(_governor) OTCPoolDesk(_OTCProvider) OTCPoolTradeable(_tradeFactory) {}

  // CollectableDustWithTokenManagement
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@lbertenasco/contract-utils/interfaces/utils/ICollectableDust.sol';

interface ICollectableDustWithTokensManagement is ICollectableDust {}

abstract contract CollectableDustWithTokensManagement is ICollectableDustWithTokensManagement {
  using SafeERC20 for IERC20;

  mapping(address => uint256) internal _tokensUnderManagement;

  function _addTokenUnderManagement(address _token, uint256 _amount) internal {
    require(
      _tokensUnderManagement[_token] + _amount <= IERC20(_token).balanceOf(address(this)),
      'CollectableDust: cant manage more than balance'
    );
    _tokensUnderManagement[_token] += _amount;
  }

  function _subTokenUnderManagement(address _token, uint256 _amount) internal {
    require(_tokensUnderManagement[_token] >= _amount, 'CollectableDust: subtracting more than managed');
    _tokensUnderManagement[_token] -= _amount;
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'CollectableDust: zero address');
    require(_amount <= IERC20(_token).balanceOf(address(this)) - _tokensUnderManagement[_token], 'CollectableDust: taking more than dust');
    IERC20(_token).safeTransfer(_to, _amount);
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../TradeFactory/TradeFactorySwapperHandler.sol';
import '../OTCSwapper.sol';
import './OTCPoolDesk.sol';

interface IOTCPoolTradeable {
  event TradeFactorySet(address indexed _tradeFactory);
  event Claimed(address indexed _receiver, address _claimedToken, uint256 _amountClaimed);
  event TradePerformed(
    address indexed _swapper,
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _tookFromPool,
    uint256 _tookFromSwapper
  );

  function tradeFactory() external view returns (address _tradeFactory);

  function swappedAvailable(address _swappedToken) external view returns (uint256 _swappedAmount);

  function setTradeFactory(address _tradeFactory) external;

  function claim(address _token, uint256 _amount) external;

  function takeOffer(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _offeredAmount
  ) external returns (uint256 _tookFromPool, uint256 _tookFromSwapper);
}

abstract contract OTCPoolTradeable is IOTCPoolTradeable, OTCPoolDesk {
  using SafeERC20 for IERC20;

  address public override tradeFactory;
  mapping(address => uint256) public override swappedAvailable;

  constructor(address _tradeFactory) {
    _setTradeFactory(_tradeFactory);
  }

  // this modifier allows any registered swapper to utilize OTC funds, this is not an idial design. TODO change.
  modifier onlyRegisteredSwapper() {
    require(ITradeFactorySwapperHandler(tradeFactory).isSwapper(msg.sender), 'OTCPool: unregistered swapper');
    _;
  }

  function setTradeFactory(address _tradeFactory) external override onlyGovernor {
    _setTradeFactory(_tradeFactory);
  }

  function _setTradeFactory(address _tradeFactory) internal {
    require(_tradeFactory != address(0), 'OTCPool: zero address');
    tradeFactory = _tradeFactory;
    emit TradeFactorySet(_tradeFactory);
  }

  function claim(address _token, uint256 _amountToClaim) external override onlyOTCProvider {
    require(msg.sender != address(0), 'OTCPool: zero address');
    require(_token != address(0), 'OTCPool: zero address'); // TODO: can this be deprecated ? technically if token is zero, it wont have swapped available -- gas optimization
    require(_amountToClaim <= swappedAvailable[_token], 'OTCPool: zero claim');
    swappedAvailable[_token] -= _amountToClaim;
    IERC20(_token).safeTransfer(msg.sender, _amountToClaim);
    _subTokenUnderManagement(_token, _amountToClaim);
    emit Claimed(msg.sender, _token, _amountToClaim);
  }

  function takeOffer(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _maxOfferedAmount
  ) external override onlyRegisteredSwapper returns (uint256 _tookFromPool, uint256 _tookFromSwapper) {
    if (availableFor[_wantedTokenFromPool][_offeredTokenToPool] == 0) return (0, 0);
    (_tookFromPool, _tookFromSwapper) = _getMaxTakeableFromPoolAndSwapper(
      msg.sender,
      _offeredTokenToPool,
      _wantedTokenFromPool,
      _maxOfferedAmount
    );
    IERC20(_offeredTokenToPool).safeTransferFrom(msg.sender, address(this), _tookFromSwapper);
    _addTokenUnderManagement(_offeredTokenToPool, _tookFromSwapper);
    availableFor[_wantedTokenFromPool][_offeredTokenToPool] -= _tookFromPool;
    swappedAvailable[_offeredTokenToPool] += _tookFromSwapper;
    IERC20(_wantedTokenFromPool).safeTransfer(msg.sender, _tookFromPool);
    _subTokenUnderManagement(_wantedTokenFromPool, _tookFromPool);
    emit TradePerformed(msg.sender, _offeredTokenToPool, _wantedTokenFromPool, _tookFromPool, _tookFromSwapper);
  }

  function _getMaxTakeableFromPoolAndSwapper(
    address _swapper,
    address _offered,
    address _wanted,
    uint256 _offeredAmount
  ) internal view virtual returns (uint256 _tookFromPool, uint256 _tookFromSwapper) {
    uint256 _maxWantedFromOffered = IOTCSwapper(_swapper).getTotalAmountOut(_offered, _wanted, _offeredAmount);
    _tookFromPool = Math.min(availableFor[_wanted][_offered], _maxWantedFromOffered);
    _tookFromSwapper = IOTCSwapper(_swapper).getTotalAmountOut(_wanted, _offered, _tookFromPool);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@lbertenasco/contract-utils/contracts/utils/Governable.sol';

import '../utils/CollectableDustWithTokensManagement.sol';

interface IOTCPoolDesk {
  event OTCProviderSet(address indexed _OTCProvider);
  event Deposited(address indexed _depositor, address _offeredTokenToPool, address _wantedTokenFromPool, uint256 _amountToOffer);
  event Withdrew(address indexed _receiver, address _offeredTokenToPool, address _wantedTokenFromPool, uint256 _amountToWithdraw);

  function OTCProvider() external view returns (address);

  function availableFor(address _offeredToken, address _wantedtoken) external view returns (uint256 _offeredAmount);

  function setOTCProvider(address _OTCProvider) external;

  function deposit(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _amount
  ) external;

  function withdraw(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _amount
  ) external;
}

abstract contract OTCPoolDesk is IOTCPoolDesk, CollectableDustWithTokensManagement, Governable {
  using SafeERC20 for IERC20;

  address public override OTCProvider;
  mapping(address => mapping(address => uint256)) public override availableFor;

  constructor(address _OTCProvider) {
    _setOTCProvider(_OTCProvider);
  }

  modifier onlyOTCProvider() {
    require(msg.sender == OTCProvider, 'OTCPool: unauthorized');
    _;
  }

  function setOTCProvider(address _OTCProvider) external virtual override onlyGovernor {
    _setOTCProvider(_OTCProvider);
  }

  function _setOTCProvider(address _OTCProvider) internal {
    require(_OTCProvider != address(0), 'OTCPool: zero address');
    OTCProvider = _OTCProvider;
    emit OTCProviderSet(_OTCProvider);
  }

  function deposit(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _amount
  ) public virtual override onlyOTCProvider {
    require(_offeredTokenToPool != address(0) && _wantedTokenFromPool != address(0), 'OTCPool: tokens should not be zero');
    require(_amount > 0, 'OTCPool: should provide more than zero');
    IERC20(_offeredTokenToPool).safeTransferFrom(msg.sender, address(this), _amount);
    availableFor[_offeredTokenToPool][_wantedTokenFromPool] += _amount;
    _addTokenUnderManagement(_offeredTokenToPool, _amount);
    emit Deposited(msg.sender, _offeredTokenToPool, _wantedTokenFromPool, _amount);
  }

  function withdraw(
    address _offeredTokenToPool,
    address _wantedTokenFromPool,
    uint256 _amount
  ) public virtual override onlyOTCProvider {
    require(_offeredTokenToPool != address(0) && _wantedTokenFromPool != address(0), 'OTCPool: tokens should not be zero');
    require(_amount > 0, 'OTCPool: should withdraw more than zero');
    require(availableFor[_offeredTokenToPool][_wantedTokenFromPool] >= _amount, 'OTCPool: not enough provided');
    availableFor[_offeredTokenToPool][_wantedTokenFromPool] -= _amount;
    IERC20(_offeredTokenToPool).safeTransfer(msg.sender, _amount);
    _subTokenUnderManagement(_offeredTokenToPool, _amount);
    emit Withdrew(msg.sender, _offeredTokenToPool, _wantedTokenFromPool, _amount);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(address _to, address _token, uint256 _amount) external;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '../Swapper.sol';
import './TradeFactoryAccessManager.sol';

interface ITradeFactorySwapperHandler {
  event SyncStrategySwapperSet(address indexed _strategy, address _swapper);
  event AsyncStrategySwapperSet(address indexed _strategy, address _swapper);
  event SwapperAdded(address _swapper);
  event SwapperRemoved(address _swapper);

  function strategySyncSwapper(address _strategy) external view returns (address _swapper);

  function strategyAsyncSwapper(address _strategy) external view returns (address _swapper);

  function swappers() external view returns (address[] memory _swappersList);

  function isSwapper(address _swapper) external view returns (bool);

  function swapperStrategies(address _swapper) external view returns (address[] memory _strategies);

  function setStrategySyncSwapper(address _strategy, address _swapper) external;

  function setStrategyAsyncSwapper(address _strategy, address _swapper) external;

  function addSwapper(address _swapper) external;

  function addSwappers(address[] memory __swappers) external;

  function removeSwapper(address _swapper) external;

  function removeSwappers(address[] memory __swappers) external;
}

abstract contract TradeFactorySwapperHandler is ITradeFactorySwapperHandler, TradeFactoryAccessManager {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant SWAPPER_ADDER = keccak256('SWAPPER_ADDER');
  bytes32 public constant SWAPPER_SETTER = keccak256('SWAPPER_SETTER');

  // swappers list
  EnumerableSet.AddressSet internal _swappers;
  // swapper -> strategy list (useful to know if we can safely deprecate a swapper)
  mapping(address => EnumerableSet.AddressSet) internal _swapperStrategies;
  // strategy -> async swapper
  mapping(address => address) public override strategyAsyncSwapper;
  // strategy -> sync swapper
  mapping(address => address) public override strategySyncSwapper;

  constructor(address _swapperAdder, address _swapperSetter) {
    _setRoleAdmin(SWAPPER_ADDER, MASTER_ADMIN);
    _setRoleAdmin(SWAPPER_SETTER, MASTER_ADMIN);
    _setupRole(SWAPPER_ADDER, _swapperAdder);
    _setupRole(SWAPPER_SETTER, _swapperSetter);
  }

  function isSwapper(address _swapper) external view override returns (bool) {
    return _swappers.contains(_swapper);
  }

  function swappers() external view override returns (address[] memory _swappersList) {
    _swappersList = new address[](_swappers.length());
    for (uint256 i = 0; i < _swappers.length(); i++) {
      _swappersList[i] = _swappers.at(i);
    }
  }

  function swapperStrategies(address _swapper) external view override returns (address[] memory _strategies) {
    _strategies = new address[](_swapperStrategies[_swapper].length());
    for (uint256 i = 0; i < _swapperStrategies[_swapper].length(); i++) {
      _strategies[i] = _swapperStrategies[_swapper].at(i);
    }
  }

  function setStrategySyncSwapper(address _strategy, address _swapper) external override onlyRole(SWAPPER_SETTER) {
    // we check that swapper being added is async
    require(ISwapper(_swapper).SWAPPER_TYPE() == ISwapper.SwapperType.SYNC, 'TF: not sync swapper');
    // we check that swapper is not already added
    require(_swappers.contains(_swapper), 'TradeFactory: invalid swapper');
    // remove strategy from previous swapper if any
    if (strategySyncSwapper[_strategy] != address(0)) _swapperStrategies[strategySyncSwapper[_strategy]].remove(_strategy);
    // set new strategy's sync swapper
    strategySyncSwapper[_strategy] = _swapper;
    // add strategy into new swapper
    _swapperStrategies[_swapper].add(_strategy);
    emit SyncStrategySwapperSet(_strategy, _swapper);
  }

  function setStrategyAsyncSwapper(address _strategy, address _swapper) external override onlyRole(SWAPPER_SETTER) {
    // we check that swapper being added is async
    require(ISwapper(_swapper).SWAPPER_TYPE() == ISwapper.SwapperType.ASYNC, 'TF: not async swapper');
    // we check that swapper is not already added
    require(_swappers.contains(_swapper), 'TradeFactory: invalid swapper');
    // remove strategy from previous swapper if any
    if (strategyAsyncSwapper[_strategy] != address(0)) _swapperStrategies[strategyAsyncSwapper[_strategy]].remove(_strategy);
    // set new strategy's async swapper
    strategyAsyncSwapper[_strategy] = _swapper;
    // add strategy into new swapper
    _swapperStrategies[_swapper].add(_strategy);
    emit AsyncStrategySwapperSet(_strategy, _swapper);
  }

  function _addSwapper(address _swapper) internal {
    require(_swapper != address(0), 'TF: zero address');
    require(_swappers.add(_swapper), 'TF: swapper already added');
    emit SwapperAdded(_swapper);
  }

  function addSwapper(address _swapper) external override onlyRole(SWAPPER_ADDER) {
    _addSwapper(_swapper);
  }

  function addSwappers(address[] memory __swappers) external override onlyRole(SWAPPER_ADDER) {
    for (uint256 i = 0; i < __swappers.length; i++) {
      _addSwapper(__swappers[i]);
    }
  }

  function _removeSwapper(address _swapper) internal {
    require(_swappers.remove(_swapper), 'TF: swapper not added');
    // TODO: SHOULD NOT BE ABLE TO REMOVE SWAPPER IF SWAPPER IS ASSIGNED TO STRAT
    emit SwapperRemoved(_swapper);
  }

  function removeSwapper(address _swapper) external override onlyRole(SWAPPER_ADDER) {
    _removeSwapper(_swapper);
  }

  function removeSwappers(address[] memory __swappers) external override onlyRole(SWAPPER_ADDER) {
    for (uint256 i = 0; i < __swappers.length; i++) {
      _removeSwapper(__swappers[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './OTCPool/OTCPool.sol';
import './Swapper.sol';

interface IOTCSwapper is ISwapper {
  function getTotalAmountOut(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256 _amountOut);

  function OTC_POOL() external view returns (address);
}

abstract contract OTCSwapper is IOTCSwapper, Swapper {
  using SafeERC20 for IERC20;

  address public immutable override OTC_POOL;

  constructor(address _otcPool) {
    OTC_POOL = _otcPool;
  }

  function getTotalAmountOut(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view virtual override returns (uint256 _amountOut) {
    _amountOut = _getTotalAmountOut(_tokenIn, _tokenOut, _amountIn);
  }

  function _getTotalAmountOut(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal view virtual returns (uint256 _amountOut);

  function swap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) external override(ISwapper, Swapper) onlyTradeFactory returns (uint256 _receivedAmount) {
    _assertPreSwap(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage);
    IERC20(_tokenIn).safeTransferFrom(TRADE_FACTORY, address(this), _amountIn);
    _receivedAmount = _executeOTCSwap(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage, _data);
    emit Swapped(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage, _receivedAmount, _data);
  }

  function _executeOTCSwap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) internal returns (uint256 _receivedAmount) {
    uint256 _usedBySwapper;

    (_receivedAmount, _usedBySwapper) = IOTCPool(OTC_POOL).takeOffer(_tokenIn, _tokenOut, _amountIn);

    // Buy what's missing from fallback swapper
    if (_usedBySwapper < _amountIn) {
      uint256 _toBuyFromFallbackSwapper = _amountIn - _usedBySwapper;

      _receivedAmount += _executeSwap(_receiver, _tokenIn, _tokenOut, _toBuyFromFallbackSwapper, _maxSlippage, _data);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@lbertenasco/contract-utils/contracts/utils/Governable.sol';
import '@lbertenasco/contract-utils/contracts/utils/CollectableDust.sol';

interface ISwapper {
  enum SwapperType {
    ASYNC,
    SYNC
  }

  event Swapped(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    uint256 _receivedAmount,
    bytes _data
  );

  // solhint-disable-next-line func-name-mixedcase
  function SLIPPAGE_PRECISION() external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function TRADE_FACTORY() external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function SWAPPER_TYPE() external view returns (SwapperType);

  function swap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) external returns (uint256 _receivedAmount);
}

abstract contract Swapper is ISwapper, Governable, CollectableDust {
  using SafeERC20 for IERC20;

  // solhint-disable-next-line var-name-mixedcase
  uint256 public immutable override SLIPPAGE_PRECISION = 10000; // 1 is 0.0001%, 1_000 is 0.1%

  // solhint-disable-next-line var-name-mixedcase
  address public immutable override TRADE_FACTORY;

  constructor(address _governor, address _tradeFactory) Governable(_governor) {
    require(_tradeFactory != address(0), 'Swapper: zero address');
    TRADE_FACTORY = _tradeFactory;
  }

  modifier onlyTradeFactory() {
    require(msg.sender == TRADE_FACTORY, 'Swapper: not trade factory');
    _;
  }

  function _assertPreSwap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage
  ) internal pure {
    require(_receiver != address(0), 'Swapper: zero address');
    require(_tokenIn != address(0) && _tokenOut != address(0), 'Swapper: zero address');
    require(_amountIn > 0, 'Swapper: zero amount');
    require(_maxSlippage > 0, 'Swapper: zero slippage');
  }

  function _executeSwap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) internal virtual returns (uint256 _receivedAmount);

  function swap(
    address _receiver,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) external virtual override onlyTradeFactory returns (uint256 _receivedAmount) {
    _assertPreSwap(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage);
    IERC20(_tokenIn).safeTransferFrom(TRADE_FACTORY, address(this), _amountIn);
    _receivedAmount = _executeSwap(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage, _data);
    emit Swapped(_receiver, _tokenIn, _tokenOut, _amountIn, _maxSlippage, _receivedAmount, _data);
  }

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external virtual override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';

abstract contract TradeFactoryAccessManager is AccessControl {
  bytes32 public constant MASTER_ADMIN = keccak256('MASTER_ADMIN');

  constructor(address _masterAdmin) {
    _setRoleAdmin(MASTER_ADMIN, MASTER_ADMIN);
    _setupRole(MASTER_ADMIN, _masterAdmin);
  }
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '../../interfaces/utils/IGovernable.sol';

contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) {
    require(_governor != address(0), 'governable/governor-should-not-be-zero-address');
    governor = _governor;
  }

  function setPendingGovernor(address _pendingGovernor) external virtual override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external virtual override onlyPendingGovernor {
    _acceptGovernor();
  }

  function _setPendingGovernor(address _pendingGovernor) internal {
    require(_pendingGovernor != address(0), 'governable/pending-governor-should-not-be-zero-addres');
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(_pendingGovernor);
  }

  function _acceptGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit GovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == governor;
  }

  modifier onlyGovernor {
    require(isGovernor(msg.sender), 'governable/only-governor');
    _;
  }

  modifier onlyPendingGovernor {
    require(msg.sender == pendingGovernor, 'governable/only-pending-governor');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import '../../interfaces/utils/ICollectableDust.sol';

abstract
contract CollectableDust is ICollectableDust {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal protocolTokens;

  constructor() {}

  function _addProtocolToken(address _token) internal {
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(protocolTokens.contains(_token), 'collectable-dust/token-not-part-of-the-protocol');
    protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'collectable-dust/cant-send-dust-to-zero-address');
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    if (_token == ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event GovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;
  function acceptGovernor() external;

  function governor() external view returns (address _governor);
  function pendingGovernor() external view returns (address _pendingGovernor);

  function isGovernor(address _account) external view returns (bool _isGovernor);
}