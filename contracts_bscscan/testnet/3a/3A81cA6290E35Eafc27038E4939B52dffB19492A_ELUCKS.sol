/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// owner address    0xc95E9785E8934e2aD283Af8A8B1ee292F256CB0F
// busd token  =    0xcf1aecc287027f797b99650b1e020ffa0fb0e248
// elux token  =    0xa02dd5B097d356990Aa5629B6643Ad9E8ECD7218
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
   
contract ELUCKS  
{
     using SafeMath for uint256;

    struct User 
    {
        uint id;
        address referrer;
        uint256 partnersCount;
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
	uint256 public  tokenPrice = 2*1e16;
	uint256 public  amountPerSlot=1000*1e18;
	uint256  priceIncPercent=185;
    uint256  priceDecPercent=184;
    uint256 public  total_virtual_buy = 0;
	
	uint public  MINIMUM_BUY = 1e18;
	
    address public owner;
    
    mapping(uint256 => uint) public buyLevel;
    mapping(uint256 => uint) public priceLevel;


    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint256 total_token, uint256 live_rate, uint256 bnb_amount, uint256 block_timestamp);
    event UserIncome(address indexed sender, address indexed receiver,  uint bnb_amount, uint8 level);
    
   //For Token Transfer
   
   IBEP20 private elucksToken; 
   IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _elucksToken) public 
    {
        owner = ownerAddress;
        
        elucksToken = _elucksToken;
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
        elucksToken.transfer(msg.sender,amt);
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
    
    

    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     (uint256 buy_amt,uint256 temp_total_virtual_buy,uint256 tempPrice)=calcBuyAmount(tokenQty);
	     
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     elucksToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
         total_virtual_buy=temp_total_virtual_buy;
         tokenPrice=tempPrice;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt,block.timestamp);					
	 }
	 

	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	  uint256 percent;
	  uint8 i=0;
	  while(i<5)
	  {
	     if(_referrer==address(0))
	     break;
	     
	     if(i==0)
	     {
	       percent=getLevelPercent(users[_referrer].selfBuyUsd,i);
	       busdToken.transfer(_referrer , (_investment*percent)/1000);
	       users[_referrer].refIncome=users[_referrer].refIncome+(_investment*percent)/1000; 
	       emit UserIncome(msg.sender, _referrer,  (_investment*percent)/1000, i+1);
	       i++;
	     }
	     else
	     {
	         uint8 level=i+1;
	         uint256 directBusinessNeed=(level*1e20);
	         if(users[_referrer].selfBuyUsd>=100*1e18 && users[_referrer].partnersCount>=level && users[_referrer].directBusiness>=directBusinessNeed)
	         {
	           percent=getLevelPercent(users[_referrer].selfBuyUsd,i);
    	       busdToken.transfer(_referrer , (_investment*percent)/1000);
    	       users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment*percent)/1000;
    	       emit UserIncome(msg.sender, _referrer,  (_investment*percent)/1000, level);
    	       i++;
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
         
         if(_investment>=2500*1e18 && _investment<=4999*1e18)
         return refPercent[5][level+1];
         
         if(_investment>=5000*1e18)
         return refPercent[6][level+1];
    }
	
	function calcBuyAmount(uint256 tokenAmount) public view returns(uint256,uint256,uint256)
	{
	    uint256 totalPrice;
	    uint256 tempPrice=tokenPrice;
	    uint256 temp_total_virtual_buy=total_virtual_buy;
	    require(tokenAmount>0,"Invalid amount.");
	    while(tokenAmount>0)
	    {
	       if((temp_total_virtual_buy+tokenAmount)<1000*1e18)
	       {
	          totalPrice=totalPrice+(tokenAmount.div(1e18)).mul(tempPrice);
	          temp_total_virtual_buy=temp_total_virtual_buy+tokenAmount;
	          tokenAmount=0;
	       }
	       else
	       {
	          uint256 _left=tokenAmount-temp_total_virtual_buy;
	          totalPrice=totalPrice+(_left.div(1e18)).mul(tempPrice);
	          tempPrice=tempPrice+((tempPrice.mul(priceIncPercent)).div(1000000));
	          temp_total_virtual_buy=0;
	          tokenAmount=tokenAmount-_left;
	       }
	    }
	    return(totalPrice,temp_total_virtual_buy,tempPrice);
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
  
    function token_setting(uint min_buy,   uint256 _tokenPrice) public payable
    {
        require(msg.sender==owner,"Only Owner");
        MINIMUM_BUY = min_buy;
        tokenPrice=_tokenPrice;
    }
    
    function updateTokenPrice(uint8 _type) private
	{
	   if(_type==1)
	   {
	     while(true)
	     {
	         uint256 tempPrice=(tokenPrice*priceIncPercent)/10000;
	         tokenPrice=tokenPrice+tempPrice;
	         total_virtual_buy=total_virtual_buy-amountPerSlot;
	         if(total_virtual_buy<amountPerSlot)
	         return;
	     }
	   }
	   else
	   {
	     while(true)
	     {
	       //  uint256 tempPrice=(tokenPrice.mul(priceDecPercent)).div(1000000);
	       //  tokenPrice=tokenPrice-tempPrice;
	       //  total_virtual_withdraw=total_virtual_withdraw-priceUpdateGap;
	       //  if(total_virtual_withdraw<priceUpdateGap)
	       //  return;
	     }
	   }
	}
   
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}