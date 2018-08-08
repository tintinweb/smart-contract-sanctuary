pragma solidity ^0.4.20;


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



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/// @title BlockchainCuties Presale
contract BlockchainCutiesPresale is Pausable
{
	struct Purchase
	{
		address owner;
		uint32 cutieKind;
	}
	Purchase[] public purchases;

	mapping (uint32 => uint256) public prices;
	mapping (uint32 => uint256) public leftCount;

	event Bid(address indexed owner, uint32 indexed cutieKind);

	function addCutie(uint32 id, uint256 price, uint256 count) public onlyOwner
	{
		prices[id] = price;
		leftCount[id] = count;
	}

	function isAvailable(uint32 cutieKind) public view returns (bool)
	{
		return leftCount[cutieKind] > 0;
	}

	function getPrice(uint32 cutieKind) public view returns (uint256 price, uint256 left)
	{
		price = prices[cutieKind];
		left = leftCount[cutieKind];
	}

	function bid(uint32 cutieKind) public payable whenNotPaused
	{
		require(isAvailable(cutieKind));
		require(prices[cutieKind] <= msg.value);

		purchases.push(Purchase(msg.sender, cutieKind));
		leftCount[cutieKind]--;

		emit Bid(msg.sender, cutieKind);
	}

	function purchasesCount() public view returns (uint256)
	{
		return purchases.length;
	}

    function destroyContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function withdraw() public onlyOwner {
        address(msg.sender).transfer(address(this).balance);
    }
}