// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "../oz/0.8.0/access/Ownable.sol";
import "../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";
import "../oz/0.8.0/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract ZapBaseV2_1 is Ownable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;
    // swapTarget => approval status
    mapping(address => bool) public approvedTargets;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address internal constant ZapperAdmin =
        0x3CE37278de6388532C3949ce4e886F365B14fB56;

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance - totalAffiliateBalance[tokens[i]];

                Address.sendValue(payable(owner()), qty);
            } else {
                qty =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    totalAffiliateBalance[tokens[i]];
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] =
                totalAffiliateBalance[tokens[i]] -
                tokenBal;

            if (tokens[i] == ETHAddress) {
                Address.sendValue(payable(msg.sender), tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2_1.sol";

abstract contract ZapOutBaseV3_1 is ZapBaseV2_1 {
    using SafeERC20 for IERC20;

    /**
    @dev Transfer tokens from msg.sender to this contract
    @param token The ERC20 token to transfer to this contract
    @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        return amount;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Aave on Polygon (Matic)
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapInBaseV3_1.sol";
import "../../_base/ZapOutBaseV3_1.sol";
import "./AaveInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Aave_Zap_Polygon_V1_0_2 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    //@dev targets must be Zaps (not tokens!!!)
    constructor(
        address[] memory targets,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = true;
        }
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into aave with MATIC or ERC20 tokens
    @param fromToken The token used for entry (address(0) if MATIC)
    @param amountIn The amount of fromToken to invest
    @param aToken Address of the aToken
    @param minATokens The minimum acceptable quantity aTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to aToken underlying address
    @param affiliate Affiliate address
    @return aTokensRec Quantity of aTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address aToken,
        uint256 minATokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 aTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(aToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (aTokensRec) = enterAave(aToken, tokensBought, minATokens);

        emit zapIn(msg.sender, aToken, aTokensRec);
    }

    function enterAave(
        address aToken,
        uint256 underlyingAmount,
        uint256 minATokens
    ) internal returns (uint256 aTokensRec) {
        ILendingPool lendingPool = getLendingPool(aToken);

        address underlyingToken = getUnderlyingToken(aToken);

        uint256 initialBalance = IERC20(aToken).balanceOf(msg.sender);

        _approveToken(underlyingToken, address(lendingPool), underlyingAmount);

        lendingPool.deposit(underlyingToken, underlyingAmount, msg.sender, 151);

        aTokensRec = IERC20(aToken).balanceOf(msg.sender) - initialBalance;

        require(aTokensRec > minATokens, "High Slippage");
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or MATIC with permit
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if MATIC)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param permitSig Signature for permit
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOutWithPermit(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        bytes calldata permitSig,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256) {
        _permit(fromToken, permitAllowance, permitSig);

        return (
            ZapOut(
                fromToken,
                amountIn,
                toToken,
                minToTokens,
                swapTarget,
                swapData,
                affiliate
            )
        );
    }

    function _permit(
        address aToken,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IAToken(aToken).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or MATIC
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if MATIC)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        uint256 underlyingRec = exitAave(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitAave(address aToken, uint256 aTokenAmount)
        internal
        returns (uint256 tokensRec)
    {
        address underlyingToken = getUnderlyingToken(aToken);

        ILendingPool lendingPool = getLendingPool(aToken);

        tokensRec = lendingPool.withdraw(
            underlyingToken,
            aTokenAmount,
            address(this)
        );
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wmaticTokenAddress) {
            IWETH(wmaticTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wmaticTokenAddress && toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address aToken) public returns (address) {
        return IAToken(aToken).UNDERLYING_ASSET_ADDRESS();
    }

    function getLendingPool(address aToken) internal returns (ILendingPool) {
        return ILendingPool(IAToken(aToken).POOL());
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2_1.sol";

abstract contract ZapInBaseV3_1 is ZapBaseV2_1 {
    using SafeERC20 for IERC20;

    /**
    @dev Transfer tokens (including ETH) from msg.sender to this contract
    @param token The ERC20 token to transfer to this contract (0 address if ETH)
    @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                msg.value,
                affiliate,
                enableGoodwill
            );

            return msg.value - totalGoodwillPortion;
        }

        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            affiliate,
            enableGoodwill
        );

        return amount - totalGoodwillPortion;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

interface IAToken {
    function POOL() external returns (address);

    function UNDERLYING_ASSET_ADDRESS() external returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Idle Finance 'Best Yield' and 'Risk Adjusted' opportunities
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./IdleInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Idle_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IIdleTokenHelper private constant IdleTokenHelper =
        IIdleTokenHelper(0x04Ce60ed10F6D2CfF3AA015fc7b950D13c113be5);

    // COMP, IDLE, stkAAVE
    address[] govTokens = [
        0xc00e94Cb662C3520282E6f5717214004A7f26888,
        0x875773784Af8135eA0ef43b5a374AaD105c5D39e,
        0x4da27a545c0c5B758a6BA100e3a049001de870f5
    ];

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into Idle finance with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param idleToken Address of the Idle token
    @param minIdleTokens The minimum acceptable quantity Idle tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to cToken underlying address
    @param affiliate Affiliate address
    @return idleTokensRec Quantity of cTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address idleToken,
        uint256 minIdleTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 idleTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(idleToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (idleTokensRec) = enterIdle(idleToken, toToken, tokensBought);
        require(idleTokensRec > minIdleTokens, "High Slippage");

        IERC20(idleToken).safeTransfer(msg.sender, idleTokensRec);

        emit zapIn(msg.sender, idleToken, idleTokensRec);
    }

    function enterIdle(
        address idleToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 idleTokensRec) {
        uint256 initialBalance = _getBalance(idleToken);

        _approveToken(underlyingToken, idleToken, underlyingAmount);
        IIdleToken(idleToken).mintIdleToken(
            underlyingAmount,
            true,
            ZapperAdmin
        );

        idleTokensRec = _getBalance(idleToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Idle finance, receiving tokens or ETH
    @param fromToken The Idle token being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        (uint256 underlyingRec, uint256[] memory govTokensRec) =
            exitIdle(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        for (uint256 i = 0; i < govTokens.length; i++) {
            if (govTokensRec[i] > 0) {
                IERC20(govTokens[i]).safeTransfer(msg.sender, govTokensRec[i]);
            }
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitIdle(address idleToken, uint256 idleTokenAmount)
        internal
        returns (uint256, uint256[] memory)
    {
        uint256[] memory initialGovBalance = new uint256[](govTokens.length);
        for (uint256 i = 0; i < govTokens.length; i++) {
            initialGovBalance[i] = _getBalance(govTokens[i]);
        }

        uint256 underlyingRec =
            IIdleToken(idleToken).redeemIdleToken(idleTokenAmount);

        uint256[] memory govTokensRec = new uint256[](govTokens.length);
        for (uint256 i = 0; i < govTokens.length; i++) {
            govTokensRec[i] = _getBalance(govTokens[i]) - initialGovBalance[i];
        }
        return (underlyingRec, govTokensRec);
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address idleToken)
        public
        view
        returns (address)
    {
        return IIdleToken(idleToken).token();
    }

    function removeLiquidityReturn(address idleToken, uint256 idleTokenAmount)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (IdleTokenHelper.getRedeemPrice(idleToken) * idleTokenAmount) /
            10**18;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IIdleToken {
    function token() external view returns (address);

    function mintIdleToken(
        uint256 _amount,
        bool _skipWholeRebalance,
        address _referral
    ) external returns (uint256 mintedTokens);

    function redeemIdleToken(uint256 _amount)
        external
        returns (uint256 redeemedTokens);

    function getGovTokens() external view returns (address[] memory);

    function tokenPrice() external view returns (uint256 price);
}

interface IIdleTokenHelper {
    function getRedeemPrice(address idleYieldToken)
        external
        view
        returns (uint256 redeemPrice);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from C.R.E.A.M or Iron Bank
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./CreamInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Cream_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant crETH = 0xD06527D5e56A3495252A528C4987003b712860eE;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        transferOwnership(ZapperAdmin);
    }

    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );
    event zapOut(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    /**
    @notice This function deposits assets into C.R.E.A.M or Iron Bank with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param crToken Address of the crToken or cyToken
    @param minCrTokens The minimum acceptable quantity crTokens or cyTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to crToken or cyToken underlying address
    @param affiliate Affiliate address
    @return crTokensRec Quantity of crTokens or cyTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address crToken,
        uint256 minCrTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 crTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(crToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (crTokensRec) = enterCream(crToken, toToken, tokensBought);
        require(crTokensRec > minCrTokens, "High Slippage");

        IERC20(crToken).safeTransfer(msg.sender, crTokensRec);

        emit zapIn(msg.sender, crToken, crTokensRec, affiliate);
    }

    function enterCream(
        address crToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 crTokensRec) {
        uint256 initialBalance = _getBalance(crToken);

        if (underlyingToken == address(0)) {
            ICreamToken(crToken).mint{ value: underlyingAmount }();
        } else {
            _approveToken(underlyingToken, crToken, underlyingAmount);
            ICreamToken(crToken).mint(underlyingAmount);
        }

        crTokensRec = _getBalance(crToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from C.R.E.A.M or Iron Bank, receiving tokens or ETH
    @param fromToken The crToken or cyToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        uint256 underlyingRec = exitCream(fromToken, amountIn, underlyingToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec, affiliate);
    }

    function exitCream(
        address crToken,
        uint256 cTokenAmount,
        address underlyingToken
    ) internal returns (uint256 underlyingRec) {
        uint256 initialBalance = _getBalance(underlyingToken);

        ICreamToken(crToken).redeem(cTokenAmount);

        underlyingRec = _getBalance(underlyingToken) - initialBalance;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address crToken) public view returns (address) {
        return
            crToken == crETH ? address(0) : ICreamToken(crToken).underlying();
    }

    function removeLiquidityReturn(address crToken, uint256 cTokenAmt)
        external
        view
        returns (uint256 underlyingRec)
    {
        return (cTokenAmt * ICreamToken(crToken).exchangeRateStored()) / 10**18;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface ICreamToken {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Alpha Homora V2 Earn
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./ibTokenInterface.sol";
import "../Cream/CreamInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Alpha_Homora_Earn_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant ibETH = 0xeEa3311250FE4c3268F8E684f7C87A82fF183Ec1;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        transferOwnership(ZapperAdmin);
    }

    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );
    event zapOut(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    /**
    @notice This function deposits assets into Alpha Homora V2 Earn with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param ibToken Address of the ibToken
    @param minIbTokens The minimum acceptable quantity ibTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to ibToken underlying address
    @param affiliate Affiliate address
    @return ibTokensRec Quantity of ibTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address ibToken,
        uint256 minIbTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 ibTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(ibToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (ibTokensRec) = enterAlpha(ibToken, toToken, tokensBought);
        require(ibTokensRec > minIbTokens, "High Slippage");

        IERC20(ibToken).safeTransfer(msg.sender, ibTokensRec);

        emit zapIn(msg.sender, ibToken, ibTokensRec, affiliate);
    }

    function enterAlpha(
        address ibToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 ibTokensRec) {
        uint256 initialBalance = _getBalance(ibToken);

        if (underlyingToken == address(0)) {
            IibToken(ibToken).deposit{ value: underlyingAmount }();
        } else {
            _approveToken(underlyingToken, ibToken, underlyingAmount);
            IibToken(ibToken).deposit(underlyingAmount);
        }

        ibTokensRec = _getBalance(ibToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Alpha Homora V2 Earn, receiving tokens or ETH
    @param fromToken The ibToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        uint256 underlyingRec = exitAlpha(fromToken, amountIn, underlyingToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec, affiliate);
    }

    function exitAlpha(
        address ibToken,
        uint256 ibTokenAmount,
        address underlyingToken
    ) internal returns (uint256 underlyingRec) {
        uint256 initialBalance = _getBalance(underlyingToken);

        IibToken(ibToken).withdraw(ibTokenAmount);

        underlyingRec = _getBalance(underlyingToken) - initialBalance;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getCyToken(address ibToken) public view returns (address) {
        return IibToken(ibToken).cToken();
    }

    function getUnderlyingToken(address ibToken) public view returns (address) {
        return ibToken == ibETH ? address(0) : IibToken(ibToken).uToken();
    }

    function removeLiquidityReturn(address ibToken, uint256 ibTokenAmount)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (ibTokenAmount *
                ICreamToken(getCyToken(ibToken)).exchangeRateStored()) / 10**18;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IibToken {
    function deposit(uint256 amount) external;

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function cToken() external view returns (address);

    function uToken() external view returns (address);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract allows minting and staking of cvxCRV and cvxCurveLP tokens
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IConvexCrvDepositor {
    function deposit(uint256 _amount, bool _lock) external;
}

interface IConvexBooster {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );
}

interface IConvexRewards {
    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);
}

contract Convex_ZapIn_V1 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant crvTokenAddress =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant cvxCrvTokenAddress =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;

    IConvexCrvDepositor depositor =
        IConvexCrvDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
    IConvexBooster booster =
        IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        approvedTargets[_curveZapIn] = true;
    }

    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    /**
    @notice This function adds and stakes liquidity into Convex pools with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromTokenAddress to invest
    @param pid The ID of the Convex pool to enter
    @param minLPTokens The minimum acceptable quantity of Curve LP to receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return crvLPReceived Quantity of Curve LP tokens received
    */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        uint256 pid,
        uint256 minLPTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 crvLPReceived) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        (address crvLpToken, address cvxToken, , address rewardContract, , ) =
            booster.poolInfo(pid);

        crvLPReceived = _fillQuote(
            fromToken,
            crvLpToken,
            toInvest,
            swapTarget,
            swapData
        );
        require(crvLPReceived >= minLPTokens, "High Slippage");

        _approveToken(crvLpToken, address(booster), crvLPReceived);
        booster.deposit(pid, crvLPReceived, false);

        _approveToken(cvxToken, rewardContract, crvLPReceived);
        IConvexRewards(rewardContract).stakeFor(msg.sender, crvLPReceived);

        emit zapIn(msg.sender, crvLpToken, crvLPReceived, affiliate);
    }

    /**
    @notice This function mints and deposits cvxCRV tokens with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromTokenAddress to invest
    @param minCRVTokens The minimum acceptable quantity of Curve tokens receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return cvxCrvReceived Quantity of cvxCRV tokens received
    */
    function ZapInCvxCRV(
        address fromToken,
        uint256 amountIn,
        uint256 minCRVTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 cvxCrvReceived) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        uint256 crvBought =
            _fillQuote(
                fromToken,
                crvTokenAddress,
                toInvest,
                swapTarget,
                swapData
            );
        require(crvBought >= minCRVTokens, "High Slippage");

        _approveToken(crvTokenAddress, address(depositor), crvBought);
        depositor.deposit(crvBought, false);

        IERC20(cvxCrvTokenAddress).safeTransfer(msg.sender, crvBought);

        emit zapIn(msg.sender, crvTokenAddress, crvBought, affiliate);

        return crvBought;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Compound
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./CompoundInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Compound_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into Compound with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param cToken Address of the cToken
    @param minCtokens The minimum acceptable quantity cTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to cToken underlying address
    @param affiliate Affiliate address
    @return cTokensRec Quantity of cTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address cToken,
        uint256 minCtokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 cTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(cToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (cTokensRec) = enterCompound(cToken, toToken, tokensBought);
        require(cTokensRec > minCtokens, "High Slippage");

        IERC20(cToken).safeTransfer(msg.sender, cTokensRec);

        emit zapIn(msg.sender, cToken, cTokensRec);
    }

    function enterCompound(
        address cToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 cTokensRec) {
        uint256 initialBalance = _getBalance(cToken);

        if (underlyingToken == address(0)) {
            ICompoundToken(cToken).mint{ value: underlyingAmount }();
        } else {
            _approveToken(underlyingToken, cToken, underlyingAmount);
            ICompoundToken(cToken).mint(underlyingAmount);
        }

        cTokensRec = _getBalance(cToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Compound, receiving tokens or ETH
    @param fromToken The cToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        uint256 underlyingRec =
            exitCompound(fromToken, amountIn, underlyingToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitCompound(
        address cToken,
        uint256 cTokenAmount,
        address underlyingToken
    ) internal returns (uint256 underlyingRec) {
        uint256 initialBalance = _getBalance(underlyingToken);

        ICompoundToken(cToken).redeem(cTokenAmount);

        underlyingRec = _getBalance(underlyingToken) - initialBalance;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address cToken) public view returns (address) {
        return
            cToken == cETH ? address(0) : ICompoundToken(cToken).underlying();
    }

    function removeLiquidityReturn(address cToken, uint256 cTokenAmt)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (cTokenAmt * ICompoundToken(cToken).exchangeRateStored()) / 10**18;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface ICompoundToken {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
// SPDX-License-Identifier: GPL-2.0

///@author Zapper
///@notice this contract adds liquidity to Balancer liquidity pools in one transaction

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";

interface IWETH {
    function deposit() external payable;
}

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}

interface IBPool {
    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable returns (uint256 poolAmountOut);

    function isBound(address t) external view returns (bool);
}

contract Balancer_ZapIn_General_V4 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    IBFactory BalancerFactory =
        IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;

        transferOwnership(ZapperAdmin);
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice This function is used to invest in given balancer pool using ETH/ERC20 Tokens
    @param _FromTokenContractAddress The token used for investment (address(0x00) if ether)
    @param _ToBalancerPoolAddress The address of balancer pool
    @param _toTokenContractAddress The token with which we are adding liquidity
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget indicates the execution target for swap.
    @param swapData indicates the callData for execution
    @param affiliate Affiliate address
    @return LPTRec quantity of Balancer pool tokens acquired
    */
    function ZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        address _toTokenContractAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 LPTRec) {
        require(
            BalancerFactory.isBPool(_ToBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        // get incoming tokens
        uint256 toInvest =
            _pullTokens(_FromTokenContractAddress, _amount, affiliate, true);

        LPTRec = _performZapIn(
            _FromTokenContractAddress,
            _ToBalancerPoolAddress,
            toInvest,
            _toTokenContractAddress,
            _swapTarget,
            swapData
        );

        require(LPTRec >= _minPoolTokens, "High Slippage");

        IERC20(_ToBalancerPoolAddress).safeTransfer(msg.sender, LPTRec);

        emit zapIn(msg.sender, _ToBalancerPoolAddress, LPTRec);

        return LPTRec;
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _amount,
        address _toTokenContractAddress,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 tokensBought) {
        bool isBound =
            IBPool(_ToBalancerPoolAddress).isBound(_FromTokenContractAddress);

        uint256 balancerTokens;

        if (isBound) {
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _FromTokenContractAddress,
                _amount
            );
        } else {
            uint256 tokenBought =
                _fillQuote(
                    _FromTokenContractAddress,
                    _toTokenContractAddress,
                    _amount,
                    _swapTarget,
                    swapData
                );

            //get BPT
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _toTokenContractAddress,
                tokenBought
            );
        }

        return balancerTokens;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
        require(amtBought > 0, "Swapped To Invalid Intermediate");
    }

    function _enter2Balancer(
        address _ToBalancerPoolAddress,
        address _FromTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 poolTokensOut) {
        require(
            IBPool(_ToBalancerPoolAddress).isBound(_FromTokenContractAddress),
            "Token not bound"
        );

        uint256 allowance =
            IERC20(_FromTokenContractAddress).allowance(
                address(this),
                _ToBalancerPoolAddress
            );

        if (allowance < tokens2Trade) {
            IERC20(_FromTokenContractAddress).safeApprove(
                _ToBalancerPoolAddress,
                tokens2Trade
            );
        }

        poolTokensOut = IBPool(_ToBalancerPoolAddress).joinswapExternAmountIn(
            _FromTokenContractAddress,
            tokens2Trade,
            1
        );

        require(poolTokensOut > 0, "Error Entering Pool");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Aave
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./AaveInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Aave_Zap_V1_0_2 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    //@dev targets must be Zaps (not tokens!!!)
    constructor(
        address[] memory targets,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = true;
        }
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into aave with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param aToken Address of the aToken
    @param minATokens The minimum acceptable quantity aTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to aToken underlying address
    @param affiliate Affiliate address
    @return aTokensRec Quantity of aTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address aToken,
        uint256 minATokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 aTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(aToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (aTokensRec) = enterAave(aToken, tokensBought, minATokens);

        emit zapIn(msg.sender, aToken, aTokensRec);
    }

    function enterAave(
        address aToken,
        uint256 underlyingAmount,
        uint256 minATokens
    ) internal returns (uint256 aTokensRec) {
        ILendingPool lendingPool = getLendingPool(aToken);

        address underlyingToken = getUnderlyingToken(aToken);

        uint256 initialBalance = IERC20(aToken).balanceOf(msg.sender);

        _approveToken(underlyingToken, address(lendingPool), underlyingAmount);

        lendingPool.deposit(underlyingToken, underlyingAmount, msg.sender, 151);

        aTokensRec = IERC20(aToken).balanceOf(msg.sender) - initialBalance;

        require(aTokensRec > minATokens, "High Slippage");
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or ETH with permit
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param permitSig Signature for permit
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOutWithPermit(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        bytes calldata permitSig,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256) {
        _permit(fromToken, permitAllowance, permitSig);

        return (
            ZapOut(
                fromToken,
                amountIn,
                toToken,
                minToTokens,
                swapTarget,
                swapData,
                affiliate
            )
        );
    }

    function _permit(
        address aToken,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IAToken(aToken).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or ETH
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        uint256 underlyingRec = exitAave(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitAave(address aToken, uint256 aTokenAmount)
        internal
        returns (uint256 tokensRec)
    {
        address underlyingToken = getUnderlyingToken(aToken);

        ILendingPool lendingPool = getLendingPool(aToken);

        tokensRec = lendingPool.withdraw(
            underlyingToken,
            aTokenAmount,
            address(this)
        );
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget, _amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address aToken) public returns (address) {
        return IAToken(aToken).UNDERLYING_ASSET_ADDRESS();
    }

    function getLendingPool(address aToken) internal returns (ILendingPool) {
        return ILendingPool(IAToken(aToken).POOL());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

interface IAToken {
    function POOL() external returns (address);

    function UNDERLYING_ASSET_ADDRESS() external returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice This contract adds liquidity to 1inch mooniswap pools using any token
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "../_base/ZapInBaseV3_1.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IMooniswap {
    function getTokens() external view returns (address[] memory);

    function tokens(uint256 i) external view returns (IERC20);

    function fee() external view returns (uint256);

    function deposit(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);

    function depositFor(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts,
        address target
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);

    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns (uint256 result);
}

contract Mooniswap_ZapIn_V2 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Mooniswap pools with ETH/ERC20 Tokens
    @param fromToken The ERC20 token used (address(0x00) if ether)
    @param amountIn The amount of fromToken to invest
    @param minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @return lpReceived Quantity of LP received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toPool,
        uint256 minPoolTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual
    ) external payable stopInEmergency returns (uint256 lpReceived) {
        uint256 intermediateAmt;

        {
            // get incoming tokens
            uint256 toInvest =
                _pullTokens(fromToken, amountIn, affiliate, true);

            // get intermediate pool token
            intermediateAmt = _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );
        }

        // fetch pool tokens
        address[] memory tokens = IMooniswap(toPool).getTokens();

        // divide intermediate into appropriate underlying tokens to add liquidity
        uint256[2] memory tokensBought =
            _swapIntermediate(
                toPool,
                tokens,
                intermediateToken,
                intermediateAmt
            );

        // add liquidity
        lpReceived = _inchDeposit(
            tokens,
            tokensBought,
            toPool,
            transferResidual
        );

        require(lpReceived >= minPoolTokens, "High Slippage");
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }

    function _getReserves(address token, address user)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = user.balance;
        } else {
            balance = IERC20(token).balanceOf(user);
        }
    }

    function _swapIntermediate(
        address toPool,
        address[] memory tokens,
        address intermediateToken,
        uint256 intermediateAmt
    ) internal returns (uint256[2] memory tokensBought) {
        uint256[2] memory reserves =
            [_getReserves(tokens[0], toPool), _getReserves(tokens[1], toPool)];

        if (intermediateToken == tokens[0]) {
            uint256 amountToSwap =
                calculateSwapInAmount(reserves[0], intermediateAmt);

            tokensBought[1] = _token2Token(
                intermediateToken,
                tokens[1],
                amountToSwap,
                toPool
            );
            tokensBought[0] = intermediateAmt - amountToSwap;
        } else {
            uint256 amountToSwap =
                calculateSwapInAmount(reserves[1], intermediateAmt);

            tokensBought[0] = _token2Token(
                intermediateToken,
                tokens[0],
                amountToSwap,
                toPool
            );
            tokensBought[1] = intermediateAmt - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    function _token2Token(
        address fromToken,
        address toToken,
        uint256 amount,
        address viaPool
    ) internal returns (uint256 tokenBought) {
        uint256 valueToSend;
        if (fromToken != address(0)) {
            _approveToken(fromToken, viaPool);
        } else {
            valueToSend = amount;
        }

        tokenBought = IMooniswap(viaPool).swap{ value: valueToSend }(
            IERC20(fromToken),
            IERC20(toToken),
            amount,
            0,
            address(0)
        );
        require(tokenBought > 0, "Error Swapping Tokens 2");
    }

    function _inchDeposit(
        address[] memory tokens,
        uint256[2] memory amounts,
        address toPool,
        bool transferResidual
    ) internal returns (uint256 lpReceived) {
        uint256[2] memory minAmounts;
        uint256[2] memory receivedAmounts;
        // tokens[1] is never ETH, approving for both cases
        _approveToken(tokens[1], toPool);
        if (tokens[0] == address(0)) {
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor{
                value: amounts[0]
            }([amounts[0], amounts[1]], minAmounts, msg.sender);
        } else {
            _approveToken(tokens[0], toPool);
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor(
                [amounts[0], amounts[1]],
                minAmounts,
                msg.sender
            );
        }
        emit zapIn(msg.sender, toPool, lpReceived);
        if (transferResidual) {
            // transfer any residue
            if (amounts[0] > receivedAmounts[0]) {
                _transferTokens(tokens[0], amounts[0] - receivedAmounts[0]);
            }
            if (amounts[1] > receivedAmounts[1]) {
                _transferTokens(tokens[1], amounts[1] - receivedAmounts[1]);
            }
        }
    }

    function _transferTokens(address token, uint256 amt) internal {
        if (token == address(0)) {
            Address.sendValue(payable(msg.sender), amt);
        } else {
            IERC20(token).safeTransfer(msg.sender, amt);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper DCA (Dollar-Cost Averaging) Vault Registry.
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../oz/0.8.0/access/Ownable.sol";

contract Infuze_Registry_V1 is Ownable {
    // Mapping from factory address to approval status
    mapping(address => bool) public approvedFactory;

    // Number of total vaults
    uint256 public numVaults;
    // Address of each vault
    address[] public vaults;

    event DeployVault(address vault, uint256 numVaults);

    modifier onlyFactory {
        require(approvedFactory[msg.sender], "Caller is not factory");
        _;
    }

    function addVault(address vault) external onlyFactory {
        vaults.push(vault);

        emit DeployVault(vault, numVaults++);
    }

    function getAllVaults() external view returns (address[] memory _vaults) {
        _vaults = vaults;
    }

    function setApprovedFactories(
        address[] calldata factories,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(factories.length == isApproved.length, "Invalid input length");

        for (uint256 i = 0; i < factories.length; i++) {
            approvedFactory[factories[i]] = isApproved[i];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "../oz/0.8.0/access/Ownable.sol";
import "../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";

abstract contract ZapBaseV2 is Ownable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;
    // swapTarget => approval status
    mapping(address => bool) public approvedTargets;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance - totalAffiliateBalance[tokens[i]];

                Address.sendValue(payable(owner()), qty);
            } else {
                qty =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    totalAffiliateBalance[tokens[i]];
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] =
                totalAffiliateBalance[tokens[i]] -
                tokenBal;

            if (tokens[i] == ETHAddress) {
                Address.sendValue(payable(msg.sender), tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract swaps and bridges ETH/Tokens to Matic/Polygon
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.0;

import "../../_base/ZapBaseV2.sol";

// PoS Bridge
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function tokenToType(address) external returns (bytes32);

    function typeToPredicate(bytes32) external returns (address);
}

// Plasma Bridge
interface IDepositManager {
    function depositERC20ForUser(
        address _token,
        address _user,
        uint256 _amount
    ) external;
}

interface IWETH {
    function deposit() external payable;
}

contract Zapper_Matic_Bridge_V1_1 is ZapBaseV2 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IRootChainManager public rootChainManager =
        IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    IDepositManager public depositManager =
        IDepositManager(0x401F6c983eA34274ec46f84D70b31C151321188b);

    address private constant maticAddress =
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        _approveToken(maticAddress, address(depositManager));

        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    /**
    @notice Bridge from Ethereum to Matic
    @notice Use index 0 for primary swap and index 1 for matic swap
    @param fromToken Address of the token to swap from
    @param toToken Address of the token to bridge
    @param swapAmounts Quantites of fromToken to swap to toToken and matic
    @param minTokensRec Minimum acceptable quantity of swapped tokens and/or matic
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapBridge(
        address fromToken,
        address toToken,
        uint256[2] calldata swapAmounts,
        uint256[2] calldata minTokensRec,
        address[2] calldata swapTargets,
        bytes[2] calldata swapData,
        address affiliate
    ) external payable stopInEmergency {
        uint256[2] memory toInvest =
            _pullTokens(fromToken, swapAmounts, affiliate);

        if (swapAmounts[0] > 0) {
            // Token swap
            uint256 toTokenAmt =
                _fillQuote(
                    fromToken,
                    toInvest[0],
                    toToken,
                    swapTargets[0],
                    swapData[0]
                );
            require(toTokenAmt >= minTokensRec[0], "ERR: High Slippage 1");

            _bridgeToken(toToken, toTokenAmt);
        }

        // Matic swap
        if (swapAmounts[1] > 0) {
            uint256 maticAmount =
                _fillQuote(
                    fromToken,
                    toInvest[1],
                    maticAddress,
                    swapTargets[1],
                    swapData[1]
                );
            require(maticAmount >= minTokensRec[1], "ERR: High Slippage 2");

            _bridgeMatic(maticAmount);
        }
    }

    function _bridgeToken(address toToken, uint256 toTokenAmt) internal {
        if (toToken == address(0)) {
            rootChainManager.depositEtherFor{ value: toTokenAmt }(msg.sender);
        } else {
            bytes32 tokenType = rootChainManager.tokenToType(toToken);
            address predicate = rootChainManager.typeToPredicate(tokenType);
            _approveToken(toToken, predicate);
            rootChainManager.depositFor(
                msg.sender,
                toToken,
                abi.encode(toTokenAmt)
            );
        }
    }

    function _bridgeMatic(uint256 maticAmount) internal {
        depositManager.depositERC20ForUser(
            maticAddress,
            msg.sender,
            maticAmount
        );
    }

    // 0x Swap
    function _fillQuote(
        address fromToken,
        uint256 amount,
        address toToken,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        uint256 valueToSend;

        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }

    function _pullTokens(
        address fromToken,
        uint256[2] memory swapAmounts,
        address affiliate
    ) internal returns (uint256[2] memory toInvest) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No eth sent");
            require(
                swapAmounts[0] + (swapAmounts[1]) == msg.value,
                "msg.value != fromTokenAmounts"
            );
        } else {
            require(msg.value == 0, "Eth sent with token");

            // transfer token
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapAmounts[0] + (swapAmounts[1])
            );
        }

        if (swapAmounts[0] > 0) {
            toInvest[0] =
                swapAmounts[0] -
                (_subtractGoodwill(fromToken, swapAmounts[0], affiliate));
        }

        if (swapAmounts[1] > 0) {
            toInvest[1] =
                swapAmounts[1] -
                (_subtractGoodwill(fromToken, swapAmounts[1], affiliate));
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2.sol";

abstract contract ZapOutBaseV3 is ZapBaseV2 {
    using SafeERC20 for IERC20;

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            uint256 allowance =
                IERC20(token).allowance(msg.sender, address(this));
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                allowance
            );

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from yEarn Vaults to ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapOutBaseV3.sol";

interface IWETH {
    function withdraw(uint256 wad) external;
}

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function name() external pure returns (string memory);

    function nonces(address owner) external view returns (uint256);
}

interface IYVaultV1Registry {
    function getVaults() external view returns (address[] memory);

    function getVaultsLength() external view returns (uint256);
}

// -- Aave --
interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

contract yVault_ZapOut_V3_0_1 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    IYVaultV1Registry V1Registry =
        IYVaultV1Registry(0x3eE41C098f9666ed2eA246f4D2558010e59d63A0);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    constructor(
        address _curveZapOut,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // Curve ZapOut
        approvedTargets[_curveZapOut] = true;
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    /**
        @notice Zap out in to a single token with permit
        @param fromVault Vault from which to remove liquidity
        @param amountIn Quantity of vault tokens to remove
        @param toToken Address of desired token
        @param isAaveUnderlying True if vault contains aave token
        @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
        @param permitSig Encoded permit hash, which contains r,s,v values
        @param swapTarget Execution targets for swap or Zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return tokensReceived Quantity of tokens or ETH received
    */
    function ZapOutWithPermit(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        bytes calldata permitSig,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external returns (uint256 tokensReceived) {
        // permit
        _permit(fromVault, permitAllowance, permitSig);

        return
            ZapOut(
                fromVault,
                amountIn,
                toToken,
                isAaveUnderlying,
                minToTokens,
                swapTarget,
                swapData,
                affiliate,
                shouldSellEntireBalance
            );
    }

    function _permit(
        address fromVault,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        bool success =
            IYVault(fromVault).permit(
                msg.sender,
                address(this),
                amountIn,
                deadline,
                permitSig
            );
        require(success, "Could Not Permit");
    }

    /**
        @notice Zap out in to a single token with permit
        @param fromVault Vault from which to remove liquidity
        @param amountIn Quantity of vault tokens to remove
        @param toToken Address of desired token
        @param isAaveUnderlying True if vault contains aave token
        @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
        @param swapTarget Execution targets for swap or Zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return tokensReceived Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensReceived) {
        _pullTokens(fromVault, amountIn, shouldSellEntireBalance);

        // get underlying token from vault
        address underlyingToken = IYVault(fromVault).token();
        uint256 underlyingTokenReceived =
            _vaultWithdraw(fromVault, amountIn, underlyingToken);

        // swap to toToken
        uint256 toTokenAmt;

        if (isAaveUnderlying) {
            address underlyingAsset =
                IAToken(underlyingToken).underlyingAssetAddress();
            // unwrap atoken
            IAToken(underlyingToken).redeem(underlyingTokenReceived);

            // aTokens are 1:1
            if (underlyingAsset == toToken) {
                toTokenAmt = underlyingTokenReceived;
            } else {
                toTokenAmt = _fillQuote(
                    underlyingAsset,
                    toToken,
                    underlyingTokenReceived,
                    swapTarget,
                    swapData
                );
            }
        } else {
            toTokenAmt = _fillQuote(
                underlyingToken,
                toToken,
                underlyingTokenReceived,
                swapTarget,
                swapData
            );
        }
        require(toTokenAmt >= minToTokens, "Err: High Slippage");

        uint256 totalGoodwillPortion =
            _subtractGoodwill(toToken, toTokenAmt, affiliate, true);
        tokensReceived = toTokenAmt - totalGoodwillPortion;

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(payable(msg.sender), tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
        emit zapOut(msg.sender, fromVault, toToken, tokensReceived);
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IYVault(fromVault).withdraw(amount);

        underlyingReceived =
            _getBalance(underlyingVaultToken) -
            iniUnderlyingBal;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");
        amtBought = finalBal - iniBal;
    }

    /**
        @notice Utility function to determine the quantity of underlying tokens removed from vault
        @param fromVault Yearn vault from which to remove liquidity
        @param liquidity Quantity of vault tokens to remove
        @return Quantity of underlying LP or token removed
    */
    function removeLiquidityReturn(address fromVault, uint256 liquidity)
        external
        view
        returns (uint256)
    {
        IYVault vault = IYVault(fromVault);

        address[] memory V1Vaults = V1Registry.getVaults();

        for (uint256 i = 0; i < V1Registry.getVaultsLength(); i++) {
            if (V1Vaults[i] == fromVault)
                return (liquidity * (vault.getPricePerFullShare())) / (10**18);
        }
        return (liquidity * (vault.pricePerShare())) / (10**vault.decimals());
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract implements one click removal of liquidity from UniswapV2 pools, receiving ETH, ERC20 or both.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapOutBaseV3.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract UniswapV2_ZapOut_General_V5 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private constant uniswapFactory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @notice Zap out in both tokens
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param affiliate Affiliate address
        @return amountA Quantity of tokenA received after zapout
        @return amountB Quantity of tokenB received after zapout
    */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(uniswapV2Router), incomingLP);

        if (token0 == wethTokenAddress || token1 == wethTokenAddress) {
            address _token = token0 == wethTokenAddress ? token1 : token0;
            (amountA, amountB) = uniswapV2Router.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            (amountA, amountB) = uniswapV2Router.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
        @notice Zap out in a single token
        @param toTokenAddress Address of desired token
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param minTokensRec Minimum quantity of tokens to receive
        @param swapTargets Execution targets for swaps
        @param swapData DEX swap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
    @notice Zap out in both tokens with permit
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitSig Signature for permit
    @return amountA Quantity of tokenA received
    @return amountB Quantity of tokenB received
    */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a single token with permit
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param permitSig Signature for permit
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(uniswapV2Router), incomingLP);

        (amount0, amount1) = uniswapV2Router.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
        address token1 = IUniswapV2Pair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
        @notice Utility function to determine quantity and addresses of tokens being removed
        @param fromPoolAddress Pool from which to remove liquidity
        @param liquidity Quantity of LP tokens to remove.
        @return amountA Quantity of tokenA removed
        @return amountB Quantity of tokenB removed
        @return token0 Address of the underlying token to be removed
        @return token1 Address of the underlying token to be removed
    */
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract implements one click removal of liquidity from Sushiswap pools, receiving ETH, ERC20 or both.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapOutBaseV3.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Sushiswap_ZapOut_General_V4 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IUniswapV2Router02 private constant sushiswapRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Factory private constant sushiswapFactory =
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @notice Zap out in both tokens
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param affiliate Affiliate address
        @return amountA Quantity of tokenA received after zapout
        @return amountB Quantity of tokenB received after zapout
    */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(sushiswapRouter), incomingLP);

        if (token0 == wethTokenAddress || token1 == wethTokenAddress) {
            address _token = token0 == wethTokenAddress ? token1 : token0;
            (amountA, amountB) = sushiswapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            (amountA, amountB) = sushiswapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
    @notice Zap out in both tokens with permit
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitSig Signature for permit
    @return amountA Quantity of tokenA received
    @return amountB Quantity of tokenB received
    */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a single token with permit
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(sushiswapRouter), incomingLP);

        (amount0, amount1) = sushiswapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
        address token1 = IUniswapV2Pair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
        @notice Utility function to determine quantity and addresses of tokens being removed
        @param fromPoolAddress Pool from which to remove liquidity
        @param liquidity Quantity of LP tokens to remove.
        @return amountA Quantity of tokenA removed
        @return amountB Quantity of tokenB removed
        @return token0 Address of the underlying token to be removed
        @return token1 Address of the underlying token to be removed
    */
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract removes liquidity from Sushiswap pools on Polygon (Matic), receiving ETH, ERC20 or both.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapOutBaseV3.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Sushiswap_ZapOut_Polygon_V3 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IUniswapV2Router02 private constant sushiswapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IUniswapV2Factory private constant sushiswapFactory =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @notice Zap out in both tokens
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param affiliate Affiliate address
        @return amountA Quantity of tokenA received after zapout
        @return amountB Quantity of tokenB received after zapout
    */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(sushiswapRouter), incomingLP);

        if (token0 == wmaticTokenAddress || token1 == wmaticTokenAddress) {
            address _token = token0 == wmaticTokenAddress ? token1 : token0;
            (amountA, amountB) = sushiswapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            (amountA, amountB) = sushiswapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
    @notice Zap out in both tokens with permit
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitSig Signature for permit
    @return amountA Quantity of tokenA received
    @return amountB Quantity of tokenB received
    */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a single token with permit
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param permitSig Signature for permit
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(sushiswapRouter), incomingLP);

        (amount0, amount1) = sushiswapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
        address token1 = IUniswapV2Pair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wmaticTokenAddress && toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
        @notice Utility function to determine quantity and addresses of tokens being removed
        @param fromPoolAddress Pool from which to remove liquidity
        @param liquidity Quantity of LP tokens to remove.
        @return amountA Quantity of tokenA removed
        @return amountB Quantity of tokenB removed
        @return token0 Address of the underlying token to be removed
        @return token1 Address of the underlying token to be removed
    */
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract removes liquidity from Quickswap pools on Polygon (Matic), receiving ETH, ERC20 or both.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapOutBaseV3.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Quickswap_ZapOut_V2 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @notice Zap out in both tokens
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param affiliate Affiliate address
        @return amountA Quantity of tokenA received after zapout
        @return amountB Quantity of tokenB received after zapout
    */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(quickswapRouter), incomingLP);

        if (token0 == wmaticTokenAddress || token1 == wmaticTokenAddress) {
            address _token = token0 == wmaticTokenAddress ? token1 : token0;
            (amountA, amountB) = quickswapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            (amountA, amountB) = quickswapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
    @notice Zap out in both tokens with permit
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitSig Signature for permit
    @return amountA Quantity of tokenA received
    @return amountB Quantity of tokenB received
    */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a single token with permit
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param permitSig Signature for permit
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(quickswapRouter), incomingLP);

        (amount0, amount1) = quickswapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
        address token1 = IUniswapV2Pair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wmaticTokenAddress && toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
        @notice Utility function to determine quantity and addresses of tokens being removed
        @param fromPoolAddress Pool from which to remove liquidity
        @param liquidity Quantity of LP tokens to remove.
        @return amountA Quantity of tokenA removed
        @return amountB Quantity of tokenB removed
        @return token0 Address of the underlying token to be removed
        @return token1 Address of the underlying token to be removed
    */
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract removes liquidity from Pancakeswap pools on BSC, receiving ETH, tokens or both.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapOutBaseV3.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Pancakeswap_ZapOut_V3 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IUniswapV2Router02 private constant pancakeswapRouter =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Factory private constant pancakeswapFactoryAddress =
        IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    address private constant wbnbTokenAddress =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @notice Zap out in both tokens
        @param fromPoolAddress Pool from which to remove liquidity
        @param incomingLP Quantity of LP to remove from pool
        @param affiliate Affiliate address
        @return amountA Quantity of tokenA received after zapout
        @return amountB Quantity of tokenB received after zapout
    */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(pancakeswapRouter), incomingLP);

        if (token0 == wbnbTokenAddress || token1 == wbnbTokenAddress) {
            address _token = token0 == wbnbTokenAddress ? token1 : token0;
            (amountA, amountB) = pancakeswapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            (amountA, amountB) = pancakeswapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
    @notice Zap out in both tokens with permit
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitSig Signature for permit
    @return amountA Quantity of tokenA received
    @return amountB Quantity of tokenB received
    */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a single token with permit
    @param toTokenAddress Address of desired token
    @param fromPoolAddress Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param permitSig Signature for permit
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IUniswapV2Pair(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(pancakeswapRouter), incomingLP);

        (amount0, amount1) = pancakeswapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
        address token1 = IUniswapV2Pair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using 0x swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wbnbTokenAddress && toToken == address(0)) {
            IWETH(wbnbTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
        @notice Utility function to determine quantity and addresses of tokens being removed
        @param fromPoolAddress Pool from which to remove liquidity
        @param liquidity Quantity of LP tokens to remove.
        @return amountA Quantity of tokenA removed
        @return amountB Quantity of tokenB removed
        @return token0 Address of the underlying token to be removed
        @return token1 Address of the underlying token to be removed
    */
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2.sol";

abstract contract ZapInBaseV3 is ZapBaseV2 {
    using SafeERC20 for IERC20;

    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill,
        bool shouldSellEntireBalance
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                msg.value,
                affiliate,
                enableGoodwill
            );

            return msg.value - totalGoodwillPortion;
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );
            amount = IERC20(token).allowance(msg.sender, address(this));
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            affiliate,
            enableGoodwill
        );

        return amount - totalGoodwillPortion;
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Yearn Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    // V2
    function pricePerShare() external view returns (uint256);
}

// -- Aave --
interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAaveLendingPoolCore {
    function getReserveATokenAddress(address _reserve)
        external
        view
        returns (address);
}

interface IAaveLendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

contract yVault_ZapIn_V4 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // Curve ZapIn
        approvedTargets[_curveZapIn] = true;
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    /**
        @notice This function adds liquidity to a Yearn vaults with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param amountIn The amount of fromToken to invest
        @param toVault Yearn vault address
        @param superVault Super vault to depoist toVault tokens into (address(0) if none)
        @param isAaveUnderlying True if vault contains aave token
        @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
        @param intermediateToken Token to swap fromToken to before entering vault
        @param swapTarget Excecution target for the swap or Zap
        @param swapData DEX quote or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return tokensReceived Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        address superVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // get 'aIntermediateToken'
        if (isAaveUnderlying) {
            address aaveLendingPoolCore =
                lendingPoolAddressProvider.getLendingPoolCore();
            _approveToken(intermediateToken, aaveLendingPoolCore);

            IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                .deposit(intermediateToken, intermediateAmt, 0);

            intermediateToken = IAaveLendingPoolCore(aaveLendingPoolCore)
                .getReserveATokenAddress(intermediateToken);
        }

        return
            _zapIn(
                toVault,
                superVault,
                minYVTokens,
                intermediateToken,
                intermediateAmt
            );
    }

    function _zapIn(
        address toVault,
        address superVault,
        uint256 minYVTokens,
        address intermediateToken,
        uint256 intermediateAmt
    ) internal returns (uint256 tokensReceived) {
        // Deposit to Vault
        if (superVault == address(0)) {
            tokensReceived = _vaultDeposit(
                intermediateToken,
                intermediateAmt,
                toVault,
                minYVTokens,
                true
            );
        } else {
            uint256 intermediateYVTokens =
                _vaultDeposit(
                    intermediateToken,
                    intermediateAmt,
                    toVault,
                    0,
                    false
                );
            // deposit to super vault
            tokensReceived = _vaultDeposit(
                IYVault(superVault).token(),
                intermediateYVTokens,
                superVault,
                minYVTokens,
                true
            );
        }
    }

    function _vaultDeposit(
        address underlyingVaultToken,
        uint256 amount,
        address toVault,
        uint256 minTokensRec,
        bool shouldTransfer
    ) internal returns (uint256 tokensReceived) {
        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IYVault(toVault).deposit(amount);
        tokensReceived =
            IERC20(toVault).balanceOf(address(this)) -
            iniYVaultBal;
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        if (shouldTransfer) {
            IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
            emit zapIn(msg.sender, toVault, tokensReceived);
        }
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Uniswap V2 pools using ETH or any ERC20 Token.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract UniswapV2_ZapIn_General_V5 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant UniSwapV2FactoryAddress =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 private constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if ether)
    @param _pairAddress The Uniswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToUniswapToken0,
                _ToUniswapToken1,
                intermediateAmt
            );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(uniswapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(uniswapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            uniswapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return (_amount, wethTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(
                    _ToUnipoolToken0,
                    _ToUnipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(uniswapRouter),
            tokens2Trade
        );

        address pair =
            UniSwapV2FactoryAddress.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = uniswapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Sushiswap pools using ETH or any ERC20 Token.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Sushiswap_ZapIn_V4 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
    @param _pairAddress The Sushiswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToUniswapToken0,
                _ToUniswapToken1,
                intermediateAmt
            );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return (_amount, wethTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                sushiSwapFactoryAddress.getPair(
                    _ToUnipoolToken0,
                    _ToUnipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(sushiSwapRouter),
            tokens2Trade
        );

        address pair =
            sushiSwapFactoryAddress.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = sushiSwapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract enters Pool Together Prize Pools with ETH or ERC tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface IPoolTogether {
    function depositTo(
        address to,
        uint256 amount,
        address controlledToken,
        address referrer
    ) external;

    function tokens() external returns (address[] memory);

    function token() external returns (address);
}

contract PoolTogether_ZapIn_V2 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant zGoodwillAddress =
        0x3CE37278de6388532C3949ce4e886F365B14fB56;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to a PoolTogether prize pool with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param toToken The intermediate ERC20 token to swap to
        @param prizePool Prize pool to enter
        @param amountIn The quantity of fromToken to invest
        @param minTickets The minimum acceptable quantity of tickets to acquire. Reverts otherwise
        @param swapTarget Excecution target for swap
        @param swapData DEX quote data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     */
    function ZapIn(
        address fromToken,
        address toToken,
        address prizePool,
        uint256 amountIn,
        uint256 minTickets,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency {
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        IPoolTogether _prizePool = IPoolTogether(prizePool);

        if (_prizePool.token() == fromToken) {
            _enterPrizePool(_prizePool, toInvest, minTickets);
        } else {
            uint256 tokensBought =
                _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);
            _enterPrizePool(_prizePool, tokensBought, minTickets);
        }
    }

    function _enterPrizePool(
        IPoolTogether prizePool,
        uint256 amount,
        uint256 minTickets
    ) internal {
        address poolToken = prizePool.token();
        address ticket = prizePool.tokens()[1];

        _approveToken(poolToken, address(prizePool));

        uint256 iniTicketBal = _getBalance(ticket);

        prizePool.depositTo(address(this), amount, ticket, zGoodwillAddress);

        uint256 ticketsRec = _getBalance(ticket) - iniTicketBal;

        require(ticketsRec >= minTickets, "High Slippage");

        IERC20(ticket).safeTransfer(msg.sender, ticketsRec);

        emit zapIn(msg.sender, address(prizePool), amount);
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);
        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");
        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Sushiswap pools on Polygon (Matic) using ETH or any ERC20 Token.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapInBaseV3.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Sushiswap_ZapIn_Polygon_V3 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
    @param _pairAddress The Sushiswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToUniswapToken0,
                _ToUniswapToken1,
                intermediateAmt
            );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wmaticTokenAddress) {
            IWETH(wmaticTokenAddress).deposit{ value: _amount }();
            return (_amount, wmaticTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                sushiSwapFactoryAddress.getPair(
                    _ToUnipoolToken0,
                    _ToUnipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(sushiSwapRouter),
            tokens2Trade
        );

        address pair =
            sushiSwapFactoryAddress.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = sushiSwapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Quickswap pools on Polygon (Matic) using ETH or any ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapInBaseV3.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Quickswap_ZapIn_V2 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Quickswap pools with ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
    @param _pairAddress The Quickswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToUniswapToken0,
                _ToUniswapToken1,
                intermediateAmt
            );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(quickswapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(quickswapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            quickswapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wmaticTokenAddress) {
            IWETH(wmaticTokenAddress).deposit{ value: _amount }();
            return (_amount, wmaticTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                quickswapFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(quickswapRouter),
            tokens2Trade
        );

        address pair =
            quickswapFactory.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = quickswapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Mushroom Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface IMVault {
    function deposit(uint256) external;

    function token() external view returns (address);
}

contract Mushroom_ZapIn_V2 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        address _curveZapIn,
        address _uniZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        // Curve ZapIn
        approvedTargets[_curveZapIn] = true;
        // Uniswap ZapIn
        approvedTargets[_uniZapIn] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to Mushroom vaults with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param amountIn The amount of fromToken to invest
        @param toVault Harvest vault address
        @param minMVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
        @param intermediateToken Token to swap fromToken to before entering vault
        @param swapTarget Excecution target for the swap or zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
        @return tokensReceived Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        uint256 minMVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, toVault, minMVTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IMVault(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniVaultBal = IERC20(toVault).balanceOf(address(this));
        IMVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)) - iniVaultBal;
        require(tokensReceived >= minTokensRec, "High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits ETH or ERC20 tokens into Harvest Vaults
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

// -- Harvest --
interface IHVault {
    function underlying() external view returns (address);

    function deposit(uint256 amountWei) external;
}

contract Harvest_ZapIn_V3 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(
        address _curveZapIn,
        address _uniZapIn,
        address _sushiZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        approvedTargets[_curveZapIn] = true;
        approvedTargets[_uniZapIn] = true;
        approvedTargets[_sushiZapIn] = true;
    }

    /**
        @notice This function adds liquidity to harvest vaults with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param amountIn The amount of fromToken to invest
        @param vault Harvest vault address
        @param minVaultTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
        @param intermediateToken Token to swap fromToken to before entering vault
        @param swapTarget Excecution target for the swap or zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
        @return tokensReceived Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address vault,
        uint256 minVaultTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, vault, minVaultTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IHVault(toVault).underlying();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IHVault(toVault).deposit(amount);
        tokensReceived =
            IERC20(toVault).balanceOf(address(this)) -
            iniYVaultBal;
        require(tokensReceived >= minTokensRec, "High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Curve pools with ETH or ERC tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface ICurveSwap {
    function coins(int128 arg0) external view returns (address);

    function underlying_coins(int128 arg0) external view returns (address);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;
}

interface ICurveEthSwap {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable
        returns (uint256);
}

interface ICurveRegistry {
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress);

    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress);

    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress);

    function getPoolTokens(address swapAddress)
        external
        view
        returns (address[4] memory poolTokens);

    function shouldAddUnderlying(address swapAddress)
        external
        view
        returns (bool);

    function getNumTokens(address swapAddress)
        external
        view
        returns (uint8 numTokens);

    function isBtcPool(address swapAddress) external view returns (bool);

    function isEthPool(address swapAddress) external view returns (bool);

    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint8);
}

contract Curve_ZapIn_General_V4 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    ICurveRegistry public curveReg;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        ICurveRegistry _curveRegistry,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        curveReg = _curveRegistry;

        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to a Curve pool with ETH or ERC20 tokens
        @param fromTokenAddress The token used for entry (address(0) if ether)
        @param toTokenAddress The intermediate ERC20 token to swap to
        @param swapAddress Curve swap address for the pool
        @param incomingTokenQty The amount of fromTokenAddress to invest
        @param minPoolTokens The minimum acceptable quantity of Curve LP to receive. Reverts otherwise
        @param swapTarget Excecution target for the first swap
        @param swapData DEX quote data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return crvTokensBought Quantity of Curve LP tokens received
    */
    function ZapIn(
        address fromTokenAddress,
        address toTokenAddress,
        address swapAddress,
        uint256 incomingTokenQty,
        uint256 minPoolTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 crvTokensBought) {
        uint256 toInvest =
            _pullTokens(
                fromTokenAddress,
                incomingTokenQty,
                affiliate,
                true,
                shouldSellEntireBalance
            );
        if (fromTokenAddress == address(0)) {
            fromTokenAddress = ETHAddress;
        }

        // perform zapIn
        crvTokensBought = _performZapIn(
            fromTokenAddress,
            toTokenAddress,
            swapAddress,
            toInvest,
            swapTarget,
            swapData
        );

        require(
            crvTokensBought > minPoolTokens,
            "Received less than minPoolTokens"
        );

        address poolTokenAddress = curveReg.getTokenAddress(swapAddress);

        emit zapIn(msg.sender, poolTokenAddress, crvTokensBought);

        IERC20(poolTokenAddress).transfer(msg.sender, crvTokensBought);
    }

    function _performZapIn(
        address fromTokenAddress,
        address toTokenAddress,
        address swapAddress,
        uint256 toInvest,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 crvTokensBought) {
        (bool isUnderlying, uint8 underlyingIndex) =
            curveReg.isUnderlyingToken(swapAddress, fromTokenAddress);

        if (isUnderlying) {
            crvTokensBought = _enterCurve(
                swapAddress,
                toInvest,
                underlyingIndex
            );
        } else {
            //swap tokens using 0x swap
            uint256 tokensBought =
                _fillQuote(
                    fromTokenAddress,
                    toTokenAddress,
                    toInvest,
                    swapTarget,
                    swapData
                );
            if (toTokenAddress == address(0)) toTokenAddress = ETHAddress;

            //get underlying token index
            (isUnderlying, underlyingIndex) = curveReg.isUnderlyingToken(
                swapAddress,
                toTokenAddress
            );

            if (isUnderlying) {
                crvTokensBought = _enterCurve(
                    swapAddress,
                    tokensBought,
                    underlyingIndex
                );
            } else {
                (uint256 tokens, uint8 metaIndex) =
                    _enterMetaPool(swapAddress, toTokenAddress, tokensBought);

                crvTokensBought = _enterCurve(swapAddress, tokens, metaIndex);
            }
        }
    }

    /**
        @notice This function gets adds the liquidity for meta pools and returns the token index and swap tokens
        @param swapAddress Curve swap address for the pool
        @param toTokenAddress The ERC20 token to which from token to be convert
        @param swapTokens quantity of toToken to invest
        @return tokensBought quantity of curve LP acquired
        @return index index of LP token in swapAddress whose pool tokens were acquired
     */
    function _enterMetaPool(
        address swapAddress,
        address toTokenAddress,
        uint256 swapTokens
    ) internal returns (uint256 tokensBought, uint8 index) {
        address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
        for (uint8 i = 0; i < 4; i++) {
            address intermediateSwapAddress =
                curveReg.getSwapAddress(poolTokens[i]);
            if (intermediateSwapAddress != address(0)) {
                (, index) = curveReg.isUnderlyingToken(
                    intermediateSwapAddress,
                    toTokenAddress
                );

                tokensBought = _enterCurve(
                    intermediateSwapAddress,
                    swapTokens,
                    index
                );

                return (tokensBought, i);
            }
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromTokenAddress == toTokenAddress) {
            return amount;
        }

        if (swapTarget == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == ETHAddress) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toTokenAddress);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toTokenAddress) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
        @notice This function adds liquidity to a curve pool
        @param swapAddress Curve swap address for the pool
        @param amount The quantity of tokens being added as liquidity
        @param index The token index for the add_liquidity call
        @return crvTokensBought the quantity of curve LP tokens received
    */
    function _enterCurve(
        address swapAddress,
        uint256 amount,
        uint8 index
    ) internal returns (uint256 crvTokensBought) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        address depositAddress = curveReg.getDepositAddress(swapAddress);
        uint256 initialBalance = _getBalance(tokenAddress);
        address entryToken = curveReg.getPoolTokens(swapAddress)[index];
        if (entryToken != ETHAddress) {
            IERC20(entryToken).safeIncreaseAllowance(
                address(depositAddress),
                amount
            );
        }

        uint256 numTokens = curveReg.getNumTokens(swapAddress);
        bool addUnderlying = curveReg.shouldAddUnderlying(swapAddress);

        if (numTokens == 4) {
            uint256[4] memory amounts;
            amounts[index] = amount;
            if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        } else if (numTokens == 3) {
            uint256[3] memory amounts;
            amounts[index] = amount;
            if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        } else {
            uint256[2] memory amounts;
            amounts[index] = amount;
            if (curveReg.isEthPool(depositAddress)) {
                ICurveEthSwap(depositAddress).add_liquidity{ value: amount }(
                    amounts,
                    0
                );
            } else if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        }
        crvTokensBought = _getBalance(tokenAddress) - initialBalance;
    }

    function updateCurveRegistry(ICurveRegistry newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Pancakeswap (BSC) pools using ETH or any token.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../../_base/ZapInBaseV3.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Pancakeswap_ZapIn_V3_1 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant pancakeswapFactoryAddress =
        IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    IUniswapV2Router02 private constant pancakeswapRouter =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address private constant wbnbTokenAddress =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Pancakeswap pools with ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
    @param _pairAddress The Pancakeswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToUniswapToken0,
                _ToUniswapToken1,
                intermediateAmt
            );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(
            _ToUnipoolToken0,
            address(pancakeswapRouter),
            token0Bought
        );
        _approveToken(
            _ToUnipoolToken1,
            address(pancakeswapRouter),
            token1Bought
        );

        (uint256 amountA, uint256 amountB, uint256 LP) =
            pancakeswapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wbnbTokenAddress) {
            IWETH(wbnbTokenAddress).deposit{ value: _amount }();
            return (_amount, wbnbTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                pancakeswapFactoryAddress.getPair(
                    _ToUnipoolToken0,
                    _ToUnipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(pancakeswapRouter),
            tokens2Trade
        );

        address pair =
            pancakeswapFactoryAddress.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = pancakeswapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        // solhint-disable-next-line not-rely-on-time
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(
            block.timestamp >= releaseTime(),
            "TokenTimelock: current time is before release time"
        );

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

// ███████╗ █████╗ ██████╗ ██████╗ ███████╗██████╗     ██╗      █████╗ ██████╗ ███████╗
// ╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗    ██║     ██╔══██╗██╔══██╗██╔════╝
//   ███╔╝ ███████║██████╔╝██████╔╝█████╗  ██████╔╝    ██║     ███████║██████╔╝███████╗
//  ███╔╝  ██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██╗    ██║     ██╔══██║██╔══██╗╚════██║
// ███████╗██║  ██║██║     ██║     ███████╗██║  ██║    ███████╗██║  ██║██████╔╝███████║
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
// Copyright (C) 2021 Zapper Labs

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@title Infuze Vaults
///@author Zapper Labs
///@notice DCA (Dollar-Cost Averaging) Vault. Uses interest earned on a
///principal token to accumulate another desired token (the wantToken).
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;

import "../oz/0.8.0-contracts-upgradeable/proxy/utils/Initializable.sol";

import "../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";
import "../oz/0.8.0/token/ERC20/extensions/IERC20Metadata.sol";
import "./FundsDistributionToken.sol";
import "./MathLib.sol";
import "./IVaultsWrapper.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IInfuzeFactory {
    function registry() external view returns (address);

    function owner() external view returns (address);

    function collector() external view returns (address);

    function approvedTargets(address) external view returns (bool);

    function approvedKeepers(address) external view returns (address);

    function performanceFee() external view returns (uint256);

    function keeperFee() external view returns (uint256);

    function toDepositBuffer() external view returns (uint256);
}

contract Infuze_Vault_V1 is Initializable, FundsDistributionToken {
    using SafeERC20 for IERC20;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    string public constant version = "1.0";

    // For use in permit
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;
    mapping(address => uint256) public nonces;

    // Used to pause the contract
    bool public stopped;

    // Total quantity of principle token deposited in the vault
    uint256 public totalPricipalDepositedInVault;
    //Token being deposited
    address public principalToken;
    // Token to acquire with interest accrued from principalToken
    address public wantToken;
    // vault address for the principalTokenVault
    address public principalTokenVaultAddress;
    // vault wrapper for the principalTokenVault
    IVaultsWrapper public principalTokenVaultWrapper;
    // vault address for the wantTokenVault (O address if none)
    address public wantTokenVaultAddress;
    // vaults wrapper for wantTokenVault
    IVaultsWrapper public wantTokenVaultWrapper;

    // 100% in bps
    uint256 constant BPS_BASE = 10000;

    // Caps total deposits of the principal token that can be held by the vault
    uint256 public depositCap;

    // Used to restrict withdrawals to at least n+1 block after a deposit
    mapping(address => uint256) internal lastDepositAtBlock;

    // current total want shares that have been distributed, but not claimed
    uint256 internal pendingDistributedWantShares;

    // Address of the WMATIC token on polygon
    address private constant wmaticTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // zDCA Factory that deploys minimal proxies
    IInfuzeFactory public factory;

    /**
     * @dev Called by the factory `deployVault` function
     * @param _principalToken The address of the token which will accrue interest
     * @param _wantToken The address of the token to acquire with accured interest
     * from the _principalToken
     * @param _principalTokenVaultAddress The vault actual in which to deposit the _principalToken
     * @param _principalTokenVaultWrapper The vault wrapper corresponding to principalTokenVault
     * @param _wantTokenVaultAddress The actual vault in which to deposit the _wantToken
     * (0 address if no vault exists)
     * @param _wantTokenVaultWrapper The vault wrapper corresponding to wantTokenVault
     * (0 address if no vault exists)
     */
    function initialize(
        address _principalToken,
        address _wantToken,
        address _principalTokenVaultAddress,
        address _principalTokenVaultWrapper,
        address _wantTokenVaultAddress, // address(0) if doesn't exist
        address _wantTokenVaultWrapper // address(0) if doesn't exist
    ) external initializer {
        require(
            _principalToken != _wantToken,
            "IFZ: Can't initialize Same token"
        );

        string memory principalTokenSymbol =
            IERC20Metadata(_principalToken).symbol();
        string memory wantTokenSymbol = IERC20Metadata(_wantToken).symbol();

        string memory tokenName =
            string(
                abi.encodePacked(
                    "Infuze Vault ",
                    principalTokenSymbol,
                    "-",
                    wantTokenSymbol
                )
            );
        string memory tokenSymbol =
            string(
                abi.encodePacked(
                    "IFZ-",
                    principalTokenSymbol,
                    "-",
                    wantTokenSymbol
                )
            );

        FundsDistributionToken.initialize(tokenName, tokenSymbol);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(tokenName)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        principalToken = _principalToken;
        wantToken = _wantToken;
        principalTokenVaultAddress = _principalTokenVaultAddress;
        principalTokenVaultWrapper = IVaultsWrapper(
            _principalTokenVaultWrapper
        );
        wantTokenVaultAddress = _wantTokenVaultAddress;
        wantTokenVaultWrapper = IVaultsWrapper(_wantTokenVaultWrapper);
        depositCap = 0;

        factory = IInfuzeFactory(msg.sender);
    }

    modifier stopInEmergency() {
        require(!stopped, "IFZ: Paused");
        _;
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == factory.owner(), "IFZ: caller is not the owner");
        _;
    }

    // --- External Mutative Functions ---

    /**
     * @notice Used to add liquidity into the vault with any token
     * @dev vault tokens are minted 1:1 with the principal token
     * @param _fromToken The token used for entry (address(0) if ether)
     * @param _amountIn Quantity of _fromToken being added
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of principal
     * tokens to receive. Reverts otherwise
     */
    function deposit(
        address _fromToken,
        uint256 _amountIn,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external payable stopInEmergency {
        lastDepositAtBlock[msg.sender] = block.number;

        // get tokens from user
        _amountIn = _pullTokens(_fromToken, _amountIn);

        // swap them to principalTokens
        uint256 netPrincipalReceived =
            _fillQuote(
                _fromToken,
                principalToken,
                _amountIn,
                _swapTarget,
                _swapData,
                _minToTokens
            );
        require(
            netPrincipalReceived +
                totalPricipalDepositedInVault +
                _getBalance(principalToken) <=
                depositCap,
            "IFZ: Capacity reached"
        );

        // deposit amount after accounting for buffer
        uint256 principalToDeposit =
            (netPrincipalReceived * factory.toDepositBuffer()) / BPS_BASE;

        // deposit into principal strategy vault
        _deposit(principalToDeposit);
        totalPricipalDepositedInVault += principalToDeposit;

        // mint shares for user
        _mint(msg.sender, netPrincipalReceived);
    }

    /**
     * @notice Used to withdraw principal tokens from the vault,
     * optionally swapping into any token
     * @param _principalAmount The quantity of principal tokens being removed
     * @param _toToken The adress of the token to receive
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of principal
     * tokens to receive. Reverts otherwise
     */
    function withdraw(
        uint256 _principalAmount,
        address _toToken,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens
    ) public {
        require(
            block.number > lastDepositAtBlock[msg.sender],
            "IFZ: Same block withdraw"
        );

        // burn user shares
        _burn(msg.sender, _principalAmount);

        uint256 principalToSwap = _principalAmount;
        uint256 principalBalance =
            IERC20(principalToken).balanceOf(address(this));

        if (principalBalance < _principalAmount) {
            uint256 principalToWithdraw = _principalAmount - principalBalance;
            // withdraw principalTokens from strategy vault
            uint256 _ppsNum =
                principalTokenVaultWrapper.ppsNum(principalTokenVaultAddress);
            uint256 _ppsDenom =
                principalTokenVaultWrapper.ppsDenom(principalTokenVaultAddress);
            uint256 sharesToBurn =
                FullMath.mulDivRoundingUp(
                    principalToWithdraw,
                    _ppsDenom,
                    _ppsNum
                );

            (bool success, ) =
                address(principalTokenVaultWrapper).delegatecall(
                    abi.encodeWithSelector(
                        principalTokenVaultWrapper.withdraw.selector,
                        principalTokenVaultAddress,
                        sharesToBurn
                    )
                );
            require(success, "IFZ: Can't withdraw from principalTokenVault");

            // take care of any vault withdrawal fees
            principalToSwap = IERC20(principalToken).balanceOf(address(this));
            totalPricipalDepositedInVault -= principalToWithdraw;
        }

        // swap to _toToken
        uint256 toTokenAmt =
            _fillQuote(
                principalToken,
                _toToken,
                principalToSwap,
                _swapTarget,
                _swapData,
                _minToTokens
            );

        // send _toToken to user
        if (_toToken == address(0)) {
            payable(msg.sender).transfer(toTokenAmt);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, toTokenAmt);
        }
    }

    function withdrawWithPermit(
        uint256 _principalAmount,
        address _toToken,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens,
        uint256 deadline,
        bytes memory signature
    ) external stopInEmergency {
        permit(
            msg.sender,
            address(this),
            _principalAmount,
            deadline,
            signature
        );

        withdraw(
            _principalAmount,
            _toToken,
            _swapTarget,
            _swapData,
            _minToTokens
        );
    }

    /**
     * @notice Used to claim dividends (denominated in wantToken),
     * optionally swapping into any token
     * @param _toToken The adress of the token to receive
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function claim(
        address _toToken,
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) public {
        uint256 userWantShares = _prepareWithdraw();

        uint256 wantTokenToSend = userWantShares;
        // unwrap wantTokens from strategy (if exists)
        if (wantTokenVaultAddress != address(0)) {
            // avoid rounding error
            if (balanceOf(msg.sender) == totalSupply()) {
                userWantShares = pendingDistributedWantShares;
            }

            (
                uint256 wantTokenBalance,
                uint256 wantVaultTokenEquivalent,
                uint256 pricePerShare
            ) = _totalWantBalance();
            uint256 totalWantBal = wantTokenBalance + wantVaultTokenEquivalent;

            wantTokenToSend =
                (userWantShares * totalWantBal) /
                pendingDistributedWantShares;
            pendingDistributedWantShares -= userWantShares;

            // if buffer is insufficient, withdraw more from vault
            if (wantTokenBalance < wantTokenToSend) {
                uint256 wantToWithdraw = wantTokenToSend - wantTokenBalance;

                uint256 sharesToBurn = (wantToWithdraw * 1e18) / pricePerShare;

                (bool success, ) =
                    address(wantTokenVaultWrapper).delegatecall(
                        abi.encodeWithSelector(
                            wantTokenVaultWrapper.withdraw.selector,
                            wantTokenVaultAddress,
                            sharesToBurn
                        )
                    );
                require(success, "IFZ: Can't withdraw from wantTokenVault");

                // takes care of any withdrawal fee with vault
                wantTokenToSend = IERC20(wantToken).balanceOf(address(this));
            }
        }

        // swap to _toToken
        uint256 toTokenAmt =
            _fillQuote(
                wantToken,
                _toToken,
                wantTokenToSend,
                _swapTarget,
                _swapData,
                _minToTokens
            );

        // send _toToken to user
        if (_toToken == address(0)) {
            payable(msg.sender).transfer(toTokenAmt);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, toTokenAmt);
        }
    }

    /**
     * @notice Exits the vault, liquidating all of the senders
     principalTokens and wantTokens, optionally swapping them
     to a desired token
     * @dev _swapData[0] and _mintTotokens[0] must be for the
     * principalToken swap. Index 1 must be used for the 
     * wantToken swap
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function exit(
        address _toToken,
        address[] calldata _swapTarget,
        bytes[] calldata _swapData,
        uint256[] calldata _minToTokens
    ) external {
        // withdraw principal tokens
        uint256 userShares = balanceOf(msg.sender);
        withdraw(
            userShares,
            _toToken,
            _swapTarget[0],
            _swapData[0],
            _minToTokens[0]
        );

        // claim wantToken dividends
        claim(_toToken, _swapTarget[1], _swapData[1], _minToTokens[1]);
    }

    /**
     * @notice Harvests interest accrued from the principal token
     * vault and acquires more wantToken, locking it in its own vault
     * if applicable
     * @dev only approved keepers may harvest this vault
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     * @param _minToTokens The minimum acceptable quantity of _toToken
     * to receive. Reverts otherwise
     */
    function harvest(
        address _swapTarget,
        bytes calldata _swapData,
        uint256 _minToTokens
    ) external stopInEmergency {
        require(
            factory.approvedKeepers(msg.sender) != address(0),
            "IFZ: Keeper not Authorized"
        );

        // get interest accumulated
        (uint256 interest, uint256 _ppsNum, uint256 _ppsDenom) =
            _pendingInterestAccumulated();

        // withdraw interest from principal strategy vault
        uint256 sharesToBurn =
            FullMath.mulDivRoundingUp(interest, _ppsDenom, _ppsNum);
        uint256 initialPrincipalBalance =
            IERC20(principalToken).balanceOf(address(this));

        (bool withdrawSuccess, ) =
            address(principalTokenVaultWrapper).delegatecall(
                abi.encodeWithSelector(
                    principalTokenVaultWrapper.withdraw.selector,
                    principalTokenVaultAddress,
                    sharesToBurn
                )
            );
        require(
            withdrawSuccess,
            "IFZ: Can't withdraw from principalTokenVault"
        );

        uint256 principalReceived =
            IERC20(principalToken).balanceOf(address(this)) -
                initialPrincipalBalance;

        // convert principalReceived to want token
        uint256 wantReceived =
            _fillQuote(
                principalToken,
                wantToken,
                principalReceived,
                _swapTarget,
                _swapData,
                _minToTokens
            );

        uint256 keeperShare = (wantReceived * factory.keeperFee()) / BPS_BASE;
        uint256 collectorShare =
            (wantReceived * factory.performanceFee()) / BPS_BASE;

        if (keeperShare > 0) {
            IERC20(wantToken).safeTransfer(msg.sender, keeperShare);
        }
        if (collectorShare > 0) {
            IERC20(wantToken).safeTransfer(factory.collector(), collectorShare);
        }

        wantReceived -= keeperShare + collectorShare;

        // deposit into wantToken strategy vault (if exists)
        uint256 _wantSharesToDistribute = wantReceived;
        if (wantTokenVaultAddress != address(0)) {
            uint256 _preTotalWantBalance = totalWantBalance() - wantReceived;

            if (pendingDistributedWantShares != 0) {
                _wantSharesToDistribute =
                    (wantReceived * pendingDistributedWantShares) /
                    _preTotalWantBalance;
            }
            pendingDistributedWantShares += _wantSharesToDistribute;

            uint256 wantToDeposit =
                (wantReceived * factory.toDepositBuffer()) / BPS_BASE;

            _approveToken(wantToken, wantTokenVaultAddress);

            (bool depositSuccess, ) =
                address(wantTokenVaultWrapper).delegatecall(
                    abi.encodeWithSelector(
                        wantTokenVaultWrapper.deposit.selector,
                        wantTokenVaultAddress,
                        wantToDeposit
                    )
                );
            require(depositSuccess, "IFZ: Can't deposit to wantTokenVault");
        }

        // update wantToken dividends
        _distributeFunds(_wantSharesToDistribute);
    }

    /**
    @notice Approves tokens for spending by signature
    @param owner    The owner of the tokens
    @param spender  The spender of the permit
    @param amount   The quantity of tokens to permit spending of
    @param deadline The deadline after which the permit is invalid
    */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(deadline >= block.timestamp, "IFZ: Deadline expired");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            amount,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner, "IFZ: Invalid signature");
        _approve(owner, spender, amount);
    }

    /**
     * @notice Toggles the vault's active state
     */
    function toggleVaultActive() external onlyFactoryOwner {
        stopped = !stopped;
    }

    /**
     * @notice Updates the deposit capacity
     * @dev should be in the base units of the principalToken
     * (i.e 18 decimals for ETH, 6 for USDC)
     */
    function updateDepositCap(uint256 _depositCap) external onlyFactoryOwner {
        depositCap = _depositCap;
    }

    // --- Internal Mutative Functions ---

    function _deposit(uint256 amount) internal {
        _approveToken(principalToken, principalTokenVaultAddress);

        (bool success, ) =
            address(principalTokenVaultWrapper).delegatecall(
                abi.encodeWithSelector(
                    principalTokenVaultWrapper.deposit.selector,
                    principalTokenVaultAddress,
                    amount
                )
            );
        require(success, "IFZ: Can't deposit to principalTokenVault");
    }

    /**
     * @dev Internal function that transfer tokens from one address to another.
     * Update recipient block number to ensure that withdrawals cannot occur
     * in the same block as deposits, even if tokens are transferred.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        super._transfer(from, to, value);

        if (lastDepositAtBlock[from] == block.number) {
            lastDepositAtBlock[to] = block.number;
        }
    }

    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return msg.value;
        }

        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        // transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    /**
     * @dev Internal function to execute a swap or Zap
     * @param _fromToken The address of the sell token
     * @param _toToken The address tof the buy token
     * @param _amount The quantity of _fromToken to sell
     * @param _swapTarget Excecution target for the swap or Zap
     * @param _swapData DEX or Zap data
     */
    function _fillQuote(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapData,
        uint256 _minToTokens
    ) internal returns (uint256 amtBought) {
        if (_fromToken == _toToken) {
            return _amount;
        }

        if (_fromToken == address(0) && _toToken == wmaticTokenAddress) {
            IWETH(wmaticTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (_fromToken == wmaticTokenAddress && _toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (_fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromToken, _swapTarget);
        }

        uint256 iniBal = _getBalance(_toToken);
        require(
            factory.approvedTargets(_swapTarget),
            "IFZ: Target not Authorized"
        );
        (bool success, ) = _swapTarget.call{ value: valueToSend }(_swapData);
        require(success, "IFZ: Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toToken);

        amtBought = finalBal - iniBal;
        require(amtBought >= _minToTokens, "IFZ: High Slippage");
    }

    /**
     * @dev Internal function for token approvals
     * @param token The address of the token being approved
     * @param spender The address of the spender of the token
     */
    function _approveToken(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) return;
        else {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    // --- External View Functions ---

    /**
     * @notice View the current total quantity of principal tokens
     * earned as interest by this vault
     * @return interest accrued
     */
    function pendingInterestAccumulated()
        public
        view
        returns (uint256 interest)
    {
        (interest, , ) = _pendingInterestAccumulated();
    }

    /**
     * @notice View dividends earned by an account
     * @param _owner The address of the token holder
     * @return Quantity of wantTokens that can be withdrawn by _owner
     */
    function claimableWantOf(address _owner) external view returns (uint256) {
        uint256 pricePerShare = 1e18;
        if (wantTokenVaultAddress != address(0)) {
            pricePerShare = wantTokenVaultWrapper.pricePerShare(
                wantTokenVaultAddress
            );
        }
        return (withdrawableFundsOf(_owner) * pricePerShare) / 1e18;
    }

    /**
     * @notice View the total wantTokens owned by vault
     * @dev totalWantBalance = (wantToken balance) + (wantTokenVault balance) * pricePerShare
     */
    function totalWantBalance() public view returns (uint256) {
        (uint256 wantTokenBalance, uint256 wantVaultTokenEquivalent, ) =
            _totalWantBalance();
        return wantTokenBalance + wantVaultTokenEquivalent;
    }

    // --- Internal View Functions ---

    /**
     * @dev View the interest of principalToken that has accumulated
     * @return interest of principalToken that has accumulated
     * pricePerShare of vault token
     */
    function _pendingInterestAccumulated()
        internal
        view
        returns (
            uint256 interest,
            uint256 _ppsNum,
            uint256 _ppsDenom
        )
    {
        _ppsNum = principalTokenVaultWrapper.ppsNum(principalTokenVaultAddress);
        _ppsDenom = principalTokenVaultWrapper.ppsDenom(
            principalTokenVaultAddress
        );

        uint256 principalTokenVaultShares =
            principalTokenVaultWrapper.balanceOf(
                principalTokenVaultAddress,
                address(this)
            );

        // principal tokens received if all vault shares burned
        // accounting similar to vault shares
        uint256 netPrincipalOnWithdraw;
        if (_ppsDenom == 0) {
            netPrincipalOnWithdraw = 0;
        } else {
            netPrincipalOnWithdraw = FullMath.mulDivRoundingUp(
                principalTokenVaultShares,
                _ppsNum,
                _ppsDenom
            );
        }

        interest = netPrincipalOnWithdraw - totalPricipalDepositedInVault;
    }

    /**
    @dev Returns the total want token quantity for this contract,
    * taking into account both want and underlying wantVault tokens
    */
    function _totalWantBalance()
        internal
        view
        returns (
            uint256 wantTokenBalance,
            uint256 wantVaultTokenEquivalent,
            uint256 wantPricePerShare
        )
    {
        wantTokenBalance = IERC20(wantToken).balanceOf(address(this));

        if (wantTokenVaultAddress != address(0)) {
            uint256 wantVaultBalance =
                wantTokenVaultWrapper.balanceOf(
                    wantTokenVaultAddress,
                    address(this)
                );
            wantPricePerShare = wantTokenVaultWrapper.pricePerShare(
                wantTokenVaultAddress
            );
            wantVaultTokenEquivalent =
                (wantVaultBalance * wantPricePerShare) /
                1e18;
        }
    }

    /**
     * @notice Balance utility function
     * @param token The address of the token used in the balance call
     * (0 address if ETH)
     * @return balance Quantity of token that is held by this contract
     */
    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    // --- Receive ---

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../oz/0.8.0-contracts-upgradeable/proxy/utils/Initializable.sol";
import "../oz/0.8.0-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../contracts/oz/0.8.0/math/SafeMath.sol";
import "../../contracts/oz/0.8.0/token/ERC20/utils/SafeERC20.sol";
import "./MathLib.sol";
import "./IFundsDistributionToken.sol";

/**
 * @title FundsDistributionToken
 * @author Johannes Escherich
 * @author Roger-Wu
 * @author Johannes Pfeffer
 * @author Tom Lam
 * @dev A  mintable token that can represent claims on cash flow of arbitrary assets such as dividends, loan repayments,
 * fee or revenue shares among large numbers of token holders. Anyone can deposit funds, token holders can withdraw
 * their claims.
 * FundsDistributionToken (FDT) implements the accounting logic. FDT-Extension contracts implement methods for
 * depositing and withdrawing funds in Ether or according to a token standard such as ERC20, ERC223, ERC777.
 */
contract FundsDistributionToken is
    Initializable,
    ERC20Upgradeable,
    IFundsDistributionToken
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant pointsMultiplier = 2**128;
    uint256 internal pointsPerShare;

    mapping(address => int256) internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;

    function initialize(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __ERC20_init(name_, symbol_);
    }

    /**
     * prev. distributeDividends
     * @notice Distributes funds to token holders.
     * @dev It reverts if the total supply of tokens is 0.
     * It emits the `FundsDistributed` event if the amount of received ether is greater than 0.
     * About undistributed funds:
     *   In each distribution, there is a small amount of funds which does not get distributed,
     *     which is `(msg.value * pointsMultiplier) % totalSupply()`.
     *   With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
     *     in a distribution can be less than 1 (base unit).
     *   We can actually keep track of the undistributed ether in a distribution
     *     and try to distribute it in the next distribution ....... todo implement
     */
    function _distributeFunds(uint256 value) internal virtual {
        require(
            totalSupply() > 0,
            "FundsDistributionToken._distributeFunds: SUPPLY_IS_ZERO"
        );

        if (value > 0) {
            pointsPerShare = pointsPerShare.add(
                value.mul(pointsMultiplier) / totalSupply()
            );
            emit FundsDistributed(msg.sender, value);
        }
    }

    /**
     * prev. withdrawDividend
     * @notice Prepares funds withdrawal
     * @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.
     */
    function _prepareWithdraw() internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);

        withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender].add(
            _withdrawableDividend
        );

        emit FundsWithdrawn(msg.sender, _withdrawableDividend);

        return _withdrawableDividend;
    }

    /**
     * prev. withdrawableDividendOf
     * @notice View the amount of funds that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount funds that `_owner` can withdraw.
     */
    function withdrawableFundsOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);
    }

    /**
     * prev. withdrawnDividendOf
     * @notice View the amount of funds that an address has withdrawn.
     * @param _owner The address of a token holder.
     * @return The amount of funds that `_owner` has withdrawn.
     */
    function withdrawnFundsOf(address _owner) public view returns (uint256) {
        return withdrawnFunds[_owner];
    }

    /**
     * prev. accumulativeDividendOf
     * @notice View the amount of funds that an address has earned in total.
     * @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
     * = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
     * @param _owner The address of a token holder.
     * @return The amount of funds that `_owner` has earned in total.
     */
    function accumulativeFundsOf(address _owner) public view returns (uint256) {
        return
            pointsPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
     * @dev Internal function that transfer tokens from one address to another.
     * Update pointsCorrection to keep funds unchanged.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        int256 _magCorrection = pointsPerShare.mul(value).toInt256Safe();
        pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
        pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);
    }

    /**
     * @dev Internal function that mints tokens to an account.
     * Update pointsCorrection to keep funds unchanged.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        pointsCorrection[account] = pointsCorrection[account].sub(
            (pointsPerShare.mul(value)).toInt256Safe()
        );
    }

    /**
     * @dev Internal function that burns an amount of the token of a given account.
     * Update pointsCorrection to keep funds unchanged.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        pointsCorrection[account] = pointsCorrection[account].add(
            (pointsPerShare.mul(value)).toInt256Safe()
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow
/// of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and
/// division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision.
    /// Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result
    ///  overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;

interface IVaultsWrapper {
    function deposit(address _vault, uint256) external payable;

    function withdraw(address _vault, uint256) external;

    function balanceOf(address _vault, address) external view returns (uint256);

    function pricePerShare(address _vault) external view returns (uint256);

    // pricePerShare Numerator
    function ppsNum(address _vault) external view returns (uint256);

    // pricePerShare Numerator
    function ppsDenom(address _vault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundsDistributionToken {
    /**
     * @dev Returns the total amount of funds a given address is able to withdraw currently.
     * @param owner Address of FundsDistributionToken holder
     * @return A uint256 representing the available funds for a given account
     */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
     * @dev This event emits when new funds are distributed
     * @param by the address of the sender who distributed funds
     * @param fundsDistributed the amount of funds received for distribution
     */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
     * @dev This event emits when distributed funds are withdrawn by a token holder.
     * @param by the address of the receiver of funds
     * @param fundsWithdrawn the amount of funds that were withdrawn
     */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice Wrapper for Vaults to standardize interfaces
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../IVaultsWrapper.sol";

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function token() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract YearnVaultsWrapper is IVaultsWrapper {
    function deposit(address _vault, uint256 _amount)
        external
        payable
        override
    {
        IYVault(_vault).deposit(_amount);
    }

    function withdraw(address _vault, uint256 _amount) external override {
        IYVault(_vault).withdraw(_amount);
    }

    // --- View Functions ---
    function balanceOf(address _vault, address _user)
        external
        view
        override
        returns (uint256)
    {
        return IYVault(_vault).balanceOf(_user);
    }

    function pricePerShare(address _vault)
        external
        view
        override
        returns (uint256)
    {
        return IYVault(_vault).pricePerShare();
    }

    function ppsNum(address _vault) external view override returns (uint256) {
        return IYVault(_vault).totalAssets();
    }

    function ppsDenom(address _vault) external view override returns (uint256) {
        return IYVault(_vault).totalSupply();
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice Wrapper for Vaults to standardize interfaces
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../IVaultsWrapper.sol";

interface IwsOHM {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function wOHMTosOHM(uint256 _amount) external view returns (uint256);

    function sOHM() external view returns (address);
}

interface IsOHM {
    function gonsForBalance(uint256 amount) external view returns (uint256);

    function INDEX() external view returns (uint256);
}

contract wsOHMWrapper is IVaultsWrapper {
    function deposit(address _vault, uint256 _amount)
        external
        payable
        override
    {
        IwsOHM(_vault).wrap(_amount);
    }

    function withdraw(address _vault, uint256 _amount) external override {
        IwsOHM(_vault).unwrap(_amount);
    }

    // --- View Functions ---
    function balanceOf(address _vault, address _user)
        external
        view
        override
        returns (uint256)
    {
        return IwsOHM(_vault).balanceOf(_user);
    }

    function pricePerShare(address _vault)
        external
        view
        override
        returns (uint256)
    {
        return IwsOHM(_vault).wOHMTosOHM(1e18);
    }

    // ----------------------------------------------------------
    // totalAssets/totalSupply = sOHM.index() / 1e18
    // = balanceForGons(INDEX) / 1e18
    // = (INDEX / _gonsPerFragment) / 1e18
    //
    // gonsForBalance(uint256 amount) = amount.mul( _gonsPerFragment )
    // so _gonsPerFragment = gonsForBalance(1)

    function ppsNum(address _vault) external view override returns (uint256) {
        address _sOHM = IwsOHM(_vault).sOHM();

        uint256 _INDEX = IsOHM(_sOHM).INDEX();
        uint256 _gonsPerFragment = IsOHM(_sOHM).gonsForBalance(1);

        return _INDEX / _gonsPerFragment;
    }

    function ppsDenom(address _vault) external view override returns (uint256) {
        return 1e18;
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice Wrapper for Vaults to standardize interfaces
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../IVaultsWrapper.sol";

interface IsSPELL {
    function mint(uint256 amount) external returns (bool);

    function burn(address to, uint256 shares) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract sSPELLWrapper is IVaultsWrapper {
    function deposit(address _vault, uint256 _amount)
        external
        payable
        override
    {
        IsSPELL(_vault).mint(_amount);
    }

    function withdraw(address _vault, uint256 _amount) external override {
        IsSPELL(_vault).burn(address(this), _amount);
    }

    // --- View Functions ---
    function balanceOf(address _vault, address _user)
        external
        view
        override
        returns (uint256)
    {
        return IsSPELL(_vault).balanceOf(_user);
    }

    function pricePerShare(address _vault)
        external
        view
        override
        returns (uint256)
    {
        uint256 _totalSupply = IsSPELL(_vault).totalSupply();
        if (_totalSupply == 0) {
            return 1e18;
        }

        uint256 _totalAssets =
            IERC20(IsSPELL(_vault).token()).balanceOf(_vault);

        return (_totalAssets * 1e18) / _totalSupply;
    }

    function ppsNum(address _vault) external view override returns (uint256) {
        return IERC20(IsSPELL(_vault).token()).balanceOf(_vault);
    }

    function ppsDenom(address _vault) external view override returns (uint256) {
        return IsSPELL(_vault).totalSupply();
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice Wrapper for Vaults to standardize interfaces
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../IVaultsWrapper.sol";

interface IBeefyVault {
    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 _shares) external;
}

contract BeefyVaultsWrapper is IVaultsWrapper {
    function deposit(address _vault, uint256 _amount)
        external
        payable
        override
    {
        IBeefyVault(_vault).deposit(_amount);
    }

    function withdraw(address _vault, uint256 _amount) external override {
        IBeefyVault(_vault).withdraw(_amount);
    }

    // --- View Functions ---
    function balanceOf(address _vault, address _user)
        external
        view
        override
        returns (uint256)
    {
        return IBeefyVault(_vault).balanceOf(_user);
    }

    function pricePerShare(address _vault)
        external
        view
        override
        returns (uint256)
    {
        return IBeefyVault(_vault).getPricePerFullShare();
    }

    function ppsNum(address _vault) external view override returns (uint256) {
        return IBeefyVault(_vault).balance();
    }

    function ppsDenom(address _vault) external view override returns (uint256) {
        return IBeefyVault(_vault).totalSupply();
    }
}