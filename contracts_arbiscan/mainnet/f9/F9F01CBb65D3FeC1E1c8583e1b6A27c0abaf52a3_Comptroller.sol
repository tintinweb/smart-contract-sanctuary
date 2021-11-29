// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/IMarket.sol";

/// @title Comptroller Hub Contract
/// @notice Handles the different collateral markets and integrates them with the Liquidity Pool
/// @dev Upgradeable Smart Contract
contract Comptroller is Initializable, OwnableUpgradeable, IComptroller {
    using SafeMath for uint256;

    address public liquidityPool;
    /// @notice Markets registered into this Comptroller
    address[] public markets;
    mapping(address => bool) public isMarket;
    mapping(address => address[]) public borrowerToMarkets;

    uint256 private constant RATIOS = 1e16;
    uint256 private constant FACTOR = 1e18;

    /// @notice Emit new market event
    event AddMarket(address indexed market);
    /// @notice Emit remove market event
    event RemoveMarket(address indexed market);
    /// @notice Emit reset market event
    event ResetMarket();
    /// @notice Emit liquidityPool update event
    event UpdateLiquidityPool(address indexed liquidityPool);

    /// @dev  Helps to perform actions meant to be executed by the Liquidity Pool itself
    modifier onlyLiquidityPool() {
        require(msg.sender == liquidityPool, "Not liquidity pool");
        _;
    }

    modifier onlyMarkets() {
        require(isMarket[msg.sender], "Only markets are allowed to perform this action");
        _;
    }

    /// @notice Upgradeable smart contract constructor
    /// @dev Initializes this comptroller
    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice Allows the owner to add a new market into the protocol
    /// @param _market (address) Market's address
    function addMarket(address _market) external override onlyOwner {
        require(_market != address(0), "Market shouldn't be zero address");
        require(isMarket[_market] == false, "This market has already added");

        markets.push(_market);
        isMarket[_market] = true;
        emit AddMarket(_market);
    }

    /// @notice Owners can set the Liquidity Pool Address
    /// @param _liquidityPool (address) Liquidity Pool's address
    function setLiquidityPool(address _liquidityPool) external override onlyOwner {
        liquidityPool = _liquidityPool;
        emit UpdateLiquidityPool(_liquidityPool);
    }

    /// @notice Anyone can know how much a borrower can borrow from the Liquidity Pool in USDC terms
    /// @dev Despite the borrower can borrow 100% of this amount, it is recommended to borrow up to 80% to avoid risk of being liquidated
    /// @dev The return value has 18 decimals
    /// @param _borrower (address) Borrower's address
    /// @return capacity (uint256) How much USDC the borrower can borrow from the Liquidity Pool
    function borrowingCapacity(address _borrower) public view override returns (uint256) {
        uint256 capacity = 0;
        address[] memory usedMarkets = borrowerToMarkets[_borrower];
        for (uint256 i = 0; i < usedMarkets.length; i++) {
            if (isMarket[usedMarkets[i]]) {
                capacity = capacity.add(IMarket(usedMarkets[i]).borrowingLimit(_borrower));
            }
        }
        return capacity;
    }

    /// @notice When the collateralize function in Market contract called first time for a user, the market is added to the usedMarket cache
    /// @dev We don't check if the market is duplicated here since when it's only called on the first collaterization
    /// @param _borrower (address) Borrower's address
    /// @param _market (address) Market address
    function addBorrowerMarket(address _borrower, address _market) external override onlyMarkets {
        address[] storage usedMarkets = borrowerToMarkets[_borrower];
        usedMarkets.push(_market);
    }

    /// @notice When user withdraw all the collateral from the market, the market is removed from the usedMarkets cache
    /// @param _borrower (address) Borrower's address
    /// @param _market (address) Market address
    function removeBorrowerMarket(address _borrower, address _market) external override onlyMarkets {
        address[] storage usedMarkets = borrowerToMarkets[_borrower];
        uint256 index = 0;
        for (; index < usedMarkets.length; index++) {
            if (usedMarkets[index] == _market) {
                break;
            }
        }
        uint256 lastIndex = usedMarkets.length - 1;
        usedMarkets[index] = usedMarkets[lastIndex];
        usedMarkets.pop();
    }

    /// @notice Tells how healthy a borrow is
    /// @dev If there is no current borrow 1e18 can be understood as infinite. Healt Ratios greater or equal to 100 are good. Below 100, indicates a borrow can be liquidated
    /// @param _borrower (address) Borrower's address
    /// @return  (uint256) Health Ratio Ex 102 can be understood as 102% or 1.02
    function getHealthRatio(address _borrower) external view override returns (uint256) {
        uint256 currentBorrow = ILiquidityPool(liquidityPool).updatedBorrowBy(_borrower);
        if (currentBorrow == 0) return FACTOR;
        else return borrowingCapacity(_borrower).mul(1e2).div(currentBorrow);
    }

    /// @notice Sends as much collateral as needed to a liquidator that covered a debt on behalf of a borrower
    /// @dev This algorithm decides first on more stable markets (i.e. higher collateral factors), then on more volatile markets, till the amount paid by the liquidator is covered
    /// @dev The amount sent to be covered might not be covered at all. The execution ends on either amount covered or all markets processed
    /// @dev USDC here has nothing to do with the decimals the actual USDC smart contract has. Since it's a market, always assume 18 decimals
    /// @dev This function has a high gas consumption. In any case prefer to use sendCollateralToLiquidatorWithPreference. Use this one on extreme cases.
    /// @param _liquidator (address) Liquidator's address
    /// @param _borrower (address) Borrower's address
    /// @param _amount (uint256) Amount paid by the Liquidator in USDC terms at Liquidity Pool's side
    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external override onlyLiquidityPool {
        address[] memory localMarkets = markets;
        uint256[] memory borrowingLimits = new uint256[](localMarkets.length);
        uint256[] memory collateralFactors = new uint256[](localMarkets.length);
        uint256 marketsProcessed;

        for (uint256 i = 0; i < localMarkets.length; i++) {
            borrowingLimits[i] = IMarket(localMarkets[i]).borrowingLimit(_borrower);
            collateralFactors[i] = IMarket(localMarkets[i]).getCollateralFactor();
        }

        while (_amount > 0 && marketsProcessed < localMarkets.length) {
            uint256 maxIndex = 0;
            uint256 maxCollateral = 0;
            for (uint256 i = 0; i < localMarkets.length; i++) {
                if (localMarkets[i] != address(0) && borrowingLimits[i] > 0 && collateralFactors[i] > maxCollateral) {
                    maxCollateral = collateralFactors[i];
                    maxIndex = i;
                }
            }

            // in case of all markets has gone through already except the first market, and it has zero borrowing limit
            // maxIndex & maxCollateral keeps zero
            if (maxCollateral > 0) {
                uint256 borrowingLimit = borrowingLimits[maxIndex];
                uint256 collateralFactor = maxCollateral.mul(RATIOS);
                delete localMarkets[maxIndex];
                uint256 collateral = borrowingLimit.mul(FACTOR).div(collateralFactor);
                uint256 toPay = (_amount >= collateral) ? collateral : _amount;
                _amount = _amount.sub(toPay);
                IMarket(markets[maxIndex]).sendCollateralToLiquidator(_liquidator, _borrower, toPay);
            }

            marketsProcessed = marketsProcessed + 1;
        }
    }

    /// @notice Sends as much collateral as needed to a liquidator that covered a debt on behalf of a borrower
    /// @dev Here the Liquidator have to tell the specific order in which they want to get collateral assets
    /// @dev The USDC amount here has 18 decimals
    /// @param _liquidator (address) Liquidator's address
    /// @param _borrower (address) Borrower's address
    /// @param _amount (uint256) Amount paid by the Liquidator in USDC terms at Liquidity Pool's side
    /// @param _markets (address[]) Array of markets in their specific order to send collaterals to the liquidator
    function sendCollateralToLiquidatorWithPreference(
        address _liquidator,
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) external override onlyLiquidityPool {
        for (uint256 i = 0; i < _markets.length; i++) {
            if (_amount == 0) break;
            uint256 borrowingLimit = IMarket(_markets[i]).borrowingLimit(_borrower);
            if (borrowingLimit == 0) continue;
            uint256 collateralFactor = IMarket(_markets[i]).getCollateralFactor().mul(RATIOS);
            uint256 collateral = borrowingLimit.mul(FACTOR).div(collateralFactor);
            uint256 toPay = (_amount >= collateral) ? collateral : _amount;
            _amount = _amount.sub(toPay);
            IMarket(_markets[i]).sendCollateralToLiquidator(_liquidator, _borrower, toPay);
        }
    }

    /// @notice Get the addresses of all the markets handled by this comptroller
    /// @return (address[] memory) The array with the addresses of all the markets handled by this comptroller
    function getAllMarkets() public view returns (address[] memory) {
        return markets;
    }

    /// @notice Removes a specific index market from the markets this comptroller handles
    /// @dev The order of markets doesn't matter in this comptroller
    /// @dev This function is executable only by the owner of this comptroller
    function removeMarket(uint256 _index) external onlyOwner {
        require(_index < markets.length, "Invalid market index");

        address market = markets[_index];
        require(isMarket[market] == true, "Market should exist");

        if (_index < markets.length - 1) {
            markets[_index] = markets[markets.length - 1];
        }

        isMarket[market] = false;
        markets.pop();

        emit RemoveMarket(market);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface ILiquidityPool {
    function updatedBorrowBy(address _borrower) external view returns (uint256);

    function flashLoan(
        address _receiver,
        uint256 _amount,
        bytes memory _params
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface IComptroller {
    function addMarket(address _market) external;

    function setLiquidityPool(address _liquidityPool) external;

    function borrowingCapacity(address _borrower) external view returns (uint256 capacity);

    function addBorrowerMarket(address _borrower, address _market) external;

    function removeBorrowerMarket(address _borrower, address _market) external;

    function getHealthRatio(address _borrower) external view returns (uint256);

    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external;

    function sendCollateralToLiquidatorWithPreference(
        address _liquidator,
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface IMarket {
    function getCollateralFactor() external view returns (uint256);

    function setCollateralFactor(uint256 _collateralFactor) external;

    function getCollateralCap() external view returns (uint256);

    function setCollateralCap(uint256 _collateralCap) external;

    function collateralize(uint256 _amount) external;

    function collateral(address _borrower) external view returns (uint256);

    function borrowingLimit(address _borrower) external view returns (uint256);

    function setComptroller(address _comptroller) external;

    function setCollateralizationActive(bool _active) external;

    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external;
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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