/**
 *Submitted for verification at polygonscan.com on 2021-11-08
*/

pragma solidity 0.6.4;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//ERC20 Interface
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    }
    
interface ASP {
    
   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

interface OSP {
    
   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }
 
interface DSP {
    
   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

interface USP {
    
   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }
 
interface NFT {
    
   function ActivateNFT(address NFTOwner, uint cardType) external returns(bool);
   function DeactivateNFT(address NFTOwner, uint cardType) external returns (bool);
   
 }
    
//======================================AXIA CONTRACT=========================================//
contract AXIATOKEN is ERC20 {
    
    using SafeMath for uint256;
    
//======================================AXIA EVENTS=========================================//

    event NewEpoch(uint epoch, uint emission, uint nextepoch);
    event NewDay(uint epoch, uint day, uint nextday);
    event BurnEvent(address indexed pool, address indexed burnaddress, uint amount);
    event emissions(address indexed root, address indexed pool, uint value);
    event TrigRewardEvent(address indexed root, address indexed receiver, uint value);
    event BasisPointAdded(uint value);
    
    
    event ActivateCard(address indexed staker, address indexed pool, uint amount);
    event DeactivateCard(address indexed NFTOwner, address indexed pool, uint amount);
    event RewardEvent(address indexed staker, address indexed pool, uint amount);
    event RewardNFTOwner(address indexed NFTOwner, address indexed pool, uint amount);
    
   // ERC-20 Parameters
    string public name; 
    string public symbol;
    uint public decimals; 
    uint public startdecimal;
    uint public override totalSupply;
    uint public initialsupply;
    
     //======================================STAKING POOLS=========================================//
    
    address public lonePool;
    address public swapPool;
    address public DefiPool;
    address public OraclePool;
    
    address public burningPool;
    
    uint public pool1Amount;
    uint public pool2Amount;
    uint public pool3Amount;
    uint public pool4Amount;
    uint public NFTPoolAmount;
    
    uint public basisAmount;
    uint public poolAmountTrig;
    
    
    uint public TrigAmount;
    
    
    // ERC-20 Mappings
    mapping(address => uint) private tokenbalanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    
    
    // Public Parameters
    uint crypto; 
    uint startcrypto;
    uint public emission;
    uint public currentEpoch; 
    uint public currentDay;
    uint public daysPerEpoch; 
    uint public secondsPerDay;
    uint public genesis;
    uint public nextEpochTime; 
    uint public nextDayTime;
    uint public amountToEmit;
    uint public BPE = 99990000000000000000000;
    
    //======================================BASIS POINT VARIABLES=========================================//
    uint public bpValue;
    uint public actualValue;
    uint public TrigReward;
    uint public burnAmount;
    address administrator;
    uint totalEmitted;
    
    uint256 public pool1percentage = 9000;
    uint256 public pool2percentage = 500;
    uint256 public pool3percentage = 0;
    uint256 public pool4percentage = 0;
    uint256 public NFTPoolpercentage = 500;
    
    uint256 public basispercentage = 500;
    uint256 public trigRewardpercentage = 20;
    
    
    address public messagesender;
     
    // Public Mappings
    
    mapping(address=>bool) public emission_Whitelisted;
    

    //=====================================CREATION=========================================//
    // Constructor
    constructor() public {
        name = "Axia (axiaprotocol.io)"; 
        symbol = "AXIA"; 
        decimals = 18; 
        startdecimal = 16;
        crypto = 1*10**decimals; 
        startcrypto =  1*10**startdecimal; 
        totalSupply =  4100000*crypto;                                 
        initialsupply = 150000000*startcrypto;
        emission = 1800*crypto; 
        currentEpoch = 3; 
        currentDay = 395;                             
        genesis = now;
        
        daysPerEpoch = 180; 
        secondsPerDay = 86400; 
       
        administrator = msg.sender;
        tokenbalanceOf[administrator] = initialsupply; 
        emit Transfer(administrator, address(this), initialsupply);                                
        //nextEpochTime = genesis + (secondsPerDay * daysPerEpoch);
        nextEpochTime = 1648941898;
        //nextDayTime = genesis + secondsPerDay; 
        nextDayTime = 1636413898;
                      
        
        emission_Whitelisted[administrator] = true;
        
        
        
    }
    
//========================================CONFIGURATIONS=========================================//
    
    function poolconfigs(address _axia, address _swap, address _defi, address _oracle) public onlyAdministrator returns (bool success) {
        
        lonePool = _axia;
        swapPool = _swap;
        DefiPool = _defi;
        OraclePool = _oracle;
        
        
        
        return true;
    }
    
    
    
    function burningPoolconfigs(address _pooladdress) public onlyAdministrator returns (bool success) {
           
        burningPool = _pooladdress;
        
        return true;
    }
    
    modifier onlyNFT() {
        require(msg.sender == NFTaddress, "Administration: caller is not permitted");
        _;
    }
    
    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyBurningPool() {
        require(msg.sender == burningPool, "Authorization: Only the pool that allows burn can call on this");
        _;
    }
    
    function secondAndDay(uint _secondsperday, uint _daysperepoch) public onlyAdministrator returns (bool success) {
       secondsPerDay = _secondsperday;
       daysPerEpoch = _daysperepoch;
        return true;
    }
    
    function nextEpoch(uint _nextepoch) public onlyAdministrator returns (bool success) {
       nextEpochTime = _nextepoch;
       
        return true;
    }
    
    function whitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = true;
        return true;
    }
    
    function unwhitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = false;
        return true;
    }
    
    
    function supplyeffect(uint _amount) public onlyBurningPool returns (bool success) {
       totalSupply -= _amount;
       emit BurnEvent(burningPool, address(0x0), _amount);
        return true;
    }
    
    function poolpercentages(uint _p1, uint _p2, uint _p3, uint _p4, uint _basispercent, uint trigRe) public onlyAdministrator returns (bool success) {
       
       pool1percentage = _p1;
       pool2percentage = _p2;
       pool3percentage = _p3;
       pool4percentage = _p4;
       basispercentage = _basispercent;
       trigRewardpercentage = trigRe;
       
       return true;
    }
    
    function Burn(uint _amount) public returns (bool success) {
       
       require(tokenbalanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       tokenbalanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BurnEvent(msg.sender, address(0x0), _amount);
       return true;
       
    }
    
    
   
     
      uint256 public cardAreward; //Diamond Cards
      uint256 public cardBreward; //Platinum Cards
      uint256 public cardCreward; //Gold Cards
      
    
      
    
      uint CardAShare = 2000;
      uint CardBShare = 3000;
      uint CardCShare = 5000;
      
    
      address NFTaddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
     
     
    function balanceOf(address _user) public view override returns(uint256) {        
         (uint256 a, uint256 b, uint256 c) = dividendsOf(_user);
        return tokenbalanceOf[_user] + (a+b+c);       
    }
    
    function NFTCardsRewardPercentages(uint _cardA, uint _cardB, uint _cardC) public onlyAdministrator returns (bool success) {
        
        CardAShare = _cardA;
        CardBShare = _cardB;
        CardCShare = _cardC;
        
        return true;
    }
    
     function toggleNFTAddress(address _NFTaddress) public onlyAdministrator {
         
        NFTaddress = _NFTaddress;
    }
    
    
    
    //////////////////////////////////////////////////////////////////////
    
    uint256 constant private FLOAT_SCALAR = 2**64;
    uint256 public MINIMUM_STAKE = 1000000000000000000; // 1 minimum

	
	
    
    
    //>>>>>>>>>   ---CARDHOLDER DATA TYPE A----  <<<<<<<<<<<<<<<<<<///
    uint public infocheckA;
    struct UserA {
		uint256 balance;
		uint256 frozen;
		int256 scaledPayout;  
		uint256 staketime;
	}

	struct InfoA {
	    
		uint256 totalFrozen;
		mapping(address => UserA) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	
	InfoA private infoA;
	
	
	 //>>>>>>>>>   ---CARDHOLDER DATA TYPE B----   <<<<<<<<<<<<<<<<<<///
	uint public infocheckB;
    struct UserB {
		uint256 balance;
		uint256 frozen;
		int256 scaledPayout;  
		uint256 staketime;
	}

	struct InfoB {
	    
		uint256 totalFrozen;
		mapping(address => UserA) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	
	InfoB private infoB;
	
	//>>>>>>>>>   ---CARDHOLDER DATA TYPE C----   <<<<<<<<<<<<<<<<<<///
	
	uint public infocheckC;
    struct UserC {
		uint256 balance;
		uint256 frozen;
		int256 scaledPayout;  
		uint256 staketime;
	}

	struct InfoC {
	    
		uint256 totalFrozen;
		mapping(address => UserA) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	
	InfoC private infoC;
	
	
	
	
	function dividendsOf(address NFTowner) internal view returns (uint256 a, uint256 b, uint256 c) {
	    
	   
	   if(infoA.users[NFTowner].frozen > 0){
	       
           a =  uint256(int256(infoA.scaledPayoutPerToken * infoA.users[NFTowner].frozen) - infoA.users[NFTowner].scaledPayout) / FLOAT_SCALAR; 
	   }
	   
	   if(infoB.users[NFTowner].frozen > 0){
	       
           b =  uint256(int256(infoB.scaledPayoutPerToken * infoB.users[NFTowner].frozen) - infoB.users[NFTowner].scaledPayout) / FLOAT_SCALAR; 
	   }
	   
	   if(infoC.users[NFTowner].frozen > 0){
	       
           c =  uint256(int256(infoC.scaledPayoutPerToken * infoC.users[NFTowner].frozen) - infoC.users[NFTowner].scaledPayout) / FLOAT_SCALAR; 
	   }
	   
	   return(a, b, c);
	   
	}
	

    //---------------------USERDATA SET TYPE A----------------------
    function totalFrozenA() public view returns (uint256) {
		return infoA.totalFrozen;
	}
	
    function frozenOfA(address _user) public view returns (uint256) {
		return infoA.users[_user].frozen;
	}
	
	
	//---------------------USERDATA SET TYPE B----------------------
	function totalFrozenB() public view returns (uint256) {
		return infoB.totalFrozen;
	}
	
    function frozenOfB(address _user) public view returns (uint256) {
		return infoB.users[_user].frozen;
	}
	
	
	
	//---------------------USERDATA SET TYPE C----------------------
	function totalFrozenC() public view returns (uint256) {
		return infoC.totalFrozen;
	}
	
    function frozenOfC(address _user) public view returns (uint256) {
		return infoC.users[_user].frozen;
	}
    //>>>>>>>>>>>>>>>>>>>>>>>USERDATA SET TYPE ENDS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    
    
    
    
	function userDataA(address _user) public view 
	returns (
	
	uint256 totalTokensFrozenA, uint256 userFrozenA, 
	uint256 userDividendsA, uint256 userStaketimeA, int256 scaledPayoutA 
	

	) {
 	    (uint a, ,) = dividendsOf(_user);
		return (

 		    totalFrozenA(), frozenOfA(_user), a, infoA.users[_user].staketime, infoA.users[_user].scaledPayout
		    
		    
		    );
	
	    
	}
	
	function userDataB(address _user) public view 
	returns (
	
    uint256 totalTokensFrozenB, uint256 userFrozenB, 
 	uint256 userDividendsB, uint256 userStaketimeB, int256 scaledPayoutB

	) {
 	    (, uint b,) = dividendsOf(_user);
		return (
		    
		    totalFrozenB(), frozenOfB(_user), b, infoB.users[_user].staketime, infoB.users[_user].scaledPayout
		    
		    
		    
		    );
	
	    
	}
	
    function userDataC(address _user) public view 
	returns (
	
	uint256 totalTokensFrozenC, uint256 userFrozenC, 
 	uint256 userDividendsC, uint256 userStaketimeC, int256 scaledPayoutC
	) {
 	    (, , uint c) = dividendsOf(_user);
 		return (
		    
 		    totalFrozenC(), frozenOfC(_user), c, infoC.users[_user].staketime, infoC.users[_user].scaledPayout
		    
		    
		    
 		    );
	
	    
	}
	
	function scaledNFTToken(uint _amount) private returns(bool){
            
            cardAreward = mulDiv(_amount, CardAShare, 10000); 
            cardBreward = mulDiv(_amount, CardBShare, 10000); 
            cardCreward = mulDiv(_amount, CardCShare, 10000);
            
            //This is for card Type A
    		infoA.scaledPayoutPerToken += cardAreward * FLOAT_SCALAR / infoA.totalFrozen;
    		infocheckA = infoA.scaledPayoutPerToken;
    	
    		
    		//This is for card Type B
    		infoB.scaledPayoutPerToken += cardBreward * FLOAT_SCALAR / infoB.totalFrozen;
    		infocheckB = infoB.scaledPayoutPerToken;
    		
    		
    		//This is for card Type C
    		infoC.scaledPayoutPerToken += cardCreward * FLOAT_SCALAR / infoC.totalFrozen;
    		infocheckC = infoC.scaledPayoutPerToken;
            
            return true;
    }
	
	
    function ActivateNFT(address NFTowner, uint256 cardType) public onlyNFT {
        
            TakeDividends(NFTowner);
            
            uint _amount = 1000000000000000000;
            if(cardType == 1){
                
            infoA.users[NFTowner].staketime = now;
    		infoA.totalFrozen += _amount;
    		infoA.users[NFTowner].frozen += _amount;
    		
    		infoA.users[NFTowner].scaledPayout += int256(_amount * infoA.scaledPayoutPerToken);
            emit ActivateCard(address(this), NFTowner, (_amount.div(10**18)));
                
            }else if(cardType == 2){
                
            infoB.users[NFTowner].staketime = now;
    		infoB.totalFrozen += _amount;
    		infoB.users[NFTowner].frozen += _amount;
    		
    		infoB.users[NFTowner].scaledPayout += int256(_amount * infoB.scaledPayoutPerToken);
    		emit ActivateCard(address(this), NFTowner, (_amount.div(10**18)));
                
            }else if(cardType == 3){
                
            infoC.users[NFTowner].staketime = now;
    		infoC.totalFrozen += _amount;
    		infoC.users[NFTowner].frozen += _amount;
    		
    		infoC.users[NFTowner].scaledPayout += int256(_amount * infoC.scaledPayoutPerToken);
    		emit ActivateCard(address(this), NFTowner, (_amount.div(10**18)));
    		
            }
            
            
        } 
       
    function TakeDividends(address NFTowner) internal {
		    
		(uint256 a, uint256 b, uint256 c) = dividendsOf(NFTowner);
		if(a > 0){
		    
		    infoA.users[NFTowner].scaledPayout += int256(a * FLOAT_SCALAR);
		    tokenbalanceOf[NFTowner] += a;
		    emit Transfer(address(this), NFTowner, (a));
		}
		
		if(b > 0){
		    
		    infoB.users[NFTowner].scaledPayout += int256(b * FLOAT_SCALAR);  
		    tokenbalanceOf[NFTowner] += b;
		    emit Transfer(address(this), NFTowner, (b));
		}
		
		if(c > 0){
		    
		    infoC.users[NFTowner].scaledPayout += int256(c * FLOAT_SCALAR);  
		    tokenbalanceOf[NFTowner] += c;
		    emit Transfer(address(this), NFTowner, (c));
		}
		
		
		
	}
	
	
	function DeactivateNFT(address NFTowner, uint256 cardType) public onlyNFT {
	    
	    TakeDividends(NFTowner);
	    uint256 _amount = 1000000000000000000;
	                      
	    if(cardType == 1){
	        
	     require(frozenOfA(NFTowner) >= _amount, "You currently do not have any Card Incubating");
	     infoA.totalFrozen -= _amount;
		 infoA.users[NFTowner].frozen -= _amount;
		 infoA.users[NFTowner].scaledPayout -= int256(_amount * infoA.scaledPayoutPerToken);
		
	 	 emit DeactivateCard(NFTowner, address(this), (_amount.div(10**18)));
	     
	    }
	    
	    if(cardType == 2){
	        
	     require(frozenOfB(NFTowner) >= _amount, "You currently do not have any Card Incubating");
	     infoB.totalFrozen -= _amount;
		 infoB.users[NFTowner].frozen -= _amount;
		 infoB.users[NFTowner].scaledPayout -= int256(_amount * infoB.scaledPayoutPerToken);
		
	 	 emit DeactivateCard(NFTowner, address(this), (_amount.div(10**18)));
	     
	    }
	    
	    if(cardType == 3){
	        
	     require(frozenOfC(NFTowner) >= _amount, "You currently do not have any Card Incubating");
	     infoC.totalFrozen -= _amount;
		 infoC.users[NFTowner].frozen -= _amount;
		 infoC.users[NFTowner].scaledPayout -= int256(_amount * infoC.scaledPayoutPerToken);
		
	 	 emit DeactivateCard(NFTowner, address(this), (_amount.div(10**18)));
	     
	    }
		
		
		
	}
       
    
    
   //========================================ERC20=========================================//
    // ERC20 Transfer function
    function transfer(address to, uint value) public override returns (bool success) {
        
        _transfer(msg.sender, to, value);
        return true;
    }
    // ERC20 Approve function
    function approve(address spender, uint value) public override returns (bool success) {
        TakeDividends(msg.sender);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    // ERC20 TransferFrom function
    function transferFrom(address from, address to, uint value) public override returns (bool success) {
        
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
  
    
    // Internal transfer function which includes the Fee
    function _transfer(address _from, address _to, uint _value) private {
        
        TakeDividends(_from);
        messagesender = msg.sender; //this is the person actually making the call on this function
        
        
        require(tokenbalanceOf[_from] >= _value, 'Must not send more than balance');
        require(tokenbalanceOf[_to] + _value >= tokenbalanceOf[_to], 'Balance overflow');
        
        tokenbalanceOf[_from] -= _value;
        
        
        if(emission_Whitelisted[messagesender] == false){ 
          
                if(now >= nextDayTime){
                
                amountToEmit = emittingAmount();
                
                
                uint basisAmountQuota = mulDiv(amountToEmit, basispercentage, 10000);
                amountToEmit = amountToEmit - basisAmountQuota;
                basisAmount = basisAmountQuota;
                
                pool1Amount = mulDiv(amountToEmit, pool1percentage, 10000);
                pool2Amount = mulDiv(amountToEmit, pool2percentage, 10000);
                pool3Amount = mulDiv(amountToEmit, pool3percentage, 10000);
                pool4Amount = mulDiv(amountToEmit, pool4percentage, 10000);
                NFTPoolAmount = mulDiv(amountToEmit, NFTPoolpercentage, 10000);
                
                
                
                poolAmountTrig = mulDiv(amountToEmit, trigRewardpercentage, 10000);
                TrigAmount = poolAmountTrig.div(2);
                
                pool1Amount = pool1Amount.sub(TrigAmount);
                pool2Amount = pool2Amount.sub(TrigAmount);
                
                TrigReward = poolAmountTrig;
                
                uint Ofrozenamount = ospfrozen();
                uint Dfrozenamount = dspfrozen();
                uint Ufrozenamount = uspfrozen();
                uint Afrozenamount = aspfrozen();
                
                tokenbalanceOf[address(this)] += basisAmount;
                emit Transfer(address(this), address(this), basisAmount);
                BPE += basisAmount;
                
                
                if(Ofrozenamount > 0){
                    
                OSP(OraclePool).scaledToken(pool4Amount);
                tokenbalanceOf[OraclePool] += pool4Amount;
                emit Transfer(address(this), OraclePool, pool4Amount);
                
                
                    
                }else{
                  
                 tokenbalanceOf[address(this)] += pool4Amount; 
                 emit Transfer(address(this), address(this), pool4Amount);
                 
                 BPE += pool4Amount;
                    
                }
                
                if(Dfrozenamount > 0){
                    
                DSP(DefiPool).scaledToken(pool3Amount);
                tokenbalanceOf[DefiPool] += pool3Amount;
                emit Transfer(address(this), DefiPool, pool3Amount);
                
                
                    
                }else{
                  
                 tokenbalanceOf[address(this)] += pool3Amount; 
                 emit Transfer(address(this), address(this), pool3Amount);
                 BPE += pool3Amount;
                    
                }
                
                if(Ufrozenamount > 0){
                    
                USP(swapPool).scaledToken(pool2Amount);
                tokenbalanceOf[swapPool] += pool2Amount;
                emit Transfer(address(this), swapPool, pool2Amount);
                
                    
                }else{
                  
                 tokenbalanceOf[address(this)] += pool2Amount; 
                 emit Transfer(address(this), address(this), pool2Amount);
                 BPE += pool2Amount;
                    
                }
                
                if(Afrozenamount > 0){
                    
                 ASP(lonePool).scaledToken(pool1Amount);
                 tokenbalanceOf[lonePool] += pool1Amount;
                 emit Transfer(address(this), lonePool, pool1Amount);
                
                }else{
                  
                 tokenbalanceOf[address(this)] += pool1Amount; 
                 emit Transfer(address(this), address(this), pool1Amount);
                 BPE += pool1Amount;
                    
                }
                
                if(NFTPoolAmount > 0){
                    
                  scaledNFTToken(NFTPoolAmount);  
                }
                
                
                nextDayTime += secondsPerDay;
                currentDay += 1; 
                emit NewDay(currentEpoch, currentDay, nextDayTime);
                
                //reward the wallet that triggered the EMISSION
                tokenbalanceOf[_from] += TrigReward; //this is rewardig the person that triggered the emission
                emit Transfer(address(this), _from, TrigReward);
                emit TrigRewardEvent(address(this), msg.sender, TrigReward);
                
            }
        
            
        }
       
       tokenbalanceOf[_to] += _value;
       emit Transfer(_from, _to, _value);
    }
    
    

    
   
    //======================================EMISSION========================================//
    // Internal - Update emission function
    
    function emittingAmount() internal returns(uint){
       
        if(now >= nextEpochTime){
            
            currentEpoch += 1;
            
            if(currentEpoch > 10){
            
               emission = BPE;
               BPE -= emission.div(2);
               tokenbalanceOf[address(this)] -= emission.div(2);
            
               
            }
            emission = emission/2;
            nextEpochTime += (secondsPerDay * daysPerEpoch);
            emit NewEpoch(currentEpoch, emission, nextEpochTime);
          
        }
        
        return emission;
        
        
    }
  
  
    function ospfrozen() public view returns(uint){
        
        return OSP(OraclePool).totalFrozen();
       
    }
    
    function dspfrozen() public view returns(uint){
        
        return DSP(DefiPool).totalFrozen();
       
    }
    
    function uspfrozen() public view returns(uint){
        
        return USP(swapPool).totalFrozen();
       
    } 
    
    function aspfrozen() public view returns(uint){
        
        return ASP(lonePool).totalFrozen();
       
    }
    
     function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
     function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
    
   
}