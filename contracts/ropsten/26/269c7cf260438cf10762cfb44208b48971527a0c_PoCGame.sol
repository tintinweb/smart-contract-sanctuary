pragma solidity ^0.4.21;






contract PoCGame
{
    
    /**
     * Modifiers
     */
     
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
   modifier isOpenToPublic()
    {
        require(openToPublic);
        _;
    }

    modifier onlyRealPeople()
    {
          require (msg.sender == tx.origin);
        _;
    }

    modifier  onlyPlayers()
    { 
        require (wagers[msg.sender] > 0); 
        _; 
    }
    
   
    /**
     * Events
     */
    event Wager(uint256 amount, address depositer);
    event Win(uint256 amount, address paidTo);
    event Lose(uint256 amount, address loser);
    event Donate(uint256 amount, address paidTo, address donator);
    event DifficultyChanged(uint256 currentDifficulty);
    event BetLimitChanged(uint256 currentBetLimit);

    /**
     * Global Variables
     */
    address private whale;
    uint256 betLimit;
    uint difficulty;
    uint private randomSeed;
    address owner;
    mapping(address => uint256) timestamps;
    mapping(address => uint256) wagers;
    bool openToPublic;
    uint256 totalDonated;

    /**
     * Constructor
     */
    constructor(address whaleAddress, uint256 wagerLimit) 
    onlyRealPeople()
    public 
    {
        openToPublic = false;
        owner = msg.sender;
        whale = whaleAddress;
        totalDonated = 0;
        betLimit = wagerLimit;
        
    }


    /**
     * Let the public play
     */
    function OpenToThePublic() 
    onlyOwner()
    public
    {
        openToPublic = true;
    }
    
    /**
     * Adjust the bet amounts
     */
    function AdjustBetAmounts(uint256 amount) 
    onlyOwner()
    public
    {
        betLimit = amount;
        
        emit BetLimitChanged(betLimit);
    }
    
     /**
     * Adjust the difficulty
     */
    function AdjustDifficulty(uint256 amount) 
    onlyOwner()
    public
    {
        difficulty = amount;
        
        emit DifficultyChanged(difficulty);
    }
    
    
    function() public payable { }

    /**
     * Wager your bet
     */
    function wager()
    isOpenToPublic()
    onlyRealPeople() 
    payable
    public 
    {
        //You have to send exactly 0.01 ETH.
        require(msg.value == betLimit);

        //log the wager and timestamp(block number)
        timestamps[msg.sender] = block.number;
        wagers[msg.sender] = msg.value;
        emit Wager(msg.value, msg.sender);
    }
    
    /**
     * method to determine winners and losers
     */
    function play()
    isOpenToPublic()
    onlyRealPeople()
    onlyPlayers()
    public
    {
        uint256 blockNumber = timestamps[msg.sender];
        if(blockNumber < block.number)
        {
            timestamps[msg.sender] = 0;
            wagers[msg.sender] = 0;
    
            uint256 winningNumber = uint256(keccak256(abi.encodePacked(blockhash(blockNumber),  msg.sender)))%difficulty +1;
    
            if(winningNumber == difficulty / 2)
            {
                payout(msg.sender);
            }
            else 
            {
                //player loses
                loseWager(betLimit / 2);
            }    
        }
        else
        {
            revert();
        }
    }

    /**
     * For those that just want to donate to the whale
     */
    function donate()
    isOpenToPublic()
    public 
    payable
    {
        donateToWhale(msg.value);
    }

    /**
     * Payout ETH to winner
     */
    function payout(address winner) 
    internal 
    {
        uint256 ethToTransfer = address(this).balance / 2;
        
        winner.transfer(ethToTransfer);
        emit Win(ethToTransfer, winner);
    }

    /**
     * Payout ETH to whale
     */
    function donateToWhale(uint256 amount) 
    internal 
    {
        whale.call.value(amount)(bytes4(keccak256("donate()")));
        totalDonated += amount;
        emit Donate(amount, whale, msg.sender);
    }

    /**
     * Payout ETH to whale when player loses
     */
    function loseWager(uint256 amount) 
    internal 
    {
        whale.call.value(amount)(bytes4(keccak256("donate()")));
        totalDonated += amount;
        emit Lose(amount, msg.sender);
    }
    

    /**
     * ETH balance of contract
     */
    function ethBalance() 
    public 
    view 
    returns (uint256)
    {
        return address(this).balance;
    }
    
    
    /**
     * current difficulty of the game
     */
    function currentDifficulty() 
    public 
    view 
    returns (uint256)
    {
        return difficulty;
    }
    
    
    /**
     * current bet amount for the game
     */
    function currentBetLimit() 
    public 
    view 
    returns (uint256)
    {
        return betLimit;
    }
    
    function hasPlayerWagered(address player)
    public 
    view 
    returns (bool)
    {
        if(wagers[player] > 0)
        {
            return true;
        }
        else
        {
            return false;
        }
        
    }

    /**
     * For the UI to properly display the winner&#39;s pot
     */
    function winnersPot() 
    public 
    view 
    returns (uint256)
    {
        return address(this).balance / 2;
    }

    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
}

//Define ERC20Interface.transfer, so PoCWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}