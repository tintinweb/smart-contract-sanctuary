// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DappStore is AccessControl, Initializable {
    using SafeERC20 for IERC20;
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    uint public minMarginAmount;
    uint public curPrimaryCategoryIndex;
    uint public curSecondaryCategoryIndex;

    enum ProjectState {
        None,
        Pending,
        Succeeded,
        Defeated,
        Canceled
    }
    ProjectState constant defaultProjectState = ProjectState.Pending;

    struct ProjectInfo {
        RequiredProjectInfo requiredProjectInfo;
        OptionalProjectInfo optionalProjectInfo;
        uint8 status;
        uint curVersion;
        uint createTime;
        bool updateStatus;
    }

    struct RequiredProjectInfo {
        string title;
        uint primaryCategoryIndex;
        uint secondaryCategoryIndex;
        string shortIntroduction;
        string logoLink;
        string banner;
        string websiteLink;
        string contractAddresses;
        string email;
        uint marginAmount;
    }

    struct OptionalProjectInfo {
        string tokenSymbol;
        string tokenContractAddress;
        string tvlInterface;
        string detailDescription;
        string twitterLink;
        string telegramLink;
        string githubLink;
        string coinmarketcapLink;
        string coingeckoLink;
    }

    struct ChangedInfo {
        OptionalProjectInfo optionalProjectInfo;
        uint primaryCategory;
        uint secondaryCategory;
        string shortIntroduction;
        string logoLink;
        string banner;
        string websiteLink;
        uint addMarginAmount;
    }

    struct CommentInfo {
        uint8 score;
        string title;
        string review;
        uint timestamp;
    }

    mapping(string => bool) public existPrimaryCategories;
    mapping(string => bool) public existSecondaryCategories;
    mapping(uint => string) public primaryCategories;
    mapping(uint => string) public secondaryCategories;
    mapping(address => ProjectInfo) public projectInfos;
    mapping(address => mapping(uint => ChangedInfo)) public changedInfos;
    mapping(address => mapping(address => CommentInfo)) public commentInfos;
    mapping(bytes32 => mapping(address => uint8)) public isLikeCommentInfos;

    event UpdateMinMarginAmount(uint amount);
    event AddPrimaryCategory(uint index, string primaryCategory);
    event UpdatePrimaryCategory(uint index, string newPrimaryCategory);
    event AddSecondaryCategory(uint index, string secondaryCategory);
    event UpdateSecondaryCategory(uint index, string newSecondaryCategory);
    event SubmitProjectInfo(address projectAddress, ProjectInfo projectInfo);
    event VerifySubmitProjectInfo(address projectAddress, uint8 status);
    event UpdateProjectInfo(address projectAddress, uint version, ChangedInfo _changedInfo);
    event VerifyUpdateProjectInfo(address projectAddress, uint version, bool isUpdate);
    event SubmitCommentInfo(address projectAddress, address submitAddress, CommentInfo commentInfo);
    event IsLikeCommentInfo(address projectAddress, address reviewer, address isLikeAddress, uint8 isLike);
    event DeleteComment(address projectAddress, address reviewer);


    // ["DeFi", "Infrastructure", "Tools"]
    // ["Exchange", "NFT", "Game", "Earn", "Lending", "DAO", "Wallet", "Community", "Others"]
    function initialize(string[] memory _primaryCategories, string[] memory _secondaryCategories) public initializer {
        minMarginAmount = 10 ** 17;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VERIFIER_ROLE, _msgSender());

        for (uint index; index < _primaryCategories.length; index++) {
            addPrimaryCategory(_primaryCategories[index]);
        }
        for (uint index; index < _secondaryCategories.length; index++) {
            addSecondaryCategory(_secondaryCategories[index]);
        }
    }

    function updateMinMarginAmount(uint amount) public onlyOwner {
        minMarginAmount = amount;

        emit UpdateMinMarginAmount(amount);
    }

    function addPrimaryCategory(string memory primaryCategory) public onlyVerifier {
        require(!existPrimaryCategories[primaryCategory], "DS: primaryCategory already exists");
        primaryCategories[curPrimaryCategoryIndex] = primaryCategory;
        existPrimaryCategories[primaryCategory] = true;
        uint index = curPrimaryCategoryIndex;
        curPrimaryCategoryIndex++;

        emit AddPrimaryCategory(index, primaryCategory);
    }

    function updatePrimaryCategory(uint index, string calldata primaryCategory, string calldata newPrimaryCategory) public onlyVerifier {
        require(existPrimaryCategories[primaryCategory], "DS: primaryCategory must in primaryCategories");
        bytes32 primaryCategoryHash = keccak256(abi.encodePacked(primaryCategory));
        require(primaryCategoryHash == keccak256(abi.encodePacked(primaryCategories[index])), "DS: primaryCategories[index] != primaryCategory");
        primaryCategories[index] = newPrimaryCategory;
        delete existPrimaryCategories[primaryCategory];
        existPrimaryCategories[newPrimaryCategory] = true;

        emit UpdatePrimaryCategory(index, newPrimaryCategory);
    }

    function addSecondaryCategory(string memory secondaryCategory) public onlyVerifier {
        require(!existSecondaryCategories[secondaryCategory], "DS: secondaryCategory already exists");
        secondaryCategories[curSecondaryCategoryIndex] = secondaryCategory;
        existSecondaryCategories[secondaryCategory] = true;
        uint index = curSecondaryCategoryIndex;
        curSecondaryCategoryIndex++;

        emit AddSecondaryCategory(index, secondaryCategory);
    }

    function updateSecondaryCategory(uint index, string calldata secondaryCategory, string calldata newSecondaryCategory) public onlyVerifier {
        require(existSecondaryCategories[secondaryCategory], "DS: secondaryCategory must in secondaryCategories");
        bytes32 secondaryCategoryHash = keccak256(abi.encodePacked(secondaryCategory));
        require(secondaryCategoryHash == keccak256(abi.encodePacked(secondaryCategories[index])), "DS: secondaryCategories[index] != secondaryCategory");
        secondaryCategories[index] = newSecondaryCategory;
        delete existSecondaryCategories[secondaryCategory];
        existSecondaryCategories[newSecondaryCategory] = true;

        emit UpdateSecondaryCategory(index, newSecondaryCategory);
    }
    // ["title", 0, 0, "shortIntroduction", "logoLink", "bannerLink","websiteLink", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "[email protected]", "100000000000000000"]
    // ["", "", "", "", "", "", "", "", ""]
    function submitProjectInfo(RequiredProjectInfo calldata requiredProjectInfo, OptionalProjectInfo calldata optionalProjectInfo) public payable onlyCheckedCategory(requiredProjectInfo.primaryCategoryIndex, requiredProjectInfo.secondaryCategoryIndex) {
        uint8 status = projectInfos[msg.sender].status;
        require((status == uint8(ProjectState.None)) || (status == uint8(ProjectState.Defeated)), "DS: only one submission is allowed for an account");
        require(msg.value == requiredProjectInfo.marginAmount, "DS: margin amount error");
        require(msg.value >= minMarginAmount, "DS: insufficient value amounts");
        require(bytes(requiredProjectInfo.title).length <= 30, "DS: title length must <= 30");
        require(bytes(requiredProjectInfo.shortIntroduction).length <= 50, "DS: shortIntroduction length must <= 50");

        ProjectInfo storage projectInfo = projectInfos[msg.sender];
        projectInfo.requiredProjectInfo = requiredProjectInfo;
        projectInfo.optionalProjectInfo = optionalProjectInfo;
        projectInfo.status = uint8(defaultProjectState);
        projectInfo.createTime = block.timestamp;
        ++projectInfo.curVersion;

        emit SubmitProjectInfo(msg.sender, projectInfo);
    }

    function successSubmittedProjectInfo(address projectAddress) public onlyVerifier {
        require(projectInfos[projectAddress].status == uint8(ProjectState.Pending), "DS: invalid _status value");
        changeProjectState(projectAddress, ProjectState.Succeeded);
    }

    function defeatSubmittedProjectInfo(address payable projectAddress) public onlyVerifier {
        require(projectInfos[projectAddress].status == uint8(ProjectState.Pending), "DS: invalid _status value");
        projectAddress.transfer(projectInfos[projectAddress].requiredProjectInfo.marginAmount);
        changeProjectState(projectAddress, ProjectState.Defeated);
    }

    function cancelledProject(address payable projectAddress) public onlyVerifier {
        require(projectInfos[projectAddress].status == uint8(ProjectState.Succeeded), "DS: invalid _status value");
        changeProjectState(projectAddress, ProjectState.Canceled);
    }

    function changeProjectState(address projectAddress, ProjectState _status) internal {
        projectInfos[projectAddress].status = uint8(_status);
        emit VerifySubmitProjectInfo(projectAddress, uint8(_status));
    }

    // [["", "", "", "", "", "", "", "", ""], 1, 1, "shortIntroduction", "logoLink", "bannerLink","websiteLink", "0"]
    function updateProjectInfo(address projectAddress, ChangedInfo calldata _changedInfo) public payable onlyPassedProject(projectAddress) onlyCheckedCategory(_changedInfo.primaryCategory, _changedInfo.secondaryCategory) {
        require(!projectInfos[projectAddress].updateStatus, "DS: updateStatus must be false");
        require(msg.sender == projectAddress, "DS: projectAddress must be equal to msg.sender");
        require(msg.value == _changedInfo.addMarginAmount, "DS: msg.value not equal to addMarginAmount");
        require(_changedInfo.addMarginAmount + projectInfos[projectAddress].requiredProjectInfo.marginAmount >= minMarginAmount, "DS: insufficient margin amount");
        require(bytes(_changedInfo.shortIntroduction).length <= 50, "DS: shortIntroduction length must <= 50");

        uint version = ++projectInfos[projectAddress].curVersion;
        changedInfos[projectAddress][version] = _changedInfo;
        projectInfos[projectAddress].updateStatus = true;

        emit UpdateProjectInfo(projectAddress, version, _changedInfo);
    }

    function successUpdatedProjectInfo(address projectAddress) public onlyVerifier onlyPassedProject(projectAddress) onlyPendingUpdate(projectAddress) {
        uint version = projectInfos[projectAddress].curVersion;
        uint newMarginAmount = projectInfos[projectAddress].requiredProjectInfo.marginAmount + changedInfos[projectAddress][version].addMarginAmount;
        projectInfos[projectAddress].requiredProjectInfo.marginAmount = newMarginAmount;
        changeUpdatedProjectState(projectAddress, version, true);
    }

    function defeatUpdatedProjectInfo(address payable projectAddress) public onlyVerifier onlyPassedProject(projectAddress) onlyPendingUpdate(projectAddress) {
        uint version = projectInfos[projectAddress].curVersion;
        if (changedInfos[projectAddress][version].addMarginAmount > 0) {
            projectAddress.transfer(changedInfos[projectAddress][version].addMarginAmount);
        }
        changeUpdatedProjectState(projectAddress, version, false);
    }

    function changeUpdatedProjectState(address projectAddress, uint version, bool isUpdate) internal {
        projectInfos[projectAddress].updateStatus = false;
        emit VerifyUpdateProjectInfo(projectAddress, version, isUpdate);
    }

    function submitCommentInfo(address projectAddress, uint8 score, string calldata title, string calldata review) public onlyPassedProject(projectAddress) {
        require(commentInfos[projectAddress][msg.sender].score == 0, "DS: one project can be reviewed at the same address");
        require(score >= 5 && score <= 50, "DS: score must between 5 and 50");
        uint title_length = bytes(title).length;
        require(title_length > 0 && title_length <= 30, "DS: title length must between 1 and 30");

        CommentInfo memory commentInfo = CommentInfo(score, title, review, block.timestamp);
        commentInfos[projectAddress][msg.sender] = commentInfo;

        emit SubmitCommentInfo(projectAddress, msg.sender, commentInfo);
    }

    function deleteComment(address projectAddress) public onlyPassedProject(projectAddress) {
        require(commentInfos[projectAddress][msg.sender].score > 0, "DS: review must exist");
        delete commentInfos[projectAddress][msg.sender];

        emit DeleteComment(projectAddress, msg.sender);
    }

    // isLike=0 => default, isLike=1 => like, isLike=2 => dislike
    function isLikeCommentInfo(address projectAddress, address reviewer, uint8 isLike) public onlyPassedProject(projectAddress) {
        require(isLike >= 0 && isLike <= 2, "DS: isLike must between 0 and 2");
        require(commentInfos[projectAddress][reviewer].score > 0, "DS: review must exist");
        bytes32 commentHash = keccak256(abi.encodePacked(projectAddress, reviewer));
        isLikeCommentInfos[commentHash][msg.sender] = isLike;

        emit IsLikeCommentInfo(projectAddress, reviewer, msg.sender, isLike);
    }

    function withdrawMargin(address payable to, uint amount) public onlyOwner {
        require(address(this).balance >= amount, "DS: insufficient contract balance");
        to.transfer(amount);
    }

    function withdrawKRC20Token(address tokenAddress, address to, uint amount) public onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "DS: insufficient contract balance");
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DS: caller is not the owner");
        _;
    }

    modifier onlyVerifier() {
        require(hasRole(VERIFIER_ROLE, _msgSender()), "DS: caller is not the verifier");
        _;
    }

    modifier onlyCheckedCategory(uint primaryCategoryIndex, uint secondaryCategoryIndex) {
        string memory primaryCategory = primaryCategories[primaryCategoryIndex];
        string memory secondaryCategory = secondaryCategories[secondaryCategoryIndex];
        require(existPrimaryCategories[primaryCategory], "DS: primaryCategory error");
        require(existSecondaryCategories[secondaryCategory], "DS: secondaryCategory error");
        _;
    }

    modifier onlyPassedProject(address projectAddress) {
        require(projectInfos[projectAddress].status == uint8(ProjectState.Succeeded), "DS: project must have passed");
        _;
    }

    modifier onlyPendingUpdate(address projectAddress) {
        require(projectInfos[projectAddress].updateStatus, "DS: no updated info to review");
        _;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

