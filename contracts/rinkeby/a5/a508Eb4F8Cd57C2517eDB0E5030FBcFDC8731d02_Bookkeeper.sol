// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IBookkeeper.sol";
import "./Controllable.sol";
import "../interface/IGovernable.sol";

contract Bookkeeper is IBookkeeper, Initializable, Controllable, IGovernable {

  string public constant VERSION = "0";

  // DO NOT CHANGE NAMES OR ORDERING!
  address[] private _vaults;
  address[] private _strategies;
  mapping(address => uint256) public override targetTokenEarned;
  mapping(address => HardWork) private _lastHardWork;
  mapping(address => mapping(address => uint256)) public vaultUsers;
  mapping(address => mapping(address => mapping(address => uint256))) public userEarned;
  mapping(address => uint256) public override vaultUsersQuantity;
  mapping(address => PpfsChange) private _lastPpfsChange;

  event RegisterVault(address value);
  event RegisterStrategy(address value);
  event RegisterStrategyEarned(address strategy, uint256 amount);
  event RegisterUserAction(address user, uint256 amount, bool deposit);
  event RegisterUserEarned(address user, address vault, address token, uint256 amount);
  event RegisterPpfsChange(address vault, uint256 oldValue, uint256 newValue);

  function initialize(address _controller) public initializer {
    Controllable.initializeControllable(_controller);
  }

  modifier onlyStrategy() {
    require(IController(controller()).strategies(msg.sender), "only exist strategy");
    _;
  }

  modifier onlyFeeRewardForwarder() {
    require(IController(controller()).feeRewardForwarder() == msg.sender, "only exist forwarder");
    _;
  }

  modifier onlyVault() {
    require(IController(controller()).vaults(msg.sender), "only exist vault");
    _;
  }

  function addVault(address _vault) external override onlyControllerOrGovernance {
    if (!isVaultExist(_vault)) {
      _vaults.push(_vault);
      emit RegisterVault(_vault);
    }
  }

  function addStrategy(address _strategy) external override onlyControllerOrGovernance {
    if (!isStrategyExist(_strategy)) {
      _strategies.push(_strategy);
      emit RegisterStrategy(_strategy);
    }
  }

  function registerStrategyEarned(uint256 _targetTokenAmount) external override onlyStrategy {
    targetTokenEarned[msg.sender] += _targetTokenAmount;

    _lastHardWork[msg.sender] = HardWork(
      msg.sender,
      block.number,
      block.timestamp,
      _targetTokenAmount
    );
    emit RegisterStrategyEarned(msg.sender, _targetTokenAmount);
  }

  function registerPpfsChange(address vault, uint256 value)
  external override onlyFeeRewardForwarder {
    PpfsChange memory lastPpfs = _lastPpfsChange[vault];
    _lastPpfsChange[vault] = PpfsChange(
      vault,
      block.number,
      block.timestamp,
      value,
      lastPpfs.block,
      lastPpfs.time,
      lastPpfs.value
    );
    emit RegisterPpfsChange(vault, lastPpfs.value, value);
  }

  function registerUserAction(address _user, uint256 _amount, bool _deposit)
  external override onlyVault {
    if (vaultUsers[msg.sender][_user] == 0) {
      vaultUsersQuantity[msg.sender] += 1;
    }
    if (_deposit) {
      vaultUsers[msg.sender][_user] += _amount;
    } else {
      vaultUsers[msg.sender][_user] -= _amount;
    }
    if (vaultUsers[msg.sender][_user] == 0) {
      vaultUsersQuantity[msg.sender] -= 1;
    }
    emit RegisterUserAction(_user, _amount, _deposit);
  }

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount)
  external override onlyVault {
    userEarned[_user][_vault][_rt] += _amount;
    emit RegisterUserEarned(_user, _vault, _rt, _amount);
  }

  function isGovernance(address _contract) external override view returns (bool) {
    return IController(controller()).isGovernance(_contract);
  }

  function vaults() external override view returns (address[] memory) {
    return _vaults;
  }

  function strategies() external override view returns (address[] memory) {
    return _strategies;
  }

  function lastHardWork(address vault) public view override returns (HardWork memory) {
    return _lastHardWork[vault];
  }

  function lastPpfsChange(address vault) public view override returns (PpfsChange memory) {
    return _lastPpfsChange[vault];
  }

  function isVaultExist(address _value) internal view returns (bool) {
    for (uint256 i = 0; i < _vaults.length; i++) {
      if (_vaults[i] == _value) {
        return true;
      }
    }
    return false;
  }

  function isStrategyExist(address _value) internal view returns (bool) {
    for (uint256 i = 0; i < _strategies.length; i++) {
      if (_strategies[i] == _value) {
        return true;
      }
    }
    return false;
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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function vaults() external view returns (address[] memory);

  function strategies() external view returns (address[] memory);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  function targetTokenEarned(address vault) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  function vaultUsersQuantity(address vault) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IController.sol";

/**
* 200 - vault does not exist
* 201 - only hard worker or governance can call this
* 202 - Not governance
* 203 - message sender is a contract and have not added to the white list
* 204 - Not reward distributor
* 205 - empty address
* 206 - Not controller
*/
abstract contract Controllable is Initializable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  event UpdateController(address oldValue, address newValue);

  function initializeControllable(address _controller) public initializer {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
    setController(_controller);
    setCreated(block.timestamp);
  }

  // ************ MODIFIERS **********************

  modifier onlyControllerOrGovernance() {
    require(controller() == msg.sender || IController(controller()).isGovernance(msg.sender), "not controller");
    _;
  }

  /**
 *  Only smart contracts will be affected by this modifier
 *  If it is a contract it should be whitelisted
 */
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  function controller() public view returns (address str) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  function created() public view returns (uint256 str) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IGovernable {

  function isGovernance(address _contract) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function notifyHelper() external view returns (address);

  function psVault() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isGovernance(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);
}

