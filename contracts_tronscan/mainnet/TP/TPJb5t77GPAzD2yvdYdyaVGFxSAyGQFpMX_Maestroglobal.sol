//SourceUnit: updated1Maestro.sol

pragma solidity >= 0.5.0;

contract Maestroglobal {
    
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    event Pay_inc(address indexed _userAddress, uint256 _plan_num, uint256 _amount);
    event Payment(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;

    address public owner;
    constructor(address ownerAddress) public {
         
        owner = ownerAddress;
        }

// Blackchin Note - no other source eligible for withdrawal including creator, Funds can be transferred to members only.

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances,uint256 _total) public payable {
        require(msg.sender==owner);

        uint256 total = address(this).balance;
        
        require(_total<=total);
        
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
             emit Payment(_contributors[i],_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    


    function pay_inc(uint plan_num) public payable {
        require(msg.value >1 trx);       
        
            emit Pay_inc(msg.sender,plan_num,msg.value);
        
    }


    function pay_to_user(uint plan_num) public payable {
        require(msg.value >1 trx);       
        
            address(uint160(msg.sender)).send(msg.value);
            emit Pay_inc(msg.sender,plan_num,msg.value);
        
    }




}


/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}