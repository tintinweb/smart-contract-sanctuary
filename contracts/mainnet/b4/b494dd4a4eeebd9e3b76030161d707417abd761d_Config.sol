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



/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
/// @dev This is the BlockchainCuties configuration. It can be changed redeploying another version.
contract ConfigInterface
{
    function isConfig() public pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation) public view returns (uint16);
    
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) public view returns (uint40);

    function getCooldownIndexCount() public view returns (uint256);
    
    function getBabyGen(uint16 _momGen, uint16 _dadGen) public pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) public pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) public pure returns (uint256);
}


/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
/// @dev This is the BlockchainCuties configuration. It can be changed redeploying another version.

contract Config is Ownable, ConfigInterface
{
	function isConfig() public pure returns (bool)
	{
		return true;
	}

    /// @dev A lookup table that shows the cooldown duration after a successful
    ///  breeding action, called "breeding cooldown". The cooldown roughly doubles each time
    /// a cutie is bred, so that owners don&#39;t breed the same cutie continuously. Maximum cooldown is seven days.
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

/*    function setCooldown(uint16 index, uint32 newCooldown) public onlyOwner
    {
        cooldowns[index] = newCooldown;
    }*/

    function getCooldownIndexFromGeneration(uint16 _generation) public view returns (uint16)
    {
        uint16 result = uint16(_generation / 2);
        if (result > getCooldownIndexCount()) {
            result = uint16(getCooldownIndexCount() - 1);
        }
        return result;
    }

    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) public view returns (uint40)
    {
        return uint40(now + cooldowns[_cooldownIndex]);
    }

    function getCooldownIndexCount() public view returns (uint256)
    {
        return cooldowns.length;
    }

    function getBabyGen(uint16 _momGen, uint16 _dadGen) public pure returns (uint16)
    {
        uint16 babyGen = _momGen;
        if (_dadGen > _momGen) {
            babyGen = _dadGen;
        }
        babyGen = babyGen + 1;
        return babyGen;
    }

    function getTutorialBabyGen(uint16 _dadGen) public pure returns (uint16)
    {
        // Tutorial pet gen is 26
        return getBabyGen(26, _dadGen);
    }

    function getBreedingFee(uint40 /*_momId*/, uint40 /*_dadId*/)
        public
        pure
        returns (uint256)
    {
        return 2000000000000000;
    }
}