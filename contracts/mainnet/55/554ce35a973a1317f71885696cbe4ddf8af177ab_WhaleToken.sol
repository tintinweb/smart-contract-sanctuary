pragma solidity ^0.4.24;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external; 
}

contract WhaleConfig {
    using SafeMath for uint;

    string internal constant TOKEN_NAME     = "Whale Token";
    string internal constant TOKEN_SYMBOL   = "WATB";
    uint8  internal constant TOKEN_DECIMALS = 18;
    uint   internal constant INITIAL_SUPPLY = 20*1e8 * 10 ** uint(TOKEN_DECIMALS);
}

contract Ownable is WhaleConfig {
    address public ceo;
    
    event LogChangeCEO(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner {
        require(msg.sender == ceo);
        _;
    }
    
    constructor() public {
        ceo = msg.sender;
    }
    
    function changeCEO(address _owner) onlyOwner public returns (bool) {
        require(_owner != address(0));
        
        emit LogChangeCEO(ceo, _owner);
        ceo = _owner;
        
        return true;
    }

    function isOwner(address _owner) internal view returns (bool) {
        return ceo == _owner;
    }
}

contract Lockable is Ownable {
    mapping (address => bool) public locked;
    
    event LogLockup(address indexed target);
    
    function lockup(address _target) onlyOwner public returns (bool) {
	    require( !isOwner(_target) );

        locked[_target] = true;
        emit LogLockup(_target);
        return true;
    }
    
    function isLockup(address _target) internal view returns (bool) {
        if(true == locked[_target])
            return true;
    }
}

contract TokenERC20 {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event ERC20Token(address indexed owner, string name, string symbol, uint8 decimals, uint supply);
    event Transfer(address indexed from, address indexed to, uint value);
    event TransferFrom(address indexed from, address indexed to, address indexed spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        uint _initialSupply
    ) public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;
        totalSupply = _initialSupply;
        
        balanceOf[msg.sender] = totalSupply;
        
        emit ERC20Token(msg.sender, name, symbol, decimals, totalSupply);
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(SafeMath.add(balanceOf[_to], _value) > balanceOf[_to]);
        
        uint previousBalances = SafeMath.add(balanceOf[_from], balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        assert(SafeMath.add(balanceOf[_from], balanceOf[_to]) == previousBalances);
        return true;
    }
    
    function transfer(address _to, uint _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        
        emit TransferFrom(_from, _to, msg.sender, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowance[_owner][_spender];
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract WhaleToken is Lockable, TokenERC20 {
    string public version = "v1.0.2";
    
    mapping (address => bool) public frozenAccount;

    event LogFrozenAccount(address indexed target, bool frozen);
    event LogBurn(address indexed owner, uint value);
    event LogMining(address indexed recipient, uint value);
    event LogWithdrawContractToken(address indexed owner, uint value);
    
    constructor() TokenERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, INITIAL_SUPPLY) public {}

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(!frozenAccount[_from]); 
        require(!frozenAccount[_to]);
        require(!isLockup(_from));
        require(!isLockup(_to));

        return super._transfer(_from, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(!isLockup(msg.sender));
        return super.transferFrom(_from, _to, _value);
    }
    
    function freezeAccount(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(!isOwner(_target));
        require(!frozenAccount[_target]);

        frozenAccount[_target] = true;

        emit LogFrozenAccount(_target, true);
        return true;
    }
    
    function unfreezeAccount(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(frozenAccount[_target]);

        frozenAccount[_target] = false;

        emit LogFrozenAccount(_target, false);
        return true;
    }
    
    function () payable public { revert(); }
}