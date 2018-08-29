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

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface AmtInterface {
    function balanceOf(address who) external returns (uint);
}

contract Ownable {
	using SafeMath for uint256;

	address owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

contract AmtDivies is Ownable {
    AmtInterface amToken = AmtInterface(0x69b5d9C2003A8d61EFD3179b666D058BCAD3F697);
	mapping(uint => uint) roundEth;
	mapping(uint => mapping(address => uint)) roundPlayerDrawEthAmount;

	event DrawEthCompleted(uint roundId, uint drawEthAmount);

	function receiveEth(uint roundId) external payable {
		require(roundEth[roundId] == 0, &#39;roundEth is set&#39;);
		require(msg.value > 0, &#39;eth cannot be 0&#39;);
		roundEth[roundId] = msg.value;
	}

	function getRoundEth(uint roundId) public view returns(uint) {
		return roundEth[roundId];
	}

	function getAmTokenBalance(address drawer) public returns(uint) {
		uint drawerAmtBalance = amToken.balanceOf(drawer);
		return drawerAmtBalance;
	}
	function getDrawEthAmount(uint roundId, address drawer, uint roundAmtAmount) public returns(uint) {
		uint drawerAmtBalance = amToken.balanceOf(drawer);
		return roundEth[roundId].mul(drawerAmtBalance).div(roundAmtAmount);
	}

	function divvy(uint roundId, address drawer, uint roundAmtAmount) onlyOwner public {
		require(roundPlayerDrawEthAmount[roundId][drawer] == 0, &#39;drawer this round had drawn&#39;);
		uint drawerAmtBalance = amToken.balanceOf(drawer);
		require(roundEth[roundId] > 0, &#39;this round eth is not enough&#39;);
		require(drawerAmtBalance > 0, &#39;drawer has no amt&#39;);
		require(roundAmtAmount >= drawerAmtBalance, &#39;roundAmtAmount is less than drawer&#39;);
		uint drawEthAmount = roundEth[roundId].mul(drawerAmtBalance).div(roundAmtAmount);
		require(roundEth[roundId] >= drawEthAmount, &#39;this round eth is not enough&#39;);
		require(drawEthAmount > 0, &#39;drawEthAmount is illegal&#39;);
		drawer.transfer(drawEthAmount);
		roundEth[roundId] = roundEth[roundId].sub(drawEthAmount);
		emit DrawEthCompleted(roundId, drawEthAmount);
	}
}