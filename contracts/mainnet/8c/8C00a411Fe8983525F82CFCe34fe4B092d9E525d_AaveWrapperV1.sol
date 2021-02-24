// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ILendingPoolV1 {
    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            IERC20 aTokenAddress,
            uint40 lastUpdateTimestamp
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWrapper {
    function wrap(IERC20 token) external view returns (IERC20 wrappedToken, uint256 rate);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/ILendingPoolV1.sol";
import "../interfaces/IWrapper.sol";


contract AaveWrapperV1 is IWrapper {
    IERC20 private constant _ETH = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant _EEE = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ILendingPoolV1 private constant _LENDING_POOL = ILendingPoolV1(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    mapping(IERC20 => IERC20) public aTokenToToken;
    mapping(IERC20 => IERC20) public tokenToaToken;

    function addMarkets(IERC20[] memory tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            (,,,,,,,,,,, IERC20 aToken,) = _LENDING_POOL.getReserveData(address(tokens[i]));
            require(aToken != IERC20(0), "Token is not supported");
            aTokenToToken[aToken] = tokens[i];
            tokenToaToken[tokens[i]] = aToken;
        }
    }

    function removeMarkets(IERC20[] memory tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            (,,,,,,,,,,, IERC20 aToken,) = _LENDING_POOL.getReserveData(address(tokens[i]));
            require(aToken == IERC20(0), "Token is still supported");
            delete aTokenToToken[aToken];
            delete tokenToaToken[tokens[i]];
        }
    }

    function wrap(IERC20 token) external view override returns (IERC20 wrappedToken, uint256 rate) {
        token = token == _ETH ? _EEE : token;
        IERC20 underlying = aTokenToToken[token];
        IERC20 aToken = tokenToaToken[token];
        if (underlying != IERC20(0)) {
            return (underlying == _EEE ? _ETH : underlying, 1e18);
        } else if (aToken != IERC20(0)) {
            return (aToken, 1e18);
        } else {
            revert("Unsupported token");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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