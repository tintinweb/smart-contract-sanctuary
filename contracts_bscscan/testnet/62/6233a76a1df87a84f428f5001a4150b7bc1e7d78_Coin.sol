/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity >=0.7.0 <0.9.0;


contract Coin {
    // The keyword "public" makes those variables
    // readable from outside.
   
    mapping (address => uint) public balances;

    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);

    function send(address receiver) external payable {
       payable(msg.sender).transfer(msg.value);
        
        emit Sent(msg.sender, receiver, msg.value);
    }
}