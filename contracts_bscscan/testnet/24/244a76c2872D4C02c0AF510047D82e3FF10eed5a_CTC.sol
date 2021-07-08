/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity 0.5.4;
//  token == 0xCF1AeCc287027f797b99650B1E020fFa0fb0e248

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
   
contract CTC  {
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

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
 

    uint public lastUserId = 2;
    uint256[] public refPercent=[10,2,2,1];

    
    
    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint8 public  priceIndex = 1;
	
	uint public  MINIMUM_BUY = 1e17;
	uint public  MINIMUM_SALE = 1e17;
	
	
    address public owner;
    address public comissionWallet;
    address public rewardWallet;
    
    mapping(uint8 => uint) public buyLevel;
    mapping(uint8 => uint) public priceLevel;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate,uint256 bnb_amount);
    
   
    
   //For Token Transfer
   
   IBEP20 private ctcToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress,IBEP20 _ctcToken,address _comissionWallet,address _rewardWallet) public 
    {
        owner = ownerAddress;
        rewardWallet=_rewardWallet;
        ctcToken = _ctcToken;
        comissionWallet=_comissionWallet;
        
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
        
        
        buyLevel[1]=111000*1e18;
        buyLevel[2]=1500000*1e18;
        buyLevel[3]=1000000*1e18;
        buyLevel[4]=500000*1e18;
        buyLevel[5]=250000*1e18;
        buyLevel[6]=100000*1e18;
        buyLevel[7]=50000*1e18;
        buyLevel[8]=45000*1e18;
        buyLevel[9]=42000*1e18;
        buyLevel[10]=38000*1e18;
        buyLevel[11]=35000*1e18;
        buyLevel[12]=32000*1e18;
        buyLevel[13]=31000*1e18;
        buyLevel[14]=30000*1e18;
        buyLevel[15]=28000*1e18;
        buyLevel[16]=26000*1e18;
        buyLevel[17]=25000*1e18;
        buyLevel[18]=24000*1e18;
        buyLevel[19]=22000*1e18;
        buyLevel[20]=20000*1e18;
        buyLevel[21]=18000*1e18;
        buyLevel[22]=16000*1e18;
        buyLevel[23]=14000*1e18;
        buyLevel[24]=12000*1e18;
        buyLevel[25]=10000*1e18;
        buyLevel[26]=8000*1e18;
        buyLevel[27]=6000*1e18;
        buyLevel[28]=4000*1e18;
        buyLevel[29]=2000*1e18;
        buyLevel[30]=1000*1e18;
        
        
        priceLevel[1]=4139*1e8;
        priceLevel[2]=22*1e11;
        priceLevel[3]=67*1e11;
        priceLevel[4]=13*1e12;
        priceLevel[5]=36*1e12;
        priceLevel[6]=90*1e12;
        priceLevel[7]=22*1e13;
        priceLevel[8]=67*1e13;
        priceLevel[9]=13*1e14;
        priceLevel[10]=27*1e14;
        priceLevel[11]=54*1e14;
        priceLevel[12]=11*1e15;
        priceLevel[13]=22*1e15;
        priceLevel[14]=45*1e15;
        priceLevel[15]=9*1e16;
        priceLevel[16]=18*1e17;
        priceLevel[17]=27*1e17;
        priceLevel[18]=45*1e17;
        priceLevel[19]=54*1e17;
        priceLevel[20]=63*1e17;
        priceLevel[21]=72*1e17;
        priceLevel[22]=81*1e17;
        priceLevel[23]=90*1e17;
        priceLevel[24]=99*1e17;
        priceLevel[25]=107*1e16;
        priceLevel[26]=116*1e16;
        priceLevel[27]=125*1e16;
        priceLevel[28]=134*1e16;
        priceLevel[29]=170*1e16;
        priceLevel[30]=202*1e16;
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
        else
        ctcToken.transfer(msg.sender,amt);
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
    

    function buyToken(uint tokenQty,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(msg.value>=MINIMUM_BUY,"Minimum 0.1 BNB");
	     
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     uint256 buy_amt=calcBuyAmt(tokenQty);
	     require(msg.value>=buy_amt,"Invalid buy amount");
	     
	     
	     (uint256 tokenAmount,uint256 newpriceGap, uint8 newpriceIndex)=calcBuyToken((msg.value*77)/100);
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenAmount;
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     
	     ctcToken.transfer(msg.sender , tokenAmount);
	     address(uint160(comissionWallet)).transfer((msg.value*2)/100);
	     address(uint160(rewardWallet)).transfer((msg.value*6)/100);
	     
	     if(msg.sender!=owner)
	     _calculateReferrerReward(msg.value,users[msg.sender].referrer);
	     
         total_token_buy=total_token_buy+tokenAmount;
		 emit TokenDistribution(address(this), msg.sender, tokenAmount, priceLevel[priceIndex],msg.value);					
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(ctcToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(ctcToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        require(isUserExists(userAddress), "user is not exists. Register first.");
	   
	    
	    (uint256 bnb_amt,uint256 newpriceGap, uint8 newpriceIndex)=calcSellAmt(tokenQty);
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     
		 ctcToken.transferFrom(userAddress ,address(this), (tokenQty));
		 address(uint160(msg.sender)).transfer((bnb_amt*92)/100);
		 address(uint160(comissionWallet)).transfer((bnb_amt*2)/100);
		 address(uint160(rewardWallet)).transfer((msg.value*6)/100);
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],bnb_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }
	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	     for(uint8 i=0;i<4;i++)
	     {
	         if(i==0)
	         users[_referrer].refIncome=users[_referrer].refIncome+(_investment*refPercent[i])/100;
	         else
	         users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment*refPercent[i])/100;
            address(uint160(_referrer)).transfer((_investment*refPercent[i])/100); 
            if(users[_referrer].referrer!=address(0))
            _referrer=users[_referrer].referrer;
            else
            break;
	     }
     }
	
	function calcBuyAmt(uint tokenQty) public view returns(uint256)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint8 i=newPriceIndex;
	        while(i<31 && tokenQty>0)
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
	    
	    return (amt);
	}
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint8)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;  
	    uint8 i=newPriceIndex; 
	    while(amount>0 && i<31)
	    {
	        if(i==30)
	        {
	            quatity=quatity+(amount/priceLevel[priceIndex]);
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
	
	function calcSellAmt(uint tokenQty) public view returns(uint256,uint256,uint8)
	{
	    uint256 amt;
	    uint256 newPriceGap=priceGap;
	    uint8 newPriceIndex=priceIndex;
	    if(newPriceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
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
	                
	                amt=(_left/1e18)*priceLevel[newPriceIndex];
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
	                    amt=(tokenQty/1e18)*priceLevel[newPriceIndex]; 
	                    if(buyLevel[newPriceIndex]>=tokenQty)
	                    newPriceGap=buyLevel[newPriceIndex]-tokenQty;
	                    else
	                    newPriceGap=0;
	                    tokenQty=0;
	                }
	                else
	                {
	                   amt=(buyLevel[newPriceIndex]/1e18)*priceLevel[newPriceIndex]; 
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
    
    
    function multisendTRX(address payable[]  memory  _contributors, uint[] memory _balances) public payable 
    {
      require(msg.sender==rewardWallet || msg.sender==owner);
        uint i = 0;
        for (i; i < _contributors.length; i++) 
        {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}