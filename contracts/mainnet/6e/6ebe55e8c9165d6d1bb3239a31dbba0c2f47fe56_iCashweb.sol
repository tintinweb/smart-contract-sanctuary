pragma solidity ^0.4.23;
///////////////////////////////////////////////////
//  
//  `iCashweb` ICW Token Contract
//
//  Total Tokens: 300,000,000.000000000000000000
//  Name: iCashweb
//  Symbol: ICWeb
//  Decimal Scheme: 18
//  
//  by Nishad Vadgama
///////////////////////////////////////////////////

library iMath {
    function mul(
        uint256 a, uint256 b
    ) 
    internal 
    pure 
    returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(
        uint256 a, uint256 b
    ) 
    internal 
    pure 
    returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(
        uint256 a, uint256 b
    ) 
    internal 
    pure 
    returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(
        uint256 a, uint256 b
    ) 
    internal 
    pure 
    returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract iSimpleContract {
    function changeRate(
        uint256 value
    ) 
    public 
    returns(bool);

    function startMinting(
        bool status
    ) 
    public 
    returns(bool);  

    function changeOwnerShip(
        address toWhom
    ) 
    public 
    returns(bool);

    function releaseMintTokens() 
    public 
    returns(bool);

    function transferMintTokens(
        address to, uint256 value
    ) 
    public 
    returns(bool);

    function moveMintTokens(
        address from, address to, uint256 value
    ) 
    public 
    returns(bool);

    function manageOperable(
        address _from, bool _value
    ) 
    public 
    returns(bool);

    function isOperable(
        address _from
    ) 
    public 
    view 
    returns(bool);

    event Release(
        address indexed from, uint256 value
    );

    event Operable(
        address indexed from, address indexed to, bool value
    );
}
contract iERC01Basic is iSimpleContract {
    function totalSupply() 
    public 
    view 
    returns(uint256);

    function balanceOf(
        address who
    ) 
    public 
    view 
    returns(uint256);

    function transfer(
        address to, uint256 value
    ) 
    public 
    returns(bool);

    function transferTokens()
    public 
    payable;

    event Transfer(
        address indexed from, address indexed to, uint256 value
    );
}
contract iERC20 is iERC01Basic {
    function allowance(
        address owner, address spender
    ) 
    public 
    view 
    returns(uint256);

    function transferFrom(
        address from, address to, uint256 value
    ) 
    public 
    returns(bool);

    function approve(
        address spender, uint256 value
    ) 
    public 
    returns(bool);
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );
}
contract ICWToken is iERC01Basic {
    using iMath for uint256;
    mapping(address => uint256)     balances;
    mapping(address => bool)        operable;
    address public                  contractModifierAddress;
    uint256                         _totalSupply;
    uint256                         _totalMintSupply;
    uint256                         _maxMintable;
    uint256                         _rate = 100;
    bool                            _mintingStarted;
    bool                            _minted;

    uint8 public constant           decimals = 18;
    uint256 public constant         INITIAL_SUPPLY = 150000000 * (10 ** uint256(decimals));

    modifier onlyByOwned() 
    {
        require(msg.sender == contractModifierAddress || operable[msg.sender] == true);
        _;
    }

    function getMinted() 
    public 
    view 
    returns(bool) {
        return _minted;
    }

    function getOwner() 
    public 
    view 
    returns(address) {
        return contractModifierAddress;
    }
    
    function getMintingStatus() 
    public 
    view 
    returns(bool) {
        return _mintingStarted;
    }

    function getRate() 
    public 
    view 
    returns(uint256) {
        return _rate;
    }

    function totalSupply() 
    public 
    view 
    returns(uint256) {
        return _totalSupply;
    }

    function totalMintSupply() 
    public 
    view 
    returns(uint256) {
        return _totalMintSupply;
    }

    function balanceOf(
        address _owner
    ) 
    public 
    view 
    returns(uint256 balance) {
        return balances[_owner];
    }

    function destroyContract() 
    public {
        require(msg.sender == contractModifierAddress);
        selfdestruct(contractModifierAddress);
    }

    function changeRate(
        uint256 _value
    ) 
    public 
    onlyByOwned 
    returns(bool) {
        require(_value > 0);
        _rate = _value;
        return true;
    }

    function startMinting(
        bool status_
    ) 
    public 
    onlyByOwned 
    returns(bool) {
        _mintingStarted = status_;
        return true;
    }

    function changeOwnerShip(
        address _to
    ) 
    public 
    onlyByOwned 
    returns(bool) {
        address oldOwner = contractModifierAddress;
        uint256 balAmount = balances[oldOwner];
        balances[_to] = balances[_to].add(balAmount);
        balances[oldOwner] = 0;
        contractModifierAddress = _to;
        emit Transfer(oldOwner, contractModifierAddress, balAmount);
        return true;
    }

    function releaseMintTokens() 
    public 
    onlyByOwned 
    returns(bool) {
        require(_minted == false);
        uint256 releaseAmount = _maxMintable.sub(_totalMintSupply);
        uint256 totalReleased = _totalMintSupply.add(releaseAmount);
        require(_maxMintable >= totalReleased);
        _totalMintSupply = _totalMintSupply.add(releaseAmount);
        balances[contractModifierAddress] = balances[contractModifierAddress].add(releaseAmount);
        emit Transfer(0x0, contractModifierAddress, releaseAmount);
        emit Release(contractModifierAddress, releaseAmount);
        return true;
    }

    function transferMintTokens(
        address _to, uint256 _value
    ) 
    public 
    onlyByOwned
    returns(bool) {
        uint totalToken = _totalMintSupply.add(_value);
        require(_maxMintable >= totalToken);
        balances[_to] = balances[_to].add(_value);
        _totalMintSupply = _totalMintSupply.add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

    function moveMintTokens(
        address _from, address _to, uint256 _value
    ) 
    public 
    onlyByOwned 
    returns(bool) {
        require(_to != _from);
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function manageOperable(
        address _from, bool _value
    ) 
    public returns(bool) {
        require(msg.sender == contractModifierAddress);
        operable[_from] = _value;
        emit Operable(msg.sender, _from, _value);
        return true;
    }

    function isOperable(
        address _from
    ) 
    public 
    view 
    returns(bool) {
        return operable[_from];
    }

    function transferTokens()
    public 
    payable {
        require(_mintingStarted == true && msg.value > 0);
        uint tokens = msg.value.mul(_rate);
        uint totalToken = _totalMintSupply.add(tokens);
        require(_maxMintable >= totalToken);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalMintSupply = _totalMintSupply.add(tokens);
        contractModifierAddress.transfer(msg.value);
        emit Transfer(0x0, msg.sender, tokens);
    }

    function transfer(
        address _to, uint256 _value
    ) 
    public 
    returns(bool) {
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
contract iCashwebToken is iERC20, ICWToken {
    mapping(
        address => mapping(address => uint256)
    ) internal _allowed;

    function transferFrom(
        address _from, address _to, uint256 _value
    ) 
    public 
    returns(bool) {
        require(_to != msg.sender);
        require(_value <= balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, uint256 _value
    ) 
    public 
    returns(bool) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner, address _spender
    ) 
    public 
    view 
    returns(uint256) {
        return _allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender, uint _addedValue
    ) 
    public 
    returns(bool) {
        _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender, uint _subtractedValue
    ) 
    public 
    returns(bool) {
        uint oldValue = _allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _allowed[msg.sender][_spender] = 0;
        } else {
            _allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }
}

contract iCashweb is iCashwebToken {
    string public constant name = "iCashweb";
    string public constant symbol = "ICWeb";
    constructor() 
    public {
        _mintingStarted = false;
        _minted = false;
        contractModifierAddress = msg.sender;
        _totalSupply = INITIAL_SUPPLY * 2;
        _maxMintable = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    function () 
    public 
    payable {
        transferTokens();
    }
}