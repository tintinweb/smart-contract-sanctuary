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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title HidingVault's state management library
 * @author KeeperDAO
 * @dev Library that manages the state of the HidingVault
 */
library LibHidingVault {
    //  HIDING_VAULT_STORAGE_POSITION = keccak256("hiding-vault.keeperdao.storage")
    bytes32 constant HIDING_VAULT_STORAGE_POSITION = 0x9b85f6ce841a6faee042a2e67df9613579f746ca80e5eb1163b287041381d23c;
    
    struct State {
        NFTLike nft;
        mapping(address => bool) recoverableTokensBlacklist;
    }

    function state() internal pure returns (State storage s) {
        bytes32 position = HIDING_VAULT_STORAGE_POSITION;
        assembly {
            s.slot := position
        } 
    }
}

interface NFTLike {
    function ownerOf(uint256 _tokenID) view external returns (address);
    function implementations(bytes4 _sig) view external returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
//
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// This contract is copied from https://github.com/compound-finance/compound-protocol

pragma solidity 0.8.6;


contract CTokenStorage {
    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    address public comptroller;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;
}

abstract contract CToken is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint);
    function balanceOf(address owner) external virtual view returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external virtual view returns (uint);
    function supplyRatePerBlock() external virtual view returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) external virtual view returns (uint);
    function exchangeRateCurrent() external virtual returns (uint);
    function exchangeRateStored() external virtual view returns (uint);
    function getCash() external virtual view returns (uint);
    function accrueInterest() external virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);
}

abstract contract CErc20 is CToken {
    function underlying() external virtual view returns (address);
    function mint(uint mintAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
}

abstract contract CEther is CToken {
    function mint() external virtual payable;
    function repayBorrow() external virtual payable;
    function repayBorrowBehalf(address borrower) external virtual payable;
    function liquidateBorrow(address borrower, CToken cTokenCollateral) external virtual payable;
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
}

abstract contract PriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external virtual view returns (uint);
}

abstract contract Comptroller {
    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /// @notice A list of all markets
    CToken[] public allMarkets;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    struct Market {
        // Whether or not this market is listed
        bool isListed;

        
        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint collateralFactorMantissa;

        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        // Whether or not this market receives COMP
        bool isComped;
    }

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint[] memory);
    function exitMarket(address cToken) external virtual returns (uint);
    function checkMembership(address account, CToken cToken) external virtual view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external virtual view returns (uint, uint);

    function getAssetsIn(address account) external virtual view returns (address[] memory);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) external virtual view returns (uint, uint, uint);

    function _setPriceOracle(PriceOracle newOracle) external virtual returns (uint);
}

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) prices;
    uint256 ethPrice;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
        if (compareStrings(cToken.symbol(), "cETH")) {
            return ethPrice;
        } else {
            return prices[address(CErc20(address(cToken)).underlying())];
        }
    }

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public {
         if (compareStrings(cToken.symbol(), "cETH")) {
            ethPrice = underlyingPriceMantissa;
        } else {
            address asset = address(CErc20(address(cToken)).underlying());
            emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
            prices[asset] = underlyingPriceMantissa;
        }   
    }

    function setDirectPrice(address asset, uint price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./Compound.sol";

/**
 * @title KCompound Interface
 * @author KeeperDAO
 * @notice Interface for the KCompound hiding vault plugin.
 */
interface IKCompound {
    /**
     * @notice Calculate the given cToken's balance of this contract.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOf(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the given cToken's underlying token's balance 
     * of this contract.
     * 
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOfUnderlying(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the unhealth of this account.
     * @dev    unhealth of an account starts from 0, if a position 
     *         has an unhealth of more than 100 then the position
     *         is liquidatable.
     *
     * @return Unhealth of this account.
     */
    function compound_unhealth() external view returns (uint256);

    /**
     * @notice Checks whether given position is underwritten.
     */
    function compound_isUnderwritten() external view returns (bool);

    /** Following functions can only be called by the owner */

    /** 
     * @notice Deposit funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_deposit(CToken _cToken, uint256 _amount) external payable;

    /**
     * @notice Repay funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_repay(CToken _cToken, uint256 _amount) external payable;

    /** 
     * @notice Withdraw funds from the Compound Protocol.
     *
     * @param _to The address of the receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The amount to be withdrawn.
     */
    function compound_withdraw(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice Borrow funds from the Compound Protocol.
     *
     * @param _to The address of the amount receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_borrow(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice The user can enter new markets by passing them here.
     */
    function compound_enterMarkets(address[] memory _cTokens) external;

    /** Following functions can only be called by JITU */

    /**
     * @notice Allows a user to migrate an existing compound position.
     * @dev The user has to approve all the cTokens (he owns) to this 
     * contract before calling this function, otherwise this contract will
     * be reverted.
     * @param  _amount The amount that needs to be flash lent (should be 
     *                 greater than the value of the compund position).
     */
    function compound_migrate(
        address account, 
        uint256 _amount, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external;

    /**
     * @notice Prempt liquidation for positions underwater if the provided 
     *         buffer is not considered on the Compound Protocol.
     *
     * @param _cTokenRepay The cToken for which the loan is being repaid for.
     * @param _repayAmount The amount that should be repaid.
     * @param _cTokenCollateral The collateral cToken address.
     */
    function compound_preempt(
        address _liquidator, 
        CToken _cTokenRepay, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable returns (uint256);

    /**
     * @notice Allows JITU to underwrite this contract, by providing cTokens.
     *
     * @param _cToken The address of the cToken.
     * @param _tokens The amount of the cToken tokens.
     */
    function compound_underwrite(CToken _cToken, uint256 _tokens) external payable;

    /**
     * @notice Allows JITU to reclaim the cTokens it provided.
     */
    function compound_reclaim() external; 
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./IKCompound.sol";
import "./LibCompound.sol";

/**
 * @title Compound plugin for the HidingVault
 * @author KeeperDAO
 * @dev This is the contract logic for the HidingVault compound plugin.
 *  
 * This contract holds the compound position account details for the users, and allows 
 * users to manage their compound positions by depositing, withdrawing funds, repaying  
 * existing loans and borrowing.
 * 
 * This contract allows JITU to underwrite loans that are close to getting liquidated so that 
 * only friendly keepers can liquidate the position, resulting in lower liquidation fees to 
 * the user. Once a position is either liquidated or comes back to a safe LTV (Loan-To-Value)
 * ratio JITU should claim back the assets provided to underwrite the loan.
 * 
 * To migrate an existing compound position we flash lend cTokens greater than the total 
 * existing compound position value, borrow all the assets that are currently borrowed by the        
 * user and repay the user's loans. Once all the loans are repaid transfer over the assets from the 
 * user, then repay the ETH flash loan borrowed in the beginning. `migrate()` function is used by 
 * the user to migrate a compound  position over. The user has to approve all the cTokens he owns 
 * to this contract before calling the `migrate()` function.        
 */
contract KCompound is IKCompound {
    using LibCToken for CToken;

    address constant JITU = 0x8AeA7B58409B4124cBc92dA298C9b2AAFA605B4c;

    /**
     * @dev revert if the caller is not JITU
     */
    modifier onlyJITU() {
        require(msg.sender == JITU, "KCompoundPosition: caller is not the MEV protector");
        _;
    }

    /**
     * @dev revert if the caller is not the owner
     */
    modifier onlyOwner() {
        require(msg.sender == LibCompound.owner(), "KCompoundPosition: caller is not the owner");
        _;
    }
    
    /**
     * @dev revert if the position is underwritten
     */
    modifier whenNotUnderwritten() {
        require(!compound_isUnderwritten(), "LibCompound: operation not allowed when underwritten");
        _;
    }

    /**
     * @dev revert if the position is not underwritten
     */
    modifier whenUnderwritten() {
        require(compound_isUnderwritten(), "LibCompound: operation not allowed when underwritten");
        _;
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_deposit(CToken _cToken, uint256 _amount) external payable override {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.pullAndApproveUnderlying(msg.sender, address(_cToken), _amount);
        _cToken.mint(_amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_withdraw(address payable _to, CToken _cToken, uint256 _amount) external override onlyOwner whenNotUnderwritten {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.redeemUnderlying(_amount);
        _cToken.transferUnderlying(_to, _amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_borrow(address payable _to, CToken _cToken, uint256 _amount) external override onlyOwner whenNotUnderwritten {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.borrow(_amount);
        _cToken.transferUnderlying(_to, _amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_repay(CToken _cToken, uint256 _amount) external payable override {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.pullAndApproveUnderlying(msg.sender, address(_cToken), _amount);
        _cToken.repayBorrow(_amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_preempt(
        address _liquidator,
        CToken _cTokenRepay,
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable override onlyJITU returns (uint256) {
        return LibCompound.preempt(_cTokenRepay, _liquidator, _repayAmount, _cTokenCollateral);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_migrate(
        address _account, 
        uint256 _amount, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external override onlyJITU {
        LibCompound.migrate(
            _account,
            _amount,
            _collateralMarkets,
            _debtMarkets
        );
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_underwrite(CToken _cToken, uint256 _tokens) external payable override onlyJITU whenNotUnderwritten {    
        LibCompound.underwrite(_cToken, _tokens);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_reclaim() external override onlyJITU whenUnderwritten {
        LibCompound.reclaim();
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_enterMarkets(address[] memory _markets) external override onlyOwner {
        LibCompound.enterMarkets(_markets);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_balanceOfUnderlying(CToken _cToken) external override returns (uint256) {
        return LibCompound.balanceOfUnderlying(_cToken);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_balanceOf(CToken _cToken) external view override returns (uint256) {
        return LibCompound.balanceOf(_cToken);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_unhealth() external override view returns (uint256) {
        return LibCompound.unhealth();
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_isUnderwritten() public override view returns (bool) {
        return LibCompound.isUnderwritten();
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Compound.sol";

/**
 * @title Library to simplify CToken interaction
 * @author KeeperDAO
 * @dev this library abstracts cERC20 and cEther interactions.
 */
library LibCToken {
    using SafeERC20 for IERC20;

    // Network: MAINNET
    Comptroller constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    CEther constant CETHER = CEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /**
     * @notice checks if the given cToken is listed as a valid market on 
     * comptroller.
     * 
     * @param _cToken cToken address
     */
    function isListed(CToken _cToken) internal view returns (bool listed) {
        (listed, , ) = COMPTROLLER.markets(address(_cToken));
    }

    /**
     * @notice returns the given cToken's underlying token address.
     * 
     * @param _cToken cToken address
     */
    function underlying(CToken _cToken) internal view returns (address) {
        if (address(_cToken) == address(CETHER)) {
            return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            return CErc20(address(_cToken)).underlying();
        }
    }

    /**
     * @notice redeems given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function redeemUnderlying(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.redeemUnderlying(_amount) == 0, "failed to redeem ether");
        } else {
            require(CErc20(address(_cToken)).redeemUnderlying(_amount) == 0, "failed to redeem ERC20");
        }
    }

    /**
     * @notice borrows given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function borrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.borrow(_amount) == 0, "failed to borrow ether");
        } else {
            require(CErc20(address(_cToken)).borrow(_amount) == 0, "failed to borrow ERC20");
        }
    }

    /**
     * @notice deposits given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function mint(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.mint{ value: _amount }();
        } else {

            require(CErc20(address(_cToken)).mint(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function repayBorrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrow{ value: _amount }();
        } else {
            require(CErc20(address(_cToken)).repayBorrow(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens on behalf of the borrower.
     * 
     * @param _cToken cToken address
     * @param _borrower borrower address
     * @param _amount underlying token amount
     */
    function repayBorrowBehalf(CToken _cToken, address _borrower, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrowBehalf{ value: _amount }(_borrower);
        } else {
            require(CErc20(address(_cToken)).repayBorrowBehalf(_borrower, _amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice transfer given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _to reciever address
     * @param _amount underlying token amount
     */
    function transferUnderlying(CToken _cToken, address payable _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            (bool success,) = _to.call{ value: _amount }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(CErc20(address(_cToken)).underlying()).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _spender spender address
     * @param _amount underlying token amount
     */
    function approveUnderlying(CToken _cToken, address _spender, uint256 _amount) internal {
        if (address(_cToken) != address(CETHER)) {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeIncreaseAllowance(_spender, _amount);
        } 
    }

    /**
     * @notice pull approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _from address from which the funds need to be pulled
     * @param _to address to which the funds are approved to
     * @param _amount underlying token amount
     */
    function pullAndApproveUnderlying(CToken _cToken, address _from, address _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(msg.value == _amount, "failed to mint CETHER");
        } else {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeTransferFrom(_from, address(this), _amount);
            token.safeIncreaseAllowance(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./LibCToken.sol";
import "../../LibHidingVault.sol";

/**
 * @title Buffer accounting library for KCompound
 * @author KeeperDAO
 * @dev This library handles existing compound position migration.
 * @dev This library implements all the logic for the individual kCompound
 *      position contracts.
 */
library LibCompound {
    using LibCToken for CToken;

    //  KCOMPOUND_STORAGE_POSITION = keccak256("keeperdao.hiding-vault.compound.storage")
    bytes32 constant KCOMPOUND_STORAGE_POSITION = 0x4f39ec42b5bbf77786567b02cbf043f85f0f917cbaa97d8df56931d77a999205;

    /**
     * State for LibCompound 
     */
    struct State {
        uint256 bufferAmount;
        CToken bufferToken;
    }

    /**
     * @notice Load the LibCompound State for the given user
     */
    function state() internal pure returns (State storage s) {
        bytes32 position = KCOMPOUND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /**
     * @dev this function will be called by the KeeperDAO's LiquidityPool.
     * @param _account The address of the compund position owner.
     * @param _tokens The amount that is being flash lent.
     */
    function migrate(
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) internal {
        // Enter markets
        enterMarkets(_collateralMarkets);

        // Migrate all the cToken Loans.
        if (_debtMarkets.length != 0) migrateLoans(_debtMarkets, _account);

        // Migrate all the assets from compound.
        if (_collateralMarkets.length != 0) migrateFunds(_collateralMarkets, _account);
        
        // repay CETHER
        require(
            CToken(_collateralMarkets[0]).transfer(msg.sender, _tokens), 
            "LibCompound: failed to return funds during migration"
        );
    }

    /**
     * @notice this function borrows required amount of ETH/ERC20 tokens,  
     * repays the ETH/ERC20 loan (if it exists) on behalf of the  
     * compound position owner.
     */
    function migrateLoans(address[] memory _cTokens, address _account) private {
        for (uint32 i = 0; i < _cTokens.length; i++) {
            CToken cToken = CToken(_cTokens[i]);
            uint256 borrowBalance = cToken.borrowBalanceCurrent(_account);
            cToken.borrow(borrowBalance);
            cToken.approveUnderlying(address(cToken), borrowBalance);
            cToken.repayBorrowBehalf(_account, borrowBalance);
        }
    }

    /**
     * @notice transfer all the assets from the account.
     */
    function migrateFunds(address[] memory _cTokens, address _account) private {
        for (uint32 i = 0; i < _cTokens.length; i++) {
            CToken cToken = CToken(_cTokens[i]);
            require(cToken.transferFrom(
                _account, 
                address(this), 
                cToken.balanceOf(_account)
            ), "LibCompound: failed to transfer CETHER");       
        }
    }

    /**
     * @notice Prempt liquidation for positions underwater if the provided 
     *         buffer is not considered on the Compound Protocol.
     *
     * @param _liquidator The address of the liquidator.
     * @param _cTokenRepaid The repay cToken address.
     * @param _repayAmount The amount that should be repaid.
     * @param _cTokenCollateral The collateral cToken address.
     */    
    function preempt(
        CToken _cTokenRepaid,
        address _liquidator,
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) internal returns (uint256) {
        // Check whether the user's position is liquidatable, and if it is
        // return the amount of tokens that can be seized for the given loan,
        // token pair.
        uint seizeTokens = seizeTokenAmount(
            address(_cTokenRepaid), 
            address(_cTokenCollateral), 
            _repayAmount
        );

        // This is a preemptive liquidation, so it would just repay the given loan
        // and seize the corresponding amount of tokens.
        _cTokenRepaid.pullAndApproveUnderlying(_liquidator, address(_cTokenRepaid), _repayAmount);
        _cTokenRepaid.repayBorrow(_repayAmount);
        require(_cTokenCollateral.transfer(_liquidator, seizeTokens), "LibCompound: failed to transfer cTokens");
        return seizeTokens;
    }

    /**
     * @notice Allows JITU to underwrite this contract, by providing cTokens.
     *
     * @param _cToken The address of the token.
     * @param _tokens The tokens being transferred.
     */
    function underwrite(CToken _cToken, uint256 _tokens) internal { 
        require(_tokens * 3 <= _cToken.balanceOf(address(this)), 
            "LibCompound: underwrite pre-conditions not met");
        State storage s = state();
        s.bufferToken = _cToken;
        s.bufferAmount = _tokens;
        blacklistCTokens();
    }

    /**
     * @notice Allows JITU to reclaim the cTokens it provided.
     */
    function reclaim() internal {
        State storage s = state();
        require(s.bufferToken.transfer(msg.sender, s.bufferAmount), "LibCompound: failed to return cTokens");
        s.bufferToken = CToken(address(0));
        s.bufferAmount = 0;
        whitelistCTokens();
    }

    /**
     * @notice Blacklist all the collateral assets.
     */
    function blacklistCTokens() internal {
        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        for (uint32 i = 0; i < cTokens.length; i++) {
            LibHidingVault.state().recoverableTokensBlacklist[cTokens[i]] = true;
        }
    }

    /**
     * @notice Whitelist all the collateral assets.
     */
    function whitelistCTokens() internal {
        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        for (uint32 i = 0; i < cTokens.length; i++) {
            LibHidingVault.state().recoverableTokensBlacklist[cTokens[i]] = false;
        }
    }

    /**
     * @notice check whether the position is liquidatable, 
     *         if it is calculate the amount of tokens 
     *         that can be seized.
     *
     * @param cTokenRepaid the token that is being repaid.
     * @param cTokenSeized the token that is being seized.
     * @param repayAmount the amount being repaid.
     *
     * @return the amount of tokens that need to be seized.
     */
    function seizeTokenAmount(
        address cTokenRepaid,
        address cTokenSeized,
        uint repayAmount
    ) internal returns (uint) {
        State storage s = state();

        // accrue interest
        require(CToken(cTokenRepaid).accrueInterest() == 0, "LibCompound: failed to accrue interest on cTokenRepaid");
        require(CToken(cTokenSeized).accrueInterest() == 0, "LibCompound: failed to accrue interest on cTokenSeized");

        // The borrower must have shortfall in order to be liquidatable
        (uint err, , uint shortfall) = LibCToken.COMPTROLLER.getHypotheticalAccountLiquidity(address(this), address(s.bufferToken), s.bufferAmount, 0);
        require(err == 0, "LibCompound: failed to get account liquidity");
        require(shortfall != 0, "LibCompound: insufficient shortfall to liquidate");

        // The liquidator may not repay more than what is allowed by the closeFactor 
        uint borrowBalance = CToken(cTokenRepaid).borrowBalanceStored(address(this));
        uint maxClose = mulScalarTruncate(LibCToken.COMPTROLLER.closeFactorMantissa(), borrowBalance);
        require(repayAmount <= maxClose, "LibCompound: repay amount cannot exceed the max close amount");

        // Calculate the amount of tokens that can be seized
        (uint errCode2, uint seizeTokens) = LibCToken.COMPTROLLER
            .liquidateCalculateSeizeTokens(cTokenRepaid, cTokenSeized, repayAmount);
        require(errCode2 == 0, "LibCompound: failed to calculate seize token amount");

        // Check that the amount of tokens being seized is less than the user's 
        // cToken balance
        uint256 seizeTokenCollateral = CToken(cTokenSeized).balanceOf(address(this));
        if (cTokenSeized == address(s.bufferToken)) {
            seizeTokenCollateral = seizeTokenCollateral - s.bufferAmount;
        }
        require(seizeTokenCollateral >= seizeTokens, "LibCompound: insufficient liquidity");

        return seizeTokens;
    }

    /**
     * @notice calculates the collateral value of the given cToken amount. 
     * @dev collateral value means the amount of loan that can be taken without 
     *      falling below the collateral requirement.
     *
     * @param _cToken the compound token we are calculating the collateral for.
     * @param _tokens number of compound tokens.
     *
     * @return max borrow value for the given compound tokens in USD.
     */
    function collateralValueInUSD(CToken _cToken, uint256 _tokens) internal view returns (uint256) {
        // read the exchange rate from the cToken
        uint256 exchangeRate = _cToken.exchangeRateStored();

        // read the collateralFactor from the LibCToken.COMPTROLLER
        (, uint256 collateralFactor, ) = LibCToken.COMPTROLLER.markets(address(_cToken));

        // read the underlying token prive from the Compound's oracle
        uint256 oraclePrice = LibCToken.COMPTROLLER.oracle().getUnderlyingPrice(_cToken);
        require(oraclePrice != 0, "LibCompound: failed to get underlying price from the oracle");

        return mulExp3AndScalarTruncate(collateralFactor, exchangeRate, oraclePrice, _tokens);
    }

    /**
     * @notice Calculate the given cToken's underlying token balance of the caller.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance in the given token.
     */
    function balanceOfUnderlying(CToken _cToken) internal returns (uint256) {
        return mulScalarTruncate(_cToken.exchangeRateCurrent(), balanceOf(_cToken));
    } 

    /**
     * @notice Calculate the given cToken's balance of the caller.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function balanceOf(CToken _cToken) internal view returns (uint256) {
        State storage s = state();
        uint256 cTokenBalance = _cToken.balanceOf(address(this));
        if (s.bufferToken == _cToken) {
            cTokenBalance -= s.bufferAmount;
        }
        return cTokenBalance;
    } 

    /**
     * @notice mew markets can be entered by calling this function.
     */
    function enterMarkets(address[] memory _cTokens) internal {
        uint[] memory retVals = LibCToken.COMPTROLLER.enterMarkets(_cTokens);
        for (uint i; i < retVals.length; i++) {
            require(retVals[i] == 0, "LibCompound: failed to enter market");
        }
    }

    /**
     * @notice unhealth of the given account, the position is underwater 
     * if this value is greater than 100
     * @dev if the account is empty, this fn returns an unhealth of 0
     *
     * @return unhealth of the account 
     */
    function unhealth() internal view returns (uint256) {
        uint256 totalCollateralValue;
        State storage s = state();

        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        // calculate the total collateral value of this account
        for (uint i = 0; i < cTokens.length; i++) {
            totalCollateralValue = totalCollateralValue + collateralValue(CToken(cTokens[i]));
        }
        if (totalCollateralValue > 0) {
            uint256 totalBorrowValue;

            // get the account liquidity
            (uint err, uint256 liquidity, uint256 shortFall) = 
                LibCToken.COMPTROLLER.getHypotheticalAccountLiquidity(
                    address(this),
                    address(s.bufferToken),
                    s.bufferAmount,
                    0
                );
            require(err == 0, "LibCompound: failed to calculate account liquidity");

            if (liquidity == 0) {
                totalBorrowValue = totalCollateralValue + shortFall;
            } else {
                totalBorrowValue = totalCollateralValue - liquidity;
            }

            return (totalBorrowValue * 100) / totalCollateralValue;
        }
        return 0;
    }

    /**
     * @notice calculate the collateral value of the given cToken
     *
     * @return collateral value of the given cToken
     */
    function collateralValue(CToken cToken) internal view returns (uint256) {
        State storage s = state();
        uint256 bufferAmount;
        if (s.bufferToken == cToken) {
            bufferAmount = s.bufferAmount;
        }
        return collateralValueInUSD(
            cToken, 
            cToken.balanceOf(address(this)) - bufferAmount
        );
    }

    /**
     * @notice checks whether the given position is underwritten or not
     *
     * @return underwritten status of the caller
     */
    function isUnderwritten() internal view returns (bool) {
        State storage s = state();
        return (s.bufferAmount != 0 && s.bufferToken != CToken(address(0)));
    }

    /**
     * @notice checks the owner of this vault
     *
     * @return address of the owner
     */
    function owner() internal view returns (address) {
        return LibHidingVault.state().nft.ownerOf(uint256(uint160(address(this))));
    }

    /** Exponential Math */
    function mulExp3AndScalarTruncate(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256) {
        return mulScalarTruncate(mulExp(mulExp(a, b), c), d);
    }

    function mulExp(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * _b + 5e17) / 1e18;
    }

    function mulScalarTruncate(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * _b) / 1e18;
    }
}

interface Weth {
    function balanceOf(address owner) external view returns (uint);
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address spender, uint256 amount) external returns (bool);
}

interface NFT {
    function jitu() external view returns (address);
    function ownerOf(uint256 _tokenID) external view returns (address);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}