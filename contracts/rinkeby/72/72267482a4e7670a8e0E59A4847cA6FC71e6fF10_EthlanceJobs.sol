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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "petersburg",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}