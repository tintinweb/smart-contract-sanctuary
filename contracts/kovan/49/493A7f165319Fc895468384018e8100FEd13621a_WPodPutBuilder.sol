// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../WPodPut.sol";
import "../../interfaces/IPodOption.sol";
import "../../interfaces/IOptionBuilder.sol";

/**
 * @title WPodPutBuilder
 * @author Pods Finance
 * @notice Builds WPodPut options
 */
contract WPodPutBuilder is IOptionBuilder {
    /**
     * @notice creates a new WPodPut Contract
     * @param name The option token name. Eg. "Pods Put WETH-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWETH:20AA"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. For this type of option its not going to be used. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     */
    function buildOption(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset, // solhint-disable-line
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    ) external override returns (IPodOption) {
        WPodPut option = new WPodPut(
            name,
            symbol,
            exerciseType,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        );

        return option;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodPut.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/Conversion.sol";

/**
 * @title WPodPut
 * @author Pods Finance
 *
 * @notice Represents a tokenized Put option series for ETH. Internally it Wraps
 * ETH to treat it seamlessly.
 *
 * @dev Put options represents the right, not the obligation to sell the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 * Sellers can mint fungible Put option tokens by locking strikePrice * amountOfOptions
 * strike asset units until expiration. Buyers can exercise their Put, meaning
 * selling their underlying asset for strikePrice * amountOfOptions units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such a put option series where buyers
 * may sell 1 ETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: ETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * USDC holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their USDC into this contract
 * - Will issue put tokens corresponding to this USDC amount
 * - This contract is agnostic about where options could be bought or sold and how much the
 * the option premium should be.
 *
 * USDC holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their USDC from this contract
 * - Will burn the corresponding amount of put tokens
 *
 * Put token holders may call exerciseEth() until the expiration date, to
 * exercise their option, which in turn:
 *
 * - Will sell 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of put tokens.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and its price should be worth 0 in a healthy market.
 *
 */
contract WPodPut is PodPut, Conversion {
    event Received(address indexed sender, uint256 value);

    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodPut(
            name,
            symbol,
            exerciseType,
            _parseAddressFromUint(configurationManager.getParameter("WRAPPED_NETWORK_TOKEN")),
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);
        require(strikeToSend > 0, "WPodPut: amount of options is too low");

        // Sends strike asset
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Put token holders to use them to sell some amount of units
     * of ETH for the amount * strike price units of the strike token.
     *
     * @dev It uses the amount of ETH sent to exchange to the strike amount
     *
     * During the process:
     *
     * - The amount of ETH is transferred into this contract as a payment for the strike tokens
     * - The ETH is wrapped into WETH
     * - The amount of ETH * strikePrice of strike tokens are transferred to the caller
     * - The amount of option tokens are burned
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     */
    function exerciseEth() external payable exerciseWindow {
        uint256 amountOfOptions = msg.value;
        require(amountOfOptions > 0, "WPodPut: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 strikeToSend = _strikeToTransfer(amountOfOptions);

        // Burn the option tokens equivalent to the underlying requested
        _burn(msg.sender, amountOfOptions);

        // Retrieve the underlying asset from caller
        IWETH(underlyingAsset()).deposit{ value: msg.value }();

        // Releases the strike asset to caller, completing the exchange
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        if (underlyingToSend > 0) {
            IWETH(underlyingAsset()).withdraw(underlyingToSend);
            Address.sendValue(msg.sender, underlyingToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }

    receive() external payable {
        require(msg.sender == this.underlyingAsset(), "WPodPut: Only deposits from WETH are allowed");
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPodOption is IERC20 {
    /** Enums */
    // @dev 0 for Put, 1 for Call
    enum OptionType { PUT, CALL }
    // @dev 0 for European, 1 for American
    enum ExerciseType { EUROPEAN, AMERICAN }

    /** Events */
    event Mint(address indexed minter, uint256 amount);
    event Unmint(address indexed minter, uint256 optionAmount, uint256 strikeAmount, uint256 underlyingAmount);
    event Exercise(address indexed exerciser, uint256 amount);
    event Withdraw(address indexed minter, uint256 strikeAmount, uint256 underlyingAmount);

    /** Functions */

    /**
     * @notice Locks collateral and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * The collateral could be the strike or the underlying asset depending on the option type: Put or Call,
     * respectively
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike/underlying token contract to move caller funds.
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external;

    /**
     * @notice Allow option token holders to use them to exercise the amount of units
     * of the locked tokens for the equivalent amount of the exercisable assets.
     *
     * @dev It presumes the caller has already called IERC20.approve() exercisable asset
     * to move caller funds.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external;

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their collateral to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and collateral.
     */
    function withdraw() external;

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external;

    function optionType() external view returns (OptionType);

    function exerciseType() external view returns (ExerciseType);

    function underlyingAsset() external view returns (address);

    function underlyingAssetDecimals() external view returns (uint8);

    function strikeAsset() external view returns (address);

    function strikeAssetDecimals() external view returns (uint8);

    function strikePrice() external view returns (uint256);

    function strikePriceDecimals() external view returns (uint8);

    function expiration() external view returns (uint256);

    function startOfExerciseWindow() external view returns (uint256);

    function hasExpired() external view returns (bool);

    function isTradeWindow() external view returns (bool);

    function isExerciseWindow() external view returns (bool);

    function isWithdrawWindow() external view returns (bool);

    function strikeToTransfer(uint256 amountOfOptions) external view returns (uint256);

    function getSellerWithdrawAmounts(address owner)
        external
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount);

    function underlyingReserves() external view returns (uint256);

    function strikeReserves() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IPodOption.sol";
import "./IConfigurationManager.sol";

interface IOptionBuilder {
    function buildOption(
        string memory _name,
        string memory _symbol,
        IPodOption.ExerciseType _exerciseType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _exerciseWindowSize,
        IConfigurationManager _configurationManager
    ) external returns (IPodOption);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./PodOption.sol";

/**
 * @title PodPut
 * @author Pods Finance
 *
 * @notice Represents a tokenized Put option series for some long/short token pair.
 *
 * @dev Put options represents the right, not the obligation to sell the underlying asset
 * for strike price units of the strike asset.
 *
 * There are four main actions that can be done with an option:
 *
 * Sellers can mint fungible Put option tokens by locking strikePrice * amountOfOptions
 * strike asset units until expiration. Buyers can exercise their Put, meaning
 * selling their underlying asset for strikePrice * amountOfOptions units of strike asset.
 * At the end, seller can retrieve back its collateral, that could be the underlying asset
 * AND/OR strike based on the contract's current ratio of underlying and strike assets.
 *
 * There are many option's style, but the most usual are: American and European.
 * The difference between them are the moments that the buyer is allowed to exercise and
 * the moment that seller can retrieve its locked collateral.
 *
 *  Exercise:
 *  American -> any moment until expiration
 *  European -> only after expiration and until the end of the exercise window
 *
 *  Withdraw:
 *  American -> after expiration
 *  European -> after end of exercise window
 *
 * Let's take an example: there is such an European Put option series where buyers
 * may sell 1 WETH for 300 USDC until Dec 31, 2021.
 *
 * In this case:
 *
 * - Expiration date: Dec 31, 2021
 * - Underlying asset: WETH
 * - Strike asset: USDC
 * - Strike price: 300 USDC
 *
 * USDC holders may call mint() until the expiration date, which in turn:
 *
 * - Will lock their USDC into this contract
 * - Will mint/issue option tokens corresponding to this USDC amount
 * - This contract is agnostic about where to sell/buy and how much should be the
 * the option premium.
 *
 * USDC holders who also hold the option tokens may call unmint() until the
 * expiration date, which in turn:
 *
 * - Will unlock their USDC from this contract
 * - Will burn the corresponding amount of options tokens
 *
 * Option token holders may call exercise() after the expiration date and
 * before the end of exercise window, to exercise their option, which in turn:
 *
 * - Will sell 1 ETH for 300 USDC (the strike price) each.
 * - Will burn the corresponding amount of option tokens.
 *
 * USDC holders that minted options initially can call withdraw() after the
 * end of exercise window, which in turn:
 *
 * - Will give back its amount of collateral locked. That could be o mix of
 * underlying asset and strike asset based if and how the pool was exercised.
 *
 * IMPORTANT: Note that after expiration, option tokens are worthless since they can not
 * be exercised and its price should worth 0 in a healthy market.
 *
 */
contract PodPut is PodOption {
    constructor(
        string memory name,
        string memory symbol,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager configurationManager
    )
        public
        PodOption(
            name,
            symbol,
            IPodOption.OptionType.PUT,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize,
            configurationManager
        )
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Locks strike asset and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike token contract to move caller funds.
     *
     * This function is meant to be called by strike token holders wanting
     * to write option tokens. Calling it will lock `amountOfOptions` * `strikePrice`
     * units of `strikeToken` into this contract
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external override tradeWindow {
        require(amountOfOptions > 0, "PodPut: you can not mint zero options");

        uint256 amountToTransfer = _strikeToTransfer(amountOfOptions);
        _mintOptions(amountOfOptions, amountToTransfer, owner);

        IERC20(strikeAsset()).safeTransferFrom(msg.sender, address(this), amountToTransfer);

        emit Mint(owner, amountOfOptions);
    }

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external virtual override unmintWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _unmintOptions(amountOfOptions, msg.sender);
        require(strikeToSend > 0, "PodPut: amount of options is too low");

        // Sends strike asset
        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        emit Unmint(msg.sender, amountOfOptions, strikeToSend, underlyingToSend);
    }

    /**
     * @notice Allow Put token holders to use them to sell some amount of units
     * of the underlying token for the amount * strike price units of the
     * strike token.
     *
     * @dev It presumes the caller has already called IERC20.approve() on the
     * underlying token contract to move caller funds.
     *
     * During the process:
     *
     * - The amount * strikePrice of strike tokens are transferred to the caller
     * - The amount of option tokens are burned
     * - The amount of underlying tokens are transferred into
     * this contract as a payment for the strike tokens
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external virtual override exerciseWindow {
        require(amountOfOptions > 0, "PodPut: you can not exercise zero options");
        // Calculate the strike amount equivalent to pay for the underlying requested
        uint256 amountOfStrikeToTransfer = _strikeToTransfer(amountOfOptions);

        // Burn the option tokens equivalent to the underlying requested
        _burn(msg.sender, amountOfOptions);

        // Retrieve the underlying asset from caller
        IERC20(underlyingAsset()).safeTransferFrom(msg.sender, address(this), amountOfOptions);

        // Releases the strike asset to caller, completing the exchange
        IERC20(strikeAsset()).safeTransfer(msg.sender, amountOfStrikeToTransfer);

        emit Exercise(msg.sender, amountOfOptions);
    }

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their strike asset tokens to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and strike asset tokens.
     */
    function withdraw() external virtual override withdrawWindow {
        (uint256 strikeToSend, uint256 underlyingToSend) = _withdraw();

        IERC20(strikeAsset()).safeTransfer(msg.sender, strikeToSend);

        if (underlyingToSend > 0) {
            IERC20(underlyingAsset()).safeTransfer(msg.sender, underlyingToSend);
        }

        emit Withdraw(msg.sender, strikeToSend, underlyingToSend);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract Conversion {
    /**
     * @notice Parses the address represented by an uint
     */
    function _parseAddressFromUint(uint256 x) internal pure returns (address) {
        bytes memory data = new bytes(32);
        assembly {
            mstore(add(data, 32), x)
        }
        return abi.decode(data, (address));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPodOption.sol";
import "../lib/CappedOption.sol";
import "../lib/RequiredDecimals.sol";
import "../interfaces/IConfigurationManager.sol";

/**
 * @title PodOption
 * @author Pods Finance
 *
 * @notice This contract represents the basic structure of the financial instrument
 * known as Option, sharing logic between both a PUT or a CALL types.
 *
 * @dev There are four main actions that can be called in an Option:
 *
 * A) mint => A minter can lock collateral and create new options before expiration.
 * B) unmint => The minter who previously minted can choose for leaving its position any given time
 * until expiration.
 * C) exercise => The option bearer the can exchange its option for the collateral at the strike price.
 * D) withdraw => The minter can retrieve collateral at the end of the series.
 *
 * Depending on the type (PUT / CALL) or the exercise (AMERICAN / EUROPEAN), those functions have
 * different behave and should be override accordingly.
 */
abstract contract PodOption is IPodOption, ERC20, RequiredDecimals, CappedOption {
    using SafeERC20 for IERC20;

    /**
     * @dev Minimum allowed exercise window: 24 hours
     */
    uint256 public constant MIN_EXERCISE_WINDOW_SIZE = 86400;

    OptionType private immutable _optionType;
    ExerciseType private immutable _exerciseType;
    IConfigurationManager public immutable configurationManager;

    address private immutable _underlyingAsset;
    uint8 private immutable _underlyingAssetDecimals;
    address private immutable _strikeAsset;
    uint8 private immutable _strikeAssetDecimals;
    uint256 private immutable _strikePrice;
    uint256 private immutable _expiration;
    uint256 private _startOfExerciseWindow;

    /**
     * @notice Reserve share balance
     * @dev Tracks the shares of the total asset reserve by address
     */
    mapping(address => uint256) public shares;

    /**
     * @notice Minted option balance
     * @dev Tracks amount of minted options by address
     */
    mapping(address => uint256) public mintedOptions;

    /**
     * @notice Total reserve shares
     */
    uint256 public totalShares = 0;

    constructor(
        string memory name,
        string memory symbol,
        OptionType optionType,
        ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        IConfigurationManager _configurationManager
    ) public ERC20(name, symbol) CappedOption(_configurationManager) {
        require(Address.isContract(underlyingAsset), "PodOption: underlying asset is not a contract");
        require(Address.isContract(strikeAsset), "PodOption: strike asset is not a contract");
        require(underlyingAsset != strikeAsset, "PodOption: underlying asset and strike asset must differ");
        require(expiration > block.timestamp, "PodOption: expiration should be in the future");
        require(strikePrice > 0, "PodOption: strike price must be greater than zero");

        if (exerciseType == ExerciseType.EUROPEAN) {
            require(
                exerciseWindowSize >= MIN_EXERCISE_WINDOW_SIZE,
                "PodOption: exercise window must be greater than or equal 86400"
            );
            _startOfExerciseWindow = expiration.sub(exerciseWindowSize);
        } else {
            require(exerciseWindowSize == 0, "PodOption: exercise window size must be equal to zero");
            _startOfExerciseWindow = block.timestamp;
        }

        configurationManager = _configurationManager;

        _optionType = optionType;
        _exerciseType = exerciseType;
        _expiration = expiration;

        _underlyingAsset = underlyingAsset;
        _strikeAsset = strikeAsset;

        uint8 underlyingDecimals = tryDecimals(IERC20(underlyingAsset));
        _underlyingAssetDecimals = underlyingDecimals;
        _strikeAssetDecimals = tryDecimals(IERC20(strikeAsset));

        _strikePrice = strikePrice;
        _setupDecimals(underlyingDecimals);
    }

    /**
     * @notice Checks if the options series has already expired.
     */
    function hasExpired() external override view returns (bool) {
        return _hasExpired();
    }

    /**
     * @notice External function to calculate the amount of strike asset
     * needed given the option amount
     */
    function strikeToTransfer(uint256 amountOfOptions) external override view returns (uint256) {
        return _strikeToTransfer(amountOfOptions);
    }

    /**
     * @notice Checks if the options trade window has opened.
     */
    function isTradeWindow() external override view returns (bool) {
        return _isTradeWindow();
    }

    /**
     * @notice Checks if the options exercise window has opened.
     */
    function isExerciseWindow() external override view returns (bool) {
        return _isExerciseWindow();
    }

    /**
     * @notice Checks if the options withdraw window has opened.
     */
    function isWithdrawWindow() external override view returns (bool) {
        return _isWithdrawWindow();
    }

    /**
     * @notice The option type. eg: CALL, PUT
     */
    function optionType() external override view returns (OptionType) {
        return _optionType;
    }

    /**
     * @notice Exercise type. eg: AMERICAN, EUROPEAN
     */
    function exerciseType() external override view returns (ExerciseType) {
        return _exerciseType;
    }

    /**
     * @notice The sell price of each unit of underlyingAsset; given in units
     * of strikeAsset, e.g. 0.99 USDC
     */
    function strikePrice() external override view returns (uint256) {
        return _strikePrice;
    }

    /**
     * @notice The number of decimals of strikePrice
     */
    function strikePriceDecimals() external override view returns (uint8) {
        return _strikeAssetDecimals;
    }

    /**
     * @notice The timestamp in seconds that represents the series expiration
     */
    function expiration() external override view returns (uint256) {
        return _expiration;
    }

    /**
     * @notice How many decimals does the strike token have? E.g.: 18
     */
    function strikeAssetDecimals() public override view returns (uint8) {
        return _strikeAssetDecimals;
    }

    /**
     * @notice The asset used as the strike asset, e.g. USDC, DAI
     */
    function strikeAsset() public override view returns (address) {
        return _strikeAsset;
    }

    /**
     * @notice How many decimals does the underlying token have? E.g.: 18
     */
    function underlyingAssetDecimals() public override view returns (uint8) {
        return _underlyingAssetDecimals;
    }

    /**
     * @notice The asset used as the underlying token, e.g. WETH, WBTC, UNI
     */
    function underlyingAsset() public override view returns (address) {
        return _underlyingAsset;
    }

    /**
     * @notice getSellerWithdrawAmounts returns the seller position based on his amount of shares
     * and the current option position
     *
     * @param owner address of the user to check the withdraw amounts
     *
     * @return strikeAmount current amount of strike the user will receive. It may change until maturity
     * @return underlyingAmount current amount of underlying the user will receive. It may change until maturity
     */
    function getSellerWithdrawAmounts(address owner)
        public
        override
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount)
    {
        uint256 ownerShares = shares[owner];

        strikeAmount = ownerShares.mul(strikeReserves()).div(totalShares);
        underlyingAmount = ownerShares.mul(underlyingReserves()).div(totalShares);

        return (strikeAmount, underlyingAmount);
    }

    /**
     * @notice The timestamp in seconds that represents the start of exercise window
     */
    function startOfExerciseWindow() public override view returns (uint256) {
        return _startOfExerciseWindow;
    }

    /**
     * @notice Utility function to check the amount of the underlying tokens
     * locked inside this contract
     */
    function underlyingReserves() public override view returns (uint256) {
        return IERC20(_underlyingAsset).balanceOf(address(this));
    }

    /**
     * @notice Utility function to check the amount of the strike tokens locked
     * inside this contract
     */
    function strikeReserves() public override view returns (uint256) {
        return IERC20(_strikeAsset).balanceOf(address(this));
    }

    /**
     * @dev Modifier with the conditions to be able to mint
     * based on option exerciseType.
     */
    modifier tradeWindow() {
        require(_isTradeWindow(), "PodOption: trade window has closed");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to unmint
     * based on option exerciseType.
     */
    modifier unmintWindow() {
        require(_isTradeWindow() || _isExerciseWindow(), "PodOption: not in unmint window");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to exercise
     * based on option exerciseType.
     */
    modifier exerciseWindow() {
        require(_isExerciseWindow(), "PodOption: not in exercise window");
        _;
    }

    /**
     * @dev Modifier with the conditions to be able to withdraw
     * based on exerciseType.
     */
    modifier withdrawWindow() {
        require(_isWithdrawWindow(), "PodOption: option has not expired yet");
        _;
    }

    /**
     * @dev Internal function to check expiration
     */
    function _hasExpired() internal view returns (bool) {
        return block.timestamp >= _expiration;
    }

    /**
     * @dev Internal function to check trade window
     */
    function _isTradeWindow() internal view returns (bool) {
        if (_hasExpired()) {
            return false;
        } else if (_exerciseType == ExerciseType.EUROPEAN) {
            return !_isExerciseWindow();
        }
        return true;
    }

    /**
     * @dev Internal function to check window exercise started
     */
    function _isExerciseWindow() internal view returns (bool) {
        return !_hasExpired() && block.timestamp >= _startOfExerciseWindow;
    }

    /**
     * @dev Internal function to check withdraw started
     */
    function _isWithdrawWindow() internal view returns (bool) {
        return _hasExpired();
    }

    /**
     * @dev Internal function to calculate the amount of strike asset needed given the option amount
     * @param amountOfOptions Intended amount to options to mint
     */
    function _strikeToTransfer(uint256 amountOfOptions) internal view returns (uint256) {
        uint256 strikeAmount = amountOfOptions.mul(_strikePrice).div(10**uint256(underlyingAssetDecimals()));
        require(strikeAmount > 0, "PodOption: amount of options is too low");
        return strikeAmount;
    }

    /**
     * @dev Calculate number of reserve shares based on the amount of collateral locked by the minter
     */
    function _calculatedShares(uint256 amountOfCollateral) internal view returns (uint256 ownerShares) {
        uint256 currentStrikeReserves = strikeReserves();
        uint256 currentUnderlyingReserves = underlyingReserves();

        uint256 numerator = amountOfCollateral.mul(totalShares);
        uint256 denominator;

        if (_optionType == OptionType.PUT) {
            denominator = currentStrikeReserves.add(
                currentUnderlyingReserves.mul(_strikePrice).div(uint256(10)**underlyingAssetDecimals())
            );
        } else {
            denominator = currentUnderlyingReserves.add(
                currentStrikeReserves.mul(uint256(10)**underlyingAssetDecimals()).div(_strikePrice)
            );
        }
        ownerShares = numerator.div(denominator);
        return ownerShares;
    }

    /**
     * @dev Mint options, creating the shares accordingly to the amount of collateral provided
     * @param amountOfOptions The amount option tokens to be issued
     * @param amountOfCollateral The amount of collateral provided to mint options
     * @param owner Which address will be the owner of the options
     */
    function _mintOptions(
        uint256 amountOfOptions,
        uint256 amountOfCollateral,
        address owner
    ) internal capped(amountOfOptions) {
        require(owner != address(0), "PodOption: zero address cannot be the owner");

        if (totalShares > 0) {
            uint256 ownerShares = _calculatedShares(amountOfCollateral);

            shares[owner] = shares[owner].add(ownerShares);
            totalShares = totalShares.add(ownerShares);
        } else {
            shares[owner] = amountOfCollateral;
            totalShares = amountOfCollateral;
        }

        mintedOptions[owner] = mintedOptions[owner].add(amountOfOptions);

        _mint(msg.sender, amountOfOptions);
    }

    /**
     * @dev Unmints options, burning the option tokens removing shares accordingly and releasing a certain
     * amount of collateral.
     * @param amountOfOptions The amount option tokens to be burned
     * @param owner Which address options will be burned from
     */
    function _unmintOptions(uint256 amountOfOptions, address owner)
        internal
        returns (uint256 strikeToSend, uint256 underlyingToSend)
    {
        require(shares[owner] > 0, "PodOption: you do not have minted options");
        require(amountOfOptions <= mintedOptions[owner], "PodOption: not enough minted options");

        uint256 burnedShares = shares[owner].mul(amountOfOptions).div(mintedOptions[owner]);

        if (_optionType == IPodOption.OptionType.PUT) {
            uint256 strikeAssetDeposited = totalSupply().mul(_strikePrice).div(10**uint256(decimals()));
            uint256 totalInterest = 0;

            if (strikeReserves() > strikeAssetDeposited) {
                totalInterest = strikeReserves().sub(strikeAssetDeposited);
            }

            strikeToSend = amountOfOptions.mul(_strikePrice).div(10**uint256(decimals())).add(
                totalInterest.mul(burnedShares).div(totalShares)
            );

            // In the case we lost some funds due to precision, the last user to unmint will still be able to perform.
            if (strikeToSend > strikeReserves()) {
                strikeToSend = strikeReserves();
            }
        } else {
            uint256 underlyingAssetDeposited = totalSupply();
            uint256 currentUnderlyingAmount = underlyingReserves();
            uint256 totalInterest = 0;

            if (currentUnderlyingAmount > underlyingAssetDeposited) {
                totalInterest = currentUnderlyingAmount.sub(underlyingAssetDeposited);
            }

            underlyingToSend = amountOfOptions.add(totalInterest.mul(burnedShares).div(totalShares));
        }

        shares[owner] = shares[owner].sub(burnedShares);
        mintedOptions[owner] = mintedOptions[owner].sub(amountOfOptions);
        totalShares = totalShares.sub(burnedShares);

        _burn(owner, amountOfOptions);
    }

    /**
     * @dev Removes all shares, returning the amounts that would be withdrawable
     */
    function _withdraw() internal returns (uint256 strikeToSend, uint256 underlyingToSend) {
        uint256 ownerShares = shares[msg.sender];
        require(ownerShares > 0, "PodOption: you do not have balance to withdraw");

        (strikeToSend, underlyingToSend) = getSellerWithdrawAmounts(msg.sender);

        shares[msg.sender] = 0;
        mintedOptions[msg.sender] = 0;
        totalShares = totalShares.sub(ownerShares);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/ICapProvider.sol";

/**
 * @title CappedOption
 * @author Pods Finance
 *
 * @notice Controls a maximum cap for a guarded release
 */
abstract contract CappedOption is IERC20 {
    using SafeMath for uint256;

    IConfigurationManager private immutable _configurationManager;

    constructor(IConfigurationManager configurationManager) public {
        _configurationManager = configurationManager;
    }

    /**
     * @dev Modifier to stop transactions that exceed the cap
     */
    modifier capped(uint256 amountOfOptions) {
        uint256 cap = capSize();
        if (cap > 0) {
            require(this.totalSupply().add(amountOfOptions) <= cap, "CappedOption: amount exceed cap");
        }
        _;
    }

    /**
     * @dev Get the cap size
     */
    function capSize() public view returns (uint256) {
        ICapProvider capProvider = ICapProvider(_configurationManager.getCapProvider());
        return capProvider.getCap(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RequiredDecimals {
    uint256 private constant _MAX_TOKEN_DECIMALS = 38;

    /**
     * Tries to fetch the decimals of a token, if not existent, fails with a require statement
     *
     * @param token An instance of IERC20
     * @return The decimals of a token
     */
    function tryDecimals(IERC20 token) internal view returns (uint8) {
        // solhint-disable-line private-vars-leading-underscore
        bytes memory payload = abi.encodeWithSignature("decimals()");
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = address(token).staticcall(payload);

        require(success, "RequiredDecimals: required decimals");
        uint8 decimals = abi.decode(returnData, (uint8));
        require(decimals < _MAX_TOKEN_DECIMALS, "RequiredDecimals: token decimals should be lower than 38");

        return decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IConfigurationManager {
    function setParameter(bytes32 name, uint256 value) external;

    function setEmergencyStop(address emergencyStop) external;

    function setPricingMethod(address pricingMethod) external;

    function setIVGuesser(address ivGuesser) external;

    function setIVProvider(address ivProvider) external;

    function setPriceProvider(address priceProvider) external;

    function setCapProvider(address capProvider) external;

    function setAMMFactory(address ammFactory) external;

    function setOptionFactory(address optionFactory) external;

    function setOptionHelper(address optionHelper) external;

    function setOptionPoolRegistry(address optionPoolRegistry) external;

    function getParameter(bytes32 name) external view returns (uint256);

    function owner() external view returns (address);

    function getEmergencyStop() external view returns (address);

    function getPricingMethod() external view returns (address);

    function getIVGuesser() external view returns (address);

    function getIVProvider() external view returns (address);

    function getPriceProvider() external view returns (address);

    function getCapProvider() external view returns (address);

    function getAMMFactory() external view returns (address);

    function getOptionFactory() external view returns (address);

    function getOptionHelper() external view returns (address);

    function getOptionPoolRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface ICapProvider {
    function setCap(address target, uint256 value) external;

    function getCap(address target) external view returns (uint256);
}