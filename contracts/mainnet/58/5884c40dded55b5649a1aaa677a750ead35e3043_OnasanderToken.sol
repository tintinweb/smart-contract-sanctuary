/** @title Onasander Token Contract
*   
*   @author: Andrzej Wegrzyn
*   Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e6828390838a89968b838892a6898887958788828394c885898b">[email&#160;protected]</a>
*   Date: May 5, 2018
*   Location: New York, USA
*   Token: Onasander
*   Symbol: ONA
*   
*   @notice This is a simple contract due to solidity bugs and complications. 
*
*   @notice Owner has the option to burn all the remaining tokens after the ICO.  That way Owners will not end up with majority of the tokens.
*   @notice Onasander would love to give every user the option to burn the remaining tokens, but due to Solidity VM bugs and risk, we will process
*   @notice all coin burns and refunds manually.
*   
*   @notice How to run the contract:
*
*   Requires:
*   Wallet Address
*
*   Run:
*   1. Create Contract
*   2. Set Minimum Goal
*   3. Set Tokens Per ETH
*   4. Create PRE ICO Sale (can have multiple PRE-ICOs)
*   5. End PRE ICO Sale
*   6. Create ICO Sale
*   7. End ICO Sale
*   8. END ICO
*   9. Burn Remaining Tokens
*
*   e18 for every value except tokens per ETH
*   
*   @dev This contract allows you to configure as many Pre-ICOs as you need.  It&#39;s a very simple contract written to give contract admin lots of dynamic options.
*   @dev Here, most features except for total supply, max tokens for sale, company reserves, and token standard features, are dynamic.  You can configure your contract
*   @dev however you want to.  
*
*   @dev IDE: Remix with Mist 0.10
*   @dev Token supply numbers are provided in 0e18 format in MIST in order to bypass MIST number format errors.
*/

pragma solidity ^0.4.23;

contract OnasanderToken
{
    using SafeMath for uint;
    
    address private wallet;                                // Address where funds are collected
    address public owner;                                  // contract owner
    string constant public name = "Onasander";
    string constant public symbol = "ONA";
    uint8 constant public decimals = 18;
    uint public totalSupply = 88000000e18;                       
    uint public totalTokensSold = 0e18;                    // total number of tokens sold to date
    uint public totalTokensSoldInThisSale = 0e18;          // total number of tokens sold in this sale
    uint public maxTokensForSale = 79200000e18;            // 90%  max tokens we can ever sale  
    uint public companyReserves = 8800000e18;              // 10%  company reserves. this is what we end up with after eco ends and burns the rest if any  
    uint public minimumGoal = 0e18;                        // hold minimum goal
    uint public tokensForSale = 0e18;                      // total number of tokens we are selling in the current sale (ICO, preICO)
    bool public saleEnabled = false;                       // enables all sales: ICO and tokensPreICO
    bool public ICOEnded = false;                          // flag checking if the ICO has completed
    bool public burned = false;                            // Excess tokens burned flag after ICO ends
    uint public tokensPerETH = 800;                        // amount of Onasander tokens you get for 1 ETH
    bool public wasGoalReached = false;                    // checks if minimum goal was reached
    address private lastBuyer;
    uint private singleToken = 1e18;

    constructor(address icoWallet) public 
    {   
        require(icoWallet != address(0), "ICO Wallet address is required.");

        owner = msg.sender;
        wallet = icoWallet;
        balances[owner] = totalSupply;  // give initial full balance to contract owner
        emit TokensMinted(owner, totalSupply);        
    }

    event ICOHasEnded();
    event SaleEnded();
    event OneTokenBugFixed();
    event ICOConfigured(uint minimumGoal);
    event TokenPerETHReset(uint amount);
    event ICOCapReached(uint amount);
    event SaleCapReached(uint amount);
    event GoalReached(uint amount);
    event Burned(uint amount);    
    event BuyTokens(address buyer, uint tokens);
    event SaleStarted(uint tokensForSale);    
    event TokensMinted(address targetAddress, uint tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address => uint) balances;
    
    mapping(address => mapping (address => uint)) allowances;

    function balanceOf(address accountAddress) public constant returns (uint balance)
    {
        return balances[accountAddress];
    }

    function allowance(address sender, address spender) public constant returns (uint remainingAllowedAmount)
    {
        return allowances[sender][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success)
    {     
        require (ICOEnded, "ICO has not ended.  Can not transfer.");
        require (balances[to] + tokens > balances[to], "Overflow is not allowed.");

        // actual transfer
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    function transferFrom(address from, address to, uint tokens) public returns(bool success) 
    {
        require (ICOEnded, "ICO has not ended.  Can not transfer.");
        require (balances[to] + tokens > balances[to], "Overflow is not allowed.");

        // actual transfer
        balances[from] = balances[from].sub(tokens);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens); // lower the allowance by the amount of tokens 
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(from, to, tokens);        
        return true;
    }

    function approve(address spender, uint tokens) public returns(bool success) 
    {          
        require (ICOEnded, "ICO has not ended.  Can not transfer.");      
        allowances[msg.sender][spender] = tokens;                
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

        // in case some investor pays by wire or credit card we will transfer him the tokens manually.
    function wirePurchase(address to, uint numberOfTokenPurchased) onlyOwner public
    {     
        require (saleEnabled, "Sale must be enabled.");
        require (!ICOEnded, "ICO already ended.");
        require (numberOfTokenPurchased > 0, "Tokens must be greater than 0.");
        require (tokensForSale > totalTokensSoldInThisSale, "There is no more tokens for sale in this sale.");
                        
        // calculate amount
        uint buyAmount = numberOfTokenPurchased;
        uint tokens = 0e18;

        // this check is not perfect as someone may want to buy more than we offer for sale and we lose a sale.
        // the best would be to calclate and sell you only the amout of tokens that is left and refund the rest of money        
        if (totalTokensSoldInThisSale.add(buyAmount) >= tokensForSale)
        {
            tokens = tokensForSale.sub(totalTokensSoldInThisSale);  // we allow you to buy only up to total tokens for sale, and refund the rest
            // need to program the refund for the rest,or do it manually.  
        }
        else
        {
            tokens = buyAmount;
        }

        // transfer only as we do not need to take the payment since we already did in wire
        require (balances[to].add(tokens) > balances[to], "Overflow is not allowed.");
        balances[to] = balances[to].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        lastBuyer = to;

        // update counts
        totalTokensSold = totalTokensSold.add(tokens);
        totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(tokens);
        
        emit BuyTokens(to, tokens);
        emit Transfer(owner, to, tokens);

        isGoalReached();
        isMaxCapReached();
    }

    function buyTokens() payable public
    {        
        require (saleEnabled, "Sale must be enabled.");
        require (!ICOEnded, "ICO already ended.");
        require (tokensForSale > totalTokensSoldInThisSale, "There is no more tokens for sale in this sale.");
        require (msg.value > 0, "Must send ETH");

        // calculate amount
        uint buyAmount = SafeMath.mul(msg.value, tokensPerETH);
        uint tokens = 0e18;

        // this check is not perfect as someone may want to buy more than we offer for sale and we lose a sale.
        // the best would be to calclate and sell you only the amout of tokens that is left and refund the rest of money        
        if (totalTokensSoldInThisSale.add(buyAmount) >= tokensForSale)
        {
            tokens = tokensForSale.sub(totalTokensSoldInThisSale);  // we allow you to buy only up to total tokens for sale, and refund the rest

            // need to program the refund for the rest
        }
        else
        {
            tokens = buyAmount;
        }

        // buy
        require (balances[msg.sender].add(tokens) > balances[msg.sender], "Overflow is not allowed.");
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        lastBuyer = msg.sender;

        // take the money out right away
        wallet.transfer(msg.value);

        // update counts
        totalTokensSold = totalTokensSold.add(tokens);
        totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(tokens);
        
        emit BuyTokens(msg.sender, tokens);
        emit Transfer(owner, msg.sender, tokens);

        isGoalReached();
        isMaxCapReached();
    }

    // Fallback function. Used for buying tokens from contract owner by simply
    // sending Ethers to contract.
    function() public payable 
    {
        // we buy tokens using whatever ETH was sent in
        buyTokens();
    }

    // Called when ICO is closed. Burns the remaining tokens except the tokens reserved
    // Must be called by the owner to trigger correct transfer event
    function burnRemainingTokens() public onlyOwner
    {
        require (!burned, "Remaining tokens have been burned already.");
        require (ICOEnded, "ICO has not ended yet.");

        uint difference = balances[owner].sub(companyReserves); 

        if (wasGoalReached)
        {
            totalSupply = totalSupply.sub(difference);
            balances[owner] = companyReserves;
        }
        else
        {
            // in case we did not reach the goal, we burn all tokens except tokens purchased.
            totalSupply = totalTokensSold;
            balances[owner] = 0e18;
        }

        burned = true;

        emit Transfer(owner, address(0), difference);    // this is run in order to update token holders in the website
        emit Burned(difference);        
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public
    {
        address preOwner = owner;        
        owner = newOwner;

        uint previousBalance = balances[preOwner];

        // transfer balance 
        balances[newOwner] = balances[newOwner].add(previousBalance);
        balances[preOwner] = 0;

        //emit Transfer(preOwner, newOwner, previousBalance); // required to update the Token Holders on the network
        emit OwnershipTransferred(preOwner, newOwner, previousBalance);
    }

    // Set the number of ONAs sold per ETH 
    function setTokensPerETH(uint newRate) onlyOwner public
    {
        require (!ICOEnded, "ICO already ended.");
        require (newRate > 0, "Rate must be higher than 0.");
        tokensPerETH = newRate;
        emit TokenPerETHReset(newRate);
    }

    // Minimum goal is based on USD, not on ETH. Since we will have different dynamic prices based on the daily pirce of ETH, we
    // will need to be able to adjust our minimum goal in tokens sold, as our goal is set in tokens, not USD.
    function setMinimumGoal(uint goal) onlyOwner public
    {   
        require(goal > 0e18,"Minimum goal must be greater than 0.");
        minimumGoal = goal;

        // since we can edit the goal, we want to check if we reached the goal before in case we lowered the goal number.
        isGoalReached();

        emit ICOConfigured(goal);
    }

    function createSale(uint numberOfTokens) onlyOwner public
    {
        require (!saleEnabled, "Sale is already going on.");
        require (!ICOEnded, "ICO already ended.");
        require (totalTokensSold < maxTokensForSale, "We already sold all our tokens.");

        totalTokensSoldInThisSale = 0e18;
        uint tryingToSell = totalTokensSold.add(numberOfTokens);

        // in case we are trying to create a sale with too many tokens, we subtract and sell only what&#39;s left
        if (tryingToSell > maxTokensForSale)
        {
            tokensForSale = maxTokensForSale.sub(totalTokensSold); 
        }
        else
        {
            tokensForSale = numberOfTokens;
        }

        tryingToSell = 0e18;
        saleEnabled = true;
        emit SaleStarted(tokensForSale);
    }

    function endSale() public
    {
        if (saleEnabled)
        {
            saleEnabled = false;
            tokensForSale = 0e18;
            emit SaleEnded();
        }
    }

    function endICO() onlyOwner public
    {
        if (!ICOEnded)
        {
            // run this before end of ICO and end of last sale            
            fixTokenCalcBug();

            endSale();

            ICOEnded = true;            
            lastBuyer = address(0);
            
            emit ICOHasEnded();
        }
    }

    function isGoalReached() internal
    {
        // check if we reached the goal
        if (!wasGoalReached)
        {
            if (totalTokensSold >= minimumGoal)
            {
                wasGoalReached = true;
                emit GoalReached(minimumGoal);
            }
        }
    }

    function isMaxCapReached() internal
    {
        if (totalTokensSoldInThisSale >= tokensForSale)
        {            
            emit SaleCapReached(totalTokensSoldInThisSale);
            endSale();
        }

        if (totalTokensSold >= maxTokensForSale)
        {            
            emit ICOCapReached(maxTokensForSale);
            endICO();
        }
    }

    // This is a hack to add the lost token during final full sale. 
    function fixTokenCalcBug() internal
    {        
        require(!burned, "Fix lost token can only run before the burning of the tokens.");        
        
        if (maxTokensForSale.sub(totalTokensSold) == singleToken)
        {
            totalTokensSold = totalTokensSold.add(singleToken);
            totalTokensSoldInThisSale = totalTokensSoldInThisSale.add(singleToken);
            
            balances[lastBuyer] = balances[lastBuyer].add(singleToken);
            balances[owner] = balances[owner].sub(singleToken);

            emit Transfer(owner, lastBuyer, singleToken);
            emit OneTokenBugFixed();
        }
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}