//SourceUnit: cryptocashechange.sol

pragma solidity 0.5.4;

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
   
contract CRYPTOCASH_EXCHANGE is Ownable {
     using SafeMath for uint256;
  
    uint public token_price = 100;
    
    uint public  tbuy = 0;
	uint public  tsale = 0;
    uint public  vbuy = 0;
	uint public  vsale = 0;
	
	uint public  MINIMUM_BUY = 50 trx;
	uint public  MINIMUM_SALE = 50;
	
    uint public  MAXIMUM_BUY = 600 trx;
	uint public  MAXIMUM_SALE = 600;
	
	
    address public owner;
    
   
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
  
    
   //For Token Transfer
   
   ITRC20 private GLOBAL_EXCHANGE; 
   event onBuy(address buyer , uint256 amount);
   
   mapping(address => uint256) public boughtOf;

   
    function() external payable 
    {
        if(msg.data.length == 0) {
            return buyToken(0);
        }
        
        buyToken(0);
    }

   
   
    constructor(address ownerAddress,ITRC20 _GLOBALCASH_EXCHANGE) public 
    {
        
        owner = ownerAddress;
        GLOBAL_EXCHANGE = _GLOBALCASH_EXCHANGE;
        Ownable.initialize(msg.sender);
    }
     
    
	 function buyToken(uint tokenQty) public payable {
	     require(!isContract(msg.sender),"Can not be contract");
	            require(msg.value>=MINIMUM_BUY,"Invalid minimum quantity");
	            require(msg.value<=MAXIMUM_BUY,"Invalid maximum quantity");
	         
	            uint trx_amt=((tokenQty*token_price)/1000)*1000000;
	            require(msg.value>=trx_amt,"Invalid buy amount");
			    
				GLOBAL_EXCHANGE.transfer(msg.sender , (tokenQty*100000000));
				 emit TokenDistribution(address(this), msg.sender, tokenQty*100000000, token_price);	
			
	 }
	 
	function sellToken(address userAddress,uint tokenQty) public payable 
	{
	    
	    require(!isContract(userAddress),"Can not be contract");
	          require(tokenQty>=MINIMUM_SALE,"Invalid minimum quantity");
	            require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quantity");
	     	uint trx_amt=((tokenQty-(tokenQty*1)/100)*(token_price)/100)*100000;
	        
		
			GLOBAL_EXCHANGE.transferFrom(userAddress ,address(this),(tokenQty*100000000));
			address(uint160(msg.sender)).transfer(trx_amt);
			emit TokenDistribution(userAddress,address(this), tokenQty*100000000, token_price);
		
	 }
	 
	

        function token_setting(uint min_buy, uint max_buy, uint min_sale, uint max_sale,uint price) public payable
        {
           require(msg.sender==owner,"Only Owner");
			MINIMUM_BUY = min_buy*1 trx;
			  MINIMUM_SALE = min_sale;
			  MAXIMUM_BUY = max_buy*1 trx;
			  MAXIMUM_SALE = max_sale; 
			  token_price = price;
        }
        
  function withdrawLostTRXFromBalance() public payable{
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
         
	function setTokenPriceIncr(uint256 tron_price_new) public payable
	{
	  require(msg.sender==owner,"Only Owner Can Increase");
	 token_price=tron_price_new;
	}
	

	function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   	 
		 
   
}