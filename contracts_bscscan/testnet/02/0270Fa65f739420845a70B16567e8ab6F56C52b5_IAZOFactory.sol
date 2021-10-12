// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

/*
 * ApeSwapFinance 
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com    
 * Twitter:         https://twitter.com/ape_swap 
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/ERC20.sol";
import "./interface/IIAZOSettings.sol";
import "./interface/IIAZOLiquidityLocker.sol";
import "./interface/IWNative.sol";


interface IIAZO_EXPOSER {
    function initializeExposer(address _iazoFactory, address _liquidityLocker) external;
    function registerIAZO(address newIAZO) external;
}

interface IIAZO {
    function isIAZO() external returns (bool);

    function initialize(
        // _addresses = [IAZOSettings, IAZOLiquidityLocker]
        address[2] memory _addresses, 
        // _addressesPayable = [IAZOOwner, feeAddress]
        address payable[2] memory _addressesPayable, 
        // _uint256s = [_tokenPrice,  _amount, _hardcap,  _softcap, _maxSpendPerBuyer, _liquidityPercent, _listingPrice, _startBlock, _activeBlocks, _lockPeriod, _baseFee, _iazoTokenFee]
        uint256[12] memory _uint256s, 
        // _bools = [_burnRemains]
        bool[1] memory _bools, 
        // _ERC20s = [_iazoToken, _baseToken]
        ERC20[2] memory _ERC20s, 
        IWNative _wnative
    ) external;     
}

/// @title IAZO factory 
/// @author ApeSwapFinance
/// @notice Factory to create new IAZOs
/// @dev This contract currently does NOT support non-standard ERC-20 tokens with fees on transfers
contract IAZOFactory is OwnableUpgradeable {
    IIAZO_EXPOSER public IAZO_EXPOSER;
    IIAZOSettings public IAZO_SETTINGS;
    IIAZOLiquidityLocker public IAZO_LIQUIDITY_LOCKER;
    IWNative public WNative;

    IIAZO[] public IAZOImplementations;
    uint256 public IAZOVersion;

    bool constant public isIAZOFactory = true;

    event IAZOCreated(address indexed newIAZO);
    event PushIAZOVersion(IIAZO indexed newIAZO, uint256 versionId);
    event UpdateIAZOVersion(uint256 previousVersion, uint256 newVersion);
    event SweepWithdraw(
        address indexed receiver, 
        IERC20 indexed token, 
        uint256 balance
    );

    struct IAZOParams {
        /// @dev To account for tokens with different decimals values the TOKEN_PRICE/LISTING_PRICE need to account for that
        /// Find the amount of tokens in BASE_TOKENS that 1 IAZO_TOKEN costs and use the equation below to find the TOKEN_PRICE
        /// TOKEN_PRICE = BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        /// i.e. 1 IAZO 8 decimal token (1e8) = 1 BASE_TOKEN 18 decimal token (1e18): TOKEN_PRICE = 1e28
        uint256 TOKEN_PRICE; // BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        uint256 AMOUNT; // AMOUNT of IAZO_TOKENS for sale
        uint256 HARDCAP; // HARDCAP of earnings.
        uint256 SOFTCAP; // SOFTCAP for earning. if not reached IAZO is cancelled
        uint256 START_TIME; // start timestamp of the IAZO
        uint256 ACTIVE_TIME; // end of IAZO -> START_TIME + ACTIVE_TIME
        uint256 LOCK_PERIOD; // days to lock earned tokens for IAZO_OWNER
        uint256 MAX_SPEND_PER_BUYER; // max spend per buyer
        uint256 LIQUIDITY_PERCENT; // Percentage of coins that will be locked in liquidity
        /// @dev Find the amount of tokens in BASE_TOKENS that 1 IAZO_TOKEN will be listed for and use the equation below to find the LISTING_PRICE
        /// LISTING_PRICE = BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        uint256 LISTING_PRICE; // BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
    }

    /// @notice Initialization of factory
    /// @param _iazoExposer The address of the IAZO exposer
    /// @param _iazoSettings The address of the IAZO settings
    /// @param _iazoliquidityLocker The address of the IAZO liquidity locker
    /// @param _iazoInitialImplementation The address of the initial IAZO implementation
    /// @param _wnative The address of the wrapped native coin
    /// @param _admin The admin address
    function initialize(
        IIAZO_EXPOSER _iazoExposer, 
        IIAZOSettings _iazoSettings, 
        IIAZOLiquidityLocker _iazoliquidityLocker, 
        IIAZO _iazoInitialImplementation,
        IWNative _wnative,
        address _admin
    ) external initializer {
        // Set admin as owner
        __Ownable_init();
        transferOwnership(_admin);
        // Setup the initial IAZO code to be used as the implementation
        require(_iazoInitialImplementation.isIAZO(), 'implementation does not appear to be IAZO');
        IAZOImplementations.push(_iazoInitialImplementation);
        // Assign initial implementation as version zero
        IAZOVersion = 0;
        IAZO_EXPOSER = _iazoExposer;
        IAZO_EXPOSER.initializeExposer(address(this), address(_iazoliquidityLocker));
        IAZO_SETTINGS = _iazoSettings;
        require(IAZO_SETTINGS.isIAZOSettings(), 'isIAZOSettings call returns false');
        IAZO_LIQUIDITY_LOCKER = _iazoliquidityLocker;
        require(IAZO_LIQUIDITY_LOCKER.isIAZOLiquidityLocker(), 'isIAZOLiquidityLocker call returns false');
        WNative = _wnative;
    }

    /// @notice Creates new IAZO and adds address to IAZOExposer
    /// @param _IAZOOwner The address of the IAZO owner
    /// @param _IAZOToken The address of the token to be sold
    /// @param _baseToken The address of the base token to be received
    /// @param _burnRemains Option to burn the remaining unsold tokens
    /// @param _uint_params IAZO settings. token price, amount of tokens for sale, softcap, start time, active time, liquidity locking period, maximum spend per buyer, percentage to lock as liquidity, listing price
    function createIAZO(
        address payable _IAZOOwner,
        ERC20 _IAZOToken,
        ERC20 _baseToken,
        bool _burnRemains,
        uint256[9] memory _uint_params
    ) external payable {
        require(_IAZOOwner != address(0), "IAZO Owner cannot be address(0)");
        require(address(_baseToken) != address(0), "Base token cannot be address(0)");
        IAZOParams memory params;
        params.TOKEN_PRICE = _uint_params[0];
        params.AMOUNT = _uint_params[1];
        params.SOFTCAP = _uint_params[2];
        params.START_TIME = _uint_params[3];
        params.ACTIVE_TIME = _uint_params[4];
        params.LOCK_PERIOD = _uint_params[5];
        params.MAX_SPEND_PER_BUYER = _uint_params[6];
        params.LIQUIDITY_PERCENT = _uint_params[7];
        if(_uint_params[8] == 0){
            params.LISTING_PRICE = params.TOKEN_PRICE;
        } else {
            params.LISTING_PRICE = _uint_params[8];
        }

        // Check that the unlock time was not sent in ms
        // This timestamp is Nov 20 2286
        require(params.LOCK_PERIOD < 9999999999, 'unlock time is too large ');
        // Lock period must be greater than the min lock period
        require(params.LOCK_PERIOD >= IAZO_SETTINGS.getMinLockPeriod(), 'Lock period too low');

        // Charge native coin fee for contract creation
        require(
            msg.value >= IAZO_SETTINGS.getNativeCreationFee(),
            "Fee not met"
        );
        /// @notice the entire funds sent in the tx will be taken as long as it's above the ethCreationFee
        IAZO_SETTINGS.getFeeAddress().transfer(
            address(this).balance
        );

        require(params.START_TIME > block.timestamp, "iazo should start in future");
        require(
            params.ACTIVE_TIME >= IAZO_SETTINGS.getMinIAZOLength(), 
            "iazo length not long enough"
        );
        require(
            params.ACTIVE_TIME <= IAZO_SETTINGS.getMaxIAZOLength(), 
            "Exceeds max iazo length"
        );

        /// @dev This is a check to ensure the amount is greater than zero, but also there are enough tokens
        ///   to handle percent and liquidity calculations.
        require(params.AMOUNT >= 10000, "amount is less than minimum divisibility");
        // Find the hard cap of the offering in base tokens
        uint256 hardcap = getHardCap(params.AMOUNT, params.TOKEN_PRICE);
        require(hardcap > 0, 'hardcap cannot be zero, please check the token price');
        // Check that the hardcap is greater than or equal to softcap
        require(hardcap >= params.SOFTCAP, 'softcap is greater than hardcap');

        /// @dev Adjust liquidity percentage settings here
        require(
            params.LIQUIDITY_PERCENT >= IAZO_SETTINGS.getMinLiquidityPercent() && params.LIQUIDITY_PERCENT <= 1000,
            "Liquidity percentage too low"
        );

        uint256 IAZOTokenFee = IAZO_SETTINGS.getIAZOTokenFee();

        uint256 tokensRequired = _getTokensRequired(
            params.AMOUNT,
            params.TOKEN_PRICE,
            params.LISTING_PRICE, 
            params.LIQUIDITY_PERCENT,
            IAZOTokenFee,
            true
        );

        // Setup initialization variables
        address[2] memory _addresses = [address(IAZO_SETTINGS), address(IAZO_LIQUIDITY_LOCKER)];
        address payable[2] memory _addressesPayable = [_IAZOOwner, IAZO_SETTINGS.getFeeAddress()];
        uint256[12] memory _uint256s = [params.TOKEN_PRICE, params.AMOUNT, hardcap, params.SOFTCAP, params.MAX_SPEND_PER_BUYER, params.LIQUIDITY_PERCENT, params.LISTING_PRICE, params.START_TIME, params.ACTIVE_TIME, params.LOCK_PERIOD, IAZO_SETTINGS.getBaseFee(), IAZOTokenFee];
        bool[1] memory _bools = [_burnRemains];
        ERC20[2] memory _ERC20s = [_IAZOToken, _baseToken];
        // Deploy clone contract and set implementation to current IAZO version. "We recommend explicitly describing the risks of participating in malicious sales as Factory is meant to be used without constant admin intervention."
        IIAZO newIAZO = IIAZO(Clones.clone(address(IAZOImplementations[IAZOVersion])));
        newIAZO.initialize(_addresses, _addressesPayable, _uint256s, _bools, _ERC20s, WNative);
        IAZO_EXPOSER.registerIAZO(address(newIAZO));
        _IAZOToken.transferFrom(address(msg.sender), address(newIAZO), tokensRequired);
        // transfer check and reflect token protection
        require(_IAZOToken.balanceOf(address(newIAZO)) == tokensRequired, 'invalid amount transferred in');
        emit IAZOCreated(address(newIAZO));
    }

    /// @notice Creates new IAZO and adds address to IAZOExposer
    /// @param _amount The amount of tokens for sale
    /// @param _tokenPrice The price of a single token
    /// @return Hardcap of the IAZO
    function getHardCap(
        uint256 _amount, 
        uint256 _tokenPrice
    ) public pure returns (uint256) {
        uint256 hardcap = _amount * _tokenPrice / 1e18;
        return hardcap;
    }

    /// @notice Check for how many tokens are required for the IAZO including token sale and liquidity.
    /// @param _amount The amount of tokens for sale
    /// @param _tokenPrice The price of the IAZO token in base token for sale during IAZO
    /// @param _listingPrice The price of the IAZO token in base token when creating liquidity
    /// @param _liquidityPercent The price of a single token
    /// @return Amount of tokens required
    function getTokensRequired(
        uint256 _amount, 
        uint256 _tokenPrice, 
        uint256 _listingPrice, 
        uint256 _liquidityPercent
    ) external view returns (uint256) {
        uint256 IAZOTokenFee = IAZO_SETTINGS.getIAZOTokenFee();
        return _getTokensRequired(_amount, _tokenPrice, _listingPrice, _liquidityPercent, IAZOTokenFee, false);
    }

    function _getTokensRequired(
        uint256 _amount, 
        uint256 _tokenPrice, 
        uint256 _listingPrice, 
        uint256 _liquidityPercent,  
        uint256 _iazoTokenFee,
        bool _require
    ) internal pure returns (uint256) {
        uint256 liquidityRequired = _amount * _tokenPrice * _liquidityPercent / 1000 / _listingPrice;
        /// @dev If liquidityRequired is zero, then there is a likely an issue with the pricing
        if(liquidityRequired == 0) {
            if(_require){
                require(liquidityRequired > 0, "Something wrong with liquidity values");
            } else {
                return 0;
            }
        }
        uint256 iazoTokenFee = _amount * _iazoTokenFee  / 1000;
        uint256 tokensRequired = _amount + liquidityRequired + iazoTokenFee;
        return tokensRequired;
    }

    /// @notice Add and use new IAZO implementation
    /// @param _newIAZOImplementation The address of the new IAZO implementation
    function pushIAZOVersion(IIAZO _newIAZOImplementation) external onlyOwner {
        require(_newIAZOImplementation.isIAZO(), 'implementation does not appear to be IAZO');
        IAZOImplementations.push(_newIAZOImplementation);
        IAZOVersion = IAZOImplementations.length - 1;
        emit PushIAZOVersion(_newIAZOImplementation, IAZOVersion);
    }

    /// @notice Use older IAZO implementation
    /// @dev Owner should be behind a timelock to prevent front running new IAZO deployments
    /// @param _newIAZOVersion The index of the to use IAZO implementation
    function setIAZOVersion(uint256 _newIAZOVersion) external onlyOwner {
        require(_newIAZOVersion < IAZOImplementations.length, 'version out of bounds');
        uint256 previousVersion = IAZOVersion;
        IAZOVersion = _newIAZOVersion;
        emit UpdateIAZOVersion(previousVersion, IAZOVersion);
    }

    /// @notice A public function to sweep accidental ERC20 transfers to this contract. 
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(IERC20[] memory _tokens, address _to) external onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            IERC20 token = _tokens[index];
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance
pragma solidity 0.8.6;

import "./ERC20.sol";

interface IIAZOLiquidityLocker {
    function APE_FACTORY() external view returns (address);

    function IAZO_EXPOSER() external view returns (address);

    function isIAZOLiquidityLocker() external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function apePairIsInitialized(address _token0, address _token1)
        external
        view
        returns (bool);

    function lockLiquidity(
        ERC20 _baseToken,
        ERC20 _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockDate,
        address _withdrawer
    ) external returns (address);
}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

interface IIAZOSettings {
    function SETTINGS()
        external
        view
        returns (
            address ADMIN_ADDRESS,
            address FEE_ADDRESS,
            uint256 BASE_FEE,
            uint256 MAX_BASE_FEE,
            uint256 NATIVE_CREATION_FEE,
            uint256 MIN_IAZO_LENGTH,
            uint256 MAX_IAZO_LENGTH,
            uint256 MIN_LOCK_PERIOD
        );

    function isIAZOSettings() external view returns (bool);

    function getAdminAddress() external view returns (address);

    function isAdmin(address toCheck) external view returns (bool);

    function getMaxIAZOLength() external view returns (uint256);

    function getMinIAZOLength() external view returns (uint256);

    function getBaseFee() external view returns (uint256);

    function getIAZOTokenFee() external view returns (uint256);
    
    function getMaxBaseFee() external view returns (uint256);

    function getMaxIAZOTokenFee() external view returns (uint256);

    function getNativeCreationFee() external view returns (uint256);

    function getMinLockPeriod() external view returns (uint256);

    function getMinLiquidityPercent() external view returns (uint256);

    function getFeeAddress() external view returns (address payable);

    function getBurnAddress() external view returns (address);

    function setAdminAddress(address _address) external;

    function setFeeAddresses(address _address) external;

    function setFees(uint256 _baseFee, uint256 _iazoTokenFee, uint256 _nativeCreationFee) external;

    function setMaxIAZOLength(uint256 _maxLength) external;

    function setMinIAZOLength(uint256 _minLength) external;

    function setMinLockPeriod(uint256 _minLockPeriod) external;

    function setMinLiquidityPercent(uint256 _minLiquidityPercent) external;

    function setBurnAddress(address _burnAddress) external;

}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

/**
 * A Wrapped token interface for native EVM tokens
 */
interface IWNative {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}