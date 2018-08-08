pragma solidity ^0.4.21;

/**
 * @title Serpentio Contract <http://serpentio.com> - April 2018
 * @Author Alber Erre <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0e6f7c6c627b69614e69636f6762206d6163">[email&#160;protected]</a>> <http://albererre.com>
 * Technical details here: https://medium.com/@alber_erre/serpentio-a-snake-on-the-ethereum-blockchain-non-linear-distribution-scheme-b116bfa187d8
 */

/**
 * The Serpent contract distributes its acummulated balance between investors using a non-linear scheme, inside a period of time.
 * As such, every new investor help to fund previous investors, under the promise that future new investors will fund itself.
 * Result: Early investors receive more funds than last investors.
 */

/**
 * Based on Open Zeppelin - https://github.com/OpenZeppelin/zeppelin-solidity
 * 
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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Serpent is Ownable {
	using SafeMath for uint256;

	// everyone should check this measure to find out how much they have earned.
	mapping (address => uint256) public investorReturn;

	uint256 public SerpenSegmentCount;
	uint256 public SerpentCountDown;
	address public SerpentHead;
	address[] investormapping;

	struct investorDetails {
	    address investorAddress;
	    uint256 amountInvested;
	    uint256 SegmentNumber;
	    uint256 time;
	    string  quote;
	}

	investorDetails[] public investorsList;

	function Serpent () {
		// Constructor: init public variables and add creator as SerpentHead
		SerpentHead = owner;
		SerpenSegmentCount = 0;
		SerpentCountDown = uint256(block.timestamp);
	}

	function Play (string _quote) payable public {

		require (msg.value > 0);
        require (msg.sender != address(0)); // just in case
        require (uint256(block.timestamp) < SerpentCountDown); // nobody can play once countdown is finished

        address thisAddress = msg.sender;
		uint256 thisAmmount = msg.value;

        AddReturnsMapping(thisAmmount);
	    // AddReturnsMapping MUST be before AddNewSegment, to avoid counting the new segment while calculating returns

	    SerpenSegmentCount = SerpenSegmentCount.add(1);
		AddNewSegment(thisAddress, thisAmmount, SerpenSegmentCount, uint256(block.timestamp), _quote);
	    // Adding new segment - the same address can send more than once.
        // Although, distribution is based on chronological amounts, not addresses.
	}

	// Callback function
	function () payable public {
		require(msg.value > 0);

		Play("Callback, No quote");
	}

	function NewSerpent (uint256 _SerpentCountDown) public onlyOwner {

		// this is to avoid deleting current serpent game until the previous game has finished
		require (uint256(block.timestamp) > SerpentCountDown);
		
		SerpenSegmentCount = 0;
		SerpentCountDown = _SerpentCountDown;

		//Collect prime-number reminders from previous game calculations
		uint256 nonPrimeReminders = 0;
		for (uint256 p = 0; p < investormapping.length; p++) {
			nonPrimeReminders.add(investorReturn[investormapping[p]]);
		}
		uint256 PrimeReminder = uint256(address(this).balance) - nonPrimeReminders;
		SerpentHead.transfer(PrimeReminder);

		//Delete current investormapping array elements, to init new-serpent investormapping
		while (investormapping.length != 0) {
			delete investormapping[investormapping.length-1]; //delete last element
			investormapping.length--;
		}

		// Start first serpent segment
	    SerpenSegmentCount = SerpenSegmentCount.add(1);
	    investormapping.push(SerpentHead);
	    AddNewSegment(SerpentHead, 1 ether, SerpenSegmentCount, uint256(block.timestamp), "Everything started with Salazar Slytherin");
	}
	
	
	function AddNewSegment (address _address, uint256 _amount, uint256 _segmentNumber, uint256 _time, string _quote) internal {
	    require (_amount > 0); // just in case

		// in case this is a new address, add it to mappings, if not, just do nothing
		uint256 inList = 0;
		for (uint256 n = 0; n < investormapping.length; n++) {
			if (investormapping[n] == _address) {
				inList = 1;
			}
		}
		if (inList == 0) {
			investorReturn[_address] = 0;
			investormapping.push(_address); //add only once per address
		}

		// add to struct list, but after inList check
		investorsList.push(investorDetails(_address, _amount, _segmentNumber, _time, _quote));
	}

	function AddReturnsMapping (uint256 _amount) internal {

		uint256 individualAmount = _amount.div(investormapping.length);

		for (uint256 a = 0; a < investormapping.length; a++) {
			investorReturn[investormapping[a]] = investorReturn[investormapping[a]].add(individualAmount); 
		}
	}
	
	function CollectReturns () external {

		uint256 currentTime = uint256(block.timestamp);
		uint256 amountToCollect = getReturns(msg.sender);
		require (currentTime > SerpentCountDown); // collect if serpent has finished
		require(address(this).balance >= amountToCollect);

		address(msg.sender).transfer(amountToCollect);
		investorReturn[msg.sender] = 0;
	}

	function getBalance () public view returns(uint256) {
		return uint256(address(this).balance);
	}

	function getParticipants () public view returns(uint256) {
		return uint256(investormapping.length);
	}

	function getCountdownDate () public view returns(uint256) {
		return uint256(SerpentCountDown);
	}

	function getReturns (address _address) public view returns(uint256) {
		return uint256(investorReturn[_address]);
	}
	
	function SerpentIsRunning () public view returns(bool) {
		return bool(uint256(block.timestamp) < SerpentCountDown);
	}

  // End of contract
}