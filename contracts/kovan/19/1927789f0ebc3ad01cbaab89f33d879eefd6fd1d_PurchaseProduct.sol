/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

contract PurchaseProduct {
     
     function receiveEth() external payable {
         
     }
     
     function paySeller_tshirt (address payable seller) external {
         seller.transfer(0.05 ether);
     }
     
     function paySeller_pants (address payable seller) external {
         seller.transfer(0.07 ether);
     }
 }