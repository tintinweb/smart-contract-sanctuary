pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract MultiEthSender {

    using SafeMath for uint256;

    event Send(uint256 _amount, address indexed _receiver);

    modifier enoughBalance(uint256 amount, address[] list) {
        uint256 totalAmount = amount.mul(list.length);
        require(address(this).balance >= totalAmount);
        _;
    }

    constructor() public {

    }

    function () public payable {
        require(msg.value >= 0);
    }

    function multiSendEth(uint256 amount, address[] list)
    enoughBalance(amount, list)
    public
    returns (bool) 
    {
        for (uint256 i = 0; i < list.length; i++) {
            address(list[i]).transfer(amount);
            emit Send(amount, address(list[i]));
        }
        return true;
    }
}