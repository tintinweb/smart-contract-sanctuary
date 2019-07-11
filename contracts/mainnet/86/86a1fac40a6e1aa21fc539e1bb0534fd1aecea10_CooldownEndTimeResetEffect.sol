/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.23;

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

pragma solidity ^0.4.23;

/// @author https://BlockChainArchitect.iocontract Bank is CutiePluginBase
contract PluginInterface
{
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

    /// @dev Begins new feature.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    /// @param _seller - Old owner, if not the message sender
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    )
    public
    payable;

    /// @dev Begins new feature, approved and signed by COO.
    /// @param _cutieId - ID of token to auction, sender must be owner.
    /// @param _parameter - arbitrary parameter
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    ) external payable;

    function withdraw() external;
}

pragma solidity ^0.4.23;

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

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;

contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableOperators is Operators {
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


/// @author https://BlockChainArchitect.iocontract Bank is CutiePluginBase
contract CutiePluginBase is PluginInterface, PausableOperators
{
    function isPluginInterface() public pure returns (bool)
    {
        return true;
    }

    // Reference to contract tracking NFT ownership
    CutieCoreInterface public coreContract;
    address public pluginsContract;

    // @dev Throws if called by any account other than the owner.
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }

    modifier onlyPlugins() {
        require(msg.sender == pluginsContract);
        _;
    }

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _coreAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    function setup(address _coreAddress, address _pluginsContract) public onlyOwner {
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;

        pluginsContract = _pluginsContract;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _cutieId - ID of token whose ownership to verify.
    function _isOwner(address _claimant, uint40 _cutieId) internal view returns (bool) {
        return (coreContract.ownerOf(_cutieId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _cutieId - ID of token whose approval to verify.
    function _escrow(address _owner, uint40 _cutieId) internal {
        // it will throw if transfer fails
        coreContract.transferFrom(_owner, this, _cutieId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _cutieId - ID of token to transfer.
    function _transfer(address _receiver, uint40 _cutieId) internal {
        // it will throw if transfer fails
        coreContract.transfer(_receiver, _cutieId);
    }

    function withdraw() external
    {
        require(
            isOwner(msg.sender) ||
            msg.sender == address(coreContract)
        );
        _withdraw();
    }

    function _withdraw() internal
    {
        if (address(this).balance > 0)
        {
            address(coreContract).transfer(address(this).balance);
        }
    }

    function onRemove() public onlyPlugins
    {
        _withdraw();
    }

    function run(uint40, uint256, address) public payable onlyCore
    {
        revert();
    }

    function runSigned(uint40, uint256, address) external payable onlyCore
    {
        revert();
    }
}


/// @title Item effect for Blockchain Cuties
/// @author https://BlockChainArchitect.io
contract CooldownEndTimeResetEffect is CutiePluginBase 
{
    function run(
        uint40,
        uint256,
        address
    ) 
        public
        payable
        onlyPlugins
    {
        revert();
    }

    function runSigned(
        uint40 _cutieId,
        uint256 /*_parameter*/,
        address /*_owner*/
    ) 
        external
        onlyPlugins
        whenNotPaused
        payable
    {
        uint40 t = coreContract.getCooldownEndTime(_cutieId);
        if (t > now)
        {
            coreContract.changeCooldownEndTime(_cutieId, uint40(now));
        }
        else
        {
            // not required
            revert();
        }
    }
}