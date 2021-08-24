// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/AaveV2/IAaveProtocolDataProvider.sol";
import "../interface/AaveV2/ILendingPoolAddressesProvider.sol";
import "../interface/AaveV2/IAavePriceOracle.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interface/IExchangeQuoter.sol";

/**
 * @title ExchangeQuoterAaveV2
 * @author solace.fi
 * @notice Calculates exchange rates for trades between ERC20 tokens and Ether. This version uses the Aave Price Oracle.
 */
contract ExchangeQuoterAaveV2 is IExchangeQuoter {
    /// @notice IAaveProtocolDataProvider.
    IAaveProtocolDataProvider public aaveDataProvider;
    // ETH_ADDRESS
    // solhint-disable-next-line var-name-mixedcase
    address internal _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Constructs the ExchangeQuoterAaveV2 contract.
     * @param dataProvider_ Aave protocol data provider address.
     */
    constructor(address dataProvider_) {
        aaveDataProvider = IAaveProtocolDataProvider(dataProvider_);
    }

    /**
     * @notice Calculates the exchange rate for an `amount` of `token` to **ETH**.
     * @param token The token to give.
     * @param amount The amount to give.
     * @return amountOut The amount of **ETH** received.
     */
    function tokenToEth(address token, uint256 amount) public view override returns (uint256 amountOut) {
        if(token == _ETH_ADDRESS) return amount;
        // get price oracle
        ILendingPoolAddressesProvider addressProvider = ILendingPoolAddressesProvider(aaveDataProvider.ADDRESSES_PROVIDER());
        IAavePriceOracle oracle = IAavePriceOracle(addressProvider.getPriceOracle());
        // swap math
        uint256 price = oracle.getAssetPrice(token);
        uint8 decimals = IERC20Metadata(token).decimals();
        return amount * price / 10**decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d#code

pragma solidity 0.8.6;

interface IAaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
    // solhint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0xb53c1a33016b2dc2ff3653530bff1848a515c8c5#code
pragma solidity 0.8.6;

/**
 * @title LendingPoolAddressesProvider contract
 * @author Aave
 * @notice Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 */
interface ILendingPoolAddressesProvider {

    /**
     * @notice Returns the address of the Price Oracle.
     * @return oracle The price oracle address.
     */
    function getPriceOracle() external view returns (address oracle);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0xa50ba011c48153de246e5192c8f9258a2ba79ca9
pragma solidity 0.8.6;

/// @title AaveOracle
/// @author Aave
/// @notice Proxy smart contract to get the price of an asset from a price source, with Chainlink Aggregator
///         smart contracts as primary option
/// - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallbackOracle
/// - Owned by the Aave governance system, allowed to add sources for assets, replace them
///   and change the fallbackOracle
interface IAavePriceOracle {

    /// @notice Gets an asset price by address
    /// @param asset The asset address
    function getAssetPrice(address asset) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IExchangeQuoter
 * @author solace.fi
 * @notice Calculates exchange rates for trades between ERC20 tokens and Ether.
 */
interface IExchangeQuoter {
    /**
     * @notice Calculates the exchange rate for an amount of token to eth.
     * @param token The token to give.
     * @param amount The amount to give.
     * @return amountOut The amount of eth received.
     */
    function tokenToEth(address token, uint256 amount) external view returns (uint256 amountOut);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}