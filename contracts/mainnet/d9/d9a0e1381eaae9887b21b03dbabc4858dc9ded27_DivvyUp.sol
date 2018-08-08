pragma solidity 0.4.23;

/*
*DivvyUp for Goo
*
* ====================================================================*
*&#39;||&#39;&#39;|.    ||                                    &#39;||&#39;  &#39;|&#39;         
* ||   ||  ...  .... ... .... ... .... ...      ,  ||    |  ... ... 
* ||    ||  ||   &#39;|.  |   &#39;|.  |   &#39;|.  |  <>  /   ||    |   ||&#39;  ||
* ||    ||  ||    &#39;|.|     &#39;|.|     &#39;|.|      /    ||    |   ||    |
*.||...|&#39;  .||.    &#39;|       &#39;|       &#39;|      /      &#39;|..&#39;    ||...&#39; 
*                                 .. |      /                ||     
*                                  &#39;&#39;      /  <>            &#39;&#39;&#39;&#39;    
* =====================================================================*
*
* A wealth redistribution smart contract cleverly disguised as a ERC20 token.
* Complete with a factory for making new verticals, and a fair launch contract
* to ensure a fair launch.
*
*/


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DivvyUpFactoryInterface {
    function create(
        bytes32 name, // Name of the DivvyUp
        bytes32 symbol,  // ERC20 Symbol fo the DivvyUp
        uint8 dividendDivisor, // Amount to divide incoming counter by as fees for dividens. Example: 3 for 33%, 10 for 10%, 100 for 1%
        uint8 decimals, // Number of decimals the token has. Example: 18
        uint256 initialPrice, // Starting price per token. Example: 0.0000001 ether
        uint256 incrementPrice, // How much to increment the price by. Example: 0.00000001 ether
        uint256 magnitude, //magnitude to multiply the fees by before distribution. Example: 2**64
        address counter // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
     )
        public 
        returns(address);
}


contract DivvyUpFactory is Owned {

    event Create(
        bytes32 name,
        bytes32 symbol,
        uint8 dividendDivisor,
        uint8 decimals,
        uint256 initialPrice,
        uint256 incrementPrice,
        uint256 magnitude,
        address creator
    );

  
    DivvyUp[] public registry;

    function create(
        bytes32 name, // Name of the DivvyUp
        bytes32 symbol,  // ERC20 Symbol fo the DivvyUp
        uint8 dividendDivisor, // Amount to divide incoming counter by as fees for dividens. Example: 3 for 33%, 10 for 10%, 100 for 1%
        uint8 decimals, // Number of decimals the token has. Example: 18
        uint256 initialPrice, // Starting price per token. Example: 0.0000001 ether
        uint256 incrementPrice, // How much to increment the price by. Example: 0.00000001 ether
        uint256 magnitude, //magnitude to multiply the fees by before distribution. Example: 2**64
        address counter // The counter currency to accept. Example: 0x0 for ETH, otherwise the ERC20 token address.
     )
        public 
        returns(address)
    {
        DivvyUp divvyUp = new DivvyUp(name, symbol, dividendDivisor, decimals, initialPrice, incrementPrice, magnitude, counter);
        divvyUp.changeOwner(msg.sender);
        registry.push(divvyUp);
        emit Create(name, symbol, dividendDivisor, decimals, initialPrice, incrementPrice, magnitude, msg.sender);
        return divvyUp;
    }

    function die() onlyOwner public {
        selfdestruct(msg.sender);
    }

    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract DivvyUpInterface{
    function purchaseTokens()
        public
        payable
        returns(uint256);

    function purchaseTokensERC20(uint256 amount)
        public
        returns(uint256);
}

contract DivvyUp is ERC20Interface, Owned, DivvyUpInterface {
    using SafeMath for uint256;
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyDividendHolders() {
        require(dividendDivisor > 0 && myDividends() > 0);
        _;
    }

    modifier erc20Destination(){
        require(counter != 0x0);
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Purchase(
        address indexed customerAddress,
        uint256 incomingCounter,
        uint256 tokensMinted
    );
    
    event Sell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 counterEarned
    );
    
    event Reinvestment(
        address indexed customerAddress,
        uint256 counterReinvested,
        uint256 tokensMinted
    );
    
    event Withdraw(
        address indexed customerAddress,
        uint256 counterWithdrawn
    ); 
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    bytes32 public name;
    bytes32 public symbol;
    uint8  public dividendDivisor;
    uint8 public decimals;// = 18;
    uint256 public tokenPriceInitial;// = 0.0000001 ether;
    uint256 public tokenPriceIncremental;// = 0.00000001 ether;
    uint256 public magnitude;// = 2**64;
    address counter;

   /*================================
    =            DATASETS            =
    ================================*/
    // amount of tokens for each address
    mapping(address => uint256) internal tokenBalanceLedger;
    // amount of eth withdrawn
    mapping(address => int256) internal payoutsTo;
    // amount of tokens allowed to someone else 
    mapping(address => mapping(address => uint)) allowed;
    // the actual amount of tokens
    uint256 internal tokenSupply = 0;
    // the amount of dividends per token
    uint256 internal profitPerShare;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    function DivvyUp(bytes32 aName, bytes32 aSymbol, uint8 aDividendDivisor, uint8 aDecimals, uint256 aTokenPriceInitial, uint256 aTokenPriceIncremental, uint256 aMagnitude, address aCounter) 
    public {
        require(aDividendDivisor < 100);
        name = aName;
        symbol = aSymbol;
        dividendDivisor = aDividendDivisor;
        decimals = aDecimals;
        tokenPriceInitial = aTokenPriceInitial;
        tokenPriceIncremental = aTokenPriceIncremental;
        magnitude = aMagnitude;
        counter = aCounter;    
    }
    
    /**
     * Allows the owner to change the name of the contract
     */
    function changeName(bytes32 newName) onlyOwner() public {
        name = newName;
        
    }
    
    /**
     * Allows the owner to change the symbol of the contract
     */
    function changeSymbol(bytes32 newSymbol) onlyOwner() public {
        symbol = newSymbol;
    }
    
    /**
     * Converts all incoming counter to tokens for the caller
     */
    function purchaseTokens()
        public
        payable
        returns(uint256)
    {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        return purchaseTokens(msg.value);
    }
    

    /**
     * Converts all incoming counter to tokens for the caller
     */
    function purchaseTokensERC20(uint256 amount)
        public
        erc20Destination
        returns(uint256)
    {
        require(ERC20Interface(counter).transferFrom(msg.sender, this, amount));
        return purchaseTokens(amount);
    }


        /**
     * Fallback function to handle counter that was send straight to the contract.
     * Causes tokens to be purchased.
     */
    function()
        payable
        public
    {
        if(msg.value > 0){
            require(counter == 0x0);
        }
        purchaseTokens(msg.value);
    }
    
     
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvestDividends()
        onlyDividendHolders()
        public
        returns (uint256)
    {
        // fetch dividends
        uint256 dividends = myDividends(); 
       
        // pay out the dividends virtually
        address customerAddress = msg.sender;
        payoutsTo[customerAddress] += (int256) (dividends * magnitude);
        
        // dispatch a buy order with the virtualized "withdrawn dividends" if we have dividends
        uint256 tokens = purchaseTokens(dividends);
        
        // fire event
        emit Reinvestment(customerAddress, dividends, tokens);
        
        return tokens;
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        // get token count for caller & sell them all
        address customerAddress = msg.sender;
        uint256 tokens = tokenBalanceLedger[customerAddress];
        if(tokens > 0) {
            sell(tokens);
        }
        // lambo delivery service
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyDividendHolders()
        public
    {
        // setup data
        address customerAddress = msg.sender;
        uint256 dividends = myDividends(); 

        // update dividend tracker
        payoutsTo[customerAddress] += (int256) (dividends * magnitude);
                
        // fire event
        emit Withdraw(customerAddress, dividends);
    }
    
    /**
     * Liquifies tokens to counter.
     */
    function sell(uint256 amountOfTokens)
        onlyTokenHolders()
        public
    {
        require(amountOfTokens > 0);
        // setup data
        address customerAddress = msg.sender;
        // russian hackers BTFO
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
        uint256 tokens = amountOfTokens;
        uint256 counterAmount = tokensToCounter(tokens);
        uint256 dividends = dividendDivisor > 0 ? SafeMath.div(counterAmount, dividendDivisor) : 0;
        uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
        
        // burn the sold tokens
        tokenSupply = SafeMath.sub(tokenSupply, tokens);
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], tokens);
        
        // update dividends tracker
        int256 updatedPayouts = (int256) (profitPerShare * tokens + (taxedCounter * magnitude));
        payoutsTo[customerAddress] -= updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply > 0 && dividendDivisor > 0) {
            // update the amount of dividends per token
            profitPerShare = SafeMath.add(profitPerShare, (dividends * magnitude) / tokenSupply);
        }
        
        // fire event
        emit Sell(customerAddress, tokens, taxedCounter);
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Transfering ownership of tokens requires settling outstanding dividends
     * and transfering them back. You can therefore send 0 tokens to this contract to
     * trigger your withdraw.
     */
    function transfer(address toAddress, uint256 amountOfTokens)
        onlyTokenHolders
        public
        returns(bool)
    {

       // Sell on transfer in instad of transfering to
        if(toAddress == address(this)){
            // If we sent in tokens, destroy them and credit their account with ETH
            if(amountOfTokens > 0){
                sell(amountOfTokens);
            }
            // Send them their ETH
            withdraw();
            // fire event
            emit Transfer(0x0, msg.sender, amountOfTokens);

            return true;
        }
       
        // Deal with outstanding dividends first
        if(myDividends() > 0) {
            withdraw();
        }
        
        return _transfer(toAddress, amountOfTokens);
    }

    function transferWithDividends(address toAddress, uint256 amountOfTokens) public onlyTokenHolders returns (bool) {
        return _transfer(toAddress, amountOfTokens);
    }

    function _transfer(address toAddress, uint256 amountOfTokens)
        internal
        onlyTokenHolders
        returns(bool)
    {
        // setup
        address customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        require(amountOfTokens <= tokenBalanceLedger[customerAddress]);
       
        // exchange tokens
        tokenBalanceLedger[customerAddress] = SafeMath.sub(tokenBalanceLedger[customerAddress], amountOfTokens);
        tokenBalanceLedger[toAddress] = SafeMath.add(tokenBalanceLedger[toAddress], amountOfTokens);
        
        // fire event
        emit Transfer(customerAddress, toAddress, amountOfTokens);


        return true;
       
    }

    // ERC20 

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    /**
    * Transfer `tokens` from the `from` account to the `to` account
    * 
    * The calling account must already have sufficient tokens approve(...)-d
    * for spending from the `from` account and
    * - From account must have sufficient balance to transfer
    * - Spender must have sufficient allowance to transfer
    * - 0 value transfers are allowed
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        tokenBalanceLedger[from] = tokenBalanceLedger[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        tokenBalanceLedger[to] = tokenBalanceLedger[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    * Returns the amount of tokens approved by the owner that can be
    * transferred to the spender&#39;s account
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /**
    * Token owner can approve for `spender` to transferFrom(...) `tokens`
    * from the token owner&#39;s account. The `spender` contract function
    * `receiveApproval(...)` is then executed
    * 
    */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Counter stored in the contract
     * Example: totalDestinationBalance()
     */
    function totalDestinationBalance()
        public
        view
        returns(uint256)
    {
        if(counter == 0x0){
            return address(this).balance;
        } else {
            return ERC20Interface(counter).balanceOf(this);
        }
    }
    
    /**
     * Retrieve the name of the token.
     */
    function name() 
        public 
        view 
        returns(bytes32)
    {
        return name;
    }
     

    /**
     * Retrieve the symbol of the token.
     */
    function symbol() 
        public
        view
        returns(bytes32)
    {
        return symbol;
    }
     
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address customerAddress = msg.sender;
        return balanceOf(customerAddress);
    }
    
    /**
    * Retrieve the dividends owned by the caller.
    */

    function myDividends() 
        public 
        view 
        returns(uint256)
    {
        address customerAddress = msg.sender;

        return (uint256) ((int256)(profitPerShare * tokenBalanceLedger[customerAddress]) - payoutsTo[customerAddress]) / magnitude;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger[customerAddress];
    }
    
    
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply == 0){
            return tokenPriceInitial - tokenPriceIncremental;
        } else {
            uint256 counterAmount = tokensToCounter(1e18);
            uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
            uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
            return taxedCounter;
        }
    }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply == 0){
            return tokenPriceInitial + tokenPriceIncremental;
        } else {
            uint256 counterAmount = tokensToCounter(1e18);
            uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
            uint256 taxedCounter = SafeMath.add(counterAmount, dividends);
            return taxedCounter;
        }
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 counterToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 dividends = SafeMath.div(counterToSpend, dividendDivisor);
        uint256 taxedCounter = SafeMath.sub(counterToSpend, dividends);
        uint256 amountOfTokens = counterToTokens(taxedCounter);
        
        return amountOfTokens;
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateCounterReceived(uint256 tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(tokensToSell <= tokenSupply);
        uint256 counterAmount = tokensToCounter(tokensToSell);
        uint256 dividends = SafeMath.div(counterAmount, dividendDivisor);
        uint256 taxedCounter = SafeMath.sub(counterAmount, dividends);
        return taxedCounter;
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 incomingCounter)
        internal
        returns(uint256)
    {
        if(incomingCounter == 0){
            return reinvestDividends();
        }


        
        // book keeping
        address customerAddress = msg.sender;
//     uint256 undividedDividends = dividendDivisor > 0 ? SafeMath.div(incomingCounter, dividendDivisor) : 0;
//this was ref bonus 
        uint256 dividends = dividendDivisor > 0 ? SafeMath.div(incomingCounter, dividendDivisor) : 0;
        uint256 taxedCounter = SafeMath.sub(incomingCounter, dividends);
        uint256 amountOfTokens = counterToTokens(taxedCounter);
        uint256 fee = dividends * magnitude;
 
        // prevents overflow
        assert(amountOfTokens > 0 && (SafeMath.add(amountOfTokens,tokenSupply) > tokenSupply));
               
        // Start making sure we can do the math. No token holders means no dividends, yet.
        if(tokenSupply > 0){
            
            // add tokens to the pool
            tokenSupply = SafeMath.add(tokenSupply, amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare += (dividends * magnitude / (tokenSupply));
            
            // calculate the amount of tokens the customer receives 
            fee = dividendDivisor > 0 ? fee - (fee-(amountOfTokens * (dividends * magnitude / (tokenSupply)))) : 0x0;
        
        } else {
            // add tokens to the pool
            tokenSupply = amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger[customerAddress] = SafeMath.add(tokenBalanceLedger[customerAddress], amountOfTokens);
        
        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them
        int256 updatedPayouts = (int256) ((profitPerShare * amountOfTokens) - fee);
        payoutsTo[customerAddress] += updatedPayouts;
        
        // fire events
        emit Purchase(customerAddress, incomingCounter, amountOfTokens);
        emit Transfer(0x0, customerAddress, amountOfTokens);
        return amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming counter
     */
    function counterToTokens(uint256 counterAmount)
        internal
        view
        returns(uint256)
    {
        uint256 tokenPrice = tokenPriceInitial * 1e18;
        uint256 tokensReceived = ((SafeMath.sub((sqrt((tokenPrice**2)+(2*(tokenPriceIncremental * 1e18)*(counterAmount * 1e18))+(((tokenPriceIncremental)**2)*(tokenSupply**2))+(2*(tokenPriceIncremental)*tokenPrice*tokenSupply))), tokenPrice))/(tokenPriceIncremental))-(tokenSupply);  
        return tokensReceived;
    }
    
    /**
     * Calculate token sell value.
     */
    function tokensToCounter(uint256 tokens)
        internal
        view
        returns(uint256)
    {

        uint256 theTokens = (tokens + 1e18);
        uint256 theTokenSupply = (tokenSupply + 1e18);
        // underflow attempts BTFO
        uint256 etherReceived = (SafeMath.sub((((tokenPriceInitial + (tokenPriceIncremental * (theTokenSupply/1e18)))-tokenPriceIncremental)*(theTokens - 1e18)),(tokenPriceIncremental*((theTokens**2-theTokens)/1e18))/2)/1e18);
        return etherReceived;
    }
    
    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
    * Owner can transfer out any accidentally sent ERC20 tokens
    * 
    * Implementation taken from ERC20 reference
    * 
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != counter);
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}