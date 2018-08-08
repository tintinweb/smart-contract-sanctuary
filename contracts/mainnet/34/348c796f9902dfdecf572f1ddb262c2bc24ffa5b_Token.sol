pragma solidity ^0.4.21;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) { return 0; }
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
        require(newOwner != address(this));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
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

contract StandardToken is ERC20{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) public balances;
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
        require(_to != address(this));
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
        require(_to != address(this));
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
contract MintableToken is StandardToken, Ownable{
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    modifier canMint(){require(!mintingFinished); _;}
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
		emit Mint(_to, _amount);
        emit Transfer(address(this), _to, _amount);
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
        require(msg.value >= 0.00000001 * 1 ether);
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
    function Token() CappedToken(10000000 * 1 ether) StandardToken("JULLAR0805", "JUL0805", 18) public {
        
    }
}
contract Crowdsale is Ownable{
    using SafeMath for uint;
    Token public token;
    address private beneficiary = 0x75E6d4a772DB168f34462a21b64192557ef5c504; // Кошелек компании
    uint public collectedWei; // Собранные Веи
    uint private refundedWei; 
	

    string public TokenPriceETH = "0.0000001";  // Стоимость токена 
	
	uint public tokensSold; // Проданное количество Токенов
	uint private tokensDm; // Проданное количество Токенов + Количество покупаемых токенов
	uint private tokensForSale = 45 * 1 ether; // Токены на продажу
    uint public SoldToken;
    uint public SaleToken = tokensForSale / 1 ether;
	uint public StartIcoStage = 0;
	// uint public priceTokenWei = 12690355329949;  // 1 токен равен 0,01$ (1eth = 788$)
    uint public priceTokenWei = 100000000000;  // 0.0000001 ETH за 1 токен
	
    bool public crowdsaleClosed = false;
    mapping(address => uint256) public purchaseBalances;  // Массив держателей токенов
    event Rurchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    
    event CrowdsaleClose();
	uint256 private oSb = 8000000 * 1 ether;
    /*Пауза и Старт*/
	bool public paused = false;
	uint public pausestatus = 1;
    event Pause();
    event StartNextIcoStage();
	function pause() private {
        pausestatus = 0;
		paused = true;
        emit Pause();
    }	
	function Crowdsale() public {
     token = new Token();
	 emit Rurchase(beneficiary, oSb, 0);
	 token.mint(beneficiary, oSb);
	}
    function() payable public {
		if(crowdsaleClosed == false){
		       purchase();
		}
    }	
	function purchase() payable public {
		require(pausestatus != 0);
        require(!crowdsaleClosed);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.0000001 ether);    // Минимальное количество Эфиров для покупки 
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

        emit Rurchase(msg.sender, amount, sum);
    }
	
	function StartNextStage() onlyOwner public {
        require(!crowdsaleClosed);
        require(pausestatus != 1);
		pausestatus = 1;
        paused = false;
        emit StartNextIcoStage(); // Начало этапа ICO 
    }

	
	/*Смена этапа и стоимости*/
	function NewStage() private {

		priceTokenWei = 200000000000; // Новая стоимость Токена 2 раза больше чем на PreICO
		TokenPriceETH = "0.0000001";
	}
    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        beneficiary.transfer(address(this).balance);
        token.mint(beneficiary, token.cap().sub(token.totalSupply()));
        token.transferOwnership(beneficiary);
        crowdsaleClosed = true;
        emit CrowdsaleClose();
    }
}