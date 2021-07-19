/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-13
*/

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.18;


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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Lockup.sol

pragma solidity ^0.4.18;


/**
 * @title Lockup
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Lockup is Ownable {

	uint256 public lockup_time;

	function Lockup(uint256 _lockUp_release_time)public{

		lockup_time = _lockUp_release_time; 
	}


	/**
	* @dev Function to check token is locked or not
	* @return A bool that indicates if the operation was successful.
	*/
	function isLockup() public view returns(bool){
		return (now >= lockup_time);
	}

	/**
	* @dev Function to get token lockup time
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getLockup()public view returns (uint256) {
		return lockup_time;
	}

	/**
	* @dev Function to update token lockup time
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockup(uint256 _newLockUpTime) onlyOwner public returns(bool){

		require( _newLockUpTime > now );

		lockup_time = _newLockUpTime;

		return true;
	}
}