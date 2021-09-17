/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;


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

// File: @openzeppelin/contracts/math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IERC20Detailed.sol

pragma solidity 0.6.12;


interface IERC20Detailed is IERC20 {
  function decimals() external view returns (uint256);
}

// File: contracts/interfaces/IdleToken.sol

pragma solidity 0.6.12;

interface IdleToken {
  function totalSupply() external view returns (uint256);
  function tokenPrice() external view returns (uint256 price);
  function token() external view returns (address);
  function getAvgAPR() external view returns (uint256 apr);
  function balanceOf(address) external view returns (uint256 apr);
  function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);
  function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);
  function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
  function redeemInterestBearingTokens(uint256 _amount) external;
  function rebalance() external returns (bool);
}

// File: contracts/interfaces/CERC20.sol

pragma solidity 0.6.12;

interface CERC20 {
  function comptroller() external view returns (address);
  function exchangeRateStored() external view returns (uint256);
}

// File: contracts/interfaces/AToken.sol

pragma solidity 0.6.12;

interface AToken {
  function getIncentivesController() external view returns (address);
  function redeem(uint256 amount) external;
  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;
}

// File: contracts/interfaces/Comptroller.sol

pragma solidity 0.6.12;

interface Comptroller {
  function claimComp(address) external;
  function compSpeeds(address _cToken) external view returns (uint256);
  function claimComp(address[] calldata holders, address[] calldata cTokens, bool borrowers, bool suppliers) external;
}

// File: contracts/interfaces/ChainLinkOracle.sol

pragma solidity 0.6.12;

interface ChainLinkOracle {
  function latestAnswer() external view returns (uint256);
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

// File: contracts/interfaces/IAaveIncentivesController.sol

pragma solidity 0.6.12;
interface IAaveIncentivesController {
  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);
  function getAssetData(address asset) external view returns (uint256, uint256, uint256);
}

// File: contracts/PriceOracleV3.sol

pragma solidity 0.6.12;











contract PriceOracleV3 is OwnableUpgradeable {
  using SafeMath for uint256;

  uint256 constant private ONE_18 = 10**18;
  address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant public COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
  address constant public WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address constant public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant public SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
  address constant public TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
  address constant public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant public stkAAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
  address constant public RAI = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;
  address constant public FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

  uint256 public blocksPerYear;
  uint256 public constant secondsPerYear = 31536000;

  // underlying -> chainlink feed see https://docs.chain.link/docs/reference-contracts
  mapping (address => address) public priceFeedsUSD;
  mapping (address => address) public priceFeedsETH;

  function initialize() public initializer {
    __Ownable_init();

    blocksPerYear = 2371428; // -> blocks per year with ~13.3s block time

    // USD feeds
    priceFeedsUSD[WETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
    priceFeedsUSD[COMP] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5; // COMP
    priceFeedsUSD[WBTC] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // wBTC
    priceFeedsUSD[DAI] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9; // DAI
    priceFeedsUSD[stkAAVE] = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9; // AAVE
    priceFeedsUSD[FEI] = 0x31e0a88fecB6eC0a411DBe0e9E76391498296EE9; // FEI

    // ETH feeds
    priceFeedsETH[WBTC] = 0xdeb288F737066589598e9214E782fa5A8eD689e8; // wBTC
    priceFeedsETH[DAI] = 0x773616E4d11A78F511299002da57A0a94577F1f4; // DAI
    priceFeedsETH[SUSD] = 0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757; // SUSD
    priceFeedsETH[TUSD] = 0x3886BA987236181D98F2401c507Fb8BeA7871dF2; // TUSD
    priceFeedsETH[USDC] = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4; // USDC
    priceFeedsETH[USDT] = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46; // USDT
    priceFeedsETH[stkAAVE] = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012; // AAVE
    priceFeedsETH[RAI] = 0x4ad7B025127e89263242aB68F0f9c4E5C033B489; // RAI
    priceFeedsETH[FEI] = 0x7F0D2c2838c6AC24443d13e23d99490017bDe370; // FEI
    priceFeedsETH[COMP] = 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699; // COMP
  }

  /// @notice get price in USD for an asset
  function getPriceUSD(address _asset) public view returns (uint256) {
    return _getPriceUSD(_asset); // 1e18
  }
  /// @notice get price in ETH for an asset
  function getPriceETH(address _asset) public view returns (uint256) {
    return _getPriceETH(_asset); // 1e18
  }
  /// @notice get price in a specific token for an asset
  function getPriceToken(address _asset, address _token) public view returns (uint256) {
    return _getPriceToken(_asset, _token); // 1e(_token.decimals())
  }
  /// @notice get price for the underlying token of an idleToken
  function getUnderlyingPrice(address _idleToken) external view returns (uint256) {
    return getPriceUSD(IdleToken(_idleToken).token()); // 1e18
  }
  /// @notice get COMP additional apr for a specific cToken market
  function getCompApr(address _cToken, address _token) external view returns (uint256) {
    CERC20 _ctoken = CERC20(_cToken);
    uint256 compSpeeds = Comptroller(_ctoken.comptroller()).compSpeeds(_cToken);
    uint256 cTokenNAV = _ctoken.exchangeRateStored().mul(IERC20Detailed(_cToken).totalSupply()).div(ONE_18);
    // how much costs 1COMP in token (1e(_token.decimals()))
    uint256 compUnderlyingPrice = getPriceToken(COMP, _token);
    // mul(100) needed to have a result in the format 4.4e18
    return compSpeeds.mul(compUnderlyingPrice).mul(blocksPerYear).mul(100).div(cTokenNAV);
  }

  /// @notice get AAVE additional apr for a specific aToken market
  function getStkAaveApr(address _aToken, address _token) external view returns (uint256) {
    IAaveIncentivesController _ctrl = IAaveIncentivesController(AToken(_aToken).getIncentivesController());
    (,uint256 aavePerSec,) = _ctrl.getAssetData(_aToken);
    uint256 aTokenNAV = IERC20Detailed(_aToken).totalSupply();
    // how much costs 1AAVE in token (1e(_token.decimals()))
    uint256 aaveUnderlyingPrice = getPriceToken(stkAAVE, _token);
    // mul(100) needed to have a result in the format 4.4e18
    return aavePerSec.mul(aaveUnderlyingPrice).mul(secondsPerYear).mul(100).div(aTokenNAV);
  }

  // #### internal
  function _getPriceUSD(address _asset) internal view returns (uint256 price) {
    if (priceFeedsUSD[_asset] != address(0)) {
      price = _getLatestPrice(priceFeedsUSD[_asset]).mul(10**10); // scale it to 1e18
    } else if (priceFeedsETH[_asset] != address(0)) {
      price = _getLatestPrice(priceFeedsETH[_asset]);
      price = price.mul(_getLatestPrice(priceFeedsUSD[WETH]).mul(10**10)).div(ONE_18);
    }
  }
  function _getPriceETH(address _asset) internal view returns (uint256 price) {
    if (priceFeedsETH[_asset] != address(0)) {
      price = _getLatestPrice(priceFeedsETH[_asset]);
    }
  }
  function _getPriceToken(address _asset, address _token) internal view returns (uint256 price) {
    uint256 assetUSD = getPriceUSD(_asset);
    uint256 tokenUSD = getPriceUSD(_token);
    if (tokenUSD == 0) {
      return price;
    }
    return assetUSD.mul(10**(uint256(IERC20Detailed(_token).decimals()))).div(tokenUSD); // 1e(tokenDecimals)
  }

  // #### onlyOwner
  function setBlocksPerYear(uint256 _blocksPerYear) external onlyOwner {
    blocksPerYear = _blocksPerYear;
  }
  // _feed can be address(0) which means disabled
  function updateFeedETH(address _asset, address _feed) external onlyOwner {
    priceFeedsETH[_asset] = _feed;
  }
  function updateFeedUSD(address _asset, address _feed) external onlyOwner {
    priceFeedsUSD[_asset] = _feed;
  }

  function _getLatestPrice(address _priceFeed) internal view returns (uint256) {
    (,int price,,,) = ChainLinkOracle(_priceFeed).latestRoundData();
    return uint256(price);
  }

}