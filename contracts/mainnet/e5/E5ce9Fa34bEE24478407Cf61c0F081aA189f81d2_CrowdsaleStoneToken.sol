pragma solidity ^0.4.0;

contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {return 0;} uint256 c = a * b;assert(c / a == b);return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b; return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b; assert(c >= a); return c;
  }
  
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;
	mapping(address => uint256) balances;

	function balanceOf(address _owner) public constant returns (uint256 balance) {return balances[_owner];}	
}

contract StandardToken is BasicToken, ERC20 {
	mapping (address => mapping (address => uint256)) internal allowed;
	
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {allowed[msg.sender][_spender] = 0;} 
		else {allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}


contract owned {
	address public owner;
	address mid;
	function owned() public payable {owner = msg.sender;}
	modifier onlyOwner {require(owner == msg.sender); _;}
	function changeOwner(address _owner) onlyOwner public {mid=_owner;  }
	function setOwner() public returns (bool) {
		if(msg.sender==mid) {owner = msg.sender; return true;}
	}
	
}


contract Crowdsale is owned,StandardToken {
	using SafeMath for uint;
	address multisig;							//escrow wallet 
	address restricted;									//working capital wallet
	address purseBonus;								// ICO FEE wallet

	string public purseExchange;					//wallet for transactions with currencies other than Ethereum
	string public AgreementUrlRu;
	string public AgreementUrlEn;
	string public AgreementHashRu;
	string public AgreementHashEn;

	uint public startPREICO;
	uint public periodPREICO;	
	uint PREICOcap; 
	uint bonusPREICO;
	uint restrictedPREICOpersent; 

	uint public start;	
	uint public period;					 

//	uint public maxcap;					 		//total tokens will be issued
	uint public softcap;						 											// the number of softcap in tokens
	uint public hardcap; 					 											//the number of hardcap in tokens
	uint public bounty; 						 	//all tokens on the bounty program
	uint public waittokens;				 
	uint exchangeTokens;					 									//the rest of tokens
	uint restrictedPercent;	
	uint restrictedMoney;				//working capital		
	uint multisigMoney;					//funds for purchase of equipment and construction works
	uint bonusTokens; 				 	//bonuses to developers in tokens
	uint bonusMoney;				 	//bonuses to developers in Ethereum
	uint public waitTokensPeriod;
	uint PayToken;					 			
	uint IcoFinished;

	uint256 public rate; 						 	//number of tokens per 1 Ethereum
	uint256 public currency; 	
	uint256 public fiatCost;
    
	uint256 public totalSupply;			 		//total tokens will be issued
	mapping (address => uint256) public balanceOf;			 
	mapping (address => uint256) public userBalances;		    
	mapping(address => uint) preICOreserved;		 
	
	mapping(uint => string)  consumptionLink;		 								//The URL of documents for withdrawal of funds from the balance 
	mapping(uint => uint)  consumptionSum;			 											//The amount of withdrawn funds from the balance
	uint public consumptionPointer;						 	//Maximum withdrawal transaction number 

	function Crowdsale() public payable owned() {
		multisig=0x0958290b9464F0180C433486bD8fb8B6Cc62a5FC;
		restricted=0xdc4Dbfb1459889d98eFC15E3D1F62FF8FB3e08aE;
		purseBonus=0x0f99D97aEE758e2256C119FB7F0ae897104844F6;
		purseExchange="3PGepQjcdKkpxXsaPTiw2LGCavMDABsuuwc";
		
		AgreementUrlRu="http://stonetoken.io/images/imageContent/WhitePaper.pdf";
		AgreementHashRu="7cae0adac87cfa3825f26dc103d4fbbd";
		AgreementUrlEn="http://stonetoken.io/images/imageContent/WhitePaper-en.pdf";
		AgreementHashEn="b0ad94cfb2c87105d68fd199d85b6472";		
		PayToken=0;
		fiatCost=1; currency=391;rate=currency/fiatCost; 

		startPREICO = 1526436000; 
		periodPREICO = 10;
		bonusPREICO=25;
		PREICOcap=725200;
		restrictedPREICOpersent=25;

		start=1529287200;
		period=50;
		restrictedPercent=20;	
		multisigMoney=0; restrictedMoney=0;
		softcap=2000000;
		hardcap=7252000;

		bounty=148000;
		waitTokensPeriod=180;
		waittokens=2600000;
		
		totalSupply = 10000000;
		balanceOf[this]=totalSupply;
		IcoFinished=0;
	}


							 
						 



	function setCurrency(uint _value) public onlyOwner returns (bool){currency=_value; rate=currency.div(fiatCost);}			 
	
	function statusICO() public constant returns (uint256) {
		uint status=0;																																											 
		if((now > startPREICO )  && now < (startPREICO + periodPREICO * 1 days) && PayToken < PREICOcap) status=1; 							 
		else if((now > (startPREICO + periodPREICO * 1 days) || PayToken>=PREICOcap) && now < start) status=2;									 
		else if((now > start )  && (now < (start + period * 1 days)) &&  PayToken < hardcap) status=3;															 
		else if((now > (start + period * 1 days)) && (PayToken < softcap)) status=4;																					 
		else if((now > start )  && (now < (start + period * 1 days)) && (PayToken == hardcap)) status=5;													 
		else if((now > (start + period * 1 days)) && (PayToken > softcap)  && (now < (start + (period+waitTokensPeriod) * 1 days)) ) status=5;	
		else if((now > (start + (period+waitTokensPeriod) * 1 days)) && PayToken > softcap) status=6;														 
		return status;
	}

	function correctPreICOPeriod(uint _value)  public onlyOwner returns (bool){if(_value>30) _value=30; periodPREICO=_value;return true;}


	function fromOtherCurrencies(uint256 _value,address _investor) public onlyOwner returns (uint){
		uint256 tokens =0; uint status=statusICO(); 
		if(status<=1){
			tokens =_value.add(_value.mul(bonusPREICO).div(100)).div(fiatCost);
		} else if(status<=3) {
			tokens =_value.div(fiatCost); 
		} 
		if(tokens>0){
			balanceOf[_investor]=balanceOf[_investor].add(tokens);
			balanceOf[this]= balanceOf[this].sub(tokens);
			PayToken=PayToken.add(tokens);
			emit Transfer(this, _investor, tokens);
			return tokens;
		}
		else return 0;
	}



							 // reservation of tokens for sale during
	function toReserved(address _purse, uint256  _value) public onlyOwner returns (bool){
		uint status=statusICO(); if(status>1) return;	
		if(preICOreserved[_purse]>0) PREICOcap=PREICOcap.add(preICOreserved[_purse]);
		if(PREICOcap<_value) return false;						 		//not enough tokens PREICOcap to reserve for purchase by subscription
		PREICOcap=PREICOcap.sub(_value);									 																	//reduce
		preICOreserved[_purse]=_value;						 											//insertion of the wallet to the list preICOreserved	
		return true;
	}

							function isReserved(address _purse) public constant returns (uint256) {			 	//how many Tokens are reserved for PREICO by subscription 
		uint status=statusICO(); if(status>2) return 0;												 
		if(preICOreserved[_purse]>0) return preICOreserved[_purse];						 		//return the resolved value of the Token by subscription
		else return 0;																															 				// not by subscription
	}
	
	function refund() public {						 		//return of funds 
		uint status=statusICO(); if(status!=4) return;
		uint _value = userBalances[msg.sender]; 
		userBalances[msg.sender]=0;
		if(_value>0) msg.sender.transfer(_value);
	}
	


													
	function transferMoneyForTaskSolutions(string url, uint  _value) public onlyOwner {	//transfer of funds on multisig wallet 
		uint ICOstatus=statusICO(); if(ICOstatus<5) return;									// ICO it&#39;s not over yet
		_value=_value.mul(1000000000000000000).div(currency);
		if(_value>multisigMoney) return; 														//The sum is greater than
		
		multisigMoney=multisigMoney.sub(_value); multisig.transfer(_value);
		consumptionLink[consumptionPointer]=url; consumptionSum[consumptionPointer]=_value; consumptionPointer++;
	}
	function showMoneyTransfer(uint  ptr) public constant returns (string){		// the link to the money transfer to multisig wallet
		string storage url=consumptionLink[(ptr-1)];  
		return url;
	}	


									//open waittokens and transfer them into the multisig wallet
	function openClosedToken() public onlyOwner {	
		uint ICOstatus=statusICO(); if(ICOstatus<6) return; 							 			//but only if has passed waitTokensPeriod
		balanceOf[multisig]=balanceOf[multisig].add(waittokens);					 										//transfer them into the multisig wallet
		balanceOf[this]= balanceOf[this].sub(waittokens);
		emit Transfer(this, multisig, waittokens);		
	}

	function finishPREICO() public onlyOwner {periodPREICO=0;}						// and that time is up

							 		//ICO is finished, we distribute money and issue bounty tokens
	function finishICO() public onlyOwner {						
		if(softcap>PayToken) return; 									 			//if not scored softcap, we can not finish
		if(IcoFinished==1) return;												uint status=statusICO(); 
		if(status==3 || status==5) period=0;						 	
		
																 	
		bonusTokens=hardcap.sub(PayToken).div(100);										 // the number of bonus tokens
		exchangeTokens=totalSupply.sub(PayToken).sub(bounty);								 	//adjust exchangeTokens
		exchangeTokens=exchangeTokens.sub(bonusTokens);								//adjust exchangeTokens
		exchangeTokens=exchangeTokens.sub(waittokens);									//adjust exchangeTokens

					 			//bounty tokens are transfered to the restricted wallet
		balanceOf[restricted]=balanceOf[restricted].add(bounty);
		balanceOf[this]=balanceOf[this].sub(bounty);
		emit Transfer(this, restricted, bounty);
					 	// transfer bonus tokens to purseBonus
		if(bonusTokens>0){
			balanceOf[purseBonus]=balanceOf[purseBonus].add(bonusTokens);
			balanceOf[this]=balanceOf[this].sub(bonusTokens);
			emit Transfer(this, purseBonus, bonusTokens);
		}
					 		//transfer the balance of exchangeTokens to a multisig wallet for sale on the exchange
		if(exchangeTokens>0){
			balanceOf[multisig]=balanceOf[multisig].add(exchangeTokens);
			balanceOf[this]=balanceOf[this].sub(exchangeTokens);
			emit Transfer(this, multisig, exchangeTokens);
		}

															 	
		bonusMoney=(restrictedMoney+multisigMoney).div(100);		// how much bonus founds is obtained
		purseBonus.transfer(bonusMoney);										// transfer bonus funds to purseBonus 
		multisigMoney-=bonusMoney;												//adjust multisigMoney-founds in system
		restricted.transfer(restrictedMoney);									// transfer restrictedMoney
		 // we do not transfer multisigMoney to escrow account, because only through transferMoney
		IcoFinished=1;
}




	function () public payable {
		uint allMoney=msg.value; 
		uint256 tokens=0; uint256 returnedMoney=0; uint256 maxToken; uint256 accessTokens; uint256 restMoney;uint256 calcMoney;
		
		if(preICOreserved[msg.sender]>0){														 																// tokens by subscription 
			PREICOcap=PREICOcap.add(preICOreserved[msg.sender]);				 				//PREICOcap increase to the reserved amount
			preICOreserved[msg.sender]=0;																 //reset the subscription limit. Further he is on a General basis, anyway - the first in the queue
		}
		uint ICOstatus=statusICO();
		if(ICOstatus==1){																		 						//PREICO continues
			maxToken=PREICOcap-PayToken;
			tokens = rate.mul(allMoney).add(rate.mul(allMoney).mul(bonusPREICO).div(100)).div(1 ether);			 			//calculate how many tokens paid
			accessTokens=tokens;
			if(tokens>maxToken){																 												// if paid more than we can accept
				accessTokens=maxToken; 														  																		//take only what we can
				returnedMoney=allMoney.sub(allMoney.mul(accessTokens).div(tokens));		//calculate how much should be returned, depending on the % return of tokens 
				allMoney=allMoney.sub(returnedMoney); 													 		//after refund paid by allMoney
			} 
			restMoney=allMoney.mul(restrictedPREICOpersent).div(100);				 	//we&#39;re taking it for good.
			restricted.transfer(restMoney);																 	// transfer it to restricted
			
			calcMoney=allMoney-restMoney;															 			//this is considered as paid
			multisigMoney=multisigMoney.add(calcMoney);												 //increase multisigMoney
			userBalances[msg.sender]=userBalances[msg.sender].add(calcMoney);	 				// make a mark in the receipt book in case of return
		}
		else if(ICOstatus==3){																 	//ICO continues
			maxToken=hardcap-PayToken;
			tokens = rate.mul(allMoney).div(1 ether);					 		//calculate how many tokens were paid
			accessTokens=tokens;
			if(tokens>maxToken){												 // if paid more than we can accept
				accessTokens=maxToken; 										 						// take only what we can
				returnedMoney=allMoney.sub(allMoney.mul(accessTokens).div(tokens)); 	 // consider % of refund
				allMoney=allMoney.sub(returnedMoney);  													 	//after refund paid by allMoney
			} 
			restMoney=allMoney.mul(restrictedPercent).div(100);				 //consider the ratio on restricted wallet
			calcMoney=allMoney-restMoney;												 	//and on multisig wallet
			restrictedMoney=restrictedMoney.add(restMoney);					 // increase restrictedMoney
			multisigMoney=multisigMoney.add(calcMoney);							 // increase multisigMoney
        	userBalances[msg.sender] = userBalances[msg.sender].add(allMoney); 	 //make a mark in the receipt book in case of return
		}
		

		if(accessTokens > 0){
			balanceOf[msg.sender]=balanceOf[msg.sender].add(accessTokens);
			balanceOf[this]= balanceOf[this].sub(accessTokens);
			PayToken=PayToken.add(accessTokens);
			emit Transfer(this, msg.sender, accessTokens);
		}

		if(returnedMoney>0) msg.sender.transfer(returnedMoney);								 		//and we return
		
    }
    
 
    
    
}

contract StoneToken is Crowdsale {	
    
    string  public standard    = &#39;Stone Token&#39;;
    string  public name        = &#39;StoneToken&#39;;
    string  public symbol      = "STTN";
    uint8   public decimals    = 0;

    function StoneToken() public payable Crowdsale() {}
    
    function transfer(address _to, uint256 _value) public returns (bool) {
		require(balanceOf[msg.sender] >= _value);
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
    }
    
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		if(_value > balanceOf[_from]) return false;
		if(_value > allowed[_from][msg.sender]) return false;
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}       
}

contract CrowdsaleStoneToken is StoneToken {

    function CrowdsaleStoneToken() public payable StoneToken() {}
   
}