pragma solidity ^0.4.18;


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

contract RTCoin {
    using SafeMath for uint256;
    
	address public owner;
    address public saleAgent;
    uint256 public totalSupply;
	string public name;
	uint8 public decimals;
	string public symbol;
	bool private allowEmission = true;
	mapping (address => uint256) balances;
    
    
    function RTCoin(string _name, string _symbol, uint8 _decimals) public {
		decimals = _decimals;
		name = _name;
		symbol = _symbol;
		owner = msg.sender;
	}
	
	
    function changeSaleAgent(address newSaleAgent) public onlyOwner {
        require (newSaleAgent!=address(0));
        uint256 tokenAmount = balances[saleAgent];
        if (tokenAmount>0) {
            balances[newSaleAgent] = balances[newSaleAgent].add(tokenAmount);
            balances[saleAgent] = balances[saleAgent].sub(tokenAmount);
            Transfer(saleAgent, newSaleAgent, tokenAmount);
        }
        saleAgent = newSaleAgent;
    }
	
	
	function emission(uint256 amount) public onlyOwner {
	    require(allowEmission);
	    require(saleAgent!=address(0));
	    totalSupply = amount * (uint256(10) ** decimals);
		balances[saleAgent] = totalSupply;
		Transfer(0x0, saleAgent, totalSupply);
		allowEmission = false;
	}
    
    
    function burn(uint256 _value) public {
        require(_value > 0);
        address burner;
        if (msg.sender==owner)
            burner = saleAgent;
        else
            burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
     
    event Burn(address indexed burner, uint indexed value);
	
	
	function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
	
	
	function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner; 
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


	
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
	);
}

contract Crowdsale {
    
    using SafeMath for uint256;
    address fundsWallet;
    RTCoin public token;
    address public owner;
	bool public open = false;
    uint256 public tokenLimit;
    
    uint256 public rate = 20000; //значение для pre ICO, 0.00005 ETH = 1 RTC 
    
    
    function Crowdsale(address _fundsWallet, address tokenAddress, 
                       uint256 _rate, uint256 _tokenLimit) public {
        fundsWallet = _fundsWallet;
        token = RTCoin(tokenAddress);
        rate = _rate;
        owner = msg.sender;
        tokenLimit = _tokenLimit * (uint256(10) ** token.decimals());
    }
    
    
    function() external isOpen payable {
        require(tokenLimit>0);
        fundsWallet.transfer(msg.value);
        uint256 tokens = calculateTokenAmount(msg.value);
        token.transfer(msg.sender, tokens);
        tokenLimit = tokenLimit.sub(tokens);
    }
  
    
    function changeFundAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        fundsWallet = newAddress;
	}
	
	
    function changeRate(uint256 newRate) public onlyOwner {
        require(newRate>0);
        rate = newRate;
    }
    
    
    function calculateTokenAmount(uint256 weiAmount) public constant returns(uint256) {
        if (token.decimals()!=18){
            uint256 tokenAmount = weiAmount.mul(rate).div(uint256(10) ** (18-token.decimals())); 
            return tokenAmount;
        }
        else return weiAmount.mul(rate);
    }
    
    function transferTo(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(tokenLimit>0);
        token.transfer(_to, _value);
        tokenLimit = tokenLimit.sub(_value);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    function allowSale() public onlyOwner {
        open = true;
    }
    
    
    function disallowSale() public onlyOwner {
        open = false;
    }
    
    modifier isOpen() {
        require(open == true);
        _;
    }
}