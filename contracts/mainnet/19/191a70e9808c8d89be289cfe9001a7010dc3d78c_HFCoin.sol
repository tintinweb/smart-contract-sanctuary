pragma solidity ^0.4.21;

contract HFCoin {
    string public name;
    string public symbol;
    address public owner;
    uint256 public prizeAmount = 0;
    bool public gameStarted = false;
    bool public prizeWon = false;

    mapping (address => uint256) public balanceOf;
    
    event Burn(address indexed from, uint256 value);
    event Redemption(address indexed from, uint256 value);
    event TokenRequest(address indexed from, uint256 value);
    event Winner(address indexed from);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function HFCoin(
        string tokenName,
        string tokenSymbol
    ) public 
    {
        balanceOf[msg.sender] = 0;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(_value <= 10);
        balanceOf[msg.sender] -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function _redeem(address _from, uint256 _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[owner] + _value > balanceOf[owner]);
        require(_value <= 1337);

        balanceOf[_from] -= _value;
        balanceOf[owner] += _value;
        emit Redemption(_from, _value);

        if (_value == 1337 && gameStarted && !prizeWon) {
            prizeWon = true;
            emit Winner(_from);
            _from.transfer(prizeAmount);
        }
    }

    function redeem(uint256 _value) public {
        _redeem(msg.sender, _value);
    }

    function _requestTokens(address _to, uint256 _value) internal {
        require(balanceOf[_to] + _value <= 10);
        balanceOf[_to] += _value;
        emit TokenRequest(_to, _value);  
    }

    function requestTokens(uint256 _value) public {
        _requestTokens(msg.sender, _value);
    }

    function prizeDeposit() public onlyOwner payable {}

    function startGame(uint256 _prizeAmount) public onlyOwner {
        prizeAmount = _prizeAmount;
        gameStarted = true;
    }

    function gameOver() public onlyOwner {
        selfdestruct(owner);
    }
}