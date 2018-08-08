/*! prt.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if(a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _;  }

    constructor() public {
        owner = msg.sender;
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
}

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    uint256 totalSupply_;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        require(_to.length == _value.length);

        for(uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _value[i]);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];

        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract MintableToken is StandardToken, Ownable {
    bool public mintingFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() { require(!mintingFinished); _; }
    modifier hasMintPermission() { require(msg.sender == owner); _; }

    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;

        emit MintFinished();
        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address _to, uint256 _amount) public returns(bool) {
        require(totalSupply_.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}

contract Withdrawable is Ownable {
    function withdrawEther(address _to, uint _value) onlyOwner public {
        require(_to != address(0));
        require(address(this).balance >= _value);

        _to.transfer(_value);
    }

    function withdrawTokensTransfer(ERC20 _token, address _to, uint256 _value) onlyOwner public {
        require(_token.transfer(_to, _value));
    }

    function withdrawTokensTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) onlyOwner public {
        require(_token.transferFrom(_from, _to, _value));
    }

    function withdrawTokensApprove(ERC20 _token, address _spender, uint256 _value) onlyOwner public {
        require(_token.approve(_spender, _value));
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract Manageable is Ownable {
    address[] public managers;

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager() { require(isManager(msg.sender)); _; }

    function countManagers() view public returns(uint) {
        return managers.length;
    }

    function getManagers() view public returns(address[]) {
        return managers;
    }

    function isManager(address _manager) view public returns(bool) {
        for(uint i = 0; i < managers.length; i++) {
            if(managers[i] == _manager) {
                return true;
            }
        }
        return false;
    }

    function addManager(address _manager) onlyOwner public {
        require(_manager != address(0));
        require(!isManager(_manager));

        managers.push(_manager);

        emit ManagerAdded(_manager);
    }

    function removeManager(address _manager) onlyOwner public {
        require(isManager(_manager));

        uint index = 0;
        for(uint i = 0; i < managers.length; i++) {
            if(managers[i] == _manager) {
                index = i;
            }
        }

        for(; index < managers.length - 1; index++) {
            managers[index] = managers[index + 1];
        }
        
        managers.length--;
        emit ManagerRemoved(_manager);
    }
}


/*
    Papusha Token
*/
contract Token is CappedToken, BurnableToken, Withdrawable {
    constructor() CappedToken(100000000e18) StandardToken("Papusha Rocket Token", "PRT", 18) public {
        
    }
}

contract Crowdsale is Manageable, Withdrawable, Pausable {
    using SafeMath for uint;

    Token public token;
    bool public crowdsaleClosed = false;

    event ExternalPurchase(address indexed holder, string tx, string currency, uint256 currencyAmount, uint256 rateToEther, uint256 tokenAmount);
    event CrowdsaleClose();
   
    constructor() public {
        token = new Token();
    }

    function externalPurchase(address _to, string _tx, string _currency, uint _value, uint256 _rate, uint256 _tokens) whenNotPaused onlyManager public {
        token.mint(_to, _tokens);
        emit ExternalPurchase(_to, _tx, _currency, _value, _rate, _tokens);
    }

    function closeCrowdsale(address _to) onlyOwner public {
        require(!crowdsaleClosed);

        token.transferOwnership(_to);
        crowdsaleClosed = true;

        emit CrowdsaleClose();
    }
}