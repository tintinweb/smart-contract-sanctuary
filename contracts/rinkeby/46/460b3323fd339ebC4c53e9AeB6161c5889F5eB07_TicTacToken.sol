/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/TicTacToken.sol
// SPDX-License-Identifier: MIT AND Unlicense
pragma solidity >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// src/interfaces/INFT.sol
/* pragma solidity ^0.8.0; */

/* import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; */

interface INFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
}

////// src/interfaces/IToken.sol
/* pragma solidity ^0.8.0; */

/* import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; */

interface IToken is IERC20 {
    function mintTTT(address to, uint256 amount) external;
}

////// src/TicTacToken.sol
/* pragma solidity ^0.8.0; */

/* import "./interfaces/IToken.sol"; */
/* import "./interfaces/INFT.sol"; */

contract TicTacToken {
    struct Game {
        address playerX;
        address playerO;
        uint256 turns;
        uint256[9] board;
    }

    mapping(uint256 => Game) public games;
    mapping(uint256 => uint256) public gameIdByTokenId;
    IToken public token;
    INFT public nft;

    uint256 internal constant X = 1;
    uint256 internal constant O = 2;
    uint256 internal constant POINTS_PER_WIN = 300 ether;
    uint256 internal nextGameId;
    mapping(address => uint256) internal winCountByAddress;
    mapping(address => uint256) internal pointCountByAddress;

    constructor(address _token, address _nft) {
        token = IToken(_token);
        nft = INFT(_nft);
    }

    modifier requirePlayers(uint256 gameId) {
        require(
            msg.sender == _game(gameId).playerX ||
                msg.sender == _game(gameId).playerO,
            "Must be authorized player"
        );
        _;
    }

    function newGame(address _playerX, address _playerO) public {
        nextGameId++;
        games[nextGameId].playerX = _playerX;
        games[nextGameId].playerO = _playerO;
        mintGameToken(_playerX, _playerO);
    }

    function mintGameToken(address _playerX, address _playerO) internal {
        uint256 playerOToken = 2 * nextGameId;
        uint256 playerXToken = playerOToken - 1;
        nft.mint(_playerO, playerOToken);
        nft.mint(_playerX, playerXToken);
        gameIdByTokenId[playerOToken] = nextGameId;
        gameIdByTokenId[playerXToken] = nextGameId;
    }

    function markSpace(
        uint256 gameId,
        uint256 i,
        uint256 symbol
    ) public requirePlayers(gameId) {
        require(_validSpace(i), "Invalid space");
        require(_validSymbol(symbol), "Invalid symbol");
        require(_validTurn(gameId, symbol), "Not your turn");
        require(_emptySpace(gameId, i), "Already marked");
        _game(gameId).turns++;
        _game(gameId).board[i] = symbol;

        uint256 winningSymbol = winner(gameId);
        if (winningSymbol != 0) {
            address winnerAddress = _getPlayerAddress(gameId, winningSymbol);
            _incrementWinCount(winnerAddress);
            _incrementPointCount(winnerAddress);
            token.mintTTT(winnerAddress, POINTS_PER_WIN);
        }
    }

    function board(uint256 gameId) public view returns (uint256[9] memory) {
        return games[gameId].board;
    }

    function currentTurn(uint256 gameID) public view returns (uint256) {
        return (_game(gameID).turns % 2 == 0) ? X : O;
    }

    function winner(uint256 gameId) public view returns (uint256) {
        return _checkWins(gameId);
    }

    function _validSpace(uint256 i) internal pure returns (bool) {
        return i < 9;
    }

    function _validTurn(uint256 gameId, uint256 symbol)
        internal
        view
        returns (bool)
    {
        return currentTurn(gameId) == symbol;
    }

    function _emptySpace(uint256 gameId, uint256 i)
        internal
        view
        returns (bool)
    {
        return _game(gameId).board[i] == 0;
    }

    function _validSymbol(uint256 symbol) internal pure returns (bool) {
        return symbol == X || symbol == O;
    }

    function _checkWins(uint256 gameId) internal view returns (uint256) {
        uint256[8] memory wins = [
            _row(gameId, 0),
            _row(gameId, 1),
            _row(gameId, 2),
            _col(gameId, 0),
            _col(gameId, 1),
            _col(gameId, 2),
            _diag(gameId),
            _antiDiag(gameId)
        ];
        for (uint256 i = 0; i < wins.length; i++) {
            if (wins[i] == 1) {
                return X;
            } else if (wins[i] == 8) {
                return O;
            }
        }
        return 0;
    }

    function _row(uint256 gameId, uint256 row) internal view returns (uint256) {
        require(row <= 2, "Invalid row");
        uint256 pos = row * 3;
        return
            _game(gameId).board[pos] *
            _game(gameId).board[pos + 1] *
            _game(gameId).board[pos + 2];
    }

    function _col(uint256 gameId, uint256 col) internal view returns (uint256) {
        require(col <= 2, "Invalid col");
        return
            _game(gameId).board[col] *
            _game(gameId).board[col + 3] *
            _game(gameId).board[col + 6];
    }

    function _diag(uint256 gameId) internal view returns (uint256) {
        return
            _game(gameId).board[0] *
            _game(gameId).board[4] *
            _game(gameId).board[8];
    }

    function _antiDiag(uint256 gameId) internal view returns (uint256) {
        return
            _game(gameId).board[2] *
            _game(gameId).board[4] *
            _game(gameId).board[6];
    }

    function winCount(address playerAddress) public view returns (uint256) {
        return winCountByAddress[playerAddress];
    }

    function pointCount(address playerAddress) public view returns (uint256) {
        return pointCountByAddress[playerAddress];
    }

    function _incrementWinCount(address playerAddress) private {
        winCountByAddress[playerAddress]++;
    }

    function _incrementPointCount(address playerAddress) private {
        pointCountByAddress[playerAddress] += POINTS_PER_WIN;
    }

    function _getPlayerAddress(uint256 gameId, uint256 playerSymbol)
        private
        view
        returns (address)
    {
        if (playerSymbol == X) {
            return _game(gameId).playerX;
        } else if (playerSymbol == O) {
            return _game(gameId).playerO;
        } else {
            return address(0);
        }
    }

    function _game(uint256 gameId) private view returns (Game storage) {
        return games[gameId];
    }
}