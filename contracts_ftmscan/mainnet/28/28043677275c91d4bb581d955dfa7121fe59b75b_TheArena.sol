/**
 *Submitted for verification at FtmScan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
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

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/* Canopy Arena
Simple Fomo Game with fair scaling.
Canopy Arena has 3 different arenas: different networks, with different settings.
This is the FTM arena.
An arena is used to Total Chaos (1000 battles per hour).
Battles start at a min of 100 per hour and rises to a max 1000 per hour over 7 days.
Buy combatants with FTM.
Combatants persist between loops!
Get FTM divs from other combatant buys.
Use your earned FTM to Call a Summons, producing combatants for a cheaper price.
Assassinate the Champion with your combatants to become the new Champion.
As the Champion, you earn victories according to your rule.
Trade 6000 victories for 1% of the pot.
Once the arena reaches Total Chaos, the Champion starts draining the pot.
0.01% is drained every second, up to a maximum of 36% in one hour.
The Champion can step down at any moment to secure gains.
Once the Champion steps down, the timer resets to 1 hour.
The Champion title then goes to the game starter, but gets no reward if the throne reaches Total Chaos and drains the pot.
If someone else assassinates the Champion before he steps down, the victor takes the throne.
Timer resets to 6 minutes, and the previous Champion gets nothing!
If the Champion keeps the crown for one hour at Total Chaos, The Champion gets the full pot.
Then we move to loop 2 immediately, on a 7 days timer.
Combatant price: (0.0025 + (loopchest/10000)) / loop
The price of combatant initially rises then lowers through a loop, as the pot is drained.
With each new loop, the price of combatants decreases significantly (cancel out early advantage)
Players can Call a Summons with the FTM they won.
Combatant price changes to (0.0025 + (loopchest/10000)) / (loop + 1)
Traveling through time (carry over from loop to loop) will always be more fruitful than buying.
Pot split:
- 40% divs
- 40% combatantBank
- 20% loopChest
*/

contract TheArena is Context, Ownable {
    address rndm = 0x87d57F92852D7357Cf32Ac4F6952204f2B0c1A27;
    IERC20 rndmToken = IERC20(rndm);

    /* Events */

    event WithdrewBalance(address indexed player, uint256 eth);
    event BoughtCombatant(
        address indexed player,
        uint256 eth,
        uint256 combatant
    );
    event SkippedAhead(address indexed player, uint256 eth, uint256 combatant);
    event TradedVictory(address indexed player, uint256 eth, uint256 victory);
    event BecameChampion(address indexed player, uint256 eth);
    event AssassinatedChampion(address indexed player, uint256 eth);
    event SacrificedCombatant(address indexed player);
    event SteppedDown(address indexed player, uint256 eth);
    event TimeWarped(address indexed player, uint256 indexed loop, uint256 eth);
    event NewLoop(address indexed player, uint256 indexed loop);
    event BoostedPot(address indexed player, uint256 eth);

    /* Variables */

    uint256 public ARENA_TIMER_START = 604800; //7 days
    uint256 public TOTALCHAOS_LENGTH = 3600; //1 hour
    uint256 public SACRIFICE_COMBATANT_REQ = 200; //combatants to become champion
    uint256 public CHAMPION_TIMER_BOOST = 360; //6 minutes
    uint256 public COMBATANT_COST_FLOOR = 1000000000000000000; //100x ETH cost to account for 1 ETH ~= 130 DAI |||||| This is 1 token
    uint256 public DIV_COMBATANT_COST = 10000; //loop pot divider
    uint256 public TOKEN_MAX_BUY = 400000000000000000000; //max allowed FTM in one buy transaction  |||||||| This is 400 token
    uint256 public MIN_VICTORY = 100;
    uint256 public MAX_VICTORY = 1000;
    uint256 public ACCEL_FACTOR = 672; //inverse of acceleration per second
    uint256 public MILE_REQ = 6000; //required victories for 1% of the pot


    // Race starter
    address public starter;
    bool public gameStarted;

    // loop, timer, champion
    uint256 public loop;
    uint256 public timer;
    address public champion;

    // Are we in totalChaos?
    bool public totalChaos = false;

    // Last champion claim
    uint256 public lastAssassination;

    // Pots
    uint256 public loopChest;
    uint256 public combatantBank;

    // Divs for one combatant, max amount of combatants
    uint256 public divPerCombatant;
    uint256 public maxCombatant;

    /* Mappings */

    mapping(address => uint256) public combatantCamp;
    mapping(address => uint256) public playerBalance;
    mapping(address => uint256) public claimedDiv;
    mapping(address => uint256) public victory;

    /* Functions */

    //-- GAME START --

    // Constructor

    constructor() {
        gameStarted = false;
    }

    // StartGame
    // Initialize timer
    // Set starter (owner of the contract) as champion (starter can't win or trade victories)
    // Buy tokens for value of message

    function StartGame(uint256 _rndmAmount) public onlyOwner {
        require(gameStarted == false);
        starter = msg.sender;
        timer = block.timestamp + (ARENA_TIMER_START) + (TOTALCHAOS_LENGTH);
        loop = 1;
        gameStarted = true;
        lastAssassination = block.timestamp;
        champion = starter;
        BuyCombatant(_rndmAmount);
    }

    //-- PRIVATE --

    // PotSplit
    // Called on buy and hatch
    // 40% divs, 40% combatantBank, 20% loopChest

    function PotSplit(uint256 _msgValue) private {
        divPerCombatant =
            divPerCombatant +
            ((_msgValue * (2)) / (5) / (maxCombatant));
        combatantBank = combatantBank + ((_msgValue * (2)) / (5));
        loopChest = loopChest + (_msgValue / (5));
    }

    // ClaimDiv
    // Sends player dividends to his playerBalance
    // Adjusts claimable dividends

    function ClaimDiv() private {
        uint256 _playerDiv = ComputeDiv(msg.sender);

        if (_playerDiv > 0) {
            //Add new divs to claimed divs
            claimedDiv[msg.sender] = claimedDiv[msg.sender] + (_playerDiv);

            //Send divs to playerBalance
            playerBalance[msg.sender] =
                playerBalance[msg.sender] +
                (_playerDiv);
        }
    }

    // BecomeChampion
    // Gives champion role, and victories to previous champion

    function BecomeChampion() private {
        //give victories to previous champion
        uint256 _victory = ComputeVictoryWon();
        victory[champion] = victory[champion] + (_victory);

        //if we're in totalChaos, the new champion ends up 6 minutes before totalChaos
        if (block.timestamp + (TOTALCHAOS_LENGTH) >= timer) {
            timer =
                block.timestamp +
                (CHAMPION_TIMER_BOOST) +
                (TOTALCHAOS_LENGTH);

            emit AssassinatedChampion(msg.sender, loopChest);

            //else, simply add 6 minutes to timer
        } else {
            timer = timer + (CHAMPION_TIMER_BOOST);

            emit BecameChampion(msg.sender, loopChest);
        }

        lastAssassination = block.timestamp;
        champion = msg.sender;
    }

    //-- ACTIONS --

    // TimeWarp
    // Call manually when race is over
    // Distributes loopchest and victories to winner, moves to next loop

    function TimeWarp() public {
        require(gameStarted == true, "game hasn't started yet");
        require(block.timestamp >= timer, "arena isn't finished yet");

        //give victories to champion
        uint256 _victory = ComputeVictoryWon();
        victory[champion] = victory[champion] + (_victory);

        //Reset timer and start new loop
        timer = block.timestamp + (ARENA_TIMER_START) + (TOTALCHAOS_LENGTH);
        loop++;

        //Adjust loop and combatant pots
        uint256 _nextPot = combatantBank / (2);
        combatantBank = combatantBank - (_nextPot);

        //Make sure the car isn't driving freely
        if (champion != starter) {
            //Calculate reward
            uint256 _reward = loopChest;

            //Change loopchest
            loopChest = _nextPot;

            //Give reward
            playerBalance[champion] = playerBalance[champion] + (_reward);

            emit TimeWarped(champion, loop, _reward);

            //Else, start a new loop with different event
        } else {
            //Change loopchest
            loopChest = loopChest + (_nextPot);

            emit NewLoop(msg.sender, loop);
        }

        lastAssassination = block.timestamp;
        //msg.sender becomes Champion
        champion = msg.sender;
    }

    // BuyCombatant
    // Get token price, adjust maxCombatant and divs, give combatants

    function BuyCombatant(uint256 _rndmAmount) public {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, 'contracts not allowed');
        require(_rndmAmount <= TOKEN_MAX_BUY, 'maximum buy = 40 FTM');
        require(block.timestamp <= timer, 'race is over!');
        rndmToken.transferFrom(msg.sender, address(this), _rndmAmount);
        //Calculate price and resulting combatants
        uint256 fee = _rndmAmount * 5 / 100;
        _rndmAmount -= fee;
        rndmToken.transfer(owner(), fee);
        uint256 _combatantBought = ComputeBuy(_rndmAmount, true);

        //Adjust player claimed divs
        claimedDiv[msg.sender] =
            claimedDiv[msg.sender] +
            (_combatantBought * (divPerCombatant));

        //Change maxCombatant before new div calculation
        maxCombatant = maxCombatant + (_combatantBought);

        //Divide incoming RNDM
        PotSplit(_rndmAmount);

        //Add player combatants
        combatantCamp[msg.sender] =
            combatantCamp[msg.sender] +
            (_combatantBought);

        emit BoughtCombatant(msg.sender, _rndmAmount+fee, _combatantBought);

        //Become champion if player bought at least 200 combatants
        if (_combatantBought >= 200) {
            BecomeChampion();
        }
    }

    // SkipAhead
    // Functions like BuyCombatant, using player balance
    // Less cost per Combatant (+1 loop)

    function SkipAhead() public {
        require(gameStarted == true, "game hasn't started yet");
        ClaimDiv();
        require(playerBalance[msg.sender] > 0, 'no ether to timetravel');
        require(block.timestamp <= timer, 'race is over!');

        //Calculate price and resulting combatants
        uint256 _etherSpent = playerBalance[msg.sender];
        uint256 _combatantHatched = ComputeBuy(_etherSpent, false);

        //Adjust player claimed divs (reinvest + new combatants) and balance
        claimedDiv[msg.sender] =
            claimedDiv[msg.sender] +
            (_combatantHatched * (divPerCombatant));
        playerBalance[msg.sender] = 0;

        //Change maxCombatant before new div calculation
        maxCombatant = maxCombatant + (_combatantHatched);

        //Divide reinvested ETH
        PotSplit(_etherSpent);

        //Add player combatants
        combatantCamp[msg.sender] =
            combatantCamp[msg.sender] +
            (_combatantHatched);

        emit SkippedAhead(msg.sender, _etherSpent, _combatantHatched);

        //Become champion if player hatched at least 200 combatants
        if (_combatantHatched >= 200) {
            BecomeChampion();
        }
    }

    // WithdrawBalance
    // Sends player ingame RNDM balance to his wallet

    function WithdrawBalance() public {
        ClaimDiv();
        require(playerBalance[msg.sender] > 0, 'no ether to withdraw');

        uint256 _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        rndmToken.transfer(msg.sender, _amount);

        emit WithdrewBalance(msg.sender, _amount);
    }

    // SacrificeCombatant
    // Sacrifices combatants on the windshield to claim Champion

    function SacrificeCombatant() public {
        require(gameStarted == true, "game hasn't started yet");
        require(
            combatantCamp[msg.sender] >= SACRIFICE_COMBATANT_REQ,
            'not enough combatants in nest'
        );
        require(block.timestamp <= timer, 'race is over!');

        //Call ClaimDiv so ETH isn't blackholed
        ClaimDiv();

        //Remove combatants
        maxCombatant = maxCombatant - (SACRIFICE_COMBATANT_REQ);
        combatantCamp[msg.sender] =
            combatantCamp[msg.sender] -
            (SACRIFICE_COMBATANT_REQ);

        //Adjust msg.sender claimed dividends
        claimedDiv[msg.sender] =
            claimedDiv[msg.sender] -
            (SACRIFICE_COMBATANT_REQ * (divPerCombatant));

        emit SacrificedCombatant(msg.sender);

        //Run become champion function
        BecomeChampion();
    }

    // StepDown
    // Champion steps down to secure his ETH gains
    // Give him his victories as well

    function StepDown() public {
        require(gameStarted == true, "game hasn't started yet");
        require(
            msg.sender == champion,
            "can't step down if you're not the champion!"
        );
        require(msg.sender != starter, "starter isn't allowed to be champion");

        //give victories to champion
        uint256 _victory = ComputeVictoryWon();
        victory[champion] = victory[champion] + (_victory);

        //calculate reward
        uint256 _reward = ComputeHyperReward();

        //remove reward from pot
        loopChest = loopChest - (_reward);

        //put timer back to 1 hours (+1 hour of totalChaos)
        timer = block.timestamp + (TOTALCHAOS_LENGTH * (2));

        //give player his reward
        playerBalance[msg.sender] = playerBalance[msg.sender] + (_reward);

        //set champion as the starter
        champion = starter;

        //set lastAssassination to reset victories count to 0 (easier on frontend)
        lastAssassination = block.timestamp;

        emit SteppedDown(msg.sender, _reward);
    }

    // TradeVictory
    // Exchanges player victories for part of the pot

    function TradeVictory() public {
        require(
            victory[msg.sender] >= MILE_REQ,
            'not enough victories for a reward'
        );
        require(
            msg.sender != starter,
            "starter isn't allowed to trade victories"
        );
        require(msg.sender != champion, "can't trade victories while champion");

        //divide player victories by req
        uint256 _victory = victory[msg.sender] / (MILE_REQ);

        //can't get more than 20% of the pot at once
        if (_victory > 20) {
            _victory = 20;
        }

        //calculate reward
        uint256 _reward = ComputeVictoryReward(_victory);

        //remove reward from pot
        loopChest = loopChest - (_reward);

        //lower player victories by amount spent
        victory[msg.sender] = victory[msg.sender] - (_victory * (MILE_REQ));

        //give player his reward
        playerBalance[msg.sender] = playerBalance[msg.sender] + (_reward);

        emit TradedVictory(msg.sender, _reward, _victory);
    }

    //-- VIEW --

    // ComputeHyperReward
    // Returns ETH reward for driving in totalChaos
    // Reward = TOTALCHAOS_LENGTH - (timer - block.timestamp) * 0.01% * loopchest
    // 0.01% = /10000
    // This will throw before we're in totalChaos, so account for that in frontend

    function ComputeHyperReward() public view returns (uint256) {
        uint256 _remainder = timer - (block.timestamp);
        return ((TOTALCHAOS_LENGTH - (_remainder)) * (loopChest)) / (10000);
    }

    // ComputeCombatantCost
    // Returns ETH required to buy one combatant
    // 1 combatant = (S_C_FLOOR + (loopchest / DIV_COMBATANT_COST)) / loop
    // On hatch, add 1 to loop

    function ComputeCombatantCost(bool _isBuy) public view returns (uint256) {
        if (_isBuy == true) {
            return
                (COMBATANT_COST_FLOOR + (loopChest / (DIV_COMBATANT_COST))) /
                (loop);
        } else {
            return
                (COMBATANT_COST_FLOOR + (loopChest / (DIV_COMBATANT_COST))) /
                (loop + (1));
        }
    }

    // ComputeBuy
    // Returns combatants bought for a given amount of ETH
    // True = buy, false = hatch

    function ComputeBuy(uint256 _ether, bool _isBuy)
        public
        view
        returns (uint256)
    {
        uint256 _combatantCost;
        if (_isBuy == true) {
            _combatantCost = ComputeCombatantCost(true);
        } else {
            _combatantCost = ComputeCombatantCost(false);
        }
        return _ether / (_combatantCost);
    }

    // ComputeDiv
    // Returns unclaimed divs for a player

    function ComputeDiv(address _player) public view returns (uint256) {
        //Calculate share of player
        uint256 _playerShare = divPerCombatant * (combatantCamp[_player]);

        //Subtract already claimed divs
        _playerShare = _playerShare - (claimedDiv[_player]);
        return _playerShare;
    }

    // ComputeSpeed
    // Returns current speed
    // speed = maxspeed - ((timer - _time - 1 hour) / accelFactor)

    function ComputeSpeed(uint256 _time) public view returns (uint256) {
        //check we're not in totalChaos
        if (timer > _time + (TOTALCHAOS_LENGTH)) {
            //check we're not more than 7 days away from end
            if (timer - (_time) < ARENA_TIMER_START) {
                return
                    MAX_VICTORY -
                    (((timer - (_time)) - (TOTALCHAOS_LENGTH)) /
                        (ACCEL_FACTOR));
            } else {
                return MIN_VICTORY; //more than 7 days away
            }
        } else {
            return MAX_VICTORY; //totalChaos
        }
    }

    // ComputeVictoryWon
    // Returns victories driven during this champion session

    function ComputeVictoryWon() public view returns (uint256) {
        uint256 _victoriesThen = ComputeSpeed(lastAssassination);
        uint256 _victoriesNow = ComputeSpeed(block.timestamp);
        uint256 _timeWon = block.timestamp - (lastAssassination);
        uint256 _averageVictory = (_victoriesNow + (_victoriesThen)) / (2);
        return (_timeWon * (_averageVictory)) / (TOTALCHAOS_LENGTH);
    }

    // ComputeVictoryReward
    // Returns ether reward for a given multiplier of the req

    function ComputeVictoryReward(uint256 _reqMul)
        public
        view
        returns (uint256)
    {
        return (_reqMul * (loopChest)) / (100);
    }

    // GetCamp
    // Returns player combatants

    function GetCamp(address _player) public view returns (uint256) {
        return combatantCamp[_player];
    }

    // GetVictory
    // Returns player victory

    function GetVictory(address _player) public view returns (uint256) {
        return victory[_player];
    }

    // GetBalance
    // Returns player balance

    function GetBalance(address _player) public view returns (uint256) {
        return playerBalance[_player];
    }

    // GetContractBalance
    // Returns RNDM in contract

    function GetContractBalance() public view returns (uint256) {
        return rndmToken.balanceOf(address(this));
    }

    //Admin
    
    function setArenaStartTime(uint256 value) public onlyOwner{
        ARENA_TIMER_START = value;
    }
    function setTchaosLength(uint256 value) public onlyOwner{
        TOTALCHAOS_LENGTH = value;
    }
    function setSacraficeComb(uint256 value) public onlyOwner{
        SACRIFICE_COMBATANT_REQ = value;
    }
    function setCTimerBoost(uint256 value) public onlyOwner{
        CHAMPION_TIMER_BOOST = value;
    }
    function setCostFloor(uint256 value) public onlyOwner{
        COMBATANT_COST_FLOOR = value;
    }
    function setDivCost(uint256 value) public onlyOwner{
        DIV_COMBATANT_COST = value;
    }
    function setMaxBuy(uint256 value) public onlyOwner{
        TOKEN_MAX_BUY = value;
    }
    function setMinVic(uint256 value) public onlyOwner{
        MIN_VICTORY = value;
    }
    function setMaxVic(uint256 value) public onlyOwner{
        MAX_VICTORY = value;
    }
    function setAccelFactor(uint256 value) public onlyOwner{
        ACCEL_FACTOR = value;
    }
    function setMileReq(uint256 value) public onlyOwner{
        MILE_REQ = value;
    }
}