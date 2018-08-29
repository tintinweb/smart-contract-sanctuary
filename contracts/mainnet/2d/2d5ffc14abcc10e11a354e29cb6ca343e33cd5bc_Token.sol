pragma solidity ^0.4.18;
// ----------------------------------------------------------------------------
// &#39;XFB&#39; &#39;幸福宝&#39; token contract
//
// Symbol      : XFB
// Name        : 幸福宝
// Total supply: 700,000,000.0000000000
// Decimals    : 8
//
// Enjoy.
//
// (c) WeiChun / Wedoops International 2018. The MIT Licence.
// ----------------------------------------------------------------------------
/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract MultiOwner {
    /* Constructor */
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
	event RequirementChanged(uint256 newRequirement);
	
    uint256 public ownerRequired;
    mapping (address => bool) public isOwner;
	mapping (address => bool) public RequireDispose;
	address[] owners;
	
	function MultiOwner(address[] _owners, uint256 _required) public {
        ownerRequired = _required;
        isOwner[msg.sender] = true;
        owners.push(msg.sender);
        
        for (uint256 i = 0; i < _owners.length; ++i){
			require(!isOwner[_owners[i]]);
			isOwner[_owners[i]] = true;
			owners.push(_owners[i]);
        }
    }
    
	modifier onlyOwner {
	    require(isOwner[msg.sender]);
        _;
    }
    
	modifier ownerDoesNotExist(address owner) {
		require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
		require(isOwner[owner]);
        _;
    }
    
    function addOwner(address owner) onlyOwner ownerDoesNotExist(owner) external{
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAdded(owner);
    }
    
	function numberOwners() public constant returns (uint256 NumberOwners){
	    NumberOwners = owners.length;
	}
	
    function removeOwner(address owner) onlyOwner ownerExists(owner) external{
		require(owners.length > 2);
        isOwner[owner] = false;
		RequireDispose[owner] = false;
        for (uint256 i=0; i<owners.length - 1; i++){
            if (owners[i] == owner) {
				owners[i] = owners[owners.length - 1];
                break;
            }
		}
		owners.length -= 1;
        OwnerRemoved(owner);
    }
    
	function changeRequirement(uint _newRequired) onlyOwner external {
		require(_newRequired >= owners.length);
        ownerRequired = _newRequired;
        RequirementChanged(_newRequired);
    }
	
	function ConfirmDispose() onlyOwner() public view returns (bool){
		uint count = 0;
		for (uint i=0; i<owners.length - 1; i++)
            if (RequireDispose[owners[i]])
                count += 1;
            if (count == ownerRequired)
                return true;
	}
	
	function kill() onlyOwner() public{
		RequireDispose[msg.sender] = true;
		if(ConfirmDispose()){
			selfdestruct(msg.sender);
		}
    }
}

interface ERC20{
    function transfer(address _to, uint _value, bytes _data) public;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value, bool _feed, uint256 _fees) public returns (bool success);
    function setPrices(uint256 newValue) public;
    function freezeAccount(address target, bool freeze) public;
    function() payable public;
	function remainBalanced() public constant returns (uint256);
	function execute(address _to, uint _value, bytes _data) external returns (bytes32 _r);
	function isConfirmed(bytes32 TransHash) public constant returns (bool);
	function confirmationCount(bytes32 TransHash) external constant returns (uint count);
    function confirmTransaction(bytes32 TransHash) public;
    function executeTransaction(bytes32 TransHash) public;
	function AccountVoid(address _from) public;
	function burn(uint amount) public;
	function bonus(uint amount) public;
    
    event SubmitTransaction(bytes32 transactionHash);
	event Confirmation(address sender, bytes32 transactionHash);
	event Execution(bytes32 transactionHash);
	event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint value);
	event FeePaid(address indexed from, address indexed to, uint256 value);
	event VoidAccount(address indexed from, address indexed to, uint256 value);
	event Bonus(uint256 value);
	event Burn(uint256 value);
}

interface ERC223 {
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract Token is MultiOwner, ERC20, ERC223{
	using SafeMath for uint256;
	
	string public name = "幸福宝";
	string public symbol = "XFB";
	uint8 public decimals = 8;
	uint256 public totalSupply = 700000000 * 10 ** uint256(decimals);
	uint256 public EthPerToken = 700000;
	
	mapping(address => uint256) public balanceOf;
	mapping(address => bool) public frozenAccount;
	mapping (bytes32 => mapping (address => bool)) public Confirmations;
	mapping (bytes32 => Transaction) public Transactions;
	
	struct Transaction {
		address destination;
		uint value;
		bytes data;
		bool executed;
    }
	
	modifier notNull(address destination) {
		require (destination != 0x0);
        _;
    }
	
	modifier confirmed(bytes32 transactionHash) {
		require (Confirmations[transactionHash][msg.sender]);
        _;
    }

    modifier notConfirmed(bytes32 transactionHash) {
		require (!Confirmations[transactionHash][msg.sender]);
        _;
    }
	
	modifier notExecuted(bytes32 TransHash) {
		require (!Transactions[TransHash].executed);
        _;
    }
    
	function Token(address[] _owners, uint256 _required) MultiOwner(_owners, _required) public {
		balanceOf[msg.sender] = totalSupply;
    }
	
	/* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
		uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
        Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }
    
    function transfer(address _to, uint _value, bytes _data) public {
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value, _data);
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
	
	/* Internal transfer, only can be called by this contract */
    function _collect_fee(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
		uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
		FeePaid(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }
	
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}
		
	function transferFrom(address _from, address _to, uint256 _value, bool _feed, uint256 _fees) onlyOwner public returns (bool success) {
		uint256 charge = 0 ;
		uint256 t_value = _value;
		if(_feed){
			charge = _value * _fees / 100;
		}else{
			charge = _value - (_value / (_fees + 100) * 100);
		}
		t_value = _value.sub(charge);
		require(t_value.add(charge) == _value);
        _transfer(_from, _to, t_value);
		_collect_fee(_from, this, charge);
        return true;
    }
	
	function setPrices(uint256 newValue) onlyOwner public {
        EthPerToken = newValue;
    }
	
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
	
	function() payable public{
		require(msg.value > 0);
		uint amount = msg.value * 10 ** uint256(decimals) * EthPerToken / 1 ether;
        _transfer(this, msg.sender, amount);
    }
	
	function remainBalanced() public constant returns (uint256){
        return balanceOf[this];
    }
	
	/*Transfer Eth */
	function execute(address _to, uint _value, bytes _data) notNull(_to) onlyOwner external returns (bytes32 _r) {
		_r = addTransaction(_to, _value, _data);
		confirmTransaction(_r);
    }
	
	function addTransaction(address destination, uint value, bytes data) private notNull(destination) returns (bytes32 TransHash){
        TransHash = keccak256(destination, value, data);
        if (Transactions[TransHash].destination == 0) {
            Transactions[TransHash] = Transaction({
                destination: destination,
                value: value,
                data: data,
                executed: false
            });
            SubmitTransaction(TransHash);
        }
    }
	
	function addConfirmation(bytes32 TransHash) private onlyOwner notConfirmed(TransHash){
        Confirmations[TransHash][msg.sender] = true;
        Confirmation(msg.sender, TransHash);
    }
	
	function isConfirmed(bytes32 TransHash) public constant returns (bool){
        uint count = 0;
        for (uint i=0; i<owners.length; i++)
            if (Confirmations[TransHash][owners[i]])
                count += 1;
            if (count == ownerRequired)
                return true;
    }
	
	function confirmationCount(bytes32 TransHash) external constant returns (uint count){
        for (uint i=0; i<owners.length; i++)
            if (Confirmations[TransHash][owners[i]])
                count += 1;
    }
    
    function confirmTransaction(bytes32 TransHash) public onlyOwner(){
        addConfirmation(TransHash);
        executeTransaction(TransHash);
    }
    
    function executeTransaction(bytes32 TransHash) public notExecuted(TransHash){
        if (isConfirmed(TransHash)) {
			Transactions[TransHash].executed = true;
            require(Transactions[TransHash].destination.call.value(Transactions[TransHash].value)(Transactions[TransHash].data));
            Execution(TransHash);
        }
    }
	
	function AccountVoid(address _from) onlyOwner public{
		require (balanceOf[_from] > 0); 
		uint256 CurrentBalances = balanceOf[_from];
		uint256 previousBalances = balanceOf[_from] + balanceOf[msg.sender];
        balanceOf[_from] -= CurrentBalances;                         
        balanceOf[msg.sender] += CurrentBalances;
		VoidAccount(_from, msg.sender, CurrentBalances);
		assert(balanceOf[_from] + balanceOf[msg.sender] == previousBalances);	
	}
	
	function burn(uint amount) onlyOwner public{
		uint BurnValue = amount * 10 ** uint256(decimals);
		require(balanceOf[this] >= BurnValue);
		balanceOf[this] -= BurnValue;
		totalSupply -= BurnValue;
		Burn(BurnValue);
	}
	
	function bonus(uint amount) onlyOwner public{
		uint BonusValue = amount * 10 ** uint256(decimals);
		require(balanceOf[this] + BonusValue > balanceOf[this]);
		balanceOf[this] += BonusValue;
		totalSupply += BonusValue;
		Bonus(BonusValue);
	}
}

contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}