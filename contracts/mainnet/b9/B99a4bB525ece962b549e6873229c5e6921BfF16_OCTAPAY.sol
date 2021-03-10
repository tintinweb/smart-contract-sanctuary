/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.5.10;


library SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}






contract OCTAPAY {
    
    using SafeMath for uint;
     
    string  public name = "Octapay";
    string  public symbol = "OCTA";
    uint256 public initialSupply = 0;
    uint256 public currentSupply = 0 ;
    uint256 public totalSupply = 15000000000000000000000000;     // This total supply is the Maxmimum Supply Octapay is allowed to reach that is 15 million tokens
    uint8   public decimals = 18;
    address public owner ;
    
    
    address public  payzusAdminAddress = 0x819de8bA8b172a6063923EB1b003fA9487773465 ;
    address public  mintOctpayLockingAddr ;   // This address should be set time to time by Payzus Admin  everytime new Staking Pool Contract is deployed
     
    bool public tokenBurningStart = false ;
    bool public maximumSupplyReached = false ;
    


    
    // Octapay Token Burning Related Parameter,once it reaches its mazimum/total Supply
      
    
    uint  public tokenBurningInOneSlot = 25 ;
    uint  public tokenBurningInOneSlotAccuracyRatio = 100;
    uint  public tokenBurningCounter = 1;
    uint  public totalTokenBurninglot = 4;
    
    
    uint public firstSlotTokenBurningTime ;
    uint public secondSlotTokenBurningTime ;
    uint public thirdSlotTokenBurningTime ;



     uint public octapayContractReserveTokenBalance = balanceOf[address(this)];
    
    
    // uint public octapayContractReserveTokenBalance = 3000000 ;   // For testing purpose
    
    uint public octapayReserveBalFirstBurningSlot;
    
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;





  ////////////////////////////////////////////////////////////////////////////////////////EVENT DEFINATION///////////////////////////////////////////////////////////////////////////////////////////////


    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );



   ////////////////////////////////////////////////////////////////////////////////////////CONSTRUCTOR FUNCTION///////////////////////////////////////////////////////////////////////////////////////////
    
    // Make this contract address the owner of this contract
    // We have to make sure not even the deployer of this contract has access to any function of this contract
  

    constructor() public {
      owner = address(this) ;
      balanceOf[owner] = initialSupply ;
    }
    

      
      
      modifier onlyPayzusAdmin {
      
      require(msg.sender == payzusAdminAddress , 'Only Payzus Admin is allowed to call this function');
        _;
        
    }
    
    
    
       function setMintOctapayLockingAddress(address _addr) public onlyPayzusAdmin  {
         
         mintOctpayLockingAddr =  _addr;
        
    }
    
    
              
    
    ////////////////////////////////////////////////////////////////////////////////////////OCTAPAY MINTING FUNCTION///////////////////////////////////////////////////////////////////////////////////////////
    
    
    function mintOctapay (uint _mintBatchAmount) external returns (uint) {
        
        
      require(msg.sender == mintOctpayLockingAddr , 'Only the staking pool contract address set by Payzus Admin is allowed to call this mint octapay function' );
       
       
       
        require((currentSupply < totalSupply) && (maximumSupplyReached == false) , "Octapay reached its Maximum Supply");
        
        //currentSupply = initialSupply + _mintBatchAmount + currentSupply;
         currentSupply = (initialSupply).add(_mintBatchAmount).add(currentSupply);

         
         balanceOf[mintOctpayLockingAddr] = _mintBatchAmount ;    // this should turn to zero once current it distribute all its token
         
         
       
        if (currentSupply >= totalSupply ) {
            
            require(tokenBurningStart == false , 'Token Burning has already been triggered Cant be triggered twice');
          
            tokenBurningStart = true ;
            maximumSupplyReached = true ;
      
            burnOctapayFirstSlot();

        }
    }
    
    
    
     ////////////////////////////////////////////////////////////////////////////////////////OCTAPAY BURN FUNCTION///////////////////////////////////////////////////////////////////////////////////////////
    

    
    // Octapay token Burning Function ,Once Onctapay reaches its maximum Supply of  15000000 . 
    // Once Octapay reaches maximum Supply of 15000000 ,token burning of  total of Octapay  amount to  1,50,00000*20% = 3,000,000 ( where 20% is HOUSE_EDGE )  should be burnt in total
    // four slots ,or in other words in  gap of every 30days for next three months  (As first time Octapay will burn right at the very same time it reaches its maximum supply by automatically initiated by this smart contract) 
    //  of amount 25% Of 3,000,000 i.e. 750000.
    //  Next remaining (3000000−750000) 2250000 reserved tokens should be burned manually by Payzus Admin by invoking burnOctapayForNextThreeSlot() function three times in the gap of 30 days
    // this 3,000,000 is reserved Octapay contained and in access by this smart contract
    


    function burnOctapayFirstSlot () private   {
      
               require((tokenBurningCounter <= totalTokenBurninglot)  &&  (maximumSupplyReached = true) ,'All four slots of token birning acheived' );
                
                  if(octapayContractReserveTokenBalance > 0) {
                
                // octapayReserveBalFirstBurningSlot =   (octapayContractReserveTokenBalance*tokenBurningInOneSlot)/tokenBurningInOneSlotAccuracyRatio ;
                // octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance - octapayReserveBalFirstBurningSlot ;
                // totalSupply = totalSupply - (octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                
                
                 octapayReserveBalFirstBurningSlot =   (octapayContractReserveTokenBalance.mul(tokenBurningInOneSlot)).div(tokenBurningInOneSlotAccuracyRatio) ;
                 octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance.sub(octapayReserveBalFirstBurningSlot) ;
                 totalSupply = totalSupply.sub(octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
            
                 tokenBurningCounter = tokenBurningCounter+ 1;
                 firstSlotTokenBurningTime = now ;
                
                  }
   
          
      }
      
      
      
      
      //This function is allowed to call by only Payzus Admin Once Octapay Total Supply is reached and first slot of auto token burning has been completed 
      
          function burnOctapayForSecondSlot () public onlyPayzusAdmin returns(uint)   {
                
      
               require((now > firstSlotTokenBurningTime + 30 days) &&(tokenBurningCounter == 2 ) && (tokenBurningCounter <= totalTokenBurninglot) &&  (maximumSupplyReached = true) ,'All four slots of token birning acheived' );
                
                if(octapayContractReserveTokenBalance > 0) {
                    
                // octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance - octapayReserveBalFirstBurningSlot ;
                // totalSupply = totalSupply - (octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                
                octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance.sub(octapayReserveBalFirstBurningSlot) ;
                totalSupply = totalSupply.sub(octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                 
                 
                tokenBurningCounter = tokenBurningCounter+ 1;
                 secondSlotTokenBurningTime = now ;
                }
                
      }
      
      
        //This function is allowed to call by only Payzus Admin Once Octapay Total Supply is reached and second slot of manual token burning has been completed 
      
      
      
      
             function burnOctapayForThirdSlot () public onlyPayzusAdmin  returns(uint) {
                
          
          
      
                require((now > secondSlotTokenBurningTime + 30 days) && (tokenBurningCounter == 3 ) && (tokenBurningCounter <= totalTokenBurninglot) &&  (maximumSupplyReached = true) ,'All four slots of token birning acheived' );
                
                if(octapayContractReserveTokenBalance > 0) {
                    
                //  octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance - octapayReserveBalFirstBurningSlot ;
                //  totalSupply = totalSupply - (octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                
                  octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance.sub(octapayReserveBalFirstBurningSlot) ;
                  totalSupply = totalSupply.sub(octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                 
                  
                  tokenBurningCounter = tokenBurningCounter+ 1;
                  thirdSlotTokenBurningTime = now ;
                }
                
              
                
                
                
      }
      
      
      
      
       //This function is allowed to call by only Payzus Admin Once Octapay Total Supply is reached and third slot of manual token burning has been completed 
      
      
             function burnOctapayForFourthSlot () public onlyPayzusAdmin  returns(uint)  {
                
         
      
                require((now > thirdSlotTokenBurningTime + 30 days ) && (tokenBurningCounter == 4 ) && (tokenBurningCounter <= totalTokenBurninglot) &&  (maximumSupplyReached = true) ,'All four slots of token birning acheived' );
                
                if(octapayContractReserveTokenBalance > 0) {
                    
                //   octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance - octapayReserveBalFirstBurningSlot ;
                //   totalSupply = totalSupply - (octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                
                  octapayContractReserveTokenBalance  =  octapayContractReserveTokenBalance.sub(octapayReserveBalFirstBurningSlot) ;
                  totalSupply = totalSupply.sub(octapayReserveBalFirstBurningSlot *1000000000000000000) ; 
                    
                  tokenBurningCounter = tokenBurningCounter+ 1;
              
                }
                
              
                
                
      }

      
      
////////////////////////////////////////////////////////////////////////////////////////FALLBACK  FUNCTION///////////////////////////////////////////////////////////////////////////////////////////
      
      // fallback function as this contract is not designed to receive any sort of ether

     function() external  { 
       
     }
     
//////////////////////////////////////////////////////////////////////////////////////// ERC-20 Compatible Related Standard Function///////////////////////////////////////////////////////////////////////////////////////////// 

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}