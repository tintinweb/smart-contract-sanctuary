pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}



contract DistributeDividend is Ownable{
	using SafeMath for uint256;

	struct User {
      uint256 percentage ;
      bool is_active;
      bool is_creator;
    }

	mapping(address => User) users;
	address[] public addressIndices;

	constructor() public{
		User memory creator = User({
				percentage: 5,
				is_active: true,
				is_creator: true
			});
		users[0x9656e8520C1cc10721963F2E974761cf76Af81d8] = creator;
		addressIndices.push(0x9656e8520C1cc10721963F2E974761cf76Af81d8);
	}
	
	// fallback function to distribute dividend
    function () payable public{
        uint256 value = msg.value;
        for (uint i=0; i < addressIndices.length; i++) {
            address user_wallet = addressIndices[i];
            User storage user = users[user_wallet];
            if(user.is_active){
		      user_wallet.transfer(calculate_dividend(user.percentage, value));
            }
		}
    }
    
    function calculate_dividend(uint256 percentage, uint256 total_dividend) pure private returns (uint256){
        return total_dividend.mul(percentage).div(100);
    }

	function addUser(address user_wallet, uint256 percentage) onlyOwner public {
	    require(available_percentage() >= percentage);
	    require(percentage > 0);
        User memory user = User({
				percentage: percentage,
				is_active: true,
				is_creator: false
			});
		users[user_wallet] = user;
		addressIndices.push(user_wallet);
	}
	
	function changeUserStatus(address user_wallet, bool status) onlyOwner public {
	    require(users[user_wallet].percentage > 0);
	    require(!users[user_wallet].is_creator);
		users[user_wallet].is_active = status;
	}

	function available_percentage() constant public returns(uint256){
	    uint256 total_percentage = 0;
		for (uint i=0; i < addressIndices.length; i++) {
		  User storage user = users[addressIndices[i]];
		  if(user.is_active){
		    total_percentage = total_percentage.add(users[addressIndices[i]].percentage);
		  }
		}
		return uint256(100).sub(total_percentage);
	}
}