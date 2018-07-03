pragma solidity ^0.4.24;

library SafeMath {
  
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
}

contract ERC20 {
  uint256 public totalSupply;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OnlyOwner {
  address public owner;
  
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
      owner = msg.sender;
      
  }
  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
    
    
   
}

contract StandardToken is ERC20,OnlyOwner{
	using SafeMath for uint256;
	string private secretKey;
	
  	mapping(address => uint256) balances;
  	mapping (address => mapping (address => uint256)) allowed;
  	bool public stopped = false;

  	event Minted(address receiver, uint256 amount);
  	
  	 modifier validAddress{
        require(0x0 != msg.sender);
        _;
    }
    
    modifier isRunning {
        assert (!stopped);
        _;
    }
  	
   function transfer(address _to, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_value <= balances[msg.sender]);
	    _transfer(msg.sender,_to,_value);
	    emit Transfer(msg.sender, _to, _value);
        return true;
    }
  	

  	function _transfer(address _from, address _to, uint256 _value) internal returns (bool success){

	    //subtract tokens from the sender on transfer
	    balances[_from] = balances[_from].safeSub(_value);
	    //add tokens to the receiver on reception
	    balances[_to] = balances[_to].safeAdd(_value);
	    return true;
  	}

	function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress public returns (bool) {
    	uint256 _allowance = allowed[_from][msg.sender];
    	//value must be less than allowed value
    	require(_value <= _allowance);
    	//balance of sender + token value transferred by sender must be greater than balance of sender
    	require(balances[_to] + _value > balances[_to]);
    	//call transfer function
    	_transfer(_from,_to,_value);
    	//subtract the amount allowed to the sender 
     	allowed[_from][msg.sender] = _allowance.safeSub(_value);
     	//trigger Transfer event
    	emit Transfer(_from, _to, _value);
    	return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint balance) {
    	return balances[_owner];
  	}

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

}

contract AdvanceToken is StandardToken{
    struct List{
        bool isFresh;
        uint256 value;
    }
    /* mapping List structure to user ethereum address */
    mapping(address => List) lists;
    /* storing all mapped address to address array */
    address[] public addAccts;
    
    function addAirdropList(address _user, uint256 _value) isOwner validAddress public returns(bool success) {
        List memory list = lists[_user];
        list.isFresh = true;
        list.value = _value;
        addAccts.push(_user) -1;
        return true;
    }
    
    function getAirdropList() view public returns (address[]) {
        return addAccts;
    }

    function getAirdropList(address lis) view public returns (bool,uint256) {
        return (lists[lis].isFresh, lists[lis].value);
    }
    
    function isEligibleForAirdrop(address _user) view public returns (bool success){
        return lists[_user].isFresh;
    }
    
    function getAirdropTokens() public returns(bool success){
        require(isEligibleForAirdrop(msg.sender));
       _transfer(owner,msg.sender,lists[msg.sender].value);
       emit Transfer(owner,msg.sender,lists[msg.sender].value);
       return true;
   }
    
}

contract XRT is AdvanceToken{
	uint8 public constant decimals = 18;
	uint256 private billion = 10*10**8;
    uint256 private multiplier = billion*10**18;
  	string public constant name = &quot;XRT Token&quot;;
  	string public constant symbol = &quot;XRT&quot;;
  	string public version = &quot;X1.0&quot;;
  	uint256 private maxSupply = multiplier;
    uint256 public totalSupply = (50*maxSupply)/100;
  	
  	constructor() public{
  	    balances[msg.sender] = totalSupply;
  	}
  	
  	function maximumToken() isOwner internal view returns (uint){
  	    return maxSupply;
  	}
  	
  	event Mint(address indexed to, uint256 amount);
  	event MintFinished();
    
 	bool public mintingFinished = false;


	modifier canMint() {
		require(!mintingFinished);
		require(totalSupply <= maxSupply);
		_;
	}

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
	function mint(address _to, uint256 _amount) isOwner canMint public returns (bool) {
	    uint256 newAmount = _amount.safeMul(multiplier.safeDiv(100));
	    require(totalSupply <= maxSupply.safeSub(newAmount));
	    totalSupply = totalSupply.safeAdd(newAmount);
		balances[_to] = balances[_to].safeAdd(newAmount);
		emit Mint(_to, newAmount);
		emit Transfer(address(0), _to, newAmount);
		return true;
	}

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  	function finishMinting() isOwner canMint public returns (bool) {
    	mintingFinished = true;
    	emit MintFinished();
    	return true;
  	}
  	function stop() isOwner public {
        stopped = true;
    }

    function start() isOwner public {
        stopped = false;
    }
  	
  	
}