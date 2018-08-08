pragma solidity ^0.4.23;

/*
 * Contract accepting reservations for ATS tokens.
 * The actual tokens are not yet created and distributed due to non-technical reasons.
 * This contract is used to collect funds for the ATS token sale and to transparently document that on a blockchain.
 * It is tailored to allow a simple user journey while keeping complexity minimal.
 * Once the privileged "state controller" sets the state to "Open", anybody can send Ether to the contract.
 * Only Ether sent from whitelisted addresses is accepted for future ATS token conversion.
 * The whitelisting is done by a dedicated whitelist controller.
 * Whitelisting can take place asynchronously - that is, participants don&#39;t need to wait for the whitelisting to
 * succeed before sending funds. This is a technical detail which allows for a smoother user journey.
 * The state controller can switch to synchronous whitelisting (no Ether accepted from accounts not whitelisted before).
 * Participants can trigger refunding during the Open state by making a transfer of 0 Ether.
 * Funds of those not whitelisted (not accepted) are never locked, they can trigger refund beyond Open state.
 * Only in Over state can whitelisted Ether deposits be fetched from the contract.
 *
 * When setting the state to Open, the state controller specifies a minimal timeframe for this state.
 * Transition to the next state (Locked) is not possible (enforced by the contract).
 * This gives participants the guarantee that they can get their full deposits refunded anytime and independently
 * of the will of anybody else during that timeframe.
 * (Note that this is true only as long as the whole process takes place before the date specified by FALLBACK_FETCH_FUNDS_TS)
 *
 * Ideally, there&#39;s no funds left in the contract once the state is set to Over and the accepted deposits were fetched.
 * Since this can&#39;t really be foreseen, there&#39;s a fallback which allows to fetch all remaining Ether
 * to a pre-specified address after a pre-specified date.
 *
 * Static analysis: block.timestamp is not used in a way which gives miners leeway for taking advantage.
 *
 * see https://code.lab10.io/graz/04-artis/artis/issues/364 for task evolution
 */
contract ATSTokenReservation {

    // ################### DATA STRUCTURES ###################

    enum States {
        Init, // initial state. Contract is deployed, but deposits not yet accepted
        Open, // open for token reservations. Refunds possible for all
        Locked, // open for token reservations. Refunds locked for accepted deposits
        Over // contract has done its duty. Funds payout can be triggered by state controller
    }

    // ################### CONSTANTS ###################

    // 1. Oct 2018
    uint32 FALLBACK_PAYOUT_TS = 1538352000;

    // ################### STATE VARIABLES ###################

    States public state = States.Init;

    // privileged account: switch contract state, change config, whitelisting, trigger payout, ...
    address public stateController;

    // privileged account: whitelisting
    address public whitelistController;

    // Collected funds can be transferred only to this address. Is set in constructor.
    address public payoutAddress;

    // accepted deposits (received from whitelisted accounts)
    uint256 public cumAcceptedDeposits = 0;
    // not (yet) accepted deposits (received from non-whitelisted accounts)
    uint256 public cumAlienDeposits = 0;

    // cap for how much we accept (since the amount of tokens sold is also capped)
    uint256 public maxCumAcceptedDeposits = 1E9 * 1E18; // pre-set to effectively unlimited (> existing ETH)

    uint256 public minDeposit = 0.1 * 1E18; // lower bound per participant (can be a kind of spam protection)

    uint256 minLockingTs; // earliest possible start of "locked" phase

    // whitelisted addresses (those having "accepted" deposits)
    mapping (address => bool) public whitelist;

    // the state controller can set this in order to disallow deposits from addresses not whitelisted before
    bool public requireWhitelistingBeforeDeposit = false;

    // tracks accepted deposits (whitelisted accounts)
    mapping (address => uint256) public acceptedDeposits;

    // tracks alien (not yet accepted) deposits (non-whitelisted accounts)
    mapping (address => uint256) public alienDeposits;

    // ################### EVENTS ###################

    // emitted events transparently document the open funding activities.
    // only deposits made by whitelisted accounts (and not followed by a refund) count.

    event StateTransition(States oldState, States newState);
    event Whitelisted(address addr);
    event Deposit(address addr, uint256 amount);
    event Refund(address addr, uint256 amount);

    // emitted when the accepted deposits are fetched to an account controlled by the ATS token provider
    event FetchedDeposits(uint256 amount);

    // ################### MODIFIERS ###################

    modifier onlyStateControl() { require(msg.sender == stateController, "no permission"); _; }

    modifier onlyWhitelistControl()	{
        require(msg.sender == stateController || msg.sender == whitelistController, "no permission");
        _;
    }

    modifier requireState(States _requiredState) { require(state == _requiredState, "wrong state"); _; }

    // ################### CONSTRUCTOR ###################

    // the contract creator is set as stateController
    constructor(address _whitelistController, address _payoutAddress) public {
        whitelistController = _whitelistController;
        payoutAddress = _payoutAddress;
        stateController = msg.sender;
    }

    // ################### FALLBACK FUNCTION ###################

    // implements the deposit and refund actions.
    function () payable public {
        if(msg.value > 0) {
            require(state == States.Open || state == States.Locked);
            if(requireWhitelistingBeforeDeposit) {
                require(whitelist[msg.sender] == true, "not whitelisted");
            }
            tryDeposit();
        } else {
            tryRefund();
        }
    }

    // ################### PUBLIC FUNCTIONS ###################

    function stateSetOpen(uint32 _minLockingTs) public
        onlyStateControl
        requireState(States.Init)
    {
        minLockingTs = _minLockingTs;
        setState(States.Open);
    }

    function stateSetLocked() public
        onlyStateControl
        requireState(States.Open)
    {
        require(block.timestamp >= minLockingTs);
        setState(States.Locked);
    }

    function stateSetOver() public
        onlyStateControl
        requireState(States.Locked)
    {
        setState(States.Over);
    }

    // state controller can change the cap. Reducing possible only if not below current deposits
    function updateMaxAcceptedDeposits(uint256 _newMaxDeposits) public onlyStateControl {
        require(cumAcceptedDeposits <= _newMaxDeposits);
        maxCumAcceptedDeposits = _newMaxDeposits;
    }

    // new limit to be enforced for future deposits
    function updateMinDeposit(uint256 _newMinDeposit) public onlyStateControl {
        minDeposit = _newMinDeposit;
    }

    // option to switch between async and sync whitelisting
    function setRequireWhitelistingBeforeDeposit(bool _newState) public onlyStateControl {
        requireWhitelistingBeforeDeposit = _newState;
    }

    // Since whitelisting can occur asynchronously, an account to be whitelisted may already have deposited Ether.
    // In this case the deposit is converted form alien to accepted.
    // Since the deposit logic depends on the whitelisting status and since transactions are processed sequentially,
    // it&#39;s ensured that at any time an account can have either (XOR) no or alien or accepted deposits and that
    // the whitelisting status corresponds to the deposit status (not_whitelisted <-> alien | whitelisted <-> accepted).
    // This function is idempotent.
    function addToWhitelist(address _addr) public onlyWhitelistControl {
        if(whitelist[_addr] != true) {
            // if address has alien deposit: convert it to accepted
            if(alienDeposits[_addr] > 0) {
                cumAcceptedDeposits += alienDeposits[_addr];
                acceptedDeposits[_addr] += alienDeposits[_addr];
                cumAlienDeposits -= alienDeposits[_addr];
                delete alienDeposits[_addr]; // needs to be the last statement in this block!
            }
            whitelist[_addr] = true;
            emit Whitelisted(_addr);
        }
    }

    // Option for batched whitelisting (for times with crowded chain).
    // caller is responsible to not blow gas limit with too many addresses at once
    function batchAddToWhitelist(address[] _addresses) public onlyWhitelistControl {
        for (uint i = 0; i < _addresses.length; i++) {
            addToWhitelist(_addresses[i]);
        }
    }


    // transfers an alien deposit back to the sender
    function refundAlienDeposit(address _addr) public onlyWhitelistControl {
        // Note: this implementation requires that alienDeposits has a primitive value type.
        // With a complex type, this code would produce a dangling reference.
        uint256 withdrawAmount = alienDeposits[_addr];
        require(withdrawAmount > 0);
        delete alienDeposits[_addr]; // implies setting the value to 0
        cumAlienDeposits -= withdrawAmount;
        emit Refund(_addr, withdrawAmount);
        _addr.transfer(withdrawAmount); // throws on failure
    }

    // payout of the accepted deposits to the pre-designated address, available once it&#39;s all over
    function payout() public
        onlyStateControl
        requireState(States.Over)
    {
        uint256 amount = cumAcceptedDeposits;
        cumAcceptedDeposits = 0;
        emit FetchedDeposits(amount);
        payoutAddress.transfer(amount);
        // not idempotent, but multiple invocation would just trigger zero-transfers
    }

    // After the specified date, any of the privileged/special accounts can trigger payment of remaining funds
    // to the payoutAddress. This is a safety net to minimize the risk of funds remaining stuck.
    // It&#39;s not yet clear what we can / should / are allowed to do with alien deposits which aren&#39;t reclaimed.
    // With this fallback in place, we have for example the option to donate them at some point.
    function fallbackPayout() public {
        require(msg.sender == stateController || msg.sender == whitelistController || msg.sender == payoutAddress);
        require(block.timestamp > FALLBACK_PAYOUT_TS);
        payoutAddress.transfer(address(this).balance);
    }

    // ################### INTERNAL FUNCTIONS ###################

    // rule enforcement and book-keeping for incoming deposits
    function tryDeposit() internal {
        require(cumAcceptedDeposits + msg.value <= maxCumAcceptedDeposits);
        if(whitelist[msg.sender] == true) {
            require(acceptedDeposits[msg.sender] + msg.value >= minDeposit);
            acceptedDeposits[msg.sender] += msg.value;
            cumAcceptedDeposits += msg.value;
        } else {
            require(alienDeposits[msg.sender] + msg.value >= minDeposit);
            alienDeposits[msg.sender] += msg.value;
            cumAlienDeposits += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    // rule enforcement and book-keeping for refunding requests
    function tryRefund() internal {
        // Note: this implementation requires that acceptedDeposits and alienDeposits have a primitive value type.
        // With a complex type, this code would produce dangling references.
        uint256 withdrawAmount;
        if(whitelist[msg.sender] == true) {
            require(state == States.Open);
            withdrawAmount = acceptedDeposits[msg.sender];
            require(withdrawAmount > 0);
            delete acceptedDeposits[msg.sender]; // implies setting the value to 0
            cumAcceptedDeposits -= withdrawAmount;
        } else {
            // alien deposits can be withdrawn anytime (we prefer to not touch them)
            withdrawAmount = alienDeposits[msg.sender];
            require(withdrawAmount > 0);
            delete alienDeposits[msg.sender]; // implies setting the value to 0
            cumAlienDeposits -= withdrawAmount;
        }
        emit Refund(msg.sender, withdrawAmount);
        // do the actual transfer last as recommended since the DAO incident (Checks-Effects-Interaction pattern)
        msg.sender.transfer(withdrawAmount); // throws on failure
    }

    function setState(States _newState) internal {
        state = _newState;
        emit StateTransition(state, _newState);
    }
}