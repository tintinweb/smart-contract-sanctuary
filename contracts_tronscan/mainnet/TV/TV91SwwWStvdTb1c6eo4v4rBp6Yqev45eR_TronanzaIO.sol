//SourceUnit: TronanzaPROSimple.sol

pragma solidity ^0.5.10;


/**
* https://tronanza.io/
* 
**/

contract TronanzaIO {
    
    
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

    function RegisterUser(uint referrerId,address referrerAddress,uint REGESTRATION_FESS ) public payable {
        registration(msg.sender, referrerId, referrerAddress, REGESTRATION_FESS);
    }  

    function registration(address userAddress,  uint referrerId ,address referrerAddress, uint REGESTRATION_FESS) private {
        require(msg.value == REGESTRATION_FESS, "Insufficient Balance ");
        require(!isUserExists(msg.sender), "user exists");  
        require(isUserExists(referrerAddress), "Invalid referrer Address");  
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
            referrerAddress: referrerAddress, 
            Direct :uint(0),
            LevelIncome :uint(0)
        });

        RegUserlist[userAddress] = user;
        RegUserlist[userAddress].userAddress =userAddress;    
        SlotBookingStruct memory userslot = SlotBookingStruct({          
            isExist:true,            
            amount: REGESTRATION_FESS ,   
            slotid: 2    
        });
        RegUserlist[userAddress].slotlist[2] =userslot;
        UserIdList[LastSrNo] = userAddress;
        RegUserlist[referrerAddress].Direct++;
        LastSrNo++;      
        DeductBalance(REGESTRATION_FESS); 
        emit Registration(userAddress,RegUserlist[userAddress].srno, referrerId,  REGESTRATION_FESS);     

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

 



}