pragma solidity 0.4.23;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);

    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Proxied is Ownable {
    address public target;
    mapping (address => bool) public initialized;

    event EventUpgrade(address indexed newTarget, address indexed oldTarget, address indexed admin);
    event EventInitialized(address indexed target);

    function upgradeTo(address _target) public;
}

contract Upgradeable is Proxied {
    /*
     * @notice Modifier to make body of function only execute if the contract has not already been initialized.
     */
    modifier initializeOnceOnly() {
         if(!initialized[target]) {
             initialized[target] = true;
             emit EventInitialized(target);
             _;
         } else revert();
     }

    /**
     * @notice Will always fail if called. This is used as a placeholder for the contract ABI.
     * @dev This is code is never executed by the Proxy using delegate call
     */
    function upgradeTo(address) public {
        assert(false);
    }

    /**
     * @notice Initialize any state variables that would normally be set in the contructor.
     * @dev Initialization functionality MUST be implemented in inherited upgradeable contract if the child contract requires
     * variable initialization on creation. This is because the contructor of the child contract will not execute
     * and set any state when the Proxy contract targets it.
     * This function MUST be called stright after the Upgradeable contract is set as the target of the Proxy. This method
     * can be overwridden so that it may have arguments. Make sure that the initializeOnceOnly() modifier is used to protect
     * from being initialized more than once.
     * If a contract is upgraded twice, pay special attention that the state variables are not initialized again
     */
    function initialize() initializeOnceOnly public {
        // initialize contract state variables here
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

interface IClaims  {

    event ClaimCreated(uint indexed claimId);

    function createClaim(address[] _voters, uint _votingDeadline,
    address _claimantAddress) external;

    function castVote(uint _claimId, uint _pType, bytes32 _hash, string _url,
    bytes32 _tokenHash) external;
    
    function register(uint _claimId, uint _pType, bytes32 _hash, string _url,
    bytes32 _tokenHash) external;
}

contract NaiveClaims is Upgradeable, Pausable, IClaims  {

    struct Claim {
        address[] voters;
        mapping(address => Vote) votes;
        address claimantAddress;
        uint votingDeadline;
    }

    struct Vote {
        uint pType;
        bytes32 hash;
        string url;
        bool exists;
        bytes32 tokenHash;
    }

    mapping (uint => Claim) public claims;
    event ClaimCreated(uint indexed claimId);
    uint256 public claimsCreated;

    /**
     * @param _voters - addresses eligible to vote
     * @param _votingDeadline - after which votes cannot be submitted
     * @param _claimantAddress  - claimants address
     */
    function createClaim(address[] _voters, uint _votingDeadline, address _claimantAddress) external whenNotPaused {

        claims[claimsCreated].voters = _voters;
        claims[claimsCreated].claimantAddress = _claimantAddress;
        claims[claimsCreated].votingDeadline = _votingDeadline;

        emit ClaimCreated(claimsCreated);
        claimsCreated++;
    }

    /**
     * @param _claimId - claim id for which user is casting the vote
     * @param _pType - type of hashPointer (1 - PlainVote)
     * @param _hash - of the vote - in this version plain YES or NO
     * @param _url - to the location of the vote (mongo://{vote-doc-id})
     * @param _tokenHash - received from indorse on centralized vote submission
     */
    function castVote(uint _claimId, uint _pType, bytes32 _hash, string _url,
    bytes32 _tokenHash) external {
        Claim storage claim = claims[_claimId];
        Vote storage vote = claim.votes[msg.sender];

        require(vote.exists != true, "Voters can only vote once");
        require(now < claim.votingDeadline, "Cannot vote after the dealine has passed");

        claims[_claimId].votes[msg.sender] = Vote(_pType, _hash, _url, true, _tokenHash);
    }

    function getVote(uint _claimId, address _voter)  constant external returns (uint ,bytes32,
    string ,bool ,bytes32){
        return (claims[_claimId].votes[_voter].pType,
        claims[_claimId].votes[_voter].hash,
        claims[_claimId].votes[_voter].url,
        claims[_claimId].votes[_voter].exists,
        claims[_claimId].votes[_voter].tokenHash);
    }

    function getVoter(uint _claimId, uint _index) external constant returns (address) {
        return claims[_claimId].voters[_index];
    }

    function getVoterCount(uint _claimId) external constant returns (uint) {
        return claims[_claimId].voters.length;
    }

    function initialize() initializeOnceOnly public {
        claimsCreated = 0; // This is not strictly needed but is good practice to show initialization here
    }

    function register(uint _claimId, uint _pType, bytes32 _hash, string _url,
    bytes32 _tokenHash) external {
        revert("Unsupported operation");
    }
}