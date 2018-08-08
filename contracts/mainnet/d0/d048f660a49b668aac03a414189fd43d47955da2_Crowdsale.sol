/*! wem.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

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

contract Withdrawable is Ownable {
    function withdrawEther(address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));
        require(this.balance >= _value);

        _to.transfer(_value);

        return true;
    }

    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));

        return _token.call(&#39;transfer&#39;, _to, _value);
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

contract ERC223 is ERC20 {
    function transfer(address to, uint256 value, bytes data) public returns(bool);
}

contract ERC223Receiving {
    function tokenFallback(address from, uint256 value, bytes data) external;
}

contract StandardToken is ERC223 {
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

    function _transfer(address _to, uint256 _value, bytes _data) private returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        bool is_contract = false;
        assembly {
            is_contract := not(iszero(extcodesize(_to)))
        }

        if(is_contract) {
            ERC223Receiving receiver = ERC223Receiving(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            //receiver.call(&#39;tokenFallback&#39;, msg.sender, _value, _data);
        }

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        bytes memory empty;
        return _transfer(_to, _value, empty);
    }

    function transfer(address _to, uint256 _value, bytes _data) public returns(bool) {
        return _transfer(_to, _value, _data);
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
    Полное название токена: Wind Energy Mining
    Сокращенное: WEM 
    Эмиссия: 34 000 000

    PreICO  нет
    SetTokenRate нет
    Refund нет

    Цена фиксирована:
    1 ETH = 1000 WEM

    ICO
    на продажу токенов: 30 600 000
    Даты проведения: 20.03.2018 - 20.05.2018

    После окончания ICO нераскупленные токены передаются бенефициару

    Дополнительная информация:
    Бонусы - при приобретении 1000 и более токенов WEM покупатель дополнительно получает  5% от приобретенного количества бесплатно.
    Обратный выкуп токенов WEM будет производиться по фиксированной цене 0,0015 ETH за один WEM, начиная с 01.03.2019 до конца 2020 года.

    ---- En -----

    Token name: Wind Energy Mining
    Symbol: WEM 
    Emission: 34,000,000

    PreICO - no
    SetTokenRate – no
    Refund - no

    Fixed price:
    1 ETH = 1,000 WEM

    ICO
    Tokens to be sold: 30,600,000
    ICO period: 20.03.2018 - 20.05.2018

    After the ICO, all unsold tokens will be sent to a beneficiary. 

    Additional information:
    Bonuses – when purchasing 1,000 and more WEM tokens, a buyer additionally receives 5% from the number of tokens purchased.
    WEM buyback will take place beginning on 01.03.2019 until the end of 2020, at a fixed price of 0.0015 ETH for 1 WEM.
*/

contract Token is CappedToken, BurnableToken, Withdrawable {
    function Token() CappedToken(34000000 * 1 ether) StandardToken("Wind Energy Mining", "WEM", 18) public {
        
    }
}

contract Crowdsale is Withdrawable, Pausable {
    using SafeMath for uint;

    Token public token;
    address public beneficiary = 0x16DEfd1C28006c117845509e4daec7Bc6DC40F50;

    uint public priceTokenWei = 0.001 ether;
    uint public priceTokenSellWei = 0.0015 ether;
    uint public tokensForSale = 30600000 * 1 ether;
    
    uint public purchaseStartTime = 1521147600;
    uint public purchaseEndTime = 1526763600;
    uint public sellStartTime = 1551387600;
    uint public sellEndTime = 1609448400;

    uint public tokensSold;
    uint public tokensSell;
    uint public collectedWei;
    uint public sellWei;

    bool public crowdsaleClosed = false;

    event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Sell(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event AccrueEther(address indexed holder, uint256 etherAmount);
    event CrowdsaleClose();

    function Crowdsale() public {
        token = new Token();
    }

    function() payable public {
        purchase();
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) whenNotPaused external {
        require(msg.sender == address(token));
        require(now >= sellStartTime && now < sellEndTime);

        uint sum = _value.mul(priceTokenSellWei).div(1 ether);

        tokensSell = tokensSell.add(_value);
        sellWei = sellWei.add(sum);

        _from.transfer(sum);

        Sell(_from, _value, sum);
    }

    function purchase() whenNotPaused payable public {
        require(!crowdsaleClosed);
        require(now >= purchaseStartTime && now < purchaseEndTime);
        require(msg.value >= 0.001 ether);
        require(tokensSold < tokensForSale);

        uint sum = msg.value;
        uint amount = sum.mul(1 ether).div(priceTokenWei);
        uint retSum = 0;
        
        if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            retSum = retAmount.mul(priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        if(amount >= 1000 ether) {
            amount = amount.add(amount.div(100).mul(5));
        }

        tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);

        beneficiary.transfer(sum);
        token.mint(msg.sender, amount);

        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }

        Purchase(msg.sender, amount, sum);
    }

    function accrueEther() payable public {
        AccrueEther(msg.sender, msg.value);
    }

    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        
        token.mint(beneficiary, token.cap() - token.totalSupply());
        token.finishMinting();
        token.transferOwnership(beneficiary);

        crowdsaleClosed = true;

        CrowdsaleClose();
    }
}