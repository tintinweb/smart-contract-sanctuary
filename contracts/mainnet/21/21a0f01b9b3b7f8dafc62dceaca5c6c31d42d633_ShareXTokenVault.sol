pragma solidity ^0.4.18;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


//Announcement of an interface for recipient approving
interface tokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)public; 
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ShareXERC20 is Ownable{
	
	//===================public variables definition start==================
    string public name;															//Name of your Token
    string public symbol;														//Symbol of your Token
    uint8 public decimals;														//Decimals of your Token
    uint256 public totalSupply;													//Maximum amount of Token supplies

    //define dictionaries of balance
    mapping (address => uint256) public balanceOf;								//Announce the dictionary of account&#39;s balance
    mapping (address => mapping (address => uint256)) public allowance;			//Announce the dictionary of account&#39;s available balance
	//===================public variables definition end==================

	
	//===================events definition start==================    
    event Transfer(address indexed from, address indexed to, uint256 value);	//Event on blockchain which notify client
	//===================events definition end==================
	
	
	//===================Contract Initialization Sequence Definition start===================
    function ShareXERC20 () public {
		decimals=8;															//Assignment of Token&#39;s decimals
		totalSupply = 1000000000 * 10 ** uint256(decimals);  				//Assignment of Token&#39;s total supply with decimals
        balanceOf[owner] = totalSupply;                						//Assignment of Token&#39;s creator initial tokens
        name = "ShareX";                                   					//Set the name of Token
        symbol = "SEXC";                               						//Set the symbol of  Token
        
    }
	//===================Contract Initialization Sequence definition end===================
	
	//===================Contract behavior & funtions definition start===================
	
	/*
	*	Funtion: Transfer funtions
	*	Type:Internal
	*	Parameters:
			@_from:	address of sender&#39;s account
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/
    function _transfer(address _from, address _to, uint _value) internal {
		//Fault-tolerant processing
		require(_to != 0x0);						//
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        //Execute transaction
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
		
		//Verify transaction
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }
	
	
	/*
	*	Funtion: Transfer tokens
	*	Type:Public
	*	Parameters:
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/
    function transfer(address _to, uint256 _value) public returns (bool success) {
		
        _transfer(msg.sender, _to, _value);
        return true;
    }	
	
	/*
	*	Funtion: Transfer tokens from other address
	*	Type:Public
	*	Parameters:
			@_from:	address of sender&#39;s account
			@_to:	address of recipient&#39;s account
			@_value:transaction amount
	*/

    function transferFrom(address _from, address _to, uint256 _value) public 
	returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     					//Allowance verification
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
	/*
	*	Funtion: Approve usable amount for an account
	*	Type:Public
	*	Parameters:
			@_spender:	address of spender&#39;s account
			@_value:	approve amount
	*/
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
        }

	/*
	*	Funtion: Approve usable amount for other address and then notify the contract
	*	Type:Public
	*	Parameters:
			@_spender:	address of other account
			@_value:	approve amount
			@_extraData:additional information to send to the approved contract
	*/
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public 
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /*
	*	Funtion: Transfer owner&#39;s authority and account balance
	*	Type:Public and onlyOwner
	*	Parameters:
			@newOwner:	address of newOwner
	*/
    function transferOwnershipWithBalance(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		    _transfer(owner,newOwner,balanceOf[owner]);
		    owner = newOwner;
		}
	}
   //===================Contract behavior & funtions definition end===================
}



contract ShareXTokenVault is Ownable {
    using SafeMath for uint256;

    //Wallet Addresses for allocation
    address public teamReserveWallet = 0x78e27c0347fa3afcc31e160b0fbc6f90186fd2b6;
    address public firstReserveWallet = 0xef2ab7226c1a3d274caad2dec6d79a4db5d5799e;
    
    address public CEO = 0x2Fc7607CE5f6c36979CC63aFcDA6D62Df656e4aE;
    address public COO = 0x08465f80A28E095DEE4BE0692AC1bA1A2E3EEeE9;
    address public CTO = 0xB22E5Ac6C3a9427C48295806a34f7a3C0FD21443;
    address public CMO = 0xf34C06cd907AD036b75cee40755b6937176f24c3;
    address public CPO = 0xa33da3654d5fdaBC4Dd49fB4e6c81C58D28aA74a;
    address public CEO_TEAM =0xc0e3294E567e965C3Ff3687015fCf88eD3CCC9EA;
    address public AWD = 0xc0e3294E567e965C3Ff3687015fCf88eD3CCC9EA;
    
    uint256 public CEO_SHARE = 45;
    uint256 public COO_SHARE = 12;
    uint256 public CTO_SHARE = 9;
    uint256 public CMO_SHARE = 9;
    uint256 public CPO_SHARE = 9;
    uint256 public CEO_TEAM_SHARE =6;
    uint256 public AWD_SHARE =10;
    
    uint256 public DIV = 100;

    //Token Allocations
    uint256 public teamReserveAllocation = 16 * (10 ** 7) * (10 ** 8);
    uint256 public firstReserveAllocation = 4 * (10 ** 7) * (10 ** 8);
    

    //Total Token Allocations
    uint256 public totalAllocation = 2 * (10 ** 8) * (10 ** 8);

    uint256 public teamVestingStages = 8;
    //first unlocked Token 
    uint256 public firstTime =1531584000;  //2018-07-15 00:00:00
    
    //teamTimeLock
    uint256 public teamTimeLock = 2 * 365 days;
    //team unlocked over
    uint256 public secondTime =firstTime.add(teamTimeLock);


    /** Reserve allocations */
    mapping(address => uint256) public allocations;

    /** When timeLocks are over (UNIX Timestamp)  */  
    mapping(address => uint256) public timeLocks;

    /** How many tokens each reserve wallet has claimed */
    mapping(address => uint256) public claimed;

    /** When this vault was locked (UNIX Timestamp)*/
    uint256 public lockedAt = 0;

    ShareXERC20 public token;

    /** Allocated reserve tokens */
    event Allocated(address wallet, uint256 value);

    /** Distributed reserved tokens */
    event Distributed(address wallet, uint256 value);

    /** Tokens have been locked */
    event Locked(uint256 lockTime);

    //Any of the two reserve wallets
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only ShareX team reserve wallet
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only first and second token reserve wallets
    modifier onlyTokenReserve {
        require(msg.sender == firstReserveWallet );
        require(allocations[msg.sender] > 0);
        _;
    }

    //Has not been locked yet
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

    //Token allocations have not been set
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[firstReserveWallet] == 0);
        _;
    }

    function ShareXTokenVault(ERC20 _token) public {

        owner = msg.sender;
        token = ShareXERC20(_token);
        
    }

    function allocate() public notLocked notAllocated onlyOwner {

        //Makes sure Token Contract has the exact number of tokens
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[firstReserveWallet] = firstReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(firstReserveWallet, firstReserveAllocation);

        lock();
    }

    //Lock the vault for the two wallets
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

        // timeLocks[teamReserveWallet] = lockedAt.add(teamTimeLock);
        timeLocks[teamReserveWallet] = secondTime;
        
        // timeLocks[firstReserveWallet] = lockedAt.add(firstReserveTimeLock);
        timeLocks[firstReserveWallet] = firstTime;

        Locked(lockedAt);
    }

    //In the case locking failed, then allow the owner to reclaim the tokens on the contract.
    //Recover Tokens in case incorrect amount was sent to contract.
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

        // Transfer all tokens on this contract back to the owner
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

    // Total number of tokens currently in the vault
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

    // Number of tokens that are still locked
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

    //Claim tokens for first reserve wallets
    function claimTokenReserve() onlyTokenReserve locked public {

        address reserveWallet = msg.sender;

        // Can&#39;t claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]);

        // Must Only claim once
        require(claimed[reserveWallet] == 0);

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(CEO,amount.mul(CEO_SHARE).div(DIV)));
        require(token.transfer(COO,amount.mul(COO_SHARE).div(DIV)));
        require(token.transfer(CTO,amount.mul(CTO_SHARE).div(DIV)));
        require(token.transfer(CMO,amount.mul(CMO_SHARE).div(DIV)));
        require(token.transfer(CPO,amount.mul(CPO_SHARE).div(DIV)));
        require(token.transfer(CEO_TEAM,amount.mul(CEO_TEAM_SHARE).div(DIV)));
        require(token.transfer(AWD,amount.mul(AWD_SHARE).div(DIV)));

        Distributed(CEO, amount.mul(CEO_SHARE).div(DIV));
        Distributed(COO, amount.mul(COO_SHARE).div(DIV));
        Distributed(CTO, amount.mul(CTO_SHARE).div(DIV));
        Distributed(CMO, amount.mul(CMO_SHARE).div(DIV));
        Distributed(CPO, amount.mul(CPO_SHARE).div(DIV));
        Distributed(CEO_TEAM, amount.mul(CEO_TEAM_SHARE).div(DIV));
        Distributed(AWD, amount.mul(AWD_SHARE).div(DIV));
    }

    //Claim tokens for ShareX team reserve wallet
    function claimTeamReserve() onlyTeamReserve locked public {

        uint256 vestingStage = teamVestingStage();

        //Amount of tokens the team should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(allocations[teamReserveWallet]).div(teamVestingStages);

        require(totalUnlocked <= allocations[teamReserveWallet]);

        //Previously claimed tokens must be less than what is unlocked
        require(claimed[teamReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        claimed[teamReserveWallet] = totalUnlocked;

        // require(token.transfer(teamReserveWallet, payment));
        
        require(token.transfer(AWD,payment));
        
        Distributed(AWD, payment);
    }
  
    //Current Vesting stage for ShareX team 
    function teamVestingStage() public view onlyTeamReserve returns(uint256){
        
        // Every 3 months
        uint256 vestingMonths = teamTimeLock.div(teamVestingStages); 

        // uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingMonths);
        uint256 stage  = (block.timestamp).sub(firstTime).div(vestingMonths);

        //Ensures team vesting stage doesn&#39;t go past teamVestingStages
        if(stage > teamVestingStages){
            stage = teamVestingStages;
        }

        return stage;

    }

    // Checks if msg.sender can collect tokens
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}