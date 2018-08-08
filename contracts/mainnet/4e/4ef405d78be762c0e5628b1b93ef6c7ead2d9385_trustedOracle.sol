pragma solidity ^0.4.11;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


contract trustedOracle is Ownable {
	mapping (uint => uint) pricePoints;
	uint public lastTimestamp;

	function submitPrice(uint _timestamp, uint _weiForCent)
		onlyOwner
	{
		pricePoints[_timestamp] = _weiForCent;
		if (_timestamp > lastTimestamp) lastTimestamp = _timestamp;
	}


	function getWeiForCent(uint _timestamp)
		public
		constant
		returns (uint)
	{
		uint stamp = _timestamp;
		if (stamp == 0) stamp = lastTimestamp;
		return pricePoints[stamp];
	}
}