// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "interfaces/notional/nTokenERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice ERC20 proxy for nToken contracts that forwards calls to the Router, all nToken
/// balances and allowances are stored in at single address for gas efficiency. This contract
/// is used simply for ERC20 compliance.
contract nTokenERC20Proxy is IERC20 {
    /// @notice Will be "nToken {Underlying Token}.name()", therefore "USD Coin" will be
    /// nToken USD Coin
    string public name;

    /// @notice Will be "n{Underlying Token}.symbol()", therefore "USDC" will be "nUSDC"
    string public symbol;

    /// @notice Inherits from Constants.INTERNAL_TOKEN_PRECISION
    uint8 public constant decimals = 8;

    /// @notice Address of the notional proxy
    nTokenERC20 public immutable proxy;

    /// @notice Currency id that this nToken refers to
    uint16 public immutable currencyId;

    constructor(
        nTokenERC20 proxy_,
        uint16 currencyId_,
        string memory underlyingName_,
        string memory underlyingSymbol_
    ) {
        proxy = proxy_;
        currencyId = currencyId_;
        name = string(abi.encodePacked("nToken ", underlyingName_));
        symbol = string(abi.encodePacked("n", underlyingSymbol_));
    }

    /// @notice Total number of tokens in circulation
    function totalSupply() external view override returns (uint256) {
        // Total supply is looked up via the token address
        return proxy.nTokenTotalSupply(address(this));
    }

    /// @notice Get the number of tokens held by the `account`
    /// @param account The address of the account to get the balance of
    /// @return The number of tokens held
    function balanceOf(address account) external view override returns (uint256) {
        return proxy.nTokenBalanceOf(currencyId, account);
    }

    /// @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
    /// @param account The address of the account holding the funds
    /// @param spender The address of the account spending the funds
    /// @return The number of tokens approved
    function allowance(address account, address spender) external view override returns (uint256) {
        return proxy.nTokenTransferAllowance(currencyId, account, spender);
    }

    /// @notice Approve `spender` to transfer up to `amount` from `src`
    /// @dev This will overwrite the approval amount for `spender`
    ///  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
    ///  emit:Approval
    /// @param spender The address of the account which may transfer tokens
    /// @param amount The number of tokens that are approved (2^256-1 means infinite)
    /// @return Whether or not the approval succeeded
    function approve(address spender, uint256 amount) external override returns (bool) {
        bool success = proxy.nTokenTransferApprove(currencyId, msg.sender, spender, amount);
        // Emit approvals here so that they come from the correct contract address
        if (success) emit Approval(msg.sender, spender, amount);
        return success;
    }

    /// @notice Transfer `amount` tokens from `msg.sender` to `to`
    /// @dev emit:Transfer
    /// @param to The address of the destination account
    /// @param amount The number of tokens to transfer
    /// @return Whether or not the transfer succeeded
    function transfer(address to, uint256 amount) external override returns (bool) {
        bool success = proxy.nTokenTransfer(currencyId, msg.sender, to, amount);
        // Emit transfer events here so they come from the correct contract
        if (success) emit Transfer(msg.sender, to, amount);
        return success;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`
    /// @dev emit:Transfer emit:Approval
    /// @param from The address of the source account
    /// @param to The address of the destination account
    /// @param amount The number of tokens to transfer
    /// @return Whether or not the transfer succeeded
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        bool success =
            proxy.nTokenTransferFrom(currencyId, msg.sender, from, to, amount);

        // Emit transfer events here so they come from the correct contract
        if (success) emit Transfer(from, to, amount);
        return success;
    }

    /// @notice Returns the present value of the nToken's assets denominated in asset tokens
    function getPresentValueAssetDenominated() external view returns (int256) {
        return proxy.nTokenPresentValueAssetDenominated(currencyId);
    }

    /// @notice Returns the present value of the nToken's assets denominated in underlying
    function getPresentValueUnderlyingDenominated() external view returns (int256) {
        return proxy.nTokenPresentValueUnderlyingDenominated(currencyId);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);

    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);

    function nTokenClaimIncentives() external returns (uint256);

    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);
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