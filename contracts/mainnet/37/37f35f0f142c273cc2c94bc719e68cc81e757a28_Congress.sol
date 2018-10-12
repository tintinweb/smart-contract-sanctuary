pragma solidity ^0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title Abstract contract where privileged minting managed by governance
 */
contract MintableTokenStub {
  address public minter;

  event Mint(address indexed to, uint256 amount);

  /**
   * Constructor function
   */
  constructor (
    address _minter
  ) public {
    minter = _minter;
  }

  /**
   * @dev Throws if called by any account other than the minter.
   */
  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

  function mint(address _to, uint256 _amount)
  public
  onlyMinter
  returns (bool)
  {
    emit Mint(_to, _amount);
    return true;
  }

}


/**
 * @title Congress contract
 * @dev The Congress contract allows to execute certain actions (token minting in this case) via majority of votes.
 * In contrast to traditional Ownable pattern, Congress protects the managed contract (token) against unfair behaviour
 * of minority (for example, a single founder having one of the project keys has no power to mint the token until
 * other(s) vote for the operation). Majority formula is voters/2+1. The voters list is formed dynamically through the
 * voting. Voters can be added if current majority trusts new party. The party can be removed from the voters if it has
 * been compromised (majority executes untrust operation on it to do this).
 */
contract Congress {
  using SafeMath for uint256;
  // the number of active voters
  uint public voters;

  // given address is the voter or not
  mapping(address => bool) public voter;

  // Each proposal is stored in mapping by its hash (hash of mint arguments)
  mapping(bytes32 => MintProposal) public mintProposal;

  // Defines the level of other voters&#39; trust for given address. If majority of current voters
  // trusts the new member - it becomes the voter
  mapping(address => TrustRecord) public trustRegistry;

  // The governed token under Congress&#39;s control. Congress has the minter privileges on it.
  MintableTokenStub public token;

  // Event on initial token configuration
  event TokenSet(address voter, address token);

  // Proposal lifecycle events
  event MintProposalAdded(
    bytes32 proposalHash,
    address to,
    uint amount,
    string batchCode
  );

  event MintProposalVoted(
    bytes32 proposalHash,
    address voter,
    uint numberOfVotes
  );

  event MintProposalExecuted(
    bytes32 proposalHash,
    address to,
    uint amount,
    string batchCode
  );

  // Events emitted on trust claims
  event TrustSet(address issuer, address subject);
  event TrustUnset(address issuer, address subject);

  // Events on adding-deleting voters
  event VoteGranted(address voter);
  event VoteRevoked(address voter);

  // Stores the state of the proposal: executed or not (able to execute only once), number of Votes and
  // the mapping of voters and their boolean vote. true if voted.
  struct MintProposal {
    bool executed;
    uint numberOfVotes;
    mapping(address => bool) voted;
  }

  // Stores the trust counter and the addresses who trusted the given voter(candidate)
  struct TrustRecord {
    uint256 totalTrust;
    mapping(address => bool) trustedBy;
  }


  // Modifier that allows only Voters to vote
  modifier onlyVoters {
    require(voter[msg.sender]);
    _;
  }

  /**
   * Constructor function
   */
  constructor () public {
    voter[msg.sender] = true;
    voters = 1;
  }

  /**
   * @dev Determine does the given number of votes make majority of voters.
   * @return true if given number is majority
   */
  function isMajority(uint256 votes) public view returns (bool) {
    return (votes >= voters.div(2).add(1));
  }

  /**
   * @dev Determine how many voters trust given address
   * @param subject The address of trustee
   * @return the number of trusted votes
   */
  function getTotalTrust(address subject) public view returns (uint256) {
    return (trustRegistry[subject].totalTrust);
  }

  /**
   * @dev Set the trust claim (msg.sender trusts subject)
   * @param _subject The trusted address
   */
  function trust(address _subject) public onlyVoters {
    require(msg.sender != _subject);
    require(token != MintableTokenStub(0));
    if (!trustRegistry[_subject].trustedBy[msg.sender]) {
      trustRegistry[_subject].trustedBy[msg.sender] = true;
      trustRegistry[_subject].totalTrust = trustRegistry[_subject].totalTrust.add(1);
      emit TrustSet(msg.sender, _subject);
      if (!voter[_subject] && isMajority(trustRegistry[_subject].totalTrust)) {
        voter[_subject] = true;
        voters = voters.add(1);
        emit VoteGranted(_subject);
      }
      return;
    }
    revert();
  }

  /**
   * @dev Unset the trust claim (msg.sender now reclaims trust from subject)
   * @param _subject The address of trustee to revoke trust
   */
  function untrust(address _subject) public onlyVoters {
    require(token != MintableTokenStub(0));
    if (trustRegistry[_subject].trustedBy[msg.sender]) {
      trustRegistry[_subject].trustedBy[msg.sender] = false;
      trustRegistry[_subject].totalTrust = trustRegistry[_subject].totalTrust.sub(1);
      emit TrustUnset(msg.sender, _subject);
      if (voter[_subject] && !isMajority(trustRegistry[_subject].totalTrust)) {
        voter[_subject] = false;
        // ToDo SafeMath
        voters = voters.sub(1);
        emit VoteRevoked(_subject);
      }
      return;
    }
    revert();
  }

  /**
   * @dev Token and its governance should be locked to each other. Congress should be set as minter in token
   * @param _token The address of governed token
   */
  function setToken(
    MintableTokenStub _token
  )
  public
  onlyVoters
  {
    require(_token != MintableTokenStub(0));
    require(token == MintableTokenStub(0));
    token = _token;
    emit TokenSet(msg.sender, token);
  }

  /**
  * @dev Proxy function to vote and mint tokens
  * @param to The address that will receive the minted tokens.
  * @param amount The amount of tokens to mint.
  * @param batchCode The detailed information on a batch.
  * @return A boolean that indicates if the operation was successful.
  */
  function mint(
    address to,
    uint256 amount,
    string batchCode
  )
  public
  onlyVoters
  returns (bool)
  {
    bytes32 proposalHash = keccak256(abi.encodePacked(to, amount, batchCode));
    assert(!mintProposal[proposalHash].executed);
    if (!mintProposal[proposalHash].voted[msg.sender]) {
      if (mintProposal[proposalHash].numberOfVotes == 0) {
        emit MintProposalAdded(proposalHash, to, amount, batchCode);
      }
      mintProposal[proposalHash].numberOfVotes = mintProposal[proposalHash].numberOfVotes.add(1);
      mintProposal[proposalHash].voted[msg.sender] = true;
      emit MintProposalVoted(proposalHash, msg.sender, mintProposal[proposalHash].numberOfVotes);
    }
    if (isMajority(mintProposal[proposalHash].numberOfVotes)) {
      mintProposal[proposalHash].executed = true;
      token.mint(to, amount);
      emit MintProposalExecuted(proposalHash, to, amount, batchCode);
    }
    return (true);
  }
}