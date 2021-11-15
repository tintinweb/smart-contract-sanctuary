// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// No SafeMath needed for Solidity 0.8+
import "@openzeppelin/contracts/access/AccessControl.sol";

// TODO natspec docs

interface IReservationToken {
    function balanceOf(address owner) external view  returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract FaithReservationEvent is AccessControl {
    uint256 public holdsTotal = 0;                      // total amount of tokens held from the vault
    uint256 public depositsTotal = 0;                   // total amount of tokens available to hold
    uint256 public claimedTotal = 0;                    // total amount of tokens claimed from the vault
    uint256 public balancesTotal = 0;                   // total amount of eth deposited into the vault
    uint256 public offChainBalancesTotal = 0;                   // total amount of eth deposited into the vault

    IReservationToken public claimTokenContract;        // the token being traded
    uint256 public decimalsFromClaimTokenContract = 0;  // the number of decimal places in the above token contract

    uint256 private price;                              // the price, in wei, per token
    bool private claimsOpen = false;                    // is the claims window open
    bool private holdsOpen = false;                     // is the holds window open

    // Address where funds are distributed
    address private teamWallet;                         // 

    mapping(address => uint256) private _holds;             // map of contract callers and the amount held
    mapping(address => uint256) private _balances;          // map of contract callers and the amount deposited in eth
    mapping(address => uint256) private _claims;            // map of contract callers and the amount claimed (after holding)
    mapping(address => uint256) private _offchainbalances;  // map of contract callers and the amount claimed (after holding)

    // Event Logs
    event Held(address buyer, uint256 amount);
    event Claimed(address buyer, uint256 amount);
    event DepositedVault(address buyer, uint256 amount);
    event WithdrawnVault(address buyer, uint256 amount);
    event Withdrawn(address buyer, uint256 amount);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(IReservationToken _claimTokenContract, uint256 _price, address _adminRole) {
        _setupRole(ADMIN_ROLE, _adminRole);                                  // after contract creation, the passed address becomes the admin 
        
        // create a single token vault with a single price
        claimTokenContract = _claimTokenContract;                           // reference to the ERC20 token contract for tokens stored in the vault
        decimalsFromClaimTokenContract = claimTokenContract.decimals();     // multiplier for calcs
        price = _price;                                                     // price per token
    }

    function getHoldsTotal() public view returns (uint256) {
        return holdsTotal;
    }

    function getBalancesTotal() public view returns (uint256) {
        return balancesTotal;
    }

    function getOffchainBalancesTotal() public view returns (uint256) {
        return offChainBalancesTotal;
    }

    function getDepositsTotal() public view returns (uint256) {
        return depositsTotal;
    }

    function getPriceInWei() public view returns (uint256) {
        return price;
    }

    function getClaimsOpenState() public view returns (bool) {
        return claimsOpen;
    }

    function getHoldsOpenState() public view returns (bool) {
        return holdsOpen;
    }

    function getTokensRemainingToClaim() public view returns (uint256) {
      return _holds[msg.sender] - _claims[msg.sender];
    }

    // pass in number of tokens expected and send wei with the message payable
    // consider removing numberOfTokens passed, not really needed, requires perfect alignment with the front end
    function hold(uint256 weiAmount, uint256 numberOfTokensExpected) public payable {
        
        // check to make sure holds are open
        require(holdsOpen, "holds not open");

        // check the passed wei matches what is passed and isn't empty
        require(msg.value == weiAmount, "passed payable does not match hold parameter");
        require(msg.value != 0, "passed payable is zero");

        // TODO any need to check for overflows on the numbers??

        // calculate the number of tokens from the ethereum passed 
        uint256 numberOfTokensImplicit = msg.value / price;

        // check the caller expects the correct number of tokens passed by comparing the tokens expected with implicit
        require(numberOfTokensImplicit == numberOfTokensExpected, "number of tokens expected does not match number of tokens based on ethereum passed");
        
        // calculate the actual number of tokens with all the decimal places
        uint256 scaledNumberOfTokens = numberOfTokensImplicit * uint256(10) ** decimalsFromClaimTokenContract;        

        // check that the totalnumber of tokens requested wont go over the number in the vault to start
        require(holdsTotal + scaledNumberOfTokens <= depositsTotal, "not enough tokens available to cover hold amount requested");
        
        // keep track of the callers total tokens held and eth deposted
        _holds[msg.sender] += scaledNumberOfTokens;
        _balances[msg.sender] += msg.value;

        // keep track of contracts total number of tokens held and total eth deposited
        holdsTotal += scaledNumberOfTokens;
        balancesTotal += msg.value;

        emit Held(msg.sender, numberOfTokensExpected);
    }

    function holdForOffchainBuyer(address buyer, uint256 weiAmount, uint256 numberOfTokensExpected) public onlyRole(ADMIN_ROLE) {
        
        // check to make sure holds are open
        require(holdsOpen, "holds not open");

        // check the passed wei matches what is passed and isn't empty
        require(weiAmount != 0, "make sure amount is positive");
        require(numberOfTokensExpected != 0, "make sure amount is positive");
        
        // calculate the number of tokens from the wei amount passed 
        uint256 numberOfTokensImplicit = weiAmount / price;

        // check the caller expects the correct number of tokens passed by comparing the tokens expected with implicit
        require(numberOfTokensImplicit == numberOfTokensExpected, "number of tokens expected does not match number of tokens based on ethereum passed");
        
        // calculate the actual number of tokens with all the decimal places
        uint256 scaledNumberOfTokens = numberOfTokensImplicit * uint256(10) ** decimalsFromClaimTokenContract;        

        // check that the totalnumber of tokens requested wont go over the number in the vault to start
        require(holdsTotal + scaledNumberOfTokens <= depositsTotal, "not enough tokens available to cover hold amount requested");
        
        // keep track of the callers total tokens held and eth deposted
        _holds[buyer] += scaledNumberOfTokens;
        _offchainbalances[buyer] += weiAmount;

        // keep track of contracts total number of tokens held and offchain eth deposited
        holdsTotal += scaledNumberOfTokens;
        offChainBalancesTotal += weiAmount;

        emit Held(msg.sender, numberOfTokensExpected);
    }

    function claim(uint256 numberOfTokens) public {
        _claim(msg.sender, numberOfTokens);
    }

    // enables claims to be performed on behalf of an address by the admin
    function claimForOffchainBuyer(address claimer, uint256 numberOfTokens) public onlyRole(ADMIN_ROLE) {
        _claim(claimer, numberOfTokens);
    }

    // TODO - check the function declaration - any thing else needed? should this be mutex? prob eh
    function _claim(address claimer, uint256 numberOfTokens) private {
        // check to make sure claims are open
        require(claimsOpen, "claims not open");

        // check the offchain buyer has tokens to be issued
        require(_holds[claimer] != 0, "address does not have any tokens on hold");

        uint256 scaledNumberOfTokens = numberOfTokens * uint256(10) ** decimalsFromClaimTokenContract;        

        // TODO check there are enough coins to cover the request
        // scaledNumberOfTokens <= _holds[msg.sender]
        require(scaledNumberOfTokens <= _holds[claimer], "address does not have enough tokens on hold to cover the claim");

        // track total tokens claimed
        _claims[claimer] += scaledNumberOfTokens;
        claimedTotal += scaledNumberOfTokens;    

        // TODO check result of the transfer call - boolean?
        // send tokens to the caller
        claimTokenContract.transfer(claimer, scaledNumberOfTokens);

        emit Claimed(claimer, numberOfTokens);    
    }
    
    // Deposit tokens to be held by the contract vault
    function depositVault(uint256 amountToDeposit) public onlyRole(ADMIN_ROLE) {

        // do a test, not sure this is even required        
        require(amountToDeposit > 0);

        // calculate the actual number of tokens with all the decimal places
        uint256 scaledNumberOfTokens = amountToDeposit * uint256(10) ** decimalsFromClaimTokenContract;        

        // TODO add a check for deposit <= approved allowance for this spender
        // TOOD check the amount to deposit is available
        //      require(claimTokenContract.balanceOf(address(this)) >= scaledNumberOfTokens);
        
        // TODO check result of the transfer call - boolean?
        // transfer tokens from the caller to this contract 
        require(claimTokenContract.transferFrom(msg.sender, address(this), scaledNumberOfTokens), 'Failed to deposit into vault');

        depositsTotal += scaledNumberOfTokens;

        emit DepositedVault(msg.sender, amountToDeposit);
    }
    
    // withdraws all eth
    function withdraw() public onlyRole(ADMIN_ROLE) {        
        // TODO check balance on this contract matches the balances total
        // what happens if it doesn't, maybe just a warning state event??

        require(!holdsOpen && !claimsOpen, 'Cannot withdraw eth while the reservation event is active');

        // TODO check result of the transfer call - boolean?
        //payable(msg.sender).transfer(address(this).balance);
        
        payable(msg.sender).transfer(address(this).balance);
        
        emit Withdrawn(payable(msg.sender), balancesTotal);
    }

    // withdraw tokens from the vault
    function withdrawVault() public onlyRole(ADMIN_ROLE) returns (bool result) {
        // retrieve the number of tokens left in the vault
        uint256 scaledTokensRemaining = claimTokenContract.balanceOf(address(this));

        // adjust the deposits variable
        depositsTotal -= scaledTokensRemaining;

        require(!holdsOpen && !claimsOpen, 'Cannot withdraw remaining vault tokens while the reservation event is active');

        // TODO check result of the transfer call - boolean?
        // Send all tokens in vault to the caller.
        claimTokenContract.transfer(msg.sender, scaledTokensRemaining);

        emit WithdrawnVault(msg.sender, scaledTokensRemaining);
        return true;
    }

    function closeHolds() public onlyRole(ADMIN_ROLE) {
        holdsOpen = false;
    }

    function openHolds() public onlyRole(ADMIN_ROLE) {
        // only allow holds if there are tokens in the vault available to hold
        require(depositsTotal - holdsTotal > 0, 'Not enough tokens deposited (if any) are available to hold');

        holdsOpen = true;
    }
    function closeClaims() public onlyRole(ADMIN_ROLE) {
        
        claimsOpen = false;
    }
    function openClaims() public onlyRole(ADMIN_ROLE) {
                
        claimsOpen = true;
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