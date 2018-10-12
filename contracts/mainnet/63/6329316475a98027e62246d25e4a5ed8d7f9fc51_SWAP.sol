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
contract STC is Token{
	Price public currentPrice;
	uint256 public fundingEndTime;
	address public fundWallet;
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
	address public controlWallet;	
	//event
	event AddLiquidity(uint256 ethAmount);
	event RemoveLiquidity(uint256 ethAmount);
	//modifier
	modifier onlyControlWallet {
			require(msg.sender == controlWallet);
			_;
	}
	// allow controlWallet  to add ether to contract
	function addLiquidity() external onlyControlWallet payable {
			require(msg.value > 0);
			AddLiquidity(msg.value);
	}
	// allow controlWallet to remove ether from contract
	function removeLiquidity(uint256 amount) external onlyControlWallet {
			require(amount <= this.balance);
			controlWallet.transfer(amount);
			RemoveLiquidity(amount);
	}
	function changeControlWallet(address newControlWallet) external onlyControlWallet {
			require(newControlWallet != address(0));
			controlWallet = newControlWallet;
	}
	function halt() external onlyControlWallet {
			halted = true;
	}
	function unhalt() external onlyControlWallet {
			halted = false;
	}
	function claimTokens(address _token) external onlyControlWallet {
			require(_token != address(0));
			Token token = Token(_token);
			uint256 balance = token.balanceOf(this);
			token.transfer(controlWallet, balance);
	}
	
}
contract SWAP is OwnerControl {
	string public name = "SWAP STCDR-STC";	
	STC public STCToken;
	STCDR public STCDRToken;
	uint256 public discount = 5;
	uint256 public stcdr2stc_Ratio = 40;
	//event
	 event TokenSwaped(address indexed _from,  uint256 _stcBuy, uint256 _stcBonus, uint256 _stcdrBurn, uint256 _ethPrice, uint256 _stcPrice);
	//modifier
	//Initialize
	function SWAP(address _STCToken,address _STCDRToken) public  {
			controlWallet = msg.sender;
			STCToken = STC(_STCToken);
			STCDRToken = STCDR(_STCDRToken);
	}	
	function() payable {
			require(tx.origin == msg.sender);
			buyTo(msg.sender);
	}
	function transferTokensAfterEndTime(address participant, uint256 _tokens ,uint256 _tokenBonus , uint256 _tokensToBurn) private
	{
		require(this.balance>=msg.value);
		//Check if STC token are available to transfer
		require(availableSTCTokens() > safeAdd(_tokens,_tokenBonus));
		//Burn Tokens		
		STCDRToken.transferFrom(participant,this,_tokensToBurn);
		STCDRToken.transfer(controlWallet, _tokensToBurn);
		//Transfer STC Tokens
		STCToken.transferFrom(controlWallet,this,safeAdd(_tokens,_tokenBonus));
		STCToken.transfer(participant, _tokens);
		STCToken.transfer(participant, _tokenBonus);
		//TransferMoney
		STCToken.fundWallet().transfer(msg.value);
	}
	function addEthBonusToBuy(address participant, uint256 _ethBonus , uint256 _tokensToBurn ) private {
		//Check If SWAP contract have enaf ether for this opertion
		require(this.balance>=safeAdd(msg.value, _ethBonus));	
	    //Burn Tokens			
		STCDRToken.transferFrom(participant,this,_tokensToBurn);
		STCDRToken.transfer(controlWallet, _tokensToBurn);
		//Forward Etherium in to STC contract
		STCToken.buyTo.value(safeAdd(msg.value, _ethBonus))(participant);
	}
	function buyTo(address participant) public payable {
		require(!halted);		
		require(msg.value > 0);
		
		//Get STCDR tokens that can be transfer and burn
		uint256 availableTokenSTCDR = availableSTCDRTokensOF(participant);
		require(availableTokenSTCDR > 0);
		//Last ETH-USD price
		uint256 _numerator = currentETHPrice();
		require(_numerator > 0);
		//GetEnd Time
		uint256 _fundingEndTime = STCToken.fundingEndTime();
		//STC Denominator price
		uint256 _denominator = currentSTCPrice();	
		require(_denominator > 0);	
		//Max STC that can be as used to callculated bonus
		uint256 _stcMaxBonus = safeMul(availableTokenSTCDR,10000000000) / stcdr2stc_Ratio; //stcMaxBonus(availableTokenSTCDR);
		require(_stcMaxBonus > 0);
		//Calculated STC that user buy for ETH
		uint256 _stcOrginalBuy = safeMul(msg.value,_numerator) / _denominator; //stcOrginalBuy(msg.value);	
		require(_stcOrginalBuy > 0);
		
		uint256 _tokensToBurn =0 ;
		uint256 _tokensBonus =0 ;
		if (_stcOrginalBuy >= _stcMaxBonus){
			_tokensToBurn =  availableTokenSTCDR;
			_tokensBonus= safeSub(safeMul((_stcMaxBonus / safeSub(100,discount)),100),_stcMaxBonus); //safeMul(_stcMaxBonus,discount)/100;
		} else {
			_tokensToBurn = safeMul(_stcOrginalBuy,stcdr2stc_Ratio)/10000000000;	
			_tokensBonus =  safeSub(safeMul((_stcOrginalBuy / safeSub(100,discount)),100),_stcOrginalBuy);  // safeMul(_stcOrginalBuy,discount)/100;					
		} 
		require(_tokensToBurn > 0);
		require(_tokensBonus > 0);
		require(_tokensBonus < _stcOrginalBuy);
		
		if (now < _fundingEndTime) {
			//Method 1 Before End Date
			//Convert Token in to EthValue
			uint256 _ethBonus=safeMul(_tokensBonus, _denominator) / _numerator ;
			addEthBonusToBuy(participant,_ethBonus,_tokensToBurn);
		//----	
		} else {
			//Method 2
			transferTokensAfterEndTime(participant,_stcOrginalBuy,_tokensBonus ,_tokensToBurn);
			//----
		}

	TokenSwaped(participant,  _stcOrginalBuy , _tokensBonus,_tokensToBurn, _numerator ,_denominator);
	}	
	function currentETHPrice() public view returns (uint256 numerator)
	{
		var (a, b) = STCToken.currentPrice();
		return STC.Price(a, b).numerator;
	}	
	function currentSTCPrice() public view returns (uint256 numerator)
	{
		return STCToken.icoDenominatorPrice();
	}
	//Information Tokens Transfered to control wallet for burn.
	function tokenSTCDRforBurnInControlWallett() view returns (uint256 numerator) {
		return  STCDRToken.balanceOf(controlWallet);
	}
	//Information STCDR allowed for user to burn
	function availableSTCDRTokensOF(address _owner) view returns (uint256 numerator) {
		uint256 alowedTokenSTCDR = STCDRToken.allowance(_owner, this);
		uint256 balanceTokenSTCDR = STCDRToken.balanceOf(_owner);
		if (alowedTokenSTCDR>balanceTokenSTCDR) {
			return balanceTokenSTCDR;	
		} else {
			return alowedTokenSTCDR;
		}
	}
	//Information available STC tokens to assign after fundenttime when user use STCDR
	function availableSTCTokens() view returns (uint256 numerator) {
		uint256 alowedTokenSTC = STCToken.allowance(controlWallet, this);
		uint256 balanceTokenSTC = STCToken.balanceOf(controlWallet);
		if (alowedTokenSTC>balanceTokenSTC) {
			return balanceTokenSTC;	
		} else {
			return alowedTokenSTC;
		}
	}

}