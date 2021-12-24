/**
 *Submitted for verification at polygonscan.com on 2021-12-23
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
    function CalculateAccumulatePerShare(uint _amount) external;
    function maxProfit() external returns(uint256);
}

contract CrashGame is Ownable {

    struct Bet{
        address better;
        address betToken;
        uint256 betAmount;
        uint256 cashoutPoint;
        uint256 timestamp;
        bool win;
    }

    struct Game {
        uint256 gameId;
        uint256 crashPoint;
        uint256 startGameTimestamp;
        uint256 endGameTimestamp;
        mapping(address=>Bet) bets;
        address[] betters;
    }

    struct GameInfo {
        uint256 gameId;
        uint256 crashPoint;
        uint256 startGameTimestamp;
        uint256 endGameTimestamp;
        address[] betters;
    }

    mapping (uint256 => Game) games;
    mapping (address => bool) public isAcceptableToken;
    IHousePool public housepool;
    address public recipient;
    uint256 recipientShare = 5000;
    uint256 constant DECIMALS = 10000;

    constructor(IHousePool _housepool, address _recipient) Ownable() {
        housepool = _housepool;
        recipient = _recipient;
    }

    function startGame(uint256 gameId) external onlyOwner {
        require(games[gameId].gameId==0,"Game already exists");

        games[gameId].gameId = gameId;
        games[gameId].startGameTimestamp = block.timestamp;
    }

    function placeBet(uint256 gameId, uint256 autoCashoutPoint) external payable isValidBet(msg.value, autoCashoutPoint) {
        uint256 betAmount = msg.value;
        require(games[gameId].startGameTimestamp != 0, "Game not started.");
        require(games[gameId].endGameTimestamp == 0, "Game already ended.");
        require(games[gameId].bets[_msgSender()].cashoutPoint == 0, "Bet already placed.");
        require(betAmount > 0, "Invalid bet amount.");
        require(autoCashoutPoint > 101, "Invalid cashout point.");

        games[gameId].bets[_msgSender()] = Bet(_msgSender(), address(0), betAmount, autoCashoutPoint, block.timestamp, false);
        games[gameId].betters.push(_msgSender());
    }

    function placeBet(uint256 gameId, uint256 betAmount, address betToken, uint256 autoCashoutPoint) external  isValidBet(betAmount, autoCashoutPoint) {
        require(isAcceptableToken[betToken], "Invalid token.");
        require(games[gameId].startGameTimestamp != 0, "Game not started.");
        require(games[gameId].endGameTimestamp == 0, "Game already ended.");
        require(games[gameId].bets[_msgSender()].cashoutPoint == 0, "Bet already placed.");
        require(betAmount > 0, "Invalid bet amount.");
        require(autoCashoutPoint > 101, "Invalid cashout point.");

        games[gameId].bets[_msgSender()] = Bet(_msgSender(), betToken, betAmount, autoCashoutPoint, block.timestamp, false);
        games[gameId].betters.push(_msgSender());
        IERC20(betToken).transferFrom(_msgSender(), address(this), betAmount);
    }

    function manualCashout(uint256 gameId, uint256 manualCashoutPoint) external {
        require(games[gameId].startGameTimestamp!=0,"Game not started.");
        require(games[gameId].endGameTimestamp==0,"Game already ended.");
        require(games[gameId].bets[_msgSender()].cashoutPoint!=0,"Bet not placed.");
        require(games[gameId].bets[_msgSender()].cashoutPoint>manualCashoutPoint,"Invalid cashout amount.");

        games[gameId].bets[_msgSender()].cashoutPoint = manualCashoutPoint;
    }

    function endGame(uint256 gameId, uint256 crashPoint) external payable onlyOwner{
        require(games[gameId].startGameTimestamp!=0,"Game not started.");
        
        games[gameId].crashPoint = crashPoint;
        address[] memory betters=games[gameId].betters;
        for(uint256 i=0;i<betters.length;i++){
            if(games[gameId].bets[betters[i]].cashoutPoint<=crashPoint){
                games[gameId].bets[betters[i]].win=true;
                returnProfit(games[gameId].bets[betters[i]]);
            }
            else{
                games[gameId].bets[betters[i]].win=false;
                returnLoss(games[gameId].bets[betters[i]]);
            }
        }
        games[gameId].endGameTimestamp = block.timestamp;
    }

    function returnProfit(Bet memory bet) internal {
        uint256 returnAmt = getReturnAmount(bet.betAmount,bet.cashoutPoint);
        housepool.Transfer(returnAmt-bet.betAmount);
        payable(bet.better).transfer(returnAmt);
    }

    function returnLoss(Bet memory bet) internal {
        uint256 recipientAmount = bet.betAmount * recipientShare / DECIMALS;
        payable(recipient).transfer(recipientAmount);
        payable(address(housepool)).transfer(bet.betAmount-recipientAmount);
        housepool.CalculateAccumulatePerShare(bet.betAmount-recipientAmount);
    }

    function getReturnAmount(uint256 betAmount, uint256 cashoutPoint) internal pure returns(uint256) {
        return betAmount * cashoutPoint / 100;
    }

    function getBetInfo(uint256 gameId, address better) public view returns(Bet memory){
        return games[gameId].bets[better];
    }

   function getGameInfo(uint256 gameId) public view returns(GameInfo memory){
        return GameInfo(games[gameId].gameId,
                        games[gameId].crashPoint,
                        games[gameId].startGameTimestamp,
                        games[gameId].endGameTimestamp,
                        games[gameId].betters);
    }

    function setAcceptableToken(address tokenAddress, bool value) external onlyOwner {
        isAcceptableToken[tokenAddress] = value;
    }
    
    modifier isValidBet(uint256 betAmount, uint256 cashoutPoint){
        require(getReturnAmount(betAmount,cashoutPoint)<=housepool.maxProfit(),"Invalid Bet.");
        _;
    }
    
    receive() external payable {
    }

}