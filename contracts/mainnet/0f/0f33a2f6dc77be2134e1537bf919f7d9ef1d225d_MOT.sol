pragma solidity ^0.4.22;

//防止溢出
library SafeMath {
//乘以
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
 //除以
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
//减
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
	//加
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MOT is ERC20 {
    
    using SafeMath for uint256;
	//拥有者
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	//黑名单
    mapping (address => bool) public blacklist;

    string public constant name = "MOT";
    string public constant symbol = "MOT";
    uint public constant decimals = 18;
    
    uint256 public totalSupply = 100000000e18;
	//分配的数量
    uint256 public totalDistributed = 20000000e18;
	//余额 = 总量减去已经分配出去的
    uint256 public totalRemaining = totalSupply.sub(totalDistributed);
	
    uint256 public value = 1500e18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint256 value);

	//分配完成
    bool public distributionFinished = false;
    
	//是否可以分配
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    //仅仅拥有者 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    //判断是否在白名单
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
	//构造方法
     constructor() public {
        owner = msg.sender;
		//把设定好的数量分配给创建者
        balances[owner] = totalDistributed;
    }
    //设置拥有者
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    //完成分配
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    //分配
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
        
		//分配的数量大于或者等于总量的时候设置分配结束
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function () external payable {
        getTokens();
     }
    
	//获取token 没有分配结束，并且没有获取过。
    function getTokens() payable canDistr onlyWhitelist public {
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
		//分配给谁的
        address investor = msg.sender;
		//分配的数量
        uint256 toGive = value;
        
		//分配
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        value = value.div(100000).mul(99999);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    //获取某一个token的余额
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    //提取eth
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    //销毁多少个代币
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
	//提取代币
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}