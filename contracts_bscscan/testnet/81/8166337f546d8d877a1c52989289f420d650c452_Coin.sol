/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity >=0.7.0 <0.9.0;



library SafeMath {
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  assert(b <= a);
  return a - b;
}

function add(uint256 a, uint256 b) internal pure returns (uint256) {
   uint256 c = a + b;
   assert(c >= a);
   return c;
} }


contract Coin {
    using SafeMath for uint256;
    // The keyword "public" makes those variables
    // readable from outside.
    
    mapping (address => uint) public balances;

    // Events allow light clients to react on
    // changes efficiently.
    event Sent( address receiver, uint256 amount);

  

    function send(address payable receiver, uint256  amount)  public  {
        if (balances[msg.sender] < amount) return;
     //   balances[msg.sender] = balances[msg.sender].sub(amount);
      //  balances[receiver ] = balances[receiver].add(amount);
          receiver.transfer(amount);
        
        emit Sent( receiver, amount);
        
    }
}