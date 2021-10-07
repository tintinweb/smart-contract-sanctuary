// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import '../nameless/NamelessToken.sol';
import '../utils/LazyShoeDistribution.sol';

contract JuggernautsSales is EIP712, AccessControl, Initializable  {
  using LazyShoeDistribution for LazyShoeDistribution.Shoe;

  address payable public benefactor;
  string public name;

  event TokenPurchased(uint index, address buyer);

  struct Stats {
    uint32 numSold;
    uint32 maxPresale;
    uint32 maxPubsale;
  }

  mapping(uint => Stats) public statsByTier;
  mapping(uint => mapping(uint => uint )) public priceByTierQuantity;
  bool public presaleActive;
  bool public pubsaleActive;
  address public ticketSigner;
  NamelessToken public tokenContract;

  mapping(uint => LazyShoeDistribution.Shoe) private shoeByTier;
  mapping(uint => uint) private firstTokenIdByTier;

  function initialize(string memory _name, NamelessToken _tokenContract, address _ticketSigner, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);

    statsByTier[1] = Stats(0, 66, 100);
    statsByTier[2] = Stats(0, 66, 100);
    statsByTier[3] = Stats(0, 66, 100);
    priceByTierQuantity[1][1] = 1 gwei;
    priceByTierQuantity[2][1] = 1 gwei;
    priceByTierQuantity[3][1] = 1 gwei;
    priceByTierQuantity[1][4] = 3 gwei;
    priceByTierQuantity[2][4] = 3 gwei;
    priceByTierQuantity[3][4] = 3 gwei;

    presaleActive = false;
    pubsaleActive = false;
    tokenContract = _tokenContract;
    ticketSigner = _ticketSigner;

    shoeByTier[1].size = 100;
    shoeByTier[2].size = 100;
    shoeByTier[3].size = 100;

    firstTokenIdByTier[1] = 1000;
    firstTokenIdByTier[2] = 1100;
    firstTokenIdByTier[3] = 1200;
  }

  constructor(string memory _name, string memory _domain, string memory _version, NamelessToken _tokenContract, address _ticketSigner) EIP712(_domain, _version) {
    initialize(_name, _tokenContract, _ticketSigner, msg.sender);
  }

  function pickTokenId(uint tier) internal returns (uint) {
    uint random = uint256(keccak256(abi.encodePacked(msg.sender, shoeByTier[tier].size, block.difficulty, block.timestamp, block.number, blockhash(block.number - 1))));
    uint result = shoeByTier[tier].pop(random);
    statsByTier[tier].numSold += 1;
    return firstTokenIdByTier[tier] + result - 1;
  }

  function buyPresale(uint tier, uint quantity, string calldata ticket, bytes calldata signature) external payable {
    require(presaleActive, 'sale not started');
    require(tier > 0 && tier <= 3, 'tier not for sale');
    require(quantity == 1 || quantity == 4, 'only singles or 4 packs');
    require(priceByTierQuantity[tier][quantity] == msg.value, 'wrong price');


    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Ticket(address wallet,string ticket)"),
        msg.sender,
        keccak256(bytes(ticket))
    )));
    address signer = ECDSA.recover(digest, signature);
    require(signer == ticketSigner, 'invalid ticket');

    for (uint i = 0; i < quantity; i++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function buy(uint tier, uint quantity) external payable {
    require(pubsaleActive, 'sale not started');
    require(tier > 0 && tier <= 3, 'tier not for sale');
    require(quantity == 1 || quantity == 4, 'only singles or 4 packs');
    require(priceByTierQuantity[tier][quantity] == msg.value, 'wrong price');

    for (uint i = 0; i < quantity; i++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function setPresaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    presaleActive = active;
  }

  function setPubsaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pubsaleActive = active;
  }


  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './INamelessToken.sol';
import './INamelessTokenData.sol';

contract NamelessToken is INamelessToken, ERC721Enumerable, AccessControl, Initializable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REDEEM_ROLE = keccak256('REDEEM_ROLE');

  // Duplicate Token name for cloneability
  string private _name;
  // Duplicate Token symbol for cloneability
  string private _symbol;
  // informational support for external sites that respected Ownable
  address private _legacyOwner;

  address public tokenDataContract;

  function initialize (
    string memory name_,
    string memory symbol_,
    address tokenDataContract_,
    address initialAdmin
  ) public initializer override {
    _name = name_;
    _symbol = symbol_;
    _legacyOwner = initialAdmin;
    tokenDataContract = tokenDataContract_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    emit OwnershipTransferred(address(0), initialAdmin);
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address tokenDataContract_
  ) ERC721(name_, symbol_) {
    initialize(name_, symbol_, tokenDataContract_, msg.sender);
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * emulate Ownable for external applications that expect it
   */
  function owner() public view returns (address) {
    return _legacyOwner;
  }

  function transferLegacyOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(newOwner != address(0), 'new owner is null');
      _legacyOwner = newOwner;
      emit OwnershipTransferred(_legacyOwner, newOwner);
  }

  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
    return INamelessTokenData(tokenDataContract).getFeeRecipients(tokenId);
  }

  function getFeeBps(uint256 tokenId) public view returns (uint256[] memory) {
    return INamelessTokenData(tokenDataContract).getFeeBps(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'no such token');
    return INamelessTokenData(tokenDataContract).getTokenURI(tokenId, ownerOf(tokenId));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
    if (INamelessTokenData(tokenDataContract).beforeTokenTransfer(from, to, tokenId)) {
      emit TokenMetadataChanged(tokenId);
    }
  }

  function redeem(uint256 tokenId, uint256 timestamp, string calldata memo) public onlyRole(REDEEM_ROLE) {
    INamelessTokenData(tokenDataContract).redeem(tokenId);
    emit TokenRedeemed(tokenId, timestamp, memo);
  }

  function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
  }

  function mint(address creator, address recipient, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(creator, tokenId);
    _safeTransfer(creator, recipient, tokenId, '');
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return interfaceId == _INTERFACE_ID_FEES
      || ERC721Enumerable.supportsInterface(interfaceId)
      || AccessControl.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LazyShoeDistribution {
    struct Shoe {
      mapping(uint=>uint) slots;
      uint size;
    }

    function lazyValue( Shoe storage shoe, uint index) private view returns (uint result) {
      result = shoe.slots[index];
      if (result == 0) {
        result = uint16(index) + 1;
      }
    }

    function pop( Shoe storage shoe, uint256 random) internal returns (uint result ) {
      uint lastIndex = shoe.size - 1;
      if (shoe.size == 1) {
        result = lazyValue(shoe, 0);
      } else {
        uint pickIndex = random % shoe.size;
        result = lazyValue(shoe, pickIndex);
        if (pickIndex < lastIndex) {
          shoe.slots[pickIndex] = lazyValue(shoe, lastIndex);
        }
      }

      shoe.slots[lastIndex] = 0;
      shoe.size--;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessToken {
  event TokenMetadataChanged(uint256 tokenId);
  event TokenRedeemed(uint256 tokenId, uint256 timestamp, string memo);

  function initialize(string memory name, string memory symbol, address tokenDataContract, address initialAdmin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessTokenData {
  function initialize ( address templateLibrary, address clonableTokenAddress, address initialAdmin, uint256 maxGenerationSize ) external;
  function getTokenURI(uint256 tokenId, address owner) external view returns (string memory);
  function beforeTokenTransfer(address from, address, uint256 tokenId) external returns (bool);
  function redeem(uint256 tokenId) external;
  function getFeeRecipients(uint256) external view returns (address payable[] memory);
  function getFeeBps(uint256) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import './NamelessTokenData.sol';
import './NamelessToken.sol';

contract NamelessMintingQueue is AccessControl {
  constructor( ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  struct MintingInfo {
    address minter;
    address tokenContract;
    address recipient;
    uint[]  tokenIds;
    string name;
    string symbol;
  }

  mapping (address => MintingInfo ) public mintingInfoByData;

  function addMintingInfo(address minter, address recipient, address tokenDataContract, string calldata name, string calldata symbol, uint256[] calldata tokenIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (mintingInfoByData[tokenDataContract].minter == address(0)) {
      mintingInfoByData[tokenDataContract].minter = minter;
      mintingInfoByData[tokenDataContract].recipient = recipient;
      mintingInfoByData[tokenDataContract].name = name;
      mintingInfoByData[tokenDataContract].symbol = symbol;
    } else {
      require(
        mintingInfoByData[tokenDataContract].minter == address(0) && mintingInfoByData[tokenDataContract].recipient == address(0),
        'cannot update actors'
      );

      require(
        bytes(name).length == 0 && bytes(symbol).length == 0,
        'cannot update token params'
      );
    }

    for(uint idx; idx < tokenIds.length; idx++) {
      mintingInfoByData[tokenDataContract].tokenIds.push(tokenIds[idx]);
    }
  }

  function dropMintingInfo(address tokenDataContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete mintingInfoByData[tokenDataContract];
  }

  function processMintingQueue(address tokenDataContract, uint maxTokens) public {
    MintingInfo storage info = mintingInfoByData[tokenDataContract];
    require(info.minter != address(0), 'no such data contract');
    require(info.tokenContract == address(0) || info.tokenIds.length > 0, 'nothing to do');
    require(msg.sender == info.minter, 'not authorized');

    if (info.tokenContract == address(0)) {
      info.tokenContract = NamelessTokenData(tokenDataContract).createFrontend(info.name, info.symbol);
      require(info.tokenContract != address(0), 'failed to create frontend');

      NamelessToken token = NamelessToken(info.tokenContract);
      token.grantRole(token.MINTER_ROLE(), address(this));
      token.grantRole(token.DEFAULT_ADMIN_ROLE(), info.minter);
      token.grantRole(token.REDEEM_ROLE(), info.minter);
      token.transferLegacyOwnership(info.minter);
      token.renounceRole(token.DEFAULT_ADMIN_ROLE(), address(this));
    }

    uint numToMint = maxTokens < info.tokenIds.length ? maxTokens : info.tokenIds.length;
    for (uint idx = 0; idx < numToMint; idx++) {
      NamelessToken(info.tokenContract).mint(msg.sender,info.recipient, info.tokenIds[idx]);
    }

    if (numToMint == info.tokenIds.length) {
      delete info.tokenIds;
    } else {
      uint remaining = info.tokenIds.length - numToMint;
      for (uint idx = 0; idx < remaining; idx++) {
        info.tokenIds[idx] = info.tokenIds[numToMint + idx];
      }

      while (info.tokenIds.length > remaining) {
        info.tokenIds.pop();
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

import './NamelessMetadataURIV1.sol';
import './NamelessDataV1.sol';
import './INamelessTemplateLibrary.sol';
import './INamelessToken.sol';
import './INamelessTokenData.sol';

contract NamelessTokenData is INamelessTokenData, AccessControl, Initializable {
  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  address private _templateLibrary;
  string private _uriBase;
  address public clonableTokenAddress;
  address public frontendAddress;
  address payable public royaltyAddress;
  uint256 public royaltyBps;
  uint256 public maxGenerationSize;

  function initialize (
    address templateLibrary_,
    address clonableTokenAddress_,
    address initialAdmin,
    uint256 maxGenerationSize_
  ) public override initializer {
    _templateLibrary = templateLibrary_;
    _uriBase = 'data:application/json;base64,';
    clonableTokenAddress = clonableTokenAddress_;
    maxGenerationSize = maxGenerationSize_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(
    address templateLibrary_,
    address clonableTokenAddress_,
    uint256 maxGenerationSize_
  ) {
    initialize(templateLibrary_, clonableTokenAddress_, msg.sender, maxGenerationSize_);
  }

  mapping (uint32 => bool) public generationSealed;

  modifier onlyUnsealed(uint32 generation) {
    require(!generationSealed[generation], 'generation is sealed');
    _;
  }

  modifier onlyFrontend() {
    require(msg.sender == frontendAddress, 'caller not frontend');
    _;
  }

  function sealGeneration(uint32 generation) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation){
    generationSealed[generation] = true;
  }

  function _setColumnData(uint256 columnHash, bytes32[] memory data, uint offset ) internal  {
    bytes32[0xFFFF] storage storageData;
    uint256 columnDataHash = columnHash + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    for( uint idx = 0; idx < data.length; idx++) {
      storageData[idx + offset] = data[idx];
    }
  }

  function _setColumnMetadata(uint256 columnHash, uint columnType ) internal {
    uint256[1] storage columnMetadata;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      columnMetadata.slot := columnHash
    }

    columnMetadata[0] = columnMetadata[0] | ((columnType & 0xFF) << 248);
  }

  struct ColumnConfiguration {
    uint256 columnHash;
    uint256 columnType;
    uint256 dataOffset;
    bytes32[] data;
  }

  function configureData( uint32 generation, ColumnConfiguration[] calldata configs) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation) {
    for(uint idx = 0; idx < configs.length; idx++) {
      uint256 generationSlot = NamelessDataV1.getGenerationalSlot(configs[idx].columnHash, generation);
      _setColumnMetadata(generationSlot, configs[idx].columnType);
      _setColumnData(generationSlot, configs[idx].data, configs[idx].dataOffset);
    }
  }

  function idToGenerationIndex(uint256 tokenId) internal view returns (uint32 generation, uint index) {
    generation = uint32(tokenId / maxGenerationSize);
    index = tokenId % maxGenerationSize;
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION = 0x1;
  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION  = 0x2;
  uint256 public constant TOKEN_REDEEMABLE_EXTENSION     = 0x4;

  mapping (uint => uint256) public extensions;
  function enableExtensions(uint32 generation, uint256 newExtensions) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation) {
    extensions[generation] = extensions[generation] | newExtensions;

    if (newExtensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      initializeTokenTransferCountExtension(generation);
    }

    if (newExtensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      initializeTokenTransferTimeExtension(generation);
    }

    if (newExtensions & TOKEN_REDEEMABLE_EXTENSION != 0) {
      initializeTokenRedeemableExtension(generation);
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_COUNT_EXTENSION_SLOT'));
  function initializeTokenTransferCountExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferCountExtension(uint32 generation, uint index) internal {
    uint256[0xFFFF] storage storageData;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    uint256 dataSlot = generationalSlot + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := dataSlot
    }

    storageData[index] = storageData[index] + 1;
  }

  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_TIME_EXTENSION_SLOT'));
  function initializeTokenTransferTimeExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_TIME_EXTENSION_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferTimeExtension(uint32 generation, uint index) internal {
    uint256[0xFFFF] storage storageData;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    uint256 dataSlot = generationalSlot + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := dataSlot
    }

    // solhint-disable-next-line not-rely-on-time
    storageData[index] = block.timestamp;
  }

  uint256 public constant TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT = uint256(keccak256('TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT'));

  function initializeTokenRedeemableExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;  // uint256
  }


  function beforeTokenTransfer(address from, address, uint256 tokenId) public onlyFrontend override returns (bool) {
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);
    if (extensions[generation] & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      // don't count minting as a transfer
      if (from != address(0)) {
        processTokenTransferCountExtension(generation, index);
      }
    }

    if (extensions[generation] & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      processTokenTransferTimeExtension(generation, index);
    }

    return extensions[generation] & (TOKEN_TRANSFER_COUNT_EXTENSION | TOKEN_TRANSFER_TIME_EXTENSION) != 0;
  }

  function redeem(uint256 tokenId) public onlyFrontend override {
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);
    require(extensions[generation] & TOKEN_REDEEMABLE_EXTENSION != 0, 'Token is not redeemable' );

    uint256[65535] storage redemptionCount;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT, generation);
    uint256 redemptionCountSlot = generationalSlot + 1;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      redemptionCount.slot := redemptionCountSlot
    }

    redemptionCount[index] = redemptionCount[index] + 1;
  }

  function setRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
  }

  function getFeeRecipients(uint256) public view override returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view override returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }

  function setURIBase(string calldata uriBase_) public onlyRole(INFRA_ROLE) {
    _uriBase = uriBase_;
  }

  mapping (uint32 => uint256) public templateIndex;
  mapping (uint32 => bytes32[]) public templateData;
  mapping (uint32 => bytes32[]) public templateCode;

  function setLibraryTemplate(uint32 generation, uint256 which) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex[generation] = which;
    delete(templateData[generation]);
    delete(templateCode[generation]);
  }

  function setCustomTemplate(uint32 generation, bytes32[] calldata _data, bytes32[] calldata _code) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete(templateIndex[generation]);
    templateData[generation] = _data;
    templateCode[generation] = _code;
  }

  function getTokenURI(uint256 tokenId, address owner) public view override returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);

    if (templateCode[generation].length > 0) {
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, templateData[generation], templateCode[generation]);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex[generation]);
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function getTokenMetadata(uint256 tokenId, address owner) public view returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);

    if (templateCode[generation].length > 0) {
      return NamelessMetadataURIV1.makeJson(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, templateData[generation], templateCode[generation]);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex[generation]);
      return NamelessMetadataURIV1.makeJson(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function createFrontend(string calldata name, string calldata symbol) public onlyRole(MINTER_ROLE) returns (address) {
    require(frontendAddress == address(0), 'frontend already created');
    frontendAddress = Clones.clone(clonableTokenAddress);

    INamelessToken frontend = INamelessToken(frontendAddress);
    frontend.initialize(name, symbol, address(this), msg.sender);

    return frontendAddress;
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override( AccessControl) returns (bool) {
    return AccessControl.supportsInterface(interfaceId);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/StorageSlot.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './NamelessDataV1.sol';
import '../utils/Base64.sol';

library NamelessMetadataURIV1 {
  bytes constant private BASE_64_URL_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  function base64EncodeBuffer(bytes memory buffer, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint outLen = (buffer.length + 2) / 3 * 4 - ((3 - ( buffer.length % 3 )) % 3);

    uint256 i = 0;
    uint256 j = outOffset;

    for (; i + 3 <= buffer.length; i += 3) {
        (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            uint8(buffer[i+2])
        );

        j += 4;
    }

    if ((i + 2) == buffer.length) {
      (output[j], output[j+1], output[j+2], ) = base64Encode3(
          uint8(buffer[i]),
          uint8(buffer[i+1]),
          0
      );
    } else if ((i + 1) == buffer.length) {
      (output[j], output[j+1], , ) = base64Encode3(
          uint8(buffer[i]),
          0,
          0
      );
    }

    return outOffset + outLen;
  }

  function base64Encode(uint256 bigint, bytes memory output, uint outOffset) internal pure returns (uint) {
      bytes32 buffer = bytes32(bigint);

      uint256 i = 0;
      uint256 j = outOffset;

      for (; i + 3 <= 32; i += 3) {
          (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }
      (output[j], output[j+1], output[j+2], ) = base64Encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
      return outOffset + 43;
  }

  function base64Encode3(uint256 a0, uint256 a1, uint256 a2)
      internal
      pure
      returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
  {

      uint256 n = (a0 << 16) | (a1 << 8) | a2;

      uint256 c0 = (n >> 18) & 63;
      uint256 c1 = (n >> 12) & 63;
      uint256 c2 = (n >>  6) & 63;
      uint256 c3 = (n      ) & 63;

      b0 = BASE_64_URL_CHARS[c0];
      b1 = BASE_64_URL_CHARS[c1];
      b2 = BASE_64_URL_CHARS[c2];
      b3 = BASE_64_URL_CHARS[c3];
  }

  bytes constant private BASE_58_CHARS = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function ipfsCidEncode(bytes32 value, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint encodedLen = 0;
    for (uint idx = 0; idx < 34; idx++)
    {
      uint carry = 0;
      if (idx >= 2) {
        carry = uint8(value[idx - 2]);
      } else if (idx == 1) {
        carry = 0x20;
      } else if (idx == 0) {
        carry = 0x12;
      }

      for (uint jdx = 0; jdx < encodedLen; jdx++)
      {
        carry = carry + (uint(uint8(output[outOffset + 45 - jdx])) << 8);
        output[outOffset + 45 - jdx] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
      while (carry > 0) {
        output[outOffset + 45 - encodedLen++] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
    }

    for (uint idx = 0; idx < 46; idx++) {
      output[outOffset + idx] = BASE_58_CHARS[uint8(output[outOffset + idx])];
    }

    return outOffset + 46;
  }

  function base10Encode(uint256 bigint, bytes memory output, uint outOffset) internal pure returns (uint) {
    bytes memory alphabet = '0123456789';
    if (bigint == 0) {
      output[outOffset] = alphabet[0];
      return outOffset + 1;
    }

    uint digits = 0;
    uint value = bigint;
    while (value > 0) {
      digits++;
      value = value / 10;
    }

    value = bigint;
    uint currentOffset = outOffset + digits - 1;
    while (value > 0) {
      output[currentOffset] = alphabet[value % 10];
      currentOffset--;
      value = value / 10;
    }

    return outOffset + digits;
  }



  function writeAddressToString(address addr, bytes memory output, uint outOffset) internal pure returns(uint) {
    bytes32 value = bytes32(uint256(uint160(addr)));
    bytes memory alphabet = '0123456789abcdef';

    output[outOffset++] = '0';
    output[outOffset++] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      output[outOffset + (i*2) ]    = alphabet[uint8(value[i + 12] >> 4)];
      output[outOffset + (i*2) + 1] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    outOffset += 40;
    return outOffset;
  }

  function copyDictionaryString(Context memory context, bytes32 columnSlot, uint256 ordinal) internal view returns (uint) {
    bytes32 curSlot;
    uint offset;
    uint length;
    (curSlot, offset, length) = NamelessDataV1.getDictionaryStringInfo(columnSlot, ordinal);

    bytes32 curBuffer;
    uint remaining = length;
    uint bufferCap = 32 - offset;
    uint outIdx = 0;

    while (outIdx < length) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = offset + copyCount;
      curBuffer = StorageSlot.getBytes32Slot(curSlot).value;

      while( offset < lastOffset) {
        context.output[context.outOffset + outIdx++] = curBuffer[offset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      offset = 0;
      curSlot = bytes32(uint(curSlot) + 1);
    }

    return context.outOffset + outIdx;
  }

  function copyString(Context memory context, string memory value) internal pure returns (uint) {
    for (uint idx = 0; idx < bytes(value).length; idx++) {
      context.output[context.outOffset + idx] = bytes(value)[idx];
    }

    return context.outOffset + bytes(value).length;
  }

  function copyNativeString(Context memory context, bytes32 columnSlot, uint256 ordinal) internal view returns (uint) {
    string[] storage nativeStrings;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      nativeStrings.slot := columnSlot
    }

    bytes storage buffer = bytes(nativeStrings[ordinal]);
    uint length = buffer.length;

    for (uint idx = 0; idx < length; idx++) {
      context.output[context.outOffset + idx] = buffer[idx];
    }

    return context.outOffset + length;
  }


  struct Context {
    uint codeBufferIndex;
    uint codeBufferOffset;
    uint256 tokenId;
    uint32 generation;
    uint   index;
    address owner;
    string arweaveContentApi;
    string ipfsContentApi;

    uint opsRetired;

    uint outOffset;
    bytes output;
    bool done;
    uint8  stackLength;
    bytes32[0xFF] stack;
  }

  // 4byte opcode to write the bytes32 at the top of the stack to the output raw and consume it
  // byte 1 is the write codepoint,
  // byte 2 is the write format (0 = raw, 1 = hex, 2 = base64),
  // byte 3 is the offset big-endian to start at and
  // byte 4 is the big-endian byte to stop at (non-inclusive)
  function execWrite(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    require(context.stackLength > 0, 'stack underflow');
    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint start = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint end = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (format == 0) {
      bytes32 stackTop = bytes32(context.stack[context.stackLength - 1]);
      for (uint idx = start; idx < end; idx++) {
        context.output[ context.outOffset ++ ] = stackTop[idx];
      }
    } else if (format == 1) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      bytes memory alphabet = '0123456789abcdef';
      uint startNibble = start * 2;
      uint endNibble = end * 2;

      stackTop >>= (64 - endNibble) * 4;

      context.output[context.outOffset++] = '0';
      context.output[context.outOffset++] = 'x';
      for (uint256 i = endNibble-1; i >= startNibble; i--) {
        uint nibble = stackTop & 0xf;
        stackTop >>= 4;
        context.output[context.outOffset + i - startNibble ] = alphabet[nibble];
      }
      context.outOffset += endNibble - startNibble;
    } else if (format == 2) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      if (start == 0 && end == 32) {
        context.outOffset = base64Encode(stackTop, context.output, context.outOffset);
      } else {
        uint length = end - start;
        bytes memory temp = new bytes(length);
        for (uint idx = 0; idx < length; idx++) {
          temp[idx] = bytes32(stackTop)[start + idx];
        }
        context.outOffset = base64EncodeBuffer(temp, context.output, context.outOffset);
      }
    } else if (format == 3) {
      require(start == 0 && end == 32, 'invalid cid length');
      context.outOffset = ipfsCidEncode(context.stack[context.stackLength - 1], context.output, context.outOffset);
    } else if (format == 4) {
      uint mask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> (start * 8);
      uint shift = (32 - end) * 8;
      uint value = (uint256(context.stack[context.stackLength - 1]) & mask) >> shift;
      context.outOffset = base10Encode(value, context.output, context.outOffset);
    }


    context.stackLength--;
  }
  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteContext(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 0, 'stack underflow');
    uint contextId = uint(context.stack[context.stackLength - 1]);
    context.stackLength--;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (contextId == CONTEXT_TOKEN_ID || contextId == CONTEXT_TOKEN_OWNER || contextId == CONTEXT_BLOCK_TIMESTAMP || contextId == CONTEXT_GENERATION || contextId == CONTEXT_INDEX ) {
      require(format != 0, 'invalid format for uint256');
      uint value = 0;
      if (contextId == CONTEXT_TOKEN_ID) {
        value = context.tokenId;
      } else if (contextId == CONTEXT_TOKEN_OWNER ) {
        value = uint256(uint160(context.owner));
      } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
        // solhint-disable-next-line not-rely-on-time
        value = uint256(block.timestamp);
      } else if (contextId == CONTEXT_GENERATION ) {
        value = context.generation;
      } else if (contextId == CONTEXT_INDEX ) {
        value = context.index;
      }

      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 0; i < 64; i++) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + 63 - i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      } else if (format == 4) {
        context.outOffset = base10Encode(value, context.output, context.outOffset);
      }

    } else if (contextId == CONTEXT_ARWEAVE_CONTENT_API || contextId == CONTEXT_IPFS_CONTENT_API ) {
      require(format == 0, 'invalid format for string');
      string memory value;
      if (contextId == CONTEXT_ARWEAVE_CONTENT_API) {
        value = context.arweaveContentApi;
      } else if ( contextId == CONTEXT_IPFS_CONTENT_API) {
        value = context.ipfsContentApi;
      }

      context.outOffset = copyString(context, value);
    } else {
      revert(string(abi.encodePacked('Unknown/unsupported context ID', Strings.toString(contextId))));
    }
  }

  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteColumnar(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 rawColumnSlot = context.stack[context.stackLength - 2];
    bytes32 columnSlot = bytes32(NamelessDataV1.getGenerationalSlot(uint(rawColumnSlot), context.generation));
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 2;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_NATIVE_STRING) {
      require(format == 0, 'invalid format for string');
      context.outOffset = copyNativeString(context, bytes32(uint256(columnSlot) + 1), columnIndex);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_STRING) {
      require(format == 0, 'invalid format for string');
      context.outOffset = copyDictionaryString(context, bytes32(uint256(columnSlot) + 1), columnIndex);
    } else if (columnType >= NamelessDataV1.COLUMN_TYPE_UINT256 && columnType <= NamelessDataV1.COLUMN_TYPE_UINT8) {
      require(format != 0, 'invalid format for uint');
      uint value = 0;

      if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
        value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT128) {
        value = NamelessDataV1.readUint128Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT64) {
        value = NamelessDataV1.readUint64Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT32) {
        value = NamelessDataV1.readUint32Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT16) {
        value = NamelessDataV1.readUint16Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT8) {
        value = NamelessDataV1.readUint8Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      }

      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 0; i < 64; i++) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + 63 - i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      } else if (format == 3) {
        context.outOffset = ipfsCidEncode(bytes32(value), context.output, context.outOffset);
      } else if (format == 4) {
        context.outOffset = base10Encode(value, context.output, context.outOffset);
      }
    } else {
      revert('unknown column type');
    }
  }

  // 1byte opcode to push the bytes32 at a given index in the data section onto the stack
  // byte 1 is the push codepoint,
  function execPushData(Context memory context, bytes32[] memory dataSegment, bytes32[] memory) internal pure {
    context.stack[context.stackLength-1] = dataSegment[uint256(context.stack[context.stackLength-1])];
  }

  // Nbyte opcode to push the immediate bytes in the codeSegment onto the stack
  // byte 1 is the pushImmediate codepoint,
  // byte 2 big-endian offset to write the first loaded byte from
  // byte 3 number of immediate bytes
  // bytes 4-N big-endian immediate bytes
  function execPushImmediate(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    uint startShiftByte = 31 - uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint length = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 value = 0;
    for (uint idx = 0; idx < length; idx++) {
      uint byteVal = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
      incrementCodeOffset(context);
      value |= byteVal << ((startShiftByte - idx) * 8);
    }

    context.stack[context.stackLength++] = bytes32(value);
  }

  uint private constant CONTEXT_TOKEN_ID = 0;
  uint private constant CONTEXT_TOKEN_OWNER = 1;
  uint private constant CONTEXT_BLOCK_TIMESTAMP = 2;
  uint private constant CONTEXT_ARWEAVE_CONTENT_API = 3;
  uint private constant CONTEXT_IPFS_CONTENT_API = 4;
  uint private constant CONTEXT_GENERATION = 5;
  uint private constant CONTEXT_INDEX = 6;


  // 2byte opcode to push well-known context data to the stack
  // byte 1 is the push codepoint,
  // byte 2 well-known context id
  function execPushContext(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    uint contextId = uint256(context.stack[context.stackLength-1]);

    if (contextId == CONTEXT_TOKEN_ID) {
      context.stack[context.stackLength-1] = bytes32(context.tokenId);
    } else if (contextId == CONTEXT_TOKEN_OWNER ) {
      context.stack[context.stackLength-1] = bytes32(uint256(uint160(context.owner)));
    } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
      // solhint-disable-next-line not-rely-on-time
      context.stack[context.stackLength-1] = bytes32(uint256(block.timestamp));
    } else if (contextId == CONTEXT_GENERATION) {
      context.stack[context.stackLength-1] = bytes32(uint(context.generation));
    } else if (contextId == CONTEXT_INDEX) {
      context.stack[context.stackLength-1] = bytes32(context.index);
    } else {
      revert('Unknown/unsupported context ID in push');
    }
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushStorage(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    bytes32 stackTop = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = StorageSlot.getBytes32Slot(stackTop).value;
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushColumnar(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 rawColumnSlot = context.stack[context.stackLength - 2];
    bytes32 columnSlot = bytes32(NamelessDataV1.getGenerationalSlot(uint(rawColumnSlot), context.generation));
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 1;

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
      uint value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT128) {
      uint value = NamelessDataV1.readUint128Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT64) {
      uint value = NamelessDataV1.readUint64Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT32) {
      uint value = NamelessDataV1.readUint32Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT16) {
      uint value = NamelessDataV1.readUint16Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT8) {
      uint value = NamelessDataV1.readUint8Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else {
      revert('unknown or bad column type');
    }
  }

  function execPop(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stackLength--;
  }

  function execDup(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stack[context.stackLength] = context.stack[context.stackLength - 1];
    context.stackLength++;
  }

  function execSwap(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    (context.stack[context.stackLength - 1], context.stack[context.stackLength - 2]) = (context.stack[context.stackLength - 2], context.stack[context.stackLength - 1]);
  }

  function execAdd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a + b);
    context.stackLength--;
  }

  function execSub(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a - b);
    context.stackLength--;
  }

  function execMul(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a * b);
    context.stackLength--;
  }

  function execDiv(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a / b);
    context.stackLength--;
  }

  function execMod(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a % b);
    context.stackLength--;
  }

  function execJumpPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    addCodeOffset(context, offset);
  }

  function execJumpNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    subCodeOffset(context, offset);
  }

  function execBrEZPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      addCodeOffset(context, offset);
    }
  }

  function execBrEZNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      subCodeOffset(context, offset);
    }
  }

  function execSha3(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = keccak256(abi.encodePacked(a));
  }

  function execXor(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a ^ b;
    context.stackLength--;
  }

  function execOr(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a | b;
    context.stackLength--;
  }

  function execAnd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a & b;
    context.stackLength--;
  }

  function execGt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a > b ? 1 : 0));
    context.stackLength--;
  }

  function execGte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a >= b ? 1 : 0));
    context.stackLength--;
  }

  function execLt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a < b ? 1 : 0));
    context.stackLength--;
  }

  function execLte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a <= b ? 1 : 0));
    context.stackLength--;
  }

  function execEq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a == b ? 1 : 0));
    context.stackLength--;
  }

  function execNeq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a != b ? 1 : 0));
    context.stackLength--;
  }

  uint private constant OP_NOOP                = 0x00;
  uint private constant OP_WRITE               = 0x01;
  uint private constant OP_WRITE_CONTEXT       = 0x02;
  uint private constant OP_WRITE_COLUMNAR      = 0x04;
  uint private constant OP_PUSH_DATA           = 0x05;
  uint private constant OP_PUSH_STORAGE        = 0x06;
  uint private constant OP_PUSH_IMMEDIATE      = 0x07;
  uint private constant OP_PUSH_CONTEXT        = 0x08;
  uint private constant OP_PUSH_COLUMNAR       = 0x09;
  uint private constant OP_POP                 = 0x0a;
  uint private constant OP_DUP                 = 0x0b;
  uint private constant OP_SWAP                = 0x0c;
  uint private constant OP_ADD                 = 0x0d;
  uint private constant OP_SUB                 = 0x0e;
  uint private constant OP_MUL                 = 0x0f;
  uint private constant OP_DIV                 = 0x10;
  uint private constant OP_MOD                 = 0x11;
  uint private constant OP_JUMP_POS            = 0x12;
  uint private constant OP_JUMP_NEG            = 0x13;
  uint private constant OP_BRANCH_POS_EQ_ZERO  = 0x14;
  uint private constant OP_BRANCH_NEG_EQ_ZERO  = 0x15;
  uint private constant OP_SHA3                = 0x16;
  uint private constant OP_XOR                 = 0x17;
  uint private constant OP_OR                  = 0x18;
  uint private constant OP_AND                 = 0x19;
  uint private constant OP_GT                  = 0x1a;
  uint private constant OP_GTE                 = 0x1b;
  uint private constant OP_LT                  = 0x1c;
  uint private constant OP_LTE                 = 0x1d;
  uint private constant OP_EQ                  = 0x1e;
  uint private constant OP_NEQ                 = 0x1f;

  function incrementCodeOffset(Context memory context) internal pure {
    context.codeBufferOffset++;
    if (context.codeBufferOffset == 32) {
      context.codeBufferOffset = 0;
      context.codeBufferIndex++;
    }
  }

  function addCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc += offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function subCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc -= offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function execOne(Context memory context, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view {
    uint nextOp = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);

    incrementCodeOffset(context);

    if (nextOp == OP_NOOP) {
      //solhint-disable-previous-line no-empty-blocks
    } else if (nextOp == OP_WRITE) {
      execWrite(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_CONTEXT) {
      execWriteContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_COLUMNAR) {
      execWriteColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_DATA) {
      execPushData(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_STORAGE) {
      execPushStorage(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_IMMEDIATE) {
      execPushImmediate(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_CONTEXT) {
      execPushContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_COLUMNAR) {
      execPushColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_POP) {
      execPop(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DUP) {
      execDup(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SWAP) {
      execSwap(context, dataSegment, codeSegment);
    } else if (nextOp == OP_ADD) {
      execAdd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SUB) {
      execSub(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MUL) {
      execMul(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DIV) {
      execDiv(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MOD) {
      execMod(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_POS) {
      execJumpPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_NEG) {
      execJumpNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_POS_EQ_ZERO) {
      execBrEZPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_NEG_EQ_ZERO) {
      execBrEZNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SHA3) {
      execSha3(context, dataSegment, codeSegment);
    } else if (nextOp == OP_XOR) {
      execXor(context, dataSegment, codeSegment);
    } else if (nextOp == OP_OR) {
      execOr(context, dataSegment, codeSegment);
    } else if (nextOp == OP_AND) {
      execAnd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GT) {
      execGt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GTE) {
      execGte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LT) {
      execLt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LTE) {
      execLte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_EQ) {
      execEq(context, dataSegment, codeSegment);
    } else if (nextOp == OP_NEQ) {
      execNeq(context, dataSegment, codeSegment);
    } else {
      revert(string(abi.encodePacked('bad op code: ', Strings.toString(nextOp), ' next_pc: ', Strings.toString(context.codeBufferIndex), ',',  Strings.toString(context.codeBufferOffset))));
    }

    context.opsRetired++;

    if (/*context.opsRetired > 7 || */context.codeBufferIndex >= codeSegment.length) {
      context.done = true;
    }
  }

  function interpolateTemplate(uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view returns (bytes memory) {
    Context memory context;
    context.output = new bytes(0xFFFF);
    context.tokenId = tokenId;
    context.generation = generation;
    context.index = index;
    context.owner = owner;
    context.arweaveContentApi = arweaveContentApi;
    context.ipfsContentApi = ipfsContentApi;
    context.outOffset = 0;

    while (!context.done) {
      execOne(context, dataSegment, codeSegment);
    }

    bytes memory result = context.output;
    uint resultLen = context.outOffset;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(result, resultLen)
    }

    return result;
  }

  function makeJson( uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(metadata);
  }

  function makeDataURI( string memory uriBase, uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(abi.encodePacked(uriBase,Base64.encode(metadata)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/BinaryDecoder.sol';
import '../utils/PackedVarArray.sol';


library NamelessDataV1 {
  /*
   * up to 2^32 generations each separated in space by
   * 2^223 empty slots for safety
   * leaving 223 bits of space for collision resistance
   */
  function getGenerationalSlot(uint256 columnName, uint32 generation) internal pure returns (uint256) {
    uint256 finalSlot =
      (columnName & 0x000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
      (uint(generation) << 224);

    return finalSlot;
  }

  /*
   * Special Column Types
   */

  uint256 private constant MAX_COLUMN_WORDS = 65535;
  uint256 private constant MAX_CONTENT_LIBRARIES_PER_COLUMN = 256;
  uint256 private constant CONTENT_LIBRARY_SECTION_SIZE = 32 * MAX_CONTENT_LIBRARIES_PER_COLUMN;

  uint256 public constant COLUMN_TYPE_STRING = 1;
  uint256 public constant COLUMN_TYPE_UINT256 = 2;
  uint256 public constant COLUMN_TYPE_UINT128 = 3;
  uint256 public constant COLUMN_TYPE_UINT64 = 4;
  uint256 public constant COLUMN_TYPE_UINT32 = 5;
  uint256 public constant COLUMN_TYPE_UINT16 = 6;
  uint256 public constant COLUMN_TYPE_UINT8  = 7;
  uint256 public constant COLUMN_TYPE_NATIVE_STRING = 8;

  /**
    * @dev Returns an `uint256[MAX_COLUMN_WORDS]` located at `slot`.
    */
  function getColumn(bytes32 slot) internal pure returns (bytes32[MAX_COLUMN_WORDS] storage r) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
          r.slot := slot
      }
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function getBufferIndexAndOffset(uint index, uint stride, uint baseOffset) internal pure returns (uint, uint) {
    uint offset = (index * stride) + baseOffset;
    return (offset / 32, offset % 32);
  }

  /*
   * Content Library Column
   *
   * @dev a content library column references content from a secondary data source like arweave of IPFS
   *      this content has been batched into libraries to save space.  Each library is a JSON-encoded
   *      array stored on the secondary data source that provides an indirection to the "real" content.
   *      each content library can hold up to 256 content references and each column can reference 256
   *      libraries. This results in a total of 65536 addressable content hashes while only consuming
   *      2 bytes per distinct token.
   */
  function readContentLibraryColumn(bytes32 columnSlot, uint ordinal) public view returns (
    uint contentLibraryHash,
    uint contentIndex
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(ordinal, 2, CONTENT_LIBRARY_SECTION_SIZE);
    uint row = 0;
    (row, , ) = BinaryDecoder.decodeUint16Aligned(column, bufferIndex, offset);

    uint contentLibraryIndex = row >> 8;
    contentIndex = row & 0xFF;
    contentLibraryHash = uint256(column[contentLibraryIndex]);
  }

  function readDictionaryString(bytes32 dictionarySlot, uint ordinal) public view returns ( string memory ) {
    return PackedVarArray.getString(getColumn(dictionarySlot), ordinal);
  }

  function getDictionaryStringInfo(bytes32 dictionarySlot, uint ordinal) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    return PackedVarArray.getStringInfo(getColumn(dictionarySlot), ordinal);
  }

  function readDictionaryStringLength(bytes32 dictionarySlot, uint ordinal) public view returns ( uint ) {
    return PackedVarArray.getStringLength(getColumn(dictionarySlot), ordinal);
  }

  /*
   * Uint256 Column
   *
   */
  function readUint256Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    return uint256(column[ordinal]);
  }

  /*
   * Uint128 Column
   *
   */
  function readUint128Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 2;
    uint shift = (1 - (ordinal % 2)) * 128;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint64 Column
   *
   */
  function readUint64Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 4;
    uint shift = (3 - (ordinal % 4)) * 64;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint32 Column
   *
   */
  function readUint32Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 8;
    uint shift = (7 - (ordinal % 8)) * 32;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFF;
  }

  /*
   * Uint16 Column
   *
   */
  function readUint16Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 16;
    uint shift = (15 - (ordinal % 16)) * 16;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFF;
  }

  /*
   * Uint8 Column
   *
   */
  function readUint8Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 32;
    uint shift = (31 - (ordinal % 32)) * 8;
    return (uint256(column[bufferIndex]) >> shift) & 0xFF;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INamelessTemplateLibrary {
  function getTemplate(uint256 templateIndex) external view returns (bytes32[] memory dataSection, bytes32[] memory codeSection);
  function getContentApis() external view returns (string memory arweaveContentApi, string memory ipfsContentApi);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin public expiriment
// @dev see https://github.com/OpenZeppelin/solidity-jwt/blob/2a787f1c12c50da649eed1670b3a6d9c0221dd8e/contracts/Base64.sol for original
pragma solidity ^0.8.0;

library Base64 {

    bytes constant private BASE_64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory buffer, bytes memory output, uint outOffset) public pure returns (uint) {
      uint outLen = (buffer.length + 2) / 3 * 4;

      uint256 i = 0;
      uint256 j = outOffset;

      for (; i + 3 <= buffer.length; i += 3) {
          (output[j], output[j+1], output[j+2], output[j+3]) = encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }

      if (i + 2 == buffer.length) {
        (output[j], output[j+1], output[j+2], ) = encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            0
        );
        output[j+3] = '=';
      } else if (i + 1 == buffer.length) {
        (output[j], output[j+1], , ) = encode3(
            uint8(buffer[i]),
            0,
            0
        );
        output[j+2] = '=';
        output[j+3] = '=';
      }

      return outOffset + outLen;
    }

    function encode(bytes memory buffer) public pure returns (bytes memory) {
      uint outLen = (buffer.length + 2) / 3 * 4;
      bytes memory result = new bytes(outLen);

      uint256 i = 0;
      uint256 j = 0;

      for (; i + 3 <= buffer.length; i += 3) {
          (result[j], result[j+1], result[j+2], result[j+3]) = encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }

      if (i + 2 == buffer.length) {
        (result[j], result[j+1], result[j+2], ) = encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            0
        );
        result[j+3] = '=';
      } else if (i + 1 == buffer.length) {
        (result[j], result[j+1], , ) = encode3(
            uint8(buffer[i]),
            0,
            0
        );
        result[j+2] = '=';
        result[j+3] = '=';
      }

      return result;
    }

    function encode(uint256 bigint, bytes memory output, uint outOffset) external pure returns (uint) {
        bytes32 buffer = bytes32(bigint);

        uint256 i = 0;
        uint256 j = outOffset;

        for (; i + 3 <= 32; i += 3) {
            (output[j], output[j+1], output[j+2], output[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (output[j], output[j+1], output[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return outOffset + 43;
    }

    function encode(uint256 bigint) external pure returns (string memory) {
        bytes32 buffer = bytes32(bigint);
        bytes memory res = new bytes(43);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= 32; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (res[j], res[j+1], res[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = BASE_64_CHARS[c0];
        b1 = BASE_64_CHARS[c1];
        b2 = BASE_64_CHARS[c2];
        b3 = BASE_64_CHARS[c3];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BinaryDecoder.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library PackedVarArray {
  function getString(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (string memory) {
    bytes memory result = new bytes(len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while( bufferOffset < lastOffset) {
        result[outIdx++] = buffer[bufferOffset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return string(result);
  }

  function getString(bytes32[0xFFFF] storage buffers, uint index) internal view returns (string memory) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;

    return getString(buffers, stringOffset, stringLen);
  }

  function getStringInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;
    uint bufferIdx = stringOffset / 32;
    uint bufferOffset = stringOffset % 32;
    bytes32 bufferSlot;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      bufferSlot := buffers.slot
    }

    bufferSlot = bytes32(uint(bufferSlot) +  bufferIdx);


    return (bufferSlot, bufferOffset, stringLen);
  }

  function getStringLength(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    return stringOffsetLen >> 24;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (uint16[] memory) {
    uint16[] memory result = new uint16[](len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len * 2;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while (bufferOffset < lastOffset) {
        result[outIdx]  = uint16(uint8(buffer[bufferOffset++])) << 8;
        result[outIdx] |= uint16(uint8(buffer[bufferOffset++]));
        outIdx++;
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return result;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint16[] memory) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;

    return getUint16Array(buffers, arrOffset, arrLen);
  }

  function getUint16ArrayInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( uint, uint, uint ) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;
    uint bufferIdx = arrOffset / 32;
    uint bufferOffset = arrOffset % 32;

    return (bufferIdx, bufferOffset, arrLen);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';
import './INamelessTokenData.sol';
import './INamelessTemplateLibrary.sol';

contract NamelessTokenFactory is AccessControl, INamelessTemplateLibrary {
  address public clonableTokenAddress;
  address public clonableTokenDataAddress;

  constructor( address _clonableTokenAddress, address _clonableTokenDataAddress ) {
    clonableTokenAddress = _clonableTokenAddress;
    clonableTokenDataAddress = _clonableTokenDataAddress;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  event NewNamelessTokenDataContract(address indexed owner, address tokenDataAddress);

  function setClonableTokenAddress(address _clonableTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    clonableTokenAddress = _clonableTokenAddress;
  }

  function setClonableTokenDataAddress(address _clonableTokenDataAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    clonableTokenDataAddress = _clonableTokenDataAddress;
  }

  function createTokenDataContract(uint maxGenerationSize) public returns (address) {
    address clone = Clones.clone(clonableTokenDataAddress);
    INamelessTokenData assetData = INamelessTokenData(clone);
    assetData.initialize(address(this), clonableTokenAddress, msg.sender, maxGenerationSize);
    emit NewNamelessTokenDataContract(msg.sender, clone);
    return clone;
  }

  struct TemplateInfo {
    bytes32[] dataSection;
    bytes32[] codeSection;
  }

  mapping (uint256 => TemplateInfo) private templates;

  function setTemplate(uint256 templateIndex, bytes32[] calldata dataSection, bytes32[] calldata codeSection) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templates[templateIndex].dataSection = dataSection;
    templates[templateIndex].codeSection = codeSection;
  }

  function getTemplate(uint256 templateIndex) public view override returns (bytes32[] memory, bytes32[] memory) {
    return (
      templates[templateIndex].dataSection,
      templates[templateIndex].codeSection
    );
  }

  string public arweaveContentApi;
  string public ipfsContentApi;

  function setContentApis(string calldata _arweaveContentApi, string calldata _ipfsontentApi ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    arweaveContentApi = _arweaveContentApi;
    ipfsContentApi = _ipfsontentApi;
  }

  function getContentApis() public view  override returns (string memory, string memory) {
    return (arweaveContentApi, ipfsContentApi);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './NamelessToken.sol';

contract NamelessDutchAuction is AccessControl, Initializable  {
  struct ListingInfo {
    uint64         decayStartTime;
    uint64         decayEndTime;
    uint           initialPrice;
    uint           finalPrice;
    NamelessToken  tokenContract;
    address        minter;
    uint[]         tokenIds;
  }

  ListingInfo[] public listings;
  mapping(uint => bool) public listingActive;
  mapping(uint => uint) public nextTokenIndex;

  address payable public benefactor;
  string public name;

  event ListingPurchased(uint256 indexed listingId, uint index, address buyer, uint256 price);

  function initialize(string memory _name, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(string memory _name) {
    initialize(_name, msg.sender);
  }

  function calculateCurrentPrice(ListingInfo memory template) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    uint256 delta = template.initialPrice - template.finalPrice;

    if (currentTime >= template.decayEndTime) {
      return template.finalPrice;
    } else if (currentTime <= template.decayStartTime) {
      return template.initialPrice;
    }


    uint256 reduction =
      SafeMath.div(SafeMath.mul(delta, currentTime - template.decayStartTime ), template.decayEndTime - template.decayStartTime);
    return template.initialPrice - reduction;
  }

  function calculateCurrentPrice(uint256 listingId) public view returns (uint256) {
    return calculateCurrentPrice(listings[listingId]);
  }

  function bid(uint256 listingId) public payable {
    require(listingActive[listingId] != false, 'listing not active');
    require(listingId < listings.length, 'No such listing');
    ListingInfo storage listing = listings[listingId];

    require(nextTokenIndex[listingId] < listing.tokenIds.length, 'Sold Out');

    uint256 currentPrice = calculateCurrentPrice(listing);
    uint256 tokenId = listing.tokenIds[nextTokenIndex[listingId]];
    nextTokenIndex[listingId] = nextTokenIndex[listingId] + 1;

    require(msg.value >= currentPrice, 'Wrong price');
    if (listing.minter == address(0)) {
      listing.tokenContract.mint(msg.sender, tokenId);
    } else {
      listing.tokenContract.mint(listing.minter, msg.sender, tokenId);
    }

    emit ListingPurchased(listingId, tokenId, msg.sender, currentPrice);

    if (currentPrice < msg.value) {
      Address.sendValue(payable(msg.sender), msg.value - currentPrice);
    }
  }

  function addListings( ListingInfo[] calldata newListings) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newListings.length) {
      listings.push(newListings[idx]);
      idx++;
    }
  }

  function setListingActive( uint[] calldata listingIds, bool active ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < listingIds.length) {
      listingActive[listingIds[idx]] = active;
      idx++;
    }
  }

  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}