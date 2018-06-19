//A BurnableOpenPayment is instantiated with a specified payer and a commitThreshold.
//The recipient is not set when the contract is instantiated.

//The constructor is payable, so the contract can be instantiated with initial funds.
//Only the payer can fund the Payment after instantiation.

//All behavior of the contract is directed by the payer, but
//the payer can never directly recover the payment,
//unless he calls the recover() function before anyone else commit()s.

//Anyone can become the recipient by contributing the commitThreshold with commit().
//The recipient will never be changed once it&#39;s been set via commit().

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
    
    //Amount of ether a prospective recipient must pay to permanently become the recipient. See commit().
    uint public commitThreshold;
    
    //What if the payer falls off the face of the planet?
    //A BOP is instantiated with a chosen defaultAction, which cannot be changed after instantiation.
    enum DefaultAction {None, Release, Burn}
    DefaultAction public defaultAction;
    
    //if defaultAction != None, how long should we wait allowing the default action to be called?
    uint public defaultTimeoutLength;
    
    //Calculated from defaultTimeoutLength in commit(),
    //and recaluclated whenever the payer (or possibly the recipient) calls delayDefaultAction()
    uint public defaultTriggerTime;
    
    //Most action happens in the Committed state.
    enum State {Open, Committed, Expended}
    State public state;
    //Note that a BOP cannot go from Committed back to Open, but it can go from Expended back to Committed
    //(this would retain the committed recipient). Search for Expended and Unexpended events to see how this works.
    
    modifier inState(State s) { require(s == state); _; }
    modifier onlyPayer() { require(msg.sender == payer); _; }
    modifier onlyRecipient() { require(msg.sender == recipient); _; }
    modifier onlyPayerOrRecipient() { require((msg.sender == payer) || (msg.sender == recipient)); _; }
    
    event Created(address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString);
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
    
    function BurnableOpenPayment(address _payer, uint _commitThreshold, DefaultAction _defaultAction, uint _defaultTimeoutLength, string _payerString)
    public
    payable {
        Created(_payer, _commitThreshold, _defaultAction, _defaultTimeoutLength, _payerString);
        
        if (msg.value > 0) {
            FundsAdded(msg.value);
            amountDeposited += msg.value;
        }
            
        state = State.Open;
        payer = _payer;
        
        commitThreshold = _commitThreshold;
        
        defaultAction = _defaultAction;
        if (defaultAction != DefaultAction.None) 
            defaultTimeoutLength = _defaultTimeoutLength;
        
        payerString = _payerString;
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
        require(msg.value > 0);
        
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
        require(msg.value >= commitThreshold);
        
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
    {
        burnAddress.transfer(amount);
        
        amountBurned += amount;
        FundsBurned(amount);
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
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
    inState(State.Committed)
    {
        recipient.transfer(amount);
        
        amountReleased += amount;
        FundsReleased(amount);
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
        }
    }
    
    function release(uint amount)
    public
    inState(State.Committed)
    onlyPayer()
    {
        internalRelease(amount);
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
        require(defaultAction != DefaultAction.None);
        
        defaultTriggerTime = now + defaultTimeoutLength;
        DefaultActionDelayed();
    }
    
    function callDefaultAction()
    public
    onlyPayerOrRecipient()
    inState(State.Committed)
    {
        require(defaultAction != DefaultAction.None);
        require(now >= defaultTriggerTime);
        
        if (defaultAction == DefaultAction.Burn) {
            internalBurn(this.balance);
        }
        else if (defaultAction == DefaultAction.Release) {
            internalRelease(this.balance);
        }
        DefaultActionCalled();
    }
}

contract BurnableOpenPaymentFactory {
    event NewBOP(address newBOPAddress, address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString);
    
    function newBurnableOpenPayment(address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString)
    public
    payable
    returns (address) {
        //pass along any ether to the constructor
        address newBOPAddr = (new BurnableOpenPayment).value(msg.value)(payer, commitThreshold, defaultAction, defaultTimeoutLength, initialPayerString);
        NewBOP(newBOPAddr, payer, commitThreshold, defaultAction, defaultTimeoutLength, initialPayerString);
        return newBOPAddr;
    }
}