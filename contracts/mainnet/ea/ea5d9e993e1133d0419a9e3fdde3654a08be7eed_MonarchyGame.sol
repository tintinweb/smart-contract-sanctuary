pragma solidity ^0.4.23;

/**
A PennyAuction-like game to win a prize.

UI: https://www.pennyether.com

How it works:
    - An initial prize is held in the Contract
    - Anyone may overthrow the Monarch by paying a small fee.
        - They become the Monarch
        - The "reign" timer is reset to N.
        - The prize may be increased or decreased
    - If nobody overthrows the new Monarch in N blocks, the Monarch wins.

For fairness, an "overthrow" is refunded if:
    - The incorrect amount is sent.
    - The game is already over.
    - The overthrower is already the Monarch.
    - Another overthrow occurred in the same block
        - Note: Here, default gas is used for refund. On failure, fee is kept.

Other notes:
    - .sendFees(): Sends accrued fees to "collector", at any time.
    - .sendPrize(): If game is ended, sends prize to the Monarch.
*/
contract MonarchyGame {
    // We store values as GWei to reduce storage to 64 bits.
    // int64: 2^63 GWei is ~ 9 billion Ether, so no overflow risk.
    //
    // For blocks, we use uint32, which has a max value of 4.3 billion
    // At a 1 second block time, there&#39;s a risk of overflow in 120 years.
    //
    // We put these variables together because they are all written to
    // on each bid. This should save some gas when we write.
    struct Vars {
        // [first 256-bit segment]
        address monarch;        // address of monarch
        uint64 prizeGwei;       // (Gwei) the current prize
        uint32 numOverthrows;   // total number of overthrows

        // [second 256-bit segment]
        uint32 blockEnded;      // the time at which no further overthrows can occur  
        uint32 prevBlock;       // block of the most recent overthrow
        bool isPaid;            // whether or not the winner has been paid
        bytes23 decree;         // 23 leftover bytes for decree
    }

    // These values are set on construction and don&#39;t change.
    // We store in a struct for gas-efficient reading/writing.
    struct Settings {
        // [first 256-bit segment]
        address collector;       // address that fees get sent to
        uint64 initialPrizeGwei; // (Gwei > 0) amt initially staked
        // [second 256-bit segment]
        uint64 feeGwei;          // (Gwei > 0) cost to become the Monarch
        int64 prizeIncrGwei;     // amount added/removed to prize on overthrow
        uint32 reignBlocks;      // number of blocks Monarch must reign to win
    }

    Vars vars;
    Settings settings;
    uint constant version = 1;

    event SendPrizeError(uint time, string msg);
    event Started(uint time, uint initialBlocks);
    event OverthrowOccurred(uint time, address indexed newMonarch, bytes23 decree, address indexed prevMonarch, uint fee);
    event OverthrowRefundSuccess(uint time, string msg, address indexed recipient, uint amount);
    event OverthrowRefundFailure(uint time, string msg, address indexed recipient, uint amount);
    event SendPrizeSuccess(uint time, address indexed redeemer, address indexed recipient, uint amount, uint gasLimit);
    event SendPrizeFailure(uint time, address indexed redeemer, address indexed recipient, uint amount, uint gasLimit);
    event FeesSent(uint time, address indexed collector, uint amount);

    constructor(
        address _collector,
        uint _initialPrize,
        uint _fee,
        int _prizeIncr,
        uint _reignBlocks,
        uint _initialBlocks
    )
        public
        payable
    {
        require(_initialPrize >= 1e9);                // min value of 1 GWei
        require(_initialPrize < 1e6 * 1e18);          // max value of a million ether
        require(_initialPrize % 1e9 == 0);            // even amount of GWei
        require(_fee >= 1e6);                         // min value of 1 GWei
        require(_fee < 1e6 * 1e18);                   // max value of a million ether
        require(_fee % 1e9 == 0);                     // even amount of GWei
        require(_prizeIncr <= int(_fee));             // max value of _bidPrice
        require(_prizeIncr >= -1*int(_initialPrize)); // min value of -1*initialPrize
        require(_prizeIncr % 1e9 == 0);               // even amount of GWei
        require(_reignBlocks >= 1);                   // minimum of 1 block
        require(_initialBlocks >= 1);                 // minimum of 1 block
        require(msg.value == _initialPrize);          // must&#39;ve sent the prize amount

        // Set instance variables. these never change.
        // These can be safely cast to int64 because they are each < 1e24 (see above),
        // 1e24 divided by 1e9 is 1e15. Max int64 val is ~1e19, so plenty of room.
        // For block numbers, uint32 is good up to ~4e12, a long time from now.
        settings.collector = _collector;
        settings.initialPrizeGwei = uint64(_initialPrize / 1e9);
        settings.feeGwei = uint64(_fee / 1e9);
        settings.prizeIncrGwei = int64(_prizeIncr / 1e9);
        settings.reignBlocks = uint32(_reignBlocks);

        // Initialize the game variables.
        vars.prizeGwei = settings.initialPrizeGwei;
        vars.monarch = _collector;
        vars.prevBlock = uint32(block.number);
        vars.blockEnded = uint32(block.number + _initialBlocks);

        emit Started(now, _initialBlocks);
    }


    /*************************************************************/
    /********** OVERTHROWING *************************************/
    /*************************************************************/
    //
    // Upon new bid, adds fees and increments time and prize.
    //  - Refunds if overthrow is too late, user is already monarch, or incorrect value passed.
    //  - Upon an overthrow-in-same-block, refends previous monarch.
    //
    // Gas Cost: 34k - 50k
    //     Overhead: 25k
    //       - 23k: tx overhead
    //       -  2k: SLOADs, execution
    //     Failure: 34k
    //       - 25k: overhead
    //       -  7k: send refund
    //       -  2k: event: OverthrowRefundSuccess
    //     Clean: 37k
    //       - 25k: overhead
    //       - 10k: update Vars (monarch, numOverthrows, prize, blockEnded, prevBlock, decree)
    //       -  2k: event: OverthrowOccurred
    //     Refund Success: 46k
    //       - 25k: overhead
    //       -  7k: send
    //       - 10k: update Vars (monarch, decree)
    //       -  2k: event: OverthrowRefundSuccess
    //       -  2k: event: OverthrowOccurred
    //     Refund Failure: 50k
    //       - 25k: overhead
    //       - 11k: send failure
    //       - 10k: update Vars (monarch, numOverthrows, prize, decree)
    //       -  2k: event: OverthrowRefundFailure
    //       -  2k: event: OverthrowOccurred
    function()
        public
        payable
    {
        overthrow(0);
    }

    function overthrow(bytes23 _decree)
        public
        payable
    {
        if (isEnded())
            return errorAndRefund("Game has already ended.");
        if (msg.sender == vars.monarch)
            return errorAndRefund("You are already the Monarch.");
        if (msg.value != fee())
            return errorAndRefund("Value sent must match fee.");

        // compute new values. hopefully optimizer reads from vars/settings just once.
        int _newPrizeGwei = int(vars.prizeGwei) + settings.prizeIncrGwei;
        uint32 _newBlockEnded = uint32(block.number) + settings.reignBlocks;
        uint32 _newNumOverthrows = vars.numOverthrows + 1;
        address _prevMonarch = vars.monarch;
        bool _isClean = (block.number != vars.prevBlock);

        // Refund if _newPrize would end up being < 0.
        if (_newPrizeGwei < 0)
            return errorAndRefund("Overthrowing would result in a negative prize.");

        // Attempt refund, if necessary. Use minimum gas.
        bool _wasRefundSuccess;
        if (!_isClean) {
            _wasRefundSuccess = _prevMonarch.send(msg.value);   
        }

        // These blocks can be made nicer, but optimizer will
        //  sometimes do two updates instead of one. Seems it is
        //  best to keep if/else trees flat.
        if (_isClean) {
            vars.monarch = msg.sender;
            vars.numOverthrows = _newNumOverthrows;
            vars.prizeGwei = uint64(_newPrizeGwei);
            vars.blockEnded = _newBlockEnded;
            vars.prevBlock = uint32(block.number);
            vars.decree = _decree;
        }
        if (!_isClean && _wasRefundSuccess){
            // when a refund occurs, we just swap winners.
            // overthrow count and prize do not get reset.
            vars.monarch = msg.sender;
            vars.decree = _decree;
        }
        if (!_isClean && !_wasRefundSuccess){
            vars.monarch = msg.sender;   
            vars.prizeGwei = uint64(_newPrizeGwei);
            vars.numOverthrows = _newNumOverthrows;
            vars.decree = _decree;
        }

        // Emit the proper events.
        if (!_isClean){
            if (_wasRefundSuccess)
                emit OverthrowRefundSuccess(now, "Another overthrow occurred on the same block.", _prevMonarch, msg.value);
            else
                emit OverthrowRefundFailure(now, ".send() failed.", _prevMonarch, msg.value);
        }
        emit OverthrowOccurred(now, msg.sender, _decree, _prevMonarch, msg.value);
    }
        // called from the bidding function above.
        // refunds sender, or throws to revert entire tx.
        function errorAndRefund(string _msg)
            private
        {
            require(msg.sender.call.value(msg.value)());
            emit OverthrowRefundSuccess(now, _msg, msg.sender, msg.value);
        }


    /*************************************************************/
    /********** PUBLIC FUNCTIONS *********************************/
    /*************************************************************/

    // Sends prize to the current winner using _gasLimit (0 is unlimited)
    function sendPrize(uint _gasLimit)
        public
        returns (bool _success, uint _prizeSent)
    {
        // make sure game has ended, and is not paid
        if (!isEnded()) {
            emit SendPrizeError(now, "The game has not ended.");
            return (false, 0);
        }
        if (vars.isPaid) {
            emit SendPrizeError(now, "The prize has already been paid.");
            return (false, 0);
        }

        address _winner = vars.monarch;
        uint _prize = prize();
        bool _paySuccessful = false;

        // attempt to pay winner (use full gas if _gasLimit is 0)
        vars.isPaid = true;
        if (_gasLimit == 0) {
            _paySuccessful = _winner.call.value(_prize)();
        } else {
            _paySuccessful = _winner.call.value(_prize).gas(_gasLimit)();
        }

        // emit proper event. rollback .isPaid on failure.
        if (_paySuccessful) {
            emit SendPrizeSuccess({
                time: now,
                redeemer: msg.sender,
                recipient: _winner,
                amount: _prize,
                gasLimit: _gasLimit
            });
            return (true, _prize);
        } else {
            vars.isPaid = false;
            emit SendPrizeFailure({
                time: now,
                redeemer: msg.sender,
                recipient: _winner,
                amount: _prize,
                gasLimit: _gasLimit
            });
            return (false, 0);          
        }
    }
    
    // Sends accrued fees to the collector. Callable by anyone.
    function sendFees()
        public
        returns (uint _feesSent)
    {
        _feesSent = fees();
        if (_feesSent == 0) return;
        require(settings.collector.call.value(_feesSent)());
        emit FeesSent(now, settings.collector, _feesSent);
    }



    /*************************************************************/
    /********** PUBLIC VIEWS *************************************/
    /*************************************************************/

    // Expose all Vars ////////////////////////////////////////
    function monarch() public view returns (address) {
        return vars.monarch;
    }
    function prize() public view returns (uint) {
        return uint(vars.prizeGwei) * 1e9;
    }
    function numOverthrows() public view returns (uint) {
        return vars.numOverthrows;
    }
    function blockEnded() public view returns (uint) {
        return vars.blockEnded;
    }
    function prevBlock() public view returns (uint) {
        return vars.prevBlock;
    }
    function isPaid() public view returns (bool) {
        return vars.isPaid;
    }
    function decree() public view returns (bytes23) {
        return vars.decree;
    }
    ///////////////////////////////////////////////////////////

    // Expose all Settings //////////////////////////////////////
    function collector() public view returns (address) {
        return settings.collector;
    }
    function initialPrize() public view returns (uint){
        return uint(settings.initialPrizeGwei) * 1e9;
    }
    function fee() public view returns (uint) {
        return uint(settings.feeGwei) * 1e9;
    }
    function prizeIncr() public view returns (int) {
        return int(settings.prizeIncrGwei) * 1e9;
    }
    function reignBlocks() public view returns (uint) {
        return settings.reignBlocks;
    }
    ///////////////////////////////////////////////////////////

    // The following are computed /////////////////////////////
    function isEnded() public view returns (bool) {
        return block.number > vars.blockEnded;
    }
    function getBlocksRemaining() public view returns (uint) {
        if (isEnded()) return 0;
        return (vars.blockEnded - block.number) + 1;
    }
    function fees() public view returns (uint) {
        uint _balance = address(this).balance;
        return vars.isPaid ? _balance : _balance - prize();
    }
    function totalFees() public view returns (uint) {
        int _feePerOverthrowGwei = int(settings.feeGwei) - settings.prizeIncrGwei;
        return uint(_feePerOverthrowGwei * vars.numOverthrows * 1e9);
    }
    ///////////////////////////////////////////////////////////
}