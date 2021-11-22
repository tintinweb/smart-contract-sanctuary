pragma solidity ^0.5.0;

import "../interfaces/IReserveInterestRateStrategy.sol";
import "../libraries/WadRayMath.sol";
import "../configuration/LendingPoolAddressesProvider.sol";
import "./LendingPoolCore.sol";
import "../interfaces/ILendingRateOracle.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


/**
* DefaultReserveInterestRateStrategy contract
* -
* implements the calculation of the interest rates depending on the reserve parameters.
* if there is need to update the calculation of the interest rates for a specific reserve,
* a new version of this contract will be deployed.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;



   /**
    * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates
    * expressed in ray
    **/
    uint256 public constant OPTIMAL_UTILIZATION_RATE = 0.8 * 1e27;

   /**
    * @dev this constant represents the excess utilization rate above the optimal. It's always equal to
    * 1-optimal utilization rate. Added as a constant here for gas optimizations
    * expressed in ray
    **/

    uint256 public constant EXCESS_UTILIZATION_RATE = 0.2 * 1e27;

    LendingPoolAddressesProvider public addressesProvider;


    //base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 public baseVariableBorrowRate;

    //slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public variableRateSlope1;

    //slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public variableRateSlope2;

    //slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public stableRateSlope1;

    //slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public stableRateSlope2;
    
    address public reserve;

    constructor(
        address _reserve,
        LendingPoolAddressesProvider _provider,
        uint256 _baseVariableBorrowRate,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2,
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2
    ) public {
        addressesProvider = _provider;
        baseVariableBorrowRate = _baseVariableBorrowRate;
        variableRateSlope1 = _variableRateSlope1;
        variableRateSlope2 = _variableRateSlope2;
        stableRateSlope1 = _stableRateSlope1;
        stableRateSlope2 = _stableRateSlope2;
        reserve = _reserve;
    }

    /**
    @dev accessors
     */

    function getBaseVariableBorrowRate() external view returns (uint256) {
        return baseVariableBorrowRate;
    }

    function getVariableRateSlope1() external view returns (uint256) {
        return variableRateSlope1;
    }

    function getVariableRateSlope2() external view returns (uint256) {
        return variableRateSlope2;
    }

    function getStableRateSlope1() external view returns (uint256) {
        return stableRateSlope1;
    }

    function getStableRateSlope2() external view returns (uint256) {
        return stableRateSlope2;
    }

    /**
    * @dev calculates the interest rates depending on the available liquidity and the total borrowed.
    * @param _reserve the address of the reserve
    * @param _availableLiquidity the liquidity available in the reserve
    * @param _totalBorrowsStable the total borrowed from the reserve a stable rate
    * @param _totalBorrowsVariable the total borrowed from the reserve at a variable rate
    * @param _averageStableBorrowRate the weighted average of all the stable rate borrows
    * @return the liquidity rate, stable borrow rate and variable borrow rate calculated from the input parameters
    **/
    function calculateInterestRates(
        address _reserve,
        uint256 _availableLiquidity,
        uint256 _totalBorrowsStable,
        uint256 _totalBorrowsVariable,
        uint256 _averageStableBorrowRate
    )
        external
        view
        returns (
            uint256 currentLiquidityRate,
            uint256 currentStableBorrowRate,
            uint256 currentVariableBorrowRate
        )
    {
        uint256 totalBorrows = _totalBorrowsStable.add(_totalBorrowsVariable);

        uint256 utilizationRate = (totalBorrows == 0 && _availableLiquidity == 0)
            ? 0
            : totalBorrows.rayDiv(_availableLiquidity.add(totalBorrows));

        currentStableBorrowRate = ILendingRateOracle(addressesProvider.getLendingRateOracle())
            .getMarketBorrowRate(_reserve);

        if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = utilizationRate
                .sub(OPTIMAL_UTILIZATION_RATE)
                .rayDiv(EXCESS_UTILIZATION_RATE);

            currentStableBorrowRate = currentStableBorrowRate.add(stableRateSlope1).add(
                stableRateSlope2.rayMul(excessUtilizationRateRatio)
            );

            currentVariableBorrowRate = baseVariableBorrowRate.add(variableRateSlope1).add(
                variableRateSlope2.rayMul(excessUtilizationRateRatio)
            );
        } else {
            currentStableBorrowRate = currentStableBorrowRate.add(
                stableRateSlope1.rayMul(
                    utilizationRate.rayDiv(
                        OPTIMAL_UTILIZATION_RATE
                    )
                )
            );
            currentVariableBorrowRate = baseVariableBorrowRate.add(
                utilizationRate.rayDiv(OPTIMAL_UTILIZATION_RATE).rayMul(variableRateSlope1)
            );
        }

        currentLiquidityRate = getOverallBorrowRateInternal(
            _totalBorrowsStable,
            _totalBorrowsVariable,
            currentVariableBorrowRate,
            _averageStableBorrowRate
        )
            .rayMul(utilizationRate);

    }

    /**
    * @dev calculates the overall borrow rate as the weighted average between the total variable borrows and total stable borrows.
    * @param _totalBorrowsStable the total borrowed from the reserve a stable rate
    * @param _totalBorrowsVariable the total borrowed from the reserve at a variable rate
    * @param _currentVariableBorrowRate the current variable borrow rate
    * @param _currentAverageStableBorrowRate the weighted average of all the stable rate borrows
    * @return the weighted averaged borrow rate
    **/
    function getOverallBorrowRateInternal(
        uint256 _totalBorrowsStable,
        uint256 _totalBorrowsVariable,
        uint256 _currentVariableBorrowRate,
        uint256 _currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalBorrows = _totalBorrowsStable.add(_totalBorrowsVariable);

        if (totalBorrows == 0) return 0;

        uint256 weightedVariableRate = _totalBorrowsVariable.wadToRay().rayMul(
            _currentVariableBorrowRate
        );

        uint256 weightedStableRate = _totalBorrowsStable.wadToRay().rayMul(
            _currentAverageStableBorrowRate
        );

        uint256 overallBorrowRate = weightedVariableRate.add(weightedStableRate).rayDiv(
            totalBorrows.wadToRay()
        );

        return overallBorrowRate;
    }
}

pragma solidity >=0.4.24 <0.6.0;

/**
 * VersionedInitializable
 * -
 * Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 * -
 * This contract was cloned from Populous and modified to work with the Populous World eco-system.
 **/
contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure returns (uint256);

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    constructor(address _logic, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
    /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
    function() external payable {
        _fallback();
    }

    /**
   * @return The Address of the implementation.
   */
    function _implementation() internal view returns (address);

    /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }

    /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
    function _willFallback() internal {}

    /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

pragma solidity ^0.5.0;

import "./BaseAdminUpgradeabilityProxy.sol";
import "./InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
    /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, address _admin, bytes memory _data) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(_logic, _data);
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }
}

pragma solidity ^0.5.0;

import "./Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
    event Upgraded(address indexed implementation);

    /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

pragma solidity ^0.5.0;

import "./UpgradeabilityProxy.sol";

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
   * @return The address of the proxy admin.
   */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
   * @return The address of the implementation.
   */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
   * @return The admin slot.
   */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            adm := sload(slot)
        }
    }

    /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
   * @dev Only fall back when the sender is not the admin.
   */
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * WadRayMath library
 * -
 *  Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * -
 * This contract was cloned from Populous and modified to work with the Populous World eco-system.
 **/

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    /**
     * @dev calculates base^exp. The code uses the ModExp precompile
     * @return base^exp, in ray
     */
    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

pragma solidity ^0.5.0;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./WadRayMath.sol";

/**
 * CoreLibrary library
 * -
 * Defines the data structures of the reserves and the user data
 * -
 * This contract was cloned from Populous and modified to work with the Populous World eco-system.
 **/

library CoreLibrary {
    using SafeMath for uint256;
    using WadRayMath for uint256;


    enum InterestRateMode {NONE, STABLE, VARIABLE}

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    struct UserReserveData {
        //principal amount borrowed by the user.
        uint256 principalBorrowBalance;
        //cumulated variable borrow index for the user. Expressed in ray
        uint256 lastVariableBorrowCumulativeIndex;
        //origination fee cumulated by the user
        uint256 originationFee;
        // stable borrow rate at which the user has borrowed. Expressed in ray
        uint256 stableBorrowRate;
        uint40 lastUpdateTimestamp;
        //defines if a specific deposit should or not be used as a collateral in borrows
        bool useAsCollateral;
    }

    struct ReserveData {
        /**
         * @dev refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
         **/
        //the liquidity index. Expressed in ray
        uint256 lastLiquidityCumulativeIndex;
        //the current supply rate. Expressed in ray
        uint256 currentLiquidityRate;
        //the total borrows of the reserve at a stable rate. Expressed in the currency decimals
        uint256 totalBorrowsStable;
        //the total borrows of the reserve at a variable rate. Expressed in the currency decimals
        uint256 totalBorrowsVariable;
        //the current variable borrow rate. Expressed in ray
        uint256 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint256 currentStableBorrowRate;
        //the current average stable borrow rate (weighted average of all the different stable rate loans). Expressed in ray
        uint256 currentAverageStableBorrowRate;
        //variable borrow index. Expressed in ray
        uint256 lastVariableBorrowCumulativeIndex;
        //the ltv of the reserve. Expressed in percentage (0-100)
        uint256 baseLTVasCollateral;
        //the liquidation threshold of the reserve. Expressed in percentage (0-100)
        uint256 liquidationThreshold;
        //the liquidation bonus of the reserve. Expressed in percentage
        uint256 liquidationBonus;
        //the decimals of the reserve asset
        uint256 decimals;
        /**
         * @dev address of the PToken representing the asset
         **/
        address PTokenAddress;
        /**
         * @dev address of the interest rate strategy contract
         **/
        address interestRateStrategyAddress;
        uint40 lastUpdateTimestamp;
        // borrowingEnabled = true means users can borrow from this reserve
        bool borrowingEnabled;
        // usageAsCollateralEnabled = true means users can use this reserve as collateral
        bool usageAsCollateralEnabled;
        // isStableBorrowRateEnabled = true means users can borrow at a stable rate
        bool isStableBorrowRateEnabled;
        // isActive = true means the reserve has been activated and properly configured
        bool isActive;
        // isFreezed = true means the reserve only allows repays and redeems, but not deposits, new borrowings or rate swap
        bool isFreezed;
    }

    /**
     * @dev returns the ongoing normalized income for the reserve.
     * a value of 1e27 means there is no income. As time passes, the income is accrued.
     * A value of 2*1e27 means that the income of the reserve is double the initial amount.
     * @param _reserve the reserve object
     * @return the normalized income. expressed in ray
     **/
    function getNormalizedIncome(CoreLibrary.ReserveData storage _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 cumulated = calculateLinearInterest(
            _reserve
                .currentLiquidityRate,
            _reserve
                .lastUpdateTimestamp
        )
            .rayMul(_reserve.lastLiquidityCumulativeIndex);

        return cumulated;
    }

    /**
     * @dev Updates the liquidity cumulative index Ci and variable borrow cumulative index Bvc. Refer to the whitepaper for
     * a formal specification.
     * @param _self the reserve object
     **/
    function updateCumulativeIndexes(ReserveData storage _self) internal {
        uint256 totalBorrows = getTotalBorrows(_self);

        if (totalBorrows > 0) {
            //only cumulating if there is any income being produced
            uint256 cumulatedLiquidityInterest = calculateLinearInterest(
                _self.currentLiquidityRate,
                _self.lastUpdateTimestamp
            );

            _self.lastLiquidityCumulativeIndex = cumulatedLiquidityInterest
                .rayMul(_self.lastLiquidityCumulativeIndex);


                uint256 cumulatedVariableBorrowInterest
             = calculateCompoundedInterest(
                _self.currentVariableBorrowRate,
                _self.lastUpdateTimestamp
            );
            _self
                .lastVariableBorrowCumulativeIndex = cumulatedVariableBorrowInterest
                .rayMul(_self.lastVariableBorrowCumulativeIndex);
        }
    }

    /**
     * @dev accumulates a predefined amount of asset to the reserve as a fixed, one time income. Used for example to accumulate
     * the flashloan fee to the reserve, and spread it through the depositors.
     * @param _self the reserve object
     * @param _totalLiquidity the total liquidity available in the reserve
     * @param _amount the amount to accomulate
     **/
    function cumulateToLiquidityIndex(
        ReserveData storage _self,
        uint256 _totalLiquidity,
        uint256 _amount
    ) internal {
        uint256 amountToLiquidityRatio = _amount.wadToRay().rayDiv(
            _totalLiquidity.wadToRay()
        );

        uint256 cumulatedLiquidity = amountToLiquidityRatio.add(
            WadRayMath.ray()
        );

        _self.lastLiquidityCumulativeIndex = cumulatedLiquidity.rayMul(
            _self.lastLiquidityCumulativeIndex
        );
    }

    /**
     * @dev initializes a reserve
     * @param _self the reserve object
     * @param _PTokenAddress the address of the overlying PToken contract
     * @param _decimals the number of decimals of the underlying asset
     * @param _interestRateStrategyAddress the address of the interest rate strategy contract
     **/
    function init(
        ReserveData storage _self,
        address _PTokenAddress,
        uint256 _decimals,
        address _interestRateStrategyAddress
    ) external {
        require(
            _self.PTokenAddress == address(0),
            "Reserve has already been initialized"
        );

        if (_self.lastLiquidityCumulativeIndex == 0) {
            //if the reserve has not been initialized yet
            _self.lastLiquidityCumulativeIndex = WadRayMath.ray();
        }

        if (_self.lastVariableBorrowCumulativeIndex == 0) {
            _self.lastVariableBorrowCumulativeIndex = WadRayMath.ray();
        }

        _self.PTokenAddress = _PTokenAddress;
        _self.decimals = _decimals;

        _self.interestRateStrategyAddress = _interestRateStrategyAddress;
        _self.isActive = true;
        _self.isFreezed = false;
    }

    /**
     * @dev enables borrowing on a reserve
     * @param _self the reserve object
     * @param _stableBorrowRateEnabled true if the stable borrow rate must be enabled by default, false otherwise
     **/
    function enableBorrowing(
        ReserveData storage _self,
        bool _stableBorrowRateEnabled
    ) external {
        require(_self.borrowingEnabled == false, "Reserve is already enabled");

        _self.borrowingEnabled = true;
        _self.isStableBorrowRateEnabled = _stableBorrowRateEnabled;
    }

    /**
     * @dev disables borrowing on a reserve
     * @param _self the reserve object
     **/
    function disableBorrowing(ReserveData storage _self) external {
        _self.borrowingEnabled = false;
    }

    /**
     * @dev enables a reserve to be used as collateral
     * @param _self the reserve object
     * @param _baseLTVasCollateral the loan to value of the asset when used as collateral
     * @param _liquidationThreshold the threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param _liquidationBonus the bonus liquidators receive to liquidate this asset
     **/
    function enableAsCollateral(
        ReserveData storage _self,
        uint256 _baseLTVasCollateral,
        uint256 _liquidationThreshold,
        uint256 _liquidationBonus
    ) external {
        require(
            _self.usageAsCollateralEnabled == false,
            "Reserve is already enabled as collateral"
        );

        _self.usageAsCollateralEnabled = true;
        _self.baseLTVasCollateral = _baseLTVasCollateral;
        _self.liquidationThreshold = _liquidationThreshold;
        _self.liquidationBonus = _liquidationBonus;

        if (_self.lastLiquidityCumulativeIndex == 0)
            _self.lastLiquidityCumulativeIndex = WadRayMath.ray();
    }

    /**
     * @dev disables a reserve as collateral
     * @param _self the reserve object
     **/
    function disableAsCollateral(ReserveData storage _self) external {
        _self.usageAsCollateralEnabled = false;
    }

    

    /**
     * @dev calculates the compounded borrow balance of a user
     * @param _self the userReserve object
     * @param _reserve the reserve object
     * @return the user compounded borrow balance
     **/
    function getCompoundedBorrowBalance(
        CoreLibrary.UserReserveData storage _self,
        CoreLibrary.ReserveData storage _reserve
    ) internal view returns (uint256) {
        if (_self.principalBorrowBalance == 0) return 0;

        uint256 principalBorrowBalanceRay = _self
            .principalBorrowBalance
            .wadToRay();
        uint256 compoundedBalance = 0;
        uint256 cumulatedInterest = 0;

        if (_self.stableBorrowRate > 0) {
            cumulatedInterest = calculateCompoundedInterest(
                _self.stableBorrowRate,
                _self.lastUpdateTimestamp
            );
        } else {
            //variable interest
            cumulatedInterest = calculateCompoundedInterest(
                _reserve
                    .currentVariableBorrowRate,
                _reserve
                    .lastUpdateTimestamp
            )
                .rayMul(_reserve.lastVariableBorrowCumulativeIndex)
                .rayDiv(_self.lastVariableBorrowCumulativeIndex);
        }

        compoundedBalance = principalBorrowBalanceRay
            .rayMul(cumulatedInterest)
            .rayToWad();

        if (compoundedBalance == _self.principalBorrowBalance) {
            //solium-disable-next-line
            if (_self.lastUpdateTimestamp != block.timestamp) {
                //no interest cumulation because of the rounding - we add 1 wei
                //as symbolic cumulated interest to avoid interest free loans.

                return _self.principalBorrowBalance.add(1 wei);
            }
        }

        return compoundedBalance;
    }

    /**
     * @dev increases the total borrows at a stable rate on a specific reserve and updates the
     * average stable rate consequently
     * @param _reserve the reserve object
     * @param _amount the amount to add to the total borrows stable
     * @param _rate the rate at which the amount has been borrowed
     **/
    function increaseTotalBorrowsStableAndUpdateAverageRate(
        ReserveData storage _reserve,
        uint256 _amount,
        uint256 _rate
    ) internal {
        uint256 previousTotalBorrowStable = _reserve.totalBorrowsStable;
        //updating reserve borrows stable
        _reserve.totalBorrowsStable = _reserve.totalBorrowsStable.add(_amount);

        //update the average stable rate
        //weighted average of all the borrows
        uint256 weightedLastBorrow = _amount.wadToRay().rayMul(_rate);
        uint256 weightedPreviousTotalBorrows = previousTotalBorrowStable
            .wadToRay()
            .rayMul(_reserve.currentAverageStableBorrowRate);

        _reserve.currentAverageStableBorrowRate = weightedLastBorrow
            .add(weightedPreviousTotalBorrows)
            .rayDiv(_reserve.totalBorrowsStable.wadToRay());
    }

    /**
     * @dev decreases the total borrows at a stable rate on a specific reserve and updates the
     * average stable rate consequently
     * @param _reserve the reserve object
     * @param _amount the amount to substract to the total borrows stable
     * @param _rate the rate at which the amount has been repaid
     **/
    function decreaseTotalBorrowsStableAndUpdateAverageRate(
        ReserveData storage _reserve,
        uint256 _amount,
        uint256 _rate
    ) internal {
        require(
            _reserve.totalBorrowsStable >= _amount,
            "Invalid amount to decrease"
        );

        uint256 previousTotalBorrowStable = _reserve.totalBorrowsStable;

        //updating reserve borrows stable
        _reserve.totalBorrowsStable = _reserve.totalBorrowsStable.sub(_amount);

        if (_reserve.totalBorrowsStable == 0) {
            _reserve.currentAverageStableBorrowRate = 0; //no income if there are no stable rate borrows
            return;
        }

        //update the average stable rate
        //weighted average of all the borrows
        uint256 weightedLastBorrow = _amount.wadToRay().rayMul(_rate);
        uint256 weightedPreviousTotalBorrows = previousTotalBorrowStable
            .wadToRay()
            .rayMul(_reserve.currentAverageStableBorrowRate);

        require(
            weightedPreviousTotalBorrows >= weightedLastBorrow,
            "The amounts to subtract don't match"
        );

        _reserve.currentAverageStableBorrowRate = weightedPreviousTotalBorrows
            .sub(weightedLastBorrow)
            .rayDiv(_reserve.totalBorrowsStable.wadToRay());
    }

    /**
     * @dev increases the total borrows at a variable rate
     * @param _reserve the reserve object
     * @param _amount the amount to add to the total borrows variable
     **/
    function increaseTotalBorrowsVariable(
        ReserveData storage _reserve,
        uint256 _amount
    ) internal {
        _reserve.totalBorrowsVariable = _reserve.totalBorrowsVariable.add(
            _amount
        );
    }

    /**
     * @dev decreases the total borrows at a variable rate
     * @param _reserve the reserve object
     * @param _amount the amount to substract to the total borrows variable
     **/
    function decreaseTotalBorrowsVariable(
        ReserveData storage _reserve,
        uint256 _amount
    ) internal {
        require(
            _reserve.totalBorrowsVariable >= _amount,
            "The amount that is being subtracted from the variable total borrows is incorrect"
        );
        _reserve.totalBorrowsVariable = _reserve.totalBorrowsVariable.sub(
            _amount
        );
    }

    /**
     * @dev function to calculate the interest using a linear interest rate formula
     * @param _rate the interest rate, in ray
     * @param _lastUpdateTimestamp the timestamp of the last update of the interest
     * @return the interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 _rate, uint40 _lastUpdateTimestamp)
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(
            uint256(_lastUpdateTimestamp)
        );

        uint256 timeDelta = timeDifference.wadToRay().rayDiv(
            SECONDS_PER_YEAR.wadToRay()
        );

        return _rate.rayMul(timeDelta).add(WadRayMath.ray());
    }

    /**
     * @dev function to calculate the interest using a compounded interest rate formula
     * @param _rate the interest rate, in ray
     * @param _lastUpdateTimestamp the timestamp of the last update of the interest
     * @return the interest rate compounded during the timeDelta, in ray
     **/
    function calculateCompoundedInterest(
        uint256 _rate,
        uint40 _lastUpdateTimestamp
    ) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(
            uint256(_lastUpdateTimestamp)
        );

        uint256 ratePerSecond = _rate.div(SECONDS_PER_YEAR);

        return ratePerSecond.add(WadRayMath.ray()).rayPow(timeDifference);
    }

    /**
     * @dev returns the total borrows on the reserve
     * @param _reserve the reserve object
     * @return the total borrows (stable + variable)
     **/
    function getTotalBorrows(CoreLibrary.ReserveData storage _reserve)
        internal
        view
        returns (uint256)
    {
        return _reserve.totalBorrowsStable.add(_reserve.totalBorrowsVariable);
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libraries/openzeppelin-upgradeability/VersionedInitializable.sol";

import "../libraries/CoreLibrary.sol";
import "../configuration/LendingPoolAddressesProvider.sol";
import "../interfaces/ILendingRateOracle.sol";
import "../interfaces/IReserveInterestRateStrategy.sol";
import "../libraries/WadRayMath.sol";
import "../libraries/EthAddressLib.sol";

//import "../tokenization/PToken.sol";
import "../interfaces/IPToken.sol";


/**
 *LendingPoolCore contract
 * -
 * Holds the state of the lending pool and all the funds deposited
* NOTE: The core does not enforce security checks on the update of the state
* (eg, updateStateOnBorrow() does not enforce that borrowed is enabled on the reserve).
* The check that an action can be performed is a duty of the overlying LendingPool contract.
 * -
 * This contract was cloned from Populous and modified to work with the Populous World eco-system.
 **/

contract LendingPoolCore is VersionedInitializable {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using CoreLibrary for CoreLibrary.ReserveData;
    using CoreLibrary for CoreLibrary.UserReserveData;
    using SafeERC20 for ERC20;
    using Address for address payable;

    /**
    * @dev Emitted when the state of a reserve is updated
    * @param reserve the address of the reserve
    * @param liquidityRate the new liquidity rate
    * @param stableBorrowRate the new stable borrow rate
    * @param variableBorrowRate the new variable borrow rate
    * @param liquidityIndex the new liquidity index
    * @param variableBorrowIndex the new variable borrow index
    **/
    event ReserveUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    address public lendingPoolAddress;

    LendingPoolAddressesProvider public addressesProvider;

    /**
    * @dev only lending pools can use functions affected by this modifier
    **/
    modifier onlyLendingPool {
        require(lendingPoolAddress == msg.sender, "The caller must be a lending pool contract");
        _;
    }

    /**
    * @dev only lending pools configurator can use functions affected by this modifier
    **/
    modifier onlyLendingPoolConfigurator {
        require(
            addressesProvider.getLendingPoolConfigurator() == msg.sender,
            "The caller must be a lending pool configurator contract"
        );
        _;
    }

    mapping(address => CoreLibrary.ReserveData) internal reserves;
    mapping(address => mapping(address => CoreLibrary.UserReserveData)) internal usersReserveData;

    address[] public reservesList;

    uint256 public constant CORE_REVISION = 0x4;

    /**
    * @dev returns the revision number of the contract
    **/
    function getRevision() internal pure returns (uint256) {
        return CORE_REVISION;
    }

    /**
    * @dev initializes the Core contract, invoked upon registration on the AddressesProvider
    * @param _addressesProvider the addressesProvider contract
    **/

    function initialize(LendingPoolAddressesProvider _addressesProvider) public initializer {
        addressesProvider = _addressesProvider;
        refreshConfigInternal();
    }

    /**
    * @dev updates the state of the core as a result of a deposit action
    * @param _reserve the address of the reserve in which the deposit is happening
    * @param _user the address of the the user depositing
    * @param _amount the amount being deposited
    * @param _isFirstDeposit true if the user is depositing for the first time
    **/

    function updateStateOnDeposit(
        address _reserve,
        address _user,
        uint256 _amount,
        bool _isFirstDeposit
    ) external onlyLendingPool {
        reserves[_reserve].updateCumulativeIndexes();
        updateReserveInterestRatesAndTimestampInternal(_reserve, _amount, 0);

        if (_isFirstDeposit) {
            //if this is the first deposit of the user, we configure the deposit as enabled to be used as collateral
            setUserUseReserveAsCollateral(_reserve, _user, true);
        }
    }

    /**
    * @dev updates the state of the core as a result of a redeem action
    * @param _reserve the address of the reserve in which the redeem is happening
    * @param _user the address of the user redeeming
    * @param _amountRedeemed the amount being redeemed
    * @param _userRedeemedEverything true if the user is redeeming everything
    **/
    function updateStateOnRedeem(
        address _reserve,
        address _user,
        uint256 _amountRedeemed,
        bool _userRedeemedEverything
    ) external onlyLendingPool {
        //compound liquidity and variable borrow interests
        reserves[_reserve].updateCumulativeIndexes();
        updateReserveInterestRatesAndTimestampInternal(_reserve, 0, _amountRedeemed);

        //if user redeemed everything the useReserveAsCollateral flag is reset
        if (_userRedeemedEverything) {
            setUserUseReserveAsCollateral(_reserve, _user, false);
        }
    }

    /**
    * @dev updates the state of the core as a result of a flashloan action
    * @param _reserve the address of the reserve in which the flashloan is happening
    * @param _income the income of the protocol as a result of the action
    **/
    function updateStateOnFlashLoan(
        address _reserve,
        uint256 _availableLiquidityBefore,
        uint256 _income,
        uint256 _protocolFee
    ) external onlyLendingPool {
        transferFlashLoanProtocolFeeInternal(_reserve, _protocolFee);

        //compounding the cumulated interest
        reserves[_reserve].updateCumulativeIndexes();

        uint256 totalLiquidityBefore = _availableLiquidityBefore.add(
            getReserveTotalBorrows(_reserve)
        );

        //compounding the received fee into the reserve
        reserves[_reserve].cumulateToLiquidityIndex(totalLiquidityBefore, _income);

        //refresh interest rates
        updateReserveInterestRatesAndTimestampInternal(_reserve, _income, 0);
    }

    /**
    * @dev updates the state of the core as a consequence of a borrow action.
    * @param _reserve the address of the reserve on which the user is borrowing
    * @param _user the address of the borrower
    * @param _amountBorrowed the new amount borrowed
    * @param _borrowFee the fee on the amount borrowed
    * @param _rateMode the borrow rate mode (stable, variable)
    * @return the new borrow rate for the user
    **/
    function updateStateOnBorrow(
        address _reserve,
        address _user,
        uint256 _amountBorrowed,
        uint256 _borrowFee,
        CoreLibrary.InterestRateMode _rateMode
    ) external onlyLendingPool returns (uint256, uint256) {
        // getting the previous borrow data of the user
        (uint256 principalBorrowBalance, , uint256 balanceIncrease) = getUserBorrowBalances(
            _reserve,
            _user
        );

        updateReserveStateOnBorrowInternal(
            _reserve,
            _user,
            principalBorrowBalance,
            balanceIncrease,
            _amountBorrowed,
            _rateMode
        );

        updateUserStateOnBorrowInternal(
            _reserve,
            _user,
            _amountBorrowed,
            balanceIncrease,
            _borrowFee,
            _rateMode
        );

        updateReserveInterestRatesAndTimestampInternal(_reserve, 0, _amountBorrowed);

        return (getUserCurrentBorrowRate(_reserve, _user), balanceIncrease);
    }

    /**
    * @dev updates the state of the core as a consequence of a repay action.
    * @param _reserve the address of the reserve on which the user is repaying
    * @param _user the address of the borrower
    * @param _paybackAmountMinusFees the amount being paid back minus fees
    * @param _originationFeeRepaid the fee on the amount that is being repaid
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _repaidWholeLoan true if the user is repaying the whole loan
    **/

    function updateStateOnRepay(
        address _reserve,
        address _user,
        uint256 _paybackAmountMinusFees,
        uint256 _originationFeeRepaid,
        uint256 _balanceIncrease,
        bool _repaidWholeLoan
    ) external onlyLendingPool {
        updateReserveStateOnRepayInternal(
            _reserve,
            _user,
            _paybackAmountMinusFees,
            _balanceIncrease
        );
        updateUserStateOnRepayInternal(
            _reserve,
            _user,
            _paybackAmountMinusFees,
            _originationFeeRepaid,
            _balanceIncrease,
            _repaidWholeLoan
        );

        updateReserveInterestRatesAndTimestampInternal(_reserve, _paybackAmountMinusFees, 0);
    }

    /**
    * @dev updates the state of the core as a consequence of a swap rate action.
    * @param _reserve the address of the reserve on which the user is repaying
    * @param _user the address of the borrower
    * @param _principalBorrowBalance the amount borrowed by the user
    * @param _compoundedBorrowBalance the amount borrowed plus accrued interest
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _currentRateMode the current interest rate mode for the user
    **/
    function updateStateOnSwapRate(
        address _reserve,
        address _user,
        uint256 _principalBorrowBalance,
        uint256 _compoundedBorrowBalance,
        uint256 _balanceIncrease,
        CoreLibrary.InterestRateMode _currentRateMode
    ) external onlyLendingPool returns (CoreLibrary.InterestRateMode, uint256) {
        updateReserveStateOnSwapRateInternal(
            _reserve,
            _user,
            _principalBorrowBalance,
            _compoundedBorrowBalance,
            _currentRateMode
        );

        CoreLibrary.InterestRateMode newRateMode = updateUserStateOnSwapRateInternal(
            _reserve,
            _user,
            _balanceIncrease,
            _currentRateMode
        );

        updateReserveInterestRatesAndTimestampInternal(_reserve, 0, 0);

        return (newRateMode, getUserCurrentBorrowRate(_reserve, _user));
    }

    /**
    * @dev updates the state of the core as a consequence of a liquidation action.
    * @param _principalReserve the address of the principal reserve that is being repaid
    * @param _collateralReserve the address of the collateral reserve that is being liquidated
    * @param _user the address of the borrower
    * @param _amountToLiquidate the amount being repaid by the liquidator
    * @param _collateralToLiquidate the amount of collateral being liquidated
    * @param _feeLiquidated the amount of origination fee being liquidated
    * @param _liquidatedCollateralForFee the amount of collateral equivalent to the origination fee + bonus
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _liquidatorReceivesPToken true if the liquidator will receive PTokens, false otherwise
    **/
    function updateStateOnLiquidation(
        address _principalReserve,
        address _collateralReserve,
        address _user,
        uint256 _amountToLiquidate,
        uint256 _collateralToLiquidate,
        uint256 _feeLiquidated,
        uint256 _liquidatedCollateralForFee,
        uint256 _balanceIncrease,
        bool _liquidatorReceivesPToken
    ) external onlyLendingPool {
        updatePrincipalReserveStateOnLiquidationInternal(
            _principalReserve,
            _user,
            _amountToLiquidate,
            _balanceIncrease
        );

        updateCollateralReserveStateOnLiquidationInternal(
            _collateralReserve
        );

        updateUserStateOnLiquidationInternal(
            _principalReserve,
            _user,
            _amountToLiquidate,
            _feeLiquidated,
            _balanceIncrease
        );

        updateReserveInterestRatesAndTimestampInternal(_principalReserve, _amountToLiquidate, 0);

        if (!_liquidatorReceivesPToken) {
            updateReserveInterestRatesAndTimestampInternal(
                _collateralReserve,
                0,
                _collateralToLiquidate.add(_liquidatedCollateralForFee)
            );
        }

    }

    /**
    * @dev updates the state of the core as a consequence of a stable rate rebalance
    * @param _reserve the address of the principal reserve where the user borrowed
    * @param _user the address of the borrower
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @return the new stable rate for the user
    **/
    function updateStateOnRebalance(address _reserve, address _user, uint256 _balanceIncrease)
        external
        onlyLendingPool
        returns (uint256)
    {
        updateReserveStateOnRebalanceInternal(_reserve, _user, _balanceIncrease);

        //update user data and rebalance the rate
        updateUserStateOnRebalanceInternal(_reserve, _user, _balanceIncrease);
        updateReserveInterestRatesAndTimestampInternal(_reserve, 0, 0);
        return usersReserveData[_user][_reserve].stableBorrowRate;
    }

    /**
    * @dev enables or disables a reserve as collateral
    * @param _reserve the address of the principal reserve where the user deposited
    * @param _user the address of the depositor
    * @param _useAsCollateral true if the depositor wants to use the reserve as collateral
    **/
    function setUserUseReserveAsCollateral(address _reserve, address _user, bool _useAsCollateral)
        public
        onlyLendingPool
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        user.useAsCollateral = _useAsCollateral;
    }

    /**
    * @notice ETH/token transfer functions
    **/

    /**
    * @dev fallback function enforces that the caller is a contract, to support flashloan transfers
    **/
    function() external payable {
        //only contracts can send ETH to the core
        require(msg.sender.isContract(), "Only contracts can send ether to the Lending pool core");

    }

    /**
    * @dev transfers to the user a specific amount from the reserve.
    * @param _reserve the address of the reserve where the transfer is happening
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _reserve, address payable _user, uint256 _amount)
        external
        onlyLendingPool
    {
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call.value(_amount).gas(50000)("");
            require(result, "Transfer of ETH failed");
        }
    }

    /**
    * @dev transfers the protocol fees to the fees collection address
    * @param _token the address of the token being transferred
    * @param _user the address of the user from where the transfer is happening
    * @param _amount the amount being transferred
    * @param _destination the fee receiver address
    **/

    function transferToFeeCollectionAddress(
        address _token,
        address _user,
        uint256 _amount,
        address _destination
    ) external payable onlyLendingPool {
        address payable feeAddress = address(uint160(_destination)); //cast the address to payable

        if (_token != EthAddressLib.ethAddress()) {
            require(
                msg.value == 0,
                "User is sending ETH along with the ERC20 transfer. Check the value attribute of the transaction"
            );
            ERC20(_token).safeTransferFrom(_user, feeAddress, _amount);
        } else {
            require(msg.value >= _amount, "The amount and the value sent to deposit do not match");
            //solium-disable-next-line
            (bool result, ) = feeAddress.call.value(_amount).gas(50000)("");
            require(result, "Transfer of ETH failed");
        }
    }

    /**
    * @dev transfers the fees to the fees collection address in the case of liquidation
    * @param _token the address of the token being transferred
    * @param _amount the amount being transferred
    * @param _destination the fee receiver address
    **/
    function liquidateFee(
        address _token,
        uint256 _amount,
        address _destination
    ) external payable onlyLendingPool {
        address payable feeAddress = address(uint160(_destination)); //cast the address to payable
        require(
            msg.value == 0,
            "Fee liquidation does not require any transfer of value"
        );

        if (_token != EthAddressLib.ethAddress()) {
            ERC20(_token).safeTransfer(feeAddress, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = feeAddress.call.value(_amount).gas(50000)("");
            require(result, "Transfer of ETH failed");
        }
    }

    /**
    * @dev transfers an amount from a user to the destination reserve
    * @param _reserve the address of the reserve where the amount is being transferred
    * @param _user the address of the user from where the transfer is happening
    * @param _amount the amount being transferred
    **/
    function transferToReserve(address _reserve, address payable _user, uint256 _amount)
        external
        payable
        onlyLendingPool
    {
        if (_reserve != EthAddressLib.ethAddress()) {
            require(msg.value == 0, "User is sending ETH along with the ERC20 transfer.");
            ERC20(_reserve).safeTransferFrom(_user, address(this), _amount);

        } else {
            require(msg.value >= _amount, "The amount and the value sent to deposit do not match");

            if (msg.value > _amount) {
                //send back excess ETH
                uint256 excessAmount = msg.value.sub(_amount);
                //solium-disable-next-line
                (bool result, ) = _user.call.value(excessAmount).gas(50000)("");
                require(result, "Transfer of ETH failed");
            }
        }
    }

    /**
    * @notice data access functions
    **/

    /**
    * @dev returns the basic data (balances, fee accrued, reserve enabled/disabled as collateral)
    * needed to calculate the global account data in the LendingPoolDataProvider
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @return the user deposited balance, the principal borrow balance, the fee, and if the reserve is enabled as collateral or not
    **/
    function getUserBasicReserveData(address _reserve, address _user)
        external
        view
        returns (uint256, uint256, uint256, bool)
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        uint256 underlyingBalance = getUserUnderlyingAssetBalance(_reserve, _user);

        if (user.principalBorrowBalance == 0) {
            return (underlyingBalance, 0, 0, user.useAsCollateral);
        }

        return (
            underlyingBalance,
            user.getCompoundedBorrowBalance(reserve),
            user.originationFee,
            user.useAsCollateral
        );
    }

    /**
    * @dev checks if a user is allowed to borrow at a stable rate
    * @param _reserve the reserve address
    * @param _user the user
    * @param _amount the amount the the user wants to borrow
    * @return true if the user is allowed to borrow at a stable rate, false otherwise
    **/

    function isUserAllowedToBorrowAtStable(address _reserve, address _user, uint256 _amount)
        external
        view
        returns (bool)
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        if (!reserve.isStableBorrowRateEnabled) return false;

        return
            !user.useAsCollateral ||
            !reserve.usageAsCollateralEnabled ||
            _amount > getUserUnderlyingAssetBalance(_reserve, _user);
    }

    /**
    * @dev gets the underlying asset balance of a user based on the corresponding PToken balance.
    * @param _reserve the reserve address
    * @param _user the user address
    * @return the underlying deposit balance of the user
    **/

    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public
        view
        returns (uint256)
    {
        IPToken PToken = IPToken(reserves[_reserve].PTokenAddress);
        return PToken.balanceOf(_user);

    }

    /**
    * @dev gets the interest rate strategy contract address for the reserve
    * @param _reserve the reserve address
    * @return the address of the interest rate strategy contract
    **/
    function getReserveInterestRateStrategyAddress(address _reserve) public view returns (address) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.interestRateStrategyAddress;
    }

    /**
    * @dev gets the PToken contract address for the reserve
    * @param _reserve the reserve address
    * @return the address of the PToken contract
    **/

    function getReservePTokenAddress(address _reserve) public view returns (address) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.PTokenAddress;
    }

    /**
    * @dev gets the available liquidity in the reserve. The available liquidity is the balance of the core contract
    * @param _reserve the reserve address
    * @return the available liquidity
    **/
    function getReserveAvailableLiquidity(address _reserve) public view returns (uint256) {
        uint256 balance = 0;

        if (_reserve == EthAddressLib.ethAddress()) {
            balance = address(this).balance;
        } else {
            balance = IERC20(_reserve).balanceOf(address(this));
        }
        return balance;
    }

    /**
    * @dev gets the total liquidity in the reserve. The total liquidity is the balance of the core contract + total borrows
    * @param _reserve the reserve address
    * @return the total liquidity
    **/
    function getReserveTotalLiquidity(address _reserve) public view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return getReserveAvailableLiquidity(_reserve).add(reserve.getTotalBorrows());
    }

    /**
    * @dev gets the normalized income of the reserve. a value of 1e27 means there is no income. A value of 2e27 means there
    * there has been 100% income.
    * @param _reserve the reserve address
    * @return the reserve normalized income
    **/
    function getReserveNormalizedIncome(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.getNormalizedIncome();
    }

    /**
    * @dev gets the reserve total borrows
    * @param _reserve the reserve address
    * @return the total borrows (stable + variable)
    **/
    function getReserveTotalBorrows(address _reserve) public view returns (uint256) {
        return reserves[_reserve].getTotalBorrows();
    }

    /**
    * @dev gets the reserve total borrows stable
    * @param _reserve the reserve address
    * @return the total borrows stable
    **/
    function getReserveTotalBorrowsStable(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.totalBorrowsStable;
    }

    /**
    * @dev gets the reserve total borrows variable
    * @param _reserve the reserve address
    * @return the total borrows variable
    **/

    function getReserveTotalBorrowsVariable(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.totalBorrowsVariable;
    }

    /**
    * @dev gets the reserve liquidation threshold
    * @param _reserve the reserve address
    * @return the reserve liquidation threshold
    **/

    function getReserveLiquidationThreshold(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.liquidationThreshold;
    }

    /**
    * @dev gets the reserve liquidation bonus
    * @param _reserve the reserve address
    * @return the reserve liquidation bonus
    **/

    function getReserveLiquidationBonus(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.liquidationBonus;
    }

    /**
    * @dev gets the reserve current variable borrow rate. Is the base variable borrow rate if the reserve is empty
    * @param _reserve the reserve address
    * @return the reserve current variable borrow rate
    **/

    function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        if (reserve.currentVariableBorrowRate == 0) {
            return
                IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
                .getBaseVariableBorrowRate();
        }
        return reserve.currentVariableBorrowRate;
    }

    /**
    * @dev gets the reserve current stable borrow rate. Is the market rate if the reserve is empty
    * @param _reserve the reserve address
    * @return the reserve current stable borrow rate
    **/

    function getReserveCurrentStableBorrowRate(address _reserve) public view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        ILendingRateOracle oracle = ILendingRateOracle(addressesProvider.getLendingRateOracle());

        if (reserve.currentStableBorrowRate == 0) {
            //no stable rate borrows yet
            return oracle.getMarketBorrowRate(_reserve);
        }

        return reserve.currentStableBorrowRate;
    }

    /**
    * @dev gets the reserve average stable borrow rate. The average stable rate is the weighted average
    * of all the loans taken at stable rate.
    * @param _reserve the reserve address
    * @return the reserve current average borrow rate
    **/
    function getReserveCurrentAverageStableBorrowRate(address _reserve)
        external
        view
        returns (uint256)
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.currentAverageStableBorrowRate;
    }

    /**
    * @dev gets the reserve liquidity rate
    * @param _reserve the reserve address
    * @return the reserve liquidity rate
    **/
    function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.currentLiquidityRate;
    }

    /**
    * @dev gets the reserve liquidity cumulative index
    * @param _reserve the reserve address
    * @return the reserve liquidity cumulative index
    **/
    function getReserveLiquidityCumulativeIndex(address _reserve) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.lastLiquidityCumulativeIndex;
    }

    /**
    * @dev gets the reserve variable borrow index
    * @param _reserve the reserve address
    * @return the reserve variable borrow index
    **/
    function getReserveVariableBorrowsCumulativeIndex(address _reserve)
        external
        view
        returns (uint256)
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.lastVariableBorrowCumulativeIndex;
    }

    /**
    * @dev this function aggregates the configuration parameters of the reserve.
    * It's used in the LendingPoolDataProvider specifically to save gas, and avoid
    * multiple external contract calls to fetch the same data.
    * @param _reserve the reserve address
    * @return the reserve decimals
    * @return the base ltv as collateral
    * @return the liquidation threshold
    * @return if the reserve is used as collateral or not
    **/
    function getReserveConfiguration(address _reserve)
        external
        view
        returns (uint256, uint256, uint256, bool)
    {
        uint256 decimals;
        uint256 baseLTVasCollateral;
        uint256 liquidationThreshold;
        bool usageAsCollateralEnabled;

        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        decimals = reserve.decimals;
        baseLTVasCollateral = reserve.baseLTVasCollateral;
        liquidationThreshold = reserve.liquidationThreshold;
        usageAsCollateralEnabled = reserve.usageAsCollateralEnabled;

        return (decimals, baseLTVasCollateral, liquidationThreshold, usageAsCollateralEnabled);
    }

    /**
    * @dev returns the decimals of the reserve
    * @param _reserve the reserve address
    * @return the reserve decimals
    **/
    function getReserveDecimals(address _reserve) external view returns (uint256) {
        return reserves[_reserve].decimals;
    }

    /**
    * @dev returns true if the reserve is enabled for borrowing
    * @param _reserve the reserve address
    * @return true if the reserve is enabled for borrowing, false otherwise
    **/

    function isReserveBorrowingEnabled(address _reserve) external view returns (bool) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.borrowingEnabled;
    }

    /**
    * @dev returns true if the reserve is enabled as collateral
    * @param _reserve the reserve address
    * @return true if the reserve is enabled as collateral, false otherwise
    **/

    function isReserveUsageAsCollateralEnabled(address _reserve) external view returns (bool) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.usageAsCollateralEnabled;
    }

    /**
    * @dev returns true if the stable rate is enabled on reserve
    * @param _reserve the reserve address
    * @return true if the stable rate is enabled on reserve, false otherwise
    **/
    function getReserveIsStableBorrowRateEnabled(address _reserve) external view returns (bool) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.isStableBorrowRateEnabled;
    }

    /**
    * @dev returns true if the reserve is active
    * @param _reserve the reserve address
    * @return true if the reserve is active, false otherwise
    **/
    function getReserveIsActive(address _reserve) external view returns (bool) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.isActive;
    }

    /**
    * @notice returns if a reserve is freezed
    * @param _reserve the reserve for which the information is needed
    * @return true if the reserve is freezed, false otherwise
    **/

    function getReserveIsFreezed(address _reserve) external view returns (bool) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        return reserve.isFreezed;
    }

    /**
    * @notice returns the timestamp of the last action on the reserve
    * @param _reserve the reserve for which the information is needed
    * @return the last updated timestamp of the reserve
    **/

    function getReserveLastUpdate(address _reserve) external view returns (uint40 timestamp) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        timestamp = reserve.lastUpdateTimestamp;
    }

    /**
    * @dev returns the utilization rate U of a specific reserve
    * @param _reserve the reserve for which the information is needed
    * @return the utilization rate in ray
    **/

    function getReserveUtilizationRate(address _reserve) public view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        uint256 totalBorrows = reserve.getTotalBorrows();

        if (totalBorrows == 0) {
            return 0;
        }

        uint256 availableLiquidity = getReserveAvailableLiquidity(_reserve);

        return totalBorrows.rayDiv(availableLiquidity.add(totalBorrows));
    }

    /**
    * @return the array of reserves configured on the core
    **/
    function getReserves() external view returns (address[] memory) {
        return reservesList;
    }

    /**
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return true if the user has chosen to use the reserve as collateral, false otherwise
    **/
    function isUserUseReserveAsCollateralEnabled(address _reserve, address _user)
        external
        view
        returns (bool)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        return user.useAsCollateral;
    }

    /**
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the origination fee for the user
    **/
    function getUserOriginationFee(address _reserve, address _user)
        external
        view
        returns (uint256)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        return user.originationFee;
    }

    /**
    * @dev users with no loans in progress have NONE as borrow rate mode
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the borrow rate mode for the user,
    **/

    function getUserCurrentBorrowRateMode(address _reserve, address _user)
        public
        view
        returns (CoreLibrary.InterestRateMode)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        if (user.principalBorrowBalance == 0) {
            return CoreLibrary.InterestRateMode.NONE;
        }

        return
            user.stableBorrowRate > 0
            ? CoreLibrary.InterestRateMode.STABLE
            : CoreLibrary.InterestRateMode.VARIABLE;
    }

    /**
    * @dev gets the current borrow rate of the user
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the borrow rate for the user,
    **/
    function getUserCurrentBorrowRate(address _reserve, address _user)
        internal
        view
        returns (uint256)
    {
        CoreLibrary.InterestRateMode rateMode = getUserCurrentBorrowRateMode(_reserve, _user);

        if (rateMode == CoreLibrary.InterestRateMode.NONE) {
            return 0;
        }

        return
            rateMode == CoreLibrary.InterestRateMode.STABLE
            ? usersReserveData[_user][_reserve].stableBorrowRate
            : reserves[_reserve].currentVariableBorrowRate;
    }

    /**
    * @dev the stable rate returned is 0 if the user is borrowing at variable or not borrowing at all
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the user stable rate
    **/
    function getUserCurrentStableBorrowRate(address _reserve, address _user)
        external
        view
        returns (uint256)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        return user.stableBorrowRate;
    }

    /**
    * @dev calculates and returns the borrow balances of the user
    * @param _reserve the address of the reserve
    * @param _user the address of the user
    * @return the principal borrow balance, the compounded balance and the balance increase since the last borrow/repay/swap/rebalance
    **/

    function getUserBorrowBalances(address _reserve, address _user)
        public
        view
        returns (uint256, uint256, uint256)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        if (user.principalBorrowBalance == 0) {
            return (0, 0, 0);
        }

        uint256 principal = user.principalBorrowBalance;
        uint256 compoundedBalance = CoreLibrary.getCompoundedBorrowBalance(
            user,
            reserves[_reserve]
        );
        return (principal, compoundedBalance, compoundedBalance.sub(principal));
    }

    /**
    * @dev the variable borrow index of the user is 0 if the user is not borrowing or borrowing at stable
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the variable borrow index for the user
    **/

    function getUserVariableBorrowCumulativeIndex(address _reserve, address _user)
        external
        view
        returns (uint256)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        return user.lastVariableBorrowCumulativeIndex;
    }

    /**
    * @dev the variable borrow index of the user is 0 if the user is not borrowing or borrowing at stable
    * @param _reserve the address of the reserve for which the information is needed
    * @param _user the address of the user for which the information is needed
    * @return the variable borrow index for the user
    **/

    function getUserLastUpdate(address _reserve, address _user)
        external
        view
        returns (uint256 timestamp)
    {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        timestamp = user.lastUpdateTimestamp;
    }

    /**
    * @dev updates the lending pool core configuration
    **/
    function refreshConfiguration() external onlyLendingPoolConfigurator {
        refreshConfigInternal();
    }

    /**
    * @dev initializes a reserve
    * @param _reserve the address of the reserve
    * @param _PTokenAddress the address of the overlying PToken contract
    * @param _decimals the decimals of the reserve currency
    * @param _interestRateStrategyAddress the address of the interest rate strategy contract
    **/
    function initReserve(
        address _reserve,
        address _PTokenAddress,
        uint256 _decimals,
        address _interestRateStrategyAddress
    ) external onlyLendingPoolConfigurator {
        reserves[_reserve].init(_PTokenAddress, _decimals, _interestRateStrategyAddress);
        addReserveToListInternal(_reserve);

    }



    /**
    * @dev removes the last added reserve in the reservesList array
    * @param _reserveToRemove the address of the reserve
    **/
    function removeLastAddedReserve(address _reserveToRemove)
     external onlyLendingPoolConfigurator {

        address lastReserve = reservesList[reservesList.length-1];

        require(lastReserve == _reserveToRemove, "Reserve being removed is different than the reserve requested");

        //as we can't check if totalLiquidity is 0 (since the reserve added might not be an ERC20) we at least check that there is nothing borrowed
        require(getReserveTotalBorrows(lastReserve) == 0, "Cannot remove a reserve with liquidity deposited");

        reserves[lastReserve].isActive = false;
        reserves[lastReserve].PTokenAddress = address(0);
        reserves[lastReserve].decimals = 0;
        reserves[lastReserve].lastLiquidityCumulativeIndex = 0;
        reserves[lastReserve].lastVariableBorrowCumulativeIndex = 0;
        reserves[lastReserve].borrowingEnabled = false;
        reserves[lastReserve].usageAsCollateralEnabled = false;
        reserves[lastReserve].baseLTVasCollateral = 0;
        reserves[lastReserve].liquidationThreshold = 0;
        reserves[lastReserve].liquidationBonus = 0;
        reserves[lastReserve].interestRateStrategyAddress = address(0);

        reservesList.pop();
    }

    /**
    * @dev updates the address of the interest rate strategy contract
    * @param _reserve the address of the reserve
    * @param _rateStrategyAddress the address of the interest rate strategy contract
    **/

    function setReserveInterestRateStrategyAddress(address _reserve, address _rateStrategyAddress)
        external
        onlyLendingPoolConfigurator
    {
        reserves[_reserve].interestRateStrategyAddress = _rateStrategyAddress;
    }

    /**
    * @dev enables borrowing on a reserve. Also sets the stable rate borrowing
    * @param _reserve the address of the reserve
    * @param _stableBorrowRateEnabled true if the stable rate needs to be enabled, false otherwise
    **/

    function enableBorrowingOnReserve(address _reserve, bool _stableBorrowRateEnabled)
        external
        onlyLendingPoolConfigurator
    {
        reserves[_reserve].enableBorrowing(_stableBorrowRateEnabled);
    }

    /**
    * @dev disables borrowing on a reserve
    * @param _reserve the address of the reserve
    **/

    function disableBorrowingOnReserve(address _reserve) external onlyLendingPoolConfigurator {
        reserves[_reserve].disableBorrowing();
    }

    /**
    * @dev enables a reserve to be used as collateral
    * @param _reserve the address of the reserve
    **/
    function enableReserveAsCollateral(
        address _reserve,
        uint256 _baseLTVasCollateral,
        uint256 _liquidationThreshold,
        uint256 _liquidationBonus
    ) external onlyLendingPoolConfigurator {
        reserves[_reserve].enableAsCollateral(
            _baseLTVasCollateral,
            _liquidationThreshold,
            _liquidationBonus
        );
    }

    /**
    * @dev disables a reserve to be used as collateral
    * @param _reserve the address of the reserve
    **/
    function disableReserveAsCollateral(address _reserve) external onlyLendingPoolConfigurator {
        reserves[_reserve].disableAsCollateral();
    }

    /**
    * @dev enable the stable borrow rate mode on a reserve
    * @param _reserve the address of the reserve
    **/
    function enableReserveStableBorrowRate(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.isStableBorrowRateEnabled = true;
    }

    /**
    * @dev disable the stable borrow rate mode on a reserve
    * @param _reserve the address of the reserve
    **/
    function disableReserveStableBorrowRate(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.isStableBorrowRateEnabled = false;
    }

    /**
    * @dev activates a reserve
    * @param _reserve the address of the reserve
    **/
    function activateReserve(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        require(
            reserve.lastLiquidityCumulativeIndex > 0 &&
                reserve.lastVariableBorrowCumulativeIndex > 0,
            "Reserve has not been initialized yet"
        );
        reserve.isActive = true;
    }

    /**
    * @dev deactivates a reserve
    * @param _reserve the address of the reserve
    **/
    function deactivateReserve(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.isActive = false;
    }

    /**
    * @notice allows the configurator to freeze the reserve.
    * A freezed reserve does not allow any action apart from repay, redeem, liquidationCall, rebalance.
    * @param _reserve the address of the reserve
    **/
    function freezeReserve(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.isFreezed = true;
    }

    /**
    * @notice allows the configurator to unfreeze the reserve. A unfreezed reserve allows any action to be executed.
    * @param _reserve the address of the reserve
    **/
    function unfreezeReserve(address _reserve) external onlyLendingPoolConfigurator {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.isFreezed = false;
    }

    /**
    * @notice allows the configurator to update the loan to value of a reserve
    * @param _reserve the address of the reserve
    * @param _ltv the new loan to value
    **/
    function setReserveBaseLTVasCollateral(address _reserve, uint256 _ltv)
        external
        onlyLendingPoolConfigurator
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.baseLTVasCollateral = _ltv;
    }

    /**
    * @notice allows the configurator to update the liquidation threshold of a reserve
    * @param _reserve the address of the reserve
    * @param _threshold the new liquidation threshold
    **/
    function setReserveLiquidationThreshold(address _reserve, uint256 _threshold)
        external
        onlyLendingPoolConfigurator
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.liquidationThreshold = _threshold;
    }

    /**
    * @notice allows the configurator to update the liquidation bonus of a reserve
    * @param _reserve the address of the reserve
    * @param _bonus the new liquidation bonus
    **/
    function setReserveLiquidationBonus(address _reserve, uint256 _bonus)
        external
        onlyLendingPoolConfigurator
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.liquidationBonus = _bonus;
    }

    /**
    * @notice allows the configurator to update the reserve decimals
    * @param _reserve the address of the reserve
    * @param _decimals the decimals of the reserve
    **/
    function setReserveDecimals(address _reserve, uint256 _decimals)
        external
        onlyLendingPoolConfigurator
    {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        reserve.decimals = _decimals;
    }

    /**
    * @notice internal functions
    **/

    /**
    * @dev updates the state of a reserve as a consequence of a borrow action.
    * @param _reserve the address of the reserve on which the user is borrowing
    * @param _user the address of the borrower
    * @param _principalBorrowBalance the previous borrow balance of the borrower before the action
    * @param _balanceIncrease the accrued interest of the user on the previous borrowed amount
    * @param _amountBorrowed the new amount borrowed
    * @param _rateMode the borrow rate mode (stable, variable)
    **/

    function updateReserveStateOnBorrowInternal(
        address _reserve,
        address _user,
        uint256 _principalBorrowBalance,
        uint256 _balanceIncrease,
        uint256 _amountBorrowed,
        CoreLibrary.InterestRateMode _rateMode
    ) internal {
        reserves[_reserve].updateCumulativeIndexes();

        //increasing reserve total borrows to account for the new borrow balance of the user
        //NOTE: Depending on the previous borrow mode, the borrows might need to be switched from variable to stable or vice versa

        updateReserveTotalBorrowsByRateModeInternal(
            _reserve,
            _user,
            _principalBorrowBalance,
            _balanceIncrease,
            _amountBorrowed,
            _rateMode
        );
    }

    /**
    * @dev updates the state of a user as a consequence of a borrow action.
    * @param _reserve the address of the reserve on which the user is borrowing
    * @param _user the address of the borrower
    * @param _amountBorrowed the amount borrowed
    * @param _balanceIncrease the accrued interest of the user on the previous borrowed amount
    * @param _rateMode the borrow rate mode (stable, variable)
    * @return the final borrow rate for the user. Emitted by the borrow() event
    **/

    function updateUserStateOnBorrowInternal(
        address _reserve,
        address _user,
        uint256 _amountBorrowed,
        uint256 _balanceIncrease,
        uint256 _fee,
        CoreLibrary.InterestRateMode _rateMode
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        if (_rateMode == CoreLibrary.InterestRateMode.STABLE) {
            //stable
            //reset the user variable index, and update the stable rate
            user.stableBorrowRate = reserve.currentStableBorrowRate;
            user.lastVariableBorrowCumulativeIndex = 0;
        } else if (_rateMode == CoreLibrary.InterestRateMode.VARIABLE) {
            //variable
            //reset the user stable rate, and store the new borrow index
            user.stableBorrowRate = 0;
            user.lastVariableBorrowCumulativeIndex = reserve.lastVariableBorrowCumulativeIndex;
        } else {
            revert("Invalid borrow rate mode");
        }
        //increase the principal borrows and the origination fee
        user.principalBorrowBalance = user.principalBorrowBalance.add(_amountBorrowed).add(
            _balanceIncrease
        );
        user.originationFee = user.originationFee.add(_fee);

        //solium-disable-next-line
        user.lastUpdateTimestamp = uint40(block.timestamp);

    }

    /**
    * @dev updates the state of the reserve as a consequence of a repay action.
    * @param _reserve the address of the reserve on which the user is repaying
    * @param _user the address of the borrower
    * @param _paybackAmountMinusFees the amount being paid back minus fees
    * @param _balanceIncrease the accrued interest on the borrowed amount
    **/

    function updateReserveStateOnRepayInternal(
        address _reserve,
        address _user,
        uint256 _paybackAmountMinusFees,
        uint256 _balanceIncrease
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_reserve][_user];

        CoreLibrary.InterestRateMode borrowRateMode = getUserCurrentBorrowRateMode(_reserve, _user);

        //update the indexes
        reserves[_reserve].updateCumulativeIndexes();

        //compound the cumulated interest to the borrow balance and then subtracting the payback amount
        if (borrowRateMode == CoreLibrary.InterestRateMode.STABLE) {
            reserve.increaseTotalBorrowsStableAndUpdateAverageRate(
                _balanceIncrease,
                user.stableBorrowRate
            );
            reserve.decreaseTotalBorrowsStableAndUpdateAverageRate(
                _paybackAmountMinusFees,
                user.stableBorrowRate
            );
        } else {
            reserve.increaseTotalBorrowsVariable(_balanceIncrease);
            reserve.decreaseTotalBorrowsVariable(_paybackAmountMinusFees);
        }
    }

    /**
    * @dev updates the state of the user as a consequence of a repay action.
    * @param _reserve the address of the reserve on which the user is repaying
    * @param _user the address of the borrower
    * @param _paybackAmountMinusFees the amount being paid back minus fees
    * @param _originationFeeRepaid the fee on the amount that is being repaid
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _repaidWholeLoan true if the user is repaying the whole loan
    **/
    function updateUserStateOnRepayInternal(
        address _reserve,
        address _user,
        uint256 _paybackAmountMinusFees,
        uint256 _originationFeeRepaid,
        uint256 _balanceIncrease,
        bool _repaidWholeLoan
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        //update the user principal borrow balance, adding the cumulated interest and then subtracting the payback amount
        user.principalBorrowBalance = user.principalBorrowBalance.add(_balanceIncrease).sub(
            _paybackAmountMinusFees
        );
        user.lastVariableBorrowCumulativeIndex = reserve.lastVariableBorrowCumulativeIndex;

        //if the balance decrease is equal to the previous principal (user is repaying the whole loan)
        //and the rate mode is stable, we reset the interest rate mode of the user
        if (_repaidWholeLoan) {
            user.stableBorrowRate = 0;
            user.lastVariableBorrowCumulativeIndex = 0;
        }
        user.originationFee = user.originationFee.sub(_originationFeeRepaid);

        //solium-disable-next-line
        user.lastUpdateTimestamp = uint40(block.timestamp);

    }

    /**
    * @dev updates the state of the user as a consequence of a swap rate action.
    * @param _reserve the address of the reserve on which the user is performing the rate swap
    * @param _user the address of the borrower
    * @param _principalBorrowBalance the the principal amount borrowed by the user
    * @param _compoundedBorrowBalance the principal amount plus the accrued interest
    * @param _currentRateMode the rate mode at which the user borrowed
    **/
    function updateReserveStateOnSwapRateInternal(
        address _reserve,
        address _user,
        uint256 _principalBorrowBalance,
        uint256 _compoundedBorrowBalance,
        CoreLibrary.InterestRateMode _currentRateMode
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        //compounding reserve indexes
        reserve.updateCumulativeIndexes();

        if (_currentRateMode == CoreLibrary.InterestRateMode.STABLE) {
            uint256 userCurrentStableRate = user.stableBorrowRate;

            //swap to variable
            reserve.decreaseTotalBorrowsStableAndUpdateAverageRate(
                _principalBorrowBalance,
                userCurrentStableRate
            ); //decreasing stable from old principal balance
            reserve.increaseTotalBorrowsVariable(_compoundedBorrowBalance); //increase variable borrows
        } else if (_currentRateMode == CoreLibrary.InterestRateMode.VARIABLE) {
            //swap to stable
            uint256 currentStableRate = reserve.currentStableBorrowRate;
            reserve.decreaseTotalBorrowsVariable(_principalBorrowBalance);
            reserve.increaseTotalBorrowsStableAndUpdateAverageRate(
                _compoundedBorrowBalance,
                currentStableRate
            );

        } else {
            revert("Invalid rate mode received");
        }
    }

    /**
    * @dev updates the state of the user as a consequence of a swap rate action.
    * @param _reserve the address of the reserve on which the user is performing the swap
    * @param _user the address of the borrower
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _currentRateMode the current rate mode of the user
    **/

    function updateUserStateOnSwapRateInternal(
        address _reserve,
        address _user,
        uint256 _balanceIncrease,
        CoreLibrary.InterestRateMode _currentRateMode
    ) internal returns (CoreLibrary.InterestRateMode) {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        CoreLibrary.InterestRateMode newMode = CoreLibrary.InterestRateMode.NONE;

        if (_currentRateMode == CoreLibrary.InterestRateMode.VARIABLE) {
            //switch to stable
            newMode = CoreLibrary.InterestRateMode.STABLE;
            user.stableBorrowRate = reserve.currentStableBorrowRate;
            user.lastVariableBorrowCumulativeIndex = 0;
        } else if (_currentRateMode == CoreLibrary.InterestRateMode.STABLE) {
            newMode = CoreLibrary.InterestRateMode.VARIABLE;
            user.stableBorrowRate = 0;
            user.lastVariableBorrowCumulativeIndex = reserve.lastVariableBorrowCumulativeIndex;
        } else {
            revert("Invalid interest rate mode received");
        }
        //compounding cumulated interest
        user.principalBorrowBalance = user.principalBorrowBalance.add(_balanceIncrease);
        //solium-disable-next-line
        user.lastUpdateTimestamp = uint40(block.timestamp);

        return newMode;
    }

    /**
    * @dev updates the state of the principal reserve as a consequence of a liquidation action.
    * @param _principalReserve the address of the principal reserve that is being repaid
    * @param _user the address of the borrower
    * @param _amountToLiquidate the amount being repaid by the liquidator
    * @param _balanceIncrease the accrued interest on the borrowed amount
    **/

    function updatePrincipalReserveStateOnLiquidationInternal(
        address _principalReserve,
        address _user,
        uint256 _amountToLiquidate,
        uint256 _balanceIncrease
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_principalReserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_principalReserve];

        //update principal reserve data
        reserve.updateCumulativeIndexes();

        CoreLibrary.InterestRateMode borrowRateMode = getUserCurrentBorrowRateMode(
            _principalReserve,
            _user
        );

        if (borrowRateMode == CoreLibrary.InterestRateMode.STABLE) {
            //increase the total borrows by the compounded interest
            reserve.increaseTotalBorrowsStableAndUpdateAverageRate(
                _balanceIncrease,
                user.stableBorrowRate
            );

            //decrease by the actual amount to liquidate
            reserve.decreaseTotalBorrowsStableAndUpdateAverageRate(
                _amountToLiquidate,
                user.stableBorrowRate
            );

        } else {
            //increase the total borrows by the compounded interest
            reserve.increaseTotalBorrowsVariable(_balanceIncrease);

            //decrease by the actual amount to liquidate
            reserve.decreaseTotalBorrowsVariable(_amountToLiquidate);
        }

    }

    /**
    * @dev updates the state of the collateral reserve as a consequence of a liquidation action.
    * @param _collateralReserve the address of the collateral reserve that is being liquidated
    **/
    function updateCollateralReserveStateOnLiquidationInternal(
        address _collateralReserve
    ) internal {
        //update collateral reserve
        reserves[_collateralReserve].updateCumulativeIndexes();

    }

    /**
    * @dev updates the state of the user being liquidated as a consequence of a liquidation action.
    * @param _reserve the address of the principal reserve that is being repaid
    * @param _user the address of the borrower
    * @param _amountToLiquidate the amount being repaid by the liquidator
    * @param _feeLiquidated the amount of origination fee being liquidated
    * @param _balanceIncrease the accrued interest on the borrowed amount
    **/
    function updateUserStateOnLiquidationInternal(
        address _reserve,
        address _user,
        uint256 _amountToLiquidate,
        uint256 _feeLiquidated,
        uint256 _balanceIncrease
    ) internal {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        //first increase by the compounded interest, then decrease by the liquidated amount
        user.principalBorrowBalance = user.principalBorrowBalance.add(_balanceIncrease).sub(
            _amountToLiquidate
        );

        if (
            getUserCurrentBorrowRateMode(_reserve, _user) == CoreLibrary.InterestRateMode.VARIABLE
        ) {
            user.lastVariableBorrowCumulativeIndex = reserve.lastVariableBorrowCumulativeIndex;
        }

        if(_feeLiquidated > 0){
            user.originationFee = user.originationFee.sub(_feeLiquidated);
        }

        //solium-disable-next-line
        user.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
    * @dev updates the state of the reserve as a consequence of a stable rate rebalance
    * @param _reserve the address of the principal reserve where the user borrowed
    * @param _user the address of the borrower
    * @param _balanceIncrease the accrued interest on the borrowed amount
    **/

    function updateReserveStateOnRebalanceInternal(
        address _reserve,
        address _user,
        uint256 _balanceIncrease
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];

        reserve.updateCumulativeIndexes();

        reserve.increaseTotalBorrowsStableAndUpdateAverageRate(
            _balanceIncrease,
            user.stableBorrowRate
        );

    }

    /**
    * @dev updates the state of the user as a consequence of a stable rate rebalance
    * @param _reserve the address of the principal reserve where the user borrowed
    * @param _user the address of the borrower
    * @param _balanceIncrease the accrued interest on the borrowed amount
    **/

    function updateUserStateOnRebalanceInternal(
        address _reserve,
        address _user,
        uint256 _balanceIncrease
    ) internal {
        CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        user.principalBorrowBalance = user.principalBorrowBalance.add(_balanceIncrease);
        user.stableBorrowRate = reserve.currentStableBorrowRate;

        //solium-disable-next-line
        user.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
    * @dev updates the state of the user as a consequence of a stable rate rebalance
    * @param _reserve the address of the principal reserve where the user borrowed
    * @param _user the address of the borrower
    * @param _balanceIncrease the accrued interest on the borrowed amount
    * @param _amountBorrowed the accrued interest on the borrowed amount
    **/
    function updateReserveTotalBorrowsByRateModeInternal(
        address _reserve,
        address _user,
        uint256 _principalBalance,
        uint256 _balanceIncrease,
        uint256 _amountBorrowed,
        CoreLibrary.InterestRateMode _newBorrowRateMode
    ) internal {
        CoreLibrary.InterestRateMode previousRateMode = getUserCurrentBorrowRateMode(
            _reserve,
            _user
        );
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];

        if (previousRateMode == CoreLibrary.InterestRateMode.STABLE) {
            CoreLibrary.UserReserveData storage user = usersReserveData[_user][_reserve];
            reserve.decreaseTotalBorrowsStableAndUpdateAverageRate(
                _principalBalance,
                user.stableBorrowRate
            );
        } else if (previousRateMode == CoreLibrary.InterestRateMode.VARIABLE) {
            reserve.decreaseTotalBorrowsVariable(_principalBalance);
        }

        uint256 newPrincipalAmount = _principalBalance.add(_balanceIncrease).add(_amountBorrowed);
        if (_newBorrowRateMode == CoreLibrary.InterestRateMode.STABLE) {
            reserve.increaseTotalBorrowsStableAndUpdateAverageRate(
                newPrincipalAmount,
                reserve.currentStableBorrowRate
            );
        } else if (_newBorrowRateMode == CoreLibrary.InterestRateMode.VARIABLE) {
            reserve.increaseTotalBorrowsVariable(newPrincipalAmount);
        } else {
            revert("Invalid new borrow rate mode");
        }
    }

    /**
    * @dev Updates the reserve current stable borrow rate Rf, the current variable borrow rate Rv and the current liquidity rate Rl.
    * Also updates the lastUpdateTimestamp value. Please refer to the whitepaper for further information.
    * @param _reserve the address of the reserve to be updated
    * @param _liquidityAdded the amount of liquidity added to the protocol (deposit or repay) in the previous action
    * @param _liquidityTaken the amount of liquidity taken from the protocol (redeem or borrow)
    **/

    function updateReserveInterestRatesAndTimestampInternal(
        address _reserve,
        uint256 _liquidityAdded,
        uint256 _liquidityTaken
    ) internal {
        CoreLibrary.ReserveData storage reserve = reserves[_reserve];
        (uint256 newLiquidityRate, uint256 newStableRate, uint256 newVariableRate) = IReserveInterestRateStrategy(
            reserve
                .interestRateStrategyAddress
        )
            .calculateInterestRates(
            _reserve,
            getReserveAvailableLiquidity(_reserve).add(_liquidityAdded).sub(_liquidityTaken),
            reserve.totalBorrowsStable,
            reserve.totalBorrowsVariable,
            reserve.currentAverageStableBorrowRate
        );

        reserve.currentLiquidityRate = newLiquidityRate;
        reserve.currentStableBorrowRate = newStableRate;
        reserve.currentVariableBorrowRate = newVariableRate;

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);

        emit ReserveUpdated(
            _reserve,
            newLiquidityRate,
            newStableRate,
            newVariableRate,
            reserve.lastLiquidityCumulativeIndex,
            reserve.lastVariableBorrowCumulativeIndex
        );
    }

    /**
    * @dev transfers to the protocol fees of a flashloan to the fees collection address
    * @param _token the address of the token being transferred
    * @param _amount the amount being transferred
    **/

    function transferFlashLoanProtocolFeeInternal(address _token, uint256 _amount) internal {
        address payable receiver = address(uint160(addressesProvider.getTokenDistributor()));

        if (_token != EthAddressLib.ethAddress()) {
            ERC20(_token).safeTransfer(receiver, _amount);
        } else {
            receiver.transfer(_amount);
        }
    }

    /**
    * @dev updates the internal configuration of the core
    **/
    function refreshConfigInternal() internal {
        lendingPoolAddress = addressesProvider.getLendingPool();
    }

    /**
    * @dev adds a reserve to the array of the reserves address
    **/
    function addReserveToListInternal(address _reserve) internal {
        bool reserveAlreadyAdded = false;
        for (uint256 i = 0; i < reservesList.length; i++)
            if (reservesList[i] == _reserve) {
                reserveAlreadyAdded = true;
            }
        if (!reserveAlreadyAdded) reservesList.push(_reserve);
    }

}

pragma solidity ^0.5.0;

/**
* IReserveInterestRateStrategyInterface interface
* -
* Interface for the calculation of the interest rates.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface IReserveInterestRateStrategy {

    /**
    * @dev returns the base variable borrow rate, in rays
    */

    function getBaseVariableBorrowRate() external view returns (uint256);
    /**
    * @dev calculates the liquidity, stable, and variable rates depending on the current utilization rate
    *      and the base parameters
    *
    */
    function calculateInterestRates(
        address _reserve,
        uint256 _utilizationRate,
        uint256 _totalBorrowsStable,
        uint256 _totalBorrowsVariable,
        uint256 _averageStableBorrowRate)
    external
    view
    returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate);
}

pragma solidity ^0.5.0;

//note create a proper PToken interface

interface IPToken {
    event Redeem(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event MintOnDeposit(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event BurnOnLiquidation(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event BalanceTransfer(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _toBalanceIncrease,
        uint256 _fromIndex,
        uint256 _toIndex
    );
    event InterestStreamRedirected(
        address indexed _from,
        address indexed _to,
        uint256 _redirectedBalance,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event RedirectedBalanceUpdated(
        address indexed _targetAddress,
        uint256 _targetBalanceIncrease,
        uint256 _targetIndex,
        uint256 _redirectedBalanceAdded,
        uint256 _redirectedBalanceRemoved
    );
    event InterestRedirectionAllowanceChanged(
        address indexed _from,
        address indexed _to
    );

    function balanceOf(address _user) external view returns (uint256);
}

pragma solidity ^0.5.0;

/**
* ILendingRateOracle interface
* -
* Interface for the Populous borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface ILendingRateOracle {
    /**
    @dev returns the market borrow rate in ray
    **/
    function getMarketBorrowRate(address _asset) external view returns (uint256);

    /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
    function setMarketBorrowRate(address _asset, uint256 _rate) external;
}

pragma solidity ^0.5.0;

/**
* ILendingPoolAddressesProvider interface
* -
* Provides the interface to fetch the LendingPoolCore address
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

contract ILendingPoolAddressesProvider {

    function getLendingPool() public view returns (address);
    function setLendingPoolImpl(address _pool) public;

    function getLendingPoolCore() public view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public;

    function getLendingPoolConfigurator() public view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public;

    function getLendingPoolDataProvider() public view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public;

    function getLendingPoolParametersProvider() public view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public;

    function getTokenDistributor() public view returns (address);
    function setTokenDistributor(address _tokenDistributor) public;


    function getFeeProvider() public view returns (address);
    function setFeeProviderImpl(address _feeProvider) public;

    function getLendingPoolLiquidationManager() public view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public;

    function getLendingPoolManager() public view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public;

    function getPriceOracle() public view returns (address);
    function setPriceOracle(address _priceOracle) public;

    function getLendingRateOracle() public view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public;

}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../libraries/openzeppelin-upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "./AddressStorage.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

/**
* LendingPoolAddressesProvider contract
* -
* Is the main registry of the protocol. All the different components of the protocol are accessible
* through the addresses provider.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

/**


 */

contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider, AddressStorage {
    //events
    event LendingPoolUpdated(address indexed newAddress);
    event LendingPoolCoreUpdated(address indexed newAddress);
    event LendingPoolParametersProviderUpdated(address indexed newAddress);
    event LendingPoolManagerUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolLiquidationManagerUpdated(address indexed newAddress);
    event LendingPoolDataProviderUpdated(address indexed newAddress);
    event EthereumAddressUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event FeeProviderUpdated(address indexed newAddress);
    event TokenDistributorUpdated(address indexed newAddress);

    event ProxyCreated(bytes32 id, address indexed newAddress);

    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant LENDING_POOL_CORE = "LENDING_POOL_CORE";
    bytes32 private constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant LENDING_POOL_PARAMETERS_PROVIDER = "PARAMETERS_PROVIDER";
    bytes32 private constant LENDING_POOL_MANAGER = "LENDING_POOL_MANAGER";
    bytes32 private constant LENDING_POOL_LIQUIDATION_MANAGER = "LIQUIDATION_MANAGER";
    bytes32 private constant LENDING_POOL_FLASHLOAN_PROVIDER = "FLASHLOAN_PROVIDER";
    bytes32 private constant DATA_PROVIDER = "DATA_PROVIDER";
    bytes32 private constant ETHEREUM_ADDRESS = "ETHEREUM_ADDRESS";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";
    bytes32 private constant FEE_PROVIDER = "FEE_PROVIDER";
    bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";
    bytes32 private constant TOKEN_DISTRIBUTOR = "TOKEN_DISTRIBUTOR";


    /**
    * @dev returns the address of the LendingPool proxy
    * @return the lending pool proxy address
    **/
    function getLendingPool() public view returns (address) {
        return getAddress(LENDING_POOL);
    }


    /**
    * @dev updates the implementation of the lending pool
    * @param _pool the new lending pool implementation
    **/
    function setLendingPoolImpl(address _pool) public onlyOwner {
        updateImplInternal(LENDING_POOL, _pool);
        emit LendingPoolUpdated(_pool);
    }

    /**
    * @dev returns the address of the LendingPoolCore proxy
    * @return the lending pool core proxy address
     */
    function getLendingPoolCore() public view returns (address payable) {
        address payable core = address(uint160(getAddress(LENDING_POOL_CORE)));
        return core;
    }

    /**
    * @dev updates the implementation of the lending pool core
    * @param _lendingPoolCore the new lending pool core implementation
    **/
    function setLendingPoolCoreImpl(address _lendingPoolCore) public onlyOwner {
        updateImplInternal(LENDING_POOL_CORE, _lendingPoolCore);
        emit LendingPoolCoreUpdated(_lendingPoolCore);
    }

    /**
    * @dev returns the address of the LendingPoolConfigurator proxy
    * @return the lending pool configurator proxy address
    **/
    function getLendingPoolConfigurator() public view returns (address) {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    /**
    * @dev updates the implementation of the lending pool configurator
    * @param _configurator the new lending pool configurator implementation
    **/
    function setLendingPoolConfiguratorImpl(address _configurator) public onlyOwner {
        updateImplInternal(LENDING_POOL_CONFIGURATOR, _configurator);
        emit LendingPoolConfiguratorUpdated(_configurator);
    }

    /**
    * @dev returns the address of the LendingPoolDataProvider proxy
    * @return the lending pool data provider proxy address
     */
    function getLendingPoolDataProvider() public view returns (address) {
        return getAddress(DATA_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool data provider
    * @param _provider the new lending pool data provider implementation
    **/
    function setLendingPoolDataProviderImpl(address _provider) public onlyOwner {
        updateImplInternal(DATA_PROVIDER, _provider);
        emit LendingPoolDataProviderUpdated(_provider);
    }

    /**
    * @dev returns the address of the LendingPoolParametersProvider proxy
    * @return the address of the Lending pool parameters provider proxy
    **/
    function getLendingPoolParametersProvider() public view returns (address) {
        return getAddress(LENDING_POOL_PARAMETERS_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool parameters provider
    * @param _parametersProvider the new lending pool parameters provider implementation
    **/
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public onlyOwner {
        updateImplInternal(LENDING_POOL_PARAMETERS_PROVIDER, _parametersProvider);
        emit LendingPoolParametersProviderUpdated(_parametersProvider);
    }

    /**
    * @dev returns the address of the FeeProvider proxy
    * @return the address of the Fee provider proxy
    **/
    function getFeeProvider() public view returns (address) {
        return getAddress(FEE_PROVIDER);
    }

    /**
    * @dev updates the implementation of the FeeProvider proxy
    * @param _feeProvider the new lending pool fee provider implementation
    **/
    function setFeeProviderImpl(address _feeProvider) public onlyOwner {
        updateImplInternal(FEE_PROVIDER, _feeProvider);
        emit FeeProviderUpdated(_feeProvider);
    }

    /**
    * @dev returns the address of the LendingPoolLiquidationManager. Since the manager is used
    * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
    * the addresses are changed directly.
    * @return the address of the Lending pool liquidation manager
    **/

    function getLendingPoolLiquidationManager() public view returns (address) {
        return getAddress(LENDING_POOL_LIQUIDATION_MANAGER);
    }

    /**
    * @dev updates the address of the Lending pool liquidation manager
    * @param _manager the new lending pool liquidation manager address
    **/
    function setLendingPoolLiquidationManager(address _manager) public onlyOwner {
        _setAddress(LENDING_POOL_LIQUIDATION_MANAGER, _manager);
        emit LendingPoolLiquidationManagerUpdated(_manager);
    }

    /**
    * @dev the functions below are storing specific addresses that are outside the context of the protocol
    * hence the upgradable proxy pattern is not used
    **/


    function getLendingPoolManager() public view returns (address) {
        return getAddress(LENDING_POOL_MANAGER);
    }

    function setLendingPoolManager(address _lendingPoolManager) public onlyOwner {
        _setAddress(LENDING_POOL_MANAGER, _lendingPoolManager);
        emit LendingPoolManagerUpdated(_lendingPoolManager);
    }

    function getPriceOracle() public view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address _priceOracle) public onlyOwner {
        _setAddress(PRICE_ORACLE, _priceOracle);
        emit PriceOracleUpdated(_priceOracle);
    }

    function getLendingRateOracle() public view returns (address) {
        return getAddress(LENDING_RATE_ORACLE);
    }

    function setLendingRateOracle(address _lendingRateOracle) public onlyOwner {
        _setAddress(LENDING_RATE_ORACLE, _lendingRateOracle);
        emit LendingRateOracleUpdated(_lendingRateOracle);
    }


    function getTokenDistributor() public view returns (address) {
        return getAddress(TOKEN_DISTRIBUTOR);
    }

    function setTokenDistributor(address _tokenDistributor) public onlyOwner {
        _setAddress(TOKEN_DISTRIBUTOR, _tokenDistributor);
        emit TokenDistributorUpdated(_tokenDistributor);
    }


    /**
    * @dev internal function to update the implementation of a specific component of the protocol
    * @param _id the id of the contract to be updated
    * @param _newAddress the address of the new implementation
    **/
    function updateImplInternal(bytes32 _id, address _newAddress) internal {
        address payable proxyAddress = address(uint160(getAddress(_id)));

        InitializableAdminUpgradeabilityProxy proxy = InitializableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableAdminUpgradeabilityProxy();
            proxy.initialize(_newAddress, address(this), params);
            _setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
        } else {
            proxy.upgradeToAndCall(_newAddress, params);
        }

    }
}

pragma solidity ^0.5.0;

contract AddressStorage {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
    }

}

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}