// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./roles/AccessOperatable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface MCHLandPool {
    function addToLandPool(uint256 addAmount, uint16 _landType, address _purchaseBy) external payable;
}

interface IngameMoney {
    function hashTransactedAt(bytes32 _hash) external view returns(uint256);
    function buy(address payable _user, address payable _referrer, uint256 _referralBasisPoint, bytes calldata _signature, bytes32 _hash)
        external
        payable;
}

contract MCHGUMGatewayPolygon is AccessOperatable, Ownable {
    struct Campaign {
        uint8 purchaseType;
        uint8 subPurchaseType;
        uint8 proxyPurchaseType;
    }

    uint8 constant PURCHASE_NORMAL = 0;
    uint8 constant PURCHASE_ETH_BACK = 1;
    uint8 constant PURCHASE_UP20 = 2;
    uint8 constant PURCHASE_REGULAR = 3;
    uint8 constant PURCHASE_ETH_BACK_UP20 = 4;

    Campaign public campaign;

    mapping(uint256 => bool) public payableOptions;
    address public validater;

    address public currency;
    MCHLandPool public landPool;
    uint256 public landBasisPoint;

    uint256 constant BASE = 10000;
    uint256 private nonce;
    uint16 public chanceDenom;
    uint256 public ethBackBasisPoint;
    bytes private salt;
    mapping(bytes32 => uint256) public hashTransactedAt;

    event Sold(
        address indexed user,
        address indexed referrer,
        uint8 purchaseType,
        uint256 grossValue,
        uint256 referralValue,
        uint256 landValue,
        uint256 netValue,
        uint16 indexed landType
    );

    event CampaignUpdated(
        uint8 purchaseType,
        uint8 subPurchaseType,
        uint8 proxyPurchaseType
    );

    event LandBasisPointUpdated(
        uint256 landBasisPoint
    );

    constructor(
        address _validater,
        address payable _landPoolAddress,
        address _currency
    ) {
        setValidater(_validater);
        setLandPoolAddress(_landPoolAddress);
        setCurrency(_currency);
        setCampaign(0, 0, 0);
        updateLandBasisPoint(3000);
        updateEthBackBasisPoint(5000);
        updateChance(25);

        // Initial values don't have any particular significance
        salt = bytes("iiNg4uJulaa4Yoh7");
        nonce = 222;

        payableOptions[0.001 ether] = true;
        payableOptions[0.01 ether] = true;
        payableOptions[0.05 ether] = true;
        payableOptions[0.1 ether] = true;
        payableOptions[0.5 ether] = true;
        payableOptions[1 ether] = true;
        payableOptions[5 ether] = true;
        payableOptions[10 ether] = true;
    }

    function setValidater(address _validater) public onlyRole(OPERATOR) {
        validater = _validater;
    }

    function setPayableOption(uint256 _option, bool desired) external onlyRole(OPERATOR) {
        payableOptions[_option] = desired;
    }

    function setCampaign(
        uint8 _purchaseType,
        uint8 _subPurchaseType,
        uint8 _proxyPurchaseType
    )
        public
        onlyRole(OPERATOR)
    {
        campaign = Campaign(_purchaseType, _subPurchaseType, _proxyPurchaseType);
        emit CampaignUpdated(_purchaseType, _subPurchaseType, _proxyPurchaseType);
    }

    function setLandPoolAddress(address payable _landPoolAddress) public onlyOwner() {
        landPool = MCHLandPool(_landPoolAddress);
    }

    function setCurrency(address _currency) public onlyRole(OPERATOR) {
        currency = _currency;
    }

    function updateLandBasisPoint(uint256 _newLandBasisPoint) public onlyRole(OPERATOR) {
        landBasisPoint = _newLandBasisPoint;
        emit LandBasisPointUpdated(landBasisPoint);
    }

    function updateChance(uint16 _newchanceDenom) public onlyRole(OPERATOR) {
        chanceDenom = _newchanceDenom;
    }

    function updateEthBackBasisPoint(uint256 _ethBackBasisPoint) public onlyRole(OPERATOR) {
        ethBackBasisPoint = _ethBackBasisPoint;
    }

    function buy(
        uint256 purchaseAmount, // in wei
        address payable _user,
        address payable _referrer,
        uint256 _referralBasisPoint,
        uint16 _landType,
        bytes memory _signature,
        bytes32 _hash
    )
        public
        payable
        whenNotPaused()
    {
        require(_referralBasisPoint + ethBackBasisPoint + landBasisPoint <= BASE, "Invalid basis points");
        require(payableOptions[purchaseAmount], "Invalid purchase amount");
        require(validateSig(encodeData(_user, _referrer, _referralBasisPoint, _landType, block.chainid), _signature), "Invalid signature");
        if (_hash != bytes32(0)) {
            recordHash(_hash);
        }

        // Transfer Erc20 from purchaser to this contract
        require(
            IERC20(currency).allowance(msg.sender, address(this)) >= purchaseAmount,
            "must be approved"
        );
        IERC20(currency).transferFrom(msg.sender, address(this), purchaseAmount);

        uint8 purchaseType = campaign.proxyPurchaseType;
        uint256 netValue = purchaseAmount;
        uint256 referralValue = _referrerBack(purchaseAmount, _referrer, _referralBasisPoint);
        uint256 landValue = _landPoolBack(purchaseAmount, _landType);
        netValue = purchaseAmount - referralValue - landValue;

        emit Sold(
            _user,
            _referrer,
            purchaseType,
            purchaseAmount,
            referralValue,
            landValue,
            netValue,
            _landType
        );
    }

    function buyGUM(
        uint256 purchaseAmount, // in wei
        address payable _referrer,
        uint256 _referralBasisPoint,
        uint16 _landType,
        bytes memory _signature
    )
        public
        payable
    {
        require(_referralBasisPoint + ethBackBasisPoint + landBasisPoint <= BASE, "Invalid basis points");
        require(payableOptions[purchaseAmount], "Invalid purchase amount");
        require(validateSig(encodeData(msg.sender, _referrer, _referralBasisPoint, _landType, block.chainid), _signature), "Invalid signature");

        uint8 purchaseType = campaign.purchaseType;
        uint256 netValue = purchaseAmount;
        uint256 referralValue = 0;
        uint256 landValue = 0;

        // Transfer Erc20 from purchaser to this contract
        require(
            IERC20(currency).allowance(msg.sender, address(this)) >= purchaseAmount,
            "must be approved"
        );
        IERC20(currency).transferFrom(msg.sender, address(this), purchaseAmount);

        if (purchaseType == PURCHASE_ETH_BACK || purchaseType == PURCHASE_ETH_BACK_UP20) {
            if (getRandom(chanceDenom, nonce, msg.sender) == 0) {
                uint256 ethBackValue = _ethBack(purchaseAmount, ethBackBasisPoint);
                netValue = netValue - ethBackValue;
            } else {
                purchaseType = campaign.subPurchaseType;
                referralValue = _referrerBack(purchaseAmount, _referrer, _referralBasisPoint);
                landValue = _landPoolBack(purchaseAmount, _landType);
                netValue = purchaseAmount - referralValue - landValue;
            }
            nonce++;
        } else {
            referralValue = _referrerBack(purchaseAmount, _referrer, _referralBasisPoint);
            landValue = _landPoolBack(purchaseAmount, _landType);
            netValue = purchaseAmount - referralValue - landValue;
        }

        emit Sold(
            msg.sender,
            _referrer,
            purchaseType,
            purchaseAmount,
            referralValue,
            landValue,
            netValue,
            _landType
        );
    }

    function recordHash(bytes32 _hash) internal {
        require(hashTransactedAt[_hash] == 0, "The hash is already transacted");
        hashTransactedAt[_hash] = block.number;
    }

    function getRandom(uint16 max, uint256 _nonce, address _sender) public view returns (uint16) {
        return uint16(
            bytes2(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number-1),
                        _sender,
                        _nonce,
                        salt
                    )
                )
            )
        ) % max;
    }

    // Transfer ether back to buyer (Only used when hitting jackpot chance)
    function _ethBack(uint256 purchaseAmount, uint256 _ethBackBasisPoint) internal returns (uint256) {
        uint256 ethBackValue = purchaseAmount * _ethBackBasisPoint / BASE;
        IERC20(currency).transfer(msg.sender, ethBackValue);
        return ethBackValue;
    }

    // Transfer ether reward to land pool of land type
    function _landPoolBack(uint256 purchaseAmount, uint16 _landType) internal returns (uint256) {
        if(_landType == 0) {
            return 0;
        }
        // Check that land type is valid
        require(_landType >= 1 && _landType <= 9, "Invalid _landType");

        uint256 landValue;
        landValue = purchaseAmount * landBasisPoint / BASE;

        IERC20(currency).approve(address(landPool), landValue);
        landPool.addToLandPool(landValue, _landType, msg.sender);
        return landValue;
    }

    // Transfer ether reward to referrer of buyer
    function _referrerBack(uint256 purchaseAmount, address payable _referrer, uint256 _referralBasisPoint) internal returns (uint256) {
        if(_referrer == address(0x0) || _referrer == msg.sender) {
            return 0;
        }
        uint256 referralValue = purchaseAmount * _referralBasisPoint / BASE;
        IERC20(currency).transfer(_referrer, referralValue);
        return referralValue;
    }

    function encodeData(address _sender, address _referrer, uint256 _referralBasisPoint, uint16 _landType, uint256 _chainId) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _sender,
                _referrer,
                _referralBasisPoint,
                _landType,
                _chainId
            )
        );
    }

    function validateSig(bytes32 _message, bytes memory _signature) public view returns (bool) {
        require(validater != address(0), "validater must be set");
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return (signer == validater);
    }

    function recover(bytes32 _message, bytes memory _signature) public pure returns (address) {
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return signer;
    }

    function withdrawBalance() public onlyOwner() {
        uint256 balance = IERC20(currency).balanceOf(address(this));
        IERC20(currency).transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessOperatable is AccessControl {

    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    event Paused(address account);
    event Unpaused(address account);

    bool public _paused;

    constructor() {
        _setRoleAdmin(OPERATOR, OPERATOR);
        _setupRole(OPERATOR, msg.sender);
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyRole(OPERATOR) whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyRole(OPERATOR) whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

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
        mapping (address => bool) members;
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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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