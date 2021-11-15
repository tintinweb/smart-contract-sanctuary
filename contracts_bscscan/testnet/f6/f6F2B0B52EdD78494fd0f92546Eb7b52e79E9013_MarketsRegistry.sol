// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../market/IMarketsRegistry.sol";

interface InitializeableAmm {
    function initialize(
        IMarketsRegistry _registry,
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../token/ISimpleToken.sol";

/** Interface for any Siren Market
 */
interface IMarket {
    /** Tracking the different states of the market */
    enum MarketState {
        /**
         * New options can be created
         * Redemption token holders can redeem their options for collateral
         * Collateral token holders can't do anything
         */
        OPEN,
        /**
         * No new options can be created
         * Redemption token holders can't do anything
         * Collateral tokens holders can re-claim their collateral
         */
        EXPIRED,
        /**
         * 180 Days after the market has expired, it will be set to a closed state.
         * Once it is closed, the owner can sweep any remaining tokens and destroy the contract
         * No new options can be created
         * Redemption token holders can't do anything
         * Collateral tokens holders can't do anything
         */
        CLOSED
    }

    /** Specifies the manner in which options can be redeemed */
    enum MarketStyle {
        /**
         * Options can only be redeemed 30 minutes prior to the option's expiration date
         */
        EUROPEAN_STYLE,
        /**
         * Options can be redeemed any time between option creation
         * and the option's expiration date
         */
        AMERICAN_STYLE
    }

    function state() external view returns (MarketState);

    function mintOptions(uint256 collateralAmount) external;

    function calculatePaymentAmount(uint256 collateralAmount)
        external
        view
        returns (uint256);

    function calculateFee(uint256 amount, uint16 basisPoints)
        external
        pure
        returns (uint256);

    function exerciseOption(uint256 collateralAmount) external;

    function claimCollateral(uint256 collateralAmount) external;

    function closePosition(uint256 collateralAmount) external;

    function recoverTokens(IERC20 token) external;

    function selfDestructMarket(address payable refundAddress) external;

    function updateRestrictedMinter(address _restrictedMinter) external;

    function marketName() external view returns (string memory);

    function priceRatio() external view returns (uint256);

    function expirationDate() external view returns (uint256);

    function collateralToken() external view returns (IERC20);

    function paymentToken() external view returns (IERC20);

    function wToken() external view returns (ISimpleToken);

    function bToken() external view returns (ISimpleToken);

    function updateImplementation(address newImplementation) external;

    function initialize(
        string calldata _marketName,
        address _collateralToken,
        address _paymentToken,
        MarketStyle _marketStyle,
        uint256 _priceRatio,
        uint256 _expirationDate,
        uint16 _exerciseFeeBasisPoints,
        uint16 _closeFeeBasisPoints,
        uint16 _claimFeeBasisPoints,
        address _tokenImplementation
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IMarket.sol";

/** Interface for any Siren MarketsRegistry
 */
interface IMarketsRegistry {
    // function state() external view returns (MarketState);

    function markets(string calldata marketName)
        external
        view
        returns (address);

    function getMarketsByAssetPair(bytes32 assetPair)
        external
        view
        returns (address[] memory);

    function amms(bytes32 assetPair) external view returns (address);

    function initialize(
        address _tokenImplementation,
        address _marketImplementation,
        address _ammImplementation
    ) external;

    function updateTokenImplementation(address newTokenImplementation) external;

    function updateMarketImplementation(address newMarketImplementation)
        external;

    function updateAmmImplementation(address newAmmImplementation) external;

    function updateMarketsRegistryImplementation(
        address newMarketsRegistryImplementation
    ) external;

    function createMarket(
        string calldata _marketName,
        address _collateralToken,
        address _paymentToken,
        IMarket.MarketStyle _marketStyle,
        uint256 _priceRatio,
        uint256 _expirationDate,
        uint16 _exerciseFeeBasisPoints,
        uint16 _closeFeeBasisPoints,
        uint16 _claimFeeBasisPoints,
        address _amm
    ) external returns (address);

    function createAmm(
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) external returns (address);

    function selfDestructMarket(IMarket market, address payable refundAddress)
        external;

    function updateImplementationForMarket(
        IMarket market,
        address newMarketImplementation
    ) external;

    function recoverTokens(IERC20 token, address destination) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "./IMarket.sol";
import "./IMarketsRegistry.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../proxy/Proxy.sol";
import "../proxy/Proxiable.sol";
import "../amm/InitializeableAmm.sol";

/**
 * The Markets Registry is responsible for creating and tracking markets
 */
contract MarketsRegistry is OwnableUpgradeSafe, Proxiable, IMarketsRegistry {
    /** Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Receiver {
        address secondaryAddress;
        uint8 vaultPercentage;
        bool authorized;
    }

    /** Mapping of authorized fee receivers */
    mapping(address => Receiver) public feeReceivers;

    /** Mapping of market names to addresses */
    mapping(string => address) public override markets;
    mapping(bytes32 => address[]) marketsByAssets;

    /** Mapping of keccak256(abi.encode(address(_collateralToken), address(_paymentToken))) 
     * bytes32 keys to AMM (Automated Market Maker) addresses
     */
    mapping(bytes32 => address) public override amms;

    /** Implementation address for token contracts - can be upgraded by owner */
    address public tokenImplementation;

    /** Implementation address for the markets contract - can be upgraded by owner */
    address public marketImplementation;

    /** Implementation address for the AMM contract - can be upgraded by owner */
    address public ammImplementation;

    /** Emitted when the owner updates the token implementation address */
    event TokenImplementationUpdated(address newAddress);

    /** Emitted when the owner updates the market implementation address */
    event MarketImplementationUpdated(address newAddress);

    /** Emitted when the owner updates the amm implementation address */
    event AmmImplementationUpdated(address newAddress);

    /** Emitted when the owner creates a new market */
    event MarketCreated(string name, address newAddress, uint256 marketIndex);

    /** Emitted when contract is destroyed */
    event MarketDestroyed(address market);

    /** Emitted when tokens are recovered */
    event TokensRecovered(
        address indexed token,
        address indexed to,
        uint256 value
    );

    /** Emitted when a new AMM is created and initialized */
    event AmmCreated(address amm);

    /**
     * Called to set this contract up
     * Creation and initialization should be called in a single transaction.
     */
    function initialize(
        address _tokenImplementation,
        address _marketImplementation,
        address _ammImplementation
    ) public override {
        __MarketsRegistry_init(
            _tokenImplementation,
            _marketImplementation,
            _ammImplementation
        );
    }

    /**
     * Initialization function that only allows itself to be called once
     */
    function __MarketsRegistry_init(
        address _tokenImplementation,
        address _marketImplementation,
        address _ammImplementation
    ) internal initializer {
        // Verify addresses
        require(_tokenImplementation != address(0x0), "Invalid _tokenImplementation");
        require(_marketImplementation != address(0x0), "Invalid _marketImplementation");
        require(_ammImplementation != address(0x0), "Invalid _ammImplementation");

        // Save off implementation addresses
        tokenImplementation = _tokenImplementation;
        marketImplementation = _marketImplementation;
        ammImplementation = _ammImplementation;

        // Set up the initialization of the inherited ownable contract
        __Ownable_init();
    }

    /**
     * The owner can update the token implementation address that will be used for future markets
     */
    function updateTokenImplementation(address newTokenImplementation)
        public
        override
        onlyOwner
    {
        require(newTokenImplementation != address(0x0), "Invalid newTokenImplementation");

        // Update the address
        tokenImplementation = newTokenImplementation;

        // Emit the event
        emit TokenImplementationUpdated(tokenImplementation);
    }

    /**
     * The owner can update the market implementation address that will be used for future markets
     */
    function updateMarketImplementation(address newMarketImplementation)
        public
        override
        onlyOwner
    {
        require(newMarketImplementation != address(0x0), "Invalid newMarketImplementation");

        // Update the address
        marketImplementation = newMarketImplementation;

        // Emit the event
        emit MarketImplementationUpdated(marketImplementation);
    }

    /**
     * The owner can update the AMM implementation address that will be used for future AMMs
     */
    function updateAmmImplementation(address newAmmImplementation)
        public
        override
        onlyOwner
    {
        require(newAmmImplementation != address(0x0), "Invalid newAmmImplementation");

        // Update the address
        ammImplementation = newAmmImplementation;

        // Emit the event
        emit AmmImplementationUpdated(ammImplementation);
    }

    /**
     * The owner can update the contract logic address in the proxy itself to upgrade
     */
    function updateMarketsRegistryImplementation(
        address newMarketsRegistryImplementation
    ) public override onlyOwner {
        require(newMarketsRegistryImplementation != address(0x0), "Invalid newMarketsRegistryImplementation");

        // Call the proxiable update
        _updateCodeAddress(newMarketsRegistryImplementation);
    }


    /**
     * The owner can update the contract logic address of a particular Market
     * in the proxy itself to upgrade
     */
    function updateImplementationForMarket(
        IMarket market,
        address newMarketImplementation
    ) public override onlyOwner {
        require(newMarketImplementation != address(0x0), "Invalid newMarketImplementation");

        // Call the proxiable update
        market.updateImplementation(newMarketImplementation);
    }

    /**
     * The owner can create new markets
     */
    function createMarket(
        string calldata _marketName,
        address _collateralToken,
        address _paymentToken,
        IMarket.MarketStyle _marketStyle,
        uint256 _priceRatio,
        uint256 _expirationDate,
        uint16 _exerciseFeeBasisPoints,
        uint16 _closeFeeBasisPoints,
        uint16 _claimFeeBasisPoints,
        address _amm
    ) public override onlyOwner returns (address) {
        require(_collateralToken != address(0x0), "Invalid _collateralToken");
        require(_paymentToken != address(0x0), "Invalid _paymentToken");

        // Verify a market with this name does not exist
        require(
            markets[_marketName] == address(0x0),
            "Market name already registered"
        );

        // Deploy a new proxy pointing at the market impl
        Proxy marketProxy = new Proxy(marketImplementation);
        IMarket newMarket = IMarket(address(marketProxy));

        // Initialize it
        newMarket.initialize(
            _marketName,
            _collateralToken,
            _paymentToken,
            _marketStyle,
            _priceRatio,
            _expirationDate,
            _exerciseFeeBasisPoints,
            _closeFeeBasisPoints,
            _claimFeeBasisPoints,
            tokenImplementation
        );

        // only allow a particular AMM to mint options from this Market
        newMarket.updateRestrictedMinter(address(_amm));

        // Save off the new market
        markets[_marketName] = address(newMarket);

        // Add to list of markets by assets
        bytes32 assetPair = keccak256(abi.encode(address(_collateralToken), address(_paymentToken)));
        marketsByAssets[assetPair].push(address(newMarket));

        // Emit the event
        emit MarketCreated(_marketName, address(newMarket), marketsByAssets[assetPair].length - 1);

        // Return the address of the market that was created
        return address(newMarket);
    }

    /**
     * The owner can create new AMM's for different asset pairs
     */
    function createAmm(
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) public override onlyOwner returns (address) {
        require(address(_priceOracle) != address(0x0), "Invalid _priceOracle");
        require(address(_paymentToken) != address(0x0), "Invalid _paymentToken");
        require(address(_collateralToken) != address(0x0), "Invalid _collateralToken");

        // Verify a amm with this name does not exist
        bytes32 assetPair = keccak256(abi.encode(address(_collateralToken), address(_paymentToken)));

        require(
            amms[assetPair] == address(0x0),
            "AMM name already registered"
        );

        // Deploy a new proxy pointing at the AMM impl
        Proxy ammProxy = new Proxy(ammImplementation);
        InitializeableAmm newAmm = InitializeableAmm(address(ammProxy));

        newAmm.initialize(
            this,
            _priceOracle,
            _paymentToken,
            _collateralToken,
            tokenImplementation,
            _tradeFeeBasisPoints,
            _shouldInvertOraclePrice
        );

        // Set owner to msg.sender
        newAmm.transferOwnership(msg.sender);

        // Save off the new AMM
        amms[assetPair] = address(newAmm);

        // Emit the event
        emit AmmCreated(address(newAmm));

        // Return the address of the AMM that was created
        return address(newAmm);
    }

    /**
     * The owner can destroy a market (only once the market has closed)
     */
    function selfDestructMarket(IMarket market, address payable refundAddress)
        public
        override
        onlyOwner
    {
        require(refundAddress != address(0x0), "Invalid refundAddress");

        // Destroy the market
        market.selfDestructMarket(refundAddress);

        // Emit the event
        emit MarketDestroyed(address(market));
    }

    function addFeeReceiver(
        address _receiver,
        address _secondaryAddress,
        uint8 _vaultPercentage
    ) public onlyOwner {
        require(_receiver != address(0x0), "Invalid fee receiver address");
        require(_secondaryAddress != address(0x0), "Invalid secondary address");
        require(_vaultPercentage <= 100, "Vault percentage must be from 0 to 100");

        feeReceivers[_receiver] = Receiver({
            secondaryAddress: _secondaryAddress,
            vaultPercentage: _vaultPercentage,
            authorized: true
        });
    }

    /**
     * Allow owner to move tokens from the registry
     */
    function recoverTokens(IERC20 token, address destination)
        public
        override
    {
        Receiver memory receiver = feeReceivers[msg.sender];

        require(destination != address(0x0), "Invalid destination");
        require(
            receiver.authorized
            || owner() == msg.sender,
            "Sender address must be an authorized receiver or an owner"
        );
        // Get the balance
        uint256 balance = token.balanceOf(address(this));

        if (msg.sender == owner()) {
            token.safeTransfer(destination, balance);
            emit TokensRecovered(address(token), destination, balance);
            return;
        }

        uint256 vaultShare;
        uint256 secondaryShare;

        if (receiver.vaultPercentage > 0) {
            vaultShare = balance.mul(receiver.vaultPercentage).div(100);

            token.safeTransfer(destination, vaultShare);
            emit TokensRecovered(address(token), destination, vaultShare);
        }

        secondaryShare = balance.sub(vaultShare);
        if (secondaryShare > 0) {
            token.safeTransfer(receiver.secondaryAddress, secondaryShare);
            emit TokensRecovered(address(token), receiver.secondaryAddress, secondaryShare);
        }
    }

    function getMarketsByAssetPair(bytes32 assetPair)
        public
        view
        override
        returns (address[] memory)
    {
        return marketsByAssets[assetPair];
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    constructor(address contractLogic) public {
        // Verify a valid address was passed in
        require(contractLogic != address(0), "Contract Logic cannot be 0x0");

        // save the code address
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, contractLogic)
        }
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(PROXY_MEM_SLOT)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                ptr,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(ptr, 0, retSz)
            switch success
                case 0 {
                    revert(ptr, retSz)
                }
                default {
                    return(ptr, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/** Interface for any Siren SimpleToken
 */
interface ISimpleToken is IERC20 {
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function selfDestructToken(address payable refundAddress) external;
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

