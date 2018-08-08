/*! eft.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.21;

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

/*
    Exit Factory Token
*/
contract Token is CappedToken, BurnableToken, Withdrawable {
    uint public mintingFinishedTime;

    function Token() CappedToken(2000000000 ether) StandardToken("Exit Factory Token", "EXIT", 18) public {
        
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(mintingFinishedTime > 0 && now + 2 weeks >= mintingFinishedTime);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(mintingFinishedTime > 0 && now + 2 weeks >= mintingFinishedTime);
        return super.transferFrom(_from, _to, _value);
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinishedTime = now;
        return super.finishMinting();
    }
}

contract Crowdsale is Manageable, Withdrawable, Pausable {
    using SafeMath for uint;

    Token public token;
    uint public timeEnd;
    bool public crowdsaleClosed = false;

    uint public commandTookAway;

    event ExternalPurchase(address indexed holder, string tx, string currency, uint256 currencyAmount, uint256 rateToEther, uint256 tokenAmount);
    event CrowdsaleClose();
   
    function Crowdsale() public {
        token = new Token();

        token.mint(0x8871147bbF3f664e086F6F9f49F493Fcead5a8a9, 240000000 ether);     // Reserve Fund
        token.mint(0x1e2aD7B66914bf432F66295604A66a3279DDEB1D, 200000000 ether);     // Founders
        token.mint(0x235112Ca8A7c6c143b0E0902564f992955894BB1, 20000000 ether);      // Bounty
        token.mint(0x9246714faF8781c5D896eBBC0D09F93B6Ca6807e, 20000000 ether);      // IT Security
        token.mint(0xBB197831f6A2EA90cEff94Cf94A23aA16fdB77a4, 20000000 ether);      // Legal Compliance

        token.mint(this, 300000000 ether);                                           // Team, Advisors, Affiliate program

        addManager(0x3915029Dc964F32b7dE52cefd859Eb66A5f80c96);
    }

    function externalPurchase(address _to, string _tx, string _currency, uint _value, uint256 _rate, uint256 _tokens) whenNotPaused onlyManager public {
        token.mint(_to, _tokens);
        ExternalPurchase(_to, _tx, _currency, _value, _rate, _tokens);
    }

    function closeCrowdsale(address _to) onlyOwner public {
        require(!crowdsaleClosed);

        token.finishMinting();
        token.transferOwnership(_to);

        crowdsaleClosed = true;
        timeEnd = now;

        CrowdsaleClose();
    }
    
    function getCommandTokens() onlyOwner public {
        require(crowdsaleClosed);

        uint months = now.sub(timeEnd).div(30 days);

        require(months > 0);

        uint right = months.mul(12500000 ether);
        uint send = right.sub(commandTookAway);

        require(send > 0);
        
        commandTookAway = commandTookAway.add(send);

        token.transfer(0x7Ba026aBb24c55fFFfaE612E498efb1a22c12438, send.div(3));                    // Advisors
        token.transfer(0x1763D74a1B3c3C8844336Be3DC302ff77012aC81, send.div(3));                    // Team
        token.transfer(0xe1de68015AD6dCB0f79c34a6CaD58Dc097C76023, send.sub(send.div(3).mul(2)));   // Affiliate program
    }
    
    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_token != token || commandTookAway >= 300000000 ether);
        
        return super.withdrawTokens(_token, _to, _value);
    }
}