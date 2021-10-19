/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title A rugpull opportunity for anyone
*/
contract FomoOE {
    address developer;
    uint public developerOnePercent;
    uint public giveToDeveloper;
    uint public giveToJackpot;
    uint public startTime;
    uint public totalTime;
    uint public timeLeft;

    address winning;
    uint public balanceReceived;
    uint public keyPrice = 3366666666666000 wei;
    uint public increased_order = 3366666666666000;
    uint public keyPriceIncreaseBlockNumber;
    uint public multiplier = 100;


    uint public totalKeys;
    uint public keyPurchases;
    uint public divPool;
    uint public jackpot;
    
    struct Divvies {
        uint _keyBalance;
        uint _divBalance;
        uint _withdrawnAmount;
        bool _voted;
        bool _boughtKeys;
    }
    mapping(address => Divvies) public divTracker;

    event keysPurchased(uint _amount, address _winning);
    
    constructor() {
    /**
     * @notice developer address is used to withdraw 1% depending on the outcome
     * of the vote. Developer address has NO more privileges than any other address.  
    */
    developer = msg.sender;
    }
    /**
     * @dev Only humans can play. No smart contracts can play. 
    */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev put 24 (or 86,400 seconds) hours on the clock to start the game
     */
    function letTheGamesBegin() private {
        totalTime = block.timestamp + 86400;
    }

    /**
     * @notice source of truth for the time keeping. 
     * This function will resync the clock after every block.
     */
    function getTimeLeft() public view returns(uint) {
        if (totalKeys == 0) {
            return 86400;
        }
        if (totalTime >= block.timestamp) {
            return totalTime - block.timestamp;
        } else {
            return 0;
        }
    }
    /**
     * @dev holds a logic for key price increase, adding time per key,
     * updating player's key balance, allocating funds, and setting the current winning player.
     * @notice If multiple key purchases are made a the end of the game, 
     * the winner will be the address who gets included FIRST in the game ending block.
    */
    function purchaseKeys(uint _amount) public payable isHuman() {
        /// @notice Incase the game has a slow start (no players), the first 5 key purchases set the clock to 24 hours. 
        if (totalKeys == 0 || keyPurchases < 5) {
            letTheGamesBegin();
        } 
        /// @notice Not sure why anyone would, but you can't buy keys after the game ends.
        require(getTimeLeft() > 0, "there is already a winner");
        /** 
         * @dev Key price can only increase once per block. Without this if/else
         * statement, there could only be one key purchase per block.
         * Example: Alice and Bob purchase keys at the exact same time, thus paying the
         * same price for their keys. Both transactions get mined in the same block. Due to
         * the sequential nature of transactions in the EVM, Alice's transaction gets processed,
         * she gets her keys, and updates the key price. Bob's transaction gets processed next which
         * fails because the key price has been updated by Alice, despite both paying the correct price. 
        */
        if (msg.value >= keyPrice*_amount) {
            keyPriceIncreaseBlockNumber = block.number;
            /**
             * @notice Starting at 1% price hike per purchase, if next price increase adds a digit to the key price,
             * then the price hike reduces by 0.1%. This tapering will continue until the minimum 0.2% price increase is reached. 
             * This game should end well before reaching 0.2% increases. 
             * If it doesn't, then you people took this way too seriously and somebody is going to get hurt.
             * EXAMPLE: KeyPrice=10 results in 1% increases each time keys are bought. 
             * When KeyPrice=100, price will now increase by 0.9%. When KeyPrice=1000, price increases by 0.8% and so on..
             * This continues until 0.2%. Again, it shouldn't get that far...
            */
            uint numerator = keyPrice*multiplier;
            keyPrice = keyPrice + numerator/10000;
                if (keyPrice/increased_order >= 10 && multiplier >= 20) {
                    increased_order = keyPrice;
                    multiplier = multiplier - 10;
                }
        /**
         * @dev If multiple players purchase a key at the same time (i.e. executes purchaseKeys function in the same block),
         * the key price only gets updated by the first purchaseKeys call in that block. 
        */
        } else {
            uint numerator = keyPrice*multiplier;
            uint tempKeyPrice = keyPrice - numerator/10000;
            require(msg.value >= tempKeyPrice*_amount && block.number <= keyPriceIncreaseBlockNumber+2, "Not enough to buy the key(s): Key price is increasing quickly. Try refreshing the page and quickly submitting key purchase again.");
        }
        uint devShareNumerator = msg.value*100;
        uint devShare = devShareNumerator/10000;
        uint gameShare = msg.value - devShare;
        uint floor = gameShare/2;
        developerOnePercent += devShare;
        jackpot += floor;
        divPool += gameShare - floor; 
        divTracker[msg.sender]._keyBalance += _amount;
        divTracker[msg.sender]._boughtKeys = true;
        totalKeys += _amount;
        if (_amount*30 > 86400 - (totalTime-block.timestamp)) {
            letTheGamesBegin();
        } else {
            totalTime += _amount*30;
        }

        keyPurchases += 1;
        winning = msg.sender;
        emit keysPurchased(_amount, winning);
    } 
    /**
     * @dev returns which address is currently winning. 
     * I know this is redundant but it just needs to be here.
    */
    function getWinner() public view returns(address) {
        return winning;
    }
    /**
     * @notice Tracks each player's dividends.
     * EXAMPLE: (UserKeys/TotalKeys)*TotalDividendPool - UserPreviousWithdrawls
     * The ratio of a user's keys to all keys purchased determines the proportion of the entire
     * dividend pool the user is entitled to. Subtracting any amount the user has already withdrawn.
    */
    function updateDivvies(address _userAddress) public view returns(uint) {
        uint tempUserWithdrawAmount;
        uint tempNumerator;
        if (totalKeys == 0 ) {
            tempUserWithdrawAmount = 0;
        } else {
            tempNumerator = divTracker[_userAddress]._keyBalance * divPool;
            tempUserWithdrawAmount = tempNumerator/totalKeys - divTracker[_userAddress]._withdrawnAmount;  
        }  
        return tempUserWithdrawAmount;
    }
    /**
     * @dev Contains the same 'on-the-fly' calculations as the updateDivvies function,
     * as well as setting that user's withdrawn amount.
     * Ah crap, I've been using "withdraw" instead of "withdrawal" throughout the code.
    */
    function withdrawDivvies() public isHuman() {
        address payable to = payable(msg.sender);
        uint tempUserWithdrawAmount;
        uint tempNumerator;
        if (totalKeys == 0 ) {
            tempUserWithdrawAmount = 0;
        } else {
            tempNumerator = divTracker[msg.sender]._keyBalance * divPool;
            tempUserWithdrawAmount = tempNumerator/totalKeys - divTracker[msg.sender]._withdrawnAmount;
            divTracker[msg.sender]._withdrawnAmount += tempUserWithdrawAmount;
        }  
        require(tempUserWithdrawAmount > 0, "You have no divvies to claim");
        to.transfer(tempUserWithdrawAmount);
    }

    /**
     * @notice Criteria to claim jackpot:
     * 1.) The game must be over (i.e. timer at zero).
     * 2.) User must be the winner (only winner can withdraw jackpot).
     * 3.) Jackpot must have a non zero balance (I can't blame you for trying to withdraw it twice).
    */
    function jackpotPayout() public isHuman() {
        require(getTimeLeft() == 0, "game is still in play");
        require(jackpot > 0, "No money in jackpot");
        require(msg.sender == winning, "you are not the winner");
        address payable to = payable(winning);
        to.transfer(jackpot);
        /**
         * @dev Yes I know the solidity static analyzer flags this as being susceptible
         * to a reentry attack, but look at the require statements.
        */  
        jackpot = 0;
    }

    function whoWon(address _userAddress) public view returns(address winner){
        if (getTimeLeft() == 0 && _userAddress == winning) {
            winner = _userAddress;
            return winner;
        }
    }
    /**
     * @notice The game must be over and then I can call this function.
     * Depending on the outcome of the vote, I'll either pay the gas to send the 1% 
     * to the winner, or to the developer (me). 
     * Disclaimer: A tie goes to the developer.
    */
    function developerOnePercentAllocation(address _developerAddress) public {
        require(msg.sender == developer, "you aren't the developer of this contract.");
        require(getTimeLeft() == 0, "game is still in play");
        if (giveToDeveloper >= giveToJackpot) {
            address payable to = payable(_developerAddress);
            to.transfer(developerOnePercent);
            
        } else {
            address payable to = payable(winning);
            to.transfer(developerOnePercent);
        }
        developerOnePercent = 0;
    }
    /**
     * @notice 1% of every key purchase is set aside. Key holders may cast their
     * vote to decide if the 1% should go to the developer (really cool guy) or whoever wins.
     * Criteria to vote (FYI voting will cost gas):
     * 1.) Player must own at least one key.
     * 2.) The game must be alive (timer not at zero).
     * 3.) Player has not already voted.
    */
    function voteForOnePercent(bool _vote) public isHuman() {
        require(divTracker[msg.sender]._boughtKeys == true, "you need to buy at least one key to vote.");
        require(getTimeLeft() > 0, "Game is over and polls have closed");
        require(divTracker[msg.sender]._voted == false, "you already voted.");
        divTracker[msg.sender]._voted = true;
        if (_vote == true) {
            giveToDeveloper += 1;
        } else {
            giveToJackpot += 1;
        }
    }

}