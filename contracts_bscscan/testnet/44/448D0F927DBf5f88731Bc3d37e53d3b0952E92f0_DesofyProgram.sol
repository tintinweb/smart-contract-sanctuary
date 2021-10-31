/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

/* 
  owner    0x6dA4867268c80BFcc1Fe4515A841eCa6299557Fb
  busd     0xcf1aecc287027f797b99650b1e020ffa0fb0e248
  desofy   0x941d4CeBaE121A60cbb9F57cd91cC4dac4F46d91
*/
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

contract DesofyProgram  {
    using SafeMath for uint256;
     
    struct User 
    {
        uint id;
        address referrer;
        uint256 referralReward;
        uint256 selfBuy;
        uint256 selfSell;
    }
    
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
   

    uint public lastUserId = 2;
    uint256 public tokenPrice=1*1e16;
    uint256  priceIncPercent=1;
    uint256  priceDecPercent=1;
    bool public isAdminOpen;
    
    uint256 public  total_token_buy = 0;
    uint256 public  total_token_sell = 0;
	
	bool   public  buyOn = true;
	bool   public  sellOn = true;
	uint256 public  transaction_fee=4;
	uint256 public  MINIMUM_BUY = 1e18;
	uint256 public  MINIMUM_SELL = 1e18;
	uint256 public  total_virtual_buy = 0;
	uint256 public  total_virtual_sell = 0;
	uint256 public  buyPriceUpdateGap=5000*1e18;
	uint256 public  sellPriceUpdateGap=2500*1e18;
	uint256[] public BUY_REFERRAL_PERCENTS = [500,300,200];
	uint256[] public SELL_REFERRAL_PERCENTS = [100,50,25];
    address public owner;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint busd_amount);
    event RefBonus(address _user, address _from, uint256 level, uint256 amount,uint8 _type);
    IBEP20 private desofyToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _desofyToken) public 
    {
        owner = ownerAddress;
        
        desofyToken = _desofyToken;
        busdToken = _busdToken;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            referralReward: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0)
        });
      
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    } 
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
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
            referralReward: 0,
            selfBuy: 0,
            selfSell: 0
        }); 
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyToken(uint256 tokenQty, address referrerAddress) public payable
	{
	     require(buyOn,"Buy Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender,referrerAddress);  
	     }
	     uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
	     buy_amt=buy_amt+((buy_amt.mul(transaction_fee)).div(10000));
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     desofyToken.transfer(msg.sender , tokenQty);
	     total_virtual_buy=total_virtual_buy+tokenQty;
         total_token_buy=total_token_buy+tokenQty;
         if(buyPriceUpdateGap<total_virtual_buy)
         {
           updateTokenPrice(1);
         }
         refReward(users[msg.sender].referrer,tokenQty);
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable
	{
	     require(sellOn,"Sell Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_SELL,"Invalid minimum quantity");
	     require(isUserExists(msg.sender),"User Not Exist");
	     require(desofyToken.balanceOf(msg.sender)>=(tokenQty),"Low Balance");
	     require(desofyToken.allowance(msg.sender,address(this))>=tokenQty,"Invalid buy amount");
	     
	     uint256 busd_amt=(tokenQty/1e18)*tokenPrice;
	     busd_amt=busd_amt-((busd_amt.mul(transaction_fee)).div(10000));
	     
	     users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
	     
	     total_virtual_sell=total_virtual_sell+tokenQty;
         total_token_sell=total_token_sell+tokenQty;
         if(sellPriceUpdateGap<=total_virtual_sell)
         {
           updateTokenPrice(2);
         }
         sellRefReward(users[msg.sender].referrer,tokenQty);
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, busd_amt);					
	 }
	 
    function refReward(address upline,uint256 amt) private
    {
        if (upline!=address(0)) 
        {
			for (uint256 i = 0; i < BUY_REFERRAL_PERCENTS.length; i++) 
			{
				if (upline != address(0)) 
				{
					uint256 amount = amt.mul(BUY_REFERRAL_PERCENTS[i]).div(10000);
					users[upline].referralReward = users[upline].referralReward.add(amount);
					desofyToken.transfer(upline , amount);
					emit RefBonus(upline, msg.sender, i, amount,1);
					upline = users[upline].referrer;
				} else break;
			}

		}
    }
    
    function sellRefReward(address upline,uint256 amt) private
    {
        if (upline!=address(0)) 
        {
			for (uint256 i = 0; i < BUY_REFERRAL_PERCENTS.length; i++) 
			{
				if (upline != address(0)) 
				{
					uint256 amount = amt.mul(SELL_REFERRAL_PERCENTS[i]).div(10000);
					users[upline].referralReward = users[upline].referralReward.add(amount);
					desofyToken.transfer(upline , amount);
					emit RefBonus(upline, msg.sender, i, amount,2);
					upline = users[upline].referrer;
				} else break;
			}

		}
    }
    
	function updateTokenPrice(uint8 _type) private
	{
	   if(_type==1)
	   {
	     while(true)
	     {
	         uint256 tempPrice=(tokenPrice*priceIncPercent)/10000;
	         tokenPrice=tokenPrice+tempPrice;
	         total_virtual_buy=total_virtual_buy-buyPriceUpdateGap;
	         if(total_virtual_buy<buyPriceUpdateGap)
	         return;
	     }
	   }
	   else
	   {
	     while(true)
	     {
	         uint256 tempPrice=(tokenPrice.mul(priceDecPercent)).div(1000000);
	         tokenPrice=tokenPrice-tempPrice;
	         total_virtual_sell=total_virtual_sell-sellPriceUpdateGap;
	         if(total_virtual_sell<sellPriceUpdateGap)
	         return;
	     }
	   }
	}

    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
    
    function openAdminPrice(uint8 _type) public payable
    {
              require(msg.sender==owner,"Only Owner");
              if(_type==1)
              isAdminOpen=true;
              else
              {
                isAdminOpen=false;
                total_virtual_buy=0;
                total_virtual_sell=0;
              }
    }
    
 
    
    function updatePrice(uint256 _price) public payable
    {
              require(msg.sender==owner,"Only Owner");
              require(isAdminOpen,"Admin option not open.");
              tokenPrice=_price;
    }
 
    function switchBuy(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            buyOn=true;
            else
            buyOn=false;
    }
    
     function switchSell(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            sellOn=true;
            else
            sellOn=false;
    }
    
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}