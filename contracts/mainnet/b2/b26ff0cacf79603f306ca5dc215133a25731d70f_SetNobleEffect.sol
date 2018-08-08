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
    )
    external
    payable;

    function withdraw() public;
}



contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

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
}


/// @author https://BlockChainArchitect.iocontract Bank is CutiePluginBase
contract CutiePluginBase is PluginInterface, Pausable
{
    function isPluginInterface() public pure returns (bool)
    {
        return true;
    }

    // Reference to contract tracking NFT ownership
    CutieCoreInterface public coreContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint16 public ownerFee;

    // @dev Throws if called by any account other than the owner.
    modifier onlyCore() {
        require(msg.sender == address(coreContract));
        _;
    }

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _coreAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _fee - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    function setup(address _coreAddress, uint16 _fee) public {
        require(_fee <= 10000);
        require(msg.sender == owner);
        ownerFee = _fee;
        
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
    }

    // @dev Set the owner&#39;s fee.
    //  @param fee should be between 0-10,000.
    function setFee(uint16 _fee) public
    {
        require(_fee <= 10000);
        require(msg.sender == owner);

        ownerFee = _fee;
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

    /// @dev Computes owner&#39;s cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeFee(uint128 _price) internal view returns (uint128) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerFee <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerFee / 10000;
    }

    function withdraw() public
    {
        require(
            msg.sender == owner ||
            msg.sender == address(coreContract)
        );
        if (address(this).balance > 0)
        {
            address(coreContract).transfer(address(this).balance);
        }
    }

    function onRemove() public onlyCore
    {
        withdraw();
    }
}


/// @title Item effect for Blockchain Cuties
/// @author https://BlockChainArchitect.io
contract SetNobleEffect is CutiePluginBase
{
    function run(uint40, uint256, address) public payable onlyCore
    {
        revert();
    }

    function runSigned(
        uint40 _cutieId,
        uint256 /*_parameter*/,
        address /*_owner*/
    ) 
        external
        onlyCore
        whenNotPaused
        payable
    {
        uint256 genes = coreContract.getGenes(_cutieId);
        require(genes & 0x10000 == 0); // nobility not set
        genes |= 0x10000;
        coreContract.changeGenes(_cutieId, genes);
    }
}