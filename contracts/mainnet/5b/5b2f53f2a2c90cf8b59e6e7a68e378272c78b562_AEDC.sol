/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity  ^0.4.0 ;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
  
library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

//   function assert(bool assertion) internal {
//     if (!assertion) {
//       throw;
//     }
//   }
}
  
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
 contract Ownable {
    address public owner;
    mapping (address =>  bool) public admins;

    function owned() public {
        owner = msg.sender;
        admins[msg.sender]=true;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Caller is not the owner");
        _;
    }
     modifier onlyAdmin   {
        require(admins[msg.sender] == true,"Caller is not the admin");
        _;
    }

    // function transferOwnership(address newOwner) onlyOwner public {
    //     owner = newOwner;
    // }
     function makeAdmin(address newAdmin, bool isAdmin) onlyOwner public{
        admins[newAdmin] = isAdmin;
    }
}
  
 
contract ERC20Basic{
    uint256 public totalSupply_; 
    string public  name  ;
    string public   symbol ;
    uint8 public constant decimals = 18;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
     
     
    using SafeMath for uint256;
  
   /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
     
    function totalSupply() public   view returns (uint256 ) {
    return totalSupply_;
    }

    function balanceOf(address owner_) public  view returns (uint256 ) {
        return (balances[owner_]);
    }



    function approve(address delegate, uint256 amount) public   returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner_, address delegate) public   view returns (uint256) {
        return allowed[owner_][delegate];
    }

   
   
} 
contract BlackList is Ownable, ERC20Basic {
    
     mapping (address => bool) public isBlackListed; 
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded AEDC) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    } 
    function getOwner() external view returns (address) {
        return owner;
    } 
    function addBlackList (address _evilUser) public onlyAdmin {
        isBlackListed[_evilUser] = true;
       emit AddedBlackList(_evilUser);
    } 
    function removeBlackList (address _clearedUser) public onlyAdmin {
        isBlackListed[_clearedUser] = false;
       emit RemovedBlackList(_clearedUser);
    } 
    function destroyBlackFunds (address _blackListedUser) public onlyAdmin {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply_ =totalSupply_.safeSub(dirtyFunds);
       emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

  
 
 /******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract AEDC is  BlackList {
    uint256 public totalIcoSupply;
    uint256  buyPrice;
    uint256  buyBackPrice; 
    uint256  icoBuyPrice; 
    uint256  transactionFee;  
    uint256  icoStartTime;
    uint256  icoEndTime;
    mapping(address => uint256) icoBalances;
    event TransferICO(address indexed from, address indexed to, uint256 value); // transfer ico  
    event IcoWithdrawn(address indexed owner_ , uint256 value,  uint256 time); // generates event when ico holder convert into AEDC coin 
    event Withdrawn(address indexed _to, uint256 value);// transfer balance to owner 
    event Issue(uint256 amount);// Called when new token are issued 
    event Redeem(uint256 amount); // Called when tokens are redeemed 
    event BuyPrice(uint256 value); // generates event on chenge coin buy price from ETH
    event BuyBackPrice(uint256 value);// generates event on chenge coin sell price in ETH
    event IcoBuyPrice(uint256 value); // generates event on chenge ico buy price from ETH
    event Bought(uint256 amount);
    event BoughtICO(uint256 amount);
    event Sold(uint256 amount);
    /* Initializes contract with initial supply tokens to the creator of the contract */ 
    constructor(uint256  initialSupply,uint256 icoInitialSupply,string memory tokenName, string memory tokenSymbol,uint256 icoSatrtTime_,uint256 icoEndTime_,uint256 buyPrice_,uint256 buyBackPrice_,uint256 icoBuyPrice_,uint256 transactionFee_) public {
        owned() ;
        totalSupply_ = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        totalIcoSupply = icoInitialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[this] = totalSupply_;                // Give the creator all initial tokens 
        icoBalances[this] = totalIcoSupply;          // Give the creator all initial ico Coins
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        icoStartTime = icoSatrtTime_; // start ico   
        icoEndTime = icoEndTime_;    
        buyPrice = buyPrice_;
        buyBackPrice = buyBackPrice_;
        icoBuyPrice = icoBuyPrice_;
        transactionFee = transactionFee_;
      } 
      
    using SafeMath for uint256;
      
    /* Internal transfer  ICO, only can be called by this contract */
    function _transferICO(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);      // Prevent transfer to 0x0 address. Use burn() instead
        require (icoBalances[_from] >= _value ,"Don't have enough ICO  balances.");               // Check if the sender has enough
        require ( (icoBalances[_to] + _value) > icoBalances[_to]); // Check for overflows
        require(!isBlackListed[_from],"Sender is black Listed");                     // Check if sender is isBlackListed
        require(!isBlackListed[_to],"Recipient is black listed");                       // Check if recipient is isBlackListed
        icoBalances[_from] = icoBalances[_from].safeSub( _value);                         // Subtract from the sender
        icoBalances[_to] = icoBalances[_to].safeAdd( _value);                           // Add the same to the recipient
        emit TransferICO(_from, _to, _value);
    } 
      /* Transfer ICO Coins from other address By owner */
    function transferICO( address _to, uint256 _value)  public  returns (bool success) {  
        _transferICO(msg.sender, _to, _value);
        return true;
    }
      /* Transfer ICO Coins from other address By owner */
    function transferICOFrom(address _from, address _to, uint256 _value) onlyAdmin public  returns (bool success) {  
        require (icoBalances[_from] >=  (_value+transactionFee),"Don't have enough ICO balances.");
        icoBalances[_from] = icoBalances[_from].safeSub(transactionFee);// Subtract from the targeted balance 
        icoBalances[this] = icoBalances[this].safeAdd(transactionFee); //return tokens to owner 
        _transferICO(_from, _to, _value);
        return true;
    }
     
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value,"Don't have enough balances.");               // Check if the sender has enough
        require ( (balances[_to] + _value) > balances[_to]); // Check for overflows
        require(!isBlackListed[_from],"Sender  is black listed");                     // Check if sender is isBlackListed
        require(!isBlackListed[_to],"Recipient is black listed");                       // Check if recipient is isBlackListed
        balances[_from] = balances[_from].safeSub( _value);                         // Subtract from the sender
        balances[_to] = balances[_to].safeAdd( _value);                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    } 
    
     function sell_(uint256 amount) internal  {
        require(!isBlackListed[msg.sender],"Sender is black listed");                     // Check if sender is black listed
        require(balances[msg.sender] >= amount,"You need to sell at least some AEDC");         // checks if the sender has enough to sell
        uint256 revenue=amount.safeMul(buyBackPrice);
        revenue=revenue.safeDiv(10 ** uint256(decimals));
        require(revenue<=address(this).balance,"Not enough ether balance in the reserve to Buy AEDC");
        balances[this] = balances[this].safeAdd(amount)  ;                       // adds the amount to owner's balance
        balances[msg.sender] = balances[msg.sender].safeSub(amount);             // subtracts the amount from seller's balance
        msg.sender.transfer(revenue); 
        emit Sold(amount);              // executes an event reflecting on the change
                                            // ends function and returns
    }
    
    // transfer coin 
     function transfer( address _to, uint256 _value)  public  returns (bool) { 
         
         if( _to==address(this))
         {
            sell_(_value); 
            emit Transfer(msg.sender, this, _value);
            
         }
         else 
         {
              _transfer(msg.sender, _to, _value);
         }
       
        return true;
    } 
     function transferFrom(address owner_, address buyer, uint256 amount_) public   returns (bool) {
        require(amount_ <= balances[owner_],"Don't have enough balances.");
        require(amount_ <= allowed[owner_][msg.sender]);  
        allowed[owner_][msg.sender] = allowed[owner_][msg.sender].safeSub(amount_); 
        _transfer(owner_, buyer, amount_); 
        return true;
    }
    
   /** * Transfer Coins from other address By owner  */
    function transferCoinFrom(address _from, address _to, uint256 _value) onlyAdmin public  returns (bool success) {  
        require (balances[_from] >=  (_value+transactionFee),"Don't have enough balances.");
        balances[_from] = balances[_from].safeSub(  transactionFee);// Subtract from the targeted balance 
        balances[this] =balances[this].safeAdd(transactionFee); 
        _transfer(_from, _to, _value);
        return true;
    }
     /* Internal ico Withdrawn, only can be called by this contract */
    function _icoWithdrawn(address owner_, uint256 _value) internal {
        require( block.timestamp >=icoEndTime,"ICO Withdrawn not allowed"); 
        require (icoBalances[owner_] >= _value,"Don't have enough ICO balances.");               // Check if the sender has enough
        require ( (balances[owner_] + _value) > balances[owner_]); // Check for overflows
        require(!isBlackListed[owner_],"Owner is black listed ");                     // Check if sender is isBlackListed  
        icoBalances[owner_] =  icoBalances[owner_].safeSub( _value);                         // Subtract from the sender
        totalIcoSupply=totalIcoSupply.safeSub(_value);  // subtract from total ico supply 
        _transfer(address(this), owner_, _value); // transer ADEC coin from contract to address 
        emit IcoWithdrawn(owner_, _value, block.timestamp);
    } 

   // Ico Withdrawn by AEDC
     function icoWithdrawn(  uint256 _value)  public  returns (bool) { 
        _icoWithdrawn(msg.sender, _value);
        return true;
    } 
    // ico Withdrawn
     function icoWithdrawnFrom(address owner_, uint256 _value) onlyAdmin public   returns (bool) { 
        require (icoBalances[owner_] >=  (_value+transactionFee),"Don't have enough ICO balances.");
        icoBalances[owner_] = icoBalances[owner_].safeSub(  transactionFee);// Subtract from the targeted balance 
        totalIcoSupply=totalIcoSupply.safeSub(transactionFee); 
        _icoWithdrawn(owner_, _value);
        return true;
    }

    
    /// @notice Allow users to buy tokens for `newBuyPrice`  
    /// @param newBuyPrice Price users can buy from the contract denominator
    function setBuyPrices( uint256 newBuyPrice) internal { 
        buyPrice = newBuyPrice; 
        emit BuyPrice(newBuyPrice);
    }
    /// @notice Allow users to sell tokens for `newBuyBackPrice`  
    /// @param newBuyBackPrice Price users can buy from the contract denominator
    function setBuyBackPrices( uint256 newBuyBackPrice) internal {
        buyBackPrice = newBuyBackPrice; 
        emit BuyBackPrice(newBuyBackPrice);
    }
      /// @notice Allow owner to Set Per tokens Transfer Fee  
    /// @param _transactionFee Price users pay on token transfer 
    function setTransactionFees( uint256 _transactionFee) internal {
        transactionFee =_transactionFee ;
    }
     
    function setPrices(uint256 newBuyPrice,uint256 newBuyBackPrice, uint256 newTransationFee) onlyAdmin public{
        require(newBuyPrice>0);
        require(newBuyBackPrice>0);
        require(newTransationFee>0);
      setBuyPrices(newBuyPrice);  
      setBuyBackPrices(newBuyBackPrice);
      setTransactionFees(newTransationFee);
    
    }
     function setIcoBuyPrices( uint256 newIcoBuyPrice) onlyAdmin public {
         require(newIcoBuyPrice>0);
        icoBuyPrice = newIcoBuyPrice; 
        emit IcoBuyPrice(newIcoBuyPrice);
    }
   
    
    function setIcoTimePeriod( uint256 _icoStartTime,uint256 _icoEndTime) onlyAdmin public {
        require(_icoStartTime>0);
        require(_icoEndTime>0);
        icoStartTime=_icoStartTime;
        icoEndTime=_icoEndTime;
    }
    
    /// @notice Buy tokens from contract by sending ether
    function buy() payable public returns (uint256 amount){
        require(msg.value > 0, "You need to send some Ether");
        amount =  msg.value.safeMul(10 ** uint256(decimals)); 
        amount= amount.safeDiv(buyPrice);  // calculates the  amount
        require(balanceOf(this)>=amount,"Not enough balance in the reserve to sell") ;//// checks if it has enough to sell  
        balances[msg.sender] = balances[msg.sender].safeAdd(amount);    // adds the amount to buyer's balance
        balances[this] = balances[this].safeSub(amount);     // subtracts amount from seller's balance
        emit Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }
     /// @notice Buy tokens from contract by sending ether
    function buyICO() payable public returns (uint256 amount){
        require(now <= icoEndTime,"Ico purchase not allowed");
        require(msg.value > 0, "You need to send some Ether");
         amount =  msg.value.safeMul(10 ** uint256(decimals)); 
         amount= amount.safeDiv(icoBuyPrice);  // calculates the  amount 
         require(icoBalances[this]>=amount,"Not enough ICO balance in the reserve to sell") ;//// checks if it has enough to sell  
        icoBalances[msg.sender] = icoBalances[msg.sender].safeAdd(amount);    // adds the amount to buyer's balance
        icoBalances[this] = icoBalances[this].safeSub(amount);     // subtracts amount from seller's balance
        emit TransferICO(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }
    
    // Sell token on behalf of admins
    // function  buyBackFrom(address _from,uint256 amount) onlyAdmin public returns (uint256 revenue){
    //     require(!isBlackListed[_from],"Sender is black listed");                     // Check if sender is frozen
    //     require(balances[_from] >= amount*10 ** uint256(decimals) +transactionFee,"Sender has not enough amount to sell");         // checks if the sender has enough to sell
    //     balances[this] += amount*10 ** uint256(decimals) ;                       // adds the amount to owner's balance
    //     balances[_from] -= amount*10 ** uint256(decimals) +transactionFee;            // subtracts the amount from seller's balance
    //     revenue =  amount*buyBackPrice;
    //     _from.transfer(revenue); 
    //     emit  Transfer(_from, this, amount*10 ** uint256(decimals));               // executes an event reflecting on the change
    //     return revenue;                                   // ends function and returns
    // } 
    
     // Sell token on behalf of admins
    function  buyBackFrom(uint256 amount)  onlyAdmin public returns (uint256 revenue){
        require(!isBlackListed[msg.sender],"Sender is black listed");                     // Check if sender is black listed
        require(balances[msg.sender] >= amount +transactionFee,"You need to sell at least some AEDC");         // checks if the sender has enough to sell
        revenue=amount.safeMul(buyBackPrice);
        revenue=revenue.safeDiv(10 ** uint256(decimals));
        require(revenue<=address(this).balance,"Not enough ether balance in the reserve to Buy AEDC");
        balances[this] = balances[this].safeAdd(amount)  ; 
        balances[this] = balances[this].safeAdd(transactionFee)  ; // adds the amount to owner's balance
        balances[msg.sender] = balances[msg.sender].safeSub(amount);             // subtracts the amount from seller's balance
        balances[msg.sender] = balances[msg.sender].safeSub(transactionFee);  
        msg.sender.transfer(revenue); 
        emit Sold(amount);              // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    } 
    
    function sell(uint256 amount) public returns (uint256 revenue){
        require(!isBlackListed[msg.sender],"Sender is black listed");                     // Check if sender is black listed
        require(balances[msg.sender] >= amount,"You need to sell at least some AEDC");         // checks if the sender has enough to sell
        revenue=amount.safeMul(buyBackPrice);
        revenue=revenue.safeDiv(10 ** uint256(decimals));
        require(revenue<=address(this).balance,"Not enough ether balance in the reserve to Buy AEDC");
        balances[this] = balances[this].safeAdd(amount)  ;                       // adds the amount to owner's balance
        balances[msg.sender] = balances[msg.sender].safeSub(amount);             // subtracts the amount from seller's balance
        msg.sender.transfer(revenue); 
        emit Sold(amount);              // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }
      
      
      
    // transfer ether to admins
	function withdrawEther(uint256 amount) onlyAdmin public {
	    require(admins[msg.sender]==true,"");  
	    msg.sender.transfer(amount);
	    emit  Withdrawn(msg.sender, amount);
		
	} 
	 // transfer balance to owner
	function withdrawEtherToOwner(uint256 amount) onlyOwner public {
		require(msg.sender == owner);
		msg.sender.transfer(amount);
	}
	 	// can accept ether
	function() public payable { 
	    require(msg.value > 0, "You need to send some Ether");
        uint256 amount =  msg.value.safeMul(10 ** uint256(decimals)); 
        amount= amount.safeDiv(buyPrice);  // calculates the  amount
        require(balanceOf(this)>=amount,"Not enough balance in the reserve to sell") ;//// checks if it has enough to sell  
        balances[msg.sender] = balances[msg.sender].safeAdd(amount);    // adds the amount to buyer's balance
        balances[this] = balances[this].safeSub(amount);     // subtracts amount from seller's balance
        emit Transfer(this, msg.sender, amount);               // execute an event reflecting the change
 
    } 
   function TranserEtherToContract() payable public  {
           
    }
	  
	  // get ico balance
	  function icoBalanceOf(address owner_) public  view returns (uint256) {
        return icoBalances[owner_];
    }
	  
	 // get buyPrice
	function getBuyPrice() public   view returns (uint256) {
        return buyPrice;
    }
	 // get buyBackPrice
	function getBuyBackPrice() public   view returns (uint256) {
        return buyBackPrice;
    }
	 // get transaction Fee
	   function getTransactionFee() public   view returns (uint256) {
        return transactionFee;
    }
	 // get icoBuyPrice
	function getIcoBuyPrice() public   view returns (uint256) {
        return icoBuyPrice;
    }
	 
    function getTotalIcoSupply() public   view returns (uint256) {
        return totalIcoSupply;
    }
    function getIcoStartTime() public view returns(uint256)
	{
		return icoStartTime;
	} 
	 function getIcoEndTime() public view returns(uint256)
	{
		return icoEndTime;
	} 
	function getIcoTimePeriod() public view returns(uint256)
	{
		return icoEndTime.safeSub(icoStartTime);
	} 
      
	function TimeNow() public view returns(uint256)
	{
		return now;
	}
 
}