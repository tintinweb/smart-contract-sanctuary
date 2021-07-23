/**
 *Submitted for verification at BscScan.com on 2021-07-23
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
   
contract GABX  
{
     using SafeMath for uint256;


    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 selfBuy;
        uint256 selfBuyUsd;
        uint256 directBusiness;
    }
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint8 => mapping(uint8 => uint256)) public refPercent;
    
    uint public lastUserId = 2;
    
    uint256 public  total_token_buy = 0;
	uint256 public  apriceGap = 0;
	uint256 public  apriceIndex = 1;
	uint256 public  priceGap = 0;
	uint256 public  priceIndex = 1;
	uint256 public  tokenPrice = 15*1e15;
	uint256 public  amountPerSlot=5000*1e18;
	
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
            selfBuyUsd:uint(0),
            directBusiness:uint(0)
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
        
        refPercent[1][1]=50;
        
        refPercent[2][1]=60;
        refPercent[2][2]=30;
        refPercent[2][3]=20;
        refPercent[2][4]=10;
        refPercent[2][5]=10;
        
        refPercent[3][1]=70;
        refPercent[3][2]=30;
        refPercent[3][3]=20;
        refPercent[3][4]=10;
        refPercent[3][5]=10;
        
        refPercent[4][1]=80;
        refPercent[4][2]=40;
        refPercent[4][3]=30;
        refPercent[4][4]=20;
        refPercent[4][5]=10;
        
        refPercent[5][1]=90;
        refPercent[5][2]=40;
        refPercent[5][3]=30;
        refPercent[5][4]=20;
        refPercent[5][5]=10;
        
        refPercent[6][1]=100;
        refPercent[6][2]=50;
        refPercent[6][3]=40;
        refPercent[6][4]=30;
        refPercent[6][5]=20;
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
            selfBuyUsd:0,
            directBusiness:0
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
	     if(!isUserExists(user))
	     {
	       registration(user, referrer);   
	     }
	     require(isUserExists(user), "user not exists");
	     
	     users[user].selfBuy=users[user].selfBuy+tokenQty;
	     users[user].selfBuyUsd=users[user].selfBuyUsd+buy_amt;
	     apriceGap=newpriceGap;
	     apriceIndex=newpriceIndex;
	     gabxToken.transfer(user, tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), user, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
    

    function buyToken(uint256 amount,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(amount>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(busdToken.balanceOf(msg.sender)>=(amount),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=amount,"Invalid buy amount");
	     (uint256 buy_amt,uint256 newpriceGap, uint256 newpriceIndex,uint256 newTokenPrice)=calcBuyAmount(amount); 
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+buy_amt;
	     users[msg.sender].selfBuyUsd=users[msg.sender].selfBuyUsd+amount;
	     
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     tokenPrice=newTokenPrice;
	     busdToken.transferFrom(msg.sender ,address(this), (amount));
	     gabxToken.transfer(msg.sender , buy_amt);
	     
	     if(msg.sender!=owner)
	     {
	       users[users[msg.sender].referrer].directBusiness=users[users[msg.sender].referrer].directBusiness+amount; 
	      _calculateReferrerReward(amount,users[msg.sender].referrer);
	     }
	     
         total_token_buy=total_token_buy+buy_amt;
		 emit TokenDistribution(address(this), msg.sender, buy_amt, tokenPrice,amount);					
	 }
	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	  uint256 percent;
	  for(uint8 i=0;i<5;i++)
	  {
	     if(_referrer==address(0))
	     break;
	     
	     if(i==0)
	     {
	       percent=getLevelPercent(users[_referrer].selfBuyUsd,i);
	       busdToken.transfer(_referrer , (_investment*percent)/1000);
	       users[_referrer].refIncome=users[_referrer].refIncome+(_investment*percent)/1000;  
	     }
	     else
	     {
	         if(users[_referrer].selfBuyUsd>=100*1e18 && users[_referrer].partnersCount>=i+1 && users[_referrer].directBusiness>=((i+1)*100*1e18))
	         {
	              percent=getLevelPercent(users[_referrer].selfBuyUsd,i);
    	          busdToken.transfer(_referrer , (_investment*percent)/1000);
    	          users[_referrer].refIncome=users[_referrer].refIncome+(_investment*percent)/1000;
    	     
	         }
	     }
	     _referrer=users[_referrer].referrer;
	 }
	
    }
    
    function getLevelPercent(uint256 _investment,uint8 level) public view returns(uint256)
    {
         if(_investment>=10*1e18 && _investment<=99*1e18)
         return refPercent[1][level+1];
         
         if(_investment>=100*1e18 && _investment<=499*1e18)
         return refPercent[2][level+1];
         
         if(_investment>=500*1e18 && _investment<=999*1e18)
         return refPercent[3][level+1];
         
         if(_investment>=1000*1e18 && _investment<=2499*1e18)
         return refPercent[4][level+1];
         
         if(_investment>=2500*1e18 && _investment<=2499*1e18)
         return refPercent[5][level+1];
         
         if(_investment>=5000*1e18)
         return refPercent[6][level+1];
    }
	
	function acalcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint256)
	{
	    uint256 amt;
	    uint256 total_buy=apriceGap+tokenQty;
	    uint256 newPriceGap=apriceGap;
	    uint256 newPriceIndex=apriceIndex;
	    if(total_buy<abuyLevel[1] && apriceIndex==1)
	    {
	        amt=(tokenQty/1e18)*apriceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint256 i=newPriceIndex;
	        while(i<5 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=abuyLevel[i])
	            {
	               uint256 _left=((abuyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left/1e18)*apriceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty/1e18)*apriceLevel[i]);  
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
	    uint256 newPriceGap=apriceGap;
	    uint256 newPriceIndex=apriceIndex;  
	    uint256 i=newPriceIndex; 
	    while(amount>0 && i<5)
	    {
	        if(i==100)
	        {
	            quatity=quatity+(amount/apriceLevel[newPriceIndex]);
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(abuyLevel[newPriceIndex]-newPriceGap)/1e18;
	            
	            uint256 LeftValue=(left*apriceLevel[newPriceIndex]);
	            
	            if(LeftValue>=amount)
	            {
	                left=(amount/apriceLevel[newPriceIndex]);
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
	
	function calcBuyAmount(uint256 amount) public view returns(uint256,uint256,uint256,uint256)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint256 newPriceIndex=priceIndex;  
	    uint256 newTokenPrice=tokenPrice;  
	    while(amount>0)
	    {
	        if((newPriceGap+amount)<amountPerSlot)
	        {
	           quatity=quatity+(amount/newTokenPrice);  
	           newPriceGap=newPriceGap+amount;
	           amount=0;
	        }
	        else
	        {
	            uint256 _bal=amountPerSlot-newPriceGap;
	            quatity=quatity+(_bal/newTokenPrice);  
	            amount=amount-_bal;
	            newPriceGap=0;
	            newPriceIndex=newPriceIndex+1;
	            if(newPriceIndex<47)
	            newTokenPrice=newTokenPrice+(5*1e14);
	            else
	            newTokenPrice=newTokenPrice+(25*1e13);
	        }
	    }
	    return (quatity*1e18,newPriceGap,newPriceIndex,newTokenPrice);
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
    
   
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}