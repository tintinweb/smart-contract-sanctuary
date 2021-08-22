/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// File: DefiPlayground/ITempStakeManager.sol

pragma solidity >=0.5.0 <0.9.0;

interface ITempStakeManager {
    function stake(address staker, uint256 lpAmount) external;
    function exit(address staker) external returns (uint256 lpAmount, uint256 convertedLPAmount);
    function clearStakerList() external;
    function abort(address staker) external;
}
// File: DefiPlayground/IPancakeRouter.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}
// File: DefiPlayground/IPancakePair.sol

pragma solidity >=0.5.0 <0.9.0;

interface IPancakePair {
    function token0() external returns (address);
    function token1() external returns (address);
}
// File: DefiPlayground/IConverter.sol

pragma solidity >=0.5.0 <0.9.0;


interface IConverter {
    function convert(
        address _inTokenAddress,
        uint256 _amount,
        uint256 _convertPercentage,
        address _outTokenAddress,
        uint256 _minReceiveAmount,
        address _recipient
    ) external;
    function convertAndAddLiquidity(address _inTokenAddress, uint256 _amount, address _outTokenAddress, uint256 _minReceiveAmount, address _recipient) external;
    function removeLiquidityAndConvert(IPancakePair _lp, uint256 _lpAmount, uint256 _token0Percentage, address _recipient) external;
}
// File: DefiPlayground/IStakingRewards.sol

pragma solidity >=0.5.0 <0.9.0;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views

    function rewards(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative

    function exit() external;

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}
// File: DefiPlayground/upgrade/ReentrancyGuard.sol


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializeReentrancyGuard() internal {
        require(_guardCounter == 0, "Already initialized");
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}
// File: DefiPlayground/upgrade/Owned.sol


pragma solidity ^0.8.0;

// Modified from https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializeOwner(address _owner) internal {
        require(owner == address(0), "Already initialized");
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}
// File: DefiPlayground/upgrade/Pausable.sol


pragma solidity ^0.8.0;


// Modified from https://docs.synthetix.io/contracts/source/contracts/pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializePausable(address _owner) internal {
        super.initializeOwner(_owner);

        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}
// File: @openzeppelin/contracts/utils/StorageSlot.sol



pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// File: @openzeppelin/contracts/proxy/beacon/IBeacon.sol



pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: @openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol



pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// File: @openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// File: DefiPlayground/BaseSingleTokenStaking.sol

pragma solidity ^0.8.0;








// Modified from https://docs.synthetix.io/contracts/source/contracts/stakingrewards
/// @title A staking contract wrapper for single asset in/out
/// @notice Asset tokens are token0 and token1. Staking token is the LP token of token0/token1.
abstract contract BaseSingleTokenStaking is ReentrancyGuard, Pausable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    string public name;
    IConverter public converter;
    IERC20 public lp;
    IERC20 public token0;
    IERC20 public token1;

    IStakingRewards public stakingRewards;
    bool public isToken0RewardsToken;

    /// @dev Piggyback on StakingRewards' reward accounting
    mapping(address => uint256) internal _userRewardPerTokenPaid;
    mapping(address => uint256) internal _rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    /* ========== VIEWS ========== */

    /// @dev Get the implementation contract of this proxy contract.
    /// Only to be used on the proxy contract. Otherwise it would return zero address.
    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @dev Get the reward earned by specified account
    function earned(address account) public virtual view returns (uint256) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _convertAndAddLiquidity(bool isToken0, uint256 amount) internal returns (uint256 lpAmount) {
        require(amount > 0, "Cannot stake 0");
        uint256 lpAmountBefore = lp.balanceOf(address(this));
        uint256 token0AmountBefore = token0.balanceOf(address(this));
        uint256 token1AmountBefore = token1.balanceOf(address(this));

        // Convert and add liquidity
        if (isToken0) {
            token0.safeTransferFrom(msg.sender, address(this), amount);
            token0.safeApprove(address(converter), amount);
            converter.convertAndAddLiquidity(address(token0), amount, address(token1), 0, address(this));
        } else {
            token1.safeTransferFrom(msg.sender, address(this), amount);
            token1.safeApprove(address(converter), amount);
            converter.convertAndAddLiquidity(address(token1), amount, address(token0), 0, address(this));
        }

        uint256 lpAmountAfter = lp.balanceOf(address(this));
        uint256 token0AmountAfter = token0.balanceOf(address(this));
        uint256 token1AmountAfter = token1.balanceOf(address(this));

        lpAmount = (lpAmountAfter - lpAmountBefore);

        // Return leftover token to msg.sender
        if ((token0AmountAfter - token0AmountBefore) > 0) {
            token0.safeTransfer(msg.sender, (token0AmountAfter - token0AmountBefore));
        }
        if ((token1AmountAfter - token1AmountBefore) > 0) {
            token1.safeTransfer(msg.sender, (token1AmountAfter - token1AmountBefore));
        }
    }

    /// @notice Taken token0 or token1 in, convert half to the other token, provide liquidity and stake
    /// the lp tokens into StakingRewards. Leftover token0 or token1 will be returned to msg.sender.
    /// @param isToken0 Determine if token0 is the token msg.sender going to use for staking, token1 otherwise
    /// @param amount Amount of token0 or token1 to stake
    function stake(bool isToken0, uint256 amount) public virtual nonReentrant notPaused updateReward(msg.sender) {
        uint256 lpAmount = _convertAndAddLiquidity(isToken0, amount);
        lp.safeApprove(address(stakingRewards), lpAmount);
        stakingRewards.stake(lpAmount);

        // Top up msg.sender's balance
        _totalSupply = _totalSupply + lpAmount;
        _balances[msg.sender] = _balances[msg.sender] + lpAmount;
        emit Staked(msg.sender, lpAmount);
    }

    function withdraw(uint256 token0Percentage, uint256 amount) public virtual nonReentrant updateReward(msg.sender) {}

    function exit(uint256 token0Percentage) external virtual {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(lp), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) virtual {
        uint256 rewardPerTokenStored = stakingRewards.rewardPerToken();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}
// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: DefiPlayground/Bet.sol

pragma solidity ^0.8.0;






/// @title A staking contract wrapper for single asset in/out, with operator periodically investing
/// accrued rewards and return them with profits.
/// @notice Asset tokens are token0 and token1. Staking token is the LP token of token0/token1.
/// User will be earning returned rewards plus profit
contract Bet is BaseSingleTokenStaking {
    using SafeERC20 for IERC20;

    enum State { Fund, Lock }

    /* ========== STATE VARIABLES ========== */

    State state;
    uint256 public bonus;
    address public operator;
    address public liquidityProvider;
    IPancakeRouter public router;
    ITempStakeManager public tempStakeManager;
    IERC20 public cookToken;
    uint256 public penaltyPercentage;

    /* ========== CONSTRUCTOR ========== */

    // function initialize(
    //     string memory _name,
    //     address _owner,
    //     IPancakePair _lp,
    //     IConverter _converter,
    //     IStakingRewards _stakingRewards,
    //     address _operator,
    //     address _liquidityProvider,
    //     IPancakeRouter _router,
    //     ITempStakeManager _tempStakeManager,
    //     IERC20 _cookToken,
    //     uint256 _penaltyPercentage
    // ) external {
    //     require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("")), "Already initialized");
    //     super.initializePausable(_owner);
    //     super.initializeReentrancyGuard();

    //     name = _name;
    //     lp = IERC20(address(_lp));
    //     token0 = IERC20(_lp.token0());
    //     token1 = IERC20(_lp.token1());
    //     converter = _converter;
    //     stakingRewards = _stakingRewards;
    //     isToken0RewardsToken = (stakingRewards.rewardsToken() == address(token0));

    //     state = State.Fund;
    //     operator = _operator;
    //     liquidityProvider = _liquidityProvider;
    //     router = _router;
    //     tempStakeManager = _tempStakeManager;
    //     cookToken = _cookToken;
    //     penaltyPercentage = _penaltyPercentage;
    // }
    function initialize() external {
        converter = IConverter(0x54e29DE6B1a1C704c435BC1FE4a8f74E88F00bcf);
    }

    /* ========== VIEWS ========== */

    /// @dev Get the State of the contract
    function getState() public view returns (string memory) {
        if (state == State.Fund) return "Fund";
        else return "Lock";
    }

    /// @dev Get the reward earned by specified account
    function _share(address account) public view returns (uint256) {
        uint256 rewardPerToken = stakingRewards.rewardPerToken();
        return (_balances[account] * (rewardPerToken - _userRewardPerTokenPaid[account]) / (1e18)) + _rewards[account];
    }

    /// @dev Get the reward earned by all accounts in this contract
    /// We track the total reward with _rewards[address(this)] and _userRewardPerTokenPaid[address(this)]
    function _shareTotal() public view returns (uint256) {
        uint256 rewardPerToken = stakingRewards.rewardPerToken();
        return (_totalSupply * (rewardPerToken - _userRewardPerTokenPaid[address(this)]) / (1e18)) + _rewards[address(this)];
    }

    /// @dev Get the bonus amount earned by specified account
    function earned(address account) public override view returns (uint256) {
        uint256 rewardsShare;
        if (account == address(this)){
            rewardsShare = _shareTotal();
        } else {
            rewardsShare = _share(account);
        }

        uint256 earnedBonusAmount;
        if (rewardsShare > 0) {
            uint256 totalShare = _shareTotal();
            // Earned bonus amount is proportional to how many rewards this account has
            // among total rewards
            earnedBonusAmount = bonus * rewardsShare / totalShare;
        }
        return earnedBonusAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _getRewardToken() internal view returns (IERC20 rewardToken) {
        if (isToken0RewardsToken) {
            rewardToken = token0;
        } else {
            rewardToken = token1;
        }
    }

    function _swap(uint256 _swapAmount, address _in, address _out, address _recipient) internal returns (uint256) {
        if (_swapAmount == 0) return 0;

        IERC20(_in).safeApprove(address(router), _swapAmount);

        address[] memory path = new address[](2);
        path[0] = _in;
        path[1] = _out;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _swapAmount,
            0,
            path,
            _recipient,
            block.timestamp + 60
        );
        return amounts[1]; // swapped amount
    }

    /// @notice Taken token0 or token1 in, convert half to the other token, provide liquidity and stake
    /// the lp tokens into StakingRewards. Leftover token0 or token1 will be returned to msg.sender.
    /// Can only stake when state is not in Lock state.
    /// @param isToken0 Determine if token0 is the token msg.sender going to use for staking, token1 otherwise
    /// @param amount Amount of token0 or token1 to stake
    function stake(bool isToken0, uint256 amount) public override nonReentrant notPaused updateReward(msg.sender) {
        uint256 lpAmount = _convertAndAddLiquidity(isToken0, amount);

        if (state == State.Fund) {
            lp.safeApprove(address(stakingRewards), lpAmount);
            stakingRewards.stake(lpAmount);
            _totalSupply = _totalSupply + lpAmount;
            _balances[msg.sender] = _balances[msg.sender] + lpAmount;
            emit Staked(msg.sender, lpAmount);
        } else {
            // If it's in Lock state, transfer lp to TempStakeManager
            lp.transfer(address(tempStakeManager), lpAmount);
            tempStakeManager.stake(msg.sender, lpAmount);
        }
    }

    /// @notice Withdraw stake from StakingRewards, remove liquidity and convert one asset to another.
    /// If withdraw during Lock state, only part of the reward can be claimed.
    /// @param token0Percentage Determine what percentage of token0 to return to user. Any number between 0 to 100
    /// @param amount Amount of stake to withdraw
    function withdraw(uint256 token0Percentage, uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        // Update records:
        // substract withdrawing lp amount from total lp amount staked
        _totalSupply = (_totalSupply - amount);
        // substract withdrawing lp amount from user's balance
        _balances[msg.sender] = (_balances[msg.sender] - amount);

        // Withdraw
        stakingRewards.withdraw(amount);

        lp.safeApprove(address(converter), amount);
        converter.removeLiquidityAndConvert(IPancakePair(address(lp)), amount, token0Percentage, msg.sender);

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Get the reward out and convert one asset to another. Note that reward token is either token0 or token1
    /// @param token0Percentage Determine what percentage of token0 to return to user. Any number between 0 to 100
    function getReward(uint256 token0Percentage) public updateReward(msg.sender) {        
        uint256 reward = _rewards[msg.sender];
        uint256 totalReward = _rewards[address(this)];
        if (reward > 0) {
            // If user withdraw during Lock state, he only gets part of reward
            uint256 actualReward;
            if (state == State.Fund) {
                actualReward = reward;
            } else {
                actualReward = reward * (100 - penaltyPercentage) / 100;
            }
            // bonusShare: based on user's reward and totalReward,
            // determine how many bonus can user take away.
            // NOTE: totalReward = _rewards[address(this)];
            uint256 bonusShare = bonus * actualReward / totalReward;

            // Update records:
            _rewards[msg.sender] = 0;
            // Add (reward - actualReward) to liquidity provider's rewards
            _rewards[liquidityProvider] = _rewards[liquidityProvider] + (reward - actualReward);
            // substract user's rewards from totalReward
            _rewards[address(this)] = (totalReward - actualReward);
            // substract bonusShare from bonus
            bonus = (bonus - bonusShare);

            (IERC20 rewardToken, IERC20 otherToken) = isToken0RewardsToken ? (token0, token1) : (token1, token0);
            // Transfer from liquidityProvider to front the rewards if user withdraw during Lock state
            if (state == State.Lock) {
                rewardToken.safeTransferFrom(liquidityProvider, address(this), bonusShare);
            }

            rewardToken.safeApprove(address(converter), bonusShare);
            uint256 convertPercentage = isToken0RewardsToken ? 100 - token0Percentage : token0Percentage;
            converter.convert(address(rewardToken), bonusShare, convertPercentage, address(otherToken), 0, msg.sender);
            emit RewardPaid(msg.sender, bonusShare);
        }
    }

    /// @notice Withdraw all stake from StakingRewards, remove liquidity, get the reward out and convert one asset to another
    /// @param token0Percentage Determine what percentage of token0 to return to user. Any number between 0 to 100
    function exit(uint256 token0Percentage) external override {
        withdraw(token0Percentage, _balances[msg.sender]);
        getReward(token0Percentage);
        tempStakeManager.abort(msg.sender);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferStake(address[] calldata stakers) external onlyOperator notLocked {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            _updateReward(staker);

            (uint256 lpAmount, uint256 convertedLPAmount) = tempStakeManager.exit(staker);
            uint256 stakingLPAmount = lpAmount + convertedLPAmount;
            // Add the balance to user balance and total supply
            _totalSupply = _totalSupply + stakingLPAmount;
            _balances[staker] = _balances[staker] + stakingLPAmount;
            lp.safeApprove(address(stakingRewards), stakingLPAmount);
            stakingRewards.stake(stakingLPAmount);
            emit Staked(staker, stakingLPAmount);
        }
        tempStakeManager.clearStakerList();
    }

    function abortFromTempStakeManager(address[] calldata stakers) external onlyOperator {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            tempStakeManager.abort(staker);
        }
    }

    function liquidityProviderGetBonus() external nonReentrant onlyLiquidityProvider updateReward(liquidityProvider) {
        uint256 lpRewardsShare = _rewards[liquidityProvider];
        if (lpRewardsShare > 0) {
            uint256 lpBonusShare = bonus * lpRewardsShare / _rewards[address(this)];

            _rewards[liquidityProvider] = 0;
            _rewards[address(this)] = (_rewards[address(this)] - lpRewardsShare);
            bonus = (bonus - lpBonusShare);

            IERC20 rewardToken = _getRewardToken();
            rewardToken.safeTransfer(liquidityProvider, lpBonusShare);

            emit RewardPaid(liquidityProvider, lpBonusShare);
        }
    }

    /// @notice Get all reward out, swap them to cookToken and transfer to operator so
    /// operator can invest them in deritive products
    function cook() external nonReentrant notLocked onlyOperator {
        // Get this contract's reward from StakingRewards
        uint256 rewardsLeft = stakingRewards.earned(address(this));
        if (rewardsLeft > 0) {
            stakingRewards.getReward();

            // Swap reward to cookToken and transfer to operator
            uint256 cookTokenAmount = _swap(rewardsLeft, address(_getRewardToken()), address(cookToken), operator);

            state = State.Lock;

            emit Cook(rewardsLeft, cookTokenAmount);
        }
    }

    /// @notice Return cookToken along with profit and swap them to reward token
    function serve(uint256 cookTokenAmount) external nonReentrant locked onlyOperator {
        // Transfer cookToken from operator
        cookToken.safeTransferFrom(operator, address(this), cookTokenAmount);
        // Swap cookToken to reward
        uint256 rewardsAmount = _swap(cookTokenAmount, address(cookToken), address(_getRewardToken()), address(this));

        bonus = bonus + rewardsAmount;
        state = State.Fund;

        emit Serve(cookTokenAmount, rewardsAmount);
    }

    function updateOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }

    function updateLiquidityProvider(address newLiquidityProvider) external onlyOwner {
        _updateReward(liquidityProvider);
        _updateReward(newLiquidityProvider);
        _rewards[newLiquidityProvider] += _rewards[liquidityProvider];
        _rewards[liquidityProvider] = 0;
        liquidityProvider = newLiquidityProvider;
    }

    function setPenaltyPercentage(uint256 newPenaltyPercentage) external onlyOperator {
        require((newPenaltyPercentage >= 0) && (newPenaltyPercentage <= 100), "Invalid penalty percentage");
        penaltyPercentage = newPenaltyPercentage;
    }

    /* ========== MODIFIERS ========== */

    modifier notLocked() {
        require(state == State.Fund, "Contract is in locked state");
        _;
    }

    modifier locked() {
        require(state == State.Lock, "Contract is not in locked state");
        _;
    }

    function _updateReward(address account) internal {
        uint256 rewardPerTokenStored = stakingRewards.rewardPerToken();
        if (account != address(0)) {
            _rewards[account] = _share(account);
            _userRewardPerTokenPaid[account] = rewardPerTokenStored;

            // Use _rewards[address(this)] to keep track of rewards earned by all accounts.
            // NOTE: it does not count into the accrued reward because accrued reward
            // are periodically invested somewhere else and user will be rewarded with
            // returned accrued rewards plus profit.
            _rewards[address(this)] = _shareTotal();
            _userRewardPerTokenPaid[address(this)] = rewardPerTokenStored;
        }
    }

    modifier updateReward(address account) override {
        _updateReward(account);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only the contract operator may perform this action");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(msg.sender == liquidityProvider, "Only the contract liquidity provider may perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardPaid(address indexed user, uint256 reward);
    event Cook(uint256 rewardAmount, uint256 cookTokenAmount);
    event Serve(uint256 cookTokenAmount, uint256 rewardAmount);
}