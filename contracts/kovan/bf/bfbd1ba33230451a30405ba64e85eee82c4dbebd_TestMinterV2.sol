/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org
// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity =0.8.9;

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// File contracts/interfaces/ILiquidityBasedTWAP.sol

interface ILiquidityBasedTWAP {
    function maxUpdateWindow() external view returns (uint256);

    function getVaderPrice() external returns (uint256);
}

// File contracts/VaderMinterStorage.sol

struct Limits {
    uint256 fee;
    uint256 mintLimit;
    uint256 burnLimit;
    uint256 lockDuration;
}

contract VaderMinterStorage {
    // The LBT pricing mechanism for the conversion
    ILiquidityBasedTWAP public lbt;

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    Limits public dailyLimits;

    // The current cycle end timestamp
    uint256 public cycleTimestamp;

    // The current cycle cumulative mints
    uint256 public cycleMints;

    // The current cycle cumulative burns
    uint256 public cycleBurns;

    // The limits applied to each partner
    mapping(address => Limits) public partnerLimits;

    // Transmuter Contract
    address public transmuter;
}

// File contracts/interfaces/IVaderMinterUpgradeable.sol

interface IVaderMinterUpgradeable {
    /* ========== FUNCTIONS ========== */
    function mint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount);

    function burn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount);

    function partnerMint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount);

    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount);

    /* ========== EVENTS ========== */

    event DailyLimitsChanged(Limits previousLimits, Limits nextLimits);
    event WhitelistPartner(
        address partner,
        uint256 mintLimit,
        uint256 burnLimit,
        uint256 fee
    );
    event RemovePartner(address partner);
    event SetPartnerFee(address indexed partner, uint256 fee);
    event IncreasePartnerMintLimit(address indexed partner, uint256 mintLimit);
    event DecreasePartnerMintLimit(address indexed partner, uint256 mintLimit);
    event IncreasePartnerBurnLimit(address indexed partner, uint256 burnLimit);
    event DecreasePartnerBurnLimit(address indexed partner, uint256 burnLimit);
    event SetPartnerLockDuration(address indexed partner, uint256 lockDuration);
}

// File contracts/interfaces/IUSDV.sol

interface IUSDV {
    /* ========== ENUMS ========== */

    enum LockTypes {
        USDV,
        VADER
    }

    /* ========== STRUCTS ========== */

    struct Lock {
        LockTypes token;
        uint256 amount;
        uint256 release;
    }

    /* ========== FUNCTIONS ========== */

    function mint(
        address account,
        uint256 vAmount,
        uint256 uAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    function burn(
        address account,
        uint256 uAmount,
        uint256 vAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    /* ========== EVENTS ========== */

    event ExchangeFeeChanged(uint256 previousExchangeFee, uint256 exchangeFee);
    event DailyLimitChanged(uint256 previousDailyLimit, uint256 dailyLimit);
    event LockClaimed(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event LockCreated(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event ValidatorSet(address previous, address current);
    event GuardianSet(address previous, address current);
    event LockStatusSet(bool status);
    event MinterSet(address minter);
}

// File contracts/ProtocolConstants.sol

abstract contract ProtocolConstants {
    /* ========== GENERAL ========== */

    // The zero address, utility
    address internal constant _ZERO_ADDRESS = address(0);

    // One year, utility
    uint256 internal constant _ONE_YEAR = 365 days;

    // Basis Points
    uint256 internal constant _MAX_BASIS_POINTS = 100_00;

    /* ========== VADER TOKEN ========== */

    // Max VADER supply
    uint256 internal constant _INITIAL_VADER_SUPPLY = 25_000_000_000 * 1 ether;

    // Allocation for VETH holders
    uint256 internal constant _VETH_ALLOCATION = 7_500_000_000 * 1 ether;

    // Team allocation vested over {VESTING_DURATION} years
    uint256 internal constant _TEAM_ALLOCATION = 2_500_000_000 * 1 ether;

    // Ecosystem growth fund unlocked for partnerships & USDV provision
    uint256 internal constant _ECOSYSTEM_GROWTH = 2_500_000_000 * 1 ether;

    // Total grant tokens
    uint256 internal constant _GRANT_ALLOCATION = 12_500_000_000 * 1 ether;

    // Emission Era
    uint256 internal constant _EMISSION_ERA = 24 hours;

    // Initial Emission Curve, 5
    uint256 internal constant _INITIAL_EMISSION_CURVE = 5;

    // Fee Basis Points
    uint256 internal constant _MAX_FEE_BASIS_POINTS = 1_00;

    /* ========== USDV TOKEN ========== */

    // Max locking duration
    uint256 internal constant _MAX_LOCK_DURATION = 30 days;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 internal constant _VESTING_DURATION = 2 * _ONE_YEAR;

    /* ========== CONVERTER ========== */

    // Vader -> Vether Conversion Rate (10000:1)
    uint256 internal constant _VADER_VETHER_CONVERSION_RATE = 10_000;

    // Burn Address
    address internal constant _BURN =
        0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    /* ========== GAS QUEUE ========== */

    // Address of Chainlink Fast Gas Price Oracle
    address internal constant _FAST_GAS_ORACLE =
        0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /* ========== VADER RESERVE ========== */

    // Minimum delay between grants
    uint256 internal constant _GRANT_DELAY = 30 days;

    // Maximum grant size divisor
    uint256 internal constant _MAX_GRANT_BASIS_POINTS = 10_00;
}

// File contracts/test/TestMinterV2.sol

contract TestMinterV2 is
    VaderMinterStorage,
    IVaderMinterUpgradeable,
    ProtocolConstants,
    OwnableUpgradeable
{
    // USDV Contract for Mint / Burn Operations
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IUSDV public immutable usdv;

    // Test upgrade
    uint256 public version;

    function test() external {
        version = 2;
    }

    /* ========== CONSTRUCTOR ========== */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _usdv) initializer {
        require(_usdv != address(0), "usdv = zero address");
        usdv = IUSDV(_usdv);
    }

    /* ========== VIEWS ========== */

    function getPublicFee() public view returns (uint256) {
        // 24 hours passed, reset fee to 100%
        if (block.timestamp >= cycleTimestamp) {
            return dailyLimits.fee;
        }

        // cycle timestamp > block.timestamp, fee < 100%
        return
            (dailyLimits.fee * (cycleTimestamp - block.timestamp)) / 24 hours;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /*
     * @dev Public mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @param uAmountMinOut USDV minimum amount to get back from the mint.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     **/
    function mint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount)
    {
        uint256 vPrice = lbt.getVaderPrice();

        uAmount = (vPrice * vAmount) / 1e18;

        if (cycleTimestamp <= block.timestamp) {
            cycleTimestamp = block.timestamp + 24 hours;
            cycleMints = uAmount;
        } else {
            cycleMints += uAmount;
        }

        require(
            cycleMints <= dailyLimits.mintLimit,
            "VMU::mint: 24 Hour Limit Reached"
        );

        // Actual amount of USDV minted including fees
        uAmount = usdv.mint(
            msg.sender,
            vAmount,
            uAmount,
            getPublicFee(),
            dailyLimits.lockDuration
        );

        require(
            uAmount >= uAmountMinOut,
            "VMU::mint: Insufficient Trade Output"
        );

        return uAmount;
    }

    /*
     * @dev Public burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @param vAmountMinOut Vader minimum amount to get back from the burn.
     * @returns vAmount in Vader, represents the Vader amount received from the burn.
     *
     **/
    function burn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount)
    {
        uint256 vPrice = lbt.getVaderPrice();

        vAmount = (1e18 * uAmount) / vPrice;

        if (cycleTimestamp <= block.timestamp) {
            cycleTimestamp = block.timestamp + 24 hours;
            cycleBurns = uAmount;
        } else {
            cycleBurns += uAmount;
        }

        require(
            cycleBurns <= dailyLimits.burnLimit,
            "VMU::burn: 24 Hour Limit Reached"
        );

        // Actual amount of Vader minted including fees
        vAmount = usdv.burn(
            msg.sender,
            uAmount,
            vAmount,
            getPublicFee(),
            dailyLimits.lockDuration
        );

        require(
            vAmount >= vAmountMinOut,
            "VMU::burn: Insufficient Trade Output"
        );

        return vAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /*
     * @dev Partner mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @param uAmountMinOut USDV minimum amount to get back from the mint.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerMint(uint256 vAmount, uint256 uAmountMinOut)
        external
        returns (uint256 uAmount)
    {
        require(
            partnerLimits[msg.sender].mintLimit != 0,
            "VMU::partnerMint: Not Whitelisted"
        );
        uint256 vPrice = lbt.getVaderPrice();

        uAmount = (vPrice * vAmount) / 1e18;

        Limits storage _partnerLimits = partnerLimits[msg.sender];

        require(
            uAmount <= _partnerLimits.mintLimit,
            "VMU::partnerMint: Mint Limit Reached"
        );

        unchecked {
            _partnerLimits.mintLimit -= uAmount;
        }

        uAmount = usdv.mint(
            msg.sender,
            vAmount,
            uAmount,
            _partnerLimits.fee,
            _partnerLimits.lockDuration
        );

        require(
            uAmount >= uAmountMinOut,
            "VMU::partnerMint: Insufficient Trade Output"
        );

        return uAmount;
    }

    /*
     * @dev Partner burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @param vAmountMinOut Vader minimum amount to get back from the burn.
     * @returns vAmount in Vader, represents the Vader amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut)
        external
        returns (uint256 vAmount)
    {
        require(
            partnerLimits[msg.sender].burnLimit != 0,
            "VMU::partnerBurn: Not Whitelisted"
        );
        uint256 vPrice = lbt.getVaderPrice();

        vAmount = (1e18 * uAmount) / vPrice;

        Limits storage _partnerLimits = partnerLimits[msg.sender];

        require(
            vAmount <= _partnerLimits.burnLimit,
            "VMU::partnerBurn: Burn Limit Reached"
        );

        unchecked {
            _partnerLimits.burnLimit -= vAmount;
        }

        vAmount = usdv.burn(
            msg.sender,
            uAmount,
            vAmount,
            _partnerLimits.fee,
            _partnerLimits.lockDuration
        );

        require(
            vAmount >= vAmountMinOut,
            "VMU::partnerBurn: Insufficient Trade Output"
        );

        return vAmount;
    }

    /*
     * @dev Sets the daily limits for public mints represented by the param {_dailyMintLimit}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     * - Param {_mintLimit} mint limit can be 0.
     * - Param {_burnLimit} burn limit can be 0.
     * - Param {_lockDuration} lock duration can be 0.
     **/
    function setDailyLimits(
        uint256 _fee,
        uint256 _mintLimit,
        uint256 _burnLimit,
        uint256 _lockDuration
    ) external onlyOwner {
        require(_fee <= _MAX_BASIS_POINTS, "VMU::setDailyLimits: Invalid Fee");
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::setDailyLimits: Invalid lock duration"
        );

        Limits memory _dailyLimits = Limits({
            fee: _fee,
            mintLimit: _mintLimit,
            burnLimit: _burnLimit,
            lockDuration: _lockDuration
        });

        emit DailyLimitsChanged(dailyLimits, _dailyLimits);
        dailyLimits = _dailyLimits;
    }

    /*
     * @dev Sets the a partner address {_partner }  to a given limit {_limits} that represents the ability
     * to mint USDV from the reserve partners minting allocation.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_partner} cannot be a zero address.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     * - Param {_mintLimit} mint limits can be 0.
     * - Param {_burnLimit} burn limits can be 0.
     * - Param {_lockDuration} lock duration can be 0.
     **/
    function whitelistPartner(
        address _partner,
        uint256 _fee,
        uint256 _mintLimit,
        uint256 _burnLimit,
        uint256 _lockDuration
    ) external onlyOwner {
        require(_partner != address(0), "VMU::whitelistPartner: Zero Address");
        require(
            _fee <= _MAX_BASIS_POINTS,
            "VMU::whitelistPartner: Invalid Fee"
        );
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::whitelistPartner: Invalid lock duration"
        );

        emit WhitelistPartner(_partner, _mintLimit, _burnLimit, _fee);
        partnerLimits[_partner] = Limits({
            fee: _fee,
            mintLimit: _mintLimit,
            burnLimit: _burnLimit,
            lockDuration: _lockDuration
        });
    }

    /*
     * @dev Remove partner
     * @param _partner Address of partner.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function removePartner(address _partner) external onlyOwner {
        delete partnerLimits[_partner];
        emit RemovePartner(_partner);
    }

    /*
     * @dev Set partner fee
     * @param _partner Address of partner.
     * @param _fee New fee.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_fee} fee can not be bigger than _MAX_BASIS_POINTS.
     **/
    function setPartnerFee(address _partner, uint256 _fee) external onlyOwner {
        require(_fee <= _MAX_BASIS_POINTS, "VMU::setPartnerFee: Invalid Fee");
        partnerLimits[_partner].fee = _fee;
        emit SetPartnerFee(_partner, _fee);
    }

    /*
     * @dev Increase partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to increase the mint limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function increasePartnerMintLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.mintLimit += _amount;
        emit IncreasePartnerMintLimit(_partner, limits.mintLimit);
    }

    /*
     * @dev Decrease partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to decrease the mint limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function decreasePartnerMintLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.mintLimit -= _amount;
        emit DecreasePartnerMintLimit(_partner, limits.mintLimit);
    }

    /*
     * @dev Increase partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to increase the burn limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function increasePartnerBurnLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.burnLimit += _amount;
        emit IncreasePartnerBurnLimit(_partner, limits.burnLimit);
    }

    /*
     * @dev Decrease partner mint limit.
     * @param _partner Address of partner.
     * @param _amount Amount to decrease the burn limit by.
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function decreasePartnerBurnLimit(address _partner, uint256 _amount)
        external
        onlyOwner
    {
        Limits storage limits = partnerLimits[_partner];
        limits.burnLimit -= _amount;
        emit DecreasePartnerBurnLimit(_partner, limits.burnLimit);
    }

    /*
     * @dev Set partner lock duration.
     * @param _partner Address of partner.
     * @param _lockDuration New lock duration
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_lockDuration} cannot be bigger than _MAX_LOCK_DURATION
     **/
    function setPartnerLockDuration(address _partner, uint256 _lockDuration)
        external
        onlyOwner
    {
        require(
            _lockDuration <= _MAX_LOCK_DURATION,
            "VMU::setPartnerLockDuration: Invalid lock duration"
        );
        partnerLimits[_partner].lockDuration = _lockDuration;
        emit SetPartnerLockDuration(_partner, _lockDuration);
    }

    /*
     * @dev Sets the transmuter contract address represented by the param {_transmuter}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_transmuter} can not be address ZERO.
     **/
    function setTransmuterAddress(address _transmuter) external onlyOwner {
        require(
            _transmuter != address(0),
            "VMU::setTransmuterAddress: Zero Address"
        );
        transmuter = _transmuter;
    }

    /*
     * @dev Sets the lbt contract address represented by the param {_lbt}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_lbt} can not be address ZERO.
     **/
    function setLBT(ILiquidityBasedTWAP _lbt) external onlyOwner {
        require(
            _lbt != ILiquidityBasedTWAP(address(0)),
            "VMU::setLBT: Insufficient Privileges"
        );
        lbt = _lbt;
    }
}