/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

pragma solidity 0.5.4;

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
   
contract INZSWAP {
     using SafeMath for uint256;
  
    uint public token_price = 500;
    
    uint public  tbuy  =  0;
	uint public  tsale =  0;
    uint public  vbuy  =  0;
	uint public  vsale =  0;
	
	uint public  MINIMUM_BUY  =  50;
	uint public  MINIMUM_SALE =  50;
	
    uint public  MAXIMUM_BUY  = 5000;
	uint public  MAXIMUM_SALE = 5000;
	
	
    address public owner;
    
   
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
  
    
   //For Token Transfer
   
   ITRC20 private INZ; 
   event onBuy(address buyer , uint256 amount);
   
   mapping(address => uint256) public boughtOf;

   
    function() external payable 
    {
        if(msg.data.length == 0) {
            return buyToken(0);
        }
        
        buyToken(0);
    }

   
   
    constructor(address ownerAddress,ITRC20 _INZ) public 
    {
        
        owner = ownerAddress;
        INZ = _INZ;
        // Ownable.initialize(msg.sender);
    }
     
    
	 function buyToken(uint tokenQty) public payable {
	        require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	        require(tokenQty<=MAXIMUM_BUY,"Invalid maximum quantity");
	         
	        uint trx_amt=((tokenQty*token_price)/1000)*1000000;
	        require(msg.value>=trx_amt,"Invalid buy amount");
			
			INZ.transfer(msg.sender , (tokenQty*100000000));
			emit TokenDistribution(address(this), msg.sender, tokenQty*100000000, token_price);	
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	        require(tokenQty>=MINIMUM_SALE,"Invalid minimum quantity");
	        require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quantity");
	     	uint trx_amt=((tokenQty*(token_price/1000)))*1000000;
	     	
			INZ.transferFrom(msg.sender ,address(this),(tokenQty*100000000));
			msg.sender.transfer(trx_amt);
			emit TokenDistribution(msg.sender,address(this), tokenQty*100000000, token_price);
			//vsale=vsale+tokenQty;
			tsale=tsale+tokenQty;
// 			if(vsale>=2000)
//             {
//                 //uint 
//                 if(token_price>1000)
//                 {
//                 emit TokenPriceHistory(token_price,10, token_price-10, 0); 
//                 token_price=token_price-10;
//                 vsale=vsale-2000;
//                 }
//             }
	 }
	 
	

        function token_setting(uint min_buy, uint max_buy, uint min_sale, uint max_sale) public payable
        {
           require(msg.sender==owner,"Only Owner");
            MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
            MAXIMUM_BUY = max_buy ;
            MAXIMUM_SALE = max_sale; 
        }
        

         
		
		  
   
}