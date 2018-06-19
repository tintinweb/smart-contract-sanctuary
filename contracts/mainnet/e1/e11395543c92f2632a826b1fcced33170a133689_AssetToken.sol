pragma solidity 0.4.11;
 
contract admined {
	address public admin;

	function admined(){
		admin = msg.sender;
	}

	modifier onlyAdmin(){
		if(msg.sender != admin) throw;
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

}

contract Token {

	mapping (address => uint256) public balanceOf;
	// balanceOf[address] = 5;
	string public name;
	string public symbol;
	uint8 public decimal; 
	uint256 public totalSupply;
	event Transfer(address indexed from, address indexed to, uint256 value);


	function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits){
		balanceOf[msg.sender] = initialSupply;
		totalSupply = initialSupply;
		decimal = decimalUnits;
		symbol = tokenSymbol;
		name = tokenName;
	}

	function transfer(address _to, uint256 _value){
		if(balanceOf[msg.sender] < _value) throw;
		if(balanceOf[_to] + _value < balanceOf[_to]) throw;
		//if(admin)

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}

contract AssetToken is admined, Token{


	function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) Token (0, tokenName, tokenSymbol, decimalUnits ){
		totalSupply = initialSupply;
		if(centralAdmin != 0)
			admin = centralAdmin;
		else
			admin = msg.sender;
		balanceOf[admin] = initialSupply;
		totalSupply = initialSupply;	
	}

	function mintToken(address target, uint256 mintedAmount) onlyAdmin{
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}

	function transfer(address _to, uint256 _value){
		if(balanceOf[msg.sender] <= 0) throw;
		if(balanceOf[msg.sender] < _value) throw;
		if(balanceOf[_to] + _value < balanceOf[_to]) throw;
		//if(admin)
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}