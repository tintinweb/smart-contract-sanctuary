pragma solidity ^0.4.11;
 
contract admined {
	address public admin;

	function admined(){
		admin = msg.sender;
	}

	modifier onlyAdmin(){
		require(msg.sender == admin);
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

}

contract AllInOne {

	mapping (address => uint256) public balanceOf;
	// balanceOf[address] = 5;
	string public name;
	string public symbol;
	uint8 public decimal; 
	uint256 public intialSupply=500000000;
	uint256 public totalSupply;
	
	
	event Transfer(address indexed from, address indexed to, uint256 value);


	function AllInOne(){
		balanceOf[msg.sender] = intialSupply;
		totalSupply = intialSupply;
		decimal = 2;
		symbol = "AIO";
		name = "AllInOne";
	}

	function transfer(address _to, uint256 _value){
		require(balanceOf[msg.sender] > _value);
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
		//if(admin)

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}

contract AssetToken is admined, AllInOne{


	function AssetToken() AllInOne (){
		totalSupply = 500000000;
		admin = msg.sender;
		balanceOf[admin] = 500000000;
		totalSupply = 500000000;	
	}

	function mintToken(address target, uint256 mintedAmount) onlyAdmin{
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}

	function transfer(address _to, uint256 _value){
		require(balanceOf[msg.sender] > 0);
		require(balanceOf[msg.sender] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]);
		//if(admin)
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}