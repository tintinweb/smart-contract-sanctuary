// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../reputation/IReputation.sol";
import "../pawn-p2p/IPawn.sol";
import "../pawn-p2p-v2/ILoan.sol";
import "../pawn-p2p-v2/PawnLib.sol";
import "../pawn-nft/IPawnNFT.sol";

contract UserReview is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    IReputation public reputation;

    address public pawnContract;
    address public loanContract;

    // mapping from reviewer address to pawn or loan contract address => contractId
    mapping(address => mapping(bytes32 => bool))
        public _listOfContractReviewedByUser;

    mapping(address => mapping(bytes32 => Review)) public _listOfReviewByUser;

    mapping(uint8 => IReputation.ReasonType) public _lenderReviewedByBorrower;
    mapping(uint8 => IReputation.ReasonType) public _borrowerReviewedByLender;

    address public pawnNFTContract;

    struct Review {
        address reviewee;
        uint256 contractId;
        uint256 points;
        address contractOrigin;
    }

    event UserReviewSubmitted(
        address reviewer,
        address reviewee,
        uint256 points,
        uint256 contractId,
        address contractOrigin,
        IReputation.ReasonType reason
    );

    /** ==================== Initialization ==================== */

    /**
     * @dev initialize function
     */
    function initialize(
        address _pawnContractAddress,
        address _loanContractAddress,
        address _pawnNFTContractAddress,
        address _reputationContractAddress
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        pawnContract = _pawnContractAddress;
        loanContract = _loanContractAddress;
        pawnNFTContract = _pawnNFTContractAddress;
        reputation = IReputation(_reputationContractAddress);

        _initializePointToRewardReason();
    }

    function setReputationContract(address _reputationContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        reputation = IReputation(_reputationContractAddress);
    }

    function setPawnContract(address _pawnContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnContract = _pawnContractAddress;
    }

    function setLoanContract(address _loanContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        loanContract = _loanContractAddress;
    }

    function setPawnNFTContract(address _pawnNFTContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnNFTContract = _pawnNFTContractAddress;
    }

    function initializePointToRewardReason()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _initializePointToRewardReason();
    }

    function _initializePointToRewardReason() internal virtual {
        _lenderReviewedByBorrower[1] = IReputation
            .ReasonType
            .LD_REVIEWED_BY_BORROWER_1;
        _lenderReviewedByBorrower[2] = IReputation
            .ReasonType
            .LD_REVIEWED_BY_BORROWER_2;
        _lenderReviewedByBorrower[3] = IReputation
            .ReasonType
            .LD_REVIEWED_BY_BORROWER_3;
        _lenderReviewedByBorrower[4] = IReputation
            .ReasonType
            .LD_REVIEWED_BY_BORROWER_4;
        _lenderReviewedByBorrower[5] = IReputation
            .ReasonType
            .LD_REVIEWED_BY_BORROWER_5;

        _borrowerReviewedByLender[1] = IReputation
            .ReasonType
            .BR_REVIEWED_BY_LENDER_1;
        _borrowerReviewedByLender[2] = IReputation
            .ReasonType
            .BR_REVIEWED_BY_LENDER_2;
        _borrowerReviewedByLender[3] = IReputation
            .ReasonType
            .BR_REVIEWED_BY_LENDER_3;
        _borrowerReviewedByLender[4] = IReputation
            .ReasonType
            .BR_REVIEWED_BY_LENDER_4;
        _borrowerReviewedByLender[5] = IReputation
            .ReasonType
            .BR_REVIEWED_BY_LENDER_5;
    }

    /** ==================== User-reviews function implementations ==================== */

    function submitUserReviewCryptoContract(
        uint8 _points,
        uint256 _contractId,
        address _contractAddress
    ) external {
        require(
            _contractAddress == pawnContract ||
                _contractAddress == loanContract,
            "DFY: Invalid pawn or loan contract"
        ); // invalid pawn or loan contract

        address borrower;
        address lender;
        ContractStatus status;

        // Get contract data for review
        if (_contractAddress == pawnContract) {
            (borrower, lender, status) = IPawn(pawnContract)
                .getContractInfoForReview(_contractId);
        } else if (_contractAddress == loanContract) {
            (borrower, lender, status) = ILoan(loanContract)
                .getContractInfoForReview(_contractId);
        }

        // Check contract status, must be Completed or Default
        require(
            (status == ContractStatus.COMPLETED ||
                status == ContractStatus.DEFAULT),
            "DFY: Crypto loan contract is active"
        ); // Loan contract must not active

        _submitUserReview(
            borrower,
            lender,
            _contractId,
            _contractAddress,
            _points
        );
    }

    function submitUserReviewNFTContract(
        uint8 _points,
        uint256 _contractId,
        address _contractAddress
    ) external {
        require(
            _contractAddress == pawnNFTContract,
            "DFY: Invalid pawn or loan contract"
        ); // invalid Pawn NFT contract

        (
            address borrower,
            address lender,
            IPawnNFT.ContractStatus status
        ) = IPawnNFT(pawnNFTContract).getContractInfoForReview(_contractId);

        // Check contract status, must be Completed or Default
        require(
            (status == IPawnNFT.ContractStatus.COMPLETED ||
                status == IPawnNFT.ContractStatus.DEFAULT),
            "DFY: NFT loan contract is active"
        ); // Loan contract must not active

        _submitUserReview(
            borrower,
            lender,
            _contractId,
            _contractAddress,
            _points
        );
    }

    function _submitUserReview(
        address _borrower,
        address _lender,
        uint256 _contractId,
        address _contractOrigin,
        uint8 _points
    ) internal {
        // Determine reviewer, reviewee, and reward reason
        address reviewer;
        address reviewee;
        IReputation.ReasonType rewardReason;
        if (msg.sender == _borrower) {
            reviewer = _borrower;
            reviewee = _lender;
            rewardReason = IReputation.ReasonType(
                _lenderReviewedByBorrower[_points]
            );
        } else if (msg.sender == _lender) {
            reviewer = _lender;
            reviewee = _borrower;
            rewardReason = IReputation.ReasonType(
                _borrowerReviewedByLender[_points]
            );
        }

        // Check for invalid reviewer
        require(reviewer != address(0), "DFY: Reviewer is not defined"); // Reviewer is undefined

        // Check if contract has been reviewed by reviewer
        bytes32 key = keccak256(abi.encodePacked(_contractOrigin, _contractId));
        require(
            _listOfContractReviewedByUser[reviewer][key] == false,
            "DFY: Contract must not be reviewed by this user"
        ); // Contract must not be reviewed by this user before

        // Store review information
        _listOfReviewByUser[reviewer][key] = Review(
            reviewee,
            _contractId,
            _points,
            _contractOrigin
        );
        _listOfContractReviewedByUser[reviewer][key] = true;

        // Adjust reputation point of reviewee
        reputation.adjustReputationScore(reviewee, rewardReason);

        emit UserReviewSubmitted(
            reviewer,
            reviewee,
            _points,
            _contractId,
            _contractOrigin,
            rewardReason
        );
    }

    function getReviewKey(uint256 _contractId, address _contractAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_contractAddress, _contractId));
    }

    function getContractReviewStatusByUser(
        address _user,
        uint256 _contractId,
        address _contractAddress
    ) external view returns (bool) {
        bytes32 key = keccak256(
            abi.encodePacked(_contractAddress, _contractId)
        );
        address sender = _user != address(0) ? _user : _msgSender();

        return _listOfContractReviewedByUser[sender][key];
    }

    function getContractReviewInfoByUser(
        address _user,
        uint256 _contractId,
        address _contractAddress
    ) external view returns (Review memory) {
        bytes32 key = keccak256(
            abi.encodePacked(_contractAddress, _contractId)
        );
        address sender = _user != address(0) ? _user : _msgSender();

        return _listOfReviewByUser[sender][key];
    }

    /** ==================== Standard interface function implementations ==================== */

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
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

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.4;

interface IReputation {
    
    // Reason for Reputation point adjustment
    /**
    * @dev Reputation points in correspondence with ReasonType 
    * LD_CREATE_PACKAGE         : +3    (0)
    * LD_CANCEL_PACKAGE         : -3    (1)
    * LD_REOPEN_PACKAGE         : +3    (2)
    * LD_GENERATE_CONTRACT      : +1    (3)
    * LD_CREATE_OFFER           : +2    (4)
    * LD_CANCEL_OFFER           : -2    (5)
    * LD_ACCEPT_OFFER           : +1    (6)
    * BR_CREATE_COLLATERAL      : +3    (7)
    * BR_CANCEL_COLLATERAL      : -3    (8)
    * BR_ONTIME_PAYMENT         : +1    (9)
    * BR_LATE_PAYMENT           : -1    (10)
    * BR_ACCEPT_OFFER           : +1    (11)
    * BR_CONTRACT_COMPLETE      : +5    (12)
    * BR_CONTRACT_DEFAULTED     : -5    (13)
    * LD_REVIEWED_BY_BORROWER_1 : +1    (14)
    * LD_REVIEWED_BY_BORROWER_2 : +2    (15)
    * LD_REVIEWED_BY_BORROWER_3 : +3    (16)
    * LD_REVIEWED_BY_BORROWER_4 : +4    (17)
    * LD_REVIEWED_BY_BORROWER_5 : +5    (18)
    * LD_KYC                    : +5    (19)
    * BR_REVIEWED_BY_LENDER_1   : +1    (20)
    * BR_REVIEWED_BY_LENDER_2   : +2    (21)
    * BR_REVIEWED_BY_LENDER_3   : +3    (22)
    * BR_REVIEWED_BY_LENDER_4   : +4    (23)
    * BR_REVIEWED_BY_LENDER_5   : +5    (24)
    * BR_KYC                    : +5    (25)
    */
    
    enum ReasonType {
        LD_CREATE_PACKAGE, 
        LD_CANCEL_PACKAGE,
        LD_REOPEN_PACKAGE,
        LD_GENERATE_CONTRACT,
        LD_CREATE_OFFER,
        LD_CANCEL_OFFER,
        LD_ACCEPT_OFFER,
        BR_CREATE_COLLATERAL,
        BR_CANCEL_COLLATERAL,
        BR_ONTIME_PAYMENT,
        BR_LATE_PAYMENT,
        BR_ACCEPT_OFFER,
        BR_CONTRACT_COMPLETE,
        BR_CONTRACT_DEFAULTED,
        
        LD_REVIEWED_BY_BORROWER_1,
        LD_REVIEWED_BY_BORROWER_2,
        LD_REVIEWED_BY_BORROWER_3,
        LD_REVIEWED_BY_BORROWER_4,
        LD_REVIEWED_BY_BORROWER_5,
        LD_KYC,

        BR_REVIEWED_BY_LENDER_1,
        BR_REVIEWED_BY_LENDER_2,
        BR_REVIEWED_BY_LENDER_3,
        BR_REVIEWED_BY_LENDER_4,
        BR_REVIEWED_BY_LENDER_5,
        BR_KYC
    }
    
    /**
    * @dev Get the reputation score of an account
    */
    function getReputationScore(address _address) external view returns(uint32);

    function adjustReputationScore(address _user, ReasonType _reasonType) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../pawn-p2p-v2/PawnLib.sol";

interface IPawn {
    /** General functions */

    function emergencyWithdraw(address _token) external;

    function updateCollateralStatus(
        uint256 _collateralId,
        CollateralStatus _status
    ) external;

    function updateCollateralAmount(uint256 _collateralId, uint256 _amount)
        external;

    function getContractInfoForReview(uint256 _contractId) 
        external
        view
        returns (
            address borrower,
            address lender,
            ContractStatus status
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IPawn.sol";

interface ILoan is IPawnV2 {
    function createContract(ContractRawData memory _contractData)
        external
        returns (uint256 _idx);

    function closePaymentRequestAndStartNew(
        int256 _paymentRequestId,
        uint256 _contractId,
        PaymentRequestTypeEnum _paymentRequestType
    ) external;

    function checkLenderAccount(
        address collateralAddress,
        uint256 amount,
        uint256 loanToValue,
        address loanToken,
        address repaymentAsset,
        address owner,
        address spender
    ) external view returns (bool sufficientBalance, bool overAllowance);

    function getContractInfoForReview(uint256 _contractId) 
        external
        view
        returns (
            address borrower,
            address lender,
            ContractStatus status
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "./IPawn.sol";

enum LoanDurationType {
    WEEK,
    MONTH
}
enum CollateralStatus {
    OPEN,
    DOING,
    COMPLETED,
    CANCEL
}
struct Collateral {
    address owner;
    uint256 amount;
    address collateralAddress;
    address loanAsset;
    uint256 expectedDurationQty;
    LoanDurationType expectedDurationType;
    CollateralStatus status;
}

enum OfferStatus {
    PENDING,
    ACCEPTED,
    COMPLETED,
    CANCEL
}
struct CollateralOfferList {
    mapping(uint256 => Offer) offerMapping;
    uint256[] offerIdList;
    bool isInit;
}

struct Offer {
    address owner;
    address repaymentAsset;
    uint256 loanAmount;
    uint256 interest;
    uint256 duration;
    OfferStatus status;
    LoanDurationType loanDurationType;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    bool isInit;
}

enum PawnShopPackageStatus {
    ACTIVE,
    INACTIVE
}
enum PawnShopPackageType {
    AUTO,
    SEMI_AUTO
}
struct Range {
    uint256 lowerBound;
    uint256 upperBound;
}

struct PawnShopPackage {
    address owner;
    PawnShopPackageStatus status;
    PawnShopPackageType packageType;
    address loanToken;
    Range loanAmountRange;
    address[] collateralAcceptance;
    uint256 interest;
    uint256 durationType;
    Range durationRange;
    address repaymentAsset;
    LoanDurationType repaymentCycleType;
    uint256 loanToValue;
    uint256 loanToValueLiquidationThreshold;
}

enum LoanRequestStatus {
    PENDING,
    ACCEPTED,
    REJECTED,
    CONTRACTED,
    CANCEL
}
struct LoanRequestStatusStruct {
    bool isInit;
    LoanRequestStatus status;
}
struct CollateralAsLoanRequestListStruct {
    mapping(uint256 => LoanRequestStatusStruct) loanRequestToPawnShopPackageMapping; // Mapping from package to status
    uint256[] pawnShopPackageIdList;
    bool isInit;
}

enum ContractStatus {
    ACTIVE,
    COMPLETED,
    DEFAULT
}
struct ContractTerms {
    address borrower;
    address lender;
    address collateralAsset;
    uint256 collateralAmount;
    address loanAsset;
    uint256 loanAmount;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 contractStartDate;
    uint256 contractEndDate;
    uint256 lateThreshold;
    uint256 systemFeeRate;
    uint256 penaltyRate;
    uint256 prepaidFeeRate;
}
struct Contract {
    uint256 collateralId;
    int256 offerId;
    int256 pawnShopPackageId;
    ContractTerms terms;
    ContractStatus status;
    uint8 lateCount;
}

enum PaymentRequestStatusEnum {
    ACTIVE,
    LATE,
    COMPLETE,
    DEFAULT
}
enum PaymentRequestTypeEnum {
    INTEREST,
    OVERDUE,
    LOAN
}
struct PaymentRequest {
    uint256 requestId;
    PaymentRequestTypeEnum paymentRequestType;
    uint256 remainingLoan;
    uint256 penalty;
    uint256 interest;
    uint256 remainingPenalty;
    uint256 remainingInterest;
    uint256 dueDateTimestamp;
    bool chargePrepaidFee;
    PaymentRequestStatusEnum status;
}

enum ContractLiquidedReasonType {
    LATE,
    RISK,
    UNPAID
}

struct ContractRawData {
    uint256 collateralId;
    address borrower;
    address loanAsset;
    address collateralAsset;
    uint256 collateralAmount;
    int256 packageId;
    int256 offerId;
    uint256 exchangeRate;
    uint256 loanAmount;
    address lender;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 loanDurationQty;
}

struct ContractLiquidationData {
    uint256 contractId;
    uint256 liquidAmount;
    uint256 systemFeeAmount;
    uint256 collateralExchangeRate;
    uint256 loanExchangeRate;
    uint256 repaymentExchangeRate;
    uint256 rateUpdateTime;
    ContractLiquidedReasonType reasonType;
}

library PawnLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "0"); // balance
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "1"); //fail-trans-bnb
            } else {
                // Send from other address to another address
                require(false, "2"); //not-allow-transfer
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(
                IERC20Upgradeable(asset).balanceOf(from) >= amount,
                "3" //not-enough-balance
            );
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(
                    IERC20Upgradeable(asset).allowance(from, address(this)) >=
                        amount,
                    "4" //not-allowance
                );
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(
                IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance,
                "5" //not-trans-enough
            );
        }
    }

    function calculateAmount(address _token, address from)
        internal
        view
        returns (uint256 _amount)
    {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }

    function calculateContractDuration(
        LoanDurationType durationType,
        uint256 duration
    ) internal pure returns (uint256 inSeconds) {
        if (durationType == LoanDurationType.WEEK) {
            inSeconds = 7 * 24 * 3600 * duration;
        } else {
            inSeconds = 30 * 24 * 3600 * duration;
        }
    }

    function isPrepaidChargeRequired(
        LoanDurationType durationType,
        uint256 startDate,
        uint256 endDate
    ) internal pure returns (bool) {
        // uint256 week = 600; // define week duration
        // uint256 month = 900; // define month duration
        uint256 week = 7 * 24 * 3600;
        uint256 month = 30 * 24 * 3600;

        if (durationType == LoanDurationType.WEEK) {
            // if loan contract only lasts one week
            if ((endDate - startDate) <= week) {
                return false;
            } else {
                return true;
            }
        } else {
            // if loan contract only lasts one month
            if ((endDate - startDate) <= month) {
                return false;
            } else {
                return true;
            }
        }
    }

    function calculatedueDateTimestampInterest(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            duedateTimestampInterest = 3 * 24 * 3600;
            // duedateTimestampInterest = 180; // test
        } else {
            duedateTimestampInterest = 7 * 24 * 3600;
            // duedateTimestampInterest = 300; // test
        }
    }

    function calculatedueDateTimestampPenalty(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            duedateTimestampInterest = (7 - 3) * 24 * 3600;
            // duedateTimestampInterest = 600 - 180; // test
        } else {
            duedateTimestampInterest = (30 - 7) * 24 * 3600;
            // duedateTimestampInterest = 900 - 300; // test
        }
    }

    function checkLenderAccount(
        uint256 loanAmount,
        address loanToken,
        address owner,
        address spender
    ) internal view {
        // Check if lender has enough balance and allowance for lending
        uint256 lenderCurrentBalance = IERC20Upgradeable(loanToken).balanceOf(
            owner
        );
        require(lenderCurrentBalance >= loanAmount, "4"); // insufficient balance

        uint256 lenderCurrentAllowance = IERC20Upgradeable(loanToken).allowance(
            owner,
            spender
        );
        require(lenderCurrentAllowance >= loanAmount, "5"); // allowance not enough
    }

    /**
     * @dev Return the absolute value of a signed integer
     * @param _input is any signed integer
     * @return an unsigned integer that is the absolute value of _input
     */
    function abs(int256 _input) internal pure returns (uint256) {
        return _input >= 0 ? uint256(_input) : uint256(_input * -1);
    }
}

library CollateralLib {
    function create(
        Collateral storage self,
        address _collateralAddress,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) internal {
        self.owner = msg.sender;
        self.amount = _amount;
        self.collateralAddress = _collateralAddress;
        self.loanAsset = _loanAsset;
        self.status = CollateralStatus.OPEN;
        self.expectedDurationQty = _expectedDurationQty;
        self.expectedDurationType = _expectedDurationType;
    }

    function submitToLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        if (!_loanRequestListStruct.isInit) {
            _loanRequestListStruct.isInit = true;
        }

        LoanRequestStatusStruct storage statusStruct = _loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == false);
        statusStruct.isInit = true;
        statusStruct.status = LoanRequestStatus.PENDING;

        _loanRequestListStruct.pawnShopPackageIdList.push(_packageId);
    }

    function removeFromLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        delete _loanRequestListStruct.loanRequestToPawnShopPackageMapping[
            _packageId
        ];

        uint256 lastIndex = _loanRequestListStruct
            .pawnShopPackageIdList
            .length - 1;

        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_loanRequestListStruct.pawnShopPackageIdList[i] == _packageId) {
                _loanRequestListStruct.pawnShopPackageIdList[
                        i
                    ] = _loanRequestListStruct.pawnShopPackageIdList[lastIndex];
                break;
            }
        }
    }

    function checkCondition(
        Collateral storage self,
        uint256 _packageId,
        PawnShopPackage storage _pawnShopPackage,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct,
        CollateralStatus _requiredCollateralStatus,
        LoanRequestStatus _requiredLoanRequestStatus
    ) internal view returns (LoanRequestStatusStruct storage _statusStruct) {
        // Check for owner of packageId
        // _pawnShopPackage = pawnShopPackages[_packageId];
        require(_pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, "0"); // pack

        // Check for collateral status is open
        // _collateral = collaterals[_collateralId];
        require(self.status == _requiredCollateralStatus, "1"); // col

        // Check for collateral-package status is PENDING (waiting for accept)
        // _loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(_loanRequestListStruct.isInit == true, "2"); // col-loan-req
        _statusStruct = _loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(_statusStruct.isInit == true, "3"); // col-loan-req-pack
        require(_statusStruct.status == _requiredLoanRequestStatus, "4"); // stt
    }
}

library OfferLib {
    function create(
        Offer storage self,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint8 _loanDurationType,
        uint8 _repaymentCycleType,
        uint256 _liquidityThreshold
    ) internal {
        self.isInit = true;
        self.owner = msg.sender;
        self.loanAmount = _loanAmount;
        self.interest = _interest;
        self.duration = _duration;
        self.loanDurationType = LoanDurationType(_loanDurationType);
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = LoanDurationType(_repaymentCycleType);
        self.liquidityThreshold = _liquidityThreshold;
        self.status = OfferStatus.PENDING;
    }

    function cancel(
        Offer storage self,
        uint256 _id,
        address _collateralOwner,
        CollateralOfferList storage _collateralOfferList
    ) internal {
        require(self.isInit == true, "1"); // offer-col
        require(
            self.owner == msg.sender || _collateralOwner == msg.sender,
            "2"
        ); // owner
        require(self.status == OfferStatus.PENDING, "3"); // offer

        delete _collateralOfferList.offerMapping[_id];
        uint256 lastIndex = _collateralOfferList.offerIdList.length - 1;
        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_collateralOfferList.offerIdList[i] == _id) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList
                    .offerIdList[lastIndex];
                break;
            }
        }

        delete _collateralOfferList.offerIdList[lastIndex];
    }
}

library PawnPackageLib {
    function create(
        PawnShopPackage storage self,
        PawnShopPackageType _packageType,
        address _loanToken,
        Range calldata _loanAmountRange,
        address[] calldata _collateralAcceptance,
        uint256 _interest,
        uint256 _durationType,
        Range calldata _durationRange,
        address _repaymentAsset,
        LoanDurationType _repaymentCycleType,
        uint256 _loanToValue,
        uint256 _loanToValueLiquidationThreshold
    ) internal {
        self.owner = msg.sender;
        self.status = PawnShopPackageStatus.ACTIVE;
        self.packageType = _packageType;
        self.loanToken = _loanToken;
        self.loanAmountRange = _loanAmountRange;
        self.collateralAcceptance = _collateralAcceptance;
        self.interest = _interest;
        self.durationType = _durationType;
        self.durationRange = _durationRange;
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = _repaymentCycleType;
        self.loanToValue = _loanToValue;
        self.loanToValueLiquidationThreshold = _loanToValueLiquidationThreshold;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPawnNFT {
    /** ========================= Collateral ============================= */

    // Enum
    enum LoanDurationType {
        WEEK,
        MONTH
    }
    enum CollateralStatus {
        OPEN,
        DOING,
        COMPLETED,
        CANCEL
    }
    enum OfferStatus {
        PENDING,
        ACCEPTED,
        COMPLETED,
        CANCEL
    }
    enum ContractStatus {
        ACTIVE,
        COMPLETED,
        DEFAULT
    }
    enum PaymentRequestStatusEnum {
        ACTIVE,
        LATE,
        COMPLETE,
        DEFAULT
    }
    enum PaymentRequestTypeEnum {
        INTEREST,
        OVERDUE,
        LOAN
    }
    enum ContractLiquidedReasonType {
        LATE,
        RISK,
        UNPAID
    }

    struct Collateral {
        address owner;
        address nftContract;
        uint256 nftTokenId;
        uint256 loanAmount;
        address loanAsset;
        uint256 nftTokenQuantity;
        uint256 expectedDurationQty;
        LoanDurationType durationType;
        CollateralStatus status;
    }

    /**
     * @dev create collateral function, collateral will be stored in this contract
     * @param _nftContract is address NFT token collection
     * @param _nftTokenId is token id of NFT
     * @param _loanAmount is amount collateral
     * @param _loanAsset is address of loan token
     * @param _nftTokenQuantity is quantity NFT token
     * @param _expectedDurationQty is expected duration
     * @param _durationType is expected duration type
     * @param _UID is UID pass create collateral to event collateral
     */
    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType _durationType,
        uint256 _UID
    ) external;

    /**
     * @dev withdrawCollateral function, collateral will be delete stored in contract
     * @param _nftCollateralId is id of collateral
     */
    function withdrawCollateral(uint256 _nftCollateralId, uint256 _UID)
        external;

    /** ========================= OFFER ============================= */

    struct CollateralOfferList {
        //offerId => Offer
        mapping(uint256 => Offer) offerMapping;
        uint256[] offerIdList;
        bool isInit;
    }

    struct Offer {
        address owner;
        address repaymentAsset;
        uint256 loanToValue;
        uint256 loanAmount;
        uint256 interest;
        uint256 duration;
        OfferStatus status;
        LoanDurationType loanDurationType;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
    }

    /**
     * @dev create offer to collateral
     * @param _nftCollateralId is id collateral
     * @param _repaymentAsset is address token repayment
     * @param _loanToValue is LTV token of loan
     * @param _loanAmount is amount token of loan
     * @param _interest is interest of loan
     * @param _duration is duration of loan
     * @param _liquidityThreshold is liquidity threshold of loan
     * @param _loanDurationType is duration type of loan
     * @param _repaymentCycleType is repayment type of loan
     */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType _loanDurationType,
        LoanDurationType _repaymentCycleType,
        uint256 _UID
    ) external;

    /**
     * @dev cancel offer
     * @param _offerId is id offer
     * @param _nftCollateralId is id NFT collateral
     */
    function cancelOffer(
        uint256 _offerId,
        uint256 _nftCollateralId,
        uint256 _UID
    ) external;

    /** ========================= ACCEPT OFFER ============================= */

    struct ContractTerms {
        address borrower;
        address lender;
        uint256 nftTokenId;
        address nftCollateralAsset;
        uint256 nftCollateralAmount;
        address loanAsset;
        uint256 loanAmount;
        address repaymentAsset;
        uint256 interest;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
        uint256 contractStartDate;
        uint256 contractEndDate;
        uint256 lateThreshold;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
    }

    struct Contract {
        uint256 nftCollateralId;
        uint256 offerId;
        ContractTerms terms;
        ContractStatus status;
        uint8 lateCount;
    }

    function acceptOffer(
        uint256 _nftCollateralId,
        uint256 _offerId,
        uint256 _UID
    ) external;

    /** ========================= REPAYMENT ============================= */

    struct PaymentRequest {
        uint256 requestId;
        PaymentRequestTypeEnum paymentRequestType;
        uint256 remainingLoan;
        uint256 penalty;
        uint256 interest;
        uint256 remainingPenalty;
        uint256 remainingInterest;
        uint256 dueDateTimestamp;
        bool chargePrepaidFee;
        PaymentRequestStatusEnum status;
    }

    /**
     * @dev End lend period settlement and generate invoice for next period
     * @param _contractId is id contract
     * @param _remainingLoan is remaining Loan of borrower
     * @param _nextPhrasePenalty is next Phrase Penalty
     * @param _nextPhraseInterest is token next Phrase Interest
     * @param _dueDateTimestamp is due DateTimestamp
     * @param _paymentRequestType is type of payment request
     * @param _chargePrepaidFee is charge Prepaid Fee
     */
    function closePaymentRequestAndStartNew(
        uint256 _contractId,
        uint256 _remainingLoan,
        uint256 _nextPhrasePenalty,
        uint256 _nextPhraseInterest,
        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType,
        bool _chargePrepaidFee
    ) external;

    /**
     * @dev Borrowers make repayments
     * @param _contractId is id contract
     * @param _paidPenaltyAmount is paid Penalty Amount
     * @param _paidInterestAmount is paid Interest Amount
     * @param _paidLoanAmount is paidLoanAmount
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external;

    function collateralRiskLiquidationExecution(
        uint256 _contractId,
        uint256 _collateralPerRepaymentTokenExchangeRate,
        uint256 _collateralPerLoanAssetExchangeRate
    ) external;

    function lateLiquidationExecution(uint256 _contractId) external;

    function notPaidFullAtEndContractLiquidation(uint256 _contractId) external;

    function getContractInfoForReview(uint256 _contractId) 
        external
        view
        returns (
            address borrower,
            address lender,
            ContractStatus status
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
library StorageSlotUpgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.4;

import "./PawnLib.sol";

interface IPawnV2 {

    /** General functions */

    function emergencyWithdraw(address _token) external;
}