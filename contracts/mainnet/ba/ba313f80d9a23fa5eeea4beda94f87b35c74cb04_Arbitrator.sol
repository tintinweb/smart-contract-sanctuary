pragma solidity ^0.4.18;


contract Owned {
    address public owner;

    function Owned() 
    public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) 
        onlyOwner 
    public {
        owner = newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BalanceHolder {

    mapping(address => uint256) public balanceOf;

    event LogWithdraw(
        address indexed user,
        uint256 amount
    );

    function withdraw() 
    public {
        uint256 bal = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(bal);
        LogWithdraw(msg.sender, bal);
    }

}


contract RealityCheck is BalanceHolder {

    using SafeMath for uint256;
    using SafeMath32 for uint32;

    address constant NULL_ADDRESS = address(0);

    // History hash when no history is created, or history has been cleared
    bytes32 constant NULL_HASH = bytes32(0);

    // An unitinalized finalize_ts for a question will indicate an unanswered question.
    uint32 constant UNANSWERED = 0;

    // An unanswered reveal_ts for a commitment will indicate that it does not exist.
    uint256 constant COMMITMENT_NON_EXISTENT = 0;

    // Commit->reveal timeout is 1/8 of the question timeout (rounded down).
    uint32 constant COMMITMENT_TIMEOUT_RATIO = 8;

    event LogSetQuestionFee(
        address arbitrator,
        uint256 amount
    );

    event LogNewTemplate(
        uint256 indexed template_id,
        address indexed user, 
        string question_text
    );

    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user, 
        uint256 template_id,
        string question,
        bytes32 indexed content_hash,
        address arbitrator, 
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce,
        uint256 created
    );

    event LogFundAnswerBounty(
        bytes32 indexed question_id,
        uint256 bounty_added,
        uint256 bounty,
        address indexed user 
    );

    event LogNewAnswer(
        bytes32 answer,
        bytes32 indexed question_id,
        bytes32 history_hash,
        address indexed user,
        uint256 bond,
        uint256 ts,
        bool is_commitment
    );

    event LogAnswerReveal(
        bytes32 indexed question_id, 
        address indexed user, 
        bytes32 indexed answer_hash, 
        bytes32 answer, 
        uint256 nonce, 
        uint256 bond
    );

    event LogNotifyOfArbitrationRequest(
        bytes32 indexed question_id,
        address indexed user 
    );

    event LogFinalize(
        bytes32 indexed question_id,
        bytes32 indexed answer
    );

    event LogClaim(
        bytes32 indexed question_id,
        address indexed user,
        uint256 amount
    );

    struct Question {
        bytes32 content_hash;
        address arbitrator;
        uint32 opening_ts;
        uint32 timeout;
        uint32 finalize_ts;
        bool is_pending_arbitration;
        uint256 bounty;
        bytes32 best_answer;
        bytes32 history_hash;
        uint256 bond;
    }

    // Stored in a mapping indexed by commitment_id, a hash of commitment hash, question, bond. 
    struct Commitment {
        uint32 reveal_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }

    // Only used when claiming more bonds than fits into a transaction
    // Stored in a mapping indexed by question_id.
    struct Claim {
        address payee;
        uint256 last_bond;
        uint256 queued_funds;
    }

    uint256 nextTemplateID = 0;
    mapping(uint256 => uint256) public templates;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees; 

    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator);
        _;
    }

    modifier stateAny() {
        _;
    }

    modifier stateNotCreated(bytes32 question_id) {
        require(questions[question_id].timeout == 0);
        _;
    }

    modifier stateOpen(bytes32 question_id) {
        require(questions[question_id].timeout > 0); // Check existence
        require(!questions[question_id].is_pending_arbitration);
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now));
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now)); 
        _;
    }

    modifier statePendingArbitration(bytes32 question_id) {
        require(questions[question_id].is_pending_arbitration);
        _;
    }

    modifier stateFinalized(bytes32 question_id) {
        require(isFinalized(question_id));
        _;
    }

    modifier bondMustBeZero() {
        require(msg.value == 0);
        _;
    }

    modifier bondMustDouble(bytes32 question_id) {
        require(msg.value > 0); 
        require(msg.value >= (questions[question_id].bond.mul(2)));
        _;
    }

    modifier previousBondMustNotBeatMaxPrevious(bytes32 question_id, uint256 max_previous) {
        if (max_previous > 0) {
            require(questions[question_id].bond <= max_previous);
        }
        _;
    }

    /// @notice Constructor, sets up some initial templates
    /// @dev Creates some generalized templates for different question types used in the DApp.
    function RealityCheck() 
    public {
        createTemplate(&#39;{"title": "%s", "type": "bool", "category": "%s"}&#39;);
        createTemplate(&#39;{"title": "%s", "type": "uint", "decimals": 18, "category": "%s"}&#39;);
        createTemplate(&#39;{"title": "%s", "type": "int", "decimals": 18, "category": "%s"}&#39;);
        createTemplate(&#39;{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s"}&#39;);
        createTemplate(&#39;{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s"}&#39;);
        createTemplate(&#39;{"title": "%s", "type": "datetime", "category": "%s"}&#39;);
    }

    /// @notice Function for arbitrator to set an optional per-question fee. 
    /// @dev The per-question fee, charged when a question is asked, is intended as an anti-spam measure.
    /// @param fee The fee to be charged by the arbitrator when a question is asked
    function setQuestionFee(uint256 fee) 
        stateAny() 
    external {
        arbitrator_question_fees[msg.sender] = fee;
        LogSetQuestionFee(msg.sender, fee);
    }

    /// @notice Create a reusable template, which should be a JSON document.
    /// Placeholders should use gettext() syntax, eg %s.
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplate(string content) 
        stateAny()
    public returns (uint256) {
        uint256 id = nextTemplateID;
        templates[id] = block.number;
        LogNewTemplate(id, msg.sender, content);
        nextTemplateID = id.add(1);
        return id;
    }

    /// @notice Create a new reusable template and use it to ask a question
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplateAndAskQuestion(
        string content, 
        string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce 
    ) 
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {
        uint256 template_id = createTemplate(content);
        return askQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }

    /// @notice Ask a new question and return the ID
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created question, created deterministically.
    function askQuestion(uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) 
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {

        require(templates[template_id] > 0); // Template must exist

        bytes32 content_hash = keccak256(template_id, opening_ts, question);
        bytes32 question_id = keccak256(content_hash, arbitrator, timeout, msg.sender, nonce);

        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts);
        LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, now);

        return question_id;
    }

    function _askQuestion(bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 timeout, uint32 opening_ts) 
        stateNotCreated(question_id)
    internal {

        // A timeout of 0 makes no sense, and we will use this to check existence
        require(timeout > 0); 
        require(timeout < 365 days); 
        require(arbitrator != NULL_ADDRESS);

        uint256 bounty = msg.value;

        // The arbitrator can set a fee for asking a question. 
        // This is intended as an anti-spam defence.
        // The fee is waived if the arbitrator is asking the question.
        // This allows them to set an impossibly high fee and make users proxy the question through them.
        // This would allow more sophisticated pricing, question whitelisting etc.
        if (msg.sender != arbitrator) {
            uint256 question_fee = arbitrator_question_fees[arbitrator];
            require(bounty >= question_fee); 
            bounty = bounty.sub(question_fee);
            balanceOf[arbitrator] = balanceOf[arbitrator].add(question_fee);
        }

        questions[question_id].content_hash = content_hash;
        questions[question_id].arbitrator = arbitrator;
        questions[question_id].opening_ts = opening_ts;
        questions[question_id].timeout = timeout;
        questions[question_id].bounty = bounty;

    }

    /// @notice Add funds to the bounty for a question
    /// @dev Add bounty funds after the initial question creation. Can be done any time until the question is finalized.
    /// @param question_id The ID of the question you wish to fund
    function fundAnswerBounty(bytes32 question_id) 
        stateOpen(question_id)
    external payable {
        questions[question_id].bounty = questions[question_id].bounty.add(msg.value);
        LogFundAnswerBounty(question_id, msg.value, questions[question_id].bounty, msg.sender);
    }

    /// @notice Submit an answer for a question.
    /// @dev Adds the answer to the history and updates the current "best" answer.
    /// May be subject to front-running attacks; Substitute submitAnswerCommitment()->submitAnswerReveal() to prevent them.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function submitAnswer(bytes32 question_id, bytes32 answer, uint256 max_previous) 
        stateOpen(question_id)
        bondMustDouble(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {
        _addAnswerToHistory(question_id, answer, msg.sender, msg.value, false);
        _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
    }

    /// @notice Submit the hash of an answer, laying your claim to that answer if you reveal it in a subsequent transaction.
    /// @dev Creates a hash, commitment_id, uniquely identifying this answer, to this question, with this bond.
    /// The commitment_id is stored in the answer history where the answer would normally go.
    /// Does not update the current best answer - this is left to the later submitAnswerReveal() transaction.
    /// @param question_id The ID of the question
    /// @param answer_hash The hash of your answer, plus a nonce that you will later reveal
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    /// @param _answerer If specified, the address to be given as the question answerer. Defaults to the sender.
    /// @dev Specifying the answerer is useful if you want to delegate the commit-and-reveal to a third-party.
    function submitAnswerCommitment(bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer) 
        stateOpen(question_id)
        bondMustDouble(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {

        bytes32 commitment_id = keccak256(question_id, answer_hash, msg.value);
        address answerer = (_answerer == NULL_ADDRESS) ? msg.sender : _answerer;

        require(commitments[commitment_id].reveal_ts == COMMITMENT_NON_EXISTENT);

        uint32 commitment_timeout = questions[question_id].timeout / COMMITMENT_TIMEOUT_RATIO;
        commitments[commitment_id].reveal_ts = uint32(now).add(commitment_timeout);

        _addAnswerToHistory(question_id, commitment_id, answerer, msg.value, true);

    }

    /// @notice Submit the answer whose hash you sent in a previous submitAnswerCommitment() transaction
    /// @dev Checks the parameters supplied recreate an existing commitment, and stores the revealed answer
    /// Updates the current answer unless someone has since supplied a new answer with a higher bond
    /// msg.sender is intentionally not restricted to the user who originally sent the commitment; 
    /// For example, the user may want to provide the answer+nonce to a third-party service and let them send the tx
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded as bytes32
    /// @param nonce The nonce that, combined with the answer, recreates the answer_hash you gave in submitAnswerCommitment()
    /// @param bond The bond that you paid in your submitAnswerCommitment() transaction
    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) 
        stateOpen(question_id)
    external {

        bytes32 answer_hash = keccak256(answer, nonce);
        bytes32 commitment_id = keccak256(question_id, answer_hash, bond);

        require(!commitments[commitment_id].is_revealed);
        require(commitments[commitment_id].reveal_ts > uint32(now)); // Reveal deadline must not have passed

        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;

        if (bond == questions[question_id].bond) {
            _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
        }

        LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);

    }

    function _addAnswerToHistory(bytes32 question_id, bytes32 answer_or_commitment_id, address answerer, uint256 bond, bool is_commitment) 
    internal 
    {
        bytes32 new_history_hash = keccak256(questions[question_id].history_hash, answer_or_commitment_id, bond, answerer, is_commitment);

        questions[question_id].bond = bond;
        questions[question_id].history_hash = new_history_hash;

        LogNewAnswer(answer_or_commitment_id, question_id, new_history_hash, answerer, bond, now, is_commitment);
    }

    function _updateCurrentAnswer(bytes32 question_id, bytes32 answer, uint32 timeout_secs)
    internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(now).add(timeout_secs);
    }

    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they&#39;ve been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    function notifyOfArbitrationRequest(bytes32 question_id, address requester) 
        onlyArbitrator(question_id)
        stateOpen(question_id)
    external {
        questions[question_id].is_pending_arbitration = true;
        LogNotifyOfArbitrationRequest(question_id, requester);
    }

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn&#39;t require (or allow) a bond.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param answerer The account credited with this answer for the purpose of bond claims
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) 
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
        bondMustBeZero
    external {

        require(answerer != NULL_ADDRESS);
        LogFinalize(question_id, answer);

        questions[question_id].is_pending_arbitration = false;
        _addAnswerToHistory(question_id, answer, answerer, 0, false);
        _updateCurrentAnswer(question_id, answer, 0);

    }

    /// @notice Report whether the answer to the specified question is finalized
    /// @param question_id The ID of the question
    /// @return Return true if finalized
    function isFinalized(bytes32 question_id) 
    constant public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return ( !questions[question_id].is_pending_arbitration && (finalize_ts > UNANSWERED) && (finalize_ts <= uint32(now)) );
    }

    /// @notice Return the final answer to the specified question, or revert if there isn&#39;t one
    /// @param question_id The ID of the question
    /// @return The answer formatted as a bytes32
    function getFinalAnswer(bytes32 question_id) 
        stateFinalized(question_id)
    external constant returns (bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Return the final answer to the specified question, provided it matches the specified criteria.
    /// @dev Reverts if the question is not finalized, or if it does not match the specified criteria.
    /// @param question_id The ID of the question
    /// @param content_hash The hash of the question content (template ID + opening time + question parameter string)
    /// @param arbitrator The arbitrator chosen for the question (regardless of whether they are asked to arbitrate)
    /// @param min_timeout The timeout set in the initial question settings must be this high or higher
    /// @param min_bond The bond sent with the final answer must be this high or higher
    /// @return The answer formatted as a bytes32
    function getFinalAnswerIfMatches(
        bytes32 question_id, 
        bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond
    ) 
        stateFinalized(question_id)
    external constant returns (bytes32) {
        require(content_hash == questions[question_id].content_hash);
        require(arbitrator == questions[question_id].arbitrator);
        require(min_timeout <= questions[question_id].timeout);
        require(min_bond <= questions[question_id].bond);
        return questions[question_id].best_answer;
    }

    /// @notice Assigns the winnings (bounty and bonds) to everyone who gave the accepted answer
    /// Caller must provide the answer history, in reverse order
    /// @dev Works up the chain and assign bonds to the person who gave the right answer
    /// If someone gave the winning answer earlier, they must get paid from the higher bond
    /// That means we can&#39;t pay out the bond added at n until we have looked at n-1
    /// The first answer is authenticated by checking against the stored history_hash.
    /// One of the inputs to history_hash is the history_hash before it, so we use that to authenticate the next entry, etc
    /// Once we get to a null hash we&#39;ll know we&#39;re done and there are no more answers.
    /// Usually you would call the whole thing in a single transaction, but if not then the data is persisted to pick up later.
    /// @param question_id The ID of the question
    /// @param history_hashes Second-last-to-first, the hash of each history entry. (Final one should be empty).
    /// @param addrs Last-to-first, the address of each answerer or commitment sender
    /// @param bonds Last-to-first, the bond supplied with each answer or commitment
    /// @param answers Last-to-first, each answer supplied, or commitment ID if the answer was supplied with commit->reveal
    function claimWinnings(
        bytes32 question_id, 
        bytes32[] history_hashes, address[] addrs, uint256[] bonds, bytes32[] answers
    ) 
        stateFinalized(question_id)
    public {

        require(history_hashes.length > 0);

        // These are only set if we split our claim over multiple transactions.
        address payee = question_claims[question_id].payee; 
        uint256 last_bond = question_claims[question_id].last_bond; 
        uint256 queued_funds = question_claims[question_id].queued_funds; 

        // Starts as the hash of the final answer submitted. It&#39;ll be cleared when we&#39;re done.
        // If we&#39;re splitting the claim over multiple transactions, it&#39;ll be the hash where we left off last time
        bytes32 last_history_hash = questions[question_id].history_hash;

        bytes32 best_answer = questions[question_id].best_answer;

        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {
        
            // Check input against the history hash, and see which of 2 possible values of is_commitment fits.
            bool is_commitment = _verifyHistoryInputOrRevert(last_history_hash, history_hashes[i], answers[i], bonds[i], addrs[i]);
            
            queued_funds = queued_funds.add(last_bond); 
            (queued_funds, payee) = _processHistoryItem(
                question_id, best_answer, queued_funds, payee, 
                addrs[i], bonds[i], answers[i], is_commitment);
 
            // Line the bond up for next time, when it will be added to somebody&#39;s queued_funds
            last_bond = bonds[i];
            last_history_hash = history_hashes[i];

        }
 
        if (last_history_hash != NULL_HASH) {
            // We haven&#39;t yet got to the null hash (1st answer), ie the caller didn&#39;t supply the full answer chain.
            // Persist the details so we can pick up later where we left off later.

            // If we know who to pay we can go ahead and pay them out, only keeping back last_bond
            // (We always know who to pay unless all we saw were unrevealed commits)
            if (payee != NULL_ADDRESS) {
                _payPayee(question_id, payee, queued_funds);
                queued_funds = 0;
            }

            question_claims[question_id].payee = payee;
            question_claims[question_id].last_bond = last_bond;
            question_claims[question_id].queued_funds = queued_funds;
        } else {
            // There is nothing left below us so the payee can keep what remains
            _payPayee(question_id, payee, queued_funds.add(last_bond));
            delete question_claims[question_id];
        }

        questions[question_id].history_hash = last_history_hash;

    }

    function _payPayee(bytes32 question_id, address payee, uint256 value) 
    internal {
        balanceOf[payee] = balanceOf[payee].add(value);
        LogClaim(question_id, payee, value);
    }

    function _verifyHistoryInputOrRevert(
        bytes32 last_history_hash,
        bytes32 history_hash, bytes32 answer, uint256 bond, address addr
    )
    internal pure returns (bool) {
        if (last_history_hash == keccak256(history_hash, answer, bond, addr, true) ) {
            return true;
        }
        if (last_history_hash == keccak256(history_hash, answer, bond, addr, false) ) {
            return false;
        } 
        revert();
    }

    function _processHistoryItem(
        bytes32 question_id, bytes32 best_answer, 
        uint256 queued_funds, address payee, 
        address addr, uint256 bond, bytes32 answer, bool is_commitment
    )
    internal returns (uint256, address) {

        // For commit-and-reveal, the answer history holds the commitment ID instead of the answer.
        // We look at the referenced commitment ID and switch in the actual answer.
        if (is_commitment) {
            bytes32 commitment_id = answer;
            // If it&#39;s a commit but it hasn&#39;t been revealed, it will always be considered wrong.
            if (!commitments[commitment_id].is_revealed) {
                delete commitments[commitment_id];
                return (queued_funds, payee);
            } else {
                answer = commitments[commitment_id].revealed_answer;
                delete commitments[commitment_id];
            }
        }

        if (answer == best_answer) {

            if (payee == NULL_ADDRESS) {

                // The entry is for the first payee we come to, ie the winner.
                // They get the question bounty.
                payee = addr;
                queued_funds = queued_funds.add(questions[question_id].bounty);
                questions[question_id].bounty = 0;

            } else if (addr != payee) {

                // Answerer has changed, ie we found someone lower down who needs to be paid

                // The lower answerer will take over receiving bonds from higher answerer.
                // They should also be paid the takeover fee, which is set at a rate equivalent to their bond. 
                // (This is our arbitrary rule, to give consistent right-answerers a defence against high-rollers.)

                // There should be enough for the fee, but if not, take what we have.
                // There&#39;s an edge case involving weird arbitrator behaviour where we may be short.
                uint256 answer_takeover_fee = (queued_funds >= bond) ? bond : queued_funds;

                // Settle up with the old (higher-bonded) payee
                _payPayee(question_id, payee, queued_funds.sub(answer_takeover_fee));

                // Now start queued_funds again for the new (lower-bonded) payee
                payee = addr;
                queued_funds = answer_takeover_fee;

            }

        }

        return (queued_funds, payee);

    }

    /// @notice Convenience function to assign bounties/bonds for multiple questions in one go, then withdraw all your funds.
    /// Caller must provide the answer history for each question, in reverse order
    /// @dev Can be called by anyone to assign bonds/bounties, but funds are only withdrawn for the user making the call.
    /// @param question_ids The IDs of the questions you want to claim for
    /// @param lengths The number of history entries you will supply for each question ID
    /// @param hist_hashes In a single list for all supplied questions, the hash of each history entry.
    /// @param addrs In a single list for all supplied questions, the address of each answerer or commitment sender
    /// @param bonds In a single list for all supplied questions, the bond supplied with each answer or commitment
    /// @param answers In a single list for all supplied questions, each answer supplied, or commitment ID 
    function claimMultipleAndWithdrawBalance(
        bytes32[] question_ids, uint256[] lengths, 
        bytes32[] hist_hashes, address[] addrs, uint256[] bonds, bytes32[] answers
    ) 
        stateAny() // The finalization checks are done in the claimWinnings function
    public {
        
        uint256 qi;
        uint256 i;
        for (qi = 0; qi < question_ids.length; qi++) {
            bytes32 qid = question_ids[qi];
            uint256 ln = lengths[qi];
            bytes32[] memory hh = new bytes32[](ln);
            address[] memory ad = new address[](ln);
            uint256[] memory bo = new uint256[](ln);
            bytes32[] memory an = new bytes32[](ln);
            uint256 j;
            for (j = 0; j < ln; j++) {
                hh[j] = hist_hashes[i];
                ad[j] = addrs[i];
                bo[j] = bonds[i];
                an[j] = answers[i];
                i++;
            }
            claimWinnings(qid, hh, ad, bo, an);
        }
        withdraw();
    }
}




contract Arbitrator is Owned {

    RealityCheck public realitycheck;

    mapping(bytes32 => uint256) public arbitration_bounties;

    uint256 dispute_fee;
    mapping(bytes32 => uint256) custom_dispute_fees;

    event LogRequestArbitration(
        bytes32 indexed question_id,
        uint256 fee_paid,
        address requester,
        uint256 remaining
    );

    event LogSetRealityCheck(
        address realitycheck
    );

    event LogSetQuestionFee(
        uint256 fee
    );


    event LogSetDisputeFee(
        uint256 fee
    );

    event LogSetCustomDisputeFee(
        bytes32 indexed question_id,
        uint256 fee
    );

    /// @notice Constructor. Sets the deploying address as owner.
    function Arbitrator() 
    public {
        owner = msg.sender;
    }

    /// @notice Set the Reality Check contract address
    /// @param addr The address of the Reality Check contract
    function setRealityCheck(address addr) 
        onlyOwner 
    public {
        realitycheck = RealityCheck(addr);
        LogSetRealityCheck(addr);
    }

    /// @notice Set the default fee
    /// @param fee The default fee amount
    function setDisputeFee(uint256 fee) 
        onlyOwner 
    public {
        dispute_fee = fee;
        LogSetDisputeFee(fee);
    }

    /// @notice Set a custom fee for this particular question
    /// @param question_id The question in question
    /// @param fee The fee amount
    function setCustomDisputeFee(bytes32 question_id, uint256 fee) 
        onlyOwner 
    public {
        custom_dispute_fees[question_id] = fee;
        LogSetCustomDisputeFee(question_id, fee);
    }

    /// @notice Return the dispute fee for the specified question. 0 indicates that we won&#39;t arbitrate it.
    /// @param question_id The question in question
    /// @dev Uses a general default, but can be over-ridden on a question-by-question basis.
    function getDisputeFee(bytes32 question_id) 
    public constant returns (uint256) {
        return (custom_dispute_fees[question_id] > 0) ? custom_dispute_fees[question_id] : dispute_fee;
    }

    /// @notice Set a fee for asking a question with us as the arbitrator
    /// @param fee The fee amount
    /// @dev Default is no fee. Unlike the dispute fee, 0 is an acceptable setting.
    /// You could set an impossibly high fee if you want to prevent us being used as arbitrator unless we submit the question.
    /// (Submitting the question ourselves is not implemented here.)
    /// This fee can be used as a revenue source, an anti-spam measure, or both.
    function setQuestionFee(uint256 fee) 
        onlyOwner 
    public {
        realitycheck.setQuestionFee(fee);
        LogSetQuestionFee(fee);
    }

    /// @notice Submit the arbitrator&#39;s answer to a question.
    /// @param question_id The question in question
    /// @param answer The answer
    /// @param answerer The answerer. If arbitration changed the answer, it should be the payer. If not, the old answerer.
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) 
        onlyOwner 
    public {
        delete arbitration_bounties[question_id];
        realitycheck.submitAnswerByArbitrator(question_id, answer, answerer);
    }

    /// @notice Request arbitration, freezing the question until we send submitAnswerByArbitrator
    /// @dev The bounty can be paid only in part, in which case the last person to pay will be considered the payer
    /// Will trigger an error if the notification fails, eg because the question has already been finalized
    /// @param question_id The question in question
    function requestArbitration(bytes32 question_id) 
    external payable returns (bool) {

        uint256 arbitration_fee = getDisputeFee(question_id);
        require(arbitration_fee > 0);

        arbitration_bounties[question_id] += msg.value;
        uint256 paid = arbitration_bounties[question_id];

        if (paid >= arbitration_fee) {
            realitycheck.notifyOfArbitrationRequest(question_id, msg.sender);
            LogRequestArbitration(question_id, msg.value, msg.sender, 0);
            return true;
        } else {
            require(!realitycheck.isFinalized(question_id));
            LogRequestArbitration(question_id, msg.value, msg.sender, arbitration_fee - paid);
            return false;
        }

    }

    /// @notice Withdraw any accumulated fees to the specified address
    /// @param addr The address to which the balance should be sent
    function withdraw(address addr) 
        onlyOwner 
    public {
        addr.transfer(this.balance); 
    }

    function() 
    public payable {
    }

    /// @notice Withdraw any accumulated question fees from the specified address into this contract
    /// @dev Funds can then be liberated from this contract with our withdraw() function
    function callWithdraw() 
        onlyOwner 
    public {
        realitycheck.withdraw(); 
    }

}