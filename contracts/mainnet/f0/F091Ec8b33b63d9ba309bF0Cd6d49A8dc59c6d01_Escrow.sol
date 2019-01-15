pragma solidity ^0.4.15;


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}








/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}





/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract OpportyToken is StandardToken {

  string public constant name = "OpportyToken";
  string public constant symbol = "OPP";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function OpportyToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}




contract Escrow is Ownable {
  // status of the project
  enum Status { NEW, PAYED, WORKDONE, CLAIMED, CLOSED }

  // status of the current work
  enum WorkStatus {NEW, STARTED, FULLYDONE, PARTIALLYDONE }

  // token address
  address tokenHolder = 0x08990456DC3020C93593DF3CaE79E27935dd69b9;

  // execute funciton only by token holders
  modifier onlyShareholders {
      require (token.balanceOf(msg.sender) > 0);
      _;
  }

  // transaction only after deadline
  modifier afterDeadline(uint idProject)
  {
    Project storage project = projects[idProject];
    require (now > project.deadline) ;
    _;
  }

  // transaction can be executed  by project client
  modifier onlyClient(uint idProject) {
    Project storage project = projects[idProject];

    require (project.client == msg.sender);
    _;
  }

  // transaction can be executed only by performer
  modifier onlyPerformer(uint idProject) {
    Project storage project = projects[idProject];
    require (project.performer == msg.sender);
    _;
  }

  // project in Opporty system
  // TODO: decrease size of struct
  struct Project {
    uint id;
    string  name;
    address client;
    address performer;
    uint deadline;
    uint sum;
    Status status;
    string report;
    WorkStatus wstatus;
    uint votingDeadline;
    uint numberOfVotes;
    uint totalVotesNeeded;
    bool withdrawed;
    Vote[] votes;
    mapping (address => bool) voted;
  }
  // one vote - one element of struct
  struct Vote {
      bool inSupport;
      address voter;
  }
  // event - project was added
  event ProjectAdded(uint idExternal, uint projectID, address performer, string name, uint sum);
  // event - fund was transferred
  event FundTransfered(address recipient, uint amount);
  // work was done
  event WorkDone(uint projectId, address performer, WorkStatus status, string link);
  // already voted
  event Voted(uint projectID, bool position, address voter);
  // status of project changed
  event ChangedProjectStatus(uint projectID, Status status);

  event log(string val);
  event loga(address addr);
  event logi(uint i);

  // token for payments
  OpportyToken token;

  // all projects
  Project[] projects;


  // number or projects
  uint public numProjects;

  function Escrow(address tokenUsed) public
  {
    token = OpportyToken(tokenUsed);
  }

  function getNumberOfProjects() public constant  returns(uint)
  {
    return numProjects;
  }

  // Add a project to blockchain
  // idExternal - id in opporty
  // name
  // performer
  // duration
  // sum
  function addProject(uint idExternal, string name, address performer, uint durationInMinutes, uint sum) public
     returns (uint projectId)
  {
    projectId = projects.length++;
    Project storage p = projects[projectId];
    p.id = idExternal;
    p.name = name;
    p.client = msg.sender;
    p.performer = performer;
    p.deadline = now + durationInMinutes * 1 minutes;
    p.sum = sum * 1 ether;
    p.status = Status.NEW;

    ProjectAdded(idExternal, projectId, performer, name, sum);
    return projectId;
  }

  function getProjectReport(uint idProject) public constant returns (string t) {
    Project storage p = projects[idProject];
    return p.report;
  }

  function getJudgeVoted(uint idProject, address judge) public constant returns (bool voted) {
    Project storage p = projects[idProject];
    if (p.voted[judge])
      return true;
       else
      return false;
  }

  // get status of project
  function getStatus(uint idProject) public constant returns (uint t) {
    Project storage p = projects[idProject];
    return uint(p.status);
  }

  // is deadline
  function isDeadline(uint idProject) public constant returns (bool f) {
      Project storage p = projects[idProject];

      if (now >= p.deadline) {
        return true;
      } else {
        return false;
      }
  }
  // pay for project by client
  function payFor(uint idProject) payable onlyClient(idProject) public returns (bool) {
    Project storage project = projects[idProject];

    uint price = project.sum;

    require (project.status == Status.NEW);
    if (msg.value >= price) {
      project.status = Status.PAYED;
      FundTransfered(this, msg.value);
      ChangedProjectStatus(idProject, Status.PAYED);
      return true;
    } else {
      revert();
    }
  }
  // pay by project in tokens
  function payByTokens(uint idProject) onlyClient(idProject) onlyShareholders public {
    Project storage project = projects[idProject];
    require (project.sum <= token.balanceOf(project.client));
    require (token.transferFrom(project.client, tokenHolder, project.sum));

    ChangedProjectStatus(idProject, Status.PAYED);
  }
  // change status of project - done
  // and provide report
  function workDone(uint idProject, string report, WorkStatus status) onlyPerformer(idProject) afterDeadline(idProject) public {
    Project storage project = projects[idProject];
    require (project.status == Status.PAYED);

    project.status = Status.WORKDONE;
    project.report = report;
    project.wstatus = status;

    WorkDone(idProject, project.performer, project.wstatus, project.report);
    ChangedProjectStatus(idProject, Status.WORKDONE);
  }
  // work is done - execured by client
  function acceptWork(uint idProject) onlyClient(idProject) afterDeadline(idProject) public {
    Project storage project = projects[idProject];
    require (project.status == Status.WORKDONE);
    project.status = Status.CLOSED;
    ChangedProjectStatus(idProject, Status.CLOSED);
  }
  // claim - project was undone (?)
  // numberOfVoters
  // debatePeriod - time for voting
  function claimWork(uint idProject, uint numberOfVoters, uint debatePeriod) afterDeadline(idProject) public {
    Project storage project = projects[idProject];
    require (project.status == Status.WORKDONE);
    project.status = Status.CLAIMED;
    project.votingDeadline = now + debatePeriod * 1 minutes;
    project.totalVotesNeeded = numberOfVoters;
    ChangedProjectStatus(idProject, Status.CLAIMED);
  }

  // voting process
  function vote(uint idProject, bool supportsProject) public
        returns (uint voteID)
  {
        Project storage p = projects[idProject];
        require(p.voted[msg.sender] != true);
        require(p.status == Status.CLAIMED);
        require(p.numberOfVotes < p.totalVotesNeeded);
        require(now >= p.votingDeadline );

        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProject, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID + 1;
        Voted(idProject,  supportsProject, msg.sender);
        return voteID;
  }

  // safeWithdrawal - get money by performer / return money for client
  function safeWithdrawal(uint idProject) afterDeadline(idProject) public
  {
      Project storage p = projects[idProject];

      // if status closed and was not withdrawed
      require(p.status == Status.CLAIMED || p.status == Status.CLOSED && !p.withdrawed);

      // if project closed
      if (p.status == Status.CLOSED) {

        if (msg.sender == p.performer && !p.withdrawed && msg.sender.send(p.sum) ) {
          FundTransfered(msg.sender, p.sum);
          p.withdrawed = true;
        } else {
          revert();
        }
      } else {
        // claim
        uint yea = 0;
        uint nay = 0;
        // calculating votes
        for (uint i = 0; i <  p.votes.length; ++i) {
            Vote storage v = p.votes[i];

            if (v.inSupport) {
                yea += 1;
            } else {
                nay += 1;
            }
        }
        // если уже время голосования закончилось
        if (now >= p.votingDeadline) {
         if (msg.sender == p.performer && p.numberOfVotes >= p.totalVotesNeeded ) {
            if (yea>nay && !p.withdrawed && msg.sender.send(p.sum)) {
              FundTransfered(msg.sender, p.sum);
              p.withdrawed = true;
              p.status = Status.CLOSED;
              ChangedProjectStatus(idProject, Status.CLOSED);
            }
          }

          if (msg.sender == p.client) {
            if (nay>=yea && !p.withdrawed &&  msg.sender.send(p.sum)) {
              FundTransfered(msg.sender, p.sum);
              p.withdrawed = true;
              p.status = Status.CLOSED;
              // меняем статус проекта
              ChangedProjectStatus(idProject, Status.CLOSED);
            }
          }
        } else {
          revert();
        }
      }
  }

  // get tokens
  function safeWithdrawalTokens(uint idProject) afterDeadline(idProject) public
  {
    Project storage p = projects[idProject];
    require(p.status == Status.CLAIMED || p.status == Status.CLOSED && !p.withdrawed);

    if (p.status == Status.CLOSED) {

      if (msg.sender == p.performer && token.transfer(p.performer, p.sum) && !p.withdrawed) {
        FundTransfered(msg.sender, p.sum);
        p.withdrawed = true;
      } else {
        revert();
      }
    }
  }
}