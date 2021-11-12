// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PokeMeReady.sol";
import "./RandomNumberGenerator.sol";
import "./SwapperEtherToLink.sol";
import "./Enums/Status.sol";
import "./Structs/Game.sol";
import "./Structs/VRFRequestInfo.sol";

contract RevolverRoll is SwapperEtherToLink, RandomNumberGenerator, PokeMeReady {

    using SafeERC20 for IERC20;

    event PlayerEnterGame(address indexed player, uint256 indexed gameId, uint256 amout);
    event PlayerExitGame(address indexed player, uint256 indexed gameId);
    event StartGame(uint256 indexed gameId);
    event FinishGame(address indexed winner, uint256 indexed gameId, uint8 rounds);
    event Claimed(address indexed winner, uint256 indexed gameId, uint256 amout);
    event MinBetChange(uint128 minBet);

    uint128 public minBet = type(uint128).min;

    mapping(uint256 => Game) public games;
    uint256 public lastGameId;
    mapping(bytes32 => VRFRequestInfo) public vrfRequestInfo;

    constructor(
        address _pokeMe,
        address _uniswapRouter,
        address _linkToken,
        address _weth9Token,
        address _vrfCoordinator,
        bytes32 _rngKeyHash,
        uint128 _rngFee,
        uint24 _uniswapPoolFee
    )
        RandomNumberGenerator(_vrfCoordinator, _linkToken, _rngKeyHash, _rngFee)
        SwapperEtherToLink(_uniswapRouter, _weth9Token, _linkToken, _uniswapPoolFee)
        PokeMeReady(_pokeMe)
    { }

    /**
     * @notice Create a game, pay the bet and assigned to player1
     */
    function createGame() external payable {
        require(msg.value >= minBet , "BET_IS_LOW");
        
        lastGameId++;
        games[lastGameId] = Game({
            status: Status.WaitingToPlayer2,
            player1: msg.sender,
            player2: address(0),
            winner: address(0),
            amountCollected: msg.value, 
            randomNumber: 0,
            vrfRequestId: 0
        });

        emit PlayerEnterGame(msg.sender, lastGameId, msg.value);
    }

    /**
     * @notice Exit game and refound bet
     * @param _gameId: Id of an existing game
     * @dev only player1 when player2 is not ready
     */
    function exitGame(uint256 _gameId) external {
        require(_gameId <= lastGameId, "ID_NOT_VALID");
        require(
            games[_gameId].status == Status.WaitingToPlayer2 ||
            games[_gameId].status == Status.PlayersReady ||
            games[_gameId].status == Status.Canceled
        , "GAME_IS_NOT_IN_THE_CORRECT_STATE");

        games[_gameId].status = Status.Canceled;

        address player;
        if( games[_gameId].player1 == msg.sender ) {
            player = msg.sender;
            games[_gameId].player1 = address(0);
        } else if (games[_gameId].player2 == msg.sender) {
            player = msg.sender;
            games[_gameId].player2 = address(0);
        } else {
            revert("YOU_ARE_NOT_PLAYER");
        }

        uint256 bet;
        if (
            games[_gameId].player1 == address(0) &&
            games[_gameId].player2 == address(0)
        ) {
            bet = games[_gameId].amountCollected;
        } else {
            bet = games[_gameId].amountCollected/2;
        }
        
        games[_gameId].amountCollected -= bet;
        (bool success,) = player.call{value: bet}("");
        require(success, "FAILED_TO_SEND_ETHER");

        emit PlayerExitGame(msg.sender, _gameId);
    }

    /**
     * @notice Pay the bet and assigned to player2
     * @param _gameId: Id of an existing game
     */
    function enterGame(uint256 _gameId) external payable {
        require(_gameId <= lastGameId, "ID_NOT_VALID");
        require(games[_gameId].status == Status.WaitingToPlayer2, "GAME_IS_NOT_IN_THE_CORRECT_STATE");
        require(games[_gameId].player1 != msg.sender, "YOU_ARE_ALREADY_IN_THE_GAME");
        require(games[_gameId].amountCollected == msg.value, "NOT_SUFFICIENT_ETHER_AMOUNT");

        games[_gameId].status = Status.PlayersReady;
        
        games[_gameId].player2 = msg.sender;
        games[_gameId].amountCollected += msg.value;

        emit PlayerEnterGame(msg.sender, _gameId, msg.value);
    }

    /**
     * @notice Request a random number to vrf chainlink for the games
     * @param _gameIds: Ids of an existing games
     * @dev Only called by gelato when any game have players are ready
     * @dev The transaction fee, gelato fee and vrf fee is paid from the amount collected
     * @dev The Link token for pay the vrf request is getting from uniswap
     */
    function startGames(uint256[] memory _gameIds) external onlyPokeMe {
        require(_gameIds.length <= 100, "TOO_MANY_GAME_IDS");
        for(uint256 i = 0; i < _gameIds.length; i++) {
            require(_gameIds[i] <= lastGameId, "ID_NOT_VALID");
            require(games[_gameIds[i]].status == Status.PlayersReady, "GAME_IS_NOT_IN_THE_CORRECT_STATE");
            
            games[_gameIds[i]].status = Status.Started;

            emit StartGame(_gameIds[i]);
        }

        uint256 etherSwapped = swapExactOutputSingle(rngFee);
        uint256 amountReduction = etherSwapped/_gameIds.length;
        bytes32 vrfRequestId = getRandomNumber();
        vrfRequestInfo[vrfRequestId].gameIds = _gameIds;

        require(IERC20(linkToken).balanceOf(address(this)) == 0, "NOT_ALL_LINK_TOKENS_ARE_USED");

        uint256 fee = payFee();
        amountReduction -= fee/_gameIds.length;
    
        for(uint256 i = 0; i < _gameIds.length; i++) {
            games[_gameIds[i]].vrfRequestId = vrfRequestId;
            games[_gameIds[i]].amountCollected -= amountReduction;
            require(games[_gameIds[i]].amountCollected > 0, "INSUFFICIENT_OF_AMOUNT_COLLECTED");
        }
    }

    /**
     * @notice Read the random number and check the winner, make bet claimeable
     * @param _gameIds: Ids of an existing games
     * @dev Only called by gelato when the random number are ready
     * @dev The transaction fee and gelato fee is paid from the amount collected
     */
    function finishGames(uint256[] memory _gameIds) external onlyPokeMe {
        require(_gameIds.length <= 100, "TOO_MANY_GAME_IDS");
        for(uint256 i = 0; i < _gameIds.length; i++) {            
            require(_gameIds[i] <= lastGameId, "ID_NOT_VALID");
            require(games[_gameIds[i]].status == Status.Started, "GAME_IS_NOT_IN_THE_CORRECT_STATE");
            uint256 randomNumber = games[_gameIds[i]].randomNumber;
            require(randomNumber > 0, "RANDOM_NUMBER_IS_NOT_READY");
            require(block.number - vrfRequestInfo[games[_gameIds[i]].vrfRequestId].responseBlock > 20, "RANDOM_NUMBER_NOT_CONFIRMED");

            games[_gameIds[i]].status = Status.Claimable;

            //Game Logic
            uint8 rounds = 0; 
            for(uint8 nIdx = 1; nIdx<78; nIdx+=2){
                uint256 numberPlayer1 = (randomNumber % 10 ** nIdx) / 10 ** (nIdx-1);
                if (numberPlayer1 == 0){
                    rounds = (nIdx/2)+1;
                    games[_gameIds[i]].winner = games[_gameIds[i]].player2;
                    break;
                }
                uint256 numberPlayer2 = randomNumber % 10 ** (nIdx+1) / 10 ** nIdx;
                if (numberPlayer2 == 0){
                    rounds = (nIdx/2)+1;
                    games[_gameIds[i]].winner = games[_gameIds[i]].player1;
                    break;
                }
            }
            if(games[_gameIds[i]].winner == address(0)){
                uint256 lastNumber = randomNumber % 10;
                if (lastNumber > 4) {
                    rounds = 39;
                    games[_gameIds[i]].winner = games[_gameIds[i]].player2;
                }
                else
                {
                    rounds = 39;
                    games[_gameIds[i]].winner = games[_gameIds[i]].player1;
                }
            }

            emit FinishGame(games[_gameIds[i]].winner, _gameIds[i], rounds); 
        }

        uint256 fee = payFee();
        uint256 amountReduction = fee/_gameIds.length;
        
        for(uint256 i = 0; i < _gameIds.length; i++) {
            games[_gameIds[i]].amountCollected -= amountReduction;
        }
    }

    /**
     * @notice Withdraw the prize of the game
     * @param _gameId: Id of an existing game
     * @dev Only callable by game winner
     */
    function claimPrize(uint256 _gameId) external {
        require(_gameId <= lastGameId, "ID_NOT_VALID");
        require(games[_gameId].status == Status.Claimable, "GAME_IS_NOT_IN_THE_CORRECT_STATE");
        require(games[_gameId].winner == msg.sender, "YOU_ARE_NOT_THE_WINNER");

        games[_gameId].status = Status.Closed;

        uint256 prize = games[_gameId].amountCollected;
        games[_gameId].amountCollected = 0;
        (bool success,) = games[_gameId].winner.call{value: prize}("");
        require(success, "FAILED_TO_SEND_ETHER");

        emit Claimed(msg.sender, _gameId, prize);
    }

    /**
     * @notice Change the min bet
     * @param _minBet: new min bet
     * @dev Only callable by owner
     */
    function setMinBet(uint128 _minBet) external onlyOwner {
        minBet = _minBet;
        emit MinBetChange(_minBet);
    }

    /**
     * @notice Withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != linkToken, "CANNOT_WITHDRAW_LINK_TOKENS");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice Get Games Ids on status WaitingToPlayer2
     * @return _gameIds Ids of games
     */
    function getIdsGamesOnWaitingPlayer() external view returns(uint256[] memory _gameIds) {
        uint256 countGames = 0;
        for (uint256 i = 0; i <= lastGameId; i++) {
            if (
                games[i].status == Status.PlayersReady &&
                games[i].amountCollected/2 >= minBet
            ) {
                countGames++;
            }
        }
        _gameIds = new uint256[](countGames);
        uint256 gamesIdx = 0;
        for (uint256 i = 0; i <= lastGameId; i++) {
            if (
                games[i].status == Status.PlayersReady &&
                games[i].amountCollected/2 >= minBet
            ) {
                _gameIds[gamesIdx] = i;
                gamesIdx++;
            }
        }
    }
    
    /**
     * @notice Get Games Ids on status Started with random number ready
     * @return _gameIds Ids of games
     */
    function getIdsGamesOnStartedAndRNReady() external view returns(uint256[] memory _gameIds) {              
        uint256 countGames = 0;
        for (uint256 i = 0; i <= lastGameId; i++){
            if (games[i].status == Status.Started && 
                vrfRequestInfo[games[i].vrfRequestId].responseBlock != 0 && 
                block.number - vrfRequestInfo[games[i].vrfRequestId].responseBlock > 20) 
            {
                countGames++;
            }
        }
        _gameIds = new uint256[](countGames);
        uint256 gamesIdx = 0;
        for (uint256 i = 0; i <= lastGameId; i++){
            if (
                games[i].status == Status.Started && 
                vrfRequestInfo[games[i].vrfRequestId].responseBlock != 0 && 
                block.number - vrfRequestInfo[games[i].vrfRequestId].responseBlock > 20
            ) {
                _gameIds[gamesIdx] = i;
                gamesIdx++;
            }
        }
    }

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        uint256[] memory gameIds = vrfRequestInfo[_requestId].gameIds;
        require(gameIds.length > 0, "NO_VALID_REQUEST_ID");
        for(uint256 i = 0; i < gameIds.length; i++){
            uint256 gameId = gameIds[i];
            games[gameId].randomNumber = uint256(keccak256(abi.encode(_randomness, i)));
        }
        vrfRequestInfo[_requestId].responseBlock = block.number;
    }

    /**
     * @notice Withdraw ether sent to the contract
     * @dev Only callable by owner
     * @dev Deleted on production
     */
    function whitdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "FAILED_TO_SEND_ETHER");
    }

    /**
     * @notice Self destruct the contract
     * @dev Only callable by owner
     * @dev Deleted on production
     */
    function disable() external onlyOwner{
        selfdestruct(payable(msg.sender));
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Interfaces/IUniswapRouter.sol";

abstract contract SwapperEtherToLink is Ownable {

    event MaxEtherFoSwapChange(uint64 _maxEtherForSwap);
    event UniswapPoolFeeChange(uint24 _uniswapPoolFee);

    IUniswapRouter public immutable uniswapRouter;
    address public immutable weth9Token;
    address public immutable linkToken;
    uint64 public maxEtherForSwap = type(uint64).max;
    uint24 public uniswapPoolFee;

    constructor(address _uniswapRouter, address _weth9Token, address _linkToken, uint24 _uniswapPoolFee) {
        uniswapRouter = IUniswapRouter(_uniswapRouter);
        weth9Token = _weth9Token;
        linkToken = _linkToken;
        uniswapPoolFee = _uniswapPoolFee;
    }

    /**
     * @notice Change the max ether for swap to link
     * @param _maxEtherForSwap: new max ether for swap
     * @dev Only callable by owner
     */
    function setMaxEtherForSwap(uint64 _maxEtherForSwap) external onlyOwner {
        maxEtherForSwap = _maxEtherForSwap;
        emit MaxEtherFoSwapChange(_maxEtherForSwap);
    }

    /**
     * @notice Change the uniswap pool fee
     * @param _uniswapPoolFee: new uniswap pool fee
     * @dev Only callable by owner
     */
    function setUniswapPoolFee(uint24 _uniswapPoolFee) external onlyOwner {
        uniswapPoolFee = _uniswapPoolFee;
        emit UniswapPoolFeeChange(_uniswapPoolFee);
    }

    /**
     * @notice Swap Ether for Link
     * @param _amountOut: Exact amount of Link
     * @return _finalAmountIn Exact amount of ether swapped
     */
    function swapExactOutputSingle(uint256 _amountOut) internal returns (uint256 _finalAmountIn) {
        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: weth9Token,
                tokenOut: linkToken,
                fee: uniswapPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: maxEtherForSwap,
                sqrtPriceLimitX96: 0
            });
        _finalAmountIn = uniswapRouter.exactOutputSingle{value: maxEtherForSwap}(params);
        uniswapRouter.refundETH();
    }

    receive() external payable {}

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

struct VRFRequestInfo {
    uint256[] gameIds;
    uint256 responseBlock;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../Enums/Status.sol";

struct Game {
    Status status;
    address player1;
    address player2;
    address winner;
    uint256 amountCollected;
    uint256 randomNumber;
    bytes32 vrfRequestId;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

abstract contract RandomNumberGenerator is VRFConsumerBase, Ownable {

    event RNGFeeChange(uint256 rngFee);

    bytes32 internal immutable rngKeyHash;
    uint128 public rngFee;

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _rngKeyHash, uint128 _rngFee) 
    VRFConsumerBase(_vrfCoordinator, _linkToken) 
    {
        rngFee = _rngFee;
        rngKeyHash = _rngKeyHash;
    }

    /**
     * @notice Change the VRF fee
     * @param _fee: new fee (in LINK)
     * @dev Only callable by owner
     */
    function setVRFFee(uint128 _fee) external onlyOwner {
        rngFee = _fee;
        emit RNGFeeChange(rngFee);
    }

    /**
     * @notice Requests randomness
     */
    function getRandomNumber() internal returns(bytes32) {
        require(rngKeyHash != bytes32(0), "MIST_HAVE_VALID_KEY_HASH");
        require(LINK.balanceOf(address(this)) >= rngFee, "NOT_ENOUGH_LINK_TOKENS");
        return requestRandomness(rngKeyHash, rngFee);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IPokeMe.sol";

abstract contract PokeMeReady is Ownable{

    event MaxGelatoFeeChange(uint64 _maxGelatoFee);

    address public immutable pokeMe;
    address payable public immutable gelato;
    uint64 maxGelatoFee = type(uint64).max;

    constructor(address _pokeMe) {
        require(_pokeMe != address(0), "ADDRESS_ZERO");
        pokeMe = _pokeMe;
        gelato = IPokeMe(_pokeMe).gelato();
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "ONLY_POKEME_ADDRESS");
        _;
    }

    /**
     * @notice Change the max gelato fee
     * @param _maxGelatoFee: new max gelato fee
     * @dev Only callable by owner
     */
    function setMaxGelatoFee(uint64 _maxGelatoFee) external onlyOwner {
        maxGelatoFee = _maxGelatoFee;
        emit MaxGelatoFeeChange(_maxGelatoFee);
    }

    /**
     * @notice Pay Gelato fee, include transaction fee
     */
    function payFee() internal returns (uint256 fee) {
        (fee,) = IPokeMe(pokeMe).getFeeDetails();
        require(fee <= maxGelatoFee, "TRANSACTION_EXCEEDED_MAX_GELATO_FEE");
        (bool success,) = gelato.call{value: fee}("");
        require(success, "FAILED_TO_SEND_ETHER");
    }

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IPokeMe {
    function gelato() external view returns (address payable);    
    function getFeeDetails() external view returns (uint256, address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

enum Status {
    NoExisting,
    WaitingToPlayer2,
    PlayersReady,
    Started,
    Claimable,
    Closed,
    Canceled
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}