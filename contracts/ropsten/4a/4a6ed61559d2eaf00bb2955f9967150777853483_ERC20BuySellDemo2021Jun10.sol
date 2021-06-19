/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-15
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
        calculatedTokens = etherToToken(deposit.mul(toEther));
        
        emit onPurchase(msg.sender,deposit,calculatedTokens,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedTokens;
    }
    
    function SellTokens(uint256 tokens) public payable returns(uint256 calculatedEthers) 
    {
        calculatedEthers = tokenToEther(tokens);
        
        emit onSell(msg.sender,tokens,calculatedEthers,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        return calculatedEthers;
    }
    
    
    /*function PurchaseTokensTest(uint256 deposit) public payable //returns(uint256 calculatedTokens) 
    {
        NoOfTokensSold = NoOfTokensSold + deposit;
        
        getTokenCurrentPriceInETH();
        
        emit onPurchase(msg.sender,deposit,deposit,block.timestamp,TokensCurrentLevel,TokenCurrentBasePriceInETH,NoOfTokensSold,getNoOfTokensRemaining());
        
        //return calculatedTokens;
    }*/
    
    
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
            
            emit chkEtherLeftForNextLevel(incomingEther,AppproxNoOfTokensToSend,AmountInEtherLeftForNextLevel);

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
            
            emit chkEtherLeftForNextLevel(incomingEther,AppproxNoOfTokensToSend,AmountInEtherLeftForNextLevel);

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
            
            emit chkEtherLeftForNextLevel(incomingEther,AppproxNoOfTokensToSend,AmountInEtherLeftForNextLevel);

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

            //TokensPriceLevel 6 => Next 50000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 6)
            {
                NoOfTokensAvailableAtCurrentLevel = 350000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .00127 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .00127 ether;
                RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 50000;
                    TokensCurrentLevel = 7;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .00127 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 7 => Next 50000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 7)
            {
                NoOfTokensAvailableAtCurrentLevel = 400000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .00124 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .00124 ether;
                RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 50000;
                    TokensCurrentLevel = 8;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .00124 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 8 => Next 50000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 8)
            {
                NoOfTokensAvailableAtCurrentLevel = 450000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .00387 ether);

                    if(AmountInEtherLeftForNextLevel<0)
                    {
                        NoOfTokensAvailableAtCurrentLevel= RemainingInEtherLeftForNextLevel / .00387 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 50000;
                    TokensCurrentLevel = 9;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .00387 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 9 => Next 50000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 9)
            {
                NoOfTokensAvailableAtCurrentLevel = 500000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .0073 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .0073 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 50000;
                    TokensCurrentLevel = 10;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .0073 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 10 => Next 50000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 10)
            {
                NoOfTokensAvailableAtCurrentLevel = 550000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * .0142 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / .0142 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 50000;
                    TokensCurrentLevel = 11;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / .0142 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 11 => Next 40000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 11)
            {
                NoOfTokensAvailableAtCurrentLevel = 590000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.0281 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.0281 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 40000;
                    TokensCurrentLevel = 12;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.0281 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 12 => Next 40000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 12)
            {
                NoOfTokensAvailableAtCurrentLevel = 630000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.0502 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.0502 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 40000;
                    TokensCurrentLevel = 13;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.0502 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 13 => Next 40000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 13)
            {
                NoOfTokensAvailableAtCurrentLevel = 670000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.0945 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.0945 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 40000;
                    TokensCurrentLevel = 14;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.0945 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 14 => Next 40000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 14)
            {
                NoOfTokensAvailableAtCurrentLevel = 710000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.1831 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.1831 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 40000;
                    TokensCurrentLevel = 15;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.1831 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 15 => Next 40000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 15)
            {
                NoOfTokensAvailableAtCurrentLevel = 750000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.3602 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.3602 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 40000;
                    TokensCurrentLevel = 16;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.3602 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 16 => Next 30000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 16)
            {
                NoOfTokensAvailableAtCurrentLevel = 780000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 0.7144 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 0.7144 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 30000;
                    TokensCurrentLevel = 17;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 0.7144 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 17 => Next 30000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 17)
            {
                NoOfTokensAvailableAtCurrentLevel = 810000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 1.245 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 1.245 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 30000;
                    TokensCurrentLevel = 18;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 1.245 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 18 => Next 30000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 18)
            {
                NoOfTokensAvailableAtCurrentLevel = 840000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 2.308 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 2.308 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 30000;
                    TokensCurrentLevel = 19;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 2.308 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 19 => Next 30000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 19)
            {
                NoOfTokensAvailableAtCurrentLevel = 870000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 4.434 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 4.434 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 30000;
                    TokensCurrentLevel = 20;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 4.434 ether;

                    NoOfTokensSold = NoOfTokensSold + AppproxNoOfTokensToSend;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + AppproxNoOfTokensToSend;
                }
            }

            //TokensPriceLevel 20 => Next 30000
            if (AmountInEtherLeftForNextLevel > 0 && TokensCurrentLevel == 20)
            {
                NoOfTokensAvailableAtCurrentLevel = 900000 - NoOfTokensSold;

                if (AppproxNoOfTokensToSend > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of Tokens To Send
                    RemainingInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel;

                    AmountInEtherLeftForNextLevel = AmountInEtherLeftForNextLevel - (NoOfTokensAvailableAtCurrentLevel * 8.865 ether);

                    if (AmountInEtherLeftForNextLevel < 0)
                    {
                        NoOfTokensAvailableAtCurrentLevel = RemainingInEtherLeftForNextLevel / 8.865 ether;
                        RemainingInEtherLeftForNextLevel = 0;
                    }

                    //ActuallNoOfTokensToSend = NoOfTokensAvailableAtCurrentLevel;

                    AppproxNoOfTokensToSend = AppproxNoOfTokensToSend - 30000;
                    //TokensCurrentLevel = 21;

                    NoOfTokensSold = NoOfTokensSold + NoOfTokensAvailableAtCurrentLevel;

                    ActuallNoOfTokensToSend = ActuallNoOfTokensToSend + NoOfTokensAvailableAtCurrentLevel;
                }
                else
                {
                    AppproxNoOfTokensToSend = AmountInEtherLeftForNextLevel / 8.865 ether;

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


            //TokensPriceLevel 20 => Next 30000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 20)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 870000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = NoOfTokensAvailableAtCurrentLevel * 8.865 ether;
                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 19;
                }
                else
                {
                    ActuallEthToSendToUser = NoOfTokensEnteredForSale * 8.865 ether;
                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 19 => Next 30000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 19)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 840000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser+NoOfTokensAvailableAtCurrentLevel * 4.434 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 18;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 4.434 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 18 => Next 30000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 18)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 810000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 2.308 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 17;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 2.308 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 17 => Next 30000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 17)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 780000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 1.245 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 16;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 1.245 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 16 => Next 30000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 16)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 750000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.7144 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 15;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.7144 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 15 => Next 40000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 15)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 710000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.3602 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 14;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.3602 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 14 => Next 40000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 14)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 670000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.1831 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 13;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.1831 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 13 => Next 40000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 13)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 630000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0945 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 12;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0945 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 12 => Next 40000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 12)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 590000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0502 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 11;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0502 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 11 => Next 40000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 11)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 550000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0281 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 10;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0281 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 10 => Next 50000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 10)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 500000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0142 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 9;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0142 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 9 => Next 50000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 9)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 450000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.0073 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 8;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.0073 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 8 => Next 50000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 8)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 400000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.00387 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 7;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.00387 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 7 => Next 50000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 7)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 350000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.00124 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 6;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.00124 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

            //TokensPriceLevel 6 => Next 50000
            if (NoOfTokensEnteredForSale > 0 && TokensCurrentLevel == 6)
            {
                NoOfTokensAvailableAtCurrentLevel = NoOfTokensSold - 300000;

                if (NoOfTokensEnteredForSale > NoOfTokensAvailableAtCurrentLevel)
                {
                    //Recalculate Actuall No Of ETH To Send
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensAvailableAtCurrentLevel * 0.00127 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensAvailableAtCurrentLevel;
                    NoOfTokensEnteredForSale = NoOfTokensEnteredForSale - NoOfTokensAvailableAtCurrentLevel;
                    TokensCurrentLevel = 5;
                }
                else
                {
                    ActuallEthToSendToUser = ActuallEthToSendToUser + NoOfTokensEnteredForSale * 0.00127 ether;

                    NoOfTokensSold = NoOfTokensSold - NoOfTokensEnteredForSale;
                    NoOfTokensEnteredForSale = 0;
                }
            }

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
     
     
     event chkEtherLeftForNextLevel(
         uint256 incomingEther,
         uint256 AppproxNoOfTokensToSend,
         uint256 AmountInEtherLeftForNextLevel
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