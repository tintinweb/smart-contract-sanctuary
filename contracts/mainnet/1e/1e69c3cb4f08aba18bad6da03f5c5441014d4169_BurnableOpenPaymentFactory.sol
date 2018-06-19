//A BurnableOpenPayment is instantiated with a specified payer and a commitThreshold.
//The recipient is not set when the contract is instantiated.

//The constructor is payable, so the contract can be instantiated with initial funds.
//Only the payer can fund the Payment after instantiation.

//All behavior of the contract is directed by the payer, but
//the payer can never directly recover the payment unless he becomes the recipient.

//Anyone can become the recipient by contributing the commitThreshold.
//The recipient cannot change once it&#39;s been set.

//The payer can at any time choose to burn or release to the recipient any amount of funds.

pragma solidity ^0.4.10;

contract BurnableOpenPayment {
    //BOP will start with a payer but no recipient (recipient==0x0)
    address public payer;
    address public recipient;
    address constant burnAddress = 0x0;
    
    //Note that these will track, but not influence the BOP logic.
    uint public amountDeposited;
    uint public amountBurned;
    uint public amountReleased;
    
    //payerString and recipientString enable rudimentary communication/publishing.
    //Although the two parties might quickly move to another medium with better privacy or convenience,
    //beginning with this is nice because it&#39;s already trustless/transparent/signed/pseudonymous/etc.
    string public payerString;
    string public recipientString;
    
    //Amount of ether a prospective recipient must pay to become (permanently) the recipient. See commit().
    uint public commitThreshold;
    
    //What if the payer falls off the face of the planet?
    //A BOP is instantiated with a chosen defaultAction, and this cannot be changed.
    enum DefaultAction {None, Release, Burn}
    DefaultAction public defaultAction;
    
    //if defaultAction != None, how long should we wait before giving up?
    //Set in constructor:
    uint public defaultTimeoutLength;
    
    //Calculated from defaultTimeoutLength on a successful recipient commit(),
    //as well as whenever the payer (or possibly the recipient) calls delayDefaultAction()
    uint public defaultTriggerTime;
    
    //Most action happens in the Committed state.
    enum State {Open, Committed, Expended}
    State public state;
    //Note that a BOP cannot go from Committed back to Open, but it can go from Expended back to Committed
    //(this would retain the committed recipient). Search for Expended and Unexpended events to see how this works.
    
    modifier inState(State s) { if (s != state) throw; _; }
    modifier onlyPayer() { if (msg.sender != payer) throw; _; }
    modifier onlyRecipient() { if (msg.sender != recipient) throw; _; }
    modifier onlyPayerOrRecipient() { if ((msg.sender != payer) && (msg.sender != recipient)) throw; _; }
    
    event FundsAdded(uint amount);//The payer has added funds to the BOP.
    event PayerStringUpdated(string newPayerString);
    event RecipientStringUpdated(string newRecipientString);
    event FundsRecovered();
    event Committed(address recipient);
    event FundsBurned(uint amount);
    event FundsReleased(uint amount);
    event Expended();
    event Unexpended();
    event DefaultActionDelayed();
    event DefaultActionCalled();
    
    function BurnableOpenPayment(address _payer, string _payerString, uint _commitThreshold, DefaultAction _defaultAction, uint _defaultTimeoutLength)
    public
    payable {
        if (msg.value > 0) {
            FundsAdded(msg.value);
            amountDeposited += msg.value;
        }
            
        state = State.Open;
        payer = _payer;
        payerString = _payerString;
        PayerStringUpdated(payerString);
        
        commitThreshold = _commitThreshold;
        
        defaultAction = _defaultAction;
        if (defaultAction != DefaultAction.None) 
            defaultTimeoutLength = _defaultTimeoutLength;
    }
    
    function getFullState()
    public
    constant
    returns (State, string, address, string, uint, uint, uint, uint) {
        return (state, payerString, recipient, recipientString, amountDeposited, amountBurned, amountReleased, defaultTriggerTime);
    }
    
    function addFunds()
    public
    onlyPayer()
    payable {
        if (msg.value == 0) throw;
        
        FundsAdded(msg.value);
        amountDeposited += msg.value;
        if (state == State.Expended) {
            state = State.Committed;
            Unexpended();
        }
    }
    
    function recoverFunds()
    public
    onlyPayer()
    inState(State.Open)
    {
        FundsRecovered();
        selfdestruct(payer);
    }
    
    function commit()
    public
    inState(State.Open)
    payable
    {
        if (msg.value < commitThreshold) throw;
        
        if (msg.value > 0) {
            FundsAdded(msg.value);
            amountDeposited += msg.value;
        }
        
        recipient = msg.sender;
        state = State.Committed;
        Committed(recipient);
        
        if (defaultAction != DefaultAction.None) {
            defaultTriggerTime = now + defaultTimeoutLength;
        }
    }
    
    function internalBurn(uint amount)
    private
    inState(State.Committed)
    returns (bool)
    {
        bool success = burnAddress.send(amount);
        if (success) {
            FundsBurned(amount);
            amountBurned += amount;
        }
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
        }
        
        return success;
    }
    
    function burn(uint amount)
    public
    inState(State.Committed)
    onlyPayer()
    returns (bool)
    {
        return internalBurn(amount);
    }
    
    function internalRelease(uint amount)
    private
    inState(State.Committed)
    returns (bool)
    {
        bool success = recipient.send(amount);
        if (success) {
            FundsReleased(amount);
            amountReleased += amount;
        }
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
        }
        return success;
    }
    
    function release(uint amount)
    public
    inState(State.Committed)
    onlyPayer()
    returns (bool)
    {
        return internalRelease(amount);
    }
    
    function setPayerString(string _string)
    public
    onlyPayer()
    {
        payerString = _string;
        PayerStringUpdated(payerString);
    }
    
    function setRecipientString(string _string)
    public
    onlyRecipient()
    {
        recipientString = _string;
        RecipientStringUpdated(recipientString);
    }
    
    function delayDefaultAction()
    public
    onlyPayerOrRecipient()
    inState(State.Committed)
    {
        if (defaultAction == DefaultAction.None) throw;
        
        DefaultActionDelayed();
        defaultTriggerTime = now + defaultTimeoutLength;
    }
    
    function callDefaultAction()
    public
    onlyPayerOrRecipient()
    inState(State.Committed)
    {
        if (defaultAction == DefaultAction.None) throw;
        if (now < defaultTriggerTime) throw;
        
        DefaultActionCalled();
        if (defaultAction == DefaultAction.Burn) {
            internalBurn(this.balance);
        }
        else if (defaultAction == DefaultAction.Release) {
            internalRelease(this.balance);
        }
    }
}

contract BurnableOpenPaymentFactory {
    event NewBOP(address newBOPAddress);
    
    function newBurnableOpenPayment(address payer, string payerString, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength)
    public
    payable
    returns (address) {
        //pass along any ether to the constructor
        address newBOPAddr = (new BurnableOpenPayment).value(msg.value)(payer, payerString, commitThreshold, defaultAction, defaultTimeoutLength);
        NewBOP(newBOPAddr);
        return newBOPAddr;
    }
}