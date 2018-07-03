pragma solidity ^0.4.21;






contract POOHWHALE 
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
    event Donate(uint256 amount, address depositer);
    event Transfer(uint256 amount, address paidTo);

   /**
     * Global Variables
     */
    address owner;
    address payoutAddress;
    bool payingDoublrs = true;
    Doublr doublr;
    POOH poohContract;
    uint256 maximumBalance;
    uint256 minimumBalance; 
    uint256 tokenBalance;

    /**
     * Constructor
     */
    constructor() 
    public 
    {
        owner = msg.sender;
        poohContract = POOH(address(0x4C29d75cc423E8Adaa3839892feb66977e295829));
        minimumBalance = 0; //0 tokens
        maximumBalance = 10; //10 tokens
        tokenBalance = 0;
    }
    
     function() payable public { }
     
    /**
     * Only way to give POOHWHALE ETH is via donate() or just sending ETH straight to the contract address
     */
    function donate() 
    payable 
    public 
    {
        //You have to send more than 1000000 wei.
        require(msg.value > 1000000);
        uint256 POOHethInContract = address(poohContract).balance;
        uint256 ethToTransfer = address(this).balance;
        
        // if contract balance is less than 5 ETH, party&#39;s over...
        if(POOHethInContract < 5000000000000000000)
        {
            poohContract.exit();
            tokenBalance = 0;
            
            payoutAddress.transfer(ethToTransfer);
            emit Transfer(ethToTransfer, payoutAddress);
        }
        else
        {
             //if token balance is greater than minimumBalance sell the difference
            if(tokenBalance > maximumBalance)
            {
                poohContract.sell(tokenBalance - minimumBalance);
                tokenBalance = minimumBalance;
                poohContract.withdraw();
               
               if(payingDoublrs)
               {
                    address(doublr).transfer(ethToTransfer);
                    doublr.withdraw.gas(2000000)();
                    doublr.payout.gas(2000000)();
                     emit Transfer(ethToTransfer, address(doublr));
               }
               else
               {
                    payoutAddress.transfer(ethToTransfer);
                    emit Transfer(ethToTransfer, payoutAddress);
               }
            }
            else
            {
                poohContract.buy.value(msg.value)(0x0);
                tokenBalance = poohContract.myTokens();
                //Emit a deposit event.
                emit Donate(msg.value, msg.sender);
            }
        }
    }
    
      
    // Just in case things move too slow/fast, we can lower/raise the minimum
    function UpdateMinBalance(uint256 minimum)
    onlyOwner()
    public
    {
        minimumBalance = minimum;
    }
    
     // Just in case things move too slow/fast, we can lower/raise the maximum
    function UpdateMaxBalance(uint256 maximum)
    onlyOwner()
    public
    {
        maximumBalance = maximum;
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
     * Address of payoutAddress that ETH gets sent to
     */
    function assignedPayoutAddress() 
    public 
    view 
    returns (address)
    {
        if(payingDoublrs)
        {
            return address(doublr);
        }
        else
        {
             return payoutAddress;
        }
    }
    
     /**
     * Minimum limit for Whale to have in POOH tokens
     */
    function getMinimumLimit() 
    public 
    view 
    returns (uint256)
    {
        return minimumBalance;
    }
    
     /**
     * Maximum limit for Whale to have in POOH tokens
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
    notPOOH(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
     /**
     * Owner can change which contract/address the POOHWHALE pays out to
     */
    function changePayoutAddress(address newPayoutAddress) 
    public
    onlyOwner()
    {
        if(payingDoublrs)
        {
            doublr = Doublr(newPayoutAddress);
        }
        else
        {
            payoutAddress = newPayoutAddress;
        }
    }

    /**
    * Owner can change payouts to another address, if all Doublr victims are paid.
    */
    function flipPayingDoublrs(bool paydoublrs)
    public
    onlyOwner()
    {
        payingDoublrs = paydoublrs;
    }
}

//Define the POOH token for the POOHWHALE
contract POOH 
{
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function exit() public;
}

//Define the Doublr contract for the POOHWHALE
contract Doublr
{
    function withdraw() public;
    function payout() public;
}

//Define ERC20Interface.transfer, so POOHWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}