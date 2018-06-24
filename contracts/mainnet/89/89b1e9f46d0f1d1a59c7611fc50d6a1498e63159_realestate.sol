/**
 * @title smart real estate platform implementation
 * @author Maxim Akimov - <devstylesoftware@gmail.com>
 */
 
 // ver  from 23/06/2018  v0.3

pragma solidity ^0.4.24;


library SafeMath {
    
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
  
}

contract Ownable {
    
	address public owner;
	address public ownerCandidat;

	/**
	* @dev The Ownable constructor sets the original `owner` of the contract to the sender
	* account.
	*/
	 constructor() public{
		owner = msg.sender;
		
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	* @dev Allows the current owner to transfer control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function  transferOwnership(address newOwner) onlyOwner  public{
		require(newOwner != address(0));      
		ownerCandidat = newOwner;
	}
	/**
	* @dev Allows safe change current owner to a newOwner.
	*/
	function confirmOwnership() public{
		require(msg.sender == ownerCandidat);      
		owner = msg.sender;
	}

}

contract realestate is Ownable{
    
   using SafeMath for uint;
     
    enum statuses {
        created,canceled,signed,finished
    }
    
    struct _dealData{
    
    address buyer;
    address seller;
    address signer;
  
    uint sum; 
    uint fee;
    
    uint atCreated;
    uint atClosed;
    
    uint balance;
    
    statuses status;
    uint dealNumber;
    
    string comment;
    uint objectType; // 0 - old 1 - new
    
    uint date;
    bool isProlong;
}

struct _dealSigns{
   
    address signBuyer;
    address signSeller;
    
    address finishSignBuyer;
    address finishSignSeller;
    address finishSignSigner;
   
}

   event MoneyTransfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
 

 address public agencyOwner;
 address public agencyReceiver;

 _dealData[] private deals;
_dealSigns[] private signs;

 mapping (uint=>uint) private dealNumbers;
   
   // **************** modifiers **************** //
   
    modifier onlyAgency(){
        require(msg.sender == agencyOwner);
        _;
    }
    
    modifier onlySigner(uint _dealNumber){
        
        uint deal = dealNumbers[_dealNumber];
        require(msg.sender == deals[deal].signer);
        _;
    }
    
    constructor() public{
        
        agencyOwner = msg.sender;
        agencyReceiver = msg.sender;
    }
    
     /**
     * @dev Change eth address of agency for create deal 
     * @param _newAgency - new agency eth address
     */  
    function changeAgencyOwner(address _newAgency) public {
        require(msg.sender == agencyOwner || msg.sender == owner);
        agencyOwner = _newAgency;
         
     }
     
     /**
     * @dev Change eth address of agency for recieve fee
     * @param _agencyReceiver - new agency eth address
     */ 
     function changeAgencyReceiver (address _agencyReceiver) public{
         
        require(msg.sender == agencyOwner || msg.sender == owner);
        agencyReceiver = _agencyReceiver;
     }
     
     /**
     * @dev to prolongate a deal for some days
     * @param _dealNumber - uniq number of deal
     * @param _days - count of days from current time
     */ 
    function changeDealDate(uint _dealNumber, uint _days) onlyAgency public{
        
        uint deal = dealNumbers[_dealNumber];
        require(deals[deal].isProlong);
         
        deals[deal].date = now + _days * 1 days;
    }

    /**
     * @dev Get all signs of deal by _dealNumber
     * @param _dealNumber - uniq number of deal 
     */ 
    function getSigns(uint _dealNumber) constant public returns (
    address signBuyer, 
    address signSeller,
    address finishSignBuyer,
    address finishSignSeller,
    address finishSignSigner){
        
        uint deal = dealNumbers[_dealNumber];
        
        return (
                signs[deal].signBuyer,
                signs[deal].signSeller,
               
                signs[deal].finishSignBuyer,
                signs[deal].finishSignSeller,
                signs[deal].finishSignSigner
            );
        
    }
    
     /**
     * @dev Get main data of deal by _dealNumber
     * @param _dealNumber - uniq number of deal 
     */ 
    function getDealByNumber(uint _dealNumber) constant public returns (
    address buyer, 
    address sender, 
    address agency,
    uint sum, 
    uint atCreated,
    statuses status,
    uint objectType) {
         
         uint deal = dealNumbers[_dealNumber];
        
        return (
            deals[deal].buyer,
            deals[deal].seller,
            deals[deal].signer,
            deals[deal].sum,
            deals[deal].atCreated,
            deals[deal].status,
            deals[deal].objectType
            );
    }
    
    /**
     * @dev Get lenght of priviate array deals (for agency only)
     */ 
    function getDealsLength() onlyAgency  constant public returns (uint len){
        return deals.length;
    }
    
     /**
     * @dev Get main data of deal
     * @param deal - uniq id from priviate array deals 
     */ 
    function getDealById(uint deal) onlyAgency constant public returns (
    address buyer, 
    address sender, 
    address agency,
    uint sum, 
    uint atCreated,
    statuses status,
    uint objectType,
    uint dealID) {
         
        
        return (
            deals[deal].buyer,
            deals[deal].seller,
            deals[deal].signer,
            deals[deal].sum,
            deals[deal].atCreated,
            deals[deal].status,
            deals[deal].objectType,
            deal
            );
    }
    
    /**
     * @dev Get comment, fee, atCloced, date, is prolong of deal
     * @param _dealNumber - uniq number of deal 
     */ 
    function getDealDataByNumber(uint _dealNumber)  constant public returns (
    string comment, 
    uint fee, 
    uint atClosed,
    uint date,
    bool isProlong) {
       
         uint deal = dealNumbers[_dealNumber];
        
        return (
            deals[deal].comment,
            deals[deal].fee,
            deals[deal].atClosed,
            deals[deal].date,
            deals[deal].isProlong
            );
    }

   
    
     /**
    * @dev function for create deal by agency owner only
    * @param _buyer -  eth address of buyer
    * @param _seller -  eth address of seller
    * @param _signer -  eth address of signer (how cah canceled deal)
    * @param _sum -  sum of the deal (in wei)
    * @param _fee -  fee of the deal (in wei)
    * @param _objectType -  type of property (0 - old, 1 - new)
    * @param _dealNumber - uniq number of deal
    * @param _comment -  any text coment of the deal
    * @param whoPay -  point out who pay fee of the deal (0 - buyer, 1 - seller)
    * @param _countDays - Hoe many days allow for deal processing
    * @param _isProlong - Allow to prolongate deal, if true
    */
   function addDeal(
   address _buyer, 
   address _seller, 
   address _signer,
   uint _sum,
   uint _fee,
   uint _objectType, 
   uint _dealNumber, 
   string _comment,
   uint whoPay,
   uint _countDays,
   bool _isProlong) onlyAgency public{
      
      if(whoPay ==0){
        _sum = _sum.add(_fee);  
      }
     
      uint  newIndex = deals.length++; signs.length ++;
      
      deals[newIndex].buyer = _buyer;
      deals[newIndex].seller = _seller;
      deals[newIndex].signer = _signer;
      deals[newIndex].sum = _sum;
      deals[newIndex].fee = _fee;
      deals[newIndex].date = now + _countDays * 1 days;
      deals[newIndex].isProlong = _isProlong;
      deals[newIndex].atCreated = now;
      deals[newIndex].comment = _comment;
      deals[newIndex].status = statuses.created;
      deals[newIndex].balance = 0;
      deals[newIndex].objectType = _objectType;
      deals[newIndex].dealNumber = _dealNumber;
     
     dealNumbers[_dealNumber] = newIndex;
     
     signs[newIndex].signBuyer = 0x0;
     signs[newIndex].signSeller = 0x0;
     signs[newIndex].finishSignSeller = 0x0;
     signs[newIndex].finishSignBuyer = 0x0;
     signs[newIndex].finishSignSigner = 0x0;
     
     
   }
   
     /**
    * @dev function for sign deal by buyer and for transfer money  (call after sign seller only)
    * @param _dealNumber (deal number)
    */
   function signBuyer(uint _dealNumber) public payable{
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of buyer is mpty and sender it is buyer for this deal
       require(signs[deal].signBuyer == 0x0 && msg.sender == deals[deal].buyer);
       require(signs[deal].signSeller == deals[deal].seller);
       
       //Check, value of tx need >= summ of deal
       //TODO: need change maker!!!!
       require(deals[deal].sum == msg.value);
       
       signs[deal].signBuyer = msg.sender;
        deals[deal].balance =  msg.value;
       deals[deal].status = statuses.signed;
     
   }
   
    /**
    * @dev function for sign deal by seller (in start and before buyer)
    * @param _dealNumber (deal number)
    */
   function signSeller(uint _dealNumber) public {
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of seller is empty and sender it is seller for this deal
       require(signs[deal].signSeller == 0x0 && msg.sender == deals[deal].seller);
       signs[deal].signSeller = msg.sender;
   }
   
   // Agency sign
  /* function signAgency(uint _dealNumber) onlyAgency public {
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of Agency is empty and sender it is agency for this deal
       require(deals[deal].signAgency == 0x0);
       deals[deal].signAgency = msg.sender;
     
   }*/
   
   
   /**
    * @dev function for buyer (for mmoney refund after time of the deal)
    * @param _dealNumber (deal number)
    */
   function refund(uint _dealNumber) public{
       
       uint deal = dealNumbers[_dealNumber];
       require(now > deals[deal].date && deals[deal].balance > 0 && msg.sender == deals[deal].buyer);
       
       deals[deal].buyer.transfer(deals[deal].balance);
       
       deals[deal].balance = 0;
       
   }
   
   /**
    * @dev function for sign in end of the deal (for finis need 2 sign from 3)
    * @param _dealNumber (deal number)
    */
   function finishDeal(uint _dealNumber)  public{
       
       uint deal = dealNumbers[_dealNumber];
       
       require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed );
       
       //SIGNING.....
       
       if(msg.sender == deals[deal].buyer){
           signs[deal].finishSignBuyer = msg.sender;
       }
        
      if(msg.sender == deals[deal].seller){
           signs[deal].finishSignSeller = msg.sender;
       }
       if(msg.sender ==deals[deal].signer){
            signs[deal].finishSignSigner = msg.sender;
       }
       
       //////////////////////////
       
       
      uint signCount = 0;
       if(deals[deal].buyer == signs[deal].finishSignBuyer){
           signCount++;
       }
        if(deals[deal].seller == signs[deal].finishSignSeller){
           signCount++;
       }
        if(deals[deal].signer == signs[deal].finishSignSigner){
           signCount++;
       }
       
       if(signCount >= 2){
       
         //transfer fund to seller
          deals[deal].seller.transfer(deals[deal].sum - deals[deal].fee);
           
           emit MoneyTransfer(this,deals[deal].seller,deals[deal].sum-deals[deal].fee);
          
           //transer fund to agency (fee)
           agencyReceiver.transfer(deals[deal].fee);
           
           emit MoneyTransfer(this,agencyReceiver,deals[deal].fee);
           
           deals[deal].balance = 0;
           deals[deal].status = statuses.finished;
           deals[deal].atClosed = now;
       }
   }
   
   
   
   /**
    * @dev function for cancel deal (accessable ony for signer of current deal)
    * @param _dealNumber (deal number)
    */
    function cancelDeal(uint _dealNumber) onlySigner(_dealNumber) public{
       
        uint deal = dealNumbers[_dealNumber];
       
       require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed);
       
       deals[deal].buyer.transfer(deals[deal].balance);
       
       emit MoneyTransfer(this,deals[deal].buyer,deals[deal].balance);
       
       deals[deal].balance = 0;
       deals[deal].status = statuses.canceled;
       deals[deal].atClosed = now;
       
   }
}