//A BurnableOpenPayment is instantiated with a specified payer and a commitThreshold.
//The recipient is not set when the contract is instantiated.

//The constructor is payable, so the contract can be instantiated with initial funds.
//In addition, anyone can add more funds to the Payment by calling addFunds.

//All behavior of the contract is directed by the payer, but
//the payer can never directly recover the payment,
//unless he calls the recover() function before anyone else commit()s.

//If the BOP is in the Open state,
//anyone can become the recipient by contributing the commitThreshold with commit().
//This changes the state from Open to Committed. The BOP will never return to the Open state.
//The recipient will never be changed once it&#39;s been set via commit().

//In the committed state,
//the payer can at any time choose to burn or release to the recipient any amount of funds.

pragma solidity ^ 0.4.10;
contract BurnableOpenPaymentFactory {
	event NewBOP(address indexed contractAddress, address newBOPAddress, address payer, uint commitThreshold, bool hasDefaultRelease, uint defaultTimeoutLength, string initialPayerString);

	//contract address array
	address[]public contracts;

	function getContractCount()
	public
	constant
	returns(uint) {
		return contracts.length;
	}

	function newBurnableOpenPayment(address payer, uint commitThreshold, bool hasDefaultRelease, uint defaultTimeoutLength, string initialPayerString)
	public
	payable
	returns(address) {
		//pass along any ether to the constructor
		address newBOPAddr = (new BurnableOpenPayment).value(msg.value)(payer, commitThreshold, hasDefaultRelease, defaultTimeoutLength, initialPayerString);
		NewBOP(this, newBOPAddr, payer, commitThreshold, hasDefaultRelease, defaultTimeoutLength, initialPayerString);

		//save created BOPs in contract array
		contracts.push(newBOPAddr);

		return newBOPAddr;
	}
}

contract BurnableOpenPayment {
	//BOP will start with a payer but no recipient (recipient==0x0)
	address public payer;
	address public recipient;
	address constant burnAddress = 0x0;
	
	//Set to true if fundsRecovered is called
	bool recovered = false;

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
	//A BOP is instantiated with or without defaultRelease, which cannot be changed after instantiation.
	bool public hasDefaultRelease;

	//if hasDefaultRelease == True, how long should we wait allowing the default release to be called?
	uint public defaultTimeoutLength;

	//Calculated from defaultTimeoutLength in commit(),
	//and recaluclated whenever the payer (or possibly the recipient) calls delayhasDefaultRelease()
	uint public defaultTriggerTime;

	//Most action happens in the Committed state.
	enum State {
		Open,
		Committed,
		Expended
	}
	State public state;
	//Note that a BOP cannot go from Committed back to Open, but it can go from Expended back to Committed
	//(this would retain the committed recipient). Search for Expended and Unexpended events to see how this works.

	modifier inState(State s) {
		require(s == state);
		_;
	}
	modifier onlyPayer() {
		require(msg.sender == payer);
		_;
	}
	modifier onlyRecipient() {
		require(msg.sender == recipient);
		_;
	}
	modifier onlyPayerOrRecipient() {
		require((msg.sender == payer) || (msg.sender == recipient));
		_;
	}

	event Created(address indexed contractAddress, address payer, uint commitThreshold, bool hasDefaultRelease, uint defaultTimeoutLength, string initialPayerString);
	event FundsAdded(uint amount); //The payer has added funds to the BOP.
	event PayerStringUpdated(string newPayerString);
	event RecipientStringUpdated(string newRecipientString);
	event FundsRecovered();
	event Committed(address recipient);
	event FundsBurned(uint amount);
	event FundsReleased(uint amount);
	event Expended();
	event Unexpended();
	event DefaultReleaseDelayed();
	event DefaultReleaseCalled();

	function BurnableOpenPayment(address _payer, uint _commitThreshold, bool _hasDefaultRelease, uint _defaultTimeoutLength, string _payerString)
	public
	payable {
		Created(this, _payer, _commitThreshold, _hasDefaultRelease, _defaultTimeoutLength, _payerString);

		if (msg.value > 0) {
			FundsAdded(msg.value);
			amountDeposited += msg.value;
		}

		state = State.Open;
		payer = _payer;

		commitThreshold = _commitThreshold;

		hasDefaultRelease = _hasDefaultRelease;
		if (hasDefaultRelease)
			defaultTimeoutLength = _defaultTimeoutLength;

		payerString = _payerString;
	}

	function getFullState()
	public
	constant
	returns(State, address, string, address, string, uint, uint, uint, uint, uint, bool, uint, uint) {
		return (state, payer, payerString, recipient, recipientString, this.balance, commitThreshold, amountDeposited, amountBurned, amountReleased, hasDefaultRelease, defaultTimeoutLength, defaultTriggerTime);
	}

	function addFunds()
	public
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
	inState(State.Open) {
	    recovered = true;
		FundsRecovered();
		selfdestruct(payer);
	}

	function commit()
	public
	inState(State.Open)
	payable{
		require(msg.value >= commitThreshold);

		if (msg.value > 0) {
			FundsAdded(msg.value);
			amountDeposited += msg.value;
		}

		recipient = msg.sender;
		state = State.Committed;
		Committed(recipient);

		if (hasDefaultRelease) {
			defaultTriggerTime = now + defaultTimeoutLength;
		}
	}

	function internalBurn(uint amount)
	private
	inState(State.Committed) {
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
	onlyPayer() {
		internalBurn(amount);
	}

	function internalRelease(uint amount)
	private
	inState(State.Committed) {
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
	onlyPayer() {
		internalRelease(amount);
	}

	function setPayerString(string _string)
	public
	onlyPayer() {
		payerString = _string;
		PayerStringUpdated(payerString);
	}

	function setRecipientString(string _string)
	public
	onlyRecipient() {
		recipientString = _string;
		RecipientStringUpdated(recipientString);
	}

	function delayDefaultRelease()
	public
	onlyPayerOrRecipient()
	inState(State.Committed) {
		require(hasDefaultRelease);

		defaultTriggerTime = now + defaultTimeoutLength;
		DefaultReleaseDelayed();
	}

	function callDefaultRelease()
	public
	onlyPayerOrRecipient()
	inState(State.Committed) {
		require(hasDefaultRelease);
		require(now >= defaultTriggerTime);

		if (hasDefaultRelease) {
			internalRelease(this.balance);
		}
		DefaultReleaseCalled();
	}
}