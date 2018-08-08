pragma solidity ^0.4.18;

interface ERC223
{
	function transfer(address _to, uint _value, bytes _data) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed data);
}

interface ERC20
{
	function transferFrom(address _from, address _to, uint _value) public returns(bool);
	function approve(address _spender, uint _value) public returns (bool);
	function allowance(address _owner, address _spender) public constant returns(uint);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract ERC223ReceivingContract
{
	function tokenFallBack(address _from, uint _value, bytes _data)public;	 
}

contract Token
{
	string internal _symbol;
	string internal _name;
	uint8 internal _decimals;	
    uint internal _totalSupply;
   	mapping(address =>uint) internal _balanceOf;
	mapping(address => mapping(address => uint)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public{
	    _symbol = symbol;
		_name = name;
		_decimals = decimals;
		_totalSupply = totalSupply;
    }

	function name() public constant returns (string){
        	return _name;    
	}

	function symbol() public constant returns (string){
        	return _symbol;    
	}

	function decimals() public constant returns (uint8){
		return _decimals;
	}

	function totalSupply() public constant returns (uint){
        	return _totalSupply;
	}
            	
	event Transfer(address indexed _from, address indexed _to, uint _value);	
}


contract Multiownable {
    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address insideOnlyManyOwners;
    
    // Reverse lookup tables for owners and allOperations
    mapping(address => uint) ownersIndices; // Starts from 1
    mapping(bytes32 => uint) allOperationsIndicies;
    
    // Owners voting mask per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;
    event OwnershipTransferred(address[] previousOwners, address[] newOwners);
    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public constant returns(uint) {
        return allOperations.length;
    }

    // MODIFIERS

    /**
    * @dev Allows to perform method by any of the owners
    */
    modifier onlyAnyOwner {
        require(isOwner(msg.sender));
        _;
    }

    /**
    * @dev Allows to perform method only after all owners call it with the same arguments
    */
    modifier onlyManyOwners {
        if (insideOnlyManyOwners == msg.sender) {
            _;
            return;
        }
        require(isOwner(msg.sender));

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        bytes32 operation = keccak256(msg.data);
        
        if (votesMaskByOperation[operation] == 0) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
        }
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0);
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        votesCountByOperation[operation] += 1;

        // If all owners confirm same operation
        if (votesCountByOperation[operation] == howManyOwnersDecide) {
            deleteOperation(operation);
            insideOnlyManyOwners = msg.sender;
            _;
            insideOnlyManyOwners = address(0);
        }
    }

    // CONSTRUCTOR

    function Multiownable() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

    // INTERNAL METHODS

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (allOperations.length > 1) {
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;
        
        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

    // PUBLIC METHODS

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    */
    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    * @param newHowManyOwnersDecide defines how many owners can decide
    */
    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0);
        require(newOwners.length <= 256);
        require(newHowManyOwnersDecide > 0);
        require(newHowManyOwnersDecide <= newOwners.length);
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0));
        }

        OwnershipTransferred(owners, newOwners);

        // Reset owners array and index reverse lookup table
        for (i = 0; i < owners.length; i++) {
            delete ownersIndices[owners[i]];
        }
        for (i = 0; i < newOwners.length; i++) {
            require(ownersIndices[newOwners[i]] == 0);
            ownersIndices[newOwners[i]] = i + 1;
        }
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;

        // Discard all pendign operations
        for (i = 0; i < allOperations.length; i++) {
            delete votesMaskByOperation[allOperations[i]];
            delete votesCountByOperation[allOperations[i]];
            delete allOperationsIndicies[allOperations[i]];
        }
        allOperations.length = 0;
    }
}

contract MyToken is Token("TLT","Talent Coin",18,50000000000000000000000000),ERC20,ERC223,Multiownable
{    		
	uint256 internal sellPrice;
	uint256 internal buyPrice;
    function MyToken() public payable
    {
    	_balanceOf[msg.sender]=_totalSupply;       		
    }

    function totalSupply() public constant returns (uint){
    	return _totalSupply;  
	}
	
    function balanceOf(address _addr)public constant returns (uint){
      	return _balanceOf[_addr];
	}

	function transfer(address _to, uint _value)public onlyManyOwners returns (bool){
    	require(_value>0 && _value <= balanceOf(msg.sender));
    	if(!isContract(_to))
    	{
    		_balanceOf[msg.sender]-= _value;
        	_balanceOf[_to]+=_value;
		    Transfer(msg.sender, _to, _value); 
 			return true;
	    }
    	return false;
	}

	function transfer(address _to, uint _value, bytes _data)public returns(bool)
	{
	    require(_value>0 && _value <= balanceOf(msg.sender));
		if(isContract(_to))
		{
			_balanceOf[msg.sender]-= _value;
	       	_balanceOf[_to]+=_value;
			ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
			_contract.tokenFallBack(msg.sender,_value,_data);
			Transfer(msg.sender, _to, _value, _data); 
    		return true;
		}
		return false;
	}

	function isContract(address _addr) internal view returns(bool){
		uint codeLength;
		assembly
		{
		    codeLength := extcodesize(_addr)
	    }
		return codeLength > 0;
	}	
    
	function transferFrom(address _from, address _to, uint _value)public onlyManyOwners returns(bool){
    	require(_allowances[_from][msg.sender] > 0 && _value > 0 && _allowances[_from][msg.sender] >= _value && _balanceOf[_from] >= _value);
    	{
			_balanceOf[_from]-=_value;
    		_balanceOf[_to]+=_value;
			_allowances[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);            
			return true;
    	}
    	return false;
   }

	function approve(address _spender, uint _value) public returns (bool)
	{
    	_allowances[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);	
    	return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns(uint)
    {
    	return _allowances[_owner][_spender];
    }
    
}