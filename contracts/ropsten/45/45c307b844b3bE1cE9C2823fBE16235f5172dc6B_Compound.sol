// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/CTokenInterface.sol";
import "./interfaces/ComptrollerInterface.sol";
import "./interfaces/PriceOracleInterface.sol";

contract Compound {
    ComptrollerInterface public comptroller;
    PriceOracleInterface public priceOracle;

    constructor(address _comptroller, address _priceOracle) {
        comptroller = ComptrollerInterface(_comptroller);
        priceOracle = PriceOracleInterface(_priceOracle);
    }

    /**************** LENDING PART ***************/

    function supply(address cTokenAddress, uint256 underlyingAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint256 result = cToken.mint(underlyingAmount); // if fails, it doesn't throw
        require(
            result == 0,
            "cToken#mint() failed. See Compound ErrorReporter.sol for more details"
        );
    }

    // Reedem the token plus the interest
    function redeem(address cTokenAddress, uint256 cTokenAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        uint256 result = cToken.redeem(cTokenAmount); // Alternatively, cToken.redeemUnderlying(redeemAmount);
        require(
            result == 0,
            "cToken#redeem() failed. See Compound ErrorReporter.sol for more details"
        );
    }

    /**************** BORROWING PART ***************/

    // to determine which token to use as collateral
    function enterMarket(address cTokenAddress) external {
        address[] memory markets = new address[](1);
        markets[0] = cTokenAddress;
        uint256[] memory results = comptroller.enterMarkets(markets);
        require(
            results[0] == 0, // because we add only 1 cToken
            "comptroller#enterMarket() failed. See Compound ErrorReporter.sol for more details"
        );
    }

    // borrow tokens (after enterMarket)
    function borrow(address cTokenAddress, uint256 borrowAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        //address underlyingAddress = cToken.underlying();
        uint256 result = cToken.borrow(borrowAmount);
        require(
            result == 0,
            "cToken#borrow() failed. See Compound ErrorReporter.sol for more details"
        ); // if it fails, it is likely that we don't have enough collateral
    }

    // repay the loan
    function repayBorrow(address cTokenAddress, uint256 underlyingAmount)
        external
    {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint256 result = cToken.repayBorrow(underlyingAmount);
        require(
            result == 0,
            "cToken#repayBorrow() failed. See Compound ErrorReporter.sol for more details"
        );
    }

    // Determine what is the maximum amount we can borrow for any asset
    function getMaxBorrow(address cTokenAddress)
        external
        view
        returns (uint256)
    {
        (uint256 result, uint256 liquidity, uint256 shortfall) =
            comptroller.getAccountLiquidity(address(this));
        require(
            result == 0,
            "comptroller#getAccountLiquidity() failed. See Compound ErrorReporter.sol for more details"
        );
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account does not have collateral"); // otherwise, we are at the limit
        uint256 underlyingPrice = priceOracle.getUnderlyingPrice(cTokenAddress); // e.g.: if we pass cDAI, it will return the price of DAI
        return liquidity / underlyingPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

/**
 * @notice  Where the borrowing and lending happen. One cToken by asset supported by the platform (e.g.: for DAI, it is cDAI)
            There are 11 markets (cBAT, cCOMP, cDAI, cETH, cREP, cSAI, cUNI, cUSDC, cUSDT, cWBTC)
            New markets can only be added through the Governance system of Compound
 */

interface CTokenInterface {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function underlying() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

/**
 * @notice  Central smart contract of Compound: deals with risk management 
            by calculating how much each address is allowed to borrow
 */

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address owner)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

/**
 * @notice  Calculate the dollar value of the aggregated collateral position for each address.
            This allows to calculate how much an address is allowed to borrow.
            Prices are retrieved from Coinbase Pro to the OpenOraclePriceData, and then
            price is compared with a second Oracle (UniswapAnchoredView) from Uniswap.
 */

interface PriceOracleInterface {
  function getUnderlyingPrice(address asset) external view returns(uint);
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