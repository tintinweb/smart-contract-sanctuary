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
  }
  contract Ownership is SafeMath {
	address public fundWallet;
	modifier onlyFundWallet {
        require(msg.sender == fundWallet);
        _;
    }
	function changeFundWallet(address newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = newFundWallet;
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
	
  contract STCDRListing is Ownership {
	string public name = "STCDR Listing";
	bool public enable = true;
	uint256 public count =0 ;
	
	// MAPPING
	mapping (uint256 => Sendvalue) public receivedEther;
		
	  // EVENTS
    event Received(address indexed participant,uint256 amountEther);
	event Withdraw(uint256 amountEther);
	 
	// TYPES
	struct Sendvalue { // tokensPerEth
		address sender;
		uint256 value;
	}		
	 // CONSTRUCTOR
	function STCDRListing() public  {
        fundWallet = msg.sender;
    }
	function removeLiquidity(uint256 amount) external onlyFundWallet {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
		Withdraw(amount);
    }	
	function stop() external onlyFundWallet {
        enable = false;
    }
	function start() external onlyFundWallet {
        enable = true;
    }
	function() payable {
		require(tx.origin == msg.sender);
		require(enable);
		require(msg.value>0);
		count =	safeAdd(count,1);		
		receivedEther[count] = Sendvalue(msg.sender,msg.value);
		Received(msg.sender,msg.value);
	}
	function claimTokens(address _token) external onlyFundWallet {
			require(_token != address(0));
			Token token = Token(_token);
			uint256 balance = token.balanceOf(this);
			token.transfer(fundWallet, balance);
	}	 
  }