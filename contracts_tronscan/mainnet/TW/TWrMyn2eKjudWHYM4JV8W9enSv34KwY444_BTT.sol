//SourceUnit: bit.sol

pragma solidity >= 0.5.0;

contract BTT{
  
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
     address public owner;
     
     
       constructor(address ownerAddress) public {
        owner = ownerAddress;  
    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
		    trcToken id=1002000;
        for (i; i < _contributors.length; i++) {
			_contributors[i].transferToken(_balances[i],id);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        trcToken id=1002000;
        for (uint i = 0; i < _userAddresses.length; i++) {
           // _userAddresses[i].transfer(_amount);
			_userAddresses[i].transferToken(_amount,id);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }
    
     function withdrawLostTRXFromBalance() public payable{
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
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