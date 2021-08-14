/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/IDeTrust.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IDeTrust {

    struct Trust {
        uint id;  // the id of the trust
        string name;  // the name of the trust, like 'trust for Bob's son'
        address settlor;  // the settlor of the trust
        address beneficiary;  // the beneficiary of the trust, such as Bob's son
        uint nextReleaseTime;  // when would the money begin to release to beneficiary
        uint timeInterval;  // how often the money is going to release to beneficiary
        uint amountPerTimeInterval;  // how much can a beneficiary to get the money
        uint totalAmount;  // total money in this trust
        bool revocable;  // is this trust revocable or irrevocable
    }

    /*
     * Event that a new trust is added
     *
     * @param name the name of the trust
     * @param settlor the settlor address of the trust
     * @param beneficiary the beneficiary address of the trust
     * @param trustId the trustId of the trust
     * @param startReleaseTime will this trust start to release money, UTC in seconds
     * @param timeInterval how often can a beneficiary to get the money in seconds
     * @param amountPerTimeInterval how much can a beneficiary to get the money
     * @param totalAmount how much money are put in the trust
     * @param revocable whether this trust is revocalbe
     */
    event TrustAdded(
        string name,
        address indexed settlor,
        address indexed beneficiary,
        uint indexed trustId,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    );

    /*
     * Event that new fund are added into a existing trust
     *
     * @param trustId the trustId of the trust
     * @param amount how much money are added into the trust
     */
    event TrustFundAdded(uint indexed trustId, uint amount);

    /*
     * Event that a trust is finished
     *
     * @param trustId the trustId of the trust
     */
    event TrustFinished(uint indexed trustId);

    /*
     * Event that a trust is releaseed
     *
     * @param trustId the trustId of the trust
     */
    event TrustReleased(
        uint indexed trustId,
        address indexed beneficiary,
        uint amount,
        uint nextReleaseTime
    );

    /*
     * Event that a trust is revoked
     *
     * @param trustId the trustId of the trust
     */
    event TrustRevoked(uint indexed trustId);

    /*
     * Event that beneficiary get some money from the contract
     *
     * @param beneficiary the address of beneficiary
     * @param totalAmount how much the beneficiary released from this contract
     */
    event Release(address indexed beneficiary, uint totalAmount);

    /*
     * Get the balance in this contract, which is not send to any trust
     * @return the balance of the settlor in this contract
     *
     */
    function getBalance(address account) external view returns (uint balance);

    /*
     * If money is send to this contract by accident, can use this
     * function to get money back ASAP.
     *
     * @param to the address money would send to
     * @param amount how much money are added into the trust
     */
    function sendBalanceTo(address to, uint amount) external;

    /*
     * Get beneficiary's all trusts
     *
     * @return array of trusts which's beneficiary is the tx.orgigin
     */
    function getTrustListAsBeneficiary(address account)
        external
        view
        returns(Trust[] memory);


    /*
     * Get settlor's all trusts
     *
     * @return array of trusts which's settlor is the tx.orgigin
     */
    function getTrustListAsSettlor(address account)
        external
        view
        returns(Trust[] memory);

    /*
     * Add a new trust from settlor's balance in this contract.
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param totalAmount how much money is added to the trust
     * @param revocable whether this trust is revocable
     */
    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        returns (uint trustId);

    /*
     * Add a new trust by pay
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param revocable whether this trust is revocalbe
     */
    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        returns (uint trustId);

    /*
     * Set trust to irrevocable
     *
     * @param trustId the trustId settlor want to set irrevocable
     */
    function setIrrevocable(uint trustId) external;

    /*
     * Revoke a trust, withdraw all the money out
     *
     * @param trustId the trustId settlor want to top up
     */
    function revoke(uint trustId) external;

    /*
     * Top up a trust by payment
     * @param trustId the trustId settlor want to top up
     */
    function topUp(uint trustId) external payable;

    /*
     * Top up from balance to a trust by trustId
     *
     * @param trustId the trustId settlor want add to top up
     * @param amount the amount of money settlor want to top up
     */
    function topUpFromBalance(uint trustId, uint amount) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     *
     */
    function release(uint trustId) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     * @param to the address beneficiary want to release to
     *
     */
    function releaseTo(uint trustId, address to) external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     */
    function releaseAll() external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     *
     * @param to the address beneficiary want to release to
     */
    function releaseAllTo(address to) external;

}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File contracts/DeTrust.sol

pragma solidity 0.8.0;
contract DeTrust is IDeTrust, Initializable {

    uint private trustId;

    /*
      Paid directly would be here.
    */
    mapping(address => uint) private settlorBalance;

    mapping(uint => Trust) private trusts;

    mapping(address => uint[]) private settlorToTrustIds;

    mapping(address => uint[]) private beneficiaryToTrustIds;


    uint private unlocked;

    modifier lock() {
        require(unlocked == 1, 'Trust: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * constructor replaced by initialize with timelock upgrade
     */
    function initialize() external initializer {
        unlocked = 1;
    }

    /**
     * If ppl send the ether to this contract directly
     */
    receive() external payable {
        require(msg.value > 0, "msg.value is 0");
        settlorBalance[msg.sender] += msg.value;
    }

    function getBalance(address account)
        external
        view
        override
        returns (uint balance)
    {
        return settlorBalance[account];
    }

    function sendBalanceTo(address to, uint amount) external override {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        require(payable(to).send(amount), "send balance failed");
    }

    function getTrustListAsBeneficiary(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = beneficiaryToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsBeneficiary = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsBeneficiary[i] = t;
        }
        return trustsAsBeneficiary;
    }

    function getTrustListAsSettlor(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = settlorToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsSettlor = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsSettlor[i] = t;
        }
        return trustsAsSettlor;
    }

    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        override
        lock
        returns (uint tId)
    {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= totalAmount, "balance insufficient");

        settlorBalance[settlor] -= totalAmount;

        return _addTrust(
            name,
            beneficiary,
            settlor,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        override
        lock returns (uint tId)
    {
        uint totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");

        return _addTrust(
            name,
            beneficiary,
            msg.sender,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function setIrrevocable(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        if (!t.revocable) {
            return;
        }
        t.revocable = false;
    }

    function revoke(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        require(t.revocable, "trust irrevocable");
        _deleteTrust(tId, t.beneficiary, t.settlor);

        require(payable(msg.sender).send(totalAmount), "revoke failed");
        emit TrustRevoked(tId);
    }

    function topUp(uint tId) external payable override lock {
        uint amount = msg.value;
        require(amount > 0, "msg.value is 0");
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function topUpFromBalance(uint tId, uint amount) external override lock {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function release(uint tId) external override lock {
        address beneficiary = msg.sender;
        _release(tId, beneficiary, beneficiary);
    }

    function releaseTo(uint tId, address to) external override lock {
        _release(tId, msg.sender, to);
    }

    function releaseAll() external override lock {
        address beneficiary = msg.sender;
        _releaseAll(beneficiary, beneficiary);
    }

    function releaseAllTo(address to) external override lock {
        _releaseAll(msg.sender, to);
    }

    // internal functions

    function _release(uint tId, address beneficiary, address to) internal {
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        require(t.beneficiary == beneficiary, "beneficiary error");
        uint releaseAmount = _releaseTrust(t);
        if (releaseAmount == 0) {
            revert("nothing to release");
        }
        bool isDeleted = (t.totalAmount == 0);
        if (isDeleted) {
            _deleteTrust(tId, t.beneficiary, t.settlor);
            emit TrustFinished(tId);
        }
        require(payable(to).send(releaseAmount), "release failed");
        emit Release(beneficiary, releaseAmount);
    }

    function _releaseAll(address beneficiary, address to) internal {
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        require(trustIds.length > 0, "nothing to release");
        uint i;
        uint j;
        uint totalReleaseAmount;
        uint tId;
        bool isDeleted;
        uint length = trustIds.length;
        for (i = 0; i < length && trustIds.length > 0; i++) {
            tId = trustIds[j];
            Trust storage t = trusts[tId];
            uint releaseAmount = _releaseTrust(t);
            if (releaseAmount != 0) {
                totalReleaseAmount += releaseAmount;
            }
            isDeleted = (t.totalAmount == 0);
            if (isDeleted) {
                _deleteTrust(tId, t.beneficiary, t.settlor);
                emit TrustFinished(tId);
            } else {
                j++;
            }
        }
        if (totalReleaseAmount == 0) {
            revert("nothing to release");
        }

        require(payable(to).send(totalReleaseAmount), "release failed");
        emit Release(beneficiary, totalReleaseAmount);
    }

    function _deleteTrust(uint tId, address beneficiary, address settlor) internal {
        delete trusts[tId];
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        if (trustIds.length == 1) {
            trustIds.pop();
        } else {
            uint i;
            for (i = 0; i < trustIds.length; i++) {
                if (trustIds[i] == tId) {
                    if (i != trustIds.length - 1) {
                        trustIds[i] = trustIds[trustIds.length - 1];
                    }
                    trustIds.pop();
                }
            }
        }
        uint[] storage settlorTIds = settlorToTrustIds[settlor];
        if (settlorTIds.length == 1) {
            settlorTIds.pop();
            return;
        }
        uint k;
        for (k = 0; k < settlorTIds.length; k++) {
            if (settlorTIds[k] == tId) {
                if (k != settlorTIds.length - 1) {
                    settlorTIds[k] = settlorTIds[settlorTIds.length - 1];
                }
                settlorTIds.pop();
            }
        }
    }

    function _addTrust(
        string memory name,
        address beneficiary,
        address settlor,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        internal
        returns (uint _id)
    {
        require(timeInterval != 0, "timeInterval should be positive");
        _id = ++trustId;
        trusts[_id].id = _id;
        trusts[_id].name = name;
        trusts[_id].settlor = settlor;
        trusts[_id].beneficiary = beneficiary;
        trusts[_id].nextReleaseTime = startReleaseTime;
        trusts[_id].timeInterval = timeInterval;
        trusts[_id].amountPerTimeInterval = amountPerTimeInterval;
        trusts[_id].totalAmount = totalAmount;
        trusts[_id].revocable = revocable;

        settlorToTrustIds[settlor].push(_id);
        beneficiaryToTrustIds[beneficiary].push(_id);

        emit TrustAdded(
            name,
            settlor,
            beneficiary,
            _id,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );

        return _id;
    }

    function _releaseTrust(Trust storage t) internal returns (uint) {
        uint nowTimestamp = block.timestamp;
        if (t.nextReleaseTime > nowTimestamp) {
            return 0;
        }
        uint distributionAmount = (nowTimestamp - t.nextReleaseTime) / t.timeInterval + 1;
        uint releaseAmount = distributionAmount * t.amountPerTimeInterval;
        if (releaseAmount >= t.totalAmount) {
            releaseAmount = t.totalAmount;
            t.totalAmount = 0;
        } else {
            t.totalAmount -= releaseAmount;
            t.nextReleaseTime += distributionAmount * t.timeInterval;
        }
        emit TrustReleased(t.id, t.beneficiary, releaseAmount, t.nextReleaseTime);
        return releaseAmount;
    }

}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;



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


// File contracts/TimelockController.sol


pragma solidity 0.8.0;
/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay);

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        // solhint-disable-next-line not-rely-on-time
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        // solhint-disable-next-line not-rely-on-time
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 predecessor) private view {
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(bytes32 id, uint256 index, address target, uint256 value, bytes calldata data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}