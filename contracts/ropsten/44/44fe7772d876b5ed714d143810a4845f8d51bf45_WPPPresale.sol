pragma solidity ^0.4.19;


contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 * The WPPToken contract does this and that...
 */
contract WPPToken is ERC20, Ownable {

	using SafeMath for uint256;

	uint256  public  totalSupply = 500000000000 * 1 ether;


	mapping  (address => uint256)                       _balances;
    mapping  (address => mapping (address => uint256))  _approvals;

    string   public  name = &quot;WPPTOKEN&quot;;
    string   public  symbol = &quot;WPP&quot;;
    uint256  public  decimals = 18;

    event Mint(uint256 wad);
    

    constructor () public{
		_balances[owner] = totalSupply;
	}

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }

    function mint(uint256 wad) public onlyOwner {
        _balances[msg.sender] = _balances[msg.sender].add(wad);
        totalSupply = totalSupply.add(wad);
        emit Mint(wad);
    }

}


contract WPPPresale {
	using SafeMath for uint256;
	WPPToken wpp;
	uint256 public tokencap = 250000000 * 1 ether;
	// uint256 public  softcap = 50000000 * 1 ether;
	uint256 public  hardcap = 250000000 * 1 ether;
	bool    public  reached = false;
	uint    public  startTime ;
	uint    public  endTime ;
	uint256 public   rate = 2700;
	uint256 public   remain;

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint time);

	constructor(address token, uint _startTime, uint _endTime) public{
		wpp = WPPToken(token);
		startTime = _startTime; // 1530450000 2018-07-01 9:AM EDT
		endTime = _endTime; // 1535806800 2018-09-01 9:AM EDT
		remain = hardcap;
	}

	  // fallback function can be used to buy tokens
	function () public payable {
		buyTokens(msg.sender);
	}

	// low level token purchase function
	function buyTokens(address beneficiary) public payable {
		buyTokens(beneficiary, msg.value);
	}

	// implementation of low level token purchase function
	function buyTokens(address beneficiary, uint256 weiAmount) internal {
		require(beneficiary != 0x0);
		require(validPurchase(weiAmount));

		// calculate token amount to be sent
		uint256 tokens = weiAmount.mul(rate);
		remain = remain.sub(tokens);
		if(remain < 0){
			uint256 real = remain;

			uint256 refund = weiAmount - real.div(rate);

			beneficiary.transfer(refund);

			transferToken(beneficiary, calcBonus(real));

			forwardFunds(weiAmount.sub(refund));

			emit TokenPurchase(msg.sender, beneficiary, weiAmount.sub(refund), calcBonus(real), now);
		} else{
			transferToken(beneficiary, calcBonus(tokens));

			forwardFunds(weiAmount);

			emit TokenPurchase(msg.sender, beneficiary, weiAmount, calcBonus(tokens), now);
		}

	}

	function calcBonus(uint256 token_amount) internal constant returns (uint256) {
		if(now > startTime && now <= (startTime + 3 days))
			return token_amount * 110 / 100;
	}

	// low level transfer token
	// override to create custom token transfer mechanism, eg. pull pattern
	function transferToken(address beneficiary, uint256 tokenamount) internal {

		wpp.transfer(beneficiary, tokenamount);

	}

	// send ether to the fund collection wallet
	// override to create custom fund forwarding mechanisms
	function forwardFunds(uint256 weiAmount) internal {
		address(this).transfer(weiAmount);
	}

	// @return true if the transaction can buy tokens
	function validPurchase(uint256 weiAmount) internal constant returns (bool) {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = weiAmount >= 1 ether;
		bool withinSale = reached ? false : true;
		return withinPeriod && nonZeroPurchase && withinSale;
	}

	// @return true if crowdsale event has ended
	function hasEnded() public constant returns (bool) {
		return now > endTime;
	}

	// @return true if crowdsale has started
	function hasStarted() public constant returns (bool) {
		return now >= startTime;
	}
	
}