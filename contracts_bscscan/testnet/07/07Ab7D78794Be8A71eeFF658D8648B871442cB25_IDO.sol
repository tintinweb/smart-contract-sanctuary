// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "contracts/tokens/ITokenERC20.sol";

contract IDO is AccessControl, ReentrancyGuard {
    using SafeERC20 for ITokenERC20;

    event CreateCampaign(
        Campaign campaign,
        DistributionInfo[] distributionToken,
        uint256 campaignId,
        uint256 timestamp
    );
    event UpdateCampaign(
        DistributionInfo[] distributionInfo,
        uint256 _campaignId,
        uint256 timestamp
    );
    event JoinToCampaign(
        uint256 campaignID,
        uint256 amount,
        address account,
        uint256 DLSburn,
        uint256 timeStamp
    );
    event ApproveCampaign(
        uint256 campaignID,
        CampaignState campaignState,
        uint256 receivedTokens,
        uint256 timestamp
    );
    event Claim(
        uint256 campaignID,
        address account,
        uint256 amount,
        uint256 timestamp
    );
    event ClaimRefund(
        uint256 campaignID,
        address account,
        uint256 amount,
        uint256 timestamp
    );
    event DepositDLS(
        address account,
        uint256 amount,
        uint256 campaignID,
        uint256 timestamp
    );
    event WithdrawDLS(
        address account,
        uint256 amount,
        uint256 campaignID,
        uint256 timestamp
    );
    event SetAvailability(
        bool isDepositAvailable,
        bool isJoinAvailable,
        bool isClaimAvailable
    );

    enum CampaignState {
        Unknown,
        Expectation,
        Vesting,
        Refund
    }
    enum CampaignType {
        Unknown,
        Public,
        Private
    }

    struct CampaignInfo {
        uint256 receivedTokens;
        uint256 paidOut;
        uint256 decimalAcceptedToken;
        uint256 decimalRewardToken;
        uint256 refunded;
        CampaignState campaignState; // current status of the campaign
    }

    struct Campaign {
        uint256 startTime; // campaign start time
        uint256 endTime; // campaign end time
        uint256 minAllocation; // minimum amount to participate in the campaign
        uint256 maxAllocation; // maximum amount to participate in the campaign
        uint256 minGoal; // minimum required amount to start a campaign
        uint256 maxGoal; // maximum amount to start a campaign
        uint256 tokenRate; // the price of the company's token in relation to the accepted token
        address acceptedToken; // Token accepted for the exchange
        address rewardToken; // campaign token
        CampaignType campaignType; // campaign type
    }

    struct UserInfo {
        uint256 investedTokens;
        uint256 rewardTokens;
        uint256 paidOutTokens;
    }

    struct DistributionInfo {
        uint256 unlockTime; // token unlock timestamp
        uint256 percent; // percentage of tokens that will be available after unlocking
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    uint256 campaignCount;
    address ETHER = address(0);
    ITokenERC20 public tokenDLS;

    bool public isDepositAvailable = true;
    bool public isJoinAvailable = true;
    bool public isClaimAvailable = true;

    mapping(uint256 => Campaign) public campaignMainData;
    mapping(uint256 => CampaignInfo) public campaignInfos;
    mapping(uint256 => DistributionInfo[]) public distributionTokenInfo;
    mapping(address => mapping(uint256 => UserInfo)) public userInfos;

    mapping(address => mapping(uint256 => uint256)) public balanceDLS; // account => campaignID => amount

    constructor(address validator, address DLStoken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(VALIDATOR_ROLE, validator);
        tokenDLS = ITokenERC20(DLStoken);
    }

    function setAvailability(
        bool _isDepositAvailable,
        bool _isJoinAvailable,
        bool _isClaimAvailable
    ) external onlyRole(ADMIN_ROLE) {
        if (isDepositAvailable != _isDepositAvailable)
            isDepositAvailable = _isDepositAvailable;
        if (isJoinAvailable != _isJoinAvailable)
            isJoinAvailable = _isJoinAvailable;
        if (isClaimAvailable != _isClaimAvailable)
            isClaimAvailable = _isClaimAvailable;

        emit SetAvailability(
            _isDepositAvailable,
            _isJoinAvailable,
            _isClaimAvailable
        );
    }

    /**
     *@dev Creating a new company
     *@param campaign info campaign
     *@param distributionToken an array with data on the distribution of tokens
     */
    function createCampaign(
        Campaign memory campaign,
        DistributionInfo[] memory distributionToken
    ) external onlyRole(ADMIN_ROLE) {
        require(
            campaign.startTime >= block.timestamp &&
                campaign.startTime < campaign.endTime,
            "Time error"
        );
        require(
            campaign.minAllocation <= campaign.maxAllocation &&
                campaign.minAllocation > 0,
            "Allocation error"
        );
        require(
            campaign.minGoal < campaign.maxGoal && campaign.minGoal > 0,
            "Goal error"
        );
        require(campaign.tokenRate > 0, "TokenRate error");

        string memory strError = _checkDistributionInfo(distributionToken);
        require(bytes(strError).length == 0, strError);
        require(
            campaign.campaignType != CampaignType.Unknown,
            "CampaignType error"
        );

        campaignMainData[campaignCount] = campaign;

        for (uint256 i; i < distributionToken.length; i++) {
            distributionTokenInfo[campaignCount].push(distributionToken[i]);
        }

        campaignInfos[campaignCount] = CampaignInfo(
            0,
            0,
            (campaign.acceptedToken != ETHER)
                ? IERC20Metadata(campaign.acceptedToken).decimals()
                : 18,
            IERC20Metadata(campaign.rewardToken).decimals(),
            0,
            CampaignState.Expectation
        );

        emit CreateCampaign(
            campaign,
            distributionToken,
            campaignCount,
            block.timestamp
        );
        campaignCount++;
    }

    /**
     *@dev The function is called after the campaign is created.
     *If the campaign was successful, the collected tokens are sent to the address and the distribution of rewards is started.
     *In case of failure, users will be able to withdraw their attachments
     *@param campaignID campaignID
     *@param campaignOwner the address to which the collected tokens will be sent
     */
    function approveCampaign(uint256 campaignID, address payable campaignOwner)
        external
        onlyRole(ADMIN_ROLE)
    {
        Campaign memory campaign = campaignMainData[campaignID];
        CampaignInfo storage campaignInfo = campaignInfos[campaignID];

        require(campaign.endTime <= block.timestamp, "endTime > timestamp");
        require(
            campaignInfo.campaignState == CampaignState.Expectation,
            "campaignState error"
        );
        if (campaignInfo.receivedTokens < campaign.minGoal) {
            campaignInfo.campaignState = CampaignState.Refund;

            emit ApproveCampaign(
                campaignID,
                campaignInfo.campaignState,
                campaignInfo.receivedTokens,
                block.timestamp
            );
            return;
        }
        if (campaign.acceptedToken == ETHER) {
            campaignOwner.transfer(campaignInfo.receivedTokens);
        } else {
            ITokenERC20(campaign.acceptedToken).safeTransfer(
                campaignOwner,
                campaignInfo.receivedTokens
            );
        }
        campaignInfo.campaignState = CampaignState.Vesting;

        emit ApproveCampaign(
            campaignID,
            campaignInfo.campaignState,
            campaignInfo.receivedTokens,
            block.timestamp
        );
    }

    /**
     *@dev Update token distribution parameters
     *@param campaignID campaign ID
     *@param  distributionToken array with token distribution parameters
     */
    function updateCampaign(
        uint256 campaignID,
        DistributionInfo[] memory distributionToken
    ) external onlyRole(ADMIN_ROLE) {
        delete distributionTokenInfo[campaignID];
        string memory strError = _checkDistributionInfo(distributionToken);
        require(bytes(strError).length == 0, strError);

        for (uint256 i; i < distributionToken.length; i++) {
            distributionTokenInfo[campaignCount].push(distributionToken[i]);
        }
        emit UpdateCampaign(distributionToken, campaignID, block.timestamp);
    }

    /**
     *@dev
     */
    function depositDLS(uint256 amount, uint256 campaignID) external {
        require(isDepositAvailable == true, "isDepositAvailable = false");
        Campaign memory campaign = campaignMainData[campaignID];
        require(
            campaign.startTime > block.timestamp,
            "Whitelist has already been formed"
        );
        require(
            campaign.campaignType == CampaignType.Private,
            "CampaignType.Public"
        );
        tokenDLS.safeTransferFrom(msg.sender, address(this), amount);
        balanceDLS[msg.sender][campaignID] += amount;

        emit DepositDLS(msg.sender, amount, campaignID, block.timestamp);
    }

    /**
     *@dev
     */
    function withdrawDLS(uint256 amount, uint256 campaignID)
        external
        nonReentrant
    {
        require(amount != 0, "amount=0");

        require(
            balanceDLS[msg.sender][campaignID] >= amount,
            "balance < amount"
        );
        if (campaignMainData[campaignID].startTime < block.timestamp) {
            amount = balanceDLS[msg.sender][campaignID];
        }

        balanceDLS[msg.sender][campaignID] -= amount;
        tokenDLS.safeTransfer(msg.sender, amount);

        emit WithdrawDLS(msg.sender, amount, campaignID, block.timestamp);
    }

    /**
     *@dev
     *@param campaignID campaign ID
     *@param amount amount tokens
     *@param v v signature
     *@param r r signature
     *@param s s signature
     */
    function joinToCampaign(
        uint256 campaignID,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(isJoinAvailable == true, "isJoinAvailable = false");
        Campaign memory campaign = campaignMainData[campaignID];
        CampaignInfo memory campaignInfo = campaignInfos[campaignID];
        require(
            campaignInfo.campaignState == CampaignState.Expectation &&
                campaign.endTime > block.timestamp,
            "you cannot participate in this company"
        );

        if (campaign.acceptedToken == ETHER) {
            amount = msg.value;
        } else {
            ITokenERC20(campaign.acceptedToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        if (campaign.campaignType == CampaignType.Private) {
            bytes32 message = keccak256(
                abi.encodePacked(campaignID, amount, msg.sender)
            );

            require(
                hasRole(
                    VALIDATOR_ROLE,
                    ECDSA.recover(
                        ECDSA.toEthSignedMessageHash(message),
                        v,
                        r,
                        s
                    )
                ),
                "VALIDATOR error"
            );
        }

        UserInfo storage userInfo = userInfos[msg.sender][campaignID];
        userInfo.investedTokens += amount;

        require(
            userInfo.investedTokens >= campaign.minAllocation &&
                userInfo.investedTokens <= campaign.maxAllocation,
            "Allocation error"
        );

        userInfo.rewardTokens += _calcTotalReward(amount, campaignID);

        campaignInfos[campaignID].receivedTokens += amount;

        uint256 amountDLS = _burnDLS(msg.sender, campaignID);

        require(campaignInfo.receivedTokens <= campaign.maxGoal, "max Goal");

        emit JoinToCampaign(
            campaignID,
            amount,
            msg.sender,
            amountDLS,
            block.timestamp
        );
    }

    /**
     *@dev collect tokens after a failed campaign
     */
    function claimRefund(uint256 campaignID) external nonReentrant {
        Campaign memory campaign = campaignMainData[campaignID];
        CampaignInfo memory campaignInfo = campaignInfos[campaignID];
        UserInfo storage userInfo = userInfos[msg.sender][campaignID];
        require(
            campaignInfo.campaignState == CampaignState.Refund,
            "CampaignState unequal Refund"
        );
        require(
            userInfo.investedTokens > 0,
            "investedTokens greater than zero"
        );

        if (campaign.acceptedToken != ETHER) {
            ITokenERC20(campaign.acceptedToken).safeTransfer(
                msg.sender,
                userInfo.investedTokens
            );
        } else {
            payable(msg.sender).transfer(userInfo.investedTokens);
        }
        campaignInfo.refunded += userInfo.investedTokens;

        emit ClaimRefund(
            campaignID,
            msg.sender,
            userInfo.investedTokens,
            block.timestamp
        );
        userInfo.investedTokens = 0;
    }

    /**
     *@dev collect available tokens if the campaign was successful
     */
    function claim(uint256 campaignID) external nonReentrant {
        require(isClaimAvailable == true, "isClaimAvailable = false");
        Campaign memory campaign = campaignMainData[campaignID];
        CampaignInfo memory campaignInfo = campaignInfos[campaignID];
        UserInfo storage userInfo = userInfos[msg.sender][campaignID];

        require(
            campaignInfo.campaignState == CampaignState.Vesting,
            "campaignState!=Vesting"
        );
        require(userInfo.investedTokens > 0, "investedTokens<0");

        uint256 percent = getAvailablePercent(campaignID);
        uint256 amount = ((userInfo.rewardTokens * percent) / 1e14) -
            userInfo.paidOutTokens;
        require(amount > 0, "amount == 0");

        userInfo.paidOutTokens += amount;

        ITokenERC20(campaign.rewardToken).safeTransfer(msg.sender, amount);

        emit Claim(campaignID, msg.sender, amount, block.timestamp);
    }

    /**
     *@dev withdraw token to sender by token address, if sender is admin
     *@param token address token
     *@param amount amount
     *@param account account address
     */
    function withdrawToken(
        address token,
        uint256 amount,
        address account
    ) external onlyRole(ADMIN_ROLE) {
        if (token != ETHER) {
            ITokenERC20(token).safeTransfer(account, amount);
        } else {
            payable(account).transfer(amount);
        }
    }

    /**
    @dev get information about the distribution of tokens in a particular campaign
     */
    function getDistributionInfo(uint256 campaignID)
        external
        view
        returns (DistributionInfo[] memory)
    {
        return distributionTokenInfo[campaignID];
    }

    /**
     *@dev get an available percentage of rewardos
     */
    function getAvailablePercent(uint256 campaignID)
        public
        view
        returns (uint256 percent)
    {
        DistributionInfo[] memory distrInfo = distributionTokenInfo[campaignID];

        for (uint256 i; i < distrInfo.length; i++) {
            if (distrInfo[i].unlockTime > block.timestamp) {
                return percent;
            }
            percent += distrInfo[i].percent;
        }

        return percent;
    }

    /**
     *@dev calculation of the number of all rewards
     */
    function _calcTotalReward(uint256 amount, uint256 campaignID)
        internal
        view
        returns (uint256)
    {
        CampaignInfo memory campaignInfo = campaignInfos[campaignID];

        uint256 reward = (amount * campaignMainData[campaignID].tokenRate) /
            1e18;

        if (
            campaignInfo.decimalAcceptedToken == campaignInfo.decimalRewardToken
        ) {
            return reward;
        } else {
            return
                (campaignInfo.decimalAcceptedToken >
                    campaignInfo.decimalRewardToken)
                    ? (reward /
                        (10 **
                            (campaignInfo.decimalAcceptedToken -
                                campaignInfo.decimalRewardToken)))
                    : (reward *
                        (10 **
                            (campaignInfo.decimalRewardToken -
                                campaignInfo.decimalAcceptedToken)));
        }
    }

    /**
     *@dev checking for the correctness of the received data
     */
    function _checkDistributionInfo(DistributionInfo[] memory distributionToken)
        internal
        pure
        returns (string memory)
    {
        uint256 sumPercent;

        for (uint256 i; i < distributionToken.length; i++) {
            if (i != 0) {
                if (
                    distributionToken[i].unlockTime <
                    distributionToken[i - 1].unlockTime
                ) {
                    return "unlockTime[i] less unlockTime[i-1]";
                }
            }
            sumPercent += distributionToken[i].percent;
        }

        if (sumPercent != 1e14) {
            return "percent!=100%";
        }
        return "";
    }

    function _burnDLS(address account, uint256 campaignID)
        internal
        returns (uint256)
    {
        uint256 amountDLS = balanceDLS[account][campaignID];
        tokenDLS.burn(address(this), amountDLS);
        balanceDLS[account][campaignID] = 0;
        return amountDLS;
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
pragma solidity ^0.8.0;

interface ITokenERC20 is IERC20{
    // function totalSupply() external view returns (uint256);

    // function balanceOf(address account) external view returns (uint256);

    // function transfer(address recipient, uint256 amount)
    //     external
    //     returns (bool);

    // function allowance(address owner, address spender)
    //     external
    //     view
    //     returns (uint256);

    // function approve(address spender, uint256 amount) external returns (bool);

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
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