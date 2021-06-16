/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity 0.6.8;

contract ERC20BuySellDemo2021Jun10
{
    using SafeMath for uint256;
    address payable public Owner;
    
    int TokensCurrentLevel = 0;
    uint256 TokenCurrentBasePriceInETH = 0;
    
    uint256 NoOfTokensSold = 0;
    uint256 constant TotalSupply = 900000;
    
    
    uint256 constant toEther = 1000000000000000000;
    
    // This is the constructor whose code is
    // run only when the contract is created.
    constructor() public payable 
    {
        Owner = msg.sender;
        //getTokenCurrentPriceInETH();
        
        TokensCurrentLevel = 1;
        TokenCurrentBasePriceInETH = .00027 ether;
    }
    
    function GetOwner() public view returns(address)
    {
        return Owner;
    }
    
    // GetAddressCurrentBalance
    function GetBalance(address strAddress) external view returns(uint)
    {
        return address(strAddress).balance;
    }
    
    /*
    function Register(string memory InputData) public payable 
    {
        if(keccak256(abi.encodePacked(InputData))==keccak256(abi.encodePacked('')))
        {
            // do nothing!
            revert();
        }
        
        if(msg.sender!=Owner)
        {
            Owner.transfer(msg.value);
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function Send(address payable toAddressID) public payable 
    {
        if(msg.sender==Owner)
        {
            toAddressID.transfer(msg.value);
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function SendWithdrawals(address[] memory toAddressIDs, uint256[] memory tranValues) public payable 
    {
        if(msg.sender==Owner)
        {
            uint256 total = msg.value;
            uint256 i = 0;
            for (i; i < toAddressIDs.length; i++) 
            {
                require(total >= tranValues[i] );
                total = total.sub(tranValues[i]);
                payable(toAddressIDs[i]).transfer(tranValues[i]);
            }
        }
        else
        {
            // else do nothing!
            revert();
        }
    }
    
    function Transfer() public
    {
      Owner.transfer(address(this).balance);  
    }*/
    
    
    function PurchaseTokens(uint256 deposit) public payable returns(uint256 calculatedTokens) 
    {
        calculatedTokens = etherToToken(deposit);
        
        emit onPurchase(msg.sender,deposit,calculatedTokens,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedTokens;
    }
    
    function SellTokens(uint256 tokens) public payable returns(uint256 calculatedEthers) 
    {
        calculatedEthers = tokenToEther(tokens);
        
        emit onSell(msg.sender,tokens,calculatedEthers,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedEthers;
    }
    
    
    function etherToToken(uint256 incomingEther) internal returns(uint256)  //tokensCalculated  
    {
        uint256 AppproxNoOfTokensToSend = 0;
        uint256 ActuallNoOfTokensToSend = 0;
        uint256 AmountEnteredInETH = 0;
        uint256 AmountInEtherLeftForNextLevel = 0;
        uint256 RemainingInEtherLeftForNextLevel = 0;
        
        AmountEnteredInETH = incomingEther;
        
        if (AmountEnteredInETH > 0)
        {
            AppproxNoOfTokensToSend = AmountEnteredInETH / TokenCurrentBasePriceInETH;
            //txtAppproxClubEtherTokensRecieved.Text = AppproxNoOfTokensToSend.ToString();

            //TotalNoOfTokensForCalculation = NoOfTokensPurchased + AppproxNoOfTokensToSend;

            uint256 NoOfTokensAvailableAtCurrentLevel = 0;

            AmountInEtherLeftForNextLevel = AmountEnteredInETH;

            //TokensPriceLevel 1 => First 60000
            if (TokensCurrentLevel == 1)
            {
                NoOfTokensAvailableAtCurrentLevel = 60000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .00027 ether);            

                    ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 60000;
                    TokensCurrentLevel = 2;
                }
                else
                {
                    ActuallNoOfTokensToSend = AppproxNoOfTokensToSend;
                }
        
                NoOfTokensSold = NoOfTokensSold + ActuallNoOfTokensToSend;
            }

            //TokensPriceLevel 2 => Next 60000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 2)
            {
                NoOfTokensAvailableAtCurrentLevel = 120000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .0003 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .0003 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 60000;
                    TokensCurrentLevel = 3;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend+NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .0003 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            ////TokensPriceLevel 3 => Next 60000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 3)
            {
                NoOfTokensAvailableAtCurrentLevel = 180000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .000367 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .000367 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 60000;
                    TokensCurrentLevel = 4;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend =
                    ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .000367 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            ////TokensPriceLevel 4 => Next 60000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 4)
            {
                NoOfTokensAvailableAtCurrentLevel = 240000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .000497 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .000497 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 60000;
                    TokensCurrentLevel = 5;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .000497 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 5 => Next 60000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 5)
            {
                NoOfTokensAvailableAtCurrentLevel = 300000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .000756 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .000756 ether;
                RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 60000;
                    TokensCurrentLevel = 6;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .000756 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            

            ////TokensPriceLevel 20 => Next 30000
            //if (NoOfTokensPurchased > 900000)
            //{
            //    TokensCurrentLevel = 21;
            //    TokenCurrentBasePriceInETH = 0;
            //}

            getTokenCurrentPriceInETH();
        }
        
        
        return ActuallNoOfTokensToSend;
    }
   
   
    function tokenToEther(uint256 tokenToSell) internal returns(uint256)  //EthersCalculated
    {
        uint256 ActuallEthToSendToUser = 0;
        uint256 NoOfTokensEnteredForSale = 0;
        
        NoOfTokensEnteredForSale = tokenToSell;
        
        if (NoOfTokensEnteredForSale > 0)
        {
            //AppproxNoOfTokensToSend = AmountEnteredInETH / TokenCurrentBasePriceInETH;

            uint256 NoOfTokensAvailableAtCurrentLevel = 0;


            

            //TokensPriceLevel 5 => Next 60000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 5)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 240000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.000756 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 4;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.000756 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 4 => Next 60000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 4)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 180000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.000497 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 3;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.000497 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 3 => Next 60000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 3)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 120000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.000367 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 2;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.000367 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 2 => Next 60000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 2)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 60000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0003 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 1;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0003 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 1 => Next 60000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 1)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 0;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.00027 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    //TokensCurrentLevel = 0;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.00027 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            ////TokensPriceLevel 20 => Next 30000
            //if (NoOfTokensPurchased > 900000)
            //{
            //    TokensCurrentLevel = 21;
            //    TokenCurrentBasePriceInETH = 0;
            //}
            
            getTokenCurrentPriceInETH();
        }
        
        
        return ActuallEthToSendToUser;
    }
    
    
    function getTokenCurrentPriceInETH() internal
        {
            //NoOfTokensSold = Convert.ToDouble(txtNoOfTokensSold.Text);

            //TokensPriceLevel 1 => First 60000
            if (NoOfTokensSold > 0 && NoOfTokensSold <= 60000)
            {
                TokensCurrentLevel = 1;
                TokenCurrentBasePriceInETH = .00027 ether;
            }
            //TokensPriceLevel 2 => Next 60000
            if (NoOfTokensSold > 60000 && NoOfTokensSold <= 120000)
            {
                TokensCurrentLevel = 2;
                TokenCurrentBasePriceInETH = .0003 ether;
            }
            //TokensPriceLevel 3 => Next 60000
            if (NoOfTokensSold > 120000 && NoOfTokensSold <= 180000)
            {
                TokensCurrentLevel = 3;
                TokenCurrentBasePriceInETH = .000367 ether;
            }
            //TokensPriceLevel 4 => Next 60000
            if (NoOfTokensSold > 180000 && NoOfTokensSold <= 240000)
            {
                TokensCurrentLevel = 4;
                TokenCurrentBasePriceInETH = .000497 ether;
            }
            //TokensPriceLevel 5 => Next 60000
            if (NoOfTokensSold > 240000 && NoOfTokensSold <= 300000)
            {
                TokensCurrentLevel = 5;
                TokenCurrentBasePriceInETH = .000756 ether;
            }
            
            
        }


	function getTokensCurrentLevel() public view returns(int) 
    {
		return TokensCurrentLevel;
	}

	function getTokenCurrentBasePriceInETH() public view returns(uint256) 
	{
		return TokenCurrentBasePriceInETH;
	}
	
	function getNoOfTokensSold() public view returns(uint256) 
    {
		return NoOfTokensSold;
	}

	function getNoOfTokensRemaining() public view returns(uint256) 
	{
		return TotalSupply - NoOfTokensSold;
	}
	
	function getDepositInfo(address userAddress) public view returns(int TkLevel, uint256 TkPrice, uint256 TkSold, uint256 TkRemaining) 
	{

		TkLevel = TokensCurrentLevel;
		TkPrice = TokenCurrentBasePriceInETH;
		TkSold = NoOfTokensSold;
		TkRemaining = TotalSupply - NoOfTokensSold;
		
	}
	
	/*** on Buy-Purchase Event (tokens Calculated-Transfered)*/

     event onPurchase(
         address purchaser,
         uint256 ethDeposited,
         uint256 tokensCalculated,
         uint256 datePurchased,
         int tokenLevel,
         uint256 tokenPriceInETH,
         uint256 totalTokensSold,
         uint256 totalTokensRemaining
     );
   
   /*** on Sell Event */

     event onSell(
         address seller,
         uint256 tokensSold,
         uint256 ethersCalculated,
         uint256 dateSold,
         int tokenLevel,
         uint256 tokenPriceInETH,
         uint256 totalTokensSold,
         uint256 totalTokensRemaining
     );
}


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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