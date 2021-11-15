// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IFanDungeonHero.sol";
import "./interfaces/IFanDungeonLand.sol";
import "./interfaces/IFanDungeonStage.sol";
import "./interfaces/ICrystal.sol";
import "./libs/HeroInfo.sol";
import "./libs/OperatorControl.sol";

contract FanDungeonAdventure is ERC721Holder, HeroInfo, OperatorControl {

    event NewHeroAndLandAndStageAndCrystal(address sender,address hero,address land,address stage, address crystal);

    event Deposit(
        address user,
        uint256[] tokenIds,
        uint256 dungeonId,
        uint256 level,
        uint256 teamId,
        uint256 duration
    );

    event Withdrawal(
        address user,
        uint256 teamId
    );

    ICrystal public crystalToken;
    IFanDungeonHero public fanDungeonHero;
    IFanDungeonLand public fanDungeonLand;
    IFanDungeonStage public fanDungeonStage;
    uint256 public numberOfHeroesPerTeam = 3;
    uint256 public maximumDuration = 8 hours;
    uint256 internal day = 1 days;
    uint256 public regenerationTime = 4 hours;

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
    }

    function setHeroAndLandAndStageAndCrystalAddress(address _fanDungeonHero, address _fanDungeonLand, address _fanDungeonStage, address _crystalToken) external onlyOwner{
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

        emit NewHeroAndLandAndStageAndCrystal(msg.sender,_fanDungeonHero,_fanDungeonLand,_fanDungeonStage,_crystalToken);
    }

    struct Team{
        uint256[] heroes;
        uint256 dungeonId;
        uint256 dungeonLevel;
        uint256 startTime;
        uint256 endTime;
        uint256 reservedCrystal;
        uint256 reservedXP;
        bool isClaimed;
    }

    struct UserInfo {
        uint256[] teamIds;
        uint256 lastRefreshTime;
    }

    struct Dungeon {
        uint256 updatedAt;
        uint256 reservedCrystal;
    }

    Team[] internal _teams;
    mapping(address => UserInfo) internal _userInfo;
    mapping(uint256 => Dungeon) internal _dungeons;

    struct LevelInfo {
        uint256 xpPerSecond;
        uint256 crystalPerSecond;
        uint256 minPower;
        uint256 crystalPool;
    }
    mapping(uint256 => LevelInfo) internal _dungeonLevelInfo;

    function setLevelInfo(
        uint256 _level,
        uint256 _xpPerSecond,
        uint256 _crystalPerSecond,
        uint256 _minPower,
        uint256 _crystalPool
    ) external onlyOwner {
        _dungeonLevelInfo[_level] = LevelInfo({
            xpPerSecond: _xpPerSecond,
            crystalPerSecond: _crystalPerSecond,
            minPower: _minPower,
            crystalPool: _crystalPool
        });
    }

    function deposit(
        uint256[] calldata _tokenIds,
        uint256 _dungeonId,
        uint256 _level
    ) external {
        require(
            fanDungeonLand.viewLand(_dungeonId).landType == 1,
            "Adventure: Dungeon Id"
        );
        require(
            _level <= fanDungeonStage.viewLevelCap(_dungeonId) && _level > 0,
            "Adventure: Dungeon level"
        );
        require(
            _tokenIds.length == numberOfHeroesPerTeam,
            "Adventure: Number of heroes"
        );
        require(
            calculateAllHeroPower(_tokenIds) >= _dungeonLevelInfo[_level].minPower,
            "Adventure: Power"
        );
        _removeUserStamina(msg.sender);
        _transferHeroesToContract(msg.sender, _tokenIds);
        uint256 currentTeam = _teams.length;
        (uint256 _endTime,uint256 _reservedCrystal,uint256 _reservedXP) = _takeReservedRewards(_dungeonId, _level);
        _userInfo[msg.sender].teamIds.push(currentTeam);
        emit Deposit(msg.sender, _tokenIds, _dungeonId, _level, currentTeam, _endTime - block.timestamp);
        _teams.push(Team({
                heroes: _tokenIds,
                dungeonId: _dungeonId,
                dungeonLevel: _level,
                startTime: block.timestamp,
                endTime: _endTime,
                reservedCrystal: _reservedCrystal,
                reservedXP: _reservedXP,
                isClaimed: false
        }));
    }

    function withdraw(uint256 _teamId) external {
        require(_teams[_teamId].isClaimed == false, "Adventure: Claimed");
        (uint256 _xp, uint256 _crystal) = pendingRewards(_teamId);
        _earnCrystal(
            msg.sender,
            fanDungeonLand.ownerOf(_teams[_teamId].dungeonId),
            _crystal,
            fanDungeonStage.viewFee(_teams[_teamId].dungeonId)
        );
        _dungeons[_teams[_teamId].dungeonId]
            .reservedCrystal -= _calculateRefundReservedCrystal(
            _teams[_teamId].endTime,
            block.timestamp,
            maximumDuration,
            _teams[_teamId].reservedCrystal - _crystal
        );

        for (uint256 i = 0; i < _teams[_teamId].heroes.length; i++) {
            fanDungeonHero.increaseXP(
                _teams[_teamId].heroes[i],
                _xp / _teams[_teamId].heroes.length
            );
            fanDungeonHero.safeTransferFrom(
                address(this),
                msg.sender,
                _teams[_teamId].heroes[i]
            );
        }
        _teams[_teamId].isClaimed = true;

        emit Withdrawal(msg.sender,_teamId);

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
            _teams[_teamId].endTime,
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
    function pendingRewards(uint256 _teamId)
        public
        view
        returns (uint256 xp, uint256 crystal)
    {
        Team memory team_ = _teams[_teamId];
        return _calculatePendingRewards(team_, block.timestamp);
    }

    function getTeam(uint256 _teamId) public
        view
        returns (Team memory)
    {
        return _teams[_teamId];
    }

    function getDungeon(uint256 _dungeonId)
        public
        view
        returns (Dungeon memory dungeon)
    {
        Dungeon memory d = _dungeons[_dungeonId];
        return _calculateReservedCrystalDungeon(d, block.timestamp, maximumDuration);
    }

    function staminaOf(address user) external view returns (uint256) {
        return
            _calculateStamina(
                _userInfo[user].lastRefreshTime,
                block.timestamp,
                regenerationTime
            );
    }

    function getTeamIds(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _userInfo[user].teamIds;
    }

    function calculateAllHeroPower(uint256[] memory _heroIds)
        public
        view
        returns (uint256 power)
    {
        for (uint256 i; i < _heroIds.length; i++) {
            power += _calculateHeroPower(fanDungeonHero.viewHero(_heroIds[i]));
        }
    }

    function dungeonLevelInfo(uint256 _level)
        public
        view
        returns (LevelInfo memory)
    {
        return _dungeonLevelInfo[_level];
    }

    // # private and internal functions
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
        uint256 _refreshedEvery,
        uint256 _crystal
    ) internal view returns (uint256) {
        if (
            _endTime < block.timestamp &&
            _isCurrentRound(_endTime, _timestamp, _refreshedEvery)
        ) {
            return _crystal;
        }

        return 0;
    }

    function _takeReservedRewards(
        uint256 _dungeonId,
        uint256 _dungeonLevel
    ) internal returns(uint256 endTime,uint256 reservedCrystal,uint256 reservedXP) {
        Dungeon memory dungeon = getDungeon(_dungeonId);
        
        uint256 _remainingCrystal = _dungeonLevelInfo[_dungeonLevel].crystalPool - dungeon.reservedCrystal;
        uint256 _maxCrystalPerTurn = _dungeonLevelInfo[_dungeonLevel].crystalPerSecond * maximumDuration;
        uint256 duration;
        if (_remainingCrystal<_maxCrystalPerTurn) {
            duration = _remainingCrystal / _dungeonLevelInfo[_dungeonLevel].crystalPerSecond;
        } else {
            duration = (_maxCrystalPerTurn) / _dungeonLevelInfo[_dungeonLevel].crystalPerSecond;
        }

        uint256 _reservedCrystal = duration * _dungeonLevelInfo[_dungeonLevel].crystalPerSecond;
        uint256 _reservedXP = duration * _dungeonLevelInfo[_dungeonLevel].xpPerSecond;
        uint256 _endTime = block.timestamp + duration;
        dungeon.updatedAt = block.timestamp;
        dungeon.reservedCrystal += _reservedCrystal;
        _dungeons[_dungeonId] = dungeon;
        
        return (_endTime,_reservedCrystal,_reservedXP);
    }

    function _calculatePendingRewards(
        Team memory team_,
        uint256 _timestamp
    ) internal pure returns (uint256 xp, uint256 crystal) {
        if (team_.endTime <= _timestamp) {
            return (team_.reservedXP, team_.reservedCrystal);
        }

        return _calculatePendingIncompleteRewards(team_, _timestamp);
    }

    function _calculateStamina(
        uint256 _lastRefreshTime,
        uint256 _timestamp,
        uint256 _refreshedEvery
    ) internal pure returns (uint256) {
        uint256 _stamina = (_timestamp - _lastRefreshTime) / _refreshedEvery;
        if (_stamina < 6) {
            return _stamina;
        }

        return 6;
    }

    function _calculateLastRefreshTime(
        uint256 _lastRefreshTime,
        uint256 _timestamp,
        uint256 _refreshedEvery,
        uint256 _remainingStamina
    ) internal pure returns (uint256) {
        return
            _timestamp -
            (_lastRefreshTime % _refreshedEvery) -
            (_remainingStamina * _refreshedEvery);
    }

    function _calculateReservedCrystalDungeon(
        Dungeon memory d,
        uint256 _timestamp,
        uint256 _refreshedEvery
    ) internal view returns (Dungeon memory) {
        if (_isCurrentRound(d.updatedAt, _timestamp, _refreshedEvery)) {
            return d;
        }

        d.reservedCrystal = 0;
        d.updatedAt = block.timestamp;
        return d;
    }

    function _calculatePendingIncompleteRewards(
        Team memory team_,
        uint256 _timestamp
    ) internal pure returns (uint256 xp, uint256 crystal) {
        xp = _calculateProportion(
            team_.reservedXP,
            team_.startTime,
            team_.endTime,
            _timestamp
        );
        crystal = _calculateProportion(
            team_.reservedCrystal,
            team_.startTime,
            team_.endTime,
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

    function _removeUserStamina(address user) internal {
        uint256 _stamina = _calculateStamina(
            _userInfo[user].lastRefreshTime,
            block.timestamp,
            regenerationTime
        );
        require(_stamina > 0, "Adventure: Stamina");
        _userInfo[user].lastRefreshTime = _calculateLastRefreshTime(
            _userInfo[user].lastRefreshTime,
            block.timestamp,
            regenerationTime,
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

    function _removeElementByIndex(uint256[] memory array, uint256 index)
        internal
        pure
        returns (uint256[] memory)
    {
        if (index >= array.length) return array;

        array[index] = array[array.length - 1];
        delete array[array.length - 1];
        return array;
    }

    function _findElementIndex(uint256[] memory array, uint256 value)
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

    /**
     * @notice calculate hero power
     * @param _hero: hero data
     */
    function _calculateHeroPower(Hero memory _hero)
        internal
        pure
        returns (uint256 power)
    {
        power += _calculatePartPower(_hero.level, _hero.parts.head);
        power += _calculatePartPower(_hero.level, _hero.parts.upper);
        power += _calculatePartPower(_hero.level, _hero.parts.lower);
        power += _calculatePartPower(_hero.level, _hero.parts.hat);
        power += _calculatePartPower(_hero.level, _hero.parts.tool);
    }

    /**
     * @notice calculate part power
     * @param _part: part for calculation
     */
    function _calculatePartPower(uint256 _level, Part memory _part)
        internal
        pure
        returns (uint256 power)
    {
        uint256 _points;
        _points += _part.str;
        _points += _part.con;
        _points += _part.dex;
        _points += _part.agi;

        power = ((_points * _level * 2) / 10) + _points;
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

    function safeMint(address to, Hero memory _hero) external returns (uint256);

    function viewHero(uint256 _tokenId)
        external
        view
        returns (Hero memory hero);

    function setPart(
        uint256 _tokenId,
        PartId _partId,
        Part memory _part
    ) external;

    function increaseXP(uint256 _tokenId, uint256 _xp) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ILandInfo.sol";

interface IFanDungeonLand is IERC721, ILandInfo {
    function viewLand(uint256 _tokenId) external view returns (Land memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonStage {
    function viewLevelCap(uint256 _dungeonId) external view returns(uint256);
    function viewFee(uint256 _dungeonId) external view returns(uint256);
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
        uint256 id;
        uint256 str;
        uint256 con;
        uint256 dex;
        uint256 agi;
    }

    enum Element {
        none,
        rock,
        paper,
        scissors
    }

    enum PartId {
        head,
        upper,
        lower,
        hat,
        tool
    }

    struct Parts {
        Part head;
        Part upper;
        Part lower;
        Part hat;
        Part tool;
    }

    struct Hero {
        uint256 level;
        uint256 xp;
        Element element;
        Parts parts;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OperatorControl is Ownable {

    event OperatorChanged(address indexed sender,address indexed account,bool grant);

    mapping(address => bool) private _operators;

    constructor() {
        setOperator(_msgSender(),true);
    }

    function setOperator(address _account,bool _grant) public onlyOwner{
        require(_account!=address(0),"OperatorControl: Cannot be zero address");
        require(isOperator(_account)!=_grant,"OperatorControl: Already setted");
        _operators[_account] = _grant;

        emit OperatorChanged(_msgSender(),_account,_grant);
    }

    function isOperator(address _account) public view returns(bool) {
        return _operators[_account];
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorControl: Not operator");
        _;
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LandInfo {

    struct Land {
        uint256 landType;
        uint256 terrain;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

