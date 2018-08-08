/**
 * @title smart real estate platform implementation
 * @author Maxim Akimov - <devstylesoftware@gmail.com>
 */

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

/*
  пока не забыл -  контаркту "хранилице" нужно сделать несоклько владельцев
  что б можно было основной контаркт с бищнес логикой новый выпускать 
  (дажеесли в старом еще есть незакрытые сделки)
*/
contract realestate is Ownable{
    
   using SafeMath for uint;
     
    enum statuses {
        created,canceled,signed,finished
    }
    
    struct _sdeal{
    
    address buyer;
    address seller;
    address signer;
   // address agency;
    uint sum; 
    uint fee;
    
    address signBuyer;
    address signSeller;
   // address signAgency;
    uint atCreated;
    uint atClosed;
    
    uint balance;
    
    statuses status;
    uint dealNumber;
    
    string comment;
    uint objectType; // 0 - old 1 - new
}

struct _sSigns{
    
   address finishSignBuyer;
   address finishSignSeller;
   address finishSignSigner;
}

   event MoneyTransfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
 
   //Need to change to private
   
 //uint public feePercent; // нуно ли менять в процессе? 
 address public agencyOwner;
 address public agencyReceiver;

 _sdeal[] public deals;
_sSigns[] public signs;
 
   
   // **************** modifiers **************** //
   
    modifier onlyAgency(){
        require(msg.sender == agencyOwner);
        _;
    }
    
   /* modifier onlyDealMembers(uint _dealNumber){
        
        uint deal = dealNumbers[_dealNumber];
          require(msg.sender == deals[deal].buyer|| msg.sender == deals[deal].seller 
        || msg.sender == deals[deal].agency || msg.sender == deals[deal].signer);
        
        _;
    }*/
    
    modifier onlySigner(uint _dealNumber){
        
        uint deal = dealNumbers[_dealNumber];
        require(msg.sender == deals[deal].signer);
        _;
    }
    /*
    TODO
    сделать модификатор для всех ктоучавствует в сделки
    */
    
    constructor() public{
        
        //feePercent = 3;// need??
        agencyOwner = msg.sender;
        agencyReceiver = msg.sender;
    }
     
    function changeAgencyOwner(address newAgency) public {
            require(msg.sender == agencyOwner || msg.sender == owner);
         agencyOwner = newAgency;
         
     }
     function changeAgencyReceiver (address _agencyReceiver) public{
         
         require(msg.sender == agencyOwner || msg.sender == owner);
         agencyReceiver = _agencyReceiver;
     }
     
     //как много раз можно изменть ??
   /* function changeDealDate(uint _deal, uint _date) onlyAgency public{
         require(deals[_deal].isProlong);
         deals[_deal].date = _date;
    }*/

    function getSigns(uint _dealNumber) constant public returns (address signBuyer, 
    address signSeller){
        
        uint deal = dealNumbers[_dealNumber];
        
        return (
               deals[deal].signBuyer,
               deals[deal].signSeller
              // deals[deal].signAgency
            );
        
    }
    
    function getDealByNumber(uint _dealNumber) constant public returns (address buyer, 
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
    
    function getDealsLength() onlyAgency  constant public returns (uint len){
        return deals.length;
    }
    
    function getDealById(uint deal) onlyAgency constant public returns (address buyer, 
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
    
     function getDealDataByNumber(uint _dealNumber)  constant public returns 
     (string comment, 
    uint fee, 
    uint atClosed) {
       
         uint deal = dealNumbers[_dealNumber];
        
        return (
            deals[deal].comment,
            deals[deal].fee,
            deals[deal].atClosed
            );
    }

    mapping (uint=>uint) public dealNumbers;
    
   function addDeal(address buyer, address seller, address signer, uint sum, uint fee, uint objectType, uint _dealNumber, string comment, uint whoPay) onlyAgency public{
      
      /*
      objecType = 0 //  old
      objecType = 1 // new
       */ 
     //  feePercent = _feePercent;
      // sum = sum.mul(1 ether);
       //uint fee = sum.mul(feePercent).div(100);
      // fee = fee.mul(1 ether);
      
      //Кто приоритетнее objectType or WhoPay
      /*
      whopay = 0  // pay fee buyer
      whopay = 1  // pay fee seller
      */
      if(whoPay ==0){
        sum = sum.add(fee);  
      }
     
     /*  if(objectType == 0){
           //buyer pay fee. increase sum to  feePercent
            sum = sum.add(fee);
       }
      */
      
      uint  newIndex = deals.length++;
      signs.length ++;
      deals[newIndex].buyer = buyer;
      deals[newIndex].seller = seller;
       deals[newIndex].signer = signer;
     // deals[newIndex].agency = agencyOwner;
      deals[newIndex].sum = sum;
      deals[newIndex].fee = fee;
      //deals[newIndex].date = date;
     // deals[newIndex].isProlong = isProlong;
     
      deals[newIndex].atCreated = now;
      
      deals[newIndex].signBuyer = 0x0;
      deals[newIndex].signSeller = 0x0;
      deals[newIndex].comment = comment;
      deals[newIndex].status = statuses.created;
      //deals[newIndex].signAgency = 0x0;
      
      deals[newIndex].balance = 0;
      deals[newIndex].objectType = objectType;
     deals[newIndex].dealNumber = _dealNumber;
     
     dealNumbers[_dealNumber] = newIndex;
     
     signs[newIndex].finishSignSeller = 0x0;
     signs[newIndex].finishSignBuyer = 0x0;
     signs[newIndex].finishSignSigner = 0x0;
     
     
   }
   
   // Buyer sign
   function signBuyer(uint _dealNumber) public payable{
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of buyer is mpty and sender it is buyer for this deal
       require(deals[deal].signBuyer == 0x0 && msg.sender == deals[deal].buyer);
       require(deals[deal].signSeller == deals[deal].seller);
       
       //Check, value of tx need >= summ of deal
       //TODO: need change maker!!!!
       require(deals[deal].sum == msg.value);
       
       deals[deal].signBuyer = msg.sender;
        deals[deal].balance =  msg.value;
       deals[deal].status = statuses.signed;
     
   }
   
    // Seller sign
   function signSeller(uint _dealNumber) public {
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of seller is empty and sender it is seller for this deal
       require(deals[deal].signSeller == 0x0 && msg.sender == deals[deal].seller);
       deals[deal].signSeller = msg.sender;
   }
   
   // Agency sign
  /* function signAgency(uint _dealNumber) onlyAgency public {
       
       uint deal = dealNumbers[_dealNumber];
       
       //If sign of Agency is empty and sender it is agency for this deal
       require(deals[deal].signAgency == 0x0);
       deals[deal].signAgency = msg.sender;
     
   }*/
   
   
   //возарт после истечения срока
 /*  function refound(uint deal) public{
       
       require(now > deals[deal].date && deals[deal].isProlong == false && deals[deal].balance > 0);
       
       //или все таки возврат делать покупателю!!???
       deals[deal].agency.transfer(deals[deal].balance);
       balances[deals[deal].buyer] = 0;
       deals[deal].balance = 0;
       
   }*/
   
   /*
   
   function finishSign(uint _dealNumber) public{
       
        uint deal = dealNumbers[_dealNumber];
        
          require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed );
       
       if(msg.sender == deals[deal].buyer){
           signs[deal].finishSignBuyer = msg.sender;
       }
        
      if(msg.sender == deals[deal].seller){
           signs[deal].finishSignSeller = msg.sender;
       }
       if(msg.sender ==deals[deal].signer){
            signs[deal].finishSignSigner = msg.sender;
       }
       
   }*/
   
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
   
   
   // нужно ли тут расчиывать коммисию???
    function cancelDeal(uint _dealNumber) onlySigner(_dealNumber) public{
       
        uint deal = dealNumbers[_dealNumber];
       
       require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed);
       
       deals[deal].buyer.transfer(deals[deal].balance);
       
       //emit MoneyTransfer(this,deals[deal].buyer,deals[deal].balance);
       
       deals[deal].balance = 0;
       deals[deal].status = statuses.canceled;
       deals[deal].atClosed = now;
       
   }
}