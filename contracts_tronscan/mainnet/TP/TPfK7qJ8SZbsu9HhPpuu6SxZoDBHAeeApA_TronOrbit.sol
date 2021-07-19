//SourceUnit: TronOrbit.sol

pragma solidity ^0.5.10;


/**
* https://tronorbit.io/
* 
**/

contract TronOrbit {
    
    uint LastSrNo= 100000;  
    struct User {
        uint srno;  
        bool isExist;      
        address userAddress;      
        uint referrerId;  
        address referrerAddress;
        uint Direct;
        uint TotalUnit;
    }    

    struct UnitBookingStruct {  
        uint unit; 
        uint amount;  
    } 

    mapping(address => User) public RegUserlist;    
    mapping(address => UnitBookingStruct[]) public Unitlist;
    
    address public owner;
    
    event Registration(address indexed user, uint indexed srno, uint indexed referrerId, uint amount); 
    event UnitBook(address indexed from,uint indexed userid, uint indexed unit, uint amount);

    constructor(address ownerWallet, address regAddress) public {      
        owner = ownerWallet; 
        require(!isContract(regAddress),  "cannot be a contract");
        User memory user = User({
            srno:LastSrNo,
            isExist:true,              
            userAddress: regAddress,          
            referrerId: 1 ,
            referrerAddress: address(0), 
            Direct :uint(0),
            TotalUnit :1
        });
        
        UnitBookingStruct memory usertopup = UnitBookingStruct({          
           unit:1 ,       
           amount: 250000000 
        });
   
        RegUserlist[regAddress] = user;
        Unitlist[regAddress].push(usertopup);
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
            userAddress: userAddress ,              
            referrerId : referrerId,
            referrerAddress: referrerAddress, 
            Direct :uint(0),
            TotalUnit :1
        });
       
       
        RegUserlist[userAddress] = user;
        RegUserlist[referrerAddress].Direct++;
        LastSrNo++;  
        
         UnitBookingStruct memory usertopup = UnitBookingStruct({ 
            amount: REGESTRATION_FESS ,   
            unit: 1    
        });
        
        Unitlist[userAddress].push(usertopup);
        DeductBalance(REGESTRATION_FESS); 
        emit Registration(userAddress,RegUserlist[userAddress].srno, referrerId,  REGESTRATION_FESS);     

    }
 
    function UnitBooking(uint userid,uint unit, uint Amount) public payable {
        require(msg.value == Amount, "Insufficient Balance ");
        require(isUserExists(msg.sender), "Invalid Wallet"); 
        UnitBookingStruct memory usertopup = UnitBookingStruct({ 
            amount: Amount ,   
            unit: unit    
        });

        RegUserlist[msg.sender].TotalUnit= RegUserlist[msg.sender].TotalUnit+unit;
        Unitlist[msg.sender].push(usertopup);
        DeductBalance(Amount); 
        emit UnitBook(msg.sender,userid,unit, Amount); 
         
    }

    function isUserExists(address user) public view returns (bool) {
       return (RegUserlist[user].isExist);
    }   
  
    
    function GetTotalTopUpCount(address _user) public view returns (uint) {
       return  Unitlist[_user].length;
    }  
    
    function GetTotalTopUp(address _user,uint srno) public view returns (uint,uint) {
       UnitBookingStruct memory topup= Unitlist[_user][srno];
       return (topup.unit, topup.amount );       
    } 
    function GetTotalTopUpList(address _user) public view returns (uint[] memory) {
        uint[] memory units = new uint[](Unitlist[_user].length);
        uint numberofTopup = 0;
    
        for(uint i = 0; i < Unitlist[_user].length;  i++) {
            units[numberofTopup] = Unitlist[_user][i].unit;
            numberofTopup++;
        }
        return units;
    }
    
    function GetTotalTopUpListWithAmount(address _user) public view returns (uint[] memory,uint[] memory) {
        uint[] memory units = new uint[](Unitlist[_user].length);
        uint[] memory amountList = new uint[](Unitlist[_user].length);
        uint numberofTopup = 0;
        for(uint i = 0; i < Unitlist[_user].length;  i++) {
            units[numberofTopup] = Unitlist[_user][i].unit;
            amountList[numberofTopup] = Unitlist[_user][i].amount;
            numberofTopup++;
        }
        return (units, amountList);
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