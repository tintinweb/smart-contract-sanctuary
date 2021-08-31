//SourceUnit: main.sol

pragma solidity 0.5.4;

interface TRC20 {
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
   
contract DDCPRESALE{
    using SafeMath for uint256;
    struct User {
        uint id;
        uint256 selfBuy;
        uint256 selfSell;
    }    
    bool public saleOpen=true;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
   
    
    uint public lastUserId = 2;
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint8 public  priceIndex = 1;
	
	uint public  MINIMUM_BUY = 10*1e8;
	
	uint public  MINIMUM_SALE = 1e8;
    address public owner;
   

    mapping(uint8 => uint) public buyLevel;
    mapping(uint8 => uint) public MAXIMUM_BUY;
    mapping(uint8 => uint) public priceLevel;
    mapping(address => uint256) public boughtOf;
    
    event Registration(address indexed user,uint indexed userId);
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate,uint256 bnb_amount);
    event onBuy(address buyer , uint256 amount);
    
   //For Token Transfer
   
    TRC20 private ddcToken; 
   

    constructor(address ownerAddress,TRC20 _ddcToken) public 
    {
        owner = ownerAddress;
        ddcToken = _ddcToken;

        User memory user = User({
            id: 1,
            selfBuy: uint(0),
            selfSell: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    
        buyLevel[1]=10000*1e8;
        buyLevel[2]=25000*1e8;
        buyLevel[3]=0*1e8;
     
        priceLevel[1]=0*1e6;
        priceLevel[2]=0*1e6;
        priceLevel[3]=0*1e6;
        
        MAXIMUM_BUY[1]=100*1e8;
        MAXIMUM_BUY[2]=200*1e8;

    }
    
    function setpriceLevel(uint8 index,uint256 _price) public {
         priceLevel[index]=_price;
    }
    
   function setbuyLevelLevel(uint8 index,uint256 _buyprice) public {
        buyLevel[index]=_buyprice;
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender);
        }
        
        registration(msg.sender);
    }

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else
        ddcToken.transfer(msg.sender,amt);
    }

    function registrationExt() external payable 
    {
        registration(msg.sender );
    }
   
    function registration(address userAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        User memory user = User({
            id: lastUserId,
            selfBuy: 0,
            selfSell: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        
        lastUserId++;
        emit Registration(userAddress, users[userAddress].id);
    }
    
    
    function buyToken(uint tokenQty) public payable
	{    
	    
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(tokenQty<=MAXIMUM_BUY[priceIndex],"Invalid maximum quantity");

	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     uint256 buy_amt=calcBuyAmt(tokenQty);
	     require(msg.value>=buy_amt,"Invalid buy amount");
	     
	     (uint256 tokenAmount,uint256 newpriceGap, uint8 newpriceIndex)=calcBuyToken((msg.value));
	    
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenAmount;
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     ddcToken.transfer(msg.sender , tokenAmount);
	     
         total_token_buy=total_token_buy+tokenAmount;
		 emit TokenDistribution(address(this), msg.sender, tokenAmount, priceLevel[priceIndex],msg.value);					
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(saleOpen,"Sale Stopped.");
	    require(ddcToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(ddcToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        require(isUserExists(userAddress), "user is not exists. Register first.");
	   
	    (uint256 bnb_amt,uint256 newpriceGap, uint8 newpriceIndex)=calcSellAmt(tokenQty);
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     
		 ddcToken.transferFrom(userAddress ,address(this), (tokenQty));
		 address(uint160(msg.sender)).transfer((bnb_amt));
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],bnb_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }

	function calcBuyAmt(uint tokenQty) public view returns(uint256)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e8)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint8 i=newPriceIndex;
	        while(i<4 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=buyLevel[i])
	            {
	               uint256 _left=((buyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left/1e8)*priceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty/1e8)*priceLevel[i]);  
	               newPriceGap=newPriceGap+tokenQty;
	               tokenQty=0;
	            }
	            i++;
	        }
	    }
	    
	    return (amt);
	}
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint8)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;  
	    uint8 i=newPriceIndex; 
	    while(amount>0 && i<4)
	    {
	        if(i==4)
	        {
	            quatity=quatity+(amount/priceLevel[priceIndex]); //10000000+10
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(buyLevel[newPriceIndex]-newPriceGap)/1e8; //10
	            
	            uint256 LeftValue=(left*priceLevel[newPriceIndex]); //10 
	            
	            if(LeftValue>=amount) //10>=10
	            {
	                left=(amount/priceLevel[newPriceIndex]); //10
	                 quatity=quatity+(left*1e8);//10,000000
	                 amount=0;
	                 newPriceGap=newPriceGap+(left*1e8); //10,000000
	            }
	            else
	            {
	                 quatity=quatity+(left*1e8);
	                 amount=amount-LeftValue;  
	                 newPriceGap=0;
	            }
	        }
	        newPriceIndex++;
	        i++;
	    }
	    if(newPriceIndex>1)
	    newPriceIndex=newPriceIndex-1;
	     return (quatity,newPriceGap,newPriceIndex);
	}
	
	function calcSellAmt(uint tokenQty) public view returns(uint256,uint256,uint8)
	{
	    uint256 amt;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;
	    if(newPriceIndex==1)
	    {
	        amt=(tokenQty/1e8)*priceLevel[1];
	        if(tokenQty>=newPriceGap)
	        newPriceGap=0;
	        else
	        newPriceGap=newPriceGap-tokenQty;
	    }
	    else
	    {
	        uint8 i=newPriceIndex;
	        while(i>=1 && tokenQty>0)
	        {
	            if(newPriceGap>0)
	            {
	                uint256 _left;
	                if(newPriceGap>tokenQty)
	                _left=tokenQty;
	                else
	                _left=newPriceGap;
	                
	                amt=(_left/1e8)*priceLevel[newPriceIndex];
	                tokenQty=tokenQty-_left;
	                newPriceGap=newPriceGap-_left;
	            }
	            else
	            {
	                if(newPriceIndex>1)
	                {
	                    newPriceIndex--;
	                    i--;
	                }
	                if(buyLevel[i]>=tokenQty || newPriceIndex==1)
	                { 
	                    amt=(tokenQty/1e8)*priceLevel[newPriceIndex]; 
	                    if(buyLevel[newPriceIndex]>=tokenQty)
	                    newPriceGap=buyLevel[newPriceIndex]-tokenQty;
	                    else
	                    newPriceGap=0;
	                    tokenQty=0;
	                }
	                else
	                {
	                   amt=(buyLevel[newPriceIndex]/1e6)*priceLevel[newPriceIndex]; 
	                   tokenQty=tokenQty-buyLevel[newPriceIndex];
	                   newPriceGap=0; 
	                }
	                
	            }
	                
	            }
	        
	    }
	    
	    return (amt,newPriceGap,newPriceIndex);
	}
	
	function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint min_buy,  uint min_sale) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
             
    }
    
    function sale_setting(uint8 _type) public payable
    {
           require(msg.sender==owner,"Only Owner");
            if(_type==1)
            saleOpen=true;
            else
            saleOpen=false;
    }
    
   
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}