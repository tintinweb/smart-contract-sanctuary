pragma solidity ^0.4.20;
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
        emit OwnershipTransferred(owner, newOwner);
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
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    modifier canMint(){require(!mintingFinished); _;}

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
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
        emit Burn(burner, _value);
    }
}

contract RewardToken is StandardToken, Ownable {
    struct Payment {
        uint time;
        uint amount;
    }

    Payment[] public repayments;
    mapping(address => Payment[]) public rewards;

    event Reward(address indexed to, uint256 amount);

    function repayment() onlyOwner payable public {
        require(msg.value >= 0.01 * 1 ether);

        repayments.push(Payment({time : now, amount : msg.value}));
    }

    function _reward(address _to) private returns(bool) {
        if(rewards[_to].length < repayments.length) {
            uint sum = 0;
            for(uint i = rewards[_to].length; i < repayments.length; i++) {
                uint amount = balances[_to] > 0 ? (repayments[i].amount * balances[_to] / totalSupply) : 0;
                rewards[_to].push(Payment({time : now, amount : amount}));
                sum += amount;
            }
            if(sum > 0) {
                _to.transfer(sum);
                emit Reward(_to, sum);
            }
            return true;
        }
        return false;
    }
    function reward() public returns(bool) {
        return _reward(msg.sender);
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        _reward(msg.sender);
        _reward(_to);
        return super.transfer(_to, _value);
    }

    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        _reward(msg.sender);
        for(uint i = 0; i < _to.length; i++) {
            _reward(_to[i]);
        }

        return super.multiTransfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        _reward(_from);
        _reward(_to);
        return super.transferFrom(_from, _to, _value);
    }
}

contract Token is CappedToken, BurnableToken, RewardToken {
    function Token() CappedToken(10000 * 1 ether) StandardToken("CRYPTtesttt", "CRYPTtesttt", 18) public {
        
    }
}
contract Crowdsale is Pausable {
    using SafeMath for uint;

    Token public token;
    address public beneficiary = 0x8320449742D5094A410B75171c72328afDBBb70b; // Кошелек компании
    address public bountyP = 0x1b640aD9909eAc9efc9D686909EE2D28702836BE;     // Кошелёк для Бонусов
	
    uint public collectedWei; // Собранные Веи
    uint public refundedWei; 
    uint private tokensSold; // Проданное количество Токенов
	uint private tokensForSale = 4500 * 1 ether; // Токены на продажу
    uint public SoldToken = tokensSold / 1 ether;
    uint public SaleToken = tokensForSale / 1 ether;
	
    //uint public priceTokenWei = 7142857142857142; 
    uint private priceTokenWei = 12690355329949;  // 1 токен равен 0,01$ (1eth = 788$)
    string public TokenPriceETH = "0.000013";  // Стоимость токена 
    //uint public bonusPercent = 0; // Бонусная часть
    uint private Sb = 1 ether; // Цифры после запятой 18
    uint private oSb = Sb * 5000; // Токены для Владельца 
    uint private BountyCRYPT = Sb * 500; // Токены для Баунти-компании  
    uint private PRTC = Sb * 1000; // PreICO количество токенов для продажи 
    
	string public IcoStatus = "PreIco";

    bool public crowdsaleClosed = false;
    bool public crowdsaleRefund = false;
	
    mapping(address => uint256) public purchaseBalances; 
    event Rurchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Refund(address indexed holder, uint256 etherAmount); // Возврат Средств
    event CrowdsaleClose();
    event CrowdsaleRefund();
	
	
	
    function Crowdsale() public {
     token = new Token();
	 
	/*Отправляем владельцу  и на Баунти кошелйк*/
	 emit Rurchase(beneficiary, oSb, 0);
	 token.mint(beneficiary, oSb);
     emit Rurchase(bountyP, BountyCRYPT, 0); // Баунти
	 token.mint(bountyP, BountyCRYPT); 
    }
    function() payable public {
     purchase();
    }
    function setTokenRate(uint _value, string _newpriceeth) onlyOwner whenPaused public {
        require(!crowdsaleClosed);
        priceTokenWei =  _value;
        TokenPriceETH = _newpriceeth;
        
    }
	function purchase() whenNotPaused payable public {
        require(!crowdsaleClosed);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.000013 ether);    // Минимальное количество Эфиров для покупки 
        uint sum = msg.value;         // Сумма на которую хочет купить Токены
        uint amount = sum.mul(1 ether).div(priceTokenWei);
        uint retSum = 0;
    if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            retSum = retAmount.mul(priceTokenWei).div(1 ether);
            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }
        tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);
        purchaseBalances[msg.sender] = purchaseBalances[msg.sender].add(sum);
        token.mint(msg.sender, amount);
        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }
		/*Меняем статус ICO*/
		if(tokensSold > PRTC){
			if(tokensForSale == tokensSold){
				IcoStatus = "The End :D";
			}else{
				IcoStatus = "ICO";
			}
		}
        emit Rurchase(msg.sender, amount, sum);
    }
    function refund() public {
        require(crowdsaleRefund);
        require(purchaseBalances[msg.sender] > 0);
        uint sum = purchaseBalances[msg.sender]; // Cсумма отправителя
        purchaseBalances[msg.sender] = 0;
        refundedWei = refundedWei.add(sum);
        msg.sender.transfer(sum);   
        emit Refund(msg.sender, sum);
    }
    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        beneficiary.transfer(address(this).balance);
        token.mint(beneficiary, token.cap().sub(token.totalSupply()));
        token.transferOwnership(beneficiary);
        crowdsaleClosed = true;
        emit CrowdsaleClose();
    }
    function refundCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        crowdsaleRefund = true;
        crowdsaleClosed = true;
        emit CrowdsaleRefund();
    }
}