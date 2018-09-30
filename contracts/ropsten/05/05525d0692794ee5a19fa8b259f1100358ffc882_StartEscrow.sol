pragma solidity ^0.4.24;

contract StartEscrow {
	address[] public contracts;
    address public lastContractAddress;
    
    event newPurchaseContract(
       address contractAddress
    );

	constructor()
		public
	{

	}

	function getContractCount()
		public
		constant
		returns(uint contractCount)
	{
		return contracts.length;
	}

	// deploy a new purchase contract
	function newPurchase(string contractHash)
		public
		payable
		returns(address newContract)
	{
		Purchase c = (new Purchase).value(msg.value)(address(msg.sender), contractHash);
		contracts.push(c);
		lastContractAddress = address(c);
		emit newPurchaseContract(c);
		return c;
	}

	//tell me a position and I will tell you its address   
	function seePurchase(uint pos)
		public
		constant
		returns(address contractAddress)
	{
		return address(contracts[pos]);
	}
}

contract Purchase {
	uint public value;
	address public seller;
	address public buyer;
	string public ipfsHash;
	enum State { Created, Locked, Inactive }
	State public state;
    
	// Ensure that `msg.value` is an even number.
	// Division will truncate if it is an odd number.
	// Check via multiplication that it wasn&#39;t an odd number.
	constructor(address contractSeller, string contractHash) public payable {
		seller = contractSeller;
		ipfsHash = contractHash;
		value = msg.value / 2;
		require((2 * value) == msg.value);
	}

	modifier condition(bool _condition) {
		require(_condition);
		_;
	}

	modifier onlyBuyer() {
		require(msg.sender == buyer);
		_;
	}

	modifier onlySeller() {
		require(msg.sender == seller);
		_;
	}

	modifier inState(State _state) {
		require(state == _state);
		_;
	}

	event Aborted();
	event PurchaseConfirmed();
	event ItemReceived();

	/// Abort the purchase and reclaim the ether.
	/// Can only be called by the seller before
	/// the contract is locked.
	function abort()
		public
		onlySeller
		inState(State.Created)
	{
		emit Aborted();
		state = State.Inactive;
		seller.transfer(address(this).balance);
	}

	/// Confirm the purchase as buyer.
	/// Transaction has to include `2 * value` ether.
	/// The ether will be locked until confirmReceived
	/// is called.
	function confirmPurchase()
		public
		inState(State.Created)
		condition(msg.value == (2 * value))
		payable
	{
		emit PurchaseConfirmed();
		buyer = msg.sender;
		state = State.Locked;
	}

	/// Confirm that you (the buyer) received the item.
	/// This will release the locked ether.
	function confirmReceived()
		public
		onlyBuyer
		inState(State.Locked)
	{
		emit ItemReceived();
		// It is important to change the state first because
		// otherwise, the contracts called using `send` below
		// can call in again here.
		state = State.Inactive;

		// NOTE: This actually allows both the buyer and the seller to
		// block the refund - the withdraw pattern should be used.
		buyer.transfer(value);
		seller.transfer(address(this).balance);
	}
}