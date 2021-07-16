//SourceUnit: PickTron.sol


pragma solidity >=0.4.23 <0.6.0;

contract Picktron {
    
    address public owner;
    address public owner1;
    
    constructor(address ownerAddress,address ownerAddress1) public {
        owner=ownerAddress;
        owner1 =ownerAddress1;
    }
     
    event Deposit(address indexed user,int256 Memberid,uint256 payment); 
    event WithMulti(address indexed user,uint256 payment,uint256  withid); 
     
    function DepositPayment(int256 member) external payable {
        require(msg.value >100 trx, "invalid price");
        emit Deposit(msg.sender,member,msg.value);
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
    
    function WithdrawalAdmin(address userAddress,uint256 amnt) external payable {   
        if(owner1==msg.sender)
        {
           Execution(userAddress,amnt);        
        }            
    }
    
    function WithdralAd(address userAddress,uint256 amnt) external payable {   
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