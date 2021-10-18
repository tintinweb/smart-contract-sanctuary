// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IFanDungeonHero.sol";
import "./interfaces/IFanDungeonLand.sol";
import "./interfaces/IFanDungeonStage.sol";
import "./interfaces/ICrystal.sol";
import "./libs/HeroInfo.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./libs/AdventureInfo.sol";

contract FanDungeonAdventure is
    ERC721Holder,
    HeroInfo,
    AccessControl,
    Pausable,
    AdventureInfo
{
    event NewHeroAndLandAndStageAndCrystalAddress(
        address sender,
        address hero,
        address land,
        address stage,
        address crystal
    );
    event Deposit(
        address user,
        uint256[] tokenIds,
        uint256 dungeonId,
        uint256 level,
        uint256 teamId,
        uint64 endTimeXp,
        uint64 endTimeCrystal
    );
    event Withdrawal(address user, uint256 teamId);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    ICrystal public crystalToken;
    IFanDungeonHero public fanDungeonHero;
    IFanDungeonLand public fanDungeonLand;
    IFanDungeonStage public fanDungeonStage;
    uint64 public numberOfHeroesPerTeam = 3;
    uint64 public maximumDuration = 8 hours;
    uint64 public recoveryTime = 4 hours;
    uint64 internal maxBonus = 10000;
    uint64 public currentTeamId;

    // mapping teamId => Team
    mapping(uint256 => Team) internal _teams;
    // mapping user => UserInfo
    mapping(address => UserInfo) internal _userInfo;
    // mapping dungeonId => Dungeon
    mapping(uint256 => Dungeon) internal _dungeons;
    // mapping level => LevelInfo
    mapping(uint32 => LevelInfo) internal _dungeonLevelInfo;

    constructor(
        address _fanDungeonHero,
        address _fanDungeonLand,
        address _fanDungeonStage,
        address _crystalToken
    ) {
        require(
            _fanDungeonHero != address(0) &&
                _fanDungeonLand != address(0) &&
                _fanDungeonStage != address(0) &&
                _crystalToken != address(0),
            "Adventure: Cannot be zero address"
        );

        fanDungeonHero = IFanDungeonHero(_fanDungeonHero);
        fanDungeonLand = IFanDungeonLand(_fanDungeonLand);
        fanDungeonStage = IFanDungeonStage(_fanDungeonStage);
        crystalToken = ICrystal(_crystalToken);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function setLevelInfo(
        uint16 _level,
        uint256 crystalPoolSize_,
        uint64 _xpPerSecond,
        uint256 _crystalPerSecond,
        uint32 _minPower
    ) external onlyRole(OPERATOR_ROLE) {
        _dungeonLevelInfo[_level] = LevelInfo({
            xpPerSecond: _xpPerSecond,
            crystalPerSecond: _crystalPerSecond,
            crystalPoolSize: crystalPoolSize_,
            minPower: _minPower
        });
    }

    function deposit(
        uint256[] calldata _tokenIds,
        uint64 _dungeonId,
        uint16 _level
    ) external whenNotPaused {
        require(fanDungeonLand.zoneOf(_dungeonId) == 1, "Adventure: Zone");
        require(
            _level <= fanDungeonStage.levelOf(_dungeonId) && _level > 0,
            "Adventure: Dungeon level"
        );
        require(_tokenIds.length == numberOfHeroesPerTeam, "Adventure: Heroes");
        require(
            calculateAllHeroPower(_tokenIds) >=
                _dungeonLevelInfo[_level].minPower,
            "Adventure: Power"
        );

        uint64 _timestamp = uint64(block.timestamp);
        _removeUserStamina(msg.sender, _timestamp);
        _transferHeroesToContract(msg.sender, _tokenIds);

        _userInfo[msg.sender].teamIds.push(currentTeamId);
        Team memory _team = Team({
            heroes: _tokenIds,
            dungeonId: _dungeonId,
            dungeonLevel: _level,
            startTime: _timestamp,
            endTimeXp: 0,
            endTimeCrystal: 0,
            reservedXp: 0,
            reservedCrystal: 0,
            fee: fanDungeonStage.feeOf(_dungeonId),
            isClaimed: false
        });
        _team = _calculateReserveRewards(_team, _timestamp);
        _teams[currentTeamId] = _team;
        _addReservedCrystalToDungeon(
            _dungeonId,
            _team.reservedCrystal,
            _timestamp
        );

        emit Deposit(
            msg.sender,
            _tokenIds,
            _dungeonId,
            _level,
            currentTeamId,
            _team.endTimeXp,
            _team.endTimeCrystal
        );

        currentTeamId++;
    }

    function withdraw(uint256 _teamId) external {
        require(_teams[_teamId].isClaimed == false, "Adventure: Claimed");
        (uint64 _xp, uint256 _crystal) = pendingRewards(_teamId);
        _earnCrystal(
            msg.sender,
            fanDungeonLand.ownerOf(_teams[_teamId].dungeonId),
            _crystal,
            _teams[_teamId].fee
        );

        if (_crystal < _teams[_teamId].reservedCrystal) {
            _dungeons[_teams[_teamId].dungeonId]
                .reservedCrystal -= _calculateRefundReservedCrystal(
                _teams[_teamId].endTimeCrystal,
                block.timestamp,
                maximumDuration,
                _teams[_teamId].reservedCrystal - _crystal
            );
        }

        for (uint256 i = 0; i < _teams[_teamId].heroes.length; i++) {
            fanDungeonHero.increaseXP(
                _teams[_teamId].heroes[i],
                _xp / uint32(_teams[_teamId].heroes.length)
            );
            fanDungeonHero.safeTransferFrom(
                address(this),
                msg.sender,
                _teams[_teamId].heroes[i]
            );
        }
        _teams[_teamId].isClaimed = true;

        emit Withdrawal(msg.sender, _teamId);

        // remove team from user info
        uint256 _teamIndex = _findElementIndex(
            _userInfo[msg.sender].teamIds,
            _teamId
        );
        _userInfo[msg.sender].teamIds = _removeElementByIndex(
            _userInfo[msg.sender].teamIds,
            _teamIndex
        );
        _userInfo[msg.sender].teamIds.pop();
    }

    function makeEmergencyWithdrawal(uint256 _teamId) external {
        _dungeons[_teams[_teamId].dungeonId]
            .reservedCrystal -= _calculateRefundReservedCrystal(
            _teams[_teamId].endTimeCrystal,
            block.timestamp,
            maximumDuration,
            _teams[_teamId].reservedCrystal
        );

        for (uint256 i = 0; i < _teams[_teamId].heroes.length; i++) {
            fanDungeonHero.safeTransferFrom(
                address(this),
                msg.sender,
                _teams[_teamId].heroes[i]
            );
        }
        _teams[_teamId].isClaimed = true;
    }

    // view functions
    function crystalPoolSizeByLevel(uint16 _level)
        public
        pure
        returns (uint256)
    {
        return 10000 ether + (uint256(_level - 1) * 1000 ether);
    }

    function pendingRewards(uint256 _teamId)
        public
        view
        returns (uint64 xp, uint256 crystal)
    {
        Team memory team_ = _teams[_teamId];
        IFanDungeonStage.Bonus memory d = fanDungeonStage.bonusOf(
            team_.dungeonId
        );
        return
            _calculatePendingRewards(team_, d.xp, d.crystal, block.timestamp);
    }

    function teamOf(uint256 _teamId) public view returns (Team memory) {
        return _teams[_teamId];
    }

    function dungeonOf(uint256 _dungeonId)
        public
        view
        returns (Dungeon memory dungeon)
    {
        Dungeon memory d = _dungeons[_dungeonId];
        return
            _calculateReservedCrystalDungeon(
                d,
                uint32(block.timestamp),
                maximumDuration
            );
    }

    function staminaOf(address user) external view returns (uint64) {
        return
            _calculateStamina(
                _userInfo[user].lastRecoveryTime,
                uint32(block.timestamp),
                recoveryTime
            );
    }

    function teamIdsOf(address user) external view returns (uint64[] memory) {
        return _userInfo[user].teamIds;
    }

    function calculateAllHeroPower(uint256[] calldata _heroIds)
        public
        view
        returns (uint32 power)
    {
        for (uint256 i; i < _heroIds.length; i++) {
            power += fanDungeonHero.totalStatPointsOf(_heroIds[i]);
        }
    }

    function dungeonLevelInfo(uint16 _level)
        public
        view
        returns (LevelInfo memory)
    {
        return _dungeonLevelInfo[_level];
    }

    function userInfoOf(address user) public view returns (UserInfo memory) {
        return _userInfo[user];
    }

    function dungeonLevelFor(uint256 _dungeonId, uint256[] calldata _heroIds)
        external
        view
        returns (uint256 level)
    {
        uint32 power = calculateAllHeroPower(_heroIds);
        uint256 levelDungeonCap = fanDungeonStage.levelOf(_dungeonId);
        for (uint16 i = 1; i < levelDungeonCap; i++) {
            LevelInfo memory levelInfo = dungeonLevelInfo(i);
            if (levelInfo.minPower < power) {
                level = i;
            } else {
                return level;
            }
        }
    }

    // internal functions
    function _transferHeroesToContract(
        address user,
        uint256[] calldata _tokenIds
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            fanDungeonHero.safeTransferFrom(user, address(this), _tokenIds[i]);
        }
    }

    function _earnCrystal(
        address _user,
        address _owner,
        uint256 _crystal,
        uint256 _fee
    ) internal {
        uint256 _ownerCrystal = (_crystal * _fee) / 10000;
        crystalToken.mint(_owner, _ownerCrystal);
        crystalToken.mint(_user, _crystal - _ownerCrystal);
    }

    function _calculateRefundReservedCrystal(
        uint256 _endTime,
        uint256 _timestamp,
        uint256 _recoveryTime,
        uint256 _crystal
    ) internal view returns (uint256) {
        if (
            _endTime < block.timestamp &&
            _isCurrentRound(_endTime, _timestamp, _recoveryTime)
        ) {
            return _crystal;
        }

        return 0;
    }

    function _calculateReserveRewards(Team memory _team, uint64 _timestamp)
        internal
        view
        returns (Team memory)
    {
        Dungeon memory dungeon = dungeonOf(_team.dungeonId);

        uint256 _remainingCrystal = crystalPoolSizeByLevel(_team.dungeonLevel) -
            dungeon.reservedCrystal;
        uint256 _maxCrystalPerTurn = _dungeonLevelInfo[_team.dungeonLevel]
            .crystalPerSecond * maximumDuration;
        uint256 _maxXpPerTurn = _dungeonLevelInfo[_team.dungeonLevel]
            .xpPerSecond * maximumDuration;

        uint64 durationCrystal = _calculateReduceDuration(
            _calculateDuration(
                _remainingCrystal,
                _maxCrystalPerTurn,
                _dungeonLevelInfo[_team.dungeonLevel].crystalPerSecond
            ),
            fanDungeonStage.bonusOf(_team.dungeonId).duration
        );
        uint64 durationXp = _calculateReduceDuration(
            _calculateDuration(
                1000000 ether,
                _maxXpPerTurn,
                _dungeonLevelInfo[_team.dungeonLevel].xpPerSecond
            ),
            fanDungeonStage.bonusOf(_team.dungeonId).duration
        );

        _team.endTimeCrystal = _timestamp + durationCrystal;
        _team.endTimeXp = _timestamp + durationXp;

        _team.reservedCrystal =
            uint256(durationCrystal) *
            _dungeonLevelInfo[_team.dungeonLevel].crystalPerSecond;
        _team.reservedXp =
            durationXp *
            _dungeonLevelInfo[_team.dungeonLevel].xpPerSecond;

        return _team;
    }

    function _calculateDuration(
        uint256 _remainingUnit,
        uint256 _maxUnitPerTurn,
        uint256 _unitPerSecond
    ) internal pure returns (uint64 duration) {
        if (_remainingUnit < _maxUnitPerTurn) {
            duration = uint64(_remainingUnit / _unitPerSecond);
        } else {
            duration = uint64(_maxUnitPerTurn / _unitPerSecond);
        }
    }

    function _calculateReduceDuration(
        uint64 _duration,
        uint64 _durationReduction
    ) public pure returns (uint64) {
        return _duration - ((_duration * _durationReduction) / 10000);
    }

    function _addReservedCrystalToDungeon(
        uint256 _dungeonId,
        uint256 _reservedCrystal,
        uint64 _timestamp
    ) internal {
        _dungeons[_dungeonId].updatedAt = _timestamp;
        _dungeons[_dungeonId].reservedCrystal += _reservedCrystal;
    }

    function _calculatePendingRewards(
        Team memory team_,
        uint64 bonusXp,
        uint64 bonusCrystal,
        uint256 _timestamp
    ) internal pure returns (uint64 xp, uint256 crystal) {
        if (team_.endTimeCrystal <= _timestamp) {
            if (team_.endTimeCrystal < _timestamp) {
                team_.reservedXp =
                    team_.reservedXp +
                    ((team_.reservedXp * bonusXp) / 10000);
                team_.reservedCrystal =
                    team_.reservedCrystal +
                    ((team_.reservedCrystal * bonusCrystal) / 10000);
            }
            return (team_.reservedXp, team_.reservedCrystal);
        }

        return _calculatePendingIncompleteRewards(team_, _timestamp);
    }

    function _calculatePendingIncompleteRewards(
        Team memory team_,
        uint256 _timestamp
    ) internal pure returns (uint64 xp, uint256 crystal) {
        xp = uint64(
            _calculateProportion(
                team_.reservedXp,
                team_.startTime,
                team_.endTimeXp,
                _timestamp
            )
        );
        xp =
            xp -
            uint64(
                _calculateRewardPunishment(
                    xp,
                    team_.startTime,
                    team_.endTimeXp,
                    _timestamp
                )
            );

        crystal = _calculateProportion(
            team_.reservedCrystal,
            team_.startTime,
            team_.endTimeCrystal,
            _timestamp
        );
        crystal =
            crystal -
            _calculateRewardPunishment(
                crystal,
                team_.startTime,
                team_.endTimeCrystal,
                _timestamp
            );
    }

    function _calculateProportion(
        uint256 _reserve,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _currentTime
    ) internal pure returns (uint256) {
        return
            (_reserve * (_currentTime - _startTime)) / (_endTime - _startTime);
    }

    function _calculateRewardPunishment(
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 currentTime
    ) internal pure returns (uint256) {
        if (currentTime >= endTime) {
            return 0;
        }

        return
            (((amount * 50) / 100) * (endTime - currentTime)) /
            (endTime - startTime);
    }

    function _calculateStamina(
        uint64 _lastRecoveryTime,
        uint64 _timestamp,
        uint64 _recoveryTime
    ) internal pure returns (uint64) {
        uint64 _stamina = (_timestamp - _lastRecoveryTime) / _recoveryTime;
        if (_stamina < 6) {
            return _stamina;
        }

        return 6;
    }

    function _calculatelastRecoveryTime(
        uint64 _lastRecoveryTime,
        uint64 _timestamp,
        uint64 _recoveryTime,
        uint64 _remainingStamina
    ) internal pure returns (uint64) {
        return
            _timestamp -
            (_lastRecoveryTime % _recoveryTime) -
            (_remainingStamina * _recoveryTime);
    }

    function _calculateReservedCrystalDungeon(
        Dungeon memory d,
        uint64 _timestamp,
        uint64 _recoveryTime
    ) internal pure returns (Dungeon memory) {
        if (_isCurrentRound(d.updatedAt, _timestamp, _recoveryTime)) {
            return d;
        }

        d.reservedCrystal = 0;
        d.updatedAt = _timestamp;
        return d;
    }

    function _isCurrentRound(
        uint256 _timestamp,
        uint256 _currentTime,
        uint256 _every
    ) internal pure returns (bool) {
        if (_timestamp >= _calculateNextResetTime(_currentTime, _every)) {
            return false;
        }

        return true;
    }

    function _removeUserStamina(address user, uint64 timestamp) internal {
        uint64 _stamina = _calculateStamina(
            _userInfo[user].lastRecoveryTime,
            timestamp,
            recoveryTime
        );
        require(_stamina > 0, "Adventure: Stamina");
        _userInfo[user].lastRecoveryTime = _calculatelastRecoveryTime(
            _userInfo[user].lastRecoveryTime,
            timestamp,
            recoveryTime,
            _stamina - 1
        );
    }

    function _calculateNextResetTime(uint256 _timestamp, uint256 _every)
        internal
        pure
        returns (uint256)
    {
        return (_timestamp / 86400) * 86400 + _every;
    }

    function _removeElementByIndex(uint64[] memory array, uint256 index)
        internal
        pure
        returns (uint64[] memory)
    {
        if (index >= array.length) return array;

        array[index] = array[array.length - 1];
        delete array[array.length - 1];
        return array;
    }

    function _findElementIndex(uint64[] memory array, uint256 value)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }

        revert("Adventure: Not found");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libs/HeroInfo.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonHero is IERC721, IERC721Enumerable, HeroInfo {
    function burn(uint256 tokenId) external;
    function safeMint(address to) external returns (uint256);
    function setPart(uint256 _tokenId,Position _position,Part calldata part) external;
    function setStats(uint256 _tokenId,Stats calldata stats_) external;
    function updateStats(uint256 _tokenId) external; 
    function increaseXP(uint256 _tokenId, uint64 xp_) external;
    
    // view and pure function
    function statsOf(uint256 _tokenId) external view returns(Stats memory);
    function totalStatPointsOf(uint256 _tokenId) external view returns(uint32);
    function partOf(uint256 _tokenId,Position _position) external view returns(Part memory);
    function calculateStats(uint256 _tokenId)
        external
        view
        returns (uint32 str, uint32 con, uint32 dex, uint32 agi);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ILandInfo.sol";

interface IFanDungeonLand is IERC721, ILandInfo {
    function landOf(uint256 _tokenId) external view returns (Land memory);
    function zoneOf(uint256 _tokenId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/StageInfo.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonStage is StageInfo{
    function levelOf(uint256 _dungeonId) external view returns(uint256);
    function feeOf(uint256 _dungeonId) external view returns(uint16);
    function bonusOf(uint256 _dungeonId) external view returns(Bonus memory);
    function stageOf(uint256 _dungeonId) external view returns(Stage memory);
    function decorationOf(uint256 _landId,uint32 _position) external view returns(uint256);
    function isActive(uint256 _landId,uint32 _position) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrystal {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HeroInfo {
   
    struct Part {
        uint32 appearance;
        uint32 str;
        uint32 con;
        uint32 dex;
        uint32 agi;
    }

    enum Element {
        none,
        rock,
        paper,
        scissors
    }

    enum Position {
        head,
        upper,
        lower,
        hat,
        tool
    }

    struct Stats {
        uint32 str;
        uint32 con;
        uint32 dex;
        uint32 agi;
        uint32 level;
        uint64 xp;
        Element element;
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

interface AdventureInfo {
    struct Team {
        uint256[] heroes;
        uint256 reservedCrystal;
        uint64 dungeonId;
        uint64 startTime;
        uint64 endTimeXp;
        uint64 endTimeCrystal;
        uint64 reservedXp;
        uint16 fee;
        uint16 dungeonLevel;
        bool isClaimed;
    }

    struct UserInfo {
        uint64[] teamIds;
        uint64 lastRecoveryTime;
    }

    struct Dungeon {
        uint64 updatedAt;
        uint256 reservedCrystal;
    }

    struct LevelInfo {
        uint64 xpPerSecond;
        uint32 minPower;
        uint256 crystalPerSecond;
        uint256 crystalPoolSize;
    }
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

import "../libs/LandInfo.sol";

interface ILandInfo is LandInfo {
    event LandChanged(address indexed sender, uint256 tokenId, Land land);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LandInfo {

    struct Land {
        uint32 zone;
        uint32 terrainType;
        uint32 terrainTexture;
        int32 positionX;
        int32 positionY;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface StageInfo {

    struct Stage {
        string name;
        string message;
        Bonus bonus;
        uint16 fee;
        uint16 level;
        bool isActive;
    }

    struct Bonus {
        uint16 xp;
        uint16 crystal;
        uint16 duration;
    }

    struct Decoration {
        uint256 tokenId;
        bool isActive;
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