/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/libs/HeroInfo.sol


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
        rock,
        paper,
        scissors,
        none
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


// File contracts/interfaces/IFanDungeonHero.sol


pragma solidity ^0.8.0;




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


// File contracts/interfaces/ILandInfo.sol


pragma solidity ^0.8.0;

interface ILandInfo {

}


// File contracts/interfaces/IFanDungeonLand.sol



pragma solidity ^0.8.0;


interface IFanDungeonLand is IERC721, ILandInfo {
    function getTypeId(uint256 tokenId) external view returns (uint256);
}


// File contracts/interfaces/ICrystal.sol


pragma solidity ^0.8.0;

interface ICrystal {
    function mint(address to, uint256 amount) external;
}


// File contracts/FanDungeonAdventure.sol


pragma solidity ^0.8.2;




contract FanDungeonAdventure is ERC721Holder {
    ICrystal public crystalToken;
    IFanDungeonHero public fanDungeonHero;
    IFanDungeonLand public fanDungeonLand;
    uint256 public maxNumHeroesPerUser = 3;
    uint256 public waitingTime = 8 hours;
    uint256 internal day = 1 days;

    constructor(
        address _fanDungeonHero,
        address _fanDungeonLand,
        address _crystalToken
    ) {
        require(
            _fanDungeonHero != address(0) &&
                _fanDungeonLand != address(0) &&
                _crystalToken != address(0),
            "FanDungeon: Cannot be zero address"
        );

        fanDungeonHero = IFanDungeonHero(_fanDungeonHero);
        fanDungeonLand = IFanDungeonLand(_fanDungeonLand);
        crystalToken = ICrystal(_crystalToken);
    }

    struct UserInfo {
        uint256[] heroes;
        uint256 currentDungeon;
        uint256 currentDungeonLevel;
        uint256 startTime;
        uint256 endTime;
        uint256 reservedCrystal;
        uint256 reservedXP;
    }

    struct Dungeon {
        uint256 updatedAt;
        uint256 reservedCrystal;
        uint256 reservedXP;
    }

    mapping(address => UserInfo) internal _userInfo;
    mapping(uint256 => Dungeon) internal _dungeons;

    function deposit(
        uint256[] calldata _tokenIds,
        uint256 _landId,
        uint256 _level
    ) external {
        require(fanDungeonLand.getTypeId(_landId) == 1, "FanDungeon: _landId");
        require(_tokenIds.length > 0, "FanDungeon: _tokenIds");
        require(
            _userInfo[msg.sender].heroes.length == 0,
            "FanDungeon: Hero must be withdrawn"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                fanDungeonHero.ownerOf(_tokenIds[i]) == msg.sender,
                "FanDungeon: Not owner"
            );

            fanDungeonHero.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );

            _userInfo[msg.sender].heroes.push(_tokenIds[i]);
        }

        _takeReservedRewards(msg.sender, _landId, _level);
    }

    function _takeReservedRewards(
        address user,
        uint256 _landId,
        uint256 _dungeonLevel
    ) internal {
        uint256 _reservedCrystal = 10 ether;
        uint256 _reservedXP = 10000;
        uint256 _endTime = block.timestamp + waitingTime;

        _userInfo[user].currentDungeon = _landId;
        _userInfo[user].currentDungeonLevel = _dungeonLevel;
        _userInfo[user].endTime = _endTime;
        _userInfo[user].startTime = block.timestamp;
        _userInfo[user].reservedCrystal = _reservedCrystal;
        _userInfo[user].reservedXP = _reservedXP;

        uint256 _currentDungeon = _userInfo[user].currentDungeon;
        if (
            isCurrentRound(
                _dungeons[_currentDungeon].updatedAt,
                block.timestamp
            )
        ) {
            _dungeons[_currentDungeon].reservedCrystal += _reservedCrystal;
            _dungeons[_currentDungeon].reservedXP += _reservedXP;
        } else {
            _dungeons[_currentDungeon].reservedCrystal = _reservedCrystal;
            _dungeons[_currentDungeon].reservedXP = _reservedXP;
        }

        _dungeons[_currentDungeon].updatedAt = block.timestamp;
    }

    function withdraw() external {
        (uint256 _xp, uint256 _crystal) = viewPendingRewards(msg.sender);
        crystalToken.mint(msg.sender, _crystal);

        UserInfo memory _uinfo = _userInfo[msg.sender];
        uint256 numHero = _uinfo.heroes.length;
        for (uint256 i = 0; i < numHero; i++) {
            fanDungeonHero.increaseXP(_uinfo.heroes[i], _xp / numHero);
            fanDungeonHero.safeTransferFrom(
                address(this),
                msg.sender,
                _uinfo.heroes[i]
            );
        }

        if (
            _uinfo.endTime < block.timestamp &&
            isCurrentRound(_uinfo.endTime, block.timestamp)
        ) {
            _dungeons[_uinfo.currentDungeon].reservedCrystal -=
                _uinfo.reservedCrystal -
                _crystal;
            _dungeons[_uinfo.currentDungeon].reservedXP -=
                _uinfo.reservedXP -
                _xp;
        }

        _clearUserInfo(msg.sender);
    }

    function _clearUserInfo(address _user) internal {
        delete _userInfo[_user].heroes;
        _userInfo[_user].currentDungeon = 0;
        _userInfo[_user].currentDungeonLevel = 0;
        _userInfo[_user].startTime = 0;
        _userInfo[_user].endTime = 0;
        _userInfo[_user].reservedCrystal = 0;
        _userInfo[_user].reservedXP = 0;
    }

    function viewPendingRewards(address _user)
        public
        view
        returns (uint256 xp, uint256 crystal)
    {
        UserInfo memory _uinfo = _userInfo[_user];

        if (_uinfo.endTime >= block.timestamp) {
            return (
                _uinfo.reservedXP,
                _uinfo.reservedCrystal
            );
        }

        return _calculatePendingIncompleteRewards(_uinfo);
    }

    function _calculatePendingIncompleteRewards(UserInfo memory _uinfo)
        internal
        view
        returns (uint256 xp, uint256 crystal)
    {
        xp = _calculateProportion(
            _uinfo.reservedXP,
            _uinfo.startTime,
            _uinfo.endTime,
            block.timestamp
        );
        crystal = _calculateProportion(
            _uinfo.reservedCrystal,
            _uinfo.startTime,
            _uinfo.endTime,
            block.timestamp
        );
    }

    function _calculateProportion(
        uint256 _reserve,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _currentTime
    ) internal pure returns (uint256) {
        return
            (_reserve * (_endTime - _startTime)) / (_currentTime - _startTime);
    }

    function viewDungeon(uint256 _landId)
        public
        view
        returns (Dungeon memory dungeon)
    {
        Dungeon memory d = _dungeons[_landId];

        if (isCurrentRound(d.updatedAt, block.timestamp)) {
            return d;
        }

        d.reservedCrystal = 0;
        d.reservedXP = 0;
        return d;
    }

    function isCurrentRound(uint256 _timestamp, uint256 _currentTime)
        internal
        pure
        returns (bool)
    {
        if (_timestamp >= _calculateNextResetTime(_currentTime)) {
            return false;
        }

        return true;
    }

    function _calculateNextResetTime(uint256 _timestamp)
        internal
        pure
        returns (uint256)
    {
        return (_timestamp / 86400) * 86400 + 86400;
    }

    function checkOwnerOfHeroes(uint256[] memory _tokenIds, address _user)
        internal
        view
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                fanDungeonHero.ownerOf(_tokenIds[i]) == _user,
                "FanDungeon: Not owner"
            );
        }
    }
}