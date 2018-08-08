pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Converter ETH / US DOLLAR
*/
contract Converter is Ownable {

  uint256 constant FD = 10 ** 4; // Four decimals
  uint256 constant ETHER = 10 ** 18;
	
	uint256 public sellRate; // sell eth for US dollar
	uint256 public buyRate; // buy US dollar for eth
	
	/**
   * @dev Function to compute ETH for US Dollar
   * @param _dollar The amount of US dollar (in WEI) to change.
   * @return The amount of ETH to receive
   */
	function buy(
		uint256 _dollar
	)
	 external
	 view
	 returns (uint256)
	{
		return ((_dollar * FD) * buyRate) / FD;
	}

	/**
   * @dev Function to compute US Dollar for ETH 
   * @param _eth The amount of ETH (in WEI) to change.
   * @return The amount of US dollar to receive
   */
	function sell(
		uint256 _eth
	)
	 external
	 view
	 returns (uint256)
	{
		return (((_eth * ETHER) * sellRate) / ETHER) / ETHER;
	}
	
	/**
   * @dev Function to update the sell and buy rate value
   * @param _newSellRate The new sell rate in US dollar (WEI formatted).
   * @param _newBuyRate The new buy rate in ETH (WEI formatted).
   */
	function changeRates(
		uint256 _newSellRate,
		uint256 _newBuyRate
	)
		external
		onlyOwner
	{
		require(_newSellRate > 0);
		require(_newBuyRate > 0);
		
		sellRate = _newSellRate;
		buyRate = _newBuyRate;
	}
	
}