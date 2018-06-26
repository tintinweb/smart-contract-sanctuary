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
    event Bet(uint256 amount, address depositer);
    event Payout(uint256 amount, address paidTo);
    event PayWhale(uint256 amount, address paidTo);

    /**
     * Global Variables
     */
    address owner;
    PoCWHALE whale;
    //What type of tokens whale will own/buy
    mapping(address => uint256) timestamps;
    mapping(address => uint256) wagers;
    bool openToPublic;
    uint256 totalDonated;

    /**
     * Constructor
     */
    constructor(address whaleAddress) 
    onlyRealPeople()
    public 
    {
        openToPublic = false;
        owner = msg.sender;
        whale = PoCWHALE(whaleAddress);
        totalDonated = 0;
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
    
    function() 
    public 
    payable { }

    /**
     * Wager your bet
     */
    function wager()
    isOpenToPublic()
    onlyRealPeople() 
    payable
    public 
    {
        //You have to exactly 0.001 ETH.
        require(msg.value == 1000000000000000);

        //log the wager and timestamp(block number)
        timestamps[msg.sender] = block.number;
        wagers[msg.sender] = msg.value;
        emit Bet(msg.value, msg.sender);
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
        timestamps[msg.sender] = 0;

        uint256 winningNumber = uint256(keccak256(blockhash(blockNumber),  msg.sender))%300 +1;

        if(winningNumber > 100 && winningNumber < 200)
        {
            payout(msg.sender);
        }
        else 
        {
            //player loses
            donateToWhale(500000000000000);
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
        emit Payout(ethToTransfer, winner);
    }

    /**
     * Payout ETH to whale
     */
    function donateToWhale(uint256 amount) 
    internal 
    {
        
        
        whale.donate.value(amount)();
        totalDonated += amount;
        emit PayWhale(amount, whale);
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

//Define the PoC token for the PoCWHALE
contract PoCWHALE 
{
    function donate() payable public; 
}

//Define ERC20Interface.transfer, so PoCWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}