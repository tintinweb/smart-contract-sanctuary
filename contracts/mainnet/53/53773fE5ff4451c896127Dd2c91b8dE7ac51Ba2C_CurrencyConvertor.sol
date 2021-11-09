/*

    Copyright 2021 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { I_StarkwareContract } from "../interfaces/I_StarkwareContracts.sol";

/**
 * @title CurrencyConvertor
 * @author dYdX
 *
 * @notice Contract for depositing to dYdX L2 in non-USDC tokens.
 */
contract CurrencyConvertor is BaseRelayRecipient {
  using SafeERC20 for IERC20;

  // ============ State Variables ============

  I_StarkwareContract public immutable STARKWARE_CONTRACT;

  IERC20 immutable USDC_ADDRESS;

  uint256 immutable USDC_ASSET_TYPE;

  address immutable ETH_PLACEHOLDER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // ============ Constructor ============

  constructor(
    I_StarkwareContract starkwareContractAddress,
    IERC20 usdcAddress,
    uint256 usdcAssetType,
    address _trustedForwarder
  ) {
    STARKWARE_CONTRACT = starkwareContractAddress;
    USDC_ADDRESS = usdcAddress;
    USDC_ASSET_TYPE = usdcAssetType;

    // Set the allowance to the highest possible value.
    usdcAddress.safeApprove(address(starkwareContractAddress), type(uint256).max);

    _setTrustedForwarder(_trustedForwarder);
  }

  // ============ Events ============

  event LogConvertedDeposit(
    address indexed sender,
    address tokenFrom,
    uint256 tokenFromAmount,
    uint256 usdcAmount
  );

  // ============ External Functions ============

  function versionRecipient() external override pure returns (string memory) {
    return '1';
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution
    *
    * @param  depositAmount      The amount of USDC to deposit.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function deposit(
    uint256 depositAmount,
    uint256 starkKey,
    uint256 positionId,
    bytes calldata signature
  ) external {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    // Send fromToken to this contract.
    USDC_ADDRESS.safeTransferFrom(
      _msgSender(),
      address(this),
      depositAmount
    );

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      depositAmount
    );
  }

  /**
    * @notice Approve the token to swap and then makes a deposit with said token.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  tokenFrom          The token to convert from.
    * @param  tokenFromAmount    The amount of `tokenFrom` tokens to deposit.
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  allowanceTarget    The address being approved for the swap.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function approveSwapAndDepositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    address allowanceTarget,
    bytes calldata data,
    bytes calldata signature
  )
    external
    returns (uint256)
  {
    approveSwap(allowanceTarget, tokenFrom);
    return depositERC20(
      tokenFrom,
      tokenFromAmount,
      minUsdcAmount,
      starkKey,
      positionId,
      exchange,
      data,
      signature
    );
  }

  // ============ Public Functions ============

  /**
  * Approve an exchange to swap an asset
  *
  * @param exchange Address of exchange that will be swapping a token
  * @param token    Address of token that will be swapped by the exchange
  */
  function approveSwap(
    address exchange,
    IERC20 token
  )
    public
  {
    // safeApprove requires unsetting the allowance first.
    token.safeApprove(exchange, 0);
    token.safeApprove(exchange, type(uint256).max);
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution, after converting funds to USDC.
    *  Funds will be withdrawn from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  tokenFrom          The ERC20 token to convert from.
    * @param  tokenFromAmount    The amount of `tokenFrom` tokens to deposit.
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    bytes calldata data,
    bytes calldata signature
  )
    public
    returns (uint256)
  {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    // Send fromToken to this contract.
    tokenFrom.safeTransferFrom(
      _msgSender(),
      address(this),
      tokenFromAmount
    );

    uint256 originalUsdcBalance = USDC_ADDRESS.balanceOf(address(this));

    // Swap token
    // Limit variables on the stack to avoid “Stack too deep” error.
    {
      (bool success, bytes memory returndata) = exchange.call(data);
      require(success, string(returndata));
    }

    // Deposit change in balance of USDC to the L2 exchange account of the sender.
    uint256 usdcBalanceChange = USDC_ADDRESS.balanceOf(address(this)) - originalUsdcBalance;
    require(usdcBalanceChange >= minUsdcAmount, 'Received USDC is less than minUsdcAmount');

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalanceChange
    );

    // Log the result.
    emit LogConvertedDeposit(
      _msgSender(),
      address(tokenFrom),
      tokenFromAmount,
      usdcBalanceChange
    );

    return usdcBalanceChange;
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution, after converting funds to USDC.
    *  Funds will be withdrawn from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositEth(
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    bytes calldata data,
    bytes calldata signature
  )
    public
    payable
    returns (uint256)
  {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    uint256 originalUsdcBalance = USDC_ADDRESS.balanceOf(address(this));

    // Swap token
    (bool success, bytes memory returndata) = exchange.call{ value: msg.value }(data);
    require(success, string(returndata));

    // Deposit change in balance of USDC to the L2 exchange account of the sender.
    uint256 usdcBalanceChange = USDC_ADDRESS.balanceOf(address(this)) - originalUsdcBalance;

    require(usdcBalanceChange >= minUsdcAmount, 'Received USDC is less than minUsdcAmount');

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalanceChange
    );


    // Log the result.
    emit LogConvertedDeposit(
      _msgSender(),
      ETH_PLACEHOLDER_ADDRESS,
      msg.value,
      usdcBalanceChange
    );

    return usdcBalanceChange;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
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

/*

    Copyright 2021 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title I_StarkwareContract
 * @author dYdX
 *
 * Interface for starkex-contracts must pass in actual contract when calling CurrencyConvertorProxy.
 */
interface I_StarkwareContract {

  // ============ State-Changing Functions ============

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution.
    *
    * @param  starkKey        The starkKey of the L2 account to deposit into.
    * @param  assetType       The assetType to deposit in.
    * @param  vaultId         The L2 id to deposit into.
    * @param  quantizedAmount The quantized amount being deposited.
    */
    function deposit(
      uint256 starkKey,
      uint256 assetType,
      uint256 vaultId,
      uint256 quantizedAmount
    ) external;

    /**
    * @notice Register to the Starkware Layer2 Solution.
    *
    * @param  ethKey          The ethKey of the L2 account to deposit into.
    * @param  starkKey        The starkKey of the L2 account to deposit into.
    * @param  signature       The signature for registering.
    */
    function registerUser(
      address ethKey,
      uint256 starkKey,
      bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
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