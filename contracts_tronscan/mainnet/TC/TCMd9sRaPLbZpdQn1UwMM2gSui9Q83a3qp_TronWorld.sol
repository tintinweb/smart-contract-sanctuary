//SourceUnit: TronWorld.sol

pragma solidity ^0.6.0;

/**
* https://tronsworld.net/
* 
**/
contract TronWorld {
   struct User {
        bool isExist;  
        uint referrerId;  
        uint direct;
        uint Totalamount;
    } 
    
    uint LastSrNo= 100000;  
    address owner;
    mapping(address => User) public RegUserlist; 
    mapping(address => uint[]) public Unitlist;   
    
    event Registration(address indexed user, uint indexed referrerId, uint amount, uint srno); 
    event UnitBook(address indexed from,uint indexed userid, uint amount);
    
    constructor(address ownerWallet, address regAddress) public {      
        owner = ownerWallet; 
        
        uint32 size;
        assembly {
            size := extcodesize(regAddress)
        }
        require(size == 0, "cannot be a contract");
        User memory user = User({
            isExist:true, 
            referrerId: 1 ,
            direct: uint(0),
            Totalamount: uint(0)
        });
        RegUserlist[regAddress] = user;
    }
    
    function RegisterUser(uint referrerId,address referrerAddress,uint REGESTRATION_FESS ) public payable {
        registration(msg.sender, referrerId, referrerAddress, REGESTRATION_FESS);
    }  
    
    function registration(address userAddress,  uint referrerId ,address referrerAddress, uint REGESTRATION_FESS) private {
        
        require(REGESTRATION_FESS >=250000000 , "Minimum joining fee 250");
        require(REGESTRATION_FESS <=50000000000 , "Maximum joining fee 50000");
        
        require(msg.value == REGESTRATION_FESS, "Insufficient Balance ");
        require(!isUserExists(msg.sender), "user exists");  
        require(isUserExists(referrerAddress), "Invalid referrer Address");  
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "can not be a contract");   
        
        User memory user = User({
            isExist:true, 
            referrerId: 1 ,
            direct :uint(0),
            Totalamount:REGESTRATION_FESS
        });
        RegUserlist[userAddress] = user;
        RegUserlist[referrerAddress].direct++;
        DeductBalance(REGESTRATION_FESS); 
        LastSrNo++;  
        emit Registration(userAddress, referrerId, REGESTRATION_FESS, LastSrNo);  
    }
    
     function DepositTRX(uint userid, uint Amount) public payable {
        require(Amount >=250000000 , "Minimum joining fee 250");
        require(Amount <=50000000000 , "Maximum joining fee 50000");
        require(msg.value == Amount, "Insufficient Balance ");
        require(isUserExists(msg.sender), "Invalid Wallet"); 
        Unitlist[msg.sender].push(Amount);
        DeductBalance(Amount); 
        RegUserlist[msg.sender].Totalamount= RegUserlist[msg.sender].Totalamount+Amount;
        emit UnitBook(msg.sender,userid, Amount); 
         
    }
    function GetTotalTopUpCount(address _user) public view returns (uint) {
       return  Unitlist[_user].length;
    }  
    
    function GetTopUp(address _user,uint srno) public view returns (uint) {
       return (Unitlist[_user][srno]);       
    } 
    
     function GetTotalTopUpList(address _user) public view returns (uint[] memory) {
        uint[] memory units = new uint[](Unitlist[_user].length);
        uint numberofTopup = 0;
        for(uint i = 0; i < Unitlist[_user].length;  i++) {
            units[numberofTopup] = Unitlist[_user][i];
            numberofTopup++;
        }
        return units;
    }
    
    function isUserExists(address user) public view returns (bool) {
       return (RegUserlist[user].isExist);
    }   
    
    function DeductBalance(uint Amount) private
    {       
         if (!address(uint160(owner)).send(Amount))
         {
            return  address(uint160(owner)).transfer(Amount);
         }
    }
}