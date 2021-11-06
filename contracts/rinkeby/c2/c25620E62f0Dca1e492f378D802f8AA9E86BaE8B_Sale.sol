// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Configurable {
  // enum
  enum State {
    UNCONFIGURED,
    CONFIGURED
  }

  // storage
  State public state = State.UNCONFIGURED;

  // modifier
  modifier onlyInState(State _state) {
    require(state == _state, "Invalid state");
    _;
  }
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBurnable {
  function burn(uint256) external;
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVestingSupply {
  function vestingSupply() external view returns (uint256);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISaleSupply {
  function saleSupply() external view returns (uint256);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IBurnable} from "./IBurnable.sol";
import {ISaleSupply} from "./ISaleSupply.sol";
import {IVestingSupply} from "./IVestingSupply.sol";

interface IToken is IBurnable, ISaleSupply, IVestingSupply {}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IToken} from "./IToken.sol";

interface ITokenERC20 is IERC20, IToken {}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWhitelist {
  function use(uint256) external returns (bool);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Configurable} from "../utils/Configurable.sol";
import {ITokenERC20} from "../interfaces/ITokenERC20.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract Sale is AccessControl, Configurable {
  // stage
  struct Stage {
    uint256 supply; // stage supply
    uint256 rate; // tokens per wei (example: value 20 -> for 1 ETH gives 20 tokens)
    uint256 minAlloc; // minimum wei invested
    uint256 openingTime;
    uint256 closingTime;
  }
  struct Phase {
    Stage stage;
    uint256 soldTokens;
    uint256 weiRaised;
  }

  // storage
  Phase[] public stages;
  ITokenERC20 public erc20;
  IWhitelist public whitelist;

  address payable public wallet;
  uint256 public supply; // sale supply
  uint256 public hardCap; // ether value of sale supply
  uint256 public weiRaised;

  // events
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  event TokenBurn(uint256 amount);

  // basic errors
  error SaleNotActive(uint256 timestamp);
  error SaleNotFinished(uint256 timestamp);
  error NoTokensLeft();

  // sale errors
  error InvalidConfig(uint256 supply, uint256 cap, address wallet, uint256 stagesCount);
  error SupplyMismatch(uint256 supply, uint256 totalSupply);
  error ValueMismatch(uint256 hardCap, uint256 totalValue);

  // stage errors
  error InvalidStageConfig(uint256 rate, uint8 i);
  error StartDateInThePast(uint256 start, uint256 now_, uint8 i);
  error StartDateNotBeforeEndDate(uint256 start, uint256 end, uint8 i);
  error SupplySmallerThanRate(uint256 supply, uint256 rate, uint8 i);

  // configuration errors
  error SupplyConfigurationMishmatch(uint256 saleSupply, uint256 supply);
  error BalanceNotEqualSupply(uint256 balance, uint256 supply);

  // buy errors
  error InvalidReceiver(address receiver);
  error NotEnoughBigInvestment(uint256 amount, uint256 minimum);
  error HardCapExceeded(uint256 amount, uint256 hardCap);
  error StageSupplyDrained(uint256 amount, uint256 supply);
  error WhitelistNotPassed(address member, uint256 weiAmount);

  // modifiers
  modifier onlyWhenActive() {
    getCurrentStage();
    _;
  }
  modifier onlyWhenFinished() {
    uint256 timestamp = block.timestamp;
    if (timestamp < closingTime()) {
      revert SaleNotFinished(timestamp);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    // decode
    (uint256 supply_, uint256 hardCap_, address wallet_, Stage[] memory stages_) = abi.decode(
      arguments_,
      (uint256, uint256, address, Stage[])
    );

    // sale config
    uint256 stagesCount = stages_.length;
    if (
      supply_ == 0 ||
      hardCap_ == 0 ||
      wallet_ == address(0x0) ||
      stagesCount == 0 ||
      stagesCount > 16
    ) {
      revert InvalidConfig(supply_, hardCap_, wallet_, stages_.length);
    }

    uint256 totalSupply;
    uint256 totalValue;
    uint256 lastClosingTime = block.timestamp;
    for (uint8 i = 0; i < stages_.length; i++) {
      Stage memory stage = stages_[i];

      // stage config
      if (stage.rate == 0) {
        revert InvalidStageConfig(stage.rate, i);
      }

      // stage opening
      if (stage.openingTime < lastClosingTime) {
        revert StartDateInThePast(stage.openingTime, lastClosingTime, i);
      }

      // stage closing
      if (stage.openingTime >= stage.closingTime) {
        revert StartDateNotBeforeEndDate(stage.openingTime, stage.closingTime, i);
      }

      // requirement of OpenZeppelin crowdsale from V2
      // FIXME: to discuss if support for other rates is needed
      // 1 token (decimals 0) -> MAX 1 wei
      // 1 token (decimals 1) -> MAX 10 wei
      // 1 token (decimals 5) -> MAX 100 000 wei
      // 1 MLN token (decimals 0) -> MAX 1 MLN wei
      if (stage.supply < stage.rate) {
        revert SupplySmallerThanRate(stage.supply, stage.rate, i);
      }

      // increment counters
      totalValue += stage.supply / stage.rate;
      lastClosingTime = stage.closingTime;
      totalSupply += stage.supply;

      // storage
      stages.push(Phase(stage, 0, 0));
    }

    // sum of stages supply
    if (supply_ != totalSupply) {
      revert SupplyMismatch(supply_, totalSupply);
    }

    // sum of stages hard caps
    if (hardCap_ != totalValue) {
      revert ValueMismatch(hardCap_, totalValue);
    }

    // save storage
    supply = supply_;
    hardCap = hardCap_;
    wallet = payable(wallet_);

    // base role
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function configure(address erc20_, address whitelist_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // storage
    erc20 = ITokenERC20(erc20_);
    whitelist = IWhitelist(whitelist_);

    // check supply vs params
    uint256 saleSupply = erc20.saleSupply();
    if (saleSupply != supply) {
      revert SupplyConfigurationMishmatch(saleSupply, supply);
    }

    // check configuration vs balance
    uint256 balance = erc20.balanceOf(address(this));
    if (saleSupply != balance) {
      revert BalanceNotEqualSupply(balance, saleSupply);
    }

    // state
    state = State.CONFIGURED;
  }

  function buyTokens(address _beneficiary)
    external
    payable
    onlyInState(State.CONFIGURED)
    onlyWhenActive
  {
    // current state
    uint8 currentStage = getCurrentStage();
    Phase memory phase = stages[currentStage];

    // tx members
    uint256 weiAmount = msg.value;

    // validate receiver
    if (_beneficiary == address(0)) {
      revert InvalidReceiver(_beneficiary);
    }

    // check min invesment
    if (weiAmount < phase.stage.minAlloc) {
      revert NotEnoughBigInvestment(weiAmount, phase.stage.minAlloc);
    }

    // check hardcap
    uint256 raised = weiRaised + weiAmount;
    if (raised > hardCap) {
      revert HardCapExceeded(raised, hardCap);
    }

    // calculate token amount to be sold
    uint256 tokenAmount = weiAmount * phase.stage.rate;

    // check supply
    uint256 sold = phase.soldTokens + tokenAmount;
    if (sold > phase.stage.supply) {
      revert StageSupplyDrained(sold, phase.stage.supply);
    }

    // use whitelist
    if (address(whitelist) != address(0x0)) {
      bool success = whitelist.use(weiAmount);
      if (!success) {
        revert WhitelistNotPassed(msg.sender, weiAmount);
      }
    }

    // update state
    weiRaised = raised;
    stages[currentStage].weiRaised += weiAmount;
    stages[currentStage].soldTokens = sold;

    // store profits
    wallet.transfer(weiAmount);

    // send tokens
    erc20.transfer(_beneficiary, tokenAmount);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
  }

  receive() external payable {
    this.buyTokens(msg.sender);
  }

  function stageCount() external view returns (uint256) {
    // frontend view
    return stages.length;
  }

  function rate() external view returns (uint256) {
    // rate from current stage
    return stages[getCurrentStage()].stage.rate;
  }

  function openingTime() external view returns (uint256) {
    // opening time of first stage
    return stages[0].stage.openingTime;
  }

  function closingTime() public view returns (uint256) {
    // closing time of last stage
    return stages[getLastStage()].stage.closingTime;
  }

  function tokensLeft() public view onlyInState(State.CONFIGURED) returns (uint256) {
    // tokens left on sale contract
    return erc20.balanceOf(address(this));
  }

  function getLastStage() internal view returns (uint8) {
    return uint8(stages.length - 1);
  }

  function getCurrentStage() public view returns (uint8) {
    // tx.members
    uint256 timestamp = block.timestamp;

    // return active stage
    for (uint8 i = 0; i < stages.length; i++) {
      if (stages[i].stage.openingTime <= timestamp && timestamp <= stages[i].stage.closingTime) {
        return i;
      }
    }

    // revert if no active stage
    revert SaleNotActive(timestamp);
  }

  function hasClosed() external view returns (bool) {
    // OpenZeppelin standard method
    return block.timestamp > closingTime();
  }

  function finalize() external onlyInState(State.CONFIGURED) onlyWhenFinished {
    // check tokens left
    uint256 tokenAmount = tokensLeft();

    // revert if no tokens left
    if (tokenAmount == 0) {
      revert NoTokensLeft();
    }

    // burn remaining tokens
    erc20.burn(tokenAmount);
    emit TokenBurn(tokenAmount);
  }
}

{
  "remappings": [
    "@openzeppelin/contracts/token/ERC20/IERC20.sol=./openzeppelin/IERC20.sol",
    "@openzeppelin/contracts/access/AccessControl.sol=./openzeppelin/AccessControl.sol"
  ],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}