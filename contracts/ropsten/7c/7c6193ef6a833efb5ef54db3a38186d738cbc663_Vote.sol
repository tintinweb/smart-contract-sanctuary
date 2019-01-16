pragma solidity ^0.4.25;

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/Vote.sol

contract Vote is Ownable {
    using SafeMath for uint256;

    struct Ballot {
        uint256 weight;
        bool voted;
        bool vote;
    }

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    
    mapping(address => Ballot) private ballotByAddress;
    address[] private voters;

    uint256 public endtime;
    string public proposal;

    modifier activeVote {
        // solium-disable-next-line security/no-block-members 
        require(endtime > now, "should be an active vote");
        _;
    }

    modifier inactiveVote {
        // solium-disable-next-line security/no-block-members
        require(now > endtime, "should be an inactive vote");
        _;
    }

    constructor(uint _endtime, string _proposal, address[] _voters) public {
        endtime = _endtime;
        proposal = _proposal;

        for(uint i = 0; i < _voters.length; i++) {
            ballotByAddress[_voters[i]] = Ballot(1, false, false);
        }

        voters = _voters; 
    }

    function countAbstentions() internal view returns(uint256) {
        return (voters.length.sub(votesAgainst)).sub(votesInFavor);
    }

    function getResult() public view inactiveVote returns(bool) {
        // solium-disable-next-line security/no-block-members
        require(now > endtime, "vote has not ended, yet");
        return (votesInFavor > votesAgainst.add(countAbstentions()));
    }

    function submitBallot(bool _vote) public activeVote returns(bool) {
        //solium-disable-next-line security/no-block-members
        require(ballotByAddress[msg.sender].voted == false, "has already voted");
        uint256 weight = ballotByAddress[msg.sender].weight;
        require(weight > 0, "voter has to have voting rights");
        ballotByAddress[msg.sender].voted = true;
        ballotByAddress[msg.sender].vote = _vote;

        if(_vote == true) {
            votesInFavor = votesInFavor.add(weight);
        } else {
            votesAgainst = votesAgainst.add(weight);
        }

        return true;
    }

    function getBallotOfSender() public view returns(uint256, bool, bool) {
        Ballot storage ballot = ballotByAddress[msg.sender];
        return (ballot.weight, ballot.voted, ballot.vote);
    }
}