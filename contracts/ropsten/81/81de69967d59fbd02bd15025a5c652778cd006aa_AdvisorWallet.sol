pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts\ERC20Interface.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\AdvisorWallet.sol

contract AdvisorWallet {  
	using SafeMath for uint256;

	struct Advisor {		
		uint256 tokenAmount;    
		uint withdrawStage;		
	}

  ERC20 public tokenContract;
	uint256 public totalToken;
	address public creator;
	bool public allocateTokenDone = false;

	mapping(address => Advisor) public advisors;

  uint public firstUnlockDate;
  uint public secondUnlockDate;  

  event WithdrewTokens(address _tokenContract, address _to, uint256 _amount);  

	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

  constructor(address _tokenAddress) public {
    require(_tokenAddress != address(0));

    creator = _tokenAddress;
    tokenContract = ERC20(_tokenAddress);

    firstUnlockDate = now + (6 * 30 days); // Allow withdraw 50% after 6 month
    secondUnlockDate = now + (12 * 30 days); // Allow withdraw all after 12 month
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() external onlyCreator {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addAdvisor(address _memberAddress, uint256 _tokenAmount) external onlyCreator {		
		require(!allocateTokenDone);
		advisors[_memberAddress] = Advisor(_tokenAmount, 0);
    totalToken = totalToken.add(_tokenAmount);
	}
	
  // callable by advisor only, after specified time
  function withdrawTokens() external {		
    require(now > firstUnlockDate);
		Advisor storage advisor = advisors[msg.sender];
		require(advisor.tokenAmount > 0);

    uint256 amount = 0;
    if(now > secondUnlockDate) {
      // withdrew all token remain in second stage
      amount = advisor.tokenAmount;
    } else if(now > firstUnlockDate && advisor.withdrawStage == 0){
      // withdrew 50% in first stage
      amount = advisor.tokenAmount * 50 / 100;
    }

    if(amount > 0) {
			advisor.tokenAmount = advisor.tokenAmount.sub(amount);      
			advisor.withdrawStage = advisor.withdrawStage + 1;      
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      return;
    }

    revert();
  }
}