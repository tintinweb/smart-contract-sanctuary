pragma solidity ^0.4.23;

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
        assert(b &lt;= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c &gt;= a);
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
	event FreezeAccount(address indexed _target, bool _frozen, uint _timestamp);
	event CertifyAccount(address indexed _target, bool _certified, uint _timestamp);
}

contract ERC20Token is ERC20 {
    using SafeMath for uint;
    uint public totalToken;
	bool public frozen;
    mapping(address =&gt; uint) balances;
    mapping (address =&gt; mapping (address =&gt; uint)) allowances;
	mapping (address =&gt; bool) public frozenAccounts;
	mapping (address =&gt; bool) public certifiedAccounts;

    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
		require(_from != 0x0 &amp;&amp; _to != 0x0);
        require(balances[_from] &gt;= _value &amp;&amp; _value &gt; 0);
        require(balances[_to] + _value &gt; balances[_to]);
		require(!frozen);
		require(!frozenAccounts[_from]);                     
        require(!frozenAccounts[_to]);                       
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
		assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        return _transfer(msg.sender, _to,  _value) ;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(allowances[_from][msg.sender] &gt;= _value);     
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
	string public name = &quot;Lover&quot;;
    string public symbol = &quot;LOV&quot;;
    uint public constant decimals = 18;
	string public note = &quot;(C) loverchain.com all rights reserved&quot;;
    uint public burnedToken;
	uint public fee;
	mapping (address =&gt; string) public keys;
	mapping (address =&gt; string) public signatures;
	mapping (address =&gt; string) public identities;
	mapping (address =&gt; uint) public scores;
	mapping (address =&gt; uint) public levels;
    mapping (address =&gt; uint) public stars;
    mapping (address =&gt; string) public profiles;
	mapping (address =&gt; string) public properties;
	mapping (address =&gt; string) public rules;
    mapping (address =&gt; string) public funds;
	mapping (address =&gt; uint) public nonces;
	event Key(address indexed _user, string indexed _key, uint _timestamp);
	event Sign(address indexed _user, string indexed _data, uint _timestamp);
	event Register(address indexed _user, string indexed _identity, address _certifier, uint _timestamp);
	event Rule(address indexed _user, string _rule, address indexed _certifier, uint _timestamp);
	event Fund(address indexed _user, string _fund, address indexed _certifier, uint _timestamp);
	event Save(address indexed _user, uint _score, uint _level, uint _star, address indexed _certifier, uint _nonce, uint _timestamp);
	event Burn(address indexed _from, uint _burntAmount, uint _timestamp);

    function Lover() public {
		totalToken = 1000000000000000000000000000;
		balances[msg.sender] = totalToken;
		owner = msg.sender;
	    frozen = false;
		fee = 100000000000000000000;
		certifiedAccounts[msg.sender] = true; 
    }

    function burn(uint _burntAmount) public returns (bool success) {
    	require(balances[msg.sender] &gt;= _burntAmount &amp;&amp; _burntAmount &gt; 0);
		require(totalToken - _burntAmount &gt;= 100000000000000000000000000);
    	balances[msg.sender] = balances[msg.sender].sub(_burntAmount);
    	totalToken = totalToken.sub(_burntAmount);
    	burnedToken = burnedToken.add(_burntAmount);
    	emit Transfer(msg.sender, 0x0, _burntAmount);
    	emit Burn(msg.sender, _burntAmount, now);
    	return true;
	}

    function setKey(string _key) public {
        require(bytes(_key).length &gt;= 32);
        keys[msg.sender] = _key;
		emit Key(msg.sender, _key, now);
    }

    function sign(string _data) public {
        require(bytes(_data).length &gt;= 32);
        signatures[msg.sender] = _data;
		emit Sign(msg.sender, _data, now);
    }

	function register(address _user, string _identity) public {
		require(bytes(_identity).length &gt; 0);
		require(certifiedAccounts[msg.sender]);
		identities[_user] = _identity;
		emit Register(_user, _identity, msg.sender, now);
    }

    function _save(address _user, uint _score, uint _level, uint _star, string _profile, string _property, address _certifier, uint _nonce, uint _timestamp) internal {
		require(_nonce == nonces[_user] + 1);  
	    if(bytes(_profile).length &gt; 16){
			profiles[_user] = _profile;
		}
	    if(bytes(_property).length &gt; 16){
		    properties[_user] = _property;
		}
		if(_level &gt; levels[_user]){
			levels[_user] = _level;
		}
		scores[_user] = _score;
        stars[_user] = _star;
		nonces[_user] = _nonce;
		emit Save(_user, _score, _level, _star, _certifier, _nonce, _timestamp);
    }

    function save(address _user, uint _score, uint _level, uint _star, string _profile, string _property, uint _nonce) public {
        require(certifiedAccounts[msg.sender]);  
		_save(_user, _score, _level, _star, _profile, _property, msg.sender, _nonce, now);
    }

	function _assign(address _from, address _to, address _certifier) internal {
		require(_from != 0x0 &amp;&amp; _to != 0x0);
		uint _timestamp = now;
		uint _nonce = nonces[_from];
		_save(_to, scores[_from], levels[_from], stars[_from], profiles[_from], properties[_from], _certifier, _nonce, _timestamp);
        profiles[_from] = &quot;&quot;;
        properties[_from] = &quot;&quot;;
		scores[_from] = 0; 
		levels[_from] = 0;
		stars[_from] = 0;
    }

    function assign(address _to) public {
		_transfer(msg.sender, owner, fee);
		_assign(msg.sender, _to, owner);
	}

	function assignFrom(address _from, address _to) public {
        require(certifiedAccounts[msg.sender]);
	    _assign(_from, _to, msg.sender);
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
        uint ran = uint(keccak256(block.difficulty, now));
        return ran % _range;
    }
    
    function shuffle(uint[] _tiles) public view returns(uint[]) {
        uint len = _tiles.length;
        uint[] memory t = _tiles; 
        uint temp = 0;
        uint ran = 0;
        for (uint i = 0; i &lt; len; i++) {
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