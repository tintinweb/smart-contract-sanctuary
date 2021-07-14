/**
 *Submitted for verification at BscScan.com on 2021-07-14
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
   
contract KASSECOIN  {
     using SafeMath for uint256;
     
       struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
     
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool airdropClaim;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 selfBuy;
        uint256 selfSell;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
    }
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    
    uint256 private constant INTEREST_CYCLE = 30 days;

    uint public lastUserId = 2;
    uint256[] public refPercent=[50,25,15,10];
    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint64 public  priceIndex = 1;
	uint256 public airdropFee =21*1e14;
	uint public  MINIMUM_BUY = 1e16;
	uint public  MINIMUM_SALE = 1e17;
	uint public tokenPrice = 2320000000000;
	
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
    event Airdrop(address  _user, uint256 tokenQnt);
    
   //For Token Transfer
   
   IBEP20 private KasseToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress, IBEP20 _kassetoken) public 
    {
        owner = ownerAddress;
        KasseToken = _kassetoken;
        investmentPlans_.push(Plan(50,540*60*60*24,50)); //540 days and 5%
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome: uint(0),
            airdropClaim:false,
            levelIncome: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for(uint64 i=1;i<=10;i++)
        {
            buyLevel[i]=100000*1e18;
            if(i==1)
            priceLevel[i]=125*1e14;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=11;i<=20;i++)
        {
            buyLevel[i]=150000*1e18;
            if(i==11)
            priceLevel[i]=135*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
         for(uint64 i=21;i<=30;i++)
        {
            buyLevel[i]=200000*1e18;
            if(i==21)
            priceLevel[i]=235*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=31;i<=40;i++)
        {
            buyLevel[i]=250000*1e18;
            if(i==31)
            priceLevel[i]=335*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=41;i<=50;i++)
        {
            buyLevel[i]=300000*1e18;
            if(i==41)
            priceLevel[i]=425*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=51;i<=99;i++)
        {
            buyLevel[i]=200000*1e18;
            if(i==51)
            priceLevel[i]=535*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        buyLevel[100]=200000*1e18;
        priceLevel[100]=125*1e16;
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
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
            airdropClaim:false,
            levelIncome: 0,
            selfBuy: 0,
            selfSell: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function buyToken(uint256 _value,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(msg.value>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(msg.value==_value,"Invalid Value");
	     uint256 amount =(_value/tokenPrice)*1e18;
	   //  (uint256 buy_amt,uint256 newpriceGap, uint64 newpriceIndex)=calcBuyAmt(tokenQty);
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+amount;
	     KasseToken.transfer(msg.sender , amount);
	     KasseToken.transfer(users[msg.sender].referrer,amount);
	     users[users[msg.sender].referrer].refIncome=users[users[msg.sender].referrer].refIncome+amount;
         total_token_buy=total_token_buy+amount;
// 		 emit TokenDistribution(address(this), msg.sender, amount, priceLevel[priceIndex],buy_amt);					
	 }
	 
    function getAirdrop(address referrer) public payable
	{
	     uint256 airdropToken=370*1e18;
	     require(!isContract(msg.sender),"Can not be contract");
	     require(!isUserExists(msg.sender),"User already exist!");
         require(isUserExists(referrer),"Referrer not exist!");
	     require(msg.value==airdropFee,"Invalid airdrop fee") ;
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+airdropToken;
	     users[msg.sender].airdropClaim=true;
	     KasseToken.transfer(msg.sender , airdropToken);
	     KasseToken.transfer(referrer , airdropToken);
	     address(uint16 (owner)).transfer(msg.value);
         emit Airdrop(msg.sender,airdropToken);
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(saleOpen || users[userAddress].selfSell<(users[userAddress].refIncome+users[userAddress].levelIncome),"Sale Stopped.");
	    require(KasseToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(KasseToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        
	    
	    uint256 busd_amt=(tokenQty/1e18)*priceLevel[priceIndex];
	     
		 KasseToken.transferFrom(userAddress ,address(this), (tokenQty));
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],busd_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }

	function calcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint64)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint64 i=newPriceIndex;
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
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint64)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex=priceIndex;  
	    uint64 i=newPriceIndex; 
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