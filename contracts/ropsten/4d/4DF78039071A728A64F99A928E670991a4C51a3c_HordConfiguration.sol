/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity 0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    event MaintainersRegistrySet(address maintainersRegistry);

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "HordUpgradable: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "HordUpgradable: Restricted only to HordCongress");
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    function setMaintainersRegistry(
        address _maintainersRegistry
    )
    external
    onlyHordCongress
    {
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
        emit MaintainersRegistrySet(_maintainersRegistry);
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File contracts/libraries/SafeMath.sol

pragma solidity 0.6.12;


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


// File contracts/HordConfiguration.sol

pragma solidity 0.6.12;



/**
 * HordConfiguration contract.
 * @author Nikola Madjarevic
 * Date created: 4.8.21.
 * Github: madjarevicn
 */
contract HordConfiguration is HordUpgradable, Initializable {
    using SafeMath for *;

    // Representing HORD token address
    address private _hordToken;
    // Stating minimal champion stake in USD in order to launch pool
    uint256 private _minChampStake;
    // Maximal warmup period
    uint256 private _maxWarmupPeriod;
    // Time for followers to stake and reach MIN/MAX follower etf stake
    uint256 private _maxFollowerOnboardPeriod;
    // Minimal ETH stake followers should reach together, in USD
    uint256 private _minFollowerUSDStake;
    // Maximal ETH stake followers should reach together, in USD
    uint256 private _maxFollowerUSDStake;
    // Minimal Stake per pool ticket
    uint256 private _minStakePerPoolTicket;
    // Percent used for purchasing underlying assets
    uint256 private _assetUtilizationRatio;
    // Percent for covering gas fees for hPool operations
    uint256 private _gasUtilizationRatio;
    // Representing % of HORD necessary in every pool
    uint256 private _platformStakeRatio;
    // Representing decimals precision for %, defaults to 100
    uint256 private _percentPrecision;
    // Max supply for hPoolToken
    uint256 private _maxSupplyHPoolToken;
    // Representing maximal USD allocation per ticket
    uint256 private _maxUSDAllocationPerTicket;
    // Total supply for HPoolToken
    uint256 private _totalSupplyHPoolTokens;
    // End time for TICKET_SALE phase
    uint256 private _ticketSaleDurationSecs;
    // End time for PRIVATE_SUBSCRIPTION phase
    uint256 private _privateSubscriptionDurationSecs;
    // End time for PUBLIC_SUBSCRIPTION phase
    uint256 private _publicSubscriptionDurationSecs;
    // Representing % of burnt hord tokens in public subscription phase
    uint256 private _percentBurntFromPublicSubscription;
    // Representing % of champion fee
    uint256 private _championFeePercent;
    // Representing % of protocolFee
    uint256 private _protocolFeePercent;
    // Representing % of lenience
    uint256 private _leniencePercent;

    event ConfigurationChanged(string parameter, uint256 newValue);
    event HordTokenAddressChanged(string parameter, address newValue);

    /**
     * @notice          Initializer function
     */
    function initialize(
        address[] memory addresses,
        uint256[] memory configValues
    ) external initializer {
        // Set hord congress and maintainers registry
        setCongressAndMaintainers(addresses[0], addresses[1]);

        _hordToken = addresses[2];

        _minChampStake = configValues[0];
        _maxWarmupPeriod = configValues[1];
        _maxFollowerOnboardPeriod = configValues[2];
        _minFollowerUSDStake = configValues[3];
        _maxFollowerUSDStake = configValues[4];
        _minStakePerPoolTicket = configValues[5];
        _assetUtilizationRatio = configValues[6];
        _gasUtilizationRatio = configValues[7];
        _platformStakeRatio = configValues[8];
        _maxSupplyHPoolToken = configValues[9];
        _maxUSDAllocationPerTicket = configValues[10];
        _totalSupplyHPoolTokens = configValues[11];
        _ticketSaleDurationSecs = configValues[12];
        _privateSubscriptionDurationSecs = configValues[13];
        _publicSubscriptionDurationSecs = configValues[14];
        _percentBurntFromPublicSubscription = configValues[15];
        _championFeePercent = configValues[16];
        _protocolFeePercent = configValues[17];
        _leniencePercent = configValues[18];

        _percentPrecision = 1000000;
    }

    // Setter Functions
    // _minChampStake setter function
    function setHordTokenAddress(address hordToken_)
    external
    onlyHordCongress
    {
        require(hordToken_ != address(0), "Address can not be 0x0.");
        _hordToken = hordToken_;
        emit HordTokenAddressChanged("_hordToken", _hordToken);
    }

    // _minChampStake setter function
    function setMinChampStake(uint256 minChampStake_)
    external
    onlyHordCongress
    {
        _minChampStake = minChampStake_;
        emit ConfigurationChanged("_minChampStake", _minChampStake);
    }

    // _maxWarmupPeriod setter function
    function setMaxWarmupPeriod(uint256 maxWarmupPeriod_)
    external
    onlyHordCongress
    {
        _maxWarmupPeriod = maxWarmupPeriod_;
        emit ConfigurationChanged("_maxWarmupPeriod", _maxWarmupPeriod);
    }

    // _maxFollowerOnboardPeriod setter function
    function setMaxFollowerOnboardPeriod(uint256 maxFollowerOnboardPeriod_)
    external
    onlyHordCongress
    {
        _maxFollowerOnboardPeriod = maxFollowerOnboardPeriod_;
        emit ConfigurationChanged(
            "_maxFollowerOnboardPeriod",
            _maxFollowerOnboardPeriod
        );
    }

    // _minFollowerUSDStake setter function
    function setMinFollowerUSDStake(uint256 minFollowerUSDStake_)
    external
    onlyHordCongress
    {
        _minFollowerUSDStake = minFollowerUSDStake_;
        emit ConfigurationChanged("_minFollowerUSDStake", _minFollowerUSDStake);
    }

    // _maxFollowerUSDStake setter function
    function setMaxFollowerUSDStake(uint256 maxFollowerUSDStake_)
    external
    onlyHordCongress
    {
        _maxFollowerUSDStake = maxFollowerUSDStake_;
        emit ConfigurationChanged("_maxFollowerUSDStake", _maxFollowerUSDStake);
    }

    // _minStakePerPoolTicket setter function
    function setMinStakePerPoolTicket(uint256 minStakePerPoolTicket_)
    external
    onlyHordCongress
    {
        _minStakePerPoolTicket = minStakePerPoolTicket_;
        emit ConfigurationChanged(
            "_minStakePerPoolTicket",
            _minStakePerPoolTicket
        );
    }

    // _assetUtilizationRatio setter function
    function setAssetUtilizationRatio(uint256 assetUtilizationRatio_)
    external
    onlyHordCongress
    {
        _assetUtilizationRatio = assetUtilizationRatio_;
        emit ConfigurationChanged(
            "_assetUtilizationRatio",
            _assetUtilizationRatio
        );
    }

    // _gasUtilizationRatio setter function
    function setGasUtilizationRatio(uint256 gasUtilizationRatio_)
    external
    onlyHordCongress
    {
        _gasUtilizationRatio = gasUtilizationRatio_;
        emit ConfigurationChanged("_gasUtilizationRatio", _gasUtilizationRatio);
    }

    // _platformStakeRatio setter function
    function setPlatformStakeRatio(uint256 platformStakeRatio_)
    external
    onlyHordCongress
    {
        _platformStakeRatio = platformStakeRatio_;
        emit ConfigurationChanged("_platformStakeRatio", _platformStakeRatio);
    }

    // Set percent precision
    function setPercentPrecision(uint256 percentPrecision_)
    external
    onlyHordCongress
    {
        require(percentPrecision_ > 100, "Minimal precision is 100.");
        _percentPrecision = percentPrecision_;
        emit ConfigurationChanged("_percentPrecision", _percentPrecision);
    }

    // _maxSupplyHPoolToken setter function
    function setMaxSupplyHPoolToken(uint256 maxSupplyHPoolToken_)
    external
    onlyHordCongress
    {
        _maxSupplyHPoolToken = maxSupplyHPoolToken_;
        emit ConfigurationChanged("_maxSupplyHPoolToken", _maxSupplyHPoolToken);
    }

    // set max usd allocation per ticket
    function setMaxUSDAllocationPerTicket(uint256 maxUSDAllocationPerTicket_)
    external
    onlyHordCongress
    {
        _maxUSDAllocationPerTicket = maxUSDAllocationPerTicket_;
        emit ConfigurationChanged(
            "_maxUSDAllocationPerTicket",
            _maxUSDAllocationPerTicket
        );
    }

    // _totalSupplyHPoolTokens setter function
    function setTotalSupplyHPoolTokens(uint256 totalSupplyHPoolTokens_)
    external
    onlyHordCongress
    {
        _totalSupplyHPoolTokens = totalSupplyHPoolTokens_;
        emit ConfigurationChanged("_totalSupplyHPoolTokens", _totalSupplyHPoolTokens);
    }

    // _endTimePublicSubscription setter function
    function setEndTimeTicketSale(uint256 endTimeTicketSale_)
    external
    onlyHordCongress
    {
        _ticketSaleDurationSecs = endTimeTicketSale_;
        emit ConfigurationChanged("_endTimeTicketSale", _ticketSaleDurationSecs);
    }

    // _etEndTimePublicSubscription setter function
    function setEndTimePrivateSubscription(uint256 endTimePrivateSubscription_)
    external
    onlyHordCongress
    {
        _privateSubscriptionDurationSecs = endTimePrivateSubscription_;
        emit ConfigurationChanged("_endTimePrivateSubscription", _privateSubscriptionDurationSecs);
    }

    // _setEndTimePublicSubscription setter function
    function setEndTimePublicSubscription(uint256 endTimePublicSubscription_)
    external
    onlyHordCongress
    {
        _publicSubscriptionDurationSecs = endTimePublicSubscription_;
        emit ConfigurationChanged("_endTimePublicSubscription", _publicSubscriptionDurationSecs);
    }

    //_percentBurntFromPublicSubscription
    function setPercentBurntFromPublicSubscription(uint256 percentBurntFromPublicSubscription_)
    external
    onlyHordCongress
    {
        _percentBurntFromPublicSubscription = percentBurntFromPublicSubscription_;
        emit ConfigurationChanged("_percentBurntFromPublicSubscription", _percentBurntFromPublicSubscription);
    }

    //_championFeePercent
    function setChampionFeePercent(uint256 championFeePercent_)
    external
    onlyHordCongress
    {
        _championFeePercent = championFeePercent_;
        emit ConfigurationChanged("_championFeePercent", _championFeePercent);
    }

    //_protocolFeePercent
    function setProtocolFeePercent(uint256 protocolFeePercent_)
    external
    onlyHordCongress
    {
        _protocolFeePercent = protocolFeePercent_;
        emit ConfigurationChanged("_protocolFeePercent", _protocolFeePercent);
    }

    //_leniencePercent
    function setLeniencePercent(uint256 leniencePercent_)
    external
    onlyHordCongress
    {
        _leniencePercent = leniencePercent_;
        emit ConfigurationChanged("_leniencePercent", _leniencePercent);
    }

    // Getter Functions

    // _hordToken getter function
    function hordToken() external view returns (address) {
        return _hordToken;
    }

    // _minChampStake getter function
    function minChampStake() external view returns (uint256) {
        return _minChampStake;
    }

    // _maxWarmupPeriod getter function
    function maxWarmupPeriod() external view returns (uint256) {
        return _maxWarmupPeriod;
    }

    // _maxFollowerOnboardPeriod getter function
    function maxFollowerOnboardPeriod() external view returns (uint256) {
        return _maxFollowerOnboardPeriod;
    }

    // _minFollowerUSDStake getter function
    function minFollowerUSDStake() external view returns (uint256) {
        return _minFollowerUSDStake;
    }

    // _maxFollowerUSDStake getter function
    function maxFollowerUSDStake() external view returns (uint256) {
        return _maxFollowerUSDStake;
    }

    // _minStakePerPoolTicket getter function
    function minStakePerPoolTicket() external view returns (uint256) {
        return _minStakePerPoolTicket;
    }

    // _assetUtilizationRatio getter function
    function assetUtilizationRatio() external view returns (uint256) {
        return _assetUtilizationRatio;
    }

    // _gasUtilizationRatio getter function
    function gasUtilizationRatio() external view returns (uint256) {
        return _gasUtilizationRatio;
    }

    // _platformStakeRatio getter function
    function platformStakeRatio() external view returns (uint256) {
        return _platformStakeRatio;
    }

    // _percentPrecision getter function
    function percentPrecision() external view returns (uint256) {
        return _percentPrecision;
    }

    // _maxSupplyHPoolToken getter function
    function maxSupplyHPoolToken() external view returns (uint256) {
        return _maxSupplyHPoolToken;
    }

    // _maxUSDAllocationPerTicket getter function
    function maxUSDAllocationPerTicket() external view returns (uint256) {
        return _maxUSDAllocationPerTicket;
    }

    // _totalSupplyHPoolTokens getter function
    function totalSupplyHPoolTokens() external view returns (uint256) {
        return _totalSupplyHPoolTokens;
    }

    // _endTimeTicketSale getter function
    function ticketSaleDurationSecs() external view returns (uint256) {
        return _ticketSaleDurationSecs;
    }

    // _endTimePrivateSubscription getter function
    function privateSubscriptionDurationSecs() external view returns (uint256) {
        return _privateSubscriptionDurationSecs;
    }

    // _endTimePublicSubscription getter function
    function publicSubscriptionDurationSecs() external view returns (uint256) {
        return _publicSubscriptionDurationSecs;
    }


    // _percentBurntFromPublicSubscription getter function
    function percentBurntFromPublicSubscription() external view returns (uint256) {
        return _percentBurntFromPublicSubscription;
    }

    // _championFeePercent getter function
    function championFeePercent() external view returns (uint256) {
        return _championFeePercent;
    }

    // _protocolFeePercent getter function
    function protocolFeePercent() external view returns (uint256) {
        return _protocolFeePercent;
    }

    // _leniencePercent getter function
    function leniencePercent() external view returns (uint256) {
        return _leniencePercent;
    }

    // lenience getter function
    function lenience(uint256 amount) external view returns (uint256) {
        uint256 lenience = amount.mul(_leniencePercent).div(_percentPrecision);
        return lenience;
    }

    // exitFeeAmount getter function
    function exitFeeAmount(uint256 usdAmountWei) external view returns (uint256) {
        return sqrt(usdAmountWei).mul(10**9).div(5);
    }

    /**
    * @notice Function to compute square root of a number
    */
    function sqrt(
        uint256 x
    )
    internal
    pure
    returns (uint256 y)
    {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

}