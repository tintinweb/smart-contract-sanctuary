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
    // TODO: update tests to expect throw
    function transfer(address _to, uint256 _value) public  onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    // TODO: update tests to expect throw
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
contract ETC is WhiteBlockList {
    // FIELDS
    string public name = "1USD222";
    string public symbol = "1USD222";
    uint256 public decimals = 8;
	string public version = "1.0";
    bool public halted = false;
	bool public haltedFX  = false;
    bool public tradeable = false;
    uint256 public previousUpdateTime = 0;
    Price public currentPrice;
    uint256 public minAmount = 1 ether;
    uint256 public fxFee  = 50;
    // map participant address to a withdrawal request
    mapping (address => Withdrawal) public withdrawals;
    // maps previousUpdateTime to the next price
    mapping (uint256 => Price) public prices;

    // TYPES
    struct Price { // tokensPerEth
        uint256 numerator;
        uint256 denominator;
    }
    struct Withdrawal {
        uint256 tokens;
        uint256 time; // time for each withdrawal is set to the previousUpdateTime
    }
    // EVENTS
    event Buy(address indexed participant, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event SendTokensAfterBuy (address indexed participant, uint256 amountTokens,uint256 nawBalance);
    
	
    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
	event WithdrawFX(address indexed participant, uint256 amountTokens, uint256 fxValue);
    // MODIFIERS
    modifier isTradeable { // exempt  fundWallet to allow dev allocations
        require(tradeable || msg.sender == fundWallet);
        _;
    }

    modifier only_if_increase (uint256 newNumerator) {
        if (newNumerator > currentPrice.numerator) _;
    }
    // CONSTRUCTOR

	function ETC(address controlWalletInput, uint256 priceNumeratorInput) public  {
        require(controlWalletInput != address(0));
        require(priceNumeratorInput > 0);
        fundWallet = msg.sender;
        controlWallet = controlWalletInput;
        whitelist[fundWallet] = true;
        whitelist[controlWallet] = true;
        currentPrice = Price(priceNumeratorInput, 100); // 1 token = 1 usd at start
        previousUpdateTime = now;
    }
			
    // METHODS	
    // allows controlWallet to update the price within a time contstraint, allows fundWallet complete control
    function require_limited_change (uint256 newNumerator)
        private
        only_if_controlWallet
        only_if_increase(newNumerator)
    {
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newNumerator, 1000) / currentPrice.numerator;
        percentage_diff = safeSub(percentage_diff, 1000);
        // controlWallet can only increase price by max 20% and only every waitTime
        //require(percentage_diff <= 20);
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
        SendTokensAfterBuy(participant, amountTokens,balances[participant]);		
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
        // send ether to fundWallet
        fundWallet.transfer(msg.value);
        Buy(msg.sender, participant, msg.value, tokensToBuy);
    }
    function requestWithdrawal(uint256 amountTokensToWithdraw) external  onlyIfAllowed {
		require(!halted);       
	    require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0); // participant cannot have outstanding withdrawals
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: previousUpdateTime});
        WithdrawRequest(participant, amountTokensToWithdraw);
    }
    function withdraw() external {
        address participant = msg.sender;
        uint256 tokens = withdrawals[participant].tokens;
        require(tokens > 0); // participant must have requested a withdrawal
        uint256 requestTime = withdrawals[participant].time;
        // obtain the next price that was set after the request
        Price price = prices[requestTime];
        require(price.numerator > 0); // price must have been set
        uint256 withdrawValue = safeMul(tokens, safeMul(price.denominator,10000000000)) / price.numerator;
        // if contract ethbal > then send + transfer tokens to fundWallet, otherwise give tokens back
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
		uint256 tokens = amountTokensToWithdraw * safeSub(10000,fxFee)/10000;
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
    function checkWithdrawValue(uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(msg.sender) >= amountTokensToWithdraw);
        uint256 withdrawValue = safeMul(amountTokensToWithdraw, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
        require(this.balance >= withdrawValue);
        return withdrawValue;
    }
	function checkWithdrawValueForAddress(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
        uint256 withdrawValue = safeMul(amountTokensToWithdraw, safeMul(currentPrice.denominator,10000000000)) / currentPrice.numerator;
        return withdrawValue;
    }
	function checkWithdrawValueFX(uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(msg.sender) >= amountTokensToWithdraw);
        uint256 withdrawValue = safeMul(amountTokensToWithdraw, currentPrice.denominator) / 10000000000;
        require(this.balance >= withdrawValue);
        return withdrawValue;
    }
	function checkWithdrawValueForAddressFX(address participant,uint256 amountTokensToWithdraw) public  view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
		uint256 tokens = amountTokensToWithdraw * safeSub(10000,fxFee)/10000;
        uint256 withdrawValue = safeMul(tokens, currentPrice.denominator) / 10000000000;	
        return withdrawValue;
    }
    // allow fundWallet or controlWallet to add ether to contract
    function addLiquidity() external onlyManagingWallets payable {
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }
    // allow fundWallet to remove ether from contract
    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
        RemoveLiquidity(amount);
    }
    function enableTrading() external onlyFundWallet {
        tradeable = true;
    }
    // fallback function
    function() payable {
        require(tx.origin == msg.sender);
        buyTo(msg.sender);
    }
    // prevent transfers until trading allowed
    function transfer(address _to, uint256 _value) isTradeable onlyIfAllowed returns (bool success) {
        return super.transfer(_to, _value);
    }
	}