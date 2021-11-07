// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct MovingPunk {
      uint punkId;
      uint punkNonce;
    }

    struct MapInfo {
      uint punk;
      uint gold;
    }

    struct KillEvent {
      uint punk;
      uint t;
      int x;
      int y;
    }

    struct TimeSpace {
      uint t;
      int x;
      int y;
    }

    struct Position {
      int x;
      int y;
    }

    struct StillPunk {
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      uint showtime;
      uint gold;
      uint enemy;
      uint hp;
      uint nonce; // 代表死亡时间
      uint evil; // 记录人头数
    }
    
    struct PunkInfo {      
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      bool isMoving;
      uint totalGold;
      uint hp;
      uint evil;
      uint seed;
      address player;
      string name;
    }

    uint public constant AC = 9; // 防御力
    uint public constant BAREHAND = 5; // 徒手攻击
    
    address public owner;
    address public cherryNFTAddress;
    address public hepAddress;
    address public squidAddress;
    uint public startBlock; // 记录初始区块数
    uint private _randNonce;
    uint public blockPerRound = 500;
    uint public rewardsPerRound = 4e15;
    bool public gameOver;

  
    // 储存玩家授权信息
    mapping (uint => address) public punkMaster;
    mapping (address => uint) public punkOf;
    mapping (address => string) public nickNameOf;
    mapping (address => bool) public isVIP;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => Position)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存随机种子，用于战斗
    mapping (uint => uint) private _randseedOfRound;
    mapping (uint => uint) private _randseedOfPunk;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存punk最后的死亡信息
    mapping (address => KillEvent) public lastKilled;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;

    // 储存药水合成信息
    mapping (uint => mapping (uint => bool)) public cooked;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => MovingPunk))) public movingPunksOn;

    // 储存奖励信息
    mapping (address => bool) public claimed;

    event ActionCommitted(uint indexed punkId, uint indexed time, ActionChoices action);
    event Attacked(uint indexed punkA, uint indexed punkB, uint damage);
    event Killed(uint indexed punkA, uint indexed punkB);
  
    constructor(address cherryNFTAddress_, address hepAddress_, address squidAddress_) {
        owner = msg.sender;
        cherryNFTAddress = cherryNFTAddress_;
        hepAddress = hepAddress_;
        squidAddress = squidAddress_;
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender)));
        _randseedOfRound[0] = _randNonce;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // 增加下一回合信息
    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (uint[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        uint[] memory selectEvents = new uint[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            //selectEvents[i] = events[t][x][y];
            if (movingPunksOn[t][x][y].punkNonce == stillPunks[movingPunksOn[t][x][y].punkId].nonce) {
              selectEvents[i] = movingPunksOn[t][x][y].punkId;
            }
            if (stillPunkOn[x][y] != 0) {
              selectEvents[i] = stillPunkOn[x][y];
            }
            i ++;
          }
        }
        return selectEvents;
    }

    function _resetPunk(uint id) private {
      uint t = getCurrentTime();
      lastScheduleOf[id] = t;
      stillPunks[id].hp = 15; // 初始生命值为15
      stillPunks[id].nonce = t;
      stillPunks[id].evil = 0;

      int n = int(id%100) / 2 - 24; // punk将根据序号分为4组排布在外城边界上
      if (id % 4 == 0) {
        _addStillPunk(id, n, 25, t);
      }
      else if (id % 4 == 1) {
        _addStillPunk(id, -n, -25, t);
      }
      else if (id % 4 == 2) {
        _addStillPunk(id, 25, -n, t);
      }
      else if (id % 4 == 3) {
        _addStillPunk(id, -25, n, t);
      }
      
    }

    // 玩家设置昵称
    function setNickName(string memory name) public {
        nickNameOf[msg.sender] = name;
    }

    function setVIP(address[] calldata vips) public {
        require(msg.sender == owner, "Only admin can set VIPs.");
        uint length = vips.length;
        // batch set
        for (uint i=0; i<length; i++) {
            isVIP[vips[i]] = true;
        }
    }
    
    // 玩家注册游戏
    function _register(uint id) public {
        require(!gameOver, 'game over');
        require(punkOf[msg.sender] == 0, "registered!");
        punkMaster[id] = msg.sender;
        punkOf[msg.sender] = id;
        _randseedOfPunk[id] = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        _resetPunk(id);
    }

    function registerWithPunk() public {
        require(getCurrentTime() == 0, 'too late');
        require(isVIP[msg.sender], 'You do not have loser punk');
        uint id;
        for (id=2; id<=667; id=id+2) {
          if (punkMaster[id] == address(0)) break;
        }
        require(id <= 667, 'no position for now');
        _register(id);
    }

    function registerWithNFT() public {
        require(getCurrentTime() == 0, 'too late');
        IERC721 cherryNFT = IERC721(cherryNFTAddress);
        require(cherryNFT.balanceOf(msg.sender) > 0, 'You do not have cherry NFT');
        uint id;
        for (id=3; id<=667; id=id+2) {
          if (punkMaster[id] == address(0)) break;
        }
        require(id <= 667, 'no position for now');
        _register(id);
    }

    function registerWithSquid() public {
        IERC20 squid = IERC20(squidAddress);
        require(squid.transferFrom(msg.sender, address(this), 1e18), 'Failed to transfer the squid token');
        uint id;
        for (id=2; id<=667; id++) {
          if (punkMaster[id] == address(0)) break;
        }
        require(id <= 667, 'no position for now');
        _register(id);
    }

    // 设置游戏开始与结束时间
    function startGame(uint startBlock_) public {
        require(msg.sender == owner, "Only admin can start the game.");
        startBlock = startBlock_;
    }


    // punkA击杀了punkB
    function _kill(uint A, uint B, uint t, int x, int y) private {
      // 阻止B后续的移动，将B送回原点，并恢复生命值
      _removeStillPunk(B);
      // 失去连接
      lastKilled[punkMaster[B]] = KillEvent(A, t, x, y);
      punkOf[punkMaster[B]] = 0;
      punkMaster[B] = address(0);
      // A获得了B的所有金币
      stillPunks[A].gold += (stillPunks[B].gold + pendingGold(B));
      stillPunks[B].gold = 0;
      stillPunks[A].enemy = 0;
      stillPunks[B].enemy = 0;
      // A变得更邪恶了
      stillPunks[A].evil ++;
      _reward(punkMaster[A], 2e17);
      
	    emit Killed(A, B);
    }
    
    // punkA向punkB进攻
    function _attack(uint A, uint B) private {
      // 命中检定1d20，徒手攻击1d5
      _randseedOfPunk[B] = uint(keccak256(abi.encode(A, _randseedOfPunk[B])));
      uint dice = _randseedOfPunk[B] % 100;
      // 骰点小于 10+被攻击者AC 时攻击命中
      if (dice/5+1 < 10+AC) {
        // 徒手攻击，伤害值1d5
        stillPunks[B].hp = (stillPunks[B].hp < (dice%5+1)? 0 : stillPunks[B].hp-(dice%5+1));
		    emit Attacked(A, B, dice%5+1);
      }
	    else {
		    emit Attacked(A, B, 0);
	    }
    }

    // punkA向punkB进攻
    function attack(uint A, uint B) public {
      require(punkOf[msg.sender] == A, "Get authorized first!");
      uint t = getCurrentTime();
      Position memory posA = getPostion(A, t);
      Position memory posB = getPostion(B, t);
	    require(stillPunks[B].showtime <= t, "punk B is moving");
      require(t > stillPunks[B].nonce, "punk B is just born!");
      //require(posA.x**2 < 625 && posA.y**2 < 625 && posB.x**2 < 625 && posB.y**2 < 625, "cannot attack punks outside the game area");
      require((posA.x-posB.x)**2 <=1  &&  (posA.y-posB.y)**2 <=1, "can only attack neighbors");

      if (stillPunks[A].enemy != B) {
        stillPunks[A].enemy = B;
      }

      _attack(A, B);
      if (stillPunks[B].hp == 0) {
        _kill(A, B, t, posB.x, posB.y);
      }
      else {
        // punkB自动反击
        _attack(B, A);
        if (stillPunks[A].hp == 0) {
          _kill(B, A, t, posA.x, posA.y);
        }
      }
    }

    // 只能在非战状态下时使用HEP
    function useHEP(uint id) public {
      IERC20 hep = IERC20(hepAddress);
      require(hep.transferFrom(msg.sender, address(this), 1), 'Failed to use hep');

      // 之后加入该机制
      //if (stillPunks[id].enemy != 0) {
      //  leaveBattle(id);
      //}

      stillPunks[id].hp += 10;
      if (stillPunks[id].hp > 15) {
        stillPunks[id].hp = 15;
      }
    }

    function _removeStillPunk(uint id) private {
        uint oldNeighbor = stillPunks[id].oldNeighbor;
        uint newNeighbor = stillPunks[id].newNeighbor;
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
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

    function _addMovingPunk(uint id, uint t, int x, int y) private {
        movingPunksOn[t][x][y].punkId = id;
        movingPunksOn[t][x][y].punkNonce = stillPunks[id].nonce;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
        // 自动进行挖矿操作
        uint gold = pendingGold(id);
        if (gold > 0) {
          stillPunks[id].gold += gold;
        }
    }



    // 操作punk
    function scheduleAction(uint id, ActionChoices action) public {
        require(punkOf[msg.sender] == id, "Get authorized first!");
        uint currentTime = getCurrentTime();
        if (lastScheduleOf[id] < currentTime) {
          lastScheduleOf[id] = currentTime;
        }
        uint t = lastScheduleOf[id];
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        // remove this punk from still punks in (x, y) 
        _removeStillPunk(id);
        _addMovingPunk(id, t, x, y);
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
        emit ActionCommitted(id, lastScheduleOf[id], action);
    }

    function getCurrentTime() public view returns (uint) {
      if (startBlock == 0 || startBlock > block.number) {
        return 0;
      }
      uint time = (block.number - startBlock) / blockPerRound + 1;
      return time;
    }

    function getPunkInfo(uint id) public view returns (PunkInfo memory) {
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      address player = punkMaster[id];
      uint totalGold = stillPunks[id].gold + pendingGold(id);
      return PunkInfo(stillPunks[id].oldNeighbor, stillPunks[id].newNeighbor, pos.x, pos.y, stillPunks[id].showtime>t, totalGold, stillPunks[id].hp, stillPunks[id].evil, _randseedOfPunk[id], player, nickNameOf[player]);
    }

    function getPunkOn(uint t, int x, int y) public view returns (uint) {
      if (stillPunkOn[x][y] != 0) {
        return stillPunkOn[x][y];
      }
      else {
        uint id = movingPunksOn[t][x][y].punkId;
        if (movingPunksOn[t][x][y].punkNonce == stillPunks[id].nonce) {
          return id;
        }
      }
      return 0;
    }

    function getPostion(uint id, uint t) public view returns (Position memory) {
      if (lastScheduleOf[id] > t) {
        return Position(movingPunks[id][t].x, movingPunks[id][t].y);
      }
      else {
        return Position(stillPunks[id].x, stillPunks[id].y);
      }
    }

    function getCurrentStatus(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      Position memory pos = getPostion(id, time);
      return TimeSpace(time, pos.x, pos.y);
    }

    function getScheduleInfo(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        time = lastScheduleOf[id];
      }
      return TimeSpace(time, stillPunks[id].x, stillPunks[id].y);
    }

    function getGoldsofAllPunk() public view returns (uint[667] memory) {
      uint[667] memory golds;
      for (uint i=0; i<667; i++) {
        golds[i] = stillPunks[i+1].gold;
      }
      return golds;
    }

    function getProductivity(int x, int y) public pure returns (uint) {
      if (x == 0 && y == 0) {
        return 100;
      }
      else if (x**2 <= 1  &&  y**2 <= 1) {
        return 25;
      }
      else if (x**2 <= 9  &&  y**2 <= 9) {
        return 10;
      }
      else if (x**2 <= 36  &&  y**2 <= 36) {
        return 5;
      }
      else if (x**2 <= 100  &&  y**2 <= 100) {
        return 3;
      }
      else if (x**2 <= 225  &&  y**2 <= 225) {
        return 2;
      }
      else if (x**2 <= 576  &&  y**2 <= 576) {
        return 1;
      }
      else {
        return 0;
      }
    }

    function pendingGold(uint id) public view returns (uint) {
      uint time = getCurrentTime();
      if (stillPunks[id].showtime < time) {
        uint productivity = getProductivity(stillPunks[id].x, stillPunks[id].y);
        return (time - stillPunks[id].showtime) * productivity * rewardsPerRound;
      }
      else {
        return 0;
      }
    }


    function _reward(address player, uint amount) private {
        require(!gameOver, 'game over');
        IERC20 squid = IERC20(squidAddress);
        uint balance = squid.balanceOf(address(this));
        if (balance <= amount) {
          squid.transfer(player, balance);
          gameOver = true;
        }
        else {
          squid.transfer(player, amount);
        }
    }

    // 领取奖励
    function claimRewards() public {
        uint id = punkOf[msg.sender];
        _reward(msg.sender, stillPunks[id].gold);
        stillPunks[id].gold = 0;
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