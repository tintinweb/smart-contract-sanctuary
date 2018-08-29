pragma solidity ^0.4.21;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/InstantListingV2.sol

contract InstantListingV2 is Ownable {
    using SafeMath for uint256;

    struct Proposal {
        address tokenAddress;
        string projectName;
        string websiteUrl;
        string logoUrl;
        string whitepaperUrl;
        string legalDocumentUrl;
        uint256 icoStartDate;
        uint256 icoEndDate;
        uint256 icoRate; // If 4000 COB = 1 ETH, then icoRate = 4000.
        uint256 totalRaised;
    }

    struct ProposalInfo {
        uint256 totalContributions;
        address sender;
        uint256 round;
    }

    // Round number
    uint256 public round;

    // The address of beneficiary.
    address public beneficiary;

    // Proposals.
    mapping(uint256 => mapping(address => Proposal)) public proposals;

    // Mapping of tokenAddress to ProposalInfo
    mapping(address => ProposalInfo) public proposalInfos;

    // Contribution of each round.
    mapping(uint256 => uint256) public roundContribution;

    // A mapping from token contract address to the last refundable unix
    // timestamp, 0 means not refundable.
    mapping(address => uint256) public refundable;

    // Configs.
    uint256 public startTime;
    uint256 public hardCap;
    uint256 public duration;

    // Events.
    event TokenListed(uint256 indexed _round, address _tokenAddress);
    event TokenListingCancelled(address _tokenAddress);
    event RoundFinalized(uint256 _round);

    constructor() public {
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function initialize(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }

    function reset(
        uint256 _startTime,
        uint256 _duration,
        uint256 _hardCap)
        onlyOwner public {
        require(getCurrentTimestamp() >= startTime + duration);

        // Transfer all balance except for latest round,
        // which is reserved for refund.
        if (round > 0) {
            beneficiary.transfer(address(this).balance - roundContribution[round]);
        }

        startTime = _startTime;
        duration = _duration;
        hardCap = _hardCap;

        emit RoundFinalized(round);
        round += 1;
    }

    function propose(
        address _tokenAddress,
        string _projectName,
        string _websiteUrl,
        string _logoUrl,
        string _whitepaperUrl,
        string _legalDocumentUrl,
        uint256 _icoStartDate,
        uint256 _icoEndDate,
        uint256 _icoRate,
        uint256 _totalRaised) public payable {

        require(proposalInfos[_tokenAddress].totalContributions == 0);
        require(getCurrentTimestamp() < startTime + duration);
        require(msg.value >= hardCap);

        proposals[round][_tokenAddress] = Proposal({
            tokenAddress: _tokenAddress,
            projectName: _projectName,
            websiteUrl: _websiteUrl,
            logoUrl: _logoUrl,
            whitepaperUrl: _whitepaperUrl,
            legalDocumentUrl: _legalDocumentUrl,
            icoStartDate: _icoStartDate,
            icoEndDate: _icoEndDate,
            icoRate: _icoRate,
            totalRaised: _totalRaised
        });

        proposalInfos[_tokenAddress] = ProposalInfo({
            totalContributions: msg.value,
            sender: msg.sender,
            round: round
        });

        roundContribution[round] = roundContribution[round].add(msg.value);
        emit TokenListed(round, _tokenAddress);
    }

    function setRefundable(address _tokenAddress, uint256 endTime)
        onlyOwner public {
        refundable[_tokenAddress] = endTime;
    }

    function refund(address _tokenAddress) public {
        require(refundable[_tokenAddress] > 0 &&
                getCurrentTimestamp() < refundable[_tokenAddress]);

        uint256 value = proposalInfos[_tokenAddress].totalContributions;
        proposalInfos[_tokenAddress].totalContributions = 0;
        roundContribution[proposalInfos[_tokenAddress].round] =
            roundContribution[proposalInfos[_tokenAddress].round].sub(value);
        proposalInfos[_tokenAddress].sender.transfer(value);

        emit TokenListingCancelled(_tokenAddress);
    }

    function getContributions(address _tokenAddress)
        view public returns (uint256) {
        return proposalInfos[_tokenAddress].totalContributions;
    }

    function kill() public onlyOwner {
        selfdestruct(beneficiary);
    }

    function () public payable {
        revert();
    }
}