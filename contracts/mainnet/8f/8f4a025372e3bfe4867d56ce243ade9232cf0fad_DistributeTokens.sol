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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract token { function transfer(address receiver, uint amount){  } }

contract DistributeTokens is Ownable{
  
	token tokenReward;
  address public addressOfTokenUsedAsReward;

  function setTokenReward(address _addr) onlyOwner {
    tokenReward = token(_addr);
    addressOfTokenUsedAsReward = _addr;
  }

	function distributeVariable(address[] _addrs, uint[] _bals) onlyOwner{
		for(uint i = 0; i < _addrs.length; ++i){
			tokenReward.transfer(_addrs[i],_bals[i]);
		}
	}

  function distributeFixed(address[] _addrs, uint _amoutToEach) onlyOwner{
    for(uint i = 0; i < _addrs.length; ++i){
      tokenReward.transfer(_addrs[i],_amoutToEach);
    }
  }

	function withdrawTokens(uint _amount) onlyOwner {
		tokenReward.transfer(owner,_amount);
	}
}