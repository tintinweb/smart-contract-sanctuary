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
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }
}
contract Token {
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
    }}
contract WhiteBlockList is Ownership {	
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
}
contract FXTOKEN is WhiteBlockList {
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
	uint256 public ethFee  = 0;
    mapping (address => Withdrawal) public withdrawals;
    mapping (uint256 => Price) public prices;
    struct Price {
        uint256 numerator;
        uint256 denominator;
    }
    struct Withdrawal {
        uint256 tokens;
        uint256 time;
    }
    event Buy(address indexed participant, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event SendTokensAfterBuy (address indexed participant, uint256 amountTokens);
    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
	event WithdrawFX(address indexed participant, uint256 amountTokens, uint256 fxValue);
    modifier isTradeable { // exempt  fundWallet
        require(tradeable || msg.sender == fundWallet);
        _;
    }
	function FXTOKEN(address controlWalletInput, uint256 priceNumeratorInput) public  {
        require(controlWalletInput != address(0));
        require(priceNumeratorInput > 0);
        fundWallet = msg.sender;
        controlWallet = controlWalletInput;
        whitelist[fundWallet] = true;
        whitelist[controlWallet] = true;
        currentPrice = Price(priceNumeratorInput, 100); // 1 token = 1 usd at start
        previousUpdateTime = now;
    }			
    function require_limited_change (uint256 newNumerator)
        private
        only_if_controlWallet
    {
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newNumerator, 1000) / currentPrice.numerator;
        percentage_diff = safeSub(percentage_diff, 1000);
        require(percentage_diff <= 20);
    }
    function updatePriceAndDenominator(uint256 newNumerator, uint256 newDenominator) external onlyManagingWallets {
			require(newDenominator > 0);
			require(newNumerator > 0);
			currentPrice.denominator = newDenominator;
			currentPrice.numerator = newNumerator;
			prices[previousUpdateTime] = currentPrice;
			previousUpdateTime = now;
			PriceUpdate(currentPrice.numerator, newDenominator);
		}
	function allocateTokens(address participant, uint256 amountTokens) private {
        totalSupply = safeAdd(totalSupply, amountTokens);
        balances[participant] = safeAdd(balances[participant], amountTokens);
    }
    function sendTokensAfterBuy(address participant, uint amountTokens, uint expectedTokens) external onlyFundWallet {       
		allocatetokensAndWL(participant, amountTokens, expectedTokens);
    }	
	function batchAllocate(address[] participants, uint256[] values, uint[] expectedTokens) external onlyFundWallet {
      uint256 i = 0;
      while (i < participants.length) {
		allocatetokensAndWL(participants[i], values[i] ,expectedTokens[i]);
        i++;
      }
	} 
	function allocatetokensAndWL(address participant, uint amountTokens,  uint expectedTokens ) private {
		require(participant != address(0));		
		require(safeAdd(balances[participant], amountTokens) == expectedTokens);
		require(participant != address(0));
		whitelist[participant] = true; 
		blocklist[participant] = false;
        allocateTokens(participant, amountTokens);
        Whitelist(participant);
        SendTokensAfterBuy(participant, amountTokens);		
	}	
    function buy() external payable {
        buyTo(msg.sender);
    }
    function buyTo(address participant) public payable onlyIfAllowed {
        require(!halted);
        require(participant != address(0));
        require(msg.value >= minAmount);
        uint256 tokensToBuy = safeMul(msg.value, currentPrice.numerator) /  safeMul(currentPrice.denominator,10000000000);
        allocateTokens(participant, tokensToBuy);
        fundWallet.transfer(msg.value);
        Buy(msg.sender, participant, msg.value, tokensToBuy);
    }
    function requestWithdrawal(uint256 amountTokensToWithdraw) external  onlyIfAllowed {
		require(!halted);       
	    require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0); 
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: previousUpdateTime});
        WithdrawRequest(participant, amountTokensToWithdraw);
    }
    function withdraw() external {
        address participant = msg.sender;
        uint256 amountTokensToWithdraw = withdrawals[participant].tokens;
        require(amountTokensToWithdraw > 0);
        uint256 requestTime = withdrawals[participant].time;
        Price price = prices[requestTime];
        require(price.numerator > 0);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,ethFee))/10000;
		uint256 feetokens = safeSub(amountTokensToWithdraw,tokens);
		balances[fundWallet] = safeAdd(balances[fundWallet], feetokens);
        uint256 withdrawValue = safeMul(tokens, safeMul(price.denominator,10000000000)) / price.numerator;
        withdrawals[participant].tokens = 0;
        if (this.balance >= withdrawValue)
            enact_withdrawal_greater_equal(participant, withdrawValue, tokens);
        else
            enact_withdrawal_less(participant, withdrawValue, tokens);
    }
	function withdrawalFX(uint256 amountTokensToWithdraw) external  onlyIfAllowed {
        require(!haltedFX);
		require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,fxFee))/10000;
		uint256 feetokens = safeSub(amountTokensToWithdraw,tokens);
		uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;
		balances[fundWallet] = safeAdd(balances[fundWallet], feetokens);
		totalSupply = safeSub(totalSupply, tokens);
        WithdrawFX(participant, amountTokensToWithdraw, withdrawValue);
    }
    function enact_withdrawal_greater_equal(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(this.balance >= withdrawValue);
        balances[fundWallet] = safeAdd(balances[fundWallet], tokens);
		totalSupply = safeSub(totalSupply, withdrawals[participant].tokens);
        participant.transfer(withdrawValue);
        Withdraw(participant, tokens, withdrawValue);
    }
    function enact_withdrawal_less(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(this.balance < withdrawValue);
        balances[participant] = safeAdd(balances[participant], tokens);
        Withdraw(participant, tokens, 0); // indicate a failed withdrawal
    }
	function checkWithdrawValueForAddress(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,ethFee))/10000;
        uint256 withdrawValue = safeMul(tokens, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
        return withdrawValue;
    }
	function checkWithdrawValueForAddressFX(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 FXcentValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
		uint256 tokens = safeMul(amountTokensToWithdraw , safeSub(10000,fxFee))/10000;
        uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;	
        return withdrawValue;
    }
    function addLiquidity() external onlyManagingWallets payable {
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }
    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
        RemoveLiquidity(amount);
    }
    function updatefxFee(uint256 newfxFee) external onlyFundWallet {
		require(newfxFee >= 0);
		fxFee =newfxFee;
	}
	function updateethFee(uint256 newethFee) external onlyFundWallet {
		require(newethFee >= 0);
		ethFee =newethFee; 
	}
    function() payable {
        require(tx.origin == msg.sender);
        buyTo(msg.sender);
    }
    function transfer(address _to, uint256 _value) isTradeable onlyIfAllowed returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public onlyIfAllowed isTradeable returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
	}