// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../proxy/Proxy.sol";
import "../proxy/Proxiable.sol";
import "./InitializeableAmm.sol";
import "./IAddSeriesToAmm.sol";
import "../series/ISeriesController.sol";

/// @title AmmFactory
/// @author The Siren Devs
/// @notice Factory contract responsible for AMM creation
contract AmmFactory is OwnableUpgradeable, Proxiable {
    /// @notice Implementation address for the AMM contract - can be upgraded by owner
    address public ammImplementation;

    /// @notice Implementation address for token contracts - can be upgraded by owner
    address public tokenImplementation;

    /// @notice Address of the SeriesController associated with this AmmFactory
    ISeriesController public seriesController;

    /// @notice Mapping of keccak256(abi.encode(address(_underlyingToken), address(_priceToken), address(collateralToken)))
    /// bytes32 keys to AMM (Automated Market Maker) addresses
    /// @dev used to ensure we cannot create AMM's with the same <underlying>-<price>-<collateral> triplet
    mapping(bytes32 => address) public amms;

    /// @notice Emitted when the owner updates the amm implementation address
    event AmmImplementationUpdated(address newAddress);

    /// @notice Emitted when a new AMM is created and initialized
    event AmmCreated(address amm);

    /// @notice Emitted when the owner updates the token implementation address
    event TokenImplementationUpdated(address newAddress);

    /// @notice Setup the state variables for an AmmFactory
    function initialize(
        address _ammImplementation,
        address _tokenImplementation,
        ISeriesController _seriesController
    ) external {
        __AmmFactory_init(
            _ammImplementation,
            _tokenImplementation,
            _seriesController
        );
    }

    /**
     * Initialization function that only allows itself to be called once
     */
    function __AmmFactory_init(
        address _ammImplementation,
        address _tokenImplementation,
        ISeriesController _seriesController
    ) internal initializer {
        // Verify addresses
        require(
            _ammImplementation != address(0x0),
            "Invalid _ammImplementation"
        );
        require(
            _tokenImplementation != address(0x0),
            "Invalid _tokenImplementation"
        );
        require(
            address(_seriesController) != address(0x0),
            "Invalid _seriesController"
        );

        // Save off implementation address
        ammImplementation = _ammImplementation;
        tokenImplementation = _tokenImplementation;
        seriesController = _seriesController;

        // Set up the initialization of the inherited ownable contract
        __Ownable_init();
    }

    /**
     * The owner can update the AMM implementation address that will be used for future AMMs
     */
    function updateAmmImplementation(address newAmmImplementation)
        external
        onlyOwner
    {
        require(
            newAmmImplementation != address(0x0),
            "Invalid newAmmImplementation"
        );

        // Update the address
        ammImplementation = newAmmImplementation;

        // Emit the event
        emit AmmImplementationUpdated(ammImplementation);
    }

    /// @notice The owner can update the token implementation address that will be used for future AMMs
    function updateTokenImplementation(address newTokenImplementation)
        external
        onlyOwner
    {
        require(
            newTokenImplementation != address(0x0),
            "Invalid newTokenImplementation"
        );

        // Update the address
        tokenImplementation = newTokenImplementation;

        // Emit the event
        emit TokenImplementationUpdated(tokenImplementation);
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new AmmFactory implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        require(
            _newImplementation != address(0x0),
            "Invalid _newImplementation"
        );

        _updateCodeAddress(_newImplementation);
    }

    /// @notice Deploy and initializes an AMM
    /// @param _sirenPriceOracle the PriceOracle contract to use for fetching series and settlement prices
    /// @param _underlyingToken The token whose price movements determine the AMM's Series' moneyness
    /// @param _priceToken The token whose units are used for all prices
    /// @param _collateralToken The token used for this AMM's Series' collateral
    /// @param _tradeFeeBasisPoints The fees to charge on option token trades
    function createAmm(
        address _sirenPriceOracle,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        uint16 _tradeFeeBasisPoints
    ) external onlyOwner {
        require(
            address(_sirenPriceOracle) != address(0x0),
            "Invalid _sirenPriceOracle"
        );
        require(
            address(_underlyingToken) != address(0x0),
            "Invalid _underlyingToken"
        );
        require(address(_priceToken) != address(0x0), "Invalid _priceToken");
        require(
            address(_collateralToken) != address(0x0),
            "Invalid _collateralToken"
        );

        // Verify a amm with this name does not exist
        bytes32 assetPair =
            keccak256(
                abi.encode(
                    address(_underlyingToken),
                    address(_priceToken),
                    address(_collateralToken)
                )
            );

        require(amms[assetPair] == address(0x0), "AMM name already registered");

        // Deploy a new proxy pointing at the AMM impl
        Proxy ammProxy = new Proxy(ammImplementation);
        InitializeableAmm newAmm = InitializeableAmm(address(ammProxy));

        newAmm.initialize(
            seriesController,
            _sirenPriceOracle,
            _underlyingToken,
            _priceToken,
            _collateralToken,
            tokenImplementation,
            _tradeFeeBasisPoints
        );

        // Set owner to msg.sender
        OwnableUpgradeable(address(newAmm)).transferOwnership(msg.sender);

        // Save off the new AMM, this way we don't accidentally create an AMM with a duplicate
        // <underlying>-<price>-<collateral> triplet
        amms[assetPair] = address(newAmm);

        // Emit the event
        emit AmmCreated(address(newAmm));
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

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

pragma solidity 0.8.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

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

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../series/ISeriesController.sol";

interface InitializeableAmm {
    function initialize(
        ISeriesController _seriesController,
        address _priceOracle,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IAddSeriesToAmm {
    function addSeries(uint64 _seriesId) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/**
 @title ISeriesController
 @author The Siren Devs
 @notice Onchain options protocol for minting, exercising, and claiming calls and puts
 @notice Manages the lifecycle of individual Series
 @dev The id's for bTokens and wTokens on the same Series are consecutive uints
 */
interface ISeriesController {
    /// @notice The basis points to use for fees on the various SeriesController functions,
    /// in units of basis points (1 basis point = 0.01%)
    struct Fees {
        address feeReceiver;
        uint16 exerciseFeeBasisPoints;
        uint16 closeFeeBasisPoints;
        uint16 claimFeeBasisPoints;
    }

    struct Tokens {
        address underlyingToken;
        address priceToken;
        address collateralToken;
    }

    /// @notice All data pertaining to an individual series
    struct Series {
        uint40 expirationDate;
        bool isPutOption;
        ISeriesController.Tokens tokens;
        uint256 strikePrice;
    }

    /// @notice All possible states a Series can be in with regard to its expiration date
    enum SeriesState {
        /**
         * New option token cans be created.
         * Existing positions can be closed.
         * bTokens cannot be exercised
         * wTokens cannot be claimed
         */
        OPEN,
        /**
         * No new options can be created
         * Positions cannot be closed
         * bTokens can be exercised
         * wTokens can be claimed
         */
        EXPIRED
    }

    /** Enum to track Fee Events */
    enum FeeType {EXERCISE_FEE, CLOSE_FEE, CLAIM_FEE}

    ///////////////////// EVENTS /////////////////////

    /// @notice Emitted when the owner creates a new series
    event SeriesCreated(
        uint64 seriesId,
        Tokens tokens,
        address[] restrictedMinters,
        uint256 strikePrice,
        uint40 expirationDate,
        bool isPutOption
    );

    /// @notice Emitted when the SeriesController gets initialized
    event SeriesControllerInitialized(
        address priceOracle,
        address vault,
        address erc1155Controller,
        Fees fees
    );

    /// @notice Emitted when SeriesController.mintOptions is called, and wToken + bToken are minted
    event OptionMinted(
        address minter,
        uint64 seriesId,
        uint256 optionTokenAmount
    );

    /// @notice Emitted when either the SeriesController transfers ERC20 funds to the SeriesVault,
    /// or the SeriesController transfers funds from the SeriesVault to a recipient
    event ERC20VaultTransferIn(address sender, uint64 seriesId, uint256 amount);
    event ERC20VaultTransferOut(
        address recipient,
        uint64 seriesId,
        uint256 amount
    );

    event FeePaid(
        FeeType indexed feeType,
        address indexed token,
        uint256 value
    );

    /** Emitted when a bToken is exercised for collateral */
    event OptionExercised(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 collateralAmount
    );

    /** Emitted when a wToken is redeemed after expiration */
    event CollateralClaimed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 collateralAmount
    );

    /** Emitted when an equal amount of wToken and bToken is redeemed for original collateral */
    event OptionClosed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 collateralAmount
    );

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    function priceDecimals() external view returns (uint8);

    function erc1155Controller() external view returns (address);

    function series(uint256 seriesId)
        external
        view
        returns (ISeriesController.Series memory);

    function state(uint64 _seriesId) external view returns (SeriesState);

    function calculateFee(uint256 _amount, uint16 _basisPoints)
        external
        pure
        returns (uint256);

    function getExerciseAmount(uint64 _seriesId, uint256 _bTokenAmount)
        external
        view
        returns (uint256, uint256);

    function getClaimAmount(uint64 _seriesId, uint256 _wTokenAmount)
        external
        view
        returns (uint256, uint256);

    function seriesName(uint64 _seriesId) external view returns (string memory);

    function strikePrice(uint64 _seriesId) external view returns (uint256);

    function expirationDate(uint64 _seriesId) external view returns (uint40);

    function underlyingToken(uint64 _seriesId) external view returns (address);

    function priceToken(uint64 _seriesId) external view returns (address);

    function collateralToken(uint64 _seriesId) external view returns (address);

    function exerciseFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function closeFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function claimFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function wTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function bTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function isPutOption(uint64 _seriesId) external view returns (bool);

    function getCollateralPerOptionToken(
        uint64 _seriesId,
        uint256 _optionTokenAmount
    ) external view returns (uint256);

    /// @notice Returns the amount of collateralToken held in the vault on behalf of the Series at _seriesId
    /// @param _seriesId The index of the Series in the SeriesController
    function getSeriesERC20Balance(uint64 _seriesId)
        external
        view
        returns (uint256);

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    function mintOptions(uint64 _seriesId, uint256 _optionTokenAmount) external;

    function exerciseOption(
        uint64 _seriesId,
        uint256 _bTokenAmount,
        bool _revertOtm
    ) external;

    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount) external;

    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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