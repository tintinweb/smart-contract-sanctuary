pragma solidity ^0.4.24;

contract Ownable {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor() public {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external;
  function allowance(address owner, address spender) external view returns (uint256) ;
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract KuberaToken is Ownable, ERC20 {
    using SafeMath for uint;
     
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    constructor() public {
        _symbol = &#39;KBR&#39;;
        _name = &#39;Kubera Token&#39;;
        _decimals = 0;
        _totalSupply = 10000000000;
                
        _owner = msg.sender;
       
        balances[msg.sender] = _totalSupply;
    }

    function owner()
        external
        view
        returns (address) {
        return _owner;
    }
    
    function name()
        external
        view
        returns (string) {
        return _name;
    }

    function symbol()
        external
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        external
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        external
        view
        returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
	}
    
    function transfer(address _to, uint256 _value) external {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
    }

  	function transferFrom(address _from, address _to, uint _value) external {
    	uint _allowance = allowed[_from][msg.sender];

    	balances[_to] = balances[_to].add(_value);
    	balances[_from] = balances[_from].sub(_value);
    	allowed[_from][msg.sender] = _allowance.sub(_value);
    	emit Transfer(_from, _to, _value);
  	}

  	function approve(address _spender, uint _value) external {
  	    require(_value > 0);
  	    
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
  	}

  	function allowance(address _from, address _spender) external view returns (uint256) {
    	return allowed[_from][_spender];
  	}
  
    function paybackToOwner(address _target) external onlyOwner {  
        uint256 amount =  balances[_target];
        	
        require(_target != address(0));
        require(amount > 0);
                    
        balances[_target] = 0;
        balances[_owner]  = SafeMath.add(balances[_owner], amount);
        emit Transfer(_target, _owner, amount);
    }
}