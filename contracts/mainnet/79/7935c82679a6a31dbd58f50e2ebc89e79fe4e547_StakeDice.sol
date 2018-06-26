pragma solidity 0.4.24;

// Minimal required STAKE token interface
contract StakeToken
{
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract StakeDiceGame
{
    // Prevent people from losing Ether by accidentally sending it to this contract.
    function () payable external
    {
        revert();
    }
    
    ///////////////////////////////
    /////// GAME PARAMETERS
    
    StakeDice public stakeDice;
    
    // Number between 0 and 10 000. Examples:
    // 700 indicates 7% chance.
    // 5000 indicates 50% chance.
    // 8000 indicates 80% chance.
    uint256 public winningChance;
    
    // Examples of multiplierOnWin() return values:
    // 10 000 indicates 1x returned.
    // 13 000 indicated 1.3x returned
    // 200 000 indicates 20x returned
    function multiplierOnWin() public view returns (uint256)
    {
        uint256 beforeHouseEdge = 10000;
        uint256 afterHouseEdge = beforeHouseEdge - stakeDice.houseEdge();
        return afterHouseEdge * 10000 / winningChance;
    }
    
    function maximumBet() public view returns (uint256)
    {
        uint256 availableTokens = stakeDice.stakeTokenContract().balanceOf(address(stakeDice));
        return availableTokens * 10000 / multiplierOnWin() / 5;
    }
    

    
    ///////////////////////////////
    /////// OWNER FUNCTIONS
    
    // Constructor function
    // Provide a number between 0 and 10 000 to indicate the winning chance and house edge.
    constructor(StakeDice _stakeDice, uint256 _winningChance) public
    {
        // Ensure the parameters are sane
        require(_winningChance > 0);
        require(_winningChance < 10000);
        require(_stakeDice != address(0x0));
        require(msg.sender == address(_stakeDice));
        
        stakeDice = _stakeDice;
        winningChance = _winningChance;
    }
    
    // Allow the owner to change the winning chance
    function setWinningChance(uint256 _newWinningChance) external
    {
        require(msg.sender == stakeDice.owner());
        require(_newWinningChance > 0);
        require(_newWinningChance < 10000);
        winningChance = _newWinningChance;
    }
    
    // Allow the owner to withdraw STAKE tokens that
    // may have been accidentally sent here.
    function withdrawStakeTokens(uint256 _amount, address _to) external
    {
        require(msg.sender == stakeDice.owner());
        require(_to != address(0x0));
        stakeDice.stakeTokenContract().transfer(_to, _amount);
    }
}


contract StakeDice
{
    ///////////////////////////////
    /////// GAME PARAMETERS
    
    StakeToken public stakeTokenContract;
    mapping(address => bool) public addressIsStakeDiceGameContract;
    StakeDiceGame[] public allGames;
    uint256 public houseEdge;
    uint256 public minimumBet;
    
    //////////////////////////////
    /////// PLAYER STATISTICS
    
    address[] public allPlayers;
    mapping(address => uint256) public playersToTotalBets;
    mapping(address => uint256[]) public playersToBetIndices;
    function playerAmountOfBets(address _player) external view returns (uint256)
    {
        return playersToBetIndices[_player].length;
    }
    
    function totalUniquePlayers() external view returns (uint256)
    {
        return allPlayers.length;
    }
    
    //////////////////////////////
    /////// GAME FUNCTIONALITY
    
    // Events
    event BetPlaced(address indexed gambler, uint256 betIndex);
    event BetWon(address indexed gambler, uint256 betIndex);
    event BetLost(address indexed gambler, uint256 betIndex);
    event BetCanceled(address indexed gambler, uint256 betIndex);
    
    enum BetStatus
    {
        NON_EXISTANT,
        IN_PROGRESS,
        WON,
        LOST,
        CANCELED
    }
    
    struct Bet
    {
        address gambler;
        uint256 winningChance;
        uint256 betAmount;
        uint256 potentialRevenue;
        uint256 roll;
        BetStatus status;
    }
    
    Bet[] public bets;
    uint public betsLength = 0;
    mapping(bytes32 => uint256) public oraclizeQueryIdsToBetIndices;
    
    function betPlaced(address gameContract, uint256 _amount) external
    {
        // Only StakeDiceGame contracts are allowed to call this function
        require(addressIsStakeDiceGameContract[gameContract] == true);
        
         // Make sure the bet is within the current limits
        require(_amount >= minimumBet);
        require(_amount <= StakeDiceGame(gameContract).maximumBet());
        
        // Tranfer the STAKE tokens from the user&#39;s account to the StakeDice contract
        stakeTokenContract.transferFrom(msg.sender, this, _amount);
        
        
        // Calculate how much the gambler might win
        uint256 potentialRevenue = StakeDiceGame(gameContract).multiplierOnWin() * _amount / 10000;
        
        // Store the bet
        emit BetPlaced(msg.sender, bets.length);
        playersToBetIndices[msg.sender].push(bets.length);
        bets.push(Bet({gambler: msg.sender, winningChance: StakeDiceGame(gameContract).winningChance(), betAmount: _amount, potentialRevenue: potentialRevenue, roll: 0, status: BetStatus.IN_PROGRESS}));
        betsLength +=1;
        // Update statistics
        if (playersToTotalBets[msg.sender] == 0)
        {
            allPlayers.push(msg.sender);
        }
        playersToTotalBets[msg.sender] += _amount;
        //uint _result = 1; //the random number
        uint256 betIndex = betsLength;
        Bet storage bet = bets[betIndex];
        require(bet.status == BetStatus.IN_PROGRESS);
        // Now that we have generated a random number, let&#39;s use it..
        uint randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%100);
       
        // Store the roll in the blockchain permanently
        bet.roll = randomNumber;
        
        // If the random number is smaller than the winningChance, the gambler won!
        if (randomNumber < bet.winningChance/100)
        {
            // If we somehow don&#39;t have enough tokens to payout their winnings,
            // cancel the bet and refund the gambler automatically
            if (stakeTokenContract.balanceOf(this) < bet.potentialRevenue)
            {
                _cancelBet(betIndex);
            }
            
            // Otherwise, (if we do have enough tokens)
            else
            {
                // The gambler won!
                bet.status = BetStatus.WON;
            
                // Send them their winnings
                stakeTokenContract.transfer(bet.gambler, bet.potentialRevenue);
                
                // Trigger BetWon event
                emit BetWon(bet.gambler, betIndex);
            }
        }
        else
        {
            // The gambler lost!
            bet.status = BetStatus.LOST;
            
            // Send them the smallest possible token unit as consolation prize
            // and as notification that their bet has lost.
            stakeTokenContract.transfer(bet.gambler, 1); // Send 0.00000001 STAKE
            
            // Trigger BetLost event
            emit BetLost(bet.gambler, betIndex);
        }
    }
    
    function _cancelBet(uint256 _betIndex) private
    {
        // Only bets that are in progress can be canceled
        require(bets[_betIndex].status == BetStatus.IN_PROGRESS);
        
        // Store the fact that the bet has been canceled
        bets[_betIndex].status = BetStatus.CANCELED;
        
        // Refund the bet amount to the gambler
        stakeTokenContract.transfer(bets[_betIndex].gambler, bets[_betIndex].betAmount);
        
        // Trigger BetCanceled event
        emit BetCanceled(bets[_betIndex].gambler, _betIndex);
        
        // Subtract the bet from their total
        playersToTotalBets[bets[_betIndex].gambler] -= bets[_betIndex].betAmount;
    }
    
    function amountOfGames() external view returns (uint256)
    {
        return allGames.length;
    }
    
    function amountOfBets() external view returns (uint256)
    {
        return bets.length-1;
    }
    
    ///////////////////////////////
    /////// OWNER FUNCTIONS
    
    address public owner;
    
    // Constructor function
    constructor(StakeToken _stakeTokenContract, uint256 _houseEdge, uint256 _minimumBet) public
    {
        // Bet indices start at 1 because the values of the
        // oraclizeQueryIdsToBetIndices mapping are by default 0.
        bets.length = 1;
        
        // Whoever deployed the contract is made owner
        owner = msg.sender;
        
        // Ensure that the arguments are sane
        require(_houseEdge < 10000);
        require(_stakeTokenContract != address(0x0));
        
        // Store the initializing arguments
        stakeTokenContract = _stakeTokenContract;
        houseEdge = _houseEdge;
        minimumBet = _minimumBet;
    }
    
    // Allow the owner to easily create the default dice games
    function createDefaultGames() public
    {
        require(allGames.length == 0);
        
        addNewStakeDiceGame(500); // 5% chance
        addNewStakeDiceGame(1000); // 10% chance
        addNewStakeDiceGame(1500); // 15% chance
        addNewStakeDiceGame(2000); // 20% chance
        addNewStakeDiceGame(2500); // 25% chance
        addNewStakeDiceGame(3000); // 30% chance
        addNewStakeDiceGame(3500); // 35% chance
        addNewStakeDiceGame(4000); // 40% chance
        addNewStakeDiceGame(4500); // 45% chance
        addNewStakeDiceGame(5000); // 50% chance
        addNewStakeDiceGame(5500); // 55% chance
        addNewStakeDiceGame(6000); // 60% chance
        addNewStakeDiceGame(6500); // 65% chance
        addNewStakeDiceGame(7000); // 70% chance
        addNewStakeDiceGame(7500); // 75% chance
        addNewStakeDiceGame(8000); // 80% chance
        addNewStakeDiceGame(8500); // 85% chance
        addNewStakeDiceGame(9000); // 90% chance
        addNewStakeDiceGame(9500); // 95% chance
    }
    
    // Allow the owner to cancel a bet when it&#39;s in progress.
    // This will probably never be needed, but it might some day be needed
    // to refund people if oraclize is not responding.
    function cancelBet(uint256 _betIndex) public
    {
        require(msg.sender == owner);
        
        _cancelBet(_betIndex);
    }
    
    // Allow the owner to add new games with different winning chances
    function addNewStakeDiceGame(uint256 _winningChance) public
    {
        require(msg.sender == owner);
        
        // Deploy a new StakeDiceGame contract
        StakeDiceGame newGame = new StakeDiceGame(this, _winningChance);
        
        // Store the fact that this new address is a StakeDiceGame contract
        addressIsStakeDiceGameContract[newGame] = true;
        allGames.push(newGame);
    }
    
    // Allow the owner to change the house edge
    function setHouseEdge(uint256 _newHouseEdge) external
    {
        require(msg.sender == owner);
        require(_newHouseEdge < 10000);
        houseEdge = _newHouseEdge;
    }
    
    // Allow the owner to change the minimum bet
    // This also allows the owner to temporarily disable the game by setting the
    // minimum bet to an impossibly high number.
    function setMinimumBet(uint256 _newMinimumBet) external
    {
        require(msg.sender == owner);
        minimumBet = _newMinimumBet;
    }
    
    // Allow the owner to deposit and withdraw ether
    // (this contract needs to pay oraclize fees)
    function depositEther() payable external
    {
        require(msg.sender == owner);
    }
    function withdrawEther(uint256 _amount) payable external
    {
        require(msg.sender == owner);
        owner.transfer(_amount);
    }
    
    // Allow the owner to make another address the owner
    function transferOwnership(address _newOwner) external 
    {
        require(msg.sender == owner);
        require(_newOwner != 0x0);
        owner = _newOwner;
    }
    
    // Allow the owner to withdraw STAKE tokens
    function withdrawStakeTokens(uint256 _amount) external
    {
        require(msg.sender == owner);
        stakeTokenContract.transfer(owner, _amount);
    }
    
    // Prevent people from losing Ether by accidentally sending it to this contract.
    function () payable external
    {
        revert();
    }
    
}