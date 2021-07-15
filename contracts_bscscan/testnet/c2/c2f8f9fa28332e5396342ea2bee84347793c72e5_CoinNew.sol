/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity >=0.7.0 <0.9.0;


contract CoinNew {
    // The keyword "public" makes those variables
    // readable from outside.
   
 

    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);
      event sendBNB(address _user, uint _amount);

   function _sendBNB(address _user, uint _amount) internal returns(bool tStatus) {
        require(address(this).balance >= _amount, "Insufficient Balance in Contract");
        tStatus = (payable(_user)).send(_amount);
        return tStatus;
    }
     
}