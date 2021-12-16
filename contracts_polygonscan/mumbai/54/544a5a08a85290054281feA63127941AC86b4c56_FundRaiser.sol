/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

pragma solidity 0.5.16;

/**
 * @title FundRaiser Smart Contract
 * @author Malarena SA - www.malarena.com
 * @notice A Fund Raising Smart Contract used to raise funds, with payments then released based on contributors voting
 */
contract FundRaiser {
  using SafeMath for uint256;
  // Initial set-up of Struct for Spending Requests
  struct Request {
    string description;
    uint256 value;
    address payable recipient;
    bool completed;
    uint256 numberOfVoters;
    mapping(address => bool) voters;
  }

  // Initial storage variables
  uint256 public deadline;  // Deadline Block Number for fundraising campaign
  uint256 public initialPaymentDeadline; // Deadline Block Number for initial payment release to be approved and processed
  uint256 public goal;  // Total amount needing to be raised, in wei
  uint256 public minimumContribution;  // Minimum contribution value, in wei
  address public owner;  // Ethereum address of the Smart Contract owner
  uint256 public totalContributors;  // Total number of contributors
  uint256 public totalRequests;  // Total number of spending requests
  uint256 public amountRaised;  // Total amount actually raised
  uint256 public amountPaidOut;  // Total amount actually paid out
  uint256 public requestCountMax = 100;  // Max Count of Spending Requests, required to stop refund/remove voting loop from getting out of gas. Recommend 100 and never > 1000

  Request[] public requests;

  mapping(address => uint256) public contributions;

  event Contribution(address indexed from, uint256 value);  // Confirmation of Contribution processed
  event Refund(address indexed to, uint256 value);  // Confirmation of Refund processed
  event RequestCreated(address indexed from, uint256 requestId, string description, uint256 value, address recipient);  // Confirmation of Spending Request Created
  event Vote(address indexed from, uint256 requestId);  // Confirmation of Vote processed
  event PaymentReleased(address indexed from, uint256 requestId, uint256 value, address recipient);  // Confirmation of Spending Request Payment Released
  event OwnerChanged(address indexed from, address to);  // Confirmation of Owner change processed

  /**
   * @notice Constructor Function used to deploy contract
   * @dev During Deploy the Ethereum address used to deploy the Smart Contract is set as the "owner" and certain functions below can only be actioned by the owner
   * @param _duration Duration of fund-raising part of Contract, in blocks
   * @param _initialPaymentDuration Period after _duration for owner to start releasing payments, in blocks
   * @param _goal Financial goal of the Smart Contract, in wei
   * @param _minimumContribution Minimum amount required for each contribution, in wei
   */
  constructor(uint256 _duration, uint256 _initialPaymentDuration, uint256 _goal, uint256 _minimumContribution) public {
    deadline = block.number + _duration;
    initialPaymentDeadline = block.number + _duration + _initialPaymentDuration;
    goal = _goal;
    minimumContribution = _minimumContribution;
    owner = msg.sender;
  }

  /**
   * @notice OnlyOwner Function Modifier
   * @dev Function Modifier used to restrict certain functions so that they can only be actioned by the contract owner
   */
  modifier onlyOwner {
    require(msg.sender == owner, "Caller is not the contract owner");
    _;
  }

  /**
   * @dev Fallback Function not allowed
   * @dev Removed as contracts without a fallback function now automatically revert payments
   */
  /*
  function() external {
    revert("Fallback method not allowed");
  }
  */

  /**
   * @notice Change the owner of the contract
   * @dev Can only be actioned by the current owner. Requires that _newOwner is not address zero
   * @param _newOwner Address of new contract owner
   */
  function changeOwner(address _newOwner) external onlyOwner returns (bool) {
    require(_newOwner != address(0), "Invalid Owner change to address zero");
    owner = _newOwner;
    emit OwnerChanged(msg.sender, _newOwner);
    return true;
  }

  /**
   * @notice Process a Contribution
   * @dev Payable function that should be sent Ether. Requires that minimum contribution value is met and deadline is not passed
   */
  function contribute() external payable returns (bool) {
    require(msg.value >= minimumContribution, "Minimum Contribution level not met");
    require(block.number <= deadline, "Deadline is passed");

    // Check if it is the first time the contributor is contributing
    if(contributions[msg.sender] == 0) {
      totalContributors = totalContributors.add(1);
    }
    contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    amountRaised = amountRaised.add(msg.value);
    emit Contribution(msg.sender, msg.value);
    return true;
  }

  /**
   * @notice Process a Refund, including reversing any voting
   * @dev Requires that the contribution exists, the deadline has passed and NO payments have been made. If the goal is reached then requires that initialPaymentDeadline has passed
   */
  function getRefund() external returns (bool) {
    require(contributions[msg.sender] > 0, "No contribution to return");
    require(block.number > deadline, "Deadline not reached");
    require(amountPaidOut == 0, "Payments have already been made");
    if (amountRaised >= goal) {
      require(block.number > initialPaymentDeadline, "Initial Payment Deadline not reached");
    }
    uint256 amountToRefund = contributions[msg.sender];
    contributions[msg.sender] = 0;
    totalContributors = totalContributors.sub(1);
    // amountRaised = amountRaised.sub(amountToRefund); // Removed to allow createRequest to still work if fundRaiser passed goal but then had refunds
    for (uint x = 0; (x < totalRequests && x < requestCountMax); x++) {
      Request storage thisRequest = requests[x];
      if (thisRequest.voters[msg.sender] == true) {
        thisRequest.voters[msg.sender] = false;
        thisRequest.numberOfVoters = thisRequest.numberOfVoters.sub(1);
      }
    }
    msg.sender.transfer(amountToRefund);
    emit Refund(msg.sender, amountToRefund);
    return true;
  }

  /**
   * @notice Create a spending request
   * @dev  Can only be actioned by the owner. Requires that the goal has been reached and the _value is not zero and does not exceed amountRaised or balance available on the contract. Also requires that _recipient is not address zero and requestCountMax has not been reached. Each spending request is stored sequentially starting from record 0
   * @param _description A description of what the money will be spent on
   * @param _value The amount being spent with this spending request
   * @param _recipient The Ethereum address of where the money will be sent
   */
  function createRequest(string calldata _description, uint256 _value, address payable _recipient) external onlyOwner returns (bool) {
    require(_value > 0, "Spending request value cannot be zero");
    require(amountRaised >= goal, "Amount Raised is less than Goal");
    require(_value <= address(this).balance, "Spending request value greater than amount available");
    require(_recipient != address(0), "Invalid Recipient of address zero");
    require(totalRequests < requestCountMax, "Spending Request Count limit reached");

    Request memory newRequest = Request({
      description: _description,
      value: _value,
      recipient: _recipient,
      completed: false,
      numberOfVoters: 0
    });
    requests.push(newRequest);
    totalRequests = totalRequests.add(1);
    emit RequestCreated(msg.sender, totalRequests.sub(1), _description, _value, _recipient);
    return true;
  }

  /**
   * @notice Vote for a spending request
   * @dev Requires that the caller made a contribution and has not already voted for the request. Also requires that the request exists and is not completed
   * @param _index Index Number of Spending Request to vote for
   */
  function voteForRequest(uint256 _index) external returns (bool) {
    require(totalRequests > _index, "Spending request does not exist");

    Request storage thisRequest = requests[_index];
    
    require(thisRequest.completed == false, "Request already completed");
    require(contributions[msg.sender] > 0, "No contribution from Caller");
    require(thisRequest.voters[msg.sender] == false, "Caller already voted");

    thisRequest.voters[msg.sender] = true;
    thisRequest.numberOfVoters = thisRequest.numberOfVoters.add(1);
    emit Vote(msg.sender, _index);
    return true;
  }

  /**
   * @notice View if account has voted for spending request
   * @dev Requires that the request exists
   * @param _index Index Number of Spending Request to check
   * @param _account Address of Account to check
   */
  function hasVoted(uint256 _index, address _account) external view returns (bool) {
    require(totalRequests > _index, "Spending request does not exist");
    Request storage thisRequest = requests[_index];
    return thisRequest.voters[_account];
  }

  /**
   * @notice Release the payment for a spending request
   * @dev Can only be actioned by the owner. Requires that the request exists and is not completed, and that there are funds available to make the payment. Also requires that over 50% of the contributors voted for the request
   * @param _index Index Number of Spending Request to release payment
   */
  function releasePayment(uint256 _index) external onlyOwner returns (bool) {
    require(totalRequests > _index, "Spending request does not exist");

    Request storage thisRequest = requests[_index];

    require(thisRequest.completed == false, "Request already completed");
    require(thisRequest.numberOfVoters > totalContributors / 2, "Less than a majority voted");
    require(thisRequest.value <= address(this).balance, "Spending request value greater than amount available");

    amountPaidOut = amountPaidOut.add(thisRequest.value);
    thisRequest.completed = true;
    thisRequest.recipient.transfer(thisRequest.value);
    emit PaymentReleased(msg.sender, _index, thisRequest.value, thisRequest.recipient);
    return true;
  }

  /**
   * @notice Test Functions
   * @dev These functions are ONLY required to expose the SafeMath internal Library functions and the changeRequestCountMax function for testing. These can be commented or removed after testing
   */
  /* < Remove this line for testing
  function testAdd(uint256 a, uint256 b) external pure returns (uint256) {
    return SafeMath.add(a, b);
  }

  function testSub(uint256 a, uint256 b) external pure returns (uint256) {
    return SafeMath.sub(a, b);
  }

  event RequestCountMaxChanged(uint256 value);

  function changeRequestCountMax(uint256 _newRequestCountMax) external onlyOwner returns (bool) {
    require(_newRequestCountMax > 0, "Request Count limit cannot be less than zero");
    require(_newRequestCountMax >= totalRequests, "Request Count limit cannot be less than Total Current Requests");
    requestCountMax = _newRequestCountMax;
    emit RequestCountMaxChanged( _newRequestCountMax);
    return true;
  }
  Remove this line for testing > */ 
}

/**
 * @notice SafeMath Library
 * @dev Based on OpenZeppelin/SafeMath Library
 * @dev Used to avoid Solidity Overflow Errors
 * @dev Only add and sub functions used in this contract - others removed
 */
library SafeMath {
  // Returns the addition of two unsigned integers & reverts on overflow
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  // Returns the subtraction of two unsigned integers & reverts on overflow
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
}