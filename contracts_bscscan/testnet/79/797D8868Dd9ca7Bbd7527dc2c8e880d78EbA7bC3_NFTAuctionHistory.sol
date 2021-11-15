pragma solidity =0.6.6;


import "./openzeppelin/access/AccessControlUpgradeable.sol";
import "./openzeppelin/access/OwnableUpgradeable.sol";
import "./openzeppelin/token/ERC721/ERC721PausableUpgradeable.sol";

import "./openzeppelin/token/ERC20/SafeERC20Upgradeable.sol";
import "./openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import "./libraries/TransferHelper.sol";

// ArtworkNFT
contract ArtworkNFT is ERC721PausableUpgradeable, AccessControlUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant UPDATE_TOKEN_URI_ROLE =
        keccak256("UPDATE_TOKEN_URI_ROLE");
    bytes32 public constant PAUSED_ROLE = keccak256("PAUSED_ROLE");
    uint256 public $nextTokenId;
    address public $mintFeeAddr;

    uint256 public $mintFeeAmount;

    address public $mintTokenAddr;
    uint256 public $mintTokenFeeAmount;

    mapping(uint256 => address) private $minter;

    mapping (uint256 => uint256) private $mintTimes;

    event Mint(
        address indexed seller,
        uint256 timestamp
    );

    event MintWithToken(
        address indexed seller,
        uint256 timestamp
    );

    event Burn(address indexed sender, uint256 tokenId, uint256 timestamp);
    event MintFeeAddressTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );
    event SetMintFeeAmount(
        address indexed seller,
        uint256 oldMintFeeAmount,
        uint256 newMintFeeAmount,
        uint256 timestamp
    );

    event SetMintTokenFeeAmount(
        address indexed seller,
        uint256 oldMintTokenFeeAmount,
        uint256 newMintTokenFeeAmount,
        uint256 timestamp
    );

    event SetMinTokenAddress(
        address indexed seller,
        address oldMinTokenAddress,
        address newMinTokenAddress,
        uint256 timestamp
    );


    function initialize(
        string memory name,
        string memory symbol,
        address mintFeeAddr,
        uint256 mintFeeAmount,
        address mintTokenAddr,
        uint256 mintTokenFeeAmount
    ) initializer
        public virtual
    {

        __ERC721_init(name, symbol);
        __ERC721Pausable_init();
        __AccessControl_init();
        __Ownable_init();

        require(mintTokenAddr != address(0));
        require(mintFeeAddr != address(0));

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(UPDATE_TOKEN_URI_ROLE, _msgSender());
        _setupRole(PAUSED_ROLE, _msgSender());
        $mintFeeAddr = mintFeeAddr;
        $mintFeeAmount = mintFeeAmount;
        $mintTokenAddr = mintTokenAddr;
        $mintTokenFeeAmount = mintTokenFeeAmount;
        $nextTokenId = 1;

        emit MintFeeAddressTransferred(address(0), $mintFeeAddr, now);
        emit SetMintFeeAmount(_msgSender(), 0, $mintFeeAmount, now);

        emit SetMinTokenAddress(_msgSender(), address(0), $mintTokenAddr, now);
        emit SetMintTokenFeeAmount(_msgSender(), 0, $mintTokenFeeAmount, now);
    }

    receive() external payable {}

    function pause() external virtual whenNotPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");

        _pause();
    }

    function unpause() external virtual whenPaused {
        require(hasRole(PAUSED_ROLE, _msgSender()), "Must have pause role");

        _unpause();
    }

    function mint(
        address to,
        string memory tokenURI
    )
        public
        virtual
        payable
        returns (uint256 tokenId)
    {
        require(msg.value >= $mintFeeAmount, "msg value too low");

        TransferHelper.safeTransferETH($mintFeeAddr, $mintFeeAmount);
        tokenId = $nextTokenId;
        _mint(to, tokenId);
        $minter[tokenId] = to;
        $nextTokenId++;
        _setTokenURI(tokenId, tokenURI);
        _setMintTime(tokenId, now);

        if (msg.value > $mintFeeAmount) {
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - $mintFeeAmount
            );
        }

        emit Mint(_msgSender(), now);

    }

    function mintWithToken(
        address to,
        string memory tokenURI
    )
        public
        virtual
        returns (uint256 tokenId)
    {
        require(
            IERC20Upgradeable($mintTokenAddr).balanceOf(_msgSender()) >= $mintTokenFeeAmount,
            "token amount is too low"
        );
        IERC20Upgradeable($mintTokenAddr).safeTransferFrom(
            _msgSender(),
            $mintFeeAddr,
            $mintTokenFeeAmount
        );

        tokenId = $nextTokenId;
        _mint(to, tokenId);
        $minter[tokenId] = to;
        $nextTokenId++;
        _setTokenURI(tokenId, tokenURI);
        _setMintTime(tokenId, now);

        emit MintWithToken(_msgSender(), now);
    }

    function burn(
        uint256 tokenId
    ) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );

        _burn(tokenId);

        delete $mintTimes[tokenId];

        emit Burn(_msgSender(), tokenId, now);
    }

    function setBaseURI(
        string memory baseURI
    ) public virtual
    {
        require(
            hasRole(UPDATE_TOKEN_URI_ROLE, _msgSender()),
            "Must have update token uri role"
        );

        _setBaseURI(baseURI);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) public virtual
    {
        require(
            hasRole(UPDATE_TOKEN_URI_ROLE, _msgSender()),
            "Must have update token uri role"
        );

        _setTokenURI(tokenId, tokenURI);
    }

    function transferMintFeeAddress(
        address mintFeeAddr
    )
        external virtual
    {
        require(_msgSender() == $mintFeeAddr, "FORBIDDEN");
        require(mintFeeAddr != address(0));

        $mintFeeAddr = mintFeeAddr;
        
        emit MintFeeAddressTransferred(_msgSender(), $mintFeeAddr, now);
    }

    function setMintFeeAmount(
        uint256 mintFeeAmount
    )
        external virtual
        onlyOwner
    {
        require($mintFeeAmount != mintFeeAmount, "No need to update");

        emit SetMintFeeAmount(_msgSender(), $mintFeeAmount, mintFeeAmount, now);

        $mintFeeAmount = mintFeeAmount;
    }

    function setMintTokenFeeAmount(
        uint256 mintTokenFeeAmount
    )
        external
        virtual
        onlyOwner
    {
        require($mintTokenFeeAmount != mintTokenFeeAmount, "No need to update");

        emit SetMintTokenFeeAmount(
            _msgSender(),
            $mintTokenFeeAmount,
            mintTokenFeeAmount,
            now
        );
        $mintTokenFeeAmount = mintTokenFeeAmount;
    }

    function setMintTokenAddress(
        address mintTokenAddr
    )
        external virtual
        onlyOwner
    {
        require(mintTokenAddr != address(0));
        require($mintTokenAddr != mintTokenAddr, "No need to update");

        emit SetMinTokenAddress(_msgSender(), $mintTokenAddr, mintTokenAddr, now);

        $mintTokenAddr = mintTokenAddr;
    }

    function minterOf(uint256 tokenId) external virtual view returns (address) {
        return $minter[tokenId];
    }

    function getMintTime(uint256 tokenId) public virtual view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 _mintTime = $mintTimes[tokenId];
        return _mintTime;
    }

    function _setMintTime(uint256 tokenId, uint256 mintTime) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");

        $mintTimes[tokenId] = mintTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

// import "./ERC721Upgradeable.sol";
// import "../../utils/PausableUpgradeable.sol";
// import "../../proxy/Initializable.sol";

import "./ERC721Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is Initializable, ERC721Upgradeable, PausableUpgradeable {
    function __ERC721Pausable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity 0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

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

pragma solidity 0.6.6;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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

pragma solidity 0.6.6;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

pragma solidity 0.6.6;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

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
library SafeMathUpgradeable {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity =0.6.6;

pragma experimental ABIEncoderV2;

import "./openzeppelin/access/AccessControlUpgradeable.sol";
import "./openzeppelin/math/SafeMathUpgradeable.sol";
import "./openzeppelin/access/OwnableUpgradeable.sol";
import "./openzeppelin/utils/PausableUpgradeable.sol";
import "./openzeppelin/token/ERC721/ERC721HolderUpgradeable.sol";
import "./openzeppelin/token/ERC20/SafeERC20Upgradeable.sol";
import "./openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import "./openzeppelin/utils/AddressUpgradeable.sol";
import "./interfaces/INFTMarket.sol";
import "./interfaces/IArtworkNFT.sol";
import "./interfaces/INFTHistory.sol";

import "./libraries/EnumerableMap.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/AskHelper.sol";
import "./libraries/BidHelper.sol";
import "./libraries/TradeHelper.sol";

contract NFTMarket is INFTMarket, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AskHelper for EnumerableMap.UintToUintMap;


    bytes32 public constant SERVICEWORKER_ROLE = keccak256("SERVICEWORKER_ROLE");

    IArtworkNFT public NFT;
    INFTHistory public HISTORY;

    address public $feeAddr;
    uint256 public $feePercent;
    uint256 public $feeToMinterPercent;


    EnumerableMap.UintToUintMap private $asksMap;
    // Avaliable Supported Types of token eg BUSD, JFIN
    EnumerableSet.AddressSet private $quoteErc20Tokens;
    //use for either OFFERING or AUCTION
    EnumerableMap.UintToUintMap private $startTimeMap;
    //use only AUCTION
    EnumerableMap.UintToUintMap private $endTimeMap;

    enum SellingState{
        PENDING,
        OFFERING,
        AUCTION
    }

    mapping(uint256 => SellingState) public $sellingType;

    // Type of suppored token that user choose as currency at specific time
    mapping(uint256 => address) private $asksQuoteTokens;
    mapping(uint256 => address) private $tokenSellers;
    // The current state of Bids
    mapping(uint256 => BidHelper.BidEntry[]) private $bidEntries;

    // The Users' all offering tokens
    mapping(address => EnumerableSet.UintSet) private $userSellingTokens;
    // The Users' all Bids for history of both offering and aunction
    mapping(address => EnumerableMap.UintToUintMap) private $userBids;

    uint256 public TestProxy = 0;

    event Bid(
        address indexed bidder,
        uint256 indexed tokenId,
        uint256 price,
        address quoteTokenAddr,
        uint256 timestamp
    );

    event CancelBidToken(address indexed bidder, uint256 indexed tokenId, uint256 timestamp);

    event Trade(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price,
        address quoteTokenAddr,
        uint256 fee,
        uint256 feeToMinter,
        uint256 timestamp
    );
    event Ask(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price,
        address quoteTokenAddr,
        uint256 timestamp
    );
    event CancelSellToken(address indexed seller, uint256 indexed tokenId, uint256 timestamp);
    event FeeAddressTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );
    event SetFeePercent(
        address indexed seller,
        uint256 oldFeePercent,
        uint256 newFeePercent,
        uint256 timestamp
    );
    event SetFeeToMinterPercent(
        address indexed seller,
        uint256 oldFeePercent,
        uint256 newFeePercent,
        uint256 timestamp
    );
    event AddSupportedQuoteToken(address indexed seller, address quoteToken, uint256 timestamp);
    event RemoveSupportedQuoteToken(address indexed seller, address quoteToken, uint256 timestamp);

    event SetEndTime(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 endTime,
        uint256 timestamp
    );

    event SetStartTime(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 timestamp
    );

    event OnTransferNFT(
        bytes32 indexed eventType,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 blockNumber,
        uint256 timestamp
    );

    modifier onlySupportTokens(address tokenAddr) {
        require($quoteErc20Tokens.contains(tokenAddr), "Suppoted Quoted Tokens are not added");
        _;
    }

    modifier inState(SellingState sellingstate, uint256 tokenId ) {
        require(sellingstate == $sellingType[tokenId], 'current selling state does not allow this');
        _;
    }


    function initialize(
        address nftAddress,
        address historyAddress,
        address[] memory quoteErc20Tokens,
        address feeAddr,
        uint256 feePercent,
        uint256 feeToMinterPercent
    )   initializer
        public
    {
        __ERC721Holder_init();
        __AccessControl_init();
        __Ownable_init();
        __Pausable_init();

        require(nftAddress != address(0) && nftAddress != address(this));

        for (uint256 i = 0; i < quoteErc20Tokens.length; i++) {
            require(
                quoteErc20Tokens[i] != address(0) &&
                    quoteErc20Tokens[i] != address(this)
            );
            if (!$quoteErc20Tokens.contains(quoteErc20Tokens[i])) {
                $quoteErc20Tokens.add(quoteErc20Tokens[i]);
            }
        }

        NFT = IArtworkNFT(nftAddress);
        HISTORY =  INFTHistory(historyAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        $feeAddr = feeAddr;
        $feePercent = feePercent;
        $feeToMinterPercent = feeToMinterPercent;

        emit FeeAddressTransferred(address(0), $feeAddr, now);
        emit SetFeePercent(_msgSender(), 0, $feePercent, now);
        emit SetFeeToMinterPercent(_msgSender(), 0, $feeToMinterPercent, now);
    }

    function pause() external override onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external override onlyOwner whenPaused {
        _unpause();
    }

    //[OWNER]
    // grant role to user so that he/she is able to call sellerTransferAuctionNFT
    function grantServiceWorkerRole(
        address account
    )
        external override
     {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a default admin role");
        grantRole(SERVICEWORKER_ROLE ,account);
    }
    //สำหรับคนซื้อ
    //เลือก NFT ที่ต้องการซื้อทันที (เฉพาะที่ตั้งขายแบบเสนอราคา)
    function buyToken(
        uint256 tokenId     
    )   external override
        inState(SellingState.OFFERING, tokenId)
        whenNotPaused
    {
        buyTokenTo(tokenId, _msgSender());
    }
    
    //สำหรับคนขาย
    //เปลี่ยนเวลาเริ่มสำหรับการขายแบบเสนอราคา
    function setStartTime(
        uint256 tokenId,
        uint256 startTime
    )
        external  override
        whenNotPaused
        inState(SellingState.OFFERING, tokenId)
    {
        require(
            $userSellingTokens[_msgSender()].contains(tokenId),
            "0::Only Seller can set endtime"
        );

        $startTimeMap.set(tokenId, startTime);

        emit SetStartTime(_msgSender(), tokenId, startTime, now);
    }
    //สำหรับคนขาย
    //เปลี่ยนเวลาจบสำหรับการขายแบบประมูล หากมีคนประมูลแล้วเปลี่ยนไม่ได้ หรือถ้าหากเวลาจบใกล้กว่า1วันเปลี่ยนไม่ได้
    function setEndTime(
        uint256 tokenId,
        uint256 endTime
    )
        public override
        inState(SellingState.AUCTION, tokenId)
        whenNotPaused
    {   
        require(
            $userSellingTokens[_msgSender()].contains(tokenId),
            "Only Seller can set endtime"
        );
        require($bidEntries[tokenId].length == 0,  "already have bidder");
        require(endTime > now, "Endtime must be greater than current time");
        require(now < $endTimeMap.get(tokenId) - 1 days, "Endtime must be greater than current time");

        $endTimeMap.set(tokenId, endTime);

        emit SetEndTime(_msgSender(), tokenId, endTime, now);
    }
    //สำหรับคนขาย
    //ตั้งการขายแบบเสนอขาย ใส่เวลาด้วย
    function setPriceOfferingSell (
        uint256 tokenId,
        uint256 starttime,
        uint256 price,
        address quoteTokenAddress
    ) 
        external
        override
        inState(SellingState.PENDING, tokenId)
        whenNotPaused 
    {
        setPriceOfferingSellTo(
            tokenId,
            starttime,
            price,
            quoteTokenAddress,
            address(_msgSender())
        );
    }
    //** โดนเรียกมา
    function setPriceOfferingSellTo (
        uint256 tokenId,
        uint256 startTime,
        uint256 price,
        address quoteTokenAddress,
        address to
    )
        public
        whenNotPaused
        onlySupportTokens(quoteTokenAddress)
        {

        require(
            _msgSender() == NFT.ownerOf(tokenId),
            "0::Only Token Owner can sell token"
        );

        require(price != 0, "0::Price must be greater than zero");
        require(startTime > now, "0::Start time should be setted to present and so on");

        NFT.safeTransferFrom(address(_msgSender()), address(this), tokenId);

        $asksMap.set(tokenId, price);
        $sellingType[tokenId] = SellingState.OFFERING;
        $startTimeMap.set(tokenId, startTime);
        $asksQuoteTokens[tokenId] = quoteTokenAddress;
        $tokenSellers[tokenId] = to;
        $userSellingTokens[to].add(tokenId);

        emit Ask(to, tokenId, price, quoteTokenAddress, startTime);

    }
    //สำหรับคนขาย
    //ตั้งการขายแบบประมูล ใส่เวลาด้วย
    function setAuctionSell (
        uint256 tokenId,
        uint256 starttime,
        uint256 endTime,
        uint256 price,
        address quoteTokenAddress
    ) 
        external override
        inState(SellingState.PENDING, tokenId)
        whenNotPaused 
    {
        setAuctionSellTo(
            tokenId,
            starttime,
            endTime,
            price,
            quoteTokenAddress,
            address(_msgSender())
        );
    }
    //** โดนเรียกมา
    function setAuctionSellTo (
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address quoteTokenAddress,
        address to
    )
        public
        whenNotPaused
        onlySupportTokens(quoteTokenAddress)
        {

        require(
            _msgSender() == NFT.ownerOf(tokenId),
            "0::Only Token Owner can sell token"
        );
        require(price != 0, "0::Price must be greater than zero");
        require(startTime > now, "0::Start time should be setted to present and so on");
        require(endTime > startTime, "endtime need to > starttime");

        $asksMap.set(tokenId, price);
        $sellingType[tokenId] = SellingState.AUCTION;
        $startTimeMap.set(tokenId, startTime);
        $endTimeMap.set(tokenId, endTime);
        $asksQuoteTokens[tokenId] = quoteTokenAddress;
        $tokenSellers[tokenId] = to;
        $userSellingTokens[to].add(tokenId);

        NFT.safeTransferFrom(address(_msgSender()), address(this), tokenId);

        emit Ask(to, tokenId, price, quoteTokenAddress, startTime);

        HISTORY.setAuctionHistory(
            address(this),
            tokenId, 
            _msgSender(),
            startTime,
            endTime,
            price,
            quoteTokenAddress
        );

    }
    //สำหรับคนขาย
    //ยกเลิกการตั้งขายแบบเสนอราคา ยกเลิกได้ทุกเมื่อ
    function cancelPriceOfferingSell(
        uint256 tokenId
    )
        external
        override
        whenNotPaused {
        require(
            $userSellingTokens[_msgSender()].contains(tokenId),
            "0::Only Seller can cancel sell token"
        );

        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);
        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;

        for (uint256 i = $bidEntries[tokenId].length; i > 0; i--) {
            
            address _bidder = $bidEntries[tokenId][i-1].bidder;

            TradeHelper.cancelOfferToken(
                _bidder, 
                tokenId,
                $bidEntries,
                $userBids
            );
        }

        NFT.safeTransferFrom(address(this), _msgSender(), tokenId);

        emit CancelSellToken(_msgSender(), tokenId, now);

    }
    //สำหรับคนขาย
    //ยกเลิกการตั้งขายประมูล หากมีคนเริ่มประมูลแล้วยกเลิกไม่ได้
    function cancelAuctionSell(
        uint256 tokenId
    )
        external
        override
        whenNotPaused {
        require(
            $userSellingTokens[_msgSender()].contains(tokenId) || _msgSender() == owner() ,
            "0::Only Seller can cancel sell token"
        );
        //require($bidEntries[tokenId].length == 0,  "already have bidder");

        if($bidEntries[tokenId].length != 0){
            //IERC20Upgradeable($asksQuoteTokens[tokenId]).safeTransfer($bidEntries[tokenId][0].bidder, $bidEntries[tokenId][0].price);
            TradeHelper.delOfferByTokenIdAndIndex(tokenId, 0, $bidEntries, $userBids);
        }
        address seller1 = $tokenSellers[tokenId];
        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);
        $endTimeMap.remove(tokenId);
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);
        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;

        HISTORY.removeCurrentAuctionHistory(address(this), tokenId);

        NFT.safeTransferFrom(address(this), seller1, tokenId);

        emit CancelSellToken(_msgSender(), tokenId, now);

    }
    //สำหรับคนขาย
    //ปรับราคาตั้งขายสำหรับการเสนอขาย ห้ามต่ำกว่าราคาที่เสนอขายสูงสุดไม่งั้น revert
    function updatePriceForPriceOfferingSell(
        uint256 tokenId,
        uint256 price,
        address quoteTokenAddr
    )
        external override
        inState(SellingState.OFFERING, tokenId)
        whenNotPaused
        onlySupportTokens(quoteTokenAddr) {
        require(
            $userSellingTokens[_msgSender()].contains(tokenId),
            "0::Only Seller can update price"
        );

        require(price != 0, "0::Price must be greater than zero");
        if($bidEntries[tokenId].length > 0){
            uint256 _highestOfferedPrice = price;
            uint256 len = $bidEntries[tokenId].length;
            for (uint256 i = 0; i < len - 1; i++) {
                uint256 _bidPrice = $bidEntries[tokenId][i].price;

                if (_bidPrice > _highestOfferedPrice) {
                    _highestOfferedPrice = _bidPrice;
                }

            }
            require(price > _highestOfferedPrice, "0:: Cannot set price lower than current offered price");
        }
        
        $asksMap.set(tokenId, price);
        $asksQuoteTokens[tokenId] = quoteTokenAddr;
        
        emit Ask(_msgSender(), tokenId, price, quoteTokenAddr, now);
    }
    //สำหรับคนซื้อ
    //เสนอราคา (หากใส่ราคาเกินราคาที่คนขายตั้ง จะทิปไป)
    function offerToken(
        uint256 tokenId,
        uint256  price
    )
        external
        override
        inState(SellingState.OFFERING, tokenId)
        whenNotPaused
    {
        if( price >= $asksMap.get(tokenId)) {
            buyTokenToWithPrice(tokenId, _msgSender(), price);
        } 
        else {
            require(now > $startTimeMap.get(tokenId), "0::Cannot bid before start selling time");
            TradeHelper.offerToken(
                _msgSender(),
                address(this),
                $asksMap,
                $userBids,
                $bidEntries,
                $asksQuoteTokens,
                $tokenSellers,
                tokenId,
                price
            );
        }
        
    }
    //สำหรับคนซื้อ
    //ประมูล ใส่idกับราคา
    function bidToken(
        uint256 tokenId,
        uint256 price
    )
        external
        override
        inState(SellingState.AUCTION, tokenId)
        whenNotPaused
        
    {
        require(now > $startTimeMap.get(tokenId), "0::Cannot bid before start selling time");

        TradeHelper.bidToken(
            _msgSender(),
            address(this),
            $asksMap,
            $endTimeMap,
            $userBids,
            $bidEntries,
            $asksQuoteTokens,
            $tokenSellers,
            tokenId,
            price
        );

        HISTORY.setBidHistory(
            address(this),
            tokenId,
            _msgSender(),
            price,
            $asksQuoteTokens[tokenId]
        );


    }
    //สำหรับคนซื้อ
    //อัพเดตราคาที่เสนอซื้อไป (หากใส่ราคาเกินราคาที่คนขายตั้ง จะทิปไป)
    function updateOfferPrice(
        uint256 tokenId,
        uint256 price
    )
        external
        override
        whenNotPaused
    {
        require(now > $startTimeMap.get(tokenId), "0::Cannot update bid price before start selling time");
        if(price >= $asksMap.get(tokenId)){
            cancelOfferToken(tokenId);
            buyTokenToWithPrice(tokenId, _msgSender(),price);
        }
        else{
            TradeHelper.updateOfferPrice(
            _msgSender(),
            tokenId,
            price,
            $userBids,
            $bidEntries
        );}
        
    }
    //โดนเรียกมา **
    function buyTokenTo(
        uint256 tokenId,
        address to
    )
        public
        whenNotPaused
        inState(SellingState.OFFERING, tokenId)
    {
        require(
            _msgSender() != address(0) && _msgSender() != address(this),
            "Wrong msg sender"
        );
        require($asksMap.contains(tokenId), "Token not in sell book");
        require(
            !$userBids[_msgSender()].contains(tokenId),
            "You must cancel your bid first"
        );
        uint256 _tokenId2 = tokenId;
        NFT.safeTransferFrom(address(this), to, tokenId);
        uint256 price = $asksMap.get(tokenId);
        uint256 feeAmount = price.mul($feePercent).div(100*10**18);
        uint256 feeToMinterAmount = price.mul($feeToMinterPercent).div(100*10**18);

        TradeHelper.transferBuyMoney(
            _msgSender(),
            NFT.minterOf(tokenId),
            $tokenSellers[tokenId],
            $asksMap.get(tokenId),
            feeAmount,
            feeToMinterAmount,
            $feeAddr,
            $asksQuoteTokens[_tokenId2]
        );

        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);

        delete $asksQuoteTokens[tokenId];
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);

        emit Trade(
            $tokenSellers[tokenId],
            to,
            tokenId,
            price,
            $asksQuoteTokens[tokenId],
            feeAmount,
            $feeToMinterPercent,
            now
        );

        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;

    }
    //ไม่ใช้****โดนเรียกมา
    //สำหรับคนซื้อ ซื้อขาดทันที กับ ทิป
    //เสนอราคา
    //TASK refactor to internal?
    function buyTokenToWithPrice(
        uint256 tokenId,
        address to,
        uint256 price
    )
        public
        whenNotPaused
        inState(SellingState.OFFERING, tokenId)
    {
        require(
            _msgSender() != address(0) && _msgSender() != address(this),
            "Wrong msg sender"
        );
        require($asksMap.contains(tokenId), "Token not in sell book");
        require(
            !$userBids[_msgSender()].contains(tokenId),
            "You must cancel your bid first"
        );
        require(price >= $asksMap.get(tokenId), "O::Buying price is less than current price");

        uint256 _tokenId2 = tokenId;

        NFT.safeTransferFrom(address(this), to, tokenId);

        uint256 feeAmount = price.mul($feePercent).div(100*10**18);
        uint256 feeToMinterAmount = price.mul($feeToMinterPercent).div(100*10**18);

        TradeHelper.transferBuyMoney(
            _msgSender(),
            NFT.minterOf(tokenId),
            $tokenSellers[tokenId],
            price,
            feeAmount,
            feeToMinterAmount,
            $feeAddr,
            $asksQuoteTokens[_tokenId2]
        );

        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);
        delete $asksQuoteTokens[tokenId];
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);

        emit Trade(
            $tokenSellers[tokenId],
            to,
            tokenId,
            price,
            $asksQuoteTokens[tokenId],
            feeAmount,
            $feeToMinterPercent,
            now
        );

        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;

    }
    //สำหรับคนขาย
    //เลือกขายให้กับคนที่เคยเสนอราคามา (เลือกใครก็ได้)
    function sellTokenTo(
        uint256 tokenId,
        address to
    )
        external
        override
        whenNotPaused
        inState(SellingState.OFFERING, tokenId)
    {
        require($asksMap.contains(tokenId), "Token not in sell book");
        require(
            $tokenSellers[tokenId] == address(_msgSender()),
            "Only owner can sell token"
        );

        (BidHelper.BidEntry memory bidEntry, uint256 _index) =
            BidHelper.getBidByTokenIdAndAddress($bidEntries, tokenId, to);

        require(bidEntry.price != 0, "Bidder does not exist");

        uint256 _tokenId2 = tokenId;

        NFT.safeTransferFrom(address(this), to, tokenId);

        uint256 feeAmount = bidEntry.price.mul($feePercent).div(100*10**18);
        uint256 feeToMinterAmount =
            bidEntry.price.mul($feeToMinterPercent).div(100*10**18);

        TradeHelper.transferSellMoney(
            NFT.minterOf(tokenId),
            $tokenSellers[tokenId],
            bidEntry.price,
            feeAmount,
            feeToMinterAmount,
            $feeAddr,
            $asksQuoteTokens[_tokenId2]
        );

        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);
        
        TradeHelper.delOfferByTokenIdAndIndex(
            tokenId,
            _index,
            $bidEntries,
            $userBids
        );

        emit Trade(
            $tokenSellers[tokenId],
            to,
            tokenId,
            bidEntry.price,
            bidEntry.quoteTokenAddr,
            feeAmount,
            feeToMinterAmount,
         now
        );

        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;
    }


    function _transferAuctionNFT(
        uint256 tokenId,
        address to
    ) 
        private
        whenNotPaused
    {
        (BidHelper.BidEntry memory bidEntry, uint256 _index) =
            BidHelper.getBidByTokenIdAndAddress($bidEntries, tokenId, to);

        require(bidEntry.price != 0, "Bidder does not exist");
        require($endTimeMap.get(tokenId) < now, "The end time have not pass yet");

        uint256 _tokenId2 = tokenId;
        NFT.safeTransferFrom(address(this), to, tokenId);

        uint256 feeAmount = bidEntry.price.mul($feePercent).div(100*10**18);
        uint256 feeToMinterAmount =
            bidEntry.price.mul($feeToMinterPercent).div(100*10**18);

        TradeHelper.transferSellMoney(
            NFT.minterOf(tokenId),
            $tokenSellers[tokenId],
            bidEntry.price,
            feeAmount,
            feeToMinterAmount,
            $feeAddr,
            $asksQuoteTokens[_tokenId2]
        );
    
        $asksMap.remove(tokenId);
        $startTimeMap.remove(tokenId);
        $endTimeMap.remove(tokenId);
        $userSellingTokens[$tokenSellers[tokenId]].remove(tokenId);

        TradeHelper.delOfferByTokenIdAndIndex(
            tokenId,
            _index,
            $bidEntries,
            $userBids
        );
        
        delete $tokenSellers[tokenId];
        $sellingType[tokenId] = SellingState.PENDING;
        HISTORY.updateBidHistory(address(this), tokenId, true);
    }

    //สำหรับคนซื้อ
    //เลือก tokenId ที่จบการประมูลแล้ว และฟังชั่นจะสั่งขายให้กับคนชนะเอง
    function buyerTransferAuctionNFT(
        uint256 tokenId
    )
        external
        override
        inState(SellingState.AUCTION, tokenId)
        whenNotPaused
    {
        require($asksMap.contains(tokenId), "Token not in sell book");
        address _topBidder = $bidEntries[tokenId][0].bidder;
        require(_topBidder == address(_msgSender()), "Only bidder can transfer NFT for auction");

        _transferAuctionNFT(tokenId, _topBidder);

        emit OnTransferNFT('BUYER_TRANSFER_NFT',
            tokenId,
            $tokenSellers[tokenId],
            _topBidder,
            block.number,
            now
        );

    }

    //สำหรับคนขาย
    //เลือก tokenId ที่จบการประมูลแล้ว และฟังชั่นจะสั่งขายให้กับคนชนะเอง (คนเรียกเป็นเจ้าของหรือแอดมิน)
    function sellerTransferAuctionNFT(
        uint256 tokenId
    )
        external
        override
        inState(SellingState.AUCTION, tokenId)
        whenNotPaused
    {
        require($asksMap.contains(tokenId), "Token not in sell book");
        address _NFTSeller = $tokenSellers[tokenId];
        
        require(
            _NFTSeller == address(_msgSender()) 
            || hasRole(SERVICEWORKER_ROLE, msg.sender)
            ,
            "Only owner can sell token Or Caller is a comitee"
        );
        address _topBidder = $bidEntries[tokenId][0].bidder;

        _transferAuctionNFT(tokenId, _topBidder);

        emit OnTransferNFT('SELLER_TRANSFER_NFT',
            tokenId,
            _NFTSeller,
            _topBidder,
            block.number,
            now
        );
    }

    //สำหรับคนซื้อ
    //ยกเลิกการเสนอราคา id นั้นๆ
    function cancelOfferToken(
        uint256 tokenId
        ) public whenNotPaused {
        TradeHelper.cancelOfferToken(
            _msgSender(),
            tokenId,
            $bidEntries,
            $userBids
        );
        
    }

    function getAsksLength() external override view returns (uint256) {
        return $asksMap.length();
    }

    function getAsks() external view returns (AskHelper.AskEntry[] memory) {
        return $asksMap.getAsks($asksQuoteTokens);
    }

    // function getAsksDesc() external view returns (AskHelper.AskEntry[] memory) {
    //     return $asksMap.getAsksDesc($asksQuoteTokens);
    // }

    function getCurrentPrice(
        uint256 id
    )
        external override
        view
        returns (uint256)
    {
        return $asksMap.get(id);
    }

    // function getAsksByPage(
    //     uint256 page,
    //     uint256 size
    // )
    //     external
    //     view
    //     returns (AskHelper.AskEntry[] memory)
    // {
    //     return $asksMap.getAsksByPage($asksQuoteTokens, page, size);
    // }

    // function getAsksByPageDesc(
    //     uint256 page,
    //     uint256 size
    // )
    //     external
    //     view
    //     returns (AskHelper.AskEntry[] memory)
    // {
    //     return $asksMap.getAsksByPageDesc($asksQuoteTokens, page, size);
    // }

    function getAsksByUser(
        address user
    )
        external
        view
        returns (AskHelper.AskEntry[] memory)
    {
        return $asksMap.getAsksByUser($asksQuoteTokens, $userSellingTokens, user);
    }

    // function getAsksByUserDesc(
    //     address user
    // )
    //     external
    //     view
    //     returns (AskHelper.AskEntry[] memory)
    // {
    //     return
    //         $asksMap.getAsksByUserDesc(
    //             $asksQuoteTokens,
    //             $userSellingTokens,
    //             user
    //         );
    // }

    function getBidsLength(
        uint256 tokenId
    ) external override view returns (uint256) {
        return $bidEntries[tokenId].length;
    }

    function getEndTime (
        uint256 tokenId
    ) external override view returns (uint256) {
        return $endTimeMap.get(tokenId);
    }

     function getStartTime (
         uint256 tokenId
    ) external override view returns (uint256) {
        return $startTimeMap.get(tokenId);
    }

    function getBids(
        uint256 tokenId
    )
        external
        view
        returns (BidHelper.BidEntry[] memory)
    {
        return $bidEntries[tokenId];
    }

    function getUserBids(
        address user
    )
        external
        view
        returns (BidHelper.UserBidEntry[] memory)
    {
        return BidHelper.getUserBids($userBids, $asksQuoteTokens, user);
    }

    function getSupportedQuoteTokens()
        external override
        view
        returns (address[] memory _tokens)
    {
        _tokens = new address[]($quoteErc20Tokens.length());
        for(uint256 i=0; i<$quoteErc20Tokens.length(); i++) {
            _tokens[i] = $quoteErc20Tokens.at(i);
        }
    }

    function addSupportedQuoteToken(
        address quoteTokenAddr
    )
        external override
        onlyOwner
    {
        require(quoteTokenAddr != address(0));
        require(!$quoteErc20Tokens.contains(quoteTokenAddr), "already exists");
        $quoteErc20Tokens.add(quoteTokenAddr);
        emit AddSupportedQuoteToken(_msgSender(), quoteTokenAddr, now);
    }

    // function removeSupportedQuoteToken(
    //     address quoteTokenAddr
    // )
    //     external override
    //     onlyOwner
    //     returns (bool)
    // {
    //     require($quoteErc20Tokens.contains(quoteTokenAddr), "not found");

    //     $quoteErc20Tokens.remove(quoteTokenAddr);

    //     emit RemoveSupportedQuoteToken(_msgSender(), quoteTokenAddr, now);
    // }

    function transferFeeAddress(
        address _feeAddr
    )
        external override
    {
        require(_msgSender() == $feeAddr, "FORBIDDEN");

        $feeAddr = _feeAddr;

        emit FeeAddressTransferred(_msgSender(), $feeAddr, now);
    }

    function setFeePercent(
        uint256 _feePercent
    )
        external override
        onlyOwner
    {
        require($feePercent != _feePercent, "No need to update");

        emit SetFeePercent(_msgSender(), $feePercent, _feePercent, now);

        $feePercent = _feePercent;
    }

    function setFeeToMinterPercent(
        uint256 _feeToMinterPercent
    )
        external override
        onlyOwner
    {
        require($feeToMinterPercent != _feeToMinterPercent, "No need to update");

        emit SetFeeToMinterPercent(
            _msgSender(),
            $feeToMinterPercent,
            _feeToMinterPercent,
         now
        );
        $feeToMinterPercent = _feeToMinterPercent;
    }

    function isSupportedQuoteToken(
        address tokenAddr
    )
        external
        override
        view
        returns (bool)
    {
        return $quoteErc20Tokens.contains(tokenAddr);
    }

    function getCurrentSeller(
        uint256 tokenId
    )
        external
        override
        view
        returns (address)
    {
        return $tokenSellers[tokenId];
    }

 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC721ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

pragma solidity =0.6.6;

interface INFTMarket {
    function grantServiceWorkerRole(address _account) external;
    function buyToken(uint256 _tokenId) external;

    function setStartTime(
        uint256 _tokenId,
        uint256 _startTime
    ) external;

    function setEndTime(
        uint256 _tokenId,
        uint256 _endTime
    )   external;

    function setPriceOfferingSell (
        uint256 _tokenId,
        uint256 _starttime,
        uint256 _price,
        address _quoteTokenAddress
    ) 
        external;


    function setAuctionSell (
        uint256 _tokenId,
        uint256 _starttime,
        uint256 _endTime,
        uint256 _price,
        address _quoteTokenAddress
    ) 
        external;


    function cancelPriceOfferingSell(
        uint256 _tokenId
    )
        external;

    function cancelAuctionSell(
        uint256 _tokenId
    )
        external;

    function updatePriceForPriceOfferingSell(
        uint256 _tokenId,
        uint256 _price,
        address _quoteTokenAddr
    )
        external;

    function offerToken(uint256 _tokenId, uint256 _price)
        external;

    function bidToken(uint256 _tokenId, uint256 _price)
        external;

    function updateOfferPrice(uint256 _tokenId, uint256 _price)
        external;


    function sellTokenTo(uint256 _tokenId, address _to)
        external;


    function buyerTransferAuctionNFT(
        uint256 tokenId
    )
        external;

    function sellerTransferAuctionNFT(
        uint256 tokenId
    )
        external;


    function getAsksLength() external view returns (uint256);


    function getCurrentPrice(uint256 id)
        external
        view
        returns (uint256);


    function getBidsLength(uint256 _tokenId) external view returns (uint256);

    function getEndTime (uint256 _tokenId) external view returns (uint256);

    function getStartTime (uint256 _tokenId) external view returns (uint256);


    function pause() external;

    function unpause() external;

    
    function getSupportedQuoteTokens()
        external
        view
        returns (address[] memory _tokens);

    function addSupportedQuoteToken(address quoteTokenAddr) external;

    // function removeSupportedQuoteToken(address quoteTokenAddr)
    //     external
    //     returns (bool);

    function transferFeeAddress(address _feeAddr) external;

    function setFeePercent(uint256 _feePercent) external;

    function setFeeToMinterPercent(uint256 _feeToMinterPercent)
        external;
        
    
    function isSupportedQuoteToken(address tokenAddr)
        external
        view
        returns (bool);

    function getCurrentSeller(uint256 _tokenId)
        external
        view
        returns (address);


}

pragma solidity =0.6.6;

import "../openzeppelin/token/ERC721/IERC721Upgradeable.sol";


interface IArtworkNFT is IERC721Upgradeable {
    function minterOf(uint256 _tokenId) external view returns (address);
}

pragma solidity =0.6.6;

pragma experimental ABIEncoderV2;

interface INFTHistory {

    enum BidEntryStatus{
        NEW,
        LOSE,
        WIN
    }

    struct BidHistoryEntry {
        uint256 order;
        bytes32 auctionHistoryEntryId;
        uint256 NFTtokenId;
        address bidder;
        uint256 price;
        address quoteTokenAddr;
        BidEntryStatus status;
        uint256 blockNumber;
        uint256 blockTimestamp;
    }


    struct AuctionHistoryEntry {
        bytes32 id;
        uint256 NFTtokenId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        address quoteTokenAddress;
        bool isEnded;
        uint256 blockNumber;
        uint256 blockTimestamp;
    }

    function setAuctionHistory(
        address _bidNft,
        uint256 _tokenId,
        address _seller,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        address _quoteTokenAddress
    ) external;

    function setBidHistory(
        address _bidNft,
        uint256 _tokenId,
        address _bidder,
        uint256 _price,
        address _quoteTokenAddress
    )
        external;


    function removeCurrentAuctionHistory(
        address _bidNft,
        uint256 _tokenId
    ) 
        external;

    function updateBidHistory(
        address _bidNft,
        uint256 _tokenId,
        bool isWinner
    )
        external;

    function getCurrentAuctionHistory(
        uint256 _tokenId
    )
        external
        view
        returns ( AuctionHistoryEntry memory , BidHistoryEntry[] memory);


}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

library EnumerableMap {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, uint256 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, uint256 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (uint256, uint256)
    {
        require(
            map._entries.length > index,
            "EnumerableMap: index out of bounds"
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (uint256)
    {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity =0.6.6;

pragma experimental ABIEncoderV2;


import "../openzeppelin/math/MathUpgradeable.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";


library AskHelper {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;

    struct AskEntry {
        uint256 tokenId;
        uint256 price;
        address quoteTokenAddr;
    }

    function getAsks(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        for (uint256 i = 0; i < _asksMap.length(); ++i) {
            (uint256 tokenId, uint256 price) = _asksMap.at(i);
            asks[i] = AskEntry({
                tokenId: tokenId,
                price: price,
                quoteTokenAddr: _asksQuoteTokens[tokenId]
            });
        }
        return asks;
    }

    function getAsksDesc(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        if (_asksMap.length() > 0) {
            for (uint256 i = _asksMap.length() - 1; i > 0; --i) {
                (uint256 tokenId, uint256 price) = _asksMap.at(i);
                asks[_asksMap.length() - 1 - i] = AskEntry({
                    tokenId: tokenId,
                    price: price,
                    quoteTokenAddr: _asksQuoteTokens[tokenId]
                });
            }
            (uint256 tokenId, uint256 price) = _asksMap.at(0);
            asks[_asksMap.length() - 1] = AskEntry({
                tokenId: tokenId,
                price: price,
                quoteTokenAddr: _asksQuoteTokens[tokenId]
            });
        }
        return asks;
    }

    function getAsksByPage(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens,
        uint256 page,
        uint256 size
    ) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from = page == 0 ? 0 : (page - 1) * size;
            uint256 to =
                MathUpgradeable.min((page == 0 ? 1 : page) * size, _asksMap.length());
            AskEntry[] memory asks = new AskEntry[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                (uint256 tokenId, uint256 price) = _asksMap.at(from);
                asks[i] = AskEntry({
                    tokenId: tokenId,
                    price: price,
                    quoteTokenAddr: _asksQuoteTokens[tokenId]
                });
                ++from;
            }
            return asks;
        } else {
            return new AskEntry[](0);
        }
    }

    function getAsksByPageDesc(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens,
        uint256 page,
        uint256 size
    ) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from =
                _asksMap.length() - 1 - (page == 0 ? 0 : (page - 1) * size);
            uint256 to =
                _asksMap.length() -
                    1 -
                    MathUpgradeable.min(
                        (page == 0 ? 1 : page) * size - 1,
                        _asksMap.length() - 1
                    );
            uint256 resultSize = from - to + 1;
            AskEntry[] memory asks = new AskEntry[](resultSize);
            if (to == 0) {
                for (uint256 i = 0; from > to; ++i) {
                    (uint256 tokenId, uint256 price) = _asksMap.at(from);
                    asks[i] = AskEntry({
                        tokenId: tokenId,
                        price: price,
                        quoteTokenAddr: _asksQuoteTokens[tokenId]
                    });
                    --from;
                }
                (uint256 tokenId, uint256 price) = _asksMap.at(0);
                asks[resultSize - 1] = AskEntry({
                    tokenId: tokenId,
                    price: price,
                    quoteTokenAddr: _asksQuoteTokens[tokenId]
                });
            } else {
                for (uint256 i = 0; from >= to; ++i) {
                    (uint256 tokenId, uint256 price) = _asksMap.at(from);
                    asks[i] = AskEntry({
                        tokenId: tokenId,
                        price: price,
                        quoteTokenAddr: _asksQuoteTokens[tokenId]
                    });
                    --from;
                }
            }
            return asks;
        }
        return new AskEntry[](0);
    }

    function getAsksByUser(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens,
        mapping(address => EnumerableSet.UintSet) storage _userSellingTokens,
        address user
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks =
            new AskEntry[](_userSellingTokens[user].length());
        for (uint256 i = 0; i < _userSellingTokens[user].length(); ++i) {
            uint256 tokenId = _userSellingTokens[user].at(i);
            uint256 price = _asksMap.get(tokenId);
            address quoteTokenAddr = _asksQuoteTokens[tokenId];
            asks[i] = AskEntry({
                tokenId: tokenId,
                price: price,
                quoteTokenAddr: quoteTokenAddr
            });
        }
        return asks;
    }

    function getAsksByUserDesc(
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(uint256 => address) storage _asksQuoteTokens,
        mapping(address => EnumerableSet.UintSet) storage _userSellingTokens,
        address user
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks =
            new AskEntry[](_userSellingTokens[user].length());
        if (_userSellingTokens[user].length() > 0) {
            for (
                uint256 i = _userSellingTokens[user].length() - 1;
                i > 0;
                --i
            ) {
                uint256 tokenId = _userSellingTokens[user].at(i);
                uint256 price = _asksMap.get(tokenId);
                asks[_userSellingTokens[user].length() - 1 - i] = AskEntry({
                    tokenId: tokenId,
                    price: price,
                    quoteTokenAddr: _asksQuoteTokens[tokenId]
                });
            }
            uint256 tokenId = _userSellingTokens[user].at(0);
            uint256 price = _asksMap.get(tokenId);
            asks[_userSellingTokens[user].length() - 1] = AskEntry({
                tokenId: tokenId,
                price: price,
                quoteTokenAddr: _asksQuoteTokens[tokenId]
            });
        }
        return asks;        
    }
}

pragma solidity =0.6.6;

import "./EnumerableMap.sol";


library BidHelper {
    using EnumerableMap for EnumerableMap.UintToUintMap;

    struct BidEntry {
        address bidder;
        uint256 price;
        address quoteTokenAddr;
        uint256 timestamp;
    }

    struct UserBidEntry {
        uint256 tokenId;
        uint256 price;
        address quoteTokenAddr;
    }

    function getUserBids(
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids,
        mapping(uint256 => address) storage _asksQuoteTokens,
        address user
    ) internal view returns (UserBidEntry[] memory) {

        uint256 len = _userBids[user].length();
        UserBidEntry[] memory bids = new UserBidEntry[](len);
        for (uint256 i = 0; i < len; i++) {
            (uint256 tokenId, uint256 price) = _userBids[user].at(i);
            bids[i] = UserBidEntry({
                tokenId: tokenId,
                price: price,
                quoteTokenAddr: _asksQuoteTokens[tokenId]
                
            });
        }

        return bids;
    }

    function getBidByTokenIdAndAddress(
        mapping(uint256 => BidEntry[]) storage _tokenBids,
        uint256 _tokenId,
        address _address
    ) internal view returns (BidEntry memory, uint256) {
        // find the index of the bid
        BidEntry[] memory bidEntries = _tokenBids[_tokenId];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_address == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({
                    bidder: bidEntries[i].bidder,
                    price: bidEntries[i].price,
                    quoteTokenAddr: bidEntries[i].quoteTokenAddr,
                    timestamp: bidEntries[i].timestamp
                });
                break;
            }
        }

        return (bidEntry, _index);
    }
}

pragma solidity =0.6.6;


import "../openzeppelin/token/ERC20/SafeERC20Upgradeable.sol";
import "../openzeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../openzeppelin/token/ERC721/IERC721Upgradeable.sol";
import "../openzeppelin/math/SafeMathUpgradeable.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./BidHelper.sol";


library TradeHelper {
    using SafeMathUpgradeable for uint256;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Bid(
        address indexed bidder,
        uint256 indexed tokenId,
        uint256 price,
        address quoteTokenAddr,
        uint256 timestamp
    );

    event CancelBidToken(address indexed bidder, uint256 indexed tokenId, uint256 timestamp);

    //to do function name?
    function updateOfferPrice(
        address _sender,
        uint256 _tokenId,
        uint256 _price,
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids,
        mapping(uint256 => BidHelper.BidEntry[]) storage _tokenBids        
    ) public {
        require(
            _userBids[_sender].contains(_tokenId),
            "Only Bidder can update the bid price"
        );
        require(_price != 0, "Price must be granter than zero");
        address _to = _sender; // find  bid and the index
        (BidHelper.BidEntry memory bidEntry, uint256 _index) =
            BidHelper.getBidByTokenIdAndAddress(_tokenBids, _tokenId, _to);
        require(bidEntry.price != 0, "Bidder does not exist");
        require(bidEntry.price != _price, "The bid price cannot be the same");
        if (_price > bidEntry.price) {
            IERC20Upgradeable(bidEntry.quoteTokenAddr).safeTransferFrom(
                address(_sender),
                address(this),
                _price - bidEntry.price
            );
        } else {
            IERC20Upgradeable(bidEntry.quoteTokenAddr).transfer(
                _to,
                bidEntry.price - _price
            );
        }

        _userBids[_to].set(_tokenId, _price);
        _tokenBids[_tokenId][_index] = BidHelper.BidEntry({
            bidder: _to,
            price: _price,
            quoteTokenAddr: bidEntry.quoteTokenAddr,
            timestamp: now
        });

        emit Bid(_sender, _tokenId, _price, bidEntry.quoteTokenAddr, now);
    }

    function delOfferByTokenIdAndIndex(
        uint256 _tokenId,
        uint256 _index,
        mapping(uint256 => BidHelper.BidEntry[]) storage _tokenBids,
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids
    ) public {
        _userBids[_tokenBids[_tokenId][_index].bidder].remove(_tokenId);
        // delete the bid
        uint256 len = _tokenBids[_tokenId].length;
        for (uint256 i = _index; i < len - 1; i++) {
            _tokenBids[_tokenId][i] = _tokenBids[_tokenId][i + 1];
        }
        _tokenBids[_tokenId].pop();
    }

    // [USER]: buyer
    function cancelOfferToken(
        address _sender,
        uint256 _tokenId,
        mapping(uint256 => BidHelper.BidEntry[]) storage _tokenBids,
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids
    ) public {
        require(
            _userBids[_sender].contains(_tokenId),
            "Only Bidder can cancel the bid"
        );
        // find  bid and the index
        (BidHelper.BidEntry memory bidEntry, uint256 _index) =
            BidHelper.getBidByTokenIdAndAddress(_tokenBids, _tokenId, _sender);
        require(bidEntry.price != 0, "Bidder does not exist");

        IERC20Upgradeable(bidEntry.quoteTokenAddr).transfer(_sender, bidEntry.price);
        delOfferByTokenIdAndIndex(_tokenId, _index, _tokenBids, _userBids);

        emit CancelBidToken(_sender, _tokenId, now);
    }

    // ** not returning money
    function offerToken(
        address _sender,
        address _contract,
        EnumerableMap.UintToUintMap storage _asksMap,
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids,
        mapping(uint256 => BidHelper.BidEntry[]) storage _tokenBids,
        mapping(uint256 => address) storage _asksQuoteTokens,
        mapping(uint256 => address) storage _tokenSellers,
        uint256 _tokenId,
        uint256 _price
    ) public {
        require(
            _sender != address(0) && _sender != _contract,
            "Wrong msg sender"
        );
        require (_price <=  _asksMap.get(_tokenId), "Offer must be less than sell price");
        require(_price != 0, "Price must be granter than zero");
        require(_asksMap.contains(_tokenId), "Token not in sell book");

        address _seller = _tokenSellers[_tokenId];
        address _to = address(_sender);

        require(_seller != _to, "Owner cannot bid");
        require(!_userBids[_to].contains(_tokenId), "Bidder already exists");
        
        address quoteTokenAddr = _asksQuoteTokens[_tokenId];
        IERC20Upgradeable(quoteTokenAddr).safeTransferFrom(_sender, _contract, _price);
        _userBids[_to].set(_tokenId, _price);
        _tokenBids[_tokenId].push(
            BidHelper.BidEntry({
                bidder: _to,
                price: _price,
                quoteTokenAddr: quoteTokenAddr,
                timestamp: now
            })
        );

        emit Bid(_sender, _tokenId, _price, quoteTokenAddr, now);
    }

    function bidToken(
        address _sender,
        address _contract,
        EnumerableMap.UintToUintMap storage _asksMap,
        EnumerableMap.UintToUintMap storage _endTimeMap,
        mapping(address => EnumerableMap.UintToUintMap) storage _userBids,
        mapping(uint256 => BidHelper.BidEntry[]) storage _tokenBids,
        mapping(uint256 => address) storage _asksQuoteTokens,
        mapping(uint256 => address) storage _tokenSellers,
        uint256 _tokenId,
        uint256 _price
    ) public {
        require(
            _sender != address(0) && _sender != _contract,
            "Wrong msg sender"
        );
        require(_price >=  _asksMap.get(_tokenId), "Bid must be granter than start price");
        require(_price != 0, "Price must be granter than zero");
        require(_asksMap.contains(_tokenId), "Token not in sell book");

        address _seller = _tokenSellers[_tokenId];
        address _to = address(_sender);

        require(_seller != _to, "Owner cannot bid");
        require(!_userBids[_to].contains(_tokenId), "Bidder already exists");
        require(_endTimeMap.get(_tokenId) > now, "The end time have passed");

        address quoteTokenAddr = _asksQuoteTokens[_tokenId];
        if(_tokenBids[_tokenId].length == 0){
            IERC20Upgradeable(quoteTokenAddr).safeTransferFrom(_sender, _contract, _price);
            _userBids[_to].set(_tokenId, _price);
            _tokenBids[_tokenId].push(
            BidHelper.BidEntry({
                bidder: _to,
                price: _price,
                quoteTokenAddr: quoteTokenAddr,
                timestamp: now
            })
            );
            }
        else{
            require(_price > _tokenBids[_tokenId][0].price, "Offer must be granter than previous bid");
            IERC20Upgradeable(quoteTokenAddr).safeTransfer(_tokenBids[_tokenId][0].bidder, _tokenBids[_tokenId][0].price);
            delOfferByTokenIdAndIndex(_tokenId, 0, _tokenBids, _userBids);
            IERC20Upgradeable(quoteTokenAddr).safeTransferFrom(_sender, _contract, _price);
            
            _userBids[_to].set(_tokenId, _price);
            _tokenBids[_tokenId].push(
            BidHelper.BidEntry({
                bidder: _to,
                price: _price,
                quoteTokenAddr: quoteTokenAddr,
                timestamp: now
            })
            );
            emit CancelBidToken(_sender, _tokenId, now);
            }
       
        emit Bid(_sender, _tokenId, _price, quoteTokenAddr, now);
    }
    
    function transferSellMoney(
        address _creator,
        address _seller,
        uint256 _price,
        uint256 _feeAmount,
        uint256 _feeToOwnerAmount,
        address _feeAddr,
        address _quoteTokenAddr
    ) public {
        if (_feeAmount != 0) {
            IERC20Upgradeable(_quoteTokenAddr).transfer(_feeAddr, _feeAmount);
        }
        if (_feeToOwnerAmount != 0) {
            IERC20Upgradeable(_quoteTokenAddr).transfer(_creator, _feeToOwnerAmount);
        }
        IERC20Upgradeable(_quoteTokenAddr).transfer(
            _seller,
            _price.sub(_feeAmount).sub(_feeToOwnerAmount)
        );
    }

    function transferBuyMoney(
        address _buyer,
        address _creator,
        address _seller,
        uint256 _price,
        uint256 _feeAmount,
        uint256 _feeToOwnerAmount,
        address _feeAddr,
        address _quoteTokenAddr
    ) public {
        if (_feeAmount != 0) {
            IERC20Upgradeable(_quoteTokenAddr).safeTransferFrom(
                _buyer,
                _feeAddr,
                _feeAmount
            );
        }
        if (_feeToOwnerAmount != 0) {
            IERC20Upgradeable(_quoteTokenAddr).safeTransferFrom(
                _buyer,
                _creator,
                _feeToOwnerAmount
            );
        }
        IERC20Upgradeable(_quoteTokenAddr).safeTransferFrom(
            _buyer,
            _seller,
            _price.sub(_feeAmount).sub(_feeToOwnerAmount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

pragma solidity =0.6.6;

pragma experimental ABIEncoderV2;

import "./openzeppelin/access/AccessControlUpgradeable.sol";
import "./openzeppelin/access/OwnableUpgradeable.sol";
import "./openzeppelin/utils/PausableUpgradeable.sol";
import "./interfaces/INFTHistory.sol";

contract NFTAuctionHistory is INFTHistory, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable {

    // tokenId: uint256 => auctionHistoryId: sha256
    // Pre-removed
    // mapping(uint256 => mapping(bytes32 => AuctionHistoryEntry)) public _auctionHistories;

    // tokenId: uint256 => currentAuctionHistoryId: sha256
    mapping(uint256 => bytes32) private $currentAuctionHistory;

    //? ใช้ Token ID เพื่อดึง List ของ Auction History Timestamp (เพื่อนำมาดึง Auction History แต่ละรายการ)
    // tokenId: uint256 => auctionHistoryTimestamp[]: uint256
    mapping(uint256 => uint256[]) private $auctionHistoryTimestampList;

    //? ใช้ Auction History Timestamp เพื่อหา Auction History Id (Hash)
    // auctionHistoryTimestamp: uint256 => auctionHistoryId: bytes32
    // mapping(uint256 => mapping(uint256 => bytes32)) private _auctionHistoryId;
    //tokenid -> blockTimestamp - > hash
    mapping(uint256 => mapping(uint256 => bytes32)) private $auctionHistoryTimestampMap;

    //? ใช้ Auction History Id เพื่อหา Auction History Entry
    // auctionHistory: bytes32 => auctionHistoryEntry;
    mapping(bytes32 => AuctionHistoryEntry) private $auctionHistoryEntry;

    //TASK: Fix to private

    // ? hash: => bidHistoryId: sha256 (same as auctionHistoryId)
    mapping(bytes32 => BidHistoryEntry[]) private $bidHistoryEntries;

    // ?
    // bytes32[] private _bidHistoryTimestampEntryId;


    // // tokenId: uint256 =>  
    // // ?
    // mapping(uint256 => bytes32) private _bidHistoryTimestampEntryId;


    event EventAuctionEntry(
        bytes32 indexed eventType,
        bytes32 indexed id,
        uint256 indexed NFTtokenId,
        address seller,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address quoteTokenAddress,
        bool isEnded,
        uint256 blockNumber,
        uint256 blockTimestamp
    );

    event EventBidEntry(
        bytes32 indexed eventType,
        bytes32 indexed id,
        uint256 indexed NFTtokenId,
        address bidder,
        uint256 price,
        address quoteTokenAddr,
        uint256 blockNumber,
        uint256 blockTimestamp
    );

    function initialize() initializer
        public
    {
        __AccessControl_init();
        __Ownable_init();
        __Pausable_init();
    }


    function setAuctionHistory(
        address NFT_MARKET_CONTRACT,
        uint256 tokenId,
        address seller,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address quoteTokenAddress
    )
        external override
    {
        require(_msgSender() == NFT_MARKET_CONTRACT, "Caller must be NFT Market Contract");
        uint256 _blockNumber = block.number;
        uint256 _timestamp = now;
        bytes32 _entryId = keccak256(abi.encodePacked( tokenId, _blockNumber, _timestamp));

        $currentAuctionHistory[tokenId] = _entryId;
        $auctionHistoryTimestampList[tokenId].push(_timestamp);

        $auctionHistoryTimestampMap[tokenId][_timestamp] = _entryId; 

        AuctionHistoryEntry storage auctionEntry_;
        auctionEntry_.id = _entryId;
        auctionEntry_.NFTtokenId = tokenId;
        auctionEntry_.seller = seller;
        auctionEntry_.startTime = startTime;
        auctionEntry_.endTime = endTime;
        auctionEntry_.price = price;
        auctionEntry_.quoteTokenAddress = quoteTokenAddress;
        auctionEntry_.isEnded = false;
        auctionEntry_.blockNumber = _blockNumber;
        auctionEntry_.blockTimestamp = _timestamp;

        $auctionHistoryEntry[_entryId] = auctionEntry_;

        emit EventAuctionEntry( 'SET_AUCTION', _entryId, tokenId, seller, startTime, endTime, price, quoteTokenAddress, auctionEntry_.isEnded, _blockNumber, _timestamp );

    }


    function setBidHistory(
        address NFT_MARKET_CONTRACT,
        uint256 tokenId,
        address bidder,
        uint256 price,
        address quoteTokenAddress
    )
        external override
    {
        require(_msgSender() == NFT_MARKET_CONTRACT, "Caller must be NFT Market Contract");
        uint256 _blockNumber = block.number;
        uint256 _timestamp = now;
        bytes32 _currentAuctionHistoryId = $currentAuctionHistory[tokenId];
        BidHistoryEntry[] storage bids_ = $bidHistoryEntries[_currentAuctionHistoryId];


        bids_.push(BidHistoryEntry(
            bids_.length-1,
            _currentAuctionHistoryId,
            tokenId,
            bidder,
            price,
            quoteTokenAddress,
            BidEntryStatus.NEW,
            _blockNumber,
            _timestamp
        ));


        emit EventBidEntry( 'SET_BID', _currentAuctionHistoryId, tokenId, bidder, price, quoteTokenAddress, _blockNumber, _timestamp);

        INFTHistory(address(this)).updateBidHistory(NFT_MARKET_CONTRACT, tokenId, false);

    }

    function updateBidHistory(
        address NFT_MARKET_CONTRACT,
        uint256 tokenId,
        bool isWinner
    )
        external override
    {
        require(_msgSender() == address(this) || _msgSender() == NFT_MARKET_CONTRACT , "Caller must be NFT Market Contract");

        bytes32 _currentAuctionHistoryId = $currentAuctionHistory[tokenId];
        BidHistoryEntry[] storage bids_ = $bidHistoryEntries[_currentAuctionHistoryId];

        uint256 _order = bids_.length - 1;

        if(_order > 0) {
            BidHistoryEntry storage previousOrder = bids_[_order-1];
            previousOrder.status = BidEntryStatus.LOSE;
        }

        if(isWinner) {
            
            AuctionHistoryEntry storage auctionEntry_ = $auctionHistoryEntry[_currentAuctionHistoryId];
            auctionEntry_.isEnded = true;
            $auctionHistoryEntry[_currentAuctionHistoryId] = auctionEntry_;
            BidHistoryEntry storage currentOrder = bids_[_order];
            currentOrder.status = BidEntryStatus.WIN;
        }
        
    }

    function removeCurrentAuctionHistory(
        address NFT_MARKET_CONTRACT,
        uint256 tokenId
    )
        external override
    {
        require(_msgSender() == NFT_MARKET_CONTRACT, "Caller must be NFT Market Contract");

        (AuctionHistoryEntry memory _auctionHistory, BidHistoryEntry[] memory _bidHistories) = getCurrentAuctionHistory(tokenId);

        delete $currentAuctionHistory[tokenId];

        emit EventAuctionEntry( 'REMOVE_CURRENT_AUCTION', _auctionHistory.id, _auctionHistory.NFTtokenId, _auctionHistory.seller, _auctionHistory.startTime, _auctionHistory.endTime, _auctionHistory.price, _auctionHistory.quoteTokenAddress, _auctionHistory.isEnded, _auctionHistory.blockNumber, _auctionHistory.blockTimestamp );

    }


    function getCurrentAuctionHistory(
        uint256 tokenId
    )
        public view override
       returns (AuctionHistoryEntry memory , BidHistoryEntry[] memory)
    {
        bytes32 currentAuctionHistoryId = $currentAuctionHistory[tokenId];
        AuctionHistoryEntry memory _auctionHistory = $auctionHistoryEntry[currentAuctionHistoryId];
        BidHistoryEntry[] memory _bidHistory =  $bidHistoryEntries[currentAuctionHistoryId];
        return ( _auctionHistory, _bidHistory);
    }

    function getAuctionHistoryById(
        bytes32 hashId
    ) 
        external
        view
        returns ( AuctionHistoryEntry memory , BidHistoryEntry[] memory)
    {
        AuctionHistoryEntry memory _auctionHistory = $auctionHistoryEntry[hashId];
        BidHistoryEntry[] memory _bidHistory = $bidHistoryEntries[hashId];
        return (_auctionHistory, _bidHistory);
    }

    function getHistoryTimestampSet(
        uint256 tokenId
    ) 
        public
        view
        returns (uint256[] memory)
    {
        return  $auctionHistoryTimestampList[tokenId];

    }

    //

    function getAuctionHistoryIdByTimestamp(
        uint256 tokenId,
        uint256 timestamp
    ) 
        public
        view
        returns (bytes32)
    {
        return  $auctionHistoryTimestampMap[tokenId][timestamp];

    }   

}

pragma solidity =0.6.6;

import "./openzeppelin/token/ERC20/ERC20Upgradeable.sol";

contract BasicToken is ERC20Upgradeable {


    function initialize(
        string memory name,
        string memory symbol,
        uint256 supply
    ) initializer public virtual {
        __ERC20_init(name, symbol);
        _mint(msg.sender, supply);
    }
}

