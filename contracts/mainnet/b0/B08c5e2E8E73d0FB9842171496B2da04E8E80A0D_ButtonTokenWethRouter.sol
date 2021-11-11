// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IButtonWrapper.sol";
import "./interfaces/IRebasingERC20.sol";
import "./interfaces/IWETH.sol";

/**
 * @dev Router to automatically wrap ETH into WETH for ButtonToken actions
 */
contract ButtonTokenWethRouter is ReentrancyGuard {
    IWETH9 public weth;

    constructor(address _weth) {
        weth = IWETH9(_weth);
    }

    receive() external payable {
        require(msg.sender == address(weth), "ButtonTokenWethRouter: unexpected receive");
    }

    /**
     * @dev Deposit the given amount of ETH into the given ButtonToken
     *  Returns the output buttonTokens to the user.
     *
     * @param buttonToken the button token to deposit into
     * @return The amount of ButtonTokens created
     */
    function deposit(address buttonToken) external payable nonReentrant returns (uint256) {
        uint256 value = msg.value;
        require(value > 0, "ButtonTokenWethRouter: No ETH supplied");
        weth.deposit{value: msg.value}();
        weth.approve(buttonToken, value);
        return IButtonWrapper(buttonToken).depositFor(msg.sender, value);
    }

    /**
     * @dev Withdraw the given amount of button tokens from the given ButtonToken
     *  Returns the output ETH to the user
     *
     * @param buttonToken the button token to burn from
     * @param amount The amount of ButtonTokens to burn
     * @return The amount of ButtonTokens burned
     */
    function burn(address buttonToken, uint256 amount) external nonReentrant returns (uint256) {
        IRebasingERC20(buttonToken).transferFrom(msg.sender, address(this), amount);
        IButtonWrapper(buttonToken).burn(amount);
        weth.withdraw(weth.balanceOf(address(this)));
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ETH");
        return amount;
    }

    /**
     * @dev Withdraw all button tokens from the given ButtonToken
     *  Returns the output ETH to the user
     *
     * @param buttonToken the button token to burn from
     * @return The amount of ButtonTokens burned
     */
    function burnAll(address buttonToken) external nonReentrant returns (uint256) {
        IRebasingERC20(buttonToken).transferAllFrom(msg.sender, address(this));
        uint256 amount = IButtonWrapper(buttonToken).burnAll();
        weth.withdraw(weth.balanceOf(address(this)));
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ETH");
        return amount;
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

// SPDX-License-Identifier: GPL-3.0-or-later

// Interface definition for ButtonWrapper contract, which wraps an
// underlying ERC20 token into a new ERC20 with different characteristics.
// NOTE: "uAmount" => underlying token (wrapped) amount and
//       "amount" => wrapper token amount
interface IButtonWrapper {
    //--------------------------------------------------------------------------
    // ButtonWrapper write methods

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mintFor(address to, uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burn(uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burnTo(address to, uint256 amount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of underlying tokens withdrawn.
    function burnAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of underlying tokens withdrawn.
    function burnAllTo(address to) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function depositFor(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdraw(uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdrawTo(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAllTo(address to) external returns (uint256);

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @return The address of the underlying token.
    function underlying() external view returns (address);

    /// @return The total underlying tokens held by the wrapper contract.
    function totalUnderlying() external view returns (uint256);

    /// @param who The account address.
    /// @return The underlying token balance of the account.
    function balanceOfUnderlying(address who) external view returns (uint256);

    /// @param uAmount The amount of underlying tokens.
    /// @return The amount of wrapper tokens exchangeable.
    function underlyingToWrapper(uint256 uAmount) external view returns (uint256);

    /// @param amount The amount of wrapper tokens.
    /// @return The amount of underlying tokens exchangeable.
    function wrapperToUnderlying(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Interface definition for Rebasing ERC20 tokens which have a "elastic" external
// balance and "fixed" internal balance. Each user's external balance is
// represented as a product of a "scalar" and the user's internal balance.
//
// From time to time the "Rebase" event updates scaler,
// which increases/decreases all user balances proportionally.
//
// The standard ERC-20 methods are denominated in the elastic balance
//
interface IRebasingERC20 is IERC20, IERC20Metadata {
    /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint256);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint256);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to) external returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint256 indexed epoch, uint256 newScalar);
}

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
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