// SPDX-License-Identifier: MIT

/**
 * @title Generator of EnergyFi launchpad enviroment
 * @dev This contract generate new launchpad with the given launchpad params. Launchpad
 * creation charges a fee in BNB which is defined in the launchpad settings.
 */
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERC20Meta.sol";
import "../interfaces/ILaunchpadFactory.sol";
import "./Launchpad.sol";
import "./TransferHelper.sol";

contract LaunchpadGenerator is Ownable {
    using SafeMath for uint256;

    // struct with parameter needed to create a new launchpad
    struct LaunchpadParams {
        uint256 amount; // min 10 000
        uint256 hardcap; // amount to be reached for successful ilo
        uint256 softcap; // minimum sold amount reached at end time for successful ilo
        uint256 liquidityPercent; // min 250(=25%) max 1000(=100%)
        uint256 listingRate; // listing price of sale token on pancakeswap
        uint256 maxSpendPerBuyer; // the maximum amount to be spent by a specific buyer
        uint256 tokensPerBaseToken; // the amount of sale tokens for one base token
        uint256 lockPeriod; // min 1 year in seconds
        uint256 startTime; // the timestamp to start the launchpad
        uint256 endTime; // the timestamp to end the launchpad (max length of settings contract must be met)
    }

    // addresses of dependen contracts
    address public immutable LAUNCHPAD_FACTORY;
    address public immutable LAUNCHPAD_LOCK_FORWARDER;
    address public immutable ENERGYFI_DEV;
    address public immutable WBNB;
    ILaunchpadSettings public immutable LAUNCHPAD_SETTINGS;

    /**
     *@dev sets initially contract dependend addresses
     *@param _launchpadFactory address of the launchpad factory contract
     *@param _launchpadSettings address of the settings contract
     *@param _wbnb address of the wrapped bnb contract
     *@param _launchpadLockForwarder address of LanchpadLockForwarder contract
     *@param _energyFiDev address of the developer account
     */
    constructor(
        address _launchpadFactory,
        address _launchpadSettings,
        address _wbnb,
        address _launchpadLockForwarder,
        address _energyFiDev
    ) public {
        require(
            _launchpadFactory != address(0) &&
                _launchpadSettings != address(0) &&
                _wbnb != address(0) &&
                _launchpadLockForwarder != address(0) &&
                _energyFiDev != address(0),
            "ZERO ADDRESS"
        );
        LAUNCHPAD_FACTORY = _launchpadFactory;
        LAUNCHPAD_SETTINGS = ILaunchpadSettings(_launchpadSettings);
        LAUNCHPAD_LOCK_FORWARDER = _launchpadLockForwarder;
        ENERGYFI_DEV = _energyFiDev;
        WBNB = _wbnb;
    }

    /**
     * @notice creates a new launchpad with the given parameters
     * @dev requires to receive the creation fee in BNB (defined in settings)
     * @param _launchpadOwner address of the launchpad owner account
     * @param _launchpadToken the token to be sold
     * @param _referralAddress the address to send the referral fee to
     * @param uint_params the parameters defined in LaunchpadParams struct (order matters)
     */
    function createLaunchpad(
        address payable _launchpadOwner,
        IERC20 _launchpadToken,
        IERC20Meta _baseToken,
        address payable _referralAddress,
        uint256[9] memory uint_params
    ) external payable {
        // read parameter from function call
        LaunchpadParams memory params;
        params.amount = uint_params[0];
        params.hardcap = uint_params[1];
        params.softcap = uint_params[2];
        params.liquidityPercent = uint_params[3];
        params.listingRate = uint_params[4];
        params.maxSpendPerBuyer = uint_params[5];
        params.lockPeriod = uint_params[6];
        params.startTime = uint_params[7];
        params.endTime = uint_params[8];

        // calculate token price and check precision
        params.tokensPerBaseToken = params.amount.mul(10**18).div(
            params.hardcap
        );
        require(
            params.tokensPerBaseToken.mul(params.hardcap).div(10**18) ==
                params.amount,
            "INVALID PARAMS"
        );

        // set locking period to a minimum of one year
        if (params.lockPeriod < LAUNCHPAD_SETTINGS.getMinLockingDuration()) {
            params.lockPeriod = LAUNCHPAD_SETTINGS.getMinLockingDuration();
        }

        // exact amount of creation fee has to be sent by function call
        require(
            msg.value == LAUNCHPAD_SETTINGS.getBnbCreationFee(),
            "FEE NOT MET"
        );
        // send creation fee to registered address
        LAUNCHPAD_SETTINGS.getBaseFeeReceiver().transfer(
            LAUNCHPAD_SETTINGS.getBnbCreationFee()
        );

        // check for valid referrer address
        if (_referralAddress != address(0)) {
            require(
                LAUNCHPAD_SETTINGS.referrerIsValid(_referralAddress),
                "INVALID REFERRAL"
            );
        }

        // check for sufficient amount
        require(params.amount >= 10000, "MIN DIVIS");

        // check if max time length is not met
        require(
            params.endTime.sub(params.startTime) <=
                LAUNCHPAD_SETTINGS.getMaxLaunchpadLength(),
            "INVALID TIME PERIOD"
        );

        // check for valid liquidity params (min 30% max 100%)
        require(
            params.liquidityPercent >= 250 && params.liquidityPercent <= 1000,
            "INVALID LIQUIDITY"
        );

        // calculate required token amount
        uint256 tokensRequiredForLaunchpad = calculateAmountRequired(
            params.amount,
            params.listingRate,
            params.liquidityPercent
        );

        // create launchpad
        Launchpad newLaunchpad = new Launchpad(
            address(this),
            WBNB,
            address(LAUNCHPAD_SETTINGS),
            LAUNCHPAD_LOCK_FORWARDER,
            ENERGYFI_DEV
        );

        // send required launchpad token amount to launchpad contract
        TransferHelper.safeTransferFrom(
            address(_launchpadToken),
            address(msg.sender),
            address(newLaunchpad),
            tokensRequiredForLaunchpad
        );

        // first part of launchpad initilization
        newLaunchpad.init1(
            _launchpadOwner,
            params.amount,
            params.tokensPerBaseToken,
            params.maxSpendPerBuyer,
            params.hardcap,
            params.softcap,
            params.liquidityPercent,
            params.listingRate,
            params.startTime,
            params.endTime,
            params.lockPeriod
        );

        // second part of launchpad initilization
        newLaunchpad.init2(
            _baseToken,
            _launchpadToken,
            LAUNCHPAD_SETTINGS.getTokenFee(),
            LAUNCHPAD_SETTINGS.getReferralFee(),
            LAUNCHPAD_SETTINGS.getBaseFeeReceiver(),
            LAUNCHPAD_SETTINGS.getSaleFeeReceiver(),
            _referralAddress
        );

        // register the created launchpad in factory
        ILaunchpadFactory(LAUNCHPAD_FACTORY).registerLaunchpad(
            address(newLaunchpad)
        );
    }

    /**
     *@notice calculates the amount of launchpad tokens to be required for creating a new launchpad
     *@dev this amount is sent to the new created launchpad contract
     */
    function calculateAmountRequired(
        uint256 _amount,
        uint256 _listingRate,
        uint256 _liquidityRate
    ) public view returns (uint256) {
        // calculate sale token fee
        uint256 tokenFee = LAUNCHPAD_SETTINGS.getTokenFee();
        uint256 feeAmount = _amount.mul(tokenFee).div(1000);

        // calculate required liquidity amount for locking
        uint256 liquidityRequired = _amount
            .mul(100 - _listingRate)
            .mul(_liquidityRate)
            .mul(1000 - tokenFee)
            .div(100000000);

        // calculate total required amount
        uint256 tokensRequiredForLaunchpad = _amount.add(liquidityRequired).add(
            feeAmount
        );
        return tokensRequiredForLaunchpad;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title Interface of a wrapped BNB token
 * @dev This interface describes a wrapping ERC20 token for native BNB currency
 */
interface IWBNB {
    /**
     * @dev Deposits native currency by sending it with the function call and creates
     * an equivalent amount of ERC20 token known as wrapping. The equivalent amount of
     * wrapped tokens is added to the senders account.
     */
    function deposit() external payable;

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Withraws the native currency for the given amount of wrapped token hold
     * by the function caller. The equivalent amount of native currency is sent to
     * the function caller.
     */
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

/**
 * @title Settings Interface of EnergyFi launchpad enviroment
 * @dev This Interface holds getter functions for getting the current general settings
 * of the launchpad. General settings are fees, fee receiver, launchpad length limitations,
 * allowed referrers and early access token to participate on round 1.
 */

pragma solidity 0.6.12;

interface ILaunchpadSettings {
    /**
     * @notice returns the address of the base fee receiver
     */
    function getBaseFeeReceiver() external view returns (address payable);

    /**
     * @notice returns the absolute fee in BNB for launchpad creation
     */
    function getBnbCreationFee() external view returns (uint256);

    /**
     * @notice returns the maximum duration of a launchpad in seconds
     */
    function getMaxLaunchpadLength() external view returns (uint256);

    /**
     * @notice returns the minimum duration of the lp locking period in seconds
     */
    function getMinLockingDuration() external view returns (uint256);

    /**
     * @notice returns the relative referral fee charged on base and sale token fee in parts per 1000
     */
    function getReferralFee() external view returns (uint256);

    /**
     * @notice returns the duration of round 1 in seconds
     */
    function getRound1Length() external view returns (uint256);

    /**
     * @notice returns the sale token fee receiver address
     */
    function getSaleFeeReceiver() external view returns (address payable);

    /**
     * @notice returns the relative sale token fee in parts per 1000
     */
    function getTokenFee() external view returns (uint256);

    /**
     * @notice returns if a given referrer is valid
     * @param _referrer address of the checked referrer
     */
    function referrerIsValid(address _referrer) external view returns (bool);

    /**
     * @notice returns if a given user has sufficient balance of early access tokens
     * registered in the EARLY_ACCESS_TOKENS set to participate in round 1
     * @param _user address of the user to be checked
     */
    function userHoldsSufficientRound1Token(address _user)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title LockForwarder Interface of the EnergyFi launchpad enviroment
 * @dev This interface describes the LaunchpadLockForwarder. It holds functions for interacting
 * with the pancakeswap factory for getting LP information and creating a LP on locking liquidity.
 * The locked liquidity amount is forwarded to PancakeLocker contract.
 */

import "./IERC20Meta.sol";

interface ILaunchpadLockForwarder {
    /**
     * @notice locks iquidity by creating a liquidity pair (LP) with base and sale token,
     * sending liquidity amount of both tokens to the LP and locks the minted LP token
     * with PancakeLocker contract.
     * @param _baseToken token received for sold launchpad token
     * @param _saleToken token sold in launchpad
     * @param _baseAmount amount of base tokens to be locked
     * @param _saleAmount amount of sale tokens to be locked
     * @param _unlockDate timestamp to unlock the locked lp token
     * @param _withdrawer address allowed to withdraw token after unlock date
     */
    function lockLiquidity(
        IERC20Meta _baseToken,
        IERC20 _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockDate,
        address payable _withdrawer
    ) external;

    /**
     * @notice checks if a pancake pair with liquidity exists on pancakeswap for the given tokens
     * @param _token0 one address of the pancake pair base tokens
     * @param _token1 the other address of the pancake pair base tokens
     */
    function pancakeswapPairIsInitialised(address _token0, address _token1)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 * @title Factory interface of EnergyFi launchpad enviroment
 * @dev This interface holds functions for registering launchpads and get information about
 * registered launchpads and launchpad generators.
 */

pragma solidity 0.6.12;

interface ILaunchpadFactory {
    /**
     * @notice adds a launchpad to factory by generator
     * @param _launchpadAddress address of the launchpad to be added
     */
    function registerLaunchpad(address _launchpadAddress) external;

    /**
     * @notice returns the address of a launchpad at a given index
     * @param _index index of the launchpads address set
     */
    function launchpadAtIndex(uint256 _index) external view returns (address);

    /**
     * @notice returns the address of a launchpad generator at a given index
     * @param _index index of the launchpad generator address set
     */
    function launchpadGeneratorAtIndex(uint256 _index)
        external
        view
        returns (address);

    /**
     * @notice returns the total number of registered launchpad generators
     */
    function launchpadGeneratorsLength() external view returns (uint256);

    /**
     * @notice returns if a given address is registered as a launchpad
     * @param _launchpadAddress address of the lauchpad to be checked
     */
    function launchpadIsRegistered(address _launchpadAddress)
        external
        view
        returns (bool);

    /**
     * @notice returns the total number of registered launchpads
     */
    function launchpadsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@title Interface of a burnable ERC20 token
 *@dev This interface describes a burnable ERC20 token providing a burn function.
 */
interface IERC20Meta is IERC20 {
    /**
     * @dev Returns the number of decimals of an ERC20 token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

/**
 * @title TransferHelper of EnergyFi launchpad enviroment
 * @dev This library holds function to transfer tokens safely. It allows safe transfer
 * for BNB as well as ERC20 tokens from a sender to a receiver. The ERC20 token functions
 * are used with low level call function.
 */

pragma solidity 0.6.12;

library TransferHelper {
    /**
     * @notice calls the aprove function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token spender (allowed to call transferFrom)
     * @param value amount of tokens to transfer
     */
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @notice calls the transferFrom function of a given token in a safe way
     * @dev transfers needs to be approved first. uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param from address of token sender
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way or transfers BNB
     * if base token is not a ERC20 token
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of the token receiver
     * @param value amount of tokens to transfer
     * @param isERC20 bool to indicate if the base token in BNB (=false) or ERC20 token (=true)
     */
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 * @title Launchpad of EnergyFi launchpad enviroment
 * @dev This contract represents a launchpad. A launchpad can be created and initilized by a
 * launchpad generator. Users can deposit base token if the launchpad is active and get an
 * amount of sale token in raltion to the token price. The sale tokens can be withdrawn if the
 * the launchpad is successful. Otherwise the users and the launchpad owner get back their
 * vested tokens. On launchpad success a pancakeswap liquidity pair will be created and the
 * specified amount of liquidity will be locked in pancake locker contract.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IERC20Meta.sol";
import "../interfaces/ILaunchpadLockForwarder.sol";
import "../interfaces/ILaunchpadSettings.sol";
import "../interfaces/IWBNB.sol";
import "./TransferHelper.sol";

contract Launchpad is ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant CONTRACT_VERSION = 1;

    /*---------------------------------------------------------------------------------------------
     * ------------------------------------Structs definitions-------------------------------------
     */

    // struct holding accounting information about a buyer
    struct BuyerInfo {
        uint256 baseDeposited; // amount of deposited base tokens
        uint256 tokensOwed; // amount of owed sale tokens
    }

    // struct holding information about the fees during the ilo
    struct LaunchpadFeeInfo {
        uint256 energyFiTokenFee; // fee on adding liquidity calculated on sale token (in parts per 1000)
        uint256 referralFee; // fee on adding liquidity calculated on baseFee and token fee (in parts per 1000)
        address payable baseFeeAddress; // address receiving base token fee amount
        address payable tokenFeeAddress; // address receiving sale token fee amount
        address payable referralFeeAddress; // address receiving referral fee amount in base and sale token
    }

    // struct holding information about the launchpad
    struct LaunchpadInfo {
        address payable launchpadOwner; // the owner address of the launchpad
        IERC20 sToken; // token to be sold in the launchpad (sale token)
        IERC20Meta bToken; // token to purchase the sale token (base token)
        uint256 amount; // min 10 000
        uint256 tokensPerBaseToken; // the amount of sale tokens received for one base token
        uint256 maxSpendPerBuyer; // the maximum amount to be spent by a specific buyer
        uint256 softCap; // minimum sold amount reached at end time for successful ilo
        uint256 hardcap; // amount to be reached for successful ilo
        uint256 liquidityPercentage; // min 250(=25%) max 1000(=100%)
        uint256 listingRate; // listing price of sale token on pancakeswap
        uint256 lockPeriod; // duration of the token lock in seconds (min 1 year)
        uint256 startTime; // the timestamp to start the launchpad
        uint256 endTime; // the timestamp to end the launchpad (max length of settings contract must be met)
        bool isBNB; // if the base token is native currency
    }

    // struct with information about the current launchpad status
    struct LaunchpadStatus {
        bool forceFailed; // if the ilo failed (is invalid)
        bool lpGenerationComplete; // if the lp generation was successful
        bool whitelistOnly; // allow deposits only for whitelisted users
        uint256 lpGenerationTimestamp; // set to block.timestamp when lpGenerationComplete is set to true
        uint256 totalBaseCollected; // tracks total collected amount of base tokens
        uint256 totalBaseWithdrawn; // tracks withdraws base tokens after failed ilo
        uint256 totalTokensSold; // tracks the total sold sale tokens
        uint256 totalTokensWithdrawn; // tracks withdraws sale tokens after successful ilo
        uint256 numBuyers; // total number of sale token buyers
        uint256 round1Length; // the length of round 1 in seconds
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Global Variables--------------------------------------
     */
    // struct variables holding launchpad information
    LaunchpadInfo public launchpadInfo;
    LaunchpadFeeInfo public launchpadFeeInfo;
    LaunchpadStatus public launchpadStatus;

    // interface variables
    ILaunchpadLockForwarder public immutable launchpadLockForwarder;
    ILaunchpadSettings public immutable launchpadSettings;
    IWBNB public immutable WBNB;

    // addresses used for access control
    address public immutable LAUNCHPAD_GENERATOR;
    address immutable ENERGYFI_DEV;

    // variables holding information about users
    mapping(address => BuyerInfo) public buyers;
    EnumerableSet.AddressSet private whitelist;

    /*---------------------------------------------------------------------------------------------
     * ------------------------------------Initilize functions-------------------------------------
     */

    /**
     * @dev sets initially contract dependend addresses
     * @param _launchpadGenerator address of the launchpad generator
     * @param _wbnb address of the wrapped bnb contract
     * @param _launchpadSettings address of the settings contract
     * @param _launchpadLockForwarder address of LanchpadLockForwarder contract
     * @param _energyFiDev address of the developer account
     */
    constructor(
        address _launchpadGenerator,
        address _wbnb,
        address _launchpadSettings,
        address _launchpadLockForwarder,
        address _energyFiDev
    ) public {
        require(
            _launchpadGenerator != address(0) &&
                _wbnb != address(0) &&
                _launchpadSettings != address(0) &&
                _launchpadLockForwarder != address(0) &&
                _energyFiDev != address(0),
            "ZERO ADDRESS"
        );
        LAUNCHPAD_GENERATOR = _launchpadGenerator;
        WBNB = IWBNB(_wbnb);
        launchpadSettings = ILaunchpadSettings(_launchpadSettings);
        launchpadLockForwarder = ILaunchpadLockForwarder(
            _launchpadLockForwarder
        );
        ENERGYFI_DEV = _energyFiDev;
    }

    /**
     * @notice first initilize function sets launchpad information by the launchpad generator
     * @dev this function can only be called by the launchpad generator
     * @param _launchpadOwner the owner address of the launchpad
     * @param _amount the total amount of sale tokens (min 10 000)
     * @param _tokensPerBaseToken the amount of sale tokens for one base token
     * @param _maxSpendPerBuyer the total amount of base token a specific buyer can spend
     * @param _hardcap the maximum amount of tokens to be reached for success
     * @param _softcap the minumum amount of tokens to be reached until end time for success
     * @param _liquidityPercent the percent of locked liquidity in parts per 1000 (min 250)
     * @param _listingRate the listing rate on pancakeswap
     * @param _startTime the timestamp to start launchpad
     * @param _endTime the timestamp of the launchpad end
     * @param _lockPeriod the duration of the locking period in seconds
     */
    function init1(
        address payable _launchpadOwner,
        uint256 _amount,
        uint256 _tokensPerBaseToken,
        uint256 _maxSpendPerBuyer,
        uint256 _hardcap,
        uint256 _softcap,
        uint256 _liquidityPercent,
        uint256 _listingRate,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockPeriod
    ) external {
        require(msg.sender == LAUNCHPAD_GENERATOR, "FORBIDDEN");
        launchpadInfo.launchpadOwner = _launchpadOwner;
        launchpadInfo.amount = _amount;
        launchpadInfo.tokensPerBaseToken = _tokensPerBaseToken;
        launchpadInfo.maxSpendPerBuyer = _maxSpendPerBuyer;
        launchpadInfo.hardcap = _hardcap;
        launchpadInfo.softCap = _softcap;
        launchpadInfo.liquidityPercentage = _liquidityPercent;
        launchpadInfo.listingRate = _listingRate;
        launchpadInfo.startTime = _startTime;
        launchpadInfo.endTime = _endTime;
        launchpadInfo.lockPeriod = _lockPeriod;
    }

    /**
     * @notice second initilize function sets launchpad information by the launchpad generator
     * @dev this function can only be called by the launchpad generator
     * @param _baseToken the token to purchase the sale token
     * @param _launchpadToken the token to be sold in the launchpad (sale token)
     * @param _energyFiTokenFee the fee on the sale token by adding liquidity in parts per 1000
     * @param _referralFee the fee calculated on base fee an token fee in parts per 1000
     * @param _baseFeeAddress the receiver of the base token fee amount
     * @param _tokenFeeAddress the receiver of the sale token fee amount
     * @param _referralAddress the receiver of the sale and base token referral fee amounts
     */
    function init2(
        IERC20Meta _baseToken,
        IERC20 _launchpadToken,
        uint256 _energyFiTokenFee,
        uint256 _referralFee,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress,
        address payable _referralAddress
    ) external {
        require(msg.sender == LAUNCHPAD_GENERATOR, "FORBIDDEN");

        launchpadInfo.isBNB = address(_baseToken) == address(WBNB);
        launchpadInfo.sToken = _launchpadToken;
        launchpadInfo.bToken = _baseToken;
        launchpadFeeInfo.energyFiTokenFee = _energyFiTokenFee;
        launchpadFeeInfo.referralFee = _referralFee;

        launchpadFeeInfo.baseFeeAddress = _baseFeeAddress;
        launchpadFeeInfo.tokenFeeAddress = _tokenFeeAddress;
        launchpadFeeInfo.referralFeeAddress = _referralAddress;
        launchpadStatus.round1Length = launchpadSettings.getRound1Length();
    }

    /*---------------------------------------------------------------------------------------------
     * -----------------------------------External user functions----------------------------------
     */
    /**
     * @notice has to be called after the launchpad was successful to end the launchpad.
     * @dev it creates a liquidity pair, locks liquidty and enables the withdraw of users sale tokens.
     */
    function addLiquidity() external nonReentrant {
        require(!launchpadStatus.lpGenerationComplete, "GENERATION COMPLETE");
        require(getLaunchpadStatus() == 2, "NOT SUCCESS");

        // abort the launch and set launchpad to failed if a pair already exists on pancakeswap
        if (
            launchpadLockForwarder.pancakeswapPairIsInitialised(
                address(launchpadInfo.sToken),
                address(launchpadInfo.bToken)
            )
        ) {
            launchpadStatus.forceFailed = true;
            return;
        }

        // calculate eneryFi fee on base token
        uint256 energyFiBaseFee = launchpadStatus
            .totalBaseCollected
            .mul(launchpadFeeInfo.energyFiTokenFee)
            .div(1000);

        // calculate liquidity amount of base token
        uint256 baseLiquidity = launchpadStatus
            .totalBaseCollected
            .sub(energyFiBaseFee)
            .mul(launchpadInfo.liquidityPercentage)
            .div(1000);

        // wrap BNB if base token is BNB
        if (launchpadInfo.isBNB) {
            WBNB.deposit{value: baseLiquidity}();
        }

        // approve lock forwarder with base token liquidity amount
        TransferHelper.safeApprove(
            address(launchpadInfo.bToken),
            address(launchpadLockForwarder),
            baseLiquidity
        );

        // calculate energyFi sale token fee amount
        uint256 energyFiTokenFee = launchpadStatus
            .totalTokensSold
            .mul(launchpadFeeInfo.energyFiTokenFee)
            .div(1000);

        // calculate equivalent sale token liquidity amount
        uint256 tokenLiquidity = launchpadStatus
            .totalTokensSold
            .sub(energyFiTokenFee)
            .mul(100 - launchpadInfo.listingRate)
            .mul(launchpadInfo.liquidityPercentage)
            .div(100000);

        // approve lock forwarder with sale token liquidity amount
        TransferHelper.safeApprove(
            address(launchpadInfo.sToken),
            address(launchpadLockForwarder),
            tokenLiquidity
        );

        // create liquidity pool and lock liquidity
        launchpadLockForwarder.lockLiquidity(
            launchpadInfo.bToken,
            launchpadInfo.sToken,
            baseLiquidity,
            tokenLiquidity,
            block.timestamp.add(launchpadInfo.lockPeriod),
            launchpadInfo.launchpadOwner
        );

        // calculate referral fee on energyFi base fee and energyfi token fee
        if (launchpadFeeInfo.referralFeeAddress != address(0)) {
            // calculate base token referral fee
            uint256 referralBaseFee = energyFiBaseFee
                .mul(launchpadFeeInfo.referralFee)
                .div(1000);
            // send base token referral fee to referral receiver address
            TransferHelper.safeTransferBaseToken(
                address(launchpadInfo.bToken),
                launchpadFeeInfo.referralFeeAddress,
                referralBaseFee,
                !launchpadInfo.isBNB
            );
            energyFiBaseFee = energyFiBaseFee.sub(referralBaseFee);

            // calculate sale token referral fee
            uint256 referralTokenFee = energyFiTokenFee
                .mul(launchpadFeeInfo.referralFee)
                .div(1000);
            // send sale token referral fee to referral receiver address
            TransferHelper.safeTransfer(
                address(launchpadInfo.sToken),
                launchpadFeeInfo.referralFeeAddress,
                referralTokenFee
            );
            energyFiTokenFee = energyFiTokenFee.sub(referralTokenFee);
        }
        // transfer energyFi base token fee to base token fee receiver
        TransferHelper.safeTransferBaseToken(
            address(launchpadInfo.bToken),
            launchpadFeeInfo.baseFeeAddress,
            energyFiBaseFee,
            !launchpadInfo.isBNB
        );
        // transfer energyFi sale token fee to sale token fee receiver
        TransferHelper.safeTransfer(
            address(launchpadInfo.sToken),
            launchpadFeeInfo.tokenFeeAddress,
            energyFiTokenFee
        );

        uint256 remainingSBalance = launchpadInfo.sToken.balanceOf(
            address(this)
        );

        // burn unsold amount of sale tokens
        if (remainingSBalance > launchpadStatus.totalTokensSold) {
            uint256 burnAmount = remainingSBalance.sub(
                launchpadStatus.totalTokensSold
            );
            TransferHelper.safeTransfer(
                address(launchpadInfo.sToken),
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        // send remaining base token balance to launchpad owner
        uint256 remainingBaseBalance = launchpadInfo.isBNB
            ? address(this).balance
            : launchpadInfo.bToken.balanceOf(address(this));
        TransferHelper.safeTransferBaseToken(
            address(launchpadInfo.bToken),
            launchpadInfo.launchpadOwner,
            remainingBaseBalance,
            !launchpadInfo.isBNB
        );

        // end launchpad by setting pair generation to true
        launchpadStatus.lpGenerationComplete = true;
        launchpadStatus.lpGenerationTimestamp = block.timestamp;
    }

    /**
     * @notice set the status of the launchpad to failed, if a the liquidity pair exists on
     * pancakeswap before the launchpad is successfully finished
     * @dev this function can be called by anyone and requires the launchpad to be active
     */
    function forceFailIfPairExists() external {
        require(
            !launchpadStatus.lpGenerationComplete &&
                !launchpadStatus.forceFailed,
            "LAUNCHPAD NOT ACTIVE"
        );
        if (
            launchpadLockForwarder.pancakeswapPairIsInitialised(
                address(launchpadInfo.sToken),
                address(launchpadInfo.bToken)
            )
        ) {
            launchpadStatus.forceFailed = true;
        }
    }

    /**
     * @notice deposits the given amount of base tokens and calculates the equivalent amount
     * of sale tokens owed by the caller.
     * @dev this function uses msg.value and ignores _amount param for BNB as base token.
     * The correct amount is required for ERC20 base tokens
     * @param _amount the amount of base token to deposit
     */
    function userDeposit(uint256 _amount) external payable nonReentrant {
        require(getLaunchpadStatus() == 1, "NOT ACTIVE");

        // check for whitelisted auction
        if (launchpadStatus.whitelistOnly) {
            require(whitelist.contains(msg.sender), "NOT WHITELISTED");
        }

        // check if token balance for round 1 deposit is met
        // round 1 deposits require the user to hold a specific token and balance
        if (
            block.timestamp <
            launchpadInfo.startTime.add(launchpadStatus.round1Length)
        ) {
            require(
                launchpadSettings.userHoldsSufficientRound1Token(msg.sender),
                "INSUFFICENT ROUND 1 TOKEN BALANCE"
            );
        }

        // check if user is allowed to spend the desired token and calculate max amount
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 amount_in = launchpadInfo.isBNB ? msg.value : _amount;
        uint256 allowance = launchpadInfo.maxSpendPerBuyer.sub(
            buyer.baseDeposited
        );
        uint256 remaining = launchpadInfo.hardcap.sub(
            launchpadStatus.totalBaseCollected
        );
        allowance = allowance > remaining ? remaining : allowance;
        if (amount_in > allowance) {
            amount_in = allowance;
        }

        // calculate amount of sale token for deposit
        uint256 tokensSold = amount_in
            .mul(launchpadInfo.tokensPerBaseToken)
            .div(10**18);
        require(tokensSold > 0, "ZERO TOKENS");

        // increase total number of buyers
        if (buyer.baseDeposited == 0) {
            launchpadStatus.numBuyers++;
        }

        // update buyer token information
        buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
        buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);

        // update launchpad token information
        launchpadStatus.totalBaseCollected = launchpadStatus
            .totalBaseCollected
            .add(amount_in);
        launchpadStatus.totalTokensSold = launchpadStatus.totalTokensSold.add(
            tokensSold
        );

        // transfer unused BNB back to user if base token is BNB
        if (launchpadInfo.isBNB && amount_in < msg.value) {
            msg.sender.transfer(msg.value.sub(amount_in));
        }

        // transfer non BNB base token to launchpad
        if (!launchpadInfo.isBNB) {
            TransferHelper.safeTransferFrom(
                address(launchpadInfo.bToken),
                msg.sender,
                address(this),
                amount_in
            );
        }
    }

    /**
     * @notice withdraws deposited base tokens of the caller if the launchpad failed
     */
    function userWithdrawBaseTokens() external nonReentrant {
        require(getLaunchpadStatus() == 3, "NOT FAILED");

        // calculate user base tokens to be withdrawn
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 baseDeposited = buyer.baseDeposited;
        require(baseDeposited > 0, "NOTHING TO WITHDRAW");

        // update deposited tokens value
        launchpadStatus.totalBaseWithdrawn = launchpadStatus
            .totalBaseWithdrawn
            .add(buyer.baseDeposited);
        buyer.baseDeposited = 0;

        // tranfer base token back to the depositor
        TransferHelper.safeTransferBaseToken(
            address(launchpadInfo.bToken),
            msg.sender,
            baseDeposited,
            !launchpadInfo.isBNB
        );
    }

    /**
     * @notice withdraws users sale token amount if the launchpad was successful and the
     * liquidity pool creation is completed.
     */
    function userWithdrawTokens() external nonReentrant {
        require(launchpadStatus.lpGenerationComplete, "AWAITING LP GENERATION");

        // get sale tokens amount to withdraw
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 tokensOwed = buyer.tokensOwed;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");

        // update withdrawn sale token amount
        launchpadStatus.totalTokensWithdrawn = launchpadStatus
            .totalTokensWithdrawn
            .add(buyer.tokensOwed);
        buyer.tokensOwed = 0;

        // transfer sale token to function caller
        TransferHelper.safeTransfer(
            address(launchpadInfo.sToken),
            msg.sender,
            tokensOwed
        );
    }

    /*---------------------------------------------------------------------------------------------
     * ------------------------------------Only Owner functions------------------------------------
     */
    modifier onlyLaunchpadOwner() {
        require(
            launchpadInfo.launchpadOwner == msg.sender,
            "NOT LAUNCHPAD OWNER"
        );
        _;
    }

    /**
     * @notice update the whitelisted users by owner. Users can be added to or removed from whitelist
     * @param _users array of user addresses to be added to or removed from whitelist
     * @param _add indicating if the given user(s) should be added to(=true) or removed from (=false) whitelist
     */
    function editWhitelist(address[] memory _users, bool _add)
        external
        onlyLaunchpadOwner
    {
        if (_add) {
            for (uint256 i = 0; i < _users.length; i++) {
                whitelist.add(_users[i]);
            }
        } else {
            for (uint256 i = 0; i < _users.length; i++) {
                whitelist.remove(_users[i]);
            }
        }
    }

    /**
     * @notice withdraws all sale tokens by launchpad owner if the launchpad failed
     * the sale tokens are sent to the launchpad owner address
     */
    function ownerWithdrawTokens() external onlyLaunchpadOwner {
        require(getLaunchpadStatus() == 3, "NOT FAILED");
        TransferHelper.safeTransfer(
            address(launchpadInfo.sToken),
            launchpadInfo.launchpadOwner,
            launchpadInfo.sToken.balanceOf(address(this))
        );
    }

    /**
     * @notice sets if the launchpad is only for whitelisted users by launchpad owner
     */
    function setWhitelistFlag(bool _flag) external onlyLaunchpadOwner {
        launchpadStatus.whitelistOnly = _flag;
    }

    /**
     * @notice updates the start and end time of the launchpad by launchpad owner
     */
    function updateDuration(uint256 _startTime, uint256 _endTime)
        external
        onlyLaunchpadOwner
    {
        require(
            getLaunchpadStatus() == 0 &&
                launchpadInfo.startTime > block.timestamp,
            "LAUNCHPAD NOT ACTIVE"
        );
        require(
            _endTime.sub(_startTime) <=
                launchpadSettings.getMaxLaunchpadLength(),
            "DURATION TOO LONG"
        );
        launchpadInfo.startTime = _startTime;
        launchpadInfo.endTime = _endTime;
    }

    /**
     * @notice updates the limit a single user can spend on the launchpad
     */
    function updateMaxSpendLimit(uint256 _maxSpend)
        external
        onlyLaunchpadOwner
    {
        launchpadInfo.maxSpendPerBuyer = _maxSpend;
    }

    /*---------------------------------------------------------------------------------------------
     * ---------------------------------Only EnergyFi Dev functions--------------------------------
     */
    /**
     * @notice enegyFi developers can force a fail in case of an unintended behaviour
     * @dev security function to ensure the launchpad can be cancelled at any time to unlock funds
     */
    function forceFailByEnergyFi() external {
        require(msg.sender == ENERGYFI_DEV);
        launchpadStatus.forceFailed = true;
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Getter functions--------------------------------------
     */
    /**
     * @notice returns the current status of the launchpad
     */
    function getLaunchpadStatus() public view returns (uint256) {
        if (launchpadStatus.forceFailed) {
            return 3; // launchpad failed
        }
        if (
            (block.timestamp > launchpadInfo.endTime) &&
            (launchpadStatus.totalBaseCollected < launchpadInfo.softCap)
        ) {
            return 3; // launchpad failed - softcap not met
        }
        if (launchpadStatus.totalBaseCollected >= launchpadInfo.hardcap) {
            return 2; // launchpad successful - hardcap met
        }
        if (
            (block.timestamp > launchpadInfo.endTime) &&
            (launchpadStatus.totalBaseCollected >= launchpadInfo.softCap)
        ) {
            return 2; // launchpad successful - softcap met
        }
        if (
            (block.timestamp >= launchpadInfo.startTime) &&
            (block.timestamp <= launchpadInfo.endTime)
        ) {
            return 1; // launchpad active
        }
        return 0; // launchpad not active yet
    }

    /**
     * @notice returns if a user if whitelisted
     * @param _user address of the user to be checked
     */
    function getUserWhitelistStatus(address _user)
        external
        view
        returns (bool)
    {
        return whitelist.contains(_user);
    }

    /**
     * @notice returns the users address at the given whitelist index
     * @param _index whitelist index
     */
    function getWhitelistedUserAtIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return whitelist.at(_index);
    }

    /**
     * @notice returns the total number of whitelisted users
     */
    function getWhitelistedUsersLength() external view returns (uint256) {
        return whitelist.length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}