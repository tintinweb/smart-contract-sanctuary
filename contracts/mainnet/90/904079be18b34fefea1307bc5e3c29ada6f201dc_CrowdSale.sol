pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations that are safe for uint256 against overflow and negative values
 * @dev https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Moderated
 * @dev restricts execution of &#39;onlyModerator&#39; modified functions to the contract moderator
 * @dev restricts execution of &#39;ifUnrestricted&#39; modified functions to when unrestricted 
 *      boolean state is true
 * @dev allows for the extraction of ether or other ERC20 tokens mistakenly sent to this address
 */
contract Moderated {
    
    address public moderator;
    
    bool public unrestricted;
    
    modifier onlyModerator {
        require(msg.sender == moderator);
        _;
    }
    
    modifier ifUnrestricted {
        require(unrestricted);
        _;
    }
    
    modifier onlyPayloadSize(uint256 numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }    
    
    function Moderated() public {
        moderator = msg.sender;
        unrestricted = true;
    }
    
    function reassignModerator(address newModerator) public onlyModerator {
        moderator = newModerator;
    }
    
    function restrict() public onlyModerator {
        unrestricted = false;
    }
    
    function unrestrict() public onlyModerator {
        unrestricted = true;
    }  
    
    /// This method can be used to extract tokens mistakenly sent to this contract.
    /// @param _token The address of the token contract that you want to recover
    function extract(address _token) public returns (bool) {
        require(_token != address(0x0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        return token.transfer(moderator, balance);
    }
    
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return (size > 0);
    }    
} 

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token { 

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);    
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);    
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);    

}






/**
 * @title Controlled
 * @dev Restricts execution of modified functions to the contract controller alone
 */
contract Controlled {
    address public controller;

    function Controlled() public {
        controller = msg.sender;
    }

    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    function transferControl(address newController) public onlyController{
        controller = newController;
    }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Controlled {
    using SafeMath for uint256;
    
    enum State { Active, Refunding, Closed }
    
    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;        
        state = State.Active;
    }

	function () external payable {
	    revert();
	}
    
    function deposit(address investor) onlyController public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }
    
    function close() onlyController public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }
    
    function enableRefunds() onlyController public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }
    
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract CrowdSale is Moderated {
	using SafeMath for uint256;
	
	// LEON ERC20 smart contract
	Token public tokenContract;
	
    // crowdsale starts 1 March 2018, 00h00 PDT
    uint256 public constant startDate = 1519891200;
    // crowdsale ends 31 December 2018, 23h59 PDT
    uint256 public constant endDate = 1546243140;
    
    // crowdsale aims to sell at least 100 000 LEONS
    uint256 public constant crowdsaleTarget = 100000 * 10**18;
    uint256 public constant margin = 1000 * 10**18;
    // running total of tokens sold
    uint256 public tokensSold;
    
    // ethereum to US Dollar exchange rate
    uint256 public etherToUSDRate;
    
    // address to receive accumulated ether given a successful crowdsale
	address public constant etherVault = 0xD8d97E3B5dB13891e082F00ED3fe9A0BC6B7eA01;    
	// vault contract escrows ether and facilitates refunds given unsuccesful crowdsale
	RefundVault public refundVault;
    
    // minimum of 0.005 ether to participate in crowdsale
	uint256 constant purchaseThreshold = 5 finney;

    // boolean to indicate crowdsale finalized state	
	bool public isFinalized = false;
	
	bool public active = false;
	
	// finalization event
	event Finalized();
	
	// purchase event
	event Purchased(address indexed purchaser, uint256 indexed tokens);
    
    // checks that crowd sale is live	
    modifier onlyWhileActive {
        require(now >= startDate && now <= endDate && active);
        _;
    }	
	
    function CrowdSale(address _tokenAddr, uint256 price) public {
        // the LEON token contract
        tokenContract = Token(_tokenAddr);
        // initiate new refund vault to escrow ether from purchasers
        refundVault = new RefundVault(etherVault);
        
        etherToUSDRate = price;
    }	
	function setRate(uint256 _rate) public onlyModerator returns (bool) {
	    etherToUSDRate = _rate;
	}
	// fallback function invokes buyTokens method
	function() external payable {
	    buyTokens(msg.sender);
	}
	
	// forwards ether received to refund vault and generates tokens for purchaser
	function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhileActive returns (bool) {
	    require(!targetReached());
	    require(msg.value > purchaseThreshold);
	    refundVault.deposit.value(msg.value)(_purchaser);
	    // 1 LEON is priced at 1 USD
	    // etherToUSDRate is stored in cents, /100 to get USD quantity
	    // crowdsale offers 100% bonus, purchaser receives (tokens before bonus) * 2
	    // tokens = (ether * etherToUSDRate in cents) * 2 / 100
		uint256 _tokens = (msg.value).mul(etherToUSDRate).div(50);		
		require(tokenContract.transferFrom(moderator,_purchaser, _tokens));
        tokensSold = tokensSold.add(_tokens);
        Purchased(_purchaser, _tokens);
        return true;
	}	
	
	function initialize() public onlyModerator returns (bool) {
	    require(!active && !isFinalized);
	    require(tokenContract.allowance(moderator,address(this)) == crowdsaleTarget + margin);
	    active = true;
	}
	
	// activates end of crowdsale state
    function finalize() public onlyModerator {
        // cannot have been invoked before
        require(!isFinalized);
        // can only be invoked after end date or if target has been reached
        require(hasEnded() || targetReached());
        
        // if crowdsale has been successful
        if(targetReached()) {
            // close refund vault and forward ether to etherVault
            refundVault.close();

        // if the sale was unsuccessful    
        } else {
            // activate refund vault
            refundVault.enableRefunds();
        }
        // emit Finalized event
        Finalized();
        // set isFinalized boolean to true
        isFinalized = true;
        
        active = false;

    }
    
	// checks if end date of crowdsale is passed    
    function hasEnded() internal view returns (bool) {
        return (now > endDate);
    }
    
    // checks if crowdsale target is reached
    function targetReached() internal view returns (bool) {
        return (tokensSold >= crowdsaleTarget);
    }
    
    // refunds ether to investors if crowdsale is unsuccessful 
    function claimRefund() public {
        // can only be invoked after sale is finalized
        require(isFinalized);
        // can only be invoked if sale target was not reached
        require(!targetReached());
        // if msg.sender invested ether during crowdsale - refund them of their contribution
        refundVault.refund(msg.sender);
    }
}