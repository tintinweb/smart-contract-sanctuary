pragma solidity ^0.4.18;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract MintableToken {
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
}

contract TokenERC20 is Ownable, MintableToken {
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply;
    bool public isEnabled = true;

    mapping (address => bool) public saleAgents;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    function TokenERC20(string _tokenName, string _tokenSymbol) public {
        name = _tokenName; // Записываем название токена
        symbol = _tokenSymbol; // Записываем символ токена
        owner = msg.sender; // Делаем создателя контракта владельцем
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(_value <= balanceOf[_from]);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        require(isEnabled);

        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
         _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function mint(address _to, uint256 _amount) canMint public returns (bool) {
        require(msg.sender == owner || saleAgents[msg.sender]);
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
    
    function finishMinting() onlyOwner canMint public returns (bool) {
        uint256 ownerTokens = totalSupply.mul(2).div(3); // 60% * 2 / 3 = 40%
        mint(owner, ownerTokens);

        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);   // Проверяем, достаточно ли средств у сжигателя

        address burner = msg.sender;
        balanceOf[burner] = balanceOf[burner].sub(_value);  // Списываем с баланса сжигателя
        totalSupply = totalSupply.sub(_value);  // Обновляем общее количество токенов
        emit Burn(burner, _value);
        emit Transfer(burner, address(0x0), _value);
        return true;
    }

    function addSaleAgent (address _saleAgent) public onlyOwner {
        saleAgents[_saleAgent] = true;
    }

    function disable () public onlyOwner {
        require(isEnabled);
        isEnabled = false;
    }
    function enable () public onlyOwner {
        require(!isEnabled);
        isEnabled = true;
    }
}

contract Token is TokenERC20 {
    function Token() public TokenERC20("Ideal Digital Memory", "IDM") {}

}