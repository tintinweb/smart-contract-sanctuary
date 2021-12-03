// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Initializable.sol";

import "KayaGame.sol";
import "WithGovernor.sol";
import "IKaya.sol";
import "IKayaCenter.sol";

contract KayaCenter is Initializable, WithGovernor, IKayaCenter {
  event SetCfo(address indexed cfo);
  event NewGame(address indexed game, string name, string uri);
  event EditGame(address indexed game, string name, string uri);
  event Deposit(address indexed game, address indexed user, uint256 value);
  event Withdraw(address indexed game, address indexed user, uint256 value);
  event Reward(address indexed game, uint256 value);

  IKaya public kaya;
  address public cfo;
  mapping(address => bool) public isGame;

  function initialize(IKaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    cfo = _gov;
    initialize__WithGovernor(_gov);
  }

  /// @dev Sets the address that is authorized to initiate withdrawal from any games.
  /// @param _cfo The address to become the CFO.
  function setCfo(address _cfo) external onlyGov {
    cfo = _cfo;
    emit SetCfo(_cfo);
  }

  /// @dev Adds a new game to the ecosystem. The game will be able to earn KAYA rewards.
  /// @param name The name of the newly added game.
  /// @param uri The uri of the newly added game.
  function add(string memory name, string memory uri) external onlyGov returns (address) {
    address game = address(new KayaGame(name, uri));
    isGame[game] = true;
    emit NewGame(game, name, uri);
    return game;
  }

  /// @dev Edits the information of an existing game.
  /// @param game The address of the game contract to edit.
  /// @param name The name to edit to.
  /// @param uri The uri to edit to.
  function edit(
    address game,
    string memory name,
    string memory uri
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).edit(name, uri);
    emit EditGame(address(game), name, uri);
  }

  /// @dev Deposits KAYA into the given game.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  function deposit(address game, uint256 value) external {
    _deposit(game, value);
  }

  /// @dev Deposits KAYA into the given game using EIP-2612 permit to permit for max int.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  /// @param deadline The deadline for EIP-2616 permit parameter.
  /// @param v Part of permit signature.
  /// @param r Part of permit signature.
  /// @param s Part of permit signature.
  function depositWithPermit(
    address game,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _deposit(game, value);
  }

  /// @dev Internal function to process KAYA deposits to games.
  /// @param game The game address to deposit KAYA to.
  /// @param value The size of KAYA to deposit.
  function _deposit(address game, uint256 value) internal {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(game, msg.sender, value);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param value TODO
  function withdraw(
    address game,
    address to,
    uint256 value
  ) external {
    require(msg.sender == cfo, "!cfo");
    require(isGame[game], "!game");
    KayaGame(game).withdraw(to, value);
    emit Withdraw(game, to, value);
  }

  /// @dev Adds more KAYA reward to the game. Can technically be called by anyone.
  /// @param game The game contract to reward.
  /// @param value The size of KAYA tokens to add as rewards.
  function reward(address game, uint256 value) external {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value));
    emit Reward(game, value);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param data TODO
  function sos(
    address game,
    address to,
    bytes memory data
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).sos(to, data);
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

import "IKaya.sol";
import "IKayaCenter.sol";
import "IKayaGame.sol";

contract KayaGame is IKayaGame {
  IKaya public immutable kaya;
  address public immutable controller;

  string public name;
  string public uri;

  /// @dev Initializes the smart contract with the initial state values.
  constructor(string memory _name, string memory _uri) {
    kaya = IKaya(IKayaCenter(msg.sender).kaya());
    controller = msg.sender;
    name = _name;
    uri = _uri;
  }

  /// @dev Edits the name and uri of this game contract.
  /// @param _name The new name to update, or "" if do-not-modify.
  /// @param _uri The new uri to update, or "" if do-not-modify.
  function edit(string memory _name, string memory _uri) external {
    require(msg.sender == controller, "!controller");
    if (bytes(_name).length > 0) {
      name = _name;
    }
    if (bytes(_uri).length > 0) {
      uri = _uri;
    }
  }

  /// @dev Withdraws KAYA tokens to the target address. Must be called by the controller.
  /// @param to The address to send KAYA tokens to.
  /// @param value The size of KAYA tokens to send.
  function withdraw(address to, uint256 value) external {
    require(msg.sender == controller, "!controller");
    require(kaya.transfer(to, value), "!transfer");
  }

  /// @dev Called by controller to ask this contract to any action. Primarily for recovering
  /// lost assets, whether in the forms of ERC20, ERC721, ERC1155, punks, or any other standard
  /// that get accidietnally sent to this contract.
  /// @param to The contract address to execute the acton.
  /// @param data The data attached the call.
  function sos(address to, bytes memory data) external payable {
    require(msg.sender == controller, "!controller");
    (bool ok, ) = to.call{ value: msg.value }(data);
    require(ok, "!ok");
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

import "IKaya.sol";

interface IKayaCenter {
  function kaya() external view returns (IKaya);

  function isGame(address game) external view returns (bool);

  function reward(address game, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IKayaGame {
  function withdraw(address to, uint256 value) external;
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