pragma solidity ^0.4.11;

/* Ethart unindexed Factory Contract:

	Ethart ARCHITECTURE
	-------------------
						_________________________________________
						V										V
	Controller --> Registrar <--> Factory Contract1 --> Artwork Contract1
								  Factory Contract2	    Artwork Contract2
								  		...					...
								  Factory ContractN	    Artwork ContractN

	Controller: The controler contract is the owner of the Registrar contract and can
		- Set a new owner
		- Controll the assets of the Registrar (withdraw ETH, transfer, sell, burn pieces owned by the Registrar)
		- The plan is to replace the controller contract with a DAO in preperation for a possible ICO
	
	Registrar:
		- The Registrar contract atcs as the central registry for all sha256 hashes in the Ethart factory contract network.
		- Approved Factory Contracts can register sha256 hashes using the Registrar interface.
		- 2.5% of the art produced and 2.5% of turnover of the contract network will be transfered to the Registrar.
	
	Factory Contracts:
		- Factory Contracts can spawn Artwork Contracts in line with artists specifications
		- Factory Contracts will only spawn Artwork Contracts who&#39;s sha256 hashes are unique per the Registrar&#39;s sha256 registry
		- Factory Contracts will register every new Artwork Contract with it&#39;s details with the Registrar contract
	
	Artwork Contracts:
		- Artwork Contracts act as minimalist decentralized exchanges for their pieces in line with specified conditions
		- Artwork Contracts will interact with the Registrar to issue buyers of pieces a predetermined amount of Patron tokens based on the transaction value 
		- Artwork Contracts can be interacted with by the Controller via the Registrar using their interfaces to transfer, sell, burn etc pieces
	
	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.
*/

contract Interface {

	// Ethart network interface
	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);			// Check if a sha256 hash is registared
	function isFactoryApproved (address _factory) returns (bool _approved);						// Check if an address is a registred factory contract
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
    function transferIndexedByAddress (address _contract, uint256 _index, address _to);		// Transfers indexed pieces owned by the registrar contract
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
	function transferIndexed (address _to, uint256 __index) returns (bool success);			// Transfers an indexed piece of art
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
	
	// BEGIN ERC20 functions (c) BokkyPooBah 2017. The MIT Licence.

    function totalSupply() constant returns (uint256 totalPatronSupply) {
		totalPatronSupply = _totalPatronSupply;
		}

	// What is the balance of a particular account?
	function balanceOf(address _owner) constant returns (uint256 balance) {
 		return balances[_owner];
		}

	// Transfer the balance from owner&#39;s account to another account
	function transfer(address _to, uint256 _amount) returns (bool success) {
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
 	// deliberately authorized the sender of the message via some mechanism; we propose
 	// these standardized APIs for approval:
 	function transferFrom( address _from, address _to, uint256 _amount) returns (bool success)
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

	function burnFrom(address _from, uint256 _value) returns (bool success) {
		if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			_totalPatronSupply -= _value;
			Burn(_from, _value);
			return true;
		}
		else {throw;}
	}

	// Ethart variables
    mapping (bytes32 => address) public SHA256HashRegister;		// Register of all SHA256 Hashes
	mapping (address => bool) public approvedFactories;			// Register of all approved factory contracts
	mapping (address => bool) public approvedContracts;			// Register of all approved artwork contracts
	mapping (address => address) public referred;				// Register of all referrers (referree => referrer) used for the affiliate program
	mapping (address => bool) public cantSetReferrer;			// Referrer for an artist has to be set _before_ the first piece has been created by an address

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
	
	mapping (address => artwork) public artworkRegister;		// Register of all artworks and their details

	// An indexed register of all of an artist&#39;s artworks
	mapping(address => mapping (uint256 => address)) public artistsArtworks;	// Enter artist address and a running number to get the artist&#39;s artwork addresses.
	mapping(address => uint256) public artistsArtworkCount;						// A running number counting an artist&#39;s artworks
	mapping(address => address) public artworksFactory;							// Maps all artworks to their respective factory contracts

	uint256 artworkCount;										// Keeps track of the number of artwork contracts in the network
	
	mapping (uint256 => address) public artworkIndex;			// An index of all the artwork contracts in the network

	address public owner;										// The address of the contract owner
	
	uint256 public donationMultiplier;

    // Functions with this modifier can only be executed by a specific address
    modifier onlyBy (address _account)
    {
        require(msg.sender == _account);
        _;
    }

    // Functions with this modifier can only be executed by approved factory contracts
    modifier registerdFactoriesOnly ()
    {
        require(approvedFactories[msg.sender]);
        _;
    }

	modifier approvedContractsOnly ()
	{
		require(approvedContracts[msg.sender]);
		_;
	}

	function setReferrer (address _referrer)
		{
			if (referred[msg.sender] == 0x0 && !cantSetReferrer[msg.sender])
			{
				referred[msg.sender] = _referrer;
			}
		}

	function Registrar () {
		owner = msg.sender;
		donationMultiplier = 100;
	}

	// allows the current owner to assign a new owner
	function changeOwner (address newOwner) onlyBy (owner) 
		{
			owner = newOwner;
		}

	function issuePatrons (address _to, uint256 _amount) approvedContractsOnly
		{
			balances[_to] += _amount;
			_totalPatronSupply += _amount;
		}

	function setDonationReward (uint256 _multiplier) onlyBy (owner)
		{
			donationMultiplier = _multiplier;
		}

	function donate () payable
		{
			balances[msg.sender] += msg.value * donationMultiplier;
			_totalPatronSupply += msg.value * donationMultiplier;
		}

	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros) registerdFactoriesOnly
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
			artworksFactory[_contract] = msg.sender;
			NewArtwork (_contract, _SHA256Hash, _editionSize, _title, _fileLink, _ownerCommission, _artist, _indexed, _ouroboros);
			artworkCount++;
			}
			else {throw;}
		}

	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered)
		{
		if (SHA256HashRegister[_SHA256Hash] == 0x0)
			{return false;}
		else {return true;}
		}


	function approveFactoryContract (address _factoryContractAddress, bool _approved) onlyBy (owner)
		{
			approvedFactories[_factoryContractAddress] = _approved;
		}

	function isFactoryApproved (address _factory) returns (bool _approved)
		{
			if (approvedFactories[_factory])
			{
				return true;
			}
			else {return false;}
		}

	function withdrawFunds (uint256 _ETHAmount, address _to) onlyBy (owner)
		{
			if (this.balance >= _ETHAmount)
			{
				_to.transfer(_ETHAmount);
			}
			else {throw;}
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

	function fillBidByAddress (address _contract) onlyBy (owner)							// Fill a bid with an unindexed piece owned by the registrar
		{
			Interface c = Interface(_contract);
			c.fillBid();
		}

	function cancelSaleByAddress (address _contract) onlyBy (owner)							// Cancel the sale of an unindexed piece owned by the registrar
		{
			Interface c = Interface(_contract);
			c.cancelSale();
		}

	function offerIndexedPieceForSaleByAddress (address _contract, uint256 _index, uint256 _price) onlyBy (owner)			// Sell an indexed piece owned by the registrar.
		{
			Interface c = Interface(_contract);
			c.offerIndexedPieceForSale(_index, _price);
		}

	function fillIndexedBidByAddress (address _contract, uint256 _index) onlyBy (owner)					// Fill a bid with an indexed piece owned by the registrar
		{
			Interface c = Interface(_contract);
			c.fillIndexedBid(_index);
		}

	function cancelIndexedSaleByAddress (address _contract) onlyBy (owner)								// Cancel the sale of an unindexed piece owned by the registrar
		{
			Interface c = Interface(_contract);
			c.cancelIndexedSale();
		}
	
	function() payable
		{
			if (!approvedContracts[msg.sender]) {throw;}						// use donate () for donations and you will get donationMultiplier * your donation in Patron tokens. Yay!
		}

	// Semi uinversal call function for unforseen future Ethart network contract types and use cases. String format: "<functionName>(address,address,uint256,uint256,bool,string,bytes32)"
	function callContractFunctionByAddress(address _contract, string functionNameAndTypes, address _address1, address _address2, uint256 _value1, uint256 _value2, bool _bool, string _string, bytes32 _bytes32) onlyBy (owner)
	{
		if(!_contract.call(bytes4(sha3(functionNameAndTypes)),_address1, _address2, _value1, _value2, _bool, _string, _bytes32)) {throw;}
	}
}