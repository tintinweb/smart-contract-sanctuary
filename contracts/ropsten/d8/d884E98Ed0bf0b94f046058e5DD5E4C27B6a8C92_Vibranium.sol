pragma solidity >=0.8.7;

contract Vibranium {
    
    string private _name = "Vibranium";
    string private _symbol = "VIB";
    uint8 private _decimals = 2;
    uint256 private _totalSupply;
    uint256 public price = 0.00001 ether; 
    address payable owner;
    uint256 public count;
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _alow;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);
    
    // инициализация при деплое контракта
    constructor (){
        uint256 suply = 21000*10**_decimals;
        _totalSupply = suply;
        count = 0;
        owner = payable(msg.sender);
    }
    
    // Имя токена
    function name() public view returns (string memory){
        return _name;
    }
    
    // Тикет символа
    function symbol() public view returns (string memory){
        return _symbol;
    }
    
    // Покупка токенов
    function buy() public payable {
        require(count < 2100000, "VIB is over");
        uint256 amount = (msg.value / price) * 10**_decimals;
        _balances[msg.sender] += amount;
        _totalSupply -= amount;
        count += amount;
        
        //if (_totalSupply - 1000*10**_decimals <= 2000000) {
            //uint256 ten = price * 0.1 ether;
           // price += ten;
        //}
        
        emit Transfer(address(0), msg.sender, amount);
        emit Buy(msg.sender,amount);
        
    }
    
    // Вывод ETH
    function withdraw() public {
        owner.transfer(address(this).balance);
    }
    
    // Удаление контракта
    function destroy() public {
        require(msg.sender == owner, "only owner can destroy");
        selfdestruct(owner);
    }
    
    // Количество знаков после запятой
    function decimals() public view returns (uint8){
        return _decimals;
    }
    
    // Общее количесво токенов
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    // Баланс токенов на адресе
    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }
    
    // Перевод токенов
    function transfer(address _to, uint256 _value) public returns (bool success){
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // Право на перевод токенов с кошелька владельца на другой адрес другим кошельком
    function approve(address _spender, uint256 _value) public returns (bool success){
        _alow[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // разрешенное количество токенов на перевод другим адресом
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _alow[_owner][_spender];
    }
    
    // Перевод с чужого адреса на свой/другой адрес
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_alow[_from][msg.sender] >= _value,"don't have money");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _alow[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}