pragma solidity ^0.4.16;

  contract SafeMath{

  // math operations with safety checks that throw on error
  // small gas improvement

  function safeMul(uint256 a, uint256 b) internal returns (uint256){
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  function safeDiv(uint256 a, uint256 b) internal returns (uint256){
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }
  
  function safeSub(uint256 a, uint256 b) internal returns (uint256){
    assert(b <= a);
    return a - b;
  }
  
  function safeAdd(uint256 a, uint256 b) internal returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  // mitigate short address attack
  // https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34
  modifier onlyPayloadSize(uint numWords){
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}

  contract Token{

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
  	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  	function balanceOf(address _owner) constant returns (uint256 balance);
  	function transfer(address _to, uint256 _value) returns (bool success);
  	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  	function approve(address _spender, uint256 _value) returns (bool success);
  	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  }

   contract grantVestedEDEX is SafeMath{

  	uint256 public icoEndBlock;
  	address public beneficiary;

    // withdraw first token supply after ICO
  	bool private initialTeamWithdrawal = false;

    // withdraw tokens periodically 
  	uint256 public firstTeamWithdrawal;
  	uint256 public secondTeamWithdrawal;
  	uint256 public thirdTeamWithdrawal;
  	uint256 public fourthTeamWithdrawal;
  	uint256 public fifthTeamWithdrawal;
  	uint256 public sixthTeamWithdrawal;
  	uint256 public seventhTeamWithdrawal;
  	uint256 public eighthTeamWithdrawal;
  	
  	// check periodic withdrawals
    bool private firstWithdrawalFinished = false;
    bool private secondWithdrawalFinished = false;
    bool private thirdWithdrawalFinished = false;
    bool private fourthWithdrawalFinished = false;
    bool private fifthWithdrawalFinished = false;
    bool private sixthWithdrawalFinished = false;
    bool private seventhWithdrawalFinished = false;
    bool private eighthWithdrawalFinished = false;
    
  	Token public ERC20Token;

  	enum Phases{
      	initialTeamWithdrawal,
      	firstTeamWithdrawal,
      	secondTeamWithdrawal,
      	thirdTeamWithdrawal,
      	fourthTeamWithdrawal,
      	fifthTeamWithdrawal,
      	sixthTeamWithdrawal,
      	seventhTeamWithdrawal,
      	eighthTeamWithdrawal
  	}

  	Phases public phase = Phases.initialTeamWithdrawal;

  	modifier atPhase(Phases _phase){
      	if(phase == _phase) _;
  	}

  	function grantVestedEDEX(address _token, uint256 icoEndBlockInput){
      	require(_token != address(0));
      	beneficiary = msg.sender;
      	icoEndBlock = icoEndBlockInput;
      	ERC20Token = Token(_token);
  	}

  	function changeBeneficiary(address newBeneficiary) external{
      	require(newBeneficiary != address(0));
      	require(msg.sender == beneficiary);
      	beneficiary = newBeneficiary;
  	}

  	function changeIcoEndBlock(uint256 newIcoEndBlock){
      	require(msg.sender == beneficiary);
      	require(block.number < icoEndBlock);
      	require(block.number < newIcoEndBlock);
      	icoEndBlock = newIcoEndBlock;
  	}

  	function checkBalance() constant returns (uint256 tokenBalance){
      	return ERC20Token.balanceOf(this);
  	}

  	function withdrawal() external{
      	require(msg.sender == beneficiary);
      	require(block.number > icoEndBlock);
      	uint256 balance = ERC20Token.balanceOf(this);
      	eighth_withdrawal(balance);
      	seventh_withdrawal(balance);
      	sixth_withdrawal(balance);
      	fifth_withdrawal(balance);
      	fourth_withdrawal(balance);
      	third_withdrawal(balance);
      	second_withdrawal(balance);
      	first_withdrawal(balance);
      	initial_withdrawal(balance);
  	}

  	function nextPhase() private{
      	phase = Phases(uint256(phase) + 1);
  	}

    // initial_withdrawal releases 60% of tokens
  	function initial_withdrawal(uint256 balance) private atPhase(Phases.initialTeamWithdrawal){
      	firstTeamWithdrawal = now + 13 weeks;
      	secondTeamWithdrawal = firstTeamWithdrawal + 13 weeks;
      	thirdTeamWithdrawal = secondTeamWithdrawal + 13 weeks;
      	fourthTeamWithdrawal = thirdTeamWithdrawal + 13 weeks;
      	fifthTeamWithdrawal = fourthTeamWithdrawal + 13 weeks;
      	sixthTeamWithdrawal = fifthTeamWithdrawal + 13 weeks;
      	seventhTeamWithdrawal = sixthTeamWithdrawal + 13 weeks;
      	eighthTeamWithdrawal = seventhTeamWithdrawal + 13 weeks;
      	uint256 amountToTransfer = safeDiv(safeMul(balance, 6), 10);
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
 	 
  	function first_withdrawal(uint256 balance) private atPhase(Phases.firstTeamWithdrawal){
      	require(now > firstTeamWithdrawal);
      	uint256 amountToTransfer = balance / 8;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
 	 
  	function second_withdrawal(uint256 balance) private atPhase(Phases.secondTeamWithdrawal){
      	require(now > secondTeamWithdrawal);
      	uint256 amountToTransfer = balance / 7;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
 	 
  	function third_withdrawal(uint256 balance) private atPhase(Phases.thirdTeamWithdrawal){
      	require(now > thirdTeamWithdrawal);
      	uint256 amountToTransfer = balance / 6;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
  	
  	function fourth_withdrawal(uint256 balance) private atPhase(Phases.fourthTeamWithdrawal){
      	require(now > fourthTeamWithdrawal);
      	uint256 amountToTransfer = balance / 5;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
  	
  	function fifth_withdrawal(uint256 balance) private atPhase(Phases.fifthTeamWithdrawal){
      	require(now > fifthTeamWithdrawal);
      	uint256 amountToTransfer = balance / 4;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
  	
  	function sixth_withdrawal(uint256 balance) private atPhase(Phases.sixthTeamWithdrawal){
      	require(now > sixthTeamWithdrawal);
      	uint256 amountToTransfer = balance / 3;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
  	
  	function seventh_withdrawal(uint256 balance) private atPhase(Phases.seventhTeamWithdrawal){
      	require(now > seventhTeamWithdrawal);
      	uint256 amountToTransfer = balance / 2;
      	ERC20Token.transfer(beneficiary, amountToTransfer);
      	nextPhase();
  	}
  	
  	function eighth_withdrawal(uint256 balance) private atPhase(Phases.eighthTeamWithdrawal){
      	require(now > eighthTeamWithdrawal);
      	ERC20Token.transfer(beneficiary, balance);
  	}

  	function withdrawOtherEDEX(address _token) external{
      	require(msg.sender == beneficiary);
      	require(_token != address(0));
      	Token token = Token(_token);
      	require(token != ERC20Token);
      	uint256 balance = token.balanceOf(this);
      	token.transfer(beneficiary, balance);
   	}
 }