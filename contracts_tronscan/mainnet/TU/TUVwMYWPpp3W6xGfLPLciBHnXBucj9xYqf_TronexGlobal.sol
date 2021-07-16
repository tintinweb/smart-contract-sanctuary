//SourceUnit: tronixglobal.sol

pragma solidity >= 0.5.0;


/**
*  TCoVTaTLU6vxwKnGr4drW9VMBeA82qxk8V
* 
**/

contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public ownerWallet;
    address payable public newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract TronexGlobal is ownerShip {
    
    using SafeMath for uint256;
    uint LastSrNo= 100000;  
    mapping(uint => uint) public P_LEVEL_PRICE;
    struct User {
        uint srno;  
        bool isExist;      
        address userAddress;      
        uint referrerId;  
        address referrerAddress;
        uint Direct;
        uint LevelIncome;
        mapping(uint => SlotBookingStruct) slotlist;       
    }    

   struct SlotBookingStruct {      
        bool isExist;       
        uint slotid; 
        uint amount;  
    } 

    mapping(address => User) public RegUserlist;    
    mapping(uint => address) public UserIdList;      
    address public owner;
    
    event Registration(address indexed user, uint indexed srno, uint indexed referrerId, uint amount); 
    event SlotBook(address indexed from,uint indexed userid, uint indexed slotid, uint amount);
	event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
	
    constructor(address ownerWallet, address regAddress) public {      
        owner = ownerWallet; 
        require(!isContract(regAddress),  "cannot be a contract");
        User memory user = User({
            srno:LastSrNo,
            isExist:true,              
            userAddress: address(0),          
            referrerId: 1 ,
            referrerAddress: address(0), 
            Direct :uint(0),
            LevelIncome :uint(0)
        });

        RegUserlist[regAddress] = user;
        RegUserlist[regAddress].userAddress =regAddress;  
        SlotBookingStruct memory userslot = SlotBookingStruct({          
            isExist:true,            
            amount: 250000000 ,   
            slotid: 2   
        });
        RegUserlist[regAddress].slotlist[2] =userslot;
        UserIdList[LastSrNo] = regAddress;
        LastSrNo++;
    }

    function RegisterUser(uint referrerId) public payable {
        registration(msg.sender, referrerId);
    }  

    function registration(address userAddress,  uint referrerId) private {
        require(msg.value == 250 trx, "Insufficient Balance ");
        require(!isUserExists(msg.sender), "user exists");  
        require(isUserExists(UserIdList[referrerId]), "Invalid referrer Address");  
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
       require(size == 0, "cannot be a contract");       
       User memory user = User({
            srno:LastSrNo,
            isExist:true,
            userAddress: address(0) ,              
            referrerId : referrerId,
            referrerAddress: UserIdList[referrerId], 
            Direct :uint(0),
            LevelIncome :uint(0)
        });

        RegUserlist[userAddress] = user;
        RegUserlist[userAddress].userAddress =userAddress;    
        SlotBookingStruct memory userslot = SlotBookingStruct({          
            isExist:true,            
            amount: msg.value  ,   
            slotid: 2    
        });
        RegUserlist[userAddress].slotlist[2] =userslot;
        UserIdList[LastSrNo] = userAddress;
        RegUserlist[UserIdList[referrerId]].Direct++;
        LastSrNo++;      
        DeductBalance(msg.value ); 
        emit Registration(userAddress,RegUserlist[userAddress].srno, referrerId,msg.value);     

    }
 
    function SlotBooking(uint userid,uint slotid, uint Amount) public payable {
        require(msg.value == Amount, "Insufficient Balance ");
        require(isUserExists(msg.sender), "Invalid Wallet"); 
        require(!isSlotBook(msg.sender,slotid), "slot already exist");   
      
        SlotBookingStruct memory userslot = SlotBookingStruct({          
            isExist:true,            
            amount: Amount ,   
            slotid: slotid    
        });

        RegUserlist[msg.sender].slotlist[slotid] =userslot;
        DeductBalance(Amount); 
        emit SlotBook(msg.sender,userid,slotid, Amount); 
         
    }

    function GetSlotamount(address user, uint slotid) public view returns (uint) {
          return (RegUserlist[user].slotlist[slotid].amount);       
    } 

    function GetSlot(address user, uint slotid) public view returns (bool,uint,uint) {
        SlotBookingStruct storage slot= RegUserlist[user].slotlist[slotid];
        return (slot.isExist,slot.slotid, slot.amount );       
    }     

    function isUserExists(address user) public view returns (bool) {
       return (RegUserlist[user].isExist);
    }   

    function isUserSrnoExists(uint srno) public view returns (bool) {
          return (UserIdList[srno] != address(0x410000000000000000000000000000000000000000));       
    } 

   function isSlotBook(address user, uint slotid) public view returns (bool) {
          return (RegUserlist[user].slotlist[slotid].isExist);       
    } 
   function DeductBalance(uint Amount) private
    {       
         if (!address(uint160(owner)).send(Amount))
         {
            return  address(uint160(owner)).transfer(Amount);
         }
    }
	 function withdrawLostTRXFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}