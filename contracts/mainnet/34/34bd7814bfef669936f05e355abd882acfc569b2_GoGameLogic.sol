pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/payment/PullPayment.sol

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

// File: contracts/GoGlobals.sol

/// @title The base contract for EthernalGo, contains the admin functions and the globals used throught the game
/// @author https://www.EthernalGo.com
/// @dev See the GoGameLogic and GoBoardMetaDetails contract documentation to understand the actual game mechanics.
contract GoGlobals is Ownable, PullPayment, Destructible, Pausable {

    // Used for simplifying capture calculations
    uint8 constant MAX_UINT8 = 255;

    // Used to dermine player color and who is up next
    enum PlayerColor {None, Black, White}

    ///    @dev Board status is a critical concept that determines which actions can be taken within each phase
    ///        WaitForOpponent - When the first player has registered and waiting for a second player
    ///        InProgress - The match is on! The acting player can choose between placing a stone or passing (or resigning)
    ///        WaitingToResolve - Both players chose to pass their turn and we are waiting for the winner to ask the contract for  score count
    ///        BlackWin, WhiteWin, Draw - Pretty self explanatory
    ///        Canceled - The first player who joined the board is allowed to cancel a match if no opponent has joined yet
    enum BoardStatus {WaitForOpponent, InProgress, WaitingToResolve, BlackWin, WhiteWin, Draw, Canceled}

    // We staretd with a 9x9 rows
    uint8 constant BOARD_ROW_SIZE = 9;
    uint8 constant BOARD_SIZE = BOARD_ROW_SIZE ** 2;

    // We use a shrinked board size to optimize gas costs
    uint8 constant SHRINKED_BOARD_SIZE = 21;

    // These are the shares each player and EthernalGo are getting for each game
    uint public WINNER_SHARE;
    uint public HOST_SHARE;
    uint public HONORABLE_LOSS_BONUS;

    // Each player gets PLAYER_TURN_SINGLE_PERIOD x PLAYER_START_PERIODS to act. These may change according to player feedback and network conjunction to optimize the playing experience
    uint  public PLAYER_TURN_SINGLE_PERIOD = 4 minutes;
    uint8 public PLAYER_START_PERIODS = 5;
    
    // We decided to restrict the table stakes to several options to allow for easier match-making
    uint[] public tableStakesOptions;

    // This is the main data field that contains access to all of the GoBoards that were created
    GoBoard[] internal allBoards;

    // The CFO is the only account that is allowed to withdraw funds
    address public CFO;

    // This is the main board structure and is instantiated for every new game
    struct GoBoard {        
        // We use the last update to determine how long has it been since the player could act
        uint lastUpdate;
        
        // The table stakes marks how much ETH each participant needs to pay to register for the board
        uint tableStakes;
        
        // The board balance keeps track of how much ETH this board has in order to see if we already distributed the payments for this match
        uint boardBalance;

        // Black and white player addresses
        address blackAddress;
        address whiteAddress;

        // Black and white time periods remaining (initially they will be PLAYER_START_PERIODS)
        uint8 blackPeriodsRemaining;
        uint8 whitePeriodsRemaining;

        // Keep track of double pass to finish the game
        bool didPassPrevTurn;
        
        // Keep track of double pass to finish the game
        bool isHonorableLoss;

        // Who&#39;s next
        PlayerColor nextTurnColor;

        // Use a mapping to figure out which stone is set in which position. (Positions can be 0-BOARD_SIZE)
        // @dev We decided not use an array to minimize the storage cost
        mapping(uint8=>uint8) positionToColor;

        // The board&#39;s current status        
        BoardStatus status;
    }

    /// @notice The constructor is called with our inital values, they will probably change but this is what had in mind when developing the game.
    function GoGlobals() public Ownable() PullPayment() Destructible() {

        // Add initial price tiers so from variouos ranges
        addPriceTier(0.5 ether);
        addPriceTier(1 ether);
        addPriceTier(5 ether);

        // These are the inital shares we&#39;ve had in mind when developing the game
        updateShares(950, 50, 5);
        
        // The CFO will be the owner, but it will change soon after the contract is deployed
        CFO = owner;
    }

    /// @notice In case we need extra price tiers (table stakes where people can play) we can add additional ones
    /// @param price the price for the new price tier in WEI
    function addPriceTier(uint price) public onlyOwner {
        tableStakesOptions.push(price);
    }

    /// If we need to update price tiers
    /// @param priceTier the tier index from the array
    /// @param price the new price to set
    function updatePriceTier(uint8 priceTier, uint price) public onlyOwner {
        tableStakesOptions[priceTier] = price;
    }

    /// @notice If we need to adjust the amounts players or EthernalGo gets for each game
    /// @param newWinnerShare the winner&#39;s share (out of 1000)
    /// @param newHostShare EthernalGo&#39;s share (out of 1000)
    /// @param newBonusShare Bonus that comes our of EthernalGo and goes to the loser in case of an honorable loss (out of 1000)
    function updateShares(uint newWinnerShare, uint newHostShare, uint newBonusShare) public onlyOwner {
        require(newWinnerShare + newHostShare == 1000);
        WINNER_SHARE = newWinnerShare;
        HOST_SHARE = newHostShare;
        HONORABLE_LOSS_BONUS = newBonusShare;
    }

    /// @notice Separating the CFO and the CEO responsibilities requires the ability to set the CFO account
    /// @param newCFO the new CFO
    function setNewCFO(address newCFO) public onlyOwner {
        require(newCFO != 0);
        CFO = newCFO;
    }

    /// @notice Separating the CFO and the CEO responsibilities requires the ability to set the CFO account
    /// @param secondsPerPeriod The number of seconds we would like each period to last
    /// @param numberOfPeriods The number of of periods each player initially has
    function updateGameTimes(uint secondsPerPeriod, uint8 numberOfPeriods) public onlyOwner {

        PLAYER_TURN_SINGLE_PERIOD = secondsPerPeriod;
        PLAYER_START_PERIODS = numberOfPeriods;
    }

    /// @dev Convinience function to access the shares
    function getShares() public view returns(uint, uint, uint) {
        return (WINNER_SHARE, HOST_SHARE, HONORABLE_LOSS_BONUS);
    }
}

// File: contracts/GoBoardMetaDetails.sol

/// @title This contract manages the meta details of EthernalGo. 
///     Registering to a board, splitting the revenues and other day-to-day actions that are unrelated to the actual game
/// @author https://www.EthernalGo.com
/// @dev See the GoGameLogic to understand the actual game mechanics and rules
contract GoBoardMetaDetails is GoGlobals {
    
    /// @dev The player added to board event can be used to check upon registration success
    event PlayerAddedToBoard(uint boardId, address playerAddress);
    
    /// @dev The board updated status can be used to get the new board status
    event BoardStatusUpdated(uint boardId, BoardStatus newStatus);
    
    /// @dev The player withdrawn his accumulated balance 
    event PlayerWithdrawnBalance(address playerAddress);
    
    /// @dev Simple wrapper to return the number of boards in total
    function getTotalNumberOfBoards() public view returns(uint) {
        return allBoards.length;
    }

    /// @notice We would like to easily and transparantly share the game&#39;s statistics with anyone and present on the web-app
    function getCompletedGamesStatistics() public view returns(uint, uint) {
        uint completed = 0;
        uint ethPaid = 0;
        
        // @dev Go through all the boards, we start with 1 as it&#39;s an unsigned int
        for (uint i = 1; i <= allBoards.length; i++) {

            // Get the current board
            GoBoard storage board = allBoards[i - 1];
            
            // Check if it was a victory, otherwise it&#39;s not interesting as the players just got their deposit back
            if ((board.status == BoardStatus.BlackWin) || (board.status == BoardStatus.WhiteWin)) {
                ++completed;

                // We need to query the table stakes as the board&#39;s balance will be zero once a game is finished
                ethPaid += board.tableStakes.mul(2);
            }
        }

        return (completed, ethPaid);
    }

    /// @dev At this point there is no support for returning dynamic arrays (it&#39;s supported for web3 calls but not for internal testing) so we will "only" present the recent 50 games per player.
    uint8 constant PAGE_SIZE = 50;

    /// @dev Make sure this board is in waiting for result status
    modifier boardWaitingToResolve(uint boardId){
        require(allBoards[boardId].status == BoardStatus.WaitingToResolve);
        _;
    }

    /// @dev Make sure this board is in one of the end of game states
    modifier boardGameEnded(GoBoard storage board){
        require(isEndGameStatus(board.status));
        _;
    }

    /// @dev Make sure this board still has balance
    modifier boardNotPaid(GoBoard storage board){
        require(board.boardBalance > 0);
        _;
    }

    /// @dev Make sure this board still has a spot for at least one player to join
    modifier boardWaitingForPlayers(uint boardId){
        require(allBoards[boardId].status == BoardStatus.WaitForOpponent &&
                (allBoards[boardId].blackAddress == 0 || 
                 allBoards[boardId].whiteAddress == 0));
        _;
    }

    /// @dev Restricts games for the allowed table stakes
    /// @param value the value we are looking for to register
    modifier allowedValuesOnly(uint value){
        bool didFindValue = false;
        
        // The number of tableStakesOptions can change hence it has to be dynamic
        for (uint8 i = 0; i < tableStakesOptions.length; ++ i) {
           if (value == tableStakesOptions[i])
            didFindValue = true;
        }

        require (didFindValue);
        _;
    }

    /// @dev Checks a status if and returns if it&#39;s an end game
    /// @param status the value we are checking
    /// @return true if it&#39;s an end-game status
    function isEndGameStatus(BoardStatus status) public pure returns(bool) {
        return (status == BoardStatus.BlackWin) || (status == BoardStatus.WhiteWin) || (status == BoardStatus.Draw) || (status == BoardStatus.Canceled);
    }

    /// @dev Gets the update time for a board
    /// @param boardId The id of the board to check
    /// @return the update timestamp in seconds
    function getBoardUpdateTime(uint boardId) public view returns(uint) {
        GoBoard storage board = allBoards[boardId];
        return (board.lastUpdate);
    }

    /// @dev Gets the current board status
    /// @param boardId The id of the board to check
    /// @return the current board status
    function getBoardStatus(uint boardId) public view returns(BoardStatus) {
        GoBoard storage board = allBoards[boardId];
        return (board.status);
    }

    /// @dev Gets the current balance of the board
    /// @param boardId The id of the board to check
    /// @return the current board balance in WEI
    function getBoardBalance(uint boardId) public view returns(uint) {
        GoBoard storage board = allBoards[boardId];
        return (board.boardBalance);
    }

    /// @dev Sets the current balance of the board, this is internal and is triggerred by functions run by external player actions
    /// @param board The board to update
    /// @param boardId The board&#39;s Id
    /// @param newStatus The new status to set
    function updateBoardStatus(GoBoard storage board, uint boardId, BoardStatus newStatus) internal {    
        
        // Save gas if we accidentally are trying to update to an existing update
        if (newStatus != board.status) {
            
            // Set the new board status
            board.status = newStatus;
            
            // Update the time (important for start and finish states)
            board.lastUpdate = now;

            // If this is an end game status
            if (isEndGameStatus(newStatus)) {

                // Credit the players accoriding to the board score
                creditBoardGameRevenues(board);
            }

            // Notify status update
            BoardStatusUpdated(boardId, newStatus);
        }
    }

    /// @dev Overload to set the board status when we only have a boardId
    /// @param boardId The boardId to update
    /// @param newStatus The new status to set
    function updateBoardStatus(uint boardId, BoardStatus newStatus) internal {
        updateBoardStatus(allBoards[boardId], boardId, newStatus);
    }

    /// @dev Gets the player color given an address and board (overload for when we only have boardId)
    /// @param boardId The boardId to check
    /// @param searchAddress The player&#39;s address we are searching for
    /// @return the player&#39;s color
    function getPlayerColor(uint boardId, address searchAddress) internal view returns (PlayerColor) {
        return (getPlayerColor(allBoards[boardId], searchAddress));
    }
    
    /// @dev Gets the player color given an address and board
    /// @param board The board to check
    /// @param searchAddress The player&#39;s address we are searching for
    /// @return the player&#39;s color
    function getPlayerColor(GoBoard storage board, address searchAddress) internal view returns (PlayerColor) {

        // Check if this is the black player
        if (board.blackAddress == searchAddress) {
            return (PlayerColor.Black);
        }

        // Check if this is the white player
        if (board.whiteAddress == searchAddress) {
            return (PlayerColor.White);
        }

        // We aren&#39;t suppose to try and get the color of a player if they aren&#39;t on the board
        revert();
    }

    /// @dev Gets the player address given a color on the board
    /// @param boardId The board to check
    /// @param color The color of the player we want
    /// @return the player&#39;s address
    function getPlayerAddress(uint boardId, PlayerColor color) public view returns(address) {

        // If it&#39;s the black player
        if (color == PlayerColor.Black) {
            return allBoards[boardId].blackAddress;
        }

        // If it&#39;s the white player
        if (color == PlayerColor.White) {
            return allBoards[boardId].whiteAddress;
        }

        // We aren&#39;t suppose to try and get the color of a player if they aren&#39;t on the board
        revert();
    }

    /// @dev Check if a player is on board (overload for boardId)
    /// @param boardId The board to check
    /// @param searchAddress the player&#39;s address we want to check
    /// @return true if the player is playing in the board
    function isPlayerOnBoard(uint boardId, address searchAddress) public view returns(bool) {
        return (isPlayerOnBoard(allBoards[boardId], searchAddress));
    }

    /// @dev Check if a player is on board
    /// @param board The board to check
    /// @param searchAddress the player&#39;s address we want to check
    /// @return true if the player is playing in the board
    function isPlayerOnBoard(GoBoard storage board, address searchAddress) private view returns(bool) {
        return (board.blackAddress == searchAddress || board.whiteAddress == searchAddress);
    }

    /// @dev Check which player acts next
    /// @param boardId The board to check
    /// @return The color of the current player to act
    function getNextTurnColor(uint boardId) public view returns(PlayerColor) {
        return allBoards[boardId].nextTurnColor;
    }

    /// @notice This is the first function a player will be using in order to start playing. This function allows 
    ///  to register to an existing or a new board, depending on the current available boards.
    ///  Upon registeration the player will pay the board&#39;s stakes and will be the black or white player.
    ///  The black player also creates the board, and is the first player which gives a small advantage in the
    ///  game, therefore we decided that the black player will be the one paying for the additional gas
    ///  that is required to create the board.
    /// @param  tableStakes The tablestakes to use, although this appears in the "value" of the message, we preferred to
    ///  add it as an additional parameter for client use for clients that allow to customize the value parameter.
    /// @return The boardId the player registered to (either a new board or an existing board)
    function registerPlayerToBoard(uint tableStakes) external payable allowedValuesOnly(msg.value) whenNotPaused returns(uint) {
        // Make sure the value and tableStakes are the same
        require (msg.value == tableStakes);
        GoBoard storage boardToJoin;
        uint boardIDToJoin;
        
        // Check which board to connect to
        (boardIDToJoin, boardToJoin) = getOrCreateWaitingBoard(tableStakes);
        
        // Add the player to the board (they already paid)
        bool shouldStartGame = addPlayerToBoard(boardToJoin, tableStakes);

        // Fire the event for anyone listening
        PlayerAddedToBoard(boardIDToJoin, msg.sender);

        // If we have both players, start the game
        if (shouldStartGame) {

            // Start the game
            startBoardGame(boardToJoin, boardIDToJoin);
        }

        return boardIDToJoin;
    }

    /// @notice This function allows a player to cancel a match in the case they were waiting for an opponent for
    ///  a long time but didn&#39;t find anyone and would want to get their deposit of table stakes back.
    ///  That player may cancel the game as long as no opponent was found and the deposit will be returned in full (though gas fees still apply). The player will also need to withdraw funds from the contract after this action.
    /// @param boardId The board to cancel
    function cancelMatch(uint boardId) external {
        
        // Get the player
        GoBoard storage board = allBoards[boardId];

        // Make sure this player is on board
        require(isPlayerOnBoard(boardId, msg.sender));

        // Make sure that the game hasn&#39;t started
        require(board.status == BoardStatus.WaitForOpponent);

        // Update the board status to cancel (which also triggers the revenue sharing function)
        updateBoardStatus(board, boardId, BoardStatus.Canceled);
    }

    /// @dev Gets the current player boards to present to the player as needed
    /// @param activeTurnsOnly We might want to highlight the boards where the player is expected to act
    /// @return an array of PAGE_SIZE with the number of boards found and the actual IDs
    function getPlayerBoardsIDs(bool activeTurnsOnly) public view returns (uint, uint[PAGE_SIZE]) {
        uint[PAGE_SIZE] memory playerBoardIDsToReturn;
        uint numberOfPlayerBoardsToReturn = 0;
        
        // Look at the recent boards until you find a player board
        for (uint currBoard = allBoards.length; currBoard > 0 && numberOfPlayerBoardsToReturn < PAGE_SIZE; currBoard--) {
            uint boardID = currBoard - 1;            

            // We only care about boards the player is in
            if (isPlayerOnBoard(boardID, msg.sender)) {

                // Check if the player is the next to act, or just include it if it wasn&#39;t requested
                if (!activeTurnsOnly || getNextTurnColor(boardID) == getPlayerColor(boardID, msg.sender)) {
                    playerBoardIDsToReturn[numberOfPlayerBoardsToReturn] = boardID;
                    ++numberOfPlayerBoardsToReturn;
                }
            }
        }

        return (numberOfPlayerBoardsToReturn, playerBoardIDsToReturn);
    }

    /// @dev Creates a new board in case no board was found for a player to register
    /// @param tableStakesToUse The value used to set the board
    /// @return the id of new board (which is it&#39;s position in the allBoards array)
    function createNewGoBoard(uint tableStakesToUse) private returns(uint, GoBoard storage) {
        GoBoard memory newBoard = GoBoard({lastUpdate: now,
                                           isHonorableLoss: false,
                                           tableStakes: tableStakesToUse,
                                           boardBalance: 0,
                                           blackAddress: 0,
                                           whiteAddress: 0,
                                           blackPeriodsRemaining: PLAYER_START_PERIODS,
                                           whitePeriodsRemaining: PLAYER_START_PERIODS,
                                           nextTurnColor: PlayerColor.None,
                                           status:BoardStatus.WaitForOpponent,
                                           didPassPrevTurn:false});

        uint boardId = allBoards.push(newBoard) - 1;
        return (boardId, allBoards[boardId]);
    }

    /// @dev Creates a new board in case no board was found for a player to register
    /// @param tableStakes The value used to set the board
    /// @return the id of new board (which is it&#39;s position in the allBoards array)
    function getOrCreateWaitingBoard(uint tableStakes) private returns(uint, GoBoard storage) {
        bool wasFound = false;
        uint selectedBoardId = 0;
        GoBoard storage board;

        // First, try to find a board that has an empty spot and the right table stakes
        for (uint i = allBoards.length; i > 0 && !wasFound; --i) {
            board = allBoards[i - 1];

            // Make sure this board is already waiting and it&#39;s stakes are the same
            if (board.tableStakes == tableStakes) {
                
                // If this board is waiting for an opponent
                if (board.status == BoardStatus.WaitForOpponent) {
                    
                    // Awesome, we have the board and we are done
                    wasFound = true;
                    selectedBoardId = i - 1;
                }

                // If we found the rights stakes board but it isn&#39;t waiting for player we won&#39;t have another empty board.
                // We need to create a new one
                break;
            }
        }

        // Create a new board if we couldn&#39;t find one
        if (!wasFound) {
            (selectedBoardId, board) = createNewGoBoard(tableStakes);
        }

        return (selectedBoardId, board);
    }

    /// @dev Starts the game and sets everything up for the match
    /// @param board The board to update with the starting data
    /// @param boardId The board&#39;s Id
    function startBoardGame(GoBoard storage board, uint boardId) private {
        
        // Make sure both players are present
        require(board.blackAddress != 0 && board.whiteAddress != 0);
        
        // The black is always the first player in GO
        board.nextTurnColor = PlayerColor.Black;

        // Save the game start time and set the game status to in progress
        updateBoardStatus(board, boardId, BoardStatus.InProgress);
    }

    /// @dev Handles the registration of a player to a board
    /// @param board The board to update with the starting data
    /// @param paidAmount The amount the player paid to start playing (will be added to the board balance)
    /// @return true if the game should be started
    function addPlayerToBoard(GoBoard storage board, uint paidAmount) private returns(bool) {
        
        // Make suew we are still waitinf for opponent (otherwise we can&#39;t add players)
        bool shouldStartTheGame = false;
        require(board.status == BoardStatus.WaitForOpponent);

        // Check that the player isn&#39;t already on the board, otherwise they would pay twice for a single board... :( 
        require(!isPlayerOnBoard(board, msg.sender));

        // We always add the black player first as they created the board
        if (board.blackAddress == 0) {
            board.blackAddress = msg.sender;
        
        // If we have a black player, add the white player
        } else if (board.whiteAddress == 0) {
            board.whiteAddress = msg.sender;
        
            // Once the white player has been added, we can start the match
            shouldStartTheGame = true;           

        // If both addresses are occuipied and we got here, it&#39;s a problem
        } else {
            revert();
        }

        // Credit the board with what we know 
        board.boardBalance += paidAmount;

        return shouldStartTheGame;
    }

    /// @dev Helper function to caclulate how much time a player used since now
    /// @param lastUpdate the timestamp of last update of the board
    /// @return the number of periods used for this time
    function getTimePeriodsUsed(uint lastUpdate) private view returns(uint8) {
        return uint8(now.sub(lastUpdate).div(PLAYER_TURN_SINGLE_PERIOD));
    }

    /// @notice Convinience function to help present how much time a player has.
    /// @param boardId the board to check.
    /// @param color the color of the player to check.
    /// @return The number of time periods the player has, the number of seconds per each period and the total number of seconds for convinience.
    function getPlayerRemainingTime(uint boardId, PlayerColor color) view external returns (uint, uint, uint) {
        GoBoard storage board = allBoards[boardId];

        // Always verify we can act
        require(board.status == BoardStatus.InProgress);

        // Get the total remaining time:
        uint timePeriods = getPlayerTimePeriods(board, color);
        uint totalTimeRemaining = timePeriods * PLAYER_TURN_SINGLE_PERIOD;

        // If this is the acting player
        if (color == board.nextTurnColor) {

            // Calc time periods for player
            uint timePeriodsUsed = getTimePeriodsUsed(board.lastUpdate);
            if (timePeriods > timePeriodsUsed) {
                timePeriods -= timePeriodsUsed;
            } else {
                timePeriods = 0;
            }

            // Calc total time remaining  for player
            uint timeUsed = (now - board.lastUpdate);
            
            // Safely reduce the time used
            if (totalTimeRemaining > timeUsed) {
                totalTimeRemaining -= timeUsed;
            
            // A player can&#39;t have less than zero time to act
            } else {
                totalTimeRemaining = 0;
            }
        }
        
        return (timePeriods, PLAYER_TURN_SINGLE_PERIOD, totalTimeRemaining);
    }

    /// @dev After a player acted we might need to reduce the number of remaining time periods.
    /// @param board The board the player acted upon.
    /// @param color the color of the player that acted.
    /// @param timePeriodsUsed the number of periods the player used.
    function updatePlayerTimePeriods(GoBoard storage board, PlayerColor color, uint8 timePeriodsUsed) internal {

        // Reduce from the black player
        if (color == PlayerColor.Black) {

            // The player can&#39;t have less than 0 periods remaining
            board.blackPeriodsRemaining = board.blackPeriodsRemaining > timePeriodsUsed ? board.blackPeriodsRemaining - timePeriodsUsed : 0;
        // Reduce from the white player
        } else if (color == PlayerColor.White) {
            
            // The player can&#39;t have less than 0 periods remaining
            board.whitePeriodsRemaining = board.whitePeriodsRemaining > timePeriodsUsed ? board.whitePeriodsRemaining - timePeriodsUsed : 0;

        // We are not supposed to get here
        } else {
            revert();
        }
    }

    /// @dev Helper function to access the time periods of a player in a board.
    /// @param board The board to check.
    /// @param color the color of the player to check.
    /// @return The number of time periods remaining for this player
    function getPlayerTimePeriods(GoBoard storage board, PlayerColor color) internal view returns (uint8) {

        // For the black player
        if (color == PlayerColor.Black) {
            return board.blackPeriodsRemaining;

        // For the white player
        } else if (color == PlayerColor.White) {
            return board.whitePeriodsRemaining;

        // We are not supposed to get here
        } else {

            revert();
        }
    }

    /// @notice The main function to split game revenues, this is triggered only by changing the game&#39;s state
    ///  to one of the ending game states.
    ///  We make sure this board has a balance and that it&#39;s only running once a board game has ended
    ///  We used numbers for easier read through as this function is critical for the revenue sharing model
    /// @param board The board the credit will come from.
    function creditBoardGameRevenues(GoBoard storage board) private boardGameEnded(board) boardNotPaid(board) {
                
        // Get the shares from the globals
        uint updatedHostShare = HOST_SHARE;
        uint updatedLoserShare = 0;

        // Start accumulating funds for each participant and EthernalGo&#39;s CFO
        uint amountBlack = 0;
        uint amountWhite = 0;
        uint amountCFO = 0;
        uint fullAmount = 1000;

        // Incentivize resigns and quick end-games for the loser
        if (board.status == BoardStatus.BlackWin || board.status == BoardStatus.WhiteWin) {
            
            // In case the game ended honorably (not by time out), the loser will get credit (from the CFO&#39;s share)
            if (board.isHonorableLoss) {
                
                // Reduce the credit from the CFO
                updatedHostShare = HOST_SHARE - HONORABLE_LOSS_BONUS;
                
                // Add to the loser share
                updatedLoserShare = HONORABLE_LOSS_BONUS;
            }

            // If black won
            if (board.status == BoardStatus.BlackWin) {
                
                // Black should get the winner share
                amountBlack = board.boardBalance.mul(WINNER_SHARE).div(fullAmount);
                
                // White player should get the updated loser share (with or without the bonus)
                amountWhite = board.boardBalance.mul(updatedLoserShare).div(fullAmount);
            }

            // If white won
            if (board.status == BoardStatus.WhiteWin) {

                // White should get the winner share
                amountWhite = board.boardBalance.mul(WINNER_SHARE).div(fullAmount);
                
                // Black should get the updated loser share (with or without the bonus)
                amountBlack = board.boardBalance.mul(updatedLoserShare).div(fullAmount);
            }

            // The CFO should get the updates share if the game ended as expected
            amountCFO = board.boardBalance.mul(updatedHostShare).div(fullAmount);
        }

        // If the match ended in a draw or it was cancelled
        if (board.status == BoardStatus.Draw || board.status == BoardStatus.Canceled) {
            
            // The CFO is not taking a share from draw or a cancelled match
            amountCFO = 0;

            // If the white player was on board, we should split the balance in half
            if (board.whiteAddress != 0) {

                // Each player gets half of the balance
                amountBlack = board.boardBalance.div(2);
                amountWhite = board.boardBalance.div(2);

            // If there was only the black player, they should get the entire balance
            } else {
                amountBlack = board.boardBalance;
            }
        }

        // Make sure we are going to split the entire amount and nothing gets left behind
        assert(amountBlack + amountWhite + amountCFO == board.boardBalance);
        
        // Reset the balance
        board.boardBalance = 0;

        // Async sends to the participants (this means each participant will be required to withdraw funds)
        asyncSend(board.blackAddress, amountBlack);
        asyncSend(board.whiteAddress, amountWhite);
        asyncSend(CFO, amountCFO);
    }

    /// @dev withdraw accumulated balance, called by payee.
    function withdrawPayments() public {

        // Call Zeppelin&#39;s withdrawPayments
        super.withdrawPayments();

        // Send an event
        PlayerWithdrawnBalance(msg.sender);
    }
}

// File: contracts/GoGameLogic.sol

/// @title The actual game logic for EthernalGo - setting stones, capturing, etc.
/// @author https://www.EthernalGo.com
contract GoGameLogic is GoBoardMetaDetails {

    /// @dev The StoneAddedToBoard event is fired when a new stone is added to the board, 
    ///  and includes the board Id, stone color, row & column. This event will fire even if it was a suicide stone.
    event StoneAddedToBoard(uint boardId, PlayerColor color, uint8 row, uint8 col);

    /// @dev The PlayerPassedTurn event is fired when a player passes turn 
    ///  and includes the board Id, color.
    event PlayerPassedTurn(uint boardId, PlayerColor color);
    
    /// @dev Updating the player&#39;s time periods left, according to the current time - board last update time.
    ///  If the player does not have enough time and chose to act, the game will end and the player will lose.
    /// @param board is the relevant board.
    /// @param boardId is the board&#39;s Id.
    /// @param color is the color of the player we want to update.
    /// @return true if the player can continue playing, otherwise false.
    function updatePlayerTime(GoBoard storage board, uint boardId, PlayerColor color) private returns(bool) {

        // Verify that the board is in progress and that it&#39;s the current player
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == color);

        // Calculate time periods used by the player
        uint timePeriodsUsed = uint(now.sub(board.lastUpdate).div(PLAYER_TURN_SINGLE_PERIOD));

        // Subtract time periods if needed
        if (timePeriodsUsed > 0) {

            // Can&#39;t spend more than MAX_UINT8
            updatePlayerTimePeriods(board, color, timePeriodsUsed > MAX_UINT8 ? MAX_UINT8 : uint8(timePeriodsUsed));

            // The player losses when there aren&#39;t any time periods left
            if (getPlayerTimePeriods(board, color) == 0) {
                playerLost(board, boardId, color);
                return false;
            }
        }

        return true;
    }

    /// @notice Updates the board status according to the players score.
    ///  Can only be called when the board is in a &#39;waitingToResolve&#39; status.
    /// @param boardId is the board to check and update
    function checkVictoryByScore(uint boardId) external boardWaitingToResolve(boardId) {
        
        uint8 blackScore;
        uint8 whiteScore;

        // Get the players&#39; score
        (blackScore, whiteScore) = calculateBoardScore(boardId);

        // Default to Draw
        BoardStatus status = BoardStatus.Draw;

        // If black&#39;s score is bigger than white&#39;s score, black is the winner
        if (blackScore > whiteScore) {

            status = BoardStatus.BlackWin;
        // If white&#39;s score is bigger, white is the winner
        } else if (whiteScore > blackScore) {

            status = BoardStatus.WhiteWin;
        }

        // Update the board&#39;s status
        updateBoardStatus(boardId, status);
    }

    /// @notice Performs a pass action on a psecific board, only by the current active color player.
    /// @param boardId is the board to perform pass on.
    function passTurn(uint boardId) external {

        // Get the board & player
        GoBoard storage board = allBoards[boardId];
        PlayerColor activeColor = getPlayerColor(board, msg.sender);

        // Verify the player can act
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == activeColor);
        
        // Check if this player can act
        if (updatePlayerTime(board, boardId, activeColor)) {

            // If it&#39;s the second straight pass, the game is over
            if (board.didPassPrevTurn) {

                // Finishing the game like this is considered honorable
                board.isHonorableLoss = true;

                // On second pass, the board status changes to &#39;WaitingToResolve&#39;
                updateBoardStatus(board, boardId, BoardStatus.WaitingToResolve);

            // If it&#39;s the first pass, we can simply continue
            } else {

                // Move to the next player, flag that it was a pass action
                nextTurn(board);
                board.didPassPrevTurn = true;

                // Notify the player passed turn
                PlayerPassedTurn(boardId, activeColor);
            }
        }
    }

    /// @notice Resigns a player from a specific board, can get called by either player on the board.
    /// @param boardId is the board to resign from.
    function resignFromMatch(uint boardId) external {

        // Get the board, make sure it&#39;s in progress
        GoBoard storage board = allBoards[boardId];
        require(board.status == BoardStatus.InProgress);

        // Get the sender&#39;s color
        PlayerColor activeColor = getPlayerColor(board, msg.sender);
                
        // Finishing the game like this is considered honorable
        board.isHonorableLoss = true;

        // Set that color as the losing player
        playerLost(board, boardId, activeColor);
    }

    /// @notice Claiming the current acting player on the board is out of time, thus losses the game.
    /// @param boardId is the board to claim it on.
    function claimActingPlayerOutOfTime(uint boardId) external {

        // Get the board, make sure it&#39;s in progress
        GoBoard storage board = allBoards[boardId];
        require(board.status == BoardStatus.InProgress);

        // Get the acting player color
        PlayerColor actingPlayerColor = getNextTurnColor(boardId);

        // Calculate remaining allowed time for the acting player
        uint playerTimeRemaining = PLAYER_TURN_SINGLE_PERIOD * getPlayerTimePeriods(board, actingPlayerColor);

        // If the player doesn&#39;t have enough time left, the player losses
        if (playerTimeRemaining < now - board.lastUpdate) {
            playerLost(board, boardId, actingPlayerColor);
        }
    }

    /// @dev Update a board status with a losing color
    /// @param board is the board to update.
    /// @param boardId is the board&#39;s Id.
    /// @param color is the losing player&#39;s color.
    function playerLost(GoBoard storage board, uint boardId, PlayerColor color) private {

        // If black is the losing color, white wins
        if (color == PlayerColor.Black) {
            updateBoardStatus(board, boardId, BoardStatus.WhiteWin);
        
        // If white is the losing color, black wins
        } else if (color == PlayerColor.White) {
            updateBoardStatus(board, boardId, BoardStatus.BlackWin);

        // There&#39;s an error, revert
        } else {
            revert();
        }
    }

    /// @dev Internally used to move to the next turn, by switching sides and updating the board last update time.
    /// @param board is the board to update.
    function nextTurn(GoBoard storage board) private {
        
        // Switch sides
        board.nextTurnColor = board.nextTurnColor == PlayerColor.Black ? PlayerColor.White : PlayerColor.Black;

        // Last update time
        board.lastUpdate = now;
    }
    
    /// @notice Adding a stone to a specific board and position (row & col).
    ///  Requires the board to be in progress, that the caller is the acting player, 
    ///  and that the spot on the board is empty.
    /// @param boardId is the board to add the stone to.
    /// @param row is the row for the new stone.
    /// @param col is the column for the new stone.
    function addStoneToBoard(uint boardId, uint8 row, uint8 col) external {
        
        // Get the board & sender&#39;s color
        GoBoard storage board = allBoards[boardId];
        PlayerColor activeColor = getPlayerColor(board, msg.sender);

        // Verify the player can act
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == activeColor);

        // Calculate the position
        uint8 position = row * BOARD_ROW_SIZE + col;
        
        // Check that it&#39;s an empty spot
        require(board.positionToColor[position] == 0);

        // Update the player timeout (if the player doesn&#39;t have time left, discontinue)
        if (updatePlayerTime(board, boardId, activeColor)) {

            // Set the stone on the board
            board.positionToColor[position] = uint8(activeColor);

            // Run capture / suidice logic
            updateCaptures(board, position, uint8(activeColor));
            
            // Next turn logic
            nextTurn(board);

            // Clear the pass flag
            if (board.didPassPrevTurn) {
                board.didPassPrevTurn = false;
            }

            // Fire the event
            StoneAddedToBoard(boardId, activeColor, row, col);
        }
    }

    /// @notice Returns a board&#39;s row details, specifies which color occupies which cell in that row.
    /// @dev It returns a row and not the entire board because some nodes might fail to return arrays larger than ~50.
    /// @param boardId is the board to inquire.
    /// @param row is the row to get details on.
    /// @return an array that contains the colors occupying each cell in that row.
    function getBoardRowDetails(uint boardId, uint8 row) external view returns (uint8[BOARD_ROW_SIZE]) {
        
        // The array to return
        uint8[BOARD_ROW_SIZE] memory rowToReturn;

        // For all columns, calculate the position and get the current status
        for (uint8 col = 0; col < BOARD_ROW_SIZE; col++) {
            
            uint8 position = row * BOARD_ROW_SIZE + col;
            rowToReturn[col] = allBoards[boardId].positionToColor[position];
        }

        // Return the array
        return (rowToReturn);
    }

    /// @notice Returns the current color of a specific position in a board.
    /// @param boardId is the board to inquire.
    /// @param row is part of the position to get details on.
    /// @param col is part of the position to get details on.
    /// @return the color occupying that position.
    function getBoardSingleSpaceDetails(uint boardId, uint8 row, uint8 col) external view returns (uint8) {

        uint8 position = row * BOARD_ROW_SIZE + col;
        return allBoards[boardId].positionToColor[position];
    }

    /// @dev Calcultes whether a position captures an enemy group, or whether it&#39;s a suicide. 
    ///  Updates the board accoridngly (clears captured groups, or the suiciding stone).
    /// @param board the board to check and update
    /// @param position the position of the new stone
    /// @param positionColor the color of the new stone (this param is sent to spare another reading op)
    function updateCaptures(GoBoard storage board, uint8 position, uint8 positionColor) private {

        // Group positions, used later
        uint8[BOARD_SIZE] memory group;

        // Is group captured, or free
        bool isGroupCaptured;

        // In order to save gas, we check suicide only if the position is fully surrounded and doesn&#39;t capture enemy groups 
        bool shouldCheckSuicide = true;

        // Get the position&#39;s adjacent cells
        uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

        // Run as long as there an adjacent cell, or until we reach the end of the array
        for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {

            // Get the adjacent cell&#39;s color
            uint8 currColor = board.positionToColor[adjacentArray[currAdjacentIndex]];

            // If the enemy&#39;s color
            if (currColor != 0 && currColor != positionColor) {

                // Get the group&#39;s info
                (group, isGroupCaptured) = getGroup(board, adjacentArray[currAdjacentIndex], currColor);

                // Captured a group
                if (isGroupCaptured) {
                    
                    // Clear the group from the board
                    for (uint8 currGroupIndex = 0; currGroupIndex < BOARD_SIZE && group[currGroupIndex] < MAX_UINT8; currGroupIndex++) {

                        board.positionToColor[group[currGroupIndex]] = 0;
                    }

                    // Shouldn&#39;t check suicide
                    shouldCheckSuicide = false;
                }
            // There&#39;s an empty adjacent cell
            } else if (currColor == 0) {

                // Shouldn&#39;t check suicide
                shouldCheckSuicide = false;
            }
        }

        // Detect suicide if needed
        if (shouldCheckSuicide) {

            // Get the new stone&#39;s surrounding group
            (group, isGroupCaptured) = getGroup(board, position, positionColor);

            // If the group is captured, it&#39;s a suicide move, remove it
            if (isGroupCaptured) {

                // Clear added stone
                board.positionToColor[position] = 0;
            }
        }
    }

    /// @dev Internally used to set a flag in a shrinked board array (used to save gas costs).
    /// @param visited the array to update.
    /// @param position the position on the board we want to flag.
    /// @param flag the flag we want to set (either 1 or 2).
    function setFlag(uint8[SHRINKED_BOARD_SIZE] visited, uint8 position, uint8 flag) private pure {
        visited[position / 4] |= flag << ((position % 4) * 2);
    }

    /// @dev Internally used to check whether a flag in a shrinked board array is set.
    /// @param visited the array to check.
    /// @param position the position on the board we want to check.
    /// @param flag the flag we want to check (either 1 or 2).
    /// @return true if that flag is set, false otherwise.
    function isFlagSet(uint8[SHRINKED_BOARD_SIZE] visited, uint8 position, uint8 flag) private pure returns (bool) {
        return (visited[position / 4] & (flag << ((position % 4) * 2)) > 0);
    }

    // Get group visited flags
    uint8 constant FLAG_POSITION_WAS_IN_STACK = 1;
    uint8 constant FLAG_DID_VISIT_POSITION = 2;

    /// @dev Gets a group starting from the position & color sent. In order for a stone to be part of the group,
    ///  it must match the original stone&#39;s color, and be connected to it - either directly, or through adjacent cells.
    ///  A group is captured if there aren&#39;t any empty cells around it.
    ///  The function supports both returning colored groups - white/black, and empty groups (for that case, isGroupCaptured isn&#39;t relevant).
    /// @param board the board to check and update
    /// @param position the position of the starting stone
    /// @param positionColor the color of the starting stone (this param is sent to spare another reading op)
    /// @return an array that contains the positions of the group, 
    ///  a boolean that specifies whether the group is captured or not.
    ///  In order to save gas, if a group isn&#39;t captured, the array might not contain the enitre group.
    function getGroup(GoBoard storage board, uint8 position, uint8 positionColor) private view returns (uint8[BOARD_SIZE], bool isGroupCaptured) {

        // The return array, and its size
        uint8[BOARD_SIZE] memory groupPositions;
        uint8 groupSize = 0;
        
        // Flagging visited locations
        uint8[SHRINKED_BOARD_SIZE] memory visited;

        // Stack of waiting positions, the first position to check is the sent position
        uint8[BOARD_SIZE] memory stack;
        stack[0] = position;
        uint8 stackSize = 1;

        // That position was added to the stack
        setFlag(visited, position, FLAG_POSITION_WAS_IN_STACK);

        // Run as long as there are positions in the stack
        while (stackSize > 0) {

            // Take the last position and clear it
            position = stack[--stackSize];
            stack[stackSize] = 0;

            // Only if we didn&#39;t visit that stone before
            if (!isFlagSet(visited, position, FLAG_DID_VISIT_POSITION)) {
                
                // Set the flag so we won&#39;t visit it again
                setFlag(visited, position, FLAG_DID_VISIT_POSITION);

                // Add that position to the return value
                groupPositions[groupSize++] = position;

                // Get that position adjacent cells
                uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

                // Run over the adjacent cells
                for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {
                    
                    // Get the current adjacent cell color
                    uint8 currColor = board.positionToColor[adjacentArray[currAdjacentIndex]];
                    
                    // If it&#39;s the same color as the original position color
                    if (currColor == positionColor) {

                        // Add that position to the stack
                        if (!isFlagSet(visited, adjacentArray[currAdjacentIndex], FLAG_POSITION_WAS_IN_STACK)) {
                            stack[stackSize++] = adjacentArray[currAdjacentIndex];
                            setFlag(visited, adjacentArray[currAdjacentIndex], FLAG_POSITION_WAS_IN_STACK);
                        }
                    // If that position is empty, the group isn&#39;t captured, no need to continue running
                    } else if (currColor == 0) {
                        
                        return (groupPositions, false);
                    }
                }
            }
        }

        // Flag the end of the group array only if needed
        if (groupSize < BOARD_SIZE) {
            groupPositions[groupSize] = MAX_UINT8;
        }
        
        // The group is captured, return it
        return (groupPositions, true);
    }
    
    /// The max number of adjacent cells is 4
    uint8 constant MAX_ADJACENT_CELLS = 4;

    /// @dev returns the adjacent positions for a given position.
    /// @param position to get its adjacents.
    /// @return the adjacent positions array, filled with MAX_INT8 in case there aren&#39;t 4 adjacent positions.
    function getAdjacentCells(uint8 position) private pure returns (uint8[MAX_ADJACENT_CELLS]) {

        // Init the return array and current index
        uint8[MAX_ADJACENT_CELLS] memory returnCells = [MAX_UINT8, MAX_UINT8, MAX_UINT8, MAX_UINT8];
        uint8 adjacentCellsIndex = 0;

        // Set the up position, if relevant
        if (position / BOARD_ROW_SIZE > 0) {
            returnCells[adjacentCellsIndex++] = position - BOARD_ROW_SIZE;
        }

        // Set the down position, if relevant
        if (position / BOARD_ROW_SIZE < BOARD_ROW_SIZE - 1) {
            returnCells[adjacentCellsIndex++] = position + BOARD_ROW_SIZE;
        }

        // Set the left position, if relevant
        if (position % BOARD_ROW_SIZE > 0) {
            returnCells[adjacentCellsIndex++] = position - 1;
        }

        // Set the right position, if relevant
        if (position % BOARD_ROW_SIZE < BOARD_ROW_SIZE - 1) {
            returnCells[adjacentCellsIndex++] = position + 1;
        }

        return returnCells;
    }

    /// @notice Calculates the board&#39;s score, using area scoring.
    /// @param boardId the board to calculate the score for.
    /// @return blackScore & whiteScore, the players&#39; scores.
    function calculateBoardScore(uint boardId) public view returns (uint8 blackScore, uint8 whiteScore) {

        GoBoard storage board = allBoards[boardId];
        uint8[BOARD_SIZE] memory boardEmptyGroups;
        uint8 maxEmptyGroupId;
        (boardEmptyGroups, maxEmptyGroupId) = getBoardEmptyGroups(board);
        uint8[BOARD_SIZE] memory groupsSize;
        uint8[BOARD_SIZE] memory groupsState;
        
        blackScore = 0;
        whiteScore = 0;

        // Count stones and find empty territories
        for (uint8 position = 0; position < BOARD_SIZE; position++) {

            if (PlayerColor(board.positionToColor[position]) == PlayerColor.Black) {

                blackScore++;
            } else if (PlayerColor(board.positionToColor[position]) == PlayerColor.White) {

                whiteScore++;
            } else {

                uint8 groupId = boardEmptyGroups[position];
                groupsSize[groupId]++;

                // Checking is needed only if we didn&#39;t find the group is adjacent to the two colors already
                if ((groupsState[groupId] & uint8(PlayerColor.Black) == 0) || (groupsState[groupId] & uint8(PlayerColor.White) == 0)) {

                    uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

                    // Check adjacent cells to mark the group&#39;s bounderies
                    for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {

                        // Check if the group has a black boundry
                        if ((PlayerColor(board.positionToColor[adjacentArray[currAdjacentIndex]]) == PlayerColor.Black) && 
                            (groupsState[groupId] & uint8(PlayerColor.Black) == 0)) {

                            groupsState[groupId] |= uint8(PlayerColor.Black);

                        // Check if the group has a white boundry
                        } else if ((PlayerColor(board.positionToColor[adjacentArray[currAdjacentIndex]]) == PlayerColor.White) && 
                                   (groupsState[groupId] & uint8(PlayerColor.White) == 0)) {

                            groupsState[groupId] |= uint8(PlayerColor.White);
                        }
                    }
                }
            }
        }

        // Add territories size to the relevant player
        for (uint8 currGroupId = 1; currGroupId < maxEmptyGroupId; currGroupId++) {
            
            // Check if it&#39;s a black territory
            if ((groupsState[currGroupId] & uint8(PlayerColor.Black) > 0) &&
                (groupsState[currGroupId] & uint8(PlayerColor.White) == 0)) {

                blackScore += groupsSize[currGroupId];

            // Check if it&#39;s a white territory
            } else if ((groupsState[currGroupId] & uint8(PlayerColor.White) > 0) &&
                       (groupsState[currGroupId] & uint8(PlayerColor.Black) == 0)) {

                whiteScore += groupsSize[currGroupId];
            }
        }

        return (blackScore, whiteScore);
    }

    /// @dev IDs empty groups on the board.
    /// @param board the board to map.
    /// @return an array that contains the mapped empty group ids, and the max empty group id
    function getBoardEmptyGroups(GoBoard storage board) private view returns (uint8[BOARD_SIZE], uint8) {

        uint8[BOARD_SIZE] memory boardEmptyGroups;
        uint8 nextGroupId = 1;

        for (uint8 position = 0; position < BOARD_SIZE; position++) {

            PlayerColor currPositionColor = PlayerColor(board.positionToColor[position]);

            if ((currPositionColor == PlayerColor.None) && (boardEmptyGroups[position] == 0)) {

                uint8[BOARD_SIZE] memory emptyGroup;
                bool isGroupCaptured;
                (emptyGroup, isGroupCaptured) = getGroup(board, position, 0);

                for (uint8 currGroupIndex = 0; currGroupIndex < BOARD_SIZE && emptyGroup[currGroupIndex] < MAX_UINT8; currGroupIndex++) {

                    boardEmptyGroups[emptyGroup[currGroupIndex]] = nextGroupId;
                }

                nextGroupId++;
            }
        }

        return (boardEmptyGroups, nextGroupId);
    }
}