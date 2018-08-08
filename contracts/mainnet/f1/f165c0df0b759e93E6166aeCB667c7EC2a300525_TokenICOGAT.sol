pragma solidity ^0.4.13;
//date 1500114129 by Ournet International2022649
contract tokenGAT {
        
        uint256 public totalContribution = 0;
        uint256 public totalBonusTokensIssued = 0;
        uint256 public totalSupply = 0;
        function balanceOf(address _owner) constant returns (uint256 balance);
        function transfer(address _to, uint256 _value) returns (bool success);
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
        function approve(address _spender, uint256 _value) returns (bool success);
        function allowance(address _owner, address _spender) constant returns (uint256 remaining);
        //events for logging
        event LogTransaction(address indexed _addres, uint256 value);
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        }

/*  ERC 20 token this funtion are also call when somebody or contract want transfer, send, u operate wiht our tokens*/
contract StandarTokentokenGAT is tokenGAT{
mapping (address => uint256) balances; //asociative array for associate address and its balance like a hashmapp in java
mapping (address => uint256 ) weirecives; //asociative array for associate address and its balance like a hashmapp in java
mapping (address => mapping (address => uint256)) allowed; // this store addres that are allowed for operate in this contract

	
function allowance(address _owner, address _spender) constant returns (uint256) {
    	return allowed[_owner][_spender];
}

function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
}
	
function transfer(address _to, uint256 _value) returns (bool success) { 
   	if(msg.data.length < (2 * 32) + 4) { revert();} 	// mitigates the ERC20 short address attack
    if (balances[msg.sender] >= _value && _value >= 0){ 
		balances[msg.sender] -= _value; //substract balance from user that is transfering (who deploy or who executed it)
		balances[_to] += _value;  //add balance from user that is transfering (who deploy or who executed it)
		Transfer(msg.sender, _to, _value);    //login
       	return true;
     }else
   		return false;
     }
	
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     	if(msg.data.length < (3 * 32) + 4) { revert(); } // mitigates the ERC20 short address attack
       if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0){		
         //add balance to destinate address
          balances[_to] += _value;
		   //substract balance from source address
        	balances[_from] -= _value;        	
        	allowed[_from][msg.sender] -= _value;
		   //loggin
        	Transfer(_from, _to, _value);
        	return true;
    	} else 
  			return false;
	}
//put the addres in allowed mapping	
 function approve(address _spender, uint256 _value) returns (bool success) {
   // mitigates the ERC20 spend/approval race condition
	if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }    	
   	allowed[msg.sender][_spender] = _value;    	
    	Approval(msg.sender, _spender, _value);
    	return true;
	}
}

contract TokenICOGAT is StandarTokentokenGAT{	
	
	address owner = msg.sender;
	
	//Token Metadata
	function name() constant returns (string) { return "General Advertising Token"; }
	function symbol() constant returns (string) { return "GAT"; }
	uint256 public constant decimals = 18;
	
    //ICO Parameters
	bool public purchasingAllowed = false;	
	address public ethFoundDeposit;      // deposit address for ETH for OurNet International
	address public gatFoundDeposit;      // deposit address for Brave International use and OurNet User Fund
 	uint public deadline; 	//epoch date to end of crowsale
 	uint public startline; 	//when crowsale start
	uint public refundDeadLine;	// peiorode avaible for get refound
	uint public transactionCounter;//counter for calcucalate bonus
 	uint public etherReceived; // Number of Ether received
 	uint256 public constant gatFund = 250 * (10**6) * 10**decimals;   // 250m GAT reserved for OurNet Intl use, early adopters incentive and ournNet employees team
 	uint256 public constant tokenExchangeRate = 9000; // 9000 GAT tokens per 1 ETH
 	uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals; //total of tokens issued
 	uint256 public constant tokenSellCap =  750 * (10**6) * 10**decimals; //maximun of gat tokens for sell
	uint256 public constant tokenSaleMin =  17 * (10**6) * 10**decimals; //minimun goal
 
  //constructor or contract	
 function TokenICOGAT(){
  startline = now;
  deadline = startline + 45 * 1 days;
  refundDeadLine = deadline + 30 days;
  ethFoundDeposit = owner;
  gatFoundDeposit = owner;   	 
  balances[gatFoundDeposit] = gatFund; //deposit fondos for ourNet international 
  LogTransaction(gatFoundDeposit,gatFund); //login transaction 
 }
  
 function bonusCalculate(uint256 amount) internal returns(uint256){
 	uint256 amounttmp = 0;
	if (transactionCounter > 0 && transactionCounter <= 1000){
    	return  amount / 2   ;   // bonus 50%
	}
	if (transactionCounter > 1000 && transactionCounter <= 2000){
    return	 amount / 5 ;   // bonus 20%
	}
	if (transactionCounter > 2000 && transactionCounter <= 3000){
     return	amount / 10;   // bonus 10%
	}
	if (transactionCounter > 3000 && transactionCounter <= 5000){
     return	amount / 20;   // bonus 5%
	}
 	return amounttmp;
	}	  
	
	function enablePurchasing() {
   	if (msg.sender != owner) { revert(); }
		if(purchasingAllowed) {revert();}
		purchasingAllowed = true;	
   	}
	
	function disablePurchasing() {
    	if (msg.sender != owner) { revert(); }
	if(!purchasingAllowed) {revert();}		
    	purchasingAllowed = false;		
	}
	
    function getStats() constant returns (uint256, uint256, uint256, bool) {
    	return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
	}
		
	// recive ethers funtion witout name is call every some body send ether
	function() payable {
    	if (!purchasingAllowed) { revert(); }   
        if ((tokenCreationCap - (totalSupply + gatFund)) <= 0) { revert();}  
    	if (msg.value == 0) { return; }
	transactionCounter +=1;
    	totalContribution += msg.value;
    	uint256 bonusGiven = bonusCalculate(msg.value);
        // Number of GAT sent to Ether contributors
    	uint256 tokensIssued = (msg.value * tokenExchangeRate) + (bonusGiven * tokenExchangeRate);
    	totalBonusTokensIssued += bonusGiven;
    	totalSupply += tokensIssued;
    	balances[msg.sender] += tokensIssued;  
	weirecives[msg.sender] += msg.value; // it is import for calculate refund witout token bonus
    	Transfer(address(this), msg.sender, tokensIssued);
   }
		
      
	// send excess of tokens when de ico end
	function sendSurplusTokens() {
    	if (purchasingAllowed) { revert(); } 	
     	if (msg.sender != owner) { revert();}
    	uint256 excess = tokenCreationCap - (totalSupply + gatFund);
	if(excess <= 0){revert();}
    	balances[gatFoundDeposit] += excess;  	
    	Transfer(address(this), gatFoundDeposit, excess);
   }
	
	function withdrawEtherHomeExternal() external{//Regarding security issues the first option is save ether in a online wallet, but if some bad happens, we will use local wallet as contingency plan
		if(purchasingAllowed){revert();}
		if (msg.sender != owner) { revert();}
		ethFoundDeposit.transfer(this.balance); //send ether home		
	}
	
	function withdrawEtherHomeLocal(address _ethHome) external{ // continegency plan
		if(purchasingAllowed){revert();}
		if (msg.sender != owner) { revert();}
		_ethHome.transfer(this.balance); //send ether home		
	}
	
	/* 
     * When tokenSaleMin is not reach:
     * 1) donors call the "refund" function of the GATCrowdFundingToken contract 
	 */
	function refund() public {
	if(purchasingAllowed){revert();} // only refund after ico end
	if(now >= refundDeadLine ){revert();} // only refund are available before ico end + 30 days
	if((totalSupply - totalBonusTokensIssued) >= tokenSaleMin){revert();} // if we sould enough, no refund allow
	if(msg.sender == ethFoundDeposit){revert();}	// OurNet not entitled to a refund
	uint256 gatVal= balances[msg.sender]; // get balance of who is getting from balances mapping
	if(gatVal <=0) {revert();} //if dont have balnace sent no refund
	// balances[msg.sender] = 0;//since donor can hold the tokes as souvenir do not update balance of who is getting refund in gatcontract
        uint256 ethVal = weirecives[msg.sender]; //extract amount contribuited by sender without tokenbonus        
	LogTransaction(msg.sender,ethVal);//loggin transaction
	msg.sender.transfer(ethVal);// send ether comeback	
        totalContribution -= ethVal;
        weirecives[msg.sender] -= ethVal; // getrefound from weirecives
	}
}