// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Math library
/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library Math {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  ///@return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a*b, in wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a/b, in wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a*b, in ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a/b, in ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /// @dev Casts ray down to wad
  /// @param a Ray
  /// @return a casted to wad, rounded half up to the nearest wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  /// @param a Wad
  /// @return a converted in ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: MIT

import './interfaces/IProtocolTreasury.sol';
import './interfaces/IProtocolAddressProvider.sol';
import '../core/libraries/Math.sol';
import './storage/ProtocolTreasuryStorage.sol';

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

pragma solidity ^0.8.4;

/// @title ProtocolTreasury
/// @notice ProtocolTreasury manages accrued treasury in the protocol. Only governance contract can finance
/// the asset in this contract.
contract ProtocolTreasury is Initializable, IProtocolTreasury, ProtocolTreasuryStorage {
  using Math for uint256;

  modifier onlyGovernance() {
    if (msg.sender != _protocolAddressProvider.getGovernance()) revert OnlyGovernance();
    _;
  }

  function initialize(
    IProtocolAddressProvider protocolAddressProvider,
    uint256 base,
    uint256 baseFee,
    uint256 maxFee
  ) public initializer {
    _protocolAddressProvider = protocolAddressProvider;
    _stabilityFee.base = base;
    _stabilityFee.baseFee = baseFee;
    _stabilityFee.maxFee = maxFee;
  }

  /// @inheritdoc IProtocolTreasury
  function getProtocolAddressProvider()
    external
    view
    override
    returns (IProtocolAddressProvider protocolAddressProvider)
  {
    return _protocolAddressProvider;
  }

  function getStabilityFee()
    external
    view
    override
    returns (
      uint256 base,
      uint256 baseFee,
      uint256 maxFee
    )
  {
    base = _stabilityFee.base;
    baseFee = _stabilityFee.baseFee;
    maxFee = _stabilityFee.maxFee;
  }

  function setStabilityFee(
    uint256 base,
    uint256 baseFee,
    uint256 maxFee
  ) external override onlyGovernance {
    _stabilityFee.base = base;
    _stabilityFee.baseFee = baseFee;
    _stabilityFee.maxFee = maxFee;

    emit UpdateStabilityFee(base, baseFee, maxFee);
  }

  function calculateStabilityFeeRate(
    uint256 totalDebtTokenSupply,
    uint256 poolRemainingLiquidity,
    uint256 poolRemainingLiquidityAfterAction
  ) external view override returns (uint256 stabilityFee) {
    uint256 feeBefore = _calculateStabilityFee(
      _getUtilizationRate(totalDebtTokenSupply, poolRemainingLiquidity)
    );

    uint256 feeAfter = _calculateStabilityFee(
      _getUtilizationRate(totalDebtTokenSupply, poolRemainingLiquidityAfterAction)
    );

    stabilityFee = (feeBefore + feeAfter) / 2;
  }

  function _calculateStabilityFee(uint256 utilizationRate) internal view returns (uint256 fee) {
    StabilityFee memory vars = _stabilityFee;

    if (utilizationRate < vars.base) {
      return 0;
    } else {
      fee =
        vars.baseFee +
        (vars.maxFee - vars.baseFee).rayDiv(Math.ray() - vars.base).rayMul(
          utilizationRate - vars.base
        );
    }
  }

  function _getUtilizationRate(uint256 totalDebt, uint256 availableLiquidity)
    private
    pure
    returns (uint256)
  {
    return totalDebt == 0 ? 0 : totalDebt.rayDiv(availableLiquidity + totalDebt);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error OnlyGovernance();
error OnlyGuardian();
error OnlyCouncil();
error OnlyCore();

interface IProtocolAddressProvider {
  /// @notice emitted when liquidationManager address updated
  event UpdateLiquidationManager(address liquidationManager);

  /// @notice emitted when loanManager address updated
  event UpdateLoanManager(address loanManager);

  /// @notice emitted when incentiveManager address updated
  event UpdateIncentiveManager(address incentiveManager);

  /// @notice emitted when governance address updated
  event UpdateGovernance(address governance);

  /// @notice emitted when council address updated
  event UpdateCouncil(address council);

  /// @notice emitted when core address updated
  event UpdateCore(address core);

  /// @notice emitted when treasury address updated
  event UpdateTreasury(address treasury);

  /// @notice emitted when protocol address provider initialized
  event ProtocolAddressProviderInitialized(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treausury
  );

  /// @notice ProtocolAddressProvider should be initialized after deploying protocol contracts finished.
  /// @param guardian guardian
  /// @param liquidationManager liquidationManager
  /// @param loanManager loanManager
  /// @param incentiveManager incentiveManager
  /// @param governance governance
  /// @param council council
  /// @param core core
  /// @param treasury treasury
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external;

  /// @notice This function returns the address of the guardian
  /// @return guardian The address of the protocol guardian
  function getGuardian() external view returns (address guardian);

  /// @notice This function returns the address of liquidationManager contract
  /// @return liquidationManager The address of liquidationManager contract
  function getLiquidationManager() external view returns (address liquidationManager);

  /// @notice This function returns the address of LoanManager contract
  /// @return loanManager The address of LoanManager contract
  function getLoanManager() external view returns (address loanManager);

  /// @notice This function returns the address of incentiveManager contract
  /// @return incentiveManager The address of incentiveManager contract
  function getIncentiveManager() external view returns (address incentiveManager);

  /// @notice This function returns the address of governance contract
  /// @return governance The address of governance contract
  function getGovernance() external view returns (address governance);

  /// @notice This function returns the address of council contract
  /// @return council The address of council contract
  function getCouncil() external view returns (address council);

  /// @notice This function returns the address of core contract
  /// @return core The address of core contract
  function getCore() external view returns (address core);

  /// @notice This function returns the address of protocolTreasury contract
  /// @return protocolTreasury The address of protocolTreasury contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function updates the address of liquidationManager contract
  /// @param liquidationManager The address of liquidationManager contract to update
  function updateLiquidationManager(address liquidationManager) external;

  /// @notice This function updates the address of LoanManager contract
  /// @param loanManager The address of LoanManager contract to update
  function updateLoanManager(address loanManager) external;

  /// @notice This function updates the address of incentiveManager contract
  /// @param incentiveManager The address of incentiveManager contract to update
  function updateIncentiveManager(address incentiveManager) external;

  /// @notice This function updates the address of governance contract
  /// @param governance The address of governance contract to update
  function updateGovernance(address governance) external;

  /// @notice This function updates the address of council contract
  /// @param council The address of council contract to update
  function updateCouncil(address council) external;

  /// @notice This function updates the address of core contract
  /// @param core The address of core contract to update
  function updateCore(address core) external;

  /// @notice This function updates the address of treasury contract
  /// @param treasury The address of treasury contract to update
  function updateTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IProtocolAddressProvider.sol';

interface IProtocolTreasury {
  event UpdateStabilityFee(uint256 base, uint256 baseFee, uint256 maxFee);

  function getProtocolAddressProvider()
    external
    view
    returns (IProtocolAddressProvider protocolAddressProvider);

  function calculateStabilityFeeRate(
    uint256 totalDebtTokenSupply,
    uint256 poolRemainingLiquidity,
    uint256 poolRemainingLiquidityAfterAction
  ) external view returns (uint256 stabilityFee);

  function setStabilityFee(
    uint256 base,
    uint256 baseFee,
    uint256 maxFee
  ) external;

  function getStabilityFee()
    external
    view
    returns (
      uint256 base,
      uint256 baseFee,
      uint256 maxFee
    );
}

// SPDX-License-Identifier: MIT

import '../interfaces/IProtocolAddressProvider.sol';
import {IAssetTokenStateProvider} from '../../test/AssetTokenStateProvider.sol';

pragma solidity ^0.8.4;

abstract contract ProtocolTreasuryStorage {
  struct StabilityFee {
    uint256 base;
    uint256 baseFee;
    uint256 maxFee;
  }

  IProtocolAddressProvider internal _protocolAddressProvider;

  StabilityFee internal _stabilityFee;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAssetTokenStateProvider {
  function getAssetTokenState(address asset, uint256 tokenId) external view returns (bool);

  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external;
}

/// @title AssetTokenStateProvider
/// @notice This AssetTokenStateProvider is only for the test
contract AssetTokenStateProvider is IAssetTokenStateProvider {
  constructor() {}

  enum State {
    VALID,
    INVAILD
  }

  mapping(uint256 => State) public tokenState;

  /// @notice This function always returns false
  function getAssetTokenState(address asset, uint256 tokenId)
    external
    view
    override
    returns (bool)
  {
    asset;
    if (tokenState[tokenId] == State.INVAILD) {
      return false;
    } else {
      return true;
    }
  }

  /// @notice This function always returns false
  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external override {
    asset;
    if (state == true) {
      tokenState[tokenId] = State.VALID;
    } else {
      tokenState[tokenId] = State.INVAILD;
    }
  }
}