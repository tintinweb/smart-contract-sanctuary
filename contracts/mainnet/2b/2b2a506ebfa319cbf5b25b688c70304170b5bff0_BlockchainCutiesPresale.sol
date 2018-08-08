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
	mapping (uint256 => address) public ownerOf;
	mapping (uint256 => uint256) public prices;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	function addCutie(uint40 id, uint256 price) public onlyOwner
	{
		require(ownerOf[id] == address(0));
		prices[id] = price;
	}

	function isAvailable(uint40 id) public view returns (bool)
	{
		return ownerOf[id] == address(0) && prices[id] > 0;
	}

	function getPrice(uint40 id) public view returns (uint256 price, bool available)
	{
		price = prices[id];
		available = isAvailable(id);
	}

	function bid(uint40 id) public payable
	{
		require(isAvailable(id));
		require(prices[id] <= msg.value);

		ownerOf[id] = msg.sender;
		emit Transfer(0, msg.sender, id);
	}

    function destroyContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function withdraw() public onlyOwner {
        address(msg.sender).transfer(address(this).balance);
    }
}