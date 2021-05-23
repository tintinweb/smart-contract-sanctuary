/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract MyApp {

	/*
		holds the address of the owner of the contract
		owner -> the address which deploys this smart contract on the nwtwork.
	*/
	address public owner;
	/*
		productId is used to provide a unique ID to every product that is added.
		It increments every time a new product is created.
	*/
	uint productId = 0;

	// define all custom structs

	struct Manufacturer {
		bool exists;
		string name;
		address _address;
	}

	struct Product {
		bool exists;
		uint id;
		string name;
		string model;
		address manufacturer;
		address curOwner;
		address[] owners;
	}

	// struct Customer {
	// 	bool exists;
	// 	string name;
	// 	address _address;
	// }


	// mapping(address => Customer) public customers;
	mapping(address => Manufacturer) public manufacturers;
	mapping(uint => Product) products;


	// events to be emitted when certain operatons are completed
	event ManufacturerCreated(string name, address _address);
	event ProductCreated(uint id, address manufacturer);
	event OwnershipUpdated(uint id, address newOwner);


	/*
		Constructor is called when this contract is deployed on the network.
		It sets the owner of the contract as the address which deploys it.
	*/
	constructor() {
		owner = msg.sender;
	}


	/*
		Used to create a new Manufacturer
		Can be called only by the owner of the contract
	*/
	function createManufacturer(string memory _name, address _address) public {
		require(msg.sender == owner, "Only owner is authorised to create a manufacturer!");

		Manufacturer storage m = manufacturers[_address];
		m.exists = true;
		m.name = _name;
		m._address = _address;
		emit ManufacturerCreated(_name, _address);
	}


	/*
		Used to create a new product
		Can be called only by the manufacturer
	*/
	function createProduct(string memory _name, string memory _model) public {
		require(manufacturers[msg.sender].exists == true, "You are not a Manufacturer!");

		Product storage p = products[productId];
		p.exists = true;
		p.id = productId;
		p.name = _name;
		p.model = _model;
		p.manufacturer = msg.sender;
		p.curOwner = msg.sender;
		// push cur owner(manufacturer) to owners array
		p.owners.push(msg.sender);

		productId++;
		emit ProductCreated(productId-1, msg.sender);
	}


	/*
		Returns a tuple of a product struct
		- p.owners[0] is the first owner (manufacturer)
		- last address in the owners list is the current owner
	*/
	function getProduct(uint _id) public view returns(Product memory) {
		return products[_id];
	}


	/*
		This function is called when an owner sells a product to new customer.
		It updates the current owner of the product, and also adds them to owners list.
		* only the current owner of the product is allowed to sell it
	*/
	function updateOwnership(uint _id, address _newOwner) public {
		Product storage p = products[_id];
		require(p.curOwner == msg.sender, "Not authorized");
		
		p.curOwner = _newOwner;
		p.owners.push(_newOwner);

		emit OwnershipUpdated(_id, _newOwner);
	}

}