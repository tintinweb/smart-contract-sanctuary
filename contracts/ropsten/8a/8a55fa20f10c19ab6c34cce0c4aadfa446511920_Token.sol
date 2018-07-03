pragma solidity ^0.4.18;

library SafeMath {

 /**
 * @dev Multiplies two numbers, throws on overflow.
 */
 function mul(uint a, uint b) internal pure returns (uint) {
   if (a == 0) {
     return 0;
   }
   uint c = a * b;
   assert(c / a == b);
   return c;
 }

 /**
 * @dev Integer division of two numbers, truncating the quotient.
 */
 function div(uint a, uint b) internal pure returns (uint) {
   // assert(b > 0); // Solidity automatically throws when dividing by 0
   // uint256 c = a / b;
   // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
   return a / b;
 }

 /**
 * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
 */
 function sub(uint a, uint b) internal pure returns (uint) {
   assert(b <= a);
   return a - b;
 }

 /**
 * @dev Adds two numbers, throws on overflow.
 */
 function add(uint a, uint b) internal pure returns (uint) {
   uint c = a + b;
   assert(c >= a);
   return c;
 }
}

contract Token {
   
   using SafeMath for uint;
   
   uint public currentSupply = 0;
   
   uint public totalSupply = 1000000 * 1 ether;
   
   event Transfer(address from, address to, uint amount);
   
   mapping(address => uint) balances;
   
   function balanceOf(address tokenOwner) public constant returns (uint balance) {
       return balances[tokenOwner];
   }
   
   function transfer(address to, uint tokens) public returns (bool success) {
       balances[msg.sender] = balances[msg.sender].sub(tokens);
       balances[to] = balances[to].add(tokens);
       Transfer(msg.sender, to, tokens);
       return true;
   }
   
   function issueTokens(uint _tokens)
   public
   {
       address to = msg.sender;
       require((currentSupply + _tokens) <= totalSupply);

       balances[to] = balances[to].add(_tokens);
       totalSupply = totalSupply.add(_tokens);

       Transfer(0x0, to, _tokens);

}
}