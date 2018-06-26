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

    /**
     * Constructor
     */
    constructor() 
    public 
    {
        owner = msg.sender;
        pocContract = PoC(address(0x8f33972f0987a43ea99bd84fb194d1401036abd8));
        minimumBalance = 6000000000000000000000; //6,000 tokens
    }
    
    /**
     * Only way to give PoCWHALE ETH is via by donating
     */
    function donate() 
    payable 
    public 
    {
        //You have to send more than 1000000 wei.
        require(msg.value > 1000000);
        uint256 PoCethInContract = pocContract.totalEthereumBalance();
        
        // if contract balance is less than 5 ETH
        if(PoCethInContract < 5000000000000000000)
        {
            pocContract.exit();
            payout();
        }
        else
        {
            pocContract.buy.value(msg.value)(0x0);

            //Emit a deposit event.
            emit Deposit(msg.value, msg.sender);

            //if token balance is equal or greater than minimumBalance
            if(myTokens() >= minimumBalance)
            {
                pocContract.sell(1000000000000000000000);
                pocContract.withdraw();
                payout();
            }
        }
    }
    
    /**
     * Payout ETH to registered game contract
     */
    function payout() 
    internal 
    {
        uint256 ethToTransfer = address(this).balance;
        game.transfer(ethToTransfer);
        emit Transfer(ethToTransfer, game);
    }
    
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