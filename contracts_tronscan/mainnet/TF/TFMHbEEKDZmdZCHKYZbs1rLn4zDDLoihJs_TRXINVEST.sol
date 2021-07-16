//SourceUnit: 合约正式(2).sol

pragma solidity >=0.5.0 <0.7.0;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Token {
  function approve(address _spender, uint256 _value) public returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {}
  function transfer(address _to, uint256 _value) public  returns (bool success){}
}

contract TRXINVEST {
    using SafeMath for uint;
    address payable public  owner;  
    address payable public  administrator; 
    mapping(address => uint256) balances; 
	mapping(address => mapping (address => uint256)) internal allowed;  
	mapping(address => bool) public frozenAccount;  
    uint256 public totalBalance; 
    mapping (address => uint256) totalTokenBalance; 
    mapping (address => uint256) invester;
    mapping (address => mapping (address => uint256)) public tokens;  
    mapping (address => uint256) nodeInvestOf; 
    mapping (address => mapping (address => uint256)) public nodeInvestTokenOf; 

  
    event SetFrozenAccount(address indexed from); 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event NodeInvest(address indexed owner, uint256 value);
    event NodeInvestToken(address indexed owner, address indexed spender, uint256 value);
    event Withdraw(address token, address user, uint amount, address to);

    constructor () public {
        owner = msg.sender; 
        administrator = msg.sender;
    }
    
    function changeOwner(address payable _add) public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0)) ;
        owner = _add ;
        return true;
    }

    function changeAdministrator(address payable _add) public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0)) ;
        administrator = _add ;
        return true;
    }

    function setFrozenAccount(address payable _add) public returns (bool success) {
        require (msg.sender == owner || msg.sender == administrator) ;
        require (_add != address(0)) ;
        frozenAccount[_add] = true;
        emit SetFrozenAccount(_add);
        return true;
    }

    function setFrozenAccountFalse(address payable _add) public returns (bool success) {
        require (msg.sender == owner || msg.sender == administrator) ;
        require (_add != address(0)) ;
        frozenAccount[_add] = false;
        return true;
    }

    
    function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

    function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}


	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
 
    function balanceOf(address _token, address _user) public view returns (uint) {
        return tokens[_token][_user];
    }

    function nodeInvest(uint256 _value) public returns (bool) {
        if(!frozenAccount[msg.sender]){
            nodeInvestOf[msg.sender] = _value;
            totalBalance = totalBalance.add(_value);
            emit NodeInvest(msg.sender, _value);
            return true;
        }else{
            return false;
        }
    }

    function nodeInvestToken(address _spender, uint256 _value) public returns (bool) {
        if(!frozenAccount[msg.sender]){
            nodeInvestTokenOf[msg.sender][_spender] = _value;
            totalTokenBalance[_spender] = totalTokenBalance[_spender].add(_value);
            emit NodeInvestToken(msg.sender, _spender, _value);
            return true;
        }else{
            return false;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        if(!frozenAccount[msg.sender] && !frozenAccount[_to]){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
        
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        if(!frozenAccount[_from] && !frozenAccount[_to]){
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        }else{
            return false;
        }
        
    }

    function invest() payable public returns (bool){
     require(!frozenAccount[msg.sender]);
     require(msg.value > 0);
     invester[msg.sender] = invester[msg.sender].add(msg.value);
     totalBalance = totalBalance.add(msg.value);
     return true;
    }

    function withdraw(address payable _add,uint256 _amount) public returns (bool){
        require(_amount <= totalBalance);
        require(msg.sender == owner || msg.sender == administrator) ;
        require(_add.send(_amount));
        totalBalance = totalBalance.sub(_amount);
        emit Withdraw(owner, msg.sender, _amount, _add);
        return true;
    }

    function withdrawToken(address _token,address _add,uint256 _amount) public returns (bool){
        require(_amount <= totalTokenBalance[_token]);
        require(msg.sender == owner || msg.sender == administrator) ;
        require(Token(_token).transfer(_add, _amount));
        totalTokenBalance[_token] = totalTokenBalance[_token].sub(_amount);
        emit Withdraw(_token, msg.sender, _amount, _add);
        return true;
    }
}