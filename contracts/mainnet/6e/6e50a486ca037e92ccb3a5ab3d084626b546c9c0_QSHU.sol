pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
	function mul(uint256 x, uint256 y) internal pure returns (uint256) {
		if (x == 0) {
			return 0;
		}
		uint256 z = x * y;
		assert(z / x == y);
		return z;
	}
	
	function div(uint256 x, uint256 y) internal pure returns (uint256) {
	    // assert(y > 0);//Solidity automatically throws when dividing by 0 
	    uint256 z = x / y;
	    // assert(x == y * z + x % y); // There is no case in which this doesn`t hold
	    return z;
	}
	
	function sub(uint256 x, uint256 y) internal pure returns (uint256) {
	    assert(y <= x);
	    return x - y;
	}
	
	function add(uint256 x, uint256 y) internal pure returns (uint256) {
	    uint256 z = x + y;
	    assert(z >= x);
	    return z;
	}
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization
 *      control function,this simplifies the implementation of "user permissions".
 */
 
 contract Ownable {
     address public owner;
     
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
     /**
      * 
      * @dev The Ownable constructor sets the original &#39;owner&#39; of the contract to the
      *         sender account.
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
      require(newOwner !=address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
  }
}

/**
 * @title ContractReceiver
 * @dev Receiver for ERC223 tokens
 */
 
contract ContractReceiver {
    
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) <<16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
        
        /*
         *tkn variable is analogue of msg variable of Ether transaction
         *tkn.sender is person who initiated this token transaction (analogue of msg.sender)
         *tkn.value the number of tokens that were sent (analogue of msg.value)
         *tkn.data is data of token transaction (analogue of msg.data)
         *tkn.sig is 4 bytes signature of function
         *if data of token transaction is a function execution
         */
         
    }
}

contract ERC223 {
    uint public totalSupply;
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);
    function balanceOf(address who) public view returns (uint);

    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/**
 * Wishing for circulation of QSHUCOIN!
 * I wish for prosperity for a long time!
 * Flapping from Kyusyu to the world!
 * We will work with integrity and sincerity!
 * ARIGATOH!
 */

contract QSHU is ERC223, Ownable {
    using SafeMath for uint256;
    
    string public name = "QSHUCOIN";
    string public symbol = "QSHU";
    uint8 public decimals = 8;
    uint256 public initialSupply = 50e9 * 1e8;
    uint256 public totalSupply;
    uint256 public distributeAmount = 0;
    bool public mintingFinished = false;
    
    mapping (address => uint) balances;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;
    
    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
    function QSHU() public {
        totalSupply = initialSupply;
        balances[msg.sender] = totalSupply;
    }
    
    function name() public view returns (string _name) {
        return name;
    }
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    modifier onlyPayloadSize(uint256 size){
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);
        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
            balances[_to] = SafeMath.add(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
        }
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.add(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.add(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

/**
 * @dev Prevent targets from sending or receiving tokens
 * @param targets Addresses to be frozen
 * @param isFrozen either to freeze it or not
 */

    function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
        require(targets.length > 0);

        for (uint q = 0; q < targets.length; q++) {
            require(targets[q] != 0x0);
            frozenAccount[targets[q]] = isFrozen;
            emit FrozenFunds(targets[q], isFrozen);
        }
    }
    
/**
 * @dev Prevent targets from sending or receiving tokens by setting Unix times 
 * @param targets Addresses to be locked funds 
 * @param unixTimes Unix times when locking up will be finished 
 */
 
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0 
            && targets.length == unixTimes.length);
            
        for(uint q = 0; q < targets.length; q++){
            require(unlockUnixTime[targets[q]] < unixTimes[q]);
            unlockUnixTime[targets[q]] = unixTimes[q];
            emit LockedFunds(targets[q], unixTimes[q]);
        }
    }

/**
 * @dev Burns a specific amount of tokens.
 * @param _from The address that will burn the tokens.
 * @param _unitAmount The amount of token to be burned.
 */
 
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
            && balanceOf(_from) >= _unitAmount);
        
        balances[_from] = SafeMath.sub(balances[_from], _unitAmount);
        totalSupply = SafeMath.sub(totalSupply, _unitAmount);
        emit Burn(_from, _unitAmount);
    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
/**
 * @dev Function to mint tokens
 * @param _to The address that will receive the minted tokens.
 * @param _unitAmount The amount of tokens to mint.
 */
 
    function mint (address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);
        
        totalSupply = SafeMath.add(totalSupply, _unitAmount);
        balances[_to] = SafeMath.add(balances[_to], _unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }


/**
 * dev Function to stop minting new tokens.
 */
 
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
    
/**
 * @dev Function to distribute tokens to the list of addresses by the provided amount
 */
 

    function distributeTokens(address[] addresses, uint256 amount) public returns (bool) {
        require(amount > 0
            && addresses.length > 0
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);
        
        amount = SafeMath.mul(amount,1e8);
        uint256 totalAmount = SafeMath.mul(amount, addresses.length);
        require(balances[msg.sender] >= totalAmount);
        
        for (uint q = 0; q < addresses.length; q++) {
            require(addresses[q] != 0x0
                && frozenAccount[addresses[q]] == false
                && now > unlockUnixTime[addresses[q]]);
            
            balances[addresses[q]] = SafeMath.add(balances[addresses[q]], amount);
            emit Transfer(msg.sender, addresses[q], amount);
        }
        balances[msg.sender] = SafeMath.sub(balances[msg.sender],totalAmount);
        return true;
    }
    
/**
 * @dev Function to collect tokens from the list of addresses
 */

    function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length);
        
        uint256 totalAmount = 0;
        
        for (uint q = 0; q < addresses.length; q++) {
            require(amounts[q] > 0
                    && addresses[q] != 0x0
                    && frozenAccount[addresses[q]] == false
                    && now > unlockUnixTime[addresses[q]]);
            
            amounts[q] = SafeMath.mul(amounts[q], 1e8);
            require(balances[addresses[q]] >= amounts[q]);
            balances[addresses[q]] = SafeMath.sub(balances[addresses[q]], amounts[q]);
            totalAmount = SafeMath.add(totalAmount, amounts[q]);
            emit Transfer(addresses[q], msg.sender, amounts[q]);
        }
        balances[msg.sender] = SafeMath.add(balances[msg.sender], totalAmount);
        return true;
    }
    function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
        distributeAmount = _unitAmount;
    }
    
/**
 * @dev Function to distribute tokens to the msg.sender automatically
 * If distributeAmount is 0 , this function doesn&#39;t work&#39;
 */
 
    function autoDistribute() payable public {
        require(distributeAmount > 0
                && balanceOf(owner) >= distributeAmount
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);
        if (msg.value > 0) owner.transfer(msg.value);
        
        balances[owner] = SafeMath.sub(balances[owner], distributeAmount);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], distributeAmount);
        emit Transfer(owner, msg.sender, distributeAmount);
    }
    
/**
 * @dev token fallback function
 */
 
    function() payable public {
        autoDistribute();
    }
}

/**
 * My thought is strong!
 * The reconstruction of Kyusyu is the power of everyone!
 */