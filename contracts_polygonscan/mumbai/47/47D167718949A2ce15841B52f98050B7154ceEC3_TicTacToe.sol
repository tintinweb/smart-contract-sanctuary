// SPDX-License-Identifier: MIT
// Borrowed from https://github.com/schemar/TicTacToe

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../TicTacToeGasStation/TicTacToeGasStation.sol";

// TicTacToe is a solidity implementation of the tic tac toe game.
// You can find the rules at https://en.wikipedia.org/wiki/Tic-tac-toe
contract TicTacToe is ERC2771Context {
    // Players enumerates all possible players
    enum Players {
        None,
        PlayerOne,
        PlayerTwo
    }
    // Winners enumerates all possible winners
    enum Winners {
        None,
        PlayerOne,
        PlayerTwo,
        Draw
    }

    struct Player {
        address publicAddress;
        string imageUrl;
        address contractAddress;
        uint256 tokenId;
    }

    // Game stores the state of a round of tic tac toe.
    // As long as `winner` is `None`, the game is not over.
    // `playerTurn` defines who may go next.
    // Player one must make the first move.
    // The `board` has the size 3x3 and in each cell, a player
    // can be listed. Initializes as `None` player, as that is the
    // first element in the enumeration.
    // That means that players are free to fill in any cell at the
    // start of the game.
    struct Game {
        Player playerOne;
        Player playerTwo;
        Winners winner;
        Players playerTurn;
        Players[3][3] board;
    }

    // games stores all the games.
    // Games that are already over as well as games that are still running.
    // It is possible to iterate over all games, as the keys of the mapping
    // are known to be the integers from `1` to `nrOfGames`.
    mapping(uint256 => Game) private games;
    // nrOfGames stores the total number of games in this contract.
    uint256 private nrOfGames;

    mapping(address => Player) public players;

    // GameCreated signals that `creator` created a new game with this `gameId`.
    event GameCreated(uint256 gameId, address creator);
    // PlayerJoinedGame signals that `player` joined the game with the id `gameId`.
    // That player has the player number `playerNumber` in that game.
    event PlayerJoinedGame(uint256 gameId, address player, uint8 playerNumber);
    // PlayerMadeMove signals that `player` filled in the board of the game with
    // the id `gameId`. She did so at the coordinates `xCoordinate`, `yCoordinate`.
    event PlayerMadeMove(uint256 gameId, address player, uint256 xCoordinate, uint256 yCoordinate);
    // GameOver signals that the game with the id `gameId` is over.
    // The winner is indicated by `winner`. No more moves are allowed in this game.
    event GameOver(uint256 gameId, Winners winner);

    constructor(TicTacToeGasStation forwarder) ERC2771Context(address(forwarder)) {}

    function register(
        string calldata imageUrl,
        address contractAddress,
        uint256 tokenId
    ) external {
        address player = _msgSender();
        players[player] = Player({
            publicAddress: player,
            imageUrl: imageUrl,
            contractAddress: contractAddress,
            tokenId: tokenId
        });
    }

    // newGame creates a new game and returns the new game's `gameId`.
    // The `gameId` is required in subsequent calls to identify the game.
    function newGame() external returns (uint256 gameId) {
        Game memory game;
        game.playerTurn = Players.PlayerOne;

        nrOfGames++;
        games[nrOfGames] = game;

        emit GameCreated(nrOfGames, _msgSender());

        return nrOfGames;
    }

    // joinGame lets the sender of the message join the game with the id `gameId`.
    // It returns `success = true` when joining the game was possible and
    // `false` otherwise.
    // `reason` indicates why a game was joined or not joined.
    function joinGame(uint256 _gameId) external returns (bool success, string memory reason) {
        if (_gameId > nrOfGames) {
            return (false, "No such game exists.");
        }

        Player storage player = players[_msgSender()];
        Game storage game = games[_gameId];

        // Assign the new player to slot 1 if it is still available.
        if (game.playerOne.publicAddress == address(0)) {
            game.playerOne = player;

            emit PlayerJoinedGame(_gameId, player.publicAddress, uint8(Players.PlayerOne));

            return (true, "Joined as player one.");
        }

        // If slot 1 is taken, assign the new player to slot 2 if it is still available.
        if (game.playerTwo.publicAddress == address(0)) {
            game.playerTwo = player;
            emit PlayerJoinedGame(_gameId, player.publicAddress, uint8(Players.PlayerTwo));

            return (true, "Joined as player two. Player one can make the first move.");
        }

        return (false, "All seats taken.");
    }

    // makeMove inserts a player on the game board.
    // The player is identified as the sender of the message.
    function makeMove(
        uint256 _gameId,
        uint256 _xCoordinate,
        uint256 _yCoordinate
    ) external returns (bool success, string memory reason) {
        if (_gameId > nrOfGames) {
            return (false, "No such game exists.");
        }

        Game storage game = games[_gameId];

        // Any winner other than `None` means that no more moves are allowed.
        if (game.winner != Winners.None) {
            return (false, "The game has already ended.");
        }

        // Only the player whose turn it is may make a move.
        if (_msgSender() != getCurrentPlayer(game).publicAddress) {
            // TODO: what if the player is not present in the game at all?
            return (false, "It is not your turn.");
        }

        // Players can only make moves in cells on the board that have not been played before.
        if (game.board[_xCoordinate][_yCoordinate] != Players.None) {
            return (false, "There is already a mark at the given coordinates.");
        }

        // Now the move is recorded and the according event emitted.
        game.board[_xCoordinate][_yCoordinate] = game.playerTurn;
        emit PlayerMadeMove(_gameId, _msgSender(), _xCoordinate, _yCoordinate);

        // Check if there is a winner now that we have a new move.
        Winners winner = calculateWinner(game.board);
        if (winner != Winners.None) {
            // If there is a winner (can be a `Draw`) it must be recorded in the game and
            // the corresponding event must be emitted.
            game.winner = winner;
            emit GameOver(_gameId, winner);

            return (true, "The game is over.");
        }

        // A move was made and there is no winner yet.
        // The next player should make her move.
        nextPlayer(game);

        return (true, "");
    }

    // getCurrentPlayer returns the address of the player that should make the next move.
    // Returns the `0x0` address if it is no player's turn.
    function getCurrentPlayer(Game storage _game) private view returns (Player memory player) {
        if (_game.playerTurn == Players.PlayerOne) {
            return _game.playerOne;
        }

        if (_game.playerTurn == Players.PlayerTwo) {
            return _game.playerTwo;
        }
    }

    // calculateWinner returns the winner on the given board.
    // The returned winner can be `None` in which case there is no winner and no draw.
    function calculateWinner(Players[3][3] memory _board) private pure returns (Winners winner) {
        // First we check if there is a victory in a row.
        // If so, convert `Players` to `Winners`
        // Subsequently we do the same for columns and diagonals.
        Players player = winnerInRow(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        player = winnerInColumn(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        player = winnerInDiagonal(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        // If there is no winner and no more space on the board,
        // then it is a draw.
        if (isBoardFull(_board)) {
            return Winners.Draw;
        }

        return Winners.None;
    }

    // winnerInRow returns the player that wins in any row.
    // To win in a row, all cells in the row must belong to the same player
    // and that player must not be the `None` player.
    function winnerInRow(Players[3][3] memory _board) private pure returns (Players winner) {
        for (uint8 x = 0; x < 3; x++) {
            if (_board[x][0] == _board[x][1] && _board[x][1] == _board[x][2] && _board[x][0] != Players.None) {
                return _board[x][0];
            }
        }

        return Players.None;
    }

    // winnerInColumn returns the player that wins in any column.
    // To win in a column, all cells in the column must belong to the same player
    // and that player must not be the `None` player.
    function winnerInColumn(Players[3][3] memory _board) private pure returns (Players winner) {
        for (uint8 y = 0; y < 3; y++) {
            if (_board[0][y] == _board[1][y] && _board[1][y] == _board[2][y] && _board[0][y] != Players.None) {
                return _board[0][y];
            }
        }

        return Players.None;
    }

    // winnerInDiagoral returns the player that wins in any diagonal.
    // To win in a diagonal, all cells in the diaggonal must belong to the same player
    // and that player must not be the `None` player.
    function winnerInDiagonal(Players[3][3] memory _board) private pure returns (Players winner) {
        if (_board[0][0] == _board[1][1] && _board[1][1] == _board[2][2] && _board[0][0] != Players.None) {
            return _board[0][0];
        }

        if (_board[0][2] == _board[1][1] && _board[1][1] == _board[2][0] && _board[0][2] != Players.None) {
            return _board[0][2];
        }

        return Players.None;
    }

    // isBoardFull returns true if all cells of the board belong to a player other
    // than `None`.
    function isBoardFull(Players[3][3] memory _board) private pure returns (bool isFull) {
        for (uint8 x = 0; x < 3; x++) {
            for (uint8 y = 0; y < 3; y++) {
                if (_board[x][y] == Players.None) {
                    return false;
                }
            }
        }

        return true;
    }

    // nextPlayer changes whose turn it is for the given `_game`.
    function nextPlayer(Game storage _game) private {
        if (_game.playerTurn == Players.PlayerOne) {
            _game.playerTurn = Players.PlayerTwo;
        } else {
            _game.playerTurn = Players.PlayerOne;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/*
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract TicTacToeGasStation is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("TicTacToeGasStation", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.gas / 63);

        return (success, returndata);
    }
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}