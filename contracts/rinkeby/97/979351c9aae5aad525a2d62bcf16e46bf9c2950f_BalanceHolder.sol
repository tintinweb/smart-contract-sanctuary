/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// File: realitio/RealitioSafeMath256.sol

pragma solidity ^0.4.25;

library RealitioSafeMath256 {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

// File: realitio/RealitioSafeMath32.sol

pragma solidity ^0.4.25;

library RealitioSafeMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: realitio/BalanceHolder.sol

pragma solidity ^0.4.25;

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
        emit LogWithdraw(msg.sender, bal);
    }

}

// File: realitio/Realitio_v2_1.sol

pragma solidity ^0.4.25;




contract Realitio_v2_1 is BalanceHolder {

    using RealitioSafeMath256 for uint256;
    using RealitioSafeMath32 for uint32;

    address constant NULL_ADDRESS = address(0);

    bytes32 constant NULL_HASH = bytes32(0);

    uint32 constant UNANSWERED = 0;

    uint256 constant COMMITMENT_NON_EXISTENT = 0;

    uint32 constant COMMITMENT_TIMEOUT_RATIO = 8;

    uint256 constant BOND_CLAIM_FEE_PROPORTION = 40; // One 40th ie 2.5%

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

    event LogCancelArbitration(
        bytes32 indexed question_id
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

    struct Commitment {
        uint32 reveal_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }

    struct Claim {
        address payee;
        uint256 last_bond;
        uint256 queued_funds;
    }

    uint256 nextTemplateID = 0;
    mapping(uint256 => uint256) public templates;
    mapping(uint256 => bytes32) public template_hashes;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees;

    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        _;
    }

    modifier stateAny() {
        _;
    }

    modifier stateNotCreated(bytes32 question_id) {
        require(questions[question_id].timeout == 0, "question must not exist");
        _;
    }

    modifier stateOpen(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }

    modifier statePendingArbitration(bytes32 question_id) {
        require(questions[question_id].is_pending_arbitration, "question must be pending arbitration");
        _;
    }

    modifier stateOpenOrPendingArbitration(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now), "finalization dealine must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }

    modifier stateFinalized(bytes32 question_id) {
        require(isFinalized(question_id), "question must be finalized");
        _;
    }

    modifier bondMustDouble(bytes32 question_id) {
        require(msg.value > 0, "bond must be positive");
        require(msg.value >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        _;
    }

    modifier previousBondMustNotBeatMaxPrevious(bytes32 question_id, uint256 max_previous) {
        if (max_previous > 0) {
            require(questions[question_id].bond <= max_previous, "bond must exceed max_previous");
        }
        _;
    }

    constructor()
    public {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }

    function setQuestionFee(uint256 fee)
        stateAny()
    external {
        arbitrator_question_fees[msg.sender] = fee;
        emit LogSetQuestionFee(msg.sender, fee);
    }

    function createTemplate(string content)
        stateAny()
    public returns (uint256) {
        uint256 id = nextTemplateID;
        templates[id] = block.number;
        template_hashes[id] = keccak256(abi.encodePacked(content));
        emit LogNewTemplate(id, msg.sender, content);
        nextTemplateID = id.add(1);
        return id;
    }

    function createTemplateAndAskQuestion(
        string content,
        string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce
    )
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {
        uint256 template_id = createTemplate(content);
        return askQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }

    function askQuestion(uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce)
        // stateNotCreated is enforced by the internal _askQuestion
    public payable returns (bytes32) {

        require(templates[template_id] > 0, "template must exist");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, msg.sender, nonce));

        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts);
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, now);

        return question_id;
    }

    function _askQuestion(bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 timeout, uint32 opening_ts)
        stateNotCreated(question_id)
    internal {

        // A timeout of 0 makes no sense, and we will use this to check existence
        require(timeout > 0, "timeout must be positive");
        require(timeout < 365 days, "timeout must be less than 365 days");
        require(arbitrator != NULL_ADDRESS, "arbitrator must be set");

        uint256 bounty = msg.value;

        if (msg.sender != arbitrator) {
            uint256 question_fee = arbitrator_question_fees[arbitrator];
            require(bounty >= question_fee, "ETH provided must cover question fee");
            bounty = bounty.sub(question_fee);
            balanceOf[arbitrator] = balanceOf[arbitrator].add(question_fee);
        }

        questions[question_id].content_hash = content_hash;
        questions[question_id].arbitrator = arbitrator;
        questions[question_id].opening_ts = opening_ts;
        questions[question_id].timeout = timeout;
        questions[question_id].bounty = bounty;

    }

    function fundAnswerBounty(bytes32 question_id)
        stateOpen(question_id)
    external payable {
        questions[question_id].bounty = questions[question_id].bounty.add(msg.value);
        emit LogFundAnswerBounty(question_id, msg.value, questions[question_id].bounty, msg.sender);
    }
    function submitAnswer(bytes32 question_id, bytes32 answer, uint256 max_previous)
        stateOpen(question_id)
        bondMustDouble(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {
        _addAnswerToHistory(question_id, answer, msg.sender, msg.value, false);
        _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
    }

    function submitAnswerFor(bytes32 question_id, bytes32 answer, uint256 max_previous, address answerer)
        stateOpen(question_id)
        bondMustDouble(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {
        require(answerer != NULL_ADDRESS, "answerer must be non-zero");
        _addAnswerToHistory(question_id, answer, answerer, msg.value, false);
        _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
    }

    function _storeCommitment(bytes32 question_id, bytes32 commitment_id)
    internal
    {
        require(commitments[commitment_id].reveal_ts == COMMITMENT_NON_EXISTENT, "commitment must not already exist");

        uint32 commitment_timeout = questions[question_id].timeout / COMMITMENT_TIMEOUT_RATIO;
        commitments[commitment_id].reveal_ts = uint32(now).add(commitment_timeout);
    }

    function submitAnswerCommitment(bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer)
        stateOpen(question_id)
        bondMustDouble(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external payable {

        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, msg.value));
        address answerer = (_answerer == NULL_ADDRESS) ? msg.sender : _answerer;
        _storeCommitment(question_id, commitment_id);
        _addAnswerToHistory(question_id, commitment_id, answerer, msg.value, true);

    }

    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond)
        stateOpenOrPendingArbitration(question_id)
    external {

        bytes32 answer_hash = keccak256(abi.encodePacked(answer, nonce));
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, bond));

        require(!commitments[commitment_id].is_revealed, "commitment must not have been revealed yet");
        require(commitments[commitment_id].reveal_ts > uint32(now), "reveal deadline must not have passed");

        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;

        if (bond == questions[question_id].bond) {
            _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
        }

        emit LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);

    }

    function _addAnswerToHistory(bytes32 question_id, bytes32 answer_or_commitment_id, address answerer, uint256 bond, bool is_commitment)
    internal
    {
        bytes32 new_history_hash = keccak256(abi.encodePacked(questions[question_id].history_hash, answer_or_commitment_id, bond, answerer, is_commitment));

        // Update the current bond level, if there's a bond (ie anything except arbitration)
        if (bond > 0) {
            questions[question_id].bond = bond;
        }
        questions[question_id].history_hash = new_history_hash;

        emit LogNewAnswer(answer_or_commitment_id, question_id, new_history_hash, answerer, bond, now, is_commitment);
    }

    function _updateCurrentAnswer(bytes32 question_id, bytes32 answer, uint32 timeout_secs)
    internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(now).add(timeout_secs);
    }

    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous)
        onlyArbitrator(question_id)
        stateOpen(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external {
        require(questions[question_id].bond > 0, "Question must already have an answer when arbitration is requested");
        questions[question_id].is_pending_arbitration = true;
        emit LogNotifyOfArbitrationRequest(question_id, requester);
    }

    function cancelArbitration(bytes32 question_id)
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
    external {
        questions[question_id].is_pending_arbitration = false;
        questions[question_id].finalize_ts = uint32(now).add(questions[question_id].timeout);
        emit LogCancelArbitration(question_id);
    }

    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer)
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
    public {

        require(answerer != NULL_ADDRESS, "answerer must be provided");
        emit LogFinalize(question_id, answer);

        questions[question_id].is_pending_arbitration = false;
        _addAnswerToHistory(question_id, answer, answerer, 0, false);
        _updateCurrentAnswer(question_id, answer, 0);

    }

    function assignWinnerAndSubmitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer)
    external {
        bool is_commitment = _verifyHistoryInputOrRevert(questions[question_id].history_hash, last_history_hash, last_answer_or_commitment_id, questions[question_id].bond, last_answerer);

        address payee;
        // If the last answer is an unrevealed commit, it's always wrong.
        // For anything else, the last answer was set as the "best answer" in submitAnswer or submitAnswerReveal.
        if (is_commitment && !commitments[last_answer_or_commitment_id].is_revealed) {
            require(commitments[last_answer_or_commitment_id].reveal_ts < uint32(now), "You must wait for the reveal deadline before finalizing");
            payee = payee_if_wrong;
        } else {
            payee = (questions[question_id].best_answer == answer) ? last_answerer : payee_if_wrong;
        }
        submitAnswerByArbitrator(question_id, answer, payee);
    }


    function isFinalized(bytes32 question_id)
    view public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return ( !questions[question_id].is_pending_arbitration && (finalize_ts > UNANSWERED) && (finalize_ts <= uint32(now)) );
    }

    function getFinalAnswer(bytes32 question_id)
        stateFinalized(question_id)
    external view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    function resultFor(bytes32 question_id)
        stateFinalized(question_id)
    external view returns (bytes32) {
        return questions[question_id].best_answer;
    }


    function getFinalAnswerIfMatches(
        bytes32 question_id,
        bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond
    )
        stateFinalized(question_id)
    external view returns (bytes32) {
        require(content_hash == questions[question_id].content_hash, "content hash must match");
        require(arbitrator == questions[question_id].arbitrator, "arbitrator must match");
        require(min_timeout <= questions[question_id].timeout, "timeout must be long enough");
        require(min_bond <= questions[question_id].bond, "bond must be high enough");
        return questions[question_id].best_answer;
    }

    function claimWinnings(
        bytes32 question_id,
        bytes32[] history_hashes, address[] addrs, uint256[] bonds, bytes32[] answers
    )
        stateFinalized(question_id)
    public {

        require(history_hashes.length > 0, "at least one history hash entry must be provided");

        address payee = question_claims[question_id].payee;
        uint256 last_bond = question_claims[question_id].last_bond;
        uint256 queued_funds = question_claims[question_id].queued_funds;

        bytes32 last_history_hash = questions[question_id].history_hash;

        bytes32 best_answer = questions[question_id].best_answer;

        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {

            bool is_commitment = _verifyHistoryInputOrRevert(last_history_hash, history_hashes[i], answers[i], bonds[i], addrs[i]);

            queued_funds = queued_funds.add(last_bond);
            (queued_funds, payee) = _processHistoryItem(
                question_id, best_answer, queued_funds, payee,
                addrs[i], bonds[i], answers[i], is_commitment);

            last_bond = bonds[i];

            if (last_bond != questions[question_id].bond) {
                last_bond = last_bond.sub(last_bond / BOND_CLAIM_FEE_PROPORTION);
            }

            last_history_hash = history_hashes[i];

        }

        if (last_history_hash != NULL_HASH) {
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
        emit LogClaim(question_id, payee, value);
    }

    function _verifyHistoryInputOrRevert(
        bytes32 last_history_hash,
        bytes32 history_hash, bytes32 answer, uint256 bond, address addr
    )
    internal pure returns (bool) {
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, true)) ) {
            return true;
        }
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, false)) ) {
            return false;
        }
        revert("History input provided did not match the expected hash");
    }

    function _processHistoryItem(
        bytes32 question_id, bytes32 best_answer,
        uint256 queued_funds, address payee,
        address addr, uint256 bond, bytes32 answer, bool is_commitment
    )
    internal returns (uint256, address) {

        if (is_commitment) {
            bytes32 commitment_id = answer;
            // If it's a commit but it hasn't been revealed, it will always be considered wrong.
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

                payee = addr;
                queued_funds = queued_funds.add(questions[question_id].bounty);
                questions[question_id].bounty = 0;

            } else if (addr != payee) {

                uint256 answer_takeover_fee = (queued_funds >= bond) ? bond : queued_funds;
                _payPayee(question_id, payee, queued_funds.sub(answer_takeover_fee));

                payee = addr;
                queued_funds = answer_takeover_fee;

            }

        }

        return (queued_funds, payee);

    }

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

    function getContentHash(bytes32 question_id)
    public view returns(bytes32) {
        return questions[question_id].content_hash;
    }

    function getArbitrator(bytes32 question_id)
    public view returns(address) {
        return questions[question_id].arbitrator;
    }

    function getOpeningTS(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].opening_ts;
    }

    function getTimeout(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].timeout;
    }

    function getFinalizeTS(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].finalize_ts;
    }

    function isPendingArbitration(bytes32 question_id)
    public view returns(bool) {
        return questions[question_id].is_pending_arbitration;
    }

    function getBounty(bytes32 question_id)
    public view returns(uint256) {
        return questions[question_id].bounty;
    }

    function getBestAnswer(bytes32 question_id) 
    public view returns(bytes32) {
        return questions[question_id].best_answer;
    }

    function getHistoryHash(bytes32 question_id)
    public view returns(bytes32) {
        return questions[question_id].history_hash;
    }

    function getBond(bytes32 question_id)
    public view returns(uint256) {
        return questions[question_id].bond;
    }

}