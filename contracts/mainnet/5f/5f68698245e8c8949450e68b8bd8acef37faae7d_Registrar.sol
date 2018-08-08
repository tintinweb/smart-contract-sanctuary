pragma solidity ^0.4.11;

/* Ethart Registrar Contract:

	https://ethart.com - The Ethereum Art Network

	Ethart ARCHITECTURE
	-------------------
						_________________________________________
						V										V
	Controller --> Registrar <--> Factory Contract1 --> Artwork Contract1
								  Factory Contract2	    Artwork Contract2
								  		...					...
								  Factory ContractN	    Artwork ContractN

	Controller: The controller contract is the owner of the Registrar contract and can
		- Set a new owner
		- Control the assets of the Registrar (withdraw ETH, transfer, sell, burn pieces owned by the Registrar)
		- The plan is to have the controller contract be a DAO in preparation for a possible ICO
	
	Registrar:
		- The Registrar contract acts as the central registry for all sha256 hashes in the Ethart factory contract network.
		- Approved Factory Contracts can register sha256 hashes using the Registrar interface.
		- ethartArtReward of the art produced and ethartRevenueReward of turnover of the contract network will be awarded to the Registrar.
	
	Factory Contracts:
		- Factory Contracts can spawn Artwork Contracts in line with artists specifications
		- Factory Contracts will only spawn Artwork Contracts who&#39;s sha256 hashes are unique per the Registrar&#39;s sha256 registry
		- Factory Contracts will register every new Artwork Contract with it&#39;s details with the Registrar contract
	
	Artwork Contracts:
		- Artwork Contracts act as minimalist decentralised exchanges for their pieces in line with specified conditions
		- Artwork Contracts will interact with the Registrar to issue buyers of pieces a predetermined amount of Patron tokens based on the transaction value 
		- Artwork Contracts can be interacted with by the Controller via the Registrar using their interfaces to transfer, sell, burn etc pieces
	
	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.
*/

contract Interface {

	// Ethart network interface
	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);			// Check if a sha256 hash is registered
	function isFactoryApproved (address _factory) returns (bool _approved);						// Check if an address is a registered factory contract
	function issuePatrons (address _to, uint256 _amount);										// Issues Patron tokens according to conditions specified in factory contracts
	function approveFactoryContract (address _factoryContractAddress, bool _approved);			// Approves/disapproves factory contracts.
	function changeOwner (address newOwner);													// Change the registrar&#39;s owner.

	function offerPieceForSaleByAddress (address _contract, uint256 _price);					// Sell a piece owned by the registrar.
	function offerPieceForSale (uint256 _price);
	function fillBidByAddress (address _contract);												// Fill a bid with an unindexed piece owned by the registrar
	function fillBid();
	function cancelSaleByAddress (address _contract);											// Cancel the sale of an unindexed piece owned by the registrar
	function cancelSale();
	function offerIndexedPieceForSaleByAddress (address _contract, uint256 _index, uint256 _price);				// Sell an indexed piece owned by the registrar.
	function offerIndexedPieceForSale(uint256 _index, uint256 _price);
	function fillIndexedBidByAddress (address _contract, uint256 _index);						// Fill a bid with an indexed piece owned by the registrar
	function fillIndexedBid (uint256 _index);
	function cancelIndexedSaleByAddress (address _contract);									// Cancel the sale of an unindexed piece owned by the registrar
	function cancelIndexedSale();

	function transferByAddress (address _contract, uint256 _amount, address _to);				// Transfers unindexed pieces owned by the registrar contract
	function transferIndexedByAddress (address _contract, uint256 _index, address _to);			// Transfers indexed pieces owned by the registrar contract
	function approveByAddress (address _contract, address _spender, uint256 _amount);			// Sets an allowance for unindexed pieces owned by the registrar contract
	function approveIndexedByAddress (address _contract, address _spender, uint256 _index);		// Sets an allowance for indexed pieces owned by the registrar contract
	function burnByAddress (address _contract, uint256 _amount);								// Burn an unindexed piece owned by the registrar contract
	function burnFromByAddress (address _contract, uint256 _amount, address _from);				// Burn an unindexed piece owned by annother address
	function burnIndexedByAddress (address _contract, uint256 _index);							// Burn an indexed piece owned by the registrar contract
	function burnIndexedFromByAddress (address _contract, address _from, uint256 _index);		// Burn an indexed piece owned by another address

	// ERC20 interface
	function totalSupply() constant returns (uint256 totalSupply);									// Returns the total supply of an artwork or token
	function balanceOf(address _owner) constant returns (uint256 balance);							// Returns an address&#39; balance of an artwork or token
 	function transfer(address _to, uint256 _value) returns (bool success);							// Transfers pieces of art or tokens to an address
 	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);		// Transfers pieces of art of tokens owned by another address to an address
	function approve(address _spender, uint256 _value) returns (bool success);						// Sets an allowance for an address
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);		// Returns the allowance of an address for another address

	// Additional token functions
	function burn(uint256 _amount) returns (bool success);										// Burns (removes from circulation) unindexed pieces of art or tokens.
																								// In the case of &#39;ouroboros&#39; pieces this function also returns the piece&#39;s
																								// components to the message sender
	
	function burnFrom(address _from, uint256 _amount) returns (bool success);					// Burns (removes from circulation) unindexed pieces of art or tokens
																								// owned by another address. In the case of &#39;ouroboros&#39; pieces this
																								// function also returns the piece&#39;s components to the message sender
	
	// Extended ERC20 interface for indexed pieces
	function transferIndexed (address _to, uint256 __index) returns (bool success);				// Transfers an indexed piece of art
	function transferFromIndexed (address _from, address _to, uint256 _index) returns (bool success);	// Transfers an indexed piece of art from another address
	function approveIndexed (address _spender, uint256 _index) returns (bool success);			// Sets an allowance for an indexed piece of art for another address
	function burnIndexed (uint256 _index);														// Burns (removes from circulation) indexed pieces of art or tokens.
																								// In the case of &#39;ouroboros&#39; pieces this function also returns the
																								// piece&#39;s components to the message sender
	
	function burnIndexedFrom (address _owner, uint256 _index);									// Burns (removes from circulation) indexed pieces of art or tokens
																								// owned by another address. In the case of &#39;ouroboros&#39; pieces this
																								// function also returns the piece&#39;s components to the message sender

}

contract Registrar {

	// Patron token ERC20 public variables
	string public constant symbol = "ART";
	string public constant name = "Patron - Ethart Network Token";
	uint8 public constant decimals = 18;
	uint256 _totalPatronSupply;

	event Transfer(address indexed _from, address _to, uint256 _value);
	event Approval(address indexed _owner, address _spender, uint256 _value);
	event Burn(address indexed _owner, uint256 _amount);

    // Patron token balances for each account
	mapping(address => uint256) public balances;						// Patron token balances

	event NewArtwork(address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);

	// Owner of account approves the transfer of an amount of Patron tokens to another account
	mapping(address => mapping (address => uint256)) allowed;			// Patron token allowances
	
	// Mitigating ERC20 short address attacks (http://vessenes.com/the-erc20-short-address-attack-explained/)
	modifier onlyPayloadSize(uint size)
	{
		require(msg.data.length >= size + 4);
		_;
	}
	
	// BEGIN ERC20 functions (c) BokkyPooBah 2017. The MIT Licence.

	function totalSupply() constant returns (uint256 totalPatronSupply) {
		totalPatronSupply = _totalPatronSupply;
		}

	// What is the balance of a particular account?
	function balanceOf(address _owner) constant returns (uint256 balance) {
 		return balances[_owner];
		}

	// Transfer the balance from owner&#39;s account to another account
	function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) returns (bool success) {
		if (balances[msg.sender] >= _amount 
			&& _amount > 0
 		   	&& balances[_to] + _amount > balances[_to]
			&& _to != 0x0)										// use burn() instead
			{
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
 		   	return true;
			}
			else { return false;}
 		 }

	// Send _value amount of tokens from address _from to address _to
	// The transferFrom method is used for a withdraw workflow, allowing contracts to send
 	// tokens on your behalf, for example to "deposit" to a contract address and/or to charge
 	// fees in sub-currencies; the command should fail unless the _from account has
 	// deliberately authorised the sender of the message via some mechanism; we propose
 	// these standardised APIs for approval:
 	function transferFrom( address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) returns (bool success)
		{
			if (balances[_from] >= _amount
				&& allowed[_from][msg.sender] >= _amount
				&& _amount > 0
				&& balances[_to] + _amount > balances[_to]
				&& _to != 0x0)										// use burn() instead
					{
					balances[_from] -= _amount;
					allowed[_from][msg.sender] -= _amount;
					balances[_to] += _amount;
					Transfer(_from, _to, _amount);
					return true;
					} else {return false;}
		}

	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	// To be extra secure set allowance to 0 and check that none of the allowance was spend between you sending the tx and it getting mined. Only then decrease/increase the allowance.
	// See https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.m9fhqynw2xvt
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
		}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
		}

	// END ERC20 functions (c) BokkyPooBah 2017. The MIT Licence.
	
	// Additional Patron token functions
	
	function burn(uint256 _amount) returns (bool success) {
			if (balances[msg.sender] >= _amount) {
				balances[msg.sender] -= _amount;
				_totalPatronSupply -= _amount;
				Burn(msg.sender, _amount);
				return true;
			}
			else {throw;}
		}

	function burnFrom(address _from, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			_totalPatronSupply -= _value;
			Burn(_from, _value);
			return true;
		}
		else {throw;}
	}

	// BEGIN safe math functions by Open Zeppelin
	// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol

	function mul(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	// END safe math functions by Open Zeppelin

	// Ethart variables
	
	// Register of all SHA256 Hashes
    mapping (bytes32 => address) public SHA256HashRegister;
	
	// Register of all approved factory contracts
	mapping (address => bool) public approvedFactories;
	
	// Register of all approved artwork contracts
	
	// Register of all approved contracts for amending pending withdrawals and issuing Patron tokens
	mapping (address => bool) public approvedContracts;
	
	// Register of all referrers (referee => referrer) used for the affiliate program
	mapping (address => address) public referred;
	
	// Referrer for an artist has to be set _before_ the first piece has been created by an address
	mapping (address => bool) public cantSetReferrer;

	// Register of all artworks and their details by their respective addresses
	struct artwork {
		bytes32 SHA256Hash;
		uint256 editionSize;
		string title;
		string fileLink;
		uint256 ownerCommission;
		address artist;
		address factory;
		bool isIndexed;
		bool isOuroboros;}
	
	mapping (address => artwork) public artworkRegister;

	// An indexed register of all of an artist&#39;s artworks

	// Enter artist address and a running number to get the artist&#39;s artwork addresses
	mapping(address => mapping (uint256 => address)) public artistsArtworks;

	// A running number counting an artist&#39;s artworks
	mapping(address => uint256) public artistsArtworkCount;						

	// Keeps track of the number of artwork contracts in the network
	uint256 public artworkCount;

	// An index of all the artwork contracts in the network
	mapping (uint256 => address) public artworkIndex;

	// All pending withdrawals
	mapping (address => uint256) public pendingWithdrawals;
	uint256 public totalPendingWithdrawals;

	// The address of the Registrar&#39;s owner
	address public owner;
	
	// Determines how many Patrons are issues per donation
	uint256 public donationMultiplier;
	
	// Determines how many Patrons are issues per purchase of an artwork in basis points (10,000 = 100%)
	uint256 public patronRewardMultiplier;
	
	// Determines how much Ethart is entitled to artworks/revenue percentages in basis points (10,000 = 100%)
	uint256 public ethartRevenueReward;
	uint256 public ethartArtReward;
	
	// Determines how much of a percentage a referrer get of ethartRevenueReward
	uint256 public referrerReward;

	// Functions with this modifier can only be executed by a specific address
	modifier onlyBy (address _account)
	{
		require(msg.sender == _account);
		_;
		}

	// Functions with this modifier can only be executed by approved factory contracts
	modifier registeredFactoriesOnly ()
	{
		require(approvedFactories[msg.sender]);
		_;
	}

	// Functions with this modifier can only be executed by approved contracts
	modifier approvedContractsOnly ()
	{
		require(approvedContracts[msg.sender]);
		_;
	}

	// Set the referrer of an artist. This has to be done before an artist creates their first artwork.
	function setReferrer (address _referrer)
		{
			if (referred[msg.sender] == 0x0 && !cantSetReferrer[msg.sender] && _referrer != msg.sender)
			{
				referred[msg.sender] = _referrer;
			}
		}

	function getReferrer (address _artist) returns (address _referrer)
		{
			return referred[_artist];
		}
	
	function setReferrerReward (uint256 _referrerReward) onlyBy (owner)
		{
			uint a;
			if (_referrerReward > 10000 - ethartRevenueReward) {throw;}
			a = 10000 / _referrerReward;
			// 10000 / _referrerReward has to be an even number
			if (a * _referrerReward != 10000) {throw;}
			referrerReward = _referrerReward;
		}
	
	function getReferrerReward () returns (uint256 _referrerReward)
		{
			return referrerReward;
		}

	// Constructor
	function Registrar () {
		owner = msg.sender;
		
		// Donors receive 100 Patrons per 1 wei donation
		donationMultiplier = 100;
		
		// Patrons receive 2.5 Patrons (25,000 basis points) per 1 wei purchases
		patronRewardMultiplier = 25000;
		
		// Ethart receives 2.5% of revenues and artwork&#39;s edition sizes
		ethartRevenueReward = 250;
		ethartArtReward = 250;
		
		// For balanced figures patronRewardMultiplier / donationMultiplier <= ethartRevenueReward
		
		// Referrers receive 10% of ethartRevenueReward
		referrerReward = 1000;
	}

	function setPatronReward (uint256 _donationMultiplier) onlyBy (owner)
		{
			donationMultiplier = _donationMultiplier;
			patronRewardMultiplier = ethartRevenueReward * _donationMultiplier;
			if (patronRewardMultiplier / donationMultiplier > ethartRevenueReward) {throw;}
		}

	function setEthartRevenueReward (uint256 _ethartRevenueReward) onlyBy (owner)
		{
			uint256 a;
			// Ethart revenue reward can never be greater than 10%
			if (_ethartRevenueReward >1000) {throw;}
			a = 10000 / _ethartRevenueReward;
			// Should 10000 / _ethartRevenueReward not be even throw
			if (a * _ethartRevenueReward < 10000) {throw;}
			ethartRevenueReward = _ethartRevenueReward;
		}
	
	function getEthartRevenueReward () returns (uint256 _ethartRevenueReward)
		{
			return ethartRevenueReward;
		}

	function setEthartArtReward (uint256 _ethartArtReward) onlyBy (owner)
		{
			uint256 a;
			// Ethart art reward can never be greater than 10%
			if (_ethartArtReward >1000) {throw;}
			a = 10000 / _ethartArtReward;
			// Should 10000 / _ethartArtReward not be even throw
			if (a * _ethartArtReward < 10000) {throw;}
			ethartArtReward = _ethartArtReward;
		}

	function getEthartArtReward () returns (uint256 _ethartArtReward)
		{
			return ethartArtReward;
		}

	// Allows the current owner to assign a new owner
	function changeOwner (address newOwner) onlyBy (owner) 
		{
			owner = newOwner;
		}

	// Allows approved contracts to issue Patron tokens
	function issuePatrons (address _to, uint256 _amount) approvedContractsOnly
		{
			balances[_to] += _amount / 10000 * patronRewardMultiplier;
			_totalPatronSupply += _amount / 10000 * patronRewardMultiplier;
		}

	// Change the amount of Patron tokens a donor receives
	function setDonationReward (uint256 _multiplier) onlyBy (owner)
		{
			donationMultiplier = _multiplier;
		}

	// Receive Patron tokens in returns for donations
	// Not going to worry about a theoretical Integer overflow here.
	function donate () payable
		{
			balances[msg.sender] += msg.value * donationMultiplier;
			_totalPatronSupply += msg.value * donationMultiplier;
			asyncSend(this, msg.value);
		}

	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros) registeredFactoriesOnly
		{
		if (SHA256HashRegister[_SHA256Hash] == 0x0) {
		   	SHA256HashRegister[_SHA256Hash] = _contract;
			approvedContracts[_contract] = true;
			cantSetReferrer[_artist] = true;
			artworkRegister[_contract].SHA256Hash = _SHA256Hash;
			artworkRegister[_contract].editionSize = _editionSize;
			artworkRegister[_contract].title = _title;
			artworkRegister[_contract].fileLink = _fileLink;
			artworkRegister[_contract].ownerCommission = _ownerCommission;
			artworkRegister[_contract].artist = _artist;
			artworkRegister[_contract].factory = msg.sender;
			artworkRegister[_contract].isIndexed = _indexed;
			artworkRegister[_contract].isOuroboros = _ouroboros;
			artworkIndex[artworkCount] = _contract;
			artistsArtworks[_artist][artistsArtworkCount[_artist]] = _contract;
			artistsArtworkCount[_artist]++;
			NewArtwork (_contract, _SHA256Hash, _editionSize, _title, _fileLink, _ownerCommission, _artist, _indexed, _ouroboros);
			artworkCount++;
			}
			else {throw;}
		}

	// Check if a specific sha256 hash has been used by another artwork before
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered)
		{
		if (SHA256HashRegister[_SHA256Hash] == 0x0)
			{return false;}
		else {return true;}
		}

	// Approve factory contracts
	function approveFactoryContract (address _factoryContractAddress, bool _approved) onlyBy (owner)
		{
			approvedFactories[_factoryContractAddress] = _approved;
		}
	
	// Open Zeppelin asyncSend function for pull payments
	function asyncSend (address _payee, uint256 _amount) approvedContractsOnly
		{
			pendingWithdrawals[_payee] = add(pendingWithdrawals[_payee], _amount);
			totalPendingWithdrawals = add(totalPendingWithdrawals, _amount);
		}

	function withdrawPaymentsRegistrar (address _dest, uint256 _payment) onlyBy (owner)
		{
			if (_payment == 0) {
				throw;
			}

			if (this.balance < _payment) {
				throw;
			}
			
			totalPendingWithdrawals = sub(totalPendingWithdrawals, _payment);
			pendingWithdrawals[this] = sub(pendingWithdrawals[this], _payment);

			if (!_dest.send(_payment)) {
				throw;
			}
		}

	function withdrawPayments() {
		address payee = msg.sender;
		uint256 payment = pendingWithdrawals[payee];

		if (payment == 0) {
			throw;
		}

		if (this.balance < payment) {
			throw;
		}

		totalPendingWithdrawals = sub(totalPendingWithdrawals, payment);
		pendingWithdrawals[payee] = 0;

		if (!payee.send(payment)) {
			throw;
		}
	}

	function transferByAddress (address _contract, uint256 _amount, address _to) onlyBy (owner) 
		{
			Interface c = Interface(_contract);
			c.transfer(_to, _amount);
		}

	function transferIndexedByAddress (address _contract, uint256 _index, address _to) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.transferIndexed(_to, _index);
		}

	function approveByAddress (address _contract, address _spender, uint256 _amount) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.approve(_spender, _amount);
		}	

	function approveIndexedByAddress (address _contract, address _spender, uint256 _index) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.approveIndexed(_spender, _index);
		}

	function burnByAddress (address _contract, uint256 _amount) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.burn(_amount);
		}

	function burnFromByAddress (address _contract, uint256 _amount, address _from) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.burnFrom (_from, _amount);
		}

	function burnIndexedByAddress (address _contract, uint256 _index) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.burnIndexed(_index);
		}

	function burnIndexedFromByAddress (address _contract, address _from, uint256 _index) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.burnIndexedFrom(_from, _index);
		}

	function offerPieceForSaleByAddress (address _contract, uint256 _price) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.offerPieceForSale(_price);
		}

	// Fill a bid with an unindexed piece owned by the registrar
	function fillBidByAddress (address _contract) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.fillBid();
		}

	// Cancel the sale of an unindexed piece owned by the registrar
	function cancelSaleByAddress (address _contract) onlyBy (owner)	
		{
			Interface c = Interface(_contract);
			c.cancelSale();
		}

	// Sell an indexed piece owned by the registrar.
	function offerIndexedPieceForSaleByAddress (address _contract, uint256 _index, uint256 _price) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.offerIndexedPieceForSale(_index, _price);
		}

	// Fill a bid with an indexed piece owned by the registrar
	function fillIndexedBidByAddress (address _contract, uint256 _index) onlyBy (owner)	
		{
			Interface c = Interface(_contract);
			c.fillIndexedBid(_index);
		}

	// Cancel the sale of an unindexed piece owned by the registrar
	function cancelIndexedSaleByAddress (address _contract) onlyBy (owner)
		{
			Interface c = Interface(_contract);
			c.cancelIndexedSale();
		}
	
	// use donate () for donations and you will get donationMultiplier * your donation in Patron tokens. Yay!
	function() payable
		{
			if (!approvedContracts[msg.sender]) {throw;}
		}
}