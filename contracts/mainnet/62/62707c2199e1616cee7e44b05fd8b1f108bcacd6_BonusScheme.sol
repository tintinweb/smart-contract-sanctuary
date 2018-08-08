pragma solidity ^0.4.21;

pragma solidity ^0.4.10;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable()public {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner)public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

/**
 * @title BonusScheme
 * @dev This contract is used for storing and granting tokens calculated 
 * according to bonus scheme while a crowdsale is in progress.
 * When crowdsale ends the rest of tokens is transferred to developers.
 */
contract BonusScheme is Ownable {
	using SafeMath for uint256;

	/**
	* Defining timestamps for bonuscheme from White Paper. 
	* The start of bonuses is 15 May 2018 and the end is 23 June 2018. 
	* There are 2 seconds in between changing the phases.  */
	uint256 startOfFirstBonus = 1525892100;
	uint256 endOfFirstBonus = (startOfFirstBonus - 1) + 5 minutes;	
	uint256 startOfSecondBonus = (startOfFirstBonus + 1) + 5 minutes;
	uint256 endOfSecondBonus = (startOfSecondBonus - 1) + 5 minutes;
	uint256 startOfThirdBonus = (startOfSecondBonus + 1) + 5 minutes;
	uint256 endOfThirdBonus = (startOfThirdBonus - 1) + 5 minutes;
	uint256 startOfFourthBonus = (startOfThirdBonus + 1) + 5 minutes;
	uint256 endOfFourthBonus = (startOfFourthBonus - 1) + 5 minutes;
	uint256 startOfFifthBonus = (startOfFourthBonus + 1) + 5 minutes;
	uint256 endOfFifthBonus = (startOfFifthBonus - 1) + 5 minutes;
	
	/**
	* Defining bonuses according to White Paper.
	* First week there is bonus 35%.
	* Second week there is bonus 30%.
	* Third week there is bonus 20%.
	* Fourth week there is bonus 10%.
	* Fifth week there is bonus 5%.
	*/
	uint256 firstBonus = 35;
	uint256 secondBonus = 30;
	uint256 thirdBonus = 20;
	uint256 fourthBonus = 10;
	uint256 fifthBonus = 5;

	event BonusCalculated(uint256 tokenAmount);

    function BonusScheme() public {
        
    }

	/**
	 * @dev Calculates from Bonus Scheme how many tokens can be added to purchased _tokenAmount.
	 * @param _tokenAmount The amount of calculated tokens to sent Ether.
	 * @return Number of bonus tokens that can be granted with the specified _tokenAmount.
	 */
	function getBonusTokens(uint256 _tokenAmount)onlyOwner public returns(uint256) {
		if (block.timestamp >= startOfFirstBonus && block.timestamp <= endOfFirstBonus) {
			_tokenAmount = _tokenAmount.mul(firstBonus).div(100);
		} else if (block.timestamp >= startOfSecondBonus && block.timestamp <= endOfSecondBonus) {
			_tokenAmount = _tokenAmount.mul(secondBonus).div(100);
		} else if (block.timestamp >= startOfThirdBonus && block.timestamp <= endOfThirdBonus) {
			_tokenAmount = _tokenAmount.mul(thirdBonus).div(100);
		} else if (block.timestamp >= startOfFourthBonus && block.timestamp <= endOfFourthBonus) {
			_tokenAmount = _tokenAmount.mul(fourthBonus).div(100);
		} else if (block.timestamp >= startOfFifthBonus && block.timestamp <= endOfFifthBonus) {
			_tokenAmount = _tokenAmount.mul(fifthBonus).div(100);
		} else _tokenAmount=0;
		emit BonusCalculated(_tokenAmount);
		return _tokenAmount;
	}
}