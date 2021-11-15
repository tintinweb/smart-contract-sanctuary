// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct Event {
      uint movingPunk;
      uint gold;
    }
  
    struct Authorizer {
      uint id;
      string name;
      address holder;
    }

    struct PlayerInfo {
      uint id;
      string name;
      string uri;
    }

    struct StatusInfo {
      uint t;
      int x;
      int y;
    }

    struct MovingPunk {
      uint newNeighbor;
      ActionChoices action;
      int x;
      int y;
    }

    struct StillPunk {
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      uint showtime;
    }

    address public owner;
    address public nftAddress;

    uint private _startBlock; // 记录初始区块数
  
    // 储存玩家授权信息
    mapping (address => Authorizer) public authorizerOf;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => MovingPunk)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => Event))) public events;
  
    constructor(address nftAddress_) {
        owner = msg.sender;
        nftAddress = nftAddress_;
        _startBlock = block.number;
    }

    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (Event[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        Event[] memory selectEvents = new Event[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            selectEvents[i] = events[t][x][y];
            if (events[t][x][y].movingPunk == 0 && stillPunks[stillPunkOn[x][y]].showtime <= t) {
              selectEvents[i].movingPunk = stillPunkOn[x][y];
            }
            i ++;
          }
        }
        return selectEvents;
    }

    // 授权其它玩家使用punk进行游戏
    function authorize(address player_, uint id_, string memory name_) public {
        IERC721Metadata nft = IERC721Metadata(nftAddress);
        require(msg.sender == nft.ownerOf(id_), "Only owner can authorize his punk!");
        authorizerOf[player_] = Authorizer(id_, name_, msg.sender);
        if (lastScheduleOf[id_] == 0) {
          uint t = getCurrentTime();
          lastScheduleOf[id_] = t;
          _addStillPunk(id_, 0, 0, t);
        }
    }

    function _removeStillPunk(uint id, int x, int y) private {
        uint oldNeighbor = stillPunks[id].oldNeighbor;
        uint newNeighbor = stillPunks[id].newNeighbor;
        if (oldNeighbor > 0) {
          stillPunks[oldNeighbor].newNeighbor = newNeighbor;
        }
        else {
          stillPunkOn[x][y] = newNeighbor;
        }
        if (newNeighbor > 0) {
          stillPunks[newNeighbor].oldNeighbor = oldNeighbor;
        }
    }

    function _addStillPunk(uint id, int x, int y, uint t) private {
        uint latestNeighbor = stillPunkOn[x][y];
        stillPunkOn[x][y] = id;
        stillPunks[id].oldNeighbor = 0;
        stillPunks[id].newNeighbor = latestNeighbor;
        stillPunks[id].x = x;
        stillPunks[id].y = y;
        stillPunks[id].showtime = t;
        if (latestNeighbor > 0) {
          stillPunks[latestNeighbor].oldNeighbor = id;
        }
    }

    function _addMovingPunk(uint id, uint t, int x, int y, ActionChoices action) private {
        movingPunks[id][t].newNeighbor = events[t][x][y].movingPunk;
        events[t][x][y].movingPunk = id;
        movingPunks[id][t].action = action;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
    }

    // 操作punk
    function scheduleAction(uint id, ActionChoices action) public {
        require(authorizerOf[msg.sender].id == id, "Get authorized first!");
        uint currentTime = getCurrentTime();
        if (lastScheduleOf[id] < currentTime) {
          lastScheduleOf[id] = currentTime;
        }
        uint t = lastScheduleOf[id];
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        // remove this punk from still punks in (x, y) 
        _removeStillPunk(id, x, y);
        _addMovingPunk(id, t, x, y, action);
        if (action == ActionChoices.GoLeft) {
          _addStillPunk(id, x-1, y, t+1);
        }
        if (action == ActionChoices.GoRight) {
          _addStillPunk(id, x+1, y, t+1);
        }
        if (action == ActionChoices.GoUp) {
          _addStillPunk(id, x, y+1, t+1);
        }
        if (action == ActionChoices.GoDown) {
          _addStillPunk(id, x, y-1, t+1);
        }
        if (action == ActionChoices.GoLeftUp) {
          _addStillPunk(id, x-1, y+1, t+1);
        }
        if (action == ActionChoices.GoLeftDown) {
          _addStillPunk(id, x-1, y-1, t+1);
        }
        if (action == ActionChoices.GoRightUp) {
          _addStillPunk(id, x+1, y+1, t+1);
        }
        if (action == ActionChoices.GoRightDown) {
          _addStillPunk(id, x+1, y-1, t+1);
        }
        lastScheduleOf[id] ++;
    }

    function getCurrentTime() public view returns (uint) {
      uint time = (block.number - _startBlock) / 500;
      return time;
    }

    function getCurrentStatus(uint id) public view returns (StatusInfo memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        return StatusInfo(time, movingPunks[id][time].x, movingPunks[id][time].y);
      }
      else {
        return StatusInfo(time, stillPunks[id].x, stillPunks[id].y);
      }
      
    }

    function getScheduleInfo(uint id) public view returns (StatusInfo memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        time = lastScheduleOf[id];
      }
      return StatusInfo(time, stillPunks[id].x, stillPunks[id].y);
    }

    function getAuthorizedId(address player_) public view returns (uint) {
      IERC721 nft = IERC721(nftAddress);
      if (authorizerOf[player_].holder == address(0) || authorizerOf[player_].holder != nft.ownerOf(authorizerOf[player_].id)) {
        return 0;
      }
      else {
        return authorizerOf[player_].id;
      }
    }

    function getPlayerInfo(address player_) public view returns (PlayerInfo memory) {
      require (getAuthorizedId(player_) > 0, "not authorized");
      IERC721Metadata nft = IERC721Metadata(nftAddress);
      uint id = authorizerOf[player_].id;
      string memory name = authorizerOf[player_].name;
      string memory uri = nft.tokenURI(id);
      return PlayerInfo(id, name, uri);
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

