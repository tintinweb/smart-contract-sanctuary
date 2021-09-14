/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4;
contract Blockchase {

    // GAME STATE

    // Note: To save space, we only ever keep track of where P and E are individually.
    // Note: There is therefore no actual game board, but game board boundaries and a set of rules restricting movement.

    // for quick access to an 'imaginary' game board (rows: 0-9, cols: 0-9)
    // we have index from 0 to 99 (a total of 100)
    // each row has 10, so A: 0-9, B: 10-19, ... J: 90-99
    // To get an index, we use rowIncrement + colNum
    mapping(string => uint8) private playerPositions;
    uint8 totalMovesByPAndE; // NOTE: this is increased via the increaseTurnNumber method in an external class
    string internal winner;
    uint8 internal MAXIMUM_TURN_ROUNDS;

    // AUCTION RELATED DECLARATIONS

    struct Blinded_Bid {
        bytes32 commit;
        uint8 team; // 1 team P, 2 team E
        uint deposit;
        uint64 block;
        bool revealed;
    }

    // Mappings

    mapping(uint => mapping(uint8 => mapping(address => Blinded_Bid[]))) internal bids_team_p; // submitted team b bids in the running auction
    mapping(uint => mapping(uint8 => mapping(address => Blinded_Bid[]))) internal bids_team_e; // submitted team e bids in the running auction

    mapping(uint8 => address) internal highestBidders_p; // round => address,
    mapping(uint8 => address) internal highestBidders_e; // round => address,
    mapping(address => uint) internal stakes_p; // address => money, stakes which an address has in team p at current round
    mapping(address => uint) internal stakes_e; // address => money, stakes which an address has in team e at current round

    mapping(uint8 => address[]) internal teamMembers;
    mapping(address => uint8) internal teamMembership;

    uint8 internal numberOfBidsP;
    uint8 internal numberOfBidsE;
    uint8 internal numberOfRevealsP;
    uint8 internal numberOfRevealsE;
    address internal highestBidder_p;
    address internal highestBidder_e;
    uint internal highestBid_p;
    uint internal highestBid_e;
    uint8 internal nextMove_p;
    uint8 internal nextMove_e;
    uint internal stakesPot_p;
    uint internal stakesPot_e;
    string internal last_winner;

    //address payable public beneficiary;
    address internal owner;
    uint internal biddingTime;
    uint internal biddingEnd;
    uint internal revealTime;
    uint internal revealEnd;
    uint8 internal stage; // stage 0: Closed for bids and reveals, stage 1: accepting bids. Stage 2: Accepting reveals
    uint internal currentGameID;
    uint8 internal currentRound;

    event AuctionEnded(address winner_p, uint winning_bid_p, uint winning_move_p, address winner_e, uint winning_bid_e, uint winning_move_e);
    event BiddingEnded(string _message);
    event RevealingEnded(uint _numberReveals_p, uint _numberReveals_e);
    event BidRejected(address bidder);
    event MovePursuer(string _direction);
    event MoveEvader(string _direction);
    event GameOver(uint _gameID, uint _round, string _winner);
    event CreditAccount(address _address, uint _amount);

    // debugging and development
    event outputString(string _string);
    event outputInt(uint _int);
    event outputInt8(uint _int);

    // Errors that describe failures.

    /// The function has been called too early.
    /// Try again at `time`.
    error TooEarly(uint time);
    /// The function has been called too late.
    /// It cannot be called after `time`.
    error TooLate(uint time);
    /// The number of bids for team is already full
    error BidsFull(string team);
    /// The number of bids for team is already full
    error BidderCantSwitchSidesDuringAGame(address bidder, string team);
    /// The bidder needs to have a valid team
    error BidderDoesNotHaveAValidTeam(string team);
    /// The bidder needs to have a valid team
    error NotAcceptingBids();
    /// if someone wants to end the auction but 1) the reveal time is not over and 2) not everyone has revealed yet
    error RevealNotEnded();
    /// The bidder can't reveal in other stages than "reveal"
    error NotAcceptingReveals();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();
    /// Only stages 0 (no bids, no reveals), 1 (only bids, no reveals), 2 (only reveals, no bids) are Allowed
    error StageNotValid();
    /// Function can only be called by the contract creater (owner)
    error NotAutorized();


    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }
    modifier onlyIfBidsNotFull(string memory team){
        if (((keccak256(abi.encodePacked(team))) == ((keccak256(abi.encodePacked("P"))))) && (numberOfBidsP >= 3)) revert BidsFull(team);
        if (((keccak256(abi.encodePacked(team))) == ((keccak256(abi.encodePacked("E"))))) && (numberOfBidsE >= 3)) revert BidsFull(team);
        _;
    }
    modifier onlyIfNotMemberOfOtherTeam(address bidder, string memory team){
        if (((keccak256(abi.encodePacked(team))) == ((keccak256(abi.encodePacked("P"))))) && teamMembership[bidder] == 2) revert BidderCantSwitchSidesDuringAGame(bidder, team);
        if (((keccak256(abi.encodePacked(team))) == ((keccak256(abi.encodePacked("E"))))) && teamMembership[bidder] == 1) revert BidderCantSwitchSidesDuringAGame(bidder, team);
        _;
    }
    modifier onlyIfTeamIsValid(string memory team){
        if (((keccak256(abi.encodePacked(team))) != ((keccak256(abi.encodePacked("P"))))) && ((keccak256(abi.encodePacked(team))) != ((keccak256(abi.encodePacked("E")))))) revert BidderDoesNotHaveAValidTeam(team);
        _;
    }
    
    modifier onlyIfAcceptingBids {
        if (stage != 1) revert NotAcceptingBids();
        _;
    }
    
    modifier onlyIfAcceptingReveals(uint time) {
      if (((block.timestamp < time) && (stage != 2)) || (stage == 0)) revert NotAcceptingReveals();
      _;
    }
    modifier onlyIfAuctionCanBeEnded {
        if ((((block.timestamp < revealEnd) && (stage==2)) || (stage != 0))) revert RevealNotEnded();
        _;
    }
    modifier onlyIfStageIsValid(uint _stage) {
        if ((_stage != 0) && (_stage != 1) && (_stage != 2)) revert StageNotValid();
        _;
    }
    modifier onlyIfOwner(address caller) {
        if (caller != owner) revert NotAutorized();
        _;
    }

    constructor(
        uint8 _MAXIMUM_TURN_ROUNDS,
        uint _biddingTime,
        uint _revealTime
    ) {
        MAXIMUM_TURN_ROUNDS = _MAXIMUM_TURN_ROUNDS;
        owner = msg.sender;
        biddingTime = _biddingTime;
        revealTime = _revealTime;
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;

        stage = 1; // game is open, accepting bids
        numberOfBidsP = 0;
        numberOfBidsE = 0;
        currentGameID = 1;
        currentRound = 1;
        stakesPot_p = 0;
        stakesPot_e = 0;
        numberOfRevealsP = 0;
        numberOfRevealsE = 0;
        last_winner = "None";
        newGame();
    }

    /// BLINDED AUCTION WITH COMMIT-REVEAL
    /// Inspiration and some code snippets have been taken from:
    // https://medium.com/gitcoin/commit-reveal-scheme-on-ethereum-25d1d1a25428
    // https://docs.soliditylang.org/en/v0.5.11/solidity-by-example.html

    // Submission of blinded bids and deposits for teams (stage 1)
    function submitBid (bytes32 _commit, string memory _teamName)
        public
        payable
        onlyBefore(biddingEnd)
        onlyIfAcceptingBids
        onlyIfBidsNotFull(_teamName)
        onlyIfNotMemberOfOtherTeam(msg.sender, _teamName)
        onlyIfTeamIsValid(_teamName)
    {
        uint8 _team;
        if (keccak256(abi.encodePacked(_teamName)) == keccak256(abi.encodePacked("P"))){
            _team = 1;
        } else {
            _team = 2;
        }

        // If bidder does not have a team yet, assign one
        if (teamMembership[msg.sender] == 0){
            assignTeam(msg.sender, _team);
        }
        // push the bid to the according bid-stack.
        if (_team == 1) {
            bids_team_p[currentGameID][currentRound][msg.sender].push(Blinded_Bid({
            commit: _commit,
            team: 1,
            deposit: msg.value/1000000000000000000,
            block: uint64(block.number),
            revealed: false
            }));
            numberOfBidsP++;
        }
        else if (_team == 2) {
            bids_team_e[currentGameID][currentRound][msg.sender].push(Blinded_Bid({
            commit: _commit,
            team: 2,
            deposit: msg.value/1000000000000000000,
            block: uint64(block.number),
            revealed: false
            }));
            numberOfBidsE++;
        }
        if ((numberOfBidsP >=3) && (numberOfBidsE >=3)) { // Maximum number of three bids per team
            stage = 2;
            revealEnd = block.timestamp + revealTime;
        }
    }

    function getStage() public view returns (string memory _stage){
        if (stage==1) {
            return "Bidding stage - Place your bids via submitBid now before bidding time ends. INFO: Stage 1: Bidding --> Stage 2: Reveal --> Internal Stages (Identify winner move and perform move) --> Next Auction";
        } else if (stage==2) {
            return "Reveal stage - Reveal your bids via reveal now before reveal time ends. INFO: Stage 1: Bidding --> Stage 2: Reveal --> Internal Stages (Identify winner move and perform move) --> Next Auction";
        } else if (stage==0) {
            return "Internal stage (No action needed) - Auction or game has ended. Not currently accepting bids or reveals. Please wait for next bidding stage";
        }
    }

    /// Reveal of blinded bids. Stage 2
    function reveal(
        uint[] memory _values,
        uint8[] memory _moves,
        uint[] memory _salts
    )
        public
        onlyIfAcceptingReveals(biddingEnd)
        onlyBefore(revealEnd)
    {

        // If the reveal phase was initiated manually, the stage needs to be set to 2 and the reveal time needs to be set. If the reveal was initiated by the bidding end, it is 2 anyway.
        if (stage == 1) {
            revealEnd = block.timestamp + revealTime;
            stage = 2;
        }

        // are there valid bids of the user?
        if (teamMembership[msg.sender] == 1){
            uint length = bids_team_p[currentGameID][currentRound][msg.sender].length;
            require(_values.length == length);
            require(_moves.length == length);
            require(_salts.length == length);
            for (uint i = 0; i < length; i++) {
                Blinded_Bid storage bidToCheck = bids_team_p[currentGameID][currentRound][msg.sender][i];
                (uint value, uint8 move, uint salt) = (_values[i], _moves[i], _salts[i]);
                
                if (bidToCheck.revealed) {
                    continue; // this prevents an address from executing the reveal-function twice for the same bid
                }
                
                if (bidToCheck.commit != keccak256(abi.encodePacked(value, move, salt))) {
                    // Bid was not actually revealed.
                    // Do not refund deposit.
                    continue;
                } else { // bid was revealed
                    bids_team_p[currentGameID][currentRound][msg.sender][i].revealed = true; // mark the bid as 'revealed'
                }

                if (bidToCheck.deposit >= value) {
                    if (!placeBid_p(msg.sender, value, move)) {
                        emit BidRejected(msg.sender);
                        //pendingReturns[msg.sender] += bidToCheck.deposit;
                        payable(msg.sender).transfer(bidToCheck.deposit*1000000000000000000);
                        //emit CreditAccount(msg.sender, pendingReturns[msg.sender]);
                        emit CreditAccount(msg.sender, bidToCheck.deposit*1000000000000000000);
                    } else {
                        //pendingReturns[msg.sender] += ((bidToCheck.deposit - value));
                        payable(msg.sender).transfer((bidToCheck.deposit-value)*1000000000000000000);
                        emit CreditAccount(msg.sender, (bidToCheck.deposit-value)*1000000000000000000);
                    }
                }
                // Make it impossible to re-claim the same deposit.
                
                bids_team_p[currentGameID][currentRound][msg.sender][i].deposit = 0;
                numberOfRevealsP++;
            }
        }
        else if (teamMembership[msg.sender] == 2) {
            uint length = bids_team_e[currentGameID][currentRound][msg.sender].length;
            require(_values.length == length);
            require(_moves.length == length);
            require(_salts.length == length);
            for (uint i = 0; i < length; i++) {
                Blinded_Bid storage bidToCheck = bids_team_e[currentGameID][currentRound][msg.sender][i];
                (uint value, uint8 move, uint salt) = (_values[i], _moves[i], _salts[i]);

                if (bidToCheck.revealed) {
                    continue; // this prevents an address from executing the reveal-function twice for the same bid
                }

                if (bidToCheck.commit != keccak256(abi.encodePacked(value, move, salt))) {
                    // Bid was not actually revealed.
                    // Do not refund deposit.
                    continue;
                } else { //bid was revealed
                    bids_team_e[currentGameID][currentRound][msg.sender][i].revealed = true; // mark the bid as 'revealed'
                }

                if (bidToCheck.deposit >= value) {
                    if (!placeBid_e(msg.sender, value, move)) {
                        emit BidRejected(msg.sender);
                        //pendingReturns[msg.sender] += bidToCheck.deposit;
                        payable(msg.sender).transfer(bidToCheck.deposit*1000000000000000000);
                        //emit CreditAccount(msg.sender, pendingReturns[msg.sender]);
                        emit CreditAccount(msg.sender, bidToCheck.deposit*1000000000000000000);
                    } else {
                        //pendingReturns[msg.sender] += ((bidToCheck.deposit - value));
                        payable(msg.sender).transfer((bidToCheck.deposit-value)*1000000000000000000);
                        emit CreditAccount(msg.sender, (bidToCheck.deposit-value)*1000000000000000000);
                    }
                }
                // Make it impossible to re-claim the same deposit.
                bids_team_e[currentGameID][currentRound][msg.sender][i].deposit = 0;
                numberOfRevealsE++;
            }
        }
        if ((numberOfRevealsP >= 3) && (numberOfRevealsE >=3)) { 
            stage = 0;
            auctionEnd();
        }
    }

    /*
    /// Withdraw a bid that was overbid.
    function withdrawFunds() public{
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount*1000000000000000000);
            emit CreditAccount(msg.sender, pendingReturns[msg.sender]);
        }
    }
    */

    // End auction manually
    function forceEndAuctionWhenInsufficientReveals()
        public
        onlyAfter(revealEnd)
        {
            stage = 0;
            auctionEnd();
        }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    

    function auctionEnd()
        internal
        onlyIfAuctionCanBeEnded
    {
        emit AuctionEnded(highestBidder_p, highestBid_p, nextMove_p, highestBidder_e, highestBid_e, nextMove_e);

        highestBidders_p[currentRound] = highestBidder_p;
        highestBidders_e[currentRound] = highestBidder_e;
        stakes_p[highestBidder_p] += highestBid_p;
        stakes_e[highestBidder_e] += highestBid_e;

        stakesPot_p += highestBid_p;
        stakesPot_e += highestBid_e;
        // Step 3: Put action to place
        // a) pursuer
        if ((nextMove_p == 1) && (isValidMovePursuerRight())) {
            movePursuerRight();
            emit MovePursuer("Move pursuer right");
        } else if ((nextMove_p == 2) && (isValidMovePursuerUpRight())) {
            movePursuerUpRight();
            emit MovePursuer("Move pursuer up right");
        } else if ((nextMove_p == 3) && (isValidMovePursuerUp())) {
            movePursuerUp();
            emit MovePursuer("Move pursuer up");
        } else if ((nextMove_p == 4) && (isValidMovePursuerUpLeft())) {
            movePursuerUpLeft();
            emit MovePursuer("Move pursuer up left");
        } else if ((nextMove_p == 5) && (isValidMovePursuerLeft())) {
            movePursuerLeft();
            emit MovePursuer("Move pursuer left");
        } else if ((nextMove_p == 6) && (isValidMovePursuerDownLeft())) {
            movePursuerDownLeft();
            emit MovePursuer("Move pursuer down left");
        } else if ((nextMove_p == 7) && (isValidMovePursuerDown())){
            movePursuerDown();
            emit MovePursuer("Move pursuer down");
        } else if ((nextMove_p == 8) && (isValidMovePursuerDownRight())) {
            movePursuerDownRight();
            emit MovePursuer("Move pursuer down right");
        } else {
            movePursuerNone();
            emit MovePursuer("Do not move pursuer");
        }
        // a) evader
        if ((nextMove_e == 1) && (isValidMoveEvaderRight())) {
            moveEvaderRight();
            emit MoveEvader("Move evader right");
        } else if ((nextMove_e == 3) && (isValidMoveEvaderUp())) {
            moveEvaderUp();
            emit MoveEvader("Move evader up");
        } else if ((nextMove_e == 5) && (isValidMoveEvaderLeft())) {
            moveEvaderLeft();
            emit MoveEvader("Move evader left");
        } else if ((nextMove_e == 7) && (isValidMoveEvaderDown())){
            moveEvaderDown();
            emit MoveEvader("Move evader down");
        } else {
            moveEvaderNone();
            emit MoveEvader("Do not move evader");
        }
        // Step 2: Reset all bidder parameters

        numberOfBidsP = 0;
        numberOfBidsE = 0;

        numberOfRevealsP = 0;
        numberOfRevealsE = 0;

        highestBidder_p = address(0);
        highestBidder_e = address(0);
        highestBid_p = 0;
        highestBid_e = 0;
        nextMove_p = 0;
        nextMove_e = 0;

        // reset bidding and reveal time to the maximum time
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;

        // Step 3: Has game ended now?

        if (!hasGameEnded()) {
            currentRound++;
            increaseTurnNumber();
            stage = 1; // accepting bids again
        } else {
            endGame();
        }
    }

    // Sub-functions to manage the highest bids for each team
    function placeBid_p(address bidder, uint value, uint8 move) internal
            returns (bool success)
    {
        if (value <= highestBid_p) {
            return false;
        }
        if (highestBidder_p != address(0)) {
            // Refund the previously highest bidder.
            //pendingReturns[highestBidder_p] += highestBid_p;
            payable(highestBidder_p).transfer(highestBid_p*1000000000000000000);
            //emit CreditAccount(highestBidder_p, pendingReturns[highestBidder_p]);
            emit CreditAccount(highestBidder_p, highestBid_p*1000000000000000000);
        }
        highestBid_p = value;
        highestBidder_p = bidder;
        nextMove_p = move;
        return true;
    }

    function placeBid_e(address bidder, uint value, uint8 move) internal
            returns (bool success)
    {
        if (value <= highestBid_e) {
            return false;
        }
        if (highestBidder_e != address(0)) {
            // Refund the previously highest bidder.
            //pendingReturns[highestBidder_e] += highestBid_e;
            payable(highestBidder_e).transfer(highestBid_e*1000000000000000000);
            //emit CreditAccount(highestBidder_e, pendingReturns[highestBidder_e]);
            emit CreditAccount(highestBidder_e, highestBid_e*1000000000000000000);
        }
        highestBid_e = value;
        highestBidder_e = bidder;
        nextMove_e = move;
        return true;
    }
    
    // Ending of game
    function endGame()
        internal
        {
            // step 0: get winner
            winner = getGameWinner();
            last_winner = winner;
            // step 1: pay out winning team
            if (keccak256(abi.encodePacked(winner)) == keccak256(abi.encodePacked("P"))){
                for (uint8 i = 0; i < (MAXIMUM_TURN_ROUNDS+1); i++) {
                    //pendingReturns[highestBidders_p[i]] += (stakes_p[highestBidders_p[i]]*(stakesPot_p+stakesPot_e)/stakesPot_p); //TODO replace by Transfer
                    uint rewards = (stakes_p[highestBidders_p[i]]*(stakesPot_p+stakesPot_e)/stakesPot_p);
                    payable(highestBidders_p[i]).transfer(rewards*1000000000000000000);
                    //emit CreditAccount(highestBidders_p[i], pendingReturns[highestBidders_p[i]]);
                    emit CreditAccount(highestBidders_p[i], rewards*1000000000000000000);
                    stakes_p[highestBidders_p[i]] = 0;
                }
            } else if (keccak256(abi.encodePacked(winner)) == keccak256(abi.encodePacked("E"))){
                for (uint8 i = 0; i < (MAXIMUM_TURN_ROUNDS+1); i++) {
                    //pendingReturns[highestBidders_e[i]] += (stakes_e[highestBidders_e[i]]*(stakesPot_p+stakesPot_e)/stakesPot_e); //TODO replace by Transfer
                    uint rewards = (stakes_e[highestBidders_e[i]]*(stakesPot_p+stakesPot_e)/stakesPot_e);
                    payable(highestBidders_e[i]).transfer(rewards*1000000000000000000);
                    //emit CreditAccount(highestBidders_e[i], pendingReturns[highestBidders_e[i]]);
                    emit CreditAccount(highestBidders_e[i], rewards*1000000000000000000);
                    stakes_e[highestBidders_e[i]] = 0;
                }
            }
            
            // Step 2: Emit event 1: Game over, announce winning team, Emit event 2: announce payouts
            emit GameOver(currentGameID, currentRound, winner);
            
            // step 2: reset game values
            resetTeamMemberships();
            resetBidsAndStakes();
            stakesPot_p = 0;
            stakesPot_e = 0;

            // step 3: start new game
            newGame();
            currentGameID++;
            currentRound = 1;
            stage = 1;
        }

    function assignTeam(address _address, uint8 _team) internal {
            teamMembers[_team].push(_address);
            teamMembership[_address] = _team;
    }

    function resetTeamMemberships()
        internal
        {
            uint length_p = teamMembers[1].length;
            uint length_e = teamMembers[2].length;
            for (uint i = 0; i < length_p; i++) {
                teamMembership[teamMembers[1][i]] = 0;
            }
            for (uint i = 0; i < length_e; i++) {
                teamMembership[teamMembers[2][i]] = 0;
            }
            delete teamMembers[1];
            delete teamMembers[2];
        }
    function resetBidsAndStakes()
        internal
        {
            for (uint8 i = 0; i < MAXIMUM_TURN_ROUNDS; i++) {
                delete stakes_p[highestBidders_p[i]];
                delete highestBidders_p[i];
                delete stakes_e[highestBidders_e[i]];
                delete highestBidders_e[i];
            }
        }

    function getSaltedHash(uint value, uint8 move, uint salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, move, salt));
    }

    //////////////////////////////////////////////////
    /// GAME STARTS HERE
    //////////////////////////////////////////////////
    /*
  Refreshes the Game to the start condition
  API: This is used by the auction manager to restart games
  */
    function newGame() internal {
        resetGameBoard();
        resetTurnNumber();
        winner = "E";
    }

    /*
  Determines if game has ended
  API: The auction manager may use this function to check for the current game's end, which then to restart game, call the function newGame
  */
    function hasGameEnded() internal view returns (bool) {
        return
            (totalMovesByPAndE >= MAXIMUM_TURN_ROUNDS) ||
            (getCurrentPursuerIndex() == getCurrentEvaderIndex()) ||
            (keccak256(abi.encodePacked(winner)) ==
                keccak256(abi.encodePacked("P")));
    }


  /*
  Determines winner of the last game
  */
  function getPreviousGameWinner() public view returns (string memory) {
    return last_winner;
  }
    /*
  Determines the winner of the current game round
  API: This should be used with hasGameEnded to determine the winner
  Note: Recommended to call hasGameEnded at the end of each turn after submitting the 'correct' P and E next moves, and call getGameWinner if hasGameEnded is true
  */
    function getGameWinner() internal view returns (string memory) {
        return winner;
    }

    function getTurnNumber() public view returns (uint8) {
        return totalMovesByPAndE;
    }

    function increaseTurnNumber() internal {
        totalMovesByPAndE = totalMovesByPAndE + 1;
    }

    function resetTurnNumber() internal {
        totalMovesByPAndE = 1;
    }

    /*
  Helper function to refresh gameBoard, with Pursuer at bottom left corner (0,0) and Evader E at 5th row, 5th col (4, 4)
  Note: (4,4) is used from (5-1, 5-1) due to 0 indexing
  */
    function resetGameBoard() private {
        setCurrentPursuerIndex(0);
        setCurrentEvaderIndex(22);
    }

    // GAME BOARD INDEX

    /*
  Checks if index is [0, 99]
  */
    function isValidIndex(uint8 idx) private pure returns (bool) {
        return ((idx >= 0) && (idx < 100));
    }

    /*
  Identifies the index the pursuer P is currently at in the gameBoard
  API: This is used to provide data for the visual on where P is
  */
    function getCurrentPursuerIndex() public view returns (uint8) {
        return playerPositions["P"];
    }

    /*
  Identifies the index the evader E is currently at in the gameBoard
  API: This is used to provide data for the visual on where E is
  */
    function getCurrentEvaderIndex() public view returns (uint8) {
        return playerPositions["E"];
    }

    function setCurrentPursuerIndex(uint8 newPursuerIdx) private {
        playerPositions["P"] = newPursuerIdx;
    }

    function setCurrentEvaderIndex(uint8 newEvaderIdx) private {
        playerPositions["E"] = newEvaderIdx;
    }

    // PURSUER MOVEMENT

    function isValidMovePursuerNone() internal pure returns (bool) {
        return true;
    }

    function movePursuerNone() internal {
    }

    function isValidMovePursuerUpRight() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return ((currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9) && ((currentIdx + 10) < 100));
    }

    function movePursuerUpRight() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) < 9),
            "Move Failed: Attemped to move diagonally out of the allowed right barrier"
        );
        require(
            ((currentIdx + 10) < 100),
            "Move Failed: Attemped to move diagonally out of the allowed top barrier"
        );

        moveFromTo(currentIdx, currentIdx + 11);
    }

    function isValidMovePursuerUpLeft() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return ((currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0) && ((currentIdx + 10) < 100));
    }

    function movePursuerUpLeft() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) > 0),
            "Move Failed: Attemped to move diagonally out of the allowed left barrier"
        );
        require(
            ((currentIdx + 10) < 100),
            "Move Failed: Attemped to move diagonally out of the allowed top barrier"
        );

        moveFromTo(currentIdx, currentIdx + 9);
    }

    function isValidMovePursuerDownRight() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return ((currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9) && ((currentIdx - 10) >= 0));
    }

    function movePursuerDownRight() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) < 9),
            "Move Failed: Attemped to move diagonally out of the allowed right barrier"
        );
        require(
            ((currentIdx - 10) >= 0),
            "Move Failed: Attemped to move diagonally out of the allowed bottom barrier"
        );

        moveFromTo(currentIdx, currentIdx - 9);
    }

    function isValidMovePursuerDownLeft() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return
            (currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0) && ((currentIdx - 10) >= 0);
    }

    function movePursuerDownLeft() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) > 0),
            "Move Failed: Attemped to move diagonally out of the allowed left barrier"
        );
        require(
            ((currentIdx - 10) >= 0),
            "Move Failed: Attemped to move diagonally out of the allowed bottom barrier"
        );

        moveFromTo(currentIdx, currentIdx - 11);
    }

    function isValidMovePursuerUp() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return
            (currentIdx == playerPositions["P"]) && ((currentIdx + 10) < 100);
    }

    function movePursuerUp() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx + 10) < 100),
            "Move Failed: Attemped to move out of the allowed top barrier"
        );

        moveUp(currentIdx);
    }

    function isValidMovePursuerDown() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return (currentIdx == playerPositions["P"]) && ((currentIdx - 10) >= 0);
    }

    function movePursuerDown() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx - 10) >= 0),
            "Move Failed: Attemped to move out of the allowed bottom barrier"
        );

        moveDown(currentIdx);
    }

    function isValidMovePursuerLeft() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0);
    }

    function movePursuerLeft() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) > 0),
            "Move Failed: Attemped to move out of the allowed left barrier"
        );

        moveLeft(currentIdx);
    }

    function isValidMovePursuerRight() internal view returns (bool) {
        uint8 currentIdx = getCurrentPursuerIndex();
        return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9);
    }

    function movePursuerRight() internal {
        uint8 currentIdx = getCurrentPursuerIndex();
        require(
            (currentIdx == playerPositions["P"]),
            "Move Failed: Only Pursuer (P) can perform this movement"
        );
        require(
            ((currentIdx % 10) < 9),
            "Move Failed: Attemped to move out of the allowed right barrier"
        );

        moveRight(currentIdx);
    }

    // EVADER MOVEMENT

    function isValidMoveEvaderNone() internal pure returns (bool) {
        return true;
    }

    function moveEvaderNone() internal {
    }

    function isValidMoveEvaderUp() internal view returns (bool) {
        uint8 currentIdx = getCurrentEvaderIndex();
        return
            (currentIdx == playerPositions["E"]) && ((currentIdx + 10) < 100);
    }

    function moveEvaderUp() internal {
        uint8 currentIdx = getCurrentEvaderIndex();
        require(
            (currentIdx == playerPositions["E"]),
            "Move Failed: Only Evader (E) can perform this movement"
        );
        require(
            ((currentIdx + 10) < 100),
            "Move Failed: Attemped to move out of the allowed top barrier"
        );

        moveUp(currentIdx);
    }

    function isValidMoveEvaderDown() internal view returns (bool) {
        uint8 currentIdx = getCurrentEvaderIndex();
        return (currentIdx == playerPositions["E"]) && ((currentIdx - 10) >= 0);
    }

    function moveEvaderDown() internal {
        uint8 currentIdx = getCurrentEvaderIndex();
        require(
            (currentIdx == playerPositions["E"]),
            "Move Failed: Only Evader (E) can perform this movement"
        );
        require(
            ((currentIdx - 10) >= 0),
            "Move Failed: Attemped to move out of the allowed bottom barrier"
        );

        moveDown(currentIdx);
    }

    function isValidMoveEvaderLeft() internal view returns (bool) {
        uint8 currentIdx = getCurrentEvaderIndex();
        return (currentIdx == playerPositions["E"]) && ((currentIdx % 10) > 0);
    }

    function moveEvaderLeft() internal {
        uint8 currentIdx = getCurrentEvaderIndex();
        require(
            (currentIdx == playerPositions["E"]),
            "Move Failed: Only Evader (E) can perform this movement"
        );
        require(
            ((currentIdx % 10) > 0),
            "Move Failed: Attemped to move out of the allowed left barrier"
        );

        moveLeft(currentIdx);
    }

    function isValidMoveEvaderRight() internal view returns (bool) {
        uint8 currentIdx = getCurrentEvaderIndex();
        return (currentIdx == playerPositions["E"]) && ((currentIdx % 10) < 9);
    }

    function moveEvaderRight() internal {
        uint8 currentIdx = getCurrentEvaderIndex();
        require(
            (currentIdx == playerPositions["E"]),
            "Move Failed: Only Evader (E) can perform this movement"
        );
        require(
            ((currentIdx % 10) < 9),
            "Move Failed: Attemped to move out of the allowed right barrier"
        );

        moveRight(currentIdx);
    }

    // BASIC MOVEMENT HELPER FUNCTIONS

    function moveUp(uint8 currentIdx) private {
        require(
            ((currentIdx + 10) < 100),
            "Move Failed: Attempted to move out of the allowed top grid"
        );
        moveFromTo(currentIdx, currentIdx + 10);
    }

    function moveDown(uint8 currentIdx) private {
        require(
            ((currentIdx - 10) >= 0),
            "Move Failed: Attempted to move out of the allowed bottom grid"
        );
        moveFromTo(currentIdx, currentIdx - 10);
    }

    function moveLeft(uint8 currentIdx) private {
        require(
            ((currentIdx % 10) > 0),
            "Move Failed: Attemped to move out of the allowed left barrier"
        );
        moveFromTo(currentIdx, currentIdx - 1);
    }

    function moveRight(uint8 currentIdx) private {
        require(
            ((currentIdx % 10) < 9),
            "Move Failed: Attemped to move out of the allowed right barrier"
        );
        moveFromTo(currentIdx, currentIdx + 1);
    }

    /*
  Moves the previousIdx presence to the newIdx position on gameBoard via a swap mechanic
  */
    function moveFromTo(uint8 previousIdx, uint8 newIdx) private {
        require(
            (previousIdx == playerPositions["P"]) ||
                (previousIdx == playerPositions["E"]),
            "Move Failed: Only Pursuer (P) and Evader (E) can be moved"
        );
        require(
            isValidIndex(previousIdx),
            "Move Failed: The starting position of the move is invalid"
        );
        require(
            ((newIdx < 100) && (newIdx >= 0)),
            "Move Failed: Attempted to move out of the allowed top/bottom grid"
        );

        // identify P or E to move
        if (previousIdx == getCurrentPursuerIndex()) {
            setCurrentPursuerIndex(newIdx);
        } else if (previousIdx == getCurrentEvaderIndex()) {
            setCurrentEvaderIndex(newIdx);
        }

        // if P catches E, P wins and game should end
        if (getCurrentPursuerIndex() == getCurrentEvaderIndex()) {
            winner = "P";
        }
    }

}