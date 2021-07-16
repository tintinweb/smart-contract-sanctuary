//SourceUnit: Trumb.sol

/**
 * TRUMB
*/

pragma solidity ^0.5.4;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) pure internal {
    if (!assertion) {
      revert();
    }
  }
}
contract TRUMB is SafeMath{
    string public name = "TRUMB";
    string public symbol = "TUB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10**27;
	address payable public owner;
	uint256 public Trump;
	uint256 public Joe;
	uint256 public candidateCount = 2;
	uint256 public voteTotal;
	uint256 public rate = 10**7;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => mapping(uint256 => uint256)) public voteOf;
	mapping (uint256 => uint256) public candidateVotes;
	mapping (uint256 => string) public candidateName;
	mapping (bytes32 => uint256) public condidateNameBytes32ToId;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Vote(address indexed from, uint256 indexed id, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unvote(address indexed from, uint256 indexed id, uint256 value);
    
    event Create(string indexed candidate);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;         
        candidateName[0] = "Trump";
        candidateName[1] = "Joe";
        condidateNameBytes32ToId[stringToBytes32("Trump")] = 0;
        condidateNameBytes32ToId[stringToBytes32("Joe")] = 1;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (_to == address(0x0)) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(); 
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		if (_value <= 0) revert(); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0x0)) revert();                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(); 
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success)  {
        if (balanceOf[msg.sender] < _value) revert();            // Check if the sender has enough
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function vote(uint256 _value, uint256 id) public returns (bool success) {
	    require(id < candidateCount, "invalid candidate");
        if (balanceOf[msg.sender] < _value) revert();            // Check if the sender has enough
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        voteOf[msg.sender][id]= SafeMath.safeAdd(voteOf[msg.sender][id], _value);                   // Updates totalSupply
        if (id == 0) {
            Trump = SafeMath.safeAdd(Trump, _value);
            candidateVotes[0] = SafeMath.safeAdd(candidateVotes[0], _value);
        }
        else if (id == 1) {
            Joe = SafeMath.safeAdd(Joe, _value);
            candidateVotes[1] = SafeMath.safeAdd(candidateVotes[1], _value);
        }
        else {
            candidateVotes[id] = SafeMath.safeAdd(candidateVotes[id], _value);
        }
        voteTotal = SafeMath.safeAdd(voteTotal, _value);
        emit Vote(msg.sender, id, _value);
        return true;
    }
	
	function unvote(uint256 _value, uint256 id) public returns (bool success) {
	    require(id < candidateCount, "invalid candidate");
        if (voteOf[msg.sender][id] < _value) revert();            // Check if the sender has enough
		if (_value <= 0) revert(); 
        voteOf[msg.sender][id] = SafeMath.safeSub(voteOf[msg.sender][id], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
		if (id == 0) {
            Trump = SafeMath.safeSub(Trump, _value);
            candidateVotes[0] = SafeMath.safeSub(candidateVotes[0], _value);
        }
        else if (id == 1) {
            Joe = SafeMath.safeSub(Joe, _value);
            candidateVotes[1] = SafeMath.safeSub(candidateVotes[1], _value);
        }
        else {
            candidateVotes[id] = SafeMath.safeSub(candidateVotes[id], _value);
        }
        voteTotal = SafeMath.safeSub(voteTotal, _value);
        emit Unvote(msg.sender, id,  _value);
        return true;
    }
    
    function createCandidate(string  memory _cname) public returns(uint256 id) {
        bytes32 candidateBytes = stringToBytes32(_cname);
        require(condidateNameBytes32ToId[candidateBytes] == 0, "candidate already exist");
        candidateName[candidateCount] = _cname;
        candidateVotes[candidateCount] = 0;
        condidateNameBytes32ToId[candidateBytes] = candidateCount;
        id = candidateCount;
        candidateCount ++;
        emit Create(_cname);
        return id;
    }
    
    function getCandidateNameByString(string memory _name) public view returns(uint256) {
        return condidateNameBytes32ToId[stringToBytes32(_name)];
    }
    
    function stringToBytes32(string memory _name) public pure returns(bytes32 candidateBytes) {
        bytes memory candidateMem = bytes(_name);
        if (candidateMem.length == 0) {
            return 0x0;
        }
        assembly {
            candidateBytes := mload(add(_name, 32))
        }
    }
	
	// transfer balance to owner
	function withdrawTrx(uint256 amount) public{
		if(msg.sender != owner) revert();
		owner.transfer(amount);
	}
	
	function buyTUM () payable public {
	    uint256 amount = SafeMath.safeDiv(SafeMath.safeMul(msg.value, rate), 10**8);
	    if (balanceOf[owner] < amount) revert(); 
	    if (balanceOf[msg.sender] + amount < balanceOf[msg.sender]) revert();
	    balanceOf[owner] = SafeMath.safeSub(balanceOf[owner], amount);                     // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], amount);  
	}
	
	function setRate(uint256 _rate) payable public {
	    if(msg.sender != owner) revert();
	    rate = _rate;
	}
	
	// can accept TRX
	function() payable external {
    }
}