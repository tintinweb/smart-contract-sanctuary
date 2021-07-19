/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// busd token= 0xcf1aecc287027f797b99650b1e020ffa0fb0e248
// btf token= 0xcd3d2e9f6cab548d277a1dc0f63fa845a7f6436b
pragma solidity 0.5.4;

interface IBEP20 {
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
   
contract GBAX  
{
     using SafeMath for uint256;


    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 selfBuy;
        uint256 selfSell;
    }
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    uint256[] public refPercent=[50,25,15,10];

    
    
    
    uint256 public  total_token_buy = 0;
	uint256 public  total_token_sale = 0;
	uint256 public  apriceGap = 0;
	uint256 public  apriceIndex = 1;
	uint256 public  priceGap = 0;
	uint256 public  priceIndex = 1;
	uint256 public  tokenPerSlot=5000*1e18;
	
	uint public  MINIMUM_BUY = 1e18;
	uint public  MINIMUM_SALE = 1e17;
	
    address public owner;
    
    mapping(uint256 => uint) public buyLevel;
    mapping(uint256 => uint) public priceLevel;
    
    mapping(uint256 => uint) public abuyLevel;
    mapping(uint256 => uint) public apriceLevel;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
   
    
   //For Token Transfer
   
   IBEP20 private gabxToken; 
   IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _gabxToken) public 
    {
        owner = ownerAddress;
        
        gabxToken = _gabxToken;
        busdToken = _busdToken;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome: uint(0),
            levelIncome: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        abuyLevel[1]=50000*1e18;
        apriceLevel[1]=5*1e15;
        
        abuyLevel[2]=17500*1e18;
        apriceLevel[2]=7*1e15;
        
        abuyLevel[3]=25000*1e18;
        apriceLevel[3]=1*1e16;
        
        abuyLevel[4]=65000*1e18;
        apriceLevel[4]=125*1e14;
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        busdToken.transfer(msg.sender,amt);
        else
        gabxToken.transfer(msg.sender,amt);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
   
    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            refIncome: 0,
            levelIncome: 0,
            selfBuy: 0,
            selfSell: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    
    
    function _buyToken(address user,uint256 tokenQty,address referrer) public payable
	{
	     require(msg.sender==owner,"Only Owner");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     (uint256 buy_amt,uint256 newpriceGap, uint256 newpriceIndex)=acalcBuyAmt(tokenQty);
	     require(busdToken.balanceOf(owner)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(owner,address(this))>=buy_amt,"Invalid buy amount");
	     
	     if(!isUserExists(user))
	     {
	       registration(user, referrer);   
	     }
	     require(isUserExists(user), "user not exists");
	     
	     users[user].selfBuy=users[user].selfBuy+tokenQty;
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     busdToken.transferFrom(user,address(this), (buy_amt));
	     gabxToken.transfer(user, tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), user, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
    

    function buyToken(uint256 tokenQty,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     (uint256 buy_amt,uint256 newpriceGap, uint256 newpriceIndex)=calcBuyAmt(tokenQty);
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     gabxToken.transfer(msg.sender , tokenQty);
	     
	     if(msg.sender!=owner)
	     _calculateReferrerReward(tokenQty,users[msg.sender].referrer);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(saleOpen || users[userAddress].selfSell<(users[userAddress].refIncome+users[userAddress].levelIncome),"Sale Stopped.");
	    require(gabxToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(gabxToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        
	    
	    uint256 busd_amt=(tokenQty/1e18)*priceLevel[priceIndex];
	     
		 gabxToken.transferFrom(userAddress ,address(this), (tokenQty));
		 busdToken.transfer(userAddress ,busd_amt);
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],busd_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }
	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	     for(uint8 i=0;i<4;i++)
	     {
	         if(i==0)
	         users[_referrer].refIncome=users[_referrer].refIncome+(_investment*refPercent[i])/1000;
	         else
	         users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment*refPercent[i])/1000;
            gabxToken.transfer(_referrer,(_investment*refPercent[i])/1000); 
            if(users[_referrer].referrer!=address(0))
            _referrer=users[_referrer].referrer;
            else
            break;
	     }
     }
	
	function acalcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint256)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint256 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint256 i=newPriceIndex;
	        while(i<101 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=buyLevel[i])
	            {
	               uint256 _left=((buyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left/1e18)*priceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty/1e18)*priceLevel[i]);  
	               newPriceGap=newPriceGap+tokenQty;
	               tokenQty=0;
	            }
	            i++;
	        }
	    }
	    
	    return (amt,newPriceGap,newPriceIndex);
	}
	
	function acalcBuyToken(uint256 amount) public view returns(uint256,uint256,uint256)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint256 newPriceIndex=priceIndex;  
	    uint256 i=newPriceIndex; 
	    while(amount>0 && i<101)
	    {
	        if(i==100)
	        {
	            quatity=quatity+(amount/priceLevel[newPriceIndex]);
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(buyLevel[newPriceIndex]-newPriceGap)/1e18;
	            
	            uint256 LeftValue=(left*priceLevel[newPriceIndex]);
	            
	            if(LeftValue>=amount)
	            {
	                left=(amount/priceLevel[newPriceIndex]);
	                 quatity=quatity+(left*1e18);
	                 amount=0;
	                 newPriceGap=newPriceGap+(left*1e18);
	            }
	            else
	            {
	                 quatity=quatity+(left*1e18);
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
	
	
	function calcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint256)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint256 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint256 i=newPriceIndex;
	        while(i<101 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=buyLevel[i])
	            {
	               uint256 _left=((buyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left/1e18)*priceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty/1e18)*priceLevel[i]);  
	               newPriceGap=newPriceGap+tokenQty;
	               tokenQty=0;
	            }
	            i++;
	        }
	    }
	    
	    return (amt,newPriceGap,newPriceIndex);
	}
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint256)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint256 newPriceIndex=priceIndex;  
	    uint256 i=newPriceIndex; 
	    while(amount>0 && i<101)
	    {
	        if(i==100)
	        {
	            quatity=quatity+(amount/priceLevel[newPriceIndex]);
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(buyLevel[newPriceIndex]-newPriceGap)/1e18;
	            
	            uint256 LeftValue=(left*priceLevel[newPriceIndex]);
	            
	            if(LeftValue>=amount)
	            {
	                left=(amount/priceLevel[newPriceIndex]);
	                 quatity=quatity+(left*1e18);
	                 amount=0;
	                 newPriceGap=newPriceGap+(left*1e18);
	            }
	            else
	            {
	                 quatity=quatity+(left*1e18);
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