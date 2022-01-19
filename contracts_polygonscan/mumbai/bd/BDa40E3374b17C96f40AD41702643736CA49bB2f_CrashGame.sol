/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// SPDX-License-Identifier: None
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Crash.sol


pragma solidity ^0.8.0;



interface IERC20{
    function transfer(address to, uint amount) external returns(bool);
    function transferFrom(address from, address to, uint amount) external returns(bool);
}

interface IHousePool{
    function Transfer(uint _amount) external;
    function deposit() external payable returns(bool success);
    function maxProfit() external returns(uint256);
}

contract CrashGame is Ownable, Pausable {

    enum GameStatus { NONEXISTENT, CREATED, STARTED, ENDED }

    struct Bet{
        address better;
        uint256 betAmount;
        uint256 cashoutPoint;
        uint256 timestamp;
        uint256 winAmount;
        bool isManualCashout;
        bool win;
    }

    struct Game {
        string  gameId;
        uint256 crashPoint;
        uint256 createGameTimestamp;
        uint256 startGameTimestamp;
        uint256 endGameTimestamp;
        mapping(address=>Bet) bets;
        address[] betters;
    }

    struct GameInfo {
        string  gameId;
        uint256 crashPoint;
        uint256 createGameTimestamp;
        uint256 startGameTimestamp;
        uint256 endGameTimestamp;
        GameStatus gameStatus;
        address[] betters;
    }

    mapping (string => Game) games;
    IHousePool public housepool;
    address public recipient;
    uint256 recipientShare = 5000;
    uint256 constant DECIMALS = 10000;
    uint256 lastCreatedGame;
    mapping (address => bool) public isAdmin;

    event GameCreated(string indexed gameId);
    event GameStarted(string indexed gameId);
    event GameEnded(string indexed gameId);

    event BetPlaced(string indexed gameId, address indexed better);
    event ManualCashout(string indexed gameId, address indexed better);

    event AdminUpdated(address admin, bool value);

    constructor(IHousePool _housepool, address _recipient) Ownable() {
        housepool = _housepool;
        recipient = _recipient;
        isAdmin[_msgSender()] = true;
    }

    function updateAdmin(address admin, bool value) external onlyOwner {
        isAdmin[admin] = value;
        emit AdminUpdated(admin, value);
    }

    function createGame(string calldata gameId) external onlyAdmin whenNotPaused {
        require(idMatch(games[gameId].gameId,""), "Game already exists");

        games[gameId].gameId = gameId;
        games[gameId].createGameTimestamp = block.timestamp;
        emit GameCreated(gameId);
    }

    function startGame(string calldata gameId) external onlyAdmin whenNotPaused {
        require(idMatch(games[gameId].gameId, gameId), "Invalid Game Id.");
        require(games[gameId].createGameTimestamp != 0, "Game not created.");
        require(games[gameId].startGameTimestamp == 0, "Game already started.");

        games[gameId].startGameTimestamp = block.timestamp;
        emit GameStarted(gameId);
    }

    function placeBet(string calldata gameId, uint256 autoCashoutPoint) external payable isValidBet(msg.value, autoCashoutPoint) whenNotPaused {
        uint256 betAmount = msg.value;
        require(idMatch(games[gameId].gameId, gameId), "Invalid Game Id.");
        require(games[gameId].startGameTimestamp == 0, "Game has started.");
        require(games[gameId].endGameTimestamp == 0, "Game already ended.");
        require(games[gameId].bets[_msgSender()].cashoutPoint == 0, "Bet already placed.");
        require(betAmount > 0, "Invalid bet amount.");
        require(autoCashoutPoint > 101, "Invalid cashout point.");

        games[gameId].bets[_msgSender()] = Bet(_msgSender(), betAmount, autoCashoutPoint, block.timestamp, 0, false, false);
        games[gameId].betters.push(_msgSender());
        emit BetPlaced(gameId, _msgSender());
    }

    function manualCashout(string calldata gameId, uint256 manualCashoutPoint) whenNotPaused external {
        require(games[gameId].startGameTimestamp!=0,"Game not started.");
        require(games[gameId].endGameTimestamp==0,"Game already ended.");
        require(games[gameId].bets[_msgSender()].cashoutPoint!=0,"Bet not placed.");
        require(games[gameId].bets[_msgSender()].cashoutPoint>manualCashoutPoint,"Invalid cashout amount.");

        games[gameId].bets[_msgSender()].cashoutPoint = manualCashoutPoint;
        games[gameId].bets[_msgSender()].isManualCashout = true;
        emit ManualCashout(gameId, _msgSender());
    }

    function endGame(string calldata gameId, uint256 crashPoint) external payable onlyAdmin whenNotPaused {
        require(games[gameId].startGameTimestamp!=0,"Game not started.");

        uint256 housepoolDepositAmount=0;
        uint256 housepoolWithdrawAmount=0;
        uint256 recipientAmount=0;
        games[gameId].crashPoint = crashPoint;
        address[] memory betters=games[gameId].betters;
        for(uint256 i=0;i<betters.length;i++){
            if(games[gameId].bets[betters[i]].cashoutPoint<=crashPoint){
                games[gameId].bets[betters[i]].win=true;
                ( uint housepoolAmt, uint betterAmt )=returnProfit(games[gameId].bets[betters[i]]);
                housepoolWithdrawAmount += housepoolAmt;
                games[gameId].bets[betters[i]].winAmount = betterAmt;
            }
            else{
                games[gameId].bets[betters[i]].win=false;
                ( uint housepoolAmt, uint recipientAmt )=returnLoss(games[gameId].bets[betters[i]]);
                housepoolDepositAmount += housepoolAmt;
                recipientAmount += recipientAmt;
            }
        }
        
        if(housepoolDepositAmount>0)
            housepool.deposit{value:housepoolDepositAmount}();

        if(housepoolWithdrawAmount>0)
            housepool.Transfer(housepoolWithdrawAmount);

        if(recipientAmount>0)
            payable(recipient).transfer(recipientAmount);

        games[gameId].endGameTimestamp = block.timestamp;

        transferToUser(gameId);
        emit GameEnded(gameId);
    }

    function returnProfit(Bet memory bet) internal pure returns(uint,uint) {
        uint256 returnAmt = getReturnAmount(bet.betAmount,bet.cashoutPoint);
        return (returnAmt-bet.betAmount,returnAmt);
    }

    function returnLoss(Bet memory bet) internal view returns(uint,uint) {
        uint256 recipientAmount = bet.betAmount * recipientShare / DECIMALS;
        return (bet.betAmount-recipientAmount, recipientAmount);
    }

    function transferToUser(string memory gameId) internal returns(bool) {
        address[] memory betters=games[gameId].betters;
        for(uint256 i=0;i<betters.length;i++){
            uint256 amount = games[gameId].bets[betters[i]].winAmount;
            if(amount > 0)
                payable(betters[i]).transfer(amount);
        }
        return true;
    }

    function getReturnAmount(uint256 betAmount, uint256 cashoutPoint) internal pure returns(uint256) {
        return betAmount * cashoutPoint / 100;
    }

    function getBetInfo(string calldata gameId, address better) external view returns(Bet memory){
        return games[gameId].bets[better];
    }

    function getGameStatus(string calldata gameId) public view returns(GameStatus){
        if(games[gameId].createGameTimestamp==0){
            return GameStatus.NONEXISTENT;
        }
        if(games[gameId].startGameTimestamp==0){
            return GameStatus.CREATED;
        }
        if(games[gameId].endGameTimestamp==0){
            return GameStatus.STARTED;
        }
        return GameStatus.ENDED;
    }

    function getGameInfo(string calldata gameId) external view returns(GameInfo memory){
        return GameInfo(games[gameId].gameId,
            games[gameId].crashPoint,
            games[gameId].createGameTimestamp,
            games[gameId].startGameTimestamp,
            games[gameId].endGameTimestamp,
            getGameStatus(gameId),
            games[gameId].betters);
    }

    modifier isValidBet(uint256 betAmount, uint256 cashoutPoint){
        require(getReturnAmount(betAmount,cashoutPoint)<=housepool.maxProfit(),"Invalid Bet.");
        _;
    }

    function idMatch(string memory id1, string memory id2) internal pure returns (bool){
        return keccak256(abi.encodePacked((id1))) == keccak256(abi.encodePacked(id2));
    }

    receive() external payable {
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(isAdmin[_msgSender()], "Caller is not the admin");
        _;
    }
    /**
 * @dev Pause the contract. Stops the pausable functions from being accessed.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpause the contract. Allows the pausable functions to be accessed.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }


}