pragma solidity ^0.4.18;
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
contract WhiteBlockList is Ownership {	
    // maps addresses
    mapping (address => bool) public whitelist;
	mapping (address => bool) public blocklist;
	
	event Whitelist(address indexed participant);
	event BlockList(address indexed participant, bool blocked);
	
	modifier onlyIfAllowed {
        require(whitelist[msg.sender]);
		require(!blocklist[msg.sender]);
        _;
    }
	
	function verifyParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = true;
		blocklist[participant] = false;
        Whitelist(participant);
    }
	function addBlockList(address participant) external onlyManagingWallets {
        blocklist[participant] = true;
        BlockList(participant,  blocklist[participant]);
    }
	function removeBlockList(address participant) external onlyManagingWallets {
        blocklist[participant] = false;
        BlockList(participant,  blocklist[participant]);
    }
	function destroyBlockFunds(address participant) external onlyManagingWallets {
		require(blocklist[participant] = true);
		require(balances[participant]>0);	  
		totalSupply = safeSub(totalSupply, balances[participant]);		
		balances[participant] = 0;		
    }
}
contract FXTOKEN is WhiteBlockList {
    // FIELDS
    string public name = "FXTOKEN";
    string public symbol = "1USD";
    uint256 public decimals = 8;
	string public version = "1.0";
    bool public halted = false;
	bool public haltedFX  = false;
    bool public tradeable = true;
    uint256 public previousUpdateTime = 0;
    Price public currentPrice;
    uint256 public minAmount = 1 ether;
    uint256 public fxFee  = 50;
	uint256 public ethFee  = 20;

    // TYPES
    struct Price { // tokensPerEth
        uint256 numerator;
        uint256 denominator;
    }
    // EVENTS
    event RequestBuywithETH(address indexed participant,uint256 amountTokens);
	event RequestBuywithFX(address indexed participant, uint256 amountTokens);
    event SendTokensAfterBuy (address indexed participant, uint256 amountTokens);
    event PriceUpdate(uint256 numerator, uint256 denominator);
    event RequestSellforETH(address indexed participant, uint256 amountTokens, uint256 etherAmount);
	event RequestSellforFX(address indexed participant, uint256 amountTokens, uint256 fxValue);
	event Burn(uint256 amountTokens);

    // MODIFIERS
    modifier isTradeable { // exempt  fundWallet
        require(tradeable || msg.sender == fundWallet);
        _;
    }
    // CONSTRUCTOR
	function FXTOKEN(address controlWalletInput, uint256 priceNumeratorInput) public  {
        require(controlWalletInput != address(0));
        require(priceNumeratorInput > 0);
        fundWallet = msg.sender;
        controlWallet = controlWalletInput;
        whitelist[fundWallet] = true;
        whitelist[controlWallet] = true;
        currentPrice = Price(priceNumeratorInput, 10000); // 1 token = 1 usd at start
        previousUpdateTime = now;
    }			
    // METHODS	
    function require_limited_change (uint256 newDenominator)
        private
        only_if_controlWallet
    {
        
		if (newDenominator> currentPrice.denominator){
			// controlWallet can only increase denominator by max 20% and only every waitTime
			require(safeSub(safeMul(newDenominator, 100) / currentPrice.denominator, 100) <= 20);
		} else {
			// controlWallet can only decres denominator by max 20% and only every waitTime
			require(safeMul(newDenominator, 100)/ currentPrice.denominator >= 80);		
		}     		
    }
    function updatePriceAndDenominator(uint256 newNumerator, uint256 newDenominator) external onlyManagingWallets {
			require(newDenominator > 0);
			require(newNumerator > 0);
			require_limited_change(newDenominator);
			currentPrice.denominator = newDenominator;
			currentPrice.numerator = newNumerator;
			previousUpdateTime = now;
			PriceUpdate(currentPrice.numerator, newDenominator);
		}
	function allocateTokens(address participant, uint256 amountTokens) private {
        totalSupply = safeAdd(totalSupply, amountTokens);
        balances[participant] = safeAdd(balances[participant], amountTokens);
    }
    function sendTokensAfterBuy(address participant, uint amountTokens) external onlyFundWallet {       
		allocatetokensAndWL(participant, amountTokens);
    }	
	function batchAllocate(address[] participants, uint256[] values) external onlyFundWallet {
      uint256 i = 0;
      while (i < participants.length) {
		allocatetokensAndWL(participants[i], values[i]);
        i++;
      }
	} 
	function allocatetokensAndWL(address participant, uint amountTokens) private {
		require(participant != address(0));
		whitelist[participant] = true; // automatically whitelist accepted presale
		blocklist[participant] = false;
        allocateTokens(participant, amountTokens);
        Whitelist(participant);
        SendTokensAfterBuy(participant, amountTokens);		
	}	
    function sendTokensAfterBuyExp(address participant, uint amountTokens, uint expectedTokens) external onlyFundWallet {       
		allocatetokensAndWLExp(participant, amountTokens, expectedTokens);
    }	
	function allocatetokensAndWLExp(address participant, uint amountTokens,  uint expectedTokens ) private {
		require(participant != address(0));		
		require(safeAdd(balances[participant], amountTokens) == expectedTokens);
		whitelist[participant] = true; 
		blocklist[participant] = false;
        allocateTokens(participant, amountTokens);
        Whitelist(participant);
        SendTokensAfterBuy(participant, amountTokens);		
	}
	function requestBuywithETH () public payable onlyIfAllowed {
		require(!halted);
        require(msg.sender != address(0));
        require(msg.value >= minAmount);	
		address participant = msg.sender;    		
		uint256 moneyafterfee = safeMul(msg.value , safeSub(10000,ethFee))/10000;
        uint256 tokensToBuy = safeMul(moneyafterfee, currentPrice.numerator) /  safeMul(currentPrice.denominator,10000000000);
		fundWallet.transfer(msg.value);
        RequestBuywithETH(participant, tokensToBuy);
    }
	function requestBuywithFX(uint256 fxcents) external onlyIfAllowed {
        require(!halted);
        require(msg.sender != address(0));
		address participant = msg.sender;     
		uint256 amountfxcent = safeMul(fxcents , safeSub(10000,fxFee))/10000;
        uint256 amounttokens = safeMul(amountfxcent, 10000000000) / currentPrice.denominator;		  
	    RequestBuywithFX(participant, amounttokens);
    }
    function burnTokens(uint256 amountTokensToBurn) external onlyFundWallet {
		require(balances[fundWallet] >= amountTokensToBurn);		
		balances[fundWallet] = safeSub(balances[fundWallet], amountTokensToBurn);
		totalSupply = safeSub(totalSupply,amountTokensToBurn);
		Burn(amountTokensToBurn);
	}
	function burnTokensExp(uint256 amountTokensToBurn,uint expectedTokens) external onlyFundWallet {
		require(balances[fundWallet] >= amountTokensToBurn);
		require(safeSub(balances[fundWallet], amountTokensToBurn) == expectedTokens);		
		balances[fundWallet] = safeSub(balances[fundWallet], amountTokensToBurn);
		totalSupply = safeSub(totalSupply,amountTokensToBurn);
		Burn(amountTokensToBurn);
	}
	function requestSellforETH(uint256 amountTokensToWithdraw) external  onlyIfAllowed {
		require(!haltedFX);
		require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,ethFee))/10000;
		uint256 withdrawValue = safeMul(tokens, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
		balances[fundWallet] = safeAdd(balances[fundWallet], amountTokensToWithdraw);
        RequestSellforETH(participant, amountTokensToWithdraw, withdrawValue);
    }	
	function requestSellforFX(uint256 amountTokensToWithdraw) external  onlyIfAllowed {
        require(!haltedFX);
		require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,fxFee))/10000;
		uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;
		balances[fundWallet] = safeAdd(balances[fundWallet], amountTokensToWithdraw);
        RequestSellforFX(participant, amountTokensToWithdraw, withdrawValue);
    }
    function checkWithdrawValue(uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(msg.sender) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,ethFee))/10000;
        uint256 withdrawValue = safeMul(tokens, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
        return withdrawValue;
    }
	function checkWithdrawValueForAddress(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,ethFee))/10000;
        uint256 withdrawValue = safeMul(tokens, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
        return withdrawValue;
    }
	function checkWithdrawValueFX(uint256 amountTokensToWithdraw) public  view returns (uint256 FXcentValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(msg.sender) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,fxFee))/10000;
        uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;
        return withdrawValue;
    }
	function checkWithdrawValueForAddressFX(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 FXcentValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,fxFee))/10000;
        uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;	
        return withdrawValue;
    }
    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
    }
    function halt() external onlyFundWallet {
        halted = true;
    }
    function unhalt() external onlyFundWallet {
        halted = false;
    }
    function haltFX() external onlyFundWallet {
        haltedFX = true;
    }
    function unhaltFX() external onlyFundWallet {
        haltedFX = false;
    }
    function updatefxFee(uint256 newfxFee) external onlyFundWallet {
		require(newfxFee >= 0);
		fxFee =newfxFee; //eg 50 for 50 basispoint
	}
	function updateEthFee(uint256 newethFee) external onlyFundWallet {
		require(newethFee >= 0);
		ethFee =newethFee; //eg 20 for 20 basispoint
	}
	function updateminAmount(uint256 newminAmount) external onlyFundWallet {
		require(newminAmount > 0);
		minAmount =newminAmount; //eg 1 ether at start
	}
    function enableTrading() external onlyFundWallet {
        tradeable = true;
    }
	function disableTrading() external onlyFundWallet {
        tradeable = false;
    }
    function claimTokens(address _token) external onlyFundWallet {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(fundWallet, balance);
     }
   // fallback function
    function() payable {
        require(tx.origin == msg.sender);
    }
	// prevent transfers until trading allowed
    function transfer(address _to, uint256 _value) isTradeable onlyIfAllowed returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public onlyIfAllowed isTradeable returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
	}