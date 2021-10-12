// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IFanDungeonHero.sol";
import "./interfaces/IFanDungeonLand.sol";
import "./interfaces/IFanDungeonDecoration.sol";
import "./interfaces/IFanDungeonStage.sol";
import "./interfaces/IFanDungeonAdventure.sol";

contract FanDungeonCaller {
    function getTokenIds(
        address _target,
        address _user,
        uint256 _cursor,
        uint256 _size
    ) external view returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](_size);
        for (uint256 i = 0; i < _size; i++) {
            uint256 tokenId = IERC721Enumerable(_target).tokenOfOwnerByIndex(
                _user,
                _cursor + i
            );
            tokenIds[i] = tokenId;
        }
    }

    struct Hero {
        IFanDungeonHero.Stats stats;
        Parts parts;
    }

    struct Parts {
        IFanDungeonHero.Part head;
        IFanDungeonHero.Part upper;
        IFanDungeonHero.Part lower;
        IFanDungeonHero.Part hat;
        IFanDungeonHero.Part tool;
    }

    function getHeroes(address _heroAddress, uint256[] calldata tokenIds)
        external
        view
        returns (Hero[] memory heroes)
    {
        heroes = new Hero[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IFanDungeonHero.Stats memory stats = IFanDungeonHero(_heroAddress)
                .statsOf(tokenIds[i]);
            IFanDungeonHero.Part memory head = IFanDungeonHero(_heroAddress)
                .partOf(tokenIds[i], HeroInfo.Position.head);
            IFanDungeonHero.Part memory upper = IFanDungeonHero(_heroAddress)
                .partOf(tokenIds[i], HeroInfo.Position.upper);
            IFanDungeonHero.Part memory lower = IFanDungeonHero(_heroAddress)
                .partOf(tokenIds[i], HeroInfo.Position.lower);
            IFanDungeonHero.Part memory hat = IFanDungeonHero(_heroAddress)
                .partOf(tokenIds[i], HeroInfo.Position.hat);
            IFanDungeonHero.Part memory tool = IFanDungeonHero(_heroAddress)
                .partOf(tokenIds[i], HeroInfo.Position.tool);
            heroes[i] = Hero({
                stats: stats,
                parts: Parts({
                    head: head,
                    upper: upper,
                    lower: lower,
                    hat: hat,
                    tool: tool
                })
            });
        }
    }

    struct LandCaller {
        uint256 id;
        uint32 terrainType;
        uint32 terrainTexture;
        address owner;
        uint32 zone;
        int64 xPos;
        int64 yPos;
    }

    function getLands(address _landAddress, uint256[] calldata tokenIds)
        external
        view
        returns (LandCaller[] memory lands)
    {
        lands = new LandCaller[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ILandInfo.Land memory land = IFanDungeonLand(_landAddress).landOf(
                tokenIds[i]
            );
            lands[i] = LandCaller({
                id: tokenIds[i],
                terrainType: land.terrainType,
                terrainTexture: land.terrainTexture,
                owner: IERC721(_landAddress).ownerOf(tokenIds[i]),
                zone: land.zone,
                xPos: land.positionX,
                yPos: land.positionY
            });
        }
    }

    struct DecorationCaller {
        uint256 id;
        uint32 appearance;
        uint32 position;
        uint64 bonusXp;
        uint64 bonusCrystal;
        uint64 bonusDuration;
    }

    function getDecorations(
        address _decorationAddress,
        uint256[] calldata tokenIds
    ) external view returns (DecorationCaller[] memory decorations) {
        decorations = new DecorationCaller[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IFanDungeonDecoration.Decoration
                memory decoration = IFanDungeonDecoration(_decorationAddress)
                    .decorationOf(tokenIds[i]);
            decorations[i] = DecorationCaller({
                id: tokenIds[i],
                appearance: decoration.appearance,
                position: decoration.position,
                bonusXp: decoration.bonus.xp,
                bonusCrystal: decoration.bonus.crystal,
                bonusDuration: decoration.bonus.duration
            });
        }
    }

    struct DungeonCaller {
        uint256 id;
        uint256 remainingCrystal;
        uint64 fee;
        string message;
        uint64 bonusXp;
        uint64 bonusCrystal;
        uint64 bonusDuration;
        uint256[] decorations;
    }

    function getDungeon(
        address _adventureAddress,
        address _stageAddress,
        uint256[] calldata tokenIds
    ) external view returns (DungeonCaller[] memory dungeons) {
        dungeons = new DungeonCaller[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            AdventureInfo.Dungeon memory dungeon = IFanDungeonAdventure(
                _adventureAddress
            ).dungeonOf(tokenIds[i]);
            IFanDungeonStage.Stage memory stage = IFanDungeonStage(
                _stageAddress
            ).stageOf(tokenIds[i]);
            IFanDungeonStage.Bonus memory bonus = IFanDungeonStage(
                _stageAddress
            ).bonusOf(tokenIds[i]);

            // uint32 sizeDecoration;
            // for (uint32 j = 0; j < 10; i++) {
            //     if (IFanDungeonStage(_stageAddress).isActive(tokenIds[i], j)) {
            //         sizeDecoration++;
            //     }
            // }

            uint256[] memory decorationIds = new uint256[](0);
            // uint256 increment;
            // for (uint32 j = 0; j < 10; i++) {
            //     if (IFanDungeonStage(_stageAddress).isActive(tokenIds[i], j)) {
            //         decorationIds[increment] = IFanDungeonStage(_stageAddress)
            //             .decorationOf(tokenIds[i], j);
            //         increment++;
            //     }
            // }

            dungeons[i] = DungeonCaller({
                id: tokenIds[i],
                remainingCrystal: (10000 ether) - dungeon.reservedCrystal,
                fee: stage.fee,
                message: stage.message,
                bonusXp: bonus.xp,
                bonusCrystal: bonus.crystal,
                bonusDuration: bonus.duration,
                decorations: decorationIds
            });
        }
    }

    struct DungeonLevelInfoCaller {
        uint256 level;
        uint64 xpPerSecond;
        uint256 crystalPerSecond;
        uint256 crystalPoolSize;
        uint32 minPower;
    }

    function getDungeonLevelInfo(
        address _stageAddress,
        address _adventureAddress,
        uint256 _dungeonId
    ) external view returns (DungeonLevelInfoCaller[] memory) {
        uint256 size = IFanDungeonStage(_stageAddress).levelCapOf(_dungeonId);

        DungeonLevelInfoCaller[]
            memory levelInfo = new DungeonLevelInfoCaller[](size);

        for (uint256 i = 1; i < size; i++) {
            AdventureInfo.LevelInfo memory dungeon = IFanDungeonAdventure(
                _adventureAddress
            ).dungeonLevelInfo(i);

            levelInfo[i - 1] = DungeonLevelInfoCaller({
                level: i,
                xpPerSecond: dungeon.xpPerSecond,
                crystalPerSecond: dungeon.crystalPerSecond,
                minPower: dungeon.minPower,
                crystalPoolSize: 10000 ether
            });
        }

        return levelInfo;
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

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libs/DecorationInfo.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonDecoration is IERC721, IERC721Enumerable, DecorationInfo {
    function decorationOf(uint256 _tokenId)
        external
        view
        returns (Decoration memory);

    function bonusOf(uint256 _tokenId)
        external
        view
        returns (Bonus memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/StageInfo.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonStage is StageInfo{
    function levelCapOf(uint256 _dungeonId) external view returns(uint256);
    function feeOf(uint256 _dungeonId) external view returns(uint256);
    function bonusOf(uint256 _dungeonId) external view returns(Bonus memory);
    function stageOf(uint256 _dungeonId) external view returns(Stage memory);
    function decorationOf(uint256 _landId,uint32 _position) external view returns(uint256);
    function isActive(uint256 _landId,uint32 _position) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/AdventureInfo.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IFanDungeonAdventure is AdventureInfo {
    function dungeonOf(uint256 _dungeonId)
        external
        view
        returns (Dungeon memory dungeon);

    function crystalPoolSize() external view returns (uint256);

    function dungeonLevelInfo(uint256 _level)
        external
        view
        returns (LevelInfo memory);
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

interface DecorationInfo {

    struct Decoration {
        uint32 appearance;
        uint8 position;
        Bonus bonus;
    }

    struct Bonus {
        uint64 xp;
        uint64 crystal;
        uint64 duration;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface StageInfo {
    struct Stage {
        uint64 fee;
        uint64 levelCap;
        bool isActive;
        Bonus bonus;
        string message;
    }

    struct Bonus {
        uint64 xp;
        uint64 crystal;
        uint64 duration;
    }

    struct Decoration {
        uint256 tokenId;
        bool isActive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AdventureInfo {

    struct Team {
        uint256[] heroes;
        uint256 dungeonId;
        uint256 reservedCrystal;
        uint32 dungeonLevel;
        uint64 startTime;
        uint64 endTime;
        uint64 reservedXP;
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