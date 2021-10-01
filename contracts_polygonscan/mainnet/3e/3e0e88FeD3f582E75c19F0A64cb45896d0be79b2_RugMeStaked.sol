/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract RugMeStaked  is Ownable, ReentrancyGuard{
    
    modifier noContract(address _addr){
      uint32 size;
      assembly {
        size := extcodesize(_addr)
      }
      require (size == 0);
      _;
    }
    
    event GameCreated(uint256 indexed gameId);
    event GameReady(uint256 indexed gameId);
    event GameStarted(uint256 indexed gameId);
    event GameCancelled(uint256 indexed gameId);
    event RugPulled(uint256 indexed gameId , uint256 indexed amount, address indexed rugger);
    event LotteryWon(uint256 indexed amount, address indexed winner);
    
    address public disposalAddress;
    
    uint256 public gameDuration = 2 minutes;
    uint256 public entryFee = 0.5 ether; // 0.5 of staked token

    uint256 public gameIndex = 0;
    mapping (uint256 => Game) public games;
    mapping (address => uint256[]) public playerGameIds;
    mapping (address => uint256) public playerCurrentGame;
    mapping (address => uint256) public playerTotalValueRugged;
    mapping (address => uint256) public playerTotaleRugsPulled;

    uint256 public totalRugsPulled = 0;
    uint256 public totalValueRugged = 0;
    uint256 public totalValueDisposed = 0;

    bool createGame  = true;
    Game nextGame;

    mapping (uint256 => address[]) public dailyPlayers;
    mapping (uint256 => uint256) public jackpot;
    mapping (uint256 => bool) public lotteryComplete;
    uint256 public latestJackpot;
    address public latestWinner;
    
    
    address public stakedTokenAddress = address(0x0);
    IERC20 stakedToken;
    
    // created = p1 joined
    // ready = p2 joined
    // InProgress = start by either pllayer 
    // Rugged
    // Cancelled
    enum Status {
        Created,
        Ready,
        InProgress,
        Rugged,
        Cancelled
    }

    struct Game {
        Status status;
        uint256 startTime;
        uint256 endTime;
        address p1;
        address p2;
        address rugger;
        uint256 ruggedValue;
        uint256 entryFee;
        uint256 valuePerSecond;
    }
    
    constructor(address _stakedTokenAddress){
        disposalAddress = msg.sender;
        stakedTokenAddress = _stakedTokenAddress;
        stakedToken = IERC20(stakedTokenAddress);
    }
    
    // creates a new game or joins the next one.
    function play() public payable noContract(msg.sender) nonReentrant returns (uint256 gameId) //no reenttrant // no contract 
    {
        require(playerCurrentGame[msg.sender]==0, "One game at a time!");
        require(stakedToken.balanceOf(msg.sender)>=entryFee, "Insufficient Balance");
        stakedToken.transferFrom(msg.sender,address(this), entryFee);
            
        if (createGame==true){
             // set up the next game
            nextGame = 
                Game({
                status: Status.Created,
                startTime: 0,
                endTime: 0,
                p1: msg.sender,
                p2: address(0x0),
                rugger: address(0x0),
                ruggedValue: 0,
                entryFee: entryFee,
                valuePerSecond: (entryFee*2)/gameDuration
                });
            gameIndex++;
            createGame=false;
        }else{
            require(nextGame.p1!=msg.sender , "Can't play yourself!");
            nextGame.status = Status.Ready;
            nextGame.p2 = msg.sender;
            createGame=true;
        }
        playerCurrentGame[msg.sender]=gameIndex;
        games[gameIndex]=nextGame;
       return gameIndex;
    } 
    
    
    function cancel(uint256 _gameId) public nonReentrant
    {
        Game memory g =  games[_gameId];
        require (g.p1==msg.sender || g.p2==msg.sender , "Not a player in this game.");
        require (g.status==Status.Created || g.status==Status.Ready , "Game cannot be cancelled.");
        
        playerCurrentGame[g.p1]=0;
        
        // return the entry fee
        stakedToken.transfer(g.p1,g.entryFee);

        if (g.p2!=address(0x0)){
            playerCurrentGame[g.p2]=0;
            stakedToken.transfer(g.p2,g.entryFee);
        }
        
        if (g.status==Status.Created && createGame==false){
            createGame=true;
        }
        g.status=Status.Cancelled;
        games[_gameId]=g;
        emit GameCancelled(_gameId);

    }
    
    
    
    function start(uint256 _gameId) public {
        Game memory g =  games[_gameId];
        require (g.p1==msg.sender || g.p2==msg.sender , "Not a player in this game.");
        require (g.status==Status.Ready , "Game not ready. Already started?");
        g.startTime = block.timestamp;
        g.endTime = g.startTime + gameDuration;
        g.status = Status.InProgress;
        games[_gameId] = g;
        
        emit GameStarted(_gameId);
    }
    
    function ruggableValue(uint256 _gameId) public view returns (uint256 amount){
        Game memory g =  games[_gameId];
        require (g.status==Status.InProgress, "Game not in progress");
        
        uint256 totalPot = g.entryFee*2;
        if (block.timestamp>=g.endTime) return totalPot;
        
        uint256 timeElapsedSeconds = block.timestamp-g.startTime;
        uint256 value = g.valuePerSecond*timeElapsedSeconds; 
        return value;
    }
    
    
    function rug(uint256 _gameId) public nonReentrant returns (bool success) // no rentrant
    {
        require (_gameId > 0 && _gameId <= gameIndex, "No such game.");
        Game memory g =  games[_gameId];
        require (g.p1==msg.sender || g.p2==msg.sender , "Not a player in this game.");
        require (g.status==Status.InProgress , "Game not In Progress");
        
        uint256 amount = ruggableValue(_gameId);
        uint256 totalPot = g.entryFee*2;
        uint256 excess =  totalPot-amount;
        
        if (amount>0){
            
                 totalValueRugged+=amount;
                 totalRugsPulled++;
                 g.status = Status.Rugged;
                 g.rugger = msg.sender;
                 g.ruggedValue = amount;
                 games[_gameId] = g;
                 playerTotalValueRugged[msg.sender]+=amount;
                 playerTotaleRugsPulled[msg.sender]++;
                 stakedToken.transfer(msg.sender,amount);
                emit RugPulled(_gameId , amount , msg.sender);
             
        }
       
        if (excess>0){
            handleExcess(excess);
            
            // players are only entered into the lottery if there is a winner and something will be disposed.
            dailyPlayers[today()].push(g.p1);
            dailyPlayers[today()].push(g.p2);
        }
        
        playerCurrentGame[g.p1]=0;
        playerCurrentGame[g.p2]=0;
        return true;
    } 
    
    function handleExcess(uint256 _excess) internal {
        // 25% into today's jackpot
        uint256 toJackpot = _excess/4;
        jackpot[today()]+= toJackpot;
        
        uint256 toDispose=_excess-toJackpot;
        totalValueDisposed+=toDispose;
        // dispose
        dispose(toDispose);
    }

    function currentJackpot () public view returns (uint256){
        return jackpot[today()];
    }
    
    function doLottery() public {
        require (dailyPlayers[yesterday()].length >0, "No players yesterday.");
        require (jackpot[yesterday()] > 0, "0 Jackpot");
        require (lotteryComplete[yesterday()]==false, "Lottery already complete.");

        // pseudo random pick of index
        // it doesn't matter because people are choosing their own position
        // the more times someone plays the bigger a chance to win
        uint256 winnerIndex = random(dailyPlayers[yesterday()].length);
        address winner = dailyPlayers[yesterday()][winnerIndex];
        uint256 jackpotAmount = jackpot[yesterday()];
        latestJackpot = jackpotAmount;
        latestWinner = winner;
        lotteryComplete[yesterday()]=true;
        
        stakedToken.transfer(winner,jackpotAmount);
        
    }
    
    function dispose(uint256 _amount) private {
       stakedToken.transfer(disposalAddress,_amount);
    }
    
    function today() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
    
    function yesterday() public view returns (uint256) {
        return (block.timestamp - 1 days)/ 1 days;
    }
    
    uint nonce;

    function random(uint256 range) public returns (uint256) {
        uint rnd = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % range;
        nonce++;
        return rnd;
    }

    function getPlayerGameIds(address _player) public view returns(uint256[] memory gameIds){
        return playerGameIds[_player];
    }
    
    // any benefactor can fund the lottery
    function fundLottery(uint256 _amount) public {
        stakedToken.transferFrom(msg.sender,address(this), _amount);
        jackpot[today()]+= _amount;
    }
    
    // admin functions
    function setGameDuration(uint256 _duration) external onlyOwner {
        gameDuration = _duration;
    }
    
    function setEntryFee(uint256 _entryFee) external onlyOwner {
       entryFee =  _entryFee;
    }
    
    function setDisposalAddress(address _disposalAddress) external onlyOwner {
       disposalAddress =  _disposalAddress;
    }

    
}