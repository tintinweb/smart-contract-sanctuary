// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Initializable.sol";

import "WithGovernor.sol";
import "IKaya.sol";
import "IKayaGame.sol";
import "IKayaCenter.sol";

contract KayaDistributor is Initializable, WithGovernor {
  IKaya public kaya;
  IKayaCenter public center;
  address public soKaya;

  uint256 public accKayaPerPower;
  uint256 public totalPower;

  uint256 public inflation;
  uint256 public lastTick;

  mapping(address => uint256) public powers;
  mapping(address => uint256) public prevKayaPerPowers;

  function initialize(IKayaCenter _center, address _gov) external initializer {
    kaya = _center.kaya();
    center = _center;
    kaya.approve(address(center), type(uint256).max);
    lastTick = block.timestamp;
    initialize__WithGovernor(_gov);
  }

  /// @dev Initializes SoKAYA address to the invoker. Can and must only be called once.
  function setSoKaya() external {
    require(soKaya == address(0), "!setSoKaya");
    soKaya = msg.sender;
  }

  /// @dev Updates inflation rate per year imposed on KAYA for game distribution.
  /// @param _inflation Inflation rate per year, multiplied by 1e18.
  function setInflation(uint256 _inflation) external onlyGov {
    require(_inflation <= 1e18, "!inflation");
    tick();
    inflation = _inflation;
  }

  /// @dev Increases allocation power to the given game. Must be called by SoKAYA.
  /// @param game The game contract address to add power.
  /// @param power The power to increase.
  function increasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower += power;
    powers[game] += power;
  }

  /// @dev Decreases allocation power from the given game. Must be called by SoKAYA.
  /// @param game The game contract address to reduct power.
  /// @param power The power to decrease.
  function decreasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower -= power;
    powers[game] -= power;
  }

  /// @dev Transfers allocation power from one game to another. Must be called by SoKAYA.
  /// @param src The game contract address to move allocation from.
  /// @param dst The game contract address to send allocation to.
  /// @param power The power to decrease.
  function transferPower(
    address src,
    address dst,
    uint256 power
  ) external {
    require(msg.sender == soKaya, "!SoKaya");
    require(src != dst, "!transfer");
    tick();
    flush(src);
    flush(dst);
    powers[src] -= power;
    powers[dst] += power;
  }

  /// @dev Triggers inflation logic to mint more KAYA and accumulate to the games.
  function tick() public {
    uint256 timePast = block.timestamp - lastTick;
    lastTick = block.timestamp;
    if (timePast > 0 && inflation > 0 && totalPower > 1e18) {
      uint256 value = (kaya.totalSupply() * inflation * timePast) / 1e18 / 365 days;
      kaya.mint(address(this), value);
      accKayaPerPower += (value * 1e12) / totalPower;
    }
  }

  /// @dev Flushes KAYA rewards to a specific game.
  /// @param game The game contract address to flush rewards to.
  function flush(address game) public {
    uint256 dist = ((accKayaPerPower - prevKayaPerPowers[game]) * powers[game]) / 1e12;
    prevKayaPerPowers[game] = accKayaPerPower;
    if (dist > 0) {
      center.reward(game, dist);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
pragma solidity 0.8.9;

import "Initializable.sol";

contract WithGovernor is Initializable {
  address public gov;
  address public pendingGov;

  event AcceptGov(address gov);
  event SetPendingGov(address gov);

  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  function initialize__WithGovernor(address _gov) internal initializer {
    require(_gov != address(0), "!gov");
    gov = _gov;
    emit AcceptGov(_gov);
  }

  /// @dev Updates the address to become the new governor after it accepts.
  /// @param _pendingGov The new pending governor address.
  function setPendingGov(address _pendingGov) external onlyGov {
    pendingGov = _pendingGov;
    emit SetPendingGov(_pendingGov);
  }

  /// @dev Called by the pending governor to become the governor.
  function acceptGov() external {
    require(msg.sender == pendingGov, "!pendingGov");
    pendingGov = address(0);
    gov = msg.sender;
    emit AcceptGov(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IERC20.sol";

interface IKaya is IERC20 {
  function mint(address to, uint256 amount) external;

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
pragma solidity 0.8.9;

interface IKayaGame {
  function withdraw(address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IKaya.sol";

interface IKayaCenter {
  function kaya() external view returns (IKaya);

  function reward(address game, uint256 value) external;
}