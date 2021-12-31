// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

import "../XWorldNFT.sol";

import "./XWorldDCLevelPool_0_1.sol";
import "./XWorldDCLevelPrize.sol";
import "./XWorldDCLevelStructs.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract XWorldDCLevel_0_2 is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC1967UpgradeUpgradeable,
    XWorldDCLevelStructs
{
    /**
     * @dev Ticket share is use by {XWorldDCLevel} for ticket income split
     */
    struct TicketShare {
        uint32 levelPool;
        uint32 lotteryPool;
        uint32 assetAward;
        uint32 teamRevenue;
        uint32 total;
    }

    /**
     * @dev Level pool base share is use by {XWorldDCLevel}, split level pool for each level by share
     */
    struct LevelPoolBaseShare {
        uint32 levelID;
        uint32 share;
    }

    struct LevelTicketPrice {
        uint32 levelID;
        uint256 price;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant LEVEL_ROLE = keccak256("LEVEL_ROLE");

    event XWorldDCLevelEnterLevel(
        uint32 indexed levelID,
        address indexed userAddr
    );
    event XWorldDCLevelFinishLevel(
        uint32 indexed levelID,
        address indexed userAddr,
        uint32 winPoint,
        uint256 gotnftid
    );
    event XWorldDCLevelAssetChange(uint32 indexed levelID, LevelAsset[] assets);
    event XWorldDCLevelTicketPriceChange(
        uint32 indexed levelID,
        uint256 ticketPrice
    );
    event XWorldDCLevelTicketPricesChange(LevelTicketPrice[] ticketPrices);
    event XWorldDCLevelTicketShareChange(TicketShare ticketShare);
    event XWorldDCLevelSharePoolIncome(
        uint32[] levelIds,
        uint256[] levelShareRates,
        uint256[] levelShares
    );
    event XWorldDCLevelSplitIncome(
        uint256 ticketIncome,
        uint256 poolIncome,
        uint256 levelPoolShare,
        uint256 lotteryPoolShare,
        uint256 teamShare,
        uint256 assetAwardShare
    );
    event XWorldDCLevelRoundFinish(uint256 round, uint256 totalAwards);

    XWorldDCLevelPool_0_1 public _levelPool;
    XWorldNFT public _levelPrizeNFT;

    mapping(uint256 => bool) private _userInLevel; // key : uint256(keccak256(abi.encodePacked(userAddr, levelID)));
    mapping(uint32 => uint256) public _ticketPrice; // key : levelID
    mapping(uint32 => LevelAssets) public _levelAssets; // key : levelID
    mapping(uint32 => uint32) public _levelWinPoints; // key : levelID

    TicketShare public _ticketShare;

    uint256 public _blocksPerRound;
    uint256 public _lastBlockNumber;
    uint256 public _currentRoundNumber;

    mapping(uint32 => uint32) public _levelPoolBaseShare; // key : levelID, value : level share

    uint32 public _levelRoundRatio;
    uint256 public _levelRoundPoolMaxOnRatio;

    constructor() {}

    function getVersion() public pure returns (string memory) {
        return "0.1";
    }

    //use initializer to limit call once
    //initializer store in proxy ,so only first contract call this
    function initialize() public initializer {
        __Context_init_unchained();

        __Pausable_init_unchained();

        __AccessControl_init_unchained();
        __ERC1967Upgrade_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(LEVEL_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to unpause"
        );
        _unpause();
    }

    function setLevelPoolAddress(address levelPool) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPool = XWorldDCLevelPool_0_1(levelPool);
    }

    function setLevelPrizeNftAddress(address levelPrize) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPrizeNFT = XWorldNFT(levelPrize);
    }

    function setBlocksPerRound(uint256 blocksPerRound) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        require(
            _currentRoundNumber == 0,
            "XWorldDCLevel: already set blocks per round"
        );

        _blocksPerRound = blocksPerRound;

        _lastBlockNumber = (block.number / _blocksPerRound) * _blocksPerRound;
        _currentRoundNumber = 1;
    }

    function setCurrentRoundNumber(
        uint256 lastBlockNumber,
        uint256 currentRoundNumber
    ) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        _lastBlockNumber = lastBlockNumber;
        _currentRoundNumber = currentRoundNumber;
    }

    function setLevelPoolBaseShare(LevelPoolBaseShare[] calldata baseShares)
        external
    {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        for (uint256 i = 0; i < baseShares.length; ++i) {
            _levelPoolBaseShare[baseShares[i].levelID] = baseShares[i].share;
        }
    }

    // level round ratio, each round will give away levelPool*ratio/10000 for award
    function setLevelRoundRatio(uint32 ratio) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelRoundRatio = ratio;
    }

    function setLevelRoundPoolMaxOnRatio(uint256 poolMax) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelRoundPoolMaxOnRatio = poolMax;
    }

    /**
     * @dev Entering level, call by user, cost token to enter level
     *
     * Emits an {XWorldDCLevelEnterLevel} event.
     *
     * Requirements:
     * - caller address not in level
     * - {XWorldDCLevelPool} must have allowance for caller's tokens of at least `ticketPrice`.
     *
     * @param levelID to enter level id
     */
    function enterLevel(uint32 levelID) external whenNotPaused {
        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(_msgSender(), levelID))
        );
        require(
            !_userInLevel[userLevelKey],
            "XWorldDCLevel: user already in level"
        );

        uint256 ticketPrice = getTicketPrice(levelID);
        require(ticketPrice > 0, "XWorldDCLevel: ticket price wrong");

        bool ret = _levelPool.buyTicket(levelID, _msgSender(), ticketPrice);
        require(ret, "XWorldDCLevel: buy ticket failed!");

        _userInLevel[userLevelKey] = true;

        emit XWorldDCLevelEnterLevel(levelID, _msgSender());
    }

    /**
     * @dev Finishing level, call by service, finish level and give prize nft
     *
     * Emits an {XWorldDCLevelFinishLevel} event.
     *
     * Requirements:
     * - `userAddr` in level
     * - caller must have `LEVEL_ROLE`
     *
     * @param levelID to finish level id
     * @param userAddr from which user address
     * @param winPoint winPoint > 0 means win, otherwise failed
     */
    function finishLevel(
        uint32 levelID,
        address userAddr,
        uint32 winPoint
    ) external whenNotPaused {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );

        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(userAddr, levelID))
        );
        require(_userInLevel[userLevelKey], "XWorldDCLevel: user not in level");
        uint256 nftid = 0;
        if (winPoint > 0) {
            nftid = _levelPrizeNFT.mint(
                userAddr,
                levelID,
                winPoint,
                _currentRoundNumber,
                new bytes(0)
            ); // win

            _levelWinPoints[levelID] += winPoint;
        }

        delete _userInLevel[userLevelKey];

        emit XWorldDCLevelFinishLevel(levelID, userAddr, winPoint, nftid);
    }

    /**
     * @dev Check is user in level
     *
     * @param levelID to check level id
     * @param userAddr from which user address
     */
    function isInLevel(uint32 levelID, address userAddr)
        external
        view
        returns (bool inLevel)
    {
        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(userAddr, levelID))
        );
        return _userInLevel[userLevelKey];
    }

    /**
     * @dev get current level round index
     *
     * @return round index
     */
    function getCurrentLevelRound() external view returns (uint256 round) {
        return _currentRoundNumber;
    }

    // call by service, get unshared level ticket income and split them into each share
    function spliteLevelsIncom(uint32[] calldata levelIDs)
        external
        whenNotPaused
    {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );

        // calculate pool share
        uint256 totalPoolBaseShare = 0;
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            require(
                _levelPoolBaseShare[levelIDs[i]] != 0,
                "XWorldDCLevel: need set level pool share"
            );
            totalPoolBaseShare += _levelPoolBaseShare[levelIDs[i]];
        }

        uint256[] memory poolShareRate = new uint256[](levelIDs.length);
        uint256 totalPoolShareRate = 0;

        uint256 totalTicketIncome = _levelPool._unshareLevelTicketIncomeTotal();
        require(totalTicketIncome > 0, "totalTicketIncome should not zero");
        require(totalPoolBaseShare > 0, "totalPoolBaseShare should not zero");
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint256 levelTicketIncome = _levelPool.getUnshareTicketIncome(
                levelIDs[i]
            );

            // ticket income define 50% share, pool base share define other 50% share
            uint256 share = ((1000000 * levelTicketIncome) /
                totalTicketIncome) +
                ((1000000 * _levelPoolBaseShare[levelIDs[i]]) /
                    totalPoolBaseShare);
            poolShareRate[i] = share;
            totalPoolShareRate += share;
        }

        // fetch genesis pool mining income
        uint256 poolIncome = _levelPool.transferGenesisPoolToken();

        uint256 totalTeamShare = 0;
        uint256 totalLotteryShare = 0;

        // split income
        uint256[] memory poolShares = new uint256[](levelIDs.length);
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint256 perLevelPoolIncome = (poolIncome * poolShareRate[i]) /
                totalPoolShareRate;
            poolShares[i] = levelIDs[i];

            uint256 teamShare;
            uint256 lotteryPoolShare;

            (teamShare, lotteryPoolShare) = _splitLevelIncome(
                levelIDs[i],
                perLevelPoolIncome
            );

            totalTeamShare += teamShare;
            totalLotteryShare += lotteryPoolShare;
        }

        // fill team pool
        _levelPool.fillTeamRevenue(totalTeamShare);

        // fill lottery pool
        _levelPool.fillLotteryPool(totalLotteryShare);

        emit XWorldDCLevelSharePoolIncome(levelIDs, poolShareRate, poolShares);
    }

    function _splitLevelIncome(uint32 levelID, uint256 poolIncome)
        internal
        whenNotPaused
        returns (uint256 teamShare, uint256 lotteryPoolShare)
    {
        uint256 ticketIncome = _levelPool.getUnshareTicketIncome(levelID);
        require(
            ticketIncome + poolIncome > 100 * 10**18, // TO DO : set smallest income
            "XWorldDCLevel: income too small"
        );
        // clear unshare income
        _levelPool.clearUnshareTicketIncome(levelID);

        // split ticket income into levelPool/lotteryPool/assetAward
        uint256 levelPoolShare = (ticketIncome * _ticketShare.levelPool) /
            _ticketShare.total;
        uint256 assetAwardShare = (ticketIncome * _ticketShare.assetAward) /
            _ticketShare.total;
        teamShare =
            (ticketIncome * _ticketShare.teamRevenue) /
            _ticketShare.total;

        LevelAssets memory levelAsts = _levelAssets[levelID];

        if (levelAsts.totalAssetPoint > 0) {
            AssetAward[] memory astAwards = new AssetAward[](
                levelAsts.assets.length
            );

            for (uint256 i = 0; i < levelAsts.assets.length; ++i) {
                astAwards[i].assetID = levelAsts.assets[i].assetID;
                astAwards[i].awardValue =
                    (assetAwardShare * levelAsts.assets[i].assetPoint) /
                    levelAsts.totalAssetPoint;
            }

            // give award
            _levelPool.giveAssetAward(astAwards);
        } else {
            // give back to level pool
            levelPoolShare += assetAwardShare;
            assetAwardShare = 0;
        }
        // fill level pool
        _levelPool.fillLevelPool(levelID, levelPoolShare + poolIncome); // pool income goes to level pool

        // lottery share
        lotteryPoolShare =
            ticketIncome -
            levelPoolShare -
            teamShare -
            assetAwardShare;

        // fill team pool
        //_levelPool.fillTeamRevenue(teamShare);
        // fill lottery pool
        //_levelPool.fillLotteryPool(lotteryPoolShare);

        emit XWorldDCLevelSplitIncome(
            ticketIncome,
            poolIncome,
            levelPoolShare,
            lotteryPoolShare,
            teamShare,
            assetAwardShare
        );
    }

    // call by service, finish current round and calculate round rewards.
    function calcLevelRound(uint32[] calldata levelIDs) external whenNotPaused {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );
        require(
            _lastBlockNumber + _blocksPerRound <= block.number,
            "XWorldDCLevel: round not finish yet"
        );

        uint256 pt = _levelPool._levelPoolTotal();
        uint32 levelRoundRatio = 0;
        if (pt < _levelRoundPoolMaxOnRatio) {
            levelRoundRatio = uint32(
                (_levelRoundRatio * pt) / _levelRoundPoolMaxOnRatio
            );
        } else {
            levelRoundRatio = _levelRoundRatio;
        }

        _lastBlockNumber = _lastBlockNumber + _blocksPerRound;

        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint32 levelID = levelIDs[i];

            if (_levelWinPoints[levelID] <= 0) {
                continue;
            }

            _levelPool.setLevelRound(
                _currentRoundNumber,
                levelID,
                _levelWinPoints[levelID],
                levelRoundRatio
            );
        }

        uint256 totalAwards;
        (totalAwards, ) = _levelPool.getLevelRoundStates(_currentRoundNumber);
        emit XWorldDCLevelRoundFinish(_currentRoundNumber, totalAwards);

        ++_currentRoundNumber;
    }

    function getTicketPrice(uint32 levelID)
        public
        view
        returns (uint256 ticketPrice)
    {
        return _ticketPrice[levelID];
    }

    function setTicketPrice(uint32 levelID, uint256 ticketPrice) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _ticketPrice[levelID] = ticketPrice;

        emit XWorldDCLevelTicketPriceChange(levelID, ticketPrice);
    }

    function setTicketPrices(LevelTicketPrice[] calldata prices) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        for (uint256 i = 0; i < prices.length; ++i) {
            _ticketPrice[prices[i].levelID] = prices[i].price;
        }

        emit XWorldDCLevelTicketPricesChange(prices);
    }

    function setTicketShare(
        uint32 levelPool,
        uint32 lotteryPool,
        uint32 assetAward,
        uint32 teamRevenue
    ) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        _ticketShare.assetAward = assetAward;
        _ticketShare.levelPool = levelPool;
        _ticketShare.lotteryPool = lotteryPool;
        _ticketShare.teamRevenue = teamRevenue;
        _ticketShare.total = assetAward + levelPool + lotteryPool + teamRevenue;

        emit XWorldDCLevelTicketShareChange(_ticketShare);
    }

    function modifyLevelAssets(uint32 levelID, LevelAsset[] calldata assets)
        external
    {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        LevelAssets storage asts = _levelAssets[levelID];

        //asts.assets = new LevelAsset[](assets.length);
        //**LevelAsset[] have dynamic memory size,can not be copy to storage.

        delete asts.assets; //resize to 0 element;

        for (uint256 i = 0; i < assets.length; ++i) {
            LevelAsset memory src = assets[i];
            //LevelAsset have fix size，can copy to storage
            asts.assets.push(src);
            //asts.assets[i].assetID = assets[i].assetID;
            //asts.assets[i].assetPoint = assets[i].assetPoint;
            asts.totalAssetPoint += assets[i].assetPoint;
        }

        emit XWorldDCLevelAssetChange(levelID, assets);
    }

    function getLevelAssets(uint32 levelID)
        external
        view
        returns (LevelAsset[] memory assets)
    {
        return _levelAssets[levelID].assets;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

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

// contracts/XWorldNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControl,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter internal _tokenIdTracker;

    string internal _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    // function mint(address to) public virtual {
    //     require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

    //     // We cannot just use balanceOf to create the new tokenId because tokens
    //     // can be burned (destroyed), so we need a separate counter.
    //     _mint(to, _tokenIdTracker.current());
    //     _tokenIdTracker.increment();
    // }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P1");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P2");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract XWorldExtendableNFT is ERC721PresetMinterPauserAutoId {
    
    bytes32 public constant DATA_ROLE = keccak256("DATA_ROLE");

    event XWorldNFTFreeze(uint256 indexed tokenId, bool freeze);
    
    event XWorldNFTExtendName(string extendName, bytes32 nameBytes);
    event XWorldNFTExtendModify(uint256 indexed tokenId, bytes32 nameBytes, bytes extendData);

    struct NFTExtendsNames{
        bytes32[]   NFTExtendDataNames;
    }

    struct NFTExtendData {
        bool _exist;
        mapping(uint256 => bytes) ExtendDatas; // address => data mapping
    }

    mapping(uint256 => bool) private _nftFreezed;
    mapping(uint256 => NFTExtendsNames) private _nftExtendNames;
    mapping(bytes32 => NFTExtendData) private _nftExtendDataMap; // extend name => extend datas mapping

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) 
    {
    }

    function freeze(uint256 tokenId) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "R2");

        _nftFreezed[tokenId] = true;

        emit XWorldNFTFreeze(tokenId, true);
    }

    function unFreeze(uint256 tokenId) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "R3");

        delete _nftFreezed[tokenId];

        emit XWorldNFTFreeze(tokenId, false);
    }

    function notFreezed(uint256 tokenId) public view returns (bool) {
        return !_nftFreezed[tokenId];
    }

    function isFreezed(uint256 tokenId) public view returns (bool) {
        return _nftFreezed[tokenId];
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function extendNftData(string memory extendName) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "R5");

        bytes32 nameBytes = keccak256(bytes(extendName));
        NFTExtendData storage extendData = _nftExtendDataMap[nameBytes];
        extendData._exist = true;

        emit XWorldNFTExtendName(extendName, nameBytes);
    }

    function addTokenExtendNftData(
        uint256 tokenId,
        string memory extendName,
        bytes memory extendData
    ) external whenNotPaused {
        require(
            hasRole(DATA_ROLE, _msgSender()) ||
                hasRole(
                    keccak256(abi.encodePacked("DATA_ROLE", extendName)),
                    _msgSender()
                ),
            "R6"
        );

        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E1");
        require(!_tokenExtendNameExist(tokenId, nameBytes), "E2");

        // modify extend data
        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        extendDatas.ExtendDatas[tokenId] = extendData;

        // save token extend data names
        NFTExtendsNames storage nftData = _nftExtendNames[tokenId];
        nftData.NFTExtendDataNames.push(nameBytes);

        emit XWorldNFTExtendModify(tokenId, nameBytes, extendData);
    }

    function modifyTokenExtendNftData(
        uint256 tokenId,
        string memory extendName,
        bytes memory extendData
    ) external whenNotPaused {
        require(
            hasRole(DATA_ROLE, _msgSender()) ||
                hasRole(
                    keccak256(abi.encodePacked("DATA_ROLE", extendName)),
                    _msgSender()
                ),
            "E3"
        );

        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E4");
        require(_tokenExtendNameExist(tokenId, nameBytes), "E5");

        // modify extend data
        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        extendDatas.ExtendDatas[tokenId] = extendData;

        emit XWorldNFTExtendModify(tokenId, nameBytes, extendData);
    }

    function getTokenExtendNftData(uint256 tokenId, string memory extendName)
        external
        view
        returns (bytes memory)
    {
        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E6");

        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        return extendDatas.ExtendDatas[tokenId];
    }

    function _extendNameExist(bytes32 nameBytes) internal view returns (bool) {
        return _nftExtendDataMap[nameBytes]._exist;
    }
    function _tokenExtendNameExist(uint256 tokenId, bytes32 nameBytes) internal view returns(bool) {
        NFTExtendsNames memory nftData = _nftExtendNames[tokenId];
        for(uint i=0; i<nftData.NFTExtendDataNames.length; ++i){
            if(nftData.NFTExtendDataNames[i] == nameBytes){
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(notFreezed(tokenId), "F1");

        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            // delete token extend datas;
            NFTExtendsNames memory nftData = _nftExtendNames[tokenId];
            for(uint i = 0; i< nftData.NFTExtendDataNames.length; ++i){
                NFTExtendData storage extendData = _nftExtendDataMap[nftData.NFTExtendDataNames[i]];
                delete extendData.ExtendDatas[tokenId];
            }

            // delete token datas
            delete _nftExtendNames[tokenId];
        }
    }
}

struct XWorldNFTMintOption {
    address To;
    uint32 NFTType;
    uint32 NFTTypeID;
    uint256 NFTFixedData;
    bytes NFTUserData;
}

contract XWorldNFT is XWorldExtendableNFT {
    using Counters for Counters.Counter;
    
    event XWorldNFTMint(address indexed to, uint256 indexed tokenId, uint32 nftType, uint32 nftTypeID, uint256 nftFixedData, bytes nftUserData);
    event XWorldNFTBatchMint(uint256[] mintids);
    event XWorldNFTModify(uint256 indexed tokenId, uint256 nftFixedData, bytes nftUserData);

    struct NFTData{
        uint32      NFTType;
        uint32      NFTTypeID;
        uint256     NFTFixedData;
        bytes       NFTUserData;
    }

    mapping(uint256 => NFTData) private _nftDatas;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        XWorldExtendableNFT(name, symbol, baseTokenURI)
    {
        // mint(_msgSender(), 0, 0, 0, new bytes(0));
    }

    // function mint(address to) public virtual override {
    //     revert("XWorldNFT: use mint(to, fixData, userData) instead");
    // }

    function batchMint(XWorldNFTMintOption[] calldata options) public returns(uint256[] memory) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        uint32 len = uint32(options.length);
        uint256[] memory mintids = new uint256[](len);

        for (uint32 i = 0; i <len; i++) {
            XWorldNFTMintOption memory op = options[i];
            uint256 curID = _tokenIdTracker.current();
            _mint(op.To, curID);
            NFTData storage nftData = _nftDatas[curID];
            nftData.NFTType = op.NFTType;
            nftData.NFTTypeID = op.NFTTypeID;
            nftData.NFTFixedData = op.NFTFixedData;
            nftData.NFTUserData = op.NFTUserData;
            mintids[i] = curID;
            _tokenIdTracker.increment();
        }
        emit XWorldNFTBatchMint(mintids);

        return mintids;
    }

    function mint(address to, uint32 nftType, uint32 nftTypeID, uint256 nftFixedData, bytes memory nftUserData) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        NFTData storage nftData = _nftDatas[curID];
        nftData.NFTType = nftType;
        nftData.NFTTypeID = nftTypeID;
        nftData.NFTFixedData = nftFixedData;
        nftData.NFTUserData = nftUserData;

        emit XWorldNFTMint(to, curID, nftType, nftTypeID, nftFixedData, nftUserData);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }

    function modifyNftData(uint256 tokenId, uint256 nftFixedData, bytes memory nftUserData) external whenNotPaused {
        require(hasRole(DATA_ROLE, _msgSender()), "R4");
        require(_exists(tokenId), "R5");

        // only modify user data
        NFTData storage nftData = _nftDatas[tokenId];
        nftData.NFTFixedData = nftFixedData;
        nftData.NFTUserData = nftUserData;

        emit XWorldNFTModify(tokenId, nftFixedData, nftUserData);
    }

    function getNftData(uint256 tokenId) external view returns(uint256 nftId, uint32 nftType, uint32 nftTypeID, uint256 nftFixedData, bytes memory nftUserData){
        require(_exists(tokenId), "T1");

        NFTData memory nftData = _nftDatas[tokenId];

        nftId = tokenId;
        nftType = nftData.NFTType;
        nftTypeID = nftData.NFTTypeID;
        nftFixedData = nftData.NFTFixedData;
        nftUserData = nftData.NFTUserData;
    }

}

// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../Seriality/Seriality_1_0/SerialityBuffer.sol";
import "../Seriality/Seriality_1_0/SerialityUtility.sol";
import "../Utility/TransferHelper.sol";

import "./XWorldDCLevelStructs.sol";

// XWG GenesisPoolManager
interface IXWGGenesisPoolManager {
    
    function getCurrentChannelUnspendAmount() external view returns(uint256);
    
    function spendChannelAmount(address addr, uint256 amount) external;
    
}

// XWG lottery manager
interface IXWGLotteryManager {
    function injectFundsIntoLotteryPool(uint64 lotteryPoolId, uint256 amount) external returns (uint256);

    function getLotteryBalance(uint64 lotteryPoolId, address account) external view returns (uint256);

    function claimNumOfLotteries(
        uint64 lotteryPoolId,
        uint8 lotteryAmount,
        address to,
        uint256 luckyNumber
    ) external returns (uint256 startTokenId, uint256 endTokenId);
}

contract XWorldDCLevelPool_0_1 is
    Initializable,
    ContextUpgradeable, 
    PausableUpgradeable, 
    AccessControlUpgradeable,
    ERC1967UpgradeUpgradeable,
    XWorldDCLevelStructs
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant LEVEL_ROLE = keccak256("LEVEL_ROLE");

    event XWorldDCLevelPoolFetchAssetAward(address indexed userAddr, uint256 indexed assetID, uint256 award);
    event XWorldDCLevelPoolFetchUserAward(address indexed userAddr, uint256 award);
    event XWorldDCLevelPoolFetchTeamRevenue(address indexed teamAddr, uint256 value);

    IXWGGenesisPoolManager public _xwgGenesisPM;
    IXWGLotteryManager public _xwgLotteryManager;
    IERC20 public _xwgToken;
    IERC721  public _levelAssetNFT;

    uint64 _lotteryPoolId;

    // unshared ticket income, it will split into shares by XWorldDCLevel.spliteLevelsIncom
    mapping(uint32 => uint256) public _unshareLevelTicketIncome;
    uint256 public _unshareLevelTicketIncomeTotal;

    // level pool for user award
    // token goes to _levelPool => _levelRounds => _userAward
    mapping(uint32 => uint256) public _levelPool;
    uint256 public _levelPoolTotal;

    // asset pool for asset award
    mapping(uint256 => uint256) public _assetAward;
    uint256 public _assetAwardTotal;

    // team pool for team revenue
    uint256 public _teamPool;
    address public _teamRevenueAddress;

    // user award that user can fetch
    mapping(address => uint256) public _userAward;
    uint256 public _userAwardTotal;

    // level round keeps each round award parameters.
    mapping(uint256 => LevelRound) public _levelRounds;
    uint256 public _levelRoundPoolTotal;

    constructor() {
    }

    function getVersion() public pure returns (string memory) {
        return "0.1";
    }

    //use initializer to limit call once
    //initializer store in proxy ,so only first contract call this
    function initialize() public initializer {
        __Context_init_unchained();

        __Pausable_init_unchained();

        __AccessControl_init_unchained();
        __ERC1967Upgrade_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(LEVEL_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to unpause"
        );
        _unpause();
    }

    function _checkPoolAmountOverflow(uint256 addValue) internal view returns(bool isOverFlow) {
        return addValue + _levelPoolTotal + _assetAwardTotal + _teamPool +
            _userAwardTotal + _unshareLevelTicketIncomeTotal + _levelRoundPoolTotal > _xwgToken.balanceOf(address(this));
    }

    function setXWGLotteryManagerAddress(address xwgLMAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");

        if(address(_xwgLotteryManager) != address(0)){

            _xwgToken.approve(address(_xwgLotteryManager), 0); // revoke approve
        }

        _xwgLotteryManager = IXWGLotteryManager(xwgLMAddr);

        _xwgToken.approve(address(_xwgLotteryManager), 10000000000 * 10**18); // approve token to lottery manager
    }

    function setXWGGenesisPoolManagerAddress(address xwgGPMAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        _xwgGenesisPM = IXWGGenesisPoolManager(xwgGPMAddr);
    }

    function setXWGTokenAddress(address xwgAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        _xwgToken = IERC20(xwgAddr);
    }

    function setAssetNftAddress(address assetNFT) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        _levelAssetNFT = IERC721(assetNFT);
    }

    function setLotteryPoolId(uint64 lotteryPoolId) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        _lotteryPoolId = lotteryPoolId;
    }

    function setTeamRevenueAddress(address addr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        _teamRevenueAddress = addr;
    }
    
    // call by {XWorldDCLevel}
    function buyTicket(uint32 levelID, address userAddr, uint256 ticketPrice) external whenNotPaused returns(bool success) {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(_xwgToken.balanceOf(userAddr) >= ticketPrice, "XWorldDCLevel: insufficient xwg");

        TransferHelper.safeTransferFrom(address(_xwgToken), userAddr, address(this), ticketPrice);

        _unshareLevelTicketIncome[levelID] += ticketPrice;
        _unshareLevelTicketIncomeTotal += ticketPrice;

        return true;
    }

    // call by {XWorldDCLevel}
    function transferGenesisPoolToken() external whenNotPaused returns(uint256 value){
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");

        value = _xwgGenesisPM.getCurrentChannelUnspendAmount();
        _xwgGenesisPM.spendChannelAmount(address(this), value);

        return value;
    }

    // call by {XWorldDCLevel}
    function getUnshareTicketIncome(uint32 levelID) external view returns(uint256 value) {
        return _unshareLevelTicketIncome[levelID];
    }
    function clearUnshareTicketIncome(uint32 levelID) external {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");

        _unshareLevelTicketIncomeTotal -= _unshareLevelTicketIncome[levelID];
        delete _unshareLevelTicketIncome[levelID];
    }

    // delivery awards, call by {XWorldDCLevel}
    function fillLevelPool(uint32 levelID, uint256 value) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(!_checkPoolAmountOverflow(value), "XWorldDCLevelPool: fill level pool overflow");

        _levelPool[levelID] += value;
        _levelPoolTotal += value;
    }
    function subLevelPool(uint32 levelID, uint256 value) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(_levelPool[levelID] >= value && _levelPoolTotal >= value, "XWorldDCLevelPool: sub level pool overflow");

        _levelPool[levelID] -= value;
        _levelPoolTotal -= value;
    }

    // delivery awards, call by {XWorldDCLevel}
    function giveAssetAward(AssetAward[] calldata assetAwards) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");

        uint256 awardAdded = 0;
        for(uint i = 0; i< assetAwards.length; ++i) {
            _assetAward[assetAwards[i].assetID] += assetAwards[i].awardValue;
            awardAdded += assetAwards[i].awardValue;
        }
        require(!_checkPoolAmountOverflow(awardAdded), "XWorldDCLevelPool: give asset award overflow");

        _assetAwardTotal += awardAdded;
    }

    // delivery awards, call by {XWorldDCLevel}
    function fillLotteryPool(uint256 value) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(!_checkPoolAmountOverflow(value), "XWorldDCLevelPool: fill lottery pool overflow");

        // dispath token to lottery contract
        _xwgLotteryManager.injectFundsIntoLotteryPool(_lotteryPoolId, value);
    }

    // delivery awards, call by {XWorldDCLevel}
    function fillTeamRevenue(uint256 value) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(!_checkPoolAmountOverflow(value), "XWorldDCLevelPool: fill team pool overflow");

        _teamPool += value;
    }

    // fetch team revenue
    function fetchTeamRevenue(uint256 value) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevelPool: must have manager role");
        require(value <= _teamPool, "XWorldDCLevelPool: fetch team pool overflow");

        TransferHelper.safeTransfer(address(_xwgToken), _teamRevenueAddress, value);
        _teamPool -= value;

        emit XWorldDCLevelPoolFetchTeamRevenue(_teamRevenueAddress, value);
    }

    // check asset awards
    function assetAward(uint256 assetID) external view returns(uint256 value) {
        return _assetAward[assetID];
    }
    // fetch asset awards
    function fetchAssetAward(uint256 assetID) external whenNotPaused {
        require(_levelAssetNFT.ownerOf(assetID) == _msgSender(), "XWorldDCLevelPool: ownership error");
        require(_assetAward[assetID] > 0, "XWorldDCLevelPool: can't find asset award");

        uint256 award = _assetAward[assetID];
        delete _assetAward[assetID];

        TransferHelper.safeTransfer(address(_xwgToken), _msgSender(), award);

        _assetAwardTotal -= award;

        emit XWorldDCLevelPoolFetchAssetAward(_msgSender(), assetID, award);
    }

    // check user awards
    function userAward(address userAddr) external view returns(uint256 value) {
        return _userAward[userAddr];
    }
    // fetch user awards
    function fetchUserAward() external whenNotPaused {
        require(_userAward[_msgSender()] > 0, "XWorldDCLevelPool: can't find user award");

        uint256 award = _userAward[_msgSender()];
        delete _userAward[_msgSender()];

        TransferHelper.safeTransfer(address(_xwgToken), _msgSender(), award);

        _userAwardTotal -= award;

        emit XWorldDCLevelPoolFetchUserAward(_msgSender(), award);
    }

    // record level round awards, call by {XWorldDCLevel}
    function setLevelRound(uint256 round, uint32 levelID, uint32 totalWinPoint, uint32 levelRoundRatio) external whenNotPaused {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        require(_levelPool[levelID] > 0, "XWorldDCLevelPool: level pool empty");

        LevelRound storage rnd = _levelRounds[round];
        LevelRecord storage rec = rnd.levelRecords[levelID];

        rec.levelPoint = totalWinPoint;
        rec.levelAward = _levelPool[levelID] * levelRoundRatio / 10000;

        require(_levelPoolTotal >= rec.levelAward && _levelPool[levelID] >= rec.levelAward, "XWorldDCLevelPool: level pool overflow");

        _levelPool[levelID] -= rec.levelAward;
        _levelPoolTotal -= rec.levelAward;

        rnd.roundTotalAwards += rec.levelAward;
        _levelRoundPoolTotal += rec.levelAward;
    }

    // dispatch level awards to user, call by {XWorldDCLevelPrize}
    function dispatchLevelUserAward(uint256 round, uint32 levelID, address userAddr, uint32 winPoint) external whenNotPaused returns(uint256 valueDispatched) {
        require(hasRole(LEVEL_ROLE, _msgSender()), "XWorldDCLevelPool: must have level role");
        LevelRound storage rnd = _levelRounds[round];

        require(rnd.roundTotalAwards > 0, "XWorldDCLevelPool: level round not exist");
        require(rnd.levelRecords[levelID].levelAward > 0, "XWorldDCLevelPool: level record not exist");

        LevelRecord memory rec = rnd.levelRecords[levelID];
        uint256 value = winPoint * rec.levelAward / rec.levelPoint;

        require(rnd.roundTotalAwards - rnd.roundDispatchedAwards >= value && _levelRoundPoolTotal >= value, "XWorldDCLevelPool: insufficient level awards");
        require(!_checkPoolAmountOverflow(value), "XWorldDCLevelPool: dispatch level user award overflow");

        rnd.roundDispatchedAwards += value;
        _levelRoundPoolTotal -= value;

        _userAward[userAddr] += value;
        _userAwardTotal += value;

        return value;
    }

    // get level round info
    function getLevelRoundStates(uint256 round) external view returns(uint256 roundTotalAwards, uint256 roundDispatchedAwards) {
        LevelRound storage rnd = _levelRounds[round];
        roundTotalAwards = rnd.roundTotalAwards;
        roundDispatchedAwards = rnd.roundDispatchedAwards;
    }
    function getLevelRoundRecord(uint256 round, uint32 levelID) external view returns(LevelRecord memory rec) {
        LevelRound storage rnd = _levelRounds[round];
        rec = rnd.levelRecords[levelID];
    }

    // dispatch level awards to user, call by {XWorldDCLevelPrize}
    function dispatchLotteryNFT(address userAddr, uint32 count, uint32 luckyNumber) 
        external 
        whenNotPaused 
        returns(uint256 startTokenId, uint256 endTokenId) 
    {
        // check lottery balance
        if(count > _xwgLotteryManager.getLotteryBalance(_lotteryPoolId, address(this))){
            // lottery balance less than count, dispatch failed
            return (0,0);
        }

        // give lottery nft to user
        return _xwgLotteryManager.claimNumOfLotteries(_lotteryPoolId, uint8(count), userAddr, luckyNumber);
    }
}

// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../Utility/IXWorldRandom.sol";
import "../DCEquip/XWorldDCEquipMysteryBox.sol";
import "../XWorldNFT.sol";
import "./XWorldDCLevelPool_0_1.sol";
import "./XWorldDCLevel_0_1.sol";

contract XWorldDCLevelPrize is 
    Context,
    Pausable,
    AccessControl,
    IXWorldOracleRandComsumer
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RAND_ROLE = keccak256("RAND_ROLE");

    event XWorldDCLevelTokenPrizeFetched(address indexed useAddr, uint256 levelPrizeID, uint256 tokenDipatched);
    event XWorldDCLevelNFTPrizeFetched(address indexed useAddr, uint256 levelPrizeID, uint256 equipID, uint256 lotteryID);

    struct LevelPrizeOpenRecord {
        address userAddr;
        uint256 levelPrizeID;
        uint32 levelID;
    }

    XWorldNFT public _levelPrizeNFT;
    XWorldDCLevelPool_0_1 public _levelPool;
    XWorldDCLevel_0_1 public _level;

    XWorldMBRandomSourceBase public _equipPrizeRandomSource;
    XWorldDCEquipMBContentMinter public _equipMinter;
    mapping(uint256=>LevelPrizeOpenRecord) public _levelPrizeOpened; // indexed by oracleRand request id

    mapping(uint32=>uint32) public _levelEquipDropRate; // indexed by levelid, value is ratio base 100000000
    mapping(uint32=>uint32) public _levelLotteryDropRate; // indexed by levelid, value is ratio base 100000000

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RAND_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to unpause"
        );
        _unpause();
    }

    function setLevelPrizeNftAddress(address levelPrizeNft) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPrizeNFT = XWorldNFT(levelPrizeNft);
    }

    function setLevelAddress(address level) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _level = XWorldDCLevel_0_1(level);
    }

    function setLevelPoolAddress(address levelPool) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPool = XWorldDCLevelPool_0_1(levelPool);
    }

    function setEquipPrizeRandomSource(address eqpPrizeRndSrc) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCEquipDirectMB: must have manager role"
        );
        _equipPrizeRandomSource = XWorldMBRandomSourceBase(eqpPrizeRndSrc);
    }

    function setEquipPrizeMinter(address eqpMinter) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCEquipDirectMB: must have manager role"
        );
        _equipMinter = XWorldDCEquipMBContentMinter(eqpMinter);
    }

    function setLevelEquipDropRate(uint32 levelId, uint32 dropRate) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCEquipDirectMB: must have manager role"
        );
        _levelEquipDropRate[levelId] = dropRate;
    }

    function setLevelLotteryDropRate(uint32 levelId, uint32 dropRate) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCEquipDirectMB: must have manager role"
        );
        _levelLotteryDropRate[levelId] = dropRate;
    }

    // fetch level prize by prize nft
    function fetchLevelPrize(uint256 levelPrizeID) external whenNotPaused {
        require(tx.origin == _msgSender(), "XWorldDCLevelPrize: only for outside account");
        require(_levelPrizeNFT.notFreezed(levelPrizeID), "XWorldDCLevelPrize: freezed token");
        require(_levelPrizeNFT.ownerOf(levelPrizeID) == _msgSender(), "XWorldDCLevelPrize: ownership check failed");
        require(address(_equipPrizeRandomSource) != address(0), "XWorldDCLevelPrize: equip random source need initialized");

        uint32 levelID;
        uint32 winPoint; 
        uint256 round;

        // fetch data
        (,levelID, winPoint, round, ) = _levelPrizeNFT.getNftData(levelPrizeID);

        require(round < _level.getCurrentLevelRound(), "XWorldDCLevelPrize: level round not finish");

        address rndAddr = XWorldMBRandomSourceBase(_equipPrizeRandomSource).getRandSource();
        require(rndAddr != address(0), "XWorldDCLevelPrize: rand address wrong");

        // burn token
        _levelPrizeNFT.burn(levelPrizeID);

        uint256 tokenDisp;
        // dispatch user token award
        (tokenDisp) =_levelPool.dispatchLevelUserAward(round, levelID, _msgSender(), winPoint);

        // request random number
        uint256 reqid = IXWorldRandom(rndAddr).oracleRand();

        LevelPrizeOpenRecord storage openRec = _levelPrizeOpened[reqid];
        openRec.levelID = levelID;
        openRec.levelPrizeID = levelPrizeID;
        openRec.userAddr = _msgSender();

        // emit fetch prize event
        emit XWorldDCLevelTokenPrizeFetched(_msgSender(), levelPrizeID, tokenDisp);
    }

    // get rand number, do dispatch equip and lottery
    function oracleRandResponse(uint256 reqid, uint256 randnum) override external {
        require(hasRole(RAND_ROLE, _msgSender()), "XWorldDCLevelPrize: must have rand role");
        require(address(_equipMinter) != address(0), "XWorldDCLevelPrize: equip minter need initialized");
        require(address(_equipPrizeRandomSource) != address(0), "XWorldDCLevelPrize: equip random source need initialized");

        address rndAddr = XWorldMBRandomSourceBase(_equipPrizeRandomSource).getRandSource();
        require(rndAddr != address(0), "XWorldDCLevelPrize: rand address wrong");

        LevelPrizeOpenRecord storage openRec = _levelPrizeOpened[reqid];

        require(openRec.userAddr != address(0), "XWorldDCLevelPrize: user address wrong");

        uint32 randIndex = 0;
        uint256 newEquipId = 0;
        uint256 newLotteryId = 0;

        // check if drop equip
        uint32 equipDropRatioBase = _levelEquipDropRate[openRec.levelID];
        if(equipDropRatioBase > 0) {
            uint32 equipDroped = uint32(randnum % 100000000);
            if(equipDroped < equipDropRatioBase){

                // fetch next rand number
                randnum = IXWorldRandom(rndAddr).nextRand(++randIndex, randnum);

                // dispatch equipment
                bytes memory contentNFTDatas = XWorldMBRandomSourceBase(_equipPrizeRandomSource).randomNFTData(randnum, openRec.levelID);
                newEquipId = _equipMinter.mintContentAssets(openRec.userAddr, openRec.levelPrizeID, contentNFTDatas);
            }
            
            // fetch next rand number for lottery
            randnum = IXWorldRandom(rndAddr).nextRand(++randIndex, randnum);
        }

        // check if drop lottery
        uint32 lotteryDropRatioBase = _levelLotteryDropRate[openRec.levelID];
        if(lotteryDropRatioBase > 0) {
            uint32 lotteryDroped = uint32(randnum % 100000000);
            if(lotteryDroped < lotteryDropRatioBase) {

                // fetch next rand number
                randnum = IXWorldRandom(rndAddr).nextRand(++randIndex, randnum);

                // dispatch lottery
                (newLotteryId, ) = _levelPool.dispatchLotteryNFT(openRec.userAddr, 1, uint32(randnum));
            }
        }

        // emit fetch prize event
        emit XWorldDCLevelNFTPrizeFetched(openRec.userAddr, openRec.levelPrizeID, newEquipId, newLotteryId);

        delete _levelPrizeOpened[reqid];
    }
}

// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../Seriality/Seriality_1_0/SerialityBuffer.sol";
import "../Seriality/Seriality_1_0/SerialityUtility.sol";

/**
 * @dev Data structs for {XWorldDCLevel} and {XWorldDCLevelPool}
 */
contract XWorldDCLevelStructs {

    /**
    * @dev Level asset which receive ticket income share in level pool, set level assets in {XWorldDCLevel} contract
    * with assetID and assetPoint, assetID is nft id of the asset, assetPoint use for calculate income share
    */
    struct LevelAsset{
        uint32 assetPoint;
        uint256 assetID;
    }
    struct LevelAssets{
        uint32 totalAssetPoint;
        LevelAsset[] assets;
    }

    /**
    * @dev asset award presents per asset award
    */
    struct AssetAward {
        uint256 assetID; 
        uint256 awardValue;
    }

    /**
    * @dev Level record presents levelPoint and levelAward for each level in a single levelRound, levelPoint is total
    * point and levelAward is total award for this level in the single round, help calculate level prize award
    */
    struct LevelRecord {
        uint256 levelPoint;
        uint256 levelAward;
    }

    /**
    * @dev Level round in a time period conception, count by blocks, token awards in level pool will calculate in each round,
    * level prize will be sent to user in certain round, and can be opened 1 round forward.
    */
    struct LevelRound {
        mapping(uint32 => LevelRecord) levelRecords;
        uint256 roundTotalAwards;
        uint256 roundDispatchedAwards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;
import "hardhat/console.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

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

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

import "./SerialityUtility.sol";

library SerialityBuffer {

    struct Buffer{
        uint index;
        bytes buffer;
    }

    function _checkSpace(SerialityBuffer.Buffer memory _buf, uint size) private pure returns(bool) {
        return (_buf.index >= size && _buf.index >= 32);
    }

    function enlargeBuffer(SerialityBuffer.Buffer memory _buf, uint size) internal pure {
        _buf.buffer = new bytes(size);
        _buf.index = size;
    }
    function setBuffer(SerialityBuffer.Buffer memory _buf, bytes memory buffer) internal pure {
        _buf.buffer = buffer;
    }
    function getBuffer(SerialityBuffer.Buffer memory _buf) internal pure returns(bytes memory) {
        return _buf.buffer;
    }

    // writers
    function writeAddress(SerialityBuffer.Buffer memory _buf, address _input) internal pure {
        uint size = SerialityUtility.sizeOfAddress();
        require(_checkSpace(_buf, size), "writeAddress  Seriality: write buffer size not enough");

        SerialityUtility.addressToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    function writeString(SerialityBuffer.Buffer memory _buf, string memory _input) internal pure {
        uint size = SerialityUtility.sizeOfString(_input);
        require(_checkSpace(_buf, size), "writeString   Seriality: write buffer size not enough");

        SerialityUtility.stringToBytes(_buf.index, bytes(_input), _buf.buffer);
        _buf.index -= size;
    }

    function writeBool(SerialityBuffer.Buffer memory _buf, bool _input) internal pure {
        uint size = SerialityUtility.sizeOfBool();
        require(_checkSpace(_buf, size), "writeBool Seriality: write buffer size not enough");

        SerialityUtility.boolToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    function writeInt8(SerialityBuffer.Buffer memory _buf, int8 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt8();
        require(_checkSpace(_buf, size), "writeInt8 Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeInt16(SerialityBuffer.Buffer memory _buf, int16 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt16();
        require(_checkSpace(_buf, size), "writeInt16    Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeInt32(SerialityBuffer.Buffer memory _buf, int32 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt32();
        require(_checkSpace(_buf, size), "writeInt32    Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeInt64(SerialityBuffer.Buffer memory _buf, int64 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt64();
        require(_checkSpace(_buf, size), "writeInt64    Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeInt128(SerialityBuffer.Buffer memory _buf, int128 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt128();
        require(_checkSpace(_buf, size), "writeInt128   Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    function writeInt256(SerialityBuffer.Buffer memory _buf, int256 _input) internal pure {
        uint size = SerialityUtility.sizeOfInt256();
        require(_checkSpace(_buf, size), "writeInt256   Seriality: write buffer size not enough");

        SerialityUtility.intToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    function writeUint8(SerialityBuffer.Buffer memory _buf, uint8 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint8();
        require(_checkSpace(_buf, size), "writeUint8    Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeUint16(SerialityBuffer.Buffer memory _buf, uint16 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint16();
        require(_checkSpace(_buf, size), "writeUint16   Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeUint32(SerialityBuffer.Buffer memory _buf, uint32 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint32();
        require(_checkSpace(_buf, size), "writeUint32   Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeUint64(SerialityBuffer.Buffer memory _buf, uint64 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint64();
        require(_checkSpace(_buf, size), "writeUint64   Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }
    
    function writeUint128(SerialityBuffer.Buffer memory _buf, uint128 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint128();
        require(_checkSpace(_buf, size), "writeUint128  Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    function writeUint256(SerialityBuffer.Buffer memory _buf, uint256 _input) internal pure {
        uint size = SerialityUtility.sizeOfUint256();
        require(_checkSpace(_buf, size), "writeUint256  Seriality: write buffer size not enough");

        SerialityUtility.uintToBytes(_buf.index, _input, _buf.buffer);
        _buf.index -= size;
    }

    // readers
    function readAddress(SerialityBuffer.Buffer memory _buf) internal pure returns(address) {
        uint size = SerialityUtility.sizeOfAddress();
        require(_checkSpace(_buf, size), "readAddress   Seriality: read buffer size not enough");

        address addr = SerialityUtility.bytesToAddress(_buf.index, _buf.buffer);
        _buf.index -= size;

        return addr;
    }
    
    function readString(SerialityBuffer.Buffer memory _buf) internal pure returns(string memory) {
        uint size = SerialityUtility.getStringSize(_buf.index, _buf.buffer);
        require(_checkSpace(_buf, size), "readString    Seriality: read buffer size not enough");

        string memory str = new string (size);
        SerialityUtility.bytesToString(_buf.index, _buf.buffer, bytes(str));
        _buf.index -= size;

        return str;
    }

    function readBool(SerialityBuffer.Buffer memory _buf) internal pure returns(bool) {
        uint size = SerialityUtility.sizeOfBool();
        require(_checkSpace(_buf, size), "readBool  Seriality: read buffer size not enough");

        bool b = SerialityUtility.bytesToBool(_buf.index, _buf.buffer);
        _buf.index -= size;

        return b;
    }

    function readInt8(SerialityBuffer.Buffer memory _buf) internal pure returns(int8) {
        uint size = SerialityUtility.sizeOfInt8();
        require(_checkSpace(_buf, size), "readInt8  Seriality: read buffer size not enough");

        int8 i = SerialityUtility.bytesToInt8(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readInt16(SerialityBuffer.Buffer memory _buf) internal pure returns(int16) {
        uint size = SerialityUtility.sizeOfInt16();
        require(_checkSpace(_buf, size), "readInt16 Seriality: read buffer size not enough");

        int16 i = SerialityUtility.bytesToInt16(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readInt32(SerialityBuffer.Buffer memory _buf) internal pure returns(int32) {
        uint size = SerialityUtility.sizeOfInt32();
        require(_checkSpace(_buf, size), "readInt32 Seriality: read buffer size not enough");

        int32 i = SerialityUtility.bytesToInt32(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readInt64(SerialityBuffer.Buffer memory _buf) internal pure returns(int64) {
        uint size = SerialityUtility.sizeOfInt64();
        require(_checkSpace(_buf, size), "readInt64 Seriality: read buffer size not enough");

        int64 i = SerialityUtility.bytesToInt64(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readInt128(SerialityBuffer.Buffer memory _buf) internal pure returns(int128) {
        uint size = SerialityUtility.sizeOfInt128();
        require(_checkSpace(_buf, size), "readInt128    Seriality: read buffer size not enough");

        int128 i = SerialityUtility.bytesToInt128(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }

    function readInt256(SerialityBuffer.Buffer memory _buf) internal pure returns(int256) {
        uint size = SerialityUtility.sizeOfInt256();
        require(_checkSpace(_buf, size), "readInt256    Seriality: read buffer size not enough");

        int256 i = SerialityUtility.bytesToInt256(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }

    function readUint8(SerialityBuffer.Buffer memory _buf) internal pure returns(uint8) {
        uint size = SerialityUtility.sizeOfUint8();
        require(_checkSpace(_buf, size), "readUint8 Seriality: read buffer size not enough");

        uint8 i = SerialityUtility.bytesToUint8(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readUint16(SerialityBuffer.Buffer memory _buf) internal pure returns(uint16) {
        uint size = SerialityUtility.sizeOfUint16();
        require(_checkSpace(_buf, size), "readUint16    Seriality: read buffer size not enough");

        uint16 i = SerialityUtility.bytesToUint16(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readUint32(SerialityBuffer.Buffer memory _buf) internal pure returns(uint32) {
        uint size = SerialityUtility.sizeOfUint32();
        require(_checkSpace(_buf, size), "readUint32    Seriality: read buffer size not enough");

        uint32 i = SerialityUtility.bytesToUint32(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readUint64(SerialityBuffer.Buffer memory _buf) internal pure returns(uint64) {
        uint size = SerialityUtility.sizeOfUint64();
        require(_checkSpace(_buf, size), "readUint64    Seriality: read buffer size not enough");

        uint64 i = SerialityUtility.bytesToUint64(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }
    
    function readUint128(SerialityBuffer.Buffer memory _buf) internal pure returns(uint128) {
        uint size = SerialityUtility.sizeOfUint128();
        require(_checkSpace(_buf, size), "readUint128   Seriality: read buffer size not enough");

        uint128 i = SerialityUtility.bytesToUint128(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }

    function readUint256(SerialityBuffer.Buffer memory _buf) internal pure returns(uint256) {
        uint size = SerialityUtility.sizeOfUint256();
        require(_checkSpace(_buf, size), "readUint256   Seriality: read buffer size not enough");

        uint256 i = SerialityUtility.bytesToUint256(_buf.index, _buf.buffer);
        _buf.index -= size;

        return i;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SerialityUtility {

    // size of
    
    function sizeOfString(string memory _in) internal pure  returns(uint _size){
        _size = bytes(_in).length / 32;
         if(bytes(_in).length % 32 != 0) 
            _size++;
            
        _size++; // first 32 bytes is reserved for the size of the string     
        _size *= 32;
    }

    // function sizeOfInt(uint16 _postfix) internal pure  returns(uint size){

    //     assembly{
    //         switch _postfix
    //             case 8 { size := 1 }
    //             case 16 { size := 2 }
    //             case 24 { size := 3 }
    //             case 32 { size := 4 }
    //             case 40 { size := 5 }
    //             case 48 { size := 6 }
    //             case 56 { size := 7 }
    //             case 64 { size := 8 }
    //             case 72 { size := 9 }
    //             case 80 { size := 10 }
    //             case 88 { size := 11 }
    //             case 96 { size := 12 }
    //             case 104 { size := 13 }
    //             case 112 { size := 14 }
    //             case 120 { size := 15 }
    //             case 128 { size := 16 }
    //             case 136 { size := 17 }
    //             case 144 { size := 18 }
    //             case 152 { size := 19 }
    //             case 160 { size := 20 }
    //             case 168 { size := 21 }
    //             case 176 { size := 22 }
    //             case 184 { size := 23 }
    //             case 192 { size := 24 }
    //             case 200 { size := 25 }
    //             case 208 { size := 26 }
    //             case 216 { size := 27 }
    //             case 224 { size := 28 }
    //             case 232 { size := 29 }
    //             case 240 { size := 30 }
    //             case 248 { size := 31 }
    //             case 256 { size := 32 }
    //             default  { size := 32 }
    //     }

    // }
    
    // function sizeOfUint(uint16 _postfix) internal pure  returns(uint size){
    //     return sizeOfInt(_postfix);
    // }

    function sizeOfInt8() internal pure  returns(uint size){
        return 1;
    }
    function sizeOfInt16() internal pure  returns(uint size){
        return 2;
    }
    function sizeOfInt24() internal pure  returns(uint size){
        return 3;
    }
    function sizeOfInt32() internal pure  returns(uint size){
        return 4;
    }
    // function sizeOfInt40() internal pure  returns(uint size){
    //     return 5;
    // }
    // function sizeOfInt48() internal pure  returns(uint size){
    //     return 6;
    // }
    // function sizeOfInt56() internal pure  returns(uint size){
    //     return 7;
    // }
    function sizeOfInt64() internal pure  returns(uint size){
        return 8;
    }
    // function sizeOfInt72() internal pure  returns(uint size){
    //     return 9;
    // }
    // function sizeOfInt80() internal pure  returns(uint size){
    //     return 10;
    // }
    // function sizeOfInt88() internal pure  returns(uint size){
    //     return 11;
    // }
    // function sizeOfInt96() internal pure  returns(uint size){
    //     return 12;
    // }
    // function sizeOfInt104() internal pure  returns(uint size){
    //     return 13;
    // }
    // function sizeOfInt112() internal pure  returns(uint size){
    //     return 14;
    // }
    // function sizeOfInt120() internal pure  returns(uint size){
    //     return 15;
    // }
    function sizeOfInt128() internal pure  returns(uint size){
        return 16;
    }
    // function sizeOfInt136() internal pure  returns(uint size){
    //     return 17;
    // }
    // function sizeOfInt144() internal pure  returns(uint size){
    //     return 18;
    // }
    // function sizeOfInt152() internal pure  returns(uint size){
    //     return 19;
    // }
    // function sizeOfInt160() internal pure  returns(uint size){
    //     return 20;
    // }
    // function sizeOfInt168() internal pure  returns(uint size){
    //     return 21;
    // }
    // function sizeOfInt176() internal pure  returns(uint size){
    //     return 22;
    // }
    // function sizeOfInt184() internal pure  returns(uint size){
    //     return 23;
    // }
    // function sizeOfInt192() internal pure  returns(uint size){
    //     return 24;
    // }
    // function sizeOfInt200() internal pure  returns(uint size){
    //     return 25;
    // }
    // function sizeOfInt208() internal pure  returns(uint size){
    //     return 26;
    // }
    // function sizeOfInt216() internal pure  returns(uint size){
    //     return 27;
    // }
    // function sizeOfInt224() internal pure  returns(uint size){
    //     return 28;
    // }
    // function sizeOfInt232() internal pure  returns(uint size){
    //     return 29;
    // }
    // function sizeOfInt240() internal pure  returns(uint size){
    //     return 30;
    // }
    // function sizeOfInt248() internal pure  returns(uint size){
    //     return 31;
    // }
    function sizeOfInt256() internal pure  returns(uint size){
        return 32;
    }
    
    function sizeOfUint8() internal pure  returns(uint size){
        return 1;
    }
    function sizeOfUint16() internal pure  returns(uint size){
        return 2;
    }
    function sizeOfUint24() internal pure  returns(uint size){
        return 3;
    }
    function sizeOfUint32() internal pure  returns(uint size){
        return 4;
    }
    // function sizeOfUint40() internal pure  returns(uint size){
    //     return 5;
    // }
    // function sizeOfUint48() internal pure  returns(uint size){
    //     return 6;
    // }
    // function sizeOfUint56() internal pure  returns(uint size){
    //     return 7;
    // }
    function sizeOfUint64() internal pure  returns(uint size){
        return 8;
    }
    // function sizeOfUint72() internal pure  returns(uint size){
    //     return 9;
    // }
    // function sizeOfUint80() internal pure  returns(uint size){
    //     return 10;
    // }
    // function sizeOfUint88() internal pure  returns(uint size){
    //     return 11;
    // }
    // function sizeOfUint96() internal pure  returns(uint size){
    //     return 12;
    // }
    // function sizeOfUint104() internal pure  returns(uint size){
    //     return 13;
    // }
    // function sizeOfUint112() internal pure  returns(uint size){
    //     return 14;
    // }
    // function sizeOfUint120() internal pure  returns(uint size){
    //     return 15;
    // }
    function sizeOfUint128() internal pure  returns(uint size){
        return 16;
    }
    // function sizeOfUint136() internal pure  returns(uint size){
    //     return 17;
    // }
    // function sizeOfUint144() internal pure  returns(uint size){
    //     return 18;
    // }
    // function sizeOfUint152() internal pure  returns(uint size){
    //     return 19;
    // }
    // function sizeOfUint160() internal pure  returns(uint size){
    //     return 20;
    // }
    // function sizeOfUint168() internal pure  returns(uint size){
    //     return 21;
    // }
    // function sizeOfUint176() internal pure  returns(uint size){
    //     return 22;
    // }
    // function sizeOfUint184() internal pure  returns(uint size){
    //     return 23;
    // }
    // function sizeOfUint192() internal pure  returns(uint size){
    //     return 24;
    // }
    // function sizeOfUint200() internal pure  returns(uint size){
    //     return 25;
    // }
    // function sizeOfUint208() internal pure  returns(uint size){
    //     return 26;
    // }
    // function sizeOfUint216() internal pure  returns(uint size){
    //     return 27;
    // }
    // function sizeOfUint224() internal pure  returns(uint size){
    //     return 28;
    // }
    // function sizeOfUint232() internal pure  returns(uint size){
    //     return 29;
    // }
    // function sizeOfUint240() internal pure  returns(uint size){
    //     return 30;
    // }
    // function sizeOfUint248() internal pure  returns(uint size){
    //     return 31;
    // }
    function sizeOfUint256() internal pure  returns(uint size){
        return 32;
    }

    function sizeOfAddress() internal pure  returns(uint8){
        return 20; 
    }
    
    function sizeOfBool() internal pure  returns(uint8){
        return 1; 
    }
    
    // to bytes
    
    function addressToBytes(uint _offst, address _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    }

    function bytes32ToBytes(uint _offst, bytes32 _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
            mstore(add(add(_output, _offst),32), add(_input,32))
        }
    }
    
    function boolToBytes(uint _offst, bool _input, bytes memory _output) internal pure {
        uint8 x = _input == false ? 0 : 1;
        assembly {
            mstore8(add(_output, _offst), x)
        }
    }
    
    function stringToBytes(uint _offst, bytes memory _input, bytes memory _output) internal pure {
        uint256 stack_size = _input.length / 32;
        if(_input.length % 32 > 0) stack_size++;
        
        assembly {
            stack_size := add(stack_size,1)//adding because of 32 first bytes memory as the length
            for { let index := 0 } lt(index,stack_size){ index := add(index ,1) } {
                mstore(add(_output, _offst), mload(add(_input,mul(index,32))))
                _offst := sub(_offst , 32)
            }
        }
    }

    function intToBytes(uint _offst, int _input, bytes memory  _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    } 
    
    function uintToBytes(uint _offst, uint _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    }   

    // bytes to

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
    function bytesToBool(uint _offst, bytes memory _input) internal pure returns (bool _output) {
        
        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x==0 ? _output = false : _output = true;
    }   
        
    function getStringSize(uint _offst, bytes memory _input) internal pure returns(uint size){
        
        assembly{
            
            size := mload(add(_input,_offst))
            let chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {// if size%32 > 0
                chunk_count := add(chunk_count,1)
            } 
            
             size := mul(chunk_count,32)// first 32 bytes reseves for size in strings
        }
    }

    function bytesToString(uint _offst, bytes memory _input, bytes memory _output) internal pure {

        uint size = 32;
        assembly {
            
            let chunk_count
            
            size := mload(add(_input,_offst))
            chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {
                chunk_count := add(chunk_count,1)  // chunk_count++
            }
               
            for { let index:= 0 }  lt(index , chunk_count){ index := add(index,1) } {
                mstore(add(_output,mul(index,32)),mload(add(_input,_offst)))
                _offst := sub(_offst,32)           // _offst -= 32
            }
        }
    }

    function bytesToBytes32(uint _offst, bytes memory  _input, bytes32 _output) internal pure {
        
        assembly {
            mstore(_output , add(_input, _offst))
            mstore(add(_output,32) , add(add(_input, _offst),32))
        }
    }
    
    function bytesToInt8(uint _offst, bytes memory  _input) internal pure returns (int8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
    
    function bytesToInt16(uint _offst, bytes memory _input) internal pure returns (int16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt24(uint _offst, bytes memory _input) internal pure returns (int24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt32(uint _offst, bytes memory _input) internal pure returns (int32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    // function bytesToInt40(uint _offst, bytes memory _input) internal pure returns (int40 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt48(uint _offst, bytes memory _input) internal pure returns (int48 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt56(uint _offst, bytes memory _input) internal pure returns (int56 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    function bytesToInt64(uint _offst, bytes memory _input) internal pure returns (int64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    // function bytesToInt72(uint _offst, bytes memory _input) internal pure returns (int72 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt80(uint _offst, bytes memory _input) internal pure returns (int80 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt88(uint _offst, bytes memory _input) internal pure returns (int88 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt96(uint _offst, bytes memory _input) internal pure returns (int96 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }
	
	// function bytesToInt104(uint _offst, bytes memory _input) internal pure returns (int104 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }
    
    // function bytesToInt112(uint _offst, bytes memory _input) internal pure returns (int112 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt120(uint _offst, bytes memory _input) internal pure returns (int120 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    function bytesToInt128(uint _offst, bytes memory _input) internal pure returns (int128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    // function bytesToInt136(uint _offst, bytes memory _input) internal pure returns (int136 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt144(uint _offst, bytes memory _input) internal pure returns (int144 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt152(uint _offst, bytes memory _input) internal pure returns (int152 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt160(uint _offst, bytes memory _input) internal pure returns (int160 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt168(uint _offst, bytes memory _input) internal pure returns (int168 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt176(uint _offst, bytes memory _input) internal pure returns (int176 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt184(uint _offst, bytes memory _input) internal pure returns (int184 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt192(uint _offst, bytes memory _input) internal pure returns (int192 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt200(uint _offst, bytes memory _input) internal pure returns (int200 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt208(uint _offst, bytes memory _input) internal pure returns (int208 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt216(uint _offst, bytes memory _input) internal pure returns (int216 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt224(uint _offst, bytes memory _input) internal pure returns (int224 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt232(uint _offst, bytes memory _input) internal pure returns (int232 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt240(uint _offst, bytes memory _input) internal pure returns (int240 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    // function bytesToInt248(uint _offst, bytes memory _input) internal pure returns (int248 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // }

    function bytesToInt256(uint _offst, bytes memory _input) internal pure returns (int256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint24(uint _offst, bytes memory _input) internal pure returns (uint24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint32(uint _offst, bytes memory _input) internal pure returns (uint32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	// function bytesToUint40(uint _offst, bytes memory _input) internal pure returns (uint40 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	// function bytesToUint48(uint _offst, bytes memory _input) internal pure returns (uint48 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	// function bytesToUint56(uint _offst, bytes memory _input) internal pure returns (uint56 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	function bytesToUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	// function bytesToUint72(uint _offst, bytes memory _input) internal pure returns (uint72 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	// function bytesToUint80(uint _offst, bytes memory _input) internal pure returns (uint80 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	// function bytesToUint88(uint _offst, bytes memory _input) internal pure returns (uint88 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

	// function bytesToUint96(uint _offst, bytes memory _input) internal pure returns (uint96 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 
	
	// function bytesToUint104(uint _offst, bytes memory _input) internal pure returns (uint104 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint112(uint _offst, bytes memory _input) internal pure returns (uint112 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint120(uint _offst, bytes memory _input) internal pure returns (uint120 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    function bytesToUint128(uint _offst, bytes memory _input) internal pure returns (uint128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    // function bytesToUint136(uint _offst, bytes memory _input) internal pure returns (uint136 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint144(uint _offst, bytes memory _input) internal pure returns (uint144 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint152(uint _offst, bytes memory _input) internal pure returns (uint152 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint160(uint _offst, bytes memory _input) internal pure returns (uint160 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint168(uint _offst, bytes memory _input) internal pure returns (uint168 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint176(uint _offst, bytes memory _input) internal pure returns (uint176 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint184(uint _offst, bytes memory _input) internal pure returns (uint184 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint192(uint _offst, bytes memory _input) internal pure returns (uint192 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint200(uint _offst, bytes memory _input) internal pure returns (uint200 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint208(uint _offst, bytes memory _input) internal pure returns (uint208 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint216(uint _offst, bytes memory _input) internal pure returns (uint216 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint224(uint _offst, bytes memory _input) internal pure returns (uint224 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint232(uint _offst, bytes memory _input) internal pure returns (uint232 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint240(uint _offst, bytes memory _input) internal pure returns (uint240 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    // function bytesToUint248(uint _offst, bytes memory _input) internal pure returns (uint248 _output) {
        
    //     assembly {
    //         _output := mload(add(_input, _offst))
    //     }
    // } 

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
}

// contracts/TransferHelper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// contracts/XWorldRandom.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXWorldOracleRandComsumer {
    function oracleRandResponse(uint256 reqid, uint256 randnum) external;
}

interface IXWorldRandom {
    function seedRand(uint256 inputSeed) external returns(uint256 ret);
    function sealedRand() external returns(uint256 ret);
    function setSealed() external;
    function oracleRand() external returns (uint256 reqid);
    function nextRand(uint32 index, uint256 randomNum) external view returns(uint256 ret);
}

// contracts/XWorldAvatarMBRandomSource.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../Seriality/Seriality_1_0/SerialityUtility.sol";
import "../Seriality/Seriality_1_0/SerialityBuffer.sol";

import "../MysteryBoxes/XWorldMBRandomSourceBase.sol";
import "../MysteryBoxes/XWorldMysteryBoxBase.sol";

import "../MBShop/XWorldMysteryBoxShop.sol";

import "./XWorldDCEquip.sol";

contract XWorldDCEquipMBStruct {
    using SerialityBuffer for SerialityBuffer.Buffer;

    struct DCEquipMBData {
        uint8 equip;
        uint8 role;
        uint8 grade;
        uint256 __end; // take position, not used
    }

    function _writeDCEquipMBData(DCEquipMBData memory mbdata) internal pure returns(bytes memory bytesdata) {
        // encode

        uint32 size = 1 + 1 + 1 + 32; // uint8 + uint8 + uint8 + uint256
        bytes memory buf = new bytes(size);

        SerialityBuffer.Buffer memory coder = SerialityBuffer.Buffer({
            index:size,
            buffer:buf
        });
        
        coder.writeUint8(mbdata.equip);
        coder.writeUint8(mbdata.role);
        coder.writeUint8(mbdata.grade);
        coder.writeUint256(mbdata.__end);

        return coder.getBuffer();
    }
    function _readDCEquipMBData(bytes memory bytesdata) internal pure returns(DCEquipMBData memory mbdata) {
        // decode
        
        SerialityBuffer.Buffer memory coder = SerialityBuffer.Buffer({
            index:bytesdata.length,
            buffer:bytesdata
        });

        mbdata.equip = coder.readUint8();
        mbdata.role = coder.readUint8();
        mbdata.grade = coder.readUint8();
        //mbdata.__end = coder.readUint256();
        
        return mbdata;
    }
}

contract XWorldDCEquipMBRandomSource is XWorldMBRandomSourceBase, XWorldDCEquipMBStruct {
    using XWorldRandomPool for XWorldRandomPool.RandomPool;

    constructor() XWorldMBRandomSourceBase() {

    }

    function randomNFTData(uint256 r, uint32 mbTypeID) override external view returns(bytes memory structDatas) {

        uint32[] storage poolIDArray = _mbRandomSets[mbTypeID];

        require(poolIDArray.length == 3, "mb type config wrong");

        NFTRandPool storage equipPool = _randPools[poolIDArray[0]]; // index 0 : equip pool
        require(equipPool.exist, "equip pool not exist");

        NFTRandPool storage rolePool = _randPools[poolIDArray[1]]; // index 1 : role pool
        require(rolePool.exist, "role pool not exist");

        NFTRandPool storage gradePool = _randPools[poolIDArray[2]]; // index 2 : grade pool
        require(gradePool.exist, "grade pool not exist");

        uint32 index = 0;
        DCEquipMBData memory mbdata;

        //r = _rand.nextRand(++index, r);
        mbdata.equip = uint8(equipPool.randPool.random(r)); // rand equip

        r = _rand.nextRand(++index, r);
        mbdata.role = uint8(rolePool.randPool.random(r)); // rand role

        r = _rand.nextRand(++index, r);
        mbdata.grade = uint8(gradePool.randPool.random(r)); // rand grade

        return _writeDCEquipMBData(mbdata);
    }
}

contract XWorldDCEquipMBContentMinter is 
    Context, 
    AccessControl,
    XWorldDCEquipMBStruct,
    XWorldDCEquipStruct,
    IXWorldMysteryBoxContentMinter
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    XWorldDCEquip public _equipNFTContract;

    constructor(address nftAddr) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _equipNFTContract = XWorldDCEquip(nftAddr);
    }

    function mintContentAssets(address userAddr, uint256 mbTokenId, bytes memory nftDatas) override external returns(uint256 tokenId){
        require(hasRole(MINTER_ROLE, _msgSender()), "XWorldDCEquipMBContentMinter: must have minter role to mint");

        mbTokenId; // not used

        DCEquipMBData memory mbdata = _readDCEquipMBData(nftDatas);
        
        EquipData memory eqpdata = EquipData({
            equip: mbdata.equip,
            role: mbdata.role,
            grade: mbdata.grade,
            level: 1,
            exp: 0
        });

        return _equipNFTContract.mint(userAddr, eqpdata);
    }
} 

contract XWorldDCEquipMBMinter is 
    Context, 
    AccessControl,
    IMysterBoxNFTMinter
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    XWorldMysteryBoxNFT public _nftContract;

    constructor(address nftAddr) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _nftContract = XWorldMysteryBoxNFT(nftAddr);
    }

    function mintNFT(address to, uint32 mysteryBoxType, uint32 mysteryBoxTypeId) override external returns(uint256 nftID) {
        require(hasRole(MINTER_ROLE, _msgSender()), "XWorldAvatarMBMinter: must have minter role to mint");

        return _nftContract.mint(to, mysteryBoxType, mysteryBoxTypeId);
    }

    function batchMintNFT(address to, uint32 mysteryBoxType, uint32 mysteryBoxTypeId, uint32 count) override external returns(uint256[] memory nftID) {

        XWorldMysteryBoxNFTMintOption[] memory ops = new XWorldMysteryBoxNFTMintOption[](count);
        for(uint i=0; i< count; ++i){
            ops[i] = XWorldMysteryBoxNFTMintOption({
                to: to,
                mbType: mysteryBoxType,
                mbTypeId: mysteryBoxTypeId
            });
        }
        return _nftContract.batchMint(ops);
    }
}

// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

import "../XWorldNFT.sol";

import "./XWorldDCLevelPool_0_1.sol";
import "./XWorldDCLevelPrize.sol";
import "./XWorldDCLevelStructs.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract XWorldDCLevel_0_1 is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC1967UpgradeUpgradeable,
    XWorldDCLevelStructs
{
    /**
    * @dev Ticket share is use by {XWorldDCLevel} for ticket income split
    */
    struct TicketShare {
        uint32 levelPool;
        uint32 lotteryPool;
        uint32 assetAward;
        uint32 teamRevenue;
        uint32 total;
    }

    /**
    * @dev Level pool base share is use by {XWorldDCLevel}, split level pool for each level by share
    */
    struct LevelPoolBaseShare {
        uint32 levelID;
        uint32 share;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant LEVEL_ROLE = keccak256("LEVEL_ROLE");

    event XWorldDCLevelEnterLevel(uint32 indexed levelID, address indexed userAddr);
    event XWorldDCLevelFinishLevel(
        uint32 indexed levelID,
        address indexed userAddr,
        uint32 winPoint,
        uint256 gotnftid
    );
    event XWorldDCLevelAssetChange(uint32 indexed levelID, LevelAsset[] assets);
    event XWorldDCLevelTicketPriceChange(
        uint32 indexed levelID,
        uint256 ticketPrice
    );
    event XWorldDCLevelTicketShareChange(TicketShare ticketShare);
    event XWorldDCLevelSharePoolIncome(
        uint32[] levelIds,
        uint256[] levelShareRates,
        uint256[] levelShares
    );
    event XWorldDCLevelSplitIncome(
        uint256 ticketIncome,
        uint256 poolIncome,
        uint256 levelPoolShare,
        uint256 lotteryPoolShare,
        uint256 teamShare,
        uint256 assetAwardShare
    );
    event XWorldDCLevelRoundFinish(uint256 round, uint256 totalAwards);

    XWorldDCLevelPool_0_1 public _levelPool;
    XWorldNFT public _levelPrizeNFT;

    mapping(uint256 => bool) private _userInLevel; // key : uint256(keccak256(abi.encodePacked(userAddr, levelID)));
    mapping(uint32 => uint256) public _ticketPrice; // key : levelID
    mapping(uint32 => LevelAssets) public _levelAssets; // key : levelID
    mapping(uint32 => uint32) public _levelWinPoints; // key : levelID

    TicketShare public _ticketShare;

    uint256 public _blocksPerRound;
    uint256 public _lastBlockNumber;
    uint256 public _currentRoundNumber;

    mapping(uint32 => uint32) public _levelPoolBaseShare; // key : levelID, value : level share

    uint32 public _levelRoundRatio;
    uint256 public _levelRoundPoolMaxOnRatio;

    constructor() {
    }

    function getVersion() public pure returns (string memory) {
        return "0.1";
    }

    //use initializer to limit call once
    //initializer store in proxy ,so only first contract call this
    function initialize() public initializer {
        __Context_init_unchained();

        __Pausable_init_unchained();

        __AccessControl_init_unchained();
        __ERC1967Upgrade_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(LEVEL_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "XWorldDCLevel: must have pauser role to unpause"
        );
        _unpause();
    }

    function setLevelPoolAddress(address levelPool) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPool = XWorldDCLevelPool_0_1(levelPool);
    }

    function setLevelPrizeNftAddress(address levelPrize) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _levelPrizeNFT = XWorldNFT(levelPrize);
    }

    function setBlocksPerRound(uint256 blocksPerRound) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        require(
            _currentRoundNumber == 0,
            "XWorldDCLevel: already set blocks per round"
        );

        _blocksPerRound = blocksPerRound;

        _lastBlockNumber = (block.number / _blocksPerRound) * _blocksPerRound;
        _currentRoundNumber = 1;
    }

    function setCurrentRoundNumber(uint256 lastBlockNumber, uint256 currentRoundNumber) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        _lastBlockNumber = lastBlockNumber;
        _currentRoundNumber = currentRoundNumber;
    }

    function setLevelPoolBaseShare(LevelPoolBaseShare[] calldata baseShares) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        for(uint i= 0; i< baseShares.length; ++i) {
            _levelPoolBaseShare[baseShares[i].levelID] = baseShares[i].share;
        }
    }

    // level round ratio, each round will give away levelPool*ratio/10000 for award
    function setLevelRoundRatio(uint32 ratio) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevel: must have manager role");
        _levelRoundRatio = ratio;
    }

    function setLevelRoundPoolMaxOnRatio(uint256 poolMax) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldDCLevel: must have manager role");
        _levelRoundPoolMaxOnRatio = poolMax;
    }

    /**
     * @dev Entering level, call by user, cost token to enter level
     *
     * Emits an {XWorldDCLevelEnterLevel} event.
     *
     * Requirements:
     * - caller address not in level
     * - {XWorldDCLevelPool} must have allowance for caller's tokens of at least `ticketPrice`.
     *
     * @param levelID to enter level id
     */
    function enterLevel(uint32 levelID) external whenNotPaused {
        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(_msgSender(), levelID))
        );
        require(
            !_userInLevel[userLevelKey],
            "XWorldDCLevel: user already in level"
        );

        uint256 ticketPrice = getTicketPrice(levelID);
        require(ticketPrice > 0, "XWorldDCLevel: ticket price wrong");

        bool ret = _levelPool.buyTicket(levelID, _msgSender(), ticketPrice);
        require(ret, "XWorldDCLevel: buy ticket failed!");

        _userInLevel[userLevelKey] = true;

        emit XWorldDCLevelEnterLevel(levelID, _msgSender());
    }

    /**
     * @dev Finishing level, call by service, finish level and give prize nft
     *
     * Emits an {XWorldDCLevelFinishLevel} event.
     *
     * Requirements:
     * - `userAddr` in level
     * - caller must have `LEVEL_ROLE`
     *
     * @param levelID to finish level id
     * @param userAddr from which user address
     * @param winPoint winPoint > 0 means win, otherwise failed
     */
    function finishLevel(
        uint32 levelID,
        address userAddr,
        uint32 winPoint
    ) external whenNotPaused {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );

        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(userAddr, levelID))
        );
        require(_userInLevel[userLevelKey], "XWorldDCLevel: user not in level");
        uint256 nftid = 0;
        if (winPoint > 0) {
            nftid = _levelPrizeNFT.mint(
                userAddr,
                levelID,
                winPoint,
                _currentRoundNumber,
                new bytes(0)
            ); // win

            _levelWinPoints[levelID] += winPoint;
        }

        delete _userInLevel[userLevelKey];

        emit XWorldDCLevelFinishLevel(levelID, userAddr, winPoint, nftid);
    }

    /**
     * @dev Check is user in level
     *
     * @param levelID to check level id
     * @param userAddr from which user address
     */
    function isInLevel(uint32 levelID, address userAddr)
        external
        view
        returns (bool inLevel)
    {
        uint256 userLevelKey = uint256(
            keccak256(abi.encodePacked(userAddr, levelID))
        );
        return _userInLevel[userLevelKey];
    }

    /**
     * @dev get current level round index
     *
     * @return round index
     */
    function getCurrentLevelRound() external view returns (uint256 round) {
        return _currentRoundNumber;
    }

    // call by service, get unshared level ticket income and split them into each share
    function spliteLevelsIncom(uint32[] calldata levelIDs)
        external
        whenNotPaused
    {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );

        // calculate pool share
        uint256 totalPoolBaseShare = 0;
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            require(_levelPoolBaseShare[levelIDs[i]] != 0, "XWorldDCLevel: need set level pool share");
            totalPoolBaseShare += _levelPoolBaseShare[levelIDs[i]];
        }

        uint256[] memory poolShareRate = new uint256[](levelIDs.length);
        uint256 totalPoolShareRate = 0;

        uint256 totalTicketIncome = _levelPool._unshareLevelTicketIncomeTotal();
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint256 levelTicketIncome = _levelPool.getUnshareTicketIncome(levelIDs[i]);

            // ticket income define 50% share, pool base share define other 50% share
            uint256 share = (1000000 * levelTicketIncome / totalTicketIncome) + (1000000 * _levelPoolBaseShare[levelIDs[i]] / totalPoolBaseShare);
            poolShareRate[i] = share;
            totalPoolShareRate += share;
        }

        // fetch genesis pool mining income
        uint256 poolIncome = _levelPool.transferGenesisPoolToken();

        uint256 totalTeamShare = 0;
        uint256 totalLotteryShare = 0;

        // split income
        uint256[] memory poolShares = new uint256[](levelIDs.length);
        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint256 perLevelPoolIncome = poolIncome * poolShareRate[i] / totalPoolShareRate;
            poolShares[i] = levelIDs[i];

            uint256 teamShare;
            uint256 lotteryPoolShare;

            (teamShare, lotteryPoolShare) = _splitLevelIncome(levelIDs[i], perLevelPoolIncome);

            totalTeamShare += teamShare;
            totalLotteryShare += lotteryPoolShare;
        }

        // fill team pool
        _levelPool.fillTeamRevenue(totalTeamShare);

        // fill lottery pool
        _levelPool.fillLotteryPool(totalLotteryShare);

        emit XWorldDCLevelSharePoolIncome(levelIDs, poolShareRate, poolShares);
    }

    function _splitLevelIncome(uint32 levelID, uint256 poolIncome)
        internal
        whenNotPaused
        returns (uint256 teamShare, uint256 lotteryPoolShare)
    {
        uint256 ticketIncome = _levelPool.getUnshareTicketIncome(levelID);
        require(
            ticketIncome + poolIncome > 100 * 10**18, // TO DO : set smallest income
            "XWorldDCLevel: income too small"
        );
        // clear unshare income
        _levelPool.clearUnshareTicketIncome(levelID);

        // split ticket income into levelPool/lotteryPool/assetAward
        uint256 levelPoolShare = (ticketIncome * _ticketShare.levelPool) /
            _ticketShare.total;
        uint256 assetAwardShare = (ticketIncome * _ticketShare.assetAward) /
            _ticketShare.total;
        teamShare = (ticketIncome * _ticketShare.teamRevenue) /
            _ticketShare.total;

        LevelAssets memory levelAsts = _levelAssets[levelID];

        if (levelAsts.totalAssetPoint > 0) {
            AssetAward[] memory astAwards = new AssetAward[](
                levelAsts.assets.length
            );

            for (uint256 i = 0; i < levelAsts.assets.length; ++i) {
                astAwards[i].assetID = levelAsts.assets[i].assetID;
                astAwards[i].awardValue =
                    (assetAwardShare * levelAsts.assets[i].assetPoint) /
                    levelAsts.totalAssetPoint;
            }

            // give award
            _levelPool.giveAssetAward(astAwards);
        } else {
            // give back to level pool
            levelPoolShare += assetAwardShare;
            assetAwardShare = 0;
        }
        // fill level pool
        _levelPool.fillLevelPool(levelID, levelPoolShare + poolIncome); // pool income goes to level pool

        // lottery share
        lotteryPoolShare = ticketIncome -
            levelPoolShare -
            teamShare -
            assetAwardShare;

        // fill team pool
        //_levelPool.fillTeamRevenue(teamShare);
        // fill lottery pool
        //_levelPool.fillLotteryPool(lotteryPoolShare);

        emit XWorldDCLevelSplitIncome(
            ticketIncome,
            poolIncome,
            levelPoolShare,
            lotteryPoolShare,
            teamShare,
            assetAwardShare
        );
    }

    // call by service, finish current round and calculate round rewards.
    function calcLevelRound(uint32[] calldata levelIDs) external whenNotPaused {
        require(
            hasRole(LEVEL_ROLE, _msgSender()),
            "XWorldDCLevel: must have level role"
        );
        require(
            _lastBlockNumber + _blocksPerRound <= block.number,
            "XWorldDCLevel: round not finish yet"
        );

        uint256 pt = _levelPool._levelPoolTotal();
        uint32 levelRoundRatio = 0;
        if(pt < _levelRoundPoolMaxOnRatio) {
            levelRoundRatio = uint32(_levelRoundRatio * pt / _levelRoundPoolMaxOnRatio);
        }
        else {
            levelRoundRatio = _levelRoundRatio;
        }

        _lastBlockNumber = _lastBlockNumber + _blocksPerRound;

        for (uint256 i = 0; i < levelIDs.length; ++i) {
            uint32 levelID = levelIDs[i];

            if (_levelWinPoints[levelID] <= 0) {
                continue;
            }

            _levelPool.setLevelRound(
                _currentRoundNumber,
                levelID,
                _levelWinPoints[levelID],
                levelRoundRatio
            );
        }

        uint256 totalAwards;
        (totalAwards, ) = _levelPool.getLevelRoundStates(_currentRoundNumber);
        emit XWorldDCLevelRoundFinish(_currentRoundNumber, totalAwards);

        ++_currentRoundNumber;
    }

    function getTicketPrice(uint32 levelID)
        public
        view
        returns (uint256 ticketPrice)
    {
        return _ticketPrice[levelID];
    }

    function setTicketPrice(uint32 levelID, uint256 ticketPrice) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );
        _ticketPrice[levelID] = ticketPrice;

        emit XWorldDCLevelTicketPriceChange(levelID, ticketPrice);
    }

    function setTicketShare(
        uint32 levelPool,
        uint32 lotteryPool,
        uint32 assetAward,
        uint32 teamRevenue
    ) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        _ticketShare.assetAward = assetAward;
        _ticketShare.levelPool = levelPool;
        _ticketShare.lotteryPool = lotteryPool;
        _ticketShare.teamRevenue = teamRevenue;
        _ticketShare.total = assetAward + levelPool + lotteryPool + teamRevenue;

        emit XWorldDCLevelTicketShareChange(_ticketShare);
    }

    function modifyLevelAssets(uint32 levelID, LevelAsset[] calldata assets)
        external
    {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "XWorldDCLevel: must have manager role"
        );

        LevelAssets storage asts = _levelAssets[levelID];

        //asts.assets = new LevelAsset[](assets.length);
        //**LevelAsset[] have dynamic memory size,can not be copy to storage.

        delete asts.assets; //resize to 0 element;

        for (uint256 i = 0; i < assets.length; ++i) {
            LevelAsset memory src = assets[i];
            //LevelAsset have fix size，can copy to storage
            asts.assets.push(src);
            //asts.assets[i].assetID = assets[i].assetID;
            //asts.assets[i].assetPoint = assets[i].assetPoint;
            asts.totalAssetPoint += assets[i].assetPoint;
        }

        emit XWorldDCLevelAssetChange(levelID, assets);
    }

    function getLevelAssets(uint32 levelID)
        external
        view
        returns (LevelAsset[] memory assets)
    {
        return _levelAssets[levelID].assets;
    }
}

// contracts/XWorldAvatarMBRandomSource.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../Utility/XWorldRandom.sol";
import "../Utility/XWorldRandomPool.sol";

abstract contract XWorldMBRandomSourceBase is 
    Context, 
    AccessControl
{
    using XWorldRandomPool for XWorldRandomPool.RandomPool;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RANDOM_ROLE = keccak256("RANDOM_ROLE");

    struct NFTRandPool{
        bool exist;
        XWorldRandomPool.RandomPool randPool;
    }

    IXWorldRandom _rand;
    mapping(uint32 => NFTRandPool)    _randPools; // poolID => nft data random pools
    mapping(uint32 => uint32[])       _mbRandomSets; // mbTypeID => poolID array

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RANDOM_ROLE, _msgSender());
    }

    function setRandSource(address randAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()));

        _rand = IXWorldRandom(randAddr);
    }

    function getRandSource() external view returns(address) {
        // require(hasRole(MANAGER_ROLE, _msgSender()));
        return address(_rand);
    }
    function _addPool(uint32 poolID, XWorldRandomPool.RandomSet[] memory randSetArray) internal {
        NFTRandPool storage rp = _randPools[poolID];

        rp.exist = true;
        for(uint i=0; i<randSetArray.length; ++i){
            rp.randPool.pool.push(randSetArray[i]);
        }

        rp.randPool.initRandomPool();
    }

    function addPool(uint32 poolID, XWorldRandomPool.RandomSet[] memory randSetArray) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(!_randPools[poolID].exist,"rand pool already exist");

        _addPool(poolID, randSetArray);
    }

    function modifyPool(uint32 poolID, XWorldRandomPool.RandomSet[] memory randSetArray) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(_randPools[poolID].exist,"rand pool not exist");

        NFTRandPool storage rp = _randPools[poolID];

        delete rp.randPool.pool;

        for(uint i=0; i<randSetArray.length; ++i){
            rp.randPool.pool.push(randSetArray[i]);
        }

        rp.randPool.initRandomPool();
    }

    function removePool(uint32 poolID) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(_randPools[poolID].exist, "rand pool not exist");

        delete _randPools[poolID];
    }

    function getPool(uint32 poolID) public view returns(NFTRandPool memory) {
        require(_randPools[poolID].exist, "rand pool not exist");

        return _randPools[poolID];
    }

    function hasPool(uint32 poolID) external view returns(bool){
          return (_randPools[poolID].exist);
    }

    function setRandomSet(uint32 mbTypeID, uint32[] calldata poolIds) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");

        uint32[] storage poolIDArray = _mbRandomSets[mbTypeID];
        for(uint i=0; i< poolIds.length; ++i){
            poolIDArray.push(poolIds[i]);
        }
    }
    function unsetRandomSet(uint32 mbTypeID) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");

        delete _mbRandomSets[mbTypeID];
    }
    function getRandomSet(uint32 mbTypeID) external view returns(uint32[] memory poolIds) {
        return _mbRandomSets[mbTypeID];
    }
    
    function randomNFTData(uint256 r, uint32 mbTypeID) virtual external view returns(bytes memory structDatas);
}

// contracts/XWorldMysteryBox.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../Utility/IXWorldRandom.sol";
import "./XWorldMysteryBoxNFT.sol";
import "./XWorldMBRandomSourceBase.sol";

interface IXWorldMysteryBoxContentMinter {
    function mintContentAssets(address userAddr, uint256 mbTokenId, bytes memory nftDatas) external returns(uint256 tokenId);
}

contract XWorldMysteryBoxBase is 
    Context, 
    Pausable, 
    AccessControl,
    IXWorldOracleRandComsumer
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RAND_ROLE = keccak256("RAND_ROLE");

    event XWorldOracleOpenMysteryBox(uint256 oracleRequestId, uint256 indexed mbTokenId, address owner);
    event XWorldOpenMysteryBox(uint256 indexed mbTokenId, uint256 indexed newTokenId, bytes nftData);

    struct MysteryBoxNFTData{
        address owner;
        uint32 mbType;
        uint32 mbTypeId;
    }
    struct UserData{
        uint256 tokenId;
        uint256 lockTime;
    }
    
    XWorldMysteryBoxNFT public _mbNFT;
    IXWorldMysteryBoxContentMinter public _minter;
    
    mapping(uint256 => MysteryBoxNFTData) _burnedTokens;
    mapping(uint32=>address) _randomDataSources; // indexed by mystery box type mbType
    mapping(uint256 => UserData) public _oracleUserData; // indexed by oracle request id

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RAND_ROLE, _msgSender());
    }

    function setNftAddress(address nftAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBox: must have manager role to manage");
        _mbNFT = XWorldMysteryBoxNFT(nftAddr);
    }

    function getNftAddress() external view returns(address) {
        return address(_mbNFT);
    }
    
    function setMysteryBoxContentMinter(address minter) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBox: must have manager role to manage");
        _minter = IXWorldMysteryBoxContentMinter(minter);
    }

    function setRandomSource(uint32 nftType, address randomSrc) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBox: must have manager role to manage");
        _randomDataSources[nftType] = randomSrc;
    }

    function getRandomSource(uint32 nftType) external view returns(address){
        return _randomDataSources[nftType];
    }

    // request from user
    function oracleOpenMysteryBox(uint256 tokenId) external whenNotPaused {
        require(tx.origin == _msgSender(), "XWorldMysteryBox: only for outside account");
        require(_mbNFT.notFreezed(tokenId), "XWorldMysteryBox: freezed token");
        require(_mbNFT.ownerOf(tokenId) == _msgSender(), "XWorldMysteryBox: ownership check failed");

        MysteryBoxNFTData storage nftData = _burnedTokens[tokenId];
        nftData.owner = _msgSender();
        (nftData.mbType, nftData.mbTypeId) = _mbNFT.getMysteryBoxData(tokenId);
        
        address randSrcAddr = _randomDataSources[nftData.mbType];
        require(randSrcAddr != address(0), "XWorldMysteryBox: not a mystry box");
        
        address rndAddr = XWorldMBRandomSourceBase(randSrcAddr).getRandSource();
        require(rndAddr != address(0), "XWorldMysteryBox: rand address wrong");

        _mbNFT.burn(tokenId);
        require(!_mbNFT.exists(tokenId), "XWorldMysteryBox: burn mystery box failed");

        uint256 reqid = IXWorldRandom(rndAddr).oracleRand();

        UserData storage userData = _oracleUserData[reqid];
        userData.tokenId = tokenId;
        userData.lockTime = block.timestamp;
        
        emit XWorldOracleOpenMysteryBox(reqid, tokenId, _msgSender());
    }

    // call back from random contract which triger by service call {fulfillOracleRand} function
    function oracleRandResponse(uint256 reqid, uint256 randnum) override external {
        require(hasRole(RAND_ROLE, _msgSender()), "XWorldMysteryBox: must have rand role");

        UserData storage userData = _oracleUserData[reqid];
        MysteryBoxNFTData storage nftData = _burnedTokens[userData.tokenId];

        require(nftData.owner != address(0), "XWorldMysteryBox: nftdata owner not exist");

        address randSrcAddr = _randomDataSources[nftData.mbType];
        require(randSrcAddr != address(0), "XWorldMysteryBox: not a mystry box");

        address rndAddr = XWorldMBRandomSourceBase(randSrcAddr).getRandSource();
        require(rndAddr != address(0), "XWorldMysteryBox: rand address wrong");

        bytes memory contentNFTDatas = XWorldMBRandomSourceBase(randSrcAddr).randomNFTData(randnum, nftData.mbTypeId);
        uint256 newTokenId = _minter.mintContentAssets(nftData.owner, userData.tokenId, contentNFTDatas);

        delete _oracleUserData[reqid];
        delete _burnedTokens[userData.tokenId];

        emit XWorldOpenMysteryBox(userData.tokenId, newTokenId, contentNFTDatas);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XWorldMysteryBox: must have pauser role to pause");
        _pause();
    }
    
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "XWorldMysteryBox: must have pauser role to unpause");
        _unpause();
    }
    
}

// contracts/XWorldMysteryBox.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utility/TransferHelper.sol";
import "hardhat/console.sol";
interface IXWGRecyclePoolManager {
    // methType = 0 : lock, methType = 1 : unlock;
    function changeRecycleBalance(uint256 methType, uint256 amount) external;
}

interface IMysterBoxNFTMinter {
    function mintNFT(address to, uint32 mbType, uint32 mbTypeId) external returns(uint256 nftID);
    function batchMintNFT(address to, uint32 mbType, uint32 mbTypeId, uint32 count) external returns(uint256[] memory nftID);
}

contract XWorldMysteryBoxShop is 
    Context, 
    Pausable, 
    AccessControl
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event XWorldOnSaleMysterBox(string pairName, address indexed nftMinterAddress, uint32 mysterBoxType, uint32 mysterBoxTypeId, address indexed tokenAddress, uint256 price, address indexed recyclePool);
    event XWorldOffSaleMysterBox(string pairName, address indexed nftMinterAddress, uint32 mysterBoxType, uint32 mysterBoxTypeId, address indexed tokenAddress, uint256 price, address indexed recyclePool);
    event XWorldBuyMysteryBox(address userAddr, address indexed nftMinterddress, address indexed tokenAddress, uint256 price, uint32 mysterBoxType, uint32 mysterBoxTypeId, uint256 nftID);
    event XWorldBatchBuyMysteryBox(address userAddr, address indexed nftMinterddress, address indexed tokenAddress, uint256 price, uint32 mysterBoxType, uint32 mysterBoxTypeId, uint256[] nftID);

    struct OnSaleMysterBox{
        IMysterBoxNFTMinter nftMinter;
        uint32 mysterBoxType;
        uint32 mysterBoxTypeId;

        IERC20 token;
        uint256 price;

        IXWGRecyclePoolManager recyclePoolMgr; // if recyclePoolMgr is set, than transfer income to recycle pool & lock them
    }

    mapping(string=>OnSaleMysterBox) _onSaleMysterBoxes;
    address public _receiveIncomAddress;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P1");
        _pause();
    }
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P2");
        _unpause();
    }

    function setOnSaleMysteryBox(string calldata pairName, address nftMinterAddress, uint32 mysterBoxType, uint32 mysterBoxTypeId, address tokenAddress, uint256 price, address recyclePool) external whenNotPaused {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBoxShop: must have manager role to manage");
        console.log("1");
        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        console.log("2");
        onSalePair.nftMinter = IMysterBoxNFTMinter(nftMinterAddress);
        onSalePair.mysterBoxType = mysterBoxType;
        onSalePair.mysterBoxTypeId = mysterBoxTypeId;
        onSalePair.token = IERC20(tokenAddress);
        onSalePair.price = price;
        onSalePair.recyclePoolMgr = IXWGRecyclePoolManager(recyclePool);

        emit XWorldOnSaleMysterBox(pairName, nftMinterAddress, mysterBoxType, mysterBoxTypeId, tokenAddress, price, recyclePool);
    }

    function unsetOnSaleMysteryBox(string calldata pairName) external whenNotPaused {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBoxShop: must have manager role to manage");

        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        emit XWorldOffSaleMysterBox(pairName, address(onSalePair.nftMinter), onSalePair.mysterBoxType, onSalePair.mysterBoxTypeId, address(onSalePair.token), onSalePair.price, address(onSalePair.recyclePoolMgr));

        delete _onSaleMysterBoxes[pairName];
    }

    function setReceiveIncomeAddress(address incomAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBoxShop: must have manager role to manage");

        _receiveIncomAddress = incomAddr;
    }

    function buyMysteryBox(string calldata pairName) external whenNotPaused {
        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        require(address(onSalePair.nftMinter) != address(0), "XWorldMysteryBoxShop: mystery box not on sale");

        if(onSalePair.price > 0){
            require(onSalePair.token.balanceOf(_msgSender()) >= onSalePair.price, "XWorldMysteryBoxShop: insufficient token");

            if(address(onSalePair.recyclePoolMgr) != address(0)) {
                TransferHelper.safeTransferFrom(address(onSalePair.token), _msgSender(), address(onSalePair.recyclePoolMgr), onSalePair.price);
                onSalePair.recyclePoolMgr.changeRecycleBalance(0, onSalePair.price);
            }
            else {
                TransferHelper.safeTransferFrom(address(onSalePair.token), _msgSender(), address(this), onSalePair.price);
            }
        }

        uint256 nftID = onSalePair.nftMinter.mintNFT(_msgSender(), onSalePair.mysterBoxType, onSalePair.mysterBoxTypeId);

        emit XWorldBuyMysteryBox(_msgSender(), address(onSalePair.nftMinter), address(onSalePair.token), onSalePair.price, onSalePair.mysterBoxType, onSalePair.mysterBoxTypeId, nftID);
    }

    function batchBuyMysterBox(string calldata pairName, uint32 count) external whenNotPaused {

        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        require(address(onSalePair.nftMinter) != address(0), "XWorldMysteryBoxShop: mystery box not on sale");

        if(onSalePair.price > 0){
            require(onSalePair.token.balanceOf(_msgSender()) >= onSalePair.price*count, "XWorldMysteryBoxShop: insufficient token");

            if(address(onSalePair.recyclePoolMgr) != address(0)) {
                TransferHelper.safeTransferFrom(address(onSalePair.token), _msgSender(), address(onSalePair.recyclePoolMgr), onSalePair.price*count);
                onSalePair.recyclePoolMgr.changeRecycleBalance(0, onSalePair.price*count);
            }
            else {
                TransferHelper.safeTransferFrom(address(onSalePair.token), _msgSender(), address(this), onSalePair.price*count);
            }
        }

        uint256[] memory nftIDs = onSalePair.nftMinter.batchMintNFT(_msgSender(), onSalePair.mysterBoxType, onSalePair.mysterBoxTypeId, count);

        emit XWorldBatchBuyMysteryBox(_msgSender(), address(onSalePair.nftMinter), address(onSalePair.token), onSalePair.price, onSalePair.mysterBoxType, onSalePair.mysterBoxTypeId, nftIDs);
    
    }

    function fetchIncome(address tokenAddr, uint256 value) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "XWorldMysteryBoxShop: must have manager role to manage");
        IERC20 token = IERC20(tokenAddr);

        if(value <= 0){
            value = token.balanceOf(address(this));
        }

        require(value > 0, "XWorldMysteryBoxShop: zero value");

        TransferHelper.safeTransfer(tokenAddr, _receiveIncomAddress, value);
    }
}

// contracts/XWorldAvatar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../XWorldNFT.sol";

contract XWorldDCEquipStruct {

    struct EquipData{
        uint8 equip; // 1: weapon, 2: armor
        uint8 role; // 1: knight, 2: assassin, 3: mage， 4: priest， 5: archer
        uint8 grade; // 1-5
        uint8 level; // level 1-15, level/5 = generations, level%5 = stars
        uint32 exp; // experience
    }

}

contract XWorldDCEquip is XWorldExtendableNFT, XWorldDCEquipStruct {
    using Counters for Counters.Counter;
    
    event XWorldDCEquipMint(address indexed to, uint256 indexed tokenId, EquipData data);
    event XWorldDCEquipModify(uint256 indexed tokenId, EquipData data);

    mapping(uint256 => EquipData) private _equipDatas;

    constructor() XWorldExtendableNFT("XWorld DC Equipment", "XEQP", "https://testnode.xwgdata.net/eqp_nft/") {
        // mint(_msgSender(), 0, 0, 0, new bytes(0));
    }

    function mint(address to, EquipData calldata data) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        EquipData storage nftData = _equipDatas[curID];
        nftData.equip = data.equip;
        nftData.exp = data.exp;
        nftData.grade = data.grade;
        nftData.level = data.level;
        nftData.role = data.role;

        emit XWorldDCEquipMint(to, curID, nftData);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }

    function modifyNftData(uint256 tokenId, EquipData calldata data) external whenNotPaused {
        require(hasRole(DATA_ROLE, _msgSender()), "R4");
        require(_exists(tokenId), "R5");

        EquipData storage nftData = _equipDatas[tokenId];

        // modify user data
        nftData.equip = data.equip;
        nftData.exp = data.exp;
        nftData.grade = data.grade;
        nftData.level = data.level;
        nftData.role = data.role;

        emit XWorldDCEquipModify(tokenId, nftData);
    }

    function getNftData(uint256 tokenId) external view returns(EquipData memory data){
        require(_exists(tokenId), "T1");

        data = _equipDatas[tokenId];
    }

}

// contracts/XWorldRandom.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IXWorldRandom.sol";

// XWorldRandom 随机数合约
// 接口
// setRandomSeed(uint)      修改随机种子，写状态
// setSealed()              密封（调用者），写状态
// isSealed():view bool     是否有密封（调用者）静态方法
// sealedRand():uint        用密封信息获取随机数，并删除密封 **
// oracleRand():uint        用链外信息获取随机数，并改变噪音值 **
// seedRand(uint256):uint   用用户提供信息获取随机数，并改变噪音值 **
contract XWorldRandom is Context, AccessControl, IXWorldRandom {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    uint32 _nonce;
    uint32 _sealedNonce;
    uint256 _randomSeed;
    uint256 _orcacleReqIDSeed;

    struct RandomSeed {
        uint32 sealedNonce;
        uint256 sealedNumber;
        uint256 seed;
        uint256 h1;
    }

    mapping(uint256 => RandomSeed) _sealedRandom;
    mapping(uint256 => address) _oracleRandRequests;

    event XWorldOracleRandRequest(uint256 reqid);
    event XWorldOracleRandResponse(uint256 reqid, uint256 randnum);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(ORACLE_ROLE, _msgSender());
    }

    function _seedRand(uint256 inputSeed) internal returns (uint256 ret) {
        require(block.number >= 1000,"block.number need >=1000");

        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.number, block.timestamp, inputSeed))
        );

        uint32 n1 = uint32(seed % 100);
            
        uint32 n2 = uint32(seed % 1000);

        uint256 h1 = uint256(blockhash(block.number - n1));
  
        uint256 h2 = uint256(blockhash(block.number - n2));

        _nonce++;
        uint256 v = uint256(
            keccak256(abi.encodePacked(_randomSeed, h1, h2, _nonce))
        );

        return v;
    }

    function _encodeSealedKey(address addr) internal view returns (uint256 key) {
        return uint256(
            keccak256(
                abi.encodePacked(addr, _msgSender())
            )
        );
    }

    function _sealedRand() internal returns (uint256 ret) {
    
        uint256 sealedKey = _encodeSealedKey(tx.origin);
        bool v = _isSealedDirect(sealedKey);
        //console.log("[sol]_sealedRand tx.origin=", tx.origin, sealedKey);
        require(v == true,"should sealed");

        RandomSeed storage rs = _sealedRandom[sealedKey];

        uint256 h2 = uint256(blockhash(rs.sealedNumber));
        ret = uint256(
            keccak256(
                abi.encodePacked(
                    rs.seed,
                    rs.h1,
                    h2,
                    block.difficulty,
                    rs.sealedNonce
                )
            )
        );

        delete _sealedRandom[sealedKey];

        return ret;
    }

    function _isSealedDirect(uint256 sealedKey) internal view returns (bool){
        return _sealedRandom[sealedKey].sealedNumber != 0;
    }

    function isSealed(address addr) external view returns (bool) {
        return _isSealedDirect(_encodeSealedKey(addr));
    }

    function setRandomSeed(uint256 s) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not manager");

        _randomSeed = s;
    }

    function setSealed() external override {

        require(block.number >= 100,"block is too small");
        
        uint256 sealedKey = _encodeSealedKey(tx.origin);
       
        //console.log("[sol]set Sealed tx.origin=", tx.origin,sealedKey);
       
        require(!_isSealedDirect(sealedKey),"should not sealed");

        _sealedNonce++;

        RandomSeed storage rs = _sealedRandom[sealedKey];

        rs.sealedNumber = block.number + 1;
        rs.sealedNonce = _sealedNonce;
        rs.seed = _randomSeed;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(block.number, block.timestamp, _sealedNonce)
            )
        );
        uint32 n1 = uint32(seed % 100);
        rs.h1 = uint256(blockhash(block.number - n1));
    }

    function sealedRand() external override returns (uint256 ret) {
       
        return _sealedRand();
    }

    function seedRand(uint256 inputSeed) external override returns (uint256 ret) {
        return _seedRand(inputSeed);
    }

    function oracleRand() external override returns (uint256 reqid) {
        ++_orcacleReqIDSeed;
        reqid = _orcacleReqIDSeed;

        _oracleRandRequests[reqid] = _msgSender();

        emit XWorldOracleRandRequest(reqid);

        return reqid;
    }

    // call by oracle, return with rand seed
    function fulfillOracleRand(uint256 reqid, uint256 randnum) external returns (uint256 rand) {
        require(hasRole(ORACLE_ROLE, _msgSender()),"need oracle role");
        require(_oracleRandRequests[reqid] != address(0),"reqid not exist");

        rand = _seedRand(randnum);
        IXWorldOracleRandComsumer comsumer = IXWorldOracleRandComsumer(_oracleRandRequests[reqid]);
        comsumer.oracleRandResponse(reqid, rand);

        delete _oracleRandRequests[reqid];

        emit XWorldOracleRandResponse(reqid, rand);

        return rand;
    }

    function nextRand(uint32 index, uint256 randomNum) external override view returns(uint256 ret){
        uint256 n1 = randomNum % block.number;
        uint256 h1 = uint256(blockhash(n1));

        return uint256(
            keccak256(
                abi.encodePacked(n1, h1, index)
            )
        );
    }
}

// contracts/XWorldRandomPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./XWorldRandom.sol";

library XWorldRandomPool {

    struct RandomSet {
        uint32 rate;
        uint rangMin;
        uint rangMax;
    }

    struct RandomPool {
        uint32 totalRate;
        RandomSet[] pool;
    }

    function initRandomPool(RandomPool storage pool) external {
        for(uint i=0; i< pool.pool.length; ++i){
            pool.totalRate += pool.pool[i].rate;
        }

        require(pool.totalRate > 0);
    }

    function random(RandomPool storage pool, uint256 r) external view returns(uint ret) {
        require(pool.totalRate > 0);

        uint32 rate = uint32((r>>224) % pool.totalRate);
        uint32 curRate = 0;
        for(uint i=0; i<pool.pool.length; ++i){
            curRate += pool.pool[i].rate;
            if(rate > curRate){
                continue;
            }

            return randBetween(pool.pool[i].rangMin, pool.pool[i].rangMax, r);
        }
    }

    function randBetween(
        uint256 min,
        uint256 max,
        uint256 r
    ) public pure returns (uint256 ret) {
        if(min >= max) {
            return min;
        }

        uint256 rang = (max+1) - min;
        return uint256(min + (r % rang));
    }
}

// contracts/XWorldMysteryBox.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../XWorldNFT.sol";

struct XWorldMysteryBoxNFTMintOption {
    address to;
    uint32 mbType;
    uint32 mbTypeId;
}

contract XWorldMysteryBoxNFT is XWorldExtendableNFT {
    using Counters for Counters.Counter;

    event XWorldMysteryBoxNFTMint(address indexed to, uint256 indexed tokenId, uint32 mbType, uint32 mbTypeId);
    event XWorldMysteryBoxNFTBatchMint(uint256[] mintids);

    struct NFTData{
        uint32      mbType;
        uint32      mbTypeId;
    }

    mapping(uint256 => NFTData) private _nftDatas;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        XWorldExtendableNFT(name, symbol, baseTokenURI) 
    {
        // mint(_msgSender(), 0, 0, 0, new bytes(0));
    }

    function getMysteryBoxData(uint256 tokenId) external view returns(uint32 mbType, uint32 mbTypeId){
        NFTData storage data = _nftDatas[tokenId];
        mbType = data.mbType;
        mbTypeId = data.mbTypeId;
    }

    function batchMint(XWorldMysteryBoxNFTMintOption[] calldata options) public returns(uint256[] memory) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        uint32 len = uint32(options.length);
        uint256[] memory mintids = new uint256[](len);

        for (uint32 i = 0; i <len; i++) {
            XWorldMysteryBoxNFTMintOption memory op = options[i];
            uint256 curID = _tokenIdTracker.current();
            _mint(op.to, curID);
            NFTData storage nftData = _nftDatas[curID];
            nftData.mbType = op.mbType;
            nftData.mbTypeId = op.mbTypeId;
            mintids[i] = curID;
            _tokenIdTracker.increment();
        }
        emit XWorldMysteryBoxNFTBatchMint(mintids);

        return mintids;
    }

    function mint(address to, uint32 mbType, uint32 mbTypeId) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        NFTData storage nftData = _nftDatas[curID];
        nftData.mbType = mbType;
        nftData.mbTypeId = mbTypeId;

        emit XWorldMysteryBoxNFTMint(to, curID, mbType, mbTypeId);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }
}