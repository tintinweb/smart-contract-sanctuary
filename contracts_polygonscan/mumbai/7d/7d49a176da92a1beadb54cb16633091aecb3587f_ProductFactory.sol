/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

pragma solidity >=0.4.22 <0.9.0;

contract ProductFactory {

	struct Product {
		string name;
		uint8 status;
		address owner;
		address delegate;
	}

	Product[] public products;

	mapping(uint => address) public productOwner;
	mapping(address => uint) public ownerProductCount;


	event NewProduct(uint pid, string name);

	function createProduct(string memory _name) public {
		require(ownerProductCount[msg.sender] <= 10, "Tiene muchos productos");
		products.push(
			Product(
				_name,
				0,
				msg.sender,
				address(0)
			)
		);
		uint id = products.length - 1;
		productOwner[id] = msg.sender;
		ownerProductCount[msg.sender]++;
		emit NewProduct(id, _name);


	}






}