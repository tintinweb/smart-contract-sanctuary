pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Standard {
    using SafeMath for uint256;
	uint256 public totalSupply;
	string public name;
	uint256 public decimals;
	string public symbol;
	address public owner;

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	
	bool public buy = true;
	bool public sell = true;

    function endBuy() public returns (bool) {
		require(msg.sender == owner);
        buy = false;
        return true;
    }
    function startBuy() public returns (bool) {
		require(msg.sender == owner);
        buy = true;
        return true;
    }
    function endSell() public returns (bool) {
		require(msg.sender == owner);
        sell = false;
        return true;
    }
    function startSell() public returns (bool) {
		require(msg.sender == owner);
        sell = true;
        return true;
    }
    

  function ERC20Standard(uint256 _totalSupply, string _symbol, string _name) public {
		decimals = 18;
		symbol = _symbol;
		name = _name;
		owner = msg.sender;
        totalSupply = _totalSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;
  }
	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) constant public returns (uint256) {
		return balances[_owner];
	}

	function getPrice() constant public returns (uint256) {
        uint256 supply = totalSupply.sub(balanceOf(address(this)));
        uint one = 1;
        uint cw = one.div(10);
        uint256 balance = address(this).balance;
        uint256 price  =  balance.div((supply.mul(cw)));
        return price;
	}
	
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if(_to == address(this)){
            if(sell){
                //Token的供应量【Smart Token&#39;s Supply】，简称Supply；
                uint256 supply = totalSupply.sub(balanceOf(address(this)));
                //储备金固定比率【Connector Weight】，简称CW
                uint one = 1;
                uint cw = one.div(10);
                //储备金余额【Connector Balance】，简称Balance；
                uint256 balance = address(this).balance;
                //Token的价格【Smart Token&#39;s Price 】，简称Price；
                uint256 price  =  balance.div((supply.mul(cw)));
                //Token的总市值【Smart Token&#39;s Total Value】，简称TotalValue；
                uint256 totalValue =  price.mul(supply);
                uint256 eth_Return = balance.mul((one.sub((one.sub(_amount.div(supply))) ** (one.div(cw)))));
                
                require(eth_Return <= address(this).balance);
                balances[msg.sender] = balances[msg.sender].sub(_amount);
                balances[_to] = balances[_to].add(_amount);
                emit Transfer(msg.sender, _to, _amount);
                return true;
            }else{
                return true;
            }
            
        } else {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
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

	function approve(address _spender, uint256 _value) public {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _owner, address _spender) constant public returns (uint256) {
		return allowed[_owner][_spender];
	}

	function mint(uint256 amount) public {
		assert(amount >= 0);
		require(msg.sender == owner);
		balances[msg.sender] += amount;
		totalSupply += amount;
	}
	
	function () payable public{
	    require(msg.value >= 0.001 ether);
	    if(msg.sender != owner){
    	        if(buy){
    	        //Token的供应量【Smart Token&#39;s Supply】，简称Supply；
                uint256 supply = totalSupply.sub(balanceOf(address(this)));
                //储备金固定比率【Connector Weight】，简称CW
                uint one = 1;
                uint cw = one.div(10);
                //储备金余额【Connector Balance】，简称Balance；
                uint256 balance = address(this).balance;
                //Token的价格【Smart Token&#39;s Price 】，简称Price；
                uint256 price  =  balance.div((supply.mul(cw)));
                //Token的总市值【Smart Token&#39;s Total Value】，简称TotalValue；
                uint256 totalValue =  price.mul(supply);
                uint256 token_Return = supply.mul(((one.add(msg.value.div(balance))) ** cw.sub(1)));
                
                //require(token_Return <= balances[this].div(2));
                balances[this] = balances[this].sub(token_Return);
                balances[msg.sender] = balances[msg.sender].add(token_Return);
                emit Transfer(this, msg.sender, token_Return);
    	    }
	    }
	    
	}
	
	function withdraw() public {
		require(msg.sender == owner);
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawForeignTokens(address _tokenContract)  public returns (bool) {
		require(msg.sender == owner);
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner); // validate input

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
    }

	//Event which is triggered to log all transfers to this contract&#39;s event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
		);

}