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
contract STC is Token{
	Price public currentPrice;
	function() payable {
			require(tx.origin == msg.sender);
			buyTo(msg.sender);
	}
	function buyTo(address participant) public payable; 
	function icoDenominatorPrice() public view returns (uint256);
	struct Price { // tokensPerEth
			uint256 numerator;
			uint256 denominator;
	}
}	
contract STCDR is Token{
	//function burnMyTokens(uint256 amountTokens);
}	
contract OwnerControl is SafeMath {
	bool public halted = false;
	address public fundWallet;	
	//event
	event AddLiquidity(uint256 ethAmount);
	event RemoveLiquidity(uint256 ethAmount);
	//modifier
	modifier onlyFundWallet {
			require(msg.sender == fundWallet);
			_;
	}
	// allow fundWallet or controlWallet to add ether to contract
	function addLiquidity() external onlyFundWallet payable {
			require(msg.value > 0);
			AddLiquidity(msg.value);
	}
	// allow fundWallet to remove ether from contract
	function removeLiquidity(uint256 amount) external onlyFundWallet {
			require(amount <= this.balance);
			fundWallet.transfer(amount);
			RemoveLiquidity(amount);
	}
	function changeFundWallet(address newFundWallet) external onlyFundWallet {
			require(newFundWallet != address(0));
			fundWallet = newFundWallet;
	}
	function halt() external onlyFundWallet {
			halted = true;
	}
	function unhalt() external onlyFundWallet {
			halted = false;
	}
}
contract SWAP is OwnerControl {
	string public name = "SWAP STCDR-STC";	
	STC public STCToken;
	STCDR public STCDRToken;
	uint256 public discount = 5;
	uint256 public stcRatio = 40;
	address public tokenBurnAddres;
	//event
	 event TokenSwaped(address indexed _from,  uint256 _stc, uint256 _stcBonus, uint256 _stcdrBurn);
	//modifier
	//Initialize
	function SWAP(address _STCToken,address _STCDRToken, address _tokenBurnAddres) public  {
			fundWallet = msg.sender;
			STCToken = STC(_STCToken);
			STCDRToken = STCDR(_STCDRToken);
			tokenBurnAddres= _tokenBurnAddres;
	}	
	function changetokenBurnAddres(address _newtokenBurnAddres) external onlyFundWallet {
			require(_newtokenBurnAddres != address(0));
			tokenBurnAddres = _newtokenBurnAddres;
	}
	function() payable {
			require(tx.origin == msg.sender);
			buyTo(msg.sender);
	}
	function buyTo(address participant) public payable {
		require(!halted);		
		require(msg.value > 0);
		
		//Get STCDR tokens that can be transfer and burn
		uint256 avalibleTokenSTCDR = STCDRToken.allowance(msg.sender, this);
		require(avalibleTokenSTCDR > 0);
		//Last ETH-USD price
		uint256  _numerator = getLastSTCPrice();
		require(_numerator > 0);
		//STC Denominator price
		uint256 denominator = STCToken.icoDenominatorPrice();	
		require(denominator > 0);	
		//Max STC that can be as used to callculated bonus
		uint256 _stcMaxBonus =stcMaxBonus(avalibleTokenSTCDR);
		require(_stcMaxBonus > 0);
		//Calculated STC that user buy for ETH
		uint256 _stcOrginalBuy =stcOrginalBuy(msg.value);	
		require(_stcOrginalBuy > 0);
		
		uint256 _tokensToBurn =0 ;
		uint256 _tokensBonus =0 ;
		if (_stcOrginalBuy >= _stcMaxBonus){
			_tokensToBurn =  avalibleTokenSTCDR;
			_tokensBonus=safeMul(_stcMaxBonus,discount)/100;
		} else {
			_tokensToBurn = safeMul(_stcOrginalBuy,stcRatio)/10000000000;	
			_tokensBonus= safeMul(_stcOrginalBuy,discount)/100;					
		} 
		require(_tokensToBurn > 0);
		require(_tokensBonus > 0);
		require(_tokensBonus < _stcOrginalBuy);
		
		uint256 _ethBonus=safeMul(_tokensBonus, denominator) / _numerator ;
		//Forward Etherium in to STC contract
		forwardETHtoSTCcontract(msg.value);
		forwardETHtoSTCcontract(_ethBonus);
		//Burn Tokens
		burnUserTokens(_tokensToBurn);	

		TokenSwaped(msg.sender,  _stcOrginalBuy , _tokensBonus,_tokensToBurn );
	}	
	function getLastSTCPrice() public view returns (uint256 numerator)
	{
		return STC.Price(2550000, 10000).numerator;
	}
	function stcMaxBonus(uint256 _stcdr) public  view returns (uint256 tokenBonus)
	{
		return safeMul(_stcdr,10000000000) / stcRatio;		
	}
	function stcOrginalBuy(uint256 _ether) public  view returns (uint256 buySTC)
	{
		uint256 nominator = getLastSTCPrice();
		uint256 denominator = STCToken.icoDenominatorPrice();
		return safeMul(_ether,nominator) / denominator;	
	}
	
	//temp
	function burnSTCDR(uint256 _stcdr, uint256 _ether) public  view returns (uint256 stcdrBurnReturn)
	{
		uint256 _stcMaxBonus =stcMaxBonus(_stcdr);
		uint256 _stcOrginalBuy =stcOrginalBuy(_ether);
		if (_stcOrginalBuy >= _stcMaxBonus){
			return _stcdr;
		} else {
			return safeMul(_stcOrginalBuy,stcRatio) / 10000000000;			
		}		
	}
	//temp
	function sTCBonus(uint256 _stcdr, uint256 _ether) public  view returns (uint256 bonusSTCReturn)
	{
		uint256 _stcMaxBonus =stcMaxBonus(_stcdr);
		uint256 _stcOrginalBuy =stcOrginalBuy(_ether);
		if (_stcOrginalBuy >= _stcMaxBonus){
			return safeMul(_stcMaxBonus,discount) / 100;
		} else {
			return safeMul(_stcOrginalBuy,discount) / 100;			
		}		
	}
	//temp
	function totalSTC(uint256 _stcdr, uint256 _ether) public  view returns (uint256 totalSTCReturn)
	{
		return	stcOrginalBuy(_ether) + sTCBonus(_stcdr,_ether);	
	}
	//temp
	function allowedToBurn(uint256 _stcdr) public  view returns (uint256 allowedtokentoburnReturn)
	{
		return STCDRToken.allowance(msg.sender, this);
	}
	
	function burnUserTokens(uint256 _stcdr) public
	{
		STCDRToken.transferFrom(msg.sender,this,_stcdr);
		STCDRToken.transfer(tokenBurnAddres, _stcdr);
	}
	
	function forwardETHtoSTCcontract(uint256 _ether) public
	{
		STCToken.buyTo.value(_ether)(msg.sender);
	}
	
}