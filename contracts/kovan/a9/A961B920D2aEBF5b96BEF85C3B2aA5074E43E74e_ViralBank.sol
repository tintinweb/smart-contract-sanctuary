/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.5.0;


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

contract ILendingPoolAddressesProvider {

    function getLendingPool() public view returns (address);
    function setLendingPoolImpl(address _pool) public;

    function getLendingPoolCore() public view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public;

    function getLendingPoolConfigurator() public view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public;

    function getLendingPoolDataProvider() public view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public;

    function getLendingPoolParametersProvider() public view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public;

    function getTokenDistributor() public view returns (address);
    function setTokenDistributor(address _tokenDistributor) public;


    function getFeeProvider() public view returns (address);
    function setFeeProviderImpl(address _feeProvider) public;

    function getLendingPoolLiquidationManager() public view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public;

    function getLendingPoolManager() public view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public;

    function getPriceOracle() public view returns (address);
    function setPriceOracle(address _priceOracle) public;

    function getLendingRateOracle() public view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public;

}

contract ILendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) public;
    //see: https://github.com/aave/aave-protocol/blob/1ff8418eb5c73ce233ac44bfb7541d07828b273f/contracts/tokenization/AToken.sol#L218
    function redeem(uint256 _amount) external;
}

contract ViralBank is IERC20 {

    // A short cut to figure out what this contract is doing
    // See getGmaeState()
    enum GameState {
        Starting,  // All players must do the first buy in with startGame()
        Playing,   // Monthly buy ins going with buyInMonthly()
        Cleaning,  // Need to manually call clean up for every player checkForDead()
        PayingOut  // Dividends are ready to be claimed with todo()
    }

    // How one address is faring
    // See getPlayerState()
    enum PlayerState {
        NotPlaying, // Did not get in during incubation
        Playing,    // Has kept up with the payments
        DroppedOut, // Missed a payment
        Finished    // Made up to the finishing line
    }

    // Token that patients use to buy in the game - DAI
    IERC20 public daiToken;

    // Pointer to aDAI
    IERC20 public adaiToken;

    // Which Aave instance we use to swap DAI to interest bearing aDAI
    ILendingPoolAddressesProvider public lendingPoolAddressProvider;

    // What is the monthly payment and buy in
    // Now 9.90 DAI
    uint public ticketSize = 9.90 * 10**18;

    // How many players started the journey
    uint public playerCount = 0;

    // How many people made it - after clean up
    uint public finishedPlayerCount = 0;

    // When the game started
    uint public startedAt = now;

    // How long we want to play
    uint public constant ROUND_LENGTH = 7 days;
    uint public constant INCUBATION_PERIOD = ROUND_LENGTH; // Can't differ - simplified math
    uint public constant GAME_LENGTH = 52 * 7 days;

    // Aave pays us kick back for DAI -> aDAI conversion
    // https://developers.aave.com/#referral-program
    uint16 public constant AAVE_REFERRAL_CODE = 0;

    // Book keeping
    address public patientZero;
    mapping(address => uint) public balances;
    uint public totalDeposits;

    // Track if the player has been keeping up with the game
    mapping(address => uint) public lastActivityAt;
    mapping(address => uint) public lastRound;

    //
    // Referral system
    //

    // player who bought in -> his/her referral
    mapping(address => address) public referrals;
    mapping(address => uint) public referrerCount;

    // how many interest shares each player has
    mapping(address => uint) public allocations;
    uint public totalAllocations = 0;

    //
    // Final score calculations
    //

    // Have we executed clean up for this player
    mapping(address => bool) public cleanedUp;
    uint public cleanedUpPlayerCount;

    // How much shares for the prize pool was left after eliminating all the dead
    uint public aliveAllocations = 0;

    // Withdrawal and interest handling
    uint totalWithdrawals = 0;

    constructor(IERC20 _inboundCurrency, IERC20 _interestCurrency, ILendingPoolAddressesProvider _lendingPoolAddressProvider) public {
        daiToken = _inboundCurrency;
        adaiToken = _interestCurrency;
        lendingPoolAddressProvider = _lendingPoolAddressProvider;

        // Allow lending pool convert DAI deposited on this contract to aDAI on lending pool
        uint MAX_ALLOWANCE = 2**256 - 1;
        address core = lendingPoolAddressProvider.getLendingPoolCore();
        daiToken.approve(core, MAX_ALLOWANCE);
    }

    // A new player joins the game
    function startGame(address referral) public {

        require(!isIncubationPeriodOver(), "Cannot come in after the pets have escaped the lab");

        if(playerCount == 0) {
            // Patient zero
            require(referral == address(0), "Patient zero has no referral");
            patientZero = msg.sender;
        } else {
            require(referral != address(0), "All players must have a referral");
            require(isPlayerInGame(referral), "Dead players cannot refer");

            // Referring player gets 10% interested earned by this player
            allocations[referral] += 10;
            totalAllocations += 10;
        }

        require(lastRound[msg.sender] == 0, "Need to start at round zero");
        _buyIn();

        playerCount++;

        referrals[msg.sender] = referral;

        // Superinfecter board update
        // TODO: Emit a sorted event?
        referrerCount[referral] += 1;

        // This player gets full interest for themselves
        allocations[msg.sender] += 100;
        totalAllocations += 100;

        // Second level multi marketing pyramid
        address secondLevel = referrals[referral];
        if(secondLevel != address(0)) {
            // Second level referrers give you 1% of their interest
            allocations[secondLevel] += 1;
            totalAllocations += 1;
        }
    }

    // Need to hit this every month or you are out of the game
    function buyInToRound() public {
        require(areWeHavingFun(), "Game has ended");
        require(isPlayerAddress(msg.sender), "You are not a player");
        require(isPlayerInGame(msg.sender), "You have dropped off.");

        // Check that the user has completed all the previous rounds
        if(getCurrentRoundNumber() != 0) {
            require(lastRound[msg.sender] == getCurrentRoundNumber(), "You need to be on the previous round to buy in the next one");
        }

        _buyIn();
    }

    // Transaction sender updates his playing stats and money gets banked
    function _buyIn() internal {

        _convertDAItoADAI(msg.sender, ticketSize);

        lastActivityAt[msg.sender] = now;
        lastRound[msg.sender] = getCurrentRoundNumber() + 1;
        balances[msg.sender] += ticketSize;
        totalDeposits += ticketSize;
    }

    //Collect the balance plus interest if ended the game
    function withdraw() public {
        require(!areWeHavingFun(), 'Game is running');
        require(isCleanUpComplete(), 'Complete the cleanUp');
        require(hasPlayerFinishedGame(msg.sender), 'You are not a winner');

        uint256 _amount = balances[msg.sender] + getPlayerShareOfAccruedInterest(msg.sender);
        balances[msg.sender] = 0;
        allocations[msg.sender] = 0;
        totalWithdrawals -= _amount;

        _convertADAItoDAI(msg.sender, _amount);
    }

    // Swap DAI to interest bearing aDAI token
    // How to convert DAI to ADAI
    // Note separation between lending pole CORE (approval target) and lending poo linstance
    // 1. User needs to make approve() against this smart contractt
    // 2. This smart contract has approves Aave lending pool CORE to tranferFrom() DAI from this cotract to core
    // 3. We call deposit() which will trigger transferFrom(), move DAI from this contract and generate aDAI on this contract
    function _convertDAItoADAI(address whose, uint amount) internal {

        ILendingPool lendingPool = ILendingPool(lendingPoolAddressProvider.getLendingPool());

        require(daiToken.allowance(whose, address(this)) >= amount, "You need to have allowance to do transfer DAI on the smart contract");

        // Move DAI from user wallet to this contract
        require(daiToken.transferFrom(whose, address(this), amount) == true, "Transfer failed");

        // https://developers.aave.com/#lendingpool
        // https://github.com/aave/aave-protocol/blob/master/test/atoken-transfer.spec.ts#L39

        // Move DAI form this contract to lending pool
        // See approve() in the constructor
        lendingPool.deposit(address(daiToken), amount, AAVE_REFERRAL_CODE);
    }

    // Swap ADAI back to DAI
    // ADAI is burn and the whose DAI balance is incressed
    // Note: validations should be in place before call this method.
    function _convertADAItoDAI(address whose, uint amount) internal {

        ILendingPool lendingPool = ILendingPool(lendingPoolAddressProvider.getLendingPool());

        //External call
        //Burn tokens and collect DAI
        lendingPool.redeem(amount);

        //External call
        //Send tokens to user account
        daiToken.transfer(whose, amount);
    }

    // Remove allocations for players who failed
    // A state clean up when before the final dividend.
    // Must be manually called for every player
    // https://www.youtube.com/watch?v=GU0d8kpybVg
    function checkForDead(address addr) public {
        require(!areWeHavingFun(), "Game still goes on");
        require(isPlayerAddress(addr), "Was not a player");
        require(cleanedUp[addr] == false, "Player has already been cleaned up");

        if(aliveAllocations == 0) {
            aliveAllocations = totalAllocations;
        }

        // Player failed, no prize for them
        if(!hasPlayerFinishedGame(addr)) {
            aliveAllocations -= allocations[addr];
            allocations[addr] = 0;
        } else {
            finishedPlayerCount++;
        }

        cleanedUpPlayerCount++;
        cleanedUp[addr] = true;

        //If someone is liquidating other player, that player wins more 10 base points
        if(isPlayerAddress(msg.sender) && msg.sender != addr) {
            allocations[msg.sender] += 10;
            totalAllocations += 10;
        }
    }

    // Check for the game master
    function isPatientZero(address addr) public view returns(bool) {
        return addr == patientZero;
    }

    // Cannot come in after incubation perios is over
    function isIncubationPeriodOver() public view returns(bool) {
        return now > startedAt + INCUBATION_PERIOD;
    }

    // Did this player play the game in some point
    // 1. Still playing
    // 2. Was playing / withdraw
    // 3. Was playing / dropped out
    function isPlayerAddress(address addr) public view returns(bool) {
        return isPatientZero(addr) || referrals[addr] != address(0);
    }

    /** The player has started the game and has not dropped out */
    function isPlayerInGame(address addr) public view returns(bool) {
        if(getCurrentRoundNumber() == 0) {
            return balances[addr] > 0;
        } else {
            // Player is on the current or previous round
            return (getCurrentRoundNumber() - lastRound[addr]) <= 1;
        }
    }

    // Zero for the incubation, 12 is when the game ends
    function getCurrentRoundNumber() public view returns(uint) {
        return (now - startedAt) / ROUND_LENGTH;
    }

    function getLastRoundNumber() public pure returns(uint) {
        return GAME_LENGTH / ROUND_LENGTH;
    }

    // When the next round of deposits needs to get in,
    function getNextDepositStarts() public view returns(uint) {
        return startedAt + (getCurrentRoundNumber() * ROUND_LENGTH);
    }

    // How long until the players can still deposito on this round
    function getDepositDeadline() public view returns(uint) {
        return getNextDepositStarts();
    }

    // Is the game going
    function areWeHavingFun() public view returns(bool) {
        return now < startedAt + GAME_LENGTH;
    }

    function hasPlayerFinishedGame(address addr) public view returns(bool) {
        require(isPlayerAddress(addr), "Not a player");
        return lastRound[addr] == getLastRoundNumber();
    }

    // Have we checked all the players if they made it to the finish line
    function isCleanUpComplete() public view returns(bool) {
        return cleanedUpPlayerCount == playerCount;
    }

    // Determine in which state the game is currently,
    function getGameState() public view returns(GameState) {
        if(!isIncubationPeriodOver()) {
            return GameState.Starting;
        } else if(areWeHavingFun()) {
            return GameState.Playing;
        } else if(!isCleanUpComplete()) {
            return GameState.Cleaning;
        } else {
            return GameState.PayingOut;
        }
    }

    // Figure out what is the state of a single player
    function getPlayerState(address addr) public view returns(PlayerState) {

        if(!isPlayerAddress(addr)) {
            return PlayerState.NotPlaying;
        }

        if(!hasPlayerFinishedGame(addr)) {
            return PlayerState.Finished;
        }

        if(!isPlayerInGame(addr)) {
            return PlayerState.DroppedOut;
        }

        return PlayerState.Playing;
    }

    // How much interest the game has collected
    function getTotalAccruedInterest() public view returns(uint) {
        return adaiToken.balanceOf(address(this)) - totalDeposits - totalWithdrawals;
    }

    // How much one player owns from the pot
    // (Does not account for dead players)
    function getPlayerShareOfAccruedInterest(address addr) public view returns(uint) {
        return getTotalAccruedInterest() * totalAllocations / allocations[addr];
    }

    //
    // ERC-20 dummy interface to show how much allocation each person has
    //

    string public name = "Viral Aave";
    string public symbol = "vDAI";
    uint8 public decimals = 18;

    function totalSupply() external view returns (uint256) {
        return getTotalAccruedInterest();
    }

    function balanceOf(address account) external view returns (uint256) {
        return getTotalAccruedInterest() * allocations[account] / totalAllocations;
    }

    function transfer(address, uint256) external returns (bool) {
        return false;
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external returns (bool) {
        return false;
    }
}