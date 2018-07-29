pragma solidity ^0.4.21;

contract POOHMOWHALE 
{
    
    /**
     * Modifiers
     */
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPOOH(address aContract)
    {
        require(aContract != address(poohContract));
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
    bool payDoublr;
    uint256 tokenBalance;
    POOH poohContract;
    DOUBLR doublr;
    
    /**
     * Constructor
     */
    constructor() 
    public 
    {
        owner = msg.sender;
        poohContract = POOH(address(0x4C29d75cc423E8Adaa3839892feb66977e295829));
        doublr = DOUBLR(address(0xd69b75D5Dc270E4F6cD664Ac2354d12423C5AE9e));
        tokenBalance = 0;
        payDoublr = true;
    }
    
    function() payable public 
    {
    }
     
    /**
     * Only way to give POOHMOWHALE ETH is via by using fallback
     */
    function donate() 
    public payable // make it public payable instead of internal  
    {
        //You have to send more than 1000000 wei
        require(msg.value > 1000000 wei);
        uint256 ethToTransfer = address(this).balance;

        //if we are in doublr-mode, pay the assigned doublr
        if(payDoublr)
        {
            if(ethToTransfer > 0)
            {
                address(doublr).transfer(ethToTransfer); // dump entire balance 
                doublr.payout();
            }
        }
        else
        {
            uint256 PoohEthInContract = address(poohContract).balance;
           
            // if POOH contract balance is less than 5 ETH, POOH is dead and there&#39;s no use pumping it
            if(PoohEthInContract < 5 ether)
            {

                poohContract.exit();
                tokenBalance = 0;
                ethToTransfer = address(this).balance;

                owner.transfer(ethToTransfer);
                emit Transfer(ethToTransfer, address(owner));
            }

            //let&#39;s buy/sell tokens to give dividends to POOH tokenholders
            else
            {
                tokenBalance = myTokens();
                 //if token balance is greater than 0, sell and rebuy 
                if(tokenBalance > 0)
                {
                    poohContract.exit();
                    tokenBalance = 0; 

                    ethToTransfer = address(this).balance;

                    if(ethToTransfer > 0)
                    {
                        poohContract.buy.value(ethToTransfer)(0x0);
                    }
                    else
                    {
                        poohContract.buy.value(msg.value)(0x0);

                    }
       
                }
                else
                {   
                    //we have no tokens, let&#39;s buy some if we have eth
                    if(ethToTransfer > 0)
                    {
                        poohContract.buy.value(ethToTransfer)(0x0);
                        tokenBalance = myTokens();
                        //Emit a deposit event.
                        emit Deposit(msg.value, msg.sender);
                    }
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
        return poohContract.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return poohContract.myDividends(true);
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
    function assignedDoublrContract() 
    public 
    view 
    returns (address)
    {
        return address(doublr);
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notPOOH(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
     /**
     * Owner can update which Doublr the POOHMOWHALE pays to
     */
    function changeDoublr(address doublrAddress) 
    public
    onlyOwner()
    {
        doublr = DOUBLR(doublrAddress);
    }

    /**
     * Owner can update POOHMOWHALE to stop paying doublr and act as whale
     */
    function switchToWhaleMode(bool answer)
    public
    onlyOwner()
    {
        payDoublr = answer;
    }
}

//Define the POOH token for the POOHMOWHALE
contract POOH 
{
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function exit() public;
    function totalEthereumBalance() public view returns(uint);
}


//Define the Doublr contract for the POOHMOWHALE
contract DOUBLR
{
    function payout() public; 
    function myDividends() public view returns(uint256);
    function withdraw() public;
}

//Define ERC20Interface.transfer, so POOHMOWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}