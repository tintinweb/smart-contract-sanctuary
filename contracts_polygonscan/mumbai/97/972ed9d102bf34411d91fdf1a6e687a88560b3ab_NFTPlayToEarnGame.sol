/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(getChainID())
        ));
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns(bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

}


contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

interface ILiquidityPoolManager {
    function depositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId
    ) external;
}


contract NFTPlayToEarnGame is EIP712MetaTransaction {
    using SafeMath for uint256;

    // The supported states in any game
    enum STATES {
        DRAFT,
        ACTIVE,
        ENDED
    }

    struct Game {
        address creator; // owner or creater of the game
        address nftToken; // address of the NFT token for this game
        uint256 numPlayers; // no. of players
        uint256 numPlayersJoined; // no. of players joined
        uint256 buyIn; // buy-in amount required for the game
        STATES state; // current state of the game
        uint256 creationTime; // creation time of the game
        uint256 startTime; // start time of the game
        uint256 endTime; // end time of the game
        bool isCancelled; // represents whether the game has been cancelled
        address winner; // address of the winner
        uint256 buyInPool; // buy in pool amount
    }

    struct Player {
        address player; // address of the player
        uint256 nftTokenId; // tokenId of the NFT token used for joining
    }

    uint256 public ownerSplit = 10; // split of owner in the pool of games
    uint256 public numGames = 0; // total no. of games created
    mapping(uint256 => Game) public games; // game id to game mapping
    mapping(uint256 => Player[]) public players; // game id to players mapping
    mapping(uint256 => mapping(uint256 => address)) public nftPlayer; // game id to ( nftTokenId to player) mapping
    mapping(address => uint256) public playerFunds; // amount deposited by address
    uint256 public ownerFunds; // funds that can be withdrawn by owner
    mapping(bytes => bool) depositHashes; // list of depositHashes to prevent replay attack
    
    address public ADMIN; // wallet address used by dapp to interact with smartcontract
    address public OWNER; // wallet address which deployed the smart contract
    address public WETH; // WETH address on Polygon network
    address LIQUIDITY_POOL_MANAGER_ADDRESS; // LiquidityPoolManager address on Polygon network

    constructor(string memory name, string memory version, address _weth, address _liquidityPoolManager) EIP712MetaTransaction(name, version) {
        WETH = _weth;
        LIQUIDITY_POOL_MANAGER_ADDRESS = _liquidityPoolManager;
        OWNER = msgSender();
    }

    modifier onlyOwner(){
        require(msgSender() == OWNER, "Only owner action.");
        _;
    }

    modifier onlyAdmin(){
        require(msgSender() == ADMIN, "Only admin action.");
        _;
    }

    event PlayerExitGame(uint256 gameId, address player);

    /**
     * @dev Creates a new game
     * @param _numPlayers no. of players in the game
     * @param _buyIn amount required to deposit for joining the game
     * @param _nftTokenId the tokenId of the NFT that owner holds
     */
    function createGame(
        uint256 _numPlayers,
        uint256 _buyIn,
        address _nftTokenAddress,
        uint256 _nftTokenId
    ) public onlyAdmin {
        address nftOwner = IERC721(_nftTokenAddress).ownerOf(_nftTokenId);
        require(nftOwner == msgSender(), "Player must hold the NFT token.");
        require(
            playerFunds[msgSender()] >= _buyIn,
            "Insuffient funds."
        );
        Game memory game = Game({
            creator: msgSender(),
            nftToken: _nftTokenAddress,
            numPlayers: _numPlayers,
            numPlayersJoined: 1,
            buyIn: _buyIn,
            state: STATES.DRAFT,
            creationTime: block.timestamp,
            startTime: 0,
            endTime: 0,
            isCancelled: false,
            winner: address(0),
            buyInPool: _buyIn
        });
        games[numGames] = game;
        Player memory player = Player({
            player: msgSender(),
            nftTokenId: _nftTokenId
        });
        players[numGames].push(player);
        nftPlayer[numGames][_nftTokenId] = msgSender();
        playerFunds[msgSender()] = playerFunds[msgSender()].sub(
            games[numGames].buyIn
        );
        numGames = numGames.add(1);
    }

    /**
     * @dev get info of any game
     * @param _gameId id of the game to get info
     * @return info of the game
     */
    function gameInfo(uint256 _gameId) external view returns (Game memory) {
        return games[_gameId];
    }

    /**
     * @dev Cancel a game which has not been started yet
     * @param _gameId id of the game
     */
    function cancelGame(uint256 _gameId) public onlyAdmin {
        require(
            games[_gameId].state == STATES.DRAFT,
            "Game cannot be cancelled."
        );
        require(
            !games[_gameId].isCancelled,
            "Game has already been cancelled."
        );
        games[_gameId].isCancelled = true;
        games[_gameId].state == STATES.ENDED;
        games[_gameId].buyInPool == 0;
        for (uint256 i = 0; i < games[_gameId].numPlayersJoined - 1; i++) {
            address player = players[_gameId][i].player;
            playerFunds[player] = playerFunds[player].add(
                games[_gameId].buyIn
            );
        }
    }

    /**
     * @dev Deposit funds before entering game
     * @param _amount amount to deposit
     */
    function depositFunds(uint256 _amount) public {
        IERC20(WETH).transferFrom(msgSender(), address(this), _amount);
        playerFunds[msgSender()] = playerFunds[msgSender()].add(
            _amount
        );
    }
    
    /**
     * @dev Associate cross-chain deposits
     * @param _player player to associate funds with
     * @param _amount amount of funds
     * @param _depositHash depositHash to prevent replay attack
     */
    function associatePlayerDeposit(address _player, uint256 _amount, bytes memory _depositHash) public onlyAdmin {
        require(!depositHashes[_depositHash], "The deposit hash is already recorded");
        playerFunds[_player] = playerFunds[_player].add(
            _amount
        );
        depositHashes[_depositHash] = true;
    }

    /**
     * @dev Withdraw funds after exiting game or if game has been cancelled/  terminated
     * @param _amount amount to withdraw
     */
    function withdrawFunds(uint256 _amount, bool onEthereum) public {
        require(
            _amount <= playerFunds[msgSender()],
            "Amount exceeds player funds."
        );
        if (onEthereum) {
            ILiquidityPoolManager(LIQUIDITY_POOL_MANAGER_ADDRESS).depositErc20(
                WETH,
                msgSender(),
                _amount,
                1
            );
        } else {
            IERC20(WETH).transfer(msgSender(), _amount);
        }
    }

    /**
     * @dev Join a game
     * @param _gameId id of the game
     * @param _nftTokenId the tokenId of the NFT that owner holds
     */
    function joinGame(uint256 _gameId, address _player, uint256 _nftTokenId) public onlyAdmin {
        require(games[_gameId].state == STATES.DRAFT, "Cannot join the game.");
        require(!games[_gameId].isCancelled, "Game has been cancelled.");
        require(
            games[_gameId].numPlayersJoined < games[_gameId].numPlayers,
            "Max limit reached for players."
        );
        address nftOwner = IERC721(games[_gameId].nftToken).ownerOf(_nftTokenId);
        require(nftOwner == _player, "Player must hold the NFT token.");
        require(
            nftPlayer[_gameId][_nftTokenId] == address(0),
            "This NFT has already been used to join the game."
        );
        require(
            playerFunds[_player] >= games[_gameId].buyIn,
            "Insuffient funds."
        );
        Player memory player = Player({
            player: _player,
            nftTokenId: _nftTokenId
        });
        players[_gameId].push(player);
        games[_gameId].numPlayersJoined = games[_gameId].numPlayersJoined.add(1);
        nftPlayer[_gameId][_nftTokenId] = _player;
        games[_gameId].buyInPool =games[_gameId].buyInPool.add(games[_gameId].buyIn);
        playerFunds[_player] = playerFunds[_player].sub(
            games[_gameId].buyIn
        );
        if (games[_gameId].numPlayersJoined == games[_gameId].numPlayers) {
            activateGame(_gameId);
        }
    }

    /**
     * @dev Exit a game
     * @param _gameId id of the game
     */
    function exitGame(uint256 _gameId, address _player) public onlyAdmin {
        require(games[_gameId].state == STATES.DRAFT, "Cannot exit the game");
        require(!games[_gameId].isCancelled, "Game has been cancelled.");
        require(
            games[_gameId].numPlayersJoined > 0,
            "No player has joined the game yet."
        );
        uint256 index = games[_gameId].numPlayersJoined;
        for (uint256 i = 0; i < games[_gameId].numPlayersJoined; i++) {
            if (players[_gameId][i].player == _player) {
                index = i;
                break;
            }
        }
        require(
            index != games[_gameId].numPlayersJoined,
            "Player is not present in this game."
        );
        uint256 nftTokenId = players[_gameId][index].nftTokenId;
        nftPlayer[_gameId][nftTokenId] = address(0);
        players[_gameId][index] = players[_gameId][games[_gameId].numPlayersJoined - 1];
        delete players[_gameId][games[_gameId].numPlayersJoined - 1];
        games[_gameId].numPlayersJoined = games[_gameId].numPlayersJoined.sub(1);
        games[_gameId].buyInPool =games[_gameId].buyInPool.sub(games[_gameId].buyIn);
        playerFunds[_player] = playerFunds[_player].add(
            games[_gameId].buyIn
        );
        if (games[_gameId].numPlayersJoined == 0) {
            cancelGame(_gameId);
        }
        emit PlayerExitGame(_gameId, _player);
    }

    /**
     * @dev Activate a game
     * @param _gameId id of the game
     */
    function activateGame(uint256 _gameId) public onlyAdmin {
        require(
            games[_gameId].state == STATES.DRAFT,
            "Cannot activate the game."
        );
        require(!games[_gameId].isCancelled, "Game has been cancelled");
        require(
            games[_gameId].numPlayersJoined == games[_gameId].numPlayers,
            "All the players have not joined yet."
        );
        games[_gameId].startTime = block.timestamp;
        games[_gameId].state = STATES.ACTIVE;
    }

    /**
     * @dev End a game
     * @param _gameId id of the game
     * @param _winner winner of the game
     */
    function endGame(uint256 _gameId, address _winner, bool onEthereum) public onlyAdmin {
        require(games[_gameId].state == STATES.ACTIVE, "Cannot end the game");
        uint256 index = games[_gameId].numPlayersJoined;
        for (uint256 i = 0; i < games[_gameId].numPlayersJoined; i++) {
            if (players[_gameId][i].player == _winner) {
                index = i;
                break;
            }
        }
        require(
            index != games[_gameId].numPlayersJoined,
            "Winner must be a player in the game."
        );
        games[_gameId].winner = _winner;
        uint poolAmount = games[_gameId].buyIn.mul(games[_gameId].numPlayers);
        uint256 ownerMoney = poolAmount.mul(ownerSplit).div(100);
        uint256 winnerAmount = poolAmount.sub(ownerMoney);
        if (onEthereum) {
            ILiquidityPoolManager(LIQUIDITY_POOL_MANAGER_ADDRESS).depositErc20(
                WETH,
                _winner,
                winnerAmount,
                1
            );
        } else {
            IERC20(WETH).transfer(_winner, winnerAmount);
        }
        ownerFunds = ownerFunds.add(ownerMoney);
        games[_gameId].endTime = block.timestamp;
        games[_gameId].state = STATES.ENDED;
    }

    /**
     * @dev Terminate a game which has started atleast 48 hrs ago without declaring any winner
     * @param _gameId id of the game
     */
    function terminateGame(uint256 _gameId) public onlyAdmin {
        uint256 timePassedFromStartTime = block.timestamp -
            games[_gameId].startTime;
        require(
            timePassedFromStartTime > 172800,
            "Cannot terminate game before 48 hrs from start time."
        );
        games[_gameId].state = STATES.ENDED;
        for (uint256 i = 0; i < games[_gameId].numPlayersJoined - 1; i++) {
            address player = players[_gameId][i].player;
            playerFunds[player] = playerFunds[player].add(
                games[_gameId].buyIn
            );
        }
    }

    /**
     * @dev Update the owner
     * @param _newOwner address of the new owner
     */
    function updateOwner(address _newOwner) public onlyOwner {
        OWNER = _newOwner;
    }

    /**
     * @dev Update the admin
     * @param _newAdmin address of the new admin
     */
    function updateAdmin(address _newAdmin) public onlyOwner {
        ADMIN = _newAdmin;
    }

    /**
     * @dev Update split of owner
     * @param _newOwnerSplit split percentage
     */
    function updateOwnerSplit(uint256 _newOwnerSplit) public onlyOwner {
        require(_newOwnerSplit <= 100, "Invalid split");
        ownerSplit = _newOwnerSplit;
    }

    /**
     * @dev Withdraw all owner funds
     */
    function ownerWithdraw(bool onEthereum) public onlyOwner {
        if (onEthereum) {
            ILiquidityPoolManager(LIQUIDITY_POOL_MANAGER_ADDRESS).depositErc20(
                WETH,
                msgSender(),
                ownerFunds,
                1
            );
        } else {
            IERC20(WETH).transfer(msgSender(), ownerFunds);
        }
        ownerFunds = 0;
    }

}