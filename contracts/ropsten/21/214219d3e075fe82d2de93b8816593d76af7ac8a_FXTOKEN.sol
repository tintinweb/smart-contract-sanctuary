pragma solidity ^0.4.24;
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  // mitigate short address attack
  // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
  // TODO: doublecheck implication of >= compared to ==
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }
}
contract Token { // ERC20 standard
    function balanceOf(address _owner) public  view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value)  returns (bool success);
    function allowance(address _owner, address _spender) public  view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token, SafeMath {
    uint256 public totalSupply;
    
    function transfer(address _to, uint256 _value) public  onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) view returns (uint256 balance) {
        return balances[_owner];
    }
    // To change the approve amount you first have to reduce the addresses&#39;
    //  allowance to zero by calling &#39;approve(_spender, 0)&#39; if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }
    function allowance(address _owner, address _spender) public  view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    mapping (address => uint256) public  balances;
    mapping (address => mapping (address => uint256)) public  allowed;
}
contract Ownership is StandardToken {
	address public fundWallet;
    address public controlWallet;
	
	modifier onlyFundWallet {
        require(msg.sender == fundWallet);
        _;
    }
    modifier onlyManagingWallets {
        require(msg.sender == controlWallet || msg.sender == fundWallet);
        _;
    }
    modifier only_if_controlWallet {
        if (msg.sender == controlWallet) _;
    }

	function changeFundWallet(address newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = newFundWallet;
    }
    function changeControlWallet(address newControlWallet) external onlyFundWallet {
        require(newControlWallet != address(0));
        controlWallet = newControlWallet;
    }
	
	}
contract WhiteL is Ownership {	
    // maps addresses
    mapping (address => bool) public whitelist;

	event Whitelist(address indexed participant);
	
	modifier onlyIfAllowed {
        require(whitelist[msg.sender]);
        _;
    }	
	function verifyParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = true;
        Whitelist(participant);
    }
}
contract FXTOKEN is WhiteL {
    // FIELDS
    string public name = "FXTOKEN";
    string public symbol = "FXTO";
    uint256 public decimals = 8;
	string public version = "1.0";
    bool public tradeable = false;  
    Price public currentPrice;
    uint256 public minAmount = 0.05 ether;
	bool public	allowbuy = false;
	uint256 public fundendtime = 0;
    // TYPES
    struct Price { // tokensPerEth
        uint256 numerator;
        uint256 denominator;
    }
    // EVENTS
    event Buy(address indexed participant,uint256 amountTokens);
	event AllocateTokens(address indexed participant, uint256 amountTokens);
	event PriceUpdate(uint256 numerator, uint256 denominator);
	event Burn(uint256 amountTokens);
	event Tradeable(bool isTradeable);
    // MODIFIERS
    modifier isTradeable { // exempt  fundWallet
        require(tradeable || msg.sender == fundWallet);
        _;
    }
    // CONSTRUCTOR
	function FXTOKEN(address controlWalletInput, uint256 ofundendtime, uint256 priceNumeratorInput ) public  {
        require(controlWalletInput != address(0));
        require(priceNumeratorInput > 0);
		require(ofundendtime > now);
        fundWallet = msg.sender;
        controlWallet = controlWalletInput;
		fundendtime = ofundendtime;
        whitelist[fundWallet] = true;
        whitelist[controlWallet] = true;
        currentPrice = Price(priceNumeratorInput, 800); // 1 token = 0.08 USD at start....10000 = 1 USD
    }			
    // METHODS	
    function updatePriceAndDenominator(uint256 newNumerator, uint256 newDenominator) external onlyManagingWallets {
			require(newDenominator > 0);
			require(newNumerator > 0);
			currentPrice.denominator = newDenominator;
			currentPrice.numerator = newNumerator;
			PriceUpdate(currentPrice.numerator, newDenominator);
		}
	function allocateTokens(address participant, uint256 amountTokens) private {
        totalSupply = safeAdd(totalSupply, amountTokens);
        balances[participant] = safeAdd(balances[participant], amountTokens);
		AllocateTokens(participant,amountTokens);
    }  
	function addtokensWL(address participant, uint amountTokens,  uint expectedTokens ) private {
		require(participant != address(0));		
		require(safeAdd(balances[participant], amountTokens) == expectedTokens);
		whitelist[participant] = true; 
        allocateTokens(participant, amountTokens);
        Whitelist(participant);	
	}
	function sendTokens(address participant, uint amountTokens, uint expectedTokens) external onlyManagingWallets {       
		addtokensWL(participant, amountTokens, expectedTokens);
    }
	function sendTokensBulk(address[] participants, uint256[] values, uint256[] expectedTokens) external onlyManagingWallets {
      uint256 i = 0;
      while (i < participants.length) {
		addtokensWL(participants[i], values[i],expectedTokens[i]);
        i++;
      }
	} 
	function buy() external payable {
			buyTo(msg.sender);
	}
	function buyTo(address participant) public payable onlyIfAllowed {
			require(participant != address(0));
			require(msg.value >= minAmount);
			if(fundendtime>0){
				require(now < fundendtime);
			}			
			uint256 tokensToBuy = safeMul(msg.value, currentPrice.numerator) /  safeMul(currentPrice.denominator,10000000000);
			allocateTokens(participant, tokensToBuy);
			fundWallet.transfer(msg.value);
			Buy(participant, msg.value);
	}
	function burnTokens(uint256 amountTokensToBurn,uint expectedTokens) external onlyManagingWallets {
		require(balances[fundWallet] >= amountTokensToBurn);
		require(safeSub(balances[fundWallet], amountTokensToBurn) == expectedTokens);		
		balances[fundWallet] = safeSub(balances[fundWallet], amountTokensToBurn);
		totalSupply = safeSub(totalSupply,amountTokensToBurn);
		Burn(amountTokensToBurn);
	}    
    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
    }
	function updateminAmount(uint256 newMinAmount) external onlyManagingWallets {
		require(newMinAmount > 0);
		minAmount =newMinAmount; //eg 1 ether at start
	}
	function updatefundendtime(uint256 newfundendtime) external onlyManagingWallets {
		fundendtime =newfundendtime; 
	}
    function enableTrading() external onlyManagingWallets {
        tradeable = true;
		Tradeable(true);
    }
	function disableTrading() external onlyManagingWallets {
        tradeable = false;
		Tradeable(false);
    }
	function enableAllowBuy() external onlyManagingWallets {
        allowbuy = true;
    }
	function disableAllowBuy() external onlyManagingWallets {
        allowbuy = false;
    }
    function claimTokens(address _token) external onlyManagingWallets {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(fundWallet, balance);
     }
   // fallback function
    function() payable {
		require(allowbuy);
		require(tx.origin == msg.sender);
		buyTo(msg.sender);    
    }
	
	// prevent transfers until trading allowed
    function transfer(address _to, uint256 _value) isTradeable onlyIfAllowed returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public onlyIfAllowed isTradeable returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
	}