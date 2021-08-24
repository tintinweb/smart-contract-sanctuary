/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.16;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface IERC20 {
    

    function balanceOf(address account) external view returns (uint256);

 
    function transfer(address recipient, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is IERC20{
    using SafeMath for uint256;
    uint256 public txFee = 3;
    uint256 public burnFee = 1;
    address public feeAddress;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) internal allowed;
	mapping(address => bool) tokenBlacklist;
    mapping(address => uint256) balances;

    event Blacklist(address indexed blackListed, bool value);
  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false,"you're in blacklist, please contact our dev team to get more information");
        require(_to != address(0), "the receiver address can't be Zero");
        require(_value <= balances[msg.sender], "the amount exceeds the allowance between 02 users");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 tempValue = _value;
        
        if(txFee > 0 && msg.sender != feeAddress){
            uint256 _txfee = tempValue.div(uint256(100 / txFee));
            balances[feeAddress] = balances[feeAddress].add(_txfee);
            emit Transfer(msg.sender, feeAddress, _txfee);
            _value =  _value.sub(_txfee);
        }
    
        if(burnFee > 0 && msg.sender != feeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue); 
        }
        
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false, "you're in blacklist, please contact our dev team to get more information");
        require(_to != address(0), "the receiver address can't be Zero");
        require(_value <= balances[_from], "the amount exceeds the balance of the sender");
        require(_value <= allowed[_from][msg.sender], "the amount exceeds the allowance between 02 users");
        balances[_from] = balances[_from].sub(_value);
        uint256 tempValue = _value;
        
        if(txFee > 0 && _from != feeAddress){
            uint256 _txfee = tempValue.div(uint256(100 / txFee));
            emit Transfer(_from, feeAddress, _txfee);
            _value =  _value.sub(_txfee);
        }
    
        if(burnFee > 0 && _from != feeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(_from, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue); 
        }  

        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
  


    function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
	    require(tokenBlacklist[_address] != _isBlackListed, "the user is already in the Blacklist");
	    tokenBlacklist[_address] = _isBlackListed;
	    emit Blacklist(_address, _isBlackListed);
	    return true;
    }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
  function blackListAddress(address listAddress,  bool isBlackListed) public whenNotPaused onlyOwner  returns (bool success) {
	return super._blackList(listAddress, isBlackListed);
  }
  
}


contract GPLToken is PausableToken {
    string public constant name = "Pangolins";
    string public constant symbol = "GPL";
    uint256 public constant decimals = 18;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

	
    constructor(uint256 _supply,address _feeAddress) public payable {
        totalSupply = _supply * 10**decimals;
        owner = msg.sender;
        balances[owner] = totalSupply;
	    feeAddress = _feeAddress;
        emit Transfer(address(0), owner, totalSupply);
    }
	
	function burn(uint256 _value) public{
		_burn(msg.sender, _value);
	}
	
	function updateFee(uint256 _txFee,uint256 _burnFee,address _FeeAddress) onlyOwner public{
	    txFee = _txFee;
	    burnFee = _burnFee;
	    feeAddress = _FeeAddress;
	}
	
	function _burn(address _address, uint256 _value)  internal {
		require(_value <= balances[_address], "the amount exceeds the balance of the user");
		balances[_address] = balances[_address].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_address, _value);
		emit Transfer(_address, address(0), _value);
	}

    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }
}