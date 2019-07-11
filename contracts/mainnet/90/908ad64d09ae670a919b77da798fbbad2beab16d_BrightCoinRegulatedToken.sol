pragma solidity ^0.4.25;


import "./BrightCoinTokenOwner_ICO.sol";
import "./BrightCoinERC20Contract_ICO.sol";


//Rules for Accredited Investors
/*
 This is special BrightCoinToken that will allow User to invest to Token Only after Proper Checks and Validation as provide by US Regulatories Authorities
*/

/*
 import all specific contract that will help in Validation 
 Accridetion
 KYC
 TokenDistribution Details
*/

contract BrightCoinRegulatedToken  is BrightCoinERC20
{

//BrightCoinInvestorKYC InvestorKYCInfo;
//BrightCoinInvestorCheck AccreditationInfo;


address public BrightCoinInvestorKYCAddress; 
address public BrightCoinInvestorAccreditationAddress; 
mapping (uint8 => uint256) private PeriodTokenAmount;
bool InvestorSecurity;
bool KYCSupport;

constructor() public 
{
 InvestorSecurity = false;
 KYCSupport = false;
}




  
  function DistributeToken(address _addrOfInvestor, uint256 _currenttime,
                    uint256 _tokens, uint8 _mainSalePeriodIndex) public onlyTokenOwner 
  {

      require(_addrOfInvestor != 0x0);
      require(_currenttime >0);
   //   require(_tokenlockPeriod > 0);
      require(_tokens > 0);

   
       
        if((_mainSalePeriodIndex == 0) && (PreSaleOn == true))  //PreSale
        {
        
       
      
            //Check if Period Hard cap achived 

            require(_tokens <= getMaxCoinSoldDuringPreSale());
            
            //Check if ICO Hardcap achived
            require(CheckIfHardcapAchived(_tokens) == true);
            internaltransfer(msg.sender,_addrOfInvestor,_tokens);
           // SetTokenLock(_addrOfInvestor,tokenTimeLock,_tokens);
            updatepresalemaxTokenCount(_tokens);
        }
        else
        {
            //Calculate token amount
            require(CheckIfMainSaleOn(_mainSalePeriodIndex) == true);
            require(CheckTokenPeriodSale(_currenttime,_mainSalePeriodIndex) == true);
            
          
      
            require(CheckMainSaleLimit(_mainSalePeriodIndex,_tokens) == true, "Main Sale Limit Crossed");
             
            require(CheckIfHardcapAchived(_tokens) == true);
            
             internaltransfer(msg.sender,_addrOfInvestor,_tokens);
           //  SetTokenLock(_addrOfInvestor,tokenTimeLock,_tokens);
             updateCurrentTokenCount(_mainSalePeriodIndex,_tokens);
        }
  }

 function tranfertocustodian(address _to) public onlyTokenOwner returns(bool)
{
    internaltransfer(msg.sender, _to, balances[msg.sender]);
    custodianaddress = _to;
    return true;
}

  

function regulatedtransfer( address _from , address _to, uint256 _tokens) private returns(bool) 
{
    //check if locking period is expired or not 
      uint256 currenttime = now;
      
      if (InvestorSecurity == true)
      {
          
           if(isTokenLockExpire(_from,currenttime) == true)
           {
               internaltransfer(_from,_to,_tokens);
                return true;
           }
           
           uint256 TokenLockExpiry = getTokenLockExpiry(_from); 
           require(TokenLockExpiry !=0);
         
         if( ICOType != uint8(BrightCoinICOType.Utility))
         {
        //    require(AccreditationInfo.checkBothInvestorValidity(_from,_to, ICOType) == true); 
            SetTokenLock(_to,TokenLockExpiry,_tokens);
            internaltransfer(_from,_to,_tokens);
            return true; 
         }
         else
         {
          SetTokenLock(_to,TokenLockExpiry,_tokens);
           internaltransfer(_from,_to,_tokens);
           return true;
         }
            
      }
      else
      {
        // require(isTokenLockExpire(msg.sender,currenttime) == true);
         internaltransfer(_from,_to,_tokens);
         return true;
      }
      
}

function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool success) 
{
      
       require(pauseICO == false);  //if this flag is true the no operation is allowed.
      require(_tokens > 0);
      require(allowed[_from][msg.sender] >= _tokens);
    
     require(internaltransfer(_from ,_to,_tokens) == true);
      //If regulated transfer is true then only reduce allowed map
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
      return true;
}
    

function approve(address _spender, uint256 _value) public returns (bool success)
 {
     require(_spender != address(0));
    //  require(checkCompliance(_spender) == true);
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      
      return true;
 }
  //This method will be called when investor  wants to tranfer token to other.  
function transfer(address _to, uint _tokens) public returns (bool) 
 {     
    require(pauseICO == false);  //if this flag is true the no operation is allowed.
    require(_to != address(0));
    require (internaltransfer(msg.sender, _to,_tokens ) == true);
   
     emit Transfer(msg.sender, _to, _tokens);
    return true;
       
      
}
      

   function TransferCompanyHoldingTokens() public onlyTokenOwner     returns(bool)
  { 
    
      require(CompanyHoldingBalances[msg.sender] == CompanyHoldingValue) ; 
   //   uint256 Holdinglockexpiry = now.add(_lockExpiry);
     // balances[CompanyHoldingAddress] = CompanyHoldingBalances[msg.sender];
      internaltransfer(msg.sender,CompanyHoldingAddress,CompanyHoldingValue);
    CompanyHoldingBalances[msg.sender] = 0;
  // SetTokenLock(CompanyHoldingAddress,Holdinglockexpiry,CompanyHoldingValue);
    //  emit Transfer(msg.sender, CompanyHoldingAddress, CompanyHoldingValue);
      return true;

 } 
 


}