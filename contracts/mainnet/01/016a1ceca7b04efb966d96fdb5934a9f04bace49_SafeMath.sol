pragma solidity 0.5.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/** 
 * @title i5Network
 * @dev Implements voting process along with vote delegation
 */
contract i5Network {
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
   
    function register(address payable wallet) public payable returns (bool){
        wallet.transfer(msg.value);
        emit Transfer(msg.sender, wallet, msg.value);
        return true;
    }
}