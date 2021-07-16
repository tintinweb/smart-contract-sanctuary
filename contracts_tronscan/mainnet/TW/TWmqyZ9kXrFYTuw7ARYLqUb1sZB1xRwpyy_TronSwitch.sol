//SourceUnit: tronswitch.sol

/*
www.tronswitch.io
                                                                                                                      
 888888888888  88888888ba     ,ad8888ba,    888b      88  8888888888  88           88  8888888888  88888888888888  888888888  88       88
      88       88      "8b   d8"'    `"8b   8888b     88  88          88           88      88            88        88         88       88
      88       88      ,8P  d8'        `8b  88 `8b    88  88          88           88      88            88        88         88       88
     88       88aaaaaa8P'  88          88  88  `8b   88   8888888888  88   8888    88      88            88        88         88888888888      
     88       88""""88'    88          88  88   `8b  88           88  88   88 88   88      88            88        88         88       88
     88       88    `8b    Y8,        ,8P  88    `8b 88           88  88  88   88  88      88            88        88         88       88
    88       88     `8b    Y8a.    .a8P   88     `8888            88  88 88     88 88      88            88        88         88       88
    88       88      `8b    `"Y8888Y"'    88      `888    8888888888  8888       8888  8888888888        88        888888888  88       88
                                                                                                                        
                                                                                                                      
www.tronswitch.io
*/

pragma solidity >= 0.5.8;

contract TronSwitch {
    
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
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