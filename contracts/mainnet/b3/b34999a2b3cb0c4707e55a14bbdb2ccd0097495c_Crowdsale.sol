/*! Smartcontract Token | (c) 2018 BelovITLab LLC | License: MIT */
//
//                                     _
//                                _.-~~.)              SMARTCONTRACT.RU
//          _.--~~~~~---....__  .&#39; . .,&#39;          
//        ,&#39;. . . . . . . . . .~- ._ (                 Development smart-contracts
//       ( .. .g. . . . . . . . . . .~-._              Investor&#39;s office for ICO
//    .~__.-~    ~`. . . . . . . . . . . -.
//    `----..._      ~-=~~-. . . . . . . . ~-.         Telegram: https://goo.gl/FRP4nz    
//              ~-._   `-._ ~=_~~--. . . . . .~.
//               | .~-.._  ~--._-.    ~-. . . . ~-.
//                \ .(   ~~--.._~&#39;       `. . . . .~-.                ,
//                 `._\         ~~--.._    `. . . . . ~-.    .- .   ,&#39;/
// _  . _ . -~\        _ ..  _          ~~--.`_. . . . . ~-_     ,-&#39;,&#39;`  .
//              ` ._           ~                ~--. . . . .~=.-&#39;. /. `
//        - . -~            -. _ . - ~ - _   - ~     ~--..__~ _,. /   \  - ~
//               . __ ..                   ~-               ~~_. (  `
// )`. _ _               `-       ..  - .    . - ~ ~ .    \    ~-` ` `  `. _
//                                                     - .  `  .   \  \ `.


pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
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

        ManagerAdded(_manager);
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
        ManagerRemoved(_manager);
    }
}

contract Withdrawable is Ownable {
    function withdrawEther(address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));
        require(this.balance >= _value);

        _to.transfer(_value);

        return true;
    }

    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));

        return _token.transfer(_to, _value);
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
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract ERC20 {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function StandardToken(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

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

        Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];

        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() { require(!mintingFinished); _; }
    modifier notMint() { require(mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;

        MintFinished();

        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        require(totalSupply.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(burner, _value);
    }
}

/* This is your discount for development smartcontract 5% */
/* For order smart-contract please contact at Telegram: https://t.me/joinchat/Bft2vxACXWjuxw8jH15G6w */

/* We develop inverstor&#39;s office for ICO, operator&#39;s dashboard for ICO, Token Air Drop  */
/* <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f79e999198b7849a9685839498998385969483d98582">[email&#160;protected]</a> */

contract Token is CappedToken, BurnableToken {

    string public URL = "http://smartcontract.ru";

    function Token() CappedToken(100000000 * 1 ether) StandardToken("SMARTCONTRACT.RU", "SMART", 18) public {
        
    }
    
    function transfer(address _to, uint256 _value) public returns(bool) {
        return super.transfer(_to, _value);
    }
    
    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        return super.multiTransfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


contract Crowdsale is Manageable, Withdrawable, Pausable {
    using SafeMath for uint;

    Token public token;
    bool public crowdsaleClosed = false;

    event ExternalPurchase(address indexed holder, string tx, string currency, uint256 currencyAmount, uint256 rateToEther, uint256 tokenAmount);
    event CrowdsaleClose();
   
    function Crowdsale() public {
        token = Token(0x5DD98e580f8a12C4048C26d4f489dcf2C5Cfc936);
        addManager(0x3c64B86cEE4E60EDdA517521b46Ac74134442058);
    }

    function externalPurchase(address _to, string _tx, string _currency, uint _value, uint256 _rate, uint256 _tokens) whenNotPaused onlyManager public {
        token.mint(_to, _tokens);
        ExternalPurchase(_to, _tx, _currency, _value, _rate, _tokens);
    }

    function closeCrowdsale(address _to) onlyOwner public {
        require(!crowdsaleClosed);

        token.transferOwnership(_to);
        crowdsaleClosed = true;

        CrowdsaleClose();
    }
}