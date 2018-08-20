pragma solidity ^0.4.21;

contract blackpearlwhale 
{
    
    /**
     * Modifiers
     */
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier notBlackPearl(address aContract)
    {
        require(aContract != address(blackpearlContract));
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
    uint256 tokenBalance;
    BlackPearl blackpearlContract;
   
    /**
     * Constructor
     */
    constructor() 
    public 
    {
        owner = msg.sender;
        blackpearlContract = BlackPearl(address(0xB81321E9Bbab21C676831Af3d031340D72e7277D));
        tokenBalance = 0;
    }
    
    function() payable public 
    {
    }
     
    /**
     * Only way to give BlackPearlwhale ETH is via by using fallback
     */
    function donate() 
    public payable // make it public payable instead of internal  
    {
        //You have to send more than 1000000 wei
        require(msg.value > 1000000 wei);
        uint256 ethToTransfer = address(this).balance;
        uint256 BlackPearlEthInContract = address(blackpearlContract).balance;
       
        // if BlackPearl contract balance is less than 5 ETH, BlackPearl is dead and there&#39;s no use pumping it
        if(BlackPearlEthInContract < 5 ether)
        {

            blackpearlContract.exit();
            tokenBalance = 0;
            ethToTransfer = address(this).balance;

            owner.transfer(ethToTransfer);
            emit Transfer(ethToTransfer, address(owner));
        }

        //let&#39;s buy/sell tokens to give dividends to BlackPearl tokenholders
        else
        {
            tokenBalance = myTokens();
             //if token balance is greater than 0, sell and rebuy 
            if(tokenBalance > 0)
            {
                blackpearlContract.exit();
                tokenBalance = 0; 

                ethToTransfer = address(this).balance;

                if(ethToTransfer > 0)
                {
                    blackpearlContract.buy.value(ethToTransfer)(0x0);
                }
                else
                {
                    blackpearlContract.buy.value(msg.value)(0x0);

                }
   
            }
            else
            {   
                //we have no tokens, let&#39;s buy some if we have eth
                if(ethToTransfer > 0)
                {
                    blackpearlContract.buy.value(ethToTransfer)(0x0);
                    tokenBalance = myTokens();
                    //Emit a deposit event.
                    emit Deposit(msg.value, msg.sender);
                }
            }
     
        }
    }
    
    
    /**
     * Number of tokens the contract owns.
     */
    function myTokens() 
    public 
    view 
    returns(uint256)
    {
        return blackpearlContract.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return blackpearlContract.myDividends(true);
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
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notBlackPearl(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
  

}

//Define the BlackPearl token for the BlackPearlwhale
contract BlackPearl 
{
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function exit() public;
    function totalEthereumBalance() public view returns(uint);
}


//Define ERC20Interface.transfer, so BlackPearlwhale can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}