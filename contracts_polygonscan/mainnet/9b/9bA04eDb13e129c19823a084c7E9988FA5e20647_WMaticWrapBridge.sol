// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWMatic.sol";
import "../../interfaces/IWMaticWrap.sol";

/**
 * @title QuickswapSwapBridge
 * @author DeFi Basket
 *
 * @notice Swaps using the Quickswap contract in Polygon.
 *
 * @dev This contract swaps ERC20 tokens to ERC20 tokens. Please notice that there are no payable functions.
 *
 */

contract WMaticWrapBridge is IWMaticWrap {
    address constant wMaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    IWMatic constant wmatic = IWMatic(wMaticAddress);

    /**
      * @notice Wraps MATIC to WMATIC
      *
      * @dev Wraps MATIC into WMATIC using the WMATIC contract.
      *
      * @param percentageIn Percentage of MATIC to be wrapped into WMATIC
      */
    function wrap(uint256 percentageIn) external override {
        emit DEFIBASKET_WMATIC_WRAP(address(this).balance * percentageIn / 100000);
        wmatic.deposit{value : address(this).balance * percentageIn / 100000}();
    }

    /**
      * @notice Unwraps WMATIC to MATIC
      *
      * @dev Unwraps WMATIC into MATIC using the WMATIC contract.
      *
      * @param percentageOut Percentage of WMATIC to be unwrapped into MATIC
      */
    function unwrap(uint256 percentageOut) external override {
        emit DEFIBASKET_WMATIC_UNWRAP(IERC20(wMaticAddress).balanceOf(address(this)) * percentageOut / 100000);
        wmatic.withdraw(IERC20(wMaticAddress).balanceOf(address(this)) * percentageOut / 100000);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IWMatic {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IWMaticWrap {
    event DEFIBASKET_WMATIC_WRAP (
        uint256 amountIn
    );

    event DEFIBASKET_WMATIC_UNWRAP (
        uint256 amountOut
    );

    function wrap(uint256 percentageIn) external;

    function unwrap(uint256 percentageOut) external;
}