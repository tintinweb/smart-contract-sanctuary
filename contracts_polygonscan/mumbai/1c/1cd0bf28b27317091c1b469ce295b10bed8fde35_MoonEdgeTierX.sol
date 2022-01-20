/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

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

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}
 

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
 


/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}
 

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
 
// VRF-MARK TODO-VRF-GOLIVE:Enable



// VRF-MARK TODO-VRF-GOLIVE:Disable
// contract MoonEdgeTierX is AccessControl {
// VRF-MARK TODO-VRF-GOLIVE:Enable
contract MoonEdgeTierX is VRFConsumerBase, AccessControl {
 
    address public upgradedToAddress = address(0);
    address public withdrawWallet;

    uint16 private idoCount = 0;
    mapping(uint16 => uint8) public _idoState; // state: 1 = created
    mapping(uint16 => uint256) public _idoNumberOfParticipants;
    mapping(uint16 => uint256) public _idoTotalNumberOfTickets;
    mapping(uint16 => uint16) public _idoWinnersToDraw;

    // idoId -> ticket id -> participant address
    mapping(uint16 =>  mapping(uint256 => address)) public _idoParticipantsIndex;

    // idoId -> participant address -> index of ticket of participant -> ticket id
    mapping(uint16 => mapping(address => mapping(uint16 => uint256))) public _idoParticipantsTickets;

    // idoId -> participant address -> number of tickets of the participant for the ido
    mapping(uint16 =>  mapping(address => uint16)) public _idoParticipantsTicketCount;

    //address -> 
    //mapping(address => mapping(uint256 => uint256)) private _idoParticipantsTickets;

    //mapping(uint16 =>  mapping(address => uint8)) public _idoParticipantsTickets;//original

    mapping (bytes32 => uint16) public requestSentIdoIdList;
    mapping (bytes32 => uint256) public requestResponseList;

    // not needed as we track length in _idoNumberOfParticipants
    //uint256[][] public _idoParticipantsIndexIds;
    // function _idoParticipantsIndexLength() public view returns(uint256) {
    //     return _idoParticipantsIndexIds.length;
    // }
 


    // Contract addresses Polygon mumbai testnet:
    // - LINK Token	0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    // - VRF Coordinator	0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
    // - Key Hash	0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
    // - Fee	0.0001 LINK

    // VRF-MARK TODO-VRF-GOLIVE:Enable
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator mumbai
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token mumbai
        )
    // VRF-MARK TODO-VRF-GOLIVE:Disable
    // constructor()
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; 

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        withdrawWallet = msg.sender;
    }

 

    function upgrade(address _upgradedToAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        
        upgradedToAddress = _upgradedToAddress;
    }

    // //function CreateIdo(uint16 idoID, uint8 roundId) public returns (bool) {
    function createIdo(uint16 idoID) public returns (bool) {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(! ( _idoState[idoID] > 0 ), "Round already exists");
 
        _idoState[idoID] = 1; 
        _idoNumberOfParticipants[idoID] = 0;
        idoCount++;
        
        return true;
    }
 
    function getIdoCount() public view returns (uint16) {
        return idoCount;
    }

    // be able to add more than one ticket per address
    // check that the address has correct ticket count 
    // function addParticipants(uint16 idoID, address[] calldata participants, uint8[] calldata tickets) 
    // function addParticipants(uint16 idoID, address[] calldata participants) 
    function addParticipants(uint16 idoID, address[] calldata participants, uint8[] calldata tickets) 
        public returns (bool) {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        // // if the ido doesnt exist, create it
        // if( !(_idoState[idoID] > 0) ){
        //     _idoState[idoID] = 1; // state: 1 = open
        // }
        require(_idoState[idoID] == 1, "Ido must be in state open");

        //require(_idoRoundsState[idoID][roundId] > 0, "Round does not exist");

        //uint256 lastTicketId = _idoNumberOfParticipants[idoID];
        _idoNumberOfParticipants[idoID] = _idoNumberOfParticipants[idoID] + participants.length;

        uint256 ticketId = 0;//starts at 0, added for each wallet and ticket
        for(uint256 i = 0; i < participants.length; i++) {
 
            address participantWallet = participants[i];
            require(participantWallet != address(0), "Cannot add zero address");
            //require( ! (_idoRoundsParticipantsTickets[idoID][roundId][participantWallet] >0) , "Cannot add duplicate address");

            for(uint256 y = 0; y < tickets[i]; y++) {
                
                

                // // original
                // require( ! (_idoParticipantsTickets[idoID][participantWallet] > 0) , "Cannot add duplicate address");
                // _idoParticipantsIndex[idoID][i] = participantWallet;
                // _idoParticipantsTickets[idoID][participantWallet] = tickets[i];
            
                // update
                // _idoParticipantsIndex[idoID][i] = participantWallet;
                // _idoParticipantsTicketCount[idoID][participantWallet] = _idoParticipantsTicketCount[idoID][participantWallet] + 1;
                // _idoParticipantsTickets[idoID][participantWallet][ _idoParticipantsTicketCount[idoID][participantWallet] - 1 ] = i;

                // update 2 many tickets per address
                _idoParticipantsIndex[idoID][ticketId] = participantWallet;
                _idoParticipantsTicketCount[idoID][participantWallet] = _idoParticipantsTicketCount[idoID][participantWallet] + 1;
                _idoParticipantsTickets[idoID][participantWallet][ _idoParticipantsTicketCount[idoID][participantWallet] - 1 ] = ticketId;
                _idoTotalNumberOfTickets[idoID] = _idoTotalNumberOfTickets[idoID] + 1;

                ticketId++;
            }

            //Adress 1 har två tickets
            //for(uint256 i = 1; i <= tickets[i]; i++) {
            //    ticketId++;
            //    //_idoParticipantsIndex[idoID][i] = participantWallet;
            //    _idoParticipantsIndex[idoID][ticketId] = participantWallet;
            //    
            //}

        }

        return true;

    }

    // function getParticipantTicketsForRound(uint16 idoID, uint8 roundId, address participantWallet) 
    //     public view returns (uint8) {
    //     require(_idoRoundsState[idoID][roundId] > 0, "Round does not exist");

    //     return _idoRoundsParticipantsTickets[idoID][roundId][participantWallet];
    // }
    function getTicketsForParticipantByIndex(uint16 idoID, address participantWallet, uint16 index) public view virtual returns (uint256) {
        require(_idoState[idoID] > 0, "Round does not exist");

        return _idoParticipantsTickets[idoID][participantWallet][index];
    }

    function getTicketsForParticipantCount(uint16 idoID, address participantWallet) public view virtual returns (uint256) {
        require(_idoState[idoID] > 0, "Round does not exist");

        return _idoParticipantsTicketCount[idoID][participantWallet];
    }

    // function getTicketsForParticipant(uint16 idoID, address participantWallet) 
    //     public view returns (uint8) {
    //     require(_idoState[idoID] > 0, "Round does not exist");

    //     return _idoParticipantsTickets[idoID][participantWallet];
    // }

    uint16 public currentDraw_idoID = 0;

    //vrf
    bytes32 internal keyHash;
    uint256 internal fee;
    event RandomnessRequest(bytes32 requestId);
    event RandomnessResult(uint256 randomness);
    bytes32 public lastRequestId;
    
    //100 winners
    //50-100k participants
    function triggerDraw(uint16 idoID) public returns (bytes32 requestId) {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        require(_idoState[idoID] > 0, "Round does not exist");
        require(_idoState[idoID] == 1, "Ido must be in state open");

        // VRF-MARK TODO-VRF-GOLIVE:Enable
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");

        currentDraw_idoID = idoID;

        // VRF-MARK TODO-VRF-GOLIVE:Enable
        lastRequestId = requestRandomness(keyHash, fee);
        requestSentIdoIdList[lastRequestId] = idoID;

        // test: TODO-VRF-GOLIVE:Disable
        /// lastRequestId = 0x00;
        // requestSentIdoIdList[lastRequestId] = idoID;

        emit RandomnessRequest(lastRequestId);
        return lastRequestId;

    }

    event DebugEvent(string eventName, uint256 intVal, address addressVal, bytes32 bytesVal);

    mapping(uint16 =>  mapping(uint16 => uint256)) public _idoDrawValuesRaw;//winners randomvalues raw, ido->winid->randomValue
    //mapping(uint16 =>  mapping(uint16 => uint256)) public _idoDrawValues;//winners randomValues int, ido->winid->randomValueInt

    mapping(uint16 =>  mapping(uint16 => uint256)) public _idoWinnersParticipantsIndex;//winners list - ido->winid-> is in participant list
    mapping(uint16 =>  mapping(uint16 => uint256)) public _idoWinnersParticipantsIndexOriginal;
    
    mapping(uint16 =>  mapping(uint16 => uint16)) public _idoWinnersParticipantsIndexInArray;//duplicates
    mapping(uint16 =>  mapping(uint16 => address)) public _idoWinnersList;//winners list - ido->winid-> address
    mapping(uint16 =>  mapping(address => uint16)) public _idoWinners;//winners list - ido -> address -> winner index id
    mapping(uint16 =>  mapping(uint16 => uint16)) public _idoWinnersPre;

    // ido -> address -> bool
    mapping(uint16 =>  mapping(address => bool)) public _idoWinnersPreBool;
    mapping(uint16 =>  mapping(address => bool)) public _idoWinnersBool;
    
    
    // flow
    // randomValue = random seed value 
    // _idoDrawValuesRaw[currentDraw_idoID][i] = random value
    // _idoWinnersParticipantsIndex[currentDraw_idoID][i] = winner index
    
    uint16 public winnersToDraw = 5;
    function setWinnersToDraw(uint16 _winnersToDraw) public {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        winnersToDraw = _winnersToDraw;
    }

    // VRF-MARK TODO-VRF-GOLIVE:Disable
    // function fulfillRandomness(bytes32 requestId, uint256 randomness) public {
    // VRF-MARK TODO-VRF-GOLIVE:Enable
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomValue = randomness;

        //require requestResponseList[requestId] is 0
        requestResponseList[requestId] = randomValue;
        uint16 response_IdoId = requestSentIdoIdList[requestId];

        //emit DebugEvent("randomValue-1", randomValue, address(0), 0x00);

        _idoWinnersToDraw[response_IdoId] = winnersToDraw;

        for (uint16 i = 0; i < _idoWinnersToDraw[response_IdoId]; i++) {
            // random value
            _idoDrawValuesRaw[response_IdoId][i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        //emit RandomnessResult(randomValue);
    }

    function finalizeRandomNess(uint16 idoIDToFinalize) public {
        require(address(0) == upgradedToAddress, "Contract has been upgraded to a new address");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        address currAddress = address(0);

        //TODO: change to 100
        for (uint16 i = 0; i < _idoWinnersToDraw[idoIDToFinalize]; i++) {

            currAddress = address(0);

            // winner index in participants array
            _idoWinnersParticipantsIndex[idoIDToFinalize][i] = (_idoDrawValuesRaw[idoIDToFinalize][i] % _idoNumberOfParticipants[idoIDToFinalize] );//zero based
            _idoWinnersParticipantsIndexOriginal[idoIDToFinalize][i] = _idoWinnersParticipantsIndex[idoIDToFinalize][i];

            currAddress = _idoParticipantsIndex[idoIDToFinalize][ _idoWinnersParticipantsIndex[idoIDToFinalize][i] ];
            
            // save that the original address was already a winner
            _idoWinnersPreBool[idoIDToFinalize][ currAddress ] = _idoWinnersBool[idoIDToFinalize][ currAddress ];

            // try to find a new winner
            if(_idoWinnersBool[idoIDToFinalize][ currAddress ]){
                for(uint16 e=0; e<100; e++){
                    _idoWinnersParticipantsIndex[idoIDToFinalize][i]++;
                    //if we reached the end, restart at 0
                    if(_idoWinnersParticipantsIndex[idoIDToFinalize][i] >= _idoNumberOfParticipants[idoIDToFinalize]){
                        _idoWinnersParticipantsIndex[idoIDToFinalize][i] = 0;
                    }
                    currAddress = _idoParticipantsIndex[idoIDToFinalize][ _idoWinnersParticipantsIndex[idoIDToFinalize][i] ];
                    
                    if( !_idoWinnersBool[idoIDToFinalize][ currAddress ]) {
                        break;
                    }
                }
            }

            // add participant address to winners list by id
            _idoWinnersList[idoIDToFinalize][i] = currAddress;
            
            // add participant address to winners list by address
            _idoWinners[idoIDToFinalize][ currAddress ] = i;
            
            _idoWinnersBool[idoIDToFinalize][ currAddress ] = true;

        }

        _idoState[idoIDToFinalize] = 2; //finalized

    }

    // function getChainlinkToken() public view returns (address) {
    //     return address(LINK);
    // }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
 

    fallback() external payable {}
    receive() external payable {}


    // admin functions
    function reopenIdo(uint16 _idoID) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        _idoState[_idoID] = 1; //back to open

    }

    function withdrawAll() public {
        uint256 _each = address(this).balance;
        require(payable(withdrawWallet).send(_each));
    }

    
    function adminWithdrawERC20(address token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

  }