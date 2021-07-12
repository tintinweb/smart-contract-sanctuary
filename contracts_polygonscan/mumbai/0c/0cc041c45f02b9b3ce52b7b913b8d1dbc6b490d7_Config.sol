/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function setOwner(address newOwner) public onlyOwner {
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

pragma solidity ^0.4.23;

/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
/// @dev This is the BlockchainCuties configuration. It can be changed redeploying another version.
interface ConfigInterface
{
    function isConfig() external pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 _cutieId) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 _cutieId) external view returns (uint40);
    function getCooldownIndexFromGeneration(uint16 _generation) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) external view returns (uint40);

    function getCooldownIndexCount() external view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) external pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) external view returns (uint256);
}

pragma solidity ^0.4.23;



contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    ConfigInterface public config;

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external;
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) external;
    function createGen0AuctionWithTokens(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration, address[] allowedTokens) external;
    function createPromoCutieWithGeneration(uint256 _genes, address _owner, uint16 _generation) external;
    function createPromoCutieBulk(uint256[] _genes, address _owner, uint16 _generation) external;
}


/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
/// @dev This is the BlockchainCuties configuration. It can be changed redeploying another version.

contract Config is Ownable, ConfigInterface
{
    mapping(uint40 => bool) public freeBreeding;
    uint public formulaA;
    uint public formulaB;


	function isConfig() external pure returns (bool)
	{
		return true;
	}

    /// @dev A lookup table that shows the cooldown duration after a successful
    ///  breeding action, called "breeding cooldown". The cooldown roughly doubles each time
    /// a cutie is bred, so that owners don't breed the same cutie continuously. Maximum cooldown is seven days.
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

    CutieCoreInterface public coreContract;

    function setup(address _coreAddress, uint _a, uint _b) external onlyOwner
    {
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
        setFormula(_a, _b);
    }

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 /*_cutieId*/) external view returns (uint16)
    {
        return getCooldownIndexFromGeneration(_generation);
    }

    function getCooldownIndexFromGeneration(uint16 _generation) public view returns (uint16)
    {
        uint16 result = _generation;
        if (result >= cooldowns.length) {
            result = uint16(cooldowns.length - 1);
        }
        return result;
    }

    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) public view returns (uint40)
    {
        return uint40(now + cooldowns[_cooldownIndex]);
    }

    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 /*_cutieId*/) external view returns (uint40)
    {
        return getCooldownEndTimeFromIndex(_cooldownIndex);
    }

    function getCooldownIndexCount() public view returns (uint256)
    {
        return cooldowns.length;
    }

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16)
    {
        uint16 momGen = coreContract.getGeneration(_momId);
        uint16 dadGen = coreContract.getGeneration(_dadId);

        return getBabyGen(momGen, dadGen);
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

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16)
    {
        // Tutorial pet gen is 1
        return getBabyGen(1, _dadGen);
    }

    function getBreedingFee(uint40 _momId, uint40 _dadId)
        external
        view
        returns (uint256)
    {
        if (freeBreeding[_momId] || freeBreeding[_dadId])
        {
            return 0;
        }

        uint16 momGen = coreContract.getGeneration(_momId);
        uint16 dadGen = coreContract.getGeneration(_dadId);
        uint16 momCooldown = coreContract.getCooldownIndex(_momId);
        uint16 dadCooldown = coreContract.getCooldownIndex(_dadId);

        uint256 sum = uint256(momCooldown) + dadCooldown - momGen - dadGen;
        return formulaA + formulaB*sum*sum;
    }

    function setFormula(uint256 _a, uint256 _b) public onlyOwner
    {
        formulaA = _a;
        formulaB = _b;
    }

    function setFreeBreeding(uint40 _cutieId) external onlyOwner
    {
        freeBreeding[_cutieId] = true;
    }

    function setFreeBreedings(uint40[] _cutieIds) external onlyOwner
    {
        for (uint i = 0; i < _cutieIds.length; i++)
        {
            freeBreeding[_cutieIds[i]] = true;
        }
    }

    function removeFreeBreeding(uint40 _cutieId) external onlyOwner
    {
        delete freeBreeding[_cutieId];
    }
}