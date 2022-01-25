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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./erc677/IERC677Receiver.sol";

contract CrunchSelling is Ownable, Pausable, IERC677Receiver {
    /** @dev Emitted when the crunch address is changed. */
    event CrunchChanged(
        address indexed previousCrunch,
        address indexed newCrunch
    );

    /** @dev Emitted when the usdc address is changed. */
    event UsdcChanged(address indexed previousUsdc, address indexed newUsdc);

    /** @dev Emitted when the price is changed. */
    event PriceChanged(uint256 previousPrice, uint256 newPrice);

    /** @dev Emitted when `addr` sold $CRUNCHs for $USDCs. */
    event Sell(
        address indexed addr,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 price
    );

    /** @dev CRUNCH erc20 address. */
    IERC20Metadata public crunch;

    /** @dev USDC erc20 address. */
    IERC20 public usdc;

    /** @dev How much USDC must be exchanged for 1 CRUNCH. */
    uint256 public price;

    /** @dev Cached value of 1 CRUNCH (1**18). */
    uint256 public oneCrunch;

    constructor(
        address _crunch,
        address _usdc,
        uint256 initialPrice
    ) {
        _setCrunch(_crunch);
        _setUsdc(_usdc);
        _setPrice(initialPrice);
    }

    /**
     * Sell `amount` CRUNCH to USDC.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - caller's CRUNCH allowance is greater or equal to `amount`.
     * - caller's CRUNCH balance is greater or equal to `amount`.
     * - the contract must not be paused.
     * - caller is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @dev the implementation use a {IERC20-transferFrom(address, address, uint256)} call to transfer the CRUNCH from the caller to the owner.
     *
     * @param amount CRUNCH amount to sell.
     */
    function sell(uint256 amount) public whenNotPaused {
        address seller = _msgSender();

        require(
            crunch.allowance(seller, address(this)) >= amount,
            "Selling: user's allowance is not enough"
        );
        require(
            crunch.balanceOf(seller) >= amount,
            "Selling: user's balance is not enough"
        );

        crunch.transferFrom(seller, owner(), amount);

        _sell(seller, amount);
    }

    /**
     * Sell `amount` CRUNCH to USDC from a `transferAndCall`, avoiding the usage of an `approve` call.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - caller must be the crunch token.
     * - the contract must not be paused.
     * - `sender` is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @dev the implementation use a {IERC20-transfer(address, uint256)} call to transfer the received CRUNCH to the owner.
     */
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external override onlyCrunch whenNotPaused {
        data; /* silence unused */

        crunch.transfer(owner(), value);

        _sell(sender, value);
    }

    /**
     * Internal selling function.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - `seller` is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @param seller seller address.
     * @param amount CRUNCH amount to sell.
     */
    function _sell(address seller, uint256 amount) internal {
        require(seller != owner(), "Selling: owner cannot sell");
        require(amount != 0, "Selling: cannot sell 0 unit");

        uint256 tokens = conversion(amount);
        require(tokens != 0, "Selling: selling will result in getting nothing");
        require(reserve() >= tokens, "Selling: reserve is not big enough");

        usdc.transfer(seller, tokens);

        emit Sell(seller, amount, tokens, price);
    }

    /**
     * @dev convert a value in CRUNCH to USDC using the current price.
     *
     * @param inputAmount input value to convert.
     * @return outputAmount the converted amount.
     */
    function conversion(uint256 inputAmount)
        public
        view
        returns (uint256 outputAmount)
    {
        return (inputAmount * price) / oneCrunch;
    }

    /** @return the USDC balance of the contract. */
    function reserve() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /**
     * Empty the USDC reserve.
     *
     * Requirements:
     * - caller must be the owner.
     * - the contract must not be paused.
     */
    function emptyReserve() public onlyOwner whenPaused {
        bool success = _emptyReserve();

        /* prevent useless call */
        require(success, "Selling: reserve already empty");
    }

    /**
     * Empty the CRUNCH of the smart-contract.
     * Must never be called because there is no need to send CRUNCH to this contract.
     *
     * Requirements:
     * - caller must be the owner.
     * - the contract must not be paused.
     */
    function returnCrunchs() public onlyOwner whenPaused {
        bool success = _returnCrunchs();

        /* prevent useless call */
        require(success, "Selling: no crunch");
    }

    /**
     * Pause the contract.
     *
     * Requirements:
     * - caller must be the owner.
     * - contract must not already be paused.
     */
    function pause()
        external
        onlyOwner /* whenNotPaused */
    {
        _pause();
    }

    /**
     * Unpause the contract.
     *
     * Requirements:
     * - caller must be the owner.
     * - contract must be already paused.
     */
    function unpause()
        external
        onlyOwner /* whenPaused */
    {
        _unpause();
    }

    /**
     * Update the CRUNCH token address.
     *
     * Emits a {CrunchChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     * - the contract must be paused.
     *
     * @param newCrunch new CRUNCH address.
     */
    function setCrunch(address newCrunch) external onlyOwner whenPaused {
        _setCrunch(newCrunch);
    }

    /**
     * Update the USDC token address.
     *
     * Emits a {UsdcChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     * - the contract must be paused.
     *
     * @param newUsdc new USDC address.
     */
    function setUsdc(address newUsdc) external onlyOwner whenPaused {
        _setUsdc(newUsdc);
    }

    /**
     * Update the price.
     *
     * Emits a {PriceChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     *
     * @param newPrice new price value.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        _setPrice(newPrice);
    }

    /**
     * Destroy the contract.
     * This will send the tokens (CRUNCH and USDC) back to the owner.
     *
     * Requirements:
     * - caller must be the owner.
     * - the contract must be paused.
     */
    function destroy() external onlyOwner whenPaused {
        _emptyReserve();
        _returnCrunchs();

        selfdestruct(payable(owner()));
    }

    /**
     * Update the CRUNCH token address.
     *
     * Emits a {CrunchChanged} event.
     *
     * @dev this will update the `oneCrunch` value.
     *
     * @param newCrunch new CRUNCH address.
     */
    function _setCrunch(address newCrunch) internal {
        address previous = address(crunch);

        crunch = IERC20Metadata(newCrunch);
        oneCrunch = 10**crunch.decimals();

        emit CrunchChanged(previous, newCrunch);
    }

    /**
     * Update the USDC token address.
     *
     * Emits a {UsdcChanged} event.
     *
     * @param newUsdc new USDC address.
     */
    function _setUsdc(address newUsdc) internal {
        address previous = address(usdc);

        usdc = IERC20(newUsdc);

        emit UsdcChanged(previous, newUsdc);
    }

    /**
     * Update the price.
     *
     * Emits a {PriceChanged} event.
     *
     * @param newPrice new price value.
     */
    function _setPrice(uint256 newPrice) internal {
        uint256 previous = price;

        price = newPrice;

        emit PriceChanged(previous, newPrice);
    }

    /**
     * Empty the reserve.
     *
     * @return true if at least 1 USDC has been transfered, false otherwise.
     */
    function _emptyReserve() internal returns (bool) {
        uint256 amount = reserve();

        if (amount != 0) {
            usdc.transfer(owner(), amount);
            return true;
        }

        return false;
    }

    /**
     * Return the CRUNCHs.
     *
     * @return true if at least 1 CRUNCH has been transfered, false otherwise.
     */
    function _returnCrunchs() internal returns (bool) {
        uint256 amount = crunch.balanceOf(address(this));

        if (amount != 0) {
            crunch.transfer(owner(), amount);
            return true;
        }

        return false;
    }

    modifier onlyCrunch() {
        require(
            address(crunch) == _msgSender(),
            "Selling: caller must be the crunch token"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external;
}