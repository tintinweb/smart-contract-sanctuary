// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IOptionBuilder.sol";
import "../interfaces/IPodOption.sol";
import "../lib/Conversion.sol";
import "../interfaces/IOptionFactory.sol";

/**
 * @title OptionFactory
 * @author Pods Finance
 * @notice Creates and store new Options Series
 * @dev Uses IOptionBuilder to create the different types of Options
 */
contract OptionFactory is IOptionFactory, Conversion {
    IConfigurationManager public immutable configurationManager;
    IOptionBuilder public podPutBuilder;
    IOptionBuilder public wPodPutBuilder;
    IOptionBuilder public aavePodPutBuilder;
    IOptionBuilder public podCallBuilder;
    IOptionBuilder public wPodCallBuilder;
    IOptionBuilder public aavePodCallBuilder;

    event OptionCreated(
        address indexed deployer,
        address option,
        IPodOption.OptionType _optionType,
        IPodOption.ExerciseType _exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize
    );

    constructor(
        address PodPutBuilder,
        address WPodPutBuilder,
        address AavePodPutBuilder,
        address PodCallBuilder,
        address WPodCallBuilder,
        address AavePodCallBuilder,
        address ConfigurationManager
    ) public {
        configurationManager = IConfigurationManager(ConfigurationManager);
        podPutBuilder = IOptionBuilder(PodPutBuilder);
        wPodPutBuilder = IOptionBuilder(WPodPutBuilder);
        aavePodPutBuilder = IOptionBuilder(AavePodPutBuilder);
        podCallBuilder = IOptionBuilder(PodCallBuilder);
        wPodCallBuilder = IOptionBuilder(WPodCallBuilder);
        aavePodCallBuilder = IOptionBuilder(AavePodCallBuilder);
    }

    /**
     * @notice Creates a new Option Series
     * @param name The option token name. Eg. "Pods Put WBTC-USDC 5000 2020-02-23"
     * @param symbol The option token symbol. Eg. "podWBTC:20AA"
     * @param optionType The option type. Eg. "0 for Put / 1 for Calls"
     * @param exerciseType The option exercise type. Eg. "0 for European, 1 for American"
     * @param underlyingAsset The underlying asset. Eg. "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
     * @param strikeAsset The strike asset. Eg. "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
     * @param strikePrice The option strike price including decimals. e.g. 5000000000
     * @param expiration The Expiration Option date in seconds. e.g. 1600178324
     * @param exerciseWindowSize The Expiration Window Size duration in seconds. E.g 24*60*60 (24h)
     * @return option The address for the newly created option
     */
    function createOption(
        string memory name,
        string memory symbol,
        IPodOption.OptionType optionType,
        IPodOption.ExerciseType exerciseType,
        address underlyingAsset,
        address strikeAsset,
        uint256 strikePrice,
        uint256 expiration,
        uint256 exerciseWindowSize,
        bool isAave
    ) external override returns (address) {
        IOptionBuilder builder;
        address wrappedNetworkToken = wrappedNetworkTokenAddress();

        if (optionType == IPodOption.OptionType.PUT) {
            if (underlyingAsset == wrappedNetworkToken) {
                builder = wPodPutBuilder;
            } else if (isAave) {
                builder = aavePodPutBuilder;
            } else {
                builder = podPutBuilder;
            }
        } else {
            if (underlyingAsset == wrappedNetworkToken) {
                builder = wPodCallBuilder;
            } else if (isAave) {
                builder = aavePodCallBuilder;
            } else {
                builder = podCallBuilder;
            }
        }

        address option = address(
            builder.buildOption(
                name,
                symbol,
                exerciseType,
                underlyingAsset,
                strikeAsset,
                strikePrice,
                expiration,
                exerciseWindowSize,
                configurationManager
            )
        );

        emit OptionCreated(
            msg.sender,
            option,
            optionType,
            exerciseType,
            underlyingAsset,
            strikeAsset,
            strikePrice,
            expiration,
            exerciseWindowSize
        );

        return option;
    }

    function wrappedNetworkTokenAddress() public override returns (address) {
        return _parseAddressFromUint(configurationManager.getParameter("WRAPPED_NETWORK_TOKEN"));
    }
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

import "./IPodOption.sol";

interface IOptionFactory {
    function createOption(
        string memory _name,
        string memory _symbol,
        IPodOption.OptionType _optionType,
        IPodOption.ExerciseType _exerciseType,
        address _underlyingAsset,
        address _strikeAsset,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _exerciseWindowSize,
        bool _isAave
    ) external returns (address);

    function wrappedNetworkTokenAddress() external returns (address);
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