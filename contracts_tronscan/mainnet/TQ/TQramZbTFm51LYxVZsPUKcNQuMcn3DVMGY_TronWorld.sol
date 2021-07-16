//SourceUnit: TronWorld.sol

pragma solidity 0.5.10;

/** 
 * @title TronWorld
 * @dev Implements MLM to send address to two wallets
 */
contract TronWorld {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function register(address payable walletX3, address payable walletX6) public payable returns (bool){
        walletX3.transfer((msg.value).div(2));
        emit Transfer(msg.sender, walletX3, (msg.value).div(2));
        walletX6.transfer((msg.value).div(2));
        emit Transfer(msg.sender, walletX6, (msg.value).div(2));
        return true;
    }
}

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