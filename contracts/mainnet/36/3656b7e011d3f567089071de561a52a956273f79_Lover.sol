pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
          return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
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
}

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner { require(msg.sender == owner); _; }
    event Ownership(address _prevOwner, address _newOwner, uint _timestamp);

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit Ownership(owner, newOwner, now);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint _totalSupply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ERC20Token is ERC20 {
    using SafeMath for uint;
    uint public totalToken;
	bool public frozen;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
	mapping (address => bool) public frozenAccounts;
	
    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
		require(_from != 0x0 && _to != 0x0);
        require(balances[_from] >= _value && _value > 0);
		require(!frozen);
		require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
		assert(balances[_from] + balances[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        return _transfer(msg.sender, _to,  _value) ;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(allowances[_from][msg.sender] >= _value);     
		allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function totalSupply() public view returns (uint) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowances[_owner][_spender];
    }
}

contract Lover is ERC20Token, Owned {
	string public name = "Lover";
    string public symbol = "LOV";
    uint public constant decimals = 18;
	string public note = "(C) Loverchain.com all rights reserved.";
    uint public burnedToken;
	uint public fee;
	mapping (address => bool) public certifiedAccounts;
	mapping (address => string) public keys;
	mapping (address => string) public signatures;
	mapping (address => string) public identities;
	mapping (address => uint) public scores;
	mapping (address => uint) public levels;
    mapping (address => uint) public stars;
    mapping (address => string) public profiles;
	mapping (address => string) public properties;
	mapping (address => string) public rules;
    mapping (address => string) public funds;
	mapping (address => uint) public nonces;
	event Key(address indexed _user, string indexed _key, uint _timestamp);
	event Sign(address indexed _user, string indexed _data, uint _timestamp);
	event Register(address indexed _user, string indexed _identity, address _certifier, uint _timestamp);
	event Rule(address indexed _user, string _rule, address indexed _certifier, uint _timestamp);
	event Fund(address indexed _user, string _fund, address indexed _certifier, uint _timestamp);
	event Save(address indexed _user, uint _score, uint _level, uint _star, address indexed _certifier, uint _nonce, uint _timestamp);
	event Burn(address indexed _from, uint _burntAmount, uint _timestamp);
    event FreezeAccount(address indexed _target, bool _frozen, uint _timestamp);
	event CertifyAccount(address indexed _target, bool _certified, uint _timestamp);

    constructor() public {
		totalToken = 1000000000000000000000000000;
		balances[msg.sender] = totalToken;
		owner = msg.sender;
	    frozen = false;
		fee = 0;
		certifiedAccounts[msg.sender] = true; 
    }

    function burn(uint _burntAmount) public returns (bool success) {
    	require(balances[msg.sender] >= _burntAmount && _burntAmount > 0);
    	balances[msg.sender] = balances[msg.sender].sub(_burntAmount);
    	totalToken = totalToken.sub(_burntAmount);
    	burnedToken = burnedToken.add(_burntAmount);
    	emit Transfer(msg.sender, 0x0, _burntAmount);
    	emit Burn(msg.sender, _burntAmount, now);
    	return true;
	}

    function setKey(string _key) public {
        require(bytes(_key).length > 1);
        keys[msg.sender] = _key;
		emit Key(msg.sender, _key, now);
    }

    function sign(string _data) public {
        require(bytes(_data).length > 1);
        signatures[msg.sender] = _data;
		emit Sign(msg.sender, _data, now);
    }

	function register(address _user, string _identity) public {
		require(bytes(_identity).length > 1);
		require(certifiedAccounts[msg.sender]);
		identities[_user] = _identity;
		emit Register(_user, _identity, msg.sender, now);
    }

    function _save(address _user, uint _score, uint _level, uint _star, string _profile, string _property, address _certifier, uint _nonce, uint _timestamp) internal returns (bool success){
		require(_nonce > nonces[_user]);
		require(!frozen);
		require(!frozenAccounts[_user]); 
	    if(bytes(_profile).length > 1){
			profiles[_user] = _profile;
		}
	    if(bytes(_property).length > 1){
		    properties[_user] = _property;
		}
		levels[_user] = _level;
		scores[_user] = _score;
        stars[_user] = _star;
		nonces[_user] = _nonce;
		emit Save(_user, _score, _level, _star, _certifier, _nonce, _timestamp);
		return true;
    }

    function save(address _user, uint _score, uint _level, uint _star, string _profile, string _property, uint _nonce) public returns (bool success){
        require(certifiedAccounts[msg.sender]);  
		return _save(_user, _score, _level, _star, _profile, _property, msg.sender, _nonce, now);
    }

	function _assign(address _from, address _to, address _certifier) internal returns (bool success){
		require(_from != 0x0 && _to != 0x0);
		require(!frozen);
		require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]); 
		_save(_to, scores[_from], levels[_from], stars[_from], profiles[_from], properties[_from], _certifier, nonces[_from], now);
        profiles[_from] = "";
        properties[_from] = "";
		scores[_from] = 0; 
		levels[_from] = 0;
		stars[_from] = 0;
		return true;
    }

    function assign(address _to) public returns (bool success){
        require(nonces[_to] == 0);
		return _assign(msg.sender, _to, msg.sender);
	}

	function assignFrom(address _from, address _to) public returns (bool success){
        require(certifiedAccounts[msg.sender]);
	    return _assign(_from, _to, msg.sender);
    }

    function setRule(address _user, string _rule) public {
		require(certifiedAccounts[msg.sender]);
        rules[_user] = _rule;
		emit Rule(_user, _rule, msg.sender, now);
    }

	function setFund(address _user, string _fund) public {
		require(certifiedAccounts[msg.sender]);
        funds[_user] = _fund;
		emit Fund(_user, _fund, msg.sender, now);
    }
    
  	function freeze(bool _frozen) public onlyOwner {
        frozen = _frozen;
    }

    function freezeAccount(address _user, bool _frozen) public onlyOwner {
        frozenAccounts[_user] = _frozen;
        emit FreezeAccount(_user, _frozen, now);
    }
    
	function certifyAccount(address _user, bool _certified) public onlyOwner {
        certifiedAccounts[_user] = _certified;
        emit CertifyAccount(_user, _certified, now);
    }

	function transferToken(address _tokenAddress, address _recipient, uint _value) public onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(_recipient, _value);
    }

	function setName(string _tokenName, string _tokenSymbol) public onlyOwner {
        name = _tokenName;
        symbol = _tokenSymbol; 
	}

	function setNote(string _tokenNote) public onlyOwner {
        note = _tokenNote;
	}

	function setFee(uint _value) public onlyOwner {
        fee = _value;
	}

    function random(uint _range) public view returns(uint) {
	    if(_range == 0) {
	       return 0;  
	    }
        uint ran = uint(keccak256(abi.encodePacked(block.difficulty, now)));
        return ran % _range;
    }
    
    function shuffle(uint[] _values) public view returns(uint[]) {
        uint len = _values.length;
        uint[] memory t = _values; 
        uint temp = 0;
        uint ran = 0;
        for (uint i = 0; i < len; i++) {
           ran = random(i + 1);
          if (ran != i){
              temp = t[i];
              t[i] = t[ran];
              t[ran] = temp;
          }
        }
        return t;
   }
}