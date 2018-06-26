pragma solidity ^0.4.21;






contract PoCWHALE 
{
    
    /**
     * Modifiers
     */
     
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPoC(address aContract)
    {
        require(aContract != address(pocContract));
        _;
    }
   
    /**
     * Events
     */
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Sell();
    event Payout(uint256 amount, address creditor);
    event Transfer(uint256 amount, address paidTo);

   /**
     * Global Variables
     */
    address owner;
    address game;
    //What type of tokens whale will own/buy
    PoC pocContract;
    uint256 minimumBalance; 
    uint256 maximumBalance;
    uint256 tokenBalance;

    /**
     * Constructor
     */
    constructor() 
    public 
    {
        owner = msg.sender;
        pocContract = PoC(address(0x8f33972f0987a43ea99bd84fb194d1401036abd8));
        minimumBalance = 1000000000000000000000; //1,000 tokens
        maximumBalance = 2000000000000000000000; //2,000 tokens
        tokenBalance = 0;
    }
    
     function() payable public { }
     
    /**
     * Only way to give PoCWHALE ETH is via by donating
     */
    function donate() 
    payable 
    public 
    {
        //You have to send more than 1000000 wei.
        require(msg.value > 1000000);
        uint256 PoCethInContract = address(pocContract).balance;
        uint256 ethToTransfer = address(this).balance;
        
        // if contract balance is less than 5 ETH
        if(PoCethInContract < 5000000000000000000)
        {
            pocContract.exit();
            tokenBalance = 0;
            
            game.transfer(ethToTransfer);
            emit Transfer(ethToTransfer, address(game));
        }
        else
        {
             //if token balance is greater than minimumBalance sell the difference
            if(tokenBalance > maximumBalance)
            {
                pocContract.sell(tokenBalance - minimumBalance);
                tokenBalance = minimumBalance;
                pocContract.withdraw();
                emit Sell();
               
                game.transfer(ethToTransfer);
                emit Transfer(ethToTransfer, game);
   
            }
            else
            {
                pocContract.buy.value(msg.value)(0x0);
                tokenBalance = pocContract.myTokens();
                //Emit a deposit event.
                emit Deposit(msg.value, msg.sender);
            }
           
        }
    }
    
    // Test function that will be removed after testing
    function testSell() 
    onlyOwner()
    public
    returns (uint256)
    {
        
        pocContract.sell(50000000000000000000);
        tokenBalance -= 50000000000000000000;
       // testBalance = pocContract.myTokens();
        return tokenBalance;
    }
    
    // Test function that will be removed after testing
    function UpdateMinBalance(uint256 minimum)
    onlyOwner()
    public
    {
        minimumBalance = minimum;
    }
    
     // Test function that will be removed after testing
    function UpdateMaxBalance(uint256 maximum)
    onlyOwner()
    public
    {
        maximumBalance = maximum;
    }
    
    function TestWithdraw()
    onlyOwner()
    public
    {
         pocContract.withdraw.gas(100000)();
    }
    
    //Test function that will be removed after testing
    function getTokenBalance()
    public
    view
    returns(uint256)
    {
        return tokenBalance;
    }
    /**
     * Payout ETH to registered game contract
     */
    // function payout() 
    // internal 
    // {
        
    // }
    /**
     * Number of tokens the contract owns.
     */
    function myTokens() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myDividends(true);
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
     * Address of game contract that ETH gets sent to
     */
    function assignedGameContract() 
    public 
    view 
    returns (address)
    {
        return game;
    }
    
     /**
     * Minimum limit for Whale to have in PoC tokens
     */
    function getMinimumLimit() 
    public 
    view 
    returns (uint256)
    {
        return minimumBalance;
    }
    
     /**
     * Maximum limit for Whale to have in PoC tokens
     */
    function getMaximumLimit() 
    public 
    view 
    returns (uint256)
    {
        return maximumBalance;
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notPoC(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
     /**
     * Owner can change which PoC game the PoCWHALE plays with
     */
    function changeGameAddress(address gameAddress) 
    public
    onlyOwner()
    {
        game = gameAddress;
    }
}

//Define the PoC token for the PoCWHALE
contract PoC 
{
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function exit() public;
    function totalEthereumBalance() public view returns(uint);
}

//Define ERC20Interface.transfer, so PoCWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}