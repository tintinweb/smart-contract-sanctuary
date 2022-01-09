/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

/*
    OpenLuckyCryptoSimple
    This software is a simple lucky game running on the Ethereum Blockchain Networks (Mainnet and Rinkeby).

    The rules of this game are the following:
    1. You have to transfer a given amount of ETH to this contract or call the "registerBet()" function to get a position.
        The amount is returned by calling the function "getBetMinmumValue()" (0.0005 ETH by default).
        WANING: Bigger values don't give you more chances to win, so you should tranfer only the minimum value necessary.
        If you want more chances, you can just make more bets.
    2. Each transfer stays registered into the blockchain for a given period of time (you can see the time in seconds by calling the "getGameInterval()" function).
        When a new bet is registered after that time, arbitrary bets will be selected to receive the prizes.
        DISCLAIMER: Due to Ethereum Blockchain techinical features, it's posible to a miner to influency the results for a short period of time.
        However, to force the algorithm to return a specific value is a extremely hard and costly job.
    3. The balance received by the contract is divied in 3 pieces:
        5% as reserve for the next game;
        20% to fund this project;
        75% distributed to the winners (prize).
    4. There are 3 ranges of winners:
        1st: 1% of the bets will share 80% of the prize;
        2nd: 3% of the bets will share 15% of the prize;
        3rd: 6% of the bets will share 5% of the prizes.
    
    How the winners are selected?
    All the bets are registered in one array into the blockchain.
    When a bet is received after the game interval, an arbitrary number is selected representing the position of the bet in the array.
    This position represents the first winner bet and the next positions will compose all the winners ranges.
    Eg.: Let's suppose a game with 1000 bets, the arbitrary number is 950, the winners will be:
        1st range: 10 winners (1% of the bets) - from position 950 to 959
        2nd range: 30 winners (3% of the bets) - from position 960 to 989
        3rd range: 60 winners (6% of the bets) - from position 990 to 49 (position go to start of the array if it gets the last possible position)
*/

pragma solidity >= 0.8.0;


/**
 * @title OpenLuckyCryptoSimple
 * @dev Receive the bets, make the arbitrary drawing and share the prizes
 */
contract OpenLuckyCryptoSimple {
    bool private dbg;               // Debug flag
    bool private locked;            // Flag used to avoid array collisions
    uint private max_int;           // Used to avoid uint overflows
    bool private disabled;          // Flag used to suspend the game, is necessary for any reason
    uint private game_interval;     // Seconds between each game round
    uint private recursionDepth;    // Controls the depth of the arbitraryNumber() function
    uint private last_game_time;    // Time mark to compute the next game round
    uint8 constant postions = 30;   // Lastest bets from the bets array to generate the arbitrary numbers
    uint private bet_mininum_value; // Ammount of wei necessary to register a Bet
    address private owner;          // Address of the contract ownerOnly
    address payable private wallet; // Address to store the funds for this project

    // All bets registry for the current game.
    // It'll be wiped everytime a new game start.
    address[] private bets;

    // Assert that only the owner executes restricted tasks
    modifier ownerOnly() {
        require(msg.sender == owner, "Your are not allowed");
        _;
    }

    constructor() {
        locked = false;
        owner = msg.sender;
        wallet = payable(owner);
        max_int = type(uint).max;
        disableSystem(false);
        setRecursionDepth(3);
        setGameInterval(86400); // 1 day by default
        setBetMinimumValue(500000 gwei); // 0.0005 ETH by default
        setLastGameTime(block.timestamp); // Time mark to compute the next game time
    }

    function setDebug(bool _debug) public ownerOnly {
        dbg = _debug;
    }


    // Logging facilities
    event log(string text);
    event log(string text, uint value);

    // Debugger facilities
    function debug(string memory text) private {
        if (dbg)
            emit log(text);
    }

    function debug(string memory text, uint value) private {
        if (dbg)
            emit log(text, value);
    }
    

    function setLastGameTime(uint _last_game_time) private {
        last_game_time = _last_game_time;
    }

    function getLastGameTime() private view returns (uint) {
        return last_game_time;
    }

    // This function blocks all the system
    // There is no plan to use this mechanism
    // It exists to stop the transactions for debugging or other kind of problems
    event evDisableSystem(bool disabled);
    function disableSystem(bool _disabled) public ownerOnly {
        emit evDisableSystem(_disabled);
        disabled = _disabled;
    }

    // Allows the owner to set a different value for future bets
    event evSetBetMinimumValue(uint min_value);
    function setBetMinimumValue(uint _min_value) public ownerOnly {
        emit evSetBetMinimumValue(_min_value);
        bet_mininum_value = _min_value;
    }

    // Defines the recusion depth for the arbitrary number generator
    event evSetRecursionDepth(uint8 recursionDepth);
    function setRecursionDepth(uint8 _recursionDepth) public ownerOnly {
        emit evSetBetMinimumValue(_recursionDepth);
        recursionDepth = _recursionDepth;
    }

    // Allows the user to discover the current minimum bet value
    function getBetMinimumValue() public view returns (uint) {
        return bet_mininum_value;
    }

    // Changes the owner
    event evSetOwner(address newOwner);
    function setOwner(address _newOwner) public ownerOnly {
        emit evSetOwner(_newOwner);
        owner = _newOwner;
    }

    // Sets the interval between each game (in seconds)
    event evSetGameInterval(uint interval);
    function setGameInterval(uint interval) public ownerOnly {
        require(interval >= 10, "Minimum interval is 10s");
        emit evSetGameInterval(interval);
        game_interval = interval;
    }

    // Allows the users to know when the next prizes will be shared and a new game will start
    function nextGameTime(uint lastTime) private returns (uint) {
        return lastTime + getGameInterval();
    }

    // Allows the users to know the interval between each game (in seconds)
    function getGameInterval() public view returns (uint) {
        return game_interval;
    }

    receive() external payable {
        registerBet();
    }

    fallback() external payable {}

    // Reset bets
    function resetBets() private returns(bool) {
        debug("Deleting all the previous bets");
        delete bets;
        return true;
    }

    // Number generator
    function arbitraryNumber(uint depth) private returns(uint) {
        bytes32 stream;
        uint n = numberOfBets();
        if (n > postions) {
            // Here, we create a copy of the last bets from the bets array (from blockchain)
            // to generate input for the `arbitraryNumber` function
            address[postions] memory payload;
            uint start = n - 1 - postions;
            for (uint c = 0; c < postions; c++) {
                payload[c] = bets[start + c];
            }
            stream = keccak256(abi.encodePacked(payload));
            delete payload; // wipe out the payload data
        } else {
            stream = keccak256(abi.encode(bets));
        }

        // Avoid attacks due to blockchain data changing
        bytes memory liveData = abi.encodePacked(
            (block.timestamp - getLastGameTime() + 1) * address(this).balance,
            stream
        );
        return _arbitraryNumber(liveData, n, depth);
    }


    function _arbitraryNumber(bytes memory liveData, uint seed, uint depth) private returns(uint) {
        if (depth > 0) {
            depth--;
            seed = _arbitraryNumber(liveData, seed, depth);
        }

        return uint(
            keccak256(
                abi.encodePacked(
                    liveData,
                    seed
                )
            )
        );
    }


    // Calc fund
    function calcFund() private returns(uint) {
        debug("calcFund 1");
        return address(this).balance / 10 * 2;
    }

    // Calc reserve
    function calcReserve() private returns (uint) {
        debug("calcReserve 1");
        return address(this).balance / 100 * 5;
    }

    // Calc prize total amount
    function calcPrize() private returns (uint) {
        debug("calcPrize 1");
        
        // Save part of the balance for the next game
        uint reserve = calcReserve();
        debug("calcPrize 2");

        // Compute part of the balance to fund this project
        uint fund = calcFund();
        debug("calcPrize 3");

        // Prize value
        return address(this).balance - reserve - fund;
    }

    function getBalance() public view ownerOnly returns (uint) {
        return address(this).balance;
    }

    // Store fund
    function storeFund(uint _fund) private returns (bool) {
        debug("Storing funds");
        wallet.transfer(_fund);
        return true;
    }

    // Verify if it time to share the prizes and start a new game
    modifier checkGameTime () {
        debug("checkGameTime 1");
        require(!disabled, "The system is desabled. Please, try again later");
        require(!locked, "We are closed to bets right now. Please, try again later"); // Avoid array collisions
        debug("checkGameTime 2");

        if(block.timestamp >= nextGameTime(getLastGameTime())){
            debug("checkGameTime 3");
            locked = true;
            sharePrize();
            setNewGame();
            locked = false;
        }
        _;
    }

    // Release the "locked" flag
    // Only needed by a buggy scenario where the flag remains locked due to unknown errors
    function forceUnlock() public ownerOnly {
        debug("Forced unlock");
        locked = false;
    }
    
    // Allows the users to know the number of bets
    function numberOfBets() public view returns (uint) {
        return bets.length;
    }

    // Setup new game
    function setNewGame() private returns (bool) {
        debug("Setting up a new game round");
        uint fund = calcFund();
        storeFund(fund);
        resetBets();
        setLastGameTime(block.timestamp);
        return true;
    }

    // Register a new bet
    function registerBet() public payable checkGameTime {
        debug("registerBet 1");
        require(
            uint(msg.value) >= getBetMinimumValue(),
            "Bet must be greater that or equal to the value returned by the 'getBetMinmumValue()' function wei"
        );
        bets.push(msg.sender);
    }

    // Share prize
    event evSharePrize(uint _prizeAmount);
    function sharePrize() private returns (bool) {

        // Number of bets
        uint n_bets = numberOfBets();
        debug("sharePrize 1 - bets", n_bets);

        // Check if there is at leat one bet
        if(n_bets == 0)
            return(false);
        debug("sharePrize 2 - bets > 0");

        // First winners range (1% of the players)
        uint n_1 = n_bets >= 100 ? n_bets / 100 : 1;
        debug("sharePrize 3 - no math problems");

        // Second winners range (3% of the players)
        uint n_2;
        if (n_bets > max_int / 3) { // Avoid uint overflow
            n_2 = n_bets / 100 * 3; // Divide first to avoid overflow
        } else {
            n_2 = n_bets > 33 ?
                n_bets * 3 / 100:   // Multiply first to avoid decimal precision cuts
                1;                  // Garantee minimal of one winner in this range
        }
        debug("sharePrize 4 - no math problems");

        // Third winners range (6% of the players)
        uint n_3;
        if (n_bets > max_int / 6) { // Avoid uint overflow
            n_3 = n_bets / 100 * 6; // Divide first to avoid overflow
        } else {
            n_3 = n_bets > 16 ?
                n_bets * 6 / 100:   // Multiply first to avoid decimal precision cuts
                1;                  // Garantee minimal of one winner in this range
        }
        debug("sharePrize 5 - no math problems");


        // Total prizes value
        uint prize = calcPrize();
        debug("sharePrize 6 - total prize", prize);

        // First range prize (80% of the total prize)
        uint p_1 = prize / 10 * 8 / n_1;
        emit log("1st range winners quantity", n_1);
        emit log("1st range total prize", p_1);

        // Guarantee the prize
        if (p_1 == 0) {
            emit log("No prize left");
            return(false);
        }

        // Second range prize (15% of the total prize)
        uint p_2 = prize / 100 * 15 / n_2;
        emit log("2nd range winners quantity", n_2);
        emit log("2nd range total prize", p_2);

        // Third range prize (5% of the total prize)
        uint p_3 = prize / 100 * 5 / n_3;
        emit log("3rd range winners quantity", n_3);
        emit log("3rd range total prize", p_3);

        // Get arbitary uint
        uint r = arbitraryNumber(recursionDepth);
        debug("sharePrize 7 - arbitrary number", r);

        // Select the position of the bets arrays
        // to start giving the prize
        uint win_mark = r > n_bets ? r % n_bets : n_bets % r;
        debug("sharePrize 8 - winner position", win_mark);

        // Assert the value to a valid array position
        if(win_mark >= n_bets)
            win_mark = 0;

        // First range receives prize
        debug("sharePrize 9 - 1st range initial position", win_mark);
        uint nextRange = givePrizes(n_1, win_mark, p_1) + 1;

        // Second range receives prize
        debug("sharePrize 10 - 2nd range initial position", nextRange);
        if (p_2 > 0)
            nextRange = givePrizes(n_2, nextRange, p_2) + 1;

        // Third range receives prize
        debug("sharePrize 11 - 3rd range initial position", nextRange);
        if (p_3 > 0)
            givePrizes(n_3, nextRange, p_3);

        // Happy winners!
        debug("sharePrize 12 - finish");
        return(true);
    }

    event evGivePrizeError(address indexed player, uint prize, uint indexed time, bytes indexed message);
    function givePrizes(uint n, uint position, uint prize) private returns (uint) {
        if (prize == 0) {
            emit evGivePrizeError(address(0), prize, block.timestamp, "Not enough prize");
            return position;
        }

        if (n == 0) {
            emit evGivePrizeError(address(0), prize, block.timestamp, "No winners for this range");
            return position;
        }

        uint p;
        uint n_bets = numberOfBets();
        for(uint c = 0; c < n; c++) {
            p = position + c;

            // Avoid array out of range, restarting form position 0
            if(p >= n_bets) {
                n -= c;
                position = 0;
                p = 0;
                c = 0;
            }
            

            // Give prize to the winner
            bool status = _givePrize(p, prize); // send() is less expensive than transfer()
            if(status != true) {
                emit evGivePrizeError(bets[p], prize, block.timestamp, "Failed transferring the prize");
            }
        }
        

        return p;
    }

    // Change wallet
    event evChangeWallet(address indexed _owner, address indexed _oldWallet, address indexed _newWallet, uint time);
    function changeWallet(address newWallet) public ownerOnly returns(address) {
        emit evChangeWallet(owner, wallet, newWallet, block.timestamp);
        wallet = payable(newWallet);
        return wallet;
    }

    // Finish this contract forever and returns the prizes to the players.
    // This may be necessary due to legal or security reasons
    // We hope this will never happen...
    event evGameOver(address indexed _owner, address indexed _wallet, uint _balance, uint timestamp, string comment);
    function gameOver() public ownerOnly {
        disableSystem(true);
        uint n_bets = numberOfBets();
        if (n_bets > 0) {
            uint prize = calcPrize();
            uint prize_per_bet = prize / n_bets;

            // Return the prize to the players
            for (uint c = 0; c < n_bets; c++) {
                emit evGameOver(owner, bets[c], address(this).balance, block.timestamp, "Returning prize...");
                if (_givePrize(c, prize_per_bet) == false) {
                    emit evGameOver(owner, bets[c], address(this).balance, block.timestamp, "Failed to return the prize.");
                }
            }
        }

        emit evGameOver(owner, wallet, address(this).balance, block.timestamp, "OpenLuckyCryptoSimple is dead.");
        selfdestruct(wallet);
    }

    function _givePrize(uint bet, uint prize) private returns(bool) {
        return(payable(bets[bet]).send(prize));
    }
}