pragma solidity ^0.4.11;

/*******************************************************************************
 * ERC Token Standard #20 Interface
 * https://github.com/ethereum/EIPs/issues/20
 *******************************************************************************/
contract ERC20Interface {
  // Get the total token supply
  function totalSupply() constant returns (uint256 totalSupply);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance);

  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success);

  // Send _value amount of tokens from address _from to address _to
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  // this function is required for some DEX functionality.
  function approve(address _spender, uint256 _value) returns (bool success);

  // Returns the amount which _spender is still allowed to withdraw from _owner
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*******************************************************************************
 * AICoin - Smart Contract with token and ballot handling
 *******************************************************************************/
contract AICoin is ERC20Interface {

  /* ******************************
   * COIN data / functions
   * ******************************/

  /* Token constants */
  string public constant name = &#39;AICoin&#39;;
  string public constant symbol = &#39;XAI&#39;;
  uint8 public constant decimals = 8;
  string public constant smallestUnit = &#39;Hofstadter&#39;;

  /* Token internal data */
  address m_administrator;
  uint256 m_totalSupply;

  /* Current balances for each account */
  mapping(address => uint256) balances;

  /* Account holder approves the transfer of an amount to another account */
  mapping(address => mapping (address => uint256)) allowed;

  /* One-time create function: initialize the supply and set the admin address */
  function AICoin (uint256 _initialSupply) {
    m_administrator = msg.sender;
    m_totalSupply = _initialSupply;
    balances[msg.sender] = _initialSupply;
  }

  /* Get the admin address */
  function administrator() constant returns (address adminAddress) {
    return m_administrator;
  }

  /* Get the total coin supply */
  function totalSupply() constant returns (uint256 totalSupply) {
    return m_totalSupply;
  }

  /* Get the balance of a specific account by its address */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfer an amount from the owner&#39;s account to an indicated account */
  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]
        && (! accountHasCurrentVote(msg.sender))) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  /* Send _value amount of tokens from address _from to address _to
   * The transferFrom method is used for a withdraw workflow, allowing contracts to send
   * tokens on your behalf, for example to "deposit" to a contract address and/or to charge
   * fees in sub-currencies; the command should fail unless the _from account has
   * deliberately authorized the sender of the message via some mechanism; we propose
   * these standardized APIs for approval:
   */
  function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]
        && (! accountHasCurrentVote(_from))) {
      balances[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  /* Pre-authorize an address to withdraw from your account, up to the _value amount.
   * Doing so (using transferFrom) reduces the remaining authorized amount,
   * as well as the actual account balance)
   * Subsequent calls to this function overwrite any existing authorized amount.
   * Therefore, to cancel an authorization, simply write a zero amount.
   */
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Get the currently authorized that can be withdrawn by account _spender from account _owner */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /* ******************************
   * BALLOT data / functions
   * ******************************/

  /* Dev Note: creating a struct that contained a string, uint values and
   * an array of option structs, etc, would consistently fail.
   * So the ballot details are held in separate mappings with a common integer
   * key for each ballot. The IDs are 1-indexed, sequential and contiguous.
   */

  /* Basic ballot details: time frame and number of options */
  struct BallotDetails {
    uint256 start;
    uint256 end;
    uint32 numOptions; // 1-indexed for readability
    bool sealed;
  }

  uint32 public numBallots = 0; // 1-indexed for readability
  mapping (uint32 => string) public ballotNames;
  mapping (uint32 => BallotDetails) public ballotDetails;
  mapping (uint32 => mapping (uint32 => string) ) public ballotOptions;

  /* Create a new ballot and set the basic details (proposal description, dates)
   * The ballot still need to have options added and then to be sealed
   */
  function adminAddBallot(string _proposal, uint256 _start, uint256 _end) {

    /* Admin functions must be called by the contract creator. */
    require(msg.sender == m_administrator);

    /* Create and store the new ballot objects */
    numBallots++;
    uint32 ballotId = numBallots;
    ballotNames[ballotId] = _proposal;
    ballotDetails[ballotId] = BallotDetails(_start, _end, 0, false);
  }

  /* Create a new ballot and set the basic details (proposal description, dates)
   * The ballot still need to have options added and then to be sealed
   */
  function adminAmendBallot(uint32 _ballotId, string _proposal, uint256 _start, uint256 _end) {

    /* Admin functions must be called by the contract creator. */
    require(msg.sender == m_administrator);

    /* verify that the ballot exists */
    require(_ballotId > 0 && _ballotId <= numBallots);

    /* update the ballot object */
    ballotNames[_ballotId] = _proposal;
    ballotDetails[_ballotId].start = _start;
    ballotDetails[_ballotId].end = _end;
  }

  /* Add an option to an existing Ballot
   */
  function adminAddBallotOption(uint32 _ballotId, string _option) {

    /* Admin functions must be called by the contract creator. */
    require(msg.sender == m_administrator);

    /* verify that the ballot exists */
    require(_ballotId > 0 && _ballotId <= numBallots);

    /* cannot change a ballot once it is sealed */
    if(isBallotSealed(_ballotId)) {
      revert();
    }

    /* store the new ballot option */
    ballotDetails[_ballotId].numOptions += 1;
    uint32 optionId = ballotDetails[_ballotId].numOptions;
    ballotOptions[_ballotId][optionId] = _option;
  }

  /* Amend and option in an existing Ballot
   */
  function adminEditBallotOption(uint32 _ballotId, uint32 _optionId, string _option) {

    /* Admin functions must be called by the contract creator. */
    require(msg.sender == m_administrator);

    /* verify that the ballot exists */
    require(_ballotId > 0 && _ballotId <= numBallots);

    /* cannot change a ballot once it is sealed */
    if(isBallotSealed(_ballotId)) {
      revert();
    }

    /* validate the ballot option */
    require(_optionId > 0 && _optionId <= ballotDetails[_ballotId].numOptions);

    /* update the ballot option */
    ballotOptions[_ballotId][_optionId] = _option;
  }

  /* Seal a ballot - after this the ballot is official and no changes can be made.
   */
  function adminSealBallot(uint32 _ballotId) {

    /* Admin functions must be called by the contract creator. */
    require(msg.sender == m_administrator);

    /* verify that the ballot exists */
    require(_ballotId > 0 && _ballotId <= numBallots);

    /* cannot change a ballot once it is sealed */
    if(isBallotSealed(_ballotId)) {
      revert();
    }

    /* set the ballot seal flag */
    ballotDetails[_ballotId].sealed = true;
  }

  /* Function to determine if a ballot is currently in progress, based on its
   * start and end dates, and that it has been sealed.
   */
  function isBallotInProgress(uint32 _ballotId) private constant returns (bool) {
    return (isBallotSealed(_ballotId)
            && ballotDetails[_ballotId].start <= now
            && ballotDetails[_ballotId].end >= now);
  }

  /* Function to determine if a ballot has ended, based on its end date */
  function hasBallotEnded(uint32 _ballotId) private constant returns (bool) {
    return (ballotDetails[_ballotId].end < now);
  }

  /* Function to determine if a ballot has been sealed, which means it has been
   * authorized by the administrator and can no longer be changed.
   */
  function isBallotSealed(uint32 _ballotId) private returns (bool) {
    return ballotDetails[_ballotId].sealed;
  }

  /* ******************************
   * VOTING data / functions
   * ******************************/

  mapping (uint32 => mapping (address => uint256) ) public ballotVoters;
  mapping (uint32 => mapping (uint32 => uint256) ) public ballotVoteCount;

  /* function to allow a coin holder add to the vote count of an option in an
   * active ballot. The votes added equals the balance of the account. Once this is called successfully
   * the coins cannot be transferred out of the account until the end of the ballot.
   *
   * NB: The timing of the start and end of the voting period is determined by
   * the timestamp of the block in which the transaction is included. As given by
   * the current Ethereum standard this is *NOT* guaranteed to be accurate to any
   * given external time source. Therefore, votes should be placed well in advance
   * of the UTC end time of the Ballot.
   */
  function vote(uint32 _ballotId, uint32 _selectedOptionId) {

    /* verify that the ballot exists */
    require(_ballotId > 0 && _ballotId <= numBallots);

    /* Ballot must be in progress in order to vote */
    require(isBallotInProgress(_ballotId));

    /* Calculate the balance which which the coin holder has not yet voted, which is the difference between
     * the current balance for the senders address and the amount they already voted in this ballot.
     * If the difference is zero, this attempt to vote will fail.
     */
    uint256 votableBalance = balanceOf(msg.sender) - ballotVoters[_ballotId][msg.sender];
    require(votableBalance > 0);

    /* validate the ballot option */
    require(_selectedOptionId > 0 && _selectedOptionId <= ballotDetails[_ballotId].numOptions);

    /* update the vote count and record the voter */
    ballotVoteCount[_ballotId][_selectedOptionId] += votableBalance;
    ballotVoters[_ballotId][msg.sender] += votableBalance;
  }

  /* function to determine if an address has already voted in a given ballot */
  function hasAddressVotedInBallot(uint32 _ballotId, address _voter) constant returns (bool hasVoted) {
    return ballotVoters[_ballotId][_voter] > 0;
  }

  /* function to determine if an account has voted in any current ballot */
  function accountHasCurrentVote(address _voter) constant returns (bool) {
    for(uint32 id = 1; id <= numBallots; id++) {
      if (isBallotInProgress(id) && hasAddressVotedInBallot(id, _voter)) {
        return true;
      }
    }
    return false;
  }
}