/*
-----------------------------------------------------------------
FILE HEADER
-----------------------------------------------------------------

file:       HavvenEscrow.sol
version:    1.0
authors:    Anton Jurisevic
            Dominic Romanowski
            Mike Spain

date:       2018-02-28
checked:    Mike Spain
approved:   Samuel Brooks

repo:       https://github.com/Havven/havven
commit:     34e66009b98aa18976226c139270970d105045e3

-----------------------------------------------------------------
*/

pragma solidity ^0.4.21;

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A contract with a limited setup period. Any function modified
with the setup modifier will cease to work after the
conclusion of the configurable-length post-construction setup period.

-----------------------------------------------------------------
*/

contract LimitedSetup {

    uint constructionTime;
    uint setupDuration;

    function LimitedSetup(uint _setupDuration)
        public
    {
        constructionTime = now;
        setupDuration = _setupDuration;
    }

    modifier setupFunction
    {
        require(now < constructionTime + setupDuration);
        _;
    }
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner)
        public
    {
        owner = _owner;
    }

    function nominateOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A proxy contract that, if it does not recognise the function
being called on it, passes all value and call data to an
underlying target contract.

-----------------------------------------------------------------
*/

contract Proxy is Owned {
    Proxyable target;

    function Proxy(Proxyable _target, address _owner)
        Owned(_owner)
        public
    {
        target = _target;
        emit TargetChanged(_target);
    }

    function _setTarget(address _target) 
        external
        onlyOwner
    {
        require(_target != address(0));
        target = Proxyable(_target);
        emit TargetChanged(_target);
    }

    function () 
        public
        payable
    {
        target.setMessageSender(msg.sender);
        assembly {
            // Copy call data into free memory region.
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            // Forward all gas, ether, and data to the target contract.
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            // Revert if the call failed, otherwise return the result.
            if iszero(result) { revert(free_ptr, calldatasize) }
            return(free_ptr, returndatasize)
        } 
    }

    event TargetChanged(address targetAddress);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

This contract contains the Proxyable interface.
Any contract the proxy wraps must implement this, in order
for the proxy to be able to pass msg.sender into the underlying
contract as the state parameter, messageSender.

-----------------------------------------------------------------
*/

contract Proxyable is Owned {
    // the proxy this contract exists behind.
    Proxy public proxy;

    // The caller of the proxy, passed through to this contract.
    // Note that every function using this member must apply the onlyProxy or
    // optionalProxy modifiers, otherwise their invocations can use stale values.
    address messageSender;

    function Proxyable(address _owner)
        Owned(_owner)
        public { }

    function setProxy(Proxy _proxy)
        external
        onlyOwner
    {
        proxy = _proxy;
        emit ProxyChanged(_proxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy
    {
        require(Proxy(msg.sender) == proxy);
        _;
    }

    modifier onlyOwner_Proxy
    {
        require(messageSender == owner);
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

    // Combine the optionalProxy and onlyOwner_Proxy modifiers.
    // This is slightly cheaper and safer, since there is an ordering requirement.
    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner);
        _;
    }

    event ProxyChanged(address proxyAddress);

}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A fixed point decimal library that provides basic mathematical
operations, and checks for unsafe arguments, for example that
would lead to overflows.

Exceptions are thrown whenever those unsafe operations
occur.

-----------------------------------------------------------------
*/

contract SafeDecimalMath {

    // Number of decimal places in the representation.
    uint8 public constant decimals = 18;

    // The number representing 1.0.
    uint public constant UNIT = 10 ** uint(decimals);

    /* True iff adding x and y will not overflow. */
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

    /* Return the result of adding x and y, throwing an exception in case of overflow. */
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y);
        return x + y;
    }

    /* True iff subtracting y from x will not overflow in the negative direction. */
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

    /* Return the result of subtracting y from x, throwing an exception in case of overflow. */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x);
        return x - y;
    }

    /* True iff multiplying x and y would not overflow. */
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

    /* Return the result of multiplying x and y, throwing an exception in case of overflow.*/
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y);
        return p;
    }

    /* Return the result of multiplying x and y, interpreting the operands as fixed-point
     * demicimals. Throws an exception in case of overflow. A unit factor is divided out
     * after the product of x and y is evaluated, so that product must be less than 2**256.
     * 
     * Incidentally, the internal division always rounds down: we could have rounded to the nearest integer,
     * but then we would be spending a significant fraction of a cent (of order a microether
     * at present gas prices) in order to save less than one part in 0.5 * 10^18 per operation, if the operands
     * contain small enough fractional components. It would also marginally diminish the 
     * domain this function is defined upon. 
     */
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        // Divide by UNIT to remove the extra factor introduced by the product.
        // UNIT be 0.
        return safeMul(x, y) / UNIT;

    }

    /* True iff the denominator of x/y is nonzero. */
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

    /* Return the result of dividing x by y, throwing an exception if the divisor is zero. */
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        // Although a 0 denominator already throws an exception,
        // it is equivalent to a THROW operation, which consumes all gas.
        // A require statement emits REVERT instead, which remits remaining gas.
        require(y != 0);
        return x / y;
    }

    /* Return the result of dividing x by y, interpreting the operands as fixed point decimal numbers.
     * Throws an exception in case of overflow or zero divisor; x must be less than 2^256 / UNIT.
     * Internal rounding is downward: a similar caveat holds as with safeDecMul().*/
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        // Reintroduce the UNIT factor that will be divided out by y.
        return safeDiv(safeMul(x, UNIT), y);
    }

    /* Convert an unsigned integer to a unsigned fixed-point decimal.
     * Throw an exception if the result would be out of range. */
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

This court provides the nomin contract with a confiscation
facility, if enough havven owners vote to confiscate a target
account&#39;s nomins.

This is designed to provide a mechanism to respond to abusive
contracts such as nomin wrappers, which would allow users to
trade wrapped nomins without accruing fees on those transactions.

In order to prevent tyranny, an account may only be frozen if
users controlling at least 30% of the value of havvens participate,
and a two thirds majority is attained in that vote.
In order to prevent tyranny of the majority or mob justice,
confiscation motions are only approved if the havven foundation
approves the result.
This latter requirement may be lifted in future versions.

The foundation, or any user with a sufficient havven balance may bring a
confiscation motion.
A motion lasts for a default period of one week, with a further confirmation
period in which the foundation approves the result.
The latter period may conclude early upon the foundation&#39;s decision to either
veto or approve the mooted confiscation motion.
If the confirmation period elapses without the foundation making a decision,
the motion fails.

The weight of a havven holder&#39;s vote is determined by examining their
average balance over the last completed fee period prior to the
beginning of a given motion.
Thus, since a fee period can roll over in the middle of a motion, we must
also track a user&#39;s average balance of the last two periods.
This system is designed such that it cannot be attacked by users transferring
funds between themselves, while also not requiring them to lock their havvens
for the duration of the vote. This is possible since any transfer that increases
the average balance in one account will be reflected by an equivalent reduction
in the voting weight in the other.
At present a user may cast a vote only for one motion at a time,
but may cancel their vote at any time except during the confirmation period,
when the vote tallies must remain static until the matter has been settled.

A motion to confiscate the balance of a given address composes
a state machine built of the following states:


Waiting:
  - A user with standing brings a motion:
    If the target address is not frozen;
    initialise vote tallies to 0;
    transition to the Voting state.

  - An account cancels a previous residual vote:
    remain in the Waiting state.

Voting:
  - The foundation vetoes the in-progress motion:
    transition to the Waiting state.

  - The voting period elapses:
    transition to the Confirmation state.

  - An account votes (for or against the motion):
    its weight is added to the appropriate tally;
    remain in the Voting state.

  - An account cancels its previous vote:
    its weight is deducted from the appropriate tally (if any);
    remain in the Voting state.

Confirmation:
  - The foundation vetoes the completed motion:
    transition to the Waiting state.

  - The foundation approves confiscation of the target account:
    freeze the target account, transfer its nomin balance to the fee pool;
    transition to the Waiting state.

  - The confirmation period elapses:
    transition to the Waiting state.


User votes are not automatically cancelled upon the conclusion of a motion.
Therefore, after a motion comes to a conclusion, if a user wishes to vote 
in another motion, they must manually cancel their vote in order to do so.

This procedure is designed to be relatively simple.
There are some things that can be added to enhance the functionality
at the expense of simplicity and efficiency:
  
  - Democratic unfreezing of nomin accounts (induces multiple categories of vote)
  - Configurable per-vote durations;
  - Vote standing denominated in a fiat quantity rather than a quantity of havvens;
  - Confiscate from multiple addresses in a single vote;

We might consider updating the contract with any of these features at a later date if necessary.

-----------------------------------------------------------------
*/

contract Court is Owned, SafeDecimalMath {

    /* ========== STATE VARIABLES ========== */

    // The addresses of the token contracts this confiscation court interacts with.
    Havven public havven;
    EtherNomin public nomin;

    // The minimum havven balance required to be considered to have standing
    // to begin confiscation proceedings.
    uint public minStandingBalance = 100 * UNIT;

    // The voting period lasts for this duration,
    // and if set, must fall within the given bounds.
    uint public votingPeriod = 1 weeks;
    uint constant MIN_VOTING_PERIOD = 3 days;
    uint constant MAX_VOTING_PERIOD = 4 weeks;

    // Duration of the period during which the foundation may confirm
    // or veto a motion that has concluded.
    // If set, the confirmation duration must fall within the given bounds.
    uint public confirmationPeriod = 1 weeks;
    uint constant MIN_CONFIRMATION_PERIOD = 1 days;
    uint constant MAX_CONFIRMATION_PERIOD = 2 weeks;

    // No fewer than this fraction of havvens must participate in a motion
    // in order for a quorum to be reached.
    // The participation fraction required may be set no lower than 10%.
    uint public requiredParticipation = 3 * UNIT / 10;
    uint constant MIN_REQUIRED_PARTICIPATION = UNIT / 10;

    // At least this fraction of participating votes must be in favour of
    // confiscation for the motion to pass.
    // The required majority may be no lower than 50%.
    uint public requiredMajority = (2 * UNIT) / 3;
    uint constant MIN_REQUIRED_MAJORITY = UNIT / 2;

    // The next ID to use for opening a motion.
    uint nextMotionID = 1;

    // Mapping from motion IDs to target addresses.
    mapping(uint => address) public motionTarget;

    // The ID a motion on an address is currently operating at.
    // Zero if no such motion is running.
    mapping(address => uint) public targetMotionID;

    // The timestamp at which a motion began. This is used to determine
    // whether a motion is: running, in the confirmation period,
    // or has concluded.
    // A motion runs from its start time t until (t + votingPeriod),
    // and then the confirmation period terminates no later than
    // (t + votingPeriod + confirmationPeriod).
    mapping(uint => uint) public motionStartTime;

    // The tallies for and against confiscation of a given balance.
    // These are set to zero at the start of a motion, and also on conclusion,
    // just to keep the state clean.
    mapping(uint => uint) public votesFor;
    mapping(uint => uint) public votesAgainst;

    // The last/penultimate average balance of a user at the time they voted
    // in a particular motion.
    // If we did not save this information then we would have to
    // disallow transfers into an account lest it cancel a vote
    // with greater weight than that with which it originally voted,
    // and the fee period rolled over in between.
    mapping(address => mapping(uint => uint)) voteWeight;

    // The possible vote types.
    // Abstention: not participating in a motion; This is the default value.
    // Yea: voting in favour of a motion.
    // Nay: voting against a motion.
    enum Vote {Abstention, Yea, Nay}

    // A given account&#39;s vote in some confiscation motion.
    // This requires the default value of the Vote enum to correspond to an abstention.
    mapping(address => mapping(uint => Vote)) public vote;

    /* ========== CONSTRUCTOR ========== */

    function Court(Havven _havven, EtherNomin _nomin, address _owner)
        Owned(_owner)
        public
    {
        havven = _havven;
        nomin = _nomin;
    }


    /* ========== SETTERS ========== */

    function setMinStandingBalance(uint balance)
        external
        onlyOwner
    {
        // No requirement on the standing threshold here;
        // the foundation can set this value such that
        // anyone or no one can actually start a motion.
        minStandingBalance = balance;
    }

    function setVotingPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_VOTING_PERIOD <= duration &&
                duration <= MAX_VOTING_PERIOD);
        // Require that the voting period is no longer than a single fee period,
        // So that a single vote can span at most two fee periods.
        require(duration <= havven.targetFeePeriodDurationSeconds());
        votingPeriod = duration;
    }

    function setConfirmationPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_CONFIRMATION_PERIOD <= duration &&
                duration <= MAX_CONFIRMATION_PERIOD);
        confirmationPeriod = duration;
    }

    function setRequiredParticipation(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_PARTICIPATION <= fraction);
        requiredParticipation = fraction;
    }

    function setRequiredMajority(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_MAJORITY <= fraction);
        requiredMajority = fraction;
    }


    /* ========== VIEW FUNCTIONS ========== */

    /* There is a motion in progress on the specified
     * account, and votes are being accepted in that motion. */
    function motionVoting(uint motionID)
        public
        view
        returns (bool)
    {
        // No need to check (startTime < now) as there is no way
        // to set future start times for votes.
        // These values are timestamps, they will not overflow
        // as they can only ever be initialised to relatively small values.
        return now < motionStartTime[motionID] + votingPeriod;
    }

    /* A vote on the target account has concluded, but the motion
     * has not yet been approved, vetoed, or closed. */
    function motionConfirming(uint motionID)
        public
        view
        returns (bool)
    {
        // These values are timestamps, they will not overflow
        // as they can only ever be initialised to relatively small values.
        uint startTime = motionStartTime[motionID];
        return startTime + votingPeriod <= now &&
               now < startTime + votingPeriod + confirmationPeriod;
    }

    /* A vote motion either not begun, or it has completely terminated. */
    function motionWaiting(uint motionID)
        public
        view
        returns (bool)
    {
        // These values are timestamps, they will not overflow
        // as they can only ever be initialised to relatively small values.
        return motionStartTime[motionID] + votingPeriod + confirmationPeriod <= now;
    }

    /* If the motion was to terminate at this instant, it would pass.
     * That is: there was sufficient participation and a sizeable enough majority. */
    function motionPasses(uint motionID)
        public
        view
        returns (bool)
    {
        uint yeas = votesFor[motionID];
        uint nays = votesAgainst[motionID];
        uint totalVotes = safeAdd(yeas, nays);

        if (totalVotes == 0) {
            return false;
        }

        uint participation = safeDiv_dec(totalVotes, havven.totalSupply());
        uint fractionInFavour = safeDiv_dec(yeas, totalVotes);

        // We require the result to be strictly greater than the requirement
        // to enforce a majority being "50% + 1", and so on.
        return participation > requiredParticipation &&
               fractionInFavour > requiredMajority;
    }

    function hasVoted(address account, uint motionID)
        public
        view
        returns (bool)
    {
        return vote[account][motionID] != Vote.Abstention;
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /* Begin a motion to confiscate the funds in a given nomin account.
     * Only the foundation, or accounts with sufficient havven balances
     * may elect to start such a motion.
     * Returns the ID of the motion that was begun. */
    function beginMotion(address target)
        external
        returns (uint)
    {
        // A confiscation motion must be mooted by someone with standing.
        require((havven.balanceOf(msg.sender) >= minStandingBalance) ||
                msg.sender == owner);

        // Require that the voting period is longer than a single fee period,
        // So that a single vote can span at most two fee periods.
        require(votingPeriod <= havven.targetFeePeriodDurationSeconds());

        // There must be no confiscation motion already running for this account.
        require(targetMotionID[target] == 0);

        // Disallow votes on accounts that have previously been frozen.
        require(!nomin.frozen(target));

        uint motionID = nextMotionID++;
        motionTarget[motionID] = target;
        targetMotionID[target] = motionID;

        motionStartTime[motionID] = now;
        emit MotionBegun(msg.sender, msg.sender, target, target, motionID, motionID);

        return motionID;
    }

    /* Shared vote setup function between voteFor and voteAgainst.
     * Returns the voter&#39;s vote weight. */
    function setupVote(uint motionID)
        internal
        returns (uint)
    {
        // There must be an active vote for this target running.
        // Vote totals must only change during the voting phase.
        require(motionVoting(motionID));

        // The voter must not have an active vote this motion.
        require(!hasVoted(msg.sender, motionID));

        // The voter may not cast votes on themselves.
        require(msg.sender != motionTarget[motionID]);

        // Ensure the voter&#39;s vote weight is current.
        havven.recomputeAccountLastAverageBalance(msg.sender);

        uint weight;
        // We use a fee period guaranteed to have terminated before
        // the start of the vote. Select the right period if
        // a fee period rolls over in the middle of the vote.
        if (motionStartTime[motionID] < havven.feePeriodStartTime()) {
            weight = havven.penultimateAverageBalance(msg.sender);
        } else {
            weight = havven.lastAverageBalance(msg.sender);
        }

        // Users must have a nonzero voting weight to vote.
        require(weight > 0);

        voteWeight[msg.sender][motionID] = weight;

        return weight;
    }

    /* The sender casts a vote in favour of confiscation of the
     * target account&#39;s nomin balance. */
    function voteFor(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Yea;
        votesFor[motionID] = safeAdd(votesFor[motionID], weight);
        emit VotedFor(msg.sender, msg.sender, motionID, motionID, weight);
    }

    /* The sender casts a vote against confiscation of the
     * target account&#39;s nomin balance. */
    function voteAgainst(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Nay;
        votesAgainst[motionID] = safeAdd(votesAgainst[motionID], weight);
        emit VotedAgainst(msg.sender, msg.sender, motionID, motionID, weight);
    }

    /* Cancel an existing vote by the sender on a motion
     * to confiscate the target balance. */
    function cancelVote(uint motionID)
        external
    {
        // An account may cancel its vote either before the confirmation phase
        // when the motion is still open, or after the confirmation phase,
        // when the motion has concluded.
        // But the totals must not change during the confirmation phase itself.
        require(!motionConfirming(motionID));

        Vote senderVote = vote[msg.sender][motionID];

        // If the sender has not voted then there is no need to update anything.
        require(senderVote != Vote.Abstention);

        // If we are not voting, there is no reason to update the vote totals.
        if (motionVoting(motionID)) {
            if (senderVote == Vote.Yea) {
                votesFor[motionID] = safeSub(votesFor[motionID], voteWeight[msg.sender][motionID]);
            } else {
                // Since we already ensured that the vote is not an abstention,
                // the only option remaining is Vote.Nay.
                votesAgainst[motionID] = safeSub(votesAgainst[motionID], voteWeight[msg.sender][motionID]);
            }
            // A cancelled vote is only meaningful if a vote is running
            emit VoteCancelled(msg.sender, msg.sender, motionID, motionID);
        }

        delete voteWeight[msg.sender][motionID];
        delete vote[msg.sender][motionID];
    }

    function _closeMotion(uint motionID)
        internal
    {
        delete targetMotionID[motionTarget[motionID]];
        delete motionTarget[motionID];
        delete motionStartTime[motionID];
        delete votesFor[motionID];
        delete votesAgainst[motionID];
        emit MotionClosed(motionID, motionID);
    }

    /* If a motion has concluded, or if it lasted its full duration but not passed,
     * then anyone may close it. */
    function closeMotion(uint motionID)
        external
    {
        require((motionConfirming(motionID) && !motionPasses(motionID)) || motionWaiting(motionID));
        _closeMotion(motionID);
    }

    /* The foundation may only confiscate a balance during the confirmation
     * period after a motion has passed. */
    function approveMotion(uint motionID)
        external
        onlyOwner
    {
        require(motionConfirming(motionID) && motionPasses(motionID));
        address target = motionTarget[motionID];
        nomin.confiscateBalance(target);
        _closeMotion(motionID);
        emit MotionApproved(motionID, motionID);
    }

    /* The foundation may veto a motion at any time. */
    function vetoMotion(uint motionID)
        external
        onlyOwner
    {
        require(!motionWaiting(motionID));
        _closeMotion(motionID);
        emit MotionVetoed(motionID, motionID);
    }


    /* ========== EVENTS ========== */

    event MotionBegun(address initiator, address indexed initiatorIndex, address target, address indexed targetIndex, uint motionID, uint indexed motionIDIndex);

    event VotedFor(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex, uint weight);

    event VotedAgainst(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex, uint weight);

    event VoteCancelled(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex);

    event MotionClosed(uint motionID, uint indexed motionIDIndex);

    event MotionVetoed(uint motionID, uint indexed motionIDIndex);

    event MotionApproved(uint motionID, uint indexed motionIDIndex);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A token which also has a configurable fee rate
charged on its transfers. This is designed to be overridden in
order to produce an ERC20-compliant token.

These fees accrue into a pool, from which a nominated authority
may withdraw.

This contract utilises a state for upgradability purposes.
It relies on being called underneath a proxy contract, as
included in Proxy.sol.

-----------------------------------------------------------------
*/

contract ExternStateProxyFeeToken is Proxyable, SafeDecimalMath {

    /* ========== STATE VARIABLES ========== */

    // Stores balances and allowances.
    TokenState public state;

    // Other ERC20 fields
    string public name;
    string public symbol;
    uint public totalSupply;

    // A percentage fee charged on each transfer.
    uint public transferFeeRate;
    // Fee may not exceed 10%.
    uint constant MAX_TRANSFER_FEE_RATE = UNIT / 10;
    // The address with the authority to distribute fees.
    address public feeAuthority;


    /* ========== CONSTRUCTOR ========== */

    function ExternStateProxyFeeToken(string _name, string _symbol,
                                      uint _transferFeeRate, address _feeAuthority,
                                      TokenState _state, address _owner)
        Proxyable(_owner)
        public
    {
        if (_state == TokenState(0)) {
            state = new TokenState(_owner, address(this));
        } else {
            state = _state;
        }

        name = _name;
        symbol = _symbol;
        transferFeeRate = _transferFeeRate;
        feeAuthority = _feeAuthority;
    }

    /* ========== SETTERS ========== */

    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE);
        transferFeeRate = _transferFeeRate;
        emit TransferFeeRateUpdated(_transferFeeRate);
    }

    function setFeeAuthority(address _feeAuthority)
        external
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
        emit FeeAuthorityUpdated(_feeAuthority);
    }

    function setState(TokenState _state)
        external
        optionalProxy_onlyOwner
    {
        state = _state;
        emit StateUpdated(_state);
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return state.balanceOf(account);
    }

    function allowance(address from, address to)
        public
        view
        returns (uint)
    {
        return state.allowance(from, to);
    }

    // Return the fee charged on top in order to transfer _value worth of tokens.
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return safeMul_dec(value, transferFeeRate);
        // Transfers less than the reciprocal of transferFeeRate should be completely eaten up by fees.
        // This is on the basis that transfers less than this value will result in a nil fee.
        // Probably too insignificant to worry about, but the following code will achieve it.
        //      if (fee == 0 && transferFeeRate != 0) {
        //          return _value;
        //      }
        //      return fee;
    }

    // The value that you would need to send so that the recipient receives
    // a specified value.
    function transferPlusFee(uint value)
        external
        view
        returns (uint)
    {
        return safeAdd(value, transferFeeIncurred(value));
    }

    // The quantity to send in order that the sender spends a certain value of tokens.
    function priceToSpend(uint value)
        external
        view
        returns (uint)
    {
        return safeDiv_dec(value, safeAdd(UNIT, transferFeeRate));
    }

    // The balance of the nomin contract itself is the fee pool.
    // Collected fees sit here until they are distributed.
    function feePool()
        external
        view
        returns (uint)
    {
        return state.balanceOf(address(this));
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /* Whatever calls this should have either the optionalProxy or onlyProxy modifier,
     * and pass in messageSender. */
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

        // The fee is deducted from the sender&#39;s balance, in addition to
        // the transferred quantity.
        uint fee = transferFeeIncurred(value);
        uint totalCharge = safeAdd(value, fee);

        // Insufficient balance will be handled by the safe subtraction.
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), totalCharge));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), fee));

        emit Transfer(sender, to, value);
        emit TransferFeePaid(sender, fee);
        emit Transfer(sender, address(this), fee);

        return true;
    }

    /* Whatever calls this should have either the optionalProxy or onlyProxy modifier,
     * and pass in messageSender. */
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

        // The fee is deducted from the sender&#39;s balance, in addition to
        // the transferred quantity.
        uint fee = transferFeeIncurred(value);
        uint totalCharge = safeAdd(value, fee);

        // Insufficient balance will be handled by the safe subtraction.
        state.setBalanceOf(from, safeSub(state.balanceOf(from), totalCharge));
        state.setAllowance(from, sender, safeSub(state.allowance(from, sender), totalCharge));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), fee));

        emit Transfer(from, to, value);
        emit TransferFeePaid(sender, fee);
        emit Transfer(from, address(this), fee);

        return true;
    }

    function approve(address spender, uint value)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        state.setAllowance(sender, spender, value);

        emit Approval(sender, spender, value);

        return true;
    }

    /* Withdraw tokens from the fee pool into a given account. */
    function withdrawFee(address account, uint value)
        external
        returns (bool)
    {
        require(msg.sender == feeAuthority && account != address(0));
        
        // 0-value withdrawals do nothing.
        if (value == 0) {
            return false;
        }

        // Safe subtraction ensures an exception is thrown if the balance is insufficient.
        state.setBalanceOf(address(this), safeSub(state.balanceOf(address(this)), value));
        state.setBalanceOf(account, safeAdd(state.balanceOf(account), value));

        emit FeesWithdrawn(account, account, value);
        emit Transfer(address(this), account, value);

        return true;
    }

    /* Donate tokens from the sender&#39;s balance into the fee pool. */
    function donateToFeePool(uint n)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;

        // Empty donations are disallowed.
        uint balance = state.balanceOf(sender);
        require(balance != 0);

        // safeSub ensures the donor has sufficient balance.
        state.setBalanceOf(sender, safeSub(balance, n));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), n));

        emit FeesDonated(sender, sender, n);
        emit Transfer(sender, address(this), n);

        return true;
    }

    /* ========== EVENTS ========== */

    event Transfer(address indexed from, address indexed to, uint value);

    event TransferFeePaid(address indexed account, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event TransferFeeRateUpdated(uint newFeeRate);

    event FeeAuthorityUpdated(address feeAuthority);

    event StateUpdated(address newState);

    event FeesWithdrawn(address account, address indexed accountIndex, uint value);

    event FeesDonated(address donor, address indexed donorIndex, uint value);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

Ether-backed nomin stablecoin contract.

This contract issues nomins, which are tokens worth 1 USD each. They are backed
by a pool of ether collateral, so that if a user has nomins, they may
redeem them for ether from the pool, or if they want to obtain nomins,
they may pay ether into the pool in order to do so.

The supply of nomins that may be in circulation at any time is limited.
The contract owner may increase this quantity, but only if they provide
ether to back it. The backing the owner provides at issuance must
keep each nomin at least twice overcollateralised.
The owner may also destroy nomins in the pool, which is potential avenue
by which to maintain healthy collateralisation levels, as it reduces
supply without withdrawing ether collateral.

A configurable fee is charged on nomin transfers and deposited
into a common pot, which havven holders may withdraw from once per
fee period.

Ether price is continually updated by an external oracle, and the value
of the backing is computed on this basis. To ensure the integrity of
this system, if the contract&#39;s price has not been updated recently enough,
it will temporarily disable itself until it receives more price information.

The contract owner may at any time initiate contract liquidation.
During the liquidation period, most contract functions will be deactivated.
No new nomins may be issued or bought, but users may sell nomins back
to the system.
If the system&#39;s collateral falls below a specified level, then anyone
may initiate liquidation.

After the liquidation period has elapsed, which is initially 90 days,
the owner may destroy the contract, transferring any remaining collateral
to a nominated beneficiary address.
This liquidation period may be extended up to a maximum of 180 days.
If the contract is recollateralised, the owner may terminate liquidation.

-----------------------------------------------------------------
*/

contract EtherNomin is ExternStateProxyFeeToken {

    /* ========== STATE VARIABLES ========== */

    // The oracle provides price information to this contract.
    // It may only call the updatePrice() function.
    address public oracle;

    // The address of the contract which manages confiscation votes.
    Court public court;

    // Foundation wallet for funds to go to post liquidation.
    address public beneficiary;

    // Nomins in the pool ready to be sold.
    uint public nominPool;

    // Impose a 50 basis-point fee for buying from and selling to the nomin pool.
    uint public poolFeeRate = UNIT / 200;

    // The minimum purchasable quantity of nomins is 1 cent.
    uint constant MINIMUM_PURCHASE = UNIT / 100;

    // When issuing, nomins must be overcollateralised by this ratio.
    uint constant MINIMUM_ISSUANCE_RATIO =  2 * UNIT;

    // If the collateralisation ratio of the contract falls below this level,
    // immediately begin liquidation.
    uint constant AUTO_LIQUIDATION_RATIO = UNIT;

    // The liquidation period is the duration that must pass before the liquidation period is complete.
    // It can be extended up to a given duration.
    uint constant DEFAULT_LIQUIDATION_PERIOD = 90 days;
    uint constant MAX_LIQUIDATION_PERIOD = 180 days;
    uint public liquidationPeriod = DEFAULT_LIQUIDATION_PERIOD;

    // The timestamp when liquidation was activated. We initialise this to
    // uint max, so that we know that we are under liquidation if the
    // liquidation timestamp is in the past.
    uint public liquidationTimestamp = ~uint(0);

    // Ether price from oracle (fiat per ether).
    uint public etherPrice;

    // Last time the price was updated.
    uint public lastPriceUpdate;

    // The period it takes for the price to be considered stale.
    // If the price is stale, functions that require the price are disabled.
    uint public stalePeriod = 2 days;

    // Accounts which have lost the privilege to transact in nomins.
    mapping(address => bool) public frozen;


    /* ========== CONSTRUCTOR ========== */

    function EtherNomin(address _havven, address _oracle,
                        address _beneficiary,
                        uint initialEtherPrice,
                        address _owner, TokenState initialState)
        ExternStateProxyFeeToken("Ether-Backed USD Nomins", "eUSD",
                                 15 * UNIT / 10000, // nomin transfers incur a 15 bp fee
                                 _havven, // the havven contract is the fee authority
                                 initialState,
                                 _owner)
        public
    {
        oracle = _oracle;
        beneficiary = _beneficiary;

        etherPrice = initialEtherPrice;
        lastPriceUpdate = now;
        emit PriceUpdated(etherPrice);

        // It should not be possible to transfer to the nomin contract itself.
        frozen[this] = true;
    }


    /* ========== SETTERS ========== */

    function setOracle(address _oracle)
        external
        optionalProxy_onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    function setCourt(Court _court)
        external
        optionalProxy_onlyOwner
    {
        court = _court;
        emit CourtUpdated(_court);
    }

    function setBeneficiary(address _beneficiary)
        external
        optionalProxy_onlyOwner
    {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    function setPoolFeeRate(uint _poolFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_poolFeeRate <= UNIT);
        poolFeeRate = _poolFeeRate;
        emit PoolFeeRateUpdated(_poolFeeRate);
    }

    function setStalePeriod(uint _stalePeriod)
        external
        optionalProxy_onlyOwner
    {
        stalePeriod = _stalePeriod;
        emit StalePeriodUpdated(_stalePeriod);
    }
 

    /* ========== VIEW FUNCTIONS ========== */ 

    /* Return the equivalent fiat value of the given quantity
     * of ether at the current price.
     * Reverts if the price is stale. */
    function fiatValue(uint eth)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeMul_dec(eth, etherPrice);
    }

    /* Return the current fiat value of the contract&#39;s balance.
     * Reverts if the price is stale. */
    function fiatBalance()
        public
        view
        returns (uint)
    {
        // Price staleness check occurs inside the call to fiatValue.
        return fiatValue(address(this).balance);
    }

    /* Return the equivalent ether value of the given quantity
     * of fiat at the current price.
     * Reverts if the price is stale. */
    function etherValue(uint fiat)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeDiv_dec(fiat, etherPrice);
    }

    /* The same as etherValue(), but without the stale price check. */
    function etherValueAllowStale(uint fiat) 
        internal
        view
        returns (uint)
    {
        return safeDiv_dec(fiat, etherPrice);
    }

    /* Return the units of fiat per nomin in the supply.
     * Reverts if the price is stale. */
    function collateralisationRatio()
        public
        view
        returns (uint)
    {
        return safeDiv_dec(fiatBalance(), _nominCap());
    }

    /* Return the maximum number of extant nomins,
     * equal to the nomin pool plus total (circulating) supply. */
    function _nominCap()
        internal
        view
        returns (uint)
    {
        return safeAdd(nominPool, totalSupply);
    }

    /* Return the fee charged on a purchase or sale of n nomins. */
    function poolFeeIncurred(uint n)
        public
        view
        returns (uint)
    {
        return safeMul_dec(n, poolFeeRate);
    }

    /* Return the fiat cost (including fee) of purchasing n nomins.
     * Nomins are purchased for $1, plus the fee. */
    function purchaseCostFiat(uint n)
        public
        view
        returns (uint)
    {
        return safeAdd(n, poolFeeIncurred(n));
    }

    /* Return the ether cost (including fee) of purchasing n nomins.
     * Reverts if the price is stale. */
    function purchaseCostEther(uint n)
        public
        view
        returns (uint)
    {
        // Price staleness check occurs inside the call to etherValue.
        return etherValue(purchaseCostFiat(n));
    }

    /* Return the fiat proceeds (less the fee) of selling n nomins.
     * Nomins are sold for $1, minus the fee. */
    function saleProceedsFiat(uint n)
        public
        view
        returns (uint)
    {
        return safeSub(n, poolFeeIncurred(n));
    }

    /* Return the ether proceeds (less the fee) of selling n
     * nomins.
     * Reverts if the price is stale. */
    function saleProceedsEther(uint n)
        public
        view
        returns (uint)
    {
        // Price staleness check occurs inside the call to etherValue.
        return etherValue(saleProceedsFiat(n));
    }

    /* The same as saleProceedsEther(), but without the stale price check. */
    function saleProceedsEtherAllowStale(uint n)
        internal
        view
        returns (uint)
    {
        return etherValueAllowStale(saleProceedsFiat(n));
    }

    /* True iff the current block timestamp is later than the time
     * the price was last updated, plus the stale period. */
    function priceIsStale()
        public
        view
        returns (bool)
    {
        return safeAdd(lastPriceUpdate, stalePeriod) < now;
    }

    function isLiquidating()
        public
        view
        returns (bool)
    {
        return liquidationTimestamp <= now;
    }

    /* True if the contract is self-destructible. 
     * This is true if either the complete liquidation period has elapsed,
     * or if all tokens have been returned to the contract and it has been
     * in liquidation for at least a week.
     * Since the contract is only destructible after the liquidationTimestamp,
     * a fortiori canSelfDestruct() implies isLiquidating(). */
    function canSelfDestruct()
        public
        view
        returns (bool)
    {
        // Not being in liquidation implies the timestamp is uint max, so it would roll over.
        // We need to check whether we&#39;re in liquidation first.
        if (isLiquidating()) {
            // These timestamps and durations have values clamped within reasonable values and
            // cannot overflow.
            bool totalPeriodElapsed = liquidationTimestamp + liquidationPeriod < now;
            // Total supply of 0 means all tokens have returned to the pool.
            bool allTokensReturned = (liquidationTimestamp + 1 weeks < now) && (totalSupply == 0);
            return totalPeriodElapsed || allTokensReturned;
        }
        return false;
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /* Override ERC20 transfer function in order to check
     * whether the recipient account is frozen. Note that there is
     * no need to check whether the sender has a frozen account,
     * since their funds have already been confiscated,
     * and no new funds can be transferred to it.*/
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transfer_byProxy(messageSender, to, value);
    }

    /* Override ERC20 transferFrom function in order to check
     * whether the recipient account is frozen. */
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transferFrom_byProxy(messageSender, from, to, value);
    }

    /* Update the current ether price and update the last updated time,
     * refreshing the price staleness.
     * Also checks whether the contract&#39;s collateral levels have fallen to low,
     * and initiates liquidation if that is the case.
     * Exceptional conditions:
     *     Not called by the oracle.
     *     Not the most recently sent price. */
    function updatePrice(uint price, uint timeSent)
        external
        postCheckAutoLiquidate
    {
        // Should be callable only by the oracle.
        require(msg.sender == oracle);
        // Must be the most recently sent price, but not too far in the future.
        // (so we can&#39;t lock ourselves out of updating the oracle for longer than this)
        require(lastPriceUpdate < timeSent && timeSent < now + 10 minutes);

        etherPrice = price;
        lastPriceUpdate = timeSent;
        emit PriceUpdated(price);
    }

    /* Issues n nomins into the pool available to be bought by users.
     * Must be accompanied by $n worth of ether.
     * Exceptional conditions:
     *     Not called by contract owner.
     *     Insufficient backing funds provided (post-issuance collateralisation below minimum requirement).
     *     Price is stale. */
    function replenishPool(uint n)
        external
        payable
        notLiquidating
        optionalProxy_onlyOwner
    {
        // Price staleness check occurs inside the call to fiatBalance.
        // Safe additions are unnecessary here, as either the addition is checked on the following line
        // or the overflow would cause the requirement not to be satisfied.
        require(fiatBalance() >= safeMul_dec(safeAdd(_nominCap(), n), MINIMUM_ISSUANCE_RATIO));
        nominPool = safeAdd(nominPool, n);
        emit PoolReplenished(n, msg.value);
    }

    /* Burns n nomins from the pool.
     * Exceptional conditions:
     *     Not called by contract owner.
     *     There are fewer than n nomins in the pool. */
    function diminishPool(uint n)
        external
        optionalProxy_onlyOwner
    {
        // Require that there are enough nomins in the accessible pool to burn
        require(nominPool >= n);
        nominPool = safeSub(nominPool, n);
        emit PoolDiminished(n);
    }

    /* Sends n nomins to the sender from the pool, in exchange for
     * $n plus the fee worth of ether.
     * Exceptional conditions:
     *     Insufficient or too many funds provided.
     *     More nomins requested than are in the pool.
     *     n below the purchase minimum (1 cent).
     *     contract in liquidation.
     *     Price is stale. */
    function buy(uint n)
        external
        payable
        notLiquidating
        optionalProxy
    {
        // Price staleness check occurs inside the call to purchaseEtherCost.
        require(n >= MINIMUM_PURCHASE &&
                msg.value == purchaseCostEther(n));
        address sender = messageSender;
        // sub requires that nominPool >= n
        nominPool = safeSub(nominPool, n);
        state.setBalanceOf(sender, safeAdd(state.balanceOf(sender), n));
        emit Purchased(sender, sender, n, msg.value);
        emit Transfer(0, sender, n);
        totalSupply = safeAdd(totalSupply, n);
    }

    /* Sends n nomins to the pool from the sender, in exchange for
     * $n minus the fee worth of ether.
     * Exceptional conditions:
     *     Insufficient nomins in sender&#39;s wallet.
     *     Insufficient funds in the pool to pay sender.
     *     Price is stale if not in liquidation. */
    function sell(uint n)
        external
        optionalProxy
    {

        // Price staleness check occurs inside the call to saleProceedsEther,
        // but we allow people to sell their nomins back to the system
        // if we&#39;re in liquidation, regardless.
        uint proceeds;
        if (isLiquidating()) {
            proceeds = saleProceedsEtherAllowStale(n);
        } else {
            proceeds = saleProceedsEther(n);
        }

        require(address(this).balance >= proceeds);

        address sender = messageSender;
        // sub requires that the balance is greater than n
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), n));
        nominPool = safeAdd(nominPool, n);
        emit Sold(sender, sender, n, proceeds);
        emit Transfer(sender, 0, n);
        totalSupply = safeSub(totalSupply, n);
        sender.transfer(proceeds);
    }

    /* Lock nomin purchase function in preparation for destroying the contract.
     * While the contract is under liquidation, users may sell nomins back to the system.
     * After liquidation period has terminated, the contract may be self-destructed,
     * returning all remaining ether to the beneficiary address.
     * Exceptional cases:
     *     Not called by contract owner;
     *     contract already in liquidation; */
    function forceLiquidation()
        external
        notLiquidating
        optionalProxy_onlyOwner
    {
        beginLiquidation();
    }

    function beginLiquidation()
        internal
    {
        liquidationTimestamp = now;
        emit LiquidationBegun(liquidationPeriod);
    }

    /* If the contract is liquidating, the owner may extend the liquidation period.
     * It may only get longer, not shorter, and it may not be extended past
     * the liquidation max. */
    function extendLiquidationPeriod(uint extension)
        external
        optionalProxy_onlyOwner
    {
        require(isLiquidating());
        uint sum = safeAdd(liquidationPeriod, extension);
        require(sum <= MAX_LIQUIDATION_PERIOD);
        liquidationPeriod = sum;
        emit LiquidationExtended(extension);
    }

    /* Liquidation can only be stopped if the collateralisation ratio
     * of this contract has recovered above the automatic liquidation
     * threshold, for example if the ether price has increased,
     * or by including enough ether in this transaction. */
    function terminateLiquidation()
        external
        payable
        priceNotStale
        optionalProxy_onlyOwner
    {
        require(isLiquidating());
        require(_nominCap() == 0 || collateralisationRatio() >= AUTO_LIQUIDATION_RATIO);
        liquidationTimestamp = ~uint(0);
        liquidationPeriod = DEFAULT_LIQUIDATION_PERIOD;
        emit LiquidationTerminated();
    }

    /* The owner may destroy this contract, returning all funds back to the beneficiary
     * wallet, may only be called after the contract has been in
     * liquidation for at least liquidationPeriod, or all circulating
     * nomins have been sold back into the pool. */
    function selfDestruct()
        external
        optionalProxy_onlyOwner
    {
        require(canSelfDestruct());
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    /* If a confiscation court motion has passed and reached the confirmation
     * state, the court may transfer the target account&#39;s balance to the fee pool
     * and freeze its participation in further transactions. */
    function confiscateBalance(address target)
        external
    {
        // Should be callable only by the confiscation court.
        require(Court(msg.sender) == court);
        
        // A motion must actually be underway.
        uint motionID = court.targetMotionID(target);
        require(motionID != 0);

        // These checks are strictly unnecessary,
        // since they are already checked in the court contract itself.
        // I leave them in out of paranoia.
        require(court.motionConfirming(motionID));
        require(court.motionPasses(motionID));
        require(!frozen[target]);

        // Confiscate the balance in the account and freeze it.
        uint balance = state.balanceOf(target);
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), balance));
        state.setBalanceOf(target, 0);
        frozen[target] = true;
        emit AccountFrozen(target, target, balance);
        emit Transfer(target, address(this), balance);
    }

    /* The owner may allow a previously-frozen contract to once
     * again accept and transfer nomins. */
    function unfreezeAccount(address target)
        external
        optionalProxy_onlyOwner
    {
        if (frozen[target] && EtherNomin(target) != this) {
            frozen[target] = false;
            emit AccountUnfrozen(target, target);
        }
    }

    /* Fallback function allows convenient collateralisation of the contract,
     * including by non-foundation parties. */
    function() public payable {}


    /* ========== MODIFIERS ========== */

    modifier notLiquidating
    {
        require(!isLiquidating());
        _;
    }

    modifier priceNotStale
    {
        require(!priceIsStale());
        _;
    }

    /* Any function modified by this will automatically liquidate
     * the system if the collateral levels are too low.
     * This is called on collateral-value/nomin-supply modifying functions that can
     * actually move the contract into liquidation. This is really only
     * the price update, since issuance requires that the contract is overcollateralised,
     * burning can only destroy tokens without withdrawing backing, buying from the pool can only
     * asymptote to a collateralisation level of unity, while selling into the pool can only 
     * increase the collateralisation ratio.
     * Additionally, price update checks should/will occur frequently. */
    modifier postCheckAutoLiquidate
    {
        _;
        if (!isLiquidating() && _nominCap() != 0 && collateralisationRatio() < AUTO_LIQUIDATION_RATIO) {
            beginLiquidation();
        }
    }


    /* ========== EVENTS ========== */

    event PoolReplenished(uint nominsCreated, uint collateralDeposited);

    event PoolDiminished(uint nominsDestroyed);

    event Purchased(address buyer, address indexed buyerIndex, uint nomins, uint eth);

    event Sold(address seller, address indexed sellerIndex, uint nomins, uint eth);

    event PriceUpdated(uint newPrice);

    event StalePeriodUpdated(uint newPeriod);

    event OracleUpdated(address newOracle);

    event CourtUpdated(address newCourt);

    event BeneficiaryUpdated(address newBeneficiary);

    event LiquidationBegun(uint duration);

    event LiquidationTerminated();

    event LiquidationExtended(uint extension);

    event PoolFeeRateUpdated(uint newFeeRate);

    event SelfDestructed(address beneficiary);

    event AccountFrozen(address target, address indexed targetIndex, uint balance);

    event AccountUnfrozen(address target, address indexed targetIndex);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A token interface to be overridden to produce an ERC20-compliant
token contract. It relies on being called underneath a proxy,
as described in Proxy.sol.

This contract utilises a state for upgradability purposes.

-----------------------------------------------------------------
*/

contract ExternStateProxyToken is SafeDecimalMath, Proxyable {

    /* ========== STATE VARIABLES ========== */

    // Stores balances and allowances.
    TokenState public state;

    // Other ERC20 fields
    string public name;
    string public symbol;
    uint public totalSupply;


    /* ========== CONSTRUCTOR ========== */

    function ExternStateProxyToken(string _name, string _symbol,
                                   uint initialSupply, address initialBeneficiary,
                                   TokenState _state, address _owner)
        Proxyable(_owner)
        public
    {
        name = _name;
        symbol = _symbol;
        totalSupply = initialSupply;

        // if the state isn&#39;t set, create a new one
        if (_state == TokenState(0)) {
            state = new TokenState(_owner, address(this));
            state.setBalanceOf(initialBeneficiary, totalSupply);
            emit Transfer(address(0), initialBeneficiary, initialSupply);
        } else {
            state = _state;
        }
   }

    /* ========== VIEWS ========== */

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint)
    {
        return state.allowance(tokenOwner, spender);
    }

    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return state.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setState(TokenState _state)
        external
        optionalProxy_onlyOwner
    {
        state = _state;
        emit StateUpdated(_state);
    } 

    /* Anything calling this must apply the onlyProxy or optionalProxy modifiers.*/
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

        // Insufficient balance will be handled by the safe subtraction.
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), value));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));

        emit Transfer(sender, to, value);

        return true;
    }

    /* Anything calling this must apply the onlyProxy or optionalProxy modifiers.*/
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        require(from != address(0) && to != address(0));

        // Insufficient balance will be handled by the safe subtraction.
        state.setBalanceOf(from, safeSub(state.balanceOf(from), value));
        state.setAllowance(from, sender, safeSub(state.allowance(from, sender), value));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        state.setAllowance(sender, spender, value);
        emit Approval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event StateUpdated(address newState);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

This contract allows the foundation to apply unique vesting
schedules to havven funds sold at various discounts in the token
sale. HavvenEscrow gives users the ability to inspect their
vested funds, their quantities and vesting dates, and to withdraw
the fees that accrue on those funds.

The fees are handled by withdrawing the entire fee allocation
for all havvens inside the escrow contract, and then allowing
the contract itself to subdivide that pool up proportionally within
itself. Every time the fee period rolls over in the main Havven
contract, the HavvenEscrow fee pool is remitted back into the 
main fee pool to be redistributed in the next fee period.

-----------------------------------------------------------------

*/

contract HavvenEscrow is Owned, LimitedSetup(8 weeks), SafeDecimalMath {    
    // The corresponding Havven contract.
    Havven public havven;

    // Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
    // These are the times at which each given quantity of havvens vests.
    mapping(address => uint[2][]) public vestingSchedules;

    // An account&#39;s total vested havven balance to save recomputing this for fee extraction purposes.
    mapping(address => uint) public totalVestedAccountBalance;

    // The total remaining vested balance, for verifying the actual havven balance of this contract against.
    uint public totalVestedBalance;


    /* ========== CONSTRUCTOR ========== */

    function HavvenEscrow(address _owner, Havven _havven)
        Owned(_owner)
        public
    {
        havven = _havven;
    }


    /* ========== SETTERS ========== */

    function setHavven(Havven _havven)
        external
        onlyOwner
    {
        havven = _havven;
        emit HavvenUpdated(_havven);
    }


    /* ========== VIEW FUNCTIONS ========== */

    /* A simple alias to totalVestedAccountBalance: provides ERC20 balance integration. */
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return totalVestedAccountBalance[account];
    }

    /* The number of vesting dates in an account&#39;s schedule. */
    function numVestingEntries(address account)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account].length;
    }

    /* Get a particular schedule entry for an account.
     * The return value is a pair (timestamp, havven quantity) */
    function getVestingScheduleEntry(address account, uint index)
        public
        view
        returns (uint[2])
    {
        return vestingSchedules[account][index];
    }

    /* Get the time at which a given schedule entry will vest. */
    function getVestingTime(address account, uint index)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account][index][0];
    }

    /* Get the quantity of havvens associated with a given schedule entry. */
    function getVestingQuantity(address account, uint index)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account][index][1];
    }

    /* Obtain the index of the next schedule entry that will vest for a given user. */
    function getNextVestingIndex(address account)
        public
        view
        returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

    /* Obtain the next schedule entry that will vest for a given user.
     * The return value is a pair (timestamp, havven quantity) */
    function getNextVestingEntry(address account)
        external
        view
        returns (uint[2])
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

    /* Obtain the time at which the next schedule entry will vest for a given user. */
    function getNextVestingTime(address account)
        external
        view
        returns (uint)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return 0;
        }
        return getVestingTime(account, index);
    }

    /* Obtain the quantity which the next schedule entry will vest for a given user. */
    function getNextVestingQuantity(address account)
        external
        view
        returns (uint)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return 0;
        }
        return getVestingQuantity(account, index);
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /* Withdraws a quantity of havvens back to the havven contract. */
    function withdrawHavvens(uint quantity)
        external
        onlyOwner
        setupFunction
    {
        havven.transfer(havven, quantity);
    }

    /* Destroy the vesting information associated with an account. */
    function purgeAccount(address account)
        external
        onlyOwner
        setupFunction
    {
        delete vestingSchedules[account];
        totalVestedBalance = safeSub(totalVestedBalance, totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }

    /* Add a new vesting entry at a given time and quantity to an account&#39;s schedule.
     * A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to havven.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it&#39;s only in the foundation&#39;s command to add to these lists. */
    function appendVestingEntry(address account, uint time, uint quantity)
        public
        onlyOwner
        setupFunction
    {
        // No empty or already-passed vesting entries allowed.
        require(now < time);
        require(quantity != 0);
        totalVestedBalance = safeAdd(totalVestedBalance, quantity);
        require(totalVestedBalance <= havven.balanceOf(this));

        if (vestingSchedules[account].length == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
            // Disallow adding new vested havvens earlier than the last one.
            // Since entries are only appended, this means that no vesting date can be repeated.
            require(getVestingTime(account, numVestingEntries(account) - 1) < time);
            totalVestedAccountBalance[account] = safeAdd(totalVestedAccountBalance[account], quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

    /* Construct a vesting schedule to release a quantities of havvens
     * over a series of intervals. Assumes that the quantities are nonzero
     * and that the sequence of timestamps is strictly increasing. */
    function addVestingSchedule(address account, uint[] times, uint[] quantities)
        external
        onlyOwner
        setupFunction
    {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }

    }

    /* Allow a user to withdraw any tokens that have vested. */
    function vest() 
        external
    {
        uint total;
        for (uint i = 0; i < numVestingEntries(msg.sender); i++) {
            uint time = getVestingTime(msg.sender, i);
            // The list is sorted; when we reach the first future time, bail out.
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[msg.sender][i] = [0, 0];
            total = safeAdd(total, qty);
            totalVestedAccountBalance[msg.sender] = safeSub(totalVestedAccountBalance[msg.sender], qty);
        }

        if (total != 0) {
            totalVestedBalance = safeSub(totalVestedBalance, total);
            havven.transfer(msg.sender, total);
            emit Vested(msg.sender, msg.sender,
                   now, total);
        }
    }


    /* ========== EVENTS ========== */

    event HavvenUpdated(address newHavven);

    event Vested(address beneficiary, address indexed beneficiaryIndex, uint time, uint value);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

This contract allows an inheriting contract to be destroyed after
its owner indicates an intention and then waits for a period
without changing their mind.

-----------------------------------------------------------------
*/

contract SelfDestructible is Owned {
	
	uint public initiationTime = ~uint(0);
	uint constant SD_DURATION = 3 days;
	address public beneficiary;

	function SelfDestructible(address _owner, address _beneficiary)
		public
		Owned(_owner)
	{
		beneficiary = _beneficiary;
	}

	function setBeneficiary(address _beneficiary)
		external
		onlyOwner
	{
		beneficiary = _beneficiary;
		emit SelfDestructBeneficiaryUpdated(_beneficiary);
	}

	function initiateSelfDestruct()
		external
		onlyOwner
	{
		initiationTime = now;
		emit SelfDestructInitiated(SD_DURATION);
	}

	function terminateSelfDestruct()
		external
		onlyOwner
	{
		initiationTime = ~uint(0);
		emit SelfDestructTerminated();
	}

	function selfDestruct()
		external
		onlyOwner
	{
		require(initiationTime + SD_DURATION < now);
		emit SelfDestructed(beneficiary);
		selfdestruct(beneficiary);
	}

	event SelfDestructBeneficiaryUpdated(address newBeneficiary);

	event SelfDestructInitiated(uint duration);

	event SelfDestructTerminated();

	event SelfDestructed(address beneficiary);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

Havven token contract. Havvens are transferable ERC20 tokens,
and also give their holders the following privileges.
An owner of havvens is entitled to a share in the fees levied on
nomin transactions, and additionally may participate in nomin
confiscation votes.

After a fee period terminates, the duration and fees collected for that
period are computed, and the next period begins.
Thus an account may only withdraw the fees owed to them for the previous
period, and may only do so once per period.
Any unclaimed fees roll over into the common pot for the next period.

The fee entitlement of a havven holder is proportional to their average
havven balance over the last fee period. This is computed by measuring the
area under the graph of a user&#39;s balance over time, and then when fees are
distributed, dividing through by the duration of the fee period.

We need only update fee entitlement on transfer when the havven balances of the sender
and recipient are modified. This is for efficiency, and adds an implicit friction to
trading in the havven market. A havven holder pays for his own recomputation whenever
he wants to change his position, which saves the foundation having to maintain a pot
dedicated to resourcing this.

A hypothetical user&#39;s balance history over one fee period, pictorially:

      s ____
       |    |
       |    |___ p
       |____|___|___ __ _  _
       f    t   n

Here, the balance was s between times f and t, at which time a transfer
occurred, updating the balance to p, until n, when the present transfer occurs.
When a new transfer occurs at time n, the balance being p,
we must:

  - Add the area p * (n - t) to the total area recorded so far
  - Update the last transfer time to p

So if this graph represents the entire current fee period,
the average havvens held so far is ((t-f)*s + (n-t)*p) / (n-f).
The complementary computations must be performed for both sender and
recipient.

Note that a transfer keeps global supply of havvens invariant.
The sum of all balances is constant, and unmodified by any transfer.
So the sum of all balances multiplied by the duration of a fee period is also
constant, and this is equivalent to the sum of the area of every user&#39;s
time/balance graph. Dividing through by that duration yields back the total
havven supply. So, at the end of a fee period, we really do yield a user&#39;s
average share in the havven supply over that period.

A slight wrinkle is introduced if we consider the time r when the fee period
rolls over. Then the previous fee period k-1 is before r, and the current fee
period k is afterwards. If the last transfer took place before r,
but the latest transfer occurred afterwards:

k-1       |        k
      s __|_
       |  | |
       |  | |____ p
       |__|_|____|___ __ _  _
          |
       f  | t    n
          r

In this situation the area (r-f)*s contributes to fee period k-1, while
the area (t-r)*s contributes to fee period k. We will implicitly consider a
zero-value transfer to have occurred at time r. Their fee entitlement for the
previous period will be finalised at the time of their first transfer during the
current fee period, or when they query or withdraw their fee entitlement.

In the implementation, the duration of different fee periods may be slightly irregular,
as the check that they have rolled over occurs only when state-changing havven
operations are performed.

Additionally, we keep track also of the penultimate and not just the last
average balance, in order to support the voting functionality detailed in Court.sol.

-----------------------------------------------------------------

*/

contract Havven is ExternStateProxyToken, SelfDestructible {

    /* ========== STATE VARIABLES ========== */

    // Sums of balances*duration in the current fee period.
    // range: decimals; units: havven-seconds
    mapping(address => uint) public currentBalanceSum;

    // Average account balances in the last completed fee period. This is proportional
    // to that account&#39;s last period fee entitlement.
    // (i.e. currentBalanceSum for the previous period divided through by duration)
    // WARNING: This may not have been updated for the latest fee period at the
    //          time it is queried.
    // range: decimals; units: havvens
    mapping(address => uint) public lastAverageBalance;

    // The average account balances in the period before the last completed fee period.
    // This is used as a person&#39;s weight in a confiscation vote, so it implies that
    // the vote duration must be no longer than the fee period in order to guarantee that 
    // no portion of a fee period used for determining vote weights falls within the
    // duration of a vote it contributes to.
    // WARNING: This may not have been updated for the latest fee period at the
    //          time it is queried.
    mapping(address => uint) public penultimateAverageBalance;

    // The time an account last made a transfer.
    // range: naturals
    mapping(address => uint) public lastTransferTimestamp;

    // The time the current fee period began.
    uint public feePeriodStartTime = 3;
    // The actual start of the last fee period (seconds).
    // This, and the penultimate fee period can be initially set to any value
    //   0 < val < now, as everyone&#39;s individual lastTransferTime will be 0
    //   and as such, their lastAvgBal/penultimateAvgBal will be set to that value
    //   apart from the contract, which will have totalSupply
    uint public lastFeePeriodStartTime = 2;
    // The actual start of the penultimate fee period (seconds).
    uint public penultimateFeePeriodStartTime = 1;

    // Fee periods will roll over in no shorter a time than this.
    uint public targetFeePeriodDurationSeconds = 4 weeks;
    // And may not be set to be shorter than a day.
    uint constant MIN_FEE_PERIOD_DURATION_SECONDS = 1 days;
    // And may not be set to be longer than six months.
    uint constant MAX_FEE_PERIOD_DURATION_SECONDS = 26 weeks;

    // The quantity of nomins that were in the fee pot at the time
    // of the last fee rollover (feePeriodStartTime).
    uint public lastFeesCollected;

    mapping(address => bool) public hasWithdrawnLastPeriodFees;

    EtherNomin public nomin;
    HavvenEscrow public escrow;


    /* ========== CONSTRUCTOR ========== */

    function Havven(TokenState initialState, address _owner)
        ExternStateProxyToken("Havven", "HAV", 1e8 * UNIT, address(this), initialState, _owner)
        SelfDestructible(_owner, _owner)
        // Owned is initialised in ExternStateProxyToken
        public
    {
        lastTransferTimestamp[this] = now;
        feePeriodStartTime = now;
        lastFeePeriodStartTime = now - targetFeePeriodDurationSeconds;
        penultimateFeePeriodStartTime = now - 2*targetFeePeriodDurationSeconds;
    }


    /* ========== SETTERS ========== */

    function setNomin(EtherNomin _nomin) 
        external
        optionalProxy_onlyOwner
    {
        nomin = _nomin;
    }

    function setEscrow(HavvenEscrow _escrow)
        external
        optionalProxy_onlyOwner
    {
        escrow = _escrow;
    }

    function setTargetFeePeriodDuration(uint duration)
        external
        postCheckFeePeriodRollover
        optionalProxy_onlyOwner
    {
        require(MIN_FEE_PERIOD_DURATION_SECONDS <= duration &&
                duration <= MAX_FEE_PERIOD_DURATION_SECONDS);
        targetFeePeriodDurationSeconds = duration;
        emit FeePeriodDurationUpdated(duration);
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /* Allow the owner of this contract to endow any address with havvens
     * from the initial supply. Since the entire initial supply resides
     * in the havven contract, this disallows the foundation from withdrawing
     * fees on undistributed balances. This function can also be used
     * to retrieve any havvens sent to the Havven contract itself. */
    function endow(address account, uint value)
        external
        optionalProxy_onlyOwner
        returns (bool)
    {

        // Use "this" in order that the havven account is the sender.
        // That this is an explicit transfer also initialises fee entitlement information.
        return _transfer(this, account, value);
    }

    /* Allow the owner of this contract to emit transfer events for
     * contract setup purposes. */
    function emitTransferEvents(address sender, address[] recipients, uint[] values)
        external
        onlyOwner
    {
        for (uint i = 0; i < recipients.length; ++i) {
            emit Transfer(sender, recipients[i], values[i]);
        }
    }

    /* Override ERC20 transfer function in order to perform
     * fee entitlement recomputation whenever balances are updated. */
    function transfer(address to, uint value)
        external
        optionalProxy
        returns (bool)
    {
        return _transfer(messageSender, to, value);
    }

    /* Anything calling this must apply the optionalProxy or onlyProxy modifier. */
    function _transfer(address sender, address to, uint value)
        internal
        preCheckFeePeriodRollover
        returns (bool)
    {

        uint senderPreBalance = state.balanceOf(sender);
        uint recipientPreBalance = state.balanceOf(to);

        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        _transfer_byProxy(sender, to, value);

        // Zero-value transfers still update fee entitlement information,
        // and may roll over the fee period.
        adjustFeeEntitlement(sender, senderPreBalance);
        adjustFeeEntitlement(to, recipientPreBalance);

        return true;
    }

    /* Override ERC20 transferFrom function in order to perform
     * fee entitlement recomputation whenever balances are updated. */
    function transferFrom(address from, address to, uint value)
        external
        preCheckFeePeriodRollover
        optionalProxy
        returns (bool)
    {
        uint senderPreBalance = state.balanceOf(from);
        uint recipientPreBalance = state.balanceOf(to);

        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        _transferFrom_byProxy(messageSender, from, to, value);

        // Zero-value transfers still update fee entitlement information,
        // and may roll over the fee period.
        adjustFeeEntitlement(from, senderPreBalance);
        adjustFeeEntitlement(to, recipientPreBalance);

        return true;
    }

    /* Compute the last period&#39;s fee entitlement for the message sender
     * and then deposit it into their nomin account. */
    function withdrawFeeEntitlement()
        public
        preCheckFeePeriodRollover
        optionalProxy
    {
        address sender = messageSender;

        // Do not deposit fees into frozen accounts.
        require(!nomin.frozen(sender));

        // check the period has rolled over first
        rolloverFee(sender, lastTransferTimestamp[sender], state.balanceOf(sender));

        // Only allow accounts to withdraw fees once per period.
        require(!hasWithdrawnLastPeriodFees[sender]);

        uint feesOwed;

        if (escrow != HavvenEscrow(0)) {
            feesOwed = escrow.totalVestedAccountBalance(sender);
        }

        feesOwed = safeDiv_dec(safeMul_dec(safeAdd(feesOwed, lastAverageBalance[sender]),
                                           lastFeesCollected),
                               totalSupply);

        hasWithdrawnLastPeriodFees[sender] = true;
        if (feesOwed != 0) {
            nomin.withdrawFee(sender, feesOwed);
            emit FeesWithdrawn(sender, sender, feesOwed);
        }
    }

    /* Update the fee entitlement since the last transfer or entitlement
     * adjustment. Since this updates the last transfer timestamp, if invoked
     * consecutively, this function will do nothing after the first call. */
    function adjustFeeEntitlement(address account, uint preBalance)
        internal
    {
        // The time since the last transfer clamps at the last fee rollover time if the last transfer
        // was earlier than that.
        rolloverFee(account, lastTransferTimestamp[account], preBalance);

        currentBalanceSum[account] = safeAdd(
            currentBalanceSum[account],
            safeMul(preBalance, now - lastTransferTimestamp[account])
        );

        // Update the last time this user&#39;s balance changed.
        lastTransferTimestamp[account] = now;
    }

    /* Update the given account&#39;s previous period fee entitlement value.
     * Do nothing if the last transfer occurred since the fee period rolled over.
     * If the entitlement was updated, also update the last transfer time to be
     * at the timestamp of the rollover, so if this should do nothing if called more
     * than once during a given period.
     *
     * Consider the case where the entitlement is updated. If the last transfer
     * occurred at time t in the last period, then the starred region is added to the
     * entitlement, the last transfer timestamp is moved to r, and the fee period is
     * rolled over from k-1 to k so that the new fee period start time is at time r.
     * 
     *   k-1       |        k
     *         s __|
     *  _  _ ___|**|
     *          |**|
     *  _  _ ___|**|___ __ _  _
     *             |
     *          t  |
     *             r
     * 
     * Similar computations are performed according to the fee period in which the
     * last transfer occurred.
     */
    function rolloverFee(address account, uint lastTransferTime, uint preBalance)
        internal
    {
        if (lastTransferTime < feePeriodStartTime) {
            if (lastTransferTime < lastFeePeriodStartTime) {
                // The last transfer predated the previous two fee periods.
                if (lastTransferTime < penultimateFeePeriodStartTime) {
                    // The balance did nothing in the penultimate fee period, so the average balance
                    // in this period is their pre-transfer balance.
                    penultimateAverageBalance[account] = preBalance;
                // The last transfer occurred within the one-before-the-last fee period.
                } else {
                    // No overflow risk here: the failed guard implies (penultimateFeePeriodStartTime <= lastTransferTime).
                    penultimateAverageBalance[account] = safeDiv(
                        safeAdd(currentBalanceSum[account], safeMul(preBalance, (lastFeePeriodStartTime - lastTransferTime))),
                        (lastFeePeriodStartTime - penultimateFeePeriodStartTime)
                    );
                }

                // The balance did nothing in the last fee period, so the average balance
                // in this period is their pre-transfer balance.
                lastAverageBalance[account] = preBalance;

            // The last transfer occurred within the last fee period.
            } else {
                // The previously-last average balance becomes the penultimate balance.
                penultimateAverageBalance[account] = lastAverageBalance[account];

                // No overflow risk here: the failed guard implies (lastFeePeriodStartTime <= lastTransferTime).
                lastAverageBalance[account] = safeDiv(
                    safeAdd(currentBalanceSum[account], safeMul(preBalance, (feePeriodStartTime - lastTransferTime))),
                    (feePeriodStartTime - lastFeePeriodStartTime)
                );
            }

            // Roll over to the next fee period.
            currentBalanceSum[account] = 0;
            hasWithdrawnLastPeriodFees[account] = false;
            lastTransferTimestamp[account] = feePeriodStartTime;
        }
    }

    /* Recompute and return the given account&#39;s average balance information.
     * This also rolls over the fee period if necessary, and brings
     * the account&#39;s current balance sum up to date. */
    function _recomputeAccountLastAverageBalance(address account)
        internal
        preCheckFeePeriodRollover
        returns (uint)
    {
        adjustFeeEntitlement(account, state.balanceOf(account));
        return lastAverageBalance[account];
    }

    /* Recompute and return the sender&#39;s average balance information. */
    function recomputeLastAverageBalance()
        external
        optionalProxy
        returns (uint)
    {
        return _recomputeAccountLastAverageBalance(messageSender);
    }

    /* Recompute and return the given account&#39;s average balance information. */
    function recomputeAccountLastAverageBalance(address account)
        external
        returns (uint)
    {
        return _recomputeAccountLastAverageBalance(account);
    }

    function rolloverFeePeriod()
        public
    {
        checkFeePeriodRollover();
    }


    /* ========== MODIFIERS ========== */

    /* If the fee period has rolled over, then
     * save the start times of the last fee period,
     * as well as the penultimate fee period.
     */
    function checkFeePeriodRollover()
        internal
    {
        // If the fee period has rolled over...
        if (feePeriodStartTime + targetFeePeriodDurationSeconds <= now) {
            lastFeesCollected = nomin.feePool();

            // Shift the three period start times back one place
            penultimateFeePeriodStartTime = lastFeePeriodStartTime;
            lastFeePeriodStartTime = feePeriodStartTime;
            feePeriodStartTime = now;
            
            emit FeePeriodRollover(now);
        }
    }

    modifier postCheckFeePeriodRollover
    {
        _;
        checkFeePeriodRollover();
    }

    modifier preCheckFeePeriodRollover
    {
        checkFeePeriodRollover();
        _;
    }


    /* ========== EVENTS ========== */

    event FeePeriodRollover(uint timestamp);

    event FeePeriodDurationUpdated(uint duration);

    event FeesWithdrawn(address account, address indexed accountIndex, uint value);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A contract that holds the state of an ERC20 compliant token.

This contract is used side by side with external state token
contracts, such as Havven and EtherNomin.
It provides an easy way to upgrade contract logic while
maintaining all user balances and allowances. This is designed
to to make the changeover as easy as possible, since mappings
are not so cheap or straightforward to migrate.

The first deployed contract would create this state contract,
using it as its store of balances.
When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/

contract TokenState is Owned {

    // the address of the contract that can modify balances and allowances
    // this can only be changed by the owner of this contract
    address public associatedContract;

    // ERC20 fields.
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function TokenState(address _owner, address _associatedContract)
        Owned(_owner)
        public
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }

    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }


    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract);
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address _associatedContract);
}

/*
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/