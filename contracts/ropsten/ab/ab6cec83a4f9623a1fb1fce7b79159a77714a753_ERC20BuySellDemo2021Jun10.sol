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
        //calculatedTokens = etherToToken(deposit);
        
        emit onPurchase(msg.sender,deposit,calculatedTokens,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedTokens;
    }
    
    function SellTokens(uint256 tokens) public payable returns(uint256 calculatedEthers) 
    {
        //calculatedEthers = tokenToEther(tokens);
        
        emit onSell(msg.sender,tokens,calculatedEthers,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedEthers;
    }
    
    
    function PurchaseTokensTest(uint256 deposit) public payable //returns(uint256 calculatedTokens) 
    {
        NoOfTokensSold = NoOfTokensSold + deposit;
        
        getTokenCurrentPriceInETH();
        
        emit onPurchase(msg.sender,deposit,deposit,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        //return calculatedTokens;
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
            //TokensPriceLevel 6 => Next 50000
            if (NoOfTokensSold > 300000 && NoOfTokensSold <= 350000)
            {
                TokensCurrentLevel = 6;
                TokenCurrentBasePriceInETH = .00127 ether;
            }
            //TokensPriceLevel 7 => Next 50000
            if (NoOfTokensSold > 350000 && NoOfTokensSold <= 400000)
            {
                TokensCurrentLevel = 7;
                TokenCurrentBasePriceInETH = .00124 ether;
            }
            //TokensPriceLevel 8 => Next 50000
            if (NoOfTokensSold > 400000 && NoOfTokensSold <= 450000)
            {
                TokensCurrentLevel = 8;
                TokenCurrentBasePriceInETH = .00387 ether;
            }
            //TokensPriceLevel 9 => Next 50000
            if (NoOfTokensSold > 450000 && NoOfTokensSold <= 500000)
            {
                TokensCurrentLevel = 9;
                TokenCurrentBasePriceInETH = .0073 ether;
            }
            //TokensPriceLevel 10 => Next 50000
            if (NoOfTokensSold > 500000 && NoOfTokensSold <= 550000)
            {
                TokensCurrentLevel = 10;
                TokenCurrentBasePriceInETH = .0142 ether;
            }
            //TokensPriceLevel 11 => Next 40000
            if (NoOfTokensSold > 550000 && NoOfTokensSold <= 590000)
            {
                TokensCurrentLevel = 11;
                TokenCurrentBasePriceInETH = 0.0281 ether;
            }
            //TokensPriceLevel 12 => Next 40000
            if (NoOfTokensSold > 590000 && NoOfTokensSold <= 630000)
            {
                TokensCurrentLevel = 12;
                TokenCurrentBasePriceInETH = 0.0502 ether;
            }
            //TokensPriceLevel 13 => Next 40000
            if (NoOfTokensSold > 630000 && NoOfTokensSold <= 670000)
            {
                TokensCurrentLevel = 13;
                TokenCurrentBasePriceInETH = 0.0945 ether;
            }
            //TokensPriceLevel 14 => Next 40000
            if (NoOfTokensSold > 670000 && NoOfTokensSold <= 710000)
            {
                TokensCurrentLevel = 14;
                TokenCurrentBasePriceInETH = 0.1831 ether;
            }
            //TokensPriceLevel 15 => Next 40000
            if (NoOfTokensSold > 710000 && NoOfTokensSold <= 750000)
            {
                TokensCurrentLevel = 15;
                TokenCurrentBasePriceInETH = 0.3602 ether;
            }
            //TokensPriceLevel 16 => Next 30000
            if (NoOfTokensSold > 750000 && NoOfTokensSold <= 780000)
            {
                TokensCurrentLevel = 16;
                TokenCurrentBasePriceInETH = 0.7144 ether;
            }
            //TokensPriceLevel 17 => Next 30000
            if (NoOfTokensSold > 780000 && NoOfTokensSold <= 810000)
            {
                TokensCurrentLevel = 17;
                TokenCurrentBasePriceInETH = 1.245 ether;
            }
            //TokensPriceLevel 18 => Next 30000
            if (NoOfTokensSold > 810000 && NoOfTokensSold <= 840000)
            {
                TokensCurrentLevel = 18;
                TokenCurrentBasePriceInETH = 2.308 ether;
            }
            //TokensPriceLevel 19 => Next 30000
            if (NoOfTokensSold > 840000 && NoOfTokensSold <= 870000)
            {
                TokensCurrentLevel = 19;
                TokenCurrentBasePriceInETH = 4.434 ether;
            }
            //TokensPriceLevel 20 => Next 30000
            if (NoOfTokensSold > 870000 && NoOfTokensSold <= 900000)
            {
                TokensCurrentLevel = 20;
                TokenCurrentBasePriceInETH = 8.865 ether;
            }

            //TokensPriceLevel 20 => Next 30000
            //if (NoOfTokensSold > 900000)
            //{
                //TokensCurrentLevel = 21;
                //TokenCurrentBasePriceInETH = 0;
            //}
            
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