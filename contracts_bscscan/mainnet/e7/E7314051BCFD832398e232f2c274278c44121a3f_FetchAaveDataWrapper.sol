// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/ILendingPoolV1.sol";
import "./interfaces/ILendingPoolV2.sol";
import "./interfaces/IFetchAaveDataWrapper.sol";
import "./interfaces/ILendingPoolCore.sol";
import "@kyber.network/utils-sc/contracts/Withdrawable.sol";
import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";

/// Fetch data for multiple users or reserves from AAVE
/// Checkout list deployed AAVE's contracts here
/// https://docs.aave.com/developers/deployed-contracts/deployed-contract-instances
contract FetchAaveDataWrapper is Withdrawable, IFetchAaveDataWrapper {
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant RATE_PRECISION = 10**27;

    constructor(address _admin) Withdrawable(_admin) {}

    function getReserves(address pool, bool isV1)
        external
        view
        override
        returns (address[] memory reserves)
    {
        if (isV1) {
            return ILendingPoolV1(pool).getReserves();
        }
        return ILendingPoolV2(pool).getReservesList();
    }

    function getReservesConfigurationData(
        address pool,
        bool isV1,
        address[] calldata _reserves
    ) external view override returns (ReserveConfigData[] memory configsData) {
        configsData = new ReserveConfigData[](_reserves.length);
        for (uint256 i = 0; i < _reserves.length; i++) {
            if (isV1) {
                (
                    configsData[i].ltv,
                    configsData[i].liquidationThreshold,
                    configsData[i].liquidationBonus, // rate strategy address
                    ,
                    configsData[i].usageAsCollateralEnabled,
                    configsData[i].borrowingEnabled,
                    configsData[i].stableBorrowRateEnabled,
                    configsData[i].isActive
                ) = ILendingPoolV1(pool).getReserveConfigurationData(_reserves[i]);
                configsData[i].aTokenAddress = ILendingPoolCore(ILendingPoolV1(pool).core())
                .getReserveATokenAddress(_reserves[i]);
            } else {
                IProtocolDataProvider provider = IProtocolDataProvider(pool);
                (
                    ,
                    // decimals
                    configsData[i].ltv,
                    configsData[i].liquidationThreshold,
                    configsData[i].liquidationBonus, // reserve factor
                    ,
                    configsData[i].usageAsCollateralEnabled,
                    configsData[i].borrowingEnabled,
                    configsData[i].stableBorrowRateEnabled,
                    configsData[i].isActive,

                ) = provider.getReserveConfigurationData(_reserves[i]);
                (configsData[i].aTokenAddress, , ) = provider.getReserveTokensAddresses(
                    _reserves[i]
                );
            }
        }
    }

    function getReservesData(
        address pool,
        bool isV1,
        address[] calldata _reserves
    ) external view override returns (ReserveData[] memory reservesData) {
        reservesData = new ReserveData[](_reserves.length);
        if (isV1) {
            ILendingPoolCore core = ILendingPoolCore(ILendingPoolV1(pool).core());
            for (uint256 i = 0; i < _reserves.length; i++) {
                reservesData[i].totalLiquidity = core.getReserveTotalLiquidity(_reserves[i]);
                reservesData[i].availableLiquidity = core.getReserveAvailableLiquidity(
                    _reserves[i]
                );
                reservesData[i].utilizationRate = core.getReserveUtilizationRate(_reserves[i]);
                reservesData[i].liquidityRate = core.getReserveCurrentLiquidityRate(_reserves[i]);

                reservesData[i].totalBorrowsStable = core.getReserveTotalBorrowsStable(
                    _reserves[i]
                );
                reservesData[i].totalBorrowsVariable = core.getReserveTotalBorrowsVariable(
                    _reserves[i]
                );

                reservesData[i].variableBorrowRate = core.getReserveCurrentVariableBorrowRate(
                    _reserves[i]
                );
                reservesData[i].stableBorrowRate = core.getReserveCurrentStableBorrowRate(
                    _reserves[i]
                );
                reservesData[i].averageStableBorrowRate = core
                .getReserveCurrentAverageStableBorrowRate(_reserves[i]);
            }
        } else {
            IProtocolDataProvider provider = IProtocolDataProvider(pool);
            for (uint256 i = 0; i < _reserves.length; i++) {
                (
                    reservesData[i].availableLiquidity,
                    reservesData[i].totalBorrowsStable,
                    reservesData[i].totalBorrowsVariable,
                    reservesData[i].liquidityRate,
                    reservesData[i].variableBorrowRate,
                    reservesData[i].stableBorrowRate,
                    reservesData[i].averageStableBorrowRate,
                    ,
                    ,

                ) = provider.getReserveData(_reserves[i]);
                (address aTokenAddress, , ) = provider.getReserveTokensAddresses(_reserves[i]);
                reservesData[i].availableLiquidity = IERC20Ext(_reserves[i]).balanceOf(
                    aTokenAddress
                );

                reservesData[i].totalLiquidity =
                    reservesData[i].availableLiquidity +
                    reservesData[i].totalBorrowsStable +
                    reservesData[i].totalBorrowsVariable;
                if (reservesData[i].totalLiquidity > 0) {
                    reservesData[i].utilizationRate =
                        RATE_PRECISION -
                        (reservesData[i].availableLiquidity * RATE_PRECISION) /
                        reservesData[i].totalLiquidity;
                }
            }
        }
    }

    function getUserAccountsData(
        address pool,
        bool isV1,
        address[] calldata _users
    ) external view override returns (UserAccountData[] memory accountsData) {
        accountsData = new UserAccountData[](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            accountsData[i] = getSingleUserAccountData(pool, isV1, _users[i]);
        }
    }

    function getUserReservesData(
        address pool,
        bool isV1,
        address[] calldata _reserves,
        address _user
    ) external view override returns (UserReserveData[] memory userReservesData) {
        userReservesData = new UserReserveData[](_reserves.length);
        for (uint256 i = 0; i < _reserves.length; i++) {
            if (isV1) {
                userReservesData[i] = getSingleUserReserveDataV1(
                    ILendingPoolV1(pool),
                    _reserves[i],
                    _user
                );
            } else {
                userReservesData[i] = getSingleUserReserveDataV2(
                    IProtocolDataProvider(pool),
                    _reserves[i],
                    _user
                );
            }
        }
    }

    function getUsersReserveData(
        address pool,
        bool isV1,
        address _reserve,
        address[] calldata _users
    ) external view override returns (UserReserveData[] memory userReservesData) {
        userReservesData = new UserReserveData[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            if (isV1) {
                userReservesData[i] = getSingleUserReserveDataV1(
                    ILendingPoolV1(pool),
                    _reserve,
                    _users[i]
                );
            } else {
                userReservesData[i] = getSingleUserReserveDataV2(
                    IProtocolDataProvider(pool),
                    _reserve,
                    _users[i]
                );
            }
        }
    }

    function getSingleUserReserveDataV1(
        ILendingPoolV1 pool,
        address _reserve,
        address _user
    ) public view returns (UserReserveData memory data) {
        (
            data.currentATokenBalance,
            data.currentBorrowBalance,
            data.principalBorrowBalance,
            data.borrowRateMode,
            data.borrowRate,
            data.liquidityRate,
            data.originationFee,
            ,
            ,
            data.usageAsCollateralEnabled
        ) = pool.getUserReserveData(_reserve, _user);
        IERC20Ext aToken = IERC20Ext(
            ILendingPoolCore(pool.core()).getReserveATokenAddress(_reserve)
        );
        uint256 totalSupply = aToken.totalSupply();
        if (totalSupply > 0) {
            data.poolShareInPrecision = (aToken.balanceOf(_user) * RATE_PRECISION) / totalSupply;
        }
    }

    function getSingleUserReserveDataV2(
        IProtocolDataProvider provider,
        address _reserve,
        address _user
    ) public view returns (UserReserveData memory data) {
        {
            (
                data.currentATokenBalance,
                data.currentStableDebt,
                data.currentVariableDebt,
                data.principalStableDebt,
                data.scaledVariableDebt,
                data.stableBorrowRate,
                data.liquidityRate,
                ,
                data.usageAsCollateralEnabled
            ) = provider.getUserReserveData(_reserve, _user);
        }
        {
            (address aTokenAddress, , ) = provider.getReserveTokensAddresses(_reserve);
            uint256 totalSupply = IERC20Ext(aTokenAddress).totalSupply();
            if (totalSupply > 0) {
                data.poolShareInPrecision =
                    (IERC20Ext(aTokenAddress).balanceOf(_user) * RATE_PRECISION) /
                    totalSupply;
            }
        }
    }

    function getSingleUserAccountData(
        address pool,
        bool isV1,
        address _user
    ) public view returns (UserAccountData memory data) {
        if (isV1) {
            (
                data.totalLiquidityETH,
                data.totalCollateralETH,
                data.totalBorrowsETH,
                data.totalFeesETH,
                data.availableBorrowsETH,
                data.currentLiquidationThreshold,
                data.ltv,
                data.healthFactor
            ) = ILendingPoolV1(pool).getUserAccountData(_user);
            return data;
        }
        (
            data.totalCollateralETH,
            data.totalBorrowsETH,
            data.availableBorrowsETH,
            data.currentLiquidationThreshold,
            data.ltv,
            data.healthFactor
        ) = ILendingPoolV2(pool).getUserAccountData(_user);
    }
}

pragma solidity 0.7.6;


interface ILendingPoolV1{
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function core() external view returns (address);
    function getReserves() external view returns (address[] memory);
    function getReserveConfigurationData(address _reserve)
        external
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
        );
    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";
import "./IProtocolDataProvider.sol";

interface ILendingPoolV2 {
  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  function getReservesList() external view returns (address[] memory);
  function getAddressesProvider() external view returns (IProtocolDataProvider);
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


interface IFetchAaveDataWrapper {
    struct ReserveConfigData {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool stableBorrowRateEnabled;
        bool isActive;
        address aTokenAddress;
    }

    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalBorrowsStable;
        uint256 totalBorrowsVariable;
        uint256 liquidityRate;
        uint256 variableBorrowRate;
        uint256 stableBorrowRate;
        uint256 averageStableBorrowRate;
        uint256 totalLiquidity;
        uint256 utilizationRate;
    }

    struct UserAccountData {
        uint256 totalLiquidityETH; // only v1
        uint256 totalCollateralETH;
        uint256 totalBorrowsETH;
        uint256 totalFeesETH; // only v1
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 liquidityRate;
        uint256 poolShareInPrecision;
        bool usageAsCollateralEnabled;
        // v1 data
        uint256 currentBorrowBalance;
        uint256 principalBorrowBalance;
        uint256 borrowRateMode;
        uint256 borrowRate;
        uint256 originationFee;
        // v2 data
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
    }

    function getReserves(address pool, bool isV1) external view returns (address[] memory);
    function getReservesConfigurationData(address pool, bool isV1, address[] calldata _reserves)
        external
        view
        returns (
            ReserveConfigData[] memory configsData
        );

    function getReservesData(address pool, bool isV1, address[] calldata _reserves)
        external
        view
        returns (
            ReserveData[] memory reservesData
        );

    function getUserAccountsData(address pool, bool isV1, address[] calldata _users)
        external
        view
        returns (
            UserAccountData[] memory accountsData
        );

    function getUserReservesData(address pool, bool isV1, address[] calldata _reserves, address _user)
        external
        view
        returns (
            UserReserveData[] memory userReservesData
        );

    function getUsersReserveData(address pool, bool isV1, address _reserve, address[] calldata _users)
        external
        view
        returns (
            UserReserveData[] memory userReservesData
        );
}

pragma solidity 0.7.6;


interface ILendingPoolCore {
    function getReserveATokenAddress(address _reserve) external view returns (address);
    function getReserveTotalLiquidity(address _reserve) external view returns (uint256);
    function getReserveAvailableLiquidity(address _reserve) external view returns (uint256);
    function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256);
    function getReserveUtilizationRate(address _reserve) external view returns (uint256);

    function getReserveTotalBorrowsStable(address _reserve) external view returns (uint256);
    function getReserveTotalBorrowsVariable(address _reserve) external view returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256);
    function getReserveCurrentStableBorrowRate(address _reserve) external view returns (uint256);
    function getReserveCurrentAverageStableBorrowRate(address _reserve) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IERC20Ext.sol";
import "./PermissionAdmin.sol";


abstract contract Withdrawable is PermissionAdmin {
    using SafeERC20 for IERC20Ext;

    event TokenWithdraw(IERC20Ext token, uint256 amount, address sendTo);
    event EtherWithdraw(uint256 amount, address sendTo);

    constructor(address _admin) PermissionAdmin(_admin) {}

    /**
     * @dev Withdraw all IERC20Ext compatible tokens
     * @param token IERC20Ext The address of the token contract
     */
    function withdrawToken(
        IERC20Ext token,
        uint256 amount,
        address sendTo
    ) external onlyAdmin {
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint256 amount, address payable sendTo) external onlyAdmin {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "withdraw failed");
        emit EtherWithdraw(amount, sendTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

pragma solidity 0.7.6;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IProtocolDataProvider {
  function getReserveConfigurationData(address asset)
    external view returns(
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
  function getReserveData(address asset)
    external view returns (
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate,
        uint256 averageStableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 lastUpdateTimestamp
    );
  function getUserReserveData(address asset, address user)
    external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
  function getReserveTokensAddresses(address asset)
    external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
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

pragma solidity >=0.6.2 <0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

