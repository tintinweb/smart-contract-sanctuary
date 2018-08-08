pragma solidity ^0.4.21;

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/InstantListing.sol

contract InstantListing is Ownable {
    using SafeMath for uint256;

    struct Proposal {
        uint256 totalContributions;
        mapping(address => uint256) contributions;

        address tokenAddress;
        string projectName;
        string websiteUrl;
        string whitepaperUrl;
        string legalDocumentUrl;
        uint256 icoStartDate;
        uint256 icoEndDate;
        uint256 icoRate; // If 4000 COB = 1 ETH, then icoRate = 4000.
        uint256 totalRaised;
    }

    // Round number
    uint256 public round;

    // Flag to mark if "listing-by-rank" is already executed
    bool public ranked;

    // The address of beneficiary.
    address public beneficiary;

    // The address of token used for payment (e.g. COB)
    address public paymentTokenAddress;

    // Required amount of paymentToken to able to propose a listing.
    uint256 public requiredDownPayment;

    // Proposals proposed by community.
    mapping(uint256 => mapping(address => Proposal)) public proposals;

    // Contribution of each round.
    mapping(uint256 => uint256) public roundContribution;

    // A mapping of the token listing status.
    mapping(address => bool) public listed;

    // A mapping from token contract address to the last refundable unix
    // timestamp, 0 means not refundable.
    mapping(address => uint256) public refundable;

    // Candidates
    address[] public candidates;

    // Configs.
    uint256 public startTime;
    uint256 public prevEndTime;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public duration;
    uint256 public numListed;

    // Events.
    event SoftCapReached(uint256 indexed _round, address _tokenAddress);
    event TokenProposed(uint256 indexed _round, address _tokenAddress, uint256 _refundEndTime);
    event TokenListed(uint256 indexed _round, address _tokenAddress, uint256 _refundEndTime);
    event Vote(uint256 indexed _round, address indexed _tokenAddress, address indexed voter, uint256 amount);
    event RoundFinalized(uint256 _round);

    constructor() public {
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function initialize(
        address _beneficiary,
        address _paymentTokenAddress)
        onlyOwner public {

        beneficiary = _beneficiary;
        paymentTokenAddress = _paymentTokenAddress;
    }

    function reset(
        uint256 _requiredDownPayment,
        uint256 _startTime,
        uint256 _duration,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _numListed)
        onlyOwner public {
        require(getCurrentTimestamp() >= startTime + duration);


        // List tokens in the leaderboard
        if (!ranked) {
            listTokenByRank();
        }

        // Transfer all balance except for latest round,
        // which is reserved for refund.
        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        if (round != 0) {
            prevEndTime = startTime + duration;
            paymentToken.transfer(beneficiary,
                paymentToken.balanceOf(this) - roundContribution[round]);
        }

        requiredDownPayment = _requiredDownPayment;
        startTime = _startTime;
        duration = _duration;
        hardCap = _hardCap;
        softCap = _softCap;
        numListed = _numListed;
        ranked = false;

        emit RoundFinalized(round);

        delete candidates;

        round += 1;
    }

    function propose(
        address _tokenAddress,
        string _projectName,
        string _websiteUrl,
        string _whitepaperUrl,
        string _legalDocumentUrl,
        uint256 _icoStartDate,
        uint256 _icoEndDate,
        uint256 _icoRate,
        uint256 _totalRaised) public {
        require(proposals[round][_tokenAddress].totalContributions == 0);
        require(getCurrentTimestamp() < startTime + duration);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        uint256 downPayment = paymentToken.allowance(msg.sender, this);

        if (downPayment < requiredDownPayment) {
            revert();
        }

        paymentToken.transferFrom(msg.sender, this, downPayment);

        proposals[round][_tokenAddress] = Proposal({
            tokenAddress: _tokenAddress,
            projectName: _projectName,
            websiteUrl: _websiteUrl,
            whitepaperUrl: _whitepaperUrl,
            legalDocumentUrl: _legalDocumentUrl,
            icoStartDate: _icoStartDate,
            icoEndDate: _icoEndDate,
            icoRate: _icoRate,
            totalRaised: _totalRaised,
            totalContributions: 0
        });

        // Only allow refunding amount exceeding down payment.
        proposals[round][_tokenAddress].contributions[msg.sender] =
            downPayment - requiredDownPayment;
        proposals[round][_tokenAddress].totalContributions = downPayment;
        roundContribution[round] = roundContribution[round].add(
            downPayment - requiredDownPayment);
        listed[_tokenAddress] = false;

        if (downPayment >= softCap && downPayment < hardCap) {
            candidates.push(_tokenAddress);
            emit SoftCapReached(round, _tokenAddress);
        }

        if (downPayment >= hardCap) {
            listed[_tokenAddress] = true;
            emit TokenListed(round, _tokenAddress, refundable[_tokenAddress]);
        }

        refundable[_tokenAddress] = startTime + duration + 7 * 1 days;
        emit TokenProposed(round, _tokenAddress, refundable[_tokenAddress]);
    }

    function vote(address _tokenAddress) public {
        require(getCurrentTimestamp() >= startTime &&
                getCurrentTimestamp() < startTime + duration);
        require(proposals[round][_tokenAddress].totalContributions > 0);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        bool prevSoftCapReached =
            proposals[round][_tokenAddress].totalContributions >= softCap;
        uint256 allowedPayment = paymentToken.allowance(msg.sender, this);

        paymentToken.transferFrom(msg.sender, this, allowedPayment);
        proposals[round][_tokenAddress].contributions[msg.sender] =
            proposals[round][_tokenAddress].contributions[msg.sender].add(
                allowedPayment);
        proposals[round][_tokenAddress].totalContributions =
            proposals[round][_tokenAddress].totalContributions.add(
                allowedPayment);
        roundContribution[round] = roundContribution[round].add(allowedPayment);

        if (!prevSoftCapReached &&
            proposals[round][_tokenAddress].totalContributions >= softCap &&
            proposals[round][_tokenAddress].totalContributions < hardCap) {
            candidates.push(_tokenAddress);
            emit SoftCapReached(round, _tokenAddress);
        }

        if (proposals[round][_tokenAddress].totalContributions >= hardCap) {
            listed[_tokenAddress] = true;
            refundable[_tokenAddress] = 0;
            emit TokenListed(round, _tokenAddress, refundable[_tokenAddress]);
        }

        emit Vote(round, _tokenAddress, msg.sender, allowedPayment);
    }

    function setRefundable(address _tokenAddress, uint256 endTime)
        onlyOwner public {
        refundable[_tokenAddress] = endTime;
    }

    // For those claimed but not refund payment
    function withdrawBalance() onlyOwner public {
        require(getCurrentTimestamp() >= (prevEndTime + 7 * 1 days));

        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        paymentToken.transfer(beneficiary, paymentToken.balanceOf(this));
    }

    function refund(address _tokenAddress) public {
        require(refundable[_tokenAddress] > 0 &&
                prevEndTime > 0 &&
                getCurrentTimestamp() >= prevEndTime &&
                getCurrentTimestamp() < refundable[_tokenAddress]);

        StandardToken paymentToken = StandardToken(paymentTokenAddress);

        uint256 amount = proposals[round][_tokenAddress].contributions[msg.sender];
        if (amount > 0) {
            proposals[round][_tokenAddress].contributions[msg.sender] = 0;
            proposals[round][_tokenAddress].totalContributions =
                proposals[round][_tokenAddress].totalContributions.sub(amount);
            paymentToken.transfer(msg.sender, amount);
        }
    }

    function listTokenByRank() onlyOwner public {
        require(getCurrentTimestamp() >= startTime + duration &&
                !ranked);

        quickSort(0, candidates.length);

        uint collected = 0;
        for (uint i = 0; i < candidates.length && collected < numListed; i++) {
            if (!listed[candidates[i]]) {
                listed[candidates[i]] = true;
                refundable[candidates[i]] = 0;
                emit TokenListed(round, candidates[i], refundable[candidates[i]]);
                collected++;
            }
        }

        ranked = true;
    }

    function quickSort(uint beg, uint end) internal {
        if (beg + 1 >= end)
            return;

        uint pv = proposals[round][candidates[end - 1]].totalContributions;
        uint partition = beg;

        for (uint i = beg; i < end; i++) {
            if (proposals[round][candidates[i]].totalContributions > pv) {
                (candidates[partition], candidates[i]) =
                    (candidates[i], candidates[partition]);
                partition++;
            }
        }
        (candidates[partition], candidates[end - 1]) =
           (candidates[end - 1], candidates[partition]);

        quickSort(beg, partition);
        quickSort(partition + 1, end);
    }

    function getContributions(
        uint256 _round,
        address _tokenAddress,
        address contributor) view public returns (uint256) {
        return proposals[_round][_tokenAddress].contributions[contributor];
    }

    function numCandidates() view public returns (uint256) {
        return candidates.length;
    }

    function kill() public onlyOwner {
        StandardToken paymentToken = StandardToken(paymentTokenAddress);
        paymentToken.transfer(beneficiary, paymentToken.balanceOf(this));

        selfdestruct(beneficiary);
    }

    // Default method, we do not accept ether atm.
    function () public payable {
        revert();
    }
}