//A BurnablePayment is instantiated with one "opening agent" (Payer or Worker), a title, an initial deposit, a commitThreshold, and an autoreleaseInterval.
//If the opening agent is the payer:
//    The contract starts in the PayerOpened state.
//    Payer is expected to request some service via the title and additional statements.
//    The initial deposit represents the amount Payer will pay for the service.
//    Another user can claim the job by calling commit() and becoming the worker.
//If the opening agent is the worker:
//    The contract starts in the WorkerOpened state.
//    Worker is expected to offer some service via the title and additional statements.
//    The initial deposit serves as collateral that a payer will have control over.
//    Another user can claim the service by calling commit() and becoming the payer.

//While in either Open state,
//    The opening agent can call recover() to destroy the contract and refund all deposited funds.
//    The opening agent can log statements to add additional details, clarifications, or corrections.
//    Anyone can enter the contract as the open role by contributing the commitThreshold with commit();
//        this changes the state to Committed.

//Upon changing from either Open state -> Committed:
//    AutoreleaseTime is set to (now + autoreleaseInterval).

//In the Committed state:
//    Both roles are permanent.
//    Both Payer and Worker can log statements.
//    Payer can at any time choose to burn() or release() to Worker any amount of funds.
//    Payer can delayAutorelease(), setting the autoreleaseTime to (now + autoreleaseInterval), any number of times.
//    If autoreleaseTime comes, Worker can triggerAutorelease() to claim all ether remaining in the payment.
//    Once the balance of the payment is 0, the state changes to Closed.

//In the Closed state:
//    Payer and Worker can still log statements.
//    If addFunds() is called, the contract returns to the Committed state.

pragma solidity ^ 0.4.2;

contract BurnablePaymentFactory {
    
    //contract address array
    address[]public BPs;

    event NewBurnablePayment(
        address indexed bpAddress, 
        bool payerOpened, 
        address creator, 
        uint deposited, 
        uint commitThreshold, 
        uint autoreleaseInterval, 
        string title, 
        string initialStatement
    );  

    function newBP(bool payerOpened, address creator, uint commitThreshold, uint autoreleaseInterval, string title, string initialStatement)
    public
    payable
    returns (address newBPAddr) 
    {
        //pass along any ether to the constructor
        newBPAddr = (new BurnablePayment).value(msg.value)(payerOpened, creator, commitThreshold, autoreleaseInterval, title, initialStatement);
        NewBurnablePayment(newBPAddr, payerOpened, creator, msg.value, commitThreshold, autoreleaseInterval, title, initialStatement);

        BPs.push(newBPAddr);

        return newBPAddr;
    }

    function getBPCount()
    public
    constant
    returns(uint) 
    {
        return BPs.length;
    }
}

contract BurnablePayment {
    //title will never change
    string public title;
    
    //BP will start with a payer or a worker but not both
    address public payer;
    address public worker;
    address constant BURN_ADDRESS = 0x0;
    
    //Set to true if fundsRecovered is called
    bool recovered = false;

    //Note that these will track, but not influence the BP logic.
    uint public amountDeposited;
    uint public amountBurned;
    uint public amountReleased;

    //Amount of ether that must be deposited via commit() to become the second party of the BP.
    uint public commitThreshold;

    //How long should we wait before allowing the default release to be called?
    uint public autoreleaseInterval;

    //Calculated from autoreleaseInterval in commit(),
    //and recaluclated whenever the payer (or possibly the worker) calls delayhasDefaultRelease()
    //After this time, auto-release can be called by the Worker.
    uint public autoreleaseTime;

    //Most action happens in the Committed state.
    enum State {
        PayerOpened,
        WorkerOpened,
        Committed,
        Closed
    }

    //Note that a BP cannot go from Committed back to either Open state, but it can go from Closed back to Committed
    //Search for Closed and Unclosed events to see how this works.
    State public state;

    modifier inState(State s) {
        require(s == state);
        _;
    }
    modifier inOpenState() {
        require(state == State.PayerOpened || state == State.WorkerOpened);
        _;
    }
    modifier onlyPayer() {
        require(msg.sender == payer);
        _;
    }
    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }
    modifier onlyPayerOrWorker() {
        require((msg.sender == payer) || (msg.sender == worker));
        _;
    }
    modifier onlyCreatorWhileOpen() {
        if (state == State.PayerOpened) {
            require(msg.sender == payer);
        } else if (state == State.WorkerOpened) {
            require(msg.sender == worker);
        } else {
            revert();        
        }
        _;
    }

    event Created(address indexed contractAddress, bool payerOpened, address creator, uint commitThreshold, uint autoreleaseInterval, string title);
    event FundsAdded(address from, uint amount); //The payer has added funds to the BP.
    event PayerStatement(string statement);
    event WorkerStatement(string statement);
    event FundsRecovered();
    event Committed(address committer);
    event FundsBurned(uint amount);
    event FundsReleased(uint amount);
    event Closed();
    event Unclosed();
    event AutoreleaseDelayed();
    event AutoreleaseTriggered();

    function BurnablePayment(bool payerIsOpening, address creator, uint _commitThreshold, uint _autoreleaseInterval, string _title, string initialStatement)
    public
    payable 
    {
        Created(this, payerIsOpening, creator, _commitThreshold, autoreleaseInterval, title);

        if (msg.value > 0) {
            //Here we use tx.origin instead of msg.sender (msg.sender is just the factory contract)
            FundsAdded(tx.origin, msg.value);
            amountDeposited += msg.value;
        }
        
        title = _title;

        if (payerIsOpening) {
            state = State.PayerOpened;
            payer = creator;
        } else {
            state = State.WorkerOpened;
            worker = creator;
        }

        commitThreshold = _commitThreshold;
        autoreleaseInterval = _autoreleaseInterval;

        if (bytes(initialStatement).length > 0) {
            if (payerIsOpening) {
                PayerStatement(initialStatement);
            } else {
                WorkerStatement(initialStatement);              
            }
        }
    }

    function addFunds()
    public
    payable
    onlyPayerOrWorker()
    {
        require(msg.value > 0);

        FundsAdded(msg.sender, msg.value);
        amountDeposited += msg.value;
        if (state == State.Closed) {
            state = State.Committed;
            Unclosed();
        }
    }

    function recoverFunds()
    public
    onlyCreatorWhileOpen()
    {
        recovered = true;
        FundsRecovered();
        
        if (state == State.PayerOpened)
            selfdestruct(payer);
        else if (state == State.WorkerOpened)
            selfdestruct(worker);
    }

    function commit()
    public
    inOpenState()
    payable 
    {
        require(msg.value == commitThreshold);

        if (msg.value > 0) {
            FundsAdded(msg.sender, msg.value);
            amountDeposited += msg.value;
        }

        if (state == State.PayerOpened)
            worker = msg.sender;
        else
            payer = msg.sender;
        state = State.Committed;
        
        Committed(msg.sender);

        autoreleaseTime = now + autoreleaseInterval;
    }

    function internalBurn(uint amount)
    private 
    {
        BURN_ADDRESS.transfer(amount);

        amountBurned += amount;
        FundsBurned(amount);

        if (this.balance == 0) {
            state = State.Closed;
            Closed();
        }
    }

    function burn(uint amount)
    public
    inState(State.Committed)
    onlyPayer() 
    {
        internalBurn(amount);
    }

    function internalRelease(uint amount)
    private 
    {
        worker.transfer(amount);

        amountReleased += amount;
        FundsReleased(amount);

        if (this.balance == 0) {
            state = State.Closed;
            Closed();
        }
    }

    function release(uint amount)
    public
    inState(State.Committed)
    onlyPayer() 
    {
        internalRelease(amount);
    }

    function logPayerStatement(string statement)
    public
    onlyPayer() 
    {
        PayerStatement(statement);
    }

    function logWorkerStatement(string statement)
    public
    onlyWorker() 
    {
        WorkerStatement(statement);
    }

    function delayAutorelease()
    public
    onlyPayer()
    inState(State.Committed) 
    {
        autoreleaseTime = now + autoreleaseInterval;
        AutoreleaseDelayed();
    }

    function triggerAutorelease()
    public
    onlyWorker()
    inState(State.Committed) 
    {
        require(now >= autoreleaseTime);

        AutoreleaseTriggered();
        internalRelease(this.balance);
    }
    
    function getFullState()
    public
    constant
    returns(State, address, address, string, uint, uint, uint, uint, uint, uint, uint) {
        return (state, payer, worker, title, this.balance, commitThreshold, amountDeposited, amountBurned, amountReleased, autoreleaseInterval, autoreleaseTime);
    }
}