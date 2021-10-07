/**
 *Submitted for verification at polygonscan.com on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract Decidsk {
	address payable owner;

	struct User {
		address did;
		uint[] products;
	}

    struct Product {
		address owner;
		bytes32 name;
        uint id;
	}

	mapping(address => User)  public usersMapping;
    Product[] public products;
	User[] users;

	event ProductsChanged(
		uint indexed productId,
		address indexed user
	);

	event UserAuthorized(
		uint256 timestamp,
		address indexed user
	);

	constructor() public {
		owner = msg.sender;
		products.push(Product(owner,'GoToAssist', 1));
		products.push(Product(owner,'GoToMeeting', 2));
		products.push(Product(owner,'GoToWebinar', 3));
		products.push(Product(owner,'GoToConnect', 4));
	}

	function addProductToUser(address user, uint productId) public {
		require(msg.sender == owner);

		usersMapping[user].products.push(productId);
		emit ProductsChanged(productId, user);
	}

	function getUsersProducts(address user) public view returns(uint[] memory) {
        require(msg.sender == owner);

		return(usersMapping[user].products);
	}

    function addProduct(bytes32 productName, uint productId) public {
        require(msg.sender == owner);

        products.push(Product(owner,productName, productId));
    }

	function addUser(address userAddress) public {
		require(msg.sender == owner);

		users.push(User(userAddress, new uint[](0)));
        usersMapping[userAddress] = User(userAddress, new uint[](0));
	}

	function getUsers() public view returns(address[] memory) {
		address[] memory dids = new address[](users.length);

		for (uint i = 0; i < users.length; i++) {
			dids[i] = users[i].did;
		}

		return (dids);
	}

	function userAuthorized(address user) public {
		require(msg.sender == owner);

		emit ProductsChanged(block.timestamp, user);
	}
}