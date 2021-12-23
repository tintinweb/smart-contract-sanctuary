/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

pragma solidity 0.8.0;

contract TokenERC20 {
    string name;
    string symbol;
    uint8 decimals;
    uint8 public _tokenPrice;
    address public owner;
    uint256 public InitialSupply;
    uint256 public totalSupply;
    uint256 public tokenBuyBalance;
    uint256 public Balance4Dividends;
    uint256 public shareholdersBalance;
    uint256 public totalShareholders;

    mapping (uint => address) shareholders;
    mapping (address => bool) registeredShareholders;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier notonlyOwner {
        require(msg.sender != owner);
        _;
    }


constructor () public {
        name = "rabotay";           
        symbol = "nerabotaet";  
        decimals = 0;
        totalShareholders = 0;
        _tokenPrice = 1;
        InitialSupply = 200;
        totalSupply = InitialSupply * 10 ** uint(decimals);  
        balanceOf[msg.sender] = totalSupply;  
        owner = msg.sender;
    }


    function _transfer(address _from, address _to, uint _value) public {
        require(balanceOf[_from] >= _value); 
        require(balanceOf[_to] + _value > balanceOf[_to]); // Проверка на переполнение
        uint previousBalances = balanceOf[_from] + balanceOf[_to]; // Сохранить для утверждения в будущем
        balanceOf[_from] -= _value; // Вычитать из отправителя
        balanceOf[_to] += _value; // Добавить то же самое к получателю
        if (msg.sender == owner && _to != owner) {
            shareholdersBalance += _value;
        }
        /* Remove from shareholders count if tokens spent from holder to owner */
        if (msg.sender != owner && _to == owner) {
            shareholdersBalance -= _value;
        }


        emit Transfer(msg.sender, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); // Утверждает используются на использование статического анализа для поиска ошибок в коде. Они никогда не должны терпеть неудачу
    }

     function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Проверьте, достаточно ли у отправителя
        balanceOf[msg.sender] -= _value;            // Вычитать из отправителя
        totalSupply -= _value;                      // Обновления totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


function sendProfit() payable external notonlyOwner { 
        require(msg.value/10**18 > 0  && msg.value % 10*18 == 0) ;
        Balance4Dividends += msg.value/(10**18);
}
function payDividends() external onlyOwner {
        require(Balance4Dividends > 0 && totalShareholders > 0);
            uint256 balance = Balance4Dividends;
            for (uint i = 1; i <= totalShareholders; i++) {
                uint256 currentBalance = balanceOf[shareholders[i]];
                if (currentBalance > 0) {
                    uint256 amount = balance * currentBalance / shareholdersBalance;
                    emit Transfer(owner, shareholders[i], amount);
                }
            }
        }
receive() external payable {
     require(msg.value/10**18 > 0 && msg.value/10**18 >= _tokenPrice);
        uint256 _numTokens = (msg.value/(10**18))/ _tokenPrice;
        balanceOf[msg.sender] += _numTokens;
        balanceOf[owner] -= _numTokens;
        emit Transfer(owner, msg.sender, _numTokens);
        if (registeredShareholders[msg.sender] == false) { 
            totalShareholders += 1;
            shareholders[totalShareholders] = msg.sender;
            registeredShareholders[msg.sender] = true;
        }
        if (msg.sender != owner) {
            shareholdersBalance += _numTokens;
        
        }
        tokenBuyBalance += msg.value/(10**18);
}
}