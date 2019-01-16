pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract InsightlymonialRaffle is Ownable {
	address[4] private entrants;
	uint private currentEntrantIndex;
	uint private raffleEntryCost = 0.025 ether;

	event TestimonialSubmitted(address submitter, string testimonial);

	function submitTestimonial(string _testimonial) external payable {
		require(msg.value == raffleEntryCost);
		require(bytes(_testimonial).length > 0);
		entrants[currentEntrantIndex] = msg.sender;
		currentEntrantIndex++;
		emit TestimonialSubmitted(msg.sender, _testimonial);
		if (currentEntrantIndex == 4) {
			_doRaffle();
		}
	}

	event RaffleWinnerChosen(address winner, address otherEntrant1, address otherEntrant2, address otherEntrant3);

	function _doRaffle() private {
		assert(currentEntrantIndex == 4);
		uint winnerIndex = _pseudoRandomWinnerIndex();
		address[] memory otherEntrants = new address[](3);
		uint counter = 0;
		for (uint i = 0; i < 4; i++) {
			if (i != winnerIndex) {
				otherEntrants[counter] = entrants[i];
				counter++;
			}
		}
		currentEntrantIndex = 0;
		emit RaffleWinnerChosen(entrants[winnerIndex], otherEntrants[0], otherEntrants[1], otherEntrants[2]);
		entrants[winnerIndex].transfer(address(this).balance);
	}

	uint private pseudoRandomNonce = 0;

    function _pseudoRandomWinnerIndex() private returns(uint) {
    	pseudoRandomNonce++;
    	return uint(keccak256(abi.encodePacked(now, msg.sender, pseudoRandomNonce))) % 4;
	}

	function currentEntrants() public view returns(address[]) {
    	address[] memory result = new address[](currentEntrantIndex);
		for (uint i = 0; i < currentEntrantIndex; i++) {
			result[i] = entrants[i];
		}
		return result;
	}
}