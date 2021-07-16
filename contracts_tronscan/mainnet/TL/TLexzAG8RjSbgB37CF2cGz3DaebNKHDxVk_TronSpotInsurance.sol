//SourceUnit: Tronins.sol

pragma solidity ^0.4.25;


interface withdrwa {
      function getProfit(address _addr) external view returns (uint);
      function updatePayout(address _receiver, uint _amount) external;
}


contract TronSpotInsurance {
    
    using SafeMath for uint256;
   
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
         
        
         
           uint256 transferToadmin=profit.mul(5).div(100);
           uint256 transferTouser= profit.sub(transferToadmin);
           
         
         ownerAddress.transfer(transferToadmin);
         msg.sender.transfer(transferTouser);
         updatePayout(msg.sender,(profit));
         
     }
     
      function getProfit (address _addr)  public view returns(uint256){
         return withdrwa(contractAddress).getProfit(_addr);
     }
     
     function updatePayout(address _receiver, uint _amount) internal{
           return withdrwa(contractAddress).updatePayout(_receiver,_amount);
     }
     
     
     
     
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}