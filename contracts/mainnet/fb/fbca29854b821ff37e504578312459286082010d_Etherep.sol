pragma solidity ^0.4.11;

/*  Copyright 2017 GoInto, LLC

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/**
 * Storage contract for Etherep to store ratings and score data.  It&#39;s been 
 * separated from the main contract because this is much less likely to change
 * than the other parts.  It would allow for upgrading the main contract without
 * losing data.
 */
contract RatingStore {

    struct Score {
        bool exists;
        int cumulativeScore;
        uint totalRatings;
    }

    bool internal debug;
    mapping (address => Score) internal scores;
    // The manager with full access
    address internal manager;
    // The contract that has write accees
    address internal controller;

    /// Events
    event Debug(string message);

    /**
     * Only the manager or controller can use this method
     */
    modifier restricted() { 
        require(msg.sender == manager || tx.origin == manager || msg.sender == controller);
        _; 
    }

    /**
     * Only a certain address can use this modified method
     * @param by The address that can use the method
     */
    modifier onlyBy(address by) { 
        require(msg.sender == by);
        _; 
    }

    /**
     * Constructor
     * @param _manager The address that has full access to the contract
     * @param _controller The contract that can make write calls to this contract
     */
    function RatingStore(address _manager, address _controller) {
        manager = _manager;
        controller = _controller;
        debug = false;
    }

    /**
     * Set a Score
     * @param target The address&#39; score we&#39;re setting
     * @param cumulative The cumulative score for the address
     * @param total Total individual ratings for the address
     * @return success If the set was completed successfully
     */
    function set(address target, int cumulative, uint total) external restricted {
        if (!scores[target].exists) {
            scores[target] = Score(true, 0, 0);
        }
        scores[target].cumulativeScore = cumulative;
        scores[target].totalRatings = total;
    }

    /**
     * Add a rating
     * @param target The address&#39; score we&#39;re adding to
     * @param wScore The weighted rating to add to the score
     * @return success
     */
    function add(address target, int wScore) external restricted {
        if (!scores[target].exists) {
            scores[target] = Score(true, 0, 0);
        }
        scores[target].cumulativeScore += wScore;
        scores[target].totalRatings += 1;
    }

    /**
     * Get the score for an address
     * @param target The address&#39; score to return
     * @return cumulative score
     * @return total ratings
     */
    function get(address target) external constant returns (int, uint) {
        if (scores[target].exists == true) {
            return (scores[target].cumulativeScore, scores[target].totalRatings);
        } else {
            return (0,0);
        }
    }

    /**
     * Reset an entire score storage
     * @param target The address we&#39;re wiping clean
     */
    function reset(address target) external onlyBy(manager) {
        scores[target] = Score(true, 0,0);
    }

    /**
     * Return the manager
     * @return address The manager address
     */
    function getManager() external constant returns (address) {
        return manager;
    }

    /**
     * Change the manager
     * @param newManager The address we&#39;re setting as manager
     */
    function setManager(address newManager) external onlyBy(manager) {
        manager = newManager;
    }

    /**
     * Return the controller
     * @return address The manager address
     */
    function getController() external constant returns (address) {
        return controller;
    }

    /**
     * Change the controller
     * @param newController The address we&#39;re setting as controller
     */
    function setController(address newController) external onlyBy(manager) {
        controller = newController;
    }

    /**
     * Return the debug setting
     * @return bool debug
     */
    function getDebug() external constant returns (bool) {
        return debug;
    }

    /**
     * Set debug
     * @param _debug The bool value debug should be set to
     */
    function setDebug(bool _debug) external onlyBy(manager) {
        debug = _debug;
    }

}

/** Ethereum Reputation

    Contract that takes ratings and calculates a reputation score
 */
contract Etherep {

    bool internal debug;
    address internal manager;
    uint internal fee;
    address internal storageAddress;
    uint internal waitTime;
    mapping (address => uint) internal lastRating;

    /// Events
    event Error(
        address sender,
        string message
    );
    event Debug(string message);
    event DebugInt(int message);
    event DebugUint(uint message);
    event Rating(
        address by, 
        address who, 
        int rating
    );
    event FeeChanged(uint f);
    event DelayChanged(uint d);

    /**
     * Only a certain address can use this modified method
     * @param by The address that can use the method
     */
    modifier onlyBy(address by) { 
        require(msg.sender == by);
        _; 
    }

    /**
     * Delay ratings to be at least waitTime apart
     */
    modifier delay() {
        if (debug == false && lastRating[msg.sender] > now - waitTime) {
            Error(msg.sender, "Rating too often");
            revert();
        }
        _;
    }

    /**
     * Require the minimum fee to be met
     */
    modifier requireFee() {
        require(msg.value >= fee);
        _;
    }

    /** 
     * Constructor
     * @param _manager The key that can make changes to this contract
     * @param _fee The variable fee that will be charged per rating
     * @param _storageAddress The address to the storage contract
     * @param _wait The minimum time in seconds a user has to wait between ratings
     */
    function Etherep(address _manager, uint _fee, address _storageAddress, uint _wait) {
        manager = _manager;
        fee = _fee;
        storageAddress = _storageAddress;
        waitTime = _wait;
        debug = false;
    }

    /**
     * Set debug
     * @param d The debug value that should be set
     */
    function setDebug(bool d) external onlyBy(manager) {
        debug = d;
    }

    /**
     * Get debug
     * @return debug
     */
    function getDebug() external constant returns (bool) {
        return debug;
    }

    /**
     * Change the fee
     * @param newFee New rating fee in Wei
     */
    function setFee(uint newFee) external onlyBy(manager) {
        fee = newFee;
        FeeChanged(fee);
    }

    /**
     * Get the fee
     * @return fee The current fee in Wei
     */
    function getFee() external constant returns (uint) {
        return fee;
    }

    /**
     * Change the rating delay
     * @param _delay Delay in seconds
     */
    function setDelay(uint _delay) external onlyBy(manager) {
        waitTime = _delay;
        DelayChanged(waitTime);
    }

    /**
     * Get the delay time
     * @return delay The current rating delay time in seconds
     */
    function getDelay() external constant returns (uint) {
        return waitTime;
    }

    /**
     * Change the manager
     * @param who The address of the new manager
     */
    function setManager(address who) external onlyBy(manager) {
        manager = who;
    }

    /**
     * Get the manager
     * @return manager The address of this contract&#39;s manager
     */
    function getManager() external constant returns (address) {
        return manager;
    }

    /**
     * Drain fees
     */
    function drain() external onlyBy(manager) {
        require(this.balance > 0);
        manager.transfer(this.balance);
    }

    /** 
     * Adds a rating to an address&#39; cumulative score
     * @param who The address that is being rated
     * @param rating The rating(-5 to 5)
     * @return success If the rating was processed successfully
     */
    function rate(address who, int rating) external payable delay requireFee {

        require(rating <= 5 && rating >= -5);
        require(who != msg.sender);

        RatingStore store = RatingStore(storageAddress);
        
        // Starting weight
        int weight = 0;

        // Rating multiplier
        int multiplier = 100;

        // We need the absolute value
        int absRating = rating;
        if (absRating < 0) {
            absRating = -rating;
        }

        // Get details on sender if available
        int senderScore;
        uint senderRatings;
        int senderCumulative = 0;
        (senderScore, senderRatings) = store.get(msg.sender);

        // Calculate cumulative score if available
        if (senderScore != 0) {
            senderCumulative = (senderScore / (int(senderRatings) * 100)) * 100;
        }

        // Calculate the weight if the sender is rated above 0
        if (senderCumulative > 0) {
            weight = (((senderCumulative / 5) * absRating) / 10) + multiplier;
        }
        // Otherwise, unweighted
        else {
            weight = multiplier;
        }
        
        // Calculate weighted rating
        int workRating = rating * weight;

        // Set last rating timestamp
        lastRating[msg.sender] = now;

        Rating(msg.sender, who, workRating);

        // Add the new rating to their score
        store.add(who, workRating);

    }

    /**
     * Returns the cumulative score for an address
     * @param who The address to lookup
     * @return score The cumulative score
     */
    function getScore(address who) external constant returns (int score) {

        RatingStore store = RatingStore(storageAddress);
        
        int cumulative;
        uint ratings;
        (cumulative, ratings) = store.get(who);
        
        // The score should have room for 2 decimal places, but ratings is a 
        // single count
        score = cumulative / int(ratings);

    }

    /**
     * Returns the cumulative score and count of ratings for an address
     * @param who The address to lookup
     * @return score The cumulative score
     * @return count How many ratings have been made
     */
    function getScoreAndCount(address who) external constant returns (int score, uint ratings) {

        RatingStore store = RatingStore(storageAddress);
        
        int cumulative;
        (cumulative, ratings) = store.get(who);
        
        // The score should have room for 2 decimal places, but ratings is a 
        // single count
        score = cumulative / int(ratings);

    }

}