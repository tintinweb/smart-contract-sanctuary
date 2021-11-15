pragma solidity ^0.5.0;

import "./StandardBounties.sol";
import "./EthlanceJobs.sol";
import "./token/IERC20.sol";
import "./token/IERC721.sol";

contract EthlanceIssuer {

  StandardBounties internal constant standardBounties = StandardBounties(0x27138fF9AA8AaAd29D39E8cce090CB805b0cb7d5);
  EthlanceJobs internal constant ethlanceJobs = EthlanceJobs(0x8Dc3B86d0E1E5dc62B7753162F1a032f3edE7973);

  enum JobType {EthlanceJob, StandardBounty}

  struct TokenParams {
    address token;
    uint tokenVersion;
  }

  // Track invited arbiters and their fees
  mapping(address => mapping(uint => uint)) public jobsArbitersFees;
  mapping(address => mapping(uint => uint)) public bountiesArbitersFees;

  // Track accepted (payed) arbiters per job
  mapping(uint => address) public jobsAcceptedArbiters;
  mapping(uint => address) public bountiesAcceptedArbiters;

  mapping(uint => TokenParams) public bounties;
  mapping(uint => TokenParams) public jobs;

  function transfer(address from, address to, address token, uint tokenVersion, uint depositAmount) private {
    require(depositAmount > 0, "Insufficient amount"); // Contributions of 0 tokens or token ID 0 should fail

    if (tokenVersion == 0){
      if(from == address(this)){
        address payable toPayable = address(uint160(to));
        toPayable.send(depositAmount);
      }else{
        require(msg.value >= depositAmount,"Insuficien ETH");
      }

    } else if (tokenVersion == 20){

      require(msg.value == 0, "No ETH should be provided for ERC20"); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds

      require(IERC20(token).transferFrom(from,to,depositAmount), "Couldn't transfer ERC20");
    } else if (tokenVersion == 721){
      require(msg.value == 0,"No ETH should be provided for tokenVersion 721"); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      IERC721(token).transferFrom(from,to,depositAmount);
    } else {
      revert();
    }
  }

  /**
      This function is for inviting more arbiters, in case nobody
      accepted in the first round of invites.
  */
  function inviteArbiters(address[] memory arbiters, uint fee, uint feeCurrencyId, uint jobId, JobType jobType) public payable {
    address token = bounties[jobId].token;
    uint tokenVersion = bounties[jobId].tokenVersion;

    // If paying in eth make sure you send enough funds for paying all arbiters
    if(tokenVersion == 0) require(msg.value == fee*arbiters.length,"Insuficien funds");

    // Transfer the fee that is going to be payed to the first arbiter who accepts
    transfer(msg.sender,address(this), token, tokenVersion, fee);

    for(uint i = 0; i < arbiters.length; i ++){
      // transfer fee to this contract so we can transfer it to arbiter when
      // invitation gets accepted


      if(jobType == JobType.StandardBounty){
        bountiesArbitersFees[arbiters[i]][jobId] = fee;
      } else if (jobType == JobType.EthlanceJob){
        jobsArbitersFees[arbiters[i]][jobId] = fee;
      }
    }

    emit ArbitersInvited(arbiters, fee, feeCurrencyId, jobId, jobType);
  }

  /**
     This function creates a bounty in StandardBouties contract,
     passing as issuers addresses of this contract and sender's
     address. Also it stores addresses of invited arbiters (approvers)
     and arbiter's fee for created bounty.
  */
  function issueBounty(string memory bountyData, uint deadline, address token, uint tokenVersion, uint depositAmount) public payable{
    address[] memory arbiters=new address [](0);

    // EthlanceBountyIssuer is the issuer of all bounties
    address payable[] memory issuers = new address payable[](1);

    address payable thisPayable = address(uint160(address(this)));
    issuers[0] = thisPayable;

    transfer(msg.sender, address(this), token, tokenVersion, depositAmount);

    // Also pass whatever value was sent to us forward
    uint bountyId = standardBounties.issueAndContribute.value(msg.value)(thisPayable,
                                                                         issuers,
                                                                         arbiters,
                                                                         bountyData,
                                                                         deadline,
                                                                         token,
                                                                         tokenVersion,
                                                                         depositAmount);

    bounties[bountyId] = TokenParams(token, tokenVersion);

  }

  /**
     This function creates a job in EthlanceJobs contract,
     passing as issuers addresses of this contract and sender's
     address. Also it stores addresses of invited arbiters (approvers)
     and arbiter's fee for created Job.
  */
  function issueJob(string memory jobData, address token, uint tokenVersion, uint depositAmount) public payable{
    address[] memory arbiters = new address [](0);

    // EthlanceBountyIssuer is the issuer of all bounties
    address payable[] memory issuers = new address payable[](1);

    address payable thisPayable = address(uint160(address(this)));
    issuers[0] = thisPayable;

    transfer(msg.sender, address(this), token, tokenVersion, depositAmount);

    // Also pass whatever value was sent to us forward
    uint jobId = ethlanceJobs.issueAndContribute.value(msg.value)(thisPayable,
                                                                  issuers,
                                                                  arbiters,
                                                                  jobData,
                                                                  token,
                                                                  tokenVersion,
                                                                  depositAmount);

    jobs[jobId] = TokenParams(token, tokenVersion);

  }

  /**
     Arbiter runs this function to accept invitation. If he's first, it'll
     transfer fee to him and it'll add him as arbiter for the bounty.
  */
  function acceptArbiterInvitation(JobType jobType, uint jobId) public {
    // check that it was invited

    address[] memory arbiters = new address [](1);
    arbiters[0] = msg.sender;
    address token;
    uint tokenVersion;
    uint fee;


    if(jobType == JobType.StandardBounty){

      if(bountiesAcceptedArbiters[jobId] != address(0)){
        revert("This position is close.");
      }

      fee=bountiesArbitersFees[msg.sender][jobId];
      standardBounties.addApprovers(address(this),
                                    jobId,
                                    0, // since there is only one issuer, it is the first one
                                    arbiters);
      token = bounties[jobId].token;
      tokenVersion = bounties[jobId].tokenVersion;
    } else if (jobType == JobType.EthlanceJob){

      if(jobsAcceptedArbiters[jobId] != address(0)){
        revert("This position is close.");
      }

      fee=jobsArbitersFees[msg.sender][jobId];

      ethlanceJobs.addApprovers(address(this),
                                jobId,
                                0, // since there is only one issuer, it is the first one
                                arbiters);
      token = jobs[jobId].token;
      tokenVersion = jobs[jobId].tokenVersion;
    }

    require(fee > 0,"Arbiters fees should be greater than zero.");

    transfer(address(this), msg.sender, token, tokenVersion, fee);

    emit ArbiterAccepted(msg.sender, jobId);
  }

  event ArbitersInvited(address[] _arbiters, uint _fee, uint _feeCurrencyId, uint _jobId, JobType _jobType);
  event ArbiterAccepted(address _arbiter, uint _jobId);

}

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./token/IERC20.sol";
import "./token/IERC721.sol";
import "./math/SafeMath.sol";


/// @title EthlanceJob
/// @dev A contract for issuing jobs on Ethereum paying in ETH, ERC20, or ERC721 tokens
/// @author Mark Beylin <[email protected]>, Gonçalo Sá <[email protected]>, Kevin Owocki <[email protected]>, Ricardo Guilherme Schmidt (@3esmit), Matt Garnett <[email protected]>, Craig Williams <[email protected]>
contract EthlanceJobs {

  using SafeMath for uint256;

  /*
   * Structs
   */

  struct Job {
    address payable[] issuers; // An array of individuals who have complete control over the job, and can edit any of its parameters
    address[] approvers; // An array of individuals who are allowed to accept the invoices for a particular job
    address token; // The address of the token associated with the job (should be disregarded if the tokenVersion is 0)
    uint tokenVersion; // The version of the token being used for the job (0 for ETH, 20 for ERC20, 721 for ERC721)
    uint balance; // The number of tokens which the job is able to pay out or refund
    Invoice[] invoices; // An array of Invoice which store the various submissions which have been made to the job
    Contribution[] contributions; // An array of Contributions which store the contributions which have been made to the job
    address[] hiredCandidates;
  }

  struct Invoice {
    address payable issuer; // Address who should receive payouts for a given submission
    address submitter;
    uint amount;
    bool cancelled;
  }

  struct Contribution {
    address payable contributor; // The address of the individual who contributed
    uint amount; // The amount of tokens the user contributed
    bool refunded; // A boolean storing whether or not the contribution has been refunded yet
  }

  /*
   * Storage
   */

  uint public numJobs; // An integer storing the total number of jobs in the contract
  mapping(uint => Job) public jobs; // A mapping of jobIDs to jobs
  mapping (uint => mapping (uint => bool)) public tokenBalances; // A mapping of jobIds to tokenIds to booleans, storing whether a given job has a given ERC721 token in its balance


  address public owner; // The address of the individual who's allowed to set the metaTxRelayer address
  address public metaTxRelayer; // The address of the meta transaction relayer whose _sender is automatically trusted for all contract calls

  bool public callStarted; // Ensures mutex for the entire contract

  /*
   * Modifiers
   */

  modifier callNotStarted(){
    require(!callStarted);
    callStarted = true;
    _;
    callStarted = false;
  }

  modifier validateJobArrayIndex(
                                 uint _index)
  {
    require(_index < numJobs);
    _;
  }

  modifier validateContributionArrayIndex(
                                          uint _jobId,
                                          uint _index)
  {
    require(_index < jobs[_jobId].contributions.length);
    _;
  }

  modifier validateInvoiceArrayIndex(
                                         uint _jobId,
                                         uint _index)
  {
    require(_index < jobs[_jobId].invoices.length);
    _;
  }

  modifier validateIssuerArrayIndex(
                                    uint _jobId,
                                    uint _index)
  {
    require(_index < jobs[_jobId].issuers.length);
    _;
  }

  modifier validateApproverArrayIndex(
                                      uint _jobId,
                                      uint _index)
  {
    require(_index < jobs[_jobId].approvers.length);
    _;
  }

  modifier onlyIssuer(
                      address _sender,
                      uint _jobId,
                      uint _issuerId)
  {
    require(_sender == jobs[_jobId].issuers[_issuerId]);
    _;
  }

  modifier onlyInvoiceIssuer(
                         address _sender,
                         uint _jobId,
                         uint _invoiceId)
  {
    require(_sender ==
            jobs[_jobId].invoices[_invoiceId].issuer);
    _;
  }

  modifier onlyContributor(
                           address _sender,
                           uint _jobId,
                           uint _contributionId)
  {
    require(_sender ==
            jobs[_jobId].contributions[_contributionId].contributor);
    _;
  }

  modifier isApprover(
                      address _sender,
                      uint _jobId,
                      uint _approverId)
  {
    require(_sender == jobs[_jobId].approvers[_approverId]);
    _;
  }

  modifier hasNotRefunded(
                          uint _jobId,
                          uint _contributionId)
  {
    require(!jobs[_jobId].contributions[_contributionId].refunded);
    _;
  }

  modifier senderIsValid(
                         address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }

  /*
   * Public functions
   */

  constructor() public {
    // The owner of the contract is automatically designated to be the deployer of the contract
    owner = msg.sender;
  }

  /// @dev setMetaTxRelayer(): Sets the address of the meta transaction relayer
  /// @param _relayer the address of the relayer
  function setMetaTxRelayer(address _relayer)
    external
  {
    require(msg.sender == owner); // Checks that only the owner can call
    require(metaTxRelayer == address(0)); // Ensures the meta tx relayer can only be set once
    metaTxRelayer = _relayer;
  }

  function contains(address[] memory arr, address x) private pure returns(bool)
  {
    bool found = false;
    uint i = 0;
    while(i < arr.length && !found){
      found = arr[i] == x;
      i++;
    }
    return found;
  }

  function acceptCandidate(uint jobId, address candidate)
    public
  {
    // Add the candidate as selected for the job
    jobs[jobId].hiredCandidates.push(candidate);

    emit CandidateAccepted(jobId, candidate);
  }

  /// @dev issueJob(): creates a new job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _issuers the array of addresses who will be the issuers of the job
  /// @param _approvers the array of addresses who will be the approvers of the job
  /// @param _ipfsHash the IPFS hash representing the JSON object storing the details of the job (see docs for schema details)
  /// @param _token the address of the token which will be used for the job
  /// @param _tokenVersion the version of the token being used for the job (0 for ETH, 20 for ERC20, 721 for ERC721)
  function issueJob(
                    address payable _sender,
                    address payable[] memory _issuers,
                    address[] memory _approvers,
                    string memory _ipfsHash,
                    address _token,
                    uint _tokenVersion)
    public
    senderIsValid(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721); // Ensures a job can only be issued with a valid token version
    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver

    uint jobId = numJobs; // The next job's index will always equal the number of existing jobs

    Job storage newJob = jobs[jobId];
    newJob.issuers = _issuers;
    newJob.approvers = _approvers;
    newJob.tokenVersion = _tokenVersion;

    if (_tokenVersion != 0){
      newJob.token = _token;
    }

    numJobs = numJobs.add(1); // Increments the number of jobs, since a new one has just been added

    emit JobIssued(jobId,
                   _sender,
                   _issuers,
                   _approvers,
                   _ipfsHash, // Instead of storing the string on-chain, it is emitted within the event for easy off-chain consumption
                   _token,
                   _tokenVersion);

    return (jobId);
  }

  /// @param _depositAmount the amount of tokens being deposited to the job, which will create a new contribution to the job


  function issueAndContribute(
                              address payable _sender,
                              address payable[] memory _issuers,
                              address[] memory _approvers,
                              string memory _ipfsHash,
                              address _token,
                              uint _tokenVersion,
                              uint _depositAmount)
    public
    payable
    returns(uint)
  {
    uint jobId = issueJob(_sender, _issuers, _approvers, _ipfsHash, _token, _tokenVersion);

    contribute(_sender, jobId, _depositAmount);

    return (jobId);
  }


  /// @dev contribute(): Allows users to contribute tokens to a given job.
  ///                    Contributing merits no privelages to administer the
  ///                    funds in the job or accept submissions. Contributions
  ///                    has elapsed, and the job has not yet paid out any funds.
  ///                    All funds deposited in a job are at the mercy of a
  ///                    job's issuers and approvers, so please be careful!
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _amount the amount of tokens being contributed
  function contribute(
                      address payable _sender,
                      uint _jobId,
                      uint _amount)
    public
    payable
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    callNotStarted
  {
    require(_amount > 0); // Contributions of 0 tokens or token ID 0 should fail

    jobs[_jobId].contributions.push(
                                    Contribution(_sender, _amount, false)); // Adds the contribution to the job

    if (jobs[_jobId].tokenVersion == 0){

      jobs[_jobId].balance = jobs[_jobId].balance.add(_amount); // Increments the balance of the job

      require(msg.value == _amount);
    } else if (jobs[_jobId].tokenVersion == 20){

      jobs[_jobId].balance = jobs[_jobId].balance.add(_amount); // Increments the balance of the job

      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      require(IERC20(jobs[_jobId].token).transferFrom(_sender,
                                                      address(this),
                                                      _amount));
    } else if (jobs[_jobId].tokenVersion == 721){
      tokenBalances[_jobId][_amount] = true; // Adds the 721 token to the balance of the job


      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      IERC721(jobs[_jobId].token).transferFrom(_sender,
                                               address(this),
                                               _amount);
    } else {
      revert();
    }

    emit ContributionAdded(_jobId,
                           jobs[_jobId].contributions.length - 1, // The new contributionId
                           _sender,
                           _amount);
  }

  /// @dev refundContribution(): Allows users to refund the contributions they've
  ///                            made to a particular job, but only if the job
  ///                            has not yet paid out
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _issuerId the issuer id for thre job
  /// @param _jobId the index of the job
  /// @param _contributionId the index of the contribution being refunded
  function refundContribution(
                              address _sender,
                              uint _jobId,
                              uint _issuerId,
                              uint _contributionId)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateContributionArrayIndex(_jobId, _contributionId)
    onlyIssuer(_sender, _jobId, _issuerId)
    hasNotRefunded(_jobId, _contributionId)
    callNotStarted
  {

    Contribution storage contribution = jobs[_jobId].contributions[_contributionId];

    contribution.refunded = true;

    transferTokens(_jobId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor

    emit ContributionRefunded(_jobId, _contributionId);
  }

  /// @dev refundMyContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundMyContributions(
                                 address _sender,
                                 uint _jobId,
                                 uint _issuerId,
                                 uint[] memory _contributionIds)
    public
    senderIsValid(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      refundContribution(_sender, _jobId, _issuerId, _contributionIds[i]);
    }
  }

  /// @dev refundContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundContributions(
                               address _sender,
                               uint _jobId,
                               uint _issuerId,
                               uint[] memory _contributionIds)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    onlyIssuer(_sender, _jobId, _issuerId)
    callNotStarted
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      require(_contributionIds[i] < jobs[_jobId].contributions.length);

      Contribution storage contribution = jobs[_jobId].contributions[_contributionIds[i]];

      require(!contribution.refunded);

      contribution.refunded = true;

      transferTokens(_jobId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor
    }

    emit ContributionsRefunded(_jobId, _sender, _contributionIds);
  }

  /// @dev drainJob(): Allows an issuer to drain the funds from the job
  /// @notice when using this function, if an issuer doesn't drain the entire balance, some users may be able to refund their contributions, while others may not (which is unfair to them). Please use it wisely, only when necessary
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _amounts an array of amounts of tokens to be sent. The length of the array should be 1 if the job is in ETH or ERC20 tokens. If it's an ERC721 job, the array should be the list of tokenIDs.
  function drainJob(
                    address payable _sender,
                    uint _jobId,
                    uint _issuerId,
                    uint[] memory _amounts)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    onlyIssuer(_sender, _jobId, _issuerId)
    callNotStarted
  {
    if (jobs[_jobId].tokenVersion == 0 || jobs[_jobId].tokenVersion == 20){
      require(_amounts.length == 1); // ensures there's only 1 amount of tokens to be returned
      require(_amounts[0] <= jobs[_jobId].balance); // ensures an issuer doesn't try to drain the job of more tokens than their balance permits
      transferTokens(_jobId, _sender, _amounts[0]); // Performs the draining of tokens to the issuer
    } else {
      for (uint i = 0; i < _amounts.length; i++){
        require(tokenBalances[_jobId][_amounts[i]]);// ensures an issuer doesn't try to drain the job of a token it doesn't have in its balance
        transferTokens(_jobId, _sender, _amounts[i]);
      }
    }

    emit JobDrained(_jobId, _sender, _amounts);
  }

  /// @dev invoiceJob(): Allows users to invoice the job to get paid out
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _invoiceIssuer The invoice issuer, the addresses which will receive payouts for the submission
  /// @param _ipfsHash the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function invoiceJob(
                      address _sender,
                      uint _jobId,
                      address payable _invoiceIssuer,
                      string memory _ipfsHash,
                      uint _amount)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
  {
    require(contains(jobs[_jobId].hiredCandidates, _sender));

    jobs[_jobId].invoices.push(Invoice(_invoiceIssuer, _sender, _amount, false));

    emit JobInvoice(_jobId,
                    (jobs[_jobId].invoices.length - 1),
                    _invoiceIssuer,
                    _ipfsHash, // The _ipfsHash string is emitted in an event for easy off-chain consumption
                    _sender,
                    _amount);
  }

  /// @dev cancelInvoice(): Allows the sender of the invoice to cancel it
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _invoiceId the index of the invoice to be accepted
  function cancelInvoice(
                         address _sender,
                         uint _jobId,
                         uint _invoiceId
                         )
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateInvoiceArrayIndex(_jobId, _invoiceId)
  {
    Invoice storage invoice=jobs[_jobId].invoices[_invoiceId];

    if(invoice.submitter != _sender){
      revert("Only the original invoice sender can cancel it.");
    }

    invoice.cancelled=true;
    emit InvoiceCancelled(_sender, _jobId, _invoiceId);
  }

  /// @dev acceptInvoice(): Allows any of the approvers to accept a given submission
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _invoiceId the index of the invoice to be accepted
  /// @param _approverId the index of the approver which is making the call

  function acceptInvoice(
                         address _sender,
                         uint _jobId,
                         uint _invoiceId,
                         uint _approverId
                         )
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateInvoiceArrayIndex(_jobId, _invoiceId)
    isApprover(_sender, _jobId, _approverId)
    callNotStarted
  {
    Invoice storage invoice = jobs[_jobId].invoices[_invoiceId];

    if(invoice.cancelled){
      revert("Can't accept a cancelled input");
    }

    transferTokens(_jobId, invoice.issuer,invoice.amount);

    emit InvoiceAccepted(_jobId,
                         _invoiceId,
                         _sender,
                         invoice.amount);
  }

  /// @dev invoiceAndAccept(): Allows any of the approvers to invoice and accept a submission simultaneously
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _invoiceIssuer the array of addresses which will receive payouts for the submission
  /// @param _ipfsHash the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  /// @param _approverId the index of the approver which is making the call
  function invoiceAndAccept(
                            address _sender,
                            uint _jobId,
                            address payable _invoiceIssuer,
                            string memory _ipfsHash,
                            uint _approverId,
                            uint _amount)
    public
    senderIsValid(_sender)
  {
    // first invoice the job on behalf of the _invoiceIssuer
    invoiceJob(_sender, _jobId, _invoiceIssuer, _ipfsHash, _amount);

    // then accepts the invoice
    acceptInvoice(_sender,
                  _jobId,
                  jobs[_jobId].invoices.length - 1,
                  _approverId
                  );
  }



  /// @dev changeJob(): Allows any of the issuers to change the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the new array of addresses who will be the issuers of the job
  /// @param _approvers the new array of addresses who will be the approvers of the job
  /// @param _ipfsHash the new IPFS hash representing the JSON object storing the details of the job (see docs for schema details)
  function changeJob(
                     address _sender,
                     uint _jobId,
                     uint _issuerId,
                     address payable[] memory _issuers,
                     address payable[] memory _approvers,
                     string memory _ipfsHash
                     )
    public
    senderIsValid(_sender)
  {
    require(_jobId < numJobs); // makes the validateJobArrayIndex modifier in-line to avoid stack too deep errors
    require(_issuerId < jobs[_jobId].issuers.length); // makes the validateIssuerArrayIndex modifier in-line to avoid stack too deep errors
    require(_sender == jobs[_jobId].issuers[_issuerId]); // makes the onlyIssuer modifier in-line to avoid stack too deep errors

    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    jobs[_jobId].issuers = _issuers;
    jobs[_jobId].approvers = _approvers;
    emit JobChanged(_jobId,
                    _sender,
                    _issuers,
                    _approvers,
                    _ipfsHash);
  }

  /// @dev changeIssuer(): Allows any of the issuers to change a particular issuer of the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuerIdToChange the index of the issuer who is being changed
  /// @param _newIssuer the address of the new issuer
  function changeIssuer(
                        address _sender,
                        uint _jobId,
                        uint _issuerId,
                        uint _issuerIdToChange,
                        address payable _newIssuer)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerIdToChange)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    require(_issuerId < jobs[_jobId].issuers.length || _issuerId == 0);

    jobs[_jobId].issuers[_issuerIdToChange] = _newIssuer;

    emit JobIssuersUpdated(_jobId, _sender, jobs[_jobId].issuers);
  }

  /// @dev changeApprover(): Allows any of the issuers to change a particular approver of the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approverId the index of the approver who is being changed
  /// @param _approver the address of the new approver
  function changeApprover(
                          address _sender,
                          uint _jobId,
                          uint _issuerId,
                          uint _approverId,
                          address payable _approver)
    external
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    onlyIssuer(_sender, _jobId, _issuerId)
    validateApproverArrayIndex(_jobId, _approverId)
  {
    jobs[_jobId].approvers[_approverId] = _approver;

    emit JobApproversUpdated(_jobId, _sender, jobs[_jobId].approvers);
  }

  /// @dev changeData(): Allows any of the issuers to change the data the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _ipfsHash the new IPFS hash representing the JSON object storing the details of the job (see docs for schema details)
  function changeData(
                      address _sender,
                      uint _jobId,
                      uint _issuerId,
                      string memory _ipfsHash)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerId)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    emit JobDataChanged(_jobId, _sender, _ipfsHash); // The new _ipfsHash is emitted within an event rather than being stored on-chain for minimized gas costs
  }


  /// @dev addIssuers(): Allows any of the issuers to add more issuers to the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to add to the list of valid issuers
  function addIssuers(
                      address _sender,
                      uint _jobId,
                      uint _issuerId,
                      address payable[] memory _issuers)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerId)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      jobs[_jobId].issuers.push(_issuers[i]);
    }

    emit JobIssuersUpdated(_jobId, _sender, jobs[_jobId].issuers);
  }

  /// @dev replaceIssuers(): Allows any of the issuers to replace the issuers of the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to replace the list of valid issuers
  function replaceIssuers(
                          address _sender,
                          uint _jobId,
                          uint _issuerId,
                          address payable[] memory _issuers)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerId)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    require(_issuers.length > 0 || jobs[_jobId].approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    jobs[_jobId].issuers = _issuers;

    emit JobIssuersUpdated(_jobId, _sender, jobs[_jobId].issuers);
  }

  /// @dev addApprovers(): Allows any of the issuers to add more approvers to the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to add to the list of valid approvers
  function addApprovers(
                        address _sender,
                        uint _jobId,
                        uint _issuerId,
                        address[] memory _approvers)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerId)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      jobs[_jobId].approvers.push(_approvers[i]);
    }

    emit JobApproversUpdated(_jobId, _sender, jobs[_jobId].approvers);
  }

  /// @dev replaceApprovers(): Allows any of the issuers to replace the approvers of the job
  /// @param _sender the sender of the transaction issuing the job (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _jobId the index of the job
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to replace the list of valid approvers
  function replaceApprovers(
                            address _sender,
                            uint _jobId,
                            uint _issuerId,
                            address[] memory _approvers)
    public
    senderIsValid(_sender)
    validateJobArrayIndex(_jobId)
    validateIssuerArrayIndex(_jobId, _issuerId)
    onlyIssuer(_sender, _jobId, _issuerId)
  {
    require(jobs[_jobId].issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck
    jobs[_jobId].approvers = _approvers;

    emit JobApproversUpdated(_jobId, _sender, jobs[_jobId].approvers);
  }

  /// @dev getJob(): Returns the details of the job
  /// @param _jobId the index of the job
  /// @return Returns a tuple for the job
  function getJob(uint _jobId)
    external
    view
    returns (Job memory)
  {
    return jobs[_jobId];
  }


  function transferTokens(uint _jobId, address payable _to, uint _amount)
    internal
  {
    if (jobs[_jobId].tokenVersion == 0){
      require(_amount > 0); // Sending 0 tokens should throw
      require(jobs[_jobId].balance >= _amount);

      jobs[_jobId].balance = jobs[_jobId].balance.sub(_amount);

      _to.transfer(_amount);
    } else if (jobs[_jobId].tokenVersion == 20){
      require(_amount > 0); // Sending 0 tokens should throw
      require(jobs[_jobId].balance >= _amount);

      jobs[_jobId].balance = jobs[_jobId].balance.sub(_amount);

      require(IERC20(jobs[_jobId].token).transfer(_to, _amount));
    } else if (jobs[_jobId].tokenVersion == 721){
      require(tokenBalances[_jobId][_amount]);

      tokenBalances[_jobId][_amount] = false; // Removes the 721 token from the balance of the job

      IERC721(jobs[_jobId].token).transferFrom(address(this),
                                               _to,
                                               _amount);
    } else {
      revert();
    }
  }

  /*
   * Events
   */

  event JobIssued(uint _jobId, address payable _creator, address payable[] _issuers, address[] _approvers, string _ipfsHash, address _token, uint _tokenVersion);
  event ContributionAdded(uint _jobId, uint _contributionId, address payable _contributor, uint _amount);
  event ContributionRefunded(uint _jobId, uint _contributionId);
  event ContributionsRefunded(uint _jobId, address _issuer, uint[] _contributionIds);
  event JobDrained(uint _jobId, address _issuer, uint[] _amounts);
  event JobInvoice(uint _jobId, uint _invoiceId, address payable _invoiceIssuer, string _ipfsHash, address _submitter, uint _amount);
  event InvoiceAccepted(uint _jobId, uint  _invoiceId, address _approver, uint _amount);
  event JobChanged(uint _jobId, address _changer, address payable[] _issuers, address payable[] _approvers, string _ipfsHash);
  event JobIssuersUpdated(uint _jobId, address _changer, address payable[] _issuers);
  event JobApproversUpdated(uint _jobId, address _changer, address[] _approvers);
  event JobDataChanged(uint _jobId, address _changer, string _ipfsHash);

  event CandidateAccepted(uint _jobId, address _candidate);
  event InvoiceCancelled(address _sender, uint _jobId, uint _invoiceId);
}

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./token/IERC20.sol";
import "./token/IERC721.sol";
import "./math/SafeMath.sol";


/// @title StandardBounties
/// @dev A contract for issuing bounties on Ethereum paying in ETH, ERC20, or ERC721 tokens
/// @author Mark Beylin <[email protected]>, Gonçalo Sá <[email protected]>, Kevin Owocki <[email protected]>, Ricardo Guilherme Schmidt (@3esmit), Matt Garnett <[email protected]>, Craig Williams <[email protected]>
contract StandardBounties {

  using SafeMath for uint256;

  /*
   * Structs
   */

  struct Bounty {
    address payable[] issuers; // An array of individuals who have complete control over the bounty, and can edit any of its parameters
    address[] approvers; // An array of individuals who are allowed to accept the fulfillments for a particular bounty
    uint deadline; // The Unix timestamp before which all submissions must be made, and after which refunds may be processed
    address token; // The address of the token associated with the bounty (should be disregarded if the tokenVersion is 0)
    uint tokenVersion; // The version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
    uint balance; // The number of tokens which the bounty is able to pay out or refund
    bool hasPaidOut; // A boolean storing whether or not the bounty has paid out at least once, meaning refunds are no longer allowed
    Fulfillment[] fulfillments; // An array of Fulfillments which store the various submissions which have been made to the bounty
    Contribution[] contributions; // An array of Contributions which store the contributions which have been made to the bounty
  }

  struct Fulfillment {
    address payable[] fulfillers; // An array of addresses who should receive payouts for a given submission
    address submitter; // The address of the individual who submitted the fulfillment, who is able to update the submission as needed
  }

  struct Contribution {
    address payable contributor; // The address of the individual who contributed
    uint amount; // The amount of tokens the user contributed
    bool refunded; // A boolean storing whether or not the contribution has been refunded yet
  }

  /*
   * Storage
   */

  uint public numBounties; // An integer storing the total number of bounties in the contract
  mapping(uint => Bounty) public bounties; // A mapping of bountyIDs to bounties
  mapping (uint => mapping (uint => bool)) public tokenBalances; // A mapping of bountyIds to tokenIds to booleans, storing whether a given bounty has a given ERC721 token in its balance


  address public owner; // The address of the individual who's allowed to set the metaTxRelayer address
  address public metaTxRelayer; // The address of the meta transaction relayer whose _sender is automatically trusted for all contract calls

  bool public callStarted; // Ensures mutex for the entire contract

  /*
   * Modifiers
   */

  modifier callNotStarted(){
    require(!callStarted);
    callStarted = true;
    _;
    callStarted = false;
  }

  modifier validateBountyArrayIndex(
    uint _index)
  {
    require(_index < numBounties);
    _;
  }

  modifier validateContributionArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].contributions.length);
    _;
  }

  modifier validateFulfillmentArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].fulfillments.length);
    _;
  }

  modifier validateIssuerArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].issuers.length);
    _;
  }

  modifier validateApproverArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].approvers.length);
    _;
  }

  modifier onlyIssuer(
  address _sender,
  uint _bountyId,
  uint _issuerId)
  {
  require(_sender == bounties[_bountyId].issuers[_issuerId]);
  _;
  }

  modifier onlySubmitter(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId)
  {
    require(_sender ==
            bounties[_bountyId].fulfillments[_fulfillmentId].submitter);
    _;
  }

  modifier onlyContributor(
  address _sender,
  uint _bountyId,
  uint _contributionId)
  {
    require(_sender ==
            bounties[_bountyId].contributions[_contributionId].contributor);
    _;
  }

  modifier isApprover(
    address _sender,
    uint _bountyId,
    uint _approverId)
  {
    require(_sender == bounties[_bountyId].approvers[_approverId]);
    _;
  }

  modifier hasNotPaid(
    uint _bountyId)
  {
    require(!bounties[_bountyId].hasPaidOut);
    _;
  }

  modifier hasNotRefunded(
    uint _bountyId,
    uint _contributionId)
  {
    require(!bounties[_bountyId].contributions[_contributionId].refunded);
    _;
  }

  modifier senderIsValid(
    address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }

 /*
  * Public functions
  */

  constructor() public {
    // The owner of the contract is automatically designated to be the deployer of the contract
    owner = msg.sender;
  }

  /// @dev setMetaTxRelayer(): Sets the address of the meta transaction relayer
  /// @param _relayer the address of the relayer
  function setMetaTxRelayer(address _relayer)
    external
  {
    require(msg.sender == owner); // Checks that only the owner can call
    require(metaTxRelayer == address(0)); // Ensures the meta tx relayer can only be set once
    metaTxRelayer = _relayer;
  }

  /// @dev issueBounty(): creates a new bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _issuers the array of addresses who will be the issuers of the bounty
  /// @param _approvers the array of addresses who will be the approvers of the bounty
  /// @param _data the IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the timestamp which will become the deadline of the bounty
  /// @param _token the address of the token which will be used for the bounty
  /// @param _tokenVersion the version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
  function issueBounty(
    address payable _sender,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion)
    public
    senderIsValid(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721); // Ensures a bounty can only be issued with a valid token version
    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    uint bountyId = numBounties; // The next bounty's index will always equal the number of existing bounties

    Bounty storage newBounty = bounties[bountyId];
    newBounty.issuers = _issuers;
    newBounty.approvers = _approvers;
    newBounty.deadline = _deadline;
    newBounty.tokenVersion = _tokenVersion;

    if (_tokenVersion != 0){
      newBounty.token = _token;
    }

    numBounties = numBounties.add(1); // Increments the number of bounties, since a new one has just been added

    emit BountyIssued(bountyId,
                      _sender,
                      _issuers,
                      _approvers,
                      _data, // Instead of storing the string on-chain, it is emitted within the event for easy off-chain consumption
                      _deadline,
                      _token,
                      _tokenVersion);

    return (bountyId);
  }

  /// @param _depositAmount the amount of tokens being deposited to the bounty, which will create a new contribution to the bounty


  function issueAndContribute(
    address payable _sender,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount)
    public
    payable
    returns(uint)
  {
    uint bountyId = issueBounty(_sender, _issuers, _approvers, _data, _deadline, _token, _tokenVersion);

    contribute(_sender, bountyId, _depositAmount);

    return (bountyId);
  }


  /// @dev contribute(): Allows users to contribute tokens to a given bounty.
  ///                    Contributing merits no privelages to administer the
  ///                    funds in the bounty or accept submissions. Contributions
  ///                    are refundable but only on the condition that the deadline
  ///                    has elapsed, and the bounty has not yet paid out any funds.
  ///                    All funds deposited in a bounty are at the mercy of a
  ///                    bounty's issuers and approvers, so please be careful!
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _amount the amount of tokens being contributed
  function contribute(
    address payable _sender,
    uint _bountyId,
    uint _amount)
    public
    payable
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    callNotStarted
  {
    require(_amount > 0); // Contributions of 0 tokens or token ID 0 should fail

    bounties[_bountyId].contributions.push(
      Contribution(_sender, _amount, false)); // Adds the contribution to the bounty

    if (bounties[_bountyId].tokenVersion == 0){

      bounties[_bountyId].balance = bounties[_bountyId].balance.add(_amount); // Increments the balance of the bounty

      require(msg.value == _amount);
    } else if (bounties[_bountyId].tokenVersion == 20){

      bounties[_bountyId].balance = bounties[_bountyId].balance.add(_amount); // Increments the balance of the bounty

      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      require(IERC20(bounties[_bountyId].token).transferFrom(_sender,
                                                             address(this),
                                                             _amount));
    } else if (bounties[_bountyId].tokenVersion == 721){
      tokenBalances[_bountyId][_amount] = true; // Adds the 721 token to the balance of the bounty


      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      IERC721(bounties[_bountyId].token).transferFrom(_sender,
                                                               address(this),
                                                               _amount);
    } else {
      revert();
    }

    emit ContributionAdded(_bountyId,
                           bounties[_bountyId].contributions.length - 1, // The new contributionId
                           _sender,
                           _amount);
  }

  /// @dev refundContribution(): Allows users to refund the contributions they've
  ///                            made to a particular bounty, but only if the bounty
  ///                            has not yet paid out, and the deadline has elapsed.
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionId the index of the contribution being refunded
  function refundContribution(
    address _sender,
    uint _bountyId,
    uint _contributionId)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateContributionArrayIndex(_bountyId, _contributionId)
    onlyContributor(_sender, _bountyId, _contributionId)
    hasNotPaid(_bountyId)
    hasNotRefunded(_bountyId, _contributionId)
    callNotStarted
  {
    require(now > bounties[_bountyId].deadline); // Refunds may only be processed after the deadline has elapsed

    Contribution storage contribution = bounties[_bountyId].contributions[_contributionId];

    contribution.refunded = true;

    transferTokens(_bountyId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor

    emit ContributionRefunded(_bountyId, _contributionId);
  }

  /// @dev refundMyContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundMyContributions(
    address _sender,
    uint _bountyId,
    uint[] memory _contributionIds)
    public
    senderIsValid(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
        refundContribution(_sender, _bountyId, _contributionIds[i]);
    }
  }

  /// @dev refundContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundContributions(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _contributionIds)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    callNotStarted
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      require(_contributionIds[i] < bounties[_bountyId].contributions.length);

      Contribution storage contribution = bounties[_bountyId].contributions[_contributionIds[i]];

      require(!contribution.refunded);

      contribution.refunded = true;

      transferTokens(_bountyId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor
    }

    emit ContributionsRefunded(_bountyId, _sender, _contributionIds);
  }

  /// @dev drainBounty(): Allows an issuer to drain the funds from the bounty
  /// @notice when using this function, if an issuer doesn't drain the entire balance, some users may be able to refund their contributions, while others may not (which is unfair to them). Please use it wisely, only when necessary
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _amounts an array of amounts of tokens to be sent. The length of the array should be 1 if the bounty is in ETH or ERC20 tokens. If it's an ERC721 bounty, the array should be the list of tokenIDs.
  function drainBounty(
    address payable _sender,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _amounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    callNotStarted
  {
    if (bounties[_bountyId].tokenVersion == 0 || bounties[_bountyId].tokenVersion == 20){
      require(_amounts.length == 1); // ensures there's only 1 amount of tokens to be returned
      require(_amounts[0] <= bounties[_bountyId].balance); // ensures an issuer doesn't try to drain the bounty of more tokens than their balance permits
      transferTokens(_bountyId, _sender, _amounts[0]); // Performs the draining of tokens to the issuer
    } else {
      for (uint i = 0; i < _amounts.length; i++){
        require(tokenBalances[_bountyId][_amounts[i]]);// ensures an issuer doesn't try to drain the bounty of a token it doesn't have in its balance
        transferTokens(_bountyId, _sender, _amounts[i]);
      }
    }

    emit BountyDrained(_bountyId, _sender, _amounts);
  }

  /// @dev performAction(): Allows users to perform any generalized action
  ///                       associated with a particular bounty, such as applying for it
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the action being performed (see docs for schema details)
  function performAction(
    address _sender,
    uint _bountyId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    emit ActionPerformed(_bountyId, _sender, _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev fulfillBounty(): Allows users to fulfill the bounty to get paid out
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function fulfillBounty(
    address _sender,
    uint _bountyId,
    address payable[] memory  _fulfillers,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    require(now < bounties[_bountyId].deadline); // Submissions are only allowed to be made before the deadline
    require(_fulfillers.length > 0); // Submissions with no fulfillers would mean no one gets paid out

    bounties[_bountyId].fulfillments.push(Fulfillment(_fulfillers, _sender));

    emit BountyFulfilled(_bountyId,
                         (bounties[_bountyId].fulfillments.length - 1),
                         _fulfillers,
                         _data, // The _data string is emitted in an event for easy off-chain consumption
                         _sender);
  }

  /// @dev updateFulfillment(): Allows the submitter of a fulfillment to update their submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment
  /// @param _fulfillers the new array of addresses which will receive payouts for the submission
  /// @param _data the new IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function updateFulfillment(
  address _sender,
  uint _bountyId,
  uint _fulfillmentId,
  address payable[] memory _fulfillers,
  string memory _data)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
  onlySubmitter(_sender, _bountyId, _fulfillmentId) // Only the original submitter of a fulfillment may update their submission
  {
    bounties[_bountyId].fulfillments[_fulfillmentId].fulfillers = _fulfillers;
    emit FulfillmentUpdated(_bountyId,
                            _fulfillmentId,
                            _fulfillers,
                            _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev acceptFulfillment(): Allows any of the approvers to accept a given submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment to be accepted
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function acceptFulfillment(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
    isApprover(_sender, _bountyId, _approverId)
    callNotStarted
  {
    // now that the bounty has paid out at least once, refunds are no longer possible
    bounties[_bountyId].hasPaidOut = true;

    Fulfillment storage fulfillment = bounties[_bountyId].fulfillments[_fulfillmentId];

    require(_tokenAmounts.length == fulfillment.fulfillers.length); // Each fulfiller should get paid some amount of tokens (this can be 0)

    for (uint256 i = 0; i < fulfillment.fulfillers.length; i++){
        if (_tokenAmounts[i] > 0){
          // for each fulfiller associated with the submission
          transferTokens(_bountyId, fulfillment.fulfillers[i], _tokenAmounts[i]);
        }
    }
    emit FulfillmentAccepted(_bountyId,
                             _fulfillmentId,
                             _sender,
                             _tokenAmounts);
  }

  /// @dev fulfillAndAccept(): Allows any of the approvers to fulfill and accept a submission simultaneously
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function fulfillAndAccept(
    address _sender,
    uint _bountyId,
    address payable[] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
  {
    // first fulfills the bounty on behalf of the fulfillers
    fulfillBounty(_sender, _bountyId, _fulfillers, _data);

    // then accepts the fulfillment
    acceptFulfillment(_sender,
                      _bountyId,
                      bounties[_bountyId].fulfillments.length - 1,
                      _approverId,
                      _tokenAmounts);
  }



  /// @dev changeBounty(): Allows any of the issuers to change the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the new array of addresses who will be the issuers of the bounty
  /// @param _approvers the new array of addresses who will be the approvers of the bounty
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeBounty(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers,
    address payable[] memory _approvers,
    string memory _data,
    uint _deadline)
    public
    senderIsValid(_sender)
  {
    require(_bountyId < numBounties); // makes the validateBountyArrayIndex modifier in-line to avoid stack too deep errors
    require(_issuerId < bounties[_bountyId].issuers.length); // makes the validateIssuerArrayIndex modifier in-line to avoid stack too deep errors
    require(_sender == bounties[_bountyId].issuers[_issuerId]); // makes the onlyIssuer modifier in-line to avoid stack too deep errors

    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    bounties[_bountyId].issuers = _issuers;
    bounties[_bountyId].approvers = _approvers;
    bounties[_bountyId].deadline = _deadline;
    emit BountyChanged(_bountyId,
                       _sender,
                       _issuers,
                       _approvers,
                       _data,
                       _deadline);
  }

  /// @dev changeIssuer(): Allows any of the issuers to change a particular issuer of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuerIdToChange the index of the issuer who is being changed
  /// @param _newIssuer the address of the new issuer
  function changeIssuer(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerIdToChange)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(_issuerId < bounties[_bountyId].issuers.length || _issuerId == 0);

    bounties[_bountyId].issuers[_issuerIdToChange] = _newIssuer;

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev changeApprover(): Allows any of the issuers to change a particular approver of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approverId the index of the approver who is being changed
  /// @param _approver the address of the new approver
  function changeApprover(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver)
    external
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    validateApproverArrayIndex(_bountyId, _approverId)
  {
    bounties[_bountyId].approvers[_approverId] = _approver;

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev changeData(): Allows any of the issuers to change the data the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  function changeData(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    emit BountyDataChanged(_bountyId, _sender, _data); // The new _data is emitted within an event rather than being stored on-chain for minimized gas costs
  }

  /// @dev changeDeadline(): Allows any of the issuers to change the deadline the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeDeadline(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _deadline)
    external
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].deadline = _deadline;

    emit BountyDeadlineChanged(_bountyId, _sender, _deadline);
  }

  /// @dev addIssuers(): Allows any of the issuers to add more issuers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to add to the list of valid issuers
  function addIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      bounties[_bountyId].issuers.push(_issuers[i]);
    }

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev replaceIssuers(): Allows any of the issuers to replace the issuers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to replace the list of valid issuers
  function replaceIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(_issuers.length > 0 || bounties[_bountyId].approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    bounties[_bountyId].issuers = _issuers;

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev addApprovers(): Allows any of the issuers to add more approvers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to add to the list of valid approvers
  function addApprovers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address[] memory _approvers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      bounties[_bountyId].approvers.push(_approvers[i]);
    }

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev replaceApprovers(): Allows any of the issuers to replace the approvers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to replace the list of valid approvers
  function replaceApprovers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address[] memory _approvers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(bounties[_bountyId].issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck
    bounties[_bountyId].approvers = _approvers;

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev getBounty(): Returns the details of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns a tuple for the bounty
  function getBounty(uint _bountyId)
    external
    view
    returns (Bounty memory)
  {
    return bounties[_bountyId];
  }


  function transferTokens(uint _bountyId, address payable _to, uint _amount)
    internal
  {
    if (bounties[_bountyId].tokenVersion == 0){
      require(_amount > 0); // Sending 0 tokens should throw
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.sub(_amount);

      _to.transfer(_amount);
    } else if (bounties[_bountyId].tokenVersion == 20){
      require(_amount > 0); // Sending 0 tokens should throw
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.sub(_amount);

      require(IERC20(bounties[_bountyId].token).transfer(_to, _amount));
    } else if (bounties[_bountyId].tokenVersion == 721){
      require(tokenBalances[_bountyId][_amount]);

      tokenBalances[_bountyId][_amount] = false; // Removes the 721 token from the balance of the bounty

      IERC721(bounties[_bountyId].token).transferFrom(address(this),
                                                               _to,
                                                               _amount);
    } else {
      revert();
    }
  }

  /*
   * Events
   */

  event BountyIssued(uint _bountyId, address payable _creator, address payable[] _issuers, address[] _approvers, string _data, uint _deadline, address _token, uint _tokenVersion);
  event ContributionAdded(uint _bountyId, uint _contributionId, address payable _contributor, uint _amount);
  event ContributionRefunded(uint _bountyId, uint _contributionId);
  event ContributionsRefunded(uint _bountyId, address _issuer, uint[] _contributionIds);
  event BountyDrained(uint _bountyId, address _issuer, uint[] _amounts);
  event ActionPerformed(uint _bountyId, address _fulfiller, string _data);
  event BountyFulfilled(uint _bountyId, uint _fulfillmentId, address payable[] _fulfillers, string _data, address _submitter);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId, address payable[] _fulfillers, string _data);
  event FulfillmentAccepted(uint _bountyId, uint  _fulfillmentId, address _approver, uint[] _tokenAmounts);
  event BountyChanged(uint _bountyId, address _changer, address payable[] _issuers, address payable[] _approvers, string _data, uint _deadline);
  event BountyIssuersUpdated(uint _bountyId, address _changer, address payable[] _issuers);
  event BountyApproversUpdated(uint _bountyId, address _changer, address[] _approvers);
  event BountyDataChanged(uint _bountyId, address _changer, string _data);
  event BountyDeadlineChanged(uint _bountyId, address _changer, uint _deadline);
}

pragma solidity ^0.5.0;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from,
                 address indexed to,
                 uint256 value);

  event Approval(address indexed owner,
                 address indexed spender,
                 uint256 value);
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */

interface IERC721 {

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId) external view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from,address _to,uint256 _tokenId, bytes calldata _data) external;

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _timestamp);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}

