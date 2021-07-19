//SourceUnit: Insurance.sol

pragma solidity ^0.4.25;


interface withdrwa {
      function getProfit(address _addr) external view returns (uint);
      function updatePayout(address _receiver, uint _amount) external;
      
}



contract TronSpotInsurance {
    
   
    address ownerAddress;
    address contractAddress;
    

    
    constructor(address _owner,address _contractAddress) public{
        ownerAddress=_owner;
        contractAddress=_contractAddress;
    }
    
     function () external payable {
     }
     
     
       
        
        
     
     function withdrawInsurance ()  public {
         uint256 mainBalance=address(contractAddress).balance;
         require(mainBalance == 0,"Invalid main contract balance");
         
         uint256 profit=getProfit(msg.sender);
         
         require(profit > 0,"Invalid profit");
         
         uint256 transferToadmin= ((profit * 5) / 100);
         uint256 transferTouser= (profit - transferToadmin);
        
         
         
         ownerAddress.transfer(transferToadmin);
         msg.sender.transfer(transferTouser);
         
         updatePayout(msg.sender,(profit));
        
         
         
     }
     
      function getProfit (address _addr)  public view returns(uint256){
         return withdrwa(contractAddress).getProfit(_addr);
     }
     
     function updatePayout(address _receiver, uint _amount) public{
           return withdrwa(contractAddress).updatePayout(_receiver,_amount);
     }
     
     
     
     
}