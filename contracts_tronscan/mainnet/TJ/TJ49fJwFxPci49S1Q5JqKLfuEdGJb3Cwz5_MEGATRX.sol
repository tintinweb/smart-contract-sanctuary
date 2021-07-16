//SourceUnit: mega_trx.sol

pragma solidity ^0.5.9;
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
   
contract MEGATRX is Ownable {
     using SafeMath for uint256;
    
    struct User {
        uint id;
        uint8 payType;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => mapping(uint8 => uint256)) holdBonus;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 8;
    
    uint256[] public DIRECT_PERCENTS = [46 trx, 90 trx, 180 trx, 363 trx, 686 trx, 1350 trx, 2250 trx, 9002 trx];
    uint256[] public LEVEL_PERCENTS = [11 trx, 18 trx, 30 trx, 51 trx, 84 trx, 150 trx, 225 trx, 818 trx];
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;

    mapping(uint8 => mapping(uint256 => address)) Matrix_number;
    address payable public owner;
    
    uint public token_price = 1000;
    
    uint public  tbuy  =  0;
	uint public  tsale =  0;
    uint public  vbuy  =  0;
	uint public  vsale =  0;
	
	uint public  MINIMUM_BUY  = 50;
	uint public  MINIMUM_SALE = 50;
	
    uint public  MAXIMUM_BUY  = 600;
	uint public  MAXIMUM_SALE = 600;
    
    ITRC20 private MTR;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint256) public currentMatrixId;
    mapping(uint8 => uint256) public index;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed _from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed _from, address indexed receiver, uint8 matrix, uint8 level);
    event UserIncome(address user, address indexed _from, uint8 matrix, uint8 level, uint8 subLevel, uint8 _type, uint256 income, uint8 payType);
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 _type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
    
    constructor(ITRC20 _MTR) public {
        levelPrice[1] = 200 trx;
        levelPrice[2] = 400 trx;
        levelPrice[3] = 800 trx;
        levelPrice[4] = 1600 trx;
        levelPrice[5] = 3000 trx;
        levelPrice[6] = 6000 trx;
        levelPrice[7] = 10000 trx;
        levelPrice[8] = 40000 trx;
        address ownerAddress=msg.sender;
        owner = msg.sender;
        MTR=_MTR;
        User memory user = User({
            id: 1,
            payType:1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for(uint8 i = 1;i <= LAST_LEVEL; i++) 
        {
            Matrix_number[i][1]=ownerAddress;
            index[i]=1;
            currentMatrixId[i]=1; 
            users[ownerAddress].activeX3Levels[i] = true;
        }   
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),0);
    }

    

     function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
    
     function withdrawLostTokenFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        MTR.transfer(_sender,address(this).balance);
    }


    function registrationExt(address referrerAddress,uint8 _regType) external payable {
        registration(msg.sender, referrerAddress,_regType);
    }
    
    function buyNewLevel(uint8 level,uint8 _payType) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(level>= 1 && level <= LAST_LEVEL, "invalid level");
        require(_payType== 1 || _payType == 2, "invalid level");
        
        if(_payType==1)
        require(msg.value == levelPrice[level], "invalid price");
        else
        {
            require((MTR.balanceOf(msg.sender)>=levelPrice[level]*100) || (MTR.allowance(msg.sender,address(this))>=levelPrice[level]*100), "invalid token cost");
            MTR.transferFrom(msg.sender,address(this),(levelPrice[level]*100000)/token_price);
        }
        
        if(level>1)
        require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
        
        require(!users[msg.sender].activeX3Levels[level], "level already activated");
        
            uint256 newIndex=index[level]+1;
            Matrix_number[level][newIndex]=msg.sender;
            index[level]=newIndex;
            address freeX3Referrer = findFreeMatrixReferrer(level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateMatrixReferrer(msg.sender, freeX3Referrer, level);
            
            address upline = users[msg.sender].referrer;
			for (uint8 i = 0; i < 8; i++) {
				if (upline != address(0)) {
				    if(i==0)
				    {
				      if(users[upline].payType==1)
				      {
					  address(uint160(upline)).send(DIRECT_PERCENTS[level-1]);
					  emit UserIncome(upline, msg.sender,0, level, i+1, 3, DIRECT_PERCENTS[level-1],1);
				      }
					  else
					  {
					      uint total_token=(DIRECT_PERCENTS[level-1]*100000)/token_price;
					      MTR.transfer(upline,total_token);
					      emit UserIncome(upline, msg.sender,0, level, i+1, 3, total_token,2);
					  }
					  
				    }
					else
					{
					  if(users[upline].payType==1)
					  {
					        address(uint160(upline)).send(LEVEL_PERCENTS[level-1]);
					        emit UserIncome(upline, msg.sender,0, level, i+1, 3, LEVEL_PERCENTS[level-1],1);
					  }
					  else
					  {
					        uint total_token=(LEVEL_PERCENTS[level-1]*100000)/token_price;
					        MTR.transfer(upline,total_token);
					        emit UserIncome(upline, msg.sender,0, level, i+1, 3, total_token,2);
					  }
					}
					upline = users[upline].referrer;
				} else break;
			}
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
    }    
    
    function registration(address userAddress, address referrerAddress, uint8 _regType) private {
        require(_regType>0 && _regType<3,"Invalid Registration Type");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        if(_regType==1)
        require(msg.value == levelPrice[currentStartingLevel], "invalid registration cost");
        else
        {
            require((MTR.balanceOf(msg.sender)>=levelPrice[currentStartingLevel]*100) || (MTR.allowance(msg.sender,address(this))>=levelPrice[currentStartingLevel]*100), "invalid token cost");
            MTR.transferFrom(msg.sender,address(this),(levelPrice[currentStartingLevel]*100000)/token_price);
        }
        
        User memory user = User({
            id: lastUserId,
            payType:_regType,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        
        idToAddress[lastUserId] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        if(users[referrerAddress].payType==1)
		{
            address(uint160(referrerAddress)).send(75 trx);
            emit UserIncome(referrerAddress, userAddress, 0, 0, 0, 1, 75 trx,1);
		}
		else
		{
            MTR.transfer(referrerAddress,(75*1e11)/token_price);
            emit UserIncome(referrerAddress, userAddress, 0, 0, 0, 1, (75*1e11)/token_price,2);
		}
		
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateMatrixReferrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
        if (users[referrerAddress].x3Matrix[level].referrals.length<3) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return; 
        } 
        
        if(users[referrerAddress].payType==1)
        emit UserIncome(referrerAddress, userAddress, 0, level, 1, 2, ((levelPrice[level]/2)*1),1);
        else
        emit UserIncome(referrerAddress, userAddress, 0, level, 1, 2, ((levelPrice[level]/2)*1*100000)/token_price,2);
        
        sendPayment(referrerAddress, level,1);
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        currentMatrixId[level]=currentMatrixId[level]+1;
        if(referrerAddress!=address(0))
        {
            updateMatrixLevel(userAddress, users[referrerAddress].x3Matrix[level].currentReferrer, level, 2);
        }
        else
        {
           address(uint160(owner)).send(((levelPrice[level]/2)*2));
        }
        
    }   
    
    function updateMatrixLevel(address userAddress, address referrerAddress, uint8 level, uint8 subLevel) private 
    {
        if(subLevel<5)
        {
          if(users[referrerAddress].holdBonus[level][subLevel]==((levelPrice[level]/2)*(subLevel*2)))
          {
            users[referrerAddress].holdBonus[level][subLevel]=0; 
            
            if(users[referrerAddress].payType==1)
            emit UserIncome(referrerAddress, userAddress,0, level, subLevel, 2, ((levelPrice[level]/2)*subLevel),1);
            else
            emit UserIncome(referrerAddress, userAddress,0, level, subLevel, 2, ((levelPrice[level]/2)*subLevel*100000)/token_price,2);
            
            sendPayment(referrerAddress, level,subLevel);
            if(users[referrerAddress].x3Matrix[level].currentReferrer!=address(0))
            updateMatrixLevel(referrerAddress, users[referrerAddress].x3Matrix[level].currentReferrer, level, (subLevel+1));   
          }
          else
          {
            users[referrerAddress].holdBonus[level][subLevel]=users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel);   
          }
        }
        else
        {
          if(users[referrerAddress].holdBonus[level][subLevel]==((levelPrice[level]/2)*(subLevel*2)))
          {
            uint total=(users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel))-levelPrice[level];
            address(uint160(referrerAddress)).send(total);
            users[referrerAddress].x3Matrix[level].referrals = new address[](0);
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, users[referrerAddress].x3Matrix[level].currentReferrer, msg.sender, 1 ,level);
            users[referrerAddress].holdBonus[level][subLevel]=0;
            reEntry(referrerAddress,level);
          }
          else
          {
            users[referrerAddress].holdBonus[level][subLevel]=users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel);  
          }
        }
        
     }    

    function reEntry(address _user, uint8 level) private
    {
            uint256 newIndex=index[level]+1;
            Matrix_number[level][newIndex]=_user;
            index[level]=newIndex;
            address freeX3Referrer = findFreeMatrixReferrer(level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            updateMatrixReferrer(_user, freeX3Referrer, level); 
     }
     
     
     
     
    function AbuyNewLevel(address _user,uint8 level,uint8 _payType) external payable {
        require(msg.sender==owner,"Only Owner");
        require(isUserExists(_user), "user is not exists. Register first.");
        require(level>= 1 && level <= LAST_LEVEL, "invalid level");
        require(_payType== 1 || _payType == 2, "invalid level");
        
        if(level>1)
        require(users[_user].activeX3Levels[level-1], "buy previous level first");
        
        require(!users[_user].activeX3Levels[level], "level already activated");
        
            uint256 newIndex=index[level]+1;
            Matrix_number[level][newIndex]=_user;
            index[level]=newIndex;
            address freeX3Referrer = findFreeMatrixReferrer(level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_user].activeX3Levels[level] = true;
            AupdateMatrixReferrer(_user, freeX3Referrer, level);
            
            address upline = users[_user].referrer;
			for (uint8 i = 0; i < 8; i++) {
				if (upline != address(0)) {
				    if(i==0)
				    {
				      if(users[upline].payType==1)
				      {
					  emit UserIncome(upline, _user,0, level, i+1, 3, DIRECT_PERCENTS[level-1],1);
				      }
					  else
					  {
					      uint total_token=(DIRECT_PERCENTS[level-1]*100000)/token_price;
						  emit UserIncome(upline, _user,0, level, i+1, 3, total_token,2);
					  }
					  
				    }
					else
					{
					  if(users[upline].payType==1)
					  {
					        emit UserIncome(upline, _user,0, level, i+1, 3, LEVEL_PERCENTS[level-1],1);
					  }
					  else
					  {
					        uint total_token=(LEVEL_PERCENTS[level-1]*100000)/token_price;
					        emit UserIncome(upline, _user,0, level, i+1, 3, total_token,2);
					  }
					}
					upline = users[upline].referrer;
				} else break;
			}
            
            emit Upgrade(_user, freeX3Referrer, 1, level);
    }    
    
    function Aregistration(address userAddress, address referrerAddress, uint8 _regType) public payable {
        require(msg.sender==owner,"Only Owner");
        require(_regType>0 && _regType<3,"Invalid Registration Type");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
       
        
        User memory user = User({
            id: lastUserId,
            payType:_regType,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        
        idToAddress[lastUserId] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        if(users[referrerAddress].payType==1)
		{
            emit UserIncome(referrerAddress, userAddress, 0, 0, 0, 1, 75 trx,1);
		}
		else
		{
            emit UserIncome(referrerAddress, userAddress, 0, 0, 0, 1, (75*1e11)/token_price,2);
		}
		
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function AupdateMatrixReferrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
        if (users[referrerAddress].x3Matrix[level].referrals.length<3) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return; 
        } 
        
        if(users[referrerAddress].payType==1)
        emit UserIncome(referrerAddress, userAddress, 0, level, 1, 2, ((levelPrice[level]/2)*1),1);
        else
        emit UserIncome(referrerAddress, userAddress, 0, level, 1, 2, ((levelPrice[level]/2)*1*100000)/token_price,2);

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        currentMatrixId[level]=currentMatrixId[level]+1;
        if(referrerAddress!=address(0))
        {
            AupdateMatrixLevel(userAddress, users[referrerAddress].x3Matrix[level].currentReferrer, level, 2);
        }
    }   
    
    function AupdateMatrixLevel(address userAddress, address referrerAddress, uint8 level, uint8 subLevel) private 
    {
        if(subLevel<5)
        {
          if(users[referrerAddress].holdBonus[level][subLevel]==((levelPrice[level]/2)*(subLevel*2)))
          {
            users[referrerAddress].holdBonus[level][subLevel]=0; 
            
            if(users[referrerAddress].payType==1)
            emit UserIncome(referrerAddress, userAddress,0, level, subLevel, 2, ((levelPrice[level]/2)*subLevel),1);
            else
            emit UserIncome(referrerAddress, userAddress,0, level, subLevel, 2, ((levelPrice[level]/2)*subLevel*100000)/token_price,2);
           
            if(users[referrerAddress].x3Matrix[level].currentReferrer!=address(0))
            AupdateMatrixLevel(referrerAddress, users[referrerAddress].x3Matrix[level].currentReferrer, level, (subLevel+1));   
          }
          else
          {
            users[referrerAddress].holdBonus[level][subLevel]=users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel);   
          }
        }
        else
        {
          if(users[referrerAddress].holdBonus[level][subLevel]==((levelPrice[level]/2)*(subLevel*2)))
          {
            uint total=(users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel))-levelPrice[level];
            users[referrerAddress].x3Matrix[level].referrals = new address[](0);
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, users[referrerAddress].x3Matrix[level].currentReferrer, userAddress, 1 ,level);
            users[referrerAddress].holdBonus[level][subLevel]=0;
            AreEntry(referrerAddress,level);
          }
          else
          {
            users[referrerAddress].holdBonus[level][subLevel]=users[referrerAddress].holdBonus[level][subLevel]+((levelPrice[level]/2)*subLevel);  
          }
        }
        
     }    

    function AreEntry(address _user, uint8 level) private
    {
            uint256 newIndex=index[level]+1;
            Matrix_number[level][newIndex]=_user;
            index[level]=newIndex;
            address freeX3Referrer = findFreeMatrixReferrer(level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            AupdateMatrixReferrer(_user, freeX3Referrer, level); 
     }
     
     
     

    function buyToken(uint tokenQty) public payable {
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");
	     require(tokenQty<=MAXIMUM_BUY,"Invalid maximum quatity");	            
	     uint trx_amt=((tokenQty+(tokenQty*5)/100)*(token_price)/1000)*1000000;
	     require(msg.value>=trx_amt,"Invalid buy amount");
		 MTR.transfer(msg.sender , (tokenQty*100000000));
		 owner.transfer(msg.value);
		 emit TokenDistribution(address(this), msg.sender, tokenQty*100000000, token_price);	
		 
		vbuy=vbuy+1;
		tbuy=tbuy+tokenQty;
		if(vbuy>=10)
        {
            emit TokenPriceHistory(token_price,10, token_price+10, 0); 
            token_price=token_price+10;
            vbuy=vbuy+10;
        }
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(!isContract(userAddress),"Can not be contract");
	    
        require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(tokenQty>=MINIMUM_SALE,"Invalid minimum quatity");
	    require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quatity");
	     
	    uint trx_amt=((tokenQty-(tokenQty*5)/100)*(token_price)/100)*100000;
		MTR.transferFrom(userAddress ,address(this), (tokenQty*100000000));
		address(uint160(msg.sender)).send(trx_amt);
		emit TokenDistribution(userAddress,address(this), tokenQty*100000000, token_price);
		vsale=vsale+1;
		tsale=tsale+tokenQty;
		if(vsale>=10)
        {
            if(token_price>1000)
            {
            emit TokenPriceHistory(token_price,10, token_price-10, 0); 
            token_price=token_price-10;
            vsale=vsale-10;
            }
        }
	 }

        
    function findFreeMatrixReferrer(uint8 level) public view returns(address) 
    {
            uint256 id=currentMatrixId[level];
            return Matrix_number[level][id];
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }
   
    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
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

    function sendPayment(address userAddress, uint8 level, uint8 subLevel) private 
    {
        if(users[userAddress].payType==1)
        address(uint160(userAddress)).send(((levelPrice[level]/2)*subLevel));
        else
        MTR.transfer(userAddress,(((levelPrice[level]/2)*subLevel)*100000)/token_price);
        return;
    }
    
    function getUserHoldAmount(address userAddress, uint8 level, uint8 subLevel) public view returns(uint256) 
    {
	    return(users[userAddress].holdBonus[level][subLevel]);	
	}
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
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
    
    
}