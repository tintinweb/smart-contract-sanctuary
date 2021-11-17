pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INoftToken is IERC721 {

    struct Application {
        address sender;
        uint code;
        bool approved;
        bool created;
        uint genes;
        uint attempt;
    }

    struct TokenData {
        uint id;
        uint exp;
        uint genes;
        uint generation;
        bool custom;
    }

    enum Ranks {
        CIVILIAN, RECRUIT, WARRIOR, HERO, LEGENDARY_HERO, MYSTICAL_HERO
    }

    function getToken(uint tokenId) external view returns (uint id, uint exp, uint genes, uint generation, bool custom, uint rating, Ranks rank);

    function getGeneration() external view returns (uint);

    function getLastTokenId() external view returns (uint);

    function mint(address to, uint count) external;

    function nextGeneration() external;

    function updateExp(uint[] calldata tokenIds, uint[] calldata values) external;

    function setManager(address _manager) external;

    function setMatchManager(address _matchManager) external;

    function setMarketplace(address _marketplace) external;

    function getTokenRating(uint genes) external view returns (uint rate);

    function getTokenRank(uint rate) external view returns (Ranks);

    function setBaseURI(string memory uri) external;

    function getManager() external view returns (address);

    function getMatchManager() external view returns (address);

    function getMarketplace() external view returns (address);

    function getRankRate(uint rank) external view returns (uint);

    function getGenerationTokenMin() external view returns (uint);

    function getGenerationTokenMax() external view returns (uint);

    function tokensInCurrentGeneration() external view returns (uint);

    function getApplication(uint applicationCode) external view returns (
        address sender,
        uint code,
        bool approved,
        bool created,
        uint genes,
        uint attempt
    );

    function generateGenesByApplication(uint code, address from) external;

    function approveApplication(uint code, bool approved) external;

    function createApplication(uint code, address from) external;

    function mintByApplication(uint code, bool custom, address from) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./INoftToken.sol";

contract NoftGameManager is Ownable {
    using SafeMath for uint256;

    address payable wallet;
    address manager;
    address token;
    address rentAddress;
    address serverAddress;
    INoftToken tokenContract;

    uint FEE_PERCENTAGE = 5;
    uint RENT_FEE_PERCENTAGE = 20;
    uint[] GAME_FEES = [10000000000000000, 50000000000000000, 100000000000000000];
    uint[] PLAYER_COUNTS = [8];
    uint incrementGameId = 1;
    uint incrementPlayerId = 1;

    struct Player {
        uint id;
        address payable account;
        uint tokenId;
        bool isRent;
        bool isBot;
        string strategy;
    }

    enum GameStatus {
        STARTED,
        ENDED,
        CANCELLED,
        PICKED
    }

    struct Game {
        uint id;
        GameStatus status;
        uint[] playerIds;
        uint gameFee;
        uint winnerId;
        uint bank;
        uint playersCount;
        address creator;
        bool leaveEnabled;
        bool botsEnabled;
        uint seed;
    }

    mapping(uint => Game) games;
    mapping(uint => Player) players;

    modifier onlyOwnerOrManager() {
        require(_msgSender() == owner() || manager == _msgSender());
        _;
    }

    modifier onlyOwnerOrManagerOrServer() {
        require(_msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender());
        _;
    }

    event GameStatusChanged(uint indexed gameId, GameStatus indexed status);

    event PlayerChanged(address indexed account, uint indexed gameId, uint indexed playerId, bool isBot);

    event WalletChanged(address indexed oldWallet, address indexed newWallet);
    event ManagerChanged(address oldManager, address newManager);
    event TokenChanged(address oldToken, address newToken);
    event ServerChanged(address oldServer, address newServer);
    event RentChanged(address oldRent, address newRent);

    constructor(address _token, address payable _wallet, address _manager, address _rentAddress) {
        wallet = _wallet;
        manager = _manager;
        token = _token;
        rentAddress = _rentAddress;
        tokenContract = INoftToken(_token);
    }

    function startGame(uint feeIdx, uint playersCountIdx, bool leaveEnabled, bool botsEnabled) external returns (uint gameId) {
        gameId = incrementGameId++;

        games[gameId] = Game(
            gameId,
            GameStatus.STARTED,
            new uint[](0),
            GAME_FEES[feeIdx],
            0,
            0,
            PLAYER_COUNTS[playersCountIdx],
            _msgSender(),
            leaveEnabled,
            botsEnabled,
            bytesToUint(keccak256(abi.encodePacked(blockhash(block.number - 1), gameId)))
        );

        emit GameStatusChanged(gameId, GameStatus.STARTED);
    }

    function addPlayer(uint tokenId, uint gameId, string memory strategy) external payable returns (uint playerId) {
        Game memory game = games[gameId];
        require(game.gameFee == msg.value);
        require(game.status == GameStatus.STARTED);
        playerId = incrementPlayerId++;
        bool isRent = tokenContract.ownerOf(tokenId) == rentAddress;
        bool isOwn = tokenContract.ownerOf(tokenId) == _msgSender();
        require(isRent || isOwn);

        players[playerId] = Player(playerId, payable(_msgSender()), tokenId, isRent, false, strategy);

        games[gameId].playerIds.push(playerId);
        games[gameId].bank = games[gameId].bank.add(msg.value);

        emit PlayerChanged(_msgSender(), gameId, playerId, false);
        if (game.playersCount == games[gameId].playerIds.length) {
            games[gameId].status = GameStatus.PICKED;
            emit GameStatusChanged(gameId, GameStatus.PICKED);
        }
    }

    function addBots(uint[] memory tokenIds, uint gameId, string[] memory strategies) external {
        Game memory game = games[gameId];
        require(game.botsEnabled);
        require(game.status == GameStatus.STARTED);
        bool isManager = _msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender();
        bool isGameCreator = game.creator == _msgSender();
        require(isManager || isGameCreator);
        require(tokenIds.length == strategies.length);
        require(tokenIds.length + game.playerIds.length <= game.playersCount);

        uint botsCount = getBotsCount(gameId);

        require(game.playersCount - botsCount >= 2);

        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenContract.ownerOf(tokenIds[i]) == rentAddress);
            uint playerId = incrementPlayerId++;

            players[playerId] = Player(playerId, payable(_msgSender()), tokenIds[i], false, true, strategies[i]);

            games[gameId].playerIds.push(playerId);

            emit PlayerChanged(_msgSender(), gameId, playerId, true);
            if (game.playersCount == games[gameId].playerIds.length) {
                games[gameId].status = GameStatus.PICKED;
                emit GameStatusChanged(gameId, GameStatus.PICKED);
            }
        }
    }

    function endGame(uint gameId, uint winnerId) external onlyOwnerOrManagerOrServer returns (uint prize) {
        Game memory game = games[gameId];
        require(game.status == GameStatus.PICKED);

        Player memory winner = players[winnerId];
        require(!winner.isBot);

        uint fee = winner.isRent ? RENT_FEE_PERCENTAGE : FEE_PERCENTAGE;
        uint bankFee = game.bank.div(100).mul(fee);
        prize = game.bank.sub(bankFee);

        wallet.transfer(bankFee);
        winner.account.transfer(prize);

        games[gameId].winnerId = winnerId;
        games[gameId].status = GameStatus.ENDED;

        emit PlayerChanged(_msgSender(), gameId, winnerId, false);
        emit GameStatusChanged(gameId, GameStatus.ENDED);
    }

    function leavePlayer(uint gameId, uint playerId) external {
        require(games[gameId].leaveEnabled);

        Player memory player = players[playerId];
        bool isManager = _msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender();
        bool isTokenOwner = _msgSender() == player.account;
        require(isManager || isTokenOwner);

        removePlayer(gameId, playerId);
    }

    function removePlayer(uint gameId, uint playerId) internal {
        Player memory player = players[playerId];
        Game memory game = games[gameId];

        uint playersCount = game.playerIds.length;
        uint playerIdx = playersCount;

        for (uint i = 0; i < playersCount - 1; i++) {
            if (game.playerIds[i] == playerId) {
                playerIdx = i;
            }
            if (playerIdx < playersCount) {
                game.playerIds[i] = game.playerIds[i + 1];
            }
        }

        games[gameId].playerIds.pop();

        player.account.transfer(game.gameFee);

        games[gameId].bank = games[gameId].bank.sub(game.gameFee);

        emit PlayerChanged(player.account, gameId, playerId, player.isBot);
    }

    function cancelGame(uint gameId) external onlyOwnerOrManagerOrServer {
        Game memory game = games[gameId];
        require(game.status != GameStatus.ENDED && game.status != GameStatus.CANCELLED);

        uint playersCount = game.playerIds.length;

        for (uint i = playersCount - 1; i > 0; i--) {
            removePlayer(gameId, game.playerIds[i]);
        }
        removePlayer(gameId, game.playerIds[0]);

        games[gameId].status = GameStatus.CANCELLED;

        emit GameStatusChanged(gameId, GameStatus.CANCELLED);
    }

    function setWallet(address payable newWallet) external onlyOwnerOrManager {
        address old = wallet;
        wallet = newWallet;
        emit WalletChanged(old, wallet);
    }

    function setManager(address _manager) external onlyOwner {
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setToken(address _token) external onlyOwnerOrManager {
        emit TokenChanged(token, _token);
        token = _token;
        tokenContract = INoftToken(token);
    }

    function setServer(address _server) external onlyOwnerOrManager {
        emit ServerChanged(serverAddress, _server);
        serverAddress = _server;
    }

    function setRentAddress(address _rent) external onlyOwnerOrManager {
        emit RentChanged(rentAddress, _rent);
        rentAddress = _rent;
    }

    function setRentFeePercentage(uint _fee) external onlyOwnerOrManager {
        RENT_FEE_PERCENTAGE = _fee;
    }

    function setFeePercentage(uint _fee) external onlyOwnerOrManager {
        FEE_PERCENTAGE = _fee;
    }

    function setGameFees(uint[] calldata _fees) external onlyOwnerOrManager {
        GAME_FEES = _fees;
    }

    function setPlayersCounts(uint[] calldata _counts) external onlyOwnerOrManager {
        PLAYER_COUNTS = _counts;
    }

    function getGame(uint gameId) external view returns (
        uint id,
        GameStatus status,
        uint gameFee,
        uint winnerId,
        uint bank,
        uint playersCount,
        uint currentPlayerCount,
        address creator,
        bool leaveEnabled,
        bool botsEnabled,
        uint seed
    ) {
        Game memory game = games[gameId];

        id = game.id;
        status = game.status;
        gameFee = game.gameFee;
        winnerId = game.winnerId;
        bank = game.bank;
        playersCount = game.playersCount;
        creator = game.creator;
        botsEnabled = game.botsEnabled;
        leaveEnabled = game.leaveEnabled;
        currentPlayerCount = game.playerIds.length;
        seed = game.seed;
    }

    function getPlayer(uint playerId) external view returns (
        uint id,
        address account,
        uint tokenId,
        bool isRent,
        bool isBot,
        string memory strategy
    ) {
        Player memory player = players[playerId];

        id = player.id;
        account = player.account;
        tokenId = player.tokenId;
        isRent = player.isRent;
        isBot = player.isBot;
        strategy = player.strategy;
    }

    function getGamePlayer(uint gameId, uint index) external view returns (
        uint id,
        address account,
        uint tokenId,
        bool isRent,
        bool isBot,
        string memory strategy
    ) {
        Game memory game = games[gameId];
        Player memory player = players[game.playerIds[index]];

        id = player.id;
        account = player.account;
        tokenId = player.tokenId;
        isRent = player.isRent;
        isBot = player.isBot;
        strategy = player.strategy;
    }

    function getWallet() external view returns (address) {
        return wallet;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getTokenAddress() external view returns (address) {
        return token;
    }

    function getServerAddress() external view returns (address) {
        return serverAddress;
    }

    function getRentAddress() external view returns (address) {
        return rentAddress;
    }

    function getRentFeePercentage() external view returns (uint) {
        return RENT_FEE_PERCENTAGE;
    }

    function getFeePercentage() external view returns (uint) {
        return FEE_PERCENTAGE;
    }

    function getGameFee(uint index) external view returns (uint) {
        return GAME_FEES[index];
    }

    function getGameFeeLength() external view returns (uint) {
        return GAME_FEES.length;
    }

    function getPlayersCounts(uint index) external view returns (uint) {
        return PLAYER_COUNTS[index];
    }

    function getPlayersCountsLength() external view returns (uint) {
        return PLAYER_COUNTS.length;
    }

    function bytesToUint(bytes32 b) internal pure returns (uint number){
        number = 0;
        for (uint i = 0; i < b.length; i++) {
            number = number.add(uint(uint8(b[i])) * (2 ** (8 * (b.length - (i + 1)))));
        }
    }

    function getBotsCount(uint gameId) public view returns (uint count) {
        count = 0;

        for (uint i = 0; i < games[gameId].playerIds.length; i++) {
            if (players[games[gameId].playerIds[i]].isBot) {
                count += 1;
            }
        }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}