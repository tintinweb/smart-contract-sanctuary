//SourceUnit: ZypExchane.sol

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
   
contract ZYPTRON_EXCHANGE is Ownable {
     using SafeMath for uint256;
   
    uint public token_price = 600;
    
 
	uint public  MINIMUM_BUY = 50 ;
	uint public  MINIMUM_SALE = 50;
	
    uint public  MAXIMUM_BUY = 600 ;
	uint public  MAXIMUM_SALE = 600;

	
	
    address public owner;
    
    event TokenDistribution(address sender, address receiver,string user_wallet, uint total_token, uint live_rate,string tr_type);
 
   ITRC20 private ZYPTRON; 
   event onBuy(address buyer , uint256 amount);

    constructor(address ownerAddress,ITRC20 _ZYPTRON) public 
    {
                 
        owner = ownerAddress;
        
        ZYPTRON = _ZYPTRON;
        
        Ownable.initialize(msg.sender);
    }
    
 
    function withdrawLostTRXFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
    
	 function buyToken(string memory _user,uint tokenQty) public payable {
					
	           require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");
	            require(tokenQty<=MAXIMUM_BUY,"Invalid maximum quatity");
	            uint trx_amt=((tokenQty+(tokenQty*2)/100)*(token_price)/1000)*1000000;
	            
	            require(msg.value>=trx_amt,"Invalid buy amount");
				ZYPTRON.transfer(msg.sender , (tokenQty*100000000));
				emit TokenDistribution(address(this), msg.sender,_user, tokenQty*100000000, token_price,'BUY');	
	
	}
	 
	function sellToken(string memory _user,address userAddress,uint tokenQty) public payable 
	{
	        require(tokenQty>=MINIMUM_SALE,"Invalid minimum quatity");
	            require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quatity");
	     
			uint trx_amt=((tokenQty-(tokenQty*3)/100)*(token_price)/100)*100000;
	        
			ZYPTRON.approve(userAddress,(tokenQty*1000000));
			ZYPTRON.transferFrom(userAddress ,address(this), (tokenQty*100000000));
			address(uint160(msg.sender)).send(trx_amt);
			emit TokenDistribution(userAddress,address(this),_user, tokenQty*100000000, token_price,'SELL');
			
	 }
	 
        function token_setting(uint min_buy, uint max_buy, uint min_sale, uint max_sale,uint256 token_price) public payable
        {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy ;
    	      MINIMUM_SALE = min_sale;
              MAXIMUM_BUY = max_buy;
              MAXIMUM_SALE = max_sale; 
			  token_price=token_price;
        }
        
		function withdrawLostTokenFromBalance(address payable _sender) public 
		{
        require(msg.sender == owner, "onlyOwner");
        ZYPTRON.transfer(owner,address(this).balance);
    	}
	
    
		
   
        }