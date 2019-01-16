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

// File: contracts\TeamWallet.sol

contract TeamWallet {  
	using SafeMath for uint256;

	struct Member {		
    uint256 tokenAmount;
		uint256 tokenRemain;
		uint withdrawStage;		
		address lastRejecter;
    bool isRejected;
	}

  ERC20 public tokenContract;
	uint256 public totalToken;
	address public creator;
	bool public allocateTokenDone = false;

	mapping(address => Member) public members;

  uint public firstUnlockDate;
  uint public secondUnlockDate;
  uint public thirdUnlockDate;

  address public approver1;
  address public approver2;

  event WithdrewTokens(address _tokenContract, address _to, uint256 _amount);  
  event RejectedWithdrawal(address _rejecter, address _member, uint _withdrawStage);

	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

  modifier onlyApprover() {
    require(msg.sender == approver1 || msg.sender == approver2);
    _;
  }

  constructor(
    address _tokenAddress,
    address _approver1, 
    address _approver2
  ) public {
    require(_tokenAddress != address(0));
    require(_approver1 != address(0));
    require(_approver2 != address(0));

    creator = _tokenAddress;		
    tokenContract = ERC20(_tokenAddress);
    
    firstUnlockDate = now + (12 * 30 days); // Allow withdraw 20% after 12 month    
    secondUnlockDate = now + (24 * 30 days); // Allow withdraw 30% after 24 month
    thirdUnlockDate = now + (36 * 30 days); // Allow withdraw all after 36 month    

    approver1 = _approver1;
    approver2 = _approver2;
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() external onlyCreator {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addMember(address _memberAddress, uint256 _tokenAmount) external onlyCreator {		
		require(!allocateTokenDone);
		members[_memberAddress] = Member(_tokenAmount, _tokenAmount, 0, address(0), false);
    totalToken = totalToken.add(_tokenAmount);
	}
	
  // callable by team member only, after specified time
  function withdrawTokens() public {		
    require(now > firstUnlockDate);
		Member storage member = members[msg.sender];
		require(member.tokenRemain > 0 && member.isRejected == false);

    uint256 amount = 0;
    if(now > thirdUnlockDate) {
      // withdrew all remain token in third stage
      amount = member.tokenRemain;      
    } else if(now > secondUnlockDate && member.withdrawStage == 1) {
      // withdrew 30% in second stage
      amount = member.tokenAmount * 30 / 100;
    } else if(now > firstUnlockDate && member.withdrawStage == 0){
      // withdrew 20% in first stage
      amount = member.tokenAmount * 20 / 100;
    }

    if(amount > 0) {
			member.tokenRemain = member.tokenRemain.sub(amount);      
			member.withdrawStage = member.withdrawStage + 1;      
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      return;
    }

    revert();
  }  

  function rejectWithdrawal(address _memberAddress) external onlyApprover {
		Member storage member = members[_memberAddress];
    require(member.lastRejecter != msg.sender);
		require(member.tokenRemain > 0 && member.isRejected == false);

    //have a admin reject member before
    if(member.lastRejecter != address(0)) {      
			member.isRejected = true;
		}

    member.lastRejecter = msg.sender;
    emit RejectedWithdrawal(msg.sender, _memberAddress, member.withdrawStage);
  }

	function canBurn(address _memberAddress) external view returns(bool) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.isRejected;
		return false;
	}

	function getMemberTokenRemain(address _memberAddress) external view returns(uint256) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.tokenRemain;
		return 0;
	}	

	function burnMemberToken(address _memberAddress) external onlyCreator() {
		Member storage member = members[_memberAddress];
		require(member.tokenRemain > 0 && member.isRejected);
		member.tokenRemain = 0;
	}	
}