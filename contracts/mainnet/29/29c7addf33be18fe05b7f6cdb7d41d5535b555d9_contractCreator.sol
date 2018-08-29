pragma solidity ^0.4.24;
 //     https://contractcreator.ru/ethereum/sozdaem-kontrakt-dlya-ico-chast-1/
contract contractCreator {
 
    uint256 totalSupply_; 
    string public constant name = "ContractCreator.ru Token";
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 10000000*(10**uint256(decimals));
    uint256 public buyPrice; //цена продажи
    address public owner; // адрес создателя токена, чтобы он мог снять эфиры с контракта
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }
 
    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
  }
 //--------------- Новое

	
	function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value); 
        balances[_from] = balances[_from] - _value; 
        balances[_to] = balances[_to] + _value; 
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value)  public returns (bool) {
        _transfer(msg.sender, _to, _value);
    }


		function _buy(address _from, uint256 _value) internal {
		uint256 _amount = (_value / buyPrice)*(10**uint256(decimals));
		_transfer(this, _from, _amount);
		emit Transfer(this, _from, _amount);
		}
		
		function() public payable{
			 _buy(msg.sender, msg.value);
		}
		
		function buy() public payable {
			_buy(msg.sender, msg.value);
		}
		

		function transferEthers() public {
			require(msg.sender == owner);
			owner.transfer(address(this).balance);
		}


//---------------------------------------------


 
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]); 
        balances[_from] = balances[_from] - _value; 
        balances[_to] = balances[_to] + _value; 
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value; 
        emit Transfer(_from, _to, _value); 
        return true; 
        } 
 
     function increaseApproval(address _spender, uint _addedValue) public returns (bool) { 
     allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue; 
     emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
     return true; 
     } 
 
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) { 
    uint oldValue = allowed[msg.sender][_spender]; 
    if (_subtractedValue > oldValue) {
 
        allowed[msg.sender][_spender] = 0;
    } 
        else {
        allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
    }
	

 
    constructor() public {
        totalSupply_ = initialSupply;
        balances[this] = initialSupply;
		buyPrice = 0.001 ether;
		owner = msg.sender;
    }
}