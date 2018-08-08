pragma solidity ^0.4.11;

library SafeMath {
	function mul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal returns(uint) {
		uint c = a / b;
		return c; 
	}

	function sub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function max64(uint64 a, uint64 b) internal constant returns(uint64) {
		return a >= b ? a : b;
	}

	function min64(uint64 a, uint64 b) internal constant returns(uint64) {
		return a < b ? a : b;
	}

	function max256(uint256 a, uint256 b) internal constant returns(uint256) {
		return a >= b ? a : b;
	}

	function min256(uint256 a, uint256 b) internal constant returns(uint256) {
		return a < b ? a : b;
	}

	function assert(bool assertion) internal {
		if(!assertion) {
			throw;
		}
	}
}

contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address who) constant returns(uint);
	function transfer(address to, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
}

contract BasicToken is ERC20Basic {
	using SafeMath 	for uint;
	mapping(address => uint) balances;

	modifier onlyPayloadSize(uint size) {
		if(msg.data.length < size + 4) {
			throw;
		}
		_;
	}

	function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
	}

	function balanceOf(address _owner) constant returns(uint balance) {
		return balances[_owner];
	}

}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns(uint);
	function transferFrom(address from, address to, uint value);
	function approve(address spender, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is BasicToken, ERC20 {
	mapping(address => mapping(address => uint)) allowed;
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
		var _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint _value) {
		if((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _owner, address _spender) constant returns(uint remaining) {
		return allowed[_owner][_spender];
	}

}

contract BIDTToken is StandardToken {
	string public constant symbol = "BIDT";
	string public constant name = "Block IDentity Token";
	uint8 public constant decimals = 18;
	address public target;
	
	uint public baseRate=0;
	bool public allowedBuy = false;
	uint public  basePublicPlacement  = 1;
	event InvalidCaller(address caller);

	modifier onlyOwner {
		if(target == msg.sender) {
			_;
		} else {
			InvalidCaller(msg.sender);
			throw;
		}
	}

	function setRate(uint rate) public onlyOwner {
		baseRate = rate;
	}
	function setPublicPlacementNum(uint publicPlacement) public onlyOwner {
		basePublicPlacement = publicPlacement;
	}

	function openBuy() public onlyOwner {
		allowedBuy = true;
	}
	
	function closeBuy() public onlyOwner {
		allowedBuy = false;
	}

	function BIDTToken(address _target) {
		target = _target;
		totalSupply = 45.5 * 100000000 * 10 ** 18;
		balances[target] = totalSupply.div(1000).mul(100);
		
		balances[0xBE4C612DE6221F557799b7eD456572F0c0A14BD1] = totalSupply.div(1000).mul(180);
		balances[0xA29459226F9aFa33b2b22093f5f9FCB9B16a9851] = totalSupply.div(1000).mul(20);
		
		balances[0x7E7C8b920d2Fd52b6552805C2212d40792b77f6b] = totalSupply.div(1000).mul(40);
		balances[0xC6eB2f5C7938F687F58516B5EA6438B8A4803Ee3] = totalSupply.div(1000).mul(5);
		balances[0x15dA32920eecaf05C0594C039633F8565471cb5C] = totalSupply.div(1000).mul(5);
		
		balances[0xCD2C7D18325B7E09DA08DBA6f58D0E6F0e6BDf68] = totalSupply.div(1000).mul(30);
		balances[0x2968d05dCF6e706F68ca8fC16F6e430fd822d742] = totalSupply.div(1000).mul(170);

		balances[0xD20D3CaC06BfC68f1d0e84855c3395D2D10CDb14] = totalSupply.div(1000).mul(450);
	}

	function() payable {
		issueToken();
	}

	function issueToken() payable {
	    if(allowedBuy){
	        assert(msg.value >= 1 ether );
    		assert(msg.value <= 50 ether );
    		uint tokens = computeTokenAmount(msg.value);
    		balances[msg.sender] = balances[msg.sender].add(tokens);
    		balances[target] = balances[target].sub(tokens);
	    }else{
	       	throw;
	    }
		if(!target.send(msg.value)) {
			throw;
		}
	}

	function computeTokenAmount(uint ethAmount) internal constant returns(uint tokens) {
		uint tokenBase = ethAmount.mul(baseRate);
		if(	balances[target] > (totalSupply.div(100)).mul(8-basePublicPlacement)){
		    	tokens = tokenBase;
		}else{
		   	throw;
		}
		    
	}

}