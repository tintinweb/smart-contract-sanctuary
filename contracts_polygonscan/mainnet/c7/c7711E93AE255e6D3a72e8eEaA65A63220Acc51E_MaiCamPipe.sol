// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Pipe.sol";
import "./../../../../third_party/qidao/ICamToken.sol";

/// @title Mai CamWMatic Pipe Contract
/// @author bogdoslav
contract MaiCamPipe is Pipe {
  using SafeERC20 for IERC20;

  struct MaiCamPipeData {
    address sourceToken;
    address lpToken;
    address rewardToken;
  }

  MaiCamPipeData public pipeData;

  /// @dev creates context
  constructor(MaiCamPipeData memory _d) Pipe(
    'MaiCamTokenPipe',
    _d.sourceToken,
    _d.lpToken
  ) {
    require(_d.rewardToken != address(0), "Zero reward token");

    pipeData = _d;
    rewardTokens.push(_d.rewardToken);
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) override onlyPipeline public returns (uint256 output) {
    amount = maxSourceAmount(amount);
    _erc20Approve(sourceToken, pipeData.lpToken, amount);
    ICamToken(outputToken).enter(amount);
    output = _erc20Balance(outputToken);
    _transferERC20toNextPipe(outputToken, output);
  }

  /// @dev function for de-vesting, withdrawals, leaves, paybacks
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) override onlyPipeline  public returns (uint256 output) {
    amount = maxOutputAmount(amount);
    ICamToken(pipeData.lpToken).leave(amount);
    output = _erc20Balance(sourceToken);
    _transferERC20toPrevPipe(sourceToken, output);
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interface/IPipe.sol";
import "./PipeLib.sol";

/// @title Pipe Base Contract
/// @author bogdoslav
abstract contract Pipe is IPipe {
  using SafeERC20 for IERC20;

  /// @notice Address of the master pipeline
  /// @dev After adding the pipe to a pipeline it should be immediately initialized
  address public override pipeline = address(0);

  /// @notice Pipe name for statistical purposes only
  /// @dev initialize it in constructor
  string public override name;
  /// @notice Source token address type
  /// @dev initialize it in constructor, for ether (bnb, matic) use _ETHER
  address public immutable override sourceToken;
  /// @notice Output token address type
  /// @dev initialize it in constructor, for ether (bnb, matic) use _ETHER
  address public immutable override outputToken;

  /// @notice Reward token address for claiming
  /// @dev initialize it in constructor
  address[] public override rewardTokens;

  /// @notice Next pipe in pipeline
  address public override prevPipe;
  /// @notice Previous pipe in pipeline
  address public override nextPipe;

  constructor (
    string memory _name,
    address _sourceToken,
    address _outputToken
  ) {
    require(_sourceToken != address(0), "Zero source token");
    require(_outputToken != address(0), "Zero output token");

    name = _name;
    sourceToken = _sourceToken;
    outputToken = _outputToken;
  }

  modifier onlyPipeline() {
    require(
      pipeline == msg.sender || pipeline == address(this),
      "PIPE: caller is not the pipeline"
    );
    _;
  }

  /// @dev Replaces MAX constant to source token balance. Should be used at put() function start
  function maxSourceAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return sourceBalance();
    } else {
      return amount;
    }
  }

  /// @dev Replaces MAX constant to output token balance. Should be used at get() function start
  function maxOutputAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return outputBalance();
    } else {
      return amount;
    }
  }

  /// @dev After adding the pipe to a pipeline it should be immediately initialized
  function setPipeline(address _pipeline) external override {
    require(pipeline == address(0), "PIPE: Already init");
    pipeline = _pipeline;
  }

  /// @dev Size of reward tokens array
  function rewardTokensLength() external view override returns (uint) {
    return rewardTokens.length;
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _nextPipe - next pipe in pipeline
  function setNextPipe(address _nextPipe) onlyPipeline override external {
    nextPipe = _nextPipe;
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _prevPipe - next pipe in pipeline
  function setPrevPipe(address _prevPipe) onlyPipeline override external {
    prevPipe = _prevPipe;
  }

  /// @dev function for investing, deposits, entering, borrowing. Do not forget to transfer assets to next pipe
  /// @dev In almost all cases overrides should have maxSourceAmount(amount)modifier
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for de-vesting, withdrawals, leaves, paybacks. Amount in underlying units. Do not forget to transfer assets to prev pipe
  /// @dev In almost all cases overrides should have maxOutputAmount(amount)modifier
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for re balancing. Mark it as onlyPipeline when override
  /// @return imbalance in underlying units
  /// @return deficit - when true, then ask to receive underlying imbalance amount, when false - put imbalance to next pipe,
  function rebalance() virtual override external returns (uint256 imbalance, bool deficit) {
    // balanced, no deficit by default
    return (0, false);
  }

  /// @dev Returns true when rebalance needed
  function needsRebalance() virtual override external view returns (bool){
    // balanced, no deficit by default
    return false;
  }

  /// @dev function for claiming rewards
  function claim() onlyPipeline virtual override external {
    for (uint i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      if (rewardToken == address(0)) {
        return;
      }
      require(pipeline != address(0));

      uint256 amount = _erc20Balance(rewardToken);
      if (amount > 0) {
        IERC20(rewardToken).safeTransfer(pipeline, amount);
      }
    }
  }

  /// @dev available source balance (tokens, matic etc).
  /// @return balance in source units
  function sourceBalance() public view virtual override returns (uint256) {
    return _erc20Balance(sourceToken);
  }

  /// @dev underlying balance (LP tokens, collateral etc).
  /// @return balance in underlying units
  function outputBalance() public view virtual override returns (uint256) {
    return _erc20Balance(outputToken);
  }

  /// @notice Pipeline can claim coins that are somehow transferred into the contract
  /// @param recipient Recipient address
  /// @param recipient Token address
  function salvageFromPipe(address recipient, address token) external virtual override onlyPipeline {
    // To make sure that governance cannot come in and take away the coins
    // checking first and last pipes only to have ability salvage tokens from inside pipeline
    if ((!hasPrevPipe() || !hasNextPipe())
      && (sourceToken == token || outputToken == token)) {
      return;
    }

    uint256 amount = _erc20Balance(token);
    if (amount > 0) {
      IERC20(token).safeTransfer(recipient, amount);
    }
  }

  // ***************************************
  // ************** INTERNAL HELPERS *******
  // ***************************************

  /// @dev Checks is pipe have next pipe connected
  /// @return true when connected
  function hasNextPipe() internal view returns (bool) {
    return nextPipe != address(0);
  }

  /// @dev Checks is pipe have previous pipe connected
  /// @return true when connected
  function hasPrevPipe() internal view returns (bool) {
    return prevPipe != address(0);
  }

  /// @dev Transfers ERC20 token to next pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toNextPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasNextPipe()) {
      IERC20(_token).safeTransfer(nextPipe, amount);
    }
  }

  /// @dev Transfers ERC20 token to previous pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toPrevPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasPrevPipe()) {
      IERC20(_token).safeTransfer(prevPipe, amount);
    }
  }

  /// @dev returns ERC20 token balance
  /// @param _token ERC20 token address
  /// @return balance for address(this)
  function _erc20Balance(address _token) internal view returns (uint256){
    return IERC20(_token).balanceOf(address(this));
  }

  /// @dev Approve to spend ERC20 token amount for spender
  /// @param _token ERC20 token address
  /// @param spender address
  /// @param amount to spend
  function _erc20Approve(address _token, address spender, uint256 amount) internal {
    IERC20(_token).safeApprove(spender, 0);
    IERC20(_token).safeApprove(spender, amount);
  }

}

// SPDX-License-Identifier: agpl-3.0
// Original contract: https://github.com/0xlaozi/qidao/blob/main/contracts/camWMatic.sol

pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/math/SafeMath.sol";

//import "./interfaces/IAaveIncentivesController.sol";
//import "./interfaces/ILendingPool.sol";

// stake Token to earn more Token (from farming)
// This contract handles swapping to and from uMiMatic, a staked version of miMatic stable coin.
interface ICamToken {

//    address public Token;
//    address public AaveContract;
//    address public wMatic;
//    address public constant LENDING_POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
//
//    address public treasury;
//
//    address public operator;
    function operator() external returns (address);
//
//    uint16 public depositFeeBP;
    function depositFeeBP() external returns (uint16);

    // Define the compounding aave market token contract
//    constructor() public {
//        Token = 0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4; //amWMatic
//
//        AaveContract = 0x357D51124f59836DeD84c8a1730D72B749d8BC23; // aave incentives controller
//        wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
//
//        treasury = 0x86fE8d6D4C8A007353617587988552B6921514Cb;
//        depositFeeBP = 0;
//
//        operator = address(0);
//    }


    function updateOperator(address _operator) external;

    function updateTreasury(address _treasury) external;

    function updateDepositFee(uint16 _depositFee) external;

    // Locks amToken and mints camToken (shares)
    function enter(uint256 _amount) external;

    function claimAaveRewards() external;

    //function harvestMaticIntoToken() external; // not present at blockchain

    // claim amToken by burning camToken
    function leave(uint256 _share) external;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPipe {

  function pipeline() external view returns (address);

  function name() external view returns (string memory);

  function sourceToken() external view returns (address);

  function outputToken() external view returns (address);

  function rewardTokens(uint index) external view returns (address);

  function rewardTokensLength() external view returns (uint);

  function prevPipe() external view returns (address);

  function nextPipe() external view returns (address);

  function setPipeline(address _pipeline) external;

  function setNextPipe(address _nextPipe) external;

  function setPrevPipe(address _prevPipe) external;

  function put(uint256 amount) external returns (uint256 output);

  function get(uint256 amount) external returns (uint256 output);

  function rebalance() external returns (uint256 imbalance, bool deficit);

  function needsRebalance() external view returns (bool);

  function claim() external;

  function sourceBalance() external view returns (uint256);

  function outputBalance() external view returns (uint256);

  function salvageFromPipe(address recipient, address token) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

library PipeLib {

  /// @dev Constant value to get or put all available token amount
  uint256 public constant MAX_AMOUNT = type(uint).max;

}